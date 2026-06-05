# 🌙 Night Session Log — 2026-06-05

> Trabajo autónomo mientras Joan duerme. Registro de **toda decisión tomada** para revisión al despertar.
> Regla rectora: libertad de decidir, PERO respetando el norte (vertical slice 10 min del piso 1).
> Cada cambio de código va en commits atómicos para que sea fácil revisar el diff o revertir.

---

## ⚠️ Pendiente de VOS al despertar (decisiones que no fuerzo)

1. **Animaciones del player** — BLOQUEADO por falta de asset. No hay animation library descargada (el `UAL1_Standard.glb` que un análisis asumió NO existe en el repo; los zips de `_raw` son FX/monsters/props/UI). Para anims reales hay que: (a) Mixamo (tu cuenta Adobe) o (b) descargar Quaternius UAL (CC0). No lo hago autónomo (decisión + licencia + cuenta tuya). Mientras, el player usa el WorldModel procedural (Tween) actual.
2. **Suelo del piso 1** — quedó en oliva medio (tonemap ACES + exposición bajada). No validaste la última captura. Si está bien, lo commiteo; si no, seguimos iterando con tu ojo.
3. **Fondo del main menu** (escena ilustrada / render 3D / flat) — define scope de arte del menú, es lo primero del video. Necesita tu gusto.
4. **Conflicto canon Erindar** (caverna mineral vs Valle de Erindar celta) — estacionado, no lo resuelvo afirmativo.

---

## ✅ Decisiones tomadas y avisadas

- **Respetar scope aun con libertad total**: las ideas nuevas de mundo van como BOCETOS/DRAFTS marcados post-alfa, NO como canon afirmativo. Priorizo higiene + lo útil al alfa + el canon de coherencia que pediste. No reescribo el juego a lo loco.
- **Filtro 3 clases reversible**: en `class_selector.gd` agregué `const ALPHA_ONLY = ["Guerrero","Mago","Arquero"]`. Las 6 clases siguen intactas en el código (canon de lanzamiento); para revivirlas, `ALPHA_ONLY = []`. Cero borrado.
- **Animaciones NO se activan a ciegas**: el activo más caro y de mayor riesgo visual. Si lo wireo mal, despertás con el player roto. Solo dejo el terreno preparado (guard defensivo) y la decisión documentada.
- **No descargo assets autónomo de noche** (licencia + tu decisión).

---

## 🔧 Trabajo en curso (procesos lanzados)

- **Workflow `night-content-gen`**: genera contenido de — higiene/drift (CLAUDE.md, PROJECT_STATE, doble canon escalado, READMEs, stats base), canon de coherencia de mundo (`_world_coherence.md`), world model consolidado, bocetos de los 5 pisos (`_floor_sketches.md`). Con revisor de scope. → Reviso y aplico con criterio antes de commitear.
- **Agente UI**: implementa guard anti-doble-render (`base_player.gd`), label `v0.1-alpha` (menú + pausa), CharacterPreview 3D en `class_selector`. Instruido a no romper.

---

## 📦 Commits de la sesión (antes de la noche)
- `1b44175` slimes → gltf real
- `b8d74fe` mapa poblado: gltf scatter + biome clusters + 42 assets
- `788f25d` doc semillas post-alfa inicial
- `2980d57` spawns ecológicos + age-scale + árboles escala real
- `959ae49` doc modelo macro de mundo

## ✅ Completado en la noche
- `42fab39` **feat(ui)** — filtro 3 clases (reversible `ALPHA_ONLY`) + CharacterPreview 3D en el selector + label `v0.1-alpha` en menú/pausa.
- `c11f205` **docs** — higiene/drift: `CLAUDE.md` sincronizado a la realidad (estructura 6 clases / 18 enemies / floor1 / shared; herencia 6 clases; stats → `class_base_stats.gd`; tabla escalado lineal deprecada con puntero a balance_v2; notas de sesión al día). Sección nueva **"Forma de trabajo con Claude"** (6 convenciones de proceso). README piso1 con inventario real. PROJECT_STATE con banner stale.
- `558b9c5` **docs(lore/art)** — `_world_coherence.md` (reglas de coherencia auto-aplicables, ancladas a números reales del código) + `_floor_sketches.md` (bocetos de los 5 pisos, marcados post-alfa, no canon afirmativo).

## 🔎 Hallazgos / correcciones de la noche
- **`shader_system.md` SÍ existe** (531 líneas) — el drift report inicial Y el workflow lo marcaron como inexistente por error. NO se rompieron las refs; quedan válidas (FIX 7/9 descartados correctamente).
- **Guard anti-doble-render NO aplicado**: `AnimationController3D` no tiene método `is_active()` (solo `var _active` privado). Para implementarlo: agregar `func is_active() -> bool: return _active` en `animation_controller.gd`, luego el guard en `base_player._setup_player_models()`. Lo dejo documentado, no lo fuerzo (toca el player).
- `_world_seeds_postalpha.md` ya cubría el modelo macro → no se duplicó.

## ⏳ Sin commitear (esperan TU validación)
- `floor1_prairie.gd` + `floor1_prairie.tscn` — el fix del suelo (tonemap ACES + exposición + verdes desaturados + cielo menos negro). Quedó a medio iterar; validá el look y lo commiteamos.

## 👉 Para vos al despertar (orden sugerido)
1. Validar el **look del suelo** (re-correr piso 1) → si va, commiteo.
2. Decidir **animaciones**: Mixamo (tu cuenta) vs descargar Quaternius UAL (CC0). Sin esto el player queda con WorldModel procedural.
3. Definir **fondo del main menu** (ilustrado / 3D / flat).
4. Leer `_world_coherence.md` y `_floor_sketches.md` — decir si los bocetos van por buen camino.
5. Bajar a `/effort high` para el día a día (ultracode solo para saltos grandes).
