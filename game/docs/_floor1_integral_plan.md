# Plan de Construcción Integral — Piso 1 Pradera (Alpha)

> **Filtro activo**: ¿esto sale en el video de 10 min del demo?
> **Norte**: que el piso 1 se sienta VIVO en cámara, sin inventar los otros pisos.
> **Canon de piso**: Pradera familiar, típica de RPG. Sin distorsión, sin mecánicas extrañas. Es la zona de inicio.

---

## Las 7 capas del bioma — estado actual vs. objetivo

| Capa | Estado | Target alfa |
|------|--------|-------------|
| 1. Terrain | Claro central con escena base. Sin grieta/cueva ni colinas. | Afloramientos de roca + 1 grieta-cueva + colina suave |
| 2. Flora | Assets clover/mushroom/flowers/grass importados pero SIN COMMITEAR. Sin reglas de hábitat. | Colocarlos por hábitat (húmedo/sol). Juncos en borde de agua. Hierba Silvestre cosechable |
| 3. Fauna | Slime, mini_slime, wolf, bird, hawk, fox, rat, wasp, turtle, snake, scorpion, goat, bandit. Colocados a mano, sin `habitat_type`. Fauna ambiental: cero. | Fauna ambiental (mariposas/luciérnagas/conejo), 2-3 mobs nuevos con nicho ecológico, `habitat_type` en BaseEnemy |
| 4. Hazard | Ninguno | **Sin hazard (canon — zona inicial)**. N/A para alfa. |
| 5. Recurso exclusivo | No hay recurso de bioma único | "Hierba Silvestre" (1 hongo especial cosechable, ingrediente de poción básica) |
| 6. Boss + señalización | `enemy_boss_mushroom_king.gltf` importado. Sin escena boss ni beacon. | Escena boss Mushroom King + beacon luz verde-pálida + SFX hum distante |
| 7. Post-boss | No existe `WorldState`. | Post-alfa: raid de slimes reforzados con `WorldState.has_key('defeated_floor1_boss')` |

---

## Inventario real — lo que YA existe (no duplicar)

### Mobs implementados (.gd + .tscn)
slime, mini_slime, wolf (pack + alpha + charge), bird, hawk, fox, goat, rat, snake, turtle, wasp, scorpion, golem, bandit_melee, bandit_archer, mimic, king_slime, enemy_basic.

> CLAUDE.md dice "15+ enemies" — hay más que eso ya implementado.

### Loot Tables
Tablas listas en `loot_table.gd` incluyendo: spider, rabbit, bandit_leader, rey_slime, y todas las mencionadas arriba.

### Assets 3D importados en `game/assets/art/piso1_pradera/`
- **Enemies**: slime green/pink/spiky, orc/orc_skull/ninja/frog/demon/dino/alien (big), boss `mushroom_king`
- **Deco**: bunny_deco, birb_deco
- **Vegetación** (SIN COMMITEAR — visible en git status): clover, mushroom, flowers, grass common, birch/maple trees, bush
- **Terrain**: pebbles, rocks
- **Props**: water/, outpost_extras/ (fence/cart/banner/chimney), VFX (fire/flame/magic/muzzle/light)
- **Enemies**: `enemy_frog.gltf` ✅ importado

### Framework
- BaseEnemy con SubTier/AggressionType/status/loot/knockback (GAP: falta `habitat_type`)
- `LootTable` con TC por `enemy_type` (chance + pool_pick + guaranteed)
- Patrón wolf: pack + alpha + charge (reutilizable)
- Patrón slime: hop + split on death (reutilizable)
- `EnemyModelBuilder.build_quadruped()` ya usado por wolf/fox

---

## LOTE ALFA — Priorizado por impacto en cámara

### TIER 1 — Máximo impacto visual (hacer primero)

#### 1. Vegetación por hábitat: hongos + tréboles + flores + juncos [ALFA-YA → commitear + colocar]

**Estado:** assets en disco, sin commitear, sin regla de colocación.

**Trabajo:**
- Commitear `game/assets/art/piso1_pradera/vegetation/clover/`, `/common/`, `/mushroom/`
- Aplicar reglas de hábitat al colocar en `floor1_prairie.tscn`:
  - Hongos → borde de agua + bajo árboles (húmedo/sombra)
  - Trébol/flores → claro abierto soleado
  - Pasto (common) → campo general en MultiMeshInstance3D
  - Juncos → exactamente en el borde de la poza
