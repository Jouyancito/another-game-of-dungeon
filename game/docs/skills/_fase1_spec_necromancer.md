# Spec Fase 1 — Necromancer (dept/design, ola 2, 2026-04-18)

**Leer antes**: `necromancer.md` v2.0, `_class_lore_necromancer.md` v2.0 DARK, `_system.md` v1.0, `balance_v2.md`.
**Estado**: Draft canon — handoff a B (gameplay) y D (art).
**Clase**: Necromancer | **ID clase**: `necromancer`
**Rama futura**: Maldiciones / Creador — desbloqueables lvl 25.
**Tono**: DARK. Canon excepción `_world_canon.md §6`. El framing de cada skill refleja eso — no glorificar, no justificar, describir con precisión el costo real.

---

## Recurso único — Vida como recurso (HP cost)

Canon `_system.md §5ter` + `necromancer.md §1`:

- **Algunas skills cuestan HP directo además de (o en vez de) MP**.
- `hp_cost_type` enum: `NONE(0)`, `FIXED(1)`, `PERCENT_MAX(2)`, `DRAIN_PER_SECOND(3)`.
- Llamar Esqueleto: `-15% HP max` mientras la invocación esté viva. Al morir la invocación el tope recupera. `hp_cost_type = 2 (PERCENT_MAX)`, `hp_cost_value = 0.15`.
- Fantasía visual: **venas negras** en el personaje mientras tiene invocaciones activas. A mayor cantidad de invocaciones, más intensas. Lógica: señal `summon_count_changed(int)` en `BasePlayer` → `necromancer.gd` actualiza shader de venas.
- **MP gasta**: tajos, maldiciones, auras (skills sin HP cost).
- `resource_gen_type = 0` (NONE — el Necromancer NO genera recursos secundarios activamente por hit genérico; la regeneración HP viene del lifesteal de Tajo de Hueso).

---

## Skills (4 generales — Fase 1)

### 1. `necromancer_bone_slash` — Tajo de Hueso

- **Canon ref**: `necromancer.md §3 SKILL 1`
- **Lore**: El shard óseo que vuelve con algo más que el impacto. El brujo paga con su propia sangre, recupera una fracción. Identidad del Pacto: *"pagás con sangre, recuperás con sangre"*.
- **Cast type**: INSTANT (proyectil, animación = CD, 0.5s)
- **Target type**: SINGLE_ENEMY
- **Range**: 20m (PROJ_MED 20 m/s)
- **Cost**: 5 MP
- **HP cost**: ninguno directo (lifesteal pasivo por fórmula)
- **Cooldown**: 0.5s (animación)
- **Damage formula**: MAGIC_V2
- **Base damage**: 14 | **Stat scaling**: INT, class_mult 1.3
- **Lifesteal**: 15% del daño infligido regresa como HP (lógica PlayerSkills post-apply_damage)
- **Status effects**: ninguno base. Lvl 15 aplica `marked` 3s.
- **Tags**: `[magic, projectile, lifesteal, bone]`

