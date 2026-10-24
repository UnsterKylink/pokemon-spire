class_name ShopInventory
extends RefCounted
## One Poké Mart visit: cards, held items and potions on sale + the card-removal service (story 006, criterion 5).
## Generate ONE per shop visit (deterministic for a seeded rng) and keep it while the room is open.
## Purchases mutate the injected RunState (money, deck, items, potions).

## Cards on sale (type-coherent carriers, same logic as card rewards).
var cards: Array[ShopEntry] = []
var items: Array[ShopEntry] = []
var potions: Array[ShopEntry] = []
## Story 017: 1-2 Poké Ball offers (balls.json shop), kind ShopEntry.KIND_BALL.
var balls: Array[ShopEntry] = []
var _run: RunState
var _min_deck_size: int = 1


## Stocks a shop from the data (shop.json "shop") for `run` (owned items are never offered).
static func generate(data: GameData, run: RunState, rng: RandomNumberGenerator) -> ShopInventory:
	var inv := ShopInventory.new()
	inv._run = run
	inv._min_deck_size = int(data.get_removal_config().get("min_deck_size", 1))
	var cfg: Dictionary = data.get_shop_config()
	var no_ids: Array[String] = []
	for offer: RewardOffer in RewardGenerator.generate(data, run.player_id, no_ids, rng, {}, int(cfg["card_count"])):
		var e := ShopEntry.new()
		e.kind = ShopEntry.KIND_CARD
		e.card = offer.card
		e.price = int((cfg["card_prices"] as Dictionary)[offer.card.rarity])
		inv.cards.append(e)
	var item_count: int = rng.randi_range(int(cfg["item_count_min"]), int(cfg["item_count_max"]))
	for item: ItemData in LootGenerator.pick_items(data, run, item_count, rng):
		var e := ShopEntry.new()
		e.kind = ShopEntry.KIND_ITEM
		e.item = item
		e.price = int((cfg["item_prices"] as Dictionary)[item.rarity])
		inv.items.append(e)
	for potion: PotionData in LootGenerator.pick_potions(data, int(cfg["potion_count"]), rng):
		var e := ShopEntry.new()
		e.kind = ShopEntry.KIND_POTION
		e.potion = potion
		e.price = potion.price
		inv.potions.append(e)
	var ball_cfg: Dictionary = data.get_ball_shop_config()
	if not ball_cfg.is_empty():
		var ball_count: int = rng.randi_range(int(ball_cfg["count_min"]), int(ball_cfg["count_max"]))
		for ball: BallData in LootGenerator.pick_balls(data, run.zone_index + 1, ball_count, ball_cfg["weights"], rng):
			var e := ShopEntry.new()
			e.kind = ShopEntry.KIND_BALL
			e.ball = ball
			e.price = ball.price
			inv.balls.append(e)
	return inv


## True if cards[index] can be bought now (exists, not sold, enough money).
func can_buy_card(index: int) -> bool:
	return _can_buy(cards, index)


## True if items[index] can be bought now (also requires not owning it).
func can_buy_item(index: int) -> bool:
	return _can_buy(items, index) and not _run.has_item(items[index].item.id)


## True if potions[index] can be bought now (also requires a free potion slot).
func can_buy_potion(index: int) -> bool:
	return _can_buy(potions, index) and _run.potions.size() < _run.max_potions()


## True if balls[index] can be bought now (also requires room: total balls < max_carried).
func can_buy_ball(index: int) -> bool:
	return _can_buy(balls, index) and _run.ball_total() < _run.max_balls()


## Buys balls[index]: pays and stores one ball. False (nothing changes) if not purchasable (money / bag full).
func buy_ball(index: int) -> bool:
	if not can_buy_ball(index):
		return false
	_run.spend_money(balls[index].price)
	_run.add_ball(balls[index].ball.id)
	balls[index].sold = true
	return true


## Buys cards[index]: pays and adds the card to the deck. False (nothing changes) if not purchasable.
func buy_card(index: int) -> bool:
	if not can_buy_card(index):
		return false
	_run.spend_money(cards[index].price)
	_run.add_card(cards[index].card)
	cards[index].sold = true
	return true


## Buys items[index]: pays and gives the item (on_pickup effects apply). False if not purchasable.
func buy_item(index: int) -> bool:
	if not can_buy_item(index):
		return false
	_run.spend_money(items[index].price)
	_run.add_item(items[index].item)
	items[index].sold = true
	return true


## Buys potions[index]: pays and stores the potion. False if not purchasable (money / full belt).
func buy_potion(index: int) -> bool:
	if not can_buy_potion(index):
		return false
	_run.spend_money(potions[index].price)
	_run.add_potion(potions[index].potion)
	potions[index].sold = true
	return true


## Current price of the card-removal service (rises with every removal of the run).
func removal_price() -> int:
	return _run.removal_price()


## True if deck[deck_index] can be removed now (valid index, enough money, deck stays >= min_deck_size).
func can_remove_card(deck_index: int) -> bool:
	return deck_index >= 0 and deck_index < _run.deck.size() and _run.deck.size() > _min_deck_size \
			and _run.money >= _run.removal_price()


## Pays the removal price and removes deck[deck_index] from the deck. False (nothing changes) if not allowed.
func remove_card(deck_index: int) -> bool:
	if not can_remove_card(deck_index):
		return false
	_run.spend_money(_run.removal_price())
	_run.deck.remove_at(deck_index)
	_run.card_removals += 1
	return true


func _can_buy(list: Array[ShopEntry], index: int) -> bool:
	return index >= 0 and index < list.size() and not list[index].sold and _run.money >= list[index].price
