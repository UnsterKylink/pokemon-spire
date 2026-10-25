class_name SpecialFights
extends RefCounted
## Story 018 (story-018-rival-et-evenements): builds and rewards the special fights -- the rival (map room 'rival' of the
## zones listed in rival.json, and the automatic pre-league fight) and the fights queued by events (start_fight: wild / elite
## fights, the rival's starter alone, legendary fights). Pure logic shared by Main and tools/balance/sim_run.gd so both
## run the exact same calls (same RNG draws). Every number comes from rival.json / events.json / zones.json.
##
## A "fight" dict: {kind: "rival" | "rival_final" | "event", room: the Main._fight_room_type to use ("rival",
## "rival_final", "wild", "elite", "legendary"), encounter: id (generated "roster:..." for rival teams), modifiers
## {hp_multiplier, strength_bonus}, enemies: Array[Combatant], rival_def: the rival.json encounter ({} otherwise),
## legendary_id: the legendary Pokémon id ("" otherwise), title: French header (e.g. "Rival Régis"), capture: bool}.


## The rival fight of the CURRENT zone's 'rival' room (rival.json kind "room" for this zone number, not won yet), drawn with
## `rng` (Main: the encounter rng). {} if there is none.
static func rival_room_fight(data: GameData, run: RunState, rng: RandomNumberGenerator) -> Dictionary:
	var def: Dictionary = data.get_rival_encounter_for_zone(run.zone_index + 1, "room")
	if def.is_empty() or run.rival_starter_id.is_empty() or run.rival_done(String(def["id"])):
		return {}
	return _rival_fight(data, run, def, GameData.ROOM_RIVAL, rng)


## The automatic pre-league rival fight (rival.json kind "pre_league"), if it exists and is not won yet; {} otherwise.
static func rival_final_fight(data: GameData, run: RunState, rng: RandomNumberGenerator) -> Dictionary:
	var def: Dictionary = data.get_rival_encounter_for_zone(data.get_zone_count(), "pre_league")
	if def.is_empty() or run.rival_starter_id.is_empty() or run.rival_done(String(def["id"])):
		return {}
	return _rival_fight(data, run, def, GameData.ROOM_RIVAL_FINAL, rng)


static func _rival_fight(data: GameData, run: RunState, def: Dictionary, room: String, rng: RandomNumberGenerator) -> Dictionary:
	var encounter: String = data.build_rival_team(def, run.rival_starter_id, run.badges.size(), rng, data.deck_attack_types(run.deck))
	var mods: Dictionary = data.get_rival_fight_modifiers(def, run.current_zone())
	var enemies: Array[Combatant] = data.create_enemies(encounter, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
	return {"kind": room, "room": room, "encounter": encounter, "modifiers": mods, "enemies": enemies, "rival_def": def,
			"legendary_id": "", "title": "Rival %s" % run.rival_name, "capture": false}


## After a won rival fight: records it, pays rival.json reward.money and gives ONE held item of reward.item_rarities the run
## does not own (uniform, `rng`: Main's loot rng; none if every such item is owned). Returns the RunState.apply_loot format
## {money, item: ItemData|null, potion: null, ball: null}.
static func apply_rival_win(data: GameData, run: RunState, def: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	run.mark_rival_done(String(def["id"]))
	var reward: Dictionary = def["reward"]
	var result: Dictionary = {"money": int(reward["money"]), "item": null, "potion": null, "ball": null}
	run.add_money(int(reward["money"]))
	var pool: Array[ItemData] = []
	for iid: String in data.get_item_ids():
		var it: ItemData = data.get_item(iid)
		if not run.has_item(iid) and String(it.rarity) in (reward["item_rarities"] as Array):
			pool.append(it)
	if not pool.is_empty():
		var got: ItemData = pool[rng.randi_range(0, pool.size() - 1)]
		if run.add_item(got):
			result["item"] = got
	return result


## The card offers after a won rival fight: reward.card_rarity_weights, reward.card_count cards (default offer_count), the
## stolen card only if reward.offer_stolen_card (the final encounter: 3 rare cards).
static func rival_reward_offers(data: GameData, run: RunState, def: Dictionary, defeated_ids: Array[String],
		rng: RandomNumberGenerator) -> Array[RewardOffer]:
	var reward: Dictionary = def["reward"]
	var steal: Array[String] = defeated_ids if bool(reward["offer_stolen_card"]) else ([] as Array[String])
	return RewardGenerator.generate(data, run.player_id, steal, rng, reward["card_rarity_weights"], int(reward.get("card_count", -1)))


## The fight queued by an event (RunState.pending_fight, start_fight effect) -- consumed here (pending_fight is cleared).
## room wild / elite: that room's zone modifiers x the effect's; legendary: GameData.get_legendary_fight_modifiers;
## source rival_starter: the rival's current form alone. pre_status entries are queued for that battle
## (RunState.pending_statuses). `rng` (Main: the encounter rng) is only drawn by generated teams. {} if nothing is pending.
static func event_fight(data: GameData, run: RunState, rng: RandomNumberGenerator) -> Dictionary:
	var spec: Dictionary = run.pending_fight
	run.pending_fight = {}
	if spec.is_empty():
		return {}
	var room: String = String(spec["room"])
	var encounter: String = String(spec.get("encounter", ""))
	var title: String = ""
	if String(spec["source"]) == "rival_starter":
		var form: String = run.rival_current_form(data)
		if form.is_empty():
			return {}
		encounter = GameData.ROSTER_ENCOUNTER_PREFIX + form
		title = "Rival %s" % run.rival_name
	var m: Dictionary = spec["modifiers"]
	var mods: Dictionary = {}
	if room == GameData.ROOM_LEGENDARY:
		mods = data.get_legendary_fight_modifiers(m, run.current_zone())
	else:
		var zm: Dictionary = data.get_fight_modifiers(room, run.current_zone())
		mods = {"hp_multiplier": float(zm["hp_multiplier"]) * float(m["hp_multiplier"]),
				"strength_bonus": int(zm["strength_bonus"]) + int(m["strength_bonus"])}
	for st: Variant in spec.get("pre_status", []):
		run.add_pending_status(String((st as Dictionary)["id"]), int((st as Dictionary)["value"]))
	var enemies: Array[Combatant] = data.create_enemies(encounter, float(mods["hp_multiplier"]), int(mods["strength_bonus"]))
	var legendary_id: String = ""
	if room == GameData.ROOM_LEGENDARY and not enemies.is_empty():
		legendary_id = enemies[0].id
		title = "%s — Pokémon légendaire" % enemies[0].display_name
	return {"kind": "event", "room": room, "encounter": encounter, "modifiers": mods, "enemies": enemies, "rival_def": {},
			"legendary_id": legendary_id, "title": title, "capture": data.capture_allowed_in(room)}


## After a won legendary fight: the legendary's unique card(s) (its `teaches`, carried by it) join the deck -- unless it was
## CAPTURED (RunState.apply_captures already added them). Returns {pokemon_id, name, captured: bool, cards: Array[CardData]}.
static func apply_legendary_win(data: GameData, run: RunState, legendary_id: String, captured_ids: Array[String]) -> Dictionary:
	var captured: bool = captured_ids.has(legendary_id)
	var cards: Array[CardData] = []
	for card: CardData in data.get_enemy_teaches(legendary_id):
		var carried: CardData = card.with_pokemon(legendary_id)
		if not captured:
			run.add_card(carried)
		cards.append(carried)
	return {"pokemon_id": legendary_id, "name": data.get_enemy_name(legendary_id), "captured": captured, "cards": cards}
