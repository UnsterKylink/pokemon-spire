class_name LootGenerator
extends RefCounted
## Pure loot logic (no nodes): what a won fight pays, and weighted picks of held items / potions.
## All numbers come from shop.json / items.json / potions.json. Implements: story-006-objets-et-services, criterion 3.


## Loot of a won fight in `room_type` ("wild", "elite"; "" or a type without loot config = nothing):
## {"money": int, "item_id": String ("" = none), "potion_id": String ("" = none), "ball_id": String ("" = none; story 017)}.
## money = random in [money_min, money_max] + the run's money_bonus_on_win items. An item is an unowned held item
## (weighted by rarity); a potion is only rolled if the run still has room to carry one. Deterministic for a seeded rng.
## Nothing is applied: pass the result to RunState.apply_loot.
static func generate(data: GameData, run: RunState, room_type: String, rng: RandomNumberGenerator) -> Dictionary:
	var loot: Dictionary = {"money": 0, "item_id": "", "potion_id": "", "ball_id": ""}
	var cfg: Dictionary = data.get_loot_config(room_type)
	if cfg.is_empty():
		return loot
	loot["money"] = rng.randi_range(int(cfg["money_min"]), int(cfg["money_max"])) + ItemEffects.win_money_bonus(run.items)
	if rng.randf() < float(cfg["item_chance"]):
		var picked: Array[ItemData] = pick_items(data, run, 1, rng)
		if not picked.is_empty():
			loot["item_id"] = picked[0].id
	if rng.randf() < float(cfg["potion_chance"]) and run.potions.size() < run.max_potions():
		var potions: Array[PotionData] = pick_potions(data, 1, rng)
		if not potions.is_empty():
			loot["potion_id"] = potions[0].id
	var ball_cfg: Dictionary = data.get_ball_loot_config(room_type)
	if not ball_cfg.is_empty() and rng.randf() < float(ball_cfg["chance"]) and run.ball_total() < run.max_balls():
		var balls: Array[BallData] = pick_balls(data, run.zone_index + 1, 1, ball_cfg["weights"], rng)
		if not balls.is_empty():
			loot["ball_id"] = balls[0].id
	return loot


## `count` DISTINCT balls available in `zone_number` (min_zone), drawn by `weights` (ball id -> weight; fewer if not enough).
static func pick_balls(data: GameData, zone_number: int, count: int, weights: Dictionary, rng: RandomNumberGenerator) -> Array[BallData]:
	var pool: Array[BallData] = []
	for id: String in data.get_ball_ids():
		var b: BallData = data.get_ball(id)
		if weights.has(id) and b.min_zone <= zone_number:
			pool.append(b)
	var result: Array[BallData] = []
	while result.size() < count and not pool.is_empty():
		var total: float = 0.0
		for b: BallData in pool:
			total += float(weights[b.id])
		var roll: float = rng.randf() * total
		var index: int = pool.size() - 1
		for i: int in pool.size():
			if roll < float(weights[pool[i].id]):
				index = i
				break
			roll -= float(weights[pool[i].id])
		result.append(pool[index])
		pool.remove_at(index)
	return result


## `count` DISTINCT held items the run does not own, drawn by rarity weight (fewer if not enough remain).
static func pick_items(data: GameData, run: RunState, count: int, rng: RandomNumberGenerator) -> Array[ItemData]:
	var pool: Array[ItemData] = []
	for id: String in data.get_item_ids():
		if not run.has_item(id):
			pool.append(data.get_item(id))
	var weights: Dictionary = data.get_item_rarity_weights()
	var result: Array[ItemData] = []
	while result.size() < count and not pool.is_empty():
		var total: float = 0.0
		for it: ItemData in pool:
			total += float(weights.get(it.rarity, 0.0))
		var index: int = pool.size() - 1
		if total > 0.0:
			var roll: float = rng.randf() * total
			for i: int in pool.size():
				var w: float = float(weights.get(pool[i].rarity, 0.0))
				if w > 0.0 and roll < w:
					index = i
					break
				roll -= w
		else:
			index = rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result


## `count` DISTINCT potions drawn uniformly (fewer if the data has fewer).
static func pick_potions(data: GameData, count: int, rng: RandomNumberGenerator) -> Array[PotionData]:
	var ids: Array[String] = data.get_potion_ids()
	var result: Array[PotionData] = []
	while result.size() < count and not ids.is_empty():
		var i: int = rng.randi_range(0, ids.size() - 1)
		result.append(data.get_potion(ids[i]))
		ids.remove_at(i)
	return result
