class_name Golem
extends BaseEnemy

## Golem de Piedra — NEUTRAL, se camufla como roca hasta que el jugador se acerca.
## Ataques: Puñetazo (melee + knockback), Pisotón AoE, Lanzar roca (rango).

var is_dormant := true
var awaken_tween: Tween
var attack_index := 0
var stomp_range := 3.0
var throw_range := 10.0

## Carved eyes stay dark while the golem is camouflaged as a rock; _awaken()
## lights them up. Cyan jewel accent (#5FD8FF) — the crystal core of a
## prairie golem. Matches the DP_ToonGrounded cyan accent canon.
const EYE_COLOR := Color(0.373, 0.847, 1.0)  # #5FD8FF
const EYE_ENERGY := 3.2
var _eye_mats: Array[StandardMaterial3D] = []

## Floating rocks: stored so _awaken() can tween them up and _sleep() can
## return them to their embedded resting positions.
var _floating_rocks: Array[Node3D] = []
var _rock_rest_positions: Array[Vector3] = []
var _rock_orbit_positions: Array[Vector3] = []

## Shared toon pipeline (game/docs/shader_system.md). This golem is the visual
## TEMPLATE — the whole enemy roster will move to these same shaders.
const TOON_SHADER: Shader = preload("res://scenes/levels/dp_toon_grounded.gdshader")
## 2-sided variant (abs(dot) lights both faces) — for the thin dressing so its
## back faces aren't black when double-sided.
const TOON_SHADER_2S: Shader = preload("res://scenes/levels/dp_toon_grounded_2sided.gdshader")
const OUTLINE_SHADER: Shader = preload("res://assets/art/shaders/toon_outline.gdshader")

@onready var head_mesh: MeshInstance3D = $Head


func _on_enemy_ready() -> void:
	enemy_type = "golem"
	# Personalidad: lento imparable. Una vez despierto, jamás abandona la persecución.
	# speed_mult=0.7 lo hace más lento. JUGGERNAUT_SLOW + NEUTRAL + is_provoked (set en _awaken)
	# → el golem persigue hasta 999m de distancia desde que despertó.
	personality = AggroPersonality.JUGGERNAUT_SLOW
	default_color = Color(0.5, 0.5, 0.5)
	mass = 3.0
	knockback_resistance = 0.7
	mesh.visible = false
	# Also hide the Head mesh from .tscn
	var old_head: Node = get_node_or_null("Head")
	if old_head:
		old_head.visible = false

	# Bespoke stone-golem body (game/tools/blender/gen_golem.py): a hunched rock
	# construct on its OWN low-poly mesh (~2.4k tris) with TWO material slots —
	# "golem_stone" (body) + "golem_eye_core" (the carved eyes). Dressed at runtime
	# with prairie moss/flowers/mushrooms + floating rocks so the golem reads as
	# "the prairie made stone". See docs/art/_bestiary_visual_bible.md §6.5.
	const GOLEM_BODY := "res://assets/art/piso1_pradera/enemies/big/golem_dp_body_01.glb"
	var packed: PackedScene = load(GOLEM_BODY) if ResourceLoader.exists(GOLEM_BODY) else null
	if packed != null:
		var model: Node3D = packed.instantiate()
		model.name = "Model"
		_apply_golem_materials(model)
		# Face was authored toward -Z (= Godot forward), so NO 180° flip is needed
		# (unlike Quaternius packs). If the golem ever walks backwards, set to PI.
		model.rotation.y = 0.0
		add_child(model)
		# Fit height to 2.5m + box hitbox. width_mult 1.0: the bespoke body is
		# already stocky/wide (arms span), no extra stretch needed.
		EnemyModelFitter.fit(self, model, 5.0, "box", 0.22, 1.0)  # ~5m: towers over a 1.8m player
		# Dress it — children of `model` so they track the visual exactly (scale
		# + position + rotation), added AFTER fit() so positions stay aligned.
		_grow_moss(model)
		_spawn_floating_rocks(model)
	else:
		# Fallback: procedural humanoid (graceful degradation)
		push_warning("Golem: golem_dp_body_01.glb not found, using proc mesh")
		var model := EnemyModelBuilder.build_humanoid(default_color, 1.5, 1.4)
		model.name = "Model"
		add_child(model)

	# Dormant: aplastado como roca — tween re-points to self.scale (unchanged)
	scale = Vector3(1.34, 0.40, 1.34)  # dormant: flat + wide = a mossy boulder asleep


