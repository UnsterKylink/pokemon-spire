class_name BadgeEmblem
extends Control
## Story 012 (story-012-structure-8-arenes): one gym badge drawn in code (no external art), at any size.
## Earned = an octagonal emblem in the gym type's colour (dark rim, bright core, 4-point star, highlight);
## not earned = an empty grey outline. Used by the RunHud (8 small slots), the badge screen (large emblem + row)
## and the end-of-run summary. Display only: it is given a colour and a state, it reads no game state.

const COLOR_EMPTY_OUTLINE: Color = Color(0.45, 0.46, 0.52)
const COLOR_EMPTY_FILL: Color = Color(0.11, 0.12, 0.16)
const COLOR_HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.55)
const SIDES: int = 8
const TEXT_TIP_EARNED: String = "%s — Champion %s (%s)"
const TEXT_TIP_EMPTY: String = "Badge %d/%d — pas encore obtenu"

var _earned: bool = false
var _color: Color = Color.WHITE


## A square emblem of `side` px. `tip` (optional) becomes its tooltip (the emblem then catches the mouse).
static func create(side: float, badge_color: Color, earned: bool, tip: String = "") -> BadgeEmblem:
	var e := BadgeEmblem.new()
	e.custom_minimum_size = Vector2(side, side)
	e.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	e.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	e.set_badge(badge_color, earned)
	e.tooltip_text = tip
	e.mouse_filter = Control.MOUSE_FILTER_STOP if not tip.is_empty() else Control.MOUSE_FILTER_IGNORE
	return e


## Tooltip of an earned badge (dict of RunState.award_badge): "Badge Roche — Champion Pierre (Roche)".
static func tooltip_of(badge: Dictionary) -> String:
	return TEXT_TIP_EARNED % [String(badge.get("name", "")), String(badge.get("leader", "")), String(badge.get("type_name", ""))]


## Rebuilds `row` with one emblem per zone of `run` (read only): the earned badges in their type colour (tooltip
## tooltip_of), the others as grey outlines. Without zones the row is emptied and hidden.
static func fill_row(row: HBoxContainer, run: RunState, side: float) -> void:
	for child: Node in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var count: int = run.zones.size() if run != null else 0
	for i: int in count:
		if i < run.badges.size():
			var b: Dictionary = run.badges[i]
			row.add_child(create(side, b.get("color", Color.WHITE), true, tooltip_of(b)))
		else:
			row.add_child(create(side, COLOR_EMPTY_OUTLINE, false, TEXT_TIP_EMPTY % [i + 1, count]))
	row.visible = count > 0


## Sets the colour (the gym type's) and the earned state, then redraws.
func set_badge(badge_color: Color, earned: bool) -> void:
	_color = badge_color
	_earned = earned
	queue_redraw()


## True if drawn as an earned badge (QA).
func is_earned() -> bool:
	return _earned


## Fill colour of an earned badge (QA).
func get_badge_color() -> Color:
	return _color


func _draw() -> void:
	var r: float = minf(size.x, size.y) * 0.5
	if r <= 1.0:
		return
	var c: Vector2 = size * 0.5
	var outer: PackedVector2Array = _polygon(c, r * 0.96, PI / SIDES)
	var closed: PackedVector2Array = outer.duplicate()
	closed.append(outer[0])
	if not _earned:
		draw_colored_polygon(outer, COLOR_EMPTY_FILL)
		draw_polyline(closed, COLOR_EMPTY_OUTLINE, maxf(1.5, r * 0.12), true)
		return
	draw_colored_polygon(outer, _color.darkened(0.5))
	draw_colored_polygon(_polygon(c, r * 0.76, PI / SIDES), _color)
	draw_colored_polygon(_star(c, r * 0.52, r * 0.18), _color.lightened(0.6))
	draw_circle(c + Vector2(-r * 0.36, -r * 0.36), r * 0.11, COLOR_HIGHLIGHT)
	draw_polyline(closed, _color.lightened(0.35), maxf(1.0, r * 0.07), true)


func _polygon(c: Vector2, radius: float, offset: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in SIDES:
		var a: float = offset + TAU * i / SIDES
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	return pts


func _star(c: Vector2, outer_r: float, inner_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 8:
		var a: float = -PI / 2 + TAU * i / 8
		pts.append(c + Vector2(cos(a), sin(a)) * (outer_r if i % 2 == 0 else inner_r))
	return pts
