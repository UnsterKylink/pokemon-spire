class_name BallIcon
extends Control
## Small Poké Ball icon. Story 020b: draws the official art (assets/sprites/items/<id>.png, via ItemIcon) when it
## exists; otherwise the ball drawn in code (coloured top half, white bottom half, black band and centre button,
## palette picked from the ball id, unknown ids fall back to the Poké Ball colours). Display only.
## Implements: story-017-capture (HUD balls indicator, battle capture buttons, Mart, reward chip),
## story-020b-refonte-visuelle-premium (official sprite).

## ball id -> [top colour, accent colour (marks on the top half; transparent = none)].
const PALETTES: Dictionary = {
	"poke_ball": [Color(0.86, 0.16, 0.16), Color(0, 0, 0, 0)],
	"super_ball": [Color(0.2, 0.42, 0.9), Color(0.9, 0.2, 0.2)],
	"hyper_ball": [Color(0.16, 0.16, 0.18), Color(1.0, 0.82, 0.2)],
}
const COLOR_BOTTOM: Color = Color(0.95, 0.95, 0.95)
const COLOR_LINE: Color = Color(0.05, 0.05, 0.07)

var ball_id: String = ""
## Story 020b: soft drop shadow under the sprite (off for the tiny HUD icons).
var shadow: bool = false


## Builds an icon of side `side` px for `id`. Mouse ignored (the parent carries the tooltip).
static func make(id: String, side: float) -> BallIcon:
	var icon := BallIcon.new()
	icon.ball_id = id
	icon.custom_minimum_size = Vector2(side, side)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return icon


## Top colour of a ball id (also used as the accent of its tiles / chips).
static func color_of(id: String) -> Color:
	return (PALETTES.get(id, PALETTES["poke_ball"]) as Array)[0]


## Draws the code-drawn ball of `id` (radius `r`, centre `c`) on `ci` (fallback when the sprite is missing).
static func draw_ball(ci: CanvasItem, c: Vector2, r: float, id: String) -> void:
	if r <= 1.0:
		return
	var pal: Array = PALETTES.get(id, PALETTES["poke_ball"])
	ci.draw_circle(c, r, COLOR_BOTTOM)
	var top := PackedVector2Array()
	var steps: int = 16
	for i: int in steps + 1:
		var a: float = PI + PI * float(i) / float(steps)
		top.append(c + Vector2(cos(a), sin(a)) * r)
	ci.draw_colored_polygon(top, pal[0])
	var accent: Color = pal[1]
	if accent.a > 0.0:
		ci.draw_circle(c + Vector2(-r * 0.5, -r * 0.45), r * 0.2, accent)
		ci.draw_circle(c + Vector2(r * 0.5, -r * 0.45), r * 0.2, accent)
	var band: float = maxf(1.0, r * 0.22)
	ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), COLOR_LINE, band)
	ci.draw_arc(c, r, 0.0, TAU, 24, COLOR_LINE, maxf(1.0, r * 0.14), true)
	ci.draw_circle(c, r * 0.32, COLOR_LINE)
	ci.draw_circle(c, r * 0.2, COLOR_BOTTOM)


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	var tex: Texture2D = ItemIcon.texture_for(ball_id)
	if tex != null:
		ItemIcon.draw_art(self, tex, Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)), shadow)
		return
	draw_ball(self, size * 0.5, side * 0.5 - 1.0, ball_id)
