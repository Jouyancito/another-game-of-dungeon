extends Node3D
## Live 3D title screen: a dark tomb hall lit first by the campfire, a floating
## solid title that throws its shadow on the back wall, a dark corridor on the
## right with blinking eyes, and a transparent menu over that corridor.
## Everything is built in code from primitives (no Blender export yet, see TODOs).
## Driven by `advance(delta)` so tests and capture tools can step time.

const MainMenu := preload("res://scenes/ui/main_menu.gd")

## Same color the studio splash melts into: the intro starts exactly here.
const DUNGEON_DARK := Color("#120d0b")
const FONT_PATH := "res://tools/logo/fonts/RussoOne-Regular.ttf"
const ROOM_GLB := "res://assets/art/titlescreen/titlescreen_room.glb"
const LOGO_GLB := "res://assets/art/titlescreen/titlescreen_logo.glb"
## Blender hall is x 54.5..65.5, y 0..8: this puts it on the origin (Godot z = 4 - y).
const ROOM_OFFSET := Vector3(-60.0, 0.0, 4.0)
const CAM_POS := Vector3(-0.3, 1.6, 7.4)
const CAM_ROT := Vector3(0.0, -6.0, 0.0)
const FILL_ENERGY := 0.6
const TITLE_SCALE := 0.30
const TITLE_POS := Vector3(-0.2, 2.3, -2.5)

# Intro timeline (seconds)
const T_DARK_END := 0.4
const T_FIRE_END := 1.6
const T_TITLE_START := 2.2
const T_TITLE_END := 3.2
const T_MENU_START := 3.0
const T_INTRO_END := 4.0

enum State { DARK, INTRO, IDLE }

## One exported color for every pair of eyes (yellow-amber default, red is allowed).
## Composition-review aid: a 1.8 m post (the player) next to the group.
@export var show_scale_ref := false
@export var eye_color := Color(1.0, 0.72, 0.12)
@export var fire_energy := 2.0

var state := State.DARK
## Intro time; stops at T_INTRO_END.
var t := 0.0
## Free-running time for flicker and blinks.
var clock := 0.0
## Test hook: if valid, called with the scene path instead of changing scene.
var transition_fn := Callable()

var _transitioned := false
var _saved_atlas: Array = []
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()

var _cam: Camera3D
var _fire_light: OmniLight3D
var _fire_pos := Vector3(-0.6, 0.5, 0.6)
var _fire_flame: GPUParticles3D
var _fire_embers: GPUParticles3D
var _fill_light: OmniLight3D
var _title_root: Node3D
var _title_mat: StandardMaterial3D
var _eyes: Array[Dictionary] = []  # {node, next, start}
var _veil: ColorRect
var _menu: Control
var _status: Label
var _buttons: Array[Button] = []
var _btn_jugar: Button


func _ready() -> void:
	_boost_shadow_atlas()
	_rng.seed = 7
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_build_environment()
	_build_room()
	_build_title()
	_build_fire()
	_build_placeholders()
	_build_eyes()
	_build_fill()
	_build_ui()
	_apply(0.0)


## The title's shadow needs resolution: give the single shadowed light (the campfire) the whole
## atlas. Restored on exit so gameplay keeps the project defaults.
func _boost_shadow_atlas() -> void:
	var vp := get_viewport()
	_saved_atlas = [vp.positional_shadow_atlas_size, vp.positional_shadow_atlas_quad_0,
		vp.positional_shadow_atlas_quad_1, vp.positional_shadow_atlas_quad_2, vp.positional_shadow_atlas_quad_3]
	vp.positional_shadow_atlas_size = 8192
	vp.positional_shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4
	vp.positional_shadow_atlas_quad_1 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	vp.positional_shadow_atlas_quad_2 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED
	vp.positional_shadow_atlas_quad_3 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_DISABLED


func _exit_tree() -> void:
	if _saved_atlas.is_empty():
		return
	var vp := get_viewport()
	if vp == null:
		return
	vp.positional_shadow_atlas_size = _saved_atlas[0]
	vp.positional_shadow_atlas_quad_0 = _saved_atlas[1]
	vp.positional_shadow_atlas_quad_1 = _saved_atlas[2]
	vp.positional_shadow_atlas_quad_2 = _saved_atlas[3]
	vp.positional_shadow_atlas_quad_3 = _saved_atlas[4]


