# Audio — Dungeon Party

**Estado**: los 12 SFX y los 4 tracks EXISTEN y suenan. Son **placeholders sintetizados**.

Hasta 2026-07-14 esta carpeta tenía un README y **cero archivos de audio**. El juego era mudo:
cada `AudioManager.play_sfx()` emitía un warning y seguía en silencio — incluido el golpe de
cada ataque, cada muerte, cada level-up.

## Cómo se regeneran

```bash
python game/tools/audio/gen_placeholder_sfx.py
```

Stdlib de Python, sin dependencias. Determinista (seed fija): la misma corrida produce los
mismos bytes. Escribe WAV 16-bit mono a 44.1kHz, que Godot importa nativo.

Cada sonido está moldeado para LEER como lo que representa —el puño golpea antes de sonar,
el slime muere desinflándose, el level-up es lo único que resuelve hacia arriba— para que el
juego se pueda jugar y grabar con feedback sonoro real.

## Reemplazarlos

Son placeholders, no diseño de sonido. Para pasar a audio real (CC0 o autoral): dejar los
archivos con **el mismo nombre** en `sfx/` y `music/`. `AudioManager.SFX_MAP` y `MUSIC_MAP`
no cambian. Si el reemplazo es `.ogg`, actualizar la extensión en esos dos mapas.

Fuentes CC0 sugeridas: Kenney (Impact Sounds, RPG Audio), freesound.org (filtro CC0).
