extends Node3D
## TEMPORARY DEV HARNESS — foliage shimmer measurement.
##
## WHY A SELF-CONTAINED SCENE INSTEAD OF floor1_prairie
## The first version of this harness drove the real level. Mid-measurement,
## floor1_prairie.gd started failing to parse (a concurrent linear-valley terrain
## rework removed FLAT_RADIUS_BASE while call sites still referenced it), which
## would have made before/after runs incomparable anyway. Shimmer is a property of
## the material + texture + AA pipeline, not of the level's procedural layout, so
## this harness now builds its own deterministic stage: flat ground, one tree
## framed at a fixed distance, a bush, a grass carpet, one directional light, one
## fixed Environment. Nothing here changes between runs except the render settings
## under test, which is exactly what a before/after number needs.
##
## WHAT IT MEASURES
## Renders into an off-screen SubViewport, parks the camera at player eye height
## facing the tree, then sweeps the camera yaw in fixed small increments (position
## frozen — a pure rotation), saving one PNG per step. tools/godot/shimmer_probe/
## analyze.py then scores the per-pixel temporal deltas across the sequence.
##
## It also writes a foliage MASK frame: leaf-card surfaces render flat white
## through a dedicated shader, everything else flat black, so the analyzer can
## score foliage pixels separately from terrain/grass/bark/sky. Without that split
## a global "it changed less" number cannot tell "shimmer fixed" from "whole world
## blurred".
##
## NON-INTRUSIVE: same off-screen pattern as scenes/dev/biome_capture.gd — the real
## window is shrunk to 1x1 and parked at (-4000,-4000) with FLAG_NO_FOCUS.
##
## Run (one process renders every config listed, so they stay comparable):
##   Godot_v4.6.2-stable_win64_console.exe --path game \
##       res://scenes/dev/shimmer_probe.tscn -- \
##       --yaw=0.02 --runs="base:0:0:0;msaa4:2:0:0;a2c4:2:1:0"
##
## Output: game/tools/godot/shimmer_probe/<tag>/f000.png ... mask.png, meta.json

const OUT_ROOT := "res://tools/godot/shimmer_probe/"
const SV_SIZE := Vector2i(1280, 720)

const FRAMES := 41          # -> 40 consecutive-frame deltas
const CAM_DIST := 12.0      # metres from the framed tree
const EYE_HEIGHT := 1.7

# Retargeted 2026-08-08 to the species x stage taxonomy: prairie_01 became
# prairie_mature_02 (the dominant filler) and prairie_tall_01 became
# prairie_mature_03 (the tall mature). Shimmer is a foliage-density problem, so
# the probe wants the two densest common crowns, which is what these are.
const TREE_PATH := "res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_mature_02.glb"
const TREE_FAR_PATH := "res://assets/art/piso1_pradera/vegetation/tree_pack/env_tree_prairie_mature_03.glb"
const BUSH_PATH := "res://assets/art/piso1_pradera/vegetation/bush/env_bush_flowering_01.glb"
const GRASS_PATH := "res://assets/art/piso1_pradera/vegetation/grass/env_grass_lawn_dense_01.glb"

## Fixed layout. Deterministic on purpose — no RNG anywhere in this scene.
const GRASS_ROWS := 26
const GRASS_SPACING := 0.9

var _sv: SubViewport
var _cam: Camera3D
var _stage: Node3D
var _tree: Node3D
var _tag := "run"
var _log: Array[String] = []

## Configurations to render, as "tag:msaa:a2c:ssaa:taa:scale" entries joined by ";".
##   msaa   0..3  SubViewport.msaa_3d (DISABLED / 2X / 4X / 8X). Measured useless
##                on alpha-tested foliage: `discard` is a per-FRAGMENT operation,
##                so a discarded leaf pixel takes all of its MSAA samples with it.
##                MSAA still helps every ordinary geometry edge in the frame.
##   a2c    0..2  alpha_antialiasing_mode on every alpha-scissor material
##                (OFF / ALPHA_TO_COVERAGE / ALPHA_TO_COVERAGE_AND_TO_ONE).
##                Only does anything with MSAA on — it is an MSAA-coverage trick.
##   ssaa   0|1   screen_space_aa (DISABLED / FXAA)
##   taa    0|1   Viewport.use_taa — accumulates across frames, the one technique
##                that can see sub-pixel detail a single frame cannot resolve.
##   scale  int   3D render scale as a percent (150 = render at 1.5x, downsample).
##                Brute-force supersampling: the honest upper bound on how much
##                of this is a sampling-rate problem at all.
##
## Every config renders from ONE process and ONE built stage. Relaunching Godot
## per config flashed a window each time and, worse, folded driver and
## shader-cache warm-up differences into the comparison. One process, one stage,
## N sweeps: the only thing differing between two output dirs is the setting.
var _runs: Array[Dictionary] = []
var _yaw_step := 0.2
var _base_rot := Vector3.ZERO


