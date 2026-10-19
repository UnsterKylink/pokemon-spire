class_name EventScreen
extends Control
## Event room (mouse only, fits 1280x720): title, text, 2 option buttons; after a choice, the option's
## result text + the effects summary and "Continuer". Holds no game state: it emits option_chosen,
## Main applies the effects and calls show_result. Implements: story-005-carte-acte-1 (events, 2 options).

## Emitted once when the player picks option `index`.
signal option_chosen(index: int)
## Emitted by "Continuer" once the result is shown.
signal finished

const COLOR_BG: Color = Color(0.1, 0.11, 0.15)
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_BORDER: Color = Color(0.35, 0.75, 0.42)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const COLOR_SUMMARY: Color = Color(0.55, 1.0, 0.6)
const COLOR_CHOSEN: Color = Color(1.0, 0.86, 0.3)
const PANEL_WIDTH: float = 940.0
const OPTION_SIZE: Vector2 = Vector2(640, 54)

var _event: Dictionary = {}
var _info: Label
var _title: Label
var _text: Label
var _options_box: VBoxContainer
var _option_buttons: Array[Button] = []
var _result: Label
var _summary: Label
var _continue_button: Button
var _chosen: int = -1
var _result_shown: bool = false
var _done: bool = false
var _built: bool = false


func _ready() -> void:
	_build_ui()


## Displays `event` ({id, title, text, options:[{label, ...}]}); `run` is only read for the HP line.
func setup(event: Dictionary, run: RunState) -> void:
	_build_ui()
	_event = event
	_chosen = -1
	_result_shown = false
	_done = false
	_title.text = String(event.get("title", ""))
	_text.text = String(event.get("text", ""))
	_set_info(run)
	for b: Button in _option_buttons:
		_options_box.remove_child(b)
		b.queue_free()
	_option_buttons.clear()
	var options: Array = event.get("options", [])
	for i: int in options.size():
		var b := Button.new()
		b.name = "Option%d" % i
		b.text = String((options[i] as Dictionary).get("label", ""))
		b.custom_minimum_size = OPTION_SIZE
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(choose.bind(i))
		_options_box.add_child(b)
		_option_buttons.append(b)
	_result.visible = false
	_summary.visible = false
	_continue_button.visible = false


## Picks option `index` (same path as a click). Ignored after the first choice.
func choose(index: int) -> void:
	if _chosen >= 0 or index < 0 or index >= _option_buttons.size():
		return
	_chosen = index
	for i: int in _option_buttons.size():
		_option_buttons[i].disabled = true
		if i == index:
			_option_buttons[i].add_theme_color_override("font_disabled_color", COLOR_CHOSEN)
	option_chosen.emit(index)


## Shows the outcome of the chosen option: its result text and the effects summary ("" = no change).
func show_result(result_text: String, summary: String, run: RunState) -> void:
	_result.text = result_text
	_result.visible = true
	_summary.text = summary if not summary.is_empty() else "Rien ne change."
	_summary.visible = true
	_set_info(run)
	_continue_button.visible = true
	_result_shown = true


## Presses "Continuer" (only once the result is shown).
func press_continue() -> void:
	if not _result_shown or _done:
		return
	_done = true
	finished.emit()


## The displayed event definition.
func get_event() -> Dictionary:
	return _event


## Chosen option index, -1 before the choice.
func get_chosen_index() -> int:
	return _chosen


## True once the result is displayed.
func is_result_shown() -> bool:
	return _result_shown


## The effects summary line shown after the choice.
func get_summary_text() -> String:
	return _summary.text


func _set_info(run: RunState) -> void:
	_info.text = "PV %d/%d   |   Deck : %d cartes" % [run.hp, run.max_hp, run.deck.size()]


func _build_ui() -> void:
	if _built:
		return
	_built = true
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.set_border_width_all(3)
	sb.border_color = COLOR_BORDER
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_info = CardView.make_label(18)
	box.add_child(_info)
	_title = CardView.make_label(40)
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	box.add_child(_title)
	_text = _make_wrapped_label(22)
	box.add_child(_text)
	_options_box = VBoxContainer.new()
	_options_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_box.add_theme_constant_override("separation", 12)
	box.add_child(_options_box)
	_result = _make_wrapped_label(22)
	_result.name = "Result"
	box.add_child(_result)
	_summary = CardView.make_label(24)
	_summary.name = "Summary"
	_summary.add_theme_color_override("font_color", COLOR_SUMMARY)
	box.add_child(_summary)
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continuer"
	_continue_button.custom_minimum_size = Vector2(220, 52)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.pressed.connect(press_continue)
	box.add_child(_continue_button)


func _make_wrapped_label(font_size: int) -> Label:
	var l: Label = CardView.make_label(font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_WIDTH - 56, 0)
	return l
