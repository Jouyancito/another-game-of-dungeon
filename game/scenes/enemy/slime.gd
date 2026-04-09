extends BaseEnemy

## Slime — enemigo básico agresivo
## Se mueve a saltitos hacia el jugador. Lento pero persistente.

# Saltitos
@export var hop_force := 4.0
@export var hop_interval := 1.6

var hop_timer := 0.0
var is_hopping := false


func _on_enemy_ready() -> void:
	default_color = Color(0.2, 0.75, 0.2)  # Verde slime
	hop_timer = hop_interval


func _move_toward_target(delta: float) -> void:
	# El slime se mueve a saltos, no caminando
	hop_timer -= delta

	if hop_timer <= 0.0 and is_on_floor():
		hop_timer = hop_interval
		is_hopping = true

		# Impulso hacia el jugador + hacia arriba
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		velocity.x = direction.x * speed * 1.5
		velocity.z = direction.z * speed * 1.5
		velocity.y = hop_force

	# Fricción: más fuerte en el suelo, leve en el aire para evitar spinning
	if is_on_floor() and not is_hopping:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)
	elif not is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 1.5)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 1.5)

	if is_hopping and is_on_floor() and velocity.y <= 0:
		is_hopping = false


func _idle_behavior(delta: float) -> void:
	# Frenar suavemente
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)


func _on_death() -> void:
	# Squash visual al morir — se aplasta antes de encogerse
	var squash = create_tween()
	squash.tween_property(self, "scale", Vector3(1.5, 0.3, 1.5), 0.2)