func _parse_runs(raw: String) -> void:
	for entry in raw.split(";", false):
		var f := entry.split(":")
		if f.size() < 1 or f[0] == "":
			continue
		_runs.append({
			"tag": f[0],
			"msaa": int(f[1]) if f.size() > 1 else 0,
			"a2c": int(f[2]) if f.size() > 2 else 0,
			"ssaa": int(f[3]) if f.size() > 3 else 0,
			"taa": int(f[4]) if f.size() > 4 else 0,
			"scale": (int(f[5]) if f.size() > 5 else 100),
		})


func _ready() -> void:
	var raw_runs := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			_tag = a.split("=", true, 1)[1]
		elif a.begins_with("--runs="):
			raw_runs = a.split("=", true, 1)[1]
		elif a.begins_with("--yaw="):
			_yaw_step = float(a.split("=", true, 1)[1])
	_parse_runs(raw_runs)
	# Ground truth for what the GAME window actually renders with. The probe draws
	# into its own SubViewport, which inherits none of this, so a project setting
	# can read as "on" here and still never reach the player's screen.
	var root := get_tree().root
	print("[shimmer_probe] ROOT vp: use_taa=%s msaa=%d ssaa=%d | method=%s | ProjectSettings.use_taa=%s" % [
		str(root.use_taa), int(root.msaa_3d), int(root.screen_space_aa),
		str(RenderingServer.get_current_rendering_method()),
		str(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa", false))])
	if _runs.is_empty():
		_runs.append({"tag": _tag, "msaa": 0, "a2c": 0, "ssaa": 0})

	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)

	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	svc.add_child(_sv)

	_build_stage()

	_cam = Camera3D.new()
	_cam.fov = 65.0
	_sv.add_child(_cam)
	_cam.current = true

	for _i in range(30):
		await get_tree().process_frame

	_dump_materials(_tree)
	_frame_camera()
	# Captured ONCE. _sweep used to read the camera's current rotation as its base,
	# so run 2 started where run 1 ended and every extra config was framed 8 deg
	# further round the tree — the comparison would have been between different
	# shots, not different settings.
	_base_rot = _cam.rotation

	var dirs: Array[String] = []
	for cfg in _runs:
		var out_dir: String = OUT_ROOT + str(cfg["tag"]) + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		dirs.append(out_dir)
		await _render_run(cfg, out_dir)

	# The stencil does not depend on any AA setting, and rendering it mutates the
	# stage's materials, so it runs once at the end and is copied into every dir.
	await _render_mask(dirs)

	for d in dirs:
		_flush(d)
	print("[shimmer_probe] DONE %d config(s), %d frames each, yaw step %.3f deg" % [
		_runs.size(), FRAMES, _yaw_step])
	get_tree().quit(0)


func _render_run(cfg: Dictionary, out_dir: String) -> void:
	_sv.msaa_3d = int(cfg["msaa"]) as Viewport.MSAA
	_sv.screen_space_aa = int(cfg["ssaa"]) as Viewport.ScreenSpaceAA
	_sv.use_taa = bool(cfg["taa"])
	_sv.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_sv.scaling_3d_scale = float(cfg["scale"]) / 100.0
	_apply_alpha_aa(int(cfg["a2c"]), int(cfg["msaa"]))
	# Let the renderer rebuild its targets for the new sample count / render scale.
	# TAA additionally needs frames to fill its history buffer: read it cold and the
	# first frames of the sweep would score an accumulation transient, not TAA.
	for _i in range(30):
		await get_tree().process_frame
	_say("--- run '%s' msaa=%d a2c=%d ssaa=%d taa=%d scale=%d%%" % [
		cfg["tag"], cfg["msaa"], cfg["a2c"], cfg["ssaa"], cfg["taa"], cfg["scale"]])
	await _sweep(out_dir)
	_write_meta(cfg, out_dir)


func _say(s: String) -> void:
	_log.append(s)
	print("[shimmer_probe] ", s)


func _flush(out_dir: String) -> void:
	var f := FileAccess.open(out_dir + "_log.txt", FileAccess.WRITE)
	if f == null:
		return
	for line in _log:
		f.store_line(line)
	f.close()


# ---------------------------------------------------------------------------
# Deterministic stage
# ---------------------------------------------------------------------------
func _build_stage() -> void:
	_stage = Node3D.new()
	_stage.name = "Stage"
	_sv.add_child(_stage)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# Mid grey-blue "sky". A flat background is deliberate: it isolates the
	# foliage cut-out edges instead of hiding them behind a noisy procedural sky.
	env.background_color = Color(0.42, 0.50, 0.60)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.50, 0.55)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	_stage.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.6
	sun.rotation_degrees = Vector3(-42.0, -35.0, 0.0)
	sun.shadow_enabled = true
	_stage.add_child(sun)

	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(120.0, 120.0)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.28, 0.33, 0.20)
	gm.roughness = 0.95
	ground.material_override = gm
	_stage.add_child(ground)

	_tree = (load(TREE_PATH) as PackedScene).instantiate()
	_tree.name = "TreeSubject"
	_stage.add_child(_tree)
	_tree.global_position = Vector3.ZERO

	# A second tree further back and a bush: the owner said "las cosas" (plural),
	# so the frame must contain more than the one subject.
	var tree_far := (load(TREE_FAR_PATH) as PackedScene).instantiate()
	tree_far.name = "TreeFar"
	_stage.add_child(tree_far)
	(tree_far as Node3D).global_position = Vector3(-7.0, 0.0, -9.0)

	var bush := (load(BUSH_PATH) as PackedScene).instantiate()
	bush.name = "Bush"
	_stage.add_child(bush)
	(bush as Node3D).global_position = Vector3(3.4, 0.0, 2.2)

	_build_grass()


