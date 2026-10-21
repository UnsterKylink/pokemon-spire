class_name RunState
extends RefCounted
## The player's persistent state for one run (HP and deck survive from battle to battle).
## Pure logic, no Node access. Implements: story-004-recompenses-vol-attaque, criterion 4.

var player_id: String = ""
var display_name: String = ""
var type_ids: Array[String] = []
var sprite_path: String = ""
var max_hp: int = 1
var hp: int = 1
var energy_per_turn: int = 0
var hand_size: int = 0
## The run's own copy of the deck (never the shared starter definition).
var deck: Array[CardData] = []
var battles_won: int = 0
## Pokédollars (story 006).
var money: int = 0
## Held items owned, in pickup order (permanent, no duplicates).
var items: Array[ItemData] = []
## Potions carried (single use, at most max_potions()).
var potions: Array[PotionData] = []
## Cards removed at the Poké Mart so far this run (drives the rising removal price).
var card_removals: int = 0
var _data: GameData
## Pokémon on the field at the start of every battle (GameData.get_starter_pokemon_id, story 009).
var starter_pokemon_id: String = ""
var _pokemon_infos: Dictionary = {}  # pokemon id -> info dict (GameData.get_pokemon_info)
## Progress on the act map (null until start_act is called).
var act: ActProgress = null


## Starts a run from the player's data: full HP, starter deck copy. Null if the id is unknown.
static func create(data: GameData, new_player_id: String) -> RunState:
	var def: Dictionary = data.get_player_definition(new_player_id)
	if def.is_empty():
		return null
	var r := RunState.new()
	r.player_id = new_player_id
	r.display_name = String(def.get("name", ""))
	var raw_types: Variant = def.get("types", [])
	if raw_types is Array:
		for t: Variant in (raw_types as Array):
			r.type_ids.append(String(t))
	r.sprite_path = String(def.get("sprite", ""))
	r.max_hp = int(def.get("max_hp", 1))
	r.hp = r.max_hp
	r.energy_per_turn = int(def.get("energy_per_turn", 0))
	r.hand_size = int(def.get("hand_size", 0))
	r.deck = data.get_starter_deck(new_player_id)  # fresh array each call
	r.starter_pokemon_id = data.get_starter_pokemon_id()
	for pid: String in data.get_pokemon_ids():
		r._pokemon_infos[pid] = data.get_pokemon_info(pid)
	r._init_services(data)
	return r


## Starts a run with the chosen starter (story 010): deck = GameData.build_starter_deck(starter), identity
## (name, types, sprite) from the starter's entry, max HP / energy / hand size from the shared player config
## (GameData.get_default_player_id). Null if the starter or the shared config is unknown.
static func create_with_starter(data: GameData, starter_id: String) -> RunState:
	var info: Dictionary = data.get_pokemon_info(starter_id)
	var shared: Dictionary = data.get_player_definition(data.get_default_player_id())
	if info.is_empty() or shared.is_empty():
		push_error("RunState: unknown starter '%s' or missing shared player config" % starter_id)
		return null
	var deck: Array[CardData] = data.build_starter_deck(starter_id)
	if deck.is_empty():
		return null
	var r := RunState.new()
	r.player_id = data.get_default_player_id()
	r.display_name = String(info["name"])
	r.type_ids.assign(info["types"])
	r.sprite_path = String(info["sprite_path"])
	r.max_hp = int(shared.get("max_hp", 1))
	r.hp = r.max_hp
	r.energy_per_turn = int(shared.get("energy_per_turn", 0))
	r.hand_size = int(shared.get("hand_size", 0))
	r.deck = deck
	r.starter_pokemon_id = starter_id
	for pid: String in data.get_pokemon_ids():
		r._pokemon_infos[pid] = data.get_pokemon_info(pid)
	r._init_services(data)
	return r


func _init_services(data: GameData) -> void:
	_data = data
	money = data.get_starting_money()


## Adds a reward card to the deck.
func add_card(card: CardData) -> void:
	if card != null:
		deck.append(card)


