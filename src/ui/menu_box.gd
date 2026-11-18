class_name MenuBox
extends StyleBox
## Story 033 (cohérence visuelle): the « menu Pokémon » window used by every screen — a thick coloured frame (blue by
## default) with a dark outline and a soft drop shadow, around a rounded white box with a thin darker rim of the frame
## colour. Text on it is dark (UiStyle.TEXT_DARK / TEXT_SUB). Built from two StyleBoxFlat drawn one over the other, so
## one PanelContainer gives the whole look (map_screen built it from two nested panels in story 020b).
## Make one with UiStyle.menu_panel(). Display only.

## Frame band colour.
var frame_color: Color = UiStyle.FRAME_BLUE:
	set(v):
		frame_color = v
		_dirty = true
		emit_changed()
## Inner box colour.
var fill_color: Color = UiStyle.PANEL_WHITE:
	set(v):
		fill_color = v
		_dirty = true
		emit_changed()
## Width of the frame band (between the outer outline and the white box).
var frame_width: int = UiStyle.MENU_FRAME_PAD:
	set(v):
		frame_width = v
		_dirty = true
		emit_changed()

var _outer: StyleBoxFlat
var _inner: StyleBoxFlat
var _dirty: bool = true


func _rebuild() -> void:
	_dirty = false
	_outer = UiStyle.menu_frame(frame_color)
	_inner = UiStyle.menu_inner(frame_color, 0.0, 0.0)
	_inner.bg_color = fill_color


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if _dirty or _outer == null:
		_rebuild()
	_outer.draw(to_canvas_item, rect)
	var inset: float = float(frame_width + 1)
	var inner: Rect2 = rect.grow(-inset)
	if inner.size.x > 0.0 and inner.size.y > 0.0:
		_inner.draw(to_canvas_item, inner)