## Grass as a MultiMesh, mirroring how floor1_prairie renders its carpet — the
## brief flags scattered geometry as an independent shimmer suspect.
func _build_grass() -> void:
	var src := (load(GRASS_PATH) as PackedScene).instantiate()
	var mesh: Mesh = null
	var stack: Array = [src]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			mesh = (n as MeshInstance3D).mesh
			break
		for c in n.get_children():
			stack.append(c)
	if mesh == null:
		_say("[WARN] grass mesh not found in %s — grass layer skipped" % GRASS_PATH)
		src.queue_free()
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = GRASS_ROWS * GRASS_ROWS
	var i := 0
	for r in range(GRASS_ROWS):
		for c in range(GRASS_ROWS):
			# Deterministic lattice with a fixed irrational jitter so blades do not
			# line up into a moire grid, but no RNG is involved.
			var x: float = (float(r) - float(GRASS_ROWS) * 0.5) * GRASS_SPACING + fmod(float(i) * 0.618034, 1.0) * 0.5
			var z: float = (float(c) - float(GRASS_ROWS) * 0.5) * GRASS_SPACING + fmod(float(i) * 0.414214, 1.0) * 0.5
			var t := Transform3D(Basis(Vector3.UP, fmod(float(i) * 2.399963, TAU)), Vector3(x, 0.0, z))
			mm.set_instance_transform(i, t)
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GrassCarpet"
	mmi.multimesh = mm
	_stage.add_child(mmi)
	src.queue_free()
	_say("grass carpet: %d instances of %s" % [mm.instance_count, GRASS_PATH])


## Alpha-to-coverage turns the scissor's binary keep/discard into a per-sample
## coverage fraction, so a leaf edge resolves to intermediate values instead of
## flipping a whole pixel between leaf and sky. It is an MSAA feature: with
## msaa_3d DISABLED there is one sample per pixel and it cannot do anything.
## Always writes the mode, including OFF: the stage's materials are shared
## resources mutated in place, so a run that only set the mode when non-zero
## would inherit the previous run's setting instead of clearing it.
func _apply_alpha_aa(mode: int, msaa: int) -> void:
	if mode != 0 and msaa == 0:
		_say("[WARN] a2c=%d with msaa=0 — alpha-to-coverage needs MSAA samples and is a no-op" % mode)
	var gis: Array = []
	_walk(_stage, gis)
	var touched := 0
	for gi in gis:
		var mi := gi as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_active_material(s) as BaseMaterial3D
			if m == null or m.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				continue
			m.alpha_antialiasing_mode = mode as BaseMaterial3D.AlphaAntiAliasing
			touched += 1
	_say("alpha_antialiasing_mode=%d applied to %d alpha-scissor surfaces" % [mode, touched])


