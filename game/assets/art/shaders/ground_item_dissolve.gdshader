// Ground item dissolve — el item se "deshace" y asciende.
// Combina con bind_expire_vfx.tscn (partículas alma/polvo).
// dissolve_amount 0.0 → visible normal, 1.0 → totalmente disuelto.
//
// Uso (driven por Tween en GDScript):
//   tween.tween_method(_set_dissolve, 0.0, 1.0, 1.0)  # 1 segundo
//   func _set_dissolve(v): mat.set_shader_parameter("dissolve_amount", v)

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_albedo : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.85, 0.4, 1.0); // dorado por defecto
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;
uniform float noise_scale : hint_range(0.5, 8.0) = 3.0;

// Hash noise simple — sin sampler. Determinístico por posición local.
float hash3(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash3(i);
    float n100 = hash3(i + vec3(1, 0, 0));
    float n010 = hash3(i + vec3(0, 1, 0));
    float n110 = hash3(i + vec3(1, 1, 0));
    float n001 = hash3(i + vec3(0, 0, 1));
    float n101 = hash3(i + vec3(1, 0, 1));
    float n011 = hash3(i + vec3(0, 1, 1));
    float n111 = hash3(i + vec3(1, 1, 1));
    return mix(
        mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
        mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
        f.z
    );
}

void fragment() {
    float n = noise3(VERTEX * noise_scale);
    float threshold = dissolve_amount;

    // Discard pixels by ascending Y bias — "se va para arriba"
    float y_bias = (VERTEX.y + 0.5) * 0.3;
    float local_threshold = threshold - y_bias;

    if (n < local_threshold) {
        discard;
    }

    ALBEDO = base_albedo.rgb;

    // Edge glow donde el noise está cerca del threshold
    float edge = smoothstep(local_threshold, local_threshold + edge_width, n);
    EMISSION = mix(edge_color.rgb * 3.0, vec3(0.0), edge);

    METALLIC = 0.0;
    ROUGHNESS = 0.6;
}
