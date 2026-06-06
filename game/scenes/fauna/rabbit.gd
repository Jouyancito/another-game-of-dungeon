extends Node3D

## Conejo ambiental — decorativo, no interactúa con combat/loot.
## Hop: scurry 2-3 hops hacia dir random, freeze 1-3s, repite.
## Si player <flee_radius: hop frenético opuesto al player 3-5 saltos, luego
## retoma wander normal.

signal despawned(fauna: Node)

@export var hop_distance: float = 1.0
@export var hop_height: float = 0.5
@export var hop_duration: float = 0.35
@export var freeze_duration_min: float = 1.0
@export var freeze_duration_max: float = 3.0
@export var hops_per_burst_min: int = 2
@export var hops_per_burst_max: int = 3
@export var flee_radius: float = 5.0
@export var flee_hops_min: int = 3
@export var flee_hops_max: int = 5
@export var flee_speed_multiplier: float = 1.6
@export var wander_radius: float = 15.0     # radio max desde spawner
@export var despawn_distance: float = 40.0

enum State { FREEZE, HOP }

var spawner_origin: Vector3 = Vector3.ZERO

var _state: int = State.FREEZE
var _freeze_timer: float = 0.0
var _hops_remaining: int = 0
var _hop_start: Vector3 = Vector3.ZERO
var _hop_target: Vector3 = Vector3.ZERO
var _hop_elapsed: float = 0.0
var _fleeing: bool = false


func _ready() -> void:
	spawner_origin = global_position
	add_to_group("ambient")
	_start_freeze()


func _process(delta: float) -> void:
	_check_player_proximity()

	match _state:
		State.FREEZE:
			_freeze_timer -= delta
			if _freeze_timer <= 0.0:
				_start_hop_burst()
		State.HOP:
			_process_hop(delta)

	if global_position.distance_to(spawner_origin) > despawn_distance:
		despawned.emit(self)
		queue_free()


func _check_player_proximity() -> void:
	if _fleeing:
		return
	var player: Node3D = _find_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) < flee_radius:
		_start_flee(player.global_position)


func _find_player() -> Node3D:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _start_freeze() -> void:
	_state = State.FREEZE
	_freeze_timer = randf_range(freeze_duration_min, freeze_duration_max)


func _start_hop_burst() -> void:
	_hops_remaining = randi_range(hops_per_burst_min, hops_per_burst_max)
	_fleeing = false
	_start_single_hop(_random_wander_direction())


func _start_flee(from_pos: Vector3) -> void:
	_fleeing = true
	_hops_remaining = randi_range(flee_hops_min, flee_hops_max)
	var away: Vector3 = global_position - from_pos
	away.y = 0.0
	if away.length() < 0.01:
		away = _random_wander_direction()
	else:
		away = away.normalized()
	_start_single_hop(away)


func _start_single_hop(direction: Vector3) -> void:
	_state = State.HOP
	_hop_start = global_position
	var multiplier: float = flee_speed_multiplier if _fleeing else 1.0
	_hop_target = _hop_start + direction * hop_distance * multiplier
	# Clamp dentro de wander_radius (solo si no huyendo — huir puede ir más lejos hasta despawn)
	if not _fleeing:
		var offset: Vector3 = _hop_target - spawner_origin
		offset.y = 0.0
		if offset.length() > wander_radius:
			_hop_target = spawner_origin + offset.normalized() * wander_radius
	_hop_elapsed = 0.0
	# Face direction
	if direction.length() > 0.01:
		var look_target: Vector3 = global_position + direction
		look_at(look_target, Vector3.UP)


func _process_hop(delta: float) -> void:
	_hop_elapsed += delta
	var t: float = clampf(_hop_elapsed / hop_duration, 0.0, 1.0)

	# Posición XZ lerp lineal
	var xz_pos: Vector3 = _hop_start.lerp(_hop_target, t)
	# Altura parábola: y = 4h*t*(1-t)
	var arc_y: float = 4.0 * hop_height * t * (1.0 - t)
	global_position = Vector3(xz_pos.x, _hop_start.y + arc_y, xz_pos.z)

	if t >= 1.0:
		global_position = _hop_target
		_hops_remaining -= 1
		if _hops_remaining > 0:
			# Continuar burst: mantener dirección con jitter chico
			var dir: Vector3 = (_hop_target - _hop_start).normalized()
			dir = dir.rotated(Vector3.UP, randf_range(-0.4, 0.4))
			_start_single_hop(dir)
		else:
			_fleeing = false
			_start_freeze()


func _random_wander_direction() -> Vector3:
	var angle: float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle))
