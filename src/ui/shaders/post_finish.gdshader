// Story 020b — global image finish (art bible §8), on a full-screen ColorRect in PostFx (top CanvasLayer).
// Order: halo (soft bloom of bright areas) -> gentle grade (saturation, contrast, split tint) -> vignette -> grain.
// All strengths are uniforms (quality / taste knobs); defaults are deliberately subtle.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform float halo_strength : hint_range(0.0, 1.0) = 0.16;
uniform float halo_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float halo_radius = 11.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.06;
uniform float contrast : hint_range(0.5, 1.5) = 1.05;
uniform vec3 shadow_tint = vec3(0.97, 0.99, 1.04);
uniform vec3 highlight_tint = vec3(1.03, 1.01, 0.96);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float vignette_inner : hint_range(0.0, 1.5) = 0.45;
uniform float vignette_outer : hint_range(0.0, 2.0) = 1.05;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.03;
uniform float grain_fps = 12.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	// Halo: 16-tap golden-angle disc, rotated per pixel by the noise (dithered, no ghost copies), bright part only.
	vec3 b = vec3(0.0);
	float rot = texture(noise_tex, uv / SCREEN_PIXEL_SIZE / 256.0).r * 6.28318;
	for (int i = 0; i < 16; i++) {
		float fi = float(i) + 0.5;
		float a = fi * 2.39996 + rot;
		vec2 o = vec2(cos(a), sin(a)) * sqrt(fi / 16.0) * halo_radius * SCREEN_PIXEL_SIZE;
		b += max(texture(screen_tex, uv + o).rgb - halo_threshold, 0.0);
	}
	c += b / 16.0 * halo_strength * 3.0;
	// Grade.
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= mix(shadow_tint, highlight_tint, smoothstep(0.15, 0.85, l));
	// Vignette (aspect-corrected).
	vec2 d = uv - 0.5;
	d.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float v = smoothstep(vignette_inner, vignette_outer, length(d) * 1.25);
	c *= 1.0 - v * vignette_strength;
	// Grain (stepped in time so it reads as film, not shimmer).
	float f = floor(TIME * grain_fps);
	vec2 off = fract(vec2(f * 0.6180339, f * 0.4142135));
	float n = texture(noise_tex, uv / SCREEN_PIXEL_SIZE / 256.0 + off).r - 0.5;
	c += n * grain_strength;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