func _process(delta: float) -> void:
	advance(delta)


func _input(event: InputEvent) -> void:
	if state == State.IDLE or not event.is_pressed() or event is InputEventMouseMotion:
		return
	if event is InputEventKey and event.echo:
		return
	# Wheel ticks arrive as button presses too: they must not skip the intro.
	if event is InputEventMouseButton and event.button_index > MOUSE_BUTTON_MIDDLE:
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		skip()


## Steps the whole screen by `delta` seconds.
func advance(delta: float) -> void:
	clock += delta
	if state != State.IDLE:
		t = minf(t + delta, T_INTRO_END)
	_apply(delta)


## Jumps to the end state of the intro.
func skip() -> void:
	t = T_INTRO_END
	_apply(0.0)


func is_idle() -> bool:
	return state == State.IDLE


## Runs the transition exactly once.
func go_to(path: String) -> void:
	if _transitioned:
		return
	_transitioned = true
	if transition_fn.is_valid():
		transition_fn.call(path)
	else:
		get_tree().change_scene_to_file(path)


# --- timeline ---------------------------------------------------------------

static func seg(time: float, start: float, end: float) -> float:
	return smoothstep(0.0, 1.0, clampf((time - start) / (end - start), 0.0, 1.0))


func _apply(delta: float) -> void:
	if t >= T_INTRO_END:
		state = State.IDLE
	elif t >= T_DARK_END:
		state = State.INTRO
	else:
		state = State.DARK

	# Optional slow push-in; settles when the intro ends.
	_cam.position = CAM_POS + Vector3(0.0, 0.0, lerpf(0.5, 0.0, seg(t, 0.0, T_INTRO_END)))

	_veil.modulate.a = 1.0 - seg(t, T_DARK_END, 0.85)

	# Campfire: range spreads first, energy follows; the title is lit by it, not faded in.
	var ignite := seg(t, T_DARK_END, T_FIRE_END)
	var full := seg(t, T_FIRE_END + 0.5, T_TITLE_END)
	var flick := 1.0 + 0.28 * _noise.get_noise_1d(clock * 7.0) + 0.10 * _noise.get_noise_1d(clock * 23.0 + 50.0)
	_fire_light.light_energy = fire_energy * (0.45 * ignite + 0.55 * full) * flick
	_fire_light.omni_range = lerpf(1.5, 7.5, ignite)
	_fire_light.position = _fire_pos + Vector3(
		_noise.get_noise_1d(clock * 9.0 + 10.0), 0.0, _noise.get_noise_1d(clock * 9.0 + 30.0)) * 0.05
	var burning := t >= T_DARK_END
	_fire_flame.emitting = burning
	_fire_embers.emitting = burning

	# Title: a faint cold fill shows up while the light reaches it, so it reads.
	var title_k := seg(t, T_TITLE_START, T_TITLE_END)
	_title_mat.emission_energy_multiplier = 0.9 * title_k
	_title_root.rotation.y = deg_to_rad(1.4) * sin(clock * 0.35)  # slow sway, shadow follows

	_fill_light.light_energy = FILL_ENERGY * seg(t, T_TITLE_START, T_TITLE_END)
	_update_eyes(seg(t, 2.0, 2.8))

	_menu.modulate.a = seg(t, T_MENU_START, T_INTRO_END)
	var interactive := t >= T_MENU_START
	for b in _buttons:
		b.disabled = not interactive
	if state == State.IDLE and is_inside_tree() and _btn_jugar.is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
		_btn_jugar.grab_focus()


func _update_eyes(visible_k: float) -> void:
	for e in _eyes:
		var node: Node3D = e.node
		node.visible = visible_k > 0.01
		var open := visible_k
		if e.start >= 0.0:
			var p: float = (clock - e.start) / 0.12
			if p >= 1.0:
				e.start = -1.0
				e.next = clock + _rng.randf_range(1.5, 6.0)
			else:
				open *= absf(1.0 - 2.0 * p)  # closes to 0 at p=0.5, reopens
		elif clock >= e.next and visible_k >= 1.0:
			e.start = clock
		node.scale = Vector3(1.0, maxf(open, 0.001), 1.0)


