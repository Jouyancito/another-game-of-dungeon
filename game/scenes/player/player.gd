extends BasePlayer

# Combate — click: cadena de 5 golpes, mantener: frenesí rápido
@export var base_heavy_damage := 35.0
@export var base_combo_damage := 15.0
@export var combo_cooldown := 0.25
@export var base_knockback_force := 1.5

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

func _on_class_ready() -> void:
	# Combat values — únicos del Warrior
	speed = 5.0
	sprint_speed = 8.0
	crouch_speed = 2.5
	base_health = 100.0
	base_mana = 80.0
	attack_range = 3.0
	heavy_cooldown = 0.6
	# Stats (str, int, dex, def, vit) se cargan desde SaveManager en BasePlayer

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

	_do_melee(dmg, step.side, kb_force)

	combo_index = (combo_index + 1) % combo_chain.size()
	combo_reset_timer = 0.0

	await get_tree().create_timer(heavy_cooldown).timeout
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
		_do_melee(base_combo_damage, side, base_knockback_force * 0.3)

		await get_tree().create_timer(combo_cooldown).timeout
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

		# Calcular dirección del knockback
		var forward = -camera.global_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right = camera.global_basis.x
		right.y = 0
		right = right.normalized()

		# Knockback = empuja hacia adelante + lateral según el lado del puño
		var hit_direction = forward * 0.7 + right * side * 0.5
		hit_direction = hit_direction.normalized()

		result.collider.take_damage(final_damage, hit_direction, kb_force, str_stat)