**Schema fields P0/P1 (.tres)**:
```
id = &"necromancer_bone_slash"
class_id = &"necromancer"
display_name = "Tajo de Hueso"
description = "Proyectil óseo. MAGIC_V2 base 14 INT×1.3. Lifesteal 15% del daño. 5 MP. Canon necromancer.md §3 SKILL 1."
cast_type = 0          # INSTANT
target_type = 1        # SINGLE_ENEMY
range_m = 20.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 5
resource_type = 3      # MP
cooldown_s = 0.5
damage_formula = 2     # MAGIC_V2
base_damage = 14
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 1
max_skill_level = 15
evolution_id = &"necromancer_void_slash"
tags = Array[StringName]([&"magic", &"projectile", &"lifesteal", &"bone"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0       # NONE — lifesteal positivo, no costo
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0  # NONE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación — lifesteal**: el tag `lifesteal` activa en `PlayerSkills._apply_damage` un callback post-daño: `caster.heal(damage_dealt * 0.15)`. Lvl 10 agrega `+5 MP al kill` — callback adicional en `on_kill`. El lifesteal no dispara el heal del status_manager — es heal directo sobre HP del caster.
- **VFX hint**: shard óseo rotando en el eje de vuelo, trail negro-violeta. Impacto: cruz de hueso de 0.3s sobre el punto de hit. Al lifesteal: partículas rojas volando del punto de impacto de regreso al caster (hilo visual que conecta el daño con la recuperación). Dark pero legible.
- **Gameplay hook**: el spam básico del Necromancer. 5 MP hace que sea económico — el MP del Necromancer se recupera más rápido que se consume. El lifesteal 15% convierte cada hit en una pequeña recuperación HP, que es fundamental porque las invocaciones (skill 2) van a bajar el HP max. El loop de Fase 1: Llamar Esqueleto (-15% HP max) → el esqueleto tankea → Tajo de Hueso spam desde atrás con lifesteal para compensar el tope más bajo. Es la danza del brujo: siempre en el límite, siempre recuperando un poco.

---

### 2. `necromancer_summon_skeleton` — Llamar Esqueleto

- **Canon ref**: `necromancer.md §3 SKILL 2`
- **Lore**: Las manos emergen del suelo (estilo Dark Souls). El círculo de invocación. El brujo no da bienvenida — da instrucciones. *"Arriba. Hoy trabajás para mí."*
- **Cast type**: INSTANT (1.5s cast animación)
- **Target type**: SUMMON
- **Range**: 3m desde el caster (invocación aparece adyacente)
- **Cost**: 35 MP + `-15% HP max` mientras vivo
- **Cooldown**: 12.0s
- **Damage formula**: NONE (el esqueleto tiene su propio dmg calculado por SummonResource)
- **Status effects**: ninguno en el caster. El esqueleto aplica `plague` al golpear (canon Maldiciones rama, pero el esqueleto base ya lleva el tag como mecánica core).
- **Tags**: `[summon, persistent, hp_cost]`
- **Limit**: max 2 invocaciones activas simultáneas (base, sin pasiva Séquito)

**Schema fields P0/P1 (.tres)**:

**Nota**: este skill usa `summon_data: Resource` (campo G10 de SkillResource). Requiere un `SummonResource` separado que B define con las stats escalables del esqueleto. Ver spec de SummonResource abajo.

```
id = &"necromancer_summon_skeleton"
class_id = &"necromancer"
display_name = "Llamar Esqueleto"
description = "Invocación persistente. -15% HP max mientras vivo. Max 2. 35 MP. Cast 1.5s. Canon necromancer.md §3 SKILL 2."
cast_type = 0          # INSTANT (1.5s en animación)
target_type = 6        # SUMMON
range_m = 3.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 35
resource_type = 3      # MP
cooldown_s = 12.0
damage_formula = 0     # NONE — el SummonResource tiene su propio daño
base_damage = 0
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 4
max_skill_level = 15
evolution_id = &"necromancer_skeleton_captain"
tags = Array[StringName]([&"summon", &"persistent", &"hp_cost"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 2       # PERCENT_MAX
hp_cost_value = 0.15   # -15% HP max mientras invocación viva
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

**SummonResource — `skeleton_base.tres`** (spec para B):
```
id = &"skeleton_base"
display_name = "Esqueleto Básico"
hp_formula = "50 + INT*4 + level*5"     # escala con caster INT + level
dmg_formula = "magic_v2(8, 0, INT, level, 0.8)"
speed_ms = 4.0
attack_range_m = 1.5
attack_cd_s = 1.5
max_simultaneous = 2                     # sube a 3 con pasiva Séquito rama Creador
persist_time_idle_s = 60.0               # se disuelve si 60s fuera de combate
hp_cost_percent_max = 0.15               # referencia al campo del SkillResource padre
tags = ["summon", "undead", "bone"]
```

- **VFX hint**: círculo de invocación mágico oscuro-violeta en el suelo (1.5s de formación). Manos emergentes al finalizar el cast. El esqueleto spawna desde el centro del círculo con animación de levantarse. Mientras vivo: venas negras en el personaje del Necromancer intensifican con cada invocación activa (shader param `vein_intensity += 0.5` por summon activo).
- **Gameplay hook**: el corazón del Necromancer. El -15% HP max es el precio que define el kit: con 1 esqueleto activo, el caster tiene 85% de su HP max. Con 2 (máximo Fase 1), tiene 70%. Es arriesgado spamear invocaciones sin gestionar el lifesteal de Tajo de Hueso. El esqueleto es un tanque básico — atrae atención de enemigos (Taunt implícito por proximidad), liberando al Necromancer para castear desde atrás. Lvl 10: al summon si el anterior murió, explota en `AOE_SMALL` 3m — convierte la muerte de invocaciones en un riesgo del enemigo, no solo del Necromancer.

---

### 3. `necromancer_withering_curse` — Maldición Marchita

- **Canon ref**: `necromancer.md §3 SKILL 3`
- **Lore**: Los hilos negros del Necromancer al target. El target muestra venas violetas. No es un ataque — es una sentencia.
- **Cast type**: INSTANT (0.8s cast animación)
- **Target type**: SINGLE_ENEMY
- **Range**: 15m
- **Cost**: 20 MP
- **HP cost**: ninguno directo (Maldición Marchita base no drena HP — eso es upgrade opcional en rama Maldiciones)
- **Cooldown**: 8.0s
- **Damage formula**: MAGIC_V2 (DoT, aplicado por el status `plague`)
- **Fórmula DoT/tick**: `magic_v2(8, 0, INT, level, 1.0)` cada 1s — canon `_status_effects.md §2.1`
- **Base damage**: 8 (valor por tick del DoT)
- **Status effects**: `plague` (DoT + `-15% DEF`) 8s duración. Aplica via `status_applied`.
- **Tags**: `[magic, curse, dot, debuff]`

**Schema fields P0/P1 (.tres)**:
```
id = &"necromancer_withering_curse"
class_id = &"necromancer"
display_name = "Maldición Marchita"
description = "Debuff ranged 15m. Aplica Plague: DoT magic(8,INT,1.0)/s + -15% DEF. 8s duración. 20 MP. Canon necromancer.md §3 SKILL 3."
cast_type = 0          # INSTANT
target_type = 1        # SINGLE_ENEMY
range_m = 15.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 20
resource_type = 3      # MP
cooldown_s = 8.0
damage_formula = 2     # MAGIC_V2
base_damage = 8
status_applied = Array[StringName]([&"plague"])
status_duration_s = 8.0
unlock_level = 8
max_skill_level = 15
evolution_id = &"necromancer_soul_wither"
tags = Array[StringName]([&"magic", &"curse", &"dot", &"debuff"])
dash_distance_m = 0.0
tick_interval_s = 1.0   # plague tick cada 1s
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación — `plague` status**: debe existir en `StatusManager` como status con tick_damage + debuff_def_pct. Canon: `_status_effects.md §2.1`. Los ticks usan `MAGIC_V2` del caster (INT + level). El `-15% DEF` es multiplicador sobre `total_def` del target durante duración. `plague` no stack con refresh (canon `_system.md §5quater`): aplicar sobre plague activo = refresh duración al max.
- **VFX hint**: al impactar — hilo negro visible del Necromancer hasta el target (0.5s de vida). El target desarrolla overlay de venas violetas en su material (shader param `plague_intensity = 1.0`, fade en 8s). Cada tick del DoT: pequeño destello violeta en el target.
- **Gameplay hook**: el opener del combo DPS. La receta de Fase 1: Maldición Marchita → esqueleto golpea con `plague` activo (DEF shred) → Tajo de Hueso con target debilitado. Con Archer en party: Maldición Marchita + Ojo Verdadero = armor shred efectivo ×2 (ver `_synergias.md`). El CD de 8s hace que sea usable en cada encuentro pero no spammeable — el Necromancer tiene que elegir cuándo vale la pena los 20 MP.

---

### 4. `necromancer_rite_of_abyss` — Rito del Abismo

- **Canon ref**: `necromancer.md §3 SKILL 4`
- **Lore**: El círculo arcano gigante bajo el caster. La apertura vertical al abismo. El nombre del skill aparece visible (estilo JJK). La Cofradía lo llama "el Caleuche en miniatura" — y lo dice sin ironía.
- **Cast type**: CHANNELED (2.5s cast nombre visible, DUAL_MODE — toggle pre-cast)
- **Target type**: DUAL_MODE (modo Marca = SINGLE_ENEMY boss/elite; modo Legión = SUMMON mass)
- **Range**: 15m (Marca) / 3m (Legión — invocaciones spawnan alrededor del caster)
- **Cost**: 80 MP + `-10% HP current` al activar
- **Cooldown**: 150.0s
- **Damage formula**: MAGIC_V2 (modo Marca — detonación 20s después)
- **Base damage**: 300 (detonación Marca)
- **Status effects (Marca)**: `vulnerable` 8s a sobrevivientes tras detonación
- **Tags**: `[magic, ultimate, dual_mode]`

**Schema fields P0/P1 (.tres)**:
```
id = &"necromancer_rite_of_abyss"
class_id = &"necromancer"
display_name = "Rito del Abismo"
description = "ULTIMATE DUAL. Marca: boss recibe detonación 20s (MAGIC_V2 300). Legión: 4 esqs + 2 wraiths 20s. 80 MP + -10% HP. Canon necromancer.md §3 SKILL 4."
cast_type = 1          # CHANNELED (2.5s cast + dispatch dual mode)
target_type = 6        # DUAL_MODE — reutilizamos SUMMON enum (6); B diferencia en _execute_dual
range_m = 15.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 80
resource_type = 3      # MP
cooldown_s = 150.0
damage_formula = 2     # MAGIC_V2 (modo Marca)
base_damage = 300
status_applied = Array[StringName]([&"vulnerable"])
status_duration_s = 8.0
unlock_level = 12
max_skill_level = 15
evolution_id = &"necromancer_forbidden_rite"
tags = Array[StringName]([&"magic", &"ultimate", &"dual_mode"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 1       # FIXED — los 10% HP current se calculan al castear y se aplican como fixed dmg al caster
hp_cost_value = 0.0    # 0.0 aquí — el cálculo es dinámico (10% del HP actual en el momento del cast)
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación — HP cost dinámico**: `hp_cost_type = 1 (FIXED)` con `hp_cost_value = 0.0` indica a B que el costo real se calcula en el momento del cast como `current_hp * 0.10`. La lógica queda en `PlayerSkills._execute_channeled` para el Rito: al confirmar el cast (tras los 2.5s), `caster.take_damage(caster.current_hp * 0.10)` directo (no reducible por DEF — es auto-daño del Pacto). Si B prefiere usar `PERCENT_MAX`, ajustar a `hp_cost_type = 2 / hp_cost_value = 0.10` — pero el canon dice "HP *current*", no HP max.
- **Nota implementación — DUAL_MODE**: al pre-activar el skill (antes del cast), el jugador hace toggle con botón secundario para elegir modo. Modo Marca: dispatch `_execute_mark_of_death` — aplica debuff timer 20s al target boss/elite, al expirar dispara `MAGIC_V2(300, 0, INT, level, 1.3)` + aplica `vulnerable` a sobrevivientes en 6m. Modo Legión: dispatch `_execute_legion` — spawn 4 `skeleton_base` + 2 wraith temporales (20s, B define `wraith_temp.tres` como SummonResource efímero).
- **VFX hint**: cast — círculo arcano gigante negro-violeta aparece bajo el caster (escala del tamaño de la sala, no un círculo chico). Apertura vertical que sugiere profundidad. Nombre del skill visible como floating text 2.5s. Modo Marca: una runa roja aparece sobre el target. Modo Legión: los 6 espíritus emergen del círculo secuencialmente con 0.3s delay entre cada uno. El HP drain del caster: un pulso rojo sobre el caster al momento del cast.
- **Gameplay hook**: el definidor de identidad del Necromancer. El costo es enorme (80 MP + 10% HP current) — una decisión real, no un botón de ganar. Modo Marca transforma un boss en un reloj de cuenta regresiva: si el boss llega a 0s sin morir, la explosión de 300 dmg puede ser suficiente para rematar. Modo Legión es mass summon táctica — convierte al Necromancer en un comandante temporario. Los 2 wraiths son más rápidos que los esqueletos y actúan como flanqueadores. El HP drain fuerza al Necromancer a haber gestionado su lifesteal (Tajo de Hueso) durante el combate previo — llegar al Rito con HP bajo es arriesgado.

---

## Tabla resumen — fields críticos

| Skill | cast_type | target_type | unlock_level | resource_type | hp_cost_type | cooldown_s | damage_formula |
|-------|-----------|-------------|--------------|---------------|-------------|------------|----------------|
| necromancer_bone_slash | 0 INSTANT | 1 SINGLE | 1 | 3 MP | 0 NONE | 0.5 | 2 MAGIC_V2 |
| necromancer_summon_skeleton | 0 INSTANT | 6 SUMMON | 4 | 3 MP | 2 PERCENT_MAX 0.15 | 12.0 | 0 NONE |
| necromancer_withering_curse | 0 INSTANT | 1 SINGLE | 8 | 3 MP | 0 NONE | 8.0 | 2 MAGIC_V2 |
| necromancer_rite_of_abyss | 1 CHANNELED | 6 DUAL | 12 | 3 MP | 1 FIXED dynamic | 150.0 | 2 MAGIC_V2 |

---

## Handoff

**B (gameplay)**:
- Crear 4 `.tres` + `skeleton_base.tres` (SummonResource) en `game/shared/skills/resources/necromancer/`.
- Wire en `necromancer.gd::_equip_default_skills()`.
- Lifesteal de Tajo de Hueso: callback `on_damage_dealt(damage: float)` → `caster.heal(damage * 0.15)`.
- HP max reduction por invocación activa: `BaseEnemy.apply_status` ya tiene base para HP modification — B extiende a `BasePlayer` con `hp_max_modifier` stack que se aplica/retira al summon/death del esqueleto.
- Venas negras: señal `summon_active_count_changed(count: int)` → `necromancer.gd` ajusta shader param `vein_intensity = count * 0.5` en el material del player mesh.
- Rito del Abismo dual mode: UI toggle visible antes del cast (highlight del modo activo). Si no hay boss/elite en target al elegir modo Marca: bloquear activación con feedback visual.
- `plague` status: verificar que `_status_effects.md` tiene spec correcta de tick damage + DEF debuff.
- QA: `test_necromancer_skills_phase1.gd`.

**D (art)**:
- 4 SVG icons en `game/assets/ui/icons/skills/necromancer/`: `bone_slash.svg`, `summon_skeleton.svg`, `withering_curse.svg`, `rite_of_abyss.svg`.
- Paleta: negro profundo + púrpura de corteza podrida + rojo sangre seca. Sin dorado. Sin brillante. Ver `_class_lore_necromancer.md §4`.
- VFX: shard óseo trail, círculo de invocación manos emergentes, venas violetas en target, círculo arcano opening.
- Shader venas negras en player: intensidad dinámica por conteo de invocaciones activas.

**QA**:
- `test_necromancer_skills_phase1.gd`.
- Casos clave: HP max baja al summon y recupera al kill del esqueleto, lifesteal heals al caster, plague ticks correcto, Rito HP cost dinámico (10% HP current, no HP max).

---

*Spec Fase 1 Necromancer — dept/design C, 2026-04-18. Canon DARK excepción `_world_canon.md §6`. Framing narrativo oscuro por diseño.*