## Body stone + amber eyes that light up on awaken. Overrides per-surface BY
## MATERIAL NAME — the glb carries slot "golem_stone" + slot "golem_eye_core".
## Falls back to surface index 1 = eyes if material names were stripped on import.
func _apply_golem_materials(model: Node3D) -> void:
	# White albedo + vertex colors: the body glb bakes per-block stone tones as
	# vertex colors (gen_golem.py) so the golem reads as many stones, not one flat
	# tan. vertex_color_use_as_albedo lets those baked tones drive the surface color.
	# Toon (cell-shaded) stone: the shared DP_ToonGrounded shader drives the body
	# from its baked per-block vertex colors (use_vertex_color) — 3 hard light bands
	# + cool non-black shadow + warm rim = the anime look. Dark outline via next_pass.
	var stone_mat := ShaderMaterial.new()
	stone_mat.shader = TOON_SHADER
	stone_mat.set_shader_parameter("albedo_color", Color(1, 1, 1))
	stone_mat.set_shader_parameter("use_vertex_color", true)
	# Solid HEAVY stone: kill most of the rim glow + deepen shadows so it reads as
	# opaque rock, not a washed/translucent surface (Joan: "se siente transparente").
	stone_mat.set_shader_parameter("rim_intensity", 0.10)
	stone_mat.set_shader_parameter("shadow_darkness", 0.40)  # not too dark — black shadow reads as 'transparent void'
	stone_mat.set_shader_parameter("shadow_tint_strength", 0.30)
	stone_mat.next_pass = _make_outline(0.012)  # thin: avoids poking through concave block seams

	# Eyes start CAMOUFLAGED: stone-colored albedo, emission energy 0 so the
	# golem reads as a plain rock. _awaken() (proximity OR hit) fades them up to
	# the muted amber above. Kept as a member ref so _light_up_eyes can tween it.
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.42, 0.40, 0.36)  # stone tone while dormant (camouflaged)
	eye_mat.roughness = 0.95
	eye_mat.emission_enabled = true
	eye_mat.emission = EYE_COLOR
	eye_mat.emission_energy_multiplier = 0.0
	eye_mat.next_pass = _make_outline()
	_eye_mats.append(eye_mat)

	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var surf_mesh: Mesh = (mi as MeshInstance3D).mesh
		if surf_mesh == null:
			continue
		var matched_eye := false
		for s in range(surf_mesh.get_surface_count()):
			var smat := surf_mesh.surface_get_material(s)
			var sname := smat.resource_name.to_lower() if smat != null else ""
			if sname.contains("eye"):
				(mi as MeshInstance3D).set_surface_override_material(s, eye_mat)
				matched_eye = true
			else:
				(mi as MeshInstance3D).set_surface_override_material(s, stone_mat)
		# Fallback: names stripped on import → assume 2nd surface is the eyes.
		if not matched_eye and surf_mesh.get_surface_count() == 2:
			(mi as MeshInstance3D).set_surface_override_material(1, eye_mat)


## Inverted-hull outline (shared toon_outline shader) as a material next_pass —
## the dark contour that sells the anime/cel look.
func _make_outline(thickness := 0.03) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OUTLINE_SHADER
	m.set_shader_parameter("outline_color", Color(0.05, 0.05, 0.07))
	m.set_shader_parameter("outline_thickness", thickness)
	return m


## Make a dressing instance (moss/flower/rock) DOUBLE-SIDED so it never shows
## see-through from behind (these are simple convex-ish meshes, so cull_disabled
## is clean — unlike the non-manifold body, which must stay single-sided).
func _make_solid(inst: Node3D) -> void:
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s in range(mesh.get_surface_count()):
			var base := mesh.surface_get_material(s)
			var col := Color(1, 1, 1)
			if base is BaseMaterial3D:
				col = (base as BaseMaterial3D).albedo_color
			# 2-sided toon: double-sided (no see-through) + both faces lit (no black
			# underside) + cohesive toon look. NO outline next_pass (that darkened the body).
			var tm := ShaderMaterial.new()
			tm.shader = TOON_SHADER_2S
			tm.set_shader_parameter("albedo_color", col)
			tm.set_shader_parameter("use_vertex_color", false)
			(mi as MeshInstance3D).set_surface_override_material(s, tm)


