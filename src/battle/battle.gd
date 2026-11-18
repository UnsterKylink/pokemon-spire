class_name Battle
extends RefCounted
## Pure combat logic (no nodes/scenes): 1 player Pokémon vs 1..3 enemies with data-driven intents.
## Implements: design/game-brief.md MVP features 1-2, story-001-combat-de-base,
## story-002-intentions-et-multi-ennemis, story-003-types, story-016-statuts (incl. the anti-lock rules),
## story-019-equilibrage (an enemy attack uses its action's data type, see _attack_type_of),
## story-027-profondeur-du-combat (card effect grammar EffectSpec, talents, Élan, Faiblesse / Vulnérable, exhaust / retain),
## story-030-ennemis-et-boss (new enemy actions, field rules FieldRules, boss phases Combatant.phases).

enum State { PLAYER_TURN, WON, LOST }

const MIN_ENEMIES: int = 1
const MAX_ENEMIES: int = 3
## Story 027: HP a self-damaging card always leaves to the player (a card never K.O.s its own team).
const SELF_DAMAGE_HP_FLOOR: int = 1

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
## Story 017 (capture). A ball was thrown at `target` (energy and the ball are already spent) with this success `chance` (0..1).
signal ball_thrown(target: Combatant, ball: BallData, chance: float)
## The throw succeeded: `target` was already removed from `enemies` (see captured / captured_ids); a possible win follows.
signal capture_succeeded(target: Combatant)
## The throw failed: the enemy stays and keeps acting normally (a captured Pokémon never flees).
signal capture_failed(target: Combatant)

## Story 027. Élan changed (gained by an attack of the already-active Pokémon, reset to 0 by a switch).
signal elan_changed(value: int)
## The talent `talent_id` of `pokemon_id` fired because it entered the field (effects already applied).
signal talent_triggered(pokemon_id: String, talent_id: String)
## The player's Force changed: `battle_value` lasts the whole battle, `turn_value` until the end of the turn.
signal strength_changed(battle_value: int, turn_value: int)
## A played card went to the exhaust pile (already appended to `exhaust_pile`).
signal card_exhausted(card: CardData)
## Cards were drawn outside the normal start-of-turn draw (card / talent / potion effect); `count` really drawn.
signal cards_drawn(count: int)

## Story 030. An effect of the field rule fired (battle start / turn start / a burned card...). `rule_id` = the rule's id.
signal field_rule_triggered(rule_id: String)
## A boss reached a new phase (enemy.phase_index == phase_index, its actions changed); `message` is the French announcement.
signal enemy_phase_changed(enemy: Combatant, phase_index: int, message: String)
## The player will start its next turn with `amount` less energy (drain_energy action; floor already applied at turn start).
signal energy_drained(enemy: Combatant, amount: int)
## `count` junk cards were shuffled into the draw pile (add_junk action: `enemy`; field rule: null).
signal junk_added(enemy: Combatant, count: int)
## `amount` block was removed from the player by a strip_block action.
signal block_stripped(enemy: Combatant, amount: int)
## A heal / heal_ally / enemy_heal_per_turn restored `amount` HP to `target` (an enemy).
signal enemy_healed(target: Combatant, amount: int)
## A card of the hand burned (field rule burn_costliest_card): it is already in exhaust_pile.
signal card_burned(card: CardData)

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
## Story 027: cards with `exhaust` played this battle (out of the deck until the battle ends).
var exhaust_pile: Array[CardData] = []
## Story 027: Élan of the active Pokémon (see get_elan) and the flat bonus waiting for the next attack card.
var elan: int = 0
var next_attack_bonus: int = 0
var _cards_played_this_turn: int = 0
var _talents_fired: Dictionary = {}  # pokemon id -> true (this battle, or this turn with trigger once_per_turn)
var _talent_book: TalentBook = null
## Held items active in this battle (story 006); their triggers are fired by this class.
var items: Array[ItemData] = []
## Potions carried into the battle, usable with use_potion (removed once used).
var potions: Array[PotionData] = []
## Extra damage on every attack card until the end of this turn (potion "Attaque +").
var turn_damage_bonus: int = 0
## Energy the player lost at the start of the CURRENT turn because of a status (sleep / freeze); 0 on a normal turn.
var energy_lost: int = 0
var _attacks_played: int = 0
## Story 029 (items): card types whose first card of this turn was already free / once-per-battle item powers used / enemies seen dead.
var _free_type_used: Dictionary = {}
var _recycle_used: bool = false
var _retrigger_used: bool = false
var _dead_seen: Dictionary = {}
## Divisor of the `percent` fields of items (percent / PERCENT = fraction).
const PERCENT: float = 100.0
## Story 017: true when balls may be used in this fight (Main sets it for wild fights only, via RunState.create_battle).
var capture_allowed: bool = false
## Balls carried: ball id -> count left (copy; decremented by use_ball). Order = insertion order = index for can_use_ball.
var ball_counts: Dictionary = {}
## Enemies captured so far (removed from `enemies`), in capture order; captured_ids = their Pokémon ids.
var captured: Array[Combatant] = []
var captured_ids: Array[String] = []
var _capture_rules: CaptureRules = null
var _ball_book: Dictionary = {}  # ball id -> BallData

