class_name Battle
extends RefCounted
## Pure combat logic (no nodes/scenes): 1 player Pokémon vs 1..3 enemies with data-driven intents.
## Implements: design/game-brief.md MVP features 1-2, story-001-combat-de-base,
## story-002-intentions-et-multi-ennemis, story-003-types, story-016-statuts (incl. the anti-lock rules).

enum State { PLAYER_TURN, WON, LOST }

const MIN_ENEMIES: int = 1
const MAX_ENEMIES: int = 3

signal state_changed
signal turn_started
signal card_played(card: CardData)
signal enemy_acted(enemy: Combatant, intent: EnemyIntent)
## Emitted for every damaging hit (card or enemy attack) AFTER state changes. `amount` is the
## final damage (strength and type multiplier applied) BEFORE block; `multiplier` is the type factor.
signal hit_resolved(target: Combatant, amount: int, multiplier: float)
## Emitted when a played attack card brings another Pokémon onto the field (before the hit resolves).
signal active_pokemon_changed(old_id: String, new_id: String)
signal battle_won
signal battle_lost
## Emitted when a held item's effect fired (UI feedback). Story 006.
signal item_triggered(item: ItemData)
## Status ailments (story 016). `value` of status_applied is the amount ADDED (read the combatant for the total).
signal status_applied(target: Combatant, status_id: String, value: int)
## A status dealt `amount` damage at the end of its carrier's turn (damage statuses only, after the HP changed).
signal status_ticked(target: Combatant, status_id: String, amount: int)
## An application was refused (type / held-item immunity) OR a played card of the paralysed player failed (the card is spent).
signal status_blocked(target: Combatant, status_id: String)
## `target` loses its turn because of `status_id`: an enemy does not act (no enemy_acted); the player loses
## `energy_lost` energy at the start of its turn (StatusData.player_energy_loss; cards are still drawn);
## an enemy fails its action through paralysis (chance rolled with the injected RNG).
signal turn_skipped(target: Combatant, status_id: String)
## A status that does not refresh (refresh_on_reapply false, e.g. paralysis) was re-applied while active: nothing changed.
signal status_unchanged(target: Combatant, status_id: String)
## A status disappeared (expired, decayed to 0, cured, woke on damage, thawed). Not emitted by the silent end-of-battle clear.
signal status_removed(target: Combatant, status_id: String)
## Emitted after a potion of `potions` was drunk (already removed from `potions`). Story 006.
signal potion_used(potion: PotionData)

var player: Combatant
## Id of the Pokémon currently on the field (shared HP/block; story 009). Read-only for the UI.
var active_pokemon_id: String = ""
var enemies: Array[Combatant] = []
var state: State = State.PLAYER_TURN
var energy: int = 0
var max_energy: int = 0
var hand_size: int = 0
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
## Held items active in this battle (story 006); their triggers are fired by this class.
var items: Array[ItemData] = []
## Potions carried into the battle, usable with use_potion (removed once used).
var potions: Array[PotionData] = []
## Extra damage on every attack card until the end of this turn (potion "Attaque +").
var turn_damage_bonus: int = 0
## Energy the player lost at the start of the CURRENT turn because of a status (sleep / freeze); 0 on a normal turn.
var energy_lost: int = 0
var _attacks_played: int = 0

var _rng: RandomNumberGenerator
var _type_chart: TypeChart
var _pokemon_lookup: Callable = Callable()
var _status_book: StatusBook


