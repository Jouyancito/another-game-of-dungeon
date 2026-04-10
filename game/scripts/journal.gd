extends Node
## Diario del Aventurero — bestiario estilo Arthur Morgan (RDR2).
## Autoload. Registra encuentros y kills de cada tipo de enemigo.
##
## Niveles de descubrimiento:
##   0 — nunca visto (no aparece en el diario)
##   1 — avistado (silueta borrosa, "????")
##   2 — 1+ kill (stats básicos, sketch completo)
##   3 — 10+ kills (drops, comportamiento)
##   4 — 25+ kills (info completa, debilidades, lore)

signal entry_discovered(enemy_type: String)
signal entry_updated(enemy_type: String, new_level: int)

# Datos persistentes por tipo de enemigo
# { enemy_type: { "sighted": bool, "kills": int, "first_seen": float (game time) } }
var entries: Dictionary = {}

# Umbrales de desbloqueo
const TIER_2_KILLS := 1   # primera muerte
const TIER_3_KILLS := 10  # cazador
const TIER_4_KILLS := 25  # experto

# Lore y datos estáticos por enemy_type
var _lore: Dictionary = {}


func _ready() -> void:
	_register_lore()


func _register_lore() -> void:
	_add_lore("slime", {
		"display_name": "Slime Verde",
		"category": "Fauna Pradera",
		"description": "Criatura gelatinosa que rebota sin rumbo. Parece inofensiva hasta que te pega con todo su peso. Dicen que algunos se dividen al morir.",
		"weakness": "Fuego",
		"habitat": "Praderas abiertas, cerca del agua",
		"flavor": "\"La primera vez que vi uno, pensé que era una roca musgosa. Hasta que me saltó encima.\"",
	})
	_add_lore("rat", {
		"display_name": "Rata",
		"category": "Alimañas",
		"description": "Pequeña, rápida y cobarde en soledad. En grupo se vuelven furiosas. Frecuentan ruinas y sótanos.",
		"weakness": "Trampas, veneno",
		"habitat": "Ruinas, sótanos, cuevas",
		"flavor": "\"Donde ves una, hay diez más escondidas.\"",
	})
	_add_lore("snake", {
		"display_name": "Serpiente",
		"category": "Reptiles",
		"description": "Depredadora de emboscada. Se oculta en la hierba alta y ataca cuando pasás cerca. Su veneno persiste.",
		"weakness": "Ataques a distancia",
		"habitat": "Hierba alta, grietas rocosas",
		"flavor": "\"Escuchá antes de pisar. Si escuchás, quizás no te muerden.\"",
	})
	_add_lore("fox", {
		"display_name": "Zorro",
		"category": "Mamíferos",
		"description": "Cazador ágil y astuto. Caza en grupo — uno distrae mientras los otros flanquean. Esquiva con facilidad.",
		"weakness": "Ataques en área",
		"habitat": "Bosques, bordes de pradera",
		"flavor": "\"No confíes en el que ves. Mirá atrás.\"",
	})
	_add_lore("wolf", {
		"display_name": "Lobo",
		"category": "Mamíferos",
		"description": "Depredador de manada. El alfa lidera y coordina los ataques. Si matás al alfa primero, el pack pierde coordinación.",
		"weakness": "El alfa",
		"habitat": "Bosques densos, colinas",
		"flavor": "\"La manada sigue al más fuerte. Matá al más fuerte primero.\"",
	})
	_add_lore("bird", {
		"display_name": "Córvido",
		"category": "Aves",
		"description": "Ave agresiva que patrulla desde el aire. Ataca en picada si se siente amenazada.",
		"weakness": "Proyectiles durante el ascenso",
		"habitat": "Cielo abierto, nidos en cimas",
		"flavor": "\"Graznan antes de atacar. Escuchá bien.\"",
	})
	_add_lore("hawk", {
		"display_name": "Halcón",
		"category": "Aves Rapaces",
		"description": "Más rápido y peligroso que el córvido. Intenta agarrar y dejar caer a su presa.",
		"weakness": "Proyectiles cuando planea",
		"habitat": "Cimas de colinas",
		"flavor": "\"No mires al cielo. Mirá su sombra en el suelo.\"",
	})
	_add_lore("wasp", {
		"display_name": "Avispa",
		"category": "Insectos",
		"description": "Aislada es inofensiva, pero su nido es sagrado. Si te acercás al nido, todo el enjambre te ataca.",
		"weakness": "Destruir el nido",
		"habitat": "Cerca de árboles y flores",
		"flavor": "\"Una avispa es un pinchazo. Ocho son una emergencia.\"",
	})
	_add_lore("scorpion", {
		"display_name": "Escorpión",
		"category": "Arácnidos",
		"description": "Territorial. Alterna entre pinza y aguijón envenenado. No persigue muy lejos de su zona.",
		"weakness": "Mantener distancia",
		"habitat": "Zonas rocosas, grietas",
		"flavor": "\"Su aguijón es lento pero certero. No te quedes quieto.\"",
	})
	_add_lore("goat", {
		"display_name": "Cabra Montesa",
		"category": "Mamíferos",
		"description": "Pacífica hasta que la atacás. Embiste una sola vez con fuerza y después huye.",
		"weakness": "Esquivar la embestida",
		"habitat": "Colinas y pendientes",
		"flavor": "\"Una embestida, un golpe. Si la esquivás, ya ganaste.\"",
	})
	_add_lore("turtle", {
		"display_name": "Tortuga",
		"category": "Reptiles",
		"description": "Lenta y resistente. Se retrae en su caparazón al recibir daño, volviéndose casi invulnerable por unos segundos.",
		"weakness": "Paciencia",
		"habitat": "Orillas de lagos y ríos",
		"flavor": "\"No pelees con una tortuga. Esperá a que saque la cabeza.\"",
	})
	_add_lore("bandit", {
		"display_name": "Bandido",
		"category": "Humanoides",
		"description": "Salteador humano. Bloquea ataques frontales, usa cobertura y estrategias de grupo. Cuidado con el golpe cargado.",
		"weakness": "Flanqueo, ataques por la espalda",
		"habitat": "Ruinas y campamentos",
		"flavor": "\"Pensaban que éramos presa fácil. Se equivocaron.\"",
	})
	_add_lore("bandit_archer", {
		"display_name": "Bandido Arquero",
		"category": "Humanoides",
		"description": "Apoyo a distancia. Huye si te acercás, ataca a 15m con flechas envenenadas. Prioridad al romper un grupo.",
		"weakness": "Cerrar distancia rápido",
		"habitat": "Posiciones elevadas en ruinas",
		"flavor": "\"Primero cazá al arquero. Siempre al arquero.\"",
	})
	_add_lore("golem", {
		"display_name": "Golem de Piedra",
		"category": "Criaturas Mágicas",
		"description": "Se camufla como una roca hasta que te acercás. Tres ataques: puñetazo, pisotón en área y lanzar roca. Lento pero imparable.",
		"weakness": "Magia, ataques por la espalda",
		"habitat": "Zonas rocosas",
		"flavor": "\"La roca que no recordás haber visto antes... probablemente no era una roca.\"",
	})
	_add_lore("enemy_basic", {
		"display_name": "Enemigo",
		"category": "Desconocido",
		"description": "Un enemigo simple del cual aún no tenés información detallada.",
		"weakness": "Desconocida",
		"habitat": "Variable",
		"flavor": "",
	})


