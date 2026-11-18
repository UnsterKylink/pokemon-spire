class_name MenuBackdrop
extends Control
## Story 033 (cohérence visuelle): the screen background behind the « menu Pokémon » windows, like a Pokémon menu
## backdrop: blue gradient (optionally tinted by a type colour), soft diagonal stripes and a big faint Poké Ball
## watermark. Moved out of map_screen (story 020b MapBackdrop) so every screen shares it. Display only.

## Zone / type colour the gradient leans towards (alpha 0 = plain blue).
var tint: Color = Color(0, 0, 0, 0)
## Gym type id (kept for callers; the drawing only uses `tint`).
var type_id: String = ""


## Sets the zone's gym type and colour, then redraws.
func set_zone(zone_type_id: String, color: Color) -> void:
	type_id = zone_type_id
	tint = color
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var k: float = 0.28 if tint.a > 0.0 else 0.0
	var top: Color = Color("#5C9BE6").lerp(Color(tint, 1.0), k)
	var bottom: Color = Color("#2D5EB0").lerp(Color(tint, 1.0).darkened(0.3), k * 0.9)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([top, top, bottom, bottom]))
	var x: float = -h
	while x < w:  # diagonal stripes
		draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + h, 0), Vector2(x + h + 26.0, 0),
				Vector2(x + 26.0, h)]), Color(1, 1, 1, 0.05))
		x += 64.0
	var c := Vector2(w - 120.0, h - 90.0)  # Poké Ball watermark
	var wm: Color = Color(1, 1, 1, 0.08)
	draw_arc(c, 190.0, 0.0, TAU, 96, wm, 22.0, true)
	draw_line(c - Vector2(190, 0), c + Vector2(190, 0), wm, 22.0)
	draw_circle(c, 52.0, wm)
