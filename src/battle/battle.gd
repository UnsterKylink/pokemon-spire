class_name Battle
extends RefCounted
## Pure combat logic (no nodes/scenes): 1 player Pokémon vs 1..3 enemies with data-driven intents.
## Implements: design/game-brief.md MVP features 1-2, story-001-combat-de-base,
## story-002-intentions-et-multi-ennemis, story-003-types.

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

var _rng: RandomNumberGenerator
var _type_chart: TypeChart
var _pokemon_lookup: Callable = Callable()


## Starts a battle. pokemon_lookup(pokemon_id) -> Dictionary {id, name, sprite_path, types} (GameData.get_pokemon_info)
## lets cards bring other Pokémon in; starter_pokemon_id is the active Pokémon at battle start. rng is injected so shuffles and weighted intents are seedable.
## Expects 1..3 enemies: extra enemies are ignored, an empty list is reported (push_error).
## type_chart is injected; null means no types (every hit neutral).
func _init(player_combatant: Combatant, enemy_list: Array[Combatant], deck: Array[CardData],
		energy_per_turn: int, cards_per_turn: int, rng: RandomNumberGenerator,
		type_chart: TypeChart = null, pokemon_lookup: Callable = Callable(), starter_pokemon_id: String = "") -> void:
	player = player_combatant
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
	_start_player_turn()


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
		hit_mult = _type_chart.damage_multiplier(card.type_id, hit_target.type_ids)
		hit_amount = _type_chart.final_damage(card.damage, card.type_id, hit_target.type_ids)
		hit_target.take_damage(hit_amount)  # block absorbs AFTER the type multiplier
		if not hit_target.is_alive():
			hit_target.intent = null  # a K.O. enemy no longer acts
	if card.block > 0:
		player.add_block(card.block)
	if hit_target != null:
		hit_resolved.emit(hit_target, hit_amount, hit_mult)
	card_played.emit(card)
	if first_living_enemy() < 0:
		state = State.WON
		state_changed.emit()
		battle_won.emit()
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
	for e: Combatant in enemies:
		if not e.is_alive() or e.intent == null:
			continue
		_execute_intent(e)
		if not player.is_alive():
			break
	if not player.is_alive():
		state = State.LOST
		state_changed.emit()
		battle_lost.emit()
		return true
	for e: Combatant in enemies:
		_roll_intent(e)
	_start_player_turn()
	return true


## Recomputes the final value of every living enemy's already-chosen attack against the CURRENT
## active Pokémon's types. The chosen action itself never changes.
func refresh_intents() -> void:
	for e: Combatant in enemies:
		if e.is_alive() and e.intent != null and e.intent.type == EnemyIntent.TYPE_ATTACK:
			e.intent.value = _type_chart.final_damage(e.intent.base_value, e.get_primary_type(), player.type_ids)


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
		EnemyIntent.TYPE_BLOCK:
			enemy.add_block(intent.value)
		EnemyIntent.TYPE_BUFF:
			enemy.strength += intent.value
	if hit:
		hit_resolved.emit(player, intent.value, _type_chart.damage_multiplier(enemy.get_primary_type(), player.type_ids))
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
		# Strength is added BEFORE the type multiplier; the displayed value is the final one.
		rolled.value = _type_chart.final_damage(rolled.value, enemy.get_primary_type(), player.type_ids)
	enemy.intent = rolled


func _start_player_turn() -> void:
	player.reset_block()
	energy = max_energy
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
