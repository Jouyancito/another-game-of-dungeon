extends Control

## Ventana de personaje — Stats + Skills (placeholder)
## Se abre con C, pausa el juego, muestra cursor.

var player: BasePlayer = null
var char_preview: CharacterPreview

# Identity
@onready var identity_row: HBoxContainer = %IdentityRow
@onready var name_label: Label = %NameLabel
@onready var title_label: Label = %TitleLabel
@onready var class_label: Label = %ClassLabel

# Header
@onready var stat_points_label: Label = %StatPointsLabel
@onready var level_label: Label = %LevelLabel
@onready var hp_label: Label = %HpLabel
@onready var mp_label: Label = %MpLabel
@onready var xp_label: Label = %XpLabel

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
@onready var res_poison_label: Label = %ResPoisonValue
@onready var res_void_label: Label = %ResVoidValue
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

	char_preview = CharacterPreview.new()
	char_preview.custom_minimum_size = Vector2(120, 168)
	var preview_container := identity_row.get_node("PreviewContainer")
	preview_container.add_child(char_preview)

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
		if player.has_signal("equipment_changed"):
			player.equipment_changed.connect(_on_equipment_changed)


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
	# NUNCA pausar el juego — es coop/MMORPG, los demás jugadores siguen jugando.
	# Solo liberamos el mouse para navegar la ventana.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	visible = false
	# Volver a capturar el mouse solo si no hay otras ventanas UI abiertas
	# (el pause menu / inventory / etc pueden seguir visibles)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stat_desc_label.text = ""


func _assign(stat_name: String) -> void:
	if player == null:
		return
	if player.assign_stat(stat_name):
		_refresh_stats()


func _refresh_stats() -> void:
	if player == null:
		return

	# Identity
	var char_data := {}
	var char_idx: int = GameManager.selected_character_index
	if char_idx >= 0:
		char_data = SaveManager.get_character(char_idx)
	name_label.text = char_data.get("name", "Aventurero") if not char_data.is_empty() else "Aventurero"
	var active_title: String = char_data.get("active_title", "") if not char_data.is_empty() else ""
	title_label.text = active_title
	title_label.visible = active_title != ""
	class_label.text = char_data.get("class_name", "") if not char_data.is_empty() else ""

	if char_preview and not char_preview._model:
		char_preview.setup_character(player.get_class_color())

	# Header
	level_label.text = "Nivel %d" % player.level
	stat_points_label.text = "Puntos: %d" % player.stat_points
	hp_label.text = "HP: %d/%d" % [int(player.health), int(player.max_health)]
	mp_label.text = "MP: %d/%d" % [int(player.mana), int(player.max_mana)]
	xp_label.text = "XP: %d/%d (próx nivel)" % [int(player.xp), int(player.xp_to_next_level)]

	# Base stats — muestra total (base + bonus de equipo) con sufijo "+N" si hay gear
	str_value.text = _stat_display(player.str_stat, player.get_effective_stat("str"))
	int_value.text = _stat_display(player.int_stat, player.get_effective_stat("int"))
	dex_value.text = _stat_display(player.dex_stat, player.get_effective_stat("dex"))
	def_value.text = _stat_display(player.def_stat, player.get_effective_stat("def"))
	vit_value.text = _stat_display(player.vit_stat, player.get_effective_stat("vit"))

	# Derived stats — usan effective (refleja gear equipado)
	var eff_str: int = player.get_effective_stat("str")
	var eff_int: int = player.get_effective_stat("int")
	var eff_dex: int = player.get_effective_stat("dex")
	var eff_def: int = player.get_effective_stat("def")
	var eff_vit: int = player.get_effective_stat("vit")
	phys_dmg_label.text = str(eff_str * 2)
	magic_dmg_label.text = str(eff_int * 2)
	dex_dmg_label.text = str(eff_dex * 2)
	defense_label.text = str(eff_def)
	move_speed_label.text = "%.1f" % player.speed

	# Advanced stats — resistencias muestran efectivas (base + items), capeadas 75%
	res_fire_label.text = "%d%%" % int(minf(player.get_effective_resistance("fire"), 0.75) * 100)
	res_ice_label.text = "%d%%" % int(minf(player.get_effective_resistance("ice"), 0.75) * 100)
	res_lightning_label.text = "%d%%" % int(minf(player.get_effective_resistance("lightning"), 0.75) * 100)
	res_poison_label.text = "%d%%" % int(minf(player.get_effective_resistance("poison"), 0.75) * 100)
	res_void_label.text = "%d%%" % int(minf(player.get_effective_resistance("void"), 0.75) * 100)
	hp_regen_label.text = "%.1f/s" % (0.5 + eff_vit * 0.15)
	mp_regen_label.text = "%.1f/s" % (1.0 + eff_int * 0.1)

	# Botones
	var has_points = player.stat_points > 0
	str_btn.disabled = not has_points
	int_btn.disabled = not has_points
	dex_btn.disabled = not has_points
	def_btn.disabled = not has_points
	vit_btn.disabled = not has_points


func _stat_display(base_val: int, effective: int) -> String:
	var bonus: int = effective - base_val
	if bonus == 0:
		return str(base_val)
	var sign_str: String = "+" if bonus > 0 else ""
	return "%d (%s%d)" % [base_val, sign_str, bonus]


func _toggle_advanced() -> void:
	advanced_section.visible = not advanced_section.visible
	advanced_toggle.text = "▲ Stats Avanzados" if advanced_section.visible else "▼ Stats Avanzados"


func _show_desc(stat_name: String) -> void:
	stat_desc_label.text = STAT_DESC.get(stat_name, "")


func _on_level_up(_new_level: int, _points: int) -> void:
	if visible:
		_refresh_stats()


func _on_equipment_changed() -> void:
	# Refresca los stats mostrados cuando se equipa / desequipa algo con la ventana abierta
	if visible:
		_refresh_stats()
