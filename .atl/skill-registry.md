# Skill Registry — La Biblioteca

> **Qué es esto.** El índice ("libro") de las skills disponibles: qué existe, qué cubre cada una, desde cuándo. No es un resumen ni reemplaza al `SKILL.md` (esa es la fuente de verdad) — es el catálogo para decidir QUÉ cargar y, sobre todo, para detectar **qué NO existe todavía**.
>
> **Cómo usarlo (protocolo).**
> 1. Ante una tarea, buscá acá si hay skill que la cubra → si la hay, cargá su `SKILL.md` por el path.
> 2. Si **ninguna** la cubre y es una técnica/conocimiento **reutilizable** (no un one-off) → esa es la señal: crear skill nueva con `skill-creator`. Ver "Huecos" abajo.
> 3. Las **living skills** acumulan aprendizajes con fecha → permiten comparar cómo evoluciona una técnica en el tiempo.
>
> **Regenerar:** invocar la skill `skill-registry` después de crear/mover/borrar skills.
> **Fuentes escaneadas:** `~/.claude/skills/` (user) + `DungeonParty-A/.claude/skills/` (proyecto). Saltadas: `sdd-*` (suite interna), `_shared`, `skill-registry`, y el ruido del marketplace de plugins.
> **Última actualización del índice:** 2026-07-07

---

## Mapa de cobertura (por dominio)

| Dominio | Estado | Skills |
|---|---|---|
| Godot gameplay / balance / refactor | 🟢 fuerte | godot-game-designer · godot-combat-formulas · godot-balance-curves · godot-state-machine · godot-refactor |
| Arte / 3D / animación | 🟢 fuerte | blender-asset-smith (hard-surface) · corporeo-3d (orgánico) · motion-designer · art-ref-critic · kenney-quaternius-sourcer · **KB compartido:** `game/docs/art/_modeling_knowledge_base.md` |
| Workflow Git / PR / review | 🟢 fuerte | branch-pr · chained-pr · issue-creation · work-unit-commits · judgment-day |
| Docs / comunicación | 🟡 medio | cognitive-doc-design · comment-writer |
| Meta (skills / memoria) | 🟢 fuerte | skill-creator · skill-improver · skill-registry · memory |
| Departamentos (multi-worktree, DESACTIVADO) | ⚪ dormido | dept-art/design/gameplay/qa/ui · worktree-merge-coordinator |
| Otros proyectos (Lawen) | 🟢 fuerte | lawen-app-designer · lawen-bot-designer · lawena-conversation-designer |
| Modo de salida / status | 🟢 | caveman · joan-status |
| Testing | 🟡 (solo Go) | go-testing |

---

## Catálogo completo

Leyenda: **L** = living skill (acumula aprendizajes fechados). Scope: `proj` = Dungeon Party, `user` = global, `lawen` = otro proyecto.

### 🎮 Godot / Dungeon Party — game-dev

| Skill | Cubre | Scope | Actualizada | L | Path |
|---|---|---|---|---|---|
| godot-game-designer | Acelerador DP: canon, heurísticas debug, anti-patterns (auto en paths `Dungeon`) | proj | 2026-05-08 | L | `~/.claude/skills/godot-game-designer/SKILL.md` |
| godot-combat-formulas | Enforce math de combate canon (daño/crit/resist/DEF/HP/MP/XP) vs balance_v2 | proj | 2026-04-14 | | `DungeonParty-A/.claude/skills/godot-combat-formulas/SKILL.md` |
| godot-balance-curves | Elegir curva matemática (lineal/cuad/exp/log/sigmoide) para tuning de stats/daño/XP | user | 2026-04-12 | | `~/.claude/skills/godot-balance-curves/SKILL.md` |
| godot-state-machine | Patrón state machine Godot 4.6 (enum+match, node-per-state, HP-gated) | user | 2026-04-14 | | `~/.claude/skills/godot-state-machine/SKILL.md` |
| godot-refactor | Mover/renombrar `.gd/.tscn/.tres` seguro (reescribe paths `res://`) | user | 2026-04-12 | | `~/.claude/skills/godot-refactor/SKILL.md` |

### 🎨 Arte / 3D / animación