- **Un** hongo especial con `Area3D` + interact → da `material_hierba_silvestre` (recurso de bioma)
- Colisión: NINGUNA en toda esta capa. `MultiMeshInstance3D` denso para pasto/trébol.
- Escala: hongo ~0.15m, trébol ~0.05m, flor ~0.20m, junco ~0.80m — validar vs cápsula 1.8m

**Assets:** clover/mushroom/flowers/grass ✅ ya en disco. Juncos: buscar en `vegetation/common/` primero; si no hay, Kenney "Nature Kit" (CC0).

**Impacto en video:** ★★★ — primer plano de cámara ya muestra el campo vivo.

---

#### 2. Agua: poza + arroyo en el claro central [ALFA-YA]

**Estado:** props `water/` importados. Sin integración ni shader.

**Trabajo:**
- Diseñar layout del caudal: grieta en afloramiento de roca → cauce corto → poza central
- Colocar props water en `floor1_prairie.tscn` siguiendo el cauce
- Shader agua toon: `ShaderMaterial` con leve transparencia + normales animadas + color desaturado (no plano opaco). Normal map: procedural en shader o descargar de ambientCG/Poly Haven (CC0).
- Zona de agua: cosmética, atravesable. Sin hazard ni slowdown (piso 1, canon).
- `Area3D` de borde: spawn anchor para fauna ambiental con `habitat_type = "water_edge"`

**Assets:** props water ✅. Shader: escribir (sin descarga necesaria) o normal map CC0.

**Impacto en video:** ★★★ — ancla ecológica. Justifica hongos, luciérnagas, slimes alrededor.

---

#### 3. Fauna ambiental: mariposas + luciérnagas + conejo deco [ALFA-YA]

**Estado:** `bunny_deco` asset ✅. Mariposa/luciérnaga: no hay asset todavía.

**Trabajo por tipo:**

| Criatura | Hábitat | Movimiento | HP | Grupo | Drop |
|----------|---------|------------|-----|-------|------|
| Mariposa | Cerca de flores, claro soleado | Flotación errática (noise en `_process`), círculo lento | Sin HP — indestructible | `ambient` | Ninguno |
| Luciérnaga | Borde de agua, sombra | Drift lento + `OmniLight3D` pulsante (energy 0.1-0.3) | Sin HP — indestructible | `ambient` | Ninguno |
| Conejo deco | Campo abierto | Hops + freeze. Huye a radio 4m del player (flee = opuesto) | 1 HP | `ambient` | Tabla `rabbit` ya existe (`material_rabbit_pelt` chance 0.15) |

> Mariposa/luciérnaga: NO usar `CharacterBody3D`. Usar `Node3D` + `AnimationPlayer` (mariposa con mesh sprite) o `GPUParticles3D` (luciérnaga con glow). Cero física, cero navmesh.

**Assets:** bunny_deco ✅. Mariposa: GPUParticles3D propio (cero descarga) o Quaternius "Animated Animals" (CC0). Luciérnaga: partícula con `OmniLight3D`.

**Impacto en video:** ★★★ — hace que el primer pan de cámara grite "mundo vivo" antes de disparar un tiro.

---

#### 4. Beacon del boss Mushroom King — señalización ambiental [ALFA-YA]

**Estado:** `enemy_boss_mushroom_king.gltf` ✅ importado. Sin escena boss ni señalización.

**Trabajo:**
- Crear `game/scenes/enemy/mushroom_king.tscn` (CharacterBody3D + el gltf + health 700 — escalado piso 1 para alfa demo)
- En `floor1_prairie.tscn`: área del boss con claro de boss dedicado
- Beacon visual: `OmniLight3D` color #90FF90, energy 0.3, range 20 → visible desde el claro central
- Beacon sonoro: `AudioStreamPlayer3D` con loop de hum bajo, `max_db` sube al acercarse (unit_size alto)
- Landmark visual: roca grande / seta gigante en la pared del boss room (usa asset de rocks/pebbles)

**Sin minimap marker en alfa** — la señal ambiental es más inmersiva.

**Assets:** mushroom_king ✅, pebbles/rocks ✅. OmniLight + AudioStreamPlayer son nodos Godot nativos, cero descarga.

**Impacto en video:** ★★★ — el clímax del video de 10 min necesita un boss legible con llegada dramática.

