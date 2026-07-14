extends Node3D
## golem_chunk_inspect.gd — Headless introspection of the chunked golem GLB.
## Prints every MeshInstance3D: name, local position, AABB size, vertex count.
## Goal: map chunks → body parts (torso / head / arms / legs) for the pivot rig.
##
## Run (headless OK — no rendering, just prints):
##   Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe \
##     --headless --path game res://scenes/dev/golem_chunk_inspect.tscn

const CHUNKS_GLB := "res://assets/art/piso1_pradera/enemies/big/golem_dp_chunks_01.glb"


func _ready() -> void:
	if not ResourceLoader.exists(CHUNKS_GLB):
		push_error("inspect: GLB not found: " + CHUNKS_GLB)
		get_tree().quit(1)
		return

	var packed := load(CHUNKS_GLB) as PackedScene
	var root := packed.instantiate()
	add_child(root)

	print("=== GOLEM CHUNK INSPECT ===")
	print("Root: %s (type %s)" % [root.name, root.get_class()])
	print("Direct children: %d" % root.get_child_count())
	print("")

	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	print("Total MeshInstance3D: %d" % meshes.size())
	print("")
	print("%-28s %-22s %-22s %8s" % ["NAME", "LOCAL_POS(x,y,z)", "AABB_SIZE(x,y,z)", "VERTS"])
	print(String("-").repeat(86))

	# Whole-model bounds
	var total := AABB()
	var first := true

	for m in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var aabb := mi.get_aabb()
		var gpos := mi.global_position
		var verts := 0
		for s in range(mi.mesh.get_surface_count()):
			var arr := mi.mesh.surface_get_arrays(s)
			if arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] != null:
				verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("%-28s (%6.2f,%6.2f,%6.2f) (%6.2f,%6.2f,%6.2f) %8d" % [
			mi.name.left(28),
			gpos.x, gpos.y, gpos.z,
			aabb.size.x, aabb.size.y, aabb.size.z,
			verts
		])
		var world_aabb := mi.global_transform * aabb
		if first:
			total = world_aabb
			first = false
		else:
			total = total.merge(world_aabb)

	print(String("-").repeat(86))
	print("WHOLE MODEL bounds: pos=%v  size=%v" % [total.position, total.size])
	print("Height (max dim): %.2f" % maxf(maxf(total.size.x, total.size.y), total.size.z))
	print("=== END ===")
	get_tree().quit()
