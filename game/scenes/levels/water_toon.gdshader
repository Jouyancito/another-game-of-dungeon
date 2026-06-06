shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

// Floor 1 toon water — penumbra mágica version (2026-06-06).
// Normal: smooth value-noise (2 octaves, hash at integer lattice + smoothstep bilinear)
//         replaces per-pixel fract(sin()) white noise that read as sandpaper/static.
// Color: darkened base (cavern) + faint cool-crystal emission so water catches crystal glow.
// Single transparent layer (perf red-line #5). No reflections.

uniform float time_scale     : hint_range(0.1, 2.0) = 0.8;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.05;
uniform float wave_frequency : hint_range(0.5, 3.0) = 2.0;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.18;   // reduced: gentle ripples, not static
uniform vec3  water_color    : source_color = vec3(0.10, 0.22, 0.36); // darkened for cavern penumbra
uniform float base_transparency : hint_range(0.3, 1.0) = 0.7;
uniform vec3  crystal_emission : source_color = vec3(0.85, 0.90, 1.00); // cool-crystal glow tint
uniform float emission_strength : hint_range(0.0, 0.3) = 0.06;  // subtle — catches crystal light

// ── Smooth value noise helpers ────────────────────────────────────────────────
// Hash at integer lattice (returns [-1, 1])
float _hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y) * 2.0 - 1.0;
}

// Bilinear value noise: smooth interpolation between lattice points
float _vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep
	float a = _hash(i);
	float b = _hash(i + vec2(1.0, 0.0));
	float c = _hash(i + vec2(0.0, 1.0));
	float d = _hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 2-octave smooth normal derivation (returns xy normal offset)
vec2 _ripple_normal(vec2 uv, float t) {
	// Octave 1 — large slow ripples
	float o1 = _vnoise(uv * 2.5 + vec2(t * 0.20, t * 0.11));
	// Octave 2 — smaller faster detail
	float o2 = _vnoise(uv * 5.5 + vec2(-t * 0.17, t * 0.23)) * 0.45;
	// Approximate gradient via finite differences (cheap, no analytical deriv needed)
	float eps = 0.04;
	float dx = _vnoise((uv + vec2(eps, 0.0)) * 2.5 + vec2(t * 0.20, t * 0.11))
	         + _vnoise((uv + vec2(eps, 0.0)) * 5.5 + vec2(-t * 0.17, t * 0.23)) * 0.45
	         - (o1 + o2);
	float dz = _vnoise((uv + vec2(0.0, eps)) * 2.5 + vec2(t * 0.20, t * 0.11))
	         + _vnoise((uv + vec2(0.0, eps)) * 5.5 + vec2(-t * 0.17, t * 0.23)) * 0.45
	         - (o1 + o2);
	return vec2(dx, dz) / eps;
}

void vertex() {
	float w = sin(VERTEX.x * wave_frequency + TIME * time_scale) * wave_amplitude;
	w += sin(VERTEX.z * wave_frequency * 0.7 + TIME * time_scale * 0.8) * wave_amplitude * 0.5;
	VERTEX.y += w;
}

void fragment() {
	float t = TIME * time_scale;
	vec2 grad = _ripple_normal(UV, t);

	// Build smooth normal: scale gradient by normal_strength (gentle, not sandpaper)
	vec3 n = normalize(vec3(grad.x * normal_strength, 1.0, grad.y * normal_strength));
	NORMAL = n;

	float fresnel = pow(1.0 - abs(dot(VIEW, NORMAL)), 2.0);

	// Base color (dark cavern water) + tiny animated shimmer
	ALBEDO = water_color + vec3(sin(t * 0.5) * 0.03 + 0.02) * 0.08;

	// Faint cool-crystal emission — water subtly glows like it catches crystal light
	EMISSION = crystal_emission * emission_strength * (0.6 + fresnel * 0.4);

	ALPHA = mix(base_transparency * 0.6, base_transparency, fresnel);
	ROUGHNESS = 0.25;
}
