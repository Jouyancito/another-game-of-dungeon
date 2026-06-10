extends GutTest

# Tests para SaveManager — CRUD de personajes, defaults por clase
# SaveManager extiende Node y usa FileAccess. NO lo añadimos al árbol de escena
# para que _ready() no dispare load_characters() y sobreescriba el estado limpio.
# create_character() llama save_characters() que puede loguear un error si user://
# no está disponible, pero el estado en memoria es correcto y es lo que testeamos.

var manager: Node


func before_each() -> void:
	manager = load("res://scripts/save_manager.gd").new()
	# No añadimos al árbol (_ready no se dispara, characters arranca en [])


func after_each() -> void:
	if is_instance_valid(manager):
		manager.free()


# ═══════════════════════════════════════════
# ClassBaseStats.DEFAULTS
# ═══════════════════════════════════════════

func test_defaults_has_six_classes() -> void:
	# Danzante de Sombras was added as the 6th class (canon 2026-04-23).
	assert_eq(ClassBaseStats.DEFAULTS.size(), 6, "6 clases definidas (includes Danzante)")


func test_defaults_warrior() -> void:
	var d = ClassBaseStats.DEFAULTS["res://scenes/player/player.tscn"]
	assert_eq(d["class_name"], "Guerrero")
	assert_eq(d["str_stat"], 12)
	assert_eq(d["def_stat"], 10)
	assert_eq(d["vit_stat"], 10)


func test_defaults_mage() -> void:
	var d = ClassBaseStats.DEFAULTS["res://scenes/player/mage.tscn"]
	assert_eq(d["class_name"], "Mago")
	assert_eq(d["int_stat"], 12)
	assert_eq(d["vit_stat"], 5)


func test_defaults_archer() -> void:
	var d = ClassBaseStats.DEFAULTS["res://scenes/player/archer.tscn"]
	assert_eq(d["class_name"], "Arquero")
	assert_eq(d["dex_stat"], 12)
	assert_eq(d["vit_stat"], 7)


func test_defaults_necromancer() -> void:
	var d = ClassBaseStats.DEFAULTS["res://scenes/player/necromancer.tscn"]
	assert_eq(d["class_name"], "Nigromante")
	assert_eq(d["int_stat"], 10)
	assert_eq(d["def_stat"], 4)


func test_defaults_cleric() -> void:
	var d = ClassBaseStats.DEFAULTS["res://scenes/player/cleric.tscn"]
	assert_eq(d["class_name"], "Clérigo")
	assert_eq(d["str_stat"], 8)
	assert_eq(d["int_stat"], 6)
	assert_eq(d["def_stat"], 8)
	assert_eq(d["vit_stat"], 9)


# ═══════════════════════════════════════════
# CREATE
# ═══════════════════════════════════════════

func test_create_character_returns_index() -> void:
	var idx = manager.create_character("TestGuy", "res://scenes/player/player.tscn", "Guerrero")
	assert_eq(idx, 0, "Primer personaje en índice 0")


func test_create_character_increments_count() -> void:
	manager.create_character("Guy1", "res://scenes/player/player.tscn", "Guerrero")
	manager.create_character("Guy2", "res://scenes/player/mage.tscn", "Mago")
	assert_eq(manager.get_character_count(), 2)


func test_create_character_sets_name() -> void:
	manager.create_character("Arthas", "res://scenes/player/player.tscn", "Guerrero")
	var c = manager.get_character(0)
	assert_eq(c["name"], "Arthas")


func test_create_character_sets_class_scene() -> void:
	manager.create_character("Gandalf", "res://scenes/player/mage.tscn", "Mago")
	var c = manager.get_character(0)
	assert_eq(c["class_scene"], "res://scenes/player/mage.tscn")


func test_create_character_uses_class_defaults() -> void:
	manager.create_character("Legolas", "res://scenes/player/archer.tscn", "Arquero")
	var c = manager.get_character(0)
	assert_eq(c["dex_stat"], 12, "Archer DEX default")
	assert_eq(c["str_stat"], 5, "Archer STR default")


