class_name CaptureRules
extends RefCounted
## Pure capture rules (assets/data/balls.json "capture"). Implements: story-017-capture.
## chance = clamp(ball.base_chance x (1 - hp_ratio x hp_factor) x status_bonus, min_chance, max_chance), where hp_ratio is the
## target's remaining HP / max HP and status_bonus the BEST multiplier among the target's statuses (1 without status).

## Energy a ball throw costs.
var energy_cost: int = 1
## `k` of the formula: how much full HP lowers the chance (0..1).
var hp_factor: float = 0.0
var min_chance: float = 0.0
var max_chance: float = 1.0
## status id -> multiplier (>= 1).
var status_bonus: Dictionary = {}
## Fight room types where balls can be used (act1.json room ids, e.g. "wild"; the league is never listed).
var allowed_room_types: Array[String] = []


## Builds the rules from JSON; `status_ids` / `room_ids` are the valid ids (statuses.json, fight room types).
## Null (after push_error) if invalid.
static func from_dict(d: Dictionary, status_ids: Array[String], room_ids: Array[String]) -> CaptureRules:
	var r := CaptureRules.new()
	var cost_v: Variant = d.get("energy_cost", null)
	if not ((cost_v is int or cost_v is float) and cost_v >= 0 and cost_v == floorf(cost_v)):
		push_error("CaptureRules: capture.energy_cost must be an integer >= 0")
		return null
	r.energy_cost = int(cost_v)
	var k_v: Variant = d.get("hp_factor", null)
	if not ((k_v is int or k_v is float) and k_v >= 0 and k_v <= 1):
		push_error("CaptureRules: capture.hp_factor must be between 0 and 1")
		return null
	r.hp_factor = float(k_v)
	var lo_v: Variant = d.get("min_chance", null)
	var hi_v: Variant = d.get("max_chance", null)
	if not ((lo_v is int or lo_v is float) and (hi_v is int or hi_v is float) and lo_v >= 0 and hi_v <= 1 and lo_v <= hi_v):
		push_error("CaptureRules: capture needs 0 <= min_chance <= max_chance <= 1")
		return null
	r.min_chance = float(lo_v)
	r.max_chance = float(hi_v)
	var sb: Variant = d.get("status_bonus", null)
	if not (sb is Dictionary):
		push_error("CaptureRules: capture.status_bonus must be an object {status id: multiplier}")
		return null
	for sid: String in (sb as Dictionary).keys():
		var m: Variant = (sb as Dictionary)[sid]
		if sid not in status_ids or not ((m is int or m is float) and m >= 1):
			push_error("CaptureRules: capture.status_bonus['%s'] needs a known status id and a multiplier >= 1" % sid)
			return null
		r.status_bonus[sid] = float(m)
	var rooms: Variant = d.get("allowed_room_types", null)
	if not (rooms is Array):
		push_error("CaptureRules: capture.allowed_room_types must be an array of fight room types")
		return null
	for room: Variant in (rooms as Array):
		if not (room is String) or String(room) not in room_ids:
			push_error("CaptureRules: capture.allowed_room_types has an invalid room type '%s'" % str(room))
			return null
		r.allowed_room_types.append(String(room))
	return r


## True if balls may be used in fights of `room_type`.
func allows_room(room_type: String) -> bool:
	return room_type in allowed_room_types


## Best status multiplier among `status_ids` (1.0 if none counts).
func status_multiplier(status_ids: Array[String]) -> float:
	var best: float = 1.0
	for sid: String in status_ids:
		best = maxf(best, float(status_bonus.get(sid, 1.0)))
	return best


## Capture chance (0..1) of `ball` against a target with hp/max_hp and the given status ids.
func chance(ball: BallData, hp: int, max_hp: int, status_ids: Array[String]) -> float:
	var ratio: float = clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var raw: float = ball.base_chance * (1.0 - ratio * hp_factor) * status_multiplier(status_ids)
	return clampf(raw, min_chance, max_chance)
