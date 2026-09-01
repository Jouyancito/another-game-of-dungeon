extends SceneTree
## One-shot probe: what materials and vertex data does the worn kit actually
## ship with inside Godot? Run:
##   godot --headless --path game --script res://scenes/dev/_probe_kit.gd


func _init() -> void:
	var ps: PackedScene = load("res://assets/art/piso1_pradera/props/water/river_rock_worn_kit.glb")
	if ps == null:
		print("PROBE: kit failed to load")
		quit()
		return
	var root: Node = ps.instantiate()
	_walk(root)
	root.free()
	quit()


func _walk(n: Node) -> void:
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			for s in range(m.get_surface_count()):
				var arrs: Array = m.surface_get_arrays(s)
				var has_col: bool = arrs[Mesh.ARRAY_COLOR] != null
				var col_sample: String = "-"
				if has_col:
					var cols: PackedColorArray = arrs[Mesh.ARRAY_COLOR]
					if cols.size() > 0:
						col_sample = str(cols[0])
				var mat: Material = m.surface_get_material(s)
				var mat_cls: String = "null" if mat == null else mat.get_class()
				print("%s surf%d mat=%s vcol=%s sample=%s" % [n.name, s, mat_cls, str(has_col), col_sample])
				if mat is BaseMaterial3D:
					var bm := mat as BaseMaterial3D
					print("   albedo_tex=%s albedo_color=%s vcol_albedo=%s" % [
						str(bm.albedo_texture), str(bm.albedo_color), str(bm.vertex_color_use_as_albedo)])
	for c in n.get_children():
		_walk(c)
