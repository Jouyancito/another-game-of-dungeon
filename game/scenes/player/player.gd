extends BasePlayer

# Combate — click: cadena de 5 golpes, mantener: frenesí rápido
@export var base_heavy_damage := 35.0
@export var base_combo_damage := 15.0
@export var combo_cooldown := 0.25
@export var base_knockback_force := 0.7

# Cadena de combo: cada golpe tiene dirección lateral (1.0 = derecha, -1.0 = izquierda)
# y multiplicador de daño. El último golpe es un finisher más fuerte.
var combo_chain := [
	{ "side": 1.0, "dmg_mult": 1.0 },    # Golpe 1: derecha
	{ "side": -1.0, "dmg_mult": 1.0 },    # Golpe 2: izquierda
	{ "side": 1.0, "dmg_mult": 1.1 },     # Golpe 3: derecha
	{ "side": -1.0, "dmg_mult": 1.1 },    # Golpe 4: izquierda
	{ "side": 0.0, "dmg_mult": 1.5 },     # Golpe 5: finisher central
]
var combo_index := 0
var combo_reset_timer := 0.0
@export var combo_reset_time := 1.5  # Tiempo sin pegar para resetear la cadena

func get_class_color() -> Color:
	return Color(0.8, 0.3, 0.2)  # rojo guerrero

func _on_class_ready() -> void:
	# Combat values — únicos del Warrior
	speed = 5.0
	sprint_speed = 8.0
	crouch_speed = 2.5
	base_health = 100.0
	base_mana = 80.0
	attack_range = 3.0
	heavy_cooldown = 0.6
	# Canon balance_v2 §2.3 — class_mult físico del Warrior = 1.5.
	class_mult_physical = 1.5
	class_mult_magic = 1.0
	# Stats (str, int, dex, def, vit) se cargan desde SaveManager en BasePlayer
	# Recurso único: Rage (canon _system.md §5ter). Cap 100, sin regen pasivo, decay 5/s fuera combate.
	class_resource = ClassResource.new()
	class_resource.type = ClassResource.Type.RAGE
	class_resource.max_value = 100
	class_resource.regen_rate = 0.0
	class_resource.combat_decay_rate = 5.0
	class_resource.decay_delay_s = 8.0


func _equip_default_skills() -> void:
	# Fase 1 canon: 4 skills generales del Warrior (warrior.md §3).
	var db = get_node_or_null("/root/SkillDB")
	if db == null:
		return
	var punch: SkillResource = db.get_skill(&"warrior_punch")
	var charge: SkillResource = db.get_skill(&"warrior_charge")
	var war_cry: SkillResource = db.get_skill(&"warrior_war_cry")
	var perfect_block: SkillResource = db.get_skill(&"warrior_perfect_block")
	if punch != null:
		skills.set_slot(0, punch)
	if charge != null:
		skills.set_slot(1, charge)
	if war_cry != null:
		skills.set_slot(2, war_cry)
	if perfect_block != null:
		skills.set_slot(3, perfect_block)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Resetear combo si pasa mucho tiempo sin pegar
	if combo_index > 0:
		combo_reset_timer += delta
		if combo_reset_timer >= combo_reset_time:
			combo_index = 0
			combo_reset_timer = 0.0

func _on_attack_pressed() -> void:
	is_holding_attack = false
	_attack_heavy()

func _on_attack_released() -> void:
	is_holding_attack = false

func _attack_heavy() -> void:
	if not can_attack:
		return
	can_attack = false

	var step = combo_chain[combo_index]
	var dmg = base_heavy_damage * step.dmg_mult
	var kb_force = base_knockback_force
	if combo_index == combo_chain.size() - 1:
		kb_force *= 1.8  # Finisher empuja más

	# Animar brazo según el lado del golpe
	if view_model:
		if step.side > 0:
			view_model.play_attack_right(heavy_cooldown)
		elif step.side < 0:
			view_model.play_attack_left(heavy_cooldown)
		else:
			view_model.play_attack_both(heavy_cooldown)  # finisher
	if world_model:
		if step.side > 0:
			world_model.play_attack_right(heavy_cooldown)
		elif step.side < 0:
			world_model.play_attack_left(heavy_cooldown)
		else:
			world_model.play_attack_both(heavy_cooldown)

	# AnimationTree OneShot — si rig importado, dispara punch. animation_finished
	# gateará el hit window; si inactive, caemos al timer hardcoded (fallback wave2).
	if animation_controller != null and animation_controller.trigger_attack(&"attack_punch"):
		pass  # tree activo — _wait_attack_window usa animation_finished

	_do_melee(dmg, step.side, kb_force)

	combo_index = (combo_index + 1) % combo_chain.size()
	combo_reset_timer = 0.0

	await _wait_attack_window(heavy_cooldown)
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		is_holding_attack = true
		_attack_frenzy()

