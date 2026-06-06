# Plan de Inserción Integral — Bestiario Piso 1

> Aplicación del **Principio de Inserción Integral** (`_inserccion_integral.md`, checklist B) al roster de mobs del Piso 1.
> Objetivo: cada mob con **modelo correcto** (golem parece golem, bandido parece persona, lobo parece lobo) + **movimiento** + **IA/inteligencia** coherente.
> Fecha: 2026-06-06 · Estado: 19 enemies auditados.

## TL;DR

- **17 de 19 ya son integral** (IA propia + movimiento + comportamiento). El trabajo NO es construir desde cero.
- El gap dominante es **VISUAL**: ~10 mobs usan mesh procedural (EnemyModelBuilder) o cubo placeholder en vez de gltf real.
- **Buena noticia**: hay 21 modelos gltf importados (con `.import`, runtime-safe) en `game/assets/art/piso1_pradera/enemies/`. Varios mobs solo necesitan **swap de modelo** (1-2 líneas en `_on_enemy_ready`), no IA nueva.
- Los packs `_raw/quaternius/` **NO tienen `.import`** → no se pueden cargar en runtime. Para usarlos hay que reimportar a `piso1_pradera/`. Pero para casi todo el roster ya existe equivalente importado → **no hace falta tocar `_raw/`**.

---

## 1. Tabla per-enemy

Leyenda modelo: **gltf** = modelo real importado · **proc** = EnemyModelBuilder procedural · **stub** = placeholder.
Leyenda runtime: ✅ = tiene `.import` (cargable en runtime) · ❌ = `_raw/` sin sidecar (hay que reimportar).