func test_create_character_starts_level_1() -> void:
	manager.create_character("Noob", "res://scenes/player/player.tscn", "Guerrero")
	var c = manager.get_character(0)
	assert_eq(c["level"], 1)
	assert_eq(c["xp"], 0.0)
	assert_eq(c["stat_points"], 0)


func test_create_unknown_class_uses_generic_defaults() -> void:
	manager.create_character("Custom", "res://scenes/player/custom.tscn", "Custom")
	var c = manager.get_character(0)
	assert_eq(c["str_stat"], 5, "Generic default STR = 5")
	assert_eq(c["int_stat"], 5, "Generic default INT = 5")
	assert_eq(c["class_name"], "Custom")


func test_create_character_has_created_at() -> void:
	manager.create_character("Dated", "res://scenes/player/player.tscn", "Guerrero")
	var c = manager.get_character(0)
	assert_has(c, "created_at", "Tiene campo created_at")
	assert_typeof(c["created_at"], TYPE_STRING)


# ═══════════════════════════════════════════
# GET
# ═══════════════════════════════════════════

func test_get_character_valid_index() -> void:
	manager.create_character("Hero", "res://scenes/player/player.tscn", "Guerrero")
	var c = manager.get_character(0)
	assert_eq(c["name"], "Hero")


func test_get_character_invalid_negative() -> void:
	# SaveManager emits push_error for invalid indices — this is expected behavior.
	var c = manager.get_character(-1)
	assert_eq(c, {}, "Negative index returns empty dict")
	assert_push_error_count(1, "push_error expected for invalid index -1")


func test_get_character_invalid_out_of_range() -> void:
	# SaveManager emits push_error for invalid indices — this is expected behavior.
	var c = manager.get_character(99)
	assert_eq(c, {}, "Out-of-range index returns empty dict")
	assert_push_error_count(1, "push_error expected for out-of-range index 99")


func test_get_character_count_empty() -> void:
	assert_eq(manager.get_character_count(), 0)


func test_get_character_count_after_creates() -> void:
	manager.create_character("A", "res://scenes/player/player.tscn", "Guerrero")
	manager.create_character("B", "res://scenes/player/mage.tscn", "Mago")
	manager.create_character("C", "res://scenes/player/archer.tscn", "Arquero")
	assert_eq(manager.get_character_count(), 3)


# ═══════════════════════════════════════════
# UPDATE
# ═══════════════════════════════════════════

func test_update_character_merges_data() -> void:
	manager.create_character("Leveler", "res://scenes/player/player.tscn", "Guerrero")
	manager.update_character(0, {"level": 5, "xp": 200.0})
	var c = manager.get_character(0)
	assert_eq(c["level"], 5)
	assert_eq(c["xp"], 200.0)


func test_update_character_preserves_existing() -> void:
	manager.create_character("Keeper", "res://scenes/player/mage.tscn", "Mago")
	manager.update_character(0, {"level": 10})
	var c = manager.get_character(0)
	assert_eq(c["name"], "Keeper", "Nombre no cambia")
	assert_eq(c["int_stat"], 12, "INT no cambia")
	assert_eq(c["level"], 10, "Level sí cambia")


func test_update_stat_points() -> void:
	manager.create_character("Pointer", "res://scenes/player/player.tscn", "Guerrero")
	manager.update_character(0, {"stat_points": 9, "str_stat": 15})
	var c = manager.get_character(0)
	assert_eq(c["stat_points"], 9)
	assert_eq(c["str_stat"], 15)


# ═══════════════════════════════════════════
# DELETE
# ═══════════════════════════════════════════

func test_delete_character_removes() -> void:
	manager.create_character("ToDelete", "res://scenes/player/player.tscn", "Guerrero")
	assert_eq(manager.get_character_count(), 1)
	manager.delete_character(0)
	assert_eq(manager.get_character_count(), 0)


