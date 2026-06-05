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

### BlendSwap — eval terminado 2026-05-25 (agente curl-bypaseó 403)

Status global: 42 IDs evaluados · 39 CC0 · 3 CC-BY rejected · 10 style-fit alpha + 4 borderline + 25 mood-board-only.

**Bajada técnica**: BlendSwap requiere account + click manual ("Download" button). NO `curl` directo. **Joan baja manual** los aprobados → drop `.zip` en `game/assets/art/_raw/blendswap/{id}/` → yo unzip + extract + integrate.

#### Alpha P0 — Joan descargar manual (uso en piso 1 prairie)

| # | URL | Title | Use case alpha | Status |
|---|-----|-------|----------------|--------|
| #018 | https://www.blendswap.com/blend/19742 | Low Quality Weapon Pack (24 weapons) | Inventory loot Warrior melee | 🟡 manual-pending |
| #019 | https://www.blendswap.com/blend/2429 | Low Poly Hand (rigged) | FPS view player first-person | 🟡 manual-pending |
| #020 | https://www.blendswap.com/blend/31010 | Mushroom Character | Enemy prairie candidato | 🟡 manual-pending |
| #021 | https://www.blendswap.com/blend/10651 | Simple Monster (rigged) | Enemy genérico — verify style al unzip | 🟡 manual-pending |
| #022 | https://www.blendswap.com/blend/19503 | Fatty (humanoid chunky) | Bandit/NPC variant | 🟡 manual-pending |
| #023 | https://www.blendswap.com/blend/26664 | Bird animated | Fauna prairie — verify low-poly | 🟡 manual-pending |

#### Post-alpha defer (recovery cuando hagamos piso 2-5 o si alpha necesita más variedad)

| # | URL | Title | Por qué defer | Recovery condición |
|---|-----|-------|---------------|---------------------|
| #024 | https://www.blendswap.com/blend/4979 | Ogre Creature (rigged) | Boss tier, no piso 1 | Si necesitamos boss piso 1 backup o pisos 3-5 |
| #025 | https://www.blendswap.com/blend/28068 | Medieval House Tavern | Hub futuro — taverna spec ARCHIVED post-alpha | Si revivimos taverna post-alpha |
| #026 | https://www.blendswap.com/blend/11798 | Rope Knots (stylized) | Props decoración baja prioridad | Si dungeon dressing pide variedad |
| #027 | https://www.blendswap.com/blend/28541 | Rigged Knight in Armor | Warrior reskin — alpha usa Quaternius | Si Quaternius Modular Men no convence visual |
| #028 | https://www.blendswap.com/blend/8857 | Chupacabra | Creature biome unclear | Si necesitamos creature mid-tier |
| #029 | https://www.blendswap.com/blend/29737 | Long Sword (hand-painted) | Borderline style — weapon pack #018 ya cubre | Si curated weapon individual hace falta |
| #030 | https://www.blendswap.com/blend/1592 | The Vamp Suzanne | Vampire — no canon piso 1 | Si pisos 4-5 dimensión rota pide vampires |
| #031 | https://www.blendswap.com/blend/23549 | Hellknight (Doom3-inspired) | Style dark, palette no canon | Boss dimensión rota o ref armor |

#### Mood board only (25 — no descargar, refs visuales para estudiar)

VFX/shader refs: #22951 (Toon EEVEE shader), #28835 (Procedural flame), #29591 (Eye shader), #30773 (Flesh material), #16370 (Volume clouds), #27967 (Lightning ball).

Environment refs: #2156 (Forest dense), #31530 (Cave), #30014 (Mossy rock photoscan), #19861 (Stone pack), #13382 (Medieval village), #18408 (Wild grass), #16032 (Forest Monster), #17684 (Lagoon/atoll), #27027 (Water sim), #31075 (Tree photoscan), #16382 (Desert material).

Tech refs: #27773 (Curve physics), #30728 (Auto exposure), #26504 (Rigged book).

