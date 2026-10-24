class_name StatusData
extends RefCounted
## Immutable definition of a status ailment (assets/data/statuses.json). All rules/values are data; Battle
## interprets the generic fields (no per-status code). Implements: story-016-statuts.

var id: String = ""
var display_name: String = ""
## Short icon label ("PSN") and colour for the UI.
var short: String = ""
var color: Color = Color.WHITE
var description: String = ""
## End of the carrier's turn: deals `value` damage (ignores block).
var tick_damage: bool = false
## Value lost after each tick (status removed at <= 0); 0 = value never decays.
var value_decay: int = 0
## Turns the status lasts (-1 per end-of-turn tick, refreshed when re-applied unless refresh_on_reapply is false); 0 = not turn-limited.
var duration: int = 0
## True (default): re-applying an active status refreshes its turns (and adds the value if stackable).
## False: re-applying it while it is active changes nothing (paralysis cannot be extended).
var refresh_on_reapply: bool = true
## True: re-applying adds the values; false: the value stays 1.
var stackable: bool = false
## The carrier's attacks deal this much less damage (before the type multiplier).
var attack_penalty: int = 0
## Turns lost (an enemy skips its whole action; the player loses player_energy_loss energy); 0 = none.
var skip_turns: int = 0
## Energy the PLAYER loses at the start of a turn lost to this status (cards are still drawn);
## -1 (absent in data) = the whole turn (0 energy). Only meaningful with skip_turns > 0.
var player_energy_loss: int = -1
## 0..1 chance that each action (enemy) / played card (player) fails.
var skip_chance: float = 0.0
var wake_on_damage: bool = false
## Type ids whose hits remove the status.
var thaw_types: Array[String] = []
## Type ids immune to the status.
var immune_types: Array[String] = []
## Enemy intent text while it will lose its turn ("Dort").
var skip_label: String = ""


## Builds a StatusData; null (after push_error) if invalid. `known_types` (type ids) validates the type lists when non-empty.
static func from_dict(status_id: String, d: Dictionary, known_types: Array[String] = []) -> StatusData:
	for key: String in ["name", "short", "color", "description"]:
		if not (d.get(key, null) is String) or String(d[key]).is_empty():
			push_error("StatusData: status '%s' needs a non-empty string '%s'" % [status_id, key])
			return null
	var s := StatusData.new()
	s.id = status_id
	s.display_name = String(d["name"])
	s.short = String(d["short"])
	if not String(d["color"]).is_valid_html_color():
		push_error("StatusData: status '%s' has an invalid color" % status_id)
		return null
	s.color = Color.html(String(d["color"]))
	s.description = String(d["description"])
	for key: String in ["tick_damage", "stackable", "wake_on_damage", "refresh_on_reapply"]:
		if d.has(key) and not (d[key] is bool):
			push_error("StatusData: status '%s': '%s' must be a boolean" % [status_id, key])
			return null
	s.tick_damage = bool(d.get("tick_damage", false))
	s.stackable = bool(d.get("stackable", false))
	s.wake_on_damage = bool(d.get("wake_on_damage", false))
	s.refresh_on_reapply = bool(d.get("refresh_on_reapply", true))
	for key: String in ["value_decay", "duration", "attack_penalty", "skip_turns"]:
		var v: Variant = d.get(key, 0)
		if not ((v is int or v is float) and v >= 0 and v == floorf(v)):
			push_error("StatusData: status '%s': '%s' must be an integer >= 0" % [status_id, key])
			return null
	s.value_decay = int(d.get("value_decay", 0))
	s.duration = int(d.get("duration", 0))
	s.attack_penalty = int(d.get("attack_penalty", 0))
	s.skip_turns = int(d.get("skip_turns", 0))
	if d.has("player_energy_loss"):
		var loss: Variant = d["player_energy_loss"]
		if not ((loss is int or loss is float) and loss >= 0 and loss == floorf(loss)):
			push_error("StatusData: status '%s': 'player_energy_loss' must be an integer >= 0" % status_id)
			return null
		if s.skip_turns <= 0:
			push_error("StatusData: status '%s': 'player_energy_loss' needs skip_turns" % status_id)
			return null
		s.player_energy_loss = int(loss)
	var chance: Variant = d.get("skip_chance", 0.0)
	if not ((chance is int or chance is float) and chance >= 0.0 and chance <= 1.0):
		push_error("StatusData: status '%s': 'skip_chance' must be within 0..1" % status_id)
		return null
	s.skip_chance = float(chance)
	for key: String in ["thaw_types", "immune_types"]:
		var raw: Variant = d.get(key, [])
		if not (raw is Array):
			push_error("StatusData: status '%s': '%s' must be an array of type ids" % [status_id, key])
			return null
		for t: Variant in (raw as Array):
			if not (t is String) or (not known_types.is_empty() and String(t) not in known_types):
				push_error("StatusData: status '%s': unknown type '%s' in '%s'" % [status_id, str(t), key])
				return null
			(s.thaw_types if key == "thaw_types" else s.immune_types).append(String(t))
	s.skip_label = String(d.get("skip_label", ""))
	if s.skip_turns > 0 and s.skip_label.is_empty():
		s.skip_label = s.display_name
	if s.value_decay > 0 and not s.tick_damage:
		push_error("StatusData: status '%s': value_decay needs tick_damage" % status_id)
		return null
	if not (s.tick_damage or s.attack_penalty > 0 or s.skip_turns > 0 or s.skip_chance > 0.0):
		push_error("StatusData: status '%s' has no effect (tick_damage / attack_penalty / skip_turns / skip_chance)" % status_id)
		return null
	if s.tick_damage and s.value_decay == 0 and s.duration == 0:
		push_error("StatusData: status '%s' would never end (needs value_decay or duration)" % status_id)
		return null
	if s.skip_chance > 0.0 and s.duration == 0:
		push_error("StatusData: status '%s': skip_chance needs a duration" % status_id)
		return null
	return s


## Energy the player loses on a turn lost to this status, out of `max_energy` (whole turn when player_energy_loss is -1).
func energy_loss_for(max_energy: int) -> int:
	return max_energy if player_energy_loss < 0 else mini(player_energy_loss, max_energy)


## Initial `turns` of a fresh instance: the duration, or skip_turns for turn-skipping statuses.
func initial_turns() -> int:
	return duration if duration > 0 else skip_turns
