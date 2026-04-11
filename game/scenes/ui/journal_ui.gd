extends CanvasLayer
## UI del Diario del Aventurero. Toggle con J.
## Muestra lista de enemigos descubiertos + detalles del seleccionado.

const ENEMY_SCENES := {
	"slime":         "res://scenes/enemy/slime.tscn",
	"rat":           "res://scenes/enemy/rat.tscn",
	"snake":         "res://scenes/enemy/snake.tscn",
	"fox":           "res://scenes/enemy/fox.tscn",
	"wolf":          "res://scenes/enemy/wolf.tscn",
	"bird":          "res://scenes/enemy/bird.tscn",
	"hawk":          "res://scenes/enemy/hawk.tscn",
	"wasp":          "res://scenes/enemy/wasp.tscn",
	"scorpion":      "res://scenes/enemy/scorpion.tscn",
	"goat":          "res://scenes/enemy/goat.tscn",
	"turtle":        "res://scenes/enemy/turtle.tscn",
	"bandit":        "res://scenes/enemy/bandit_melee.tscn",
	"bandit_archer": "res://scenes/enemy/bandit_archer.tscn",
	"golem":         "res://scenes/enemy/golem.tscn",
}

var _selected_type: String = ""
var _preview_model: Node3D = null

@onready var _bg: ColorRect = $Background
@onready var _title: Label = $Panel/VBoxContainer/Title
@onready var _progress_label: Label = $Panel/VBoxContainer/ProgressLabel
@onready var _entry_list: VBoxContainer = $Panel/VBoxContainer/HSplit/LeftPanel/Scroll/EntryList
@onready var _preview_viewport: SubViewport = $Panel/VBoxContainer/HSplit/RightPanel/PreviewPanel/SubViewportContainer/SubViewport
@onready var _preview_camera: Camera3D = $Panel/VBoxContainer/HSplit/RightPanel/PreviewPanel/SubViewportContainer/SubViewport/Camera3D
@onready var _preview_light: DirectionalLight3D = $Panel/VBoxContainer/HSplit/RightPanel/PreviewPanel/SubViewportContainer/SubViewport/DirLight
@onready var _preview_pivot: Node3D = $Panel/VBoxContainer/HSplit/RightPanel/PreviewPanel/SubViewportContainer/SubViewport/Pivot
@onready var _name_label: Label = $Panel/VBoxContainer/HSplit/RightPanel/InfoPanel/Name
@onready var _category_label: Label = $Panel/VBoxContainer/HSplit/RightPanel/InfoPanel/Category
@onready var _stats_label: RichTextLabel = $Panel/VBoxContainer/HSplit/RightPanel/InfoPanel/Stats
@onready var _description_label: RichTextLabel = $Panel/VBoxContainer/HSplit/RightPanel/InfoPanel/Description
@onready var _flavor_label: RichTextLabel = $Panel/VBoxContainer/HSplit/RightPanel/InfoPanel/Flavor
@onready var _close_btn: Button = $Panel/VBoxContainer/TitleRow/CloseBtn


func _ready() -> void:
	visible = false
	Journal.entry_discovered.connect(_on_entry_updated)
	Journal.entry_updated.connect(_on_entry_level_changed)
	_close_btn.pressed.connect(close)
	_refresh_list()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			close()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_list()


func close() -> void:
	visible = false
	_clear_preview()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_entry_updated(_enemy_type: String) -> void:
	if visible:
		_refresh_list()


func _on_entry_level_changed(_enemy_type: String, _level: int) -> void:
	if visible:
		_refresh_list()
		if _selected_type != "":
			_show_details(_selected_type)


func _refresh_list() -> void:
	# Limpiar lista anterior
	for child in _entry_list.get_children():
		child.queue_free()

	var progress: Vector2i = Journal.get_progress()
	_progress_label.text = "Descubiertos: %d / %d" % [progress.x, progress.y]

	# Mostrar TODOS los tipos del lore (los no descubiertos aparecen como "???")
	var all_types: Array = Journal._lore.keys()
	all_types.sort()

	for enemy_type: String in all_types:
		var level: int = Journal.get_level(enemy_type)
		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)

		if level == 0:
			btn.text = "  ???????"
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
		else:
			var lore: Dictionary = Journal.get_lore(enemy_type)
			var entry_name: String = lore.get("display_name", enemy_type.capitalize()) if level >= 2 else "????"
			var kills: int = Journal.get_kills(enemy_type)
			var stars: String = _level_to_stars(level)
			btn.text = "  %s  %s  (%d kills)" % [stars, entry_name, kills]
			btn.pressed.connect(_on_entry_selected.bind(enemy_type))

		_entry_list.add_child(btn)


