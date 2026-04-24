extends CanvasLayer

@onready var health_bar: ProgressBar = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/HealthBar
@onready var health_label: Label = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/HealthBar/HealthLabel
@onready var mana_bar: ProgressBar = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/ManaBar
@onready var mana_label: Label = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/ManaBar/ManaLabel
@onready var hotbar_slots: HBoxContainer = $HUDContainer/HotbarPanel/HotbarMargin/HotbarSlots
@onready var crosshair: Control = $Crosshair
@onready var xp_bar: ProgressBar = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/XpBar
@onready var xp_label: Label = $HUDContainer/BarsPanel/BarsMargin/BarsVBox/XpBar/XpLabel
@onready var death_screen: ColorRect = $DeathScreen
@onready var death_label: Label = $DeathScreen/DeathLabel
@onready var stat_indicator: Control = $HUDContainer/StatIndicator
@onready var level_up_label: Label = $LevelUpNotification

var _player: Node = null  # Referencia al jugador vinculado a este HUD

# Hint de interacción — "Presioná [E] para recoger" / "para abrir" / etc.
var _pickup_hint_panel: PanelContainer
var _pickup_hint_label: Label

# Target frame — panel estilo MMO para el enemigo apuntado con el crosshair
var _target_panel: PanelContainer
var _target_name_label: Label
var _target_tier_label: Label
var _target_hp_bar: ProgressBar
var _target_hp_label: Label
var _current_target: Node = null  # referencia al BaseEnemy apuntado
var _target_hide_timer := 0.0     # se oculta 1.5s después de dejar de apuntar

# Last breath — barra visible durante downed, countdown hasta muerte real
var _last_breath_panel: PanelContainer
var _last_breath_bar: ProgressBar
var _last_breath_label: Label

# Torch slot — panel visible al lado del hotbar con antorcha equipada + estado
var _torch_slot_panel: PanelContainer
var _torch_slot_icon: TextureRect
var _torch_slot_placeholder: Label
var _torch_slot_status: Label
var _torch_slot_hint: Label

func _ready() -> void:
	add_to_group("hud")
	death_screen.visible = false
	stat_indicator.visible = false
	level_up_label.visible = false
	# Font del death_label más chico y claro (antes 48 desde tscn).
	death_label.add_theme_font_size_override("font_size", 22)
	_build_pickup_hint()
	_build_target_frame()
	_wire_hotbar_slots()
	_build_last_breath_bar()
	_build_torch_slot()
	set_process(true)


# ── Hotbar drag&drop ─────────────────────────────────────────────────────────
# Cada slot tiene HotbarSlot script (hud.tscn). Conectamos sus señales al PlayerSkills.
func _wire_hotbar_slots() -> void:
	for child in hotbar_slots.get_children():
		if child is HotbarSlot:
			if not child.skill_dropped.is_connected(_on_slot_skill_dropped):
				child.skill_dropped.connect(_on_slot_skill_dropped)
			if not child.slot_swap_requested.is_connected(_on_slot_swap_requested):
				child.slot_swap_requested.connect(_on_slot_swap_requested)


func _on_slot_skill_dropped(slot_index: int, skill_res: SkillResource) -> void:
	if _player == null or _player.skills == null:
		return
	_player.skills.set_slot(slot_index, skill_res)


func _on_slot_swap_requested(from_index: int, to_index: int) -> void:
	if _player == null or _player.skills == null:
		return
	_player.skills.swap_slots(from_index, to_index)


func _refresh_hotbar_visuals() -> void:
	if _player == null or _player.skills == null:
		return
	for child in hotbar_slots.get_children():
		if child is HotbarSlot:
			var idx: int = child.slot_index
			if idx >= 0 and idx < _player.skills.hotbar.size():
				child.set_skill(_player.skills.hotbar[idx])