## Story 030: the active field rule ({} = none; see set_field_rule / get_field_rule), the player turn number (1 = first),
## the energy the player will lose at the start of its next turn (drain_energy), the junk card added by add_junk.
var field_rule: Dictionary = {}
var turn_number: int = 0
var pending_energy_drain: int = 0
var junk_card: CardData = null
## Lowest energy a drain_energy action can leave the player at (field_rules.json enemy_mechanics.min_energy_after_drain).
var min_energy_after_drain: int = DEFAULT_MIN_ENERGY_AFTER_DRAIN
const DEFAULT_MIN_ENERGY_AFTER_DRAIN: int = 1
## HP a field rule's hp loss always leaves to the player, and the fewest cards a draw_down rule leaves.
const FIELD_HP_FLOOR: int = 1
const MIN_DRAW: int = 1
var _in_enemy_phase: bool = false

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
## Story 017: capture_rules / ball_book (id -> BallData) / carried_balls (id -> count, copied) / can_capture enable use_ball.
func _init(player_combatant: Combatant, enemy_list: Array[Combatant], deck: Array[CardData],
		energy_per_turn: int, cards_per_turn: int, rng: RandomNumberGenerator,
		type_chart: TypeChart = null, pokemon_lookup: Callable = Callable(), starter_pokemon_id: String = "",
			held_items: Array[ItemData] = [], carried_potions: Array[PotionData] = [],
			status_book: StatusBook = null, capture_rules: CaptureRules = null, ball_book: Dictionary = {},
			carried_balls: Dictionary = {}, can_capture: bool = false, talent_book: TalentBook = null) -> void:
	_talent_book = talent_book
	_capture_rules = capture_rules
	_ball_book = ball_book
	capture_allowed = can_capture
	for bid: String in carried_balls.keys():
		if int(carried_balls[bid]) > 0 and ball_book.has(bid):
			ball_counts[bid] = int(carried_balls[bid])
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
	_apply_rule_battle_start()
	_apply_rule_before_intents(1)
	for e: Combatant in enemies:
		_roll_intent(e)
	_fire_items(ItemData.TRIGGER_BATTLE_START)
	_start_player_turn(true)


# --- Story 030: enemy mechanics, field rules, boss phases ------------------------------------------------

## Junk card added by add_junk / junk_each_turn (null: those effects do nothing) and the drain floor. Call before start().
func configure_enemy_mechanics(junk: CardData, min_energy_drain_floor: int) -> void:
	junk_card = junk
	min_energy_after_drain = maxi(0, min_energy_drain_floor)


## Sets the field rule {id, name, description, effects} (see FieldRules); {} = none. Invalid effects are reported and
## ignored (the battle never crashes). Call before start(); a boss phase may replace it later.
func set_field_rule(rule: Dictionary) -> void:
	field_rule = {}
	if rule.is_empty():
		return
	var effects: Array = []
	for fx: Variant in (rule.get("effects", []) as Array):
		var err: String = FieldRules.check_effect(fx)
		if err.is_empty():
			effects.append(fx)
		else:
			push_error("Battle: field rule '%s': %s (ignored)" % [String(rule.get("id", "")), err])
	field_rule = rule.duplicate()
	field_rule["effects"] = effects


## The active field rule for the UI: {id, name, description} ({} if none).
func get_field_rule() -> Dictionary:
	return FieldRules.summary(field_rule)


