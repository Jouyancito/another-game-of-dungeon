extends SubViewportContainer
class_name CharacterPreview

var _model: WorldModel
var _viewport: SubViewport
var _camera: Camera3D
var _env_light: DirectionalLight3D
var _spin_speed := 0.3
var _auto_spin := true


func _init() -> void:
	# Inicializar en _init (no _ready) para que _viewport exista ANTES de
	# que el caller invoque setup_character() tras CharacterPreview.new() + add_child().
	# _ready() corre diferido — no sirve acá.
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(200, 280)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 0.3, 1.2)
	_camera.rotation.x = deg_to_rad(-5)
	_camera.fov = 40
	_camera.cull_mask = 1
	_viewport.add_child(_camera)

	_env_light = DirectionalLight3D.new()
	_env_light.rotation = Vector3(deg_to_rad(-45), deg_to_rad(30), 0)
	_env_light.light_energy = 1.2
	_viewport.add_child(_env_light)

	stretch = true
	stretch_shrink = 1


func setup_character(color: Color) -> void:
	if _model:
		_model.queue_free()
	_model = WorldModel.new()
	_viewport.add_child(_model)
	_model.setup(color)
	MannequinBuilder.set_visual_layer_recursive(_model, 1)


func set_auto_spin(enabled: bool) -> void:
	_auto_spin = enabled


func _process(delta: float) -> void:
	if _model and _auto_spin:
		_model.rotate_y(_spin_speed * delta)
