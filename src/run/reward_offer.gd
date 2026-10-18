class_name RewardOffer
extends RefCounted
## One card proposed on the reward screen (story 004).

## The proposed card.
var card: CardData
## True when this card is an attack "stolen" from a defeated Pokémon.
var stolen: bool = false
## Display name of the Pokémon the card was stolen from ("" when not stolen).
var source_pokemon_name: String = ""


static func make(offered_card: CardData, is_stolen: bool = false, source_name: String = "") -> RewardOffer:
	var o := RewardOffer.new()
	o.card = offered_card
	o.stolen = is_stolen
	o.source_pokemon_name = source_name
	return o
