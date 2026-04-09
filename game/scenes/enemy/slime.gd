extends BaseEnemy

## Slime — enemigo básico agresivo
## Se mueve a saltitos hacia el jugador. Lento pero persistente.
## Al morir se divide en 4 mini-slimes (si no es mini).

# Saltitos
@export var hop_force := 4.0
@export var hop_interval := 1.6

# División
@export var is_mini := false
@export var split_count := 4

var hop_timer := 0.0
var is_hopping := false

var mini_slime_scene: PackedScene


func _on_enemy_ready() -> void:
	default_color = Color(0.2, 0.75, 0.2) if not is_mini else Color(0.3, 0.85, 0.3)
	mass = 0.5 if not is_mini else 0.2
	hop_timer = hop_interval
	if not is_mini:
		mini_slime_scene = load("res://scenes/enemy/mini_slime.tscn")


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


func _on_knockback(kb_velocity: Vector3) -> void:
	# Efecto jelly: se estira en la dirección del golpe y rebota de vuelta
	var stretch_dir = kb_velocity.normalized()
	var stretch_x = 1.0 + absf(stretch_dir.x) * 0.3
	var stretch_z = 1.0 + absf(stretch_dir.z) * 0.3
	var squish_y = 0.8

	var jelly = create_tween()
	jelly.tween_property(self, "scale", Vector3(stretch_x, squish_y, stretch_z), 0.1)
	jelly.tween_property(self, "scale", Vector3(0.85, 1.2, 0.85), 0.1)
	jelly.tween_property(self, "scale", Vector3(1, 1, 1), 0.15).set_ease(Tween.EASE_OUT)


func _on_death() -> void:
	if not is_mini:
		_spawn_mini_slimes()

	# Squash visual al morir — se aplasta antes de encogerse
	var squash = create_tween()
	squash.tween_property(self, "scale", Vector3(1.5, 0.3, 1.5), 0.2)


func _spawn_mini_slimes() -> void:
	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for i in split_count:
		var mini = mini_slime_scene.instantiate()
		# Posicionar en círculo alrededor de donde murió el slime grande
		var angle = (TAU / split_count) * i
		var offset = Vector3(cos(angle) * 0.8, 0.5, sin(angle) * 0.8)
		mini.global_position = global_position + offset
		scene_root.call_deferred("add_child", mini)
