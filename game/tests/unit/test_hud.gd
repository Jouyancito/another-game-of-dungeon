extends GutTest

# Tests para HUD — verificar que los callbacks actualizan correctamente
# Nota: HUD depende de nodos de escena (@onready), así que testeamos
# la lógica a través de la escena completa.

var hud_scene: PackedScene = preload("res://scenes/hud/hud.tscn")


func _create_hud() -> CanvasLayer:
	var h = hud_scene.instantiate()
	add_child_autofree(h)
	await get_tree().process_frame
	return h


# ─── _on_health_changed ───

func test_health_bar_updates() -> void:
	var h = await _create_hud()
	h._on_health_changed(75.0, 150.0)
	assert_eq(h.health_bar.max_value, 150.0)
	assert_eq(h.health_bar.value, 75.0)


func test_health_label_format() -> void:
	var h = await _create_hud()
	h._on_health_changed(80.0, 100.0)
	assert_eq(h.health_label.text, "80/100")


func test_health_at_zero() -> void:
	var h = await _create_hud()
	h._on_health_changed(0.0, 100.0)
	assert_eq(h.health_bar.value, 0.0)
	assert_eq(h.health_label.text, "0/100")


func test_health_at_max() -> void:
	var h = await _create_hud()
	h._on_health_changed(150.0, 150.0)
	assert_eq(h.health_bar.value, 150.0)
	assert_eq(h.health_label.text, "150/150")


# ─── _on_mana_changed ───

func test_mana_bar_updates() -> void:
	var h = await _create_hud()
	h._on_mana_changed(50.0, 120.0)
	assert_eq(h.mana_bar.max_value, 120.0)
	assert_eq(h.mana_bar.value, 50.0)


func test_mana_label_format() -> void:
	var h = await _create_hud()
	h._on_mana_changed(89.0, 89.0)
	assert_eq(h.mana_label.text, "89/89")


func test_mana_at_zero() -> void:
	var h = await _create_hud()
	h._on_mana_changed(0.0, 156.0)
	assert_eq(h.mana_label.text, "0/156")


# ─── _on_xp_changed ───

func test_xp_bar_updates() -> void:
	var h = await _create_hud()
	h._on_xp_changed(50.0, 100.0, 1)
	assert_eq(h.xp_bar.max_value, 100.0)
	assert_eq(h.xp_bar.value, 50.0)


func test_xp_label_format() -> void:
	var h = await _create_hud()
	h._on_xp_changed(30.0, 100.0, 5)
	assert_eq(h.xp_label.text, "Nv.5  30/100")


func test_xp_label_level_1() -> void:
	var h = await _create_hud()
	h._on_xp_changed(0.0, 100.0, 1)
	assert_eq(h.xp_label.text, "Nv.1  0/100")


func test_xp_label_high_level() -> void:
	var h = await _create_hud()
	h._on_xp_changed(500.0, 1000.0, 50)
	assert_eq(h.xp_label.text, "Nv.50  500/1000")


# ─── _on_player_died ───

func test_death_screen_hidden_initially() -> void:
	var h = await _create_hud()
	assert_false(h.death_screen.visible, "Death screen oculta al inicio")


func test_death_screen_shows_on_death() -> void:
	var h = await _create_hud()
	h._on_player_died()
	assert_true(h.death_screen.visible, "Death screen visible al morir")


func test_crosshair_hidden_on_death() -> void:
	var h = await _create_hud()
	h.crosshair.visible = true
	h._on_player_died()
	assert_false(h.crosshair.visible, "Crosshair se oculta al morir")
