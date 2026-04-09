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

func _ready() -> void:
	death_screen.visible = false
	stat_indicator.visible = false
	level_up_label.visible = false


## Llamar desde main.gd después de instanciar al jugador.
## Esto evita depender del timing de group search en _ready().
func connect_to_player(player: Node) -> void:
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

	# Verificar si quedan stat points para actualizar indicador
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		stat_indicator.visible = players[0].stat_points > 0


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
