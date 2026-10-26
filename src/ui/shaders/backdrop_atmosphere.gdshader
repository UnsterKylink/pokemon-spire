// Story 020b: painted-look atmosphere layer drawn over the code battle backdrop (BattleBackdrop).
// Horizon haze + drifting ground mist (value-noise fbm), soft noise clouds, horizon glow, light shafts from a sun
// point and a light film grain. Everything fades out above the hand band (hand_top) so the cards stay readable.
// Cost: ~4 fbm calls (4 octaves) per pixel, full screen, one draw call. Compatibility renderer safe (canvas_item).
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform float horizon = 0.47;            // horizon height (fraction of the screen)
uniform float hand_top = 1.0;            // top of the hand band (fraction); nothing is drawn below it
uniform vec4 fog_color : source_color = vec4(1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.35;
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float glow : hint_range(0.0, 1.0) = 0.25;
uniform float rays : hint_range(0.0, 1.0) = 0.2;
uniform float sun_x : hint_range(0.0, 1.0) = 0.75;
uniform float clouds : hint_range(0.0, 1.0) = 0.25;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform float mottle : hint_range(0.0, 0.5) = 0.14;  // low-frequency light/dark brush patches (painted texture)
uniform float speed = 1.0;               // 0 = reduced motion (everything still)
uniform vec2 screen_size = vec2(1280.0, 720.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float aspect = screen_size.x / max(screen_size.y, 1.0);
	float d = uv.y - horizon;

	// Horizon haze: tall above the horizon (veils the far silhouettes), short below; broken up by warped noise.
	float band = exp(-pow(d / (d < 0.0 ? 0.17 : 0.07), 2.0));
	vec2 np = vec2(uv.x * aspect * 2.0 + t * 0.012, uv.y * 5.0);
	float n = fbm(np + vec2(fbm(np * 0.6 + vec2(t * 0.02, 0.0)), 0.0));
	float fog = band * fog_density * (0.5 + 0.8 * n);

	// Ground mist: wisps drifting just below the horizon, around the fighters' feet.
	float ground = smoothstep(horizon - 0.01, horizon + 0.06, uv.y) * (1.0 - smoothstep(horizon + 0.10, horizon + 0.36, uv.y));
	float mist = ground * fog_density * 0.75 * smoothstep(0.42, 0.78, fbm(vec2(uv.x * aspect * 2.6 - t * 0.025, uv.y * 8.0)));

	// Soft painted clouds in the upper sky.
	float sky = 1.0 - smoothstep(horizon - 0.18, horizon - 0.04, uv.y);
	float cl = clouds * sky * smoothstep(0.48, 0.82, fbm(vec2(uv.x * aspect * 1.3 + t * 0.006, uv.y * 3.2)));

	// Horizon glow, strongest under the sun.
	float g = glow * exp(-pow(d / 0.11, 2.0)) * (1.0 - 0.55 * abs(uv.x - sun_x));

	// Light shafts fanning down from the sun (just above the top edge).
	vec2 sp = vec2((uv.x - sun_x) * aspect, uv.y + 0.08);
	float ang = atan(sp.x, sp.y);
	float r = length(sp);
	float beams = smoothstep(0.5, 0.95, noise(vec2(ang * 7.0 + 3.0, t * 0.04)));
	float shaft = rays * 0.55 * beams * exp(-r * 1.3) * (1.0 - smoothstep(horizon - 0.08, horizon + 0.12, uv.y));
	float halo = rays * 0.45 * exp(-r * r * 14.0);

	float keep = 1.0 - smoothstep(hand_top - 0.05, hand_top, uv.y);
	float a = clamp(fog + mist + cl * 0.8, 0.0, 0.45) * keep;
	vec3 add = glow_color.rgb * (g + shaft + halo) * keep;

	// Film grain + static brush mottling: positive = lighten, negative = darken (premultiplied output cannot go below 0).
	float gr = (hash(uv * screen_size + floor(t * 12.0) * 1.7) - 0.5) * grain;
	float below = step(horizon, uv.y);
	gr += (fbm(vec2(uv.x * aspect * (2.5 + 3.5 * below), uv.y * (4.0 + 14.0 * below))) - 0.5) * mottle * keep;
	vec3 rgb = fog_color.rgb * a + add + vec3(max(gr, 0.0));
	a = clamp(a + max(-gr, 0.0), 0.0, 1.0);
	COLOR = vec4(rgb, a);
}
