# Asset Refs Inbox — tracking + evaluación

**Propósito**: log persistente de packs/assets que Joan manda para evaluar antes de descargar/integrar.
**Creado**: 2026-05-24 (post visual diagnosis floor1_prairie).
**Fuente de verdad**: este doc + `_alpha_asset_packs.md` (canon vigente, P0).

---

## Cómo se usa

Joan manda URL → yo evalúo → entry acá con veredicto → Joan aprueba/rechaza → si aprueba, downloado a `_raw/` + sumo a `_alpha_asset_packs.md` canon.

**Eval params** (todos deben pasar):

| Param | Criterio |
|---|---|
| **Licencia** | CC0 / MIT / CC-BY ok (atribución manageable) — **NO** "non-commercial", **NO** "personal use only" |
| **Style fit** | low-poly chunky cartoon (compatible Kenney/Quaternius/KayKit). Atomic excepciones se aclaran. |
| **Formato** | gltf/glb preferido (Godot 4 nativo). FBX/OBJ ok pero requiere convert. PNG/JPG para textures/sprites. |
| **Source security** | Kenney.nl, Quaternius.com, kaylousberg.itch.io, polyhaven.com, sketchfab.com (con filter CC0), itch.io, github madjin/awesome-cc0 verified. **Sospechoso**: sitios warez, drives random sin landing pages oficiales. |
| **Scope fit** | "¿esto acerca o aleja de los 5 mapas publicables?" (filtro scope reset 2026-05-18) |

**Status flags**:
- `🟡 pending` — evaluación en curso
- `📦 downloaded` — aprobado, listo para download
- `📦 downloaded` — bajado a `_raw/`, falta integración
- `✅ integrated` — en juego (mapas/scenes lo usan)
- `🔴 rejected` — no pasa filtros (razón en notas)
- `⏸ deferred` — válido pero post-alpha

---

## Inbox entries

### #001 — Kenney Retro Fantasy Kit
- **URL**: https://kenney.nl/assets/retro-fantasy-kit
- **Mandado por**: Joan (2026-05-24)
- **Status**: 📦 downloaded
- **Tipo**: 3D environment, retro/voxel-style low-poly
- **Contenido**: 100+ medieval/castle buildings (v2.0 expanded)
- **Formato**: .glb (Kenney standard)
- **Licencia**: CC0 ✅
- **Style fit**: ✅ — compatible 100% con Fantasy Town Kit + Quaternius. Complementa variedad outposts/ruinas.
- **Source security**: ✅ kenney.nl
- **Scope fit**: ✅ — útil pisos 1-3 (outpost variants + ruins arquetipos)
- **Veredicto**: BAJAR. Suma a colección Kenney existente.
- **Próximo paso**: Joan da OK para download → curl directo URL `.zip`.

### #002 — Kenney Fantasy UI Borders
- **URL**: https://kenney.nl/assets/fantasy-ui-borders
- **Mandado por**: Joan (2026-05-24)
- **Status**: 📦 downloaded
- **Tipo**: 2D UI (panels, buttons, frames)
- **Contenido**: 140 archivos UI fantasy-themed
- **Formato**: PNG sprites (asumido — confirmar al download)
- **Licencia**: CC0 ✅
- **Style fit**: ✅ — específico para HUD/inventory/menus. NO 3D environment.
- **Source security**: ✅ kenney.nl
- **Scope fit**: ✅ — mejora HUD actual (target frame, inventory, hotbar, character window).
- **Veredicto**: BAJAR. Post-baseline visual fix.
- **Próximo paso**: descargar pero NO swap HUD aún (post B+C+D integration).

---

## Recomendaciones mías pendientes confirmación Joan

Estos los descubrí en search 2026-05-24 — esperando aprobación Joan.

