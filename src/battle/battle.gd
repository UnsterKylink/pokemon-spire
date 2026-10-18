class_name Battle
extends RefCounted
## Pure combat logic (no nodes/scenes): 1 player Pokémon vs 1..3 enemies with data-driven intents.
## Implements: design/game-brief.md MVP features 1-2, story-001-combat-de-base,
## story-002-intentions-et-multi-ennemis.

enum State { PLAYER_TURN, WON, LOST }

const MIN_ENEMIES: int = 1
const MAX_ENEMIES: int = 3

signal state_changed
signal turn_started
signal card_played(card: CardData)
signal enemy_acted(enemy: Combatant, intent: EnemyIntent)
signal battle_won
signal battle_lost

var player: Combatant
var enemies: Array[Combatant] = []
var state: State = State.PLAYER_TURN
var energy: int = 0
var max_energy: int = 0
var hand_size: int = 0
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var _rng: RandomNumberGenerator


## Starts a battle. rng is injected so shuffles and weighted intents are seedable.
## Expects 1..3 enemies: extra enemies are ignored, an empty list is reported (push_error).
func _init(player_combatant: Combatant, enemy_list: Array[Combatant], deck: Array[CardData],
		energy_per_turn: int, cards_per_turn: int, rng: RandomNumberGenerator) -> void:
	player = player_combatant
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
	energy -= card.cost
	hand.remove_at(index)
	discard_pile.append(card)
	if card.damage > 0:
		var target: Combatant = enemies[target_index]
		target.take_damage(card.damage)
		if not target.is_alive():
			target.intent = null  # a K.O. enemy no longer acts
	if card.block > 0:
		player.add_block(card.block)
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


func _execute_intent(enemy: Combatant) -> void:
	var intent: EnemyIntent = enemy.intent
	enemy.reset_block()  # block from the previous round expires when the enemy acts
	match intent.type:
		EnemyIntent.TYPE_ATTACK:
			player.take_damage(intent.value)
		EnemyIntent.TYPE_BLOCK:
			enemy.add_block(intent.value)
		EnemyIntent.TYPE_BUFF:
			enemy.strength += intent.value
	enemy_acted.emit(enemy, intent)


## Chooses the enemy's next action from its data (sequence or weighted). Attack values
## include the enemy's current strength, so the displayed intent is exactly what runs.
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
	enemy.intent = chosen.with_bonus(bonus)


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
