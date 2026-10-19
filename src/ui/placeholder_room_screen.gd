class_name PlaceholderRoomScreen
extends Control
## Simple message screen: title, body text and one button. Used for the Centre Pokémon / Poké Mart
## placeholders (their real contents are story 006) and for the minimal "Acte 1 terminé !" message
## (the real victory screen is story 007). Holds no game state. Implements: story-005-carte-acte-1.

## Emitted once by the button.
signal finished

const COLOR_BG: Color = Color(0.1, 0.11, 0.15)
const COLOR_PANEL: Color = Color(0.14, 0.15, 0.2)
const COLOR_BODY: Color = Color(0.92, 0.92, 0.95)
const PANEL_WIDTH: float = 820.0

var _title: Label
var _body: Label
var _button: Button
var _panel_style: StyleBoxFlat
var _done: bool = false
var _built: bool = false


func _ready() -> void:
	_build_ui()


## Fills the screen. `accent` colours the title and the panel border.
func setup(title: String, body: String, button_text: String, accent: Color) -> void:
	_build_ui()
	_done = false
	_title.text = title
	_title.add_theme_color_override("font_color", accent)
	_panel_style.border_color = accent
	_body.text = body
	_button.text = button_text


## Presses the button (same path as a click).
func press_continue() -> void:
	if _done:
		return
	_done = true
	finished.emit()


## Displayed title.
func get_title_text() -> String:
	return _title.text


## Displayed body text.
func get_body_text() -> String:
	return _body.text


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
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = COLOR_PANEL
	_panel_style.set_border_width_all(3)
	_panel_style.set_corner_radius_all(12)
	_panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", _panel_style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 22)
	panel.add_child(box)
	_title = CardView.make_label(42)
	box.add_child(_title)
	_body = CardView.make_label(24)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(PANEL_WIDTH - 64, 0)
	_body.add_theme_color_override("font_color", COLOR_BODY)
	box.add_child(_body)
	_button = Button.new()
	_button.name = "ContinueButton"
	_button.custom_minimum_size = Vector2(240, 54)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(press_continue)
	box.add_child(_button)
