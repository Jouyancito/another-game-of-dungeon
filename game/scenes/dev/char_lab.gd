extends Node3D

## Char Lab — banco de pruebas visual de modelos de personaje.
## Muestra los char_*_base.gltf con sus animaciones embebidas para EVALUAR
## identidad visual + animación antes de cablearlos al juego. NO es parte del juego.
##
## Controles:
##   A / D  o  ← / → : cambiar de personaje
##   W / S  o  ↑ / ↓ : cambiar de animación
##   R              : rotación on/off
##   ESC            : salir
##
## Las animaciones que se listan son las EMBEBIDAS en cada gltf. El pack completo
## (Quaternius Ultimate Modular Men / Animations.fbx) se monta como AnimationLibrary
## en un paso posterior si decidimos que estos modelos sirven.

const CHARACTERS := [
	# Quaternius (rig actual del juego, los que viste antes)
	{"name": "Quaternius: Warrior", "path": "res://assets/art/piso1_pradera/characters/char_warrior_base.gltf"},
	{"name": "Quaternius: Mage",    "path": "res://assets/art/piso1_pradera/characters/char_mage_base.gltf"},
	{"name": "Quaternius: Archer",  "path": "res://assets/art/piso1_pradera/characters/char_archer_base.gltf"},
	# KayKit Adventurers (fantasy puro, rig propio con anims Idle/Walk/Run/Attack/Block/Death)
	{"name": "KayKit: Knight (->Warrior)", "path": "res://assets/art/shared/characters/kaykit/Knight.glb"},
	{"name": "KayKit: Mage (->Mage)",      "path": "res://assets/art/shared/characters/kaykit/Mage.glb"},
	{"name": "KayKit: Rogue (->Archer)",   "path": "res://assets/art/shared/characters/kaykit/Rogue.glb"},
	{"name": "KayKit: Rogue Hooded",       "path": "res://assets/art/shared/characters/kaykit/Rogue_Hooded.glb"},
	{"name": "KayKit: Barbarian",          "path": "res://assets/art/shared/characters/kaykit/Barbarian.glb"},
]

var _char_index := 0
var _anim_index := 0
var _anim_names: Array = []
var _current_instance: Node3D = null
var _anim_player: AnimationPlayer = null
var _pivot: Node3D = null
var _auto_rotate := true

var _info_label: Label
var _help_label: Label


func _ready() -> void:
	_build_environment()
	_build_ui()
	_load_character(0)


func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.10, 0.10, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.40, 0.40, 0.45)
	e.ambient_light_energy = 1.0
	env.environment = e
	add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -35, 0)
	key.light_energy = 1.4
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.5
	add_child(fill)

	# Disco de piso para referencia de escala (~1 persona de pie).
	var floor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.2
	cyl.height = 0.05
	floor_mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.22)
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 3.2)
	cam.rotation_degrees = Vector3(-10, 0, 0)
	cam.fov = 45
	add_child(cam)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_info_label = Label.new()
	_info_label.position = Vector2(24, 20)
	_info_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(_info_label)

	_help_label = Label.new()
	_help_label.position = Vector2(24, 56)
	_help_label.add_theme_font_size_override("font_size", 15)
	_help_label.modulate = Color(1, 1, 1, 0.6)
	_help_label.text = "A/D o ←/→: personaje    W/S o ↑/↓: animación    R: rotar    ESC: salir"
	layer.add_child(_help_label)


func _load_character(index: int) -> void:
	if _current_instance and is_instance_valid(_current_instance):
		_current_instance.queue_free()
	_current_instance = null
	_anim_player = null
	_anim_names = []
	_anim_index = 0

	_char_index = wrapi(index, 0, CHARACTERS.size())
	var data: Dictionary = CHARACTERS[_char_index]
	var path: String = data["path"]
	if not ResourceLoader.exists(path):
		_info_label.text = "%s — NO ENCONTRADO: %s" % [data["name"], path]
		return

	var packed: PackedScene = load(path)
	_current_instance = packed.instantiate()
	_pivot.add_child(_current_instance)
	_pivot.rotation = Vector3.ZERO

	_anim_player = _current_instance.find_child("AnimationPlayer", true, false)
	if _anim_player:
		for a in _anim_player.get_animation_list():
			if a != "RESET":
				_anim_names.append(a)
		if not _anim_names.is_empty():
			_play_anim(0)
	_update_info()


func _play_anim(index: int) -> void:
	if _anim_names.is_empty() or _anim_player == null:
		return
	_anim_index = wrapi(index, 0, _anim_names.size())
	var anim_name: String = _anim_names[_anim_index]
	_anim_player.play(anim_name)
	_update_info()


func _update_info() -> void:
	var data: Dictionary = CHARACTERS[_char_index]
	var anim_txt := "sin animaciones embebidas"
	if not _anim_names.is_empty():
		anim_txt = "%s (%d/%d)" % [_anim_names[_anim_index], _anim_index + 1, _anim_names.size()]
	_info_label.text = "%s  [%d/%d]    ·    Anim: %s" % [data["name"], _char_index + 1, CHARACTERS.size(), anim_txt]


func _process(delta: float) -> void:
	if _auto_rotate and _pivot:
		_pivot.rotate_y(0.5 * delta)
	# Re-play para loopear animaciones one-shot (banco de prueba: queremos verlas en bucle).
	if _anim_player and not _anim_player.is_playing() and not _anim_names.is_empty():
		_anim_player.play(_anim_names[_anim_index])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_D, KEY_RIGHT:
				_load_character(_char_index + 1)
			KEY_A, KEY_LEFT:
				_load_character(_char_index - 1)
			KEY_W, KEY_UP:
				_play_anim(_anim_index + 1)
			KEY_S, KEY_DOWN:
				_play_anim(_anim_index - 1)
			KEY_R:
				_auto_rotate = not _auto_rotate
			KEY_ESCAPE:
				get_tree().quit()
