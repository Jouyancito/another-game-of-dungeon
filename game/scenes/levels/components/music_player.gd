extends AudioStreamPlayer

## Reproductor de música de exploración Floor 1. Loop simple del track principal.
## Tracks folk orgánicos CC0/CC-BY (ver game/assets/audio/CREDITS.md).

@export var track: AudioStream = null   # asignar windswept.ogg/.mp3 en el inspector
@export var music_volume_db: float = -8.0

func _ready() -> void:
	bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	volume_db = music_volume_db
	if track:
		stream = track
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		play()
