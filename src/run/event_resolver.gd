class_name EventResolver
extends RefCounted
## Picks events and applies their effects to the RunState. Pure logic (the screen is Part B).
## Events never kill: HP stays >= 1. Implements: story-005-carte-acte-1 (events with 2 options).


## A random event definition (copy) from the act's event_pool: {id, title, text, options}. {} if none.
static func pick_event(data: GameData, rng: RandomNumberGenerator) -> Dictionary:
	var ids: Array[String] = data.get_event_pool()
	if ids.is_empty():
		return {}
	return data.get_event(ids[rng.randi_range(0, ids.size() - 1)])


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
			_:
				pass  # "nothing" (unknown types are rejected by GameData validation)
	return ", ".join(parts)


static func _random_card(data: GameData, run: RunState, rarity: String, rng: RandomNumberGenerator) -> CardData:
	var matching: Array[CardData] = []
	for c: CardData in data.get_reward_pool(run.player_id):
		if c.rarity == rarity:
			matching.append(c)
	if matching.is_empty():
		return null
	return matching[rng.randi_range(0, matching.size() - 1)]
