# dungeon_flujo_ui.md — Flujo y UI

> Verificado contra código: 2026-11-04 · Rama: feat/title-screen
> Leer esto si: se trabaja en pantalla de título, menú, creación de personaje, HUD y guardado.

## Intención de Joan
Espacio para ir puliendo lo que Joan va explicando mientras conversan. Ideas en construcción, decisiones de diseño y aclaraciones que aún no llegaron al código.
- **#2706** (poción de alcohol, spawn/hogar): Idea de diseño para mecanismo de guarda al emborracharse; no hay rastro en el código aun.
- **#3093** (sala de preparación tematizada): Concepto de sala que se adapta si más del 50% de personajes comparten clase; pendiente de implementación.
- **#3094** (Marca del estudio - conejo morado): Decisión de diseño sobre la identidad visual del estudio; quedaría como diseño salvo que un asset la use.

## Resumen
Tema de trabajo sobre flujo de pantalla de título (splash), menú principal, creación de personaje, sala de preparación, guardado y HUD. Los assets de títuloscreen fueron generados y validated por el motor-showcase-gate.

## Implementado (verificado en código)
- **Arranque:** `project.godot:18` → `res://scenes/ui/title_screen.tscn`. El splash existe en `scenes/ui/studio_splash.gd` pero no está en el arranque tras `commit 7fec301`.
- **Menú:** `scenes/ui/main_menu.gd`. `begin_play()` (:18-21) lleva a `character_select.tscn` con destino `floor1_prairie.tscn`. Hay botones: Hostear, Tutorial (deshabilitado :12), Opciones y Salir.
- **Guardado:** Autoload `SaveManager` (`project.godot:24`, `scripts/save_manager.gd`). `load_characters()` :20 y `save_characters()` :155.
- **Selección de mundo:** `scenes/ui/world_select.gd:3-7`, modelo Valheim: lista de mundos guardados + crear nuevo (nombre + seed). El nivel lee `GameManager.world_seed` y genera el mapa procedural con esa semilla. Coincide con la decisión D4 de `_onboarding_flow.md`.
- **Pendiente por revisar:** `title_screen.gd`, `character_select.gd` (más allá de la contradicción de abajo), `pause_menu.gd` y el HUD (`scenes/hud/`). Cada uno con `ruta:línea`.

## Assets
- **titlescreen_logo:** Showcase generado y aprobado. Maniquí de 1,80 m correcto (lo que se veía de 17,5 m era la escala general del logo).
- **titlescreen_room:** Blockout de cajas grises. Pendiente de confirmar si es fondo simple o requiere trabajo gráfico.

## Contradicciones doc ↔ código
Sirven para decidir cuál es la versión correcta: el código manda sobre lo que *existe*, pero la decisión de cuál *se quiere* la toma Joan.
- **Navegación del char select (D1).** `../ui/_onboarding_flow.md` §D1 la marca "Tomada": se navega por **clase-bioma**, no por personaje. En el código, `scenes/ui/character_select.gd` navega **por personaje** (`MAX_CHARACTERS = 6`, `:12`), sin ningún bioma. **Por decidir (Joan):** ¿D1 sigue vigente y falta implementarla, o se descarta?

## Docs de profundidad
- `../ui/_onboarding_flow.md`: flujo de inicio completo (menú → char select → world select) y decisiones D1-D5.
- `../ui/_design_package.md`: HUD, inventario/skills y siluetas, etiquetados [ALFA-NICE] / [POST-ALFA].
- `../ui/_charselect_diablo2_spec.md`: **superseded** por `_onboarding_flow.md`. Solo vale por la lección de performance (no N SubViewports).
- Engram #2706 (project `joan-general`): reglas completas del guardado con poción.

## Historial
- 2026-11-04 — creada (Hermes)
- 2026-11-04 — world_select verificado, contradicción D1 y docs de profundidad (Claude)