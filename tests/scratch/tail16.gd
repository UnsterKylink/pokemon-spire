

# --- Status ailments (story 016) -----------------------------------------------------------------------
# Turn flow: the player's statuses tick at the end of its turn (before the enemies act); each enemy first
# consumes a lost turn (sleep/freeze) or rolls its paralysis, acts if not skipped, THEN ticks its own statuses.
# A combatant killed by a tick is dead (enemy: intent dropped, battle_won once none is left; player: battle_lost).
# Statuses live on the Combatant (statuses dict) and are cleared silently when the battle ends.

## Applies `value` of status `status_id` to `target` (a living combatant of this battle). Returns false when refused:
## unknown status / dead target, or immune (status_blocked emitted). Immunity: any of the target's types in the
## status's immune_types (the player uses the ACTIVE Pokémon's types), or a held "status_immunity" item.
## Re-applying stacks the value (stackable statuses) and refreshes the duration.
func apply_status(target: Combatant, status_id: String, value: int) -> bool:
	var def: StatusData = _status_book.get_def(status_id)
	if def == null:
		push_error("Battle: unknown status '%s'" % status_id)
		return false
	if target == null or not target.is_alive() or value <= 0:
		return false
	if is_immune(target, status_id):
		status_blocked.emit(target, status_id)
		return false
	if target.statuses.has(status_id):
		var entry: Dictionary = target.statuses[status_id]
		if def.stackable:
			entry["value"] = int(entry["value"]) + value
		entry["turns"] = def.initial_turns()
	else:
		target.statuses[status_id] = {"value": value if def.stackable else 1, "turns": def.initial_turns()}
	target.changed.emit()
	status_applied.emit(target, status_id, value)
	refresh_intents()
	return true


## True if `target` can never receive the status (type immunity, or held item immunity for the player).
func is_immune(target: Combatant, status_id: String) -> bool:
	var def: StatusData = _status_book.get_def(status_id)
	if def == null:
		return false
	for t: String in target.type_ids:
		if t in def.immune_types:
			return true
	return target == player and status_id in ItemEffects.status_immunities(items)


## Removes `status_id` ("all" = every status) from `target`; returns how many were removed (status_removed per status).
func cure_status(target: Combatant, status_id: String) -> int:
	var removed: int = 0
	for sid: String in target.status_ids():
		if status_id == "all" or sid == status_id:
			_remove_status(target, sid)
			removed += 1
	if removed > 0:
		refresh_intents()
	return removed


func _remove_status(target: Combatant, status_id: String) -> void:
	target.statuses.erase(status_id)
	target.changed.emit()
	status_removed.emit(target, status_id)


func _attack_penalty(c: Combatant) -> int:
	var sum: int = 0
	for sid: String in c.statuses.keys():
		var def: StatusData = _status_book.get_def(sid)
		if def != null:
			sum += def.attack_penalty
	return sum


## Label ("Dort") of the first status that will make this enemy lose its next turn, "" if none.
func _skip_label(c: Combatant) -> String:
	for sid: String in c.statuses.keys():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and def.skip_turns > 0:
			return def.skip_label
	return ""


## A damaging hit landed on `target` (amount >= 1 before block): wake_on_damage statuses and statuses thawed by `attack_type` go.
func _on_damaged(target: Combatant, attack_type: String) -> void:
	var changed_any: bool = false
	for sid: String in target.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and (def.wake_on_damage or (not attack_type.is_empty() and attack_type in def.thaw_types)):
			_remove_status(target, sid)
			changed_any = true
	if changed_any:
		refresh_intents()


## Consumes one lost turn of the first skip_turns status (removed when no turns are left). Returns its id or "".
func _consume_skip_turn(c: Combatant) -> String:
	for sid: String in c.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def == null or def.skip_turns <= 0:
			continue
		var entry: Dictionary = c.statuses[sid]
		entry["turns"] = int(entry["turns"]) - 1
		if int(entry["turns"]) <= 0:
			_remove_status(c, sid)
			refresh_intents()
		else:
			c.changed.emit()
		return sid
	return ""


## Rolls the skip_chance of every status of `c` with the injected RNG; returns the id that made the action fail, or "".
## The RNG is only consumed when such a status is present, so battles without paralysis keep their sequences.
func _roll_fail(c: Combatant) -> String:
	for sid: String in c.status_ids():
		var def: StatusData = _status_book.get_def(sid)
		if def != null and def.skip_chance > 0.0 and _rng.randf() < def.skip_chance:
			return sid
	return ""


func _roll_card_fizzle() -> String:
	return _roll_fail(player)


## End-of-turn tick of `c`: damage statuses deal their value (ignoring block), values decay, durations shrink.
func _tick_statuses(c: Combatant) -> void:
	for sid: String in c.status_ids():
		if not c.is_alive():
			break
		var def: StatusData = _status_book.get_def(sid)
		if def == null or not c.statuses.has(sid):
			continue
		var entry: Dictionary = c.statuses[sid]
		if def.tick_damage:
			var amount: int = int(entry["value"])
			c.lose_hp(amount)
			status_ticked.emit(c, sid, amount)
			if not c.is_alive():
				if c != player:
					c.intent = null
				break
			if def.value_decay > 0:
				entry["value"] = int(entry["value"]) - def.value_decay
				if int(entry["value"]) <= 0:
					_remove_status(c, sid)
					continue
		if def.duration > 0:
			entry["turns"] = int(entry["turns"]) - 1
			if int(entry["turns"]) <= 0:
				_remove_status(c, sid)
				continue
		c.changed.emit()
	if c != player:
		refresh_intents()


func _win() -> void:
	_fire_items(ItemData.TRIGGER_BATTLE_END)  # before the win is announced, so the HP is persisted by the caller
	state = State.WON
	player.clear_statuses()
	state_changed.emit()
	battle_won.emit()


func _lose() -> void:
	state = State.LOST
	player.clear_statuses()
	state_changed.emit()
	battle_lost.emit()
