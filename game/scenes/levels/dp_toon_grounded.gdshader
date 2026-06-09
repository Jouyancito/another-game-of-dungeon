shader_type spatial;
// DP_ToonGrounded — Dungeon Party toon shader for procedural CSG geometry (pillars,
// ruins, walls, altar, border, camp props, etc.) on Floor 1 Prairie.
//
// Design goals (D2-Act-1 hybrid look):
//   • PRESERVE each mesh's albedo (vertex COLOR or uniform albedo_color).
//   • 3-band hard toon ramp: shadow | mid | light.
//   • Shadow tint = COOL NON-BLACK (#7A8FC4 hue-shifted slate-blue) — never pure black.
//     Gives cool cave shadow vs warm key contrast without losing surface read.
//   • Matte (roughness=1, metallic=0, specular disabled).
//   • Optional cheap rim term to silhouette geometry against shadow.
//
// Usage: applied through _make_material() in floor1_prairie.gd as ShaderMaterial.
// All procedural/CSG assets share this shader; gltf scatter packs keep their own
// materials (a future material_override pass would extend to them).

render_mode cull_back, depth_draw_opaque, specular_disabled, ambient_light_disabled;

// ── Albedo ───────────────────────────────────────────────────────────────────
// Base color; multiplied by vertex color when use_vertex_color=true.
// _make_material() sets this to the COLOR_* constant for the surface.
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_vertex_color : hint_default_false = false;

// ── Toon ramp (3 bands) ──────────────────────────────────────────────────────
// band_shadow = fraction of full brightness for the darkest band (lit=0 side).
// band_mid    = fraction for the middle band.
// band_light  = fraction for the fully lit band (NdotL high side) = 1.0.
// Thresholds: < thresh_mid = shadow band, < thresh_light = mid band, else light.
uniform float thresh_mid   : hint_range(0.0, 1.0) = 0.30;
uniform float thresh_light : hint_range(0.0, 1.0) = 0.65;
uniform float edge_smooth  : hint_range(0.0, 0.1) = 0.025;  // softens band edge

// ── Shadow tint ──────────────────────────────────────────────────────────────
// Non-black shadow fill hue-shifted toward cool slate-blue (#7A8FC4).
// Strength 0..1: 0 = pure darkening, 1 = full shadow_tint applied.
uniform vec4  shadow_tint   : source_color = vec4(0.478, 0.561, 0.769, 1.0);  // #7A8FC4
uniform float shadow_tint_strength : hint_range(0.0, 1.0) = 0.45;
// Overall darkness of the shadow band (0 = surface color, 1 = fully tinted)
uniform float shadow_darkness : hint_range(0.0, 1.0) = 0.52;

// ── Rim light ─────────────────────────────────────────────────────────────────
// Cheap Fresnel rim to silhouette against cave darkness. Keep low by default.
uniform float rim_power     : hint_range(1.0, 16.0) = 5.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.30;
uniform vec4  rim_tint      : source_color = vec4(0.97, 0.86, 0.64, 1.0);  // warm gold rim

void fragment() {
	vec4 base = albedo_color;
	if (use_vertex_color) {
		base *= COLOR;
	}
	ALBEDO   = base.rgb;
	ALPHA    = base.a;
	ROUGHNESS = 1.0;
	METALLIC  = 0.0;
}

void light() {
	float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);

	// ── 3-band toon ramp ────────────────────────────────────────────────────
	float band;
	if (n_dot_l < thresh_mid - edge_smooth) {
		band = 0.0;
	} else if (n_dot_l < thresh_mid + edge_smooth) {
		band = smoothstep(thresh_mid - edge_smooth, thresh_mid + edge_smooth, n_dot_l) * 0.5;
	} else if (n_dot_l < thresh_light - edge_smooth) {
		band = 0.5;
	} else if (n_dot_l < thresh_light + edge_smooth) {
		band = 0.5 + smoothstep(thresh_light - edge_smooth, thresh_light + edge_smooth, n_dot_l) * 0.5;
	} else {
		band = 1.0;
	}

	// ── Cool non-black shadow tint ───────────────────────────────────────────
	// shadow_factor = 1 in lit areas, 0 in shadow band.
	float shadow_factor = band;  // 0..1

	// Base surface lit by light_color * band
	vec3 lit_color = ALBEDO * LIGHT_COLOR * ATTENUATION * band;

	// In shadow: blend between darkened surface and the cool tint
	float in_shadow = 1.0 - shadow_factor;
	vec3 shadow_color = mix(ALBEDO * (1.0 - shadow_darkness),
	                         shadow_tint.rgb,
	                         shadow_tint_strength);
	vec3 contribution = mix(lit_color, shadow_color * ATTENUATION, in_shadow);

	DIFFUSE_LIGHT += contribution;

	// ── Rim (only on lit half, warm gold) ────────────────────────────────────
	float n_dot_v = max(dot(NORMAL, VIEW), 0.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity;
	rim *= smoothstep(0.0, 0.35, n_dot_l);  // no rim on fully unlit side
	SPECULAR_LIGHT += rim_tint.rgb * rim * ATTENUATION;
}
