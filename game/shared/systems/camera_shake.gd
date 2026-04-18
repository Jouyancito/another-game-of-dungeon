extends Node
class_name CameraShakeSingleton

## CameraShake — singleton global para feedback de impacto visual.
## Autoload registrado en project.godot como "CameraShake".
##
## Uso:
##   CameraShake.shake(0.3, 0.3)       # intensidad, duración
##   CameraShake.shake_light()          # preset leve (skill hit)
##   CameraShake.shake_medium()         # preset medio (dash impact)
##   CameraShake.shake_heavy()          # preset pesado (reactive triggered)
##
## Busca la Camera3D activa via grupo "player_camera" o current_scene.find_child.
## Si no la encuentra, no crashea — simplemente no shakeamos.

# ── Señales ───────────────────────────────────────────────────────────────────
signal shake_started(intensity: float, duration: float)
signal shake_finished

# ── Config tuneable ────────────────────────────────────────────────────────────
@export var max_offset_x: float = 0.05   # metros máximos de offset horizontal
@export var max_offset_y: float = 0.04   # metros máximos de offset vertical

# ── Estado ────────────────────────────────────────────────────────────────────
var _current_intensity: float = 0.0
var _current_duration: float = 0.0
var _elapsed: float = 0.0
var _active: bool = false
var _camera_origin: Vector3 = Vector3.ZERO
var _camera: Camera3D = null
var _tween: Tween = null


# ── Presets ───────────────────────────────────────────────────────────────────

## Shake leve — skill hit normal.
func shake_light() -> void:
	shake(0.15, 0.2)


## Shake medio — dash hit o impacto significativo.
func shake_medium() -> void:
	shake(0.3, 0.3)


## Shake pesado — reactive triggered, boss die.
func shake_heavy() -> void:
	shake(0.6, 0.45)


# ── API principal ─────────────────────────────────────────────────────────────

## Aplica camera shake. intensity en [0, 1] (escala máximo offset).
## duration en segundos. Si ya hay shake activo, toma el mayor intensity.
func shake(intensity: float, duration: float) -> void:
	# Si hay shake activo y el nuevo es más débil, ignorar
	if _active and intensity < _current_intensity:
		# Extender duración si es mayor
		if duration > (_current_duration - _elapsed):
			_current_duration = _elapsed + duration
		return

	_current_intensity = clampf(intensity, 0.0, 1.0)
	_current_duration = duration
	_elapsed = 0.0
	_active = true

	# Guardar posición original de la cámara
	var cam := _get_camera()
	if cam != null:
		# Solo guardamos si no estábamos en shake (evitar drift acumulativo)
		if not _active or _camera != cam:
			_camera = cam
			_camera_origin = cam.position

	shake_started.emit(intensity, duration)

	# Cancelar tween anterior si existe
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var progress := _elapsed / maxf(_current_duration, 0.001)

	if progress >= 1.0:
		_finish_shake()
		return

	# Decay lineal: intensidad decrece con el tiempo
	var current_power := _current_intensity * (1.0 - progress)

	var cam := _get_camera()
	if cam == null:
		return

	# Offset random en X/Y proporcional a intensity
	var offset_x := randf_range(-1.0, 1.0) * max_offset_x * current_power
	var offset_y := randf_range(-1.0, 1.0) * max_offset_y * current_power

	cam.position = _camera_origin + Vector3(offset_x, offset_y, 0.0)


func _finish_shake() -> void:
	_active = false
	_current_intensity = 0.0
	var cam := _get_camera()
	if cam != null:
		cam.position = _camera_origin
	shake_finished.emit()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_camera() -> Camera3D:
	# 1. Grupo "player_camera" (más rápido, el jugador se registra)
	var cam_nodes := get_tree().get_nodes_in_group("player_camera")
	if cam_nodes.size() > 0 and cam_nodes[0] is Camera3D:
		return cam_nodes[0] as Camera3D

	# 2. Buscar por nombre en la escena activa
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("Camera3D", true, false) as Camera3D
