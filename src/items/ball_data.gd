class_name BallData
extends RefCounted
## Immutable definition of a Poké Ball type (assets/data/balls.json). Consumed by Battle.use_ball.
## Implements: story-017-capture.

var id: String = ""
var display_name: String = ""
var description: String = ""
## Pokédollars at the Poké Mart.
var price: int = 0
## `ball_base` of the capture formula (CaptureRules.chance); may exceed 1 (the result is clamped).
var base_chance: float = 0.0
## First zone (1-based) where the ball can be found as loot / on sale at the Mart.
var min_zone: int = 1


## Builds a BallData from JSON; null (after push_error) if invalid.
static func from_dict(ball_id: String, d: Dictionary) -> BallData:
	for key: String in ["name", "description", "price", "base_chance", "min_zone"]:
		if not d.has(key):
			push_error("BallData: ball '%s' is missing field '%s'" % [ball_id, key])
			return null
	var b := BallData.new()
	b.id = ball_id
	if not (d["name"] is String) or String(d["name"]).is_empty() or not (d["description"] is String):
		push_error("BallData: ball '%s' needs a non-empty text 'name' and a text 'description'" % ball_id)
		return null
	b.display_name = String(d["name"])
	b.description = String(d["description"])
	var price_v: Variant = d["price"]
	if not ((price_v is int or price_v is float) and price_v >= 0 and price_v == floorf(price_v)):
		push_error("BallData: ball '%s' needs an integer price >= 0" % ball_id)
		return null
	b.price = int(price_v)
	var base_v: Variant = d["base_chance"]
	if not ((base_v is int or base_v is float) and base_v > 0):
		push_error("BallData: ball '%s' needs a base_chance > 0" % ball_id)
		return null
	b.base_chance = float(base_v)
	var zone_v: Variant = d["min_zone"]
	if not ((zone_v is int or zone_v is float) and zone_v >= 1 and zone_v == floorf(zone_v)):
		push_error("BallData: ball '%s' needs an integer min_zone >= 1" % ball_id)
		return null
	b.min_zone = int(zone_v)
	return b