## Starts a battle. pokemon_lookup(pokemon_id) -> Dictionary {id, name, sprite_path, types} (GameData.get_pokemon_info)
## lets cards bring other Pokémon in; starter_pokemon_id is the active Pokémon at battle start. rng is injected so shuffles and weighted intents are seedable.
## held_items / carried_potions (story 006) fire their triggers / can be drunk; passive items (extra draw / energy)
## are NOT handled here: the caller adds them to energy_per_turn / cards_per_turn (RunState.create_battle does).
## Expects 1..3 enemies: extra enemies are ignored, an empty list is reported (push_error).
## type_chart is injected; null means no types (every hit neutral).
func _init(player_combatant: Combatant, enemy_list: Array[Combatant], deck: Array[CardData],
		energy_per_turn: int, cards_per_turn: int, rng: RandomNumberGenerator,
		type_chart: TypeChart = null, pokemon_lookup: Callable = Callable(), starter_pokemon_id: String = "",
			held_items: Array[ItemData] = [], carried_potions: Array[PotionData] = [],
			status_book: StatusBook = null) -> void:
	_status_book = status_book if status_book != null else StatusBook.new()
	player = player_combatant
	items = held_items.duplicate()
	potions = carried_potions.duplicate()
	_pokemon_lookup = pokemon_lookup
	active_pokemon_id = starter_pokemon_id if not starter_pokemon_id.is_empty() else player.active_pokemon_id
	if active_pokemon_id.is_empty():
		active_pokemon_id = player.id
	if not starter_pokemon_id.is_empty():
		_apply_identity(starter_pokemon_id)  # battle start: the starter is on the field
	_type_chart = type_chart if type_chart != null else TypeChart.neutral_chart()
	for e: Combatant in enemy_list:
		if e != null and enemies.size() < MAX_ENEMIES:
			enemies.append(e)
	if enemy_list.size() > MAX_ENEMIES:
		push_error("Battle: %d enemies given, only the first %d are used" % [enemy_list.size(), MAX_ENEMIES])
	if enemies.size() < MIN_ENEMIES:
		push_error("Battle: at least %d enemy is required" % MIN_ENEMIES)
	max_energy = energy_per_turn
	hand_size = cards_per_turn
	_rng = rng
	draw_pile = deck.duplicate()
	_shuffle(draw_pile)


## Begins the first player turn (call once after connecting signals).
func start() -> void:
	if enemies.is_empty():
		return
	for e: Combatant in enemies:
		_roll_intent(e)
	_fire_items(ItemData.TRIGGER_BATTLE_START)
	_start_player_turn(true)


## True if the card at hand index can be played now (state, index, energy).
func can_play(index: int) -> bool:
	if state != State.PLAYER_TURN or index < 0 or index >= hand.size():
		return false
	return hand[index].cost <= energy


## True if enemies[index] exists and is alive (a valid target).
func is_valid_target(index: int) -> bool:
	return index >= 0 and index < enemies.size() and enemies[index].is_alive()


## Index of the first living enemy, or -1.
func first_living_enemy() -> int:
	for i: int in enemies.size():
		if enemies[i].is_alive():
			return i
	return -1


