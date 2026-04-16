// Ground item glow — pulse emission per rarity color.
// Aplica al MeshInstance3D del ItemDrop. Color y velocidad por @export desde GDScript.
//
// Uso:
//   var sm := ShaderMaterial.new()
//   sm.shader = preload("res://assets/art/shaders/ground_item_glow.gdshader")
//   sm.set_shader_parameter("rarity_color", color)
//   sm.set_shader_parameter("pulse_speed", 1.5)  # 1.0 common → 2.5 unique
//   sm.set_shader_parameter("base_albedo", type_color)

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_albedo : source_color = vec4(0.6, 0.6, 0.6, 1.0);
uniform vec4 rarity_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;
uniform float pulse_min : hint_range(0.0, 5.0) = 0.6;
uniform float pulse_max : hint_range(0.0, 8.0) = 2.4;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.5;
uniform float bind_locked : hint_range(0.0, 1.0) = 0.0; // 1.0 mientras está bind-on-drop (intensifica)

void fragment() {
    ALBEDO = base_albedo.rgb;

    // Pulse sin con offset por TIME — uniforme por instancia (no por vertex)
    float pulse = mix(pulse_min, pulse_max, 0.5 + 0.5 * sin(TIME * pulse_speed));

    // Boost extra mientras está locked al owner
    pulse *= mix(1.0, 1.6, bind_locked);

    // Fresnel rim — borde brilla más, lectura desde lejos
    float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    EMISSION = rarity_color.rgb * pulse + rarity_color.rgb * rim * 0.8;
    METALLIC = 0.0;
    ROUGHNESS = 0.6;
}
