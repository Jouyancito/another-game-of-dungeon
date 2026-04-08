extends Control

## Ventana de personaje — Stats + Skills (placeholder)
## Se abre con C, pausa el juego, muestra cursor.

var player: BasePlayer = null

# Header
@onready var stat_points_label: Label = %StatPointsLabel
@onready var level_label: Label = %LevelLabel
@onready var hp_label: Label = %HpLabel
@onready var mp_label: Label = %MpLabel

# Stat rows — valores base + botones
@onready var str_value: Label = %StrValue
@onready var int_value: Label = %IntValue
@onready var dex_value: Label = %DexValue
@onready var def_value: Label = %DefValue
@onready var vit_value: Label = %VitValue

@onready var str_btn: Button = %StrBtn
@onready var int_btn: Button = %IntBtn
@onready var dex_btn: Button = %DexBtn
@onready var def_btn: Button = %DefBtn
@onready var vit_btn: Button = %VitBtn

# Derived stats
@onready var phys_dmg_label: Label = %PhysDmgValue
@onready var magic_dmg_label: Label = %MagicDmgValue
@onready var dex_dmg_label: Label = %DexDmgValue
@onready var defense_label: Label = %DefenseValue
@onready var move_speed_label: Label = %MoveSpeedValue

# Advanced stats (expandable)
@onready var advanced_toggle: Button = %AdvancedToggle
@onready var advanced_section: VBoxContainer = %AdvancedSection
@onready var res_fire_label: Label = %ResFireValue
@onready var res_ice_label: Label = %ResIceValue
@onready var res_lightning_label: Label = %ResLightningValue
@onready var hp_regen_label: Label = %HpRegenValue
@onready var mp_regen_label: Label = %MpRegenValue

# Equipment bonuses (placeholder)
@onready var equip_section: VBoxContainer = %EquipBonusSection

@onready var stat_desc_label: Label = %StatDescLabel

const STAT_DESC := {
	"str": "Daño físico (+2 por punto)",
	"int": "Daño mágico (+2), MP (+3), regen MP",
	"dex": "Daño a distancia (+2 por punto)",
	"def": "Reduce daño físico recibido",
	"vit": "HP máximo (+5), regen HP",
}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	advanced_section.visible = false

	# Conectar botones de asignar stats
	str_btn.pressed.connect(_assign.bind("str"))
	int_btn.pressed.connect(_assign.bind("int"))
	dex_btn.pressed.connect(_assign.bind("dex"))
	def_btn.pressed.connect(_assign.bind("def"))
	vit_btn.pressed.connect(_assign.bind("vit"))

	# Hover descriptions
	str_btn.mouse_entered.connect(_show_desc.bind("str"))
	int_btn.mouse_entered.connect(_show_desc.bind("int"))
	dex_btn.mouse_entered.connect(_show_desc.bind("dex"))
	def_btn.mouse_entered.connect(_show_desc.bind("def"))
	vit_btn.mouse_entered.connect(_show_desc.bind("vit"))

	# Toggle advanced stats
	advanced_toggle.pressed.connect(_toggle_advanced)

	# Buscar player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as BasePlayer
		player.level_up.connect(_on_level_up)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		_close()
		get_viewport().set_input_as_handled()


func _open() -> void:
	if player == null:
		return
	_refresh_stats()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	stat_desc_label.text = ""


func _assign(stat_name: String) -> void:
	if player == null:
		return
	if player.assign_stat(stat_name):
		_refresh_stats()


func _refresh_stats() -> void:
	if player == null:
		return

	# Header
	level_label.text = "Nivel %d" % player.level
	stat_points_label.text = "Puntos: %d" % player.stat_points
	hp_label.text = "HP: %d/%d" % [int(player.health), int(player.max_health)]
	mp_label.text = "MP: %d/%d" % [int(player.mana), int(player.max_mana)]

	# Base stats
	str_value.text = str(player.str_stat)
	int_value.text = str(player.int_stat)
	dex_value.text = str(player.dex_stat)
	def_value.text = str(player.def_stat)
	vit_value.text = str(player.vit_stat)

	# Derived stats
	phys_dmg_label.text = str(player.str_stat * 2)
	magic_dmg_label.text = str(player.int_stat * 2)
	dex_dmg_label.text = str(player.dex_stat * 2)
	defense_label.text = str(player.def_stat)
	move_speed_label.text = "%.1f" % player.speed

	# Advanced stats
	res_fire_label.text = "%d%%" % int(player.res_fire * 100)
	res_ice_label.text = "%d%%" % int(player.res_ice * 100)
	res_lightning_label.text = "%d%%" % int(player.res_lightning * 100)
	hp_regen_label.text = "%.1f/s" % (0.5 + player.vit_stat * 0.15)
	mp_regen_label.text = "%.1f/s" % (1.0 + player.int_stat * 0.1)

	# Botones
	var has_points = player.stat_points > 0
	str_btn.disabled = not has_points
	int_btn.disabled = not has_points
	dex_btn.disabled = not has_points
	def_btn.disabled = not has_points
	vit_btn.disabled = not has_points


func _toggle_advanced() -> void:
	advanced_section.visible = not advanced_section.visible
	advanced_toggle.text = "▲ Stats Avanzados" if advanced_section.visible else "▼ Stats Avanzados"


func _show_desc(stat_name: String) -> void:
	stat_desc_label.text = STAT_DESC.get(stat_name, "")


func _on_level_up(_new_level: int, _points: int) -> void:
	if visible:
		_refresh_stats()