## Plays hand[index]. target_index is an index into `enemies`; required for cards that
## deal damage, ignored by the others. Returns false (and changes nothing) if invalid.
func play_card(index: int, target_index: int = -1) -> bool:
	if not can_play(index):
		return false
	var card: CardData = hand[index]
	if card.needs_target() and not is_valid_target(target_index):
		return false
	# Paralysed player: each played card may fizzle (energy spent, no effect). The RNG is only drawn when paralysed.
	var fizzle_id: String = _roll_card_fizzle()
	if not fizzle_id.is_empty():
		energy -= card.cost
		hand.remove_at(index)
		discard_pile.append(card)
		status_blocked.emit(player, fizzle_id)
		card_played.emit(card)
		state_changed.emit()
		return true
	# Only attack cards bring their Pokémon in, BEFORE the hit (types/intents use the new Pokémon).
	if card.kind == CardData.KIND_ATTACK and not card.pokemon_id.is_empty() and card.pokemon_id != active_pokemon_id:
		var old_id: String = active_pokemon_id
		active_pokemon_id = card.pokemon_id
		_apply_identity(card.pokemon_id)
		refresh_intents()
		active_pokemon_changed.emit(old_id, active_pokemon_id)
	energy -= card.cost
	hand.remove_at(index)
	discard_pile.append(card)
	var hit_target: Combatant = null
	var hit_amount: int = 0
	var hit_mult: float = 1.0
	if card.damage > 0:
		hit_target = enemies[target_index]
		# Bonuses (items, "Attaque +") are added BEFORE the type multiplier, like enemy strength.
		var bonus: int = turn_damage_bonus - _attack_penalty(player)  # burn: weaker attacks (before the type multiplier)
		for item: ItemData in ItemEffects.damage_bonus_sources(items, card, _attacks_played):
			bonus += item.total("damage_bonus")
			item_triggered.emit(item)
		hit_mult = _type_chart.damage_multiplier(card.type_id, hit_target.type_ids)
		hit_amount = _type_chart.final_damage(card.damage + bonus, card.type_id, hit_target.type_ids)
		hit_target.take_damage(hit_amount)  # block absorbs AFTER the type multiplier
		if hit_amount > 0:
			_on_damaged(hit_target, card.type_id)
		if not hit_target.is_alive():
			hit_target.intent = null  # a K.O. enemy no longer acts
	if card.block > 0:
		player.add_block(card.block)
	if hit_target != null:
		hit_resolved.emit(hit_target, hit_amount, hit_mult)
	if card.kind == CardData.KIND_ATTACK:
		_attacks_played += 1
	# Status of the card: applied AFTER the damage (a sleeping target is not woken by its own card). A hit that deals
	# no damage because of a 0x type multiplier inflicts nothing; a status skill always applies.
	if not card.status_id.is_empty() and is_valid_target(target_index) and (card.damage <= 0 or hit_mult > 0.0):
		apply_status(enemies[target_index], card.status_id, card.status_value)
	card_played.emit(card)
	if first_living_enemy() < 0:
		_win()
		return true
	state_changed.emit()
	return true


## Ends the player's turn: discards hand, each living enemy (left to right) executes the
## intent it displayed, then (if the player survives) next intents are rolled and a new
## player turn begins.
func end_turn() -> bool:
	if state != State.PLAYER_TURN:
		return false
	discard_pile.append_array(hand)
	hand.clear()
	_fire_items(ItemData.TRIGGER_TURN_END)
	turn_damage_bonus = 0
	var aftermath_before: int = player.aftermath_turns
	_tick_statuses(player)  # the player's statuses tick at the end of its turn, before the enemies act
	if not player.is_alive():
		_lose()
		return true
	for e: Combatant in enemies:
		if not e.is_alive():
			continue
		if e.intent != null:
			var skip_id: String = _consume_skip_turn(e)
			if skip_id.is_empty():
				skip_id = _roll_fail(e)
			if skip_id.is_empty():
				_execute_intent(e)
			else:
				e.reset_block()
				turn_skipped.emit(e, skip_id)
		if not player.is_alive():
			break
		_tick_statuses(e)  # enemy statuses tick right after the enemy's own turn
	if not player.is_alive():
		_lose()
		return true
	if first_living_enemy() < 0:
		_win()
		return true
	# Aftermath immunity counts the player's turns: -1 once the enemies have acted, unless it only began during this
	# enemy phase (woken by a hit): then the coming turn is its first one.
	if aftermath_before > 0 and player.aftermath_turns > 0:
		player.aftermath_turns -= 1
		player.changed.emit()
	for e: Combatant in enemies:
		_roll_intent(e)
	_start_player_turn()
	return true


## True if the potion at index can be drunk now (player's turn, valid index). Potions cost no energy.
func can_use_potion(index: int) -> bool:
	return state == State.PLAYER_TURN and index >= 0 and index < potions.size()


## Drinks potions[index]: applies its effects, removes it and emits potion_used. False (no change) if invalid.
func use_potion(index: int) -> bool:
	if not can_use_potion(index):
		return false
	var potion: PotionData = potions[index]
	potions.remove_at(index)
	for e: Dictionary in potion.effects:
		match String(e["type"]):
			"cure_status":
				cure_status(player, String(e["status"]))
			"energy_gain":
				energy += int(e["value"])
			"draw_cards":
				_draw_cards(int(e["value"]))
			"damage_bonus_turn":
				turn_damage_bonus += int(e["value"])
			_:
				ItemEffects.apply_to_combatant(e, player)
	potion_used.emit(potion)
	state_changed.emit()
	return true


