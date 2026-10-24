class_name StatusChipRow
extends HBoxContainer
## Row of status "chips" (story 016-statuts): one coloured pill per active status of a Combatant, colour / short
## label / name / description from statuses.json, e.g. "PSN 4", "BRU 3 (2 t.)", "PAR (2 t.)", "DOR", "GEL".
## Tooltip = name + description. Display only: reads the Combatant, redraws on its `changed` signal.

const FONT_SIZE: int = 14
const CHIP_RADIUS: int = 8
const CHIP_PAD_X: int = 6
## "%s" = chip label, %d = turns left (statuses with a duration only).
const TEXT_TURNS: String = "%s (%d t.)"
const TEXT_TOOLTIP: String = "%s\n%s"
## Luminance above which the chip text is dark (yellow / light colours) instead of white.
const DARK_TEXT_LUMINANCE: float = 0.5
const COLOR_TEXT_LIGHT: Color = Color(1.0, 1.0, 1.0)
const COLOR_TEXT_DARK: Color = Color(0.1, 0.1, 0.12)

var _combatant: Combatant
var _book: StatusBook


func _init() -> void:
	name = "StatusChips"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 4)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	visible = false


## Shows the statuses of `combatant` (definitions from `book`) and follows its `changed` signal.
func bind(combatant: Combatant, book: StatusBook) -> void:
	if _combatant != null and _combatant.changed.is_connected(refresh):
		_combatant.changed.disconnect(refresh)
	_combatant = combatant
	_book = book
	if _combatant != null:
		_combatant.changed.connect(refresh)
	refresh()


## Chip texts currently shown, in order (QA / tests).
func get_chip_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for chip: Node in get_children():
		if chip.is_queued_for_deletion():
			continue
		out.append((chip.get_node("Text") as Label).text)
	return out


## Text of one chip: short label, + value for stackable statuses, + "(n t.)" for statuses with a duration.
static func chip_text(def: StatusData, value: int, turns: int) -> String:
	var text: String = def.short
	if def.stackable:
		text += " %d" % value
	if def.duration > 0 and turns > 0:
		text = TEXT_TURNS % [text, turns]
	return text


## Redraws every chip from the bound Combatant (hidden row when it has no status).
func refresh() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if _combatant == null or _book == null:
		visible = false
		return
	for sid: String in _combatant.status_ids():
		var def: StatusData = _book.get_def(sid)
		if def != null:
			add_child(_make_chip(def, _combatant.get_status_value(sid), _combatant.get_status_turns(sid)))
	visible = get_child_count() > 0


func _make_chip(def: StatusData, value: int, turns: int) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "Chip_" + def.id
	# PASS: hovering shows the tooltip, clicks still reach the enemy panel (card targeting).
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.tooltip_text = TEXT_TOOLTIP % [def.display_name, def.description]
	var sb := StyleBoxFlat.new()
	sb.bg_color = def.color
	sb.set_corner_radius_all(CHIP_RADIUS)
	sb.content_margin_left = CHIP_PAD_X
	sb.content_margin_right = CHIP_PAD_X
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	chip.add_theme_stylebox_override("panel", sb)
	var label := CardView.make_label(FONT_SIZE)
	label.name = "Text"
	label.text = chip_text(def, value, turns)
	label.add_theme_color_override("font_color",
			COLOR_TEXT_DARK if def.color.get_luminance() > DARK_TEXT_LUMINANCE else COLOR_TEXT_LIGHT)
	chip.add_child(label)
	return chip
