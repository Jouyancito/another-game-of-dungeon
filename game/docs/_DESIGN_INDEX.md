# Design Index — Sesión 2026-06-05
**Punto de entrada único para todos los docs de diseño generados en esta sesión.**
Abrí este archivo primero cuando retomés el trabajo.

---

## Integración y planificación

| Archivo | Qué contiene |
|---|---|
| [`_inserccion_integral.md`](_inserccion_integral.md) | Plan de integración global: cómo encajan los sistemas nuevos (visual scatter, bioma, enemies) con el estado actual del proyecto |
| [`_floor1_integral_plan.md`](_floor1_integral_plan.md) | Plan integral del Piso 1 Pradera: assets, enemies, props, layout, ambient fauna y métricas de completitud |
| [`_night_session_log.md`](_night_session_log.md) | Log de la sesión nocturna — decisiones tomadas, contexto de lo que se hizo y por qué, referencia cronológica |

---

## UI / UX

| Archivo | Qué contiene |
|---|---|
| [`ui/_onboarding_flow.md`](ui/_onboarding_flow.md) | **Flujo de inicio completo** (2026-06-06): menú → character select estilo Blade & Soul (navegación por clase-bioma) → world select Valheim (local + seed). Supersede el modelo D2 como pantalla principal. Decisiones D1-D5 registradas |
| [`ui/_charselect_diablo2_spec.md`](ui/_charselect_diablo2_spec.md) | Spec de la pantalla de selección de personaje estilo Diablo 2: layout, flujo, preview 3D, data de clase. ⚠️ **Superseded** por `_onboarding_flow.md` como modelo principal — su aporte vive como el atajo de lista izquierda + lección de performance (no N SubViewports) |
| [`ui/_design_package.md`](ui/_design_package.md) | **Paquete de diseño UI completo** — HUD (globos D2 vs barras, mockups ASCII, implementación), Inventario/Skills (grid, tooltip, miniaturas, hotbar), Personajes/siluetas (geometría procedural, attachment points armas, transmog post-alfa). Cada ítem etiquetado [ALFA-NICE] / [POST-ALFA] con assets a conseguir |

---

## Arte

| Archivo | Qué contiene |
|---|---|
| [`art/_world_coherence.md`](art/_world_coherence.md) | Análisis de coherencia visual del mundo: cómo se relacionan los biomas, paletas, y referentes de arte (LOTR/Metin2/Dark and Darker/Kimetsu) a nivel global del proyecto |

---

## Lore

| Archivo | Qué contiene |
|---|---|
| [`lore/_floor_sketches.md`](lore/_floor_sketches.md) | Bocetos narrativos / atmosféricos de los pisos del dungeon ⚠️ **LORE A CORREGIR CON JOAN**: la estructura de pisos es **bloque familiar largo → encuentro con el cuervo → distorsión progresiva**. NO es una curva gradual 1→5. Los primeros 5-15 pisos deben sentirse reconocibles (taberna, bosque, montaña chilena), la ruptura llega después del cuervo. Revisar este doc antes de usar como referencia. |
| [`lore/_world_seeds_postalpha.md`](lore/_world_seeds_postalpha.md) | Semillas de worldbuilding post-alfa: ideas narrativas, facciones, misterios y ganchos de historia que se desarrollarán después del demo |

---

## Cómo usar este índice

1. **Para el video de 10 min**: empezar por `ui/_design_package.md` (sección HUD → Sprint 1) y `_floor1_integral_plan.md`.
2. **Para validar lore antes de escribir diálogos/flavor text**: leer `lore/_floor_sketches.md` con la corrección de Joan (ver ⚠️ arriba) y `lore/_world_seeds_postalpha.md` como contexto futuro.
3. **Para decisiones de arte y assets**: `art/_world_coherence.md` + `ui/_design_package.md` sección Assets.
4. **Para integración de sistemas**: `_inserccion_integral.md` primero, luego `_floor1_integral_plan.md`.

---

## Decisiones pendientes que Joan debería resolver primero

Antes de arrancar implementación, hay dos bifurcaciones que bloquean trabajo concreto:

**1. ¿Kenney o Aseprite para los orbes del HUD?**
El único asset bloqueante del Sprint 1 (HUD) es el marco circular del orbe HP/MP. Hay dos caminos:
- Kenney "Fantasy UI Borders" (CC0, gratis, ~5 min de trabajo, look genérico).
- Aseprite manual (~15 min, identidad visual más propia, integra mejor con el art canon).
Esta decisión destraba todo el Sprint 1. Elegí UNA y arrancamos.

**2. ¿La estructura de pisos del lore ya la acordamos con Joan?**
`lore/_floor_sketches.md` puede tener la progresión 1→5 gradual que se descartó. La estructura vigente es: **bloque familiar (pisos 1-N) → encuentro con el cuervo → distorsión**. Si ese doc no refleja esto, hay que corregirlo antes de usarlo como referencia para flavor text, loading screens o diálogos de NPC del piso.
