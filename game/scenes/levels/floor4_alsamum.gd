extends BiomeFloor

## Piso 4 — Al-Samum. Canon `lore/_alpha_5_maps.md`: "Boceto previo: Al-Samum (árabe)",
## confirmado como ARENA por `lore/_mundo_entrevista.md` §4.4 ("la arena de P4").
## Al-Samum es, literalmente, el viento venenoso del desierto.
##
## El resto está ⌛ pendiente con Joan. Construido desde lo dicho: desierto árabe, tier 4.

func _get_config() -> BiomeConfig:
	var c := BiomeConfig.new()
	c.floor_number = 4
	c.display_name = "Al-Samum"

	# El calor no es rojo: es AMARILLO y te quema los ojos. Cielo lavado, sin contraste.
	c.sky_color = Color(0.78, 0.66, 0.42)
	c.ambient_color = Color(0.85, 0.74, 0.52)
	c.ambient_energy = 1.05        # el desierto no tiene sombras donde descansar
	c.fog_color = Color(0.86, 0.76, 0.55)
	c.fog_density = 0.05           # el samum: no ves, y lo que no ves te muerde
	c.sun_color = Color(1.0, 0.92, 0.72)
	c.sun_energy = 1.3
	c.sun_angle = Vector3(-72.0, 20.0, 0.0)   # sol alto: mediodía perpetuo

	c.ground_color = Color(0.82, 0.70, 0.47)
	c.ground_roughness = 0.95

	c.prop_color = Color(0.74, 0.62, 0.42)
	c.prop_count = 110
	c.prop_min_scale = 0.9
	c.prop_max_scale = 4.5

	# Arena en el viento, horizontal. No cae: te CRUZA.
	c.weather_amount = 900
	c.weather_color = Color(0.88, 0.78, 0.56, 0.55)
	c.weather_velocity = 13.0
	c.weather_drift = Vector3(1.0, -0.25, 0.15)

	# Lo del roster que pertenece a la arena: escorpión (icónico) y las serpientes.
	c.bestiary = [
		["res://scenes/enemy/scorpion.tscn", 7, 0.6],
		["res://scenes/enemy/snake.tscn", 5, 0.5],
		["res://scenes/enemy/bandit_melee.tscn", 3, 0.8],
	]
	c.boss_scene = "res://scenes/enemy/samum.tscn"
	c.next_floor_scene = "res://scenes/levels/floor5_umbral.tscn"
	return c
