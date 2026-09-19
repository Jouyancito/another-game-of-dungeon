extends Node3D
## Renders an enemy scene AS GODOT DRAWS IT — the only honest judge of a mob's
## look. Blender showcase renders are not: the slime shipped for weeks looking
## like green jelly in its build render while the GLB carried no vertex colour
## at all and Godot drew a white dome (measured 2026-07-29, see
## docs/art/_motor_tiers.md).
##
## NON-INTRUSIVE: renders into an off-screen SubViewport. The main window is
## parked at (-4000,-4000), shrunk to 1x1 px with FLAG_NO_FOCUS, so it never
## steals focus or screen space — same pattern as biome_capture.gd.
##
## Run (from repo root):
##   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/mob_capture.tscn \
##       [-- --mob res://scenes/enemy/slime.tscn] [--clip idle] [--frames 6]
##
## Output: game/tools/godot/mob_capture/<mob>_<angle>.png + _report.txt
##
## The mob is lit by a plain neutral rig, NOT the level's lighting — the point
## is to judge the asset, not the scene. A 1.75m player-height post stands
## beside it so the scale claim is checkable rather than asserted.

const OUT_DIR := "res://tools/godot/mob_capture/"
const SV_SIZE := Vector2i(900, 900)
const POST_HEIGHT := 1.75

var _sv: SubViewport
var _cam: Camera3D
var _mob: Node3D
var _mob_path := "res://scenes/enemy/slime.tscn"
var _clip := ""
var _anim_frames := 0
var _report: Array[String] = []
var _hidden_hud: Array[String] = []
var _blend_overrides: Dictionary = {}
var _fake_velocity := Vector3.ZERO
var _drive_script := false
var _lean_sweep := 0


func _ready() -> void:
	_parse_args()
	DisplayServer.window_set_position(Vector2i(-4000, -4000))
	DisplayServer.window_set_size(Vector2i(1, 1))
	get_window().set_flag(Window.FLAG_NO_FOCUS, true)
	_build_viewport()
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture_all()
	_write_report()
	get_tree().quit()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--mob":
				if i + 1 < args.size():
					_mob_path = args[i + 1]
					i += 1
			"--clip":
				if i + 1 < args.size():
					_clip = args[i + 1]
					i += 1
			"--frames":
				if i + 1 < args.size():
					_anim_frames = int(args[i + 1])
					i += 1
			"--lean-sweep":
				# Frame count for a there-and-back sweep of the directional lean,
				# written out as a numbered sequence _make_gifs.py can assemble.
				# A lean is a continuous deformation; four stills prove the shape
				# keys exist but say nothing about whether the motion reads.
				if i + 1 < args.size():
					_lean_sweep = int(args[i + 1])
					i += 1
			"--velocity":
				# x,z — drives the mob's OWN per-frame script (not a blend
				# override) so a velocity-driven deformation can be verified
				# end to end without playing the game.
				if i + 1 < args.size():
					var v := args[i + 1].split(",")
					if v.size() >= 2:
						_fake_velocity = Vector3(float(v[0]), 0.0, float(v[1]))
						_drive_script = true
					i += 1
			"--blend":
				# name=value, repeatable. Applies a blend shape by NAME before
				# capturing, so a script-driven deformation (a directional lean,
				# say) can be judged on its own without running gameplay.
				if i + 1 < args.size():
					var spec: String = args[i + 1]
					if "=" in spec:
						var parts := spec.split("=", true, 1)
						_blend_overrides[parts[0]] = float(parts[1])
					i += 1
		i += 1


