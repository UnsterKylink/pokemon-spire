class_name Combatant
extends RefCounted
## A fighter (player Pokémon or enemy) with HP and block.

signal changed

var id: String = ""
var display_name: String = ""
var sprite_path: String = ""
var max_hp: int = 1
var hp: int = 1
var block: int = 0
## Fixed attack damage (enemies only; 0 for the player).
var attack_damage: int = 0


## Creates a combatant from a JSON definition. Returns null if invalid.
static func from_dict(combatant_id: String, d: Dictionary) -> Combatant:
	for key: String in ["name", "max_hp", "sprite"]:
		if not d.has(key):
			push_error("Combatant: '%s' is missing field '%s'" % [combatant_id, key])
			return null
	var c := Combatant.new()
	c.id = combatant_id
	c.display_name = String(d["name"])
	c.max_hp = int(d["max_hp"])
	c.hp = c.max_hp
	c.sprite_path = String(d["sprite"])
	c.attack_damage = int(d.get("attack_damage", 0))
	return c


## Applies damage: block absorbs first, remainder reduces HP (min 0). Returns HP actually lost.
func take_damage(amount: int) -> int:
	var remaining: int = maxi(amount, 0)
	var absorbed: int = mini(block, remaining)
	block -= absorbed
	remaining -= absorbed
	var hp_lost: int = mini(hp, remaining)
	hp -= hp_lost
	changed.emit()
	return hp_lost


## Adds block points.
func add_block(amount: int) -> void:
	block += maxi(amount, 0)
	changed.emit()


## Removes all block (called at the start of the player's turn).
func reset_block() -> void:
	block = 0
	changed.emit()


## True while HP > 0.
func is_alive() -> bool:
	return hp > 0