---

### TIER 2 — Profundidad de fauna hostil [ALFA-NICE]

> Estos cierran nichos ecológicos vacíos usando assets ya importados. El piso tiene mobs suficientes para el demo — estos son el segundo lote si hay tiempo.

#### 5. Rana de estanque [ALFA-NICE]

**Asset:** `enemy_frog.gltf` ✅ ya importado.

**Lógica integral:**
- `habitat_type = "water_edge"`, SubTier A, AggressionType NEUTRAL (como goat — solo agrede si provoca)
- IA: idle junto a la poza → provocar activa lengua-latigazo a 3m (override `perform_attack`) o salto-embestida (patrón hop de slime reutilizable)
- Stats piso 1: HP 80, dmg 8, mass 0.6, knockback_resistance 0.3
- Drop: tabla nueva `frog` → gold 1-3, `material_frog_leg` chance 0.10, `material_venom_sac` 0.04
- Muerte: tween simple + SFX splash si está sobre agua

**Trabajo:** `frog.gd` + `frog.tscn` + tabla en `loot_table.gd`.

---

#### 6. Jabalí / bestia de campo [ALFA-NICE]

**Asset:** `EnemyModelBuilder.build_quadruped()` ✅ ya usado por wolf/fox.

**Lógica integral:**
- `habitat_type = "open_field"`, SubTier B (depredador territorial), AGGRESSIVE pero territorial
- IA: patrulla radio fijo → al ver al player, carga frontal con knockback alto. NO persigue infinito (territorial). Solitario o en par.
- Stats piso 1: HP 120, dmg 12, mass 2.5, knockback_resistance 0.8
- Su carga aplica `stun` 0.5s al impactar
- Drop: tabla nueva `jabali` → gold 3-8, `material_leather` 0.15, `material_tusk` 0.08

**Trabajo:** `jabali.gd` + `jabali.tscn` + tabla.

---

#### 7. Enjambre de avispas — integración [ALFA-NICE]

**Estado:** `wasp.gd` + tabla `wasp` YA EXISTEN. Solo falta integración al piso con comportamiento de enjambre.

**Lógica a agregar:**
- `habitat_type = "aerial"`
- Lógica de enjambre: provocar una avisa alerta a las demás cercanas (radio 8m). Patrón wolf-alpha adaptado: si `is_alpha_wasp` recibe daño, llama a `_alert_swarm()`
- Muerte del alfa dispersa al enjambre (flee)

**Trabajo:** modificar `wasp.gd` para agregar lógica de enjambre + colocar en el piso con `habitat_type`.

---

### TIER 3 — Terreno / geología [ALFA-NICE]

#### 8. Afloramientos de roca + grieta-cueva + colina suave [ALFA-NICE]

**Assets:** pebbles ✅, props rocks ✅ ya importados (en git status).

**Trabajo:**
- Commitear `game/assets/art/piso1_pradera/terrain/pebbles/` y `props/outpost_extras/`
- Layout en `floor1_prairie.tscn`:
  - Afloramiento de roca grande (con colisión `StaticBody3D` layer 1) → landmark + nacimiento del arroyo
  - Grieta-cueva: entrada pequeña en la roca (spawn anchor para slimes + hongos con `habitat_type = "cave"`)
  - Colina suave transitable: sin pendiente que trunque al player a 5m/s
- Todos los rocks/pebbles grandes: `StaticBody3D` layer 1. Pebbles decorativos pequeños: `MeshInstance3D` sin colisión.

---

### POST-ALFA — No tocar en alfa

#### A. WorldState / world-keys + raids [POST-ALFA]

Matar al boss de piso 1 activa `WorldState.add_key('defeated_floor1_boss')`. En runs futuros: 15% chance de raid de slimes reforzados al cargar el piso.

**Bloqueado por:** save system robusto necesita estar probado primero. `WorldState` autoload no existe aún.

---

#### B. Generación procedural de rooms [POST-ALFA]

Room selection estilo Hades: 3-5 prefabs por tipo (combat_small, combat_large, loot_room, boss_room), seleccionados por bucket ponderado por profundidad.

**Bloqueado por:** necesita NavMesh dinámico + conectividad validada. Para el video de 10 min el nivel hardcoded alcanza.

---

#### C. Boss drop como material gate al piso 2 [POST-ALFA]