### #R01 — KayKit Dungeon Pack Remastered
- **URL**: https://kaylousberg.itch.io/kaykit-dungeon-remastered
- **Status**: 🟡 pending (mi recomendación P0)
- **Tipo**: 3D modular dungeon assets
- **Contenido**: pisos/paredes/columnas/escaleras dungeon + props
- **Licencia**: CC0 ✅ (free comercial sin atribución)
- **Style fit**: ✅ idéntico a Quaternius/Kenney
- **Scope fit**: ✅ CRÍTICO para pisos 2-5 (interiors)
- **Por qué importante**: actualmente `floor1_prairie.tscn` es procedural con BoxMesh. Pisos 2-5 necesitan interiors REALES. KayKit es THE pack.

### #R02 — Poly Haven HDRI (HDRIs SOLO, no models)
- **URL**: https://polyhaven.com/hdris (filtro: "outdoor sky" o "forest")
- **Status**: 🟡 pending — pero SCOPED
- **Tipo**: HDRI skybox panorámicos 360°
- **Licencia**: CC0 ✅
- **Style fit**: ✅ — fix del cielo negro flatten, ambient lighting profesional
- **Scope fit**: ✅ P0 visual quality dentro de constraint low-poly
- **Por qué importante**: HDRI da rim light + ambient color + reflejos sin requerir LODs/PBR pesado. Compatible con Quaternius/Kenney style.
- **⚠️ AVISO 2026-05-24**: Joan mostró Poly Haven banner (Rob Tuytel escena photoreal). Decidimos NO pivotar a photoreal full. **Solo bajamos HDRIs**, NO los models photoreal (incompatibles con style low-poly canon).

### #R03 — KayKit Adventurers Pack
- **URL**: https://kaylousberg.itch.io/kaykit-adventurers (asumir, verify al chequear)
- **Status**: 🟡 pending
- **Tipo**: 3D characters riggeados
- **Style fit**: ✅
- **Por qué importante**: alternativa/complemento a Quaternius Modular Characters para warrior/mage/archer

### #R04 — KayKit Skeletons Pack
- **URL**: https://kaylousberg.itch.io/kaykit-skeletons (asumir, verify)
- **Status**: 🟡 pending
- **Tipo**: 3D enemy characters
- **Por qué importante**: skeletons para Necromancer summons (P2-P3) o enemy roster pisos 3-5.

---

## Rechazos (anti-canon)