| Enemy | Modelo (estado) | IA (estado) | Modelo recomendado a asignar | Runtime? | Gaps integral | Prio |
|---|---|---|---|---|---|---|
| **golem** | proc humanoid gris (BoxMesh) | ✅ dormant→awaken, 3-ciclo (punch/stomp/rock), mass 3 | `enemies/big/enemy_orc.gltf` (cuerpo pétreo/macizo) o mantener proc con tint piedra | ✅ orc importado | Modelo no "lee" como golem de piedra. Solo swap visual | **P1** |
| **bandit_melee** | proc humanoid + box-espada | ✅ 3-ciclo (slash/bash/heavy), strafe, block 30%, auto-stun | `enemies/big/enemy_orc.gltf` o `enemy_tribal.gltf` (humanoides reales) | ✅ orc/tribal/ninja/monkroose importados | Cápsula no parece persona. Swap a humanoide gltf | **P1** |
| **bandit_archer** | proc humanoid + box-arco | ✅ kiter flee/hold/approach, LoS raycast, strafe | `enemies/big/enemy_ninja.gltf` (silueta ágil) o `enemy_tribal.gltf` | ✅ ninja/tribal importados | Igual que melee: swap a humanoide. Conservar box-arco como attach | **P1** |
| **wolf** | proc quadruped (EnemyModelBuilder) | ✅ pack alpha+followers, charge 3x, flee-on-alpha-death | mantener proc (lee bien como lobo) | ✅ proc | **INTEGRAL.** Sin gaps | **P3** |
| **fox** | proc quadruped naranja + orejas | ✅ flank/weave, circle-strafe, 20% dodge, spawn grupal | mantener proc | ✅ proc | **INTEGRAL.** Sin gaps | **P3** |
| **slime** | **gltf** `enemy_slime_green` | ✅ hop + split-on-death (4 mini) | ya asignado | ✅ | **INTEGRAL.** Sin gaps | — |
| **mini_slime** | gltf (slime escalado 0.6) | ✅ hereda hop del slime | ya asignado | ✅ | **INTEGRAL.** Sin gaps | — |
| **king_slime** (boss) | proc SphereMesh + corona | ✅ boss 4-fases, summons, aura, escudo, pools, fury | opcional upgrade `enemies/big/enemy_boss_mushroom_king.gltf` | ✅ mushroom_king importado | Funcional. Upgrade visual opcional (no bloquea demo) | P2 |
| **bird** | proc (SphereMesh + pico) | ✅ neutral aéreo: wander→circling→dive→retreat | `enemies/flying/enemy_pigeon.gltf` | ✅ pigeon importado | Swap a pigeon (lee mejor como ave) | P2 |
| **hawk** | proc flyer marrón | ✅ predador aéreo 10m, grab 2-hit, teleport post-hit | `enemies/flying/enemy_pigeon.gltf` (tint oscuro) o proc | ✅ pigeon importado | Swap opcional. Proc actual funciona | P2 |
| **goat** | proc quadruped + cuernos | ✅ herbívoro neutral, carga única, flee-then-calm | mantener proc | ✅ proc | **INTEGRAL.** Sin gaps | P3 |
| **rat** | proc quadruped pequeño | ✅ pack-threshold (3+ agro), solo-flee, scurry | mantener proc | ✅ proc | **INTEGRAL.** Sin gaps | P3 |
| **snake** | proc `build_snake` (5 segs) | ✅ ambush (idle estático), slither sine, poison DoT | mantener proc | ✅ proc | **INTEGRAL.** `build_snake` SÍ existe. Solo falta `habitat_type` explícito | P3 |
| **turtle** | proc `build_shelled` | ✅ tank, retract-shell 3s (DEF 20), knockback-resist | mantener proc | ✅ proc | **INTEGRAL.** Sin gaps | P3 |
| **wasp** | proc `build_arthropod` + alas | ✅ colonia nest-bound, agro/deagro por nido, sting DoT | opcional `enemies/flying/enemy_armabee.gltf` | ✅ armabee importado | Funcional. Upgrade visual opcional | P3 |
| **scorpion** | proc `build_arthropod` + pinzas/cola | ✅ territorial, abandon-range 15m, scuttle, pinch+sting DoT | mantener proc (no hay gltf escorpión) | ✅ proc | **INTEGRAL.** Falta `habitat_type` explícito | P3 |
| **mimic** | proc (BoxMesh cofre + tapa animada) | ✅ 3-estados DISGUISED→REVEAL→AGGRO, interact [E] | mantener proc (cofre procedural es correcto) | ✅ proc | IA ok. **Gap: spawn-gate no cableado** (5% reemplazo de cofre sub-B, issue #60) | P2 |
| **enemy_basic** | **stub** cubo rojo | ❌ sin IA propia (solo defaults BaseEnemy) | retirar del roster o reasignar gltf | ✅ proc | **NO INTEGRAL.** Placeholder legacy. No incluir en demo Piso 1 | P2 (retiro) |

---

## 2. FIX FIRST — shortlist demo (máximo payoff de ambiente)

Joan nombró explícitamente **golem, bandido humano, lobo**. Los tres ya tienen IA completa → son **cheap wins de solo-modelo** salvo detalles. Orden recomendado:

### 1. bandit_melee + bandit_archer — *swap de modelo* (CHEAP, alto impacto)
- **Problema**: parecen cápsulas, no personas. Rompe la inmersión "humanos en la pradera".
- **Trabajo**: en `_on_enemy_ready()` de cada uno, reemplazar `EnemyModelBuilder.build_humanoid(...)` por carga del gltf:
  - melee → `res://game/assets/art/piso1_pradera/enemies/big/enemy_orc.gltf` o `enemy_tribal.gltf`
  - archer → `res://.../enemies/big/enemy_ninja.gltf` (silueta ágil)
- Conservar el box-arma como attachment en la mano (el modelo gltf no trae arma).
- **IA: NO TOCAR.** 3-ciclo de ataques, strafe, block y kiter ya funcionan.
- **Runtime-safe** ✅ (orc/ninja/tribal/ninja tienen `.import`). No hace falta tocar `_raw/`.

### 2. golem — *swap de modelo* (CHEAP)
- **Problema**: BoxMesh gris no "lee" como golem de piedra dormido.
- **Trabajo**: en `golem.gd:26`, donde hace `build_humanoid(...)`, cargar `enemies/big/enemy_orc.gltf` con material/tint piedra, o exagerar proporciones del proc (width 1.4, brazos largos). La mecánica dormant (squash 1.2x0.5x1.2 → awaken tween 1x1x1) se aplica sobre el nodo modelo, sea proc o gltf.
- **IA: NO TOCAR.** dormant→awaken + 3-ciclo (punch/stomp/rock) ya funcionan.
- **Nota**: hay `enemies/flying/enemy_goleling.gltf` importado, pero es la variante *voladora* pequeña → sirve como mob aparte, no como este golem-roca terrestre.

### 3. wolf — *verificar pack en escena* (NEW BEHAVIOR mínimo / integración)
- **Modelo + IA ya integral** (proc lee bien, pack/alpha/charge implementado). NO necesita modelo nuevo.
- **El único trabajo real es de INTEGRACIÓN**: confirmar que en `floor1_prairie.tscn` los lobos **spawnean en grupo** (≥3) para que la IA de manada/alpha se active. Un lobo solo en escena no muestra el comportamiento "cazan en manada" que Joan quiere ver.
- **Acción**: revisar el spawn/scatter de wolf en la escena del piso. Si están aislados, agruparlos. (Mismo chequeo aplica a **fox**, **rat** y **wasp**: su IA es grupal/colonial y se ve sosa si spawnean solos.)

### Por qué estos 3 primero
- Son los que Joan nombró → validan su pedido directo.
- bandit + golem son **swap de 1-2 líneas sobre IA ya hecha** → ratio esfuerzo/impacto altísimo.
- wolf cuesta casi nada (sin código de mob) y entrega el "feel" de manada que es el wow del ambiente.

---

## 3. Modelos NO runtime-loadable (requieren reimport antes de usar)

Los packs crudos `game/assets/art/_raw/quaternius/` (**Ultimate Monsters**, **Ultimate Modular Men**, **Ultimate Stylized Nature**) **NO tienen archivos `.import`** → Godot no los carga en runtime. Confirmado: cero `.gltf.import` bajo `_raw/`.

Para usar cualquiera de ellos hay que **importarlos a `piso1_pradera/`** (abrir en editor para generar `.import` + atlas de textura).

**Pero NO es necesario para el FIX FIRST**: ya existen equivalentes importados:
- humanoides para bandidos → `enemy_orc / enemy_ninja / enemy_tribal / enemy_monkroose` (✅ importados)
- golem pétreo → `enemy_orc` (✅) o el proc actual
- voladores → `enemy_pigeon / enemy_armabee / enemy_goleling` (✅)
- boss → `enemy_boss_mushroom_king` (✅)

**Solo reimportar `_raw/` si** Joan quiere específicamente los Modular Men (Adventurer/Swat/Farmer) para bandidos "más humanos" que el orc. Es trabajo de pipeline aparte, no bloquea el demo.

**Modelos importados disponibles sin usar aún** (candidatos para más variedad de roster): `enemy_demon`, `enemy_dino`, `enemy_alien`, `enemy_frog`, `enemy_cactoro`, `enemy_mushnub` (+evolved), `enemy_orc_skull`, decos `enemy_bunny_deco` / `enemy_birb_deco`.

---

## Resumen de conteo

- **Integral (modelo aceptable + IA + comportamiento)**: 17/19. De esos, 2 con modelo gltf real (slime, mini_slime) y 15 con proc que "lee" bien (wolf, fox, goat, rat, snake, turtle, scorpion, wasp, king_slime, bird, hawk, mimic, + bandidos/golem cuyo proc funciona pero conviene upgrade).
- **Solo necesitan swap de modelo (cheap, IA intacta)**: golem, bandit_melee, bandit_archer, bird (+ opcionales hawk, wasp, king_slime upgrade).
- **Necesitan trabajo de IA/lógica nuevo**: prácticamente ninguno de mob individual. Pendientes reales:
  - **mimic**: cablear spawn-gate (5% reemplazo de cofre sub-B) — issue #60.
  - **enemy_basic**: retirar del roster (placeholder sin IA).
  - **snake/scorpion**: setear `habitat_type` explícito (1 línea c/u).
  - **Integración de escena** (no código de mob): agrupar spawns de wolf/fox/rat/wasp para que la IA grupal se vea.
- **Primeros 3 a arreglar**: **bandit_melee/archer** (swap a humanoide gltf), **golem** (swap a orc/proc pétreo), **wolf** (verificar spawn en manada en la escena). Los tres explotan IA ya hecha.