func _build_viewport() -> void:
	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	add_child(_sv)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.30, 0.22, 0.48)   # contract ficha purple
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.63, 0.68)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.5
	key.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.light_color = Color(0.82, 0.88, 1.0)
	fill.rotation_degrees = Vector3(-18.0, 140.0, 0.0)
	_sv.add_child(fill)

	# Ground so the mob is not floating in a void — contact sells the weight.
	# It needs REAL collision on the world layer: with a bare MeshInstance3D the
	# mob's CharacterBody3D fell straight through and left frame after the first
	# shot, which read as a framing bug for two passes.
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1        # layer 1 = World
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(14.0, 0.4, 14.0)
	col.shape = box_shape
	col.position = Vector3(0.0, -0.2, 0.0)
	floor_body.add_child(col)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14.0, 14.0)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.34, 0.30, 0.26)
	gm.roughness = 0.95
	ground.material_override = gm
	floor_body.add_child(ground)
	_sv.add_child(floor_body)

	_sv.add_child(_make_scale_post())

	_cam = Camera3D.new()
	_cam.fov = 40.0
	_sv.add_child(_cam)

	var ps := load(_mob_path) as PackedScene
	if ps == null:
		_report.append("FAILED to load %s" % _mob_path)
		return
	_mob = ps.instantiate() as Node3D
	_sv.add_child(_mob)
	# AFTER add_child: _ready() runs on entering the tree and re-enables
	# processing, so disabling it beforehand had no effect. The AnimationPlayer
	# is a separate node and keeps running, which is what clip capture needs.
	_mob.set_physics_process(false)
	# _process stays ON when a velocity is being faked: that is where a
	# velocity-driven deformation lives, and switching it off would test the
	# shape keys while quietly skipping the code that drives them.
	_mob.set_process(_drive_script)
	_mob.global_position = Vector3.ZERO
	_hide_hud_nodes(_mob)


func _hide_hud_nodes(n: Node) -> void:
	## Hide in-world HUD (health bar, nameplate) so it cannot be mistaken for the
	## asset — judging a mob with its own UI drawn over it is judging the wrong
	## thing, and on a translucent body the bar is visible through the mesh.
	##
	## It is NOT the cause of the horizontal band across a translucent mob: that
	## band survives with both bars hidden and is simply the ground horizon seen
	## THROUGH the gel (body colour over purple sky above the line, over brown
	## ground below it). The side shot settles it — the red scale post is plainly
	## visible through the slime. Transparency working, not a sorting defect.
	var name_lower := n.name.to_lower()
	for marker in ["hpbar", "healthbar", "health_bar", "nameplate", "name_label", "hud"]:
		if name_lower.contains(marker):
			var was_visible := true
			if n is Node3D:
				was_visible = (n as Node3D).visible
				(n as Node3D).visible = false
			elif n is CanvasItem:
				was_visible = (n as CanvasItem).visible
				(n as CanvasItem).visible = false
			if was_visible and not _hidden_hud.has(n.name):
				_hidden_hud.append(n.name)
				_report.append("hid HUD node '%s'" % n.name)
			break
	# Keep walking siblings and children regardless — HPBarBG and HPBarFill are
	# separate nodes, so returning on the first match left one of them visible.
	for c in n.get_children():
		_hide_hud_nodes(c)


func _blend_target() -> MeshInstance3D:
	for mi in _find_meshes(_mob):
		if mi.mesh != null and mi.mesh.get_blend_shape_count() > 0:
			return mi
	return null


func _apply_blend_overrides() -> void:
	if _blend_overrides.is_empty():
		return
	var mi := _blend_target()
	if mi == null:
		return
	var mesh := mi.mesh
	for i in mesh.get_blend_shape_count():
		var nm := String(mesh.get_blend_shape_name(i))
		if _blend_overrides.has(nm):
			mi.set_blend_shape_value(i, float(_blend_overrides[nm]))


func _audit_blend_persistence() -> void:
	## Does a script-set blend shape SURVIVE the AnimationPlayer?
	##
	## glTF packs the whole morph-weight array into ONE animation channel, so a
	## clip rewrites every weight each time it evaluates — including shapes the
	## clip was never meant to own. If that happens, a directional lean driven
	## from GDScript is silently zeroed and looks like a broken shape key.
	## Written as a number rather than an eyeball: set it, let the player run,
	## read it back.
	var mi := _blend_target()
	if mi == null or _blend_overrides.is_empty():
		return
	var mesh := mi.mesh
	for i in mesh.get_blend_shape_count():
		var nm := String(mesh.get_blend_shape_name(i))
		if not _blend_overrides.has(nm):
			continue
		var wanted := float(_blend_overrides[nm])
		var got := mi.get_blend_shape_value(i)
		var verdict := "SURVIVED" if absf(got - wanted) < 0.001 else "OVERWRITTEN"
		_report.append("blend '%s': set %.3f -> read %.3f  %s" % [nm, wanted, got, verdict])


