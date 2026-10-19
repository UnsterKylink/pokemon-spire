class_name RewardGenerator
extends RefCounted
## Pure reward logic (no nodes). Implements: story-004-recompenses-vol-attaque, criteria 1-3.
## Offer = [one stolen attack if a defeated enemy teaches any] + cards from the player's pool
## drawn by rarity weight (weights, offer_count and pool all come from rewards.json).


## Returns up to offer_count DISTINCT offers (fewer only if the data cannot supply enough cards).
## The stolen card (if any) is at a random position. Seedable through the injected rng.
## `rarity_weights_override` (non-empty) replaces the rarity weights of rewards.json (elite rooms, story 005).
static func generate(data: GameData, player_id: String, defeated_enemy_ids: Array[String],
		rng: RandomNumberGenerator, rarity_weights_override: Dictionary = {}) -> Array[RewardOffer]:
	var offers: Array[RewardOffer] = []
	var used: Dictionary = {}  # card id -> true
	var count: int = data.get_offer_count()
	# 1. One stolen card among everything the defeated enemies teach.
	var candidates: Array[RewardOffer] = []
	var seen: Dictionary = {}
	for enemy_id: String in defeated_enemy_ids:
		for card: CardData in data.get_enemy_teaches(enemy_id):
			if not seen.has(card.id):
				seen[card.id] = true
				candidates.append(RewardOffer.make(card.with_pokemon(enemy_id), true, data.get_enemy_name(enemy_id)))
	if not candidates.is_empty() and count > 0:
		var stolen: RewardOffer = candidates[rng.randi_range(0, candidates.size() - 1)]
		offers.append(stolen)
		used[stolen.card.id] = true
	# 2. Remaining slots from the pool: weighted rarity, then uniform inside the rarity.
	var pool: Array[CardData] = data.get_reward_pool(player_id)
	var weights: Dictionary = data.get_rarity_weights() if rarity_weights_override.is_empty() else rarity_weights_override
	while offers.size() < count:
		var buckets: Dictionary = {}  # rarity -> Array[CardData]
		var rest: Array[CardData] = []
		for card: CardData in pool:
			if used.has(card.id):
				continue
			rest.append(card)
			if weights.has(card.rarity):
				if not buckets.has(card.rarity):
					buckets[card.rarity] = []
				(buckets[card.rarity] as Array).append(card)
		var picked: CardData = null
		if not buckets.is_empty():
			var rarities: Array = buckets.keys()
			rarities.sort()
			var total: float = 0.0
			for r: String in rarities:
				total += float(weights[r])
			var roll: float = rng.randf() * total
			var chosen: String = rarities[rarities.size() - 1]
			for r: String in rarities:
				if roll < float(weights[r]):
					chosen = r
					break
				roll -= float(weights[r])
			var bucket: Array = buckets[chosen]
			picked = bucket[rng.randi_range(0, bucket.size() - 1)]
		elif not rest.is_empty():
			picked = rest[rng.randi_range(0, rest.size() - 1)]  # graceful fallback
		if picked == null:
			break
		used[picked.id] = true
		# Story 010: an attack is carried by a random roster Pokémon having its type (default carrier if none).
		if picked.kind == CardData.KIND_ATTACK:
			var carriers: Array[String] = data.get_carriers_for_type(picked.type_id)
			if not carriers.is_empty():
				picked = picked.with_pokemon(carriers[rng.randi_range(0, carriers.size() - 1)])
		offers.append(RewardOffer.make(picked))
	# 3. Shuffle so the stolen card is not always first (Fisher-Yates, injected rng).
	for i: int in range(offers.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: RewardOffer = offers[i]
		offers[i] = offers[j]
		offers[j] = tmp
	return offers
