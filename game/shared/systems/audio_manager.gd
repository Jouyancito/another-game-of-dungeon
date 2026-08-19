extends Node
class_name AudioManagerSingleton

## AudioManager — singleton global para SFX y música.
## Autoload registrado en project.godot como "AudioManager".
##
## Uso:
##   AudioManager.play_sfx(&"punch_hit", global_position)
##   AudioManager.play_music(&"dungeon_ambient")
##
## Cuando el archivo no existe → push_warning + no crash.

# ── Señales ───────────────────────────────────────────────────────────────────
signal sfx_played(sfx_name: StringName)
signal music_changed(track_name: StringName)

# ── Config tuneable ────────────────────────────────────────────────────────────
@export var master_sfx_volume_db: float = 0.0
@export var master_music_volume_db: float = -6.0

## Distancia máxima para SFX 3D posicionales.
@export var sfx_3d_max_distance: float = 25.0

# ── Mapa interno: nombre → path del archivo de audio ──────────────────────────
const SFX_MAP: Dictionary = {
	&"punch_hit":          "res://assets/sounds/sfx/punch_hit.wav",
	&"punch_hit_crit":     "res://assets/sounds/sfx/punch_hit_crit.wav",
	&"dash_whoosh":        "res://assets/sounds/sfx/dash_whoosh.wav",
	&"dash_impact":        "res://assets/sounds/sfx/dash_impact.wav",
	&"war_cry_activate":   "res://assets/sounds/sfx/war_cry_activate.wav",
	&"war_cry_loop":       "res://assets/sounds/sfx/war_cry_loop.wav",
	&"block_success":      "res://assets/sounds/sfx/block_success.wav",
	&"block_fail":         "res://assets/sounds/sfx/block_fail.wav",
	&"enemy_hit_flesh":    "res://assets/sounds/sfx/enemy_hit_flesh.wav",
	&"enemy_die_slime":    "res://assets/sounds/sfx/enemy_die_slime.wav",
	&"item_pickup_common": "res://assets/sounds/sfx/item_pickup_common.wav",
	&"level_up":           "res://assets/sounds/sfx/level_up.wav",
	# Pieza completa del mismo tema (7.70 s), para momentos que pasan pocas
	# veces por partida: hoy la muerte de un jefe. El corte de `level_up`
	# (4.20 s) es para el uso frecuente; éste no debe dispararse seguido o se
	# solapa consigo mismo.
	&"level_up_fanfare":   "res://assets/sounds/sfx/level_up_fanfare.wav",
}

const MUSIC_MAP: Dictionary = {
	&"dungeon_ambient":  "res://assets/sounds/music/dungeon_ambient.wav",
	&"combat_loop":      "res://assets/sounds/music/combat_loop.wav",
	&"boss_theme":       "res://assets/sounds/music/boss_theme.wav",
	&"taverna_ambient":  "res://assets/sounds/music/taverna_ambient.wav",
}

# ── Estado ────────────────────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer = null
var _current_track: StringName = &""

# Cache de streams cargados para no cargar desde disco en cada llamada
var _stream_cache: Dictionary = {}


func _ready() -> void:
	# Canal de música persistente
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)


# ── API pública ───────────────────────────────────────────────────────────────

## Reproduce un SFX.
## Si position es válida (diferente de Vector3.INF), usa AudioStreamPlayer3D.
## Si position es Vector3.INF, usa AudioStreamPlayer2D (sonido global).
func play_sfx(sfx_name: StringName, position: Vector3 = Vector3.INF) -> void:
	var path: String = SFX_MAP.get(sfx_name, "")
	if path == "":
		push_warning("AudioManager.play_sfx: SFX '%s' no existe en SFX_MAP" % sfx_name)
		return

	var stream: AudioStream = _load_stream(path)
	if stream == null:
		# _load_stream ya emitió el warning
		return

	if position != Vector3.INF:
		_play_3d(stream, position)
	else:
		_play_2d(stream)

	sfx_played.emit(sfx_name)


## Reproduce una pista de música. loop=true para que haga loop.
## Si la misma pista ya está sonando, no la interrumpe.
func play_music(track_name: StringName, loop: bool = true) -> void:
	if track_name == _current_track and _music_player.playing:
		return

	var path: String = MUSIC_MAP.get(track_name, "")
	if path == "":
		push_warning("AudioManager.play_music: track '%s' no existe en MUSIC_MAP" % track_name)
		return

	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return

	# Configurar loop si el stream lo soporta
	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED

	_music_player.stream = stream
	_music_player.volume_db = master_music_volume_db
	_music_player.play()
	_current_track = track_name
	music_changed.emit(track_name)


## Detiene la música actual con un fade out opcional.
func stop_music(fade_s: float = 0.5) -> void:
	if not _music_player.playing:
		return
	if fade_s > 0.0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_s)
		tween.tween_callback(_music_player.stop)
		tween.tween_callback(func(): _music_player.volume_db = master_music_volume_db)
	else:
		_music_player.stop()
	_current_track = &""


# ── Internos ──────────────────────────────────────────────────────────────────

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: archivo de audio no encontrado: '%s' — descarga assets CC0 para activar." % path)
		_stream_cache[path] = null  # cachear null para no repetir el warning
		return null
	var stream: AudioStream = ResourceLoader.load(path, "AudioStream", ResourceLoader.CACHE_MODE_REUSE)
	if stream == null:
		push_warning("AudioManager: no se pudo cargar el stream en '%s'" % path)
	_stream_cache[path] = stream
	return stream


func _play_2d(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = master_sfx_volume_db
	player.bus = "SFX"
	# Autoremover al terminar
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _play_3d(stream: AudioStream, position: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = master_sfx_volume_db
	player.max_distance = sfx_3d_max_distance
	player.bus = "SFX"
	# Autoremover al terminar
	player.finished.connect(player.queue_free)
	# Agregar al root de la escena para posición world-space correcta
	var scene_root := get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(player)
	else:
		add_child(player)
	# global_position DESPUÉS de entrar al árbol. Antes, Godot no tiene transform global que
	# asignar y emite "Condition !is_inside_tree() is true" — en CADA sonido posicional del
	# juego: cada golpe, cada muerte. (Mismo bug que tenía DropController con los drops.)
	player.global_position = position
	player.play()
