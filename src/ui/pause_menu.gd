class_name PauseMenu
extends Control
## Story 023 (story-023-menu-options-tutoriel): the pause overlay of a run (Échap, or the « Pause » button of the run bar):
## a menu window with Reprendre, Options, Abandonner la partie (confirmation: the run counts as lost, the save is
## deleted, back to the title) and Quitter le jeu (confirmation: the autosave is kept; back to the title screen or quit
## the game). Display only: it emits signals and Main acts. Processes while the tree is paused (Main pauses the battle
## — get_tree().paused — while it is open). It also routes the Échap key for Main (`cancel_handler`), because Main
## itself is paused then.

signal resume_requested
signal options_requested
signal abandon_confirmed
signal quit_to_title_requested
signal quit_game_requested

const COLOR_DIM: Color = Color(0, 0, 0, 0.6)
const WINDOW_WIDTH: float = 420.0
const BUTTON_SIZE: Vector2 = Vector2(320, 50)
const TEXT_TITLE: String = "Pause"
const TEXT_RESUME: String = "Reprendre"
const TEXT_OPTIONS: String = "Options"
const TEXT_ABANDON: String = "Abandonner la partie"
const TEXT_QUIT: String = "Quitter le jeu"
const TEXT_ABANDON_TITLE: String = "Abandonner la partie ?"
const TEXT_ABANDON_BODY: String = "La partie sera comptée comme perdue dans tes statistiques et sa sauvegarde sera supprimée. Tu reviendras à l'écran titre."
const TEXT_ABANDON_SANDBOX_BODY: String = "Tu quittes le tutoriel et reviens à l'écran titre."
const TEXT_ABANDON_CONFIRM: String = "Abandonner"
const TEXT_QUIT_TITLE: String = "Quitter la partie ?"
const TEXT_QUIT_BODY: String = "Ta partie est sauvegardée à ton dernier passage sur la carte : tu la reprendras avec « Continuer »."
const TEXT_QUIT_TO_TITLE: String = "Écran titre"
const TEXT_QUIT_GAME: String = "Quitter le jeu"
const TEXT_CANCEL: String = "Annuler"

## Main's Échap handler (no argument, returns bool = handled); called from _unhandled_input even while paused.
var cancel_handler: Callable = Callable()
## True in the tutorial replay (sandbox: no save, no stats): the abandon text changes.
var sandbox: bool = false
var _main_box: VBoxContainer
var _confirm_box: VBoxContainer
var _confirm_title: Label
var _confirm_body: Label
var _confirm_buttons: HBoxContainer
var _confirm_kind: String = ""
var _resume_button: Button


func _init() -> void:
	name = "PauseMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	_build()


## Shows the main pause window.
func open() -> void:
	_build()
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_show_main()
	visible = true
	_resume_button.grab_focus()


## Hides the overlay (no signal).
func close() -> void:
	visible = false
	_confirm_kind = ""


## True while shown.
func is_open() -> bool:
	return visible


## "" | "abandon" | "quit": the confirmation shown.
func get_confirm_kind() -> String:
	return _confirm_kind if visible else ""


## Échap inside the overlay: a confirmation goes back to the main window; the main window resumes. True if handled.
func handle_cancel() -> bool:
	if not visible:
		return false
	if not _confirm_kind.is_empty():
		_show_main()
	else:
		press_resume()
	return true


## « Reprendre ».
func press_resume() -> void:
	resume_requested.emit()


## « Options ».
func press_options() -> void:
	options_requested.emit()


## « Abandonner la partie »: shows its confirmation.
func press_abandon() -> void:
	_show_confirm("abandon")


## « Quitter le jeu »: shows its confirmation.
func press_quit() -> void:
	_show_confirm("quit")


## Confirms the abandon (the confirmation must be shown).
func confirm_abandon() -> void:
	if _confirm_kind == "abandon":
		abandon_confirmed.emit()


## In the quit confirmation: back to the title screen (`to_title`) or quit the game.
func confirm_quit(to_title: bool) -> void:
	if _confirm_kind != "quit":
		return
	if to_title:
		quit_to_title_requested.emit()
	else:
		quit_game_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and cancel_handler.is_valid():
		if bool(cancel_handler.call()):
			get_viewport().set_input_as_handled()