## Recomputes the final value of every living enemy's already-chosen attack against the CURRENT
## active Pokémon's types. The chosen action itself never changes.
## Also refreshes the burn penalty and the "loses its turn" label of every intent (statuses changed).
func refresh_intents() -> void:
	for e: Combatant in enemies:
		if e.is_alive() and e.intent != null:
			if e.intent.type == EnemyIntent.TYPE_ATTACK:
				e.intent.value = _type_chart.final_damage(maxi(0, e.intent.base_value - _attack_penalty(e)),
						e.get_primary_type(), player.type_ids)
			e.intent.skip_label = _skip_label(e)


func _apply_identity(pokemon_id: String) -> void:
	player.active_pokemon_id = pokemon_id
	if not _pokemon_lookup.is_valid():
		return
	var info: Dictionary = _pokemon_lookup.call(pokemon_id)
	if info.is_empty():
		return
	var types: Array[String] = []
	for t: Variant in (info.get("types", []) as Array):
		types.append(String(t))
	player.set_active_pokemon(pokemon_id, String(info.get("name", "")), String(info.get("sprite_path", "")), types)


func _execute_intent(enemy: Combatant) -> void:
	var intent: EnemyIntent = enemy.intent
	enemy.reset_block()  # block from the previous round expires when the enemy acts
	var hit: bool = false
	match intent.type:
		EnemyIntent.TYPE_ATTACK:
			# intent.value is already the FINAL damage vs the player (strength + type applied).
			player.take_damage(intent.value)
			hit = true
			if intent.value > 0:
				_on_damaged(player, enemy.get_primary_type())
		EnemyIntent.TYPE_BLOCK:
			enemy.add_block(intent.value)
		EnemyIntent.TYPE_BUFF:
			enemy.strength += intent.value
	if hit:
		var mult: float = _type_chart.damage_multiplier(enemy.get_primary_type(), player.type_ids)
		hit_resolved.emit(player, intent.value, mult)
		# Status of the attack: applied unless the hit is fully immune (type multiplier 0), even if block absorbed it.
		if not intent.status_id.is_empty() and mult > 0.0 and player.is_alive():
			apply_status(player, intent.status_id, intent.status_value)
	enemy_acted.emit(enemy, intent)


## Chooses the enemy's next action from its data (sequence or weighted). Attack values
## include the enemy's strength and the type multiplier vs the player, so the displayed intent is exactly what runs.
func _roll_intent(enemy: Combatant) -> void:
	if not enemy.is_alive() or enemy.actions.is_empty():
		enemy.intent = null
		return
	var chosen: EnemyIntent
	if enemy.pattern == Combatant.PATTERN_WEIGHTED:
		var total: float = 0.0
		for a: EnemyIntent in enemy.actions:
			total += a.weight
		var roll: float = _rng.randf() * total
		chosen = enemy.actions[enemy.actions.size() - 1]
		for a: EnemyIntent in enemy.actions:
			if roll < a.weight:
				chosen = a
				break
			roll -= a.weight
	else:
		chosen = enemy.actions[enemy.sequence_index % enemy.actions.size()]
		enemy.sequence_index = (enemy.sequence_index + 1) % enemy.actions.size()
	var bonus: int = enemy.strength if chosen.type == EnemyIntent.TYPE_ATTACK else 0
	var rolled: EnemyIntent = chosen.with_bonus(bonus)
	rolled.base_value = rolled.value
	if rolled.type == EnemyIntent.TYPE_ATTACK:
		# Strength is added BEFORE the type multiplier (burn subtracts its penalty there too); the displayed value is the final one.
		rolled.value = _type_chart.final_damage(maxi(0, rolled.value - _attack_penalty(enemy)), enemy.get_primary_type(), player.type_ids)
		rolled.status_label = _status_book.name_of(rolled.status_id)
	rolled.skip_label = _skip_label(enemy)
	enemy.intent = rolled