func _add_lore(key: String, data: Dictionary) -> void:
	_lore[key] = data


# ═══════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════

## Registra un avistamiento. Llamar cuando el jugador se acerca por primera vez.
func sight(enemy_type: String) -> void:
	if enemy_type == "":
		return
	if not entries.has(enemy_type):
		entries[enemy_type] = {
			"sighted": true,
			"kills": 0,
			"first_seen": Time.get_ticks_msec() / 1000.0,
		}
		entry_discovered.emit(enemy_type)
		entry_updated.emit(enemy_type, get_level(enemy_type))


## Registra una muerte. Llamar desde BaseEnemy.die()
func record_kill(enemy_type: String) -> void:
	if enemy_type == "":
		return
	if not entries.has(enemy_type):
		entries[enemy_type] = {
			"sighted": true,
			"kills": 0,
			"first_seen": Time.get_ticks_msec() / 1000.0,
		}
		entry_discovered.emit(enemy_type)

	var old_level: int = get_level(enemy_type)
	entries[enemy_type]["kills"] += 1
	var new_level: int = get_level(enemy_type)
	if new_level != old_level:
		entry_updated.emit(enemy_type, new_level)


## Nivel de descubrimiento de un enemigo (0-4)
func get_level(enemy_type: String) -> int:
	if not entries.has(enemy_type):
		return 0
	var kills: int = entries[enemy_type].get("kills", 0)
	if kills >= TIER_4_KILLS:
		return 4
	if kills >= TIER_3_KILLS:
		return 3
	if kills >= TIER_2_KILLS:
		return 2
	return 1  # sólo avistado


## Devuelve el lore de un enemy_type (datos estáticos)
func get_lore(enemy_type: String) -> Dictionary:
	return _lore.get(enemy_type, {})


## Lista todos los enemy_types descubiertos (nivel >= 1)
func get_discovered_types() -> Array[String]:
	var result: Array[String] = []
	for key: String in entries.keys():
		result.append(key)
	return result


## Total descubiertos / total en el lore
func get_progress() -> Vector2i:
	return Vector2i(entries.size(), _lore.size())


## Kills totales de un tipo
func get_kills(enemy_type: String) -> int:
	if not entries.has(enemy_type):
		return 0
	return entries[enemy_type].get("kills", 0)
