extends Node3D
## One-shot bone discovery — prints bone_0..bone_27 rest positions (global) and
## parent index so we can map them to anatomy.
##
## Run:
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/golem_bone_discover.tscn
##
## Read the printed output to get the anatomy map, then delete this scene.

const RIGGED_GLB := "res://tools/blender/golem_rigged.glb"


func _ready() -> void:
	if not ResourceLoader.exists(RIGGED_GLB):
		push_error("golem_bone_discover: GLB not found: " + RIGGED_GLB)
		get_tree().quit()
		return

	var packed := load(RIGGED_GLB) as PackedScene
	if packed == null:
		push_error("golem_bone_discover: failed to load GLB")
		get_tree().quit()
		return

	var rig := packed.instantiate() as Node3D
	rig.name = "GolemRig"
	add_child(rig)
	# The rig was built Z-up in Blender; apply -90 X so bone world positions match
	# the "standing upright" pose we see in the preview.
	rig.rotation_degrees.x = -90.0

	# Wait a few frames for Godot to set up the skeleton
	for _i in range(10):
		await get_tree().process_frame

	var skel := _find_skeleton(rig)
	if skel == null:
		push_error("golem_bone_discover: no Skeleton3D found")
		get_tree().quit()
		return

	print("\n=== GOLEM BONE MAP (28 bones, UniRig) ===")
	print("idx    name        X         Y         Z       parent")
	print("------  ----------  --------  --------  --------  ------")

	for i in range(skel.get_bone_count()):
		var rest_local := skel.get_bone_rest(i)
		# Rest pose is local; to get a rough world sense, accumulate up the chain
		var global_rest := _bone_global_rest(skel, i)
		var parent_idx := skel.get_bone_parent(i)
		print("%d  %s  %.2f  %.2f  %.2f  %d" % [
			i,
			skel.get_bone_name(i),
			global_rest.origin.x,
			global_rest.origin.y,
			global_rest.origin.z,
			parent_idx
		])

	print("\n=== END BONE MAP ===\n")
	get_tree().quit()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var r := _find_skeleton(child)
		if r != null:
			return r
	return null


## Accumulate local rest transforms up the chain to get approximate world rest.
func _bone_global_rest(skel: Skeleton3D, bone_idx: int) -> Transform3D:
	var xform := skel.get_bone_rest(bone_idx)
	var parent := skel.get_bone_parent(bone_idx)
	while parent >= 0:
		xform = skel.get_bone_rest(parent) * xform
		parent = skel.get_bone_parent(parent)
	# Apply the -90° X rotation we put on the rig node (Blender Z-up → Godot Y-up)
	var fix := Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(-90.0)), Vector3.ZERO)
	return fix * xform