func _attack_frenzy() -> void:
	while can_attack and is_holding_attack and not is_dead:
		can_attack = false

		# Frenesí: alterna rápido derecha-izquierda, knockback reducido
		var side = 1.0 if fmod(combo_reset_timer * 10.0, 2.0) < 1.0 else -1.0
		if view_model:
			if side > 0:
				view_model.play_attack_right(combo_cooldown)
			else:
				view_model.play_attack_left(combo_cooldown)
		if world_model:
			if side > 0:
				world_model.play_attack_right(combo_cooldown)
			else:
				world_model.play_attack_left(combo_cooldown)
		_do_melee(base_combo_damage, side, base_knockback_force * 0.3)

		await _wait_attack_window(combo_cooldown)
		if not is_instance_valid(self) or is_dead:
			return
		can_attack = true

		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_holding_attack = false

	# Después del frenesí, resetear combo chain
	combo_index = 0
	combo_reset_timer = 0.0

func _do_melee(base_dmg: float, side: float = 0.0, kb_force: float = 0.0) -> void:
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_basis.z) * attack_range
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	if result and result.collider.is_in_group("enemies"):
		var final_damage = get_physical_damage(base_dmg)

		# Efecto billar: golpe centrado = máxima fuerza, golpe de costado = menos fuerza + desvío
		var enemy_pos = result.collider.global_position
		var hit_point = result.position

		# Vector desde el punto de impacto al centro del enemigo (en plano XZ)
		var impact_to_center = enemy_pos - hit_point
		impact_to_center.y = 0

		# Vector desde el jugador al enemigo
		var player_to_enemy = enemy_pos - global_position
		player_to_enemy.y = 0
		player_to_enemy = player_to_enemy.normalized()

		# Qué tan centrado fue el golpe (1.0 = perfecto al centro, 0.0 = rozando el borde)
		var center_factor = 1.0 - clampf(impact_to_center.length() * 2.0, 0.0, 0.8)

		# Dirección: golpe centrado empuja recto, golpe lateral desvía
		var hit_direction: Vector3
		if impact_to_center.length() < 0.05:
			# Casi perfecto al centro — empuja recto
			hit_direction = player_to_enemy
		else:
			# Golpe descentrado — desvía hacia donde apunta el impacto
			var deflection = (enemy_pos + impact_to_center.normalized() * 0.5) - global_position
			deflection.y = 0
			hit_direction = deflection.normalized()

		# Fuerza reducida por golpe descentrado
		var effective_kb = kb_force * (0.4 + center_factor * 0.6)

		result.collider.take_damage(final_damage, hit_direction, effective_kb, get_effective_stat("str"), self)
		# Rage gen del melee básico LMB vive en base_player.take_damage (pasivo por dmg recibido)
		# + en skills via resource_gen_on_hit. El combo hardcoded NO es una skill — no gen.
		# Fase futura: migrar el combo a skill framework para unificar.


## Gateo hit window. Si AnimationTree activo y attack OneShot disparado,
## espera `animation_finished` (real anim duration). Si inactive, fallback timer hardcoded.
## Safety timeout fallback_s*2 evita hang si signal nunca llega.
func _wait_attack_window(fallback_s: float) -> void:
	if animation_controller == null or not animation_controller.is_attacking():
		await get_tree().create_timer(fallback_s).timeout
		return
	var done: Array = [false]
	var on_finish: Callable = func(_v: StringName) -> void: done[0] = true
	var on_timeout: Callable = func() -> void: done[0] = true
	animation_controller.attack_finished.connect(on_finish, CONNECT_ONE_SHOT)
	var timer := get_tree().create_timer(fallback_s * 2.0)
	timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	while not done[0]:
		await get_tree().process_frame
	if animation_controller.attack_finished.is_connected(on_finish):
		animation_controller.attack_finished.disconnect(on_finish)