## A fresh player Combatant with the persisted HP (block 0).
func build_player_combatant() -> Combatant:
	var c := Combatant.new()
	c.id = player_id
	c.display_name = display_name
	c.sprite_path = sprite_path
	c.type_ids = type_ids.duplicate()
	c.max_hp = max_hp
	c.hp = clampi(hp, 0, max_hp)
	c.active_pokemon_id = starter_pokemon_id
	var info: Dictionary = get_pokemon_info(starter_pokemon_id)
	if not info.is_empty():
		c.set_active_pokemon(starter_pokemon_id, String(info["name"]), String(info["sprite_path"]), info["types"])
	return c


## Pokémon info {id, name, sprite_path, types} for any player/enemy id (empty if unknown); Battle's lookup.
func get_pokemon_info(pokemon_id: String) -> Dictionary:
	return (_pokemon_infos.get(pokemon_id, {}) as Dictionary).duplicate()


## Builds a battle from the persisted state; the battle gets a COPY of the deck.
## Held items and potions are handed to the battle; passive items raise the energy / hand size it is built with.
## Drinking a potion in the battle also removes it from `potions` (kept in sync through potion_used).
func create_battle(enemies: Array[Combatant], type_chart: TypeChart, rng: RandomNumberGenerator) -> Battle:
	var battle := Battle.new(build_player_combatant(), enemies, deck.duplicate(), effective_energy_per_turn(),
			effective_hand_size(), rng, type_chart, get_pokemon_info, starter_pokemon_id, items, potions)
	battle.potion_used.connect(_on_battle_potion_used)
	return battle


## Energy per turn including the (single) energy_up_per_turn item.
func effective_energy_per_turn() -> int:
	return energy_per_turn + ItemEffects.passive_total(items, "energy_up_per_turn")


## Cards drawn per turn including draw_up items.
func effective_hand_size() -> int:
	return hand_size + ItemEffects.passive_total(items, "draw_up")


func _on_battle_potion_used(potion: PotionData) -> void:
	for i: int in potions.size():
		if potions[i].id == potion.id:
			potions.remove_at(i)
			return


## Copies the player's HP back after a battle (clamped 0..max_hp). A surviving player = a battle won.
func record_battle_result(player: Combatant) -> void:
	hp = clampi(player.hp, 0, max_hp)
	if hp > 0:
		battles_won += 1


## CardData.deck_key() ("card@pokemon") -> copies in the deck.
func deck_counts() -> Dictionary:
	var counts: Dictionary = {}
	for c: CardData in deck:
		counts[c.deck_key()] = int(counts.get(c.deck_key(), 0)) + 1
	return counts


## Deck grouped for display: [{"card": CardData, "count": int}], sorted by card name.
func get_deck_entries() -> Array[Dictionary]:
	var by_id: Dictionary = {}
	var entries: Array[Dictionary] = []
	for c: CardData in deck:
		if by_id.has(c.deck_key()):
			by_id[c.deck_key()]["count"] = int(by_id[c.deck_key()]["count"]) + 1
		else:
			var e: Dictionary = {"card": c, "count": 1}
			by_id[c.deck_key()] = e
			entries.append(e)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["card"] as CardData).display_name.naturalnocasecmp_to((b["card"] as CardData).display_name) < 0)
	return entries


## Generates the act map and starts progress on it (seed 0 = random; graph.seed holds the used seed).
## Returns false if `data` has no valid act config.
func start_act(data: GameData, act_seed: int = 0) -> bool:
	var config: Dictionary = data.get_act_config()
	if config.is_empty():
		push_error("RunState: no act config loaded")
		return false
	act = ActProgress.create(MapGenerator.generate(config, act_seed))
	return true


## Heals `percent` % of max HP (rounded up), never above max HP. Returns the HP actually restored.
func heal_percent(percent: float) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + ceili(max_hp * percent / 100.0))
	return hp - before


## Loses up to `amount` HP but never goes below `min_hp` (events never kill: default 1).
## Returns the HP actually lost.
func lose_hp(amount: int, min_hp: int = 1) -> int:
	var before: int = hp
	hp = maxi(mini(hp, min_hp), hp - maxi(amount, 0))
	return before - hp


## Raises max HP by `amount` and current HP by the same amount.
func gain_max_hp(amount: int) -> void:
	var a: int = maxi(amount, 0)
	max_hp += a
	hp += a


## Removes ONE copy of the card from the deck. False (no change) if the deck has none.
func remove_card(card_id: String) -> bool:
	for i: int in deck.size():
		if deck[i].id == card_id:
			deck.remove_at(i)
			return true
	return false


