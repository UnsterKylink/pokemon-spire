class_name EvolutionOffer
extends RefCounted
## Story 007 (story-007-champion-evolution-fin-de-partie): the cards offered when the starter evolves after the
## Champion. Pure logic, no RNG (the offer is the same every time for a given starter):
##   1. the evolution's `teaches` cards (pokemon.json evolutions, GameData.get_evolution_cards), in data order;
##   2. + ONE more: the UPGRADED copy of the "strong" starter card of the evolved form's primary type
##      (pokemon.json starter cards + the shop upgrade rules), i.e. "the signature attack, mastered".
##      It is a real alternative to the big new attacks: cheaper / already upgraded. If it cannot be upgraded
##      the plain copy is offered; if it duplicates a teaches card it is not added.
## Every card is carried by the evolved form (`with_pokemon(evolved_id)`), so playing it would field that form.
## A Pokémon without an evolution gets only the upgraded strong card (carried by itself).


## Cards offered to `run` (call AFTER RunState.evolve_starter: the carrier is run.starter_pokemon_id).
## Empty if the data supplies nothing.
static func generate(data: GameData, run: RunState) -> Array[CardData]:
	var result: Array[CardData] = []
	if data == null or run == null:
		return result
	var carrier: String = run.starter_pokemon_id
	var used: Dictionary = {}
	for card: CardData in data.get_evolution_cards(run.base_pokemon_id):
		if not used.has(card.id):
			used[card.id] = true
			result.append(card.with_pokemon(carrier))
	var primary: String = run.type_ids[0] if not run.type_ids.is_empty() else data.get_primary_type(run.base_pokemon_id)
	var starter_cards: Dictionary = data.get_starter_cards_for_type(primary)
	var strong: CardData = starter_cards.get("strong", null)
	if strong != null and not used.has(strong.id):
		var up: CardData = strong.upgraded_copy(data.get_upgrade_rules())
		result.append((up if up != null else strong).with_pokemon(carrier))
	return result
