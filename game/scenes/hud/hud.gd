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

func _ready() -> void:
	death_screen.visible = false
	# Conectar señales del jugador
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		player.health_changed.connect(_on_health_changed)
		player.mana_changed.connect(_on_mana_changed)
		player.xp_changed.connect(_on_xp_changed)
		player.player_died.connect(_on_player_died)
		# Inicializar barras con valores actuales
		_on_health_changed(player.health, player.max_health)
		_on_mana_changed(player.mana, player.max_mana)
		_on_xp_changed(player.xp, player.xp_to_next_level, player.level)

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

func _on_player_died() -> void:
	crosshair.visible = false
	death_screen.visible = true
	var tween = create_tween()
	tween.tween_property(death_screen, "color", Color(0, 0, 0, 0.7), 1.0)
