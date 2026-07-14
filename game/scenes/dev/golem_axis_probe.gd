extends Node3D
## golem_axis_probe.gd — Empirically MEASURE which local axis does what on each
## UniRig bone of golem_rigged.glb. No guessing.
##
## For a set of key bones, rotates the bone +PROBE_DEG around each local axis
## (X, Y, Z) RELATIVE TO ITS REST POSE (rest * delta), renders one frame per
## (bone, axis) into an off-screen SubViewport, saves a labeled PNG.
##
## Also probes L-hip vs R-hip to CONFIRM the documented rig defect
## ("R leg co-moves with L leg").
##
## NON-INTRUSIVE: main window parked at (-4000,-4000), 1x1 px, FLAG_NO_FOCUS.
##
## Run (Godot 4.6 win64, nested binary):
##   Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64.exe \
##     --path game res://scenes/dev/golem_axis_probe.tscn
##
## Output: game/tools/godot/axis_probe/<label>.png

const RIGGED_GLB := "res://tools/blender/golem_rigged.glb"
const TOON_SHADER := "res://scenes/levels/dp_toon_grounded.gdshader"
const STONE_ALBEDO := Color(0.52, 0.50, 0.46)
const TARGET_HEIGHT_M := 4.8
const PROBE_DEG := 45.0
const SV_SIZE := Vector2i(720, 810)

# Bones to probe: [bone_idx, friendly_name]
const PROBE_BONES := [
	[3,  "spine_upper"],
	[4,  "head_base"],
	[13, "R_shoulder"],
	[14, "R_upper_arm"],
	[15, "R_forearm"],
	[17, "R_fist"],
	[20, "L_hip"],
	[24, "R_hip"],
]

const AXES := [
	[Vector3.RIGHT, "X"],
	[Vector3.UP,    "Y"],
	[Vector3.BACK,  "Z"],
]

var _rig: Node3D = null
var _skeleton: Skeleton3D = null
var _cam: Camera3D = null
var _sv: SubViewport = null
var _label: Label = null

var _target := Vector3(0.0, 2.4, 0.0)
var _yaw := 0.85
var _pitch := 0.20
var _dist := 9.5
var _out_dir := "res://tools/godot/axis_probe/"


func _ready() -> void:
	# Park main window off-screen
	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)

	# Off-screen SubViewport
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	_add_lights()
	_add_environment()
	_add_scale_reference()

	if not ResourceLoader.exists(RIGGED_GLB):
		push_error("axis_probe: rigged GLB not found: " + RIGGED_GLB)
		get_tree().quit(1)
		return

	var packed := load(RIGGED_GLB) as PackedScene
	_rig = packed.instantiate() as Node3D
	_rig.name = "GolemRig"
	_sv.add_child(_rig)
	_rig.rotation_degrees.x = -90.0
	_auto_scale_rig()

	_skeleton = _find_skeleton(_rig)
	if _skeleton == null:
		push_error("axis_probe: no Skeleton3D found")
		get_tree().quit(1)
		return

	_apply_stone(_rig)

	_cam = Camera3D.new()
	_cam.fov = 56.0
	_sv.add_child(_cam)
	_cam.current = true

	_add_hud()

	var da := DirAccess.open("res://")
	if da:
		da.make_dir_recursive("tools/godot/axis_probe")

	# Settle import
	for _i in range(40):
		await get_tree().process_frame

	# DEFAULT mode: capture the GLB's imported default pose WITHOUT touching bones,
	# to verify whether the sprawl is the rig itself or our reset.
	var uargs := OS.get_cmdline_user_args()
	if uargs.size() > 0 and uargs[0] == "default":
		await _capture("00_DEFAULT_nopose", "GLB imported default pose — NO bone reset")
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()
		return

	# REST frame first
	_reset_all_bones()
	await _capture("00_REST", "rest pose (no rotation)")

	# Probe each bone × axis
	var n := 1
	for entry in PROBE_BONES:
		var bone: int = entry[0]
		var bname: String = entry[1]
		for axis_entry in AXES:
			var axis: Vector3 = axis_entry[0]
			var axis_name: String = axis_entry[1]
			_reset_all_bones()
			_rotate_bone_from_rest(bone, axis, PROBE_DEG)
			var label := "%02d_bone%02d_%s_%s+%d" % [n, bone, bname, axis_name, int(PROBE_DEG)]
			await _capture(label, "%s (bone_%d) — local %s axis +%d deg" % [bname, bone, axis_name, int(PROBE_DEG)])
			n += 1

	await get_tree().create_timer(0.3).timeout
	print("[axis_probe] DONE — %d probe frames → %s" % [n, _out_dir])
	get_tree().quit()


