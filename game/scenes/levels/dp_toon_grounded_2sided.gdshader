shader_type spatial;
// DP_ToonGrounded (DOUBLE-SIDED variant) — same 3-band toon look as
// dp_toon_grounded.gdshader but render_mode cull_disabled, so a camera that
// clips INTO the mesh (player gets close in melee) sees the solid inner wall
// instead of seeing through to the background. Use on CREATURES you fight up
// close (golem + roster). Props/CSG keep the cheaper single-sided shader.

render_mode cull_disabled, depth_draw_opaque, specular_disabled, ambient_light_disabled;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_vertex_color = false;

uniform float thresh_mid   : hint_range(0.0, 1.0) = 0.30;
uniform float thresh_light : hint_range(0.0, 1.0) = 0.65;
uniform float edge_smooth  : hint_range(0.0, 0.1) = 0.025;

uniform vec4  shadow_tint   : source_color = vec4(0.478, 0.561, 0.769, 1.0);
uniform float shadow_tint_strength : hint_range(0.0, 1.0) = 0.45;
uniform float shadow_darkness : hint_range(0.0, 1.0) = 0.52;

uniform float rim_power     : hint_range(1.0, 16.0) = 5.0;
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.30;
uniform vec4  rim_tint      : source_color = vec4(0.97, 0.86, 0.64, 1.0);

void fragment() {
	vec4 base = albedo_color;
	if (use_vertex_color) {
		base *= COLOR;
	}
	ALBEDO   = base.rgb;
	// No ALPHA write — stay opaque (writing ALPHA = transparency pipeline = see-through).
	ROUGHNESS = 1.0;
	METALLIC  = 0.0;
}

void light() {
	// Faces the camera sees from inside have flipped facing; abs() keeps both
	// sides lit consistently so the inner wall reads solid, not black.
	float n_dot_l = max(abs(dot(NORMAL, LIGHT)), 0.0);

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

	float shadow_factor = band;
	vec3 lit_color = ALBEDO * LIGHT_COLOR * ATTENUATION * band;
	float in_shadow = 1.0 - shadow_factor;
	vec3 shadow_color = mix(ALBEDO * (1.0 - shadow_darkness),
	                         shadow_tint.rgb,
	                         shadow_tint_strength);
	vec3 contribution = mix(lit_color, shadow_color * ATTENUATION, in_shadow);
	DIFFUSE_LIGHT += contribution;

	float n_dot_v = max(dot(NORMAL, VIEW), 0.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity;
	rim *= smoothstep(0.0, 0.35, n_dot_l);
	SPECULAR_LIGHT += rim_tint.rgb * rim * ATTENUATION;
}
