extends GutTest

# El juego tiene sonido.
#
# Hasta 2026-07-14 no lo tenía: assets/sounds/sfx/ contenía un README y CERO archivos. Cada
# AudioManager.play_sfx() emitía un warning y devolvía silencio — el golpe de cada ataque,
# cada muerte, cada level-up. El juego era mudo y nada fallaba, porque AudioManager está
# diseñado para avisar y seguir. Ese diseño es correcto; lo que faltaba era el audio.
#
# Este test es lo que impide que vuelva a pasar: si alguien agrega una entrada al SFX_MAP y
# no el archivo, falla acá en vez de descubrirse grabando el demo.


func test_every_sfx_in_the_map_has_a_real_file() -> void:
	for key: StringName in AudioManager.SFX_MAP:
		var path: String = AudioManager.SFX_MAP[key]
		assert_true(ResourceLoader.exists(path),
			"el SFX '%s' está en el mapa pero no existe en '%s' — el juego enmudece ahí" % [key, path])


func test_every_music_track_in_the_map_has_a_real_file() -> void:
	for key: StringName in AudioManager.MUSIC_MAP:
		var path: String = AudioManager.MUSIC_MAP[key]
		assert_true(ResourceLoader.exists(path),
			"el track '%s' está en el mapa pero no existe en '%s'" % [key, path])


func test_the_sounds_actually_load_as_audio() -> void:
	# Que el archivo exista no alcanza: un WAV corrupto existe igual. Tiene que CARGAR como
	# AudioStream y durar más que cero.
	for key: StringName in AudioManager.SFX_MAP:
		var stream: AudioStream = load(AudioManager.SFX_MAP[key])
		assert_not_null(stream, "'%s' no carga como AudioStream" % key)
		if stream != null:
			assert_gt(stream.get_length(), 0.0, "'%s' dura 0 segundos: es silencio" % key)


func test_playing_a_sound_no_longer_warns() -> void:
	# El síntoma original: reproducir CUALQUIER sonido emitía un push_warning. GUT cuenta un
	# push_warning dentro de un test como fallo, así que este test falla solo si el juego
	# vuelve a quedarse mudo.
	AudioManager.play_sfx(&"level_up")
	AudioManager.play_sfx(&"punch_hit", Vector3.ZERO)
	AudioManager.play_sfx(&"enemy_die_slime", Vector3.ZERO)
	assert_true(true, "llegar acá sin warnings ES el assert")