func _make_scale_post() -> Node3D:
	var post := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = POST_HEIGHT
	post.mesh = cyl
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.75, 0.12, 0.12)
	pm.roughness = 0.8
	post.material_override = pm
	post.position = Vector3(1.5, POST_HEIGHT * 0.5, 0.0)
	return post


func _rest_bounds() -> AABB:
	## Rest-pose bounds in world space, built from the surface VERTEX arrays.
	##
	## MeshInstance3D.get_aabb() cannot be used here: it covers every morph
	## target's extent, so a mob with a "melt" shape key reports the flattened
	## puddle's width and a "stretch" key inflates its height (measured on the
	## slime: 1.26 m reported vs 0.99 m actually standing). Framing off that
	## number pushes the camera too far out and aims it above the subject.
	var box := AABB()
	var first := true
	for mi in _find_meshes(_mob):
		var mesh := mi.mesh
		if mesh == null or not (mesh is ArrayMesh):
			continue
		var xform := mi.global_transform
		for s in mesh.get_surface_count():
			var arrays := (mesh as ArrayMesh).surface_get_arrays(s)
			if arrays.size() <= Mesh.ARRAY_VERTEX or arrays[Mesh.ARRAY_VERTEX] == null:
				continue
			for v in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var wp := xform * v
				if first:
					box = AABB(wp, Vector3.ZERO)
					first = false
				else:
					box = box.expand(wp)
	return box


func _find_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out


func _aim(angle_deg: float, dist: float, cam_height: float, look_at_point: Vector3) -> void:
	## look_at_point is explicit: deriving it from the camera height (the first
	## version's `height * 0.45`) aimed the close-up at the ground and rendered
	## an empty frame.
	var a := deg_to_rad(angle_deg)
	_cam.position = look_at_point + Vector3(sin(a) * dist, cam_height, cos(a) * dist)
	_cam.look_at(look_at_point, Vector3.UP)


func _save(name: String) -> void:
	# Let the camera move take effect BEFORE waiting on the draw. Awaiting
	# frame_post_draw alone captures a frame whose draw had already begun with
	# the previous transform, so every shot came out framed like the one before
	# it (empty frames once the sequence moved far).
	if _mob != null:
		_mob.global_position = Vector3.ZERO   # belt and braces against any drift
		# Re-hide every shot: the health bar is built during runtime setup, so
		# hiding it once right after add_child() ran before it existed.
		_hide_hud_nodes(_mob)
		if _drive_script and _mob is CharacterBody3D:
			# Physics is off, so nothing else keeps this set; re-assert it every
			# shot so the mob's own _process keeps seeing the movement.
			(_mob as CharacterBody3D).velocity = _fake_velocity
		_apply_blend_overrides()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	var dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join("%s.png" % name))
	print("[mob_capture] saved %s.png" % name)