## Fires every held item bound to `trigger` on the player (heal / block effects); emits item_triggered if it did something.
func _fire_items(trigger: String) -> void:
	for item: ItemData in items:
		if item.trigger != trigger:
			continue
		var did: bool = false
		for e: Dictionary in item.effects:
			if ItemEffects.apply_to_combatant(e, player) > 0:
				did = true
		if did:
			item_triggered.emit(item)


## `first` = the battle's first turn: block gained from battle_start items must survive.
func _start_player_turn(first: bool = false) -> void:
	if not first:
		player.reset_block()
	energy = max_energy
	energy_lost = 0
	turn_damage_bonus = 0
	# Asleep / frozen team: it loses player_energy_loss energy (whole turn if absent), still draws and plays with the rest.
	var lost_turn: String = _consume_skip_turn(player)
	if not lost_turn.is_empty():
		var before: int = energy
		energy = maxi(0, energy - _status_book.get_def(lost_turn).energy_loss_for(max_energy))
		energy_lost = before - energy
		turn_skipped.emit(player, lost_turn)
	_fire_items(ItemData.TRIGGER_TURN_START)
	_draw_cards(hand_size)
	turn_started.emit()
	state_changed.emit()


func _draw_cards(count: int) -> void:
	for i: int in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle(draw_pile)
		hand.append(draw_pile.pop_back())