func _build_pickup_hint() -> void:
	# Cuadradito discreto debajo del crosshair, creado por código para
	# evitar que Godot sobrescriba el .tscn si la escena está abierta.
	_pickup_hint_panel = PanelContainer.new()
	_pickup_hint_panel.name = "PickupHint"
	_pickup_hint_panel.anchor_left = 0.5
	_pickup_hint_panel.anchor_right = 0.5
	_pickup_hint_panel.anchor_top = 0.5
	_pickup_hint_panel.anchor_bottom = 0.5
	_pickup_hint_panel.offset_left = -110
	_pickup_hint_panel.offset_right = 110
	_pickup_hint_panel.offset_top = 40   # ~40px debajo del crosshair
	_pickup_hint_panel.offset_bottom = 70
	_pickup_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_hint_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.65)
	style.border_color = Color(0.95, 0.85, 0.3, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_pickup_hint_panel.add_theme_stylebox_override("panel", style)

	_pickup_hint_label = Label.new()
	_pickup_hint_label.text = "Presioná [E] para recoger"
	_pickup_hint_label.add_theme_font_size_override("font_size", 13)
	_pickup_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pickup_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pickup_hint_panel.add_child(_pickup_hint_label)

	$HUDContainer.add_child(_pickup_hint_panel)


## API pública — llamada desde base_player cada frame con la disponibilidad actual.
func set_pickup_hint_visible(available: bool, text: String = "") -> void:
	if _pickup_hint_panel == null:
		return
	if available and text != "":
		_pickup_hint_label.text = text
	_pickup_hint_panel.visible = available


# ---------------------------------------------------------------------------
# Target Frame — panel estilo MMO (Metin 2 / WoW) arriba-centro
# ---------------------------------------------------------------------------
func _build_target_frame() -> void:
	_target_panel = PanelContainer.new()
	_target_panel.name = "TargetFrame"
	_target_panel.anchor_left = 0.5
	_target_panel.anchor_right = 0.5
	_target_panel.anchor_top = 0.0
	_target_panel.anchor_bottom = 0.0
	_target_panel.offset_left = -160
	_target_panel.offset_right = 160
	_target_panel.offset_top = 16
	_target_panel.offset_bottom = 90
	_target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	style.border_color = Color(0.6, 0.3, 0.3, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_target_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_panel.add_child(vbox)

	# Fila 1: Nombre + Tier badge
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	_target_name_label = Label.new()
	_target_name_label.add_theme_font_size_override("font_size", 15)
	_target_name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_target_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_target_name_label)

	_target_tier_label = Label.new()
	_target_tier_label.add_theme_font_size_override("font_size", 12)
	_target_tier_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	_target_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_target_tier_label)

	# Fila 2: HP bar con label
	var hp_container := Control.new()
	hp_container.custom_minimum_size = Vector2(0, 20)
	hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hp_container)

	_target_hp_bar = ProgressBar.new()
	_target_hp_bar.layout_mode = 1
	_target_hp_bar.anchor_right = 1.0
	_target_hp_bar.anchor_bottom = 1.0
	_target_hp_bar.show_percentage = false
	_target_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.05, 0.05, 0.8)
	hp_bg.corner_radius_top_left = 3
	hp_bg.corner_radius_top_right = 3
	hp_bg.corner_radius_bottom_left = 3
	hp_bg.corner_radius_bottom_right = 3
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.8, 0.15, 0.15, 1)
	hp_fill.corner_radius_top_left = 3
	hp_fill.corner_radius_top_right = 3
	hp_fill.corner_radius_bottom_left = 3
	hp_fill.corner_radius_bottom_right = 3
	_target_hp_bar.add_theme_stylebox_override("background", hp_bg)
	_target_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_container.add_child(_target_hp_bar)

	_target_hp_label = Label.new()
	_target_hp_label.layout_mode = 1
	_target_hp_label.anchor_right = 1.0
	_target_hp_label.anchor_bottom = 1.0
	_target_hp_label.add_theme_font_size_override("font_size", 11)
	_target_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_target_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_target_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(_target_hp_label)

	$HUDContainer.add_child(_target_panel)


