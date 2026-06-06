# Coherencia de Dominio — Índice de Proceso

> **Estado: CANON DE PROCESO VIGENTE** (desde 2026-06-06)
> Consultar SIEMPRE que toques cualquier parte de un dominio (UI, audio, combate, mundo…).
> Este doc es el **índice fino**. La versión profunda para el dominio Mundo es [`_inserccion_integral.md`](_inserccion_integral.md).

---

## Regla madre

> **Tocás una parte de un dominio → considerás el dominio ENTERO.** Si themeás 4 menús pero dejás el HUD sin theme, el dominio UI quedó incoherente. Trabajo parcial de dominio es **deuda, no contenido**.

Esto **generaliza** el Principio de Inserción Integral (`_inserccion_integral.md`), que es la versión profunda para el dominio **Mundo** (categorías A/B/C/D/E: fauna, flora, agua, terreno, mob). La misma lógica aplica a TODO dominio: lo que entra, entra entero.

El filtro scope-reset sigue por encima: *"¿esto sale en el video de 10 min del demo?"*. La regla NO autoriza a inflar scope — obliga a que lo que SÍ entra, entre coherente con su dominio.

---

## Índice de dominios

| Dominio | Regla de coherencia integral (one-liner) | Doc profundo |
|---|---|---|
| **UI** | Una superficie con theme → TODAS con theme. Mismas fuentes (Cinzel/EBGaramond), tokens de color, spacing y navegación en todas las pantallas. | §UI abajo + [`ui/_design_package.md`](ui/_design_package.md) |
| **Mundo** | Un elemento al mundo → su hábitat, lógica, HP, drop y audio completos (A/B/C/D/E). | [`_inserccion_integral.md`](_inserccion_integral.md) |
| **Combate** | Una fórmula tocada → coherente con el canon compound (daño/crit/DEF/resist/HP-MP/XP) en una sola fuente de verdad. | [`balance_v2.md`](balance_v2.md) + `shared/stats/damage_formula.gd` |
| **Audio** | Un track/SFX nuevo → bus correcto + carpeta por contexto + atribución (CC-BY) + registro en AudioManager. | §Audio abajo |
| **Progresión** | Tocás la curva XP/stats → coherente en `progression.gd` + cap de skill + ascendencia, sin hardcodear stats sueltos. | [`balance_v2.md`](balance_v2.md) + `shared/stats/progression.gd` |
| **Loot** | Un drop nuevo → entra en la TC del enemy_type con chance/guaranteed + raridad + ownership canon. | [`balance/_drop_ownership_canon.md`](balance/_drop_ownership_canon.md) + `balance/p1_loot_table.md` |
| **Clases** | Tocás una clase → skills Fase 1 + recurso único + stats base + lore alineados (no media clase). | [`skills/_system.md`](skills/_system.md) + per-class docs + `classes/class_base_stats.gd` |

> Si un dominio no tiene doc profundo todavía, este índice + su regla one-liner es suficiente para el alfa.

---

## UI — Dominio

### Inventario de superficies (auditoría 2026-06-06)

Theme canon: `res://assets/art/ui/dungeon_party_theme.tres` (Cinzel para títulos).

