class_name KeywordTooltip
extends PanelContainer
## Story 027: keyword tooltip shown above a hovered hand card (story 023: also enemy intents, status chips, type pills,
## the energy gem, Élan box, talent and field-rule pills — below the anchor when there is no room above) — one entry per keyword of the card (Épuisement,
## Rétention, Faiblesse, Vulnérable, Force, Élan, Multi-coups, Talent), name + player text from talents.json `keywords`.
## Display only: never takes the mouse, clamped inside the viewport.

const WIDTH: float = 300.0
const GAP: float = 10.0
const FONT_NAME: int = 15
const FONT_DESC: int = 13

var _box: VBoxContainer
var _texts: PackedStringArray = PackedStringArray()


func _init() -> void:
	name = "KeywordTooltip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_index = 50
	var sb: StyleBoxFlat = UiStyle.panel(Color(0.07, 0.08, 0.13, 0.96), UiStyle.BUTTON_RADIUS, UiStyle.PANEL_BORDER)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	add_theme_stylebox_override("panel", sb)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 2)
	add_child(_box)


## Shows `entries` ([{name, description}]) above `anchor` (global rect of the card); hides when empty.
func show_for(entries: Array[Dictionary], anchor: Rect2) -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_texts.clear()
	if entries.is_empty():
		visible = false
		return
	for e: Dictionary in entries:
		var n: Label = CardView.make_label(FONT_NAME)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		n.text = String(e.get("name", ""))
		n.add_theme_color_override("font_color", UiStyle.TALENT)
		n.add_theme_font_override("font", UiStyle.font_bold())
		_box.add_child(n)
		var d: Label = CardView.make_label(FONT_DESC)
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(WIDTH - 20.0, 0)
		d.text = String(e.get("description", ""))
		_box.add_child(d)
		_texts.append("%s : %s" % [n.text, d.text])
	custom_minimum_size = Vector2(WIDTH, 0)
	size = Vector2(WIDTH, 0)
	visible = true
	reset_size()
	var vp: Vector2 = get_viewport_rect().size
	var parent_origin: Vector2 = (get_parent() as Control).get_global_rect().position if get_parent() is Control else Vector2.ZERO
	var gx: float = clampf(anchor.get_center().x - WIDTH * 0.5, 6.0, vp.x - WIDTH - 6.0)
	var h: float = get_combined_minimum_size().y
	var gy: float = anchor.position.y - h - GAP
	if gy < 6.0:  # story 023: no room above (top-row pills): below the anchor instead
		gy = minf(anchor.end.y + GAP, vp.y - h - 6.0)
	position = Vector2(gx, gy) - parent_origin


## Texts currently shown ("Nom : description"), for the QA harness.
func get_texts() -> PackedStringArray:
	return _texts if visible else PackedStringArray()
