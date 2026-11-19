class_name TutorialOverlay
extends Control
## Story 023 (story-023-menu-options-tutoriel): the guided first battle. Step-by-step bubbles (assets/data/tutorial.json
## `steps`) drawn over the battle screen, each pointing (yellow frame + arrow) at the real UI element it explains — found
## every frame through `target_finder` (BattleScreen.get_tutorial_target), so it follows the hand as it is rebuilt.
## A step ends on « Suivant » or on its `advance_on` action (notify_action: "card_played", "switch", "end_turn");
## « Passer le tutoriel » is always shown. Display only: it never takes the mouse outside its bubble (the battle stays
## fully playable underneath), never changes the battle, and pauses with the battle screen (child of it).

## Emitted once, when the last step is closed (`skipped` false) or « Passer le tutoriel » is pressed (`skipped` true).
signal finished(skipped: bool)

const BUBBLE_WIDTH: float = 440.0
const BUBBLE_GAP: float = 34.0
const MARGIN: float = 10.0
const FRAME_PAD: float = 6.0
const FRAME_WIDTH: float = 4.0
const ARROW_SIZE: float = 16.0
const PULSE_SPEED: float = 4.0
const TEXT_NEXT: String = "Suivant"
const TEXT_DONE: String = "Terminer"
const TEXT_SKIP: String = "Passer le tutoriel"
const TEXT_STEP: String = "Étape %d/%d"

var _steps: Array[Dictionary] = []
var _index: int = -1
var _finder: Callable = Callable()
var _target_rect: Rect2 = Rect2()
var _has_target: bool = false
var _time: float = 0.0
var _motion: bool = true
var _done: bool = false
var _bubble: PanelContainer
var _title: Label
var _text: Label
var _counter: Label
var _next_button: Button
var _skip_button: Button


func _init() -> void:
	name = "TutorialOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 60  # above the keyword tooltip and the floating texts of the battle screen


func _ready() -> void:
	_build()


## Starts the tutorial with `steps` (tutorial.json format) and `target_finder` (String target id -> Control or null).
## `motion` false = no pulsing frame (animation speed « Instantané »).
func setup(steps: Array, target_finder: Callable, motion: bool = true) -> void:
	_build()
	_steps.clear()
	for s: Variant in steps:
		if s is Dictionary:
			_steps.append(s)
	_finder = target_finder
	_motion = motion
	_done = false
	_index = -1
	if _steps.is_empty():
		_finish(false)
		return
	_show_step(0)


## Index of the current step (0-based; -1 once finished).
func get_step_index() -> int:
	return _index if not _done else -1


## Id of the current step ("" once finished).
func get_step_id() -> String:
	return String(_steps[_index].get("id", "")) if not _done and _index >= 0 and _index < _steps.size() else ""


## Number of steps.
func get_step_count() -> int:
	return _steps.size()


## True while the current step points at a visible element (false = centred bubble).
func has_target() -> bool:
	return _has_target


## Text of the current bubble ("Titre : texte"), for QA.
func get_bubble_text() -> String:
	return "%s : %s" % [_title.text, _text.text] if not _done else ""


## True once finished or skipped.
func is_done() -> bool:
	return _done


## « Suivant »: next step (or the end after the last one).
func next() -> void:
	if _done:
		return
	if _index + 1 >= _steps.size():
		_finish(false)
	else:
		_show_step(_index + 1)


## « Passer le tutoriel ».
func skip() -> void:
	if not _done:
		_finish(true)


## The player did `action` ("card_played", "switch", "end_turn"): ends the current step if it waits for it.
func notify_action(action: String) -> void:
	if _done or _index < 0:
		return
	if String(_steps[_index].get("advance_on", "")) == action:
		next()


func _finish(skipped: bool) -> void:
	_done = true
	visible = false
	set_process(false)
	finished.emit(skipped)


func _show_step(i: int) -> void:
	_index = i
	var step: Dictionary = _steps[i]
	_title.text = String(step.get("title", ""))
	_text.text = String(step.get("text", ""))
	_counter.text = TEXT_STEP % [i + 1, _steps.size()]
	_next_button.text = TEXT_DONE if i == _steps.size() - 1 else TEXT_NEXT
	visible = true
	set_process(true)
	_update_target()
	_place_bubble()


func _process(delta: float) -> void:
	_time += delta
	_update_target()
	_place_bubble()
	queue_redraw()


func _update_target() -> void:
	_has_target = false
	if _done or _index < 0 or not _finder.is_valid():
		return
	var target: String = String(_steps[_index].get("target", ""))
	if target.is_empty():
		return
	var c: Variant = _finder.call(target)
	if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree():
		_target_rect = (c as Control).get_global_rect().grow(FRAME_PAD)
		_has_target = true


