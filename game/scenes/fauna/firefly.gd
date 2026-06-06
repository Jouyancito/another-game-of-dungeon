extends Node3D

## Luciérnaga ambiental — drift lento + OmniLight3D pulsante. Decorativa (sin combat/loot).
## Conforme al contrato de AmbientFaunaSpawner: emite `despawned` al alejarse.
## Grupo "ambient". OmniLight: shadow OFF, range chico (perf red-line #1/#2).

signal despawned(fauna: Node)

@export var drift_speed: float = 0.8
@export var drift_radius: float = 3.0
@export var light_min_energy: float = 0.10
@export var light_max_energy: float = 0.40
@export var pulse_hz: float = 1.4
@export var despawn_distance: float = 50.0

var spawner_origin: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _angle: float = 0.0

@onready var _light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	spawner_origin = global_position
	add_to_group("ambient")
	# Intención: las luciérnagas DERIVAN en el aire. Nunca se aplastan al suelo.
	# El detector de flotantes las excluye por este tag (no por adivinar altura).
	add_to_group("aerial")
	if _light:
		_light.shadow_enabled = false   # mandatory (perf red-line #2)
		_light.omni_range = 4.0          # tiny range (perf §4)


func _process(delta: float) -> void:
	_time += delta
	_angle += (drift_speed * delta) / maxf(drift_radius, 0.01)
	global_position = spawner_origin + Vector3(
		cos(_angle) * drift_radius,
		sin(_time * 0.8) * 0.4,
		sin(_angle * 0.7) * drift_radius * 0.8)
	if _light:
		var pulse: float = sin(_time * pulse_hz * TAU) * 0.5 + 0.5
		_light.light_energy = lerp(light_min_energy, light_max_energy, pulse)
	if global_position.distance_to(spawner_origin) > despawn_distance:
		despawned.emit(self)
		queue_free()
