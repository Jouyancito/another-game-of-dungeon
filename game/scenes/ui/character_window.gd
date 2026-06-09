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

# Tabs — Habilidades / Profesiones
@onready var skill_list: VBoxContainer = %SkillListContainer
@onready var skill_list_empty: Label = %SkillsEmpty
@onready var profesiones_list: VBoxContainer = %ProfesionesList
@onready var respec_btn: Button = %RespecButton

# Profesiones placeholder (canon professions_spec.md Fase 0 — sin lógica de subida).
# Lista de tuplas: [id, display_name, descripción tooltip].
const PROFESIONES_PLACEHOLDER: Array = [
	["mineria",    "Minería",     "Romper vetas en cuevas. Sube con uso."],
	["pesca",      "Pesca",       "Pescar en ríos y lagos. Sube con uso."],
	["caza",       "Caza",        "Trampas + skinning. Sube con uso."],
	["percepcion", "Percepción",  "Detectar trampas, secretos. Sube pasivo."],
	["linguistica","Lingüística", "Leer textos antiguos, runas."],
	["observacion","Observación", "Aprender comportamiento mob (Saber)."],
]

# Class scene path → class_id (SkillResource.class_id canon).
const CLASS_ID_BY_SCRIPT := {
	"player.gd": &"warrior",
	"mage.gd": &"mage",
	"archer.gd": &"archer",
	"cleric.gd": &"cleric",
	"necromancer.gd": &"necromancer",
	"danzante.gd": &"danzante",
}

# Nombre UI del recurso primario (match SkillResource.ResourceCostType enum).
const RESOURCE_LABEL := {
	0: "",
	1: "Rage",
	2: "Fe",
	3: "MP",
	4: "Combo",
	5: "Concentración",
	6: "HP",
}

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

	# Hide the Profesiones tab from the tab bar — paused scope, see post-alpha-specs/.
	# Stats=0, Habilidades=1, Profesiones=2.
	var tabs: TabContainer = get_node_or_null("Panel/Margin/VBox/Tabs")
	if tabs != null:
		var profesiones_idx: int = -1
		for i in range(tabs.get_tab_count()):
			if tabs.get_tab_title(i) == "Profesiones":
				profesiones_idx = i
				break
		if profesiones_idx >= 0:
			tabs.set_tab_hidden(profesiones_idx, true)

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

	# Respec button — stub hasta item consumible implementado.
	respec_btn.pressed.connect(_on_respec_pressed)

	# Profesiones placeholder — build una sola vez (sin lógica de subida todavía).
	_build_profesiones_placeholder()

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
	_populate_skills()
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
		char_preview.setup_character(player.get_class_color(), char_data.get("class_name", ""))

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


# ── Habilidades tab ─────────────────────────────────────────────────────────

func _class_id() -> StringName:
	# Deriva class_id canon desde el script del player (base_player.gd no expone class_id).
	if player == null or player.get_script() == null:
		return &""
	var file: String = (player.get_script() as Script).resource_path.get_file()
	return CLASS_ID_BY_SCRIPT.get(file, &"")


func _populate_skills() -> void:
	# Limpia entries anteriores
	for child in skill_list.get_children():
		child.queue_free()

	var db = get_tree().get_root().get_node_or_null("SkillDB")
	var class_key: StringName = _class_id()
	var skills: Array = []
	if db != null and class_key != &"" and db.has_method("all_skills_for_class"):
		skills = db.all_skills_for_class(class_key)

	if skills.is_empty():
		skill_list_empty.visible = true
		return
	skill_list_empty.visible = false

	# Ordenar por unlock_level asc para que el flujo de desbloqueo sea legible.
	skills.sort_custom(func(a, b): return a.unlock_level < b.unlock_level)

	for s in skills:
		skill_list.add_child(_create_skill_entry(s))


func _create_skill_entry(skill: SkillResource) -> PanelContainer:
	var entry := PanelContainer.new()
	entry.custom_minimum_size = Vector2(0, 88)
	entry.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.17, 1.0)
	style.border_color = Color(0.30, 0.30, 0.35, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	entry.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	entry.add_child(hbox)

	# Ícono 64x64 — placeholder gris si skill.icon == null
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # drag pasa al entry
	if skill.icon != null:
		icon.texture = skill.icon
	else:
		# Placeholder gris para skills sin ícono wired (por ej. Archer/Cleric/Necro pre-B).
		var ph := PlaceholderTexture2D.new()
		ph.size = Vector2(64, 64)
		icon.texture = ph
		icon.modulate = Color(0.35, 0.35, 0.40, 1.0)
	hbox.add_child(icon)

	# Info column
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	hbox.add_child(info)

	# Row 1: nombre + nivel/max
	var top_row := HBoxContainer.new()
	info.add_child(top_row)

	var name_lbl := Label.new()
	name_lbl.text = skill.display_name if skill.display_name != "" else String(skill.id)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	top_row.add_child(name_lbl)

	var level_lbl := Label.new()
	# Fase 1: per-skill level tracking aún no implementado en PlayerSkills.
	# Placeholder muestra "1/max" — cuando B agregue tracking, se lee desde ahí.
	level_lbl.text = "1/%d" % skill.max_skill_level
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.2, 1.0))
	top_row.add_child(level_lbl)

	# Row 2: descripción 2 líneas
	var desc_lbl := Label.new()
	desc_lbl.text = skill.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	desc_lbl.custom_minimum_size = Vector2(0, 28)
	info.add_child(desc_lbl)

	# Row 3: costo + daño + unlock
	var stat_lbl := Label.new()
	stat_lbl.text = _format_skill_stats(skill)
	stat_lbl.add_theme_font_size_override("font_size", 11)
	stat_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 0.90, 1.0))
	info.add_child(stat_lbl)

	# Drag source — hotbar_slot acepta type="skill_tree" (ver hotbar_slot.gd:174).
	entry.set_drag_forwarding(
		_skill_entry_get_drag.bind(skill),
		func(_p, _d): return false,
		func(_p, _d): pass,
	)

	return entry


