extends SceneTree
## Dumps MeshInstance3D surfaces + material names of a scene/glb so material-name
## based overrides can be verified after import. Usage:
##   Godot --headless --path game --script res://tools/godot/_dump_materials.gd -- <res_path>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var target: String = args[0] if args.size() > 0 else \
		"res://assets/art/piso1_pradera/enemies/big/golem_dp_body_01.glb"
	var ps: PackedScene = load(target) as PackedScene
	if ps == null:
		push_error("_dump_materials: cannot load " + target)
		quit(1)
		return
	var root := ps.instantiate()
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		if m == null:
			continue
		print("MESH ", mi.name, " surfaces=", m.get_surface_count())
		for s in range(m.get_surface_count()):
			var mat := m.surface_get_material(s)
			var mat_name: String = mat.resource_name if mat != null else "<null>"
			var mat_class: String = mat.get_class() if mat != null else "-"
			print("  surf ", s, " mat=", mat_name, " class=", mat_class)
	root.free()
	quit(0)