func _process(delta: float) -> void:
	# Update tick para last-breath bar (durante downed) y estado del torch slot.
	_update_last_breath_and_torch()

	# Actualizar HP bar en vivo si hay un target
	if _current_target != null:
		if not is_instance_valid(_current_target) or _current_target.is_dead:
			clear_target()
			return
		_target_hp_bar.value = _current_target.health
		_target_hp_label.text = "%d/%d" % [int(_current_target.health), int(_current_target._max_health)]

		# Color dinámico de la HP bar según porcentaje
		var hp_ratio: float = _current_target.health / _current_target._max_health if _current_target._max_health > 0 else 0.0
		var fill_style: StyleBoxFlat = _target_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if hp_ratio > 0.5:
				fill_style.bg_color = Color(0.2, 0.8, 0.2, 1)  # verde
			elif hp_ratio > 0.25:
				fill_style.bg_color = Color(0.9, 0.8, 0.1, 1)  # amarillo
			else:
				fill_style.bg_color = Color(0.8, 0.15, 0.15, 1)  # rojo

	# Timer de ocultamiento suave (1.5s después de dejar de apuntar)
	if _target_panel.visible and _current_target == null:
		_target_hide_timer -= delta
		if _target_hide_timer <= 0:
			_target_panel.visible = false


## Llamado desde base_player cuando el crosshair raycast detecta un enemigo.
func set_target(enemy: Node) -> void:
	if _target_panel == null:
		return
	_current_target = enemy
	_target_hide_timer = 1.5

	_target_name_label.text = "%s  Lv.%d" % [enemy.get_display_name(), enemy.enemy_level]
	_target_tier_label.text = enemy.get_tier_label()
	_target_hp_bar.max_value = enemy._max_health
	_target_hp_bar.value = enemy.health
	_target_hp_label.text = "%d/%d" % [int(enemy.health), int(enemy._max_health)]
	_target_panel.visible = true

	# Border color según sub-tier
	var panel_style: StyleBoxFlat = _target_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style:
		match enemy.sub_tier:
			BaseEnemy.SubTier.A:
				panel_style.border_color = Color(0.5, 0.5, 0.5, 0.9)    # gris
			BaseEnemy.SubTier.B:
				panel_style.border_color = Color(0.3, 0.5, 0.8, 0.9)    # azul
			BaseEnemy.SubTier.C:
				panel_style.border_color = Color(0.8, 0.6, 0.1, 0.9)    # amarillo
			BaseEnemy.SubTier.BOSS:
				panel_style.border_color = Color(0.8, 0.15, 0.15, 0.9)  # rojo


## Llamado cuando el crosshair deja de apuntar a un enemigo.
func clear_target() -> void:
	_current_target = null
	# No ocultar inmediatamente — dejar el timer de 1.5s


## Llamar desde main.gd después de instanciar al jugador.
## Esto evita depender del timing de group search en _ready().
func connect_to_player(player: Node) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.player_died.connect(_on_player_died)
	if player.has_signal("player_downed"):
		player.player_downed.connect(_on_player_downed)
	if player.has_signal("player_revived"):
		player.player_revived.connect(_on_player_revived)
	player.level_up.connect(_on_level_up)
	_on_health_changed(player.health, player.max_health)
	_on_mana_changed(player.mana, player.max_mana)
	_on_xp_changed(player.xp, player.xp_to_next_level, player.level)
	if player.stat_points > 0:
		stat_indicator.visible = true
	# Sincronizar hotbar visuals y escuchar cambios futuros (drag&drop o _equip_default_skills).
	if player.skills != null:
		if not player.skills.hotbar_changed.is_connected(_refresh_hotbar_visuals):
			player.skills.hotbar_changed.connect(_refresh_hotbar_visuals)
		if not player.skills.cooldown_tick.is_connected(_on_cooldown_tick):
			player.skills.cooldown_tick.connect(_on_cooldown_tick)
		_refresh_hotbar_visuals()