# --- Money, items, potions (story 006) -------------------------------------------------------------

## Adds Pokédollars (negative amounts are ignored).
func add_money(amount: int) -> void:
	money += maxi(amount, 0)


## Pays `amount` Pokédollars. False (nothing changes) if the run cannot afford it.
func spend_money(amount: int) -> bool:
	if amount < 0 or amount > money:
		return false
	money -= amount
	return true


## True if the item is already owned.
func has_item(item_id: String) -> bool:
	for it: ItemData in items:
		if it.id == item_id:
			return true
	return false


## Gives a held item and applies its on_pickup effects (max_hp_up raises max AND current HP; heal_*).
## False (nothing changes) for null or an item already owned.
func add_item(item: ItemData) -> bool:
	if item == null or has_item(item.id):
		return false
	items.append(item)
	if item.trigger == ItemData.TRIGGER_ON_PICKUP:
		for e: Dictionary in item.effects:
			match String(e["type"]):
				"max_hp_up":
					gain_max_hp(int(e["value"]))
				"heal_flat":
					hp = mini(max_hp, hp + int(e["value"]))
				"heal_percent_max":
					heal_percent(float(e["percent"]))
	return true


## Max number of potions carried (potions.json).
func max_potions() -> int:
	return _data.get_max_potions() if _data != null else 0


## Stores a potion. False (nothing changes) if null or the belt is full.
func add_potion(potion: PotionData) -> bool:
	if potion == null or potions.size() >= max_potions():
		return false
	potions.append(potion)
	return true


## Applies Main's loot dict (LootGenerator.generate) and reports what the player actually got:
## {"money": int, "item": ItemData or null, "potion": PotionData or null} (null = none, or no room for the potion).
func apply_loot(loot: Dictionary) -> Dictionary:
	var result: Dictionary = {"money": int(loot.get("money", 0)), "item": null, "potion": null}
	add_money(result["money"])
	var item_id: String = String(loot.get("item_id", ""))
	if not item_id.is_empty():
		var item: ItemData = _data.get_item(item_id)
		if add_item(item):
			result["item"] = item
	var potion_id: String = String(loot.get("potion_id", ""))
	if not potion_id.is_empty():
		var potion: PotionData = _data.get_potion(potion_id)
		if add_potion(potion):
			result["potion"] = potion
	return result


# --- Centre Pokémon / Poké Mart services (story 006) ------------------------------------------------

## Centre Pokémon "se soigner": heals act1.json room_types.center.heal_percent % of max HP (rounded up).
## Returns the HP actually restored.
func rest_heal() -> int:
	return heal_percent(float(_data.get_room_type("center").get("heal_percent", 0)))


## HP that rest_heal() would restore now (display only, nothing changes).
func rest_heal_preview() -> int:
	return mini(max_hp - hp, ceili(max_hp * rest_heal_percent() / 100.0))


## The Centre's heal rule: % of max HP (act1.json room_types.center.heal_percent).
func rest_heal_percent() -> float:
	return float(_data.get_room_type("center").get("heal_percent", 0))


## True if deck[deck_index] exists and can still be improved (not already upgraded, rule changes something).
func can_upgrade_card(deck_index: int) -> bool:
	return deck_index >= 0 and deck_index < deck.size() and deck[deck_index].can_upgrade(_data.get_upgrade_rules())


## Centre Pokémon "améliorer": replaces deck[deck_index] by its upgraded copy (once per card). False if impossible.
func upgrade_card(deck_index: int) -> bool:
	if not can_upgrade_card(deck_index):
		return false
	deck[deck_index] = deck[deck_index].upgraded_copy(_data.get_upgrade_rules())
	return true


## Preview of the upgrade of deck[deck_index] (the CardData it would become), null if impossible. Does not change the deck.
func preview_upgrade(deck_index: int) -> CardData:
	if deck_index < 0 or deck_index >= deck.size():
		return null
	return deck[deck_index].upgraded_copy(_data.get_upgrade_rules())


## Price of the next Poké Mart card removal: base_price + price_step per removal already made this run.
func removal_price() -> int:
	var cfg: Dictionary = _data.get_removal_config()
	return int(cfg["base_price"]) + int(cfg["price_step"]) * card_removals
