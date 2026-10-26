// Story 020b — holographic foil / hover sheen on a CardFace (art bible §7).
// Drawn as an additive overlay ColorRect covering the face. `holo` = rainbow foil strength (rare / legendary),
// `glare` = moving white glare (hover on every card). `calm_rect` (UV rect: x, y, w, h) = description box,
// where the effect drops to `calm_factor` so the text stays readable. `mouse` = cursor in face UV (0..1).
shader_type canvas_item;
render_mode blend_add;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float holo : hint_range(0.0, 1.0) = 0.0;
uniform float glare : hint_range(0.0, 1.0) = 0.0;
uniform vec2 mouse = vec2(0.5, 0.3);
uniform vec4 calm_rect = vec4(0.0, 0.6, 1.0, 0.35);
uniform float calm_factor : hint_range(0.0, 1.0) = 0.25;
uniform float radius_px = 8.0;
uniform float speed = 0.18;

float rbox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 px = vec2(abs(dFdx(UV.x)), abs(dFdy(UV.y)));
	vec2 size = 1.0 / max(px, vec2(1e-5));
	vec2 p = UV * size;
	float inside = clamp(-rbox(p - size * 0.5, size * 0.5 - 1.0, radius_px), 0.0, 1.0);
	vec2 c0 = calm_rect.xy;
	vec2 c1 = calm_rect.xy + calm_rect.zw;
	float in_calm = step(c0.x, UV.x) * step(UV.x, c1.x) * step(c0.y, UV.y) * step(UV.y, c1.y);
	float calm = mix(1.0, calm_factor, in_calm);
	// Rainbow foil: diagonal bands that slide with time and with the cursor.
	float n = texture(noise_tex, p / 180.0).r;
	float phase = (UV.x * 0.9 + UV.y * 1.3) * 1.6 + TIME * speed + mouse.x * 0.9 + mouse.y * 0.5 + n * 0.35;
	vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (phase + vec3(0.0, 0.33, 0.67)));
	float band = 0.45 + 0.55 * pow(0.5 + 0.5 * sin((UV.x - UV.y) * 9.0 + TIME * 0.9 + mouse.x * 4.0), 3.0);
	float sparkle = pow(texture(noise_tex, p / 37.0 + vec2(TIME * 0.02, 0.0)).r, 9.0) * 6.0;
	vec3 foil = rainbow * (band + sparkle) * holo;
	// Glare: soft white spot following the cursor, plus a sweeping stripe.
	float spot = exp(-dot(UV - mouse, UV - mouse) * 6.0);
	float stripe = exp(-pow((UV.x + UV.y * 0.6) - (mouse.x * 1.6 - 0.1), 2.0) * 40.0);
	vec3 shine = vec3(1.0, 0.97, 0.9) * (spot * 0.55 + stripe * 0.35) * glare;
	COLOR = vec4((foil * 0.55 + shine) * calm * inside, 1.0);
}
