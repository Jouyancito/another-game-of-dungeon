extends SubViewportContainer
class_name CharacterPreview

## Preview 3D de personaje para el char select / class selector / character window.
## Carga el modelo KayKit real según la clase (identidad fantasy). Si la clase no
## tiene modelo asignado o falla la carga, cae al mannequin procedural (WorldModel)
## — retrocompatible con los llamadores que solo pasan color.

## Mapa clase → modelo KayKit. Keys = class_name/display que usan los llamadores.
const CLASS_MODELS: Dictionary = {
	"Guerrero": "res://assets/art/shared/characters/kaykit/Knight.glb",
	"Mago": "res://assets/art/shared/characters/kaykit/Mage.glb",
	"Arquero": "res://assets/art/shared/characters/kaykit/Rogue.glb",
	"Clérigo": "res://assets/art/shared/characters/kaykit/Knight.glb",
	"Nigromante": "res://assets/art/shared/characters/kaykit/Mage.glb",
	"Danzante": "res://assets/art/shared/characters/kaykit/Rogue_Hooded.glb",
	"Danzante de Sombras": "res://assets/art/shared/characters/kaykit/Rogue_Hooded.glb",
}

var _model: Node3D
var _anim_player: AnimationPlayer
var _viewport: SubViewport
var _camera: Camera3D
var _env_light: DirectionalLight3D
var _spin_speed := 0.3
var _auto_spin := true


func _init() -> void:
	# Inicializar en _init (no _ready) para que _viewport exista ANTES de
	# que el caller invoque setup_character() tras CharacterPreview.new() + add_child().
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(200, 280)
	_viewport.transparent_bg = true
	# own_world_3d: cada preview vive en su PROPIO mundo 3D. Sin esto, todos los
	# SubViewport comparten el World3D del padre y los modelos se renderizan
	# superpuestos (y se cuela el mundo del juego de fondo).
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.0, 2.4)
	_camera.fov = 40
	_camera.cull_mask = 1
	_viewport.add_child(_camera)

	_env_light = DirectionalLight3D.new()
	_env_light.rotation = Vector3(deg_to_rad(-40), deg_to_rad(35), 0)
	_env_light.light_energy = 1.3
	_viewport.add_child(_env_light)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-15), deg_to_rad(150), 0)
	fill.light_energy = 0.4
	_viewport.add_child(fill)

	stretch = true
	stretch_shrink = 1


## color: tinte fallback del mannequin procedural. class_key: si mapea a un modelo
## KayKit, se usa ese (con su pose Idle); si no, se usa el mannequin con `color`.
func setup_character(color: Color, class_key: String = "") -> void:
	if _model and is_instance_valid(_model):
		_model.queue_free()
	_model = null
	_anim_player = null

	var model_path: String = CLASS_MODELS.get(class_key, "")
	if model_path != "" and ResourceLoader.exists(model_path):
		_setup_kaykit_model(model_path)
	else:
		_setup_procedural_model(color)


func _setup_kaykit_model(model_path: String) -> void:
	var packed: PackedScene = load(model_path)
	var inst: Node3D = packed.instantiate()
	_viewport.add_child(inst)
	_model = inst
	MannequinBuilder.set_visual_layer_recursive(inst, 1)

	_anim_player = inst.find_child("AnimationPlayer", true, false)
	if _anim_player:
		var idle := _find_idle_anim(_anim_player)
		if idle != "":
			_anim_player.play(idle)

	_frame_model(inst)


func _setup_procedural_model(color: Color) -> void:
	var wm := WorldModel.new()
	_viewport.add_child(wm)
	_model = wm
	wm.setup(color)
	MannequinBuilder.set_visual_layer_recursive(wm, 1)
	_frame_model(wm)


## Auto-encuadre: calcula el AABB del modelo y ubica la cámara para que entre
## de cuerpo entero, sin importar la escala del pack (KayKit vs procedural).
func _frame_model(model: Node3D) -> void:
	var aabb := _model_aabb(model)
	if aabb.size == Vector3.ZERO:
		return
	var height: float = max(aabb.size.y, 0.1)
	var center_y: float = aabb.position.y + height * 0.5
	# Distancia para encuadrar la altura con el fov vertical + margen.
	var dist: float = (height * 0.6) / tan(deg_to_rad(_camera.fov * 0.5)) + height * 0.2
	# Cámara a la altura del centro mirando recto en -Z. No usamos look_at() porque
	# requiere estar en el árbol; al estar a la misma altura, -Z apunta al centro.
	_camera.position = Vector3(0, center_y, dist)
	_camera.rotation = Vector3.ZERO


func _model_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var vi := child as VisualInstance3D
		# Transform local relativo al modelo (NO global_transform: el preview puede
		# no estar aún en el árbol cuando se arma la card de la galería).
		var rel := _local_transform_to(node, vi)
		var box: AABB = rel * vi.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result


func _local_transform_to(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _find_idle_anim(ap: AnimationPlayer) -> String:
	var list := ap.get_animation_list()
	# Preferir una animación cuyo nombre contenga "idle".
	for a in list:
		if a.to_lower().contains("idle"):
			return a
	# Si no hay idle, la primera que no sea RESET.
	for a in list:
		if a != "RESET":
			return a
	return ""


func set_auto_spin(enabled: bool) -> void:
	_auto_spin = enabled


func _process(delta: float) -> void:
	if _model and _auto_spin:
		_model.rotate_y(_spin_speed * delta)
	# Loop de la animación si terminó (algunas no traen loop flag).
	if _anim_player and not _anim_player.is_playing():
		var idle := _find_idle_anim(_anim_player)
		if idle != "":
			_anim_player.play(idle)
