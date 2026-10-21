class_name ItemEffects
extends RefCounted
## Stateless helpers applying the generic effects of held items / potions. Used by Battle and RunState.
## Implements: story-006-objets-et-services (generic triggers, no per-item code).


## Applies one heal_flat / heal_percent_max / block_flat effect to a Combatant.
## Returns the HP restored or block gained (0 = nothing happened or not a combatant effect).
static func apply_to_combatant(effect: Dictionary, target: Combatant) -> int:
	match String(effect.get("type", "")):
		"heal_flat":
			return target.heal(int(effect["value"]))
		"heal_percent_max":
			return target.heal(ceili(target.max_hp * float(effect["percent"]) / 100.0))
		"block_flat":
			target.add_block(int(effect["value"]))
			return int(effect["value"])
	return 0


## Sum of an effect type over all passive items (draw_up, energy_up_per_turn).
static func passive_total(items: Array[ItemData], effect_type: String) -> int:
	var sum: int = 0
	for item: ItemData in items:
		if item.trigger == ItemData.TRIGGER_PASSIVE:
			sum += item.total(effect_type)
	return sum


## Pokédollars added to a win by battle_end items (money_bonus_on_win).
static func win_money_bonus(items: Array[ItemData]) -> int:
	var sum: int = 0
	for item: ItemData in items:
		if item.trigger == ItemData.TRIGGER_BATTLE_END:
			sum += item.total("money_bonus_on_win")
	return sum


## card_played items adding damage to this attack. `attacks_played` = attack cards already played this battle.
static func damage_bonus_sources(items: Array[ItemData], card: CardData, attacks_played: int) -> Array[ItemData]:
	var result: Array[ItemData] = []
	if card.kind != CardData.KIND_ATTACK or card.damage <= 0:
		return result
	for item: ItemData in items:
		if item.trigger != ItemData.TRIGGER_CARD_PLAYED or item.total("damage_bonus") <= 0:
			continue
		if item.first_attack_each_battle and attacks_played > 0:
			continue
		result.append(item)
	return result
