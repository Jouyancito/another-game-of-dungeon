shader_type spatial;
// Inverse hull outline — usar en MeshInstance3D HIJO con surface_material_override
// cull_front = renderiza backfaces expandidas hacia afuera = outline.
render_mode unshaded, cull_front, depth_draw_opaque, skip_vertex_transform;

uniform vec4 outline_color : source_color = vec4(0.04, 0.04, 0.06, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.015;

void vertex() {
	// Expand along normal in local space, then transform
	vec3 inflated = VERTEX + NORMAL * outline_thickness;
	VERTEX = (MODEL_MATRIX * vec4(inflated, 1.0)).xyz;
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
