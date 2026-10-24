extends RefCounted
## Auto-player policy of the balance simulator (story 019): "correct, not expert". Deterministic given its RNG seed.
## Every knob lives in DEFAULTS below (documented); override any of them with `--policy=<file.json>` on the simulator
## command line (JSON object, same keys). The policy only calls LEGAL game actions and counts any refused one in
## `illegal_moves` (must stay 0; checked by the scratch test t21).
##
## Summary of the policy
##  - Starter: picks one of the 3 proposals at random (the player has no information), or the first (`starter_pick`).
##  - Map: Centre when HP < center_hp_frac, elite only when HP > elite_min_hp_frac, Mart when money >= mart_min_money,
##    otherwise wild, then event (see MAP_SCORES).
##  - Battle (per decision, repeated until nothing is worth playing): potions (heal below potion_heal_hp_frac or against a
##    lethal threat, cures when a status is on, boosters in elite / gym / league fights) -> block first if the shown attacks
##    total >= block_first_fraction of (HP + block) -> status skills on healthy targets -> attacks on the lowest-HP enemy
##    (target order = lowest HP+block), best final damage per energy, never an immune (x0) target -> spare energy on block.
##  - Rewards: score = (damage + block_weight*block + status_weight*status value) / max(cost, 0.5) + coverage bonus
##    (new types hit super-effectively), take if >= take_min_score, never > max_copies copies of a low-value card,
##    deck cap max_deck_size (then only cards >= replace_min_score).
##  - Centre: heal if HP < center_heal_below_frac else upgrade the card with the best score gain. Mart: see play_mart.
##  - Events: first option without HP loss / card loss.

const DEFAULTS: Dictionary = {
	## "random" | "first": how the starter is picked among the 3 proposals.
	"starter_pick": "random",
	## Map: HP fraction under which a reachable Centre is preferred over everything.
	"center_hp_frac": 0.5,
	## Map: elite rooms are only entered above this HP fraction.
	"elite_min_hp_frac": 0.7,
	## Map: a Mart is preferred when the run holds at least this much money.
	"mart_min_money": 150,
	## Map: base preference of each room type (higher = preferred), before the HP / money rules above.
	"map_scores": {"wild": 30.0, "event": 20.0, "elite": 25.0, "center": 5.0, "mart": 3.0, "boss": 100.0},
	## Battle: block first when the total of shown attacks >= this fraction of (current HP + block).
	"block_first_fraction": 0.4,
	## Battle: a pure status skill is played only on a target with at least this much HP + block (not about to die).
	"status_min_target_hp": 12,
	## Battle: energy value of a 0-cost card when ranking damage per energy.
	"zero_cost_energy": 0.5,
	## Battle: score bonus for a hit that kills its target.
	"kill_bonus": 20.0,
	## Battle: drink a heal potion below this HP fraction.
	"potion_heal_hp_frac": 0.4,
	## Battle: use "booster" potions (damage +, energy +, draw) in these room types only.
	"booster_rooms": ["boss", "league", "elite"],
	## Battle: safety cap on player turns / actions per turn (a stalled fight counts as a defeat).
	"max_turns": 80,
	"max_actions_per_turn": 40,
	## Reward scoring.
	"block_weight": 0.8,
	"status_weight": 1.0,
	"coverage_bonus": 0.4,
	"coverage_min_mult": 2.0,
	"skill_bonus_if_few": 1.5,
	"desired_skills": 4,
	"take_min_score": 5.0,
	"max_copies": 2,
	"low_value_score": 7.5,
	"max_deck_size": 25,
	"replace_min_score": 9.0,
	## Centre: heal below this HP fraction, else upgrade.
	"center_heal_below_frac": 0.7,
	## Mart: card bought only when score >= this; remove one basic card once per run; item rating per effect point.
	"mart_buy_card_min_score": 7.5,
	"mart_remove_once": true,
	"mart_min_item_rating": 4.0,
	"item_effect_weight": {"energy_up_per_turn": 12.0, "draw_up": 9.0, "max_hp_up": 0.6, "damage_bonus": 2.5, "heal_flat": 0.7,
			"block_flat": 0.6, "money_bonus_on_win": 0.15, "status_immunity": 2.0, "heal_percent_max": 0.2},
}

