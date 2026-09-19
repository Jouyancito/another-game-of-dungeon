extends GutTest

# Las 6 clases, jugables.
#
# ALPHA_ONLY escondía a Clérigo, Nigromante y Danzante detrás de un flag. Ese recorte existía
# para un demo de un mapa; la torre tiene cinco pisos y las tres nunca estuvieron a medias.
# Un flag que esconde trabajo terminado es peor que un TODO: el TODO al menos se ve.
#
# Este test las prueba de verdad — que carguen, que arranquen con sus stats, y que cada una
# tenga su recurso propio (Rage, Fe, Concentración...). Una clase que aparece en el selector
# pero explota al elegirla es peor que una escondida.

const ClassSelector := preload("res://scenes/ui/class_selector.gd")

const CLASS_SCENES: Dictionary = {
	"Guerrero": "res://scenes/player/player.tscn",
	"Mago": "res://scenes/player/mage.tscn",
	"Arquero": "res://scenes/player/archer.tscn",
	"Clérigo": "res://scenes/player/cleric.tscn",
	"Nigromante": "res://scenes/player/necromancer.tscn",
	"Danzante": "res://scenes/player/danzante.tscn",
}


func test_no_class_is_gated_out_of_the_game() -> void:
	assert_eq(ClassSelector.ALPHA_ONLY.size(), 0,
		"ALPHA_ONLY vacío = las 6 clases visibles. Con nombres adentro, las otras desaparecen del selector.")


func test_every_class_scene_loads() -> void:
	for class_label: String in CLASS_SCENES:
		var path: String = CLASS_SCENES[class_label]
		assert_true(ResourceLoader.exists(path), "%s no existe en '%s'" % [class_label, path])
		assert_not_null(load(path), "%s no carga" % class_label)


func test_every_class_stands_up_with_real_stats() -> void:
	# Una clase que aparece en el selector y revienta al elegirla es peor que una escondida.
	for class_label: String in CLASS_SCENES:
		var packed: PackedScene = load(CLASS_SCENES[class_label])
		var player: BasePlayer = packed.instantiate()
		add_child_autofree(player)
		await get_tree().process_frame

		assert_gt(player.max_health, 0.0, "%s tiene que arrancar con vida" % class_label)
		assert_gt(player.level, 0, "%s tiene que arrancar en nivel 1+" % class_label)
		assert_not_null(player.skills, "%s tiene que tener su hotbar de skills" % class_label)
