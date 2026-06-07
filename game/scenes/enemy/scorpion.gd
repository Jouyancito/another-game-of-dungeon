extends BaseEnemy

## Escorpion — territorial y agresivo dentro de su zona
## Stats: HP 75, DMG 8, DEF 3, XP 20, speed 4.0, mass 0.5
## Ataques: pinch (daño base) y sting (veneno: 4 ticks de 3 dmg, 1s)
## Persigue solo dentro de detection_range (10m), abandona a 15m

const ABANDON_RANGE := 15.0
const LATERAL_RANGE := 2.5  # distancia desde la que hace movimiento lateral

var _lateral_time := 0.0
var _use_sting_next := false  # alterna entre pinch y sting


func _on_enemy_ready() -> void:
	enemy_type = "scorpion"
	# Personalidad: territorial. Sólo aggro si el jugador entra en el territorio (12m del spawn).
	# Cuando el jugador escapa, el escorpión vuelve a su home (_process_territorial_leash).
	# El ABANDON_RANGE (15m) en _should_pursue override coexiste: la base TERRITORIAL
	# bloquea a 12m, y el override agrega 15m de seguridad. Efectivo = 12m.
	personality = AggroPersonality.TERRITORIAL
	default_color = Color(0.4, 0.25, 0.15)
	mass = 0.5
	# Territorial in dry, exposed terrain — hunts in open rocky fields
	habitat_type = "open_field"
	mesh.visible = false
	var model := EnemyModelBuilder.build_arthropod(
		default_color,
		0.4,    # body_length
		0.35,   # body_width
		0.12,   # body_height (flat)
		8,      # leg_count (8 legs — arachnid)
		true,   # has_tail (scorpion tail!)
		true    # has_pincers
	)
	model.name = "Model"
	add_child(model)


## Override: abandona la persecución si el jugador se aleja más de ABANDON_RANGE
func _should_pursue(distance: float) -> bool:
	if distance > ABANDON_RANGE:
		return false
	return super._should_pursue(distance)


## Movimiento con scuttle lateral cuando está cerca
func _move_toward_target(delta: float) -> void:
	if target == null:
		return

	_lateral_time += delta

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()

	if dist < 0.001:
		return

	var forward := to_target.normalized()

	if dist <= LATERAL_RANGE:
		# Movimiento lateral de cangrejo cuando está cerca
		var lateral := Vector3(forward.z, 0.0, -forward.x)
		var sine_val := sin(_lateral_time * 4.0) * 0.6
		var dir := (forward * 0.4 + lateral * sine_val).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed


## Alterna entre pinch y sting
func perform_attack() -> void:
	if has_status(&"stun"):
		return  # stun pausa ataque (canon _status_effects.md §2.2)
	can_attack = false

	if is_instance_valid(target):
		var mult: float = outgoing_damage_mult()
		if _use_sting_next:
			# Sting — picadura con veneno
			target.take_damage(damage * 0.5 * mult)
			_apply_poison_dot(target)
		else:
			# Pinch — daño base
			target.take_damage(damage * mult)

		_use_sting_next = not _use_sting_next

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


## Veneno: 4 ticks de 3 dmg con 1s de separación
func _apply_poison_dot(dot_target: Node3D) -> void:
	for i in range(4):
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(self) or not is_instance_valid(dot_target):
			return
		if is_dead:
			return
		dot_target.take_damage(3.0, "poison")
