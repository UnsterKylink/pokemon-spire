class_name EventResolver
extends RefCounted
## Picks events and applies their effects to the RunState. Pure logic (the screen is Part B).
## Events never kill: HP stays >= 1. Implements: story-005-carte-acte-1 (events with 2 options).
## Story 018 (story-018-rival-et-evenements): events filtered by zone (min_zone / max_zone), legendary events (rare, at most
## events.json legendary.max_per_run per run, from legendary.min_zone), "{rival}" replaced by the run's rival name, options
## gated by requires_money, and the generic effects listed in events.json _doc (fights are only QUEUED in
## RunState.pending_fight: Main / the simulator start them after the result screen).

const RIVAL_PLACEHOLDER: String = "{rival}"


## A random event definition (copy) from the act's event_pool: {id, title, text, options}. {} if none.
## Story 018: with a `run`, the pool is filtered by the run's zone, and first (zone >= legendary.min_zone, fewer legendary
## events seen than max_per_run, one unseen left) ONE rng roll < legendary.chance picks a legendary event instead (uniform among
## the unseen ones, a second roll); the legendary pick is recorded in run.legendary_seen. "{rival}" is replaced.
static func pick_event(data: GameData, rng: RandomNumberGenerator, run: RunState = null) -> Dictionary:
	var zone_number: int = run.zone_index + 1 if run != null else 0
	if run != null:
		var leg: Dictionary = data.get_legendary_config()
		var unseen: Array[String] = []
		for id: String in data.get_legendary_event_ids():
			if not run.legendary_seen.has(id):
				unseen.append(id)
		if not leg.is_empty() and zone_number >= int(leg["min_zone"]) and run.legendary_seen.size() < int(leg["max_per_run"]) \
				and not unseen.is_empty():
			if rng.randf() < float(leg["chance"]):
				var picked: String = unseen[rng.randi_range(0, unseen.size() - 1)]
				run.legendary_seen.append(picked)
				return _personalise(data.get_event(picked), run)
	var ids: Array[String] = data.get_event_pool_for_zone(zone_number)
	if ids.is_empty():
		return {}
	return _personalise(data.get_event(ids[rng.randi_range(0, ids.size() - 1)]), run)


## Story 018: "{rival}" -> the run's rival name in title, text, labels and result texts.
static func _personalise(ev: Dictionary, run: RunState) -> Dictionary:
	if ev.is_empty():
		return ev
	var rival_name: String = run.rival_name if run != null and not run.rival_name.is_empty() else "Rival"
	for k: String in ["title", "text"]:
		ev[k] = String(ev[k]).replace(RIVAL_PLACEHOLDER, rival_name)
	for o: Dictionary in ev["options"]:
		for k: String in ["label", "result_text"]:
			o[k] = String(o[k]).replace(RIVAL_PLACEHOLDER, rival_name)
	return ev


## Story 018: true if `option` can be chosen now (requires_money <= run.money).
static func option_available(option: Dictionary, run: RunState) -> bool:
	return run == null or run.money >= int(option.get("requires_money", 0))


## Story 018: true for a legendary event dict (pick_event result).
static func is_legendary(event: Dictionary) -> bool:
	return bool(event.get("legendary", false))


