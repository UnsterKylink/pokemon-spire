class_name ShopEntry
extends RefCounted
## One article on sale at the Poké Mart (story 006). Exactly one of card / item / potion is set according to `kind`.

const KIND_CARD: String = "card"
const KIND_ITEM: String = "item"
const KIND_POTION: String = "potion"

var kind: String = KIND_CARD
var card: CardData = null
var item: ItemData = null
var potion: PotionData = null
## Pokédollars.
var price: int = 0
## True once bought (the slot stays visible, greyed out).
var sold: bool = false


## Display name of the article (cards: plain name, add the carrier with CardData.display_label).
func get_name() -> String:
	match kind:
		KIND_CARD:
			return card.display_name
		KIND_ITEM:
			return item.display_name
	return potion.display_name


## Description text of the article.
func get_description() -> String:
	match kind:
		KIND_CARD:
			return card.description
		KIND_ITEM:
			return item.description
	return potion.description
