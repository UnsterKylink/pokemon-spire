class_name BallIcon
extends Control
## Small Poké Ball drawn in code (no texture): coloured top half, white bottom half, black band and centre button.
## The palette is picked from the ball id (PALETTES); unknown ids fall back to the Poké Ball colours. Display only.
## Implements: story-017-capture (HUD balls indicator, battle capture buttons, Mart, reward chip).

## ball id -> [top colour, accent colour (marks on the top half; transparent = none)].
const PALETTES: Dictionary = {
	"poke_ball": [Color(0.86, 0.16, 0.16), Color(0, 0, 0, 0)],
	"super_ball": [Color(0.2, 0.42, 0.9), Color(0.9, 0.2, 0.2)],
	"hyper_ball": [Color(0.16, 0.16, 0.18), Color(1.0, 0.82, 0.2)],
}
const COLOR_BOTTOM: Color = Color(0.95, 0.95, 0.95)
const COLOR_LINE: Color = Color(0.05, 0.05, 0.07)

var ball_id: String = ""


## Builds an icon of side `side` px for `id`. Mouse ignored (the parent carries the tooltip).
static func make(id: String, side: float) -> BallIcon:
	var icon := BallIcon.new()
	icon.ball_id = id
	icon.custom_minimum_size = Vector2(side, side)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Top colour of a ball id (also used as the accent of its tiles / chips).
static func color_of(id: String) -> Color:
	return (PALETTES.get(id, PALETTES["poke_ball"]) as Array)[0]


func _draw() -> void:
	var r: float = minf(size.x, size.y) * 0.5 - 1.0
	if r <= 1.0:
		return
	var c: Vector2 = size * 0.5
	var pal: Array = PALETTES.get(ball_id, PALETTES["poke_ball"])
	draw_circle(c, r, COLOR_BOTTOM)
	var top := PackedVector2Array()
	var steps: int = 16
	for i: int in steps + 1:
		var a: float = PI + PI * float(i) / float(steps)
		top.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(top, pal[0])
	var accent: Color = pal[1]
	if accent.a > 0.0:
		draw_circle(c + Vector2(-r * 0.5, -r * 0.45), r * 0.2, accent)
		draw_circle(c + Vector2(r * 0.5, -r * 0.45), r * 0.2, accent)
	var band: float = maxf(1.0, r * 0.22)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), COLOR_LINE, band)
	draw_arc(c, r, 0.0, TAU, 24, COLOR_LINE, maxf(1.0, r * 0.14), true)
	draw_circle(c, r * 0.32, COLOR_LINE)
	draw_circle(c, r * 0.2, COLOR_BOTTOM)