> **Fuente única de conocimiento de modelado:** `game/docs/art/_modeling_knowledge_base.md` (KB cross-linkeado — deform/shade/texture/pipeline + cheat-sheets por categoría + gate de validación + división automatizable-vs-interactivo). Las 2 skills de modelado son **routers finos** que apuntan ahí y se cruzan entre sí — conocimiento unificado, activación fragmentada. **Router:** hard-surface/props/estructuras/mecanismos/sci-fi/armas/accesorios → `blender-asset-smith`; orgánico/mascota/criatura/ropa/facial → `corporeo-3d`.

| Skill | Cubre | Scope | Actualizada | L | Path |
|---|---|---|---|---|---|
| blender-asset-smith | **Router hard-surface** → KB `_modeling_knowledge_base.md`. Pipeline headless bpy, gotchas Blender 5.1.2, contrato DP_ToonGrounded, librería de generadores. Cruza a corporeo-3d si es orgánico | user | 2026-07-07 | L | `~/.claude/skills/blender-asset-smith/SKILL.md` |
| motion-designer | Evaluar→simular mental→simular en código el MOVIMIENTO; weight/timing; método de anim del bestiario por material | user | 2026-06-16 | L | `~/.claude/skills/motion-designer/SKILL.md` |
| corporeo-3d | **Router orgánico** → KB `_modeling_knowledge_base.md`. 2D→3D→rig→animar mascotas/personajes (Meshy→Blender→Mixamo), mouth-bag, facial. Cruza a blender-asset-smith si es hard-surface | user | 2026-07-07 | L | `~/.claude/skills/corporeo-3d/SKILL.md` |
| art-ref-critic | Diff visual render-vs-target (juzgar el output real, no el plan) | user | 2026-06-11 | | `~/.claude/skills/art-ref-critic/SKILL.md` |
| kenney-quaternius-sourcer | Índice de packs CC0 low-poly; cuándo caer a IA (Meshy/Rodin) o Blender | user | 2026-04-14 | | `~/.claude/skills/kenney-quaternius-sourcer/SKILL.md` |

### 🔀 Workflow Git / PR / review

| Skill | Cubre | Scope | Actualizada | Path |
|---|---|---|---|---|
| branch-pr | Crear PRs Gentle AI, issue-first | user | 2026-05-09 | `~/.claude/skills/branch-pr/SKILL.md` |
| chained-pr | Partir cambios >400 líneas en PRs encadenados | user | 2026-05-09 | `~/.claude/skills/chained-pr/SKILL.md` |
| issue-creation | Crear issues / bug reports | user | 2026-05-09 | `~/.claude/skills/issue-creation/SKILL.md` |
| work-unit-commits | Planear commits como unidades revisables | user | 2026-05-09 | `~/.claude/skills/work-unit-commits/SKILL.md` |
| judgment-day | Doble review ciego adversarial → fix → re-juzgar | user | 2026-05-18 | `~/.claude/skills/judgment-day/SKILL.md` |

### 📝 Docs / comunicación

| Skill | Cubre | Scope | Actualizada | Path |
|---|---|---|---|---|
| cognitive-doc-design | Docs que reducen carga cognitiva (guías, README, RFC, onboarding) | user | 2026-05-09 | `~/.claude/skills/cognitive-doc-design/SKILL.md` |
| comment-writer | Comentarios de colaboración cálidos y directos (PR/issue/Slack) | user | 2026-05-09 | `~/.claude/skills/comment-writer/SKILL.md` |

### 🧰 Meta — skills / memoria

| Skill | Cubre | Scope | Actualizada | Path |
|---|---|---|---|---|
| skill-creator | Crear skills LLM-first con frontmatter válido | user | 2026-05-09 | `~/.claude/skills/skill-creator/SKILL.md` |
| skill-improver | Auditar y mejorar skills existentes | user | 2026-05-18 | `~/.claude/skills/skill-improver/SKILL.md` |
| skill-registry | Indexar skills (este libro) | user | 2026-06-16 | `~/.claude/skills/skill-registry/SKILL.md` |
| memory | Protocolo de memoria persistente engram (siempre activo) | user | 2026-04-02 | `~/.claude/skills/memory/SKILL.md` |

