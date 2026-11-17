class_name OptionsPanel
extends Control
## Options overlay (opened from the "Options" button of the run bar): type-effectiveness hint on / off and the
## animation speed. Saves at once (GameSettings / BattleFxDirector) and emits `changed` so the open screen updates.

## Emitted after any option changed.
signal changed
## Emitted when the panel closes.
signal closed

const PANEL_SIZE: Vector2 = Vector2(560, 300)
const COLOR_DIM: Color = Color(0, 0, 0, 0.55)
const TEXT_TITLE: String = "Options"
const TEXT_TYPE_HINTS: String = "Indicateur d'efficacité des types"
const TEXT_TYPE_HINTS_TIP: String = "Quand une attaque est sélectionnée, teinte en vert léger les ennemis qui la prennent en super efficace et en rouge léger ceux qui la résistent."
const TEXT_SPEED: String = "Animations : %s"
const TEXT_CLOSE: String = "Fermer"

var _type_hints: CheckButton
var _speed_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = COLOR_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", UiStyle.panel())
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var title: Label = Label.new()
	title.text = TEXT_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, "title")
	box.add_child(title)
	_type_hints = CheckButton.new()
	_type_hints.name = "TypeHints"
	_type_hints.text = TEXT_TYPE_HINTS
	_type_hints.tooltip_text = TEXT_TYPE_HINTS_TIP
	_type_hints.add_theme_font_size_override("font_size", 20)
	_type_hints.toggled.connect(_on_type_hints_toggled)
	box.add_child(_type_hints)
	_speed_button = Button.new()
	_speed_button.name = "Speed"
	_speed_button.custom_minimum_size = Vector2(320, 44)
	_speed_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.apply_button(_speed_button, UiStyle.ACCENT_BLUE)
	_speed_button.pressed.connect(_on_speed_pressed)
	box.add_child(_speed_button)
	var close_button: Button = Button.new()
	close_button.text = TEXT_CLOSE
	close_button.custom_minimum_size = Vector2(200, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.apply_button(close_button, UiStyle.ACCENT_BLUE)
	close_button.pressed.connect(close)
	box.add_child(close_button)
	UiStyle.style_screen(self)


## Shows the panel with the saved values.
func open() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size  # the parent (Main) may not be a sized Control
	_type_hints.set_pressed_no_signal(GameSettings.type_hints_enabled())
	_refresh_speed()
	visible = true


## Hides the panel.
func close() -> void:
	if visible:
		visible = false
		closed.emit()


## True while shown.
func is_open() -> bool:
	return visible


## QA: sets the type hint option as the checkbox does.
func set_type_hints(on: bool) -> void:
	_type_hints.button_pressed = on


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_type_hints_toggled(on: bool) -> void:
	GameSettings.set_value(GameSettings.KEY_TYPE_HINTS, on)
	changed.emit()


func _on_speed_pressed() -> void:
	var order: Array[String] = BattleFxDirector.preset_order()
	var i: int = order.find(BattleFxDirector.load_saved_speed())
	var next: String = order[(i + 1) % order.size()]
	BattleFxDirector.save_speed(next)
	_refresh_speed()
	changed.emit()


func _refresh_speed() -> void:
	_speed_button.text = TEXT_SPEED % BattleFxDirector.speed_label(BattleFxDirector.load_saved_speed())