func _on_health_changed(new_value: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = new_value
	health_label.text = "%d/%d" % [new_value, max_value]


func _on_mana_changed(new_value: float, max_value: float) -> void:
	mana_bar.max_value = max_value
	mana_bar.value = new_value
	mana_label.text = "%d/%d" % [new_value, max_value]


func _on_xp_changed(current_xp: float, max_xp: float, current_level: int) -> void:
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp
	xp_label.text = "Nv.%d  %d/%d" % [current_level, current_xp, max_xp]

	# Verificar si quedan stat points usando el jugador vinculado
	if _player != null:
		stat_indicator.visible = _player.stat_points > 0


func _on_level_up(new_level: int, _points: int) -> void:
	stat_indicator.visible = true
	_show_level_up_notification(new_level)


func _show_level_up_notification(new_level: int) -> void:
	level_up_label.text = "¡NIVEL %d!" % new_level
	level_up_label.visible = true
	level_up_label.modulate = Color(1, 0.85, 0.1, 1)
	level_up_label.scale = Vector2(0.5, 0.5)
	level_up_label.pivot_offset = level_up_label.size / 2

	var tween = create_tween()
	# Aparece con scale up
	tween.tween_property(level_up_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(level_up_label, "scale", Vector2(1.0, 1.0), 0.15)
	# Se mantiene 1.5s
	tween.tween_interval(1.5)
	# Fade out hacia arriba
	tween.tween_property(level_up_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): level_up_label.visible = false)


## Recibe ticks de cooldown desde PlayerSkills y actualiza el overlay del slot.
func _on_cooldown_tick(skill_id: StringName, remaining_s: float, total_s: float) -> void:
	for child in hotbar_slots.get_children():
		if child is HotbarSlot:
			if child.skill != null and child.skill.id == skill_id:
				child.set_cooldown(remaining_s, total_s)
				return


func _on_player_died() -> void:
	crosshair.visible = false
	death_screen.visible = true
	stat_indicator.visible = false
	# Transición inmediata — sin tween — para que el user vea el cambio claro.
	# El tween previo era invisible si venía de _on_player_downed (ya era rojizo).
	death_screen.color = Color(0, 0, 0, 0.85)
	death_label.text = "HAS CAÍDO\n\n[R] para volver al punto de partida"


func _on_player_downed(_player_ref: BasePlayer) -> void:
	# Canon MVP #5 — player caído, aliados pueden revivir. En singleplayer
	# sin aliados, el downed_time_s tickea y termina en player_died. Mientras,
	# permitimos R para respawn temprano — el user no está forzado a esperar.
	death_screen.visible = true
	death_label.text = "ESTÁS CAÍDO\n\nEsperá a un aliado\no [R] para rendirte"
	var tween = create_tween()
	tween.tween_property(death_screen, "color", Color(0.3, 0, 0, 0.5), 0.4)


func _on_player_revived(_player_ref: BasePlayer, _healer: Node) -> void:
	# Revive cancela el fade — limpiar UI.
	death_screen.visible = false
	death_screen.color = Color(0, 0, 0, 0)
	death_label.text = ""
	crosshair.visible = true


func _unhandled_input(event: InputEvent) -> void:
	# Respawn temprano — R durante downed o dead recarga la escena actual.
	# Canon futuro: revive ritual en ciudad/gremio reemplazará este flow.
	if not death_screen.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()


# ──────────────────────────────────────────────────────────────────────
# Last Breath — barra de countdown visible durante downed
# ──────────────────────────────────────────────────────────────────────

func _build_last_breath_bar() -> void:
	# Barra grande arriba centrada (pedido user 2026-04-23 round 2).
	_last_breath_panel = PanelContainer.new()
	_last_breath_panel.anchor_left = 0.5
	_last_breath_panel.anchor_right = 0.5
	_last_breath_panel.anchor_top = 0.0
	_last_breath_panel.anchor_bottom = 0.0
	_last_breath_panel.offset_left = -180.0
	_last_breath_panel.offset_right = 180.0
	_last_breath_panel.offset_top = 80.0
	_last_breath_panel.offset_bottom = 140.0
	_last_breath_panel.visible = false
	_last_breath_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	_last_breath_panel.add_child(vbox)

	_last_breath_label = Label.new()
	_last_breath_label.text = "ÚLTIMO ALIENTO"
	_last_breath_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_last_breath_label.add_theme_font_size_override("font_size", 14)
	_last_breath_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	vbox.add_child(_last_breath_label)

	_last_breath_bar = ProgressBar.new()
	_last_breath_bar.custom_minimum_size = Vector2(320, 22)
	_last_breath_bar.show_percentage = false
	_last_breath_bar.max_value = 1.0
	_last_breath_bar.value = 1.0
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.0, 0.0, 0.85)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.15, 0.15, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	_last_breath_bar.add_theme_stylebox_override("background", bg_style)
	_last_breath_bar.add_theme_stylebox_override("fill", fill_style)
	vbox.add_child(_last_breath_bar)

	add_child(_last_breath_panel)