func _capture_all() -> void:
	if _mob == null:
		return
	var mob_name := _mob_path.get_file().get_basename()
	var box := _rest_bounds()
	var h: float = box.size.y
	var widest: float = max(box.size.x, box.size.z)
	var centre := box.get_center()
	_report.append("mob        = %s" % _mob_path)
	_report.append("rest size  = %.3f m tall x %.3f m wide (player post = %.2f m)" % [
		h, widest, POST_HEIGHT])
	_report.append("proportion = %.2f : 1 (width : height)" % (widest / max(h, 0.001)))

	var players := _find_anim_players(_mob)
	if players.is_empty():
		_report.append("clips      = (no AnimationPlayer)")
	else:
		var ap := players[0]
		_report.append("clips      = %s" % ", ".join(ap.get_animation_list()))

	if _drive_script:
		_report.append("fake vel   = %s (mob's own _process left running)" % _fake_velocity)
		if _mob is CharacterBody3D:
			(_mob as CharacterBody3D).velocity = _fake_velocity
		# Let the smoothing settle — a lagged deformation needs time to arrive,
		# and sampling it on frame one would report almost zero.
		for _i in 40:
			await get_tree().process_frame
			if _mob is CharacterBody3D:
				(_mob as CharacterBody3D).velocity = _fake_velocity
		var mi_l := _blend_target()
		if mi_l != null:
			for i in mi_l.mesh.get_blend_shape_count():
				var nm := String(mi_l.mesh.get_blend_shape_name(i))
				if nm.begins_with("lean"):
					_report.append("driven '%s' = %.3f" % [nm, mi_l.get_blend_shape_value(i)])

	var blend_mi := _blend_target()
	if blend_mi != null:
		var names: Array[String] = []
		for i in blend_mi.mesh.get_blend_shape_count():
			names.append(String(blend_mi.mesh.get_blend_shape_name(i)))
		_report.append("blendshapes= %s" % ", ".join(names))
	if not _blend_overrides.is_empty():
		_report.append("overrides  = %s" % str(_blend_overrides))
		# Same ordering the mob's own script uses: an AnimationPlayer left on
		# automatic rewrites the whole morph array after we write, so hand it the
		# clock. Without this the override is measurably zeroed (verified) and
		# every shot would show the rest pose while claiming otherwise.
		if not players.is_empty():
			players[0].callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			_report.append("anim mode  = MANUAL (so overrides are not overwritten)")
		_apply_blend_overrides()
		await get_tree().process_frame
		await get_tree().process_frame
		_audit_blend_persistence()

	for mi in _find_meshes(_mob):
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if mat is StandardMaterial3D:
				_report.append("material   = %s albedo=%s vcol_albedo=%s transparency=%d" % [
					mi.name, mat.albedo_color, mat.vertex_color_use_as_albedo, mat.transparency])
			if mesh is ArrayMesh:
				var arrays := (mesh as ArrayMesh).surface_get_arrays(s)
				var has_col: bool = arrays.size() > Mesh.ARRAY_COLOR and arrays[Mesh.ARRAY_COLOR] != null
				_report.append("surface %d  = COLOR array present: %s" % [s, has_col])

	# Frame off the WIDEST extent, not the height: a squat wide mob (the slime is
	# ~1.6:1) needs the distance its width demands or it fills the frame edge to
	# edge. Camera sits near mid-height so the silhouette is not foreshortened
	# into a puddle by looking down at it.
	var look := Vector3(0.0, centre.y, 0.0)
	var dist: float = max(1.8, max(widest, h) * 2.0)
	for shot in [["front", 180.0], ["threequarter", 215.0], ["side", 270.0]]:
		_aim(float(shot[1]), dist, h * 0.35, look)
		await _save("%s_%s" % [mob_name, shot[0]])

	# Close-up on the face, same rig — a wide shot hides relief detail.
	_aim(180.0, max(0.95, widest * 0.85), h * 0.16, look)
	await _save("%s_closeup" % mob_name)

	# Eye level of a 1.75m player standing a few metres off: the honest read of
	# what this thing looks like in play.
	_aim(180.0, max(3.0, widest * 3.2), 1.75 - centre.y, look)
	await _save("%s_playereye" % mob_name)

	if _lean_sweep > 0:
		await _capture_lean_sweep(mob_name, players)

	if _drive_script and _anim_frames > 0:
		await _capture_moving(mob_name, players)

	if _clip != "" and _anim_frames > 0 and not players.is_empty():
		await _capture_clip(players[0], mob_name)