### Poly Haven 3D Models (photoreal)
- **URL**: https://polyhaven.com/models
- **Mandado por**: Joan implícito 2026-05-24 (banner Rob Tuytel chapel-otoño)
- **Status**: 🔴 rejected (style)
- **Razón**: Style photoreal AAA incompatible con baseline low-poly chunky (Quaternius/Kenney/KayKit). Mix = Frankenstein visual. Pivot completo cost = 3-6 meses + viola scope reset 2026-05-18.
- **Reconsiderar**: post-alpha si juego pega + revenue para pivot visual.
- **Sí se mantiene**: HDRIs (#R02) + maybe textures PBR puntuales para terrain/ground.

### Liminal Space Free Horror SFX (#017 — re-classified 2026-05-25)
- **URL**: https://liminal-space-dev.itch.io/free-horror-sfx-sounds
- **Status**: 🔴 rejected (AI-generated)
- **Razón**: Author declara contenido AI-generated. Aunque CC0 legalmente safe, Steam disclosure requirement post-2024 + posible hit reputación. Joan decidió 2026-05-25 evitar el flag.
- **Reemplazo canon**: Sonniss GDC Bundle + Freesound.org filter CC0 (ver sección canon audio sources).
- **Reconsiderar**: nunca — política anti-AI assets para Dungeon Party.

---

## Canon audio sources (post Liminal rechazo 2026-05-25)

Política Dungeon Party: **NO AI-generated audio**. Solo human-made + CC0.

| Fuente | URL | License | Uso |
|---|---|---|---|
| **Sonniss GDC Bundle** | https://sonniss.com/gameaudiogdc | Royalty-free Sonniss (cuasi-CC0 uso comercial sin atribución) | **P0** — bundle anual gratuito ~30GB pro-grade. Standard indie. Liberación marzo cada año. |
| **Freesound.org** (CC0 filter) | https://freesound.org/search/?f=license:%22Creative+Commons+0%22 | CC0 per file | Library comunidad, filter estricto. Para SFX específicos urgentes pre-GDC. |
| **OpenGameArt.org audio** | https://opengameart.org/art-search-advanced?field_art_type_tid%5B%5D=12 | Mix CC0 / CC-BY | Backup community source. |
| **Recording propio** | foley básico Audacity/Reaper | self-owned | Para 5-10 sonidos signature únicos (footsteps player, signature attack, etc.) |

**Workflow**:
1. P0: Bajar Sonniss bundle más reciente cuando esté disponible (Jan 2026 release likely January o March 2027 GDC).
2. Pre-Sonniss: Freesound CC0 para SFX urgentes alpha demo.
3. Signature sounds (player footsteps, signature class abilities): record propio.

---

---

## Batch 2026-05-25 — Joan tiró 57 URLs

### Poly Haven Gallery renders (mood board aspiracional)

⚠️ NOTA: estos son RENDER SHOWCASES submitted por artistas PRO usando assets Poly Haven. NO son packs descargables — son refs visuales. Confirma decisión 2026-05-24: photoreal NO pivot, solo mood board.

| # | URL | Status | Uso |
|---|-----|--------|-----|
| #003 | https://polyhaven.com/gallery?render=dzblsJfeHNQgGYvHR9XC | ⏸ mood-board | ref atmósfera (verify cuando Joan describe lo que le gusta) |
| #004 | https://polyhaven.com/gallery?render=3V7flrjCCLLTZNLeCgE2 | ⏸ mood-board | ref atmósfera |
| #005 | https://polyhaven.com/gallery?render=diW6PWc7nN8ncpm2KWOK | ⏸ mood-board | ref atmósfera |
| #006 | https://polyhaven.com/gallery?render=naNOVu6H8B8tmEC0YB5e | ⏸ mood-board | ref atmósfera |

→ Joan, decime para CADA UNA qué elemento te gusta (lighting? composition? tree shapes? color palette?). Sin eso, son inactionable.

### 3D environment / props packs

| # | Pack | URL | Status | Veredicto |
|---|------|-----|--------|-----------|
| #007 | Quaternius Universal Animation Library | https://quaternius.itch.io/universal-animation-library | 📦 downloaded | **GOLD** — animations modulares Mixamo-compatible para chars. CC0. Esencial para movimiento fluido. |
| #008 | Quaternius Stylized Nature Megakit | https://quaternius.itch.io/stylized-nature-megakit | 📦 downloaded | Supuesto upgrade del Stylized Nature pack actual. Probable MÁS variedad trees/rocks. CC0. |
| #009 | Quaternius Medieval Village Megakit | https://quaternius.itch.io/medieval-village-megakit | 📦 downloaded | Houses/wells/carts medievales. Complementa Kenney Fantasy Town Kit. CC0. |
| #010 | Quaternius Fantasy Props Megakit | https://quaternius.com/packs/fantasypropsmegakit.html | 📦 downloaded | Weapons/loot/chests/barrels. CC0. Crítico para inventory visuals + dungeon decoration. |
| #011 | Kenney Retro Textures Fantasy | https://kenney.nl/assets/retro-textures-fantasy | 🟡 pending | Textures planas — probably 2D tileable. Verify formato + uso (ground? walls?). CC0. |
| #012 | TheBaseMesh.com library | https://www.thebasemesh.com/model-library | 🔴 risk-license | 1250 assets pero **license unclear** desde landing. Necesita visit per-asset. NO bajar batch hasta verificar. |

### VFX 3D para Godot (compatible directo)

| # | Pack | URL | Status | Veredicto |
|---|------|-----|--------|-----------|
| #013 | BinBun3D Hit FX | https://binbun3d.itch.io/hit-fx | 📦 downloaded P0 | **PERFECT FIT** — Godot scenes nativas 3D, CC0, hit/magic effects stylized. Reemplaza VFX placeholder actuales. Free = 6 presets, paid = 28. |
| #014 | BinBun3D Electric FX | https://binbun3d.itch.io/electric-fx | 📦 downloaded | Companion al #013. Lightning/rayos perfecto para Mage rayo skill. CC0 (asumido — verify). |
| #015 | Screaming Brain Planet Surface BG 2 | https://screamingbrainstudios.itch.io/planet-surface-backgrounds-2 | ⏸ deferred (bioma orgánico) | CC0 ✅, 2D 128 backgrounds sci-fi 32 planet types (cratered/desert/icy/lava/ocean/tropical). **Use case Joan 2026-05-25: bioma orgánico futuro** (no alpha piso 1). Reservar post-alpha o como skybox alternativo Dimensión Rota. |

### UI

| # | Pack | URL | Status | Veredicto |
|---|------|-----|--------|-----------|
| #016 | Foozle RPG UI Set 1 (Diablo style) | https://foozlecc.itch.io/rpg-ui-set-1 | 📦 downloaded | CC0 pixel-art Diablo-feel. Diferente del Kenney UI Borders (#002) — escoger uno o mezclar. Style mix con Quaternius 3D = OK porque UI es overlay 2D plano. |

### SFX

| # | Pack | URL | Status | Veredicto |
|---|------|-----|--------|-----------|
| #017 | Liminal Space Free Horror SFX | https://liminal-space-dev.itch.io/free-horror-sfx-sounds | ⏸ deferred (pisos 4-5) | CC0 ✅, MP3 format, 2 volumes (13+9.2 MB). Content: footsteps multi-surface (concrete/carpet/metal) + wind ambience + monster growls + creaky doors. **Use case Joan 2026-05-25: ambientes de tensión + mobs psicóticos pisos 4-5 (Tormenta/Dimensión Rota)**. ⚠️ **AI-generated audio** (disclosed by author) — sin issue legal CC0 pero flag de honestidad para Steam page disclosure si aplica. |

### BlendSwap — bulk entry crítico

#### #018-#057 — 40 URLs BlendSwap individuales

**RIESGO MAYOR**: BlendSwap permite varias licencias por upload (CC0 / CC-BY / CC-BY-NC / GPL). **Cada blend file tiene SU PROPIA license** — algunos NO son CC0.

**Eval pendiente per file**:
- /28541, /26504, /31530, /16674, /13382, /2156, /29973, /11798, /30773, /27027
- /28835, /28068, /31075, /22951, /16370, /29737, /30014, /29591, /19861, /26664
- /21988, /27773, /27967, /2429, /1922, /18408, /27158, /16382, /31010, /19742
- /30728, /17684, /23549, /16032, /19383, /4979, /16698, /19503, /15767, /8857
- /10651, /1592

**Status**: 🔴 risk-license + 🟡 unknown-style — needs per-file fetch para:
1. License check (must be CC0 — descartar CC-BY-NC / GPL)
2. Style fit (low-poly chunky cartoon — descartar photoreal/anime/realistic)
3. Format (Blender .blend → necesita export a .glb antes de Godot)

**Recomendación**: NO descargar batch. Joan dame:
- ¿Por qué estos 40? (qué viste en cada uno o pasaste todos los recent featured?)
- Querés que evalúe los 10 con mejor look basado en search/preview? Te muestro shortlist, vos confirmás.
- O preferís darme criterio (ej. "todos los que sean weapons" / "props dungeon") y yo filtro?

---

## Resumen batch 2026-05-25

**Approved (bajar P0)**: 7 packs
- #007 Quaternius Universal Animation Library
- #008 Quaternius Stylized Nature Megakit
- #009 Quaternius Medieval Village Megakit
- #010 Quaternius Fantasy Props Megakit
- #013 BinBun3D Hit FX
- #014 BinBun3D Electric FX
- #016 Foozle RPG UI Set 1

**Pending verify**: 3 packs (#011, #015, #017)

**Risk / needs decision**: TheBaseMesh + 40 BlendSwap files (#012, #018-#057)

**Mood board only**: 4 Poly Haven gallery renders (#003-006) — necesito tu comentario por imagen para que sean accionables

---

## Decisión backlog

Cuando inbox tenga muchas entries, decidir:
1. Cuáles descargar batch
2. Cuáles defer post-alpha
3. Cuáles rechazar

Mantener inbox <20 entries activos para no fragmentar atención (actualmente 57+ → consolidar pronto).