func _reset_all_bones() -> void:
	for i in range(_skeleton.get_bone_count()):
		var rest := _skeleton.get_bone_rest(i)
		_skeleton.set_bone_pose_rotation(i, rest.basis.get_rotation_quaternion())
		_skeleton.set_bone_pose_position(i, rest.origin)


func _rotate_bone_from_rest(bone: int, axis: Vector3, deg: float) -> void:
	# Apply delta RELATIVE to rest: pose = rest_rot * delta
	var rest := _skeleton.get_bone_rest(bone)
	var rest_q := rest.basis.get_rotation_quaternion()
	var delta := Quaternion(axis.normalized(), deg_to_rad(deg))
	_skeleton.set_bone_pose_rotation(bone, rest_q * delta)


func _capture(label: String, hint: String) -> void:
	if _label != null:
		_label.text = label + "  |  " + hint
	# Let pose + render settle
	for _i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		push_warning("[axis_probe] null image for " + label)
		return
	var err := img.save_png(_out_dir + label + ".png")
	if err == OK:
		print("[axis_probe] saved %s.png" % label)
	else:
		push_warning("[axis_probe] save failed for %s (err=%d)" % [label, err])


func _process(_delta: float) -> void:
	if _cam != null:
		var off := Vector3(
			cos(_pitch) * sin(_yaw),
			sin(_pitch),
			cos(_pitch) * cos(_yaw)
		) * _dist
		_cam.position = _target + off
		_cam.look_at(_target, Vector3.UP)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var r := _find_skeleton(child)
		if r != null:
			return r
	return null


func _auto_scale_rig() -> void:
	var aabb := AABB()
	var found := false
	for mi_node in _rig.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		var local_aabb := mi.transform * mi.get_aabb()
		if not found:
			aabb = local_aabb
			found = true
		else:
			aabb = aabb.merge(local_aabb)
	if not found:
		_rig.scale = Vector3.ONE * 2.0
		return
	var height := maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	if height < 0.01:
		_rig.scale = Vector3.ONE * 2.0
		return
	_rig.scale = Vector3.ONE * (TARGET_HEIGHT_M / height)


func _apply_stone(root: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = STONE_ALBEDO
	stone.roughness = 0.92
	stone.metallic = 0.0
	stone.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.42, 0.40, 0.36)
	eye.emission_enabled = true
	eye.emission = Color(0.373, 0.847, 1.0)
	eye.emission_energy_multiplier = 1.6
	for mi_node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_node as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.name.to_lower().contains("eye"):
			mi.material_override = eye
		else:
			mi.material_override = stone


func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.85)
	key.light_energy = 1.55
	key.rotation_degrees = Vector3(-48, 140, 0)
	key.shadow_enabled = true
	_sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.66, 0.92)
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-55, -38, 0)
	_sv.add_child(fill)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.18, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.44, 0.58)
	env.ambient_light_energy = 0.60
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)


func _add_scale_reference() -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.30, 1.8, 0.30)
	post.mesh = box
	post.position = Vector3(3.0, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.28)
	post.material_override = mat
	_sv.add_child(post)


func _add_hud() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	_sv.add_child(cl)
	_label = Label.new()
	_label.position = Vector2(12, 10)
	_label.add_theme_font_size_override("font_size", 16)
	_label.modulate = Color(1.0, 0.85, 0.3)
	_label.text = "axis_probe"
	cl.add_child(_label)
