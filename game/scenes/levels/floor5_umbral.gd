extends BiomeFloor

## Piso 5 — Umbral Fragmentado. El único de los tres con canon REAL, en
## `lore/_mundo_entrevista.md` §4.4:
##
##   "vacío geométrico, fragmentos flotantes de todos los pisos anteriores (el pasto de P1,
##    el hielo de P3, la arena de P4 flotando sin soporte), gravedad variable,
##    manifestaciones geométricas como mobs, Guardián-Cuervo como boss de RANGO."
##
## Todo eso está acá: el vacío, los fragmentos, la gravedad rota, y el Cuervo.
## (El doc marca el boceto como ESPECULATIVO y su tabla "¿Confirmás?" sigue vacía — es lo
## dicho, no lo firmado.)

func _get_config() -> BiomeConfig:
	var c := BiomeConfig.new()
	c.floor_number = 5
	c.display_name = "Umbral Fragmentado"

	# El vacío. Negro, sin horizonte, sin niebla que suavice: no hay atmósfera que atravesar
	# porque no hay aire. Lo único que existe son los pedazos.
	c.sky_color = Color(0.01, 0.01, 0.02)
	c.ambient_color = Color(0.16, 0.13, 0.24)
	c.ambient_energy = 0.5
	c.fog_density = 0.0            # sin niebla: la distancia no se pierde, se ACABA
	c.sun_color = Color(0.72, 0.62, 0.95)
	c.sun_energy = 0.35
	c.sun_angle = Vector3(-40.0, 200.0, 0.0)  # la luz viene del lado equivocado

	c.ground_color = Color(0.10, 0.09, 0.14)
	c.ground_roughness = 1.0

	# Los fragmentos: pedazos de los pisos anteriores flotando, emisivos. Son lo único que
	# se ve, y son RECONOCIBLES — el jugador ya caminó sobre ellos.
	c.prop_color = Color(0.55, 0.45, 0.85)
	c.prop_count = 170
	c.prop_min_scale = 0.6
	c.prop_max_scale = 6.0
	c.prop_emissive = true

	# Esquirlas subiendo. Nada cae acá.
	c.weather_amount = 400
	c.weather_color = Color(0.65, 0.55, 0.95, 0.7)
	c.weather_velocity = 2.5
	c.weather_drift = Vector3(0.0, 1.0, 0.0)

	# Gravedad rota (canon: "gravedad variable"). Se siente ANTES de que nadie lo explique:
	# saltás más alto, caés más lento, y el piso ya te dijo que está mal.
	c.gravity_scale = 0.45

	# Ecos de lo anterior. Canon: "manifestaciones geométricas + ecos de bosses anteriores
	# (sombras sin color)". El golem es el eco más legible que tiene el roster.
	c.bestiary = [
		["res://scenes/enemy/golem.tscn", 3, 0.8],
		["res://scenes/enemy/giant_moth.tscn", 6, 2.5],
	]

	c.boss_scene = "res://scenes/enemy/guardian_cuervo.tscn"
	c.next_floor_scene = ""        # el último piso construido: corta con el cliffhanger
	return c
