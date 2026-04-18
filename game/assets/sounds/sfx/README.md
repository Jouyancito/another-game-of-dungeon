# SFX Placeholders — Dungeon Party

Estos 12 archivos `.ogg` deben descargarse de fuentes CC0 y colocarse en esta carpeta.
AudioManager los carga dinámicamente. Si no existen, emite `push_warning` y continúa sin crash.

## Lista de SFX esperados

| Archivo | Descripción | Fuente sugerida |
|---------|-------------|-----------------|
| `punch_hit.ogg` | Impacto de puño / golpe melee normal | Kenney Impact Sounds |
| `punch_hit_crit.ogg` | Impacto crítico — más pesado y con reverb | Kenney Impact Sounds |
| `dash_whoosh.ogg` | Whoosh de viento al iniciar Embestida | Freesound CC0 |
| `dash_impact.ogg` | Impacto al llegar al final del dash | Kenney Impact Sounds |
| `war_cry_activate.ogg` | Grito de guerra al activarse | Freesound CC0 |
| `war_cry_loop.ogg` | Loop de intensidad mientras Grito de Guerra está activo | Freesound CC0 |
| `block_success.ogg` | Bloqueo Perfecto exitoso — sonido metálico fuerte | Kenney Impact Sounds |
| `block_fail.ogg` | Bloqueo fallido / roto | Freesound CC0 |
| `enemy_hit_flesh.ogg` | Golpe a un enemigo (flesh hit) | Kenney Impact Sounds |
| `enemy_die_slime.ogg` | Muerte de slime — sonido húmedo / splat | Kenney Impact Sounds |
| `item_pickup_common.ogg` | Recoger item común del suelo | Kenney UI Sounds |
| `level_up.ogg` | Subida de nivel — fanfarria breve | Kenney Music Jingles |

## Fuentes CC0 recomendadas

- [Kenney Assets](https://kenney.nl/assets) — packs de impacto, UI, música
- [Freesound CC0](https://freesound.org/search/?license=Creative+Commons+0) — buscar "whoosh", "punch", etc.
- [OpenGameArt CC0](https://opengameart.org/content/cc0) — efectos de sonido

## Integración

AudioManager usa `AudioStreamPlayer3D` para SFX posicionales y `AudioStreamPlayer2D` para globales.
Buses de audio recomendados en Godot: `Master > SFX`, `Master > Music`.
