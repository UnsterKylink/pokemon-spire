// Story 020b — material finish of panels and buttons (art bible §4): film of grain from the generated noise,
// soft vertical light (lighter top, darker bottom), thin inner highlight under the top edge. Drawn as a ColorRect
// child above the StyleBoxFlat, masked by the same rounded rect (inside the outline). Size from UV derivatives.
shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float radius = 12.0;
uniform float border = 2.0;
uniform float bottom_inset = 0.0;
uniform float grain : hint_range(0.0, 0.5) = 0.07;
uniform float mottling : hint_range(0.0, 0.5) = 0.06;
uniform float top_light : hint_range(0.0, 0.5) = 0.12;
uniform float bottom_shade : hint_range(0.0, 0.5) = 0.16;
uniform float highlight_line : hint_range(0.0, 1.0) = 0.3;

float rbox(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 px = vec2(abs(dFdx(UV.x)), abs(dFdy(UV.y)));
	vec2 size = 1.0 / max(px, vec2(1e-5));
	vec2 p = UV * size;
	vec2 rs = vec2(size.x, max(size.y - bottom_inset, 1.0));
	float d = rbox(p - rs * 0.5, rs * 0.5 - border, max(radius - border, 0.0));
	float inside = clamp(-d, 0.0, 1.0);
	float t = clamp(p.y / rs.y, 0.0, 1.0);
	float light = top_light * (1.0 - smoothstep(0.0, 0.6, t));
	float shade = bottom_shade * smoothstep(0.4, 1.0, t);
	float line = highlight_line * (1.0 - smoothstep(0.0, 1.6, abs(-d - 1.6))) * (1.0 - smoothstep(0.05, 0.45, t));
	float n = texture(noise_tex, p / 256.0).r - 0.5;
	float m = texture(noise_tex, p / 900.0 + vec2(0.37, 0.11)).r - 0.5;
	float white = light + line + max(n, 0.0) * grain * 2.0 + max(m, 0.0) * mottling * 2.0;
	float black = shade + max(-n, 0.0) * grain * 2.0 + max(-m, 0.0) * mottling * 2.0;
	float a = clamp(white + black, 0.0, 0.85);
	vec3 col = vec3(white / max(white + black, 1e-4));
	COLOR = vec4(col, a * inside);
}