## Effects of the active rule of that type (empty if none).
func _rule_effects(effect_type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for fx: Variant in (field_rule.get("effects", []) as Array):
		if String((fx as Dictionary).get("type", "")) == effect_type:
			out.append(fx)
	return out


## Sum of `value` of the rule's effects of that type that fire on player turn `turn` (`every`).
func _rule_total(effect_type: String, turn: int = 0) -> int:
	var total: int = 0
	for fx: Dictionary in _rule_effects(effect_type):
		if turn <= 0 or turn % int(fx.get("every", 1)) == 0:
			total += int(fx.get("value", 0))
	return total


func _rule_fired() -> void:
	field_rule_triggered.emit(String(field_rule.get("id", "")))


func _apply_rule_battle_start() -> void:
	var fired: bool = false
	var start_block: int = _rule_total(FieldRules.ENEMY_START_BLOCK)
	if start_block > 0:
		for e: Combatant in enemies:
			e.add_block(start_block)
		fired = true
	for fx: Dictionary in _rule_effects(FieldRules.PLAYER_STATUS_START):
		apply_status(player, String(fx["status"]), int(fx["value"]))
		fired = true
	if fired:
		_rule_fired()


## Enemy strength of the rule for the turn about to start (before its intents are rolled, so they include it).
func _apply_rule_before_intents(turn: int) -> void:
	var gain: int = _rule_total(FieldRules.ENEMY_STRENGTH_PER_TURN, turn)
	if gain <= 0:
		return
	for e: Combatant in enemies:
		if e.is_alive():
			e.strength += gain
			e.changed.emit()
	_rule_fired()


## Start-of-turn rule effects BEFORE the draw (the HP loss never K.O.s: FIELD_HP_FLOOR).
func _apply_rule_turn_start(turn: int) -> void:
	var fired: bool = false
	var loss: int = _rule_total(FieldRules.PLAYER_HP_LOSS_PER_TURN, turn)
	if loss > 0:
		player.lose_hp(mini(loss, player.hp - FIELD_HP_FLOOR))
		fired = true
	for fx: Dictionary in _rule_effects(FieldRules.PLAYER_STATUS_EACH_TURN):
		if turn % int(fx.get("every", 1)) == 0:
			apply_status(player, String(fx["status"]), int(fx["value"]))
			fired = true
	var blk: int = _rule_total(FieldRules.ENEMY_BLOCK_PER_TURN, turn)
	var heal_v: int = _rule_total(FieldRules.ENEMY_HEAL_PER_TURN, turn)
	for e: Combatant in enemies:
		if not e.is_alive():
			continue
		if blk > 0:
			e.add_block(blk)
			fired = true
		if heal_v > 0:
			var got: int = e.heal(heal_v)
			fired = true
			if got > 0:
				enemy_healed.emit(e, got)
	var junk: int = _rule_total(FieldRules.JUNK_EACH_TURN, turn)
	if junk > 0 and _add_junk(junk) > 0:
		junk_added.emit(null, junk)
		fired = true
	if fired:
		_rule_fired()


## After the draw: burn_costliest_card.
func _apply_rule_after_draw(turn: int) -> void:
	for fx: Dictionary in _rule_effects(FieldRules.BURN_COSTLIEST_CARD):
		if turn % int(fx.get("every", 1)) != 0:
			continue
		var best: int = -1
		for i: int in hand.size():
			if not hand[i].is_junk() and (best < 0 or hand[i].cost > hand[best].cost):
				best = i
		if best >= 0:
			var card: CardData = hand[best]
			hand.remove_at(best)
			exhaust_pile.append(card)
			card_burned.emit(card)
			_rule_fired()


## Shuffles `count` copies of the junk card into the draw pile at RNG positions. Returns how many were added.
func _add_junk(count: int) -> int:
	if junk_card == null or count <= 0:
		return 0
	for i: int in count:
		draw_pile.insert(_rng.randi_range(0, draw_pile.size()), junk_card.duplicate_card())
	return count


## The living enemy with the lowest HP ratio (leftmost on ties); null if none.
func _weakest_enemy() -> Combatant:
	var best: Combatant = null
	for e: Combatant in enemies:
		if e.is_alive() and (best == null or float(e.hp) / float(e.max_hp) < float(best.hp) / float(best.max_hp)):
			best = e
	return best


## Switches every living boss whose HP ratio reached a phase threshold to that phase (several at once if crossed).
func _check_phases() -> void:
	for e: Combatant in enemies:
		while e.is_alive() and e.phase_index < e.phases.size() \
				and float(e.hp) <= float(e.max_hp) * float(e.phases[e.phase_index]["hp_below"]):
			var ph: Dictionary = e.phases[e.phase_index]
			e.phase_index += 1
			e.actions.assign(ph["actions"])
			e.pattern = String(ph["pattern"])
			e.sequence_index = 0
			e.pending_charge = null
			if bool(ph["clear_statuses"]):
				cure_status(e, "all")
			var heal_amount: int = floori(float(e.max_hp) * float(ph["heal_percent"]) / PERCENT)
			if heal_amount > 0:
				var got: int = e.heal(heal_amount)
				if got > 0:
					enemy_healed.emit(e, got)
			var rule: Dictionary = ph.get("field_rule_def", {})
			if not rule.is_empty():
				set_field_rule(rule)
			if not _in_enemy_phase and state == State.PLAYER_TURN:
				_roll_intent(e)  # the new form shows its first action right away
			enemy_phase_changed.emit(e, e.phase_index, String(ph["message"]))
			if not rule.is_empty():
				_rule_fired()


## True if the card at hand index can be played now (state, index, energy).
func can_play(index: int) -> bool:
	if state != State.PLAYER_TURN or index < 0 or index >= hand.size() or hand[index].is_junk():
		return false  # story 030: junk cards are never playable
	return card_cost(hand[index]) <= energy


## Energy `card` costs NOW: 0 for the first card of a type this turn when a held item says so (first_type_card_free).
## Story 030: + the field rule's first_card_cost_up on the first card of the turn.
func card_cost(card: CardData) -> int:
	var up: int = _rule_total(FieldRules.FIRST_CARD_COST_UP) if _cards_played_this_turn == 0 else 0
	if card.cost > 0 and not _free_type_used.has(card.type_id) and ItemEffects.free_card_item(items, card.type_id) != null:
		return up
	return card.cost + up


## Pays `card` (energy) and consumes the free-card power of its type when it was used.
func _pay_card(card: CardData) -> void:
	var cost: int = card_cost(card)
	if cost < card.cost:
		_free_type_used[card.type_id] = true
		item_triggered.emit(ItemEffects.free_card_item(items, card.type_id))
	energy -= cost


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
## Story 027 order: switch (Élan reset, talent) -> hits (each one separately) -> block / heal / effect / conditionals ->
## Élan gain -> status of the card -> card_played.
func play_card(index: int, target_index: int = -1) -> bool:
	if not can_play(index):
		return false
	var card: CardData = hand[index]
	if card.needs_target() and not is_valid_target(target_index):
		return false
	# Paralysed player: each played card may fizzle (energy spent, no effect). The RNG is only drawn when paralysed.
	var fizzle_id: String = _roll_card_fizzle()
	if not fizzle_id.is_empty():
		_pay_card(card)
		hand.remove_at(index)
		discard_pile.append(card)
		_cards_played_this_turn += 1
		status_blocked.emit(player, fizzle_id)
		card_played.emit(card)
		state_changed.emit()
		return true
	var ctx: Dictionary = _card_context(card)
	# Only attack cards bring their Pokémon in, BEFORE the hit (types/intents use the new Pokémon).
	if bool(ctx["entered"]):
		var old_id: String = active_pokemon_id
		active_pokemon_id = card.pokemon_id
		_apply_identity(card.pokemon_id)
		_set_elan(_elan_after_switch())  # switching loses the Élan (items may keep a share of it)...
		_trigger_talent(card.pokemon_id)  # ...and the newcomer's talent fires
		refresh_intents()
		active_pokemon_changed.emit(old_id, active_pokemon_id)
	_pay_card(card)
	hand.remove_at(index)
	var recycled: bool = false
	if card.exhaust:
		var recycler: ItemData = null if _recycle_used else ItemEffects.first_with(items, "exhaust_recycle")
		if recycler != null:  # story 029: the first exhausted card of the battle goes back to the discard pile
			_recycle_used = true
			recycled = true
			discard_pile.append(card)
			item_triggered.emit(recycler)
		else:
			exhaust_pile.append(card)
	else:
		discard_pile.append(card)
	# Story 018: a `target_all` card hits every living enemy (left to right), others only enemies[target_index].
	var targets: Array[int] = []
	if card.needs_target():
		if card.target_all:
			for i: int in enemies.size():
				if enemies[i].is_alive():
					targets.append(i)
		else:
			targets.append(target_index)
	# Conditions are evaluated BEFORE the damage of the card (HP, statuses and Élan as the player sees them).
	var met_any: Array[bool] = []
	for c: Dictionary in card.conditionals:
		var met: bool = targets.is_empty() and _condition_met(c["if"], card, ctx, null)
		for ti: int in targets:
			met = met or _condition_met(c["if"], card, ctx, enemies[ti])
		met_any.append(met)
	var deals: bool = card.deals_damage()
	var base_damage: int = card.damage + floori(float(player.block) * card.damage_from_block)
	var per_target: Array[Dictionary] = []  # {index, mult}
	var hits: Array[Dictionary] = []  # one per HIT: {target, amount, mult}
	for ti: int in targets:
		var hit_target: Combatant = enemies[ti]
		var mult: float = 1.0
		if deals:
			# Bonuses (items, Force, Élan) are added BEFORE the type multiplier, like enemy strength.
			var bonus: int = _flat_bonus(card, int(ctx["elan"]), true)
			var count: int = card.hits
			for c: Dictionary in card.conditionals:
				if _condition_met(c["if"], card, ctx, hit_target):
					bonus += int((c["then"] as Dictionary).get("damage", 0))
					count += int((c["then"] as Dictionary).get("hits", 0))
			mult = _type_chart.damage_multiplier(card.type_id, hit_target.type_ids)
			for h: int in count:
				if not hit_target.is_alive():
					break
				# Each hit is its own damage event: Faiblesse / Vulnérable, type, then block.
				var amount: int = _scaled_damage(base_damage + bonus, player, hit_target, card.type_id)
				hit_target.take_damage(amount)  # block absorbs AFTER the type multiplier
				if amount > 0:
					_on_damaged(hit_target, card.type_id)
				hits.append({"target": hit_target, "amount": amount, "mult": mult})
			if not hit_target.is_alive():
				hit_target.intent = null  # a K.O. enemy no longer acts
		per_target.append({"index": ti, "mult": mult})
	if card.block > 0:
		player.add_block(card.block)
	if card.heal > 0:
		player.heal(card.heal)
	_apply_effect(card.effect, target_index)
	for ci: int in card.conditionals.size():
		if met_any[ci]:
			_apply_effect(card.conditionals[ci]["then"], target_index)
	for hit: Dictionary in hits:
		hit_resolved.emit(hit["target"], int(hit["amount"]), float(hit["mult"]))
	if card.kind == CardData.KIND_ATTACK:
		_attacks_played += 1
		if deals and next_attack_bonus != 0:
			next_attack_bonus = 0
		if bool(ctx["was_active"]) and _talent_book != null:
			_set_elan(mini(get_elan_cap(), elan + _talent_book.elan_gain_per_attack))
	_cards_played_this_turn += 1
	# Status of the card: applied AFTER the damage (a sleeping target is not woken by its own card). A hit that deals
	# no damage because of a 0x type multiplier inflicts nothing; a status skill always applies.
	if not card.status_id.is_empty():
		for rec: Dictionary in per_target:
			if is_valid_target(int(rec["index"])) and (not deals or float(rec["mult"]) > 0.0):
				apply_status(enemies[int(rec["index"])], card.status_id, card.status_value)
	if card.exhaust and not recycled:
		card_exhausted.emit(card)
		_fire_items(ItemData.TRIGGER_ON_EXHAUST)
	_check_kills()
	_check_phases()
	card_played.emit(card)
	if first_living_enemy() < 0:
		_win()
		return true
	state_changed.emit()
	return true


# --- Story 027: Élan, talents, effect grammar --------------------------------------------------------

## Current Élan of the active Pokémon (0 without talent book).
func get_elan() -> int:
	return elan


## Highest Élan reachable (talents.json elan.cap; 0 = Élan disabled).
func get_elan_cap() -> int:
	if _talent_book == null or _talent_book.elan_cap <= 0:
		return 0
	return _talent_book.elan_cap + ItemEffects.passive_total(items, "elan_cap_up")


## Flat damage every hit of an attack card gains from the current Élan.
func get_elan_damage_bonus() -> int:
	return elan * _talent_book.elan_damage_per_stack if _talent_book != null else 0


## The player's Force for the whole battle (flat damage per hit).
func get_strength() -> int:
	return player.strength


## The player's Force that lasts until the end of this turn (flat damage per hit; also the "Attaque +" potion).
func get_turn_strength() -> int:
	return turn_damage_bonus


## Flat damage waiting for the next attack card (talents such as Brasier).
func get_next_attack_bonus() -> int:
	return next_attack_bonus


## Talent id of a Pokémon in this battle ("" if none / no talent book).
func get_talent_id(pokemon_id: String) -> String:
	if _talent_book == null:
		return ""
	var explicit: String = ""
	var types: Array[String] = []
	if _pokemon_lookup.is_valid():
		var info: Dictionary = _pokemon_lookup.call(pokemon_id)
		explicit = String(info.get("talent", ""))
		for t: Variant in (info.get("types", []) as Array):
			types.append(String(t))
	if types.is_empty() and pokemon_id == active_pokemon_id:
		types = player.type_ids
	return _talent_book.talent_for(pokemon_id, explicit, types)


## True if playing `card` now would make its Pokémon's talent fire (it would enter and its talent is not used up).
func would_trigger_talent(card: CardData) -> bool:
	if not bool(_card_context(card)["entered"]):
		return false
	return not get_talent_id(card.pokemon_id).is_empty() and (not is_talent_used(card.pokemon_id) or _retrigger_item() != null)


## True if the talent of `pokemon_id` already fired and may not fire again (talents.json talent_trigger:
## once_per_battle = for the rest of the fight, once_per_turn = this player turn, every_entry = never used up).
func is_talent_used(pokemon_id: String) -> bool:
	if _talent_book == null or _talent_book.trigger == TalentBook.TRIGGER_EVERY_ENTRY:
		return false
	return _talents_fired.has(pokemon_id)


## Élan kept when the active Pokémon changes: elan_keep_percent items keep that share (rounded down), else 0.
func _elan_after_switch() -> int:
	return floori(float(elan) * ItemEffects.passive_percent(items, "elan_keep_percent") / PERCENT)


## Pure preview (no RNG, no signal) of hand[index] against enemies[target_index] if played NOW:
## {"amount": final damage of ONE hit before block, "hits": number of hits, "multiplier": type factor}.
## Includes Force, Élan (lost if the card switches), items, conditionals, Faiblesse / Vulnérable and the attack bonus
## of the talent the switch would fire. {amount 0, hits 0, multiplier 1.0} if invalid or the card deals no damage.
func preview_card_damage(index: int, target_index: int) -> Dictionary:
	if index < 0 or index >= hand.size() or not is_valid_target(target_index) or not hand[index].deals_damage():
		return {"amount": 0, "hits": 0, "multiplier": 1.0}
	var card: CardData = hand[index]
	var target: Combatant = enemies[target_index]
	var ctx: Dictionary = _card_context(card)
	var bonus: int = _flat_bonus(card, int(ctx["elan"]), false)
	if would_trigger_talent(card):
		var fx: Dictionary = _talent_book.effect_of(get_talent_id(card.pokemon_id))
		bonus += int(fx.get("next_attack_bonus", 0)) + int(fx.get("strength_turn", 0)) + int(fx.get("strength", 0))
	var count: int = card.hits
	for c: Dictionary in card.conditionals:
		if _condition_met(c["if"], card, ctx, target):
			bonus += int((c["then"] as Dictionary).get("damage", 0))
			count += int((c["then"] as Dictionary).get("hits", 0))
	var base: int = card.damage + floori(float(player.block) * card.damage_from_block)
	return {"amount": _scaled_damage(base + bonus, player, target, card.type_id), "hits": count,
			"multiplier": _type_chart.damage_multiplier(card.type_id, target.type_ids)}


## What playing `card` now means for its carrier: {was_active, entered, first (first card of the turn), elan (the Élan
## the card is played with: 0 if it switches)}.
func _card_context(card: CardData) -> Dictionary:
	var is_attack: bool = card.kind == CardData.KIND_ATTACK
	var entered: bool = is_attack and not card.pokemon_id.is_empty() and card.pokemon_id != active_pokemon_id
	return {"was_active": is_attack and not entered, "entered": entered, "first": _cards_played_this_turn == 0,
			"elan": 0 if entered else elan}


func _condition_met(cond: Dictionary, card: CardData, ctx: Dictionary, target: Combatant) -> bool:
	match String(cond["type"]):
		EffectSpec.COND_WAS_ACTIVE:
			return bool(ctx["was_active"])
		EffectSpec.COND_ENTERED:
			return bool(ctx["entered"])
		EffectSpec.COND_FIRST_CARD:
			return bool(ctx["first"])
		EffectSpec.COND_ELAN:
			return int(ctx["elan"]) >= int(cond["arg"])
		EffectSpec.COND_SUPER_EFFECTIVE:
			return target != null and _type_chart.damage_multiplier(card.type_id, target.type_ids) > _neutral_multiplier()
		EffectSpec.COND_TARGET_STATUS:
			if target == null:
				return false
			return not target.statuses.is_empty() if String(cond["arg"]) == EffectSpec.ANY_STATUS else target.has_status(String(cond["arg"]))
		EffectSpec.COND_TARGET_HP_BELOW:
			return target != null and float(target.hp) < float(target.max_hp) * float(cond["arg"])
	return false


## The factor of a status-free, type-neutral hit (the default of StatusData's multipliers).
func _neutral_multiplier() -> float:
	return StatusData.new().damage_dealt_multiplier


## Flat damage added to every hit of `card` before the multipliers: Force (turn + battle), next-attack bonus, Élan
## (`elan_value` stacks, attack cards), items, minus the burn penalty. `announce` emits item_triggered.
func _flat_bonus(card: CardData, elan_value: int, announce: bool) -> int:
	var bonus: int = turn_damage_bonus + player.strength - _attack_penalty(player)  # burn: weaker attacks
	bonus += _type_rule_bonus(card.type_id)  # story 030: field rule type_damage_up
	if card.kind == CardData.KIND_ATTACK:
		bonus += next_attack_bonus
		if _talent_book != null:
			bonus += elan_value * _talent_book.elan_damage_per_stack
	for item: ItemData in ItemEffects.damage_bonus_sources(items, card, _attacks_played):
		bonus += ItemEffects.damage_bonus_for(item, card)
		if announce:
			item_triggered.emit(item)
	return bonus


## Final damage (before block) of an attack worth `raw` from `attacker` on `target`: Faiblesse of the attacker and
## Vulnérable of the target scale the value (rounded down), then the type multiplier applies.
## Story 030: flat damage the field rule (type_damage_up) adds to every attack of `type_id`.
func _type_rule_bonus(type_id: String) -> int:
	var total: int = 0
	for fx: Dictionary in _rule_effects(FieldRules.TYPE_DAMAGE_UP):
		if String(fx["of_type"]) == type_id:
			total += int(fx["value"])
	return total


func _scaled_damage(raw: int, attacker: Combatant, target: Combatant, type_id: String) -> int:
	var scale: float = _status_multiplier(attacker, true) * _status_multiplier(target, false)
	return _type_chart.final_damage(floori(float(maxi(0, raw)) * scale), type_id, target.type_ids)


func _status_multiplier(c: Combatant, dealt: bool) -> float:
	var m: float = _neutral_multiplier()
	for sid: String in c.statuses.keys():
		var def: StatusData = _status_book.get_def(sid)
		if def != null:
			m *= def.damage_dealt_multiplier if dealt else def.damage_taken_multiplier
	return m


func _set_elan(value: int) -> void:
	if value == elan:
		return
	elan = value
	elan_changed.emit(elan)


## Fires the talent of `pokemon_id` (it just entered the field) unless it is used up (see is_talent_used).
func _trigger_talent(pokemon_id: String) -> void:
	var tid: String = get_talent_id(pokemon_id)
	if tid.is_empty():
		return
	if is_talent_used(pokemon_id):
		var src: ItemData = _retrigger_item()  # story 029: a used-up talent may fire once more per battle
		if src == null:
			return
		_retrigger_used = true
		item_triggered.emit(src)
	_talents_fired[pokemon_id] = true
	_apply_effect(_talent_book.effect_of(tid), -1)
	talent_triggered.emit(pokemon_id, tid)


## The held item allowing one more talent trigger this battle (null if none or already used).
func _retrigger_item() -> ItemData:
	return null if _retrigger_used else ItemEffects.first_with(items, "talent_retrigger")


## Fires on_kill items once per enemy that died (not captured).
func _check_kills() -> void:
	for e: Combatant in enemies:
		if not e.is_alive() and not _dead_seen.has(e):
			_dead_seen[e] = true
			_fire_items(ItemData.TRIGGER_ON_KILL)


## Applies an EffectSpec effect for the player. `target_index` = the card's target (-1: none; `to: target` is skipped).
func _apply_effect(fx: Dictionary, target_index: int) -> void:
	if fx.is_empty():
		return
	if fx.has("block"):
		player.add_block(int(fx["block"]))
	if fx.has("block_per_enemy"):
		var living: int = 0
		for e: Combatant in enemies:
			if e.is_alive():
				living += 1
		player.add_block(int(fx["block_per_enemy"]) * living)
	if fx.has("heal"):
		player.heal(int(fx["heal"]))
	if fx.has("self_damage"):
		player.lose_hp(mini(int(fx["self_damage"]), player.hp - SELF_DAMAGE_HP_FLOOR))
	if fx.has("strength") or fx.has("strength_turn"):
		player.strength += int(fx.get("strength", 0))
		turn_damage_bonus += int(fx.get("strength_turn", 0))
		strength_changed.emit(player.strength, turn_damage_bonus)
	if fx.has("next_attack_bonus"):
		next_attack_bonus += int(fx["next_attack_bonus"])
	if fx.has("energy"):
		energy += int(fx["energy"])
	for a: Dictionary in fx.get(EffectSpec.FIELD_APPLY, []):
		match String(a["to"]):
			EffectSpec.TO_TARGET:
				if is_valid_target(target_index):
					apply_status(enemies[target_index], String(a["status"]), int(a["value"]))
			EffectSpec.TO_ALL:
				for e: Combatant in enemies:
					if e.is_alive():
						apply_status(e, String(a["status"]), int(a["value"]))
			EffectSpec.TO_RANDOM:
				var pick: Combatant = _random_living_enemy()
				if pick != null:
					apply_status(pick, String(a["status"]), int(a["value"]))
			EffectSpec.TO_SELF:
				apply_status(player, String(a["status"]), int(a["value"]))
	if fx.has("draw"):
		cards_drawn.emit(_draw_cards(int(fx["draw"])))


## A living enemy picked with the injected RNG (the RNG is only drawn when there is a real choice); null if none.
func _random_living_enemy() -> Combatant:
	var living: Array[Combatant] = []
	for e: Combatant in enemies:
		if e.is_alive():
			living.append(e)
	if living.is_empty():
		return null
	return living[_rng.randi_range(0, living.size() - 1)] if living.size() > MIN_ENEMIES else living[0]


## Ends the player's turn: discards hand, each living enemy (left to right) executes the
## intent it displayed, then (if the player survives) next intents are rolled and a new
## player turn begins.
func end_turn() -> bool:
	if state != State.PLAYER_TURN:
		return false
	# Story 027: cards still in hand fire their end-of-turn effect, then everything but the `retain` cards is discarded.
	for c: CardData in hand.duplicate():
		_apply_effect(c.end_of_turn_in_hand, -1)
	var kept: Array[CardData] = []
	for c: CardData in hand:
		if c.is_junk():
			exhaust_pile.append(c)  # story 030: junk cards exhaust at the end of the turn
		elif c.retain:
			kept.append(c)
		else:
			discard_pile.append(c)
	hand = kept
	_fire_items(ItemData.TRIGGER_TURN_END)
	_end_turn_strength()
	var aftermath_before: int = player.aftermath_turns
	_tick_statuses(player)  # the player's statuses tick at the end of its turn, before the enemies act
	if not player.is_alive():
		_lose()
		return true
	_in_enemy_phase = true
	# Enemy block from the previous round expires when the enemy phase begins (story 030: before anyone acts, so block given
	# by an ally this phase -- block_ally -- lasts through the player's next turn).
	for e: Combatant in enemies:
		if e.is_alive():
			e.reset_block()
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
				turn_skipped.emit(e, skip_id)
		if not player.is_alive():
			break
		_tick_statuses(e)  # enemy statuses tick right after the enemy's own turn
	_check_phases()
	_in_enemy_phase = false
	if not player.is_alive():
		_lose()
		return true
	_check_kills()
	if first_living_enemy() < 0:
		_win()
		return true
	# Aftermath immunity counts the player's turns: -1 once the enemies have acted, unless it only began during this
	# enemy phase (woken by a hit): then the coming turn is its first one.
	if aftermath_before > 0 and player.aftermath_turns > 0:
		player.aftermath_turns -= 1
		player.changed.emit()
	_apply_rule_before_intents(turn_number + 1)
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
				cards_drawn.emit(_draw_cards(int(e["value"])))
			"damage_bonus_turn":
				turn_damage_bonus += int(e["value"])
				strength_changed.emit(player.strength, turn_damage_bonus)
			_:
				ItemEffects.apply_to_combatant(e, player)
	potion_used.emit(potion)
	state_changed.emit()
	return true


# --- Capture (story 017) ---------------------------------------------------------------------------
# Balls are consumables like potions but cost `capture.energy_cost` energy. A throw always spends the ball; on success the
# enemy leaves the battle (not killed: no defeated id, no stolen card); the fight is won as usual when none is left.

## Ids of the balls still carried (count > 0), in order: the index form of can_use_ball / use_ball.
func ball_ids() -> Array[String]:
	var ids: Array[String] = []
	for bid: String in ball_counts.keys():
		if int(ball_counts[bid]) > 0:
			ids.append(bid)
	return ids


## Balls left of that id (0 if none / unknown).
func ball_count(ball_id: String) -> int:
	return int(ball_counts.get(ball_id, 0))


## Energy a throw costs (0 without capture rules).
func ball_energy_cost() -> int:
	return _capture_rules.energy_cost if _capture_rules != null else 0


## True if the target can be captured at all in this fight (capture_allowed, living enemy, Combatant.capturable).
func is_capturable(enemy_index: int) -> bool:
	return capture_allowed and _capture_rules != null and is_valid_target(enemy_index) and enemies[enemy_index].capturable


## Success chance (0..1) of `ball` (index into ball_ids() or ball id) on enemies[enemy_index] NOW (HP and statuses);
## 0.0 if the ball / enemy is invalid or not capturable. Pure observation (no RNG).
func capture_chance(ball: Variant, enemy_index: int) -> float:
	var bid: String = _resolve_ball(ball)
	if bid.is_empty() or not is_capturable(enemy_index):
		return 0.0
	var e: Combatant = enemies[enemy_index]
	var base: float = _capture_rules.chance(_ball_book[bid], e.hp, e.max_hp, e.status_ids(), e.legendary)
	return minf(1.0, base + float(ItemEffects.passive_total(items, "capture_bonus")) / PERCENT)  # story 029: capture_bonus items


## True if a ball can be thrown now: player's turn, ball carried, enough energy, capturable living target.
func can_use_ball(ball: Variant, enemy_index: int) -> bool:
	if state != State.PLAYER_TURN or _resolve_ball(ball).is_empty() or not is_capturable(enemy_index):
		return false
	return energy >= _capture_rules.energy_cost


## Throws a ball (id or index into ball_ids()) at enemies[enemy_index]. Costs the ball and the energy whether it succeeds or not.
## Returns {used: bool, success: bool, chance: float, roll: float (rng draw, success if roll < chance), ball: BallData,
## target: Combatant}; {used: false, success: false, chance: 0.0, roll: 1.0} (nothing changed, no RNG drawn) if invalid.
## Signals: ball_thrown, then capture_succeeded (target removed from `enemies`, added to captured / captured_ids; battle_won
## if no enemy is left) or capture_failed.
func use_ball(ball: Variant, enemy_index: int) -> Dictionary:
	if not can_use_ball(ball, enemy_index):
		return {"used": false, "success": false, "chance": 0.0, "roll": 1.0}
	var bid: String = _resolve_ball(ball)
	var def: BallData = _ball_book[bid]
	var target: Combatant = enemies[enemy_index]
	var chance: float = capture_chance(bid, enemy_index)
	energy -= _capture_rules.energy_cost
	ball_counts[bid] = int(ball_counts[bid]) - 1
	var roll: float = _rng.randf()
	var success: bool = roll < chance
	ball_thrown.emit(target, def, chance)
	if success:
		enemies.remove_at(enemy_index)
		target.intent = null
		captured.append(target)
		captured_ids.append(target.id)
		capture_succeeded.emit(target)
		if first_living_enemy() < 0:
			_win()
		else:
			state_changed.emit()
	else:
		capture_failed.emit(target)
		state_changed.emit()
	return {"used": true, "success": success, "chance": chance, "roll": roll, "ball": def, "target": target}


func _resolve_ball(ball: Variant) -> String:
	if ball is int:
		var ids: Array[String] = ball_ids()
		return ids[ball] if ball >= 0 and ball < ids.size() else ""
	var bid: String = String(ball)
	return bid if bid in ball_counts and int(ball_counts[bid]) > 0 and _ball_book.has(bid) else ""


## Recomputes the final value of every living enemy's already-chosen attack against the CURRENT
## active Pokémon's types. The chosen action itself never changes.
## Also refreshes the burn penalty and the "loses its turn" label of every intent (statuses changed).
func refresh_intents() -> void:
	for e: Combatant in enemies:
		if e.is_alive() and e.intent != null:
			if e.intent.type == EnemyIntent.TYPE_ATTACK:
				var at: String = _attack_type_of(e, e.intent)
				e.intent.value = _scaled_damage(e.intent.base_value - _attack_penalty(e) + _type_rule_bonus(at), e, player, at)
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
	var hit: bool = false
	var mult: float = _type_chart.damage_multiplier(_attack_type_of(enemy, intent), player.type_ids)
	match intent.type:
		EnemyIntent.TYPE_ATTACK:
			# intent.value is already the FINAL damage of ONE hit vs the player (strength + type applied); story 030: hits.
			hit = true
			if intent.charged:
				enemy.pending_charge = null
			for h: int in intent.hits:
				if not player.is_alive():
					break
				player.take_damage(intent.value)
				if intent.value > 0:
					_on_damaged(player, _attack_type_of(enemy, intent))
				hit_resolved.emit(player, intent.value, mult)
		EnemyIntent.TYPE_BLOCK:
			enemy.add_block(intent.value)
		EnemyIntent.TYPE_BUFF:
			enemy.strength += intent.value
		EnemyIntent.TYPE_STATUS:
			apply_status(player, intent.status_id, intent.status_value)
		EnemyIntent.TYPE_HEAL, EnemyIntent.TYPE_HEAL_ALLY:
			var healed: Combatant = enemy if intent.type == EnemyIntent.TYPE_HEAL else _weakest_enemy()
			var got: int = healed.heal(intent.value) if healed != null else 0
			if got > 0:
				enemy_healed.emit(healed, got)
		EnemyIntent.TYPE_BLOCK_ALLY:
			var guarded: Combatant = _weakest_enemy()
			if guarded != null:
				guarded.add_block(intent.value)
		EnemyIntent.TYPE_CHARGE:
			var big := EnemyIntent.new()
			big.type = EnemyIntent.TYPE_ATTACK
			big.value = intent.value
			big.attack_type = intent.attack_type
			big.charged = true
			enemy.pending_charge = big
		EnemyIntent.TYPE_STRIP_BLOCK:
			var removed: int = mini(player.block, intent.value)
			if removed > 0:
				player.block -= removed
				player.changed.emit()
			block_stripped.emit(enemy, removed)
		EnemyIntent.TYPE_DRAIN_ENERGY:
			pending_energy_drain += intent.value
			energy_drained.emit(enemy, intent.value)
		EnemyIntent.TYPE_ADD_JUNK:
			var added: int = _add_junk(intent.value)
			if added > 0:
				junk_added.emit(enemy, added)
	if hit:
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
	if enemy.pending_charge != null:
		chosen = enemy.pending_charge  # story 030: the charged attack comes first (kept if the enemy lost its turn)
	elif enemy.pattern == Combatant.PATTERN_WEIGHTED:
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
	if rolled.type == EnemyIntent.TYPE_STATUS:
		rolled.status_label = _status_book.name_of(rolled.status_id)
	if rolled.type == EnemyIntent.TYPE_ATTACK:
		# Strength is added BEFORE the type multiplier (burn subtracts its penalty there too); the displayed value is the final one.
		rolled.attack_type = _attack_type_of(enemy, rolled)
		rolled.attack_type_label = _type_chart.get_type_name(rolled.attack_type) if enemy.type_ids.size() > 1 else ""
		rolled.value = _scaled_damage(rolled.value - _attack_penalty(enemy) + _type_rule_bonus(rolled.attack_type), enemy, player,
				rolled.attack_type)
		rolled.status_label = _status_book.name_of(rolled.status_id)
	rolled.skip_label = _skip_label(enemy)
	enemy.intent = rolled


## Story 019: the type of an enemy attack = the action's data attack_type, else the enemy's primary type.
func _attack_type_of(enemy: Combatant, intent: EnemyIntent) -> String:
	return intent.attack_type if intent != null and not intent.attack_type.is_empty() else enemy.get_primary_type()


## Fires every held item bound to `trigger` on the player (heal / block effects); emits item_triggered if it did something.
func _fire_items(trigger: String) -> void:
	for item: ItemData in items:
		if item.trigger != trigger:
			continue
		var did: bool = false
		for e: Dictionary in item.effects:
			if _apply_battle_item_effect(e) or ItemEffects.apply_to_combatant(e, player) > 0:
				did = true
		if did:
			item_triggered.emit(item)


## Story 029 battle_start effects that need the battle: strength_start (Force for the whole fight), apply_all_enemies
## (status on every living enemy). draw_first_turn / energy_first_turn are applied by _apply_first_turn_items. True if it did something.
func _apply_battle_item_effect(e: Dictionary) -> bool:
	match String(e["type"]):
		"strength_start":
			player.strength += int(e["value"])
			strength_changed.emit(player.strength, turn_damage_bonus)
			return true
		"apply_all_enemies":
			var any: bool = false
			for en: Combatant in enemies:
				if en.is_alive() and apply_status(en, String(e["status"]), int(e["value"])):
					any = true
			return any
	return false


## battle_start items with draw_first_turn / energy_first_turn: extra cards / energy on the battle's first turn only.
func _apply_first_turn_items() -> void:
	for item: ItemData in items:
		if item.trigger != ItemData.TRIGGER_BATTLE_START:
			continue
		var cards: int = item.total("draw_first_turn")
		var gain: int = item.total("energy_first_turn")
		if cards > 0:
			_draw_cards(cards)
		energy += gain
		if cards > 0 or gain > 0:
			item_triggered.emit(item)


## `first` = the battle's first turn: block gained from battle_start items must survive.
func _start_player_turn(first: bool = false) -> void:
	if not first:
		var kept: int = floori(float(player.block) * ItemEffects.passive_percent(items, "block_keep") / PERCENT)
		player.reset_block()
		if kept > 0:  # story 029: block_keep items carry a share of the block over
			player.add_block(kept)
			item_triggered.emit(ItemEffects.first_with(items, "block_keep"))
	_free_type_used.clear()
	turn_number += 1
	energy = max_energy
	energy_lost = 0
	_end_turn_strength()
	_cards_played_this_turn = 0
	if first or (_talent_book != null and _talent_book.trigger == TalentBook.TRIGGER_ONCE_PER_TURN):
		_talents_fired.clear()
	# Asleep / frozen team: it loses player_energy_loss energy (whole turn if absent), still draws and plays with the rest.
	var lost_turn: String = _consume_skip_turn(player)
	if not lost_turn.is_empty():
		var before: int = energy
		energy = maxi(0, energy - _status_book.get_def(lost_turn).energy_loss_for(max_energy))
		energy_lost = before - energy
		turn_skipped.emit(player, lost_turn)
	if pending_energy_drain > 0:  # story 030: drain_energy, never below the floor (nor below what sleep already left)
		var before_drain: int = energy
		energy = maxi(mini(energy, min_energy_after_drain), energy - pending_energy_drain)
		energy_lost += before_drain - energy
		pending_energy_drain = 0
	_apply_rule_turn_start(turn_number)
	_fire_items(ItemData.TRIGGER_TURN_START)
	_draw_cards(maxi(MIN_DRAW, hand_size - _rule_total(FieldRules.PLAYER_DRAW_DOWN, turn_number)))
	_apply_rule_after_draw(turn_number)
	if first:
		_apply_first_turn_items()
		_trigger_talent(active_pokemon_id)  # story 027: the starter "enters" when the battle begins
	turn_started.emit()
	state_changed.emit()


## Clears the Force that only lasts one turn (announced when it was not already 0).
func _end_turn_strength() -> void:
	if turn_damage_bonus != 0:
		turn_damage_bonus = 0
		strength_changed.emit(player.strength, turn_damage_bonus)


## Draws up to `count` cards (the discard pile is reshuffled when the draw pile is empty; the exhaust pile never is).
## Returns how many were really drawn. Story 027: a drawn card fires its `on_draw` effect.
func _draw_cards(count: int) -> int:
	var drawn: int = 0
	for i: int in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle(draw_pile)
		var card: CardData = draw_pile.pop_back()
		hand.append(card)
		drawn += 1
		_apply_effect(card.on_draw, -1)
	return drawn


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
	if target != player:  # story 029: status_bonus items strengthen what the player inflicts
		value += ItemEffects.status_bonus(items, status_id)
	if is_immune(target, status_id):
		status_blocked.emit(target, status_id)
		return false
	if target.statuses.has(status_id) and not def.refresh_on_reapply:
		status_unchanged.emit(target, status_id)
		return false
	if def.value_is_turns:  # story 027 (Faiblesse / Vulnérable): the value is the duration, re-applying adds turns
		var turns: int = value + (int((target.statuses[status_id] as Dictionary)["turns"]) if target.statuses.has(status_id) else 0)
		target.statuses[status_id] = {"value": turns, "turns": turns}
	elif target.statuses.has(status_id):
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
		if def.duration > 0 or def.value_is_turns:
			entry["turns"] = int(entry["turns"]) - 1
			if def.value_is_turns:
				entry["value"] = int(entry["turns"])
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