func _level_to_stars(level: int) -> String:
	match level:
		1: return "☆☆☆☆"
		2: return "★☆☆☆"
		3: return "★★★☆"
		4: return "★★★★"
		_: return "    "


func _on_entry_selected(enemy_type: String) -> void:
	_selected_type = enemy_type
	_show_details(enemy_type)


func _show_details(enemy_type: String) -> void:
	var level: int = Journal.get_level(enemy_type)
	var lore: Dictionary = Journal.get_lore(enemy_type)
	var kills: int = Journal.get_kills(enemy_type)

	_clear_preview()

	if level == 0:
		_name_label.text = "???"
		_category_label.text = ""
		_stats_label.text = ""
		_description_label.text = ""
		_flavor_label.text = ""
		return

	# Cargar preview 3D del enemigo
	_spawn_preview(enemy_type, level)

	# Nivel 1: silueta borrosa, solo el nombre oculto
	if level == 1:
		_name_label.text = "?????"
		_category_label.text = lore.get("category", "")
		_stats_label.text = "[i][color=#888]Derrotá al menos uno para aprender más sobre esta criatura.[/color][/i]"
		_description_label.text = ""
		_flavor_label.text = ""
		return

	# Nivel 2+: información básica
	_name_label.text = lore.get("display_name", enemy_type.capitalize())
	_category_label.text = lore.get("category", "")

	var stats_text: String = "[b]Kills:[/b] %d\n" % kills
	# Intentar instanciar para leer stats reales
	if ENEMY_SCENES.has(enemy_type):
		var scene: PackedScene = load(ENEMY_SCENES[enemy_type])
		if scene:
			var tmp: CharacterBody3D = scene.instantiate()
			stats_text += "[b]HP:[/b] %d\n" % int(tmp.get("health"))
			stats_text += "[b]Daño:[/b] %d\n" % int(tmp.get("damage"))
			stats_text += "[b]XP:[/b] %d\n" % int(tmp.get("xp_reward"))
			tmp.queue_free()

	_stats_label.text = stats_text
	_description_label.text = lore.get("description", "")

	# Nivel 3+: hábitat y debilidad
	if level >= 3:
		_description_label.text += "\n\n[b]Hábitat:[/b] %s" % lore.get("habitat", "-")
		_description_label.text += "\n[b]Debilidad:[/b] %s" % lore.get("weakness", "-")

	# Nivel 4: flavor text
	if level >= 4:
		_flavor_label.text = "[i]%s[/i]" % lore.get("flavor", "")
	else:
		_flavor_label.text = ""


func _spawn_preview(enemy_type: String, level: int) -> void:
	if not ENEMY_SCENES.has(enemy_type):
		return
	var scene: PackedScene = load(ENEMY_SCENES[enemy_type])
	if scene == null:
		return
	var instance: CharacterBody3D = scene.instantiate()
	# Marcar como preview para que BaseEnemy no setee nameplate ni IA
	instance.set_meta("is_preview", true)
	_preview_pivot.add_child(instance)
	# Después del _ready de BaseEnemy, desactivar físicas
	await get_tree().process_frame
	if not is_instance_valid(instance):
		return
	instance.set_physics_process(false)
	instance.set_process(false)
	_preview_model = instance

	# Si está en nivel 1 (silueta), hacer el modelo negro
	if level == 1:
		_apply_silhouette(instance)


func _apply_silhouette(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.05, 0.05, 0.05)
		mat.roughness = 1.0
		mi.material_override = mat
	for child in node.get_children():
		_apply_silhouette(child)


func _clear_preview() -> void:
	# Limpiar TODOS los hijos del pivot (por si quedaron previews anteriores)
	for child in _preview_pivot.get_children():
		child.queue_free()
	_preview_model = null
	_preview_pivot.rotation = Vector3.ZERO


func _process(delta: float) -> void:
	if visible and _preview_pivot:
		_preview_pivot.rotate_y(delta * 0.8)