## Vegetation with ECOLOGICAL LOGIC: moss colonizes the broad UPWARD-facing
## surfaces across the whole upper body (where rain pools + light reaches);
## flowers are rare accents only on the sunniest crown/shoulder tops. Reads as
## "the prairie slowly took the rock", not props stuck on. Model-local (+Y up).
## LEFT shoulder is the overgrown side (denser). Anchors eyeballed — tune live.
func _grow_moss(model: Node3D) -> void:
	# Moss is now PAINTED into the stone (gen_golem.py paint_moss: up-facing/high
	# faces go green). Here we only sprinkle small 3D FLOWERS on top of those mossy
	# areas — the little 3D pop (Joan's idea), not a carpet of stuck-on meshes.
	var flowers := [
		"res://assets/art/piso1_pradera/enemies/big/golem_flower_pink_01.glb",
		"res://assets/art/piso1_pradera/enemies/big/golem_flower_white_01.glb",
		"res://assets/art/piso1_pradera/enemies/big/golem_flower_yellow_01.glb",
	]
	# Up-facing/mossy spots across the body; ~half get a tiny flower (sparse).
	var spots := [
		Vector3(0.00, 2.36, -0.06), Vector3(-0.22, 2.30, 0.04),
		Vector3(-0.66, 2.06, 0.00), Vector3(-0.44, 2.06, 0.14),
		Vector3(-0.30, 1.96, 0.28), Vector3(0.60, 1.92, 0.00),
		Vector3(0.48, 1.86, 0.16), Vector3(0.00, 2.12, -0.28),
		Vector3(-0.34, 2.00, -0.24), Vector3(-0.96, 1.52, 0.04),
		Vector3(0.92, 1.46, 0.02), Vector3(0.04, 1.60, 0.34),
		Vector3(-0.42, 0.42, 0.18), Vector3(0.42, 0.42, 0.18),
		Vector3(-0.40, 0.72, -0.02), Vector3(0.40, 0.72, -0.04),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xC0FFEE
	for a in spots:
		if rng.randf() > 0.72:
			continue  # most spots get a flower now (Joan: didn't see them before)
		var f := _instance_plant(flowers[rng.randi() % flowers.size()])
		if f == null:
			continue
		f.position = a
		var sc := rng.randf_range(0.42, 0.62)
		f.scale = Vector3(sc, sc, sc)
		f.rotation.y = rng.randf() * TAU
		model.add_child(f)
		_make_solid(f)

	# Branch + nest PULLED — the first pass read as crude stuck-on primitives (no
	# cohesion with the golem). Revisit as a properly-modelled bespoke asset later.


## Load + instantiate a dressing glb (null if missing).
func _instance_plant(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	return ps.instantiate()


## A few small rocks that sit EMBEDDED/RESTING on the golem while dormant, then
## LIFT into a slow orbit on _awaken(). Sides/back only — never in front of the
## face (blocks the eye read). Uses bespoke golem_rock_chip_01.glb which bakes
## the body's stone color so chips read as broken-off golem stone.
## NOTE: positions are eyeballed in model-local space; tune live in Godot.
func _spawn_floating_rocks(model: Node3D) -> void:
	const FLOAT_ROCK := "res://assets/art/piso1_pradera/enemies/big/golem_rock_chip_01.glb"
	if not ResourceLoader.exists(FLOAT_ROCK):
		return

	# Each entry: rest pos (embedded/touching body) + orbit pos (lifted, clear of body).
	# Orbit Y is higher; X/Z push the rock out slightly so it clears the silhouette.
	var specs := [
		{
			"rest":  Vector3(-1.05, 1.20, 0.20),   # tucked against left shoulder
			"orbit": Vector3(-1.40, 2.10, 0.35),   # lifted, orbiting left side
		},
		{
			"rest":  Vector3(1.00, 1.65, 0.25),    # tucked against right upper arm
			"orbit": Vector3(1.35, 2.45, 0.40),   # lifted, orbiting right side
		},
		{
			"rest":  Vector3(0.75, 0.90, 0.55),    # resting on right hip/leg
			"orbit": Vector3(1.05, 1.80, 0.80),   # lifted, orbiting right-back
		},
		{
			"rest":  Vector3(-0.55, 0.72, -0.40),  # embedded in the back hump
			"orbit": Vector3(-0.85, 2.20, -0.60), # lifted, orbiting back-left
		},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xB0CC
	for spec in specs:
		var rock_scene := load(FLOAT_ROCK) as PackedScene
		if rock_scene == null:
			continue
		var rock: Node3D = rock_scene.instantiate()
		rock.position = spec["rest"]  # start EMBEDDED — dormant state
		var sc := rng.randf_range(0.22, 0.34)
		rock.scale = Vector3(sc, sc, sc)
		rock.rotation = Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6)
		model.add_child(rock)
		_floating_rocks.append(rock)
		_rock_rest_positions.append(spec["rest"])
		_rock_orbit_positions.append(spec["orbit"])


## Override: NEUTRAL + lógica de despertar por proximidad
func _should_pursue(distance: float) -> bool:
	if is_dormant:
		if distance <= detection_range:
			_awaken()
		return false
	# Despierto: delega a BaseEnemy (respeta alert flag para aggro ranged)
	return super._should_pursue(distance)


func _awaken() -> void:
	if awaken_tween and awaken_tween.is_running():
		return
	# Phase 1: eyes light up (the rock "opens its eyes" — cyan jewel glow).
	_light_up_eyes()
	# Phase 2: body rises from flat squash to full height — un-bouncy, heavy, cubic.
	# Rigid stone must NOT scale-stretch like rubber (Joan). The real awaken will need
	# separate part meshes (forearms swing down, head lifts, shoulders grind); for now
	# the squash→stand tween with rock lift is the primary visual read.
	awaken_tween = create_tween()
	awaken_tween.tween_property(self, "scale", Vector3.ONE, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Phase 3: while the body rises, rocks lift from embedded rest to orbit heights.
	# Staggered delays so each rock lifts at a slightly different moment (cascade feel).
	for i in range(_floating_rocks.size()):
		var rock: Node3D = _floating_rocks[i]
		var orbit: Vector3 = _rock_orbit_positions[i]
		var delay := 0.10 + i * 0.12  # stagger: first rock lifts at 100ms, rest cascade
		var lift := create_tween()
		lift.tween_interval(delay)
		lift.tween_property(rock, "position", orbit, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		lift.tween_callback(func(): _start_rock_orbit(rock, orbit, i))
	awaken_tween.tween_callback(func():
		is_dormant = false
		is_provoked = true
	)


## Start the idle hover + slow spin on a rock once it has reached its orbit position.
## Each rock gets slightly different period so they don't move in lockstep.
func _start_rock_orbit(rock: Node3D, base_pos: Vector3, idx: int) -> void:
	if not is_instance_valid(rock):
		return
	var amp := 0.18 + idx * 0.05   # slightly different hover amplitude per rock
	var dur := 2.0 + idx * 0.7     # slightly different hover period per rock
	var hover := create_tween().set_loops()
	hover.tween_property(rock, "position:y", base_pos.y + amp, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover.tween_property(rock, "position:y", base_pos.y,       dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var spin := create_tween().set_loops()
	spin.tween_property(rock, "rotation:y", TAU, dur * 3.5).as_relative()


## Return to the dormant rock state (preview cycling / re-camouflage). Eyes off,
## body settles back into the flat mossy boulder, rocks drop to embedded rest.
func _sleep() -> void:
	if awaken_tween and awaken_tween.is_running():
		awaken_tween.kill()
	is_dormant = true
	is_provoked = false
	for em in _eye_mats:
		em.emission_energy_multiplier = 0.0
		em.albedo_color = Color(0.42, 0.40, 0.36)  # camouflage back to stone tone
	# Body flattens back into the boulder pose.
	create_tween().tween_property(self, "scale", Vector3(1.34, 0.40, 1.34), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Rocks sink back to their embedded rest positions (slower than lift — heavy stone).
	for i in range(_floating_rocks.size()):
		var rock: Node3D = _floating_rocks[i]
		if not is_instance_valid(rock):
			continue
		var rest: Vector3 = _rock_rest_positions[i]
		create_tween().tween_property(rock, "position", rest, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


## Fade the carved eyes from camouflaged stone to cyan jewel glow when awakening.
## Albedo also shifts to cyan so the eye face itself reads as crystal, not just a
## glowing stone (the emission bloom alone bleeds into the surrounding stone color).
func _light_up_eyes() -> void:
	for em in _eye_mats:
		em.emission = EYE_COLOR
		create_tween().tween_property(em, "albedo_color", EYE_COLOR, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(em, "emission_energy_multiplier", EYE_ENERGY, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Idle: inmóvil, camuflado como roca
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Returns the gltf model root so EnemyAnimator can find the AnimationPlayer.
func _get_anim_model_root() -> Node3D:
	return get_node_or_null("Model")


## Override take_damage: si duerme, despertar antes de recibir daño
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dormant:
		_awaken()
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


## Cicla entre 3 ataques: Puñetazo → Pisotón AoE → Lanzar roca
func perform_attack() -> void:
	if not can_attack:
		return
	can_attack = false

	match attack_index:
		0:
			_attack_punch()
		1:
			_attack_stomp()
		2:
			_attack_rock_throw()

	attack_index = (attack_index + 1) % 3

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true


## Puñetazo: daño base + knockback al target
func _attack_punch() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage * outgoing_damage_mult())
	if target.has_method("apply_knockback"):
		var direction = (target.global_position - global_position).normalized()
		target.apply_knockback(direction, 12.0)


## Pisotón AoE: daña a TODOS los jugadores dentro de stomp_range
func _attack_stomp() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not is_instance_valid(player):
			continue
		var dist = global_position.distance_to(player.global_position)
		if dist <= stomp_range and player.has_method("take_damage"):
			player.take_damage(damage * 0.8 * outgoing_damage_mult())


## Lanzar roca: daño a rango, sin proyectil — hit directo simplificado
func _attack_rock_throw() -> void:
	if not is_instance_valid(target):
		return
	var dist = global_position.distance_to(target.global_position)
	if dist <= throw_range and target.has_method("take_damage"):
		target.take_damage(damage * 0.6 * outgoing_damage_mult())


## Muerte: sin efecto extra por ahora
func _on_death() -> void:
	pass


## Knockback: el golem es muy pesado, reacción mínima
func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