El boss de piso 1 dropea "Trofeo del Guardián" → ingrediente necesario para craftear equipo de piso 2. El lock es por recurso, no narrativo (principio Valheim).

**Bloqueado por:** piso 2 no existe aún.

---

## Tabla resumen — primer lote ordenado por impacto

| # | Elemento | Categoria | Asset disponible | Trabajo pendiente | Alfa-prioridad | Impacto video |
|---|----------|-----------|-----------------|-------------------|----------------|---------------|
| 1 | Vegetación por hábitat | C | clover/mushroom/flowers ✅ (sin commit) | Commit + colocar con reglas | ALFA-YA | ★★★ |
| 2 | Poza + arroyo | D | props water ✅ | Integrar + shader agua | ALFA-YA | ★★★ |
| 3 | Fauna ambiental (conejo/mariposa/luciérnaga) | A | bunny_deco ✅ / resto a hacer | Comportamiento + 1 descarga opcional (mariposa) | ALFA-YA | ★★★ |
| 4 | Beacon boss Mushroom King | E+boss | mushroom_king ✅ | Escena boss + OmniLight + AudioStreamPlayer3D | ALFA-YA | ★★★ |
| 5 | Rana de estanque | B | enemy_frog ✅ | frog.gd/.tscn + tabla | ALFA-NICE | ★★ |
| 6 | Jabalí de campo | B | build_quadruped ✅ | jabali.gd/.tscn + tabla | ALFA-NICE | ★★ |
| 7 | Enjambre de avispas | B | wasp.gd ✅ | Lógica enjambre + colocar en piso | ALFA-NICE | ★★ |
| 8 | Rocas/grieta-cueva/colina | E | pebbles/rocks ✅ (sin commit) | Commit + layout + colisión | ALFA-NICE | ★★ |
| — | WorldState + raids | sistema | no existe | save system primero | POST-ALFA | — |
| — | Procedural rooms | sistema | no existe | NavMesh dinámico | POST-ALFA | — |
| — | Boss material gate | diseño | no existe | piso 2 primero | POST-ALFA | — |

---

## Assets a descargar (solo lo que falta)

Casi todo está en disco. Lo realmente faltante:

| Asset | Uso | Fuente | Costo |
|-------|-----|--------|-------|
| Mariposa animada | Fauna ambiental | GPUParticles3D propio (recomendado, cero descarga) o Quaternius "Animated Animals" (CC0) | 0 o libre |
| Luciérnaga | Fauna ambiental | GPUParticles3D + OmniLight pulsante (cero descarga, recomendado) | 0 |
| Juncos / cattails | Borde de agua | Buscar en `vegetation/common/` primero; si no: Kenney "Nature Kit" (CC0) | 0 |
| Normal map agua (opcional) | Shader agua toon | ambientCG / Poly Haven (CC0) o normales procedurales en shader | 0 |

**Todo lo demás** (slimes, frog, orc, mushroom_king, deco, árboles, rocas, props water): YA importado, no descargar.

---

## Próximos pasos concretos (en orden de impacto-video)

1. Commitear vegetación nueva ya en disco (clover/mushroom/flowers/pebbles/outpost_extras)
2. Colocar agua + vegetación con regla de hábitat en el claro central
3. Agregar `@export var habitat_type: String = "open_field"` a `base_enemy.gd`
4. Fauna ambiental: conejo deco + mariposas con GPUParticles3D
5. Beacon boss Mushroom King (escena + luz + SFX)
6. [si hay tiempo] Rana + jabalí + enjambre de avispas

---

## Archivos relevantes (rutas absolutas)

- `game/scenes/enemy/base_enemy.gd` — GAP: falta `habitat_type`
- `game/shared/systems/loot_table.gd` — TC por `enemy_type`
- `game/scenes/enemy/wolf.gd` — patrón pack/alpha/charge reutilizable
- `game/scenes/enemy/slime.gd` — patrón hop + split reutilizable
- `game/scenes/enemy/wasp.gd` — ya existe, solo falta lógica de enjambre
- `game/scenes/levels/floor1_prairie.tscn` — 67 nodos, sin agua ni hábitat
- `game/assets/art/piso1_pradera/` — assets importados (ver inventario arriba)
- `game/docs/_inserccion_integral.md` — checklist completo por tipo de elemento

*Documento creado 2026-06-05.*
