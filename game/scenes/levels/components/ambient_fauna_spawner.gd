extends Node3D
class_name AmbientFaunaSpawner

## Spawner reusable de fauna ambiental (mariposa, pájaro, conejo, etc).
## Instancia `count` criaturas en `_ready()` dentro de `spawn_radius` y escucha
## la señal `despawned(fauna)` para reponerlas si `respawn_on_despawn = true`.
##
## Las criaturas son decorativas (Node3D, sin CharacterBody3D, sin grupo enemies,
## sin pickup). Spawner no tiene perf cost más allá del de las N criaturas.

@export var creature_scene: PackedScene = null
@export_range(1, 30, 1) var count: int = 5
@export var spawn_radius: float = 15.0
@export var respawn_on_despawn: bool = true
## Altura Y del spawn inicial sobre origin. Criaturas con altitud propia (pájaro/mariposa)
## ignoran esto después del primer frame.
@export var spawn_height: float = 0.0

var _alive_count: int = 0


func _ready() -> void:
	if creature_scene == null:
		push_warning("[AmbientFaunaSpawner] creature_scene no asignado en %s" % name)
		return
	for i in range(count):
		_spawn_one()


func _spawn_one() -> void:
	if creature_scene == null:
		return
	var creature: Node3D = creature_scene.instantiate() as Node3D
	if creature == null:
		push_warning("[AmbientFaunaSpawner] creature_scene no es Node3D")
		return

	# Posición random dentro del radio (disco horizontal)
	var angle: float = randf() * TAU
	var r: float = sqrt(randf()) * spawn_radius  # sqrt para distribución uniforme en área
	var offset := Vector3(cos(angle) * r, spawn_height, sin(angle) * r)
	creature.position = offset

	# Escuchar despawn si la criatura lo emite
	if creature.has_signal("despawned"):
		creature.despawned.connect(_on_creature_despawned)

	add_child(creature)
	_alive_count += 1


func _on_creature_despawned(_fauna: Node) -> void:
	_alive_count -= 1
	if respawn_on_despawn:
		_spawn_one()
