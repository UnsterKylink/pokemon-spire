class_name Combatant
extends RefCounted
## A fighter (player Pokémon or enemy) with HP, block and (enemies) a data-driven behaviour.

signal changed

const PATTERN_SEQUENCE: String = "sequence"
const PATTERN_WEIGHTED: String = "weighted"

var id: String = ""
var display_name: String = ""
var sprite_path: String = ""
## Type ids from types.json (story 003/008): 1 or 2 entries; empty = typeless (always neutral).
var type_ids: Array[String] = []
## Player only (story 009): id of the Pokémon currently on the field ("" for enemies / not set).
var active_pokemon_id: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0
## Bonus added to all this combatant's attack values (gained through "buff" actions).
var strength: int = 0
## Enemy behaviour: "sequence" or "weighted" (empty for the player).
var pattern: String = ""
## Possible enemy actions, from data (empty for the player).
var actions: Array[EnemyIntent] = []
## Next action this enemy will execute (null for the player and for dead enemies).
var intent: EnemyIntent = null
## Position in the action list for the "sequence" pattern.
var sequence_index: int = 0


## Creates a combatant from a JSON definition. Returns null if invalid.
## current_hp < 0 means full HP; otherwise it is clamped to 0..max_hp (persistent run HP, story 004).
static func from_dict(combatant_id: String, d: Dictionary, current_hp: int = -1) -> Combatant:
	for key: String in ["name", "max_hp", "sprite"]:
		if not d.has(key):
			push_error("Combatant: '%s' is missing field '%s'" % [combatant_id, key])
			return null
	var c := Combatant.new()
	c.id = combatant_id
	c.display_name = String(d["name"])
	c.max_hp = int(d["max_hp"])
	c.hp = c.max_hp if current_hp < 0 else clampi(current_hp, 0, c.max_hp)
	c.sprite_path = String(d["sprite"])
	var raw_types: Variant = d.get("types", null)
	if raw_types is Array:
		for t: Variant in (raw_types as Array):
			c.type_ids.append(String(t))
	elif d.has("type"):  # tolerated for hand-built test definitions; GameData requires "types"
		c.type_ids.append(String(d["type"]))
	if d.has("pattern"):
		c.pattern = String(d["pattern"])
		if c.pattern != PATTERN_SEQUENCE and c.pattern != PATTERN_WEIGHTED:
			push_error("Combatant: '%s' has unknown pattern '%s'" % [combatant_id, c.pattern])
			return null
		var raw_actions: Variant = d.get("actions", null)
		if not (raw_actions is Array) or (raw_actions as Array).is_empty():
			push_error("Combatant: '%s' needs a non-empty 'actions' array" % combatant_id)
			return null
		for raw: Variant in (raw_actions as Array):
			if not (raw is Dictionary):
				push_error("Combatant: '%s' has a non-object action" % combatant_id)
				return null
			var action: EnemyIntent = EnemyIntent.from_dict(raw)
			if action == null:
				return null
			c.actions.append(action)
	return c


## Changes the displayed identity (name, sprite, types) WITHOUT touching HP, block or strength.
func set_active_pokemon(pokemon_id: String, new_display_name: String, new_sprite_path: String, types: Array[String]) -> void:
	active_pokemon_id = pokemon_id
	display_name = new_display_name
	sprite_path = new_sprite_path
	type_ids = types.duplicate()
	changed.emit()


## First type id ("" if typeless); kept for single-type callers (display, old tests).
func get_primary_type() -> String:
	return type_ids[0] if not type_ids.is_empty() else ""


## Applies damage: block absorbs first, remainder reduces HP (min 0). Returns HP actually lost.
## 0 damage changes nothing (block untouched, no change signal).
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var remaining: int = maxi(amount, 0)
	var absorbed: int = mini(block, remaining)
	block -= absorbed
	remaining -= absorbed
	var hp_lost: int = mini(hp, remaining)
	hp -= hp_lost
	changed.emit()
	return hp_lost


## Restores up to `amount` HP (never above max HP). Returns the HP actually restored.
func heal(amount: int) -> int:
	var before: int = hp
	hp = mini(max_hp, hp + maxi(amount, 0))
	if hp != before:
		changed.emit()
	return hp - before


## Adds block points.
func add_block(amount: int) -> void:
	block += maxi(amount, 0)
	changed.emit()


## Removes all block (player: start of its turn; enemy: start of its action).
func reset_block() -> void:
	block = 0
	changed.emit()


## True while HP > 0.
func is_alive() -> bool:
	return hp > 0