# --- build: environment ---------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = DUNGEON_DARK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.40, 0.50)
	env.ambient_light_energy = 0.05
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# Cheap volumetric fog: low density, short range, low resolution.
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.018
	env.volumetric_fog_albedo = Color(0.8, 0.65, 0.5)
	env.volumetric_fog_length = 40.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	_cam = Camera3D.new()
	_cam.fov = 58.0
	_cam.far = 80.0
	add_child(_cam)
	_cam.position = CAM_POS
	_cam.rotation_degrees = CAM_ROT


# --- build: room --------------------------------------------------------------

func _stone(color: Color, freq := 0.06) -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.frequency = freq
	n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	var nm := NoiseTexture2D.new()
	nm.noise = n
	nm.width = 512
	nm.height = 512
	nm.seamless = true
	nm.as_normal_map = true
	nm.bump_strength = 3.0
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = tex
	m.normal_enabled = true
	m.normal_texture = nm
	m.roughness = 0.9
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.16, 0.16, 0.16)
	return m


func _box(parent: Node, from: Vector3, to: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = (to - from).abs()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = (from + to) * 0.5
	parent.add_child(mi)
	return mi


func _build_room() -> void:
	# Hall + corridor blockout exported from tools/logo/titlescreen.blend (see
	# tools/titlescreen/titlescreen_export.py). glTF dropped the procedural materials, so the
	# stone is rebuilt here. Blender (x, y, z) -> Godot (x, z, -y); offset centers the hall.
	var room: Node3D = load(ROOM_GLB).instantiate()
	room.name = "Room"
	room.position = ROOM_OFFSET
	add_child(room)
	var wall := _stone(Color("#a58b79"))  # tomb palette: stone #725D4D (noise texture averages ~0.5)
	wall.cull_mode = BaseMaterial3D.CULL_DISABLED
	var floor_m := _stone(Color("#80695a"), 0.04)  # shadow-leaning #47372C..#725D4D
	floor_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi in room.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = floor_m if "floor" in String(mi.name) or "debris" in String(mi.name) else wall
	# TODO(titlescreen v2): rebuild the real tomb stone textures (slabs, fallen pieces) once the
	# texture files referenced by the .blend (C:/Users/the_j/motor-blender/_textures) are restored.


# --- build: title ---------------------------------------------------------------

func _build_title() -> void:
	_title_root = Node3D.new()
	_title_root.name = "Title"
	_title_root.position = TITLE_POS
	add_child(_title_root)
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * TITLE_SCALE
	_title_root.add_child(holder)
	var logo: Node3D = load(LOGO_GLB).instantiate()
	# Logo spans x 0..17.55, z 0..6.7 in Blender: center it on the pivot.
	logo.position = Vector3(-8.78, -3.35, 0.0)
	holder.add_child(logo)
	# Cold patinated bronze, multiplied over the baked vertex colors: separates the lettering
	# from the warm ochre wall by temperature, not value. Vines keep their own baked colors.
	_title_mat = StandardMaterial3D.new()
	_title_mat.albedo_color = Color(0.34, 0.56, 0.52)
	_title_mat.vertex_color_use_as_albedo = true
	_title_mat.metallic = 0.35
	_title_mat.roughness = 0.45
	_title_mat.emission_enabled = true
	_title_mat.emission = Color(0.10, 0.30, 0.27)
	_title_mat.emission_energy_multiplier = 0.0
	for mi in logo.find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name)
		if n.begins_with("glyph") or n.begins_with("gate"):
			mi.material_override = _title_mat
		else:
			# Only the lettering and the U-gate may cast the readable shadow on the wall.
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The small top rows ("ANOTHER gAME OF") would merge into one band with DUNGEON.
		if n in ["glyph_bigA", "glyph_gee", "glyph_me", "glyph_nother", "glyph_of"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Hanging roots hold the title (owner canon: it hangs from the ceiling, not magic).
	var root_mat := StandardMaterial3D.new()
	root_mat.albedo_color = Color(0.10, 0.08, 0.05)
	root_mat.roughness = 1.0
	for rx in [-1.8, -0.5, 1.2, 2.0]:
		var cyl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.05
		cm.height = 1.5
		cm.radial_segments = 6
		cyl.mesh = cm
		cyl.material_override = root_mat
		cyl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cyl.position = Vector3(rx, 1.2 + 0.35, -0.05)
		cyl.rotation_degrees = Vector3(0, 0, rx * 2.0)
		_title_root.add_child(cyl)
	# TODO(titlescreen v2): vine on the letters is already in the .glb; add the hanging-root
	# vegetation (canon: distinct from the climbing vine) and the U-gate door opening animation.


# --- build: fire --------------------------------------------------------

func _radial_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(0, 0, 0, 1))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex


