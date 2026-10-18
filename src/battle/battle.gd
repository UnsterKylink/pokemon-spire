class_name Battle
extends RefCounted
## Pure combat logic (no nodes/scenes): 1 player Pokémon vs 1 enemy.
## Implements: design/game-brief.md MVP feature 1, story-001-combat-de-base.

enum State { PLAYER_TURN, WON, LOST }

signal state_changed
signal turn_started
signal card_played(card: CardData)
signal enemy_acted(damage: int)
signal battle_won
signal battle_lost

var player: Combatant
var enemy: Combatant
var state: State = State.PLAYER_TURN
var energy: int = 0
var max_energy: int = 0
var hand_size: int = 0
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var _rng: RandomNumberGenerator


## Starts a battle. rng is injected so shuffles are seedable.
func _init(player_combatant: Combatant, enemy_combatant: Combatant, deck: Array[CardData],
		energy_per_turn: int, cards_per_turn: int, rng: RandomNumberGenerator) -> void:
	player = player_combatant
	enemy = enemy_combatant
	max_energy = energy_per_turn
	hand_size = cards_per_turn
	_rng = rng
	draw_pile = deck.duplicate()
	_shuffle(draw_pile)


## Begins the first player turn (call once after connecting signals).
func start() -> void:
	_start_player_turn()


## True if the card at hand index can be played now (state, index, energy).
func can_play(index: int) -> bool:
	if state != State.PLAYER_TURN or index < 0 or index >= hand.size():
		return false
	return hand[index].cost <= energy


## Plays hand[index] on target (target is required for attacks, must be the enemy).
## Returns false (and changes nothing) if the play is invalid.
func play_card(index: int, target: Combatant = null) -> bool:
	if not can_play(index):
		return false
	var card: CardData = hand[index]
	if card.needs_target() and target != enemy:
		return false
	energy -= card.cost
	hand.remove_at(index)
	discard_pile.append(card)
	if card.damage > 0:
		enemy.take_damage(card.damage)
	if card.block > 0:
		player.add_block(card.block)
	card_played.emit(card)
	if not enemy.is_alive():
		state = State.WON
		state_changed.emit()
		battle_won.emit()
		return true
	state_changed.emit()
	return true


## Ends the player's turn: discards hand, enemy attacks, then a new player turn begins.
func end_turn() -> bool:
	if state != State.PLAYER_TURN:
		return false
	discard_pile.append_array(hand)
	hand.clear()
	var dmg: int = enemy.attack_damage
	player.take_damage(dmg)
	enemy_acted.emit(dmg)
	if not player.is_alive():
		state = State.LOST
		state_changed.emit()
		battle_lost.emit()
		return true
	_start_player_turn()
	return true


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