# ──────────────────────────────────────────────────────────────────────
# Torch slot — icono al lado del hotbar con antorcha equipada + estado
# ──────────────────────────────────────────────────────────────────────

func _build_torch_slot() -> void:
	_torch_slot_panel = PanelContainer.new()
	_torch_slot_panel.custom_minimum_size = Vector2(50, 50)
	_torch_slot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_torch_slot_panel.tooltip_text = "Antorcha — [F] encender/apagar, click derecho para desequipar"

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_color = Color(0.3, 0.25, 0.15, 1.0)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	_torch_slot_panel.add_theme_stylebox_override("panel", bg_style)

	_torch_slot_icon = TextureRect.new()
	_torch_slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_torch_slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_torch_slot_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_torch_slot_panel.add_child(_torch_slot_icon)

	# Placeholder cuando no hay antorcha equipada (texto "F").
	_torch_slot_placeholder = Label.new()
	_torch_slot_placeholder.text = "F"
	_torch_slot_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_torch_slot_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_torch_slot_placeholder.add_theme_font_size_override("font_size", 22)
	_torch_slot_placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	_torch_slot_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_torch_slot_placeholder.anchor_right = 1.0
	_torch_slot_placeholder.anchor_bottom = 1.0
	_torch_slot_panel.add_child(_torch_slot_placeholder)

	# Indicador pequeño de estado on/off (esquina superior-derecha).
	_torch_slot_status = Label.new()
	_torch_slot_status.text = ""
	_torch_slot_status.add_theme_font_size_override("font_size", 10)
	_torch_slot_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_torch_slot_status.anchor_left = 1.0
	_torch_slot_status.anchor_right = 1.0
	_torch_slot_status.offset_left = -24.0
	_torch_slot_status.offset_top = 2.0
	_torch_slot_status.offset_right = -2.0
	_torch_slot_status.offset_bottom = 14.0
	_torch_slot_panel.add_child(_torch_slot_status)

	# Hint permanente abajo del slot — dice cómo desequipar. Solo visible
	# cuando hay torch equipada (sino no hay qué quitar, es ruido visual).
	_torch_slot_hint = Label.new()
	_torch_slot_hint.text = "RMB=quitar"
	_torch_slot_hint.add_theme_font_size_override("font_size", 7)
	_torch_slot_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.9))
	_torch_slot_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_torch_slot_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_torch_slot_hint.anchor_left = 0.0
	_torch_slot_hint.anchor_right = 1.0
	_torch_slot_hint.anchor_top = 1.0
	_torch_slot_hint.anchor_bottom = 1.0
	_torch_slot_hint.offset_top = -10.0
	_torch_slot_hint.visible = false
	_torch_slot_panel.add_child(_torch_slot_hint)

	_torch_slot_panel.gui_input.connect(_on_torch_slot_gui_input)
	hotbar_slots.add_child(_torch_slot_panel)


func _on_torch_slot_gui_input(event: InputEvent) -> void:
	if _player == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Click izq = toggle encender/apagar — equivalente a F.
			if _player.has_method("toggle_torch"):
				_player.toggle_torch()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Click der = desequipar off_hand (donde vive la antorcha ahora).
			if _player.has_method("unequip_slot"):
				_player.unequip_slot("off_hand")