func _capture_lean_sweep(mob_name: String, players: Array[AnimationPlayer]) -> void:
	## Sweeps the directional lean back and forth from a fixed side-on camera, so
	## the deformation is the only thing changing in frame.
	var mi := _blend_target()
	if mi == null:
		_report.append("lean sweep skipped — mesh has no blend shapes")
		return
	var idx := -1
	for i in mi.mesh.get_blend_shape_count():
		if String(mi.mesh.get_blend_shape_name(i)) == "lean_y":
			idx = i
			break
	if idx < 0:
		_report.append("lean sweep skipped — no 'lean_y' shape")
		return
	# The clip would rewrite the whole morph array and undo each step.
	if not players.is_empty():
		players[0].callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

	var box := _rest_bounds()
	var h: float = box.size.y
	var widest: float = max(box.size.x, box.size.z)
	var look := Vector3(0.0, box.get_center().y, 0.0)
	# Side-on: the forward lean happens along the camera's screen X, which is
	# where the eye reads it best. Straight-on it would foreshorten to nothing.
	_aim(270.0, max(1.8, max(widest, h) * 2.0), h * 0.30, look)

	for i in _lean_sweep:
		var phase: float = TAU * float(i) / float(_lean_sweep)
		var value: float = 0.8 * sin(phase)
		mi.set_blend_shape_value(idx, value)
		await _save("%s_leansweep_%03d" % [mob_name, i])
		mi.set_blend_shape_value(idx, value)
	mi.set_blend_shape_value(idx, 0.0)
	_report.append("lean sweep = %d frames, lean_y from -0.8 to +0.8" % _lean_sweep)


func _capture_moving(mob_name: String, players: Array[AnimationPlayer]) -> void:
	## Frames of the mob TRAVELLING, so a velocity-driven deformation can be seen
	## as motion instead of inferred from one settled still.
	##
	## The spring only shows itself while it is reacting: sampled after it has
	## come to rest, a wobbling gel and a rigid one look identical.
	var box := _rest_bounds()
	var h: float = box.size.y
	var widest: float = max(box.size.x, box.size.z)
	var look := Vector3(0.0, box.get_center().y, 0.0)
	_aim(270.0, max(2.2, max(widest, h) * 2.4), h * 0.30, look)

	if not players.is_empty():
		players[0].callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

	# Start from rest so the launch — the most legible part of a spring — is in
	# frame rather than already over.
	if _mob is CharacterBody3D:
		(_mob as CharacterBody3D).velocity = Vector3.ZERO
	for _i in 12:
		await get_tree().process_frame

	for i in _anim_frames:
		if _mob is CharacterBody3D:
			(_mob as CharacterBody3D).velocity = _fake_velocity
		# A few sim frames per captured frame: enough motion between shots to
		# read as movement rather than a series of near-identical poses.
		for _s in 3:
			await get_tree().process_frame
		await _save("%s_moving_%02d" % [mob_name, i])
	_report.append("moving sequence = %d frames at velocity %s" % [_anim_frames, _fake_velocity])


func _capture_clip(ap: AnimationPlayer, mob_name: String) -> void:
	if not ap.has_animation(_clip):
		_report.append("clip '%s' NOT FOUND — animation frames skipped" % _clip)
		return
	var anim := ap.get_animation(_clip)
	var box := _rest_bounds()
	var h: float = box.size.y
	var widest: float = max(box.size.x, box.size.z)
	var look := Vector3(0.0, box.get_center().y, 0.0)
	# Pulled back well past the rest silhouette: a clip can throw geometry far
	# outside it. The slime's death scatters droplets, and framed on the resting
	# body the puddles landed OUTSIDE the frame — the late frames looked like the
	# corpse had vanished when it was simply off-camera.
	_aim(180.0, max(2.6, max(widest, h) * 3.4), h * 0.55, look)
	for i in _anim_frames:
		var t: float = anim.length * (float(i) / float(_anim_frames))
		ap.play(_clip)
		ap.seek(t, true)
		ap.pause()
		await _save("%s_%s_%02d" % [mob_name, _clip, i])
	_report.append("clip '%s' captured %d frames over %.2fs" % [_clip, _anim_frames, anim.length])


func _find_anim_players(n: Node) -> Array[AnimationPlayer]:
	var out: Array[AnimationPlayer] = []
	if n is AnimationPlayer:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_anim_players(c))
	return out


func _write_report() -> void:
	var dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("_report.txt"), FileAccess.WRITE)
	if f == null:
		return
	f.store_line("=== mob_capture — the mob as Godot draws it ===")
	for line in _report:
		f.store_line(line)
	f.close()
	for line in _report:
		print("[mob_capture] %s" % line)