## Bubble above the target when it sits in the lower half, below it otherwise; centred when there is no target.
func _place_bubble() -> void:
	if _bubble == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	_bubble.reset_size()
	var bs: Vector2 = _bubble.get_combined_minimum_size()
	bs.x = maxf(bs.x, BUBBLE_WIDTH)
	var pos: Vector2 = (vp - bs) * 0.5
	if _has_target:
		var r: Rect2 = _target_rect
		pos.x = r.get_center().x - bs.x * 0.5
		if r.get_center().y > vp.y * 0.5:
			pos.y = r.position.y - BUBBLE_GAP - bs.y
		else:
			pos.y = r.end.y + BUBBLE_GAP
	pos.x = clampf(pos.x, MARGIN, vp.x - bs.x - MARGIN)
	pos.y = clampf(pos.y, MARGIN, vp.y - bs.y - MARGIN)
	_bubble.position = pos - get_global_rect().position


func _draw() -> void:
	if _done or not _has_target or _bubble == null:
		return
	var origin: Vector2 = get_global_rect().position
	var r: Rect2 = Rect2(_target_rect.position - origin, _target_rect.size)
	var pulse: float = 0.75 + 0.25 * sin(_time * PULSE_SPEED) if _motion else 1.0
	var col: Color = Color(UiStyle.ACCENT_YELLOW, pulse)
	draw_rect(r.grow(2.0), Color(UiStyle.OUTLINE, 0.8 * pulse), false, FRAME_WIDTH + 3.0)
	draw_rect(r, col, false, FRAME_WIDTH)
	# Arrow from the bubble edge to the target edge.
	var b: Rect2 = Rect2(_bubble.position, _bubble.size)
	var below: bool = b.position.y > r.get_center().y
	var tip: Vector2 = Vector2(clampf(b.get_center().x, r.position.x + 12.0, r.end.x - 12.0),
			r.end.y + 4.0 if below else r.position.y - 4.0)
	var base_y: float = b.position.y if below else b.end.y
	var base_x: float = clampf(tip.x, b.position.x + 24.0, b.end.x - 24.0)
	var dir: float = -1.0 if below else 1.0
	draw_line(Vector2(base_x, base_y), tip, Color(UiStyle.OUTLINE, 0.9), 9.0)
	draw_line(Vector2(base_x, base_y), tip, col, 5.0)
	var head_l: Vector2 = tip + Vector2(-ARROW_SIZE * 0.8, dir * -ARROW_SIZE)
	var head_r: Vector2 = tip + Vector2(ARROW_SIZE * 0.8, dir * -ARROW_SIZE)
	draw_colored_polygon(PackedVector2Array([tip, head_l, head_r]), col)
	draw_polyline(PackedVector2Array([tip, head_l, head_r, tip]), Color(UiStyle.OUTLINE, 0.9), 2.0)


func _build() -> void:
	if _bubble != null:
		return
	_bubble = PanelContainer.new()
	_bubble.name = "Bubble"
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)
	_bubble.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.ACCENT_YELLOW.darkened(0.05), 16.0, 10.0))
	add_child(_bubble)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_bubble.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	_title = CardView.make_label(22)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_override("font", UiStyle.font_title())
	UiStyle.dark_label(_title, UiStyle.LOGO_BLUE)
	head.add_child(_title)
	_counter = CardView.make_label(14)
	_counter.name = "Counter"
	UiStyle.dark_label(_counter, UiStyle.TEXT_SUB)
	head.add_child(_counter)
	_text = CardView.make_label(17)
	_text.name = "Text"
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(BUBBLE_WIDTH - 50.0, 0)
	UiStyle.dark_label(_text, UiStyle.TEXT_DARK)
	col.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	col.add_child(buttons)
	_skip_button = Button.new()
	_skip_button.name = "Skip"
	_skip_button.text = TEXT_SKIP
	_skip_button.custom_minimum_size = Vector2(0, 36)
	_skip_button.add_theme_font_size_override("font_size", 15)
	UiStyle.apply_button(_skip_button, UiStyle.TEXT_SUB)
	_skip_button.pressed.connect(skip)
	buttons.add_child(_skip_button)
	_next_button = Button.new()
	_next_button.name = "Next"
	_next_button.text = TEXT_NEXT
	_next_button.custom_minimum_size = Vector2(130, 36)
	_next_button.add_theme_font_size_override("font_size", 17)
	UiStyle.apply_button(_next_button, UiStyle.ACCENT_BLUE)
	_next_button.pressed.connect(next)
	buttons.add_child(_next_button)