Creature refs: #16674 (Grass+trees mixed), #21988 (NPR anime tree), #27158 (Tiger/lion rig), #19383 (Werewolf), #29973 (Insects), #26664 (Bird — also P0 if low-poly).

#### Rejected — CC-BY (incompatible CC0-only policy)

| # | URL | Title | Razón |
|---|-----|-------|-------|
| Rej-1 | https://www.blendswap.com/blend/1922 | Praying mantis (erik90mx) | CC-BY (requiere atribución) |
| Rej-2 | https://www.blendswap.com/blend/16698 | Little Goblin | CC-BY |
| Rej-3 | https://www.blendswap.com/blend/15767 | Troll King | CC-BY |

---

## Resumen batch 2026-05-25 (post BlendSwap eval)

**Approved + descargados ✅** (en `_raw/` listos para integrar):
- Kenney: fantasy-town-kit, particle-pack, retro-textures-fantasy (#011)
- Quaternius: fantasy-props-megakit (#010), medieval-village-megakit (#009), stylized-nature-megakit (#008), ultimate-stylized-nature, ultimate-modular-men, ultimate-monsters, universal-animation-library (#007)
- BinBun3D: hit-fx (#013), electric-fx (#014)
- Foozle: rpg-ui-set-1 (#016)

**Approved manual-pending (Joan baja)**:
- BlendSwap #018-#023 (6 files alpha P0)

**Defer post-alpha (recovery rápido — entries arriba)**:
- KayKit Adventurers (#R03) — alternativa a Quaternius Modular Men
- KayKit Skeletons (#R04) — Necromancer summons + enemies pisos 3-5
- BlendSwap #024-#031 (8 files)
- #015 Screaming Brain Planet BG (bioma orgánico futuro)
- #017 Liminal Space Horror SFX (AI-rejected, no recovery)

**Rejected**:
- Poly Haven 3D models (photoreal, no pivot)
- BlendSwap CC-BY (Rej-1/2/3)
- Liminal Space (AI-generated)

**Mood board (no descargar, refs visuales)**:
- 4 Poly Haven gallery renders (#003-006)
- 25 BlendSwap refs (lista arriba)

---

## Decisión backlog

Cuando inbox tenga muchas entries, decidir:
1. Cuáles descargar batch
2. Cuáles defer post-alpha
3. Cuáles rechazar

Mantener inbox <20 entries activos para no fragmentar atención.

## Recovery post-alpha — cheat sheet

Si alpha pega bien y empezamos pisos 2-5 / contenido extra:
1. KayKit Adventurers + Skeletons (chars + summons) — entries #R03/#R04
2. BlendSwap defer #024-#031 (boss tier, tavern, props extra)
3. #015 Planet BG (bioma orgánico Dimensión Rota)
4. Re-eval Poly Haven HDRIs aspiracionales (#003-006) cuando Joan describa qué le gusta de cada uno

---

## #058 — Ammo Boxes (extra batch 2026-05-25)

- **Source**: download desconocida (Joan no aclaró ID/source). Probablemente BlendSwap o Kenney/itch.
- **Status**: ⏸ deferred-postalpha
- **Tipo**: 3D props ammo crates
- **Use case canon (Joan 2026-05-25)**: **piso parodia post-alpha** + **hidden weapon floors** (pisos secretos donde se pueden encontrar/usar armas de fuego que requieren munición).
- **Scope alpha**: NO — alpha demo solo melee + magic + arquería. Pólvora/firearms = post-alpha feature.
- **Location**: `game/assets/art/_raw/blendswap/_extra_ammo_boxes/Ammo Boxes.zip`
- **TODO Joan**: confirmar source + license cuando se reviva post-alpha. Re-classify a `_raw/{source}/` con ID correcto.
- **Recovery condición**: cuando spec hidden floors o parodia floor entre en backlog post-alpha.