func _make_flame(size: float, amount: int, ember: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 2.2 if ember else 0.8
	p.emitting = false
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = size * (0.9 if ember else 0.35)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0 if ember else 12.0
	pm.initial_velocity_min = (0.8 if ember else 0.5) * size * 2.0
	pm.initial_velocity_max = (2.0 if ember else 1.1) * size * 2.0
	pm.gravity = Vector3(0, 0.6 if ember else 1.4, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.7))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	pm.scale_curve = ct
	var grad := Gradient.new()
	if ember:
		grad.colors = PackedColorArray([Color(1, 0.7, 0.25, 1), Color(1, 0.35, 0.05, 0.8), Color(0.5, 0.1, 0.0, 0)])
		grad.offsets = PackedFloat32Array([0, 0.5, 1])
	else:
		grad.colors = PackedColorArray([Color(1, 0.95, 0.65, 0.95), Color(1, 0.5, 0.1, 0.8), Color(0.55, 0.12, 0.02, 0)])
		grad.offsets = PackedFloat32Array([0, 0.45, 1])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * (size * 0.14 if ember else size * 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _radial_tex()
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	mat.particles_anim_h_frames = 1
	mat.particles_anim_v_frames = 1
	quad.material = mat
	p.draw_pass_1 = quad
	return p


func _build_fire() -> void:
	var fire := Node3D.new()
	fire.name = "Campfire"
	fire.position = Vector3(_fire_pos.x, 0.0, _fire_pos.z)
	add_child(fire)
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.12, 0.08, 0.05)
	log_mat.roughness = 1.0
	for i in 3:
		var l := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.09
		cm.bottom_radius = 0.11
		cm.height = 1.0
		cm.radial_segments = 8
		l.mesh = cm
		l.material_override = log_mat
		l.position = Vector3(0, 0.16, 0)
		l.rotation_degrees = Vector3(78, i * 60.0, 0)
		fire.add_child(l)
	_fire_flame = _make_flame(0.34, 36, false)
	_fire_flame.position = Vector3(0, 0.35, 0)
	fire.add_child(_fire_flame)
	_fire_embers = _make_flame(0.45, 14, true)
	_fire_embers.position = Vector3(0, 0.5, 0)
	fire.add_child(_fire_embers)

	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.72, 0.46)  # warm, desaturated vs pure orange
	_fire_light.light_energy = 0.0
	_fire_light.omni_range = 1.5
	_fire_light.omni_attenuation = 1.2
	_fire_light.shadow_enabled = true
	_fire_light.shadow_bias = 0.05
	_fire_light.shadow_blur = 0.08
	_fire_light.light_volumetric_fog_energy = 1.0
	_fire_light.position = _fire_pos
	add_child(_fire_light)
	# TODO(titlescreen v2): warrior (pipe smoke), explorer + mage + mimic chest around the fire.