var cfg: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var data: GameData
var chart: TypeChart
## Number of game actions the game refused (must be 0).
var illegal_moves: int = 0
var _removed_once: bool = false


func _init(game_data: GameData, overrides: Dictionary, seed_value: int) -> void:
	data = game_data
	chart = game_data.get_type_chart()
	cfg = DEFAULTS.duplicate(true)
	for k: String in overrides.keys():
		cfg[k] = overrides[k]
	rng.seed = seed_value


# --- Starter, map --------------------------------------------------------------------------------

func pick_starter(choices: Array[String]) -> String:
	if choices.is_empty():
		return ""
	if String(cfg["starter_pick"]) == "first":
		return choices[0]
	return choices[rng.randi_range(0, choices.size() - 1)]


## Id of the room to enter among `reachable` (ordered ids); ties are broken by the policy RNG (deterministic).
func choose_room(run: RunState, reachable: Array[String]) -> String:
	var hp_frac: float = float(run.hp) / float(run.max_hp)
	var scores: Dictionary = cfg["map_scores"]
	var best_id: String = ""
	var best: float = -INF
	for id: String in reachable:
		var node: MapNode = run.act.graph.get_node(id)
		var s: float = float(scores.get(node.room_type, 0.0)) + rng.randf() * 0.01
		match node.room_type:
			"center":
				if hp_frac < float(cfg["center_hp_frac"]):
					s += 1000.0
				elif hp_frac < float(cfg["center_heal_below_frac"]):
					s += 40.0
			"elite":
				if hp_frac <= float(cfg["elite_min_hp_frac"]):
					s -= 500.0
			"mart":
				if run.money >= int(cfg["mart_min_money"]):
					s += 500.0
		if s > best:
			best = s
			best_id = id
	return best_id


# --- Battle ----------------------------------------------------------------------------------------

## Plays the whole battle. `st` is a stats dictionary the caller owns (keys used: "potions_used" is counted by the caller).
## Returns true if the fight was left unfinished (turn cap): the caller treats it as a defeat.
func play_battle(b: Battle, room_type: String) -> bool:
	var boosters_used: Dictionary = {}
	var turns: int = 0
	while b.state == Battle.State.PLAYER_TURN:
		turns += 1
		if turns > int(cfg["max_turns"]):
			return true
		_play_turn(b, room_type, boosters_used)
		if b.state != Battle.State.PLAYER_TURN:
			break
		if not b.end_turn():
			illegal_moves += 1
			return true
	return false


func _play_turn(b: Battle, room_type: String, boosters_used: Dictionary) -> void:
	for _i: int in int(cfg["max_actions_per_turn"]):
		if b.state != Battle.State.PLAYER_TURN:
			return
		if _try_potion(b, room_type, boosters_used):
			continue
		var act: Dictionary = _choose_card(b)
		if act.is_empty():
			return
		if not b.play_card(int(act["index"]), int(act["target"])):
			illegal_moves += 1
			return


func _incoming(b: Battle) -> int:
	var total: int = 0
	for e: Combatant in b.enemies:
		if e.is_alive() and e.intent != null and e.intent.type == EnemyIntent.TYPE_ATTACK and e.intent.skip_label.is_empty():
			total += e.intent.value
	return total


func _use_potion(b: Battle, index: int) -> bool:
	if not b.use_potion(index):
		illegal_moves += 1
		return false
	return true


