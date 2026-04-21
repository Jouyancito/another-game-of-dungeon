shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_disabled;

// --- Albedo ---
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_albedo_texture = false;

// --- Toon ramp ---
// 3 steps por default: shadow / mid / light
uniform float ramp_steps : hint_range(2.0, 6.0, 1.0) = 3.0;
uniform float ramp_smoothness : hint_range(0.0, 0.2) = 0.02;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.55;

// --- Rim light ---
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_power : hint_range(0.5, 16.0) = 4.0;
uniform float rim_intensity : hint_range(0.0, 4.0) = 1.0;

// --- Emission opcional (VFX / props emisivos) ---
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;

void fragment() {
	vec4 base_col = albedo_color;
	if (use_albedo_texture) {
		base_col *= texture(albedo_texture, UV);
	}
	ALBEDO = base_col.rgb;
	ALPHA = base_col.a;
	EMISSION = emission_color.rgb * emission_energy;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	// NdotL raw
	float n_dot_l = dot(NORMAL, LIGHT);
	float lambert = max(n_dot_l, 0.0);

	// Step into ramp bands
	float steps = max(ramp_steps, 2.0);
	float band = floor(lambert * steps) / steps;
	// Soften the boundary between bands
	float band_next = clamp(band + 1.0 / steps, 0.0, 1.0);
	float alpha = smoothstep(band, band + ramp_smoothness, lambert);
	float shade = mix(band, band_next, alpha);

	// Remap so lowest band is not pitch black — respect shadow_intensity
	shade = mix(1.0 - shadow_intensity, 1.0, shade);

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * shade;

	// Rim light (Fresnel-like) — only for primary directional-like lights
	float rim_n_dot_v = 1.0 - max(dot(NORMAL, VIEW), 0.0);
	float rim = pow(rim_n_dot_v, rim_power) * rim_intensity;
	// Only on lit side to avoid fully bright silhouette in shadow
	rim *= smoothstep(0.0, 0.3, lambert);
	SPECULAR_LIGHT += rim_color.rgb * rim * ATTENUATION;
}