func _update_last_breath_and_torch() -> void:
	if _player == null or not is_instance_valid(_player):
		return

	# Fallback defensivo: si el signal player_died no llegó al HUD por lo que
	# sea (orden de init, reload a medias, error silencioso en _actual_die),
	# este tick detecta is_dead y fuerza la transición a death_screen.
	var dead: bool = _player.get("is_dead") == true
	if dead and not death_screen.visible:
		_on_player_died()

	# Last breath bar — visible solo durante is_downed.
	var downed: bool = _player.get("is_downed") == true
	if downed:
		var time_left: float = float(_player.get("_downed_time_left"))
		var total: float = float(_player.get("downed_time_s"))
		if total > 0.0:
			_last_breath_bar.value = clampf(time_left / total, 0.0, 1.0)
		_last_breath_label.text = "ÚLTIMO ALIENTO  %0.1fs" % maxf(time_left, 0.0)
		_last_breath_panel.visible = true
	else:
		_last_breath_panel.visible = false

	# Torch slot — lee lo equipado en off_hand y muestra solo si tiene light_range.
	# Canon 2026-04-24: torch vive en off_hand, no en slot "light". El slot del
	# HUD sigue existiendo al lado del hotbar y muestra la fuente de luz actual
	# (si la hay). Si off_hand tiene espada u otro item sin light, el HUD slot
	# queda vacío con placeholder "F".
	var equipment = _player.get("equipment")
	var entry: Dictionary = {}
	if equipment != null and equipment.has_method("get_slot"):
		entry = equipment.get_slot("off_hand")
	var has_torch: bool = false
	if not entry.is_empty() and entry.get("item_id", "") != "":
		var off_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
		if float(off_data.get("stats", {}).get("light_range", 0.0)) > 0.0:
			has_torch = true
	var panel_style: StyleBoxFlat = _torch_slot_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if has_torch:
		var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
		var icon: Texture2D = item_data.get("icon", null)
		# Estado prendida/apagada dicta el look del slot entero — canon UX
		# 2026-04-23: prendida = fondo dorado "iluminando", apagada = gris normal.
		var lit: bool = _player.get("_torch_light") != null
		if icon != null:
			_torch_slot_icon.texture = icon
			_torch_slot_icon.visible = true
			_torch_slot_placeholder.visible = false
		else:
			# ItemDatabase sin icon Texture2D → fallback a la inicial del nombre
			# (ej "A" para Antorcha). Así el user VE que hay algo equipado.
			_torch_slot_icon.visible = false
			var item_name: String = String(item_data.get("name", "?"))
			_torch_slot_placeholder.text = item_name.substr(0, 1).to_upper() if item_name.length() > 0 else "?"
			if lit:
				# Placeholder más brillante + negrita visual cuando prendida.
				_torch_slot_placeholder.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
			else:
				_torch_slot_placeholder.add_theme_color_override("font_color", Color(0.7, 0.6, 0.35, 1.0))
			_torch_slot_placeholder.visible = true
		# Panel background: dorado semi-transparente cuando prendida (efecto
		# de iluminación visible), oscuro normal cuando apagada.
		if panel_style != null:
			if lit:
				panel_style.bg_color = Color(1.0, 0.75, 0.25, 0.55)
				panel_style.border_color = Color(1.0, 0.9, 0.4, 1.0)
			else:
				panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
				panel_style.border_color = Color(0.3, 0.25, 0.15, 1.0)
		# Status — si hay timer de duración (>0s), mostramos countdown.
		if lit:
			var time_left_v: Variant = _player.get("_torch_time_remaining")
			var time_left: float = float(time_left_v) if time_left_v != null else 0.0
			if time_left > 0.0:
				_torch_slot_status.text = "%ds" % int(time_left)
			else:
				_torch_slot_status.text = "ON"
			_torch_slot_status.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5, 1.0))
		else:
			_torch_slot_status.text = "OFF"
			_torch_slot_status.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
		_torch_slot_hint.visible = true
	else:
		_torch_slot_icon.texture = null
		_torch_slot_icon.visible = false
		_torch_slot_placeholder.text = "F"
		_torch_slot_placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
		_torch_slot_placeholder.visible = true
		_torch_slot_status.text = ""
		_torch_slot_hint.visible = false
		# Sin torch — panel en estado neutro.
		if panel_style != null:
			panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
			panel_style.border_color = Color(0.3, 0.25, 0.15, 1.0)