## Returns true if a potion was drunk (the caller then re-evaluates).
func _try_potion(b: Battle, room_type: String, boosters_used: Dictionary) -> bool:
	if b.potions.is_empty():
		return false
	var p: Combatant = b.player
	var hp_frac: float = float(p.hp) / float(p.max_hp)
	var incoming: int = _incoming(b)
	var lethal: bool = incoming > 0 and incoming >= p.hp + p.block
	# 1. Lethal threat: block potion if it saves us, else a heal that does.
	if lethal:
		for i: int in b.potions.size():
			for e: Dictionary in b.potions[i].effects:
				if String(e["type"]) == "block_flat" and p.hp + p.block + int(e["value"]) > incoming:
					return _use_potion(b, i)
		for i: int in b.potions.size():
			if _heal_amount(b.potions[i], p) > 0 and p.hp + p.block + _heal_amount(b.potions[i], p) > incoming:
				return _use_potion(b, i)
	# 2. Low HP: the smallest heal that is worth it (largest if very low).
	if hp_frac < float(cfg["potion_heal_hp_frac"]):
		var best: int = -1
		var best_amount: int = 0
		for i: int in b.potions.size():
			var amount: int = _heal_amount(b.potions[i], p)
			if amount > best_amount:
				best_amount = amount
				best = i
		if best >= 0:
			return _use_potion(b, best)
	# 3. Cure a status (specific cure first, "all" otherwise).
	if not p.statuses.is_empty():
		for i: int in b.potions.size():
			for e: Dictionary in b.potions[i].effects:
				if String(e["type"]) == "cure_status" and p.has_status(String(e.get("status", ""))):
					return _use_potion(b, i)
		for i: int in b.potions.size():
			for e: Dictionary in b.potions[i].effects:
				if String(e["type"]) == "cure_status" and String(e.get("status", "")) == "all":
					return _use_potion(b, i)
	# 4. Boosters in hard fights.
	if room_type in (cfg["booster_rooms"] as Array):
		var attacks_in_hand: int = 0
		var min_cost_left: int = 99
		for c: CardData in b.hand:
			if c.kind == CardData.KIND_ATTACK:
				attacks_in_hand += 1
			if c.cost > b.energy:
				min_cost_left = mini(min_cost_left, c.cost)
		for i: int in b.potions.size():
			var pid: String = b.potions[i].id
			if boosters_used.has(pid) or b.potions[i].effects.is_empty():
				continue
			var t: String = String(b.potions[i].effects[0]["type"])
			var use: bool = false
			if t == "damage_bonus_turn":
				use = attacks_in_hand >= 2 and b.energy >= 2 and b.turn_damage_bonus == 0
			elif t == "energy_gain":
				use = b.energy == 0 and min_cost_left < 99
			elif t == "draw_cards":
				use = b.energy >= 2 and b.hand.size() <= 2
			if use:
				boosters_used[pid] = true
				return _use_potion(b, i)
	return false


func _heal_amount(potion: PotionData, p: Combatant) -> int:
	var total: int = 0
	for e: Dictionary in potion.effects:
		match String(e["type"]):
			"heal_flat":
				total += int(e["value"])
			"heal_percent_max":
				total += ceili(p.max_hp * float(e["percent"]) / 100.0)
	return mini(total, p.max_hp - p.hp)


## Next card to play: {"index": hand index, "target": enemy index (-1 if none)} or {} (nothing worth playing).
func _choose_card(b: Battle) -> Dictionary:
	var p: Combatant = b.player
	var incoming: int = _incoming(b)
	var need_block: int = incoming - p.block
	var danger: bool = incoming > 0 and float(incoming) >= float(cfg["block_first_fraction"]) * float(p.hp + p.block)
	if danger and need_block > 0:
		var blk: Dictionary = _best_block(b)
		if not blk.is_empty():
			return blk
	# Targets by lowest HP + block.
	var targets: Array[int] = []
	for i: int in b.enemies.size():
		if b.enemies[i].is_alive():
			targets.append(i)
	targets.sort_custom(func(x: int, y: int) -> bool:
		var ex: Combatant = b.enemies[x]
		var ey: Combatant = b.enemies[y]
		if ex.hp + ex.block != ey.hp + ey.block:
			return ex.hp + ex.block < ey.hp + ey.block
		return x < y)
	# Pure status skills, early, on a healthy target that does not already have it and is not immune.
	for i: int in b.hand.size():
		var c: CardData = b.hand[i]
		if c.kind != CardData.KIND_SKILL or c.status_id.is_empty() or c.cost > b.energy:
			continue
		for t: int in targets:
			var e: Combatant = b.enemies[t]
			if e.hp + e.block >= int(cfg["status_min_target_hp"]) and not e.has_status(c.status_id) and not b.is_immune(e, c.status_id):
				return {"index": i, "target": t}
	# Attacks: lowest-HP target first, super-effective / neutral cards preferred, then resisted ones.
	for min_mult: float in [1.0, 0.01]:
		for t: int in targets:
			var e: Combatant = b.enemies[t]
			var best_i: int = -1
			var best_s: float = -INF
			for i: int in b.hand.size():
				var c: CardData = b.hand[i]
				if c.kind != CardData.KIND_ATTACK or c.damage <= 0 or c.cost > b.energy:
					continue
				if chart.damage_multiplier(c.type_id, e.type_ids) < min_mult:
					continue
				var dmg: int = chart.final_damage(c.damage + b.turn_damage_bonus, c.type_id, e.type_ids)
				var s: float = float(dmg) / maxf(float(c.cost), float(cfg["zero_cost_energy"]))
				if dmg >= e.hp + e.block:
					s += float(cfg["kill_bonus"])
				if s > best_s:
					best_s = s
					best_i = i
			if best_i >= 0:
				return {"index": best_i, "target": t}
	# Spare energy: block if some attack is still unblocked.
	if need_block > 0:
		return _best_block(b)
	return {}


