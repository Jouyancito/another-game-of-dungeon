extends Node3D

## Mariposa ambiental — decorativa, no interactúa con combat/loot.
## Wander errático: pickea target random cada 0.5-2s dentro de wander_radius,
## lerp posición. Altura oscila 0.5-2.5m via sin wave.
## Se auto-libera si supera despawn_distance del spawner (señal despawned).

signal despawned(fauna: Node)

@export var wander_radius: float = 3.0       # radio target local
@export var move_speed: float = 1.5          # m/s hacia target
@export var height_min: float = 0.5
@export var height_max: float = 2.5
@export var height_period: float = 2.2       # segundos ciclo sin altura
@export var wing_flap_hz: float = 8.0        # freq batir alas
@export var despawn_distance: float = 50.0   # del spawner origin

var spawner_origin: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _time_to_repick: float = 0.0
var _time: float = 0.0

@onready var _wing_left: MeshInstance3D = $WingLeft
@onready var _wing_right: MeshInstance3D = $WingRight


func _ready() -> void:
	spawner_origin = global_position
	_pick_new_target()


func _process(delta: float) -> void:
	_time += delta
	_time_to_repick -= delta
	if _time_to_repick <= 0.0:
		_pick_new_target()

	# Movimiento XZ lerp hacia target
	var to_target: Vector3 = _target - global_position
	to_target.y = 0.0
	var step: float = move_speed * delta
	if to_target.length() > 0.05:
		global_position += to_target.normalized() * minf(step, to_target.length())

	# Altura via sin wave entre min/max
	var h_norm: float = (sin(_time * TAU / height_period) + 1.0) * 0.5
	global_position.y = spawner_origin.y + lerp(height_min, height_max, h_norm)

	# Flap alas via sin rapidísimo sobre rotation Z
	var flap: float = sin(_time * wing_flap_hz * TAU) * 0.8
	if _wing_left != null:
		_wing_left.rotation.z = flap
	if _wing_right != null:
		_wing_right.rotation.z = -flap

	# Check despawn
	if global_position.distance_to(spawner_origin) > despawn_distance:
		despawned.emit(self)
		queue_free()


func _pick_new_target() -> void:
	var angle: float = randf() * TAU
	var r: float = randf() * wander_radius
	_target = spawner_origin + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
	_time_to_repick = randf_range(0.5, 2.0)