func _format_skill_stats(skill: SkillResource) -> String:
	var parts: PackedStringArray = []
	if skill.resource_cost > 0:
		var rname: String = RESOURCE_LABEL.get(skill.resource_type, "")
		parts.append("%d %s" % [skill.resource_cost, rname])
	if skill.cooldown_s > 0.0:
		parts.append("CD %.1fs" % skill.cooldown_s)
	if skill.base_damage > 0 and skill.damage_formula != SkillResource.DamageFormulaType.NONE:
		var dtype: String = "phys"
		match skill.damage_formula:
			SkillResource.DamageFormulaType.MAGIC_V2: dtype = "mag"
			SkillResource.DamageFormulaType.HEAL: dtype = "heal"
			SkillResource.DamageFormulaType.TRUE_DAMAGE: dtype = "true"
		parts.append("Daño %d %s" % [skill.base_damage, dtype])
	parts.append("Lvl %d" % skill.unlock_level)
	return "  ·  ".join(parts)


func _skill_entry_get_drag(_at_position: Vector2, skill: SkillResource) -> Variant:
	if skill == null:
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(48, 48)
	if skill.icon != null:
		preview.texture = skill.icon
	preview.modulate = Color(1, 1, 1, 0.85)
	# set_drag_preview es método de Control; lo llamamos vía un Control local
	# (el entry está en escena, así que usamos el viewport para host del preview).
	# Patrón canon Godot: dentro de un callable wrapper esto solo devuelve la data.
	# El preview lo creará Godot a partir de esta Variant si devolvemos la ref directa — pero
	# preview se adjunta con set_drag_preview, que solo funciona dentro de _get_drag_data nativo.
	# Como usamos drag_forwarding, necesitamos llamar set_drag_preview desde un Control válido.
	# Workaround: buscar el entry en el árbol y usarlo.
	_attach_drag_preview(preview)
	return {
		"type": "skill_tree",
		"skill": skill,
	}


func _attach_drag_preview(preview: Control) -> void:
	# skill_list es un Control en el árbol — sirve como host válido para set_drag_preview.
	if skill_list != null:
		skill_list.set_drag_preview(preview)


# ── Profesiones tab (canon professions_spec.md Fase 0) ──────────────────────

func _build_profesiones_placeholder() -> void:
	# 6 rows: nombre + barra placeholder + Lvl 0/100. Tooltip al hover.
	# Sin lógica de subida — Fase 1 wirea hooks a actividades del mundo.
	for child in profesiones_list.get_children():
		child.queue_free()
	for entry in PROFESIONES_PLACEHOLDER:
		profesiones_list.add_child(_create_profesion_row(entry[0], entry[1], entry[2]))


func _create_profesion_row(_prof_id: String, prof_name: String, tooltip: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.tooltip_text = tooltip
	row.custom_minimum_size = Vector2(0, 42)
	row.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.16, 1.0)
	style.border_color = Color(0.28, 0.28, 0.32, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Nombre profesión (ancho fijo)
	var name_lbl := Label.new()
	name_lbl.text = prof_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.custom_minimum_size = Vector2(110, 0)
	hbox.add_child(name_lbl)

	# Lvl label
	var level_lbl := Label.new()
	level_lbl.text = "Lv 0"
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	level_lbl.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(level_lbl)

	# Barra de progreso
	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	hbox.add_child(bar)

	# XP label
	var xp_lbl := Label.new()
	xp_lbl.text = "0 / 100"
	xp_lbl.add_theme_font_size_override("font_size", 11)
	xp_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6, 1.0))
	xp_lbl.custom_minimum_size = Vector2(60, 0)
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(xp_lbl)

	return row


# ── Respec button stub ──────────────────────────────────────────────────────

func _on_respec_pressed() -> void:
	# Stub — se habilita cuando el ítem consumible "Piedra de Redistribución" exista.
	# Por ahora la UI lo muestra disabled; este handler queda listo para la integración.
	stat_desc_label.text = "Necesitás una Piedra de Redistribución para resetear stats."
