class_name ClassBaseStats

# Stats base por clase indexados por scene path.
# Fuente única de verdad para defaults de personaje.
const DEFAULTS := {
	"res://scenes/player/player.tscn": {
		"class_name": "Guerrero",
		"str_stat": 12, "int_stat": 3, "dex_stat": 6, "def_stat": 10, "vit_stat": 10
	},
	"res://scenes/player/mage.tscn": {
		"class_name": "Mago",
		"str_stat": 4, "int_stat": 12, "dex_stat": 5, "def_stat": 3, "vit_stat": 5
	},
	"res://scenes/player/archer.tscn": {
		"class_name": "Arquero",
		"str_stat": 5, "int_stat": 3, "dex_stat": 12, "def_stat": 5, "vit_stat": 7
	},
	"res://scenes/player/necromancer.tscn": {
		"class_name": "Nigromante",
		"str_stat": 3, "int_stat": 10, "dex_stat": 4, "def_stat": 4, "vit_stat": 6
	},
	"res://scenes/player/cleric.tscn": {
		"class_name": "Clérigo",
		"str_stat": 8, "int_stat": 6, "dex_stat": 4, "def_stat": 8, "vit_stat": 9
	},
	"res://scenes/player/danzante.tscn": {
		"class_name": "Danzante de Sombras",
		"str_stat": 7, "int_stat": 4, "dex_stat": 13, "def_stat": 3, "vit_stat": 5
	},
}