func _shuffle(cards: Array[CardData]) -> void:
	# Fisher-Yates with the injected RNG.
	for i: int in range(cards.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: CardData = cards[i]
		cards[i] = cards[j]
		cards[j] = tmp


# --- Status ailments (story 016) -----------------------------------------------------------------------
# Turn flow: the player's statuses tick at the end of its turn (before the enemies act); each enemy first
# consumes a lost turn (sleep/freeze) or rolls its paralysis, acts if not skipped, THEN ticks its own statuses.
# A combatant killed by a tick is dead (enemy: intent dropped, battle_won once none is left; player: battle_lost).
# Statuses live on the Combatant (statuses dict) and are cleared silently when the battle ends.

## Applies `value` of status `status_id` to `target` (a living combatant of this battle). Returns false when refused:
## unknown status / dead target, or immune (status_blocked emitted). Immunity: any of the target's types in the
## status's immune_types (the player uses the ACTIVE Pokémon's types), a held "status_immunity" item, or the player's
## aftermath immunity. Re-applying stacks the value (stackable statuses) and refreshes the duration; a status with
## refresh_on_reapply false is left untouched while active (returns false, status_unchanged emitted).
func apply_status(target: Combatant, status_id: String, value: int) -> bool:
	var def: StatusData = _status_book.get_def(status_id)
	if def == null:
		push_error("Battle: unknown status '%s'" % status_id)
		return false
	if target == null or not target.is_alive() or value <= 0:
		return false
	if is_immune(target, status_id):
		status_blocked.emit(target, status_id)
		return false
	if target.statuses.has(status_id) and not def.refresh_on_reapply:
		status_unchanged.emit(target, status_id)
		return false
	if target.statuses.has(status_id):
		var entry: Dictionary = target.statuses[status_id]
		if def.stackable:
			entry["value"] = int(entry["value"]) + value
		entry["turns"] = def.initial_turns()
	else:
		target.statuses[status_id] = {"value": value if def.stackable else 1, "turns": def.initial_turns()}
	target.changed.emit()
	status_applied.emit(target, status_id, value)
	refresh_intents()
	return true


## True if `target` cannot receive the status now (type immunity; for the player also held item immunity and aftermath immunity).
func is_immune(target: Combatant, status_id: String) -> bool:
	var def: StatusData = _status_book.get_def(status_id)
	if def == null:
		return false
	for t: String in target.type_ids:
		if t in def.immune_types:
			return true
	if target == player and player.aftermath_turns > 0 and status_id in _status_book.aftermath_statuses:
		return true
	return target == player and status_id in ItemEffects.status_immunities(items)


## Removes `status_id` ("all" = every status) from `target`; returns how many were removed (status_removed per status).
func cure_status(target: Combatant, status_id: String) -> int:
	var removed: int = 0
	for sid: String in target.status_ids():
		if status_id == "all" or sid == status_id:
			_remove_status(target, sid)
			removed += 1
	if removed > 0:
		refresh_intents()
	return removed


## Every end of an aftermath status on the player (expired, woken, thawed, cured) starts the aftermath immunity.
func _remove_status(target: Combatant, status_id: String) -> void:
	target.statuses.erase(status_id)
	if target == player and state == State.PLAYER_TURN and status_id in _status_book.aftermath_statuses:
		player.aftermath_turns = _status_book.aftermath_turns
	target.changed.emit()
	status_removed.emit(target, status_id)


func _attack_penalty(c: Combatant) -> int:
	var sum: int = 0
	for sid: String in c.statuses.keys():
		var def: StatusData = _status_book.get_def(sid)
		if def != null:
			sum += def.attack_penalty
	return sum


## Label ("Dort") of the first status that will make this enemy lose its next turn, "" if none.
func _skip_label(c: Combatant) -> String:
	for sid: String in c.statuses.keys():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and def.skip_turns > 0:
			return def.skip_label
	return ""


## A damaging hit landed on `target` (amount >= 1 before block): wake_on_damage statuses and statuses thawed by `attack_type` go.
func _on_damaged(target: Combatant, attack_type: String) -> void:
	var changed_any: bool = false
	for sid: String in target.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and (def.wake_on_damage or (not attack_type.is_empty() and attack_type in def.thaw_types)):
			_remove_status(target, sid)
			changed_any = true
	if changed_any:
		refresh_intents()


## Consumes one lost turn of the first skip_turns status (removed when no turns are left). Returns its id or "".
func _consume_skip_turn(c: Combatant) -> String:
	for sid: String in c.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def == null or def.skip_turns <= 0:
			continue
		var entry: Dictionary = c.statuses[sid]
		entry["turns"] = int(entry["turns"]) - 1
		if int(entry["turns"]) <= 0:
			_remove_status(c, sid)
			refresh_intents()
		else:
			c.changed.emit()
		return sid
	return ""


## Rolls the skip_chance of every status of `c` with the injected RNG; returns the id that made the action fail, or "".
## The RNG is only consumed when such a status is present, so battles without paralysis keep their sequences.
func _roll_fail(c: Combatant) -> String:
	for sid: String in c.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and def.skip_chance > 0.0 and _rng.randf() < def.skip_chance:
			return sid
	return ""


func _roll_card_fizzle() -> String:
	return _roll_fail(player)


## End-of-turn tick of `c`: damage statuses deal their value (ignoring block), values decay, durations shrink.
func _tick_statuses(c: Combatant) -> void:
	for sid: String in c.status_ids():
		if not c.is_alive():
			break
		var def: StatusData = _status_book.get_def(sid)
		if def == null or not c.statuses.has(sid):
			continue
		var entry: Dictionary = c.statuses[sid]
		if def.tick_damage:
			var amount: int = int(entry["value"])
			c.lose_hp(amount)
			status_ticked.emit(c, sid, amount)
			if not c.is_alive():
				if c != player:
					c.intent = null
				break
			if def.value_decay > 0:
				entry["value"] = int(entry["value"]) - def.value_decay
				if int(entry["value"]) <= 0:
					_remove_status(c, sid)
					continue
		if def.duration > 0:
			entry["turns"] = int(entry["turns"]) - 1
			if int(entry["turns"]) <= 0:
				_remove_status(c, sid)
				continue
		c.changed.emit()
	if c != player:
		refresh_intents()


func _win() -> void:
	_fire_items(ItemData.TRIGGER_BATTLE_END)  # before the win is announced, so the HP is persisted by the caller
	state = State.WON
	player.clear_statuses()
	state_changed.emit()
	battle_won.emit()


func _lose() -> void:
	state = State.LOST
	player.clear_statuses()
	state_changed.emit()
	battle_lost.emit()
