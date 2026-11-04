# dungeon_catalogo — Biblioteca del juego

> Puerta de entrada para cualquier agente (Hermes, Claude) o persona que trabaje en Dungeon Party.
> **No leas todo.** Busca tu tema en la tabla, abre SOLO esa ficha y, si te falta profundidad, sigue sus links.

## Cómo se usa

1. Identifica el tema de tu tarea en la tabla de abajo.
2. Abre la ficha. Mira su fecha de **"Verificado contra código"**: si es vieja respecto a los commits recientes de esa zona (`git log --since=<fecha> -- <carpeta>`), desconfía y verifica en el código antes de afirmar nada.
3. Cada ficha separa **Implementado** (está en el código), **Diseñado, no implementado** (solo existe en docs o en decisiones) y **Contradicciones**. No presentes una idea como si fuera un hecho.
4. Si cambias algo de un tema, actualiza su ficha al cerrar (ver "Mantenimiento").

## Fichas

Las fichas se crean **por demanda**: cuando alguien trabaja un tema que todavía no tiene ficha, la escribe al cerrar la tarea, verificada contra el código que acaba de tocar. Mientras una ficha esté **pendiente**, usa los docs fuente de esa fila, pero desconfía de ellos: tienen meses.

| Tema | Ficha | Leer si vas a trabajar en… | Docs fuente mientras esté pendiente | Verificado |
|---|---|---|---|---|
| Clases y skills | dungeon_clases.md | clases jugables, skills, stats, status effects, sinergias | `../skills/_system.md`, `../skills/<clase>.md`, `../stats_system.md` | pendiente |
| Balance y loot | dungeon_balance_loot.md | curvas, economía, loot tables, drops, tiers de items | `../balance_v2.md`, `../balance/*.md` | pendiente |
| Enemigos y bosses | dungeon_enemigos.md | mobs, fauna, IA/aggro, bosses, mimic, floor-clear | `../_estado_vivo.md` (mobs), `../enemy_tier_system.md`, `../art/_mob_audit_2026-08-22.md` | pendiente |
| Mundo y pisos | dungeon_mundo_pisos.md | torre, biomas, transiciones, generación procedural, aldea, zonas de farmeo | `../tower_biome_system.md`, `../floor_transitions.md`, `../village_builder.md` | pendiente |
| Lore | dungeon_lore.md | canon del mundo, historia de las clases y de los pisos, textos | `../lore/_world_canon.md`, `../lore/_floor_sketches.md` (ver su ⚠️) | pendiente |
| Flujo y UI | [dungeon_flujo_ui.md](dungeon_flujo_ui.md) | splash, menú, creación de personaje, sala de preparación, guardado, HUD | `../ui/_onboarding_flow.md`, `../ui/_design_package.md`, engram `dungeon_` | 2026-11-04 |
| Party y social | dungeon_party_social.md | multijugador, co-op, actividades de party, mascotas (Nami), monturas | `../party_activities.md`, `../pets_and_mounts.md` | pendiente |
| Arte | dungeon_arte.md | estilo visual, pipeline de assets, shaders/VFX, animación, marca del estudio | `../art/_art_canon.md`, `../art/_mob_pipeline.md`; índice de canon en `CLAUDE.md` | pendiente |
| Técnico | dungeon_tecnico.md | stack, carpetas, autoloads, tests, hooks, problemas conocidos | `CLAUDE.md` (raíz), `project.godot` | pendiente |

Al crear una ficha: convierte el nombre en link (`[dungeon_x.md](dungeon_x.md)`) y pon la fecha en **Verificado**.

### Plantilla de ficha

```
# dungeon_<tema> — <título>
> Verificado contra código: AAAA-MM-DD · Rama: <rama>
> Leer esto si: <una línea>

## Intención de Joan                      ← lo que Joan quiere, en sus palabras; se refina conversando
- AAAA-MM-DD: <idea o aclaración de Joan>
## Resumen
## Implementado (verificado en código)   ← con `ruta:línea`
## Diseñado, no implementado              ← con su fuente (doc o engram #id)
## Contradicciones doc ↔ código           ← gana el código
## Docs de profundidad                    ← links ../<doc>.md
## Historial
- AAAA-MM-DD — creada (Hermes|Claude)
```

## Fuentes de verdad (en orden)

1. **El código** (`game/`). Si una ficha o un doc contradice al código, gana el código y la ficha se corrige.
2. **Las fichas de esta carpeta**: resumen verificado con fecha.
3. **Los docs largos** (`game/docs/`, `GDD_DungeonParty.md`): profundidad y razonamiento, pero muchos tienen meses. `_DESIGN_INDEX.md` y `_estado_vivo.md` quedaron como históricos.
4. **Engram** (`project: another-game-of-dungeon`, títulos `dungeon_…`): decisiones recientes que todavía no llegan a ninguna ficha.

## Mantenimiento (aplica a Hermes y a Claude por igual)

Al cerrar una tarea que cambió el juego:

1. Abre la ficha del tema que tocaste.
2. Mueve lo que corresponda entre **Diseñado** → **Implementado** (con `ruta:línea`) o agrega lo nuevo.
3. Actualiza la línea **"Verificado contra código"** y la columna **Verificado** de esta tabla.
4. Agrega una línea al **Historial** de la ficha: `- AAAA-MM-DD — qué cambió (Hermes|Claude)`.
5. Si Joan tomó una decisión de diseño que aún no está en el código, anótala en **Diseñado, no implementado** de la ficha que corresponde. Así no se pierde en el chat.

**Mientras conversas con Joan** (no hace falta haber tocado código): ve puliendo **Intención de Joan** con lo que explica. Reescríbelo más claro, junta ideas repetidas y fecha cada aclaración. Es la única sección que no necesita verificación contra código. Una intención **nunca** pasa a *Implementado* hasta que se vea en el código con `ruta:línea`.

Reglas:
- **Tema nuevo sin ficha** → crea `dungeon_<tema>.md` con la misma plantilla y agrégalo a esta tabla.
- **Fichas cortas** (~150 líneas). Lo largo va en un doc de `game/docs/` y la ficha lo linkea.
- **No borres el historial** de una ficha.