## Composition placeholders (review only). Real models come later through the motor.
## Layout from the owner's sketch: archer + mage/mimic LEFT of the fire, warrior RIGHT with
## shield and sword leaning on a wall remain, chameleon on the upper-left wall, rubble at
## the corridor mouth. Z is toward the camera; the fire sits at (-0.6, _, 0.6).
func _ph_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _ph(parent: Node3D, node_name: String, mesh: Mesh, pos: Vector3, rot_deg := Vector3.ZERO, mat: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat if mat else _ph_mat(Color(0.30, 0.28, 0.26))
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	return c


func _boxmesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _build_placeholders() -> void:
	var root := Node3D.new()
	root.name = "Placeholders"
	add_child(root)
	var dark := _ph_mat(Color(0.30, 0.28, 0.26))
	var wood := _ph_mat(Color(0.22, 0.15, 0.10))
	var steel := _ph_mat(Color(0.30, 0.31, 0.33))
	# Warrior: seated right of the fire, ~1.1 m tall seated, facing the fire (-x).
	_ph(root, "Warrior_Placeholder", _capsule(0.30, 1.1), Vector3(1.0, 0.55, 0.6), Vector3(0, 0, 8), dark)
	# Wall remain behind him: the shield and sword lean on it.
	var stump := _ph(root, "WallRemain_Placeholder", _boxmesh(Vector3(1.6, 0.8, 0.4)), Vector3(2.5, 0.4, -0.9), Vector3(0, -8, 0), _ph_mat(Color(0.35, 0.29, 0.24)))
	stump.name = "WallRemain_Placeholder"
	var shield_mesh := CylinderMesh.new()
	shield_mesh.top_radius = 0.38
	shield_mesh.bottom_radius = 0.38
	shield_mesh.height = 0.06
	_ph(root, "Shield_Placeholder", shield_mesh, Vector3(2.2, 0.5, -0.62), Vector3(-72, 0, 0), steel)
	_ph(root, "Sword_Placeholder", _boxmesh(Vector3(0.09, 1.05, 0.03)), Vector3(2.95, 0.55, -0.62), Vector3(-14, 0, 8), steel)
	# Archer: standing left of the chest, leaning back as if pulling the mage out.
	_ph(root, "Archer_Placeholder", _capsule(0.24, 1.7), Vector3(-3.5, 0.85, 0.8), Vector3(0, 0, 14), dark)
	# Mimic chest ~0.9 x 0.6 x 0.6 m with the mage half inside.
	_ph(root, "Mimic_Placeholder", _boxmesh(Vector3(0.9, 0.6, 0.6)), Vector3(-2.2, 0.3, 0.4), Vector3(0, -10, 0), wood)
	_ph(root, "Mage_Placeholder", _capsule(0.2, 1.3), Vector3(-2.4, 0.95, 0.4), Vector3(0, 0, -22), _ph_mat(Color(0.24, 0.20, 0.26)))
	# Chameleon ~0.6 m long on the upper-left wall (body + head + curled tail).
	var cham := Node3D.new()
	cham.name = "Chameleon_Placeholder"
	cham.position = Vector3(-4.7, 2.9, -3.85)
	cham.scale = Vector3.ONE * 1.4
	root.add_child(cham)
	var green := _ph_mat(Color(0.55, 0.62, 0.45))
	_ph(cham, "Body", _capsule(0.07, 0.34), Vector3(0, 0, 0), Vector3(0, 0, 90), green)
	_ph(cham, "Head", _capsule(0.06, 0.16), Vector3(-0.22, 0.02, 0), Vector3(0, 0, 90), green)
	_ph(cham, "Tail", _capsule(0.03, 0.28), Vector3(0.28, 0.08, 0), Vector3(0, 0, 70), green)
	# Corridor-mouth rubble: low broken remains that cast extra shadow and deepen the dark.
	var rub := _stone(Color("#80695a"), 0.09)
	_box_at(root, "Rubble_A", Vector3(5.9, 0.18, -1.0), Vector3(0.7, 0.36, 0.5), Vector3(0, 20, 4), rub)
	_box_at(root, "Rubble_B", Vector3(6.2, 0.28, 0.2), Vector3(0.6, 0.56, 0.7), Vector3(3, -15, -6), rub)
	_box_at(root, "Rubble_C", Vector3(5.6, 0.14, 0.9), Vector3(0.9, 0.28, 0.4), Vector3(0, 35, 2), rub)
	_box_at(root, "Rubble_D", Vector3(6.6, 0.4, -0.45), Vector3(0.5, 0.8, 0.5), Vector3(0, 8, 12), rub)
	# Optional 1.8 m player reference (composition review only).
	var ref := _ph(root, "ScaleRef_1_8m", _boxmesh(Vector3(0.1, 1.8, 0.1)), Vector3(0.9, 0.9, 1.9), Vector3.ZERO, _ph_mat(Color(0.8, 0.2, 0.18)))
	ref.visible = show_scale_ref


func _box_at(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, rot_deg: Vector3, mat: Material) -> void:
	_ph(parent, node_name, _boxmesh(size), pos, rot_deg, mat)


func _build_eyes() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = eye_color
	mat.emission_enabled = true
	mat.emission = eye_color
	mat.emission_energy_multiplier = 4.0
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 10
	sm.rings = 5
	# Pairs in the corridor's darkness (it has NO light source: the dark is what the eyes need).
	var spots := [
		Vector3(6.6, 1.8, -0.9), Vector3(7.1, 1.0, -0.5),
		Vector3(7.7, 2.1, -0.9), Vector3(8.3, 1.4, -0.3),
	]
	for i in spots.size():
		var pair := Node3D.new()
		pair.name = "Eyes%d" % i
		pair.position = spots[i]
		pair.visible = false
		var gap := 0.22 + 0.02 * i
		for sx in [-gap * 0.5, gap * 0.5]:
			var eye := MeshInstance3D.new()
			eye.mesh = sm
			eye.material_override = mat
			eye.position.x = sx
			eye.scale = Vector3(1.6, 1.0, 0.6)
			pair.add_child(eye)
		add_child(pair)
		_eyes.append({"node": pair, "next": _rng.randf_range(2.0, 5.0), "start": -1.0})


func _build_fill() -> void:
	# Dim cool fill from behind the camera: separates the cold title from the warm wall.
	_fill_light = OmniLight3D.new()
	_fill_light.light_color = Color(0.50, 0.68, 0.85)
	_fill_light.light_energy = 0.0
	_fill_light.omni_range = 16.0
	_fill_light.omni_attenuation = 0.8
	_fill_light.shadow_enabled = false
	_fill_light.position = Vector3(-1.5, 2.8, 6.0)
	add_child(_fill_light)


# --- build: ui ---------------------------------------------------------------------

func _build_ui() -> void:
	var veil_layer := CanvasLayer.new()
	veil_layer.layer = 1
	add_child(veil_layer)
	_veil = ColorRect.new()
	_veil.color = DUNGEON_DARK
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil_layer.add_child(_veil)

	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_menu)

	var font: Font = load(FONT_PATH)
	var col := VBoxContainer.new()
	col.anchor_left = 0.70
	col.anchor_right = 0.82
	col.anchor_top = 0.5
	col.anchor_bottom = 0.5
	col.offset_top = -170
	col.offset_bottom = 170
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_child(col)

	var defs := [
		["Jugar", _on_jugar], ["Opciones", _on_proximamente],
		["Créditos", _on_proximamente], ["Salir", _on_salir],
	]
	for d in defs:
		var b := Button.new()
		b.text = d[0]
		b.custom_minimum_size = Vector2(0, 58)
		b.add_theme_font_override("font", font)
		b.add_theme_font_size_override("font_size", 26)
		b.add_theme_color_override("font_color", Color(0.93, 0.84, 0.64))
		b.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.7))
		b.add_theme_color_override("font_focus_color", Color(1.0, 0.93, 0.7))
		b.add_theme_color_override("font_disabled_color", Color(0.93, 0.84, 0.64))
		b.add_theme_stylebox_override("normal", _btn_style(0.42, 0.45))
		b.add_theme_stylebox_override("disabled", _btn_style(0.42, 0.45))
		b.add_theme_stylebox_override("hover", _btn_style(0.72, 0.9))
		b.add_theme_stylebox_override("focus", _btn_style(0.72, 0.9))
		b.add_theme_stylebox_override("pressed", _btn_style(0.85, 1.0))
		b.pressed.connect(d[1])
		col.add_child(b)
		_buttons.append(b)
	_btn_jugar = _buttons[0]
	_status = Label.new()
	_status.text = "Próximamente"
	_status.visible = false
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_override("font", font)
	_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	col.add_child(_status)


func _btn_style(bg_a: float, border_a: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.03, 0.025, bg_a)
	s.border_color = Color(0.75, 0.55, 0.28, border_a)
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s


# --- menu actions (same behavior as main_menu) ---------------------------------------

func _on_jugar() -> void:
	go_to(MainMenu.begin_play())


func _on_proximamente() -> void:
	_status.visible = true
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self):
		_status.visible = false


func _on_salir() -> void:
	get_tree().quit()