# ---------------------------------------------------------------------------
func _walk(root: Node, out: Array) -> void:
	if root is GeometryInstance3D:
		out.append(root)
	for c in root.get_children():
		_walk(c, out)


func _find_named(root: Node, n: String) -> Node:
	if root.name == n:
		return root
	for c in root.get_children():
		var r := _find_named(c, n)
		if r != null:
			return r
	return null


func _aabb_of(n: Node3D) -> AABB:
	var gis: Array = []
	_walk(n, gis)
	var acc := AABB()
	var first := true
	for gi in gis:
		if not (gi is VisualInstance3D):
			continue
		var b: AABB = (gi as VisualInstance3D).get_aabb()
		b = (gi as Node3D).global_transform * b
		if first:
			acc = b
			first = false
		else:
			acc = acc.merge(b)
	return acc


func _frame_camera() -> void:
	var box := _aabb_of(_tree)
	var centre := box.get_center()
	_cam.global_position = Vector3(0.0, EYE_HEIGHT, CAM_DIST)
	_cam.look_at(Vector3(centre.x, centre.y, centre.z), Vector3.UP)
	_say("tree aabb size=%s centre=%s" % [str(box.size), str(centre)])
	_say("camera pos=%s yaw=%.4f deg pitch=%.4f deg" % [
		str(_cam.global_position), rad_to_deg(_cam.rotation.y), rad_to_deg(_cam.rotation.x)])


func _sweep(out_dir: String) -> void:
	for i in range(FRAMES):
		_cam.rotation = Vector3(
			_base_rot.x,
			_base_rot.y + deg_to_rad(_yaw_step * float(i)),
			_base_rot.z)
		# Nothing in this scene animates; only the camera moves. Two settle frames
		# so any deferred LOD / visibility-range switch lands before the read-back.
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img == null:
			_say("[FATAL] frame %d: get_image() null" % i)
			return
		img.save_png(out_dir + "f%03d.png" % i)
	_say("sweep saved %d frames, yaw step %.4f deg, total %.3f deg" % [
		FRAMES, _yaw_step, _yaw_step * float(FRAMES - 1)])


