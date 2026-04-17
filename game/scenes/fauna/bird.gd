extends Node3D

## Pájaro ambiental — decorativo, no interactúa con combat/loot.
## Vuelo en arco: target lejano (flight_range), línea curva con altura sin,
## repite. Ocasional posarse (perch_chance) cuando llega a target.
## NO confundir con scenes/enemy/bird.tscn (enemigo real). Este es fauna.

signal despawned(fauna: Node)

@export var flight_range_min: float = 10.0
@export var flight_range_max: float = 20.0
@export var flight_speed: float = 4.0
@export var altitude_min: float = 5.0
@export var altitude_max: float = 15.0
@export var perch_chance: float = 0.1
@export var perch_duration_min: float = 2.0
@export var perch_duration_max: float = 3.0
@export var wing_flap_hz: float = 6.0
@export var despawn_distance: float = 60.0

enum State { FLYING, PERCHING }

var spawner_origin: Vector3 = Vector3.ZERO
var _state: int = State.FLYING
var _target: Vector3 = Vector3.ZERO
var _target_altitude: float = 0.0
var _perch_timer: float = 0.0
var _time: float = 0.0

@onready var _wing_left: MeshInstance3D = $WingLeft
@onready var _wing_right: MeshInstance3D = $WingRight


func _ready() -> void:
	spawner_origin = global_position
	_pick_flight_target()


func _process(delta: float) -> void:
	_time += delta

	match _state:
		State.FLYING:
			_process_flying(delta)
		State.PERCHING:
			_perch_timer -= delta
			if _perch_timer <= 0.0:
				_state = State.FLYING
				_pick_flight_target()

	# Flap alas siempre (hasta posado sigue aleteando ocasional)
	var flap: float = sin(_time * wing_flap_hz * TAU) * 0.6
	if _wing_left != null:
		_wing_left.rotation.z = flap
	if _wing_right != null:
		_wing_right.rotation.z = -flap

	if global_position.distance_to(spawner_origin) > despawn_distance:
		despawned.emit(self)
		queue_free()


func _process_flying(delta: float) -> void:
	var to_target: Vector3 = _target - global_position
	var dist: float = to_target.length()

	if dist < 0.8:
		if randf() < perch_chance:
			_state = State.PERCHING
			_perch_timer = randf_range(perch_duration_min, perch_duration_max)
			global_position.y = spawner_origin.y + 1.0
		else:
			_pick_flight_target()
		return

	var step: float = flight_speed * delta
	global_position += to_target.normalized() * minf(step, dist)

	# Face direction
	if to_target.length() > 0.01:
		look_at(_target, Vector3.UP)


func _pick_flight_target() -> void:
	var angle: float = randf() * TAU
	var r: float = randf_range(flight_range_min, flight_range_max)
	_target_altitude = randf_range(altitude_min, altitude_max)
	_target = spawner_origin + Vector3(cos(angle) * r, _target_altitude, sin(angle) * r)