### 🏗️ Departamentos (setup multi-worktree — DESACTIVADO 2026-05-09, reactivable)

| Skill | Cubre | Scope | Actualizada | Path |
|---|---|---|---|---|
| dept-art | Depto Arte & VFX (shaders, partículas, materiales, lighting) | proj | 2026-04-10 | `DungeonParty-A/.claude/skills/dept-art/SKILL.md` |
| dept-design | Depto Game Design (balance, stats, fórmulas, loot, progresión) | proj | 2026-04-10 | `DungeonParty-A/.claude/skills/dept-design/SKILL.md` |
| dept-gameplay | Depto Gameplay (mecánicas, combate, IA, CharacterBody3D, señales) | proj | 2026-04-10 | `DungeonParty-A/.claude/skills/dept-gameplay/SKILL.md` |
| dept-qa | Depto QA & Integración (review, merge, testing, conflictos) | proj | 2026-04-10 | `DungeonParty-A/.claude/skills/dept-qa/SKILL.md` |
| dept-ui | Depto UI/UX (menús, HUD, inventario, tooltips, Control nodes) | proj | 2026-04-10 | `DungeonParty-A/.claude/skills/dept-ui/SKILL.md` |
| worktree-merge-coordinator | Master mergeando ramas dept/* vía semáforo de hooks | proj | 2026-04-14 | `DungeonParty-A/.claude/skills/worktree-merge-coordinator/SKILL.md` |

### 🌿 Otros proyectos / utilitarias

| Skill | Cubre | Scope | Actualizada | L | Path |
|---|---|---|---|---|---|
| lawen-app-designer | Acelerador Lawen-app (Next.js 16 + Supabase) | lawen | 2026-05-08 | L | `~/.claude/skills/lawen-app-designer/SKILL.md` |
| lawen-bot-designer | Acelerador Lawen voice-bot (Discord + voice + AI) | lawen | 2026-05-08 | L | `~/.claude/skills/lawen-bot-designer/SKILL.md` |
| lawena-conversation-designer | Reglas de diseño conversacional del bot Lawen | lawen | 2026-06-11 | | `~/.claude/skills/lawena-conversation-designer/SKILL.md` |
| go-testing | Tests Go / teatest Bubbletea / golden files | user | 2026-05-09 | | `~/.claude/skills/go-testing/SKILL.md` |
| caveman | Modo de salida ultra-comprimido (lite/full/ultra) | user | 2026-04-12 | | `~/.claude/skills/caveman/SKILL.md` |
| joan-status | Dashboard de estado cross-proyecto | user | 2026-05-08 | | `~/.claude/skills/joan-status/SKILL.md` |

### ⚙️ Suite SDD (orquestación interna — no expandida)

`sdd-init` · `sdd-explore` · `sdd-propose` · `sdd-spec` · `sdd-design` · `sdd-tasks` · `sdd-apply` · `sdd-verify` · `sdd-archive` · `sdd-onboard` → `~/.claude/skills/sdd-*/SKILL.md`

---

## Huecos — candidatos a skill nueva

Dominios que aparecen seguido en Dungeon Party pero **no tienen skill propia** (algunos los cubre un AGENT, no una skill — ahí quizás NO hace falta skill):

| Hueco | ¿Cubierto por agent? | ¿Crear skill? |
|---|---|---|
| Netcode / multiplayer / sync | sí — agent `netcode-architect` | no urgente |
| Performance / profiling Godot | sí — agent `godot-perf` | no urgente |
| World/level building / biomas | sí — agent `world-architect` | evaluar (Joan toca mucho esto) |
| Audio / SFX / música | no | **candidato** cuando lleguemos a sonido |
| VFX / shaders skills VFX | parcial (dept-art + art_canon) | evaluar |
| Playtesting automatizado (Synapse tester) | no | **candidato** (tooling/computer-use) |

> Regla: agent ≠ skill. Un **agent** ejecuta una tarea con contexto fresco; una **skill** es conocimiento/proceso reutilizable que se carga inline. Si un dominio ya tiene buen agent y NO hay proceso reutilizable que documentar → no inflar la biblioteca con una skill redundante.