# ---------------------------------------------------------------------------
# Foliage mask: flat white where a leaf card is opaque, flat black elsewhere.
# ---------------------------------------------------------------------------
## A StandardMaterial3D cannot produce this: setting albedo_texture would tint the
## output with the leaf colour, and thresholding a green tint is not a stencil.
const MASK_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D leaf_tex : source_color, filter_linear;
uniform float cutoff = 0.45;
void fragment() {
	if (texture(leaf_tex, UV).a < cutoff) { discard; }
	ALBEDO = vec3(1.0);
}
"""


## The region under test is "alpha-tested card", not "material somebody remembered
## to call leaf". Keying on the name alone put the bush's foliage in the WORLD
## control region, which is the one region that must stay uncontaminated. Alpha
## scissor IS the feature that shimmers, so that is what selects the region; the
## name check stays as a fallback for a card authored some other way.
func _is_leaf_material(m: Material) -> bool:
	if m == null:
		return false
	var bm := m as BaseMaterial3D
	if bm != null and bm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		return true
	var n := m.resource_name.to_lower()
	if n == "" and m.resource_path != "":
		n = m.resource_path.get_file().to_lower()
	return "leaf" in n or "foliage" in n


func _render_mask(out_dirs: Array[String]) -> void:
	var mask_shader := Shader.new()
	mask_shader.code = MASK_SHADER

	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0, 0, 0)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0, 0, 0)
	env.ambient_light_energy = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := _find_named(_stage, "WorldEnvironment") as WorldEnvironment
	var prev_env: Environment = null
	if we != null:
		prev_env = we.environment
		we.environment = env

	var gis: Array = []
	_walk(_stage, gis)
	var leaf_surfaces := 0
	for gi in gis:
		var g := gi as GeometryInstance3D
		var mi := g as MeshInstance3D
		if mi == null or mi.mesh == null:
			# MultiMesh and friends expose no per-surface slot: blacken wholesale.
			g.material_override = black
			continue
		# material_override OUTRANKS every surface-override slot ("it will be used
		# instead of any material set in any material slot" — GeometryInstance3D
		# docs). The stage's ground carries one, so the first mask render came back
		# a lit grey-green photo instead of a stencil and analyze.py rejected it.
		# Read the active materials FIRST (get_active_material returns the override
		# when one is set), then drop the override, then write the stencil.
		var actives: Array[Material] = []
		for s in range(mi.mesh.get_surface_count()):
			actives.append(mi.get_active_material(s))
		mi.material_override = null
		for s in range(actives.size()):
			var m: Material = actives[s]
			if _is_leaf_material(m):
				var w := ShaderMaterial.new()
				w.shader = mask_shader
				var sm := m as BaseMaterial3D
				if sm != null:
					w.set_shader_parameter("leaf_tex", sm.albedo_texture)
					w.set_shader_parameter("cutoff", sm.alpha_scissor_threshold)
				mi.set_surface_override_material(s, w)
				leaf_surfaces += 1
			else:
				mi.set_surface_override_material(s, black)

	_say("mask: %d leaf surfaces flagged out of %d geometry instances" % [leaf_surfaces, gis.size()])

	# Back to the sweep's starting yaw so the mask lines up with f000.png. MSAA is
	# forced off: a resolved edge sample would land between white and black and
	# analyze.py rejects any stencil with mid-tones.
	_sv.msaa_3d = Viewport.MSAA_DISABLED
	_sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_sv.use_taa = false
	_sv.scaling_3d_scale = 1.0
	_cam.rotation = _base_rot
	for _i in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img != null:
		for d in out_dirs:
			img.save_png(d + "mask.png")
	if we != null:
		we.environment = prev_env


# ---------------------------------------------------------------------------
func _dump_materials(root: Node3D) -> void:
	var gis: Array = []
	_walk(root, gis)
	for gi in gis:
		if not (gi is MeshInstance3D):
			continue
		var mi := gi as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var m := mi.get_active_material(s) as BaseMaterial3D
			if m == null:
				continue
			var tex := m.albedo_texture
			var tex_desc := "none"
			if tex != null:
				var im: Image = tex.get_image()
				var mips := "?"
				if im != null:
					mips = "yes(%d)" % im.get_mipmap_count() if im.has_mipmaps() else "NO"
				tex_desc = "%dx%d fmt=%s mipmaps=%s res=%s" % [
					tex.get_width(), tex.get_height(),
					("?" if im == null else str(im.get_format())),
					mips, tex.resource_path]
			_say("MAT %s.surf%d name=%s transparency=%d scissor=%.3f alpha_aa=%d filter=%d cull=%d tex=[%s]" % [
				mi.name, s, m.resource_name, m.transparency,
				m.alpha_scissor_threshold, m.alpha_antialiasing_mode,
				m.texture_filter, m.cull_mode, tex_desc])


func _write_meta(cfg: Dictionary, out_dir: String) -> void:
	var f_px: float = (float(SV_SIZE.y) * 0.5) / tan(deg_to_rad(_cam.fov) * 0.5)
	var meta := {
		"tag": cfg["tag"],
		"frames": FRAMES,
		"yaw_step_deg": _yaw_step,
		"size": [SV_SIZE.x, SV_SIZE.y],
		"fov_deg": _cam.fov,
		"focal_px": f_px,
		"px_per_frame": deg_to_rad(_yaw_step) * f_px,
		"cam_dist_m": CAM_DIST,
		"msaa_3d": int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0)),
		"screen_space_aa": int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa", 0)),
		"use_taa": bool(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa", false)),
		"aniso": int(ProjectSettings.get_setting("rendering/textures/default_filters/anisotropic_filtering_level", 2)),
		"mip_bias": float(ProjectSettings.get_setting("rendering/textures/default_filters/texture_mipmap_bias", 0.0)),
		"vp_msaa": int(_sv.msaa_3d),
		"vp_ssaa": int(_sv.screen_space_aa),
		"vp_taa": _sv.use_taa,
		"alpha_aa": cfg["a2c"],
		"render_scale": _sv.scaling_3d_scale,
	}
	var fh := FileAccess.open(out_dir + "meta.json", FileAccess.WRITE)
	if fh != null:
		fh.store_string(JSON.stringify(meta, "  "))
		fh.close()
	_say("meta: " + JSON.stringify(meta))