func _best_block(b: Battle) -> Dictionary:
	var best_i: int = -1
	var best_s: float = -INF
	for i: int in b.hand.size():
		var c: CardData = b.hand[i]
		if c.block <= 0 or c.kind != CardData.KIND_SKILL or c.cost > b.energy:
			continue
		var s: float = float(c.block) / maxf(float(c.cost), float(cfg["zero_cost_energy"]))
		if s > best_s:
			best_s = s
			best_i = i
	if best_i < 0:
		return {}
	return {"index": best_i, "target": -1}


# --- Cards: reward / evolution / shop scoring ------------------------------------------------------

## Base value of a card per energy (no deck context).
func card_value(c: CardData) -> float:
	var raw: float = float(c.damage) + float(cfg["block_weight"]) * float(c.block)
	if not c.status_id.is_empty():
		raw += float(cfg["status_weight"]) * float(c.status_value)
	return raw / maxf(float(c.cost), float(cfg["zero_cost_energy"]))


## Types (ids) that some attack card of the deck hits for >= coverage_min_mult.
func _covered_types(deck: Array[CardData]) -> Dictionary:
	var covered: Dictionary = {}
	for c: CardData in deck:
		if c.kind == CardData.KIND_ATTACK and c.damage > 0:
			for t: String in chart.get_type_ids():
				if chart.damage_multiplier_vs(c.type_id, t) >= float(cfg["coverage_min_mult"]):
					covered[t] = true
	return covered


## Score of adding `c` to `deck` (-INF = never).
func score_card(c: CardData, deck: Array[CardData], covered: Dictionary) -> float:
	var s: float = card_value(c)
	var copies: int = 0
	var skills: int = 0
	for d: CardData in deck:
		if d.id == c.id:
			copies += 1
		if d.kind == CardData.KIND_SKILL and d.block > 0:
			skills += 1
	if c.kind == CardData.KIND_ATTACK:
		var fresh: int = 0
		for t: String in chart.get_type_ids():
			if not covered.has(t) and chart.damage_multiplier_vs(c.type_id, t) >= float(cfg["coverage_min_mult"]):
				fresh += 1
		s += float(cfg["coverage_bonus"]) * float(fresh)
	elif c.block > 0 and skills < int(cfg["desired_skills"]):
		s += float(cfg["skill_bonus_if_few"])
	if copies >= int(cfg["max_copies"]) and s < float(cfg["low_value_score"]):
		return -INF
	return s


## Index of the offer to take (-1 = skip). `offers` are CardData.
func choose_reward(run: RunState, cards: Array[CardData], min_score: float = INF) -> int:
	var threshold: float = float(cfg["take_min_score"]) if min_score == INF else min_score
	if run.deck.size() >= int(cfg["max_deck_size"]):
		threshold = maxf(threshold, float(cfg["replace_min_score"]))
	var covered: Dictionary = _covered_types(run.deck)
	var best: int = -1
	var best_s: float = -INF
	for i: int in cards.size():
		var s: float = score_card(cards[i], run.deck, covered)
		if s > best_s:
			best_s = s
			best = i
	if best >= 0 and best_s >= threshold:
		return best
	return -1


# --- Centre, Mart, events ----------------------------------------------------------------------------

