extends BiomeFloor

## Piso 3 — Jötunheim. Canon `lore/_alpha_5_maps.md`: "Boceto previo: Jötunheim (nórdico)",
## confirmado como HIELO por `lore/_mundo_entrevista.md` §4.4 (que lista "el hielo de P3"
## entre los fragmentos que flotan en el P5).
##
## El resto del piso está ⌛ pendiente de revisión con Joan. Lo que se construye acá sale de
## lo que SÍ está dicho: bioma nórdico de hielo, tier 3, y el escalado canon del tier system.
## Cuando Joan defina su bestiario y su boss, esta config es una línea por campo.

func _get_config() -> BiomeConfig:
	var c := BiomeConfig.new()
	c.floor_number = 3
	c.display_name = "Jötunheim"

	# Blanco azulado y plano. El frío no es oscuro — es EXPUESTO: no hay dónde esconderse.
	c.sky_color = Color(0.62, 0.72, 0.84)
	c.ambient_color = Color(0.66, 0.76, 0.88)
	c.ambient_energy = 0.85
	c.fog_color = Color(0.80, 0.87, 0.94)
	c.fog_density = 0.045          # ventisca: recorta la vista y te aísla
	c.sun_color = Color(0.88, 0.93, 1.0)
	c.sun_energy = 0.7
	c.sun_angle = Vector3(-28.0, 15.0, 0.0)   # sol bajo, nórdico: sombras largas todo el día

	c.ground_color = Color(0.80, 0.86, 0.92)
	c.ground_roughness = 0.55      # hielo: refleja algo

	c.prop_color = Color(0.72, 0.84, 0.93)
	c.prop_count = 140
	c.prop_min_scale = 1.2
	c.prop_max_scale = 5.5         # bloques enormes: es la tierra de los gigantes

	# Nieve.
	c.weather_amount = 700
	c.weather_color = Color(0.95, 0.97, 1.0, 0.85)
	c.weather_velocity = 3.5       # cae lento — no es tormenta, es peso
	c.weather_drift = Vector3(0.25, -1.0, 0.0)

	# Bestiario: lo que sobrevive en hielo del roster existente. Lobo (manada — el frío
	# empuja a cazar en grupo) y golem (piedra; acá lee como hielo tallado).
	c.bestiary = [
		["res://scenes/enemy/wolf.tscn", 6, 0.8],
		["res://scenes/enemy/golem.tscn", 2, 0.8],
	]
	c.boss_scene = "res://scenes/enemy/jotun_giant.tscn"
	c.next_floor_scene = "res://scenes/levels/floor4_alsamum.tscn"
	return c
