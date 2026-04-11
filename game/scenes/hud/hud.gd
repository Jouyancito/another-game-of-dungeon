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

func _ready() -> void:
	add_to_group("hud")
	death_screen.visible = false
	stat_indicator.visible = false
	level_up_label.visible = false
	_build_pickup_hint()


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


## Llamar desde main.gd después de instanciar al jugador.
## Esto evita depender del timing de group search en _ready().
func connect_to_player(player: Node) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.player_died.connect(_on_player_died)
	player.level_up.connect(_on_level_up)
	_on_health_changed(player.health, player.max_health)
	_on_mana_changed(player.mana, player.max_mana)
	_on_xp_changed(player.xp, player.xp_to_next_level, player.level)
	if player.stat_points > 0:
		stat_indicator.visible = true


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


func _on_player_died() -> void:
	crosshair.visible = false
	death_screen.visible = true
	stat_indicator.visible = false
	var tween = create_tween()
	tween.tween_property(death_screen, "color", Color(0, 0, 0, 0.7), 1.0)