func test_delete_shifts_indices() -> void:
	manager.create_character("First", "res://scenes/player/player.tscn", "Guerrero")
	manager.create_character("Second", "res://scenes/player/mage.tscn", "Mago")
	manager.create_character("Third", "res://scenes/player/archer.tscn", "Arquero")
	manager.delete_character(0)
	assert_eq(manager.get_character_count(), 2)
	assert_eq(manager.get_character(0)["name"], "Second", "Second ahora es índice 0")
	assert_eq(manager.get_character(1)["name"], "Third", "Third ahora es índice 1")


func test_delete_middle_character() -> void:
	manager.create_character("A", "res://scenes/player/player.tscn", "Guerrero")
	manager.create_character("B", "res://scenes/player/mage.tscn", "Mago")
	manager.create_character("C", "res://scenes/player/archer.tscn", "Arquero")
	manager.delete_character(1)
	assert_eq(manager.get_character_count(), 2)
	assert_eq(manager.get_character(0)["name"], "A")
	assert_eq(manager.get_character(1)["name"], "C")


# ═══════════════════════════════════════════
# EDGE CASES
# ═══════════════════════════════════════════

func test_can_create_six_characters() -> void:
	for i in range(6):
		manager.create_character("Char%d" % i, "res://scenes/player/player.tscn", "Guerrero")
	assert_eq(manager.get_character_count(), 6, "Se pueden crear hasta 6 personajes")


func test_all_six_classes_created() -> void:
	# Includes Danzante de Sombras added as 6th class (canon 2026-04-23).
	var scenes = [
		["res://scenes/player/player.tscn", "Guerrero"],
		["res://scenes/player/mage.tscn", "Mago"],
		["res://scenes/player/archer.tscn", "Arquero"],
		["res://scenes/player/necromancer.tscn", "Nigromante"],
		["res://scenes/player/cleric.tscn", "Clérigo"],
		["res://scenes/player/danzante.tscn", "Danzante de Sombras"],
	]
	for s in scenes:
		manager.create_character(s[1], s[0], s[1])

	assert_eq(manager.get_character_count(), 6)
	for i in range(6):
		var c = manager.get_character(i)
		assert_eq(c["name"], scenes[i][1])
		assert_eq(c["class_scene"], scenes[i][0])


func test_defaults_match_base_player_stats() -> void:
	# Verificar que los defaults del SaveManager coincidan con lo que
	# cada clase setea en _on_class_ready()
	var warrior = ClassBaseStats.DEFAULTS["res://scenes/player/player.tscn"]
	assert_eq(warrior["str_stat"], 12, "Warrior STR matches base_player")
	assert_eq(warrior["int_stat"], 3, "Warrior INT matches base_player")
	assert_eq(warrior["dex_stat"], 6, "Warrior DEX matches base_player")
	assert_eq(warrior["def_stat"], 10, "Warrior DEF matches base_player")
	assert_eq(warrior["vit_stat"], 10, "Warrior VIT matches base_player")


func test_load_characters_resets_when_no_file() -> void:
	# Limpiar archivo si existe de runs anteriores
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("characters.json")
		dir.remove("characters.json.tmp")
	manager.characters = [{"fake": true}]
	manager.load_characters()
	assert_eq(manager.characters, [], "Sin archivo, characters queda vacío")


func test_create_and_load_roundtrip() -> void:
	# Limpiar archivos previos
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove("characters.json")
		dir.remove("characters.json.tmp")
	manager.create_character("RoundTrip", "res://scenes/player/player.tscn", "Guerrero")
	# Crear nuevo manager y cargar desde disco
	var manager2 = load("res://scripts/save_manager.gd").new()
	manager2.load_characters()
	assert_eq(manager2.get_character_count(), 1, "Personaje persistido en disco")
	assert_eq(manager2.get_character(0)["name"], "RoundTrip")
	manager2.free()
	# Limpiar
	if dir:
		dir.remove("characters.json")
		dir.remove("characters.json.tmp")
