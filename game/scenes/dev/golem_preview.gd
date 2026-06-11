extends Node3D
## Interactive dressed-golem viewer. Open scenes/dev/golem_preview.tscn and press
## F6 (Run Current Scene). Instances the real golem (so it self-dresses at runtime
## with moss + rocks), wakes it (eyes light + stands up), and gives a mouse-orbit
## camera so the assembled creature can be judged from any angle.
##
##   Left-drag = orbit    Mouse wheel = zoom

var _target := Vector3(0.0, 2.2, 0.0)
var _yaw := 0.7
var _pitch := 0.32
var _dist := 11.0
var _cam: Camera3D
var _dragging := false


func _ready() -> void:
	_add_lights()
	_add_environment()
	_add_scale_reference()

	var golem_scene := load("res://scenes/enemy/golem.tscn")
	var golem: Node = golem_scene.instantiate()
	add_child(golem)
	# Freeze gravity/AI so it doesn't fall or wander in this bare viewer.
	if golem is Node:
		golem.set_physics_process(false)
		golem.set_process(false)

	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true

	# Let the runtime dressing settle, then wake it (stand up + light the eyes).
	for _i in range(30):
		await get_tree().process_frame
	if golem.has_method("_awaken"):
		golem.call("_awaken")


func _add_lights() -> void:
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.85)
	key.light_energy = 1.4
	key.rotation_degrees = Vector3(-50, 145, 0)
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.6, 0.7, 0.9)
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-60, -40, 0)
	add_child(fill)


func _add_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _add_scale_reference() -> void:
	# A 1.8m human-height post beside the golem so its ~4m scale reads as imposing.
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 1.8, 0.45)
	post.mesh = box
	post.position = Vector3(2.6, 0.9, 0.0)  # standing on the ground next to the golem
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.30)
	post.material_override = mat
	add_child(post)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			_dragging = e.pressed
		elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(2.0, _dist - 0.4)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(14.0, _dist + 0.4)
	elif e is InputEventMouseMotion and _dragging:
		_yaw -= e.relative.x * 0.01
		_pitch = clampf(_pitch - e.relative.y * 0.01, -1.4, 1.4)


func _process(_delta: float) -> void:
	if _cam == null:
		return
	var off := Vector3(
		cos(_pitch) * sin(_yaw),
		sin(_pitch),
		cos(_pitch) * cos(_yaw)
	) * _dist
	_cam.position = _target + off
	_cam.look_at(_target, Vector3.UP)