func _show_main() -> void:
	_confirm_kind = ""
	_main_box.visible = true
	_confirm_box.visible = false


func _show_confirm(kind: String) -> void:
	_confirm_kind = kind
	_main_box.visible = false
	_confirm_box.visible = true
	for c: Node in _confirm_buttons.get_children():
		_confirm_buttons.remove_child(c)
		c.queue_free()
	if kind == "abandon":
		_confirm_title.text = TEXT_ABANDON_TITLE
		_confirm_body.text = TEXT_ABANDON_SANDBOX_BODY if sandbox else TEXT_ABANDON_BODY
		_confirm_buttons.add_child(_button("ConfirmAbandon", TEXT_ABANDON_CONFIRM, UiStyle.ACCENT_RED, confirm_abandon, 170.0))
	else:
		_confirm_title.text = TEXT_QUIT_TITLE
		_confirm_body.text = TEXT_QUIT_BODY
		_confirm_buttons.add_child(_button("QuitToTitle", TEXT_QUIT_TO_TITLE, UiStyle.ACCENT_BLUE, confirm_quit.bind(true), 150.0))
		_confirm_buttons.add_child(_button("QuitGame", TEXT_QUIT_GAME, UiStyle.ACCENT_RED, confirm_quit.bind(false), 150.0))
	var cancel: Button = _button("Cancel", TEXT_CANCEL, UiStyle.TEXT_SUB, _show_main, 120.0)
	_confirm_buttons.add_child(cancel)
	_focus_later(cancel)


func _build() -> void:
	if _main_box != null:
		return
	theme = UiStyle.make_theme()  # art-bible fonts / buttons, as the other menu screens
	var dim := ColorRect.new()
	dim.color = COLOR_DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var window := PanelContainer.new()
	window.name = "Window"
	window.custom_minimum_size = Vector2(WINDOW_WIDTH, 0)
	window.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.FRAME_BLUE, 26.0, 18.0))
	center.add_child(window)
	var stack := VBoxContainer.new()
	window.add_child(stack)
	_main_box = VBoxContainer.new()
	_main_box.name = "Main"
	_main_box.add_theme_constant_override("separation", 12)
	stack.add_child(_main_box)
	var title := Label.new()
	title.text = TEXT_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, "title")
	_main_box.add_child(title)
	_resume_button = _button("Resume", TEXT_RESUME, UiStyle.ACCENT_BLUE, press_resume)
	_main_box.add_child(_resume_button)
	_main_box.add_child(_button("Options", TEXT_OPTIONS, UiStyle.ACCENT_BLUE, press_options))
	_main_box.add_child(_button("Abandon", TEXT_ABANDON, UiStyle.ACCENT_RED, press_abandon))
	_main_box.add_child(_button("Quit", TEXT_QUIT, UiStyle.TEXT_SUB, press_quit))
	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "Confirm"
	_confirm_box.add_theme_constant_override("separation", 14)
	_confirm_box.visible = false
	stack.add_child(_confirm_box)
	_confirm_title = CardView.make_label(26)
	_confirm_title.add_theme_font_override("font", UiStyle.font_title())
	UiStyle.dark_label(_confirm_title, UiStyle.LOGO_BLUE)
	_confirm_box.add_child(_confirm_title)
	_confirm_body = CardView.make_label(18)
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body.custom_minimum_size = Vector2(WINDOW_WIDTH, 0)
	UiStyle.dark_label(_confirm_body, UiStyle.TEXT_DARK)
	_confirm_box.add_child(_confirm_body)
	_confirm_buttons = HBoxContainer.new()
	_confirm_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_buttons.add_theme_constant_override("separation", 10)
	_confirm_box.add_child(_confirm_buttons)


func _button(node_name: String, text: String, color: Color, on_press: Callable, width: float = -1.0) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.custom_minimum_size = Vector2(width if width > 0.0 else BUTTON_SIZE.x, BUTTON_SIZE.y if width <= 0.0 else 44.0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 22 if width <= 0.0 else 18)
	UiStyle.apply_button(b, color)
	b.pressed.connect(on_press)
	return b


## Gives `b` the keyboard / gamepad focus at the end of the frame (skipped if it left the tree meanwhile).
func _focus_later(b: Control) -> void:
	(func() -> void:
		if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():
			b.grab_focus()).call_deferred()