## Centre Pokémon: heal or upgrade (applied through RunState, like Main).
func play_center(run: RunState) -> void:
	if float(run.hp) / float(run.max_hp) < float(cfg["center_heal_below_frac"]):
		run.rest_heal()
		return
	var best: int = -1
	var best_gain: float = 0.0
	for i: int in run.deck.size():
		var c: CardData = run.deck[i]
		if c.kind != CardData.KIND_ATTACK or not run.can_upgrade_card(i):
			continue
		var up: CardData = run.preview_upgrade(i)
		if up == null:
			continue
		var gain: float = card_value(up) - card_value(c) + 0.01 * float(c.damage)
		if gain > best_gain:
			best_gain = gain
			best = i
	if best >= 0 and run.upgrade_card(best):
		return
	run.rest_heal()


func _item_rating(item: ItemData) -> float:
	var w: Dictionary = cfg["item_effect_weight"]
	var total: float = 0.0
	for e: Dictionary in item.effects:
		total += float(w.get(String(e["type"]), 1.0)) * float(e.get("value", e.get("percent", 1)))
	return total


## Poké Mart: heal potion -> best item -> remove one basic card -> good card -> fill the belt with potions.
func play_mart(run: RunState, shop: ShopInventory) -> void:
	for _guard: int in 30:
		if not _mart_step(run, shop):
			return


func _mart_step(run: RunState, shop: ShopInventory) -> bool:
	# a) a heal potion if the belt holds none
	var has_heal: bool = false
	for p: PotionData in run.potions:
		for e: Dictionary in p.effects:
			if String(e["type"]) in ["heal_flat", "heal_percent_max"]:
				has_heal = true
	if not has_heal:
		var best: int = -1
		for i: int in shop.potions.size():
			if shop.can_buy_potion(i) and _heal_amount_data(shop.potions[i].potion) > 0:
				if best < 0 or shop.potions[i].price < shop.potions[best].price:
					best = i
		if best >= 0:
			return _buy(shop.buy_potion(best))
	# b) best affordable held item
	var best_item: int = -1
	var best_rating: float = float(cfg["mart_min_item_rating"])
	for i: int in shop.items.size():
		if shop.can_buy_item(i):
			var r: float = _item_rating(shop.items[i].item)
			if r > best_rating:
				best_rating = r
				best_item = i
	if best_item >= 0:
		return _buy(shop.buy_item(best_item))
	# c) remove one basic card (once per run)
	if bool(cfg["mart_remove_once"]) and not _removed_once and run.deck.size() > 8:
		var worst: int = -1
		var worst_v: float = INF
		for i: int in run.deck.size():
			var c: CardData = run.deck[i]
			if c.rarity == CardData.RARITY_STARTER and c.kind == CardData.KIND_ATTACK and card_value(c) < worst_v:
				worst_v = card_value(c)
				worst = i
		if worst >= 0 and shop.can_remove_card(worst):
			_removed_once = true
			return _buy(shop.remove_card(worst))
	# d) a good card
	var covered: Dictionary = _covered_types(run.deck)
	var best_card: int = -1
	var best_s: float = float(cfg["mart_buy_card_min_score"])
	if run.deck.size() < int(cfg["max_deck_size"]):
		for i: int in shop.cards.size():
			if shop.can_buy_card(i):
				var s: float = score_card(shop.cards[i].card, run.deck, covered)
				if s >= best_s:
					best_s = s
					best_card = i
	if best_card >= 0:
		return _buy(shop.buy_card(best_card))
	# e) fill the belt
	for i: int in shop.potions.size():
		if shop.can_buy_potion(i):
			return _buy(shop.buy_potion(i))
	return false


func _heal_amount_data(potion: PotionData) -> int:
	for e: Dictionary in potion.effects:
		if String(e["type"]) in ["heal_flat", "heal_percent_max"]:
			return 1
	return 0


func _buy(ok: bool) -> bool:
	if not ok:
		illegal_moves += 1
	return ok


## Option index of an event: the first option that loses neither HP nor a card (else the first).
func choose_event_option(event: Dictionary) -> int:
	var options: Array = event.get("options", [])
	for i: int in options.size():
		var harmful: bool = false
		for e: Variant in (options[i] as Dictionary).get("effects", []):
			if String((e as Dictionary).get("type", "")) in ["lose_hp", "remove_card"]:
				harmful = true
		if not harmful:
			return i
	return 0