| Superficie | Archivo | Categoría | Theme | Nota |
|---|---|---|---|---|
| Main Menu | `scenes/ui/main_menu.tscn` | menu | ✅ | Theme en Control raíz. Cinzel título + gradiente fondo. |
| Character Select | `scenes/ui/character_select.tscn` | menu | ✅ | Theme en raíz. Cinzel título + card container. |
| Class Selector | `scenes/ui/class_selector.tscn` | menu | ✅ | Theme en raíz. Cinzel título + carrusel preview 3D. |
| Pause Menu | `scenes/ui/pause_menu.tscn` | menu | ✅ | Theme en raíz. Cinzel título + PanelContainer dim. |
| **HUD** (vida/maná/XP, hotbar, crosshair) | `scenes/hud/hud.tscn` | hud | ❌ | StyleBoxFlat inline, colores hardcodeados (HP #d92626, MP #3366e6, XP #e6c01a). **DEUDA.** |
| **Inventory UI** | `scenes/ui/inventory_ui.tscn` | inventory | ❌ | StyleBoxFlat inline (fondo #1a1a1f, tooltip #0d0d19). CanvasLayer overlay. **DEUDA.** |
| **Equipment Panel** | `scenes/ui/equipment_panel.tscn` | equipment | ❌ | StyleBoxFlat inline solo tooltip (#0d0d19). **DEUDA.** |
| **Character Window** (stats/skills/equipo) | `scenes/ui/character_window.tscn` | character_window | ❌ | 5 StyleBoxFlat inline (panel #1a1a1f, stat rows, skill slots). **DEUDA.** |
| **Journal UI** | `scenes/ui/journal_ui.tscn` | menu | ❌ | 2 StyleBoxFlat inline (panel #1f1410 + inner #2d2317). CanvasLayer overlay. **DEUDA.** |
| Floating Damage Number | `scenes/fx/floating_damage_number.tscn` | feedback | N/A | Node3D, no es UI. Sin theme necesario. |

### Checklist de coherencia UI

Cada superficie UI nueva o tocada DEBE cumplir:

- [ ] **Theme asignado** — `theme = dungeon_party_theme.tres` en el Control raíz, no StyleBoxFlat inline.
- [ ] **Fuentes canon** — Cinzel (títulos) / EBGaramond (cuerpo), no defaults de Godot.
- [ ] **Tokens de color** — paleta del theme, no hex hardcodeado por pantalla.
- [ ] **Spacing consistente** — márgenes/paddings del theme, no mágicos por escena.
- [ ] **Navegación coherente** — focus, esc/cancel, hover/pressed states alineados con las demás pantallas.

### GAP de coherencia (deuda a cerrar antes del video de 10 min)

**4 de 9 superficies UI funcionales tienen theme; 5 NO.** Las pantallas con ❌ — **HUD, Inventory, Equipment, Character Window, Journal** — usan StyleBoxFlat inline y rompen la coherencia visual del dominio UI. El dominio quedó a medias en la sesión nocturna: se themearon los 4 menús de pre-partida pero NO el gameplay/inventario.

Acción: migrar las 5 pantallas a `dungeon_party_theme.tres` (o derivar StyleBoxFlat del theme) antes de grabar. Sin esto, el video muestra dos lenguajes visuales distintos al pasar de menú a juego.

> Nota: el HUD puede querer estilo propio (barras D2/orbes — ver `ui/_design_package.md`), pero ESO también debe salir del theme/tokens canon, no de hex sueltos. "Distinto a propósito" ≠ "sin theme".

---

## Audio — Dominio

### Organización de música (clasificación Joan 2026-06-06)

| Contexto | Tracks | Carpeta destino | Licencia |
|---|---|---|---|
| 🌾 Pradera / Floor 1 exploración (folk orgánico calmo) | Windswept (loop principal), Carefree (transición), Tranquility (16m extendida) | `music/exploration/` | CC-BY (atribución) |
| 🍃 Safe zone / calma | Elf Meditation (chequear oído: puede tirar a místico) | `music/safe_zone/` | CC-BY (atribución) |
| 🍺 Taverna / ciudad (NO dungeon) | "The Old Tower Inn" (RandomMind) | `music/tavern_city/` | CC0 |
| 🔮 Místico / distorsión post-cuervo (NO pradera) | "Heavenly Loop" (isaiah658) — semilla para pisos surreales metafísicos | `music/mystic/` | CC0 |

### Estructura de carpetas recomendada

```
game/assets/audio/music/
├── exploration/      # windswept.ogg (Floor 1 default), carefree.ogg, tranquility.ogg
├── safe_zone/        # elf_meditation.ogg
├── tavern_city/      # the_old_tower_inn.ogg
└── mystic/           # heavenly_loop.ogg  (post-cuervo / pisos surreales)
```

- Floor 1 MusicPlayer apunta a `exploration/windswept.ogg`.
- Los 4 tracks Kevin MacLeod son **CC-BY → requieren `CREDITS.md`** con atribución. Los 2 de OGA son CC0 (sin atribución obligatoria, igual conviene listarlos).

### Realidad del sistema de audio (auditoría)

- **AudioManager autoload** en `shared/systems/audio_manager.gd` — un solo `MusicPlayer` (AudioStreamPlayer) al bus `Music`; SFX al bus `SFX`. `MUSIC_MAP` (4) y `SFX_MAP` (12) son diccionarios hardcodeados.
- **MusicPlayer component** (`scenes/levels/components/music_player.gd`) — AudioStreamPlayer local de nivel; chequea si existe bus `Music` en runtime, fallback a `Master`.

### Gaps de audio (deuda del dominio)

| Gap | Severidad | Nota |
|---|---|---|
| **No existe `default_bus_layout.tres`** — buses `Music`/`SFX` son strings hardcodeados sin garantía de existir en AudioServer | **Top gap** | Sin layout, `Music` puede no existir y todo cae a `Master`. Cablear buses primero. |
| Assets faltantes — `game/assets/sounds/music/` no existe; paths en MUSIC_MAP sin archivo en disco | Alta | Bloquea cualquier playback real. La nueva estructura va en `assets/audio/music/`. |
| MusicPlayer component duplica lógica de playback en vez de delegar a AudioManager | Media | Race condition si ambos suenan. Delegar a AudioManager. |
| Sin bus `ambient` | Media | `_inserccion_integral.md` A7 pide fauna ambiental a volumen bajo en bus `ambient` — no existe. |
| MUSIC_MAP/SFX_MAP hardcodeados — agregar SFX exige editar `audio_manager.gd` | Baja | Sin manifest externo ni catálogo de eventos/naming. |
| Sin crossfade/ducking entre tracks | Baja | Asignación directa de stream, sin transición. |
| Sin control de volumen en UI | Baja | `master_*_volume_db` solo en @export, sin binding UI. |

---

## Flujo de coherencia de dominio (los 3 pasos)

1. **Identificá el dominio** que estás tocando y abrí su sección/doc profundo.
2. **Inventariá el dominio entero** — listá TODAS las piezas (todas las superficies UI, todos los tracks, todas las fórmulas). Lo que tocaste es 1 de N.
3. **Cerrá la coherencia o registrá la deuda** — o llevás todo el dominio al mismo estándar, o marcás explícitamente lo que queda como deuda (como el GAP UI acá). Deuda silenciosa = trabajo parcial disfrazado de "listo".

---

*Documento creado 2026-06-06. Living document — actualizar el inventario UI cuando se cierre el gap de theme y la estructura de audio cuando se importen los assets.*