## Applies the effects in order (story 017: add_ball gives balls up to the bag limit). Returns a short French summary ("+5 PV max, -5 PV"), "" if nothing changed.
static func apply_effects(effects: Array, run: RunState, data: GameData, rng: RandomNumberGenerator) -> String:
	var parts: Array[String] = []
	for e_v: Variant in effects:
		if not (e_v is Dictionary):
			continue
		var e: Dictionary = e_v
		match String(e.get("type", "")):
			"heal":
				var healed: int = run.heal_percent(float(e.get("percent", 0)))
				if healed > 0:
					parts.append("+%d PV" % healed)
			"lose_hp":
				var lost: int = run.lose_hp(int(e.get("value", 0)))
				if lost > 0:
					parts.append("-%d PV" % lost)
			"gain_max_hp":
				var gain: int = int(e.get("value", 0))
				run.gain_max_hp(gain)
				parts.append("+%d PV max" % gain)
			"add_card":
				var card: CardData = data.get_card(String(e.get("card", "")))
				if card != null:
					run.add_card(card)
					parts.append("Carte obtenue : %s" % card.display_name)
			"add_random_card":
				var picked: CardData = _random_card(data, run, String(e.get("rarity", "")), rng)
				if picked != null:
					run.add_card(picked)
					parts.append("Carte obtenue : %s" % picked.display_name)
			"remove_card":
				var card_id: String = String(e.get("card", ""))
				var removed: CardData = data.get_card(card_id)
				if removed != null and run.remove_card(card_id):
					parts.append("Carte perdue : %s" % removed.display_name)
			"add_ball":
				var ball: BallData = data.get_ball(String(e.get("ball", "")))
				var added: int = 0
				for i: int in int(e.get("count", 1)):
					if ball != null and run.add_ball(ball.id):
						added += 1
				if added == 1:
					parts.append("Ball obtenue : %s" % ball.display_name)
				elif added > 1:
					parts.append("%d Balls obtenues : %s" % [added, ball.display_name])
			"apply_status_next_fight":
				var sid: String = String(e.get("status", ""))
				run.add_pending_status(sid, int(e.get("value", 1)))
				var book: StatusBook = data.get_status_book()
				parts.append("Prochain combat : %s" % (book.name_of(sid) if book != null else sid))
			"cure_all":
				if not run.pending_statuses.is_empty():
					run.pending_statuses.clear()
					parts.append("Statuts soignés")
			"gain_money":
				run.add_money(int(e.get("value", 0)))
				parts.append("+%d ₽" % int(e.get("value", 0)))
			"lose_money":
				var paid: int = mini(run.money, int(e.get("value", 0)))
				run.spend_money(paid)
				if paid > 0:
					parts.append("-%d ₽" % paid)
			"gamble_money":
				var stake: int = int(e.get("stake", 0))
				if run.spend_money(stake):
					if rng.randf() < float(e.get("chance", 0.0)):
						run.add_money(int(e.get("win", 0)))
						parts.append("Gagné ! +%d ₽" % (int(e.get("win", 0)) - stake))
					else:
						parts.append("Perdu : -%d ₽" % stake)
			"upgrade_random_card":
				for i: int in int(e.get("count", 1)):
					var ups: Array[int] = []
					for d: int in run.deck.size():
						if run.can_upgrade_card(d):
							ups.append(d)
					if ups.is_empty():
						break
					var idx: int = ups[rng.randi_range(0, ups.size() - 1)]
					var before: String = run.deck[idx].display_name
					run.upgrade_card(idx)
					parts.append("%s amélioré" % before)
			"add_card_of_type":
				var typed: CardData = _random_card_of_type(data, run, String(e.get("of_type", "any")), String(e.get("rarity", "")), rng)
				if typed != null:
					run.add_card(typed)
					parts.append("Carte obtenue : %s" % typed.display_name)
			"remove_card_choice":
				run.pending_card_removals += int(e.get("count", 1))
				parts.append("Choisis une carte à oublier")
			"add_item_random":
				var pool: Array[ItemData] = []
				for iid: String in data.get_item_ids():
					var it: ItemData = data.get_item(iid)
					if not run.has_item(iid) and String(it.rarity) in (e.get("rarities", []) as Array):
						pool.append(it)
				if not pool.is_empty():
					var got: ItemData = pool[rng.randi_range(0, pool.size() - 1)]
					run.add_item(got)
					parts.append("Objet obtenu : %s" % got.display_name)
			"add_pokemon":
				var eggs: Array[String] = data.get_roster_stage1_ids(int(e.get("tier", 1)))
				if not eggs.is_empty():
					var rows: Array[Dictionary] = run.apply_captures([eggs[rng.randi_range(0, eggs.size() - 1)]] as Array[String])
					for row: Dictionary in rows:
						parts.append("%s rejoint l'équipe" % String(row["name"]))
			"evolve_team_member":
				var row: Dictionary = run.evolve_random_carrier(data, rng)
				if not row.is_empty():
					parts.append("%s évolue en %s" % [String(row["from_name"]), String(row["to_name"])])
			"start_fight":
				run.pending_fight = (e as Dictionary).duplicate(true)
			_:
				pass  # "nothing" (unknown types are rejected by GameData validation)
	return ", ".join(parts)


## Story 018: a random reward-pool card of `of_type` ("player" = the run's primary type, "any", or a type id) and `rarity`;
## attacks are carried by a random carrier of their type (RewardGenerator rule). Falls back to any type, then null.
static func _random_card_of_type(data: GameData, run: RunState, of_type: String, rarity: String,
		rng: RandomNumberGenerator) -> CardData:
	var want: String = of_type
	if of_type == "player":
		want = run.type_ids[0] if not run.type_ids.is_empty() else "any"
	var matching: Array[CardData] = []
	var any_type: Array[CardData] = []
	for c: CardData in data.get_reward_pool(run.player_id):
		if c.rarity != rarity:
			continue
		any_type.append(c)
		if want == "any" or c.type_id == want:
			matching.append(c)
	if matching.is_empty():
		matching = any_type
	if matching.is_empty():
		return null
	var picked: CardData = matching[rng.randi_range(0, matching.size() - 1)]
	if picked.kind == CardData.KIND_ATTACK:
		var carriers: Array[String] = data.get_carriers_for_type(picked.type_id)
		if not carriers.is_empty():
			picked = picked.with_pokemon(carriers[rng.randi_range(0, carriers.size() - 1)])
	return picked


static func _random_card(data: GameData, run: RunState, rarity: String, rng: RandomNumberGenerator) -> CardData:
	var matching: Array[CardData] = []
	for c: CardData in data.get_reward_pool(run.player_id):
		if c.rarity == rarity:
			matching.append(c)
	if matching.is_empty():
		return null
	return matching[rng.randi_range(0, matching.size() - 1)]
