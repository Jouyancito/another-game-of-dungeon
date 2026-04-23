# Spec Fase 1 — Cleric (dept/design, ola 2, 2026-04-18)

> **⚠️ TODO-canon-update (2026-04-23)**: refs a NPCs/lugares chilenos (Tres Cumbres, volcanes Llaima/Villarrica/Osorno, Kutral, Pangui) quedaron **DEPRECATED** por rewrite a **hub planetario multicultural** en `_world_canon.md` v2.0. Las skills y mecánicas (Fe recurso, 3 ramas excepción) **SE MANTIENEN**; solo cambia el framing cultural. No tocar por ahora. Al retomar, alinear con `_world_canon.md` v2.0 y el rewrite futuro de `_class_lore_cleric.md`.

**Leer antes**: `cleric.md` v2.0, `_class_lore_cleric.md` v2.0, `_system.md` v1.0, `balance_v2.md`.
**Estado**: Draft canon — handoff a B (gameplay) y D (art).
**Clase**: Cleric | **ID clase**: `cleric`
**Rama futura**: Sanador (Devoción del Aliento — volcán Llaima) / Buffer (Devoción del Coro — volcán Osorno) / Exorcista (Devoción del Verbo — volcán Villarrica) — excepción canon 3 ramas, desbloqueables lvl 25.

---

## Recurso único — Fe (max 50)

Canon `_system.md §5ter` + `cleric.md §1`:

- Cap 50 (más chico que Rage/Concentración — cada punto Fe pesa más).
- **NO regenera por tiempo**.
- **Genera (coop principal)**:
  - Heal efectivo a aliado: +3
  - Buff a aliado: +2
  - Cleanse a aliado: +5
- **Genera (solo-viable, reducido)**:
  - Heal a sí mismo: +1
  - Buff a sí mismo: +1
  - Ataque básico vs cualquier enemigo: +0.5
- **Plegaria** (skill general lvl 4): canal 3s estacionario, regen +15 Fe, CD 20s, interrumpible.
- **Gasta en**: skills sagradas poderosas (Juicio Sagrado, Égida Divina).
- **MP gasta**: skills básicas (Luz Restauradora, Círculo Sagrado).
- `resource_gen_type = 2` (FE en enum SkillResource).

**Nota diseño**: la generación dual (coop/solo) es intencional — el Cleric en solo puede subsistir pero a ritmo más lento. Es clase diseñada para party. Los kits de Fase 1 son los 4 generales (skills 1-4 del pool canon); la skill 5 Juicio Sagrado (ult) es general también pero gate lvl 20 — queda fuera del set Fase 1 por gate de desbloqueo. Se incluye en spec como referencia para B, pero no es la prioridad inmediata de implementación.

---

## Skills (4 generales — Fase 1)

### 1. `cleric_healing_light` — Luz Restauradora

- **Canon ref**: `cleric.md §3 SKILL 1`
- **Lore**: Pilar de luz dorada sobre el aliado. *"Tremolün"* (sanar en mapudungun). La Machi diría que es el primer aliento que no se corta.
- **Cast type**: INSTANT (heal directo con 0.4s cast implícito en animación)
- **Target type**: SINGLE_ENEMY (rebautizado SINGLE en uso — usa target aliado; DUAL_MODE si B diferencia aliado/enemigo. Fase 1: SINGLE_ENEMY con lógica de targeting aliado)
- **Range**: 20m (ALLY_RANGED)
- **Radius / cone_angle**: 0.0 / 0.0
- **Cost**: 15 MP
- **Fe gen**: +3 aliado / +1 self (via resource_gen_per_target o lógica PlayerSkills)
- **Cooldown**: 1.5s
- **Damage formula**: HEAL
- **Fórmula heal**: `(25 + INT*2) * (1 + level*0.03) * 1.2` (class_mult heal = 1.2)
- **Base damage (valor heal base)**: 25
- **Status effects**: ninguno base. Lvl 5 agrega `regen` 4s. Lvl 15 overheal → `shield` temporal.
- **Tags**: `[holy, heal, single]`

**Schema fields P0/P1 (.tres)**:
```
id = &"cleric_healing_light"
class_id = &"cleric"
display_name = "Luz Restauradora"
description = "Heal directo 20m. Fórmula (25+INT×2)×1.03^nivel×1.2. +3 Fe vs aliado / +1 self. 15 MP. Canon cleric.md §3 SKILL 1."
cast_type = 0          # INSTANT
target_type = 1        # SINGLE_ENEMY (target aliado en dispatch PlayerSkills)
range_m = 20.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 15
resource_type = 3      # MP
cooldown_s = 1.5
damage_formula = 3     # HEAL
base_damage = 25
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 1
max_skill_level = 15
evolution_id = &"cleric_light_of_dawn"
tags = Array[StringName]([&"holy", &"heal", &"single"])
dash_distance_m = 0.0
tick_interval_s = 0.0
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
resource_gen_on_cast = 3    # Fe generada al castear en aliado (B diferencia aliado/self en PlayerSkills)
resource_gen_per_target = 0
resource_gen_type = 2       # FE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **VFX hint**: pilar de luz dorada descendiendo sobre el target (1.0s de vida). Partículas doradas ascendentes del punto de impacto. Si self-heal: pilar más tenue (60% opacidad). Si overheal (Lvl 15): el pilar se convierte en escudo dorado translúcido 3s.
- **Gameplay hook**: la piedra angular del Cleric. Sin esto, el partido no sobrevive. 1.5s CD hace que sea un heal cada golpe si el Cleric gestiona bien. La generación de Fe de +3 por heal a aliado significa que 5 heals = 15 Fe acumulados — suficiente para activar Égida Divina (skill 4). El loop central del Cleric de Fase 1 es: Luz Restauradora spam → acumular Fe → Plegaria para recuperar Fe rápido → Égida en el aliado más presionado. Sinergia con Warrior Tank: el Tank recibe daño constantemente, el Cleric genera Fe constantemente — maquinaria perfecta de sustain party.

---

### 2. `cleric_prayer` — Plegaria

- **Canon ref**: `cleric.md §3 SKILL 2`
- **Lore**: Las runas doradas giran alrededor del Cleric mientras canaliza. *"Ñochi"* (silencio ritual). El Coro del Sínodo dice que la Plegaria es la prueba de que la Fe no depende del ruido.
- **Cast type**: CHANNELED (3s canal interrumpible — se interrumpe si el caster recibe daño o se mueve)
- **Target type**: SELF
- **Range**: 0.0 (self-only)
- **Cost**: 0 MP
- **Fe gen**: +15 al completar 3s / proporcional si se interrumpe (1s = 5 Fe, 2s = 10 Fe)
- **Cooldown**: 20.0s
- **Damage formula**: NONE
- **Status effects**: ninguno base. Lvl 10 agrega shield 30 HP durante el canal.
- **Tags**: `[channel, faith_gen]`

**Schema fields P0/P1 (.tres)**:
```
id = &"cleric_prayer"
class_id = &"cleric"
display_name = "Plegaria"
description = "Canal 3s estacionario. Regen +15 Fe al completar. Interrumpible. 0 MP. CD 20s. Canon cleric.md §3 SKILL 2."
cast_type = 1          # CHANNELED
target_type = 0        # SELF
range_m = 0.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 0
resource_type = 0      # NONE
cooldown_s = 20.0
damage_formula = 0     # NONE
base_damage = 0
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 4
max_skill_level = 15
evolution_id = &""
tags = Array[StringName]([&"channel", &"faith_gen"])
dash_distance_m = 0.0
tick_interval_s = 1.0  # tick cada 1s para regen proporcional en caso de interrupción
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
resource_gen_type = 2   # FE — generación al completar en lógica PlayerSkills canal
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación**: La generación de Fe proporcional por interrupción debe implementarse en el callback de cancelación de canal de PlayerSkills. El tick_interval_s = 1.0 sirve para tracking interno del tiempo canaleado (5 Fe/s acumulados). La restricción de "no moverse" necesita check en `_process` del canal: si `velocity.length() > 0.1`, cancelar.
- **VFX hint**: runas doradas flotando en espiral alrededor del Cleric (velocidad de rotación aumenta hacia el final del canal). Partículas doradas ascendentes. Si se interrumpe: las runas se disuelven con sonido de "ruptura suave". Al completar: burst dorado breve + sonido de campana.
- **Gameplay hook**: el nodo de tensión posicional del Cleric. Pararse quieto 3 segundos en un dungeon con enemigos activos **es una decisión táctica seria**. Sinergia con Égida Divina: poner la Égida en el Warrior para que absorba golpes → el Warrior aguanta → el Cleric canaliza Plegaria a salvo. La gestión de cuándo usar Plegaria define la habilidad del jugador Cleric mucho más que simplemente spamear Luz Restauradora.

---

### 3. `cleric_sacred_circle` — Círculo Sagrado

- **Canon ref**: `cleric.md §3 SKILL 3`
- **Lore**: Las runas del suelo giran lentamente mientras la luz sube. *"Antü"* (sol en mapudungun/aymara) invocado como fuente, no como divinidad.
- **Cast type**: CHANNELED (canal continuo con costo MP/s — caster puede moverse durante el canal pero el círculo está fijo en origen del cast)
- **Target type**: AOE (centrado en caster al activar — 6m radio, SELF-centered AOE)
- **Range**: 0.0 (self-centered)
- **Radius**: 6.0m (AOE_MEDIUM)
- **Cost**: 15 MP al activar + 15 MP/s durante canal (`tick_resource_cost = 15`)
- **Fe gen**: +1 Fe por aliado healeado por tick (via resource_gen_per_target)
- **Cooldown**: 5.0s post-canal
- **Damage formula**: HEAL (para aliados) / MAGIC_V2 (para undead dentro — lógica PlayerSkills diferencia por tipo de target)
- **Fórmula heal/tick**: `(10 + INT*1.5) * (1 + level*0.03)`
- **Fórmula dmg undead/tick**: `magic_v2(6, 0, INT, level, 1.1)` sagrado
- **Base damage**: 10 (heal base, también valor base para daño undead)
- **Status effects**: ninguno base. Lvl 15 aliados dentro +10% resist cap temporal.
- **Tags**: `[holy, heal, aoe, channel]`

**Schema fields P0/P1 (.tres)**:
```
id = &"cleric_sacred_circle"
class_id = &"cleric"
display_name = "Círculo Sagrado"
description = "Canal. Heal AOE 6m tick 0.5s. Daño sagrado a undead en zona. 15 MP activar + 15 MP/s. Canon cleric.md §3 SKILL 3."
cast_type = 1          # CHANNELED
target_type = 2        # AOE (self-centered — range_m = 0, radius_m define zona)
range_m = 0.0
radius_m = 6.0
cone_angle_deg = 0.0
resource_cost = 15
resource_type = 3      # MP (costo inicial)
cooldown_s = 5.0
damage_formula = 3     # HEAL (primario; dmg undead en lógica PlayerSkills secundario)
base_damage = 10
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 8
max_skill_level = 15
evolution_id = &"cleric_eternal_circle"
tags = Array[StringName]([&"holy", &"heal", &"aoe", &"channel"])
dash_distance_m = 0.0
tick_interval_s = 0.5
tick_resource_cost = 8     # ~15 MP/s dividido en ticks 0.5s = 7.5 ≈ 8 MP/tick
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
resource_gen_per_target = 1   # +1 Fe por aliado healeado en el tick (multitarget)
resource_gen_type = 2         # FE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **VFX hint**: círculo de runas doradas que aparecen en el suelo al activar (estático en punto de activación). Partículas doradas ascendentes del interior del círculo. Cuando un undead está dentro: partículas con tinte rojo sagrado impactando el enemy. El círculo persiste hasta que el canal se cancela o el MP se agota.
- **Gameplay hook**: el skill más party-heavy del kit de Fase 1. Si hay 5 aliados en el círculo y el Cleric canaliza 3 ticks, genera 15 Fe instantáneamente (5 aliados × 1 Fe × 3 ticks). Premia la coordinación espacial — si el grupo se agrupa en el círculo durante una ola de undead, el Cleric hace daño Y heal Y genera Fe simultáneamente. El costo MP/s obliga al Cleric a decidir cuánto tiempo canalizar. En solo (sin aliados) el círculo sigue sirviendo contra undead como herramienta de daño.

---

### 4. `cleric_divine_aegis` — Égida Divina

- **Canon ref**: `cleric.md §3 SKILL 4`
- **Lore**: Las placas de luz hexagonales sobre el aliado. Estilo Frieren barrera — la fe como geometría protectora. El Sínodo llama a este skill *"la decisión de elegir a estos"*.
- **Cast type**: INSTANT (0.5s cast en animación)
- **Target type**: SINGLE_ENEMY (target aliado — mismo flag que Luz Restauradora)
- **Range**: 20m (ALLY_RANGED)
- **Cost**: 30 MP + 8 Fe (dual resource: MP primario, Fe secundario)
- **Fe gen**: +2 al aplicar sobre aliado (via resource_gen_on_cast)
- **Cooldown**: 20.0s
- **Damage formula**: NONE (buff defensivo, sin daño)
- **Status effects**: `shield` (50 + INT*3 absorb, 8s duración). También aplica +30% DEF al target — lógica en PlayerSkills como `BUFF_DEF`.
- **Tags**: `[holy, shield, buff]`

**Schema fields P0/P1 (.tres)**:
```
id = &"cleric_divine_aegis"
class_id = &"cleric"
display_name = "Égida Divina"
description = "Buff aliado 8s: +30% DEF + Shield absorb (50+INT×3). 30 MP + 8 Fe. +2 Fe al aplicar. Canon cleric.md §3 SKILL 4."
cast_type = 0          # INSTANT
target_type = 1        # SINGLE_ENEMY (target aliado en dispatch)
range_m = 20.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 30
resource_type = 3      # MP (costo primario)
cooldown_s = 20.0
damage_formula = 0     # NONE
base_damage = 0
status_applied = Array[StringName]([&"shield"])
status_duration_s = 8.0
unlock_level = 12
max_skill_level = 15
evolution_id = &"cleric_seal_of_seven"
tags = Array[StringName]([&"holy", &"shield", &"buff"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 8
secondary_resource_type = 2    # FE (costo secundario)
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 2       # +2 Fe al activar sobre aliado
resource_gen_per_target = 0
resource_gen_type = 2          # FE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación**: el `status_applied = [shield]` indica que debe aplicar el sistema de absorción de daño del target. El valor `50 + INT*3` requiere que B calcule INT del caster al momento del cast y lo pase al status_manager del target. El +30% DEF buff es un multiplicador temporal sobre el `total_def` del target — implementar como `BUFF_DEF_PCT` en el status_manager si existe, o como stat override temporal.
- **VFX hint**: hexágonos de luz dorada aparecen flotando alrededor del target (3-5 hexágonos de distintos tamaños, semi-translúcidos). Duración exacta del buff. Al romperse el shield (al agotarse el absorb): hexágonos se fracturan con destello dorado. Si el buff expira naturalmente: hexágonos se desvanecen suavemente.
- **Gameplay hook**: el seguro de vida táctica del party. La razón por la que el Cleric debe acumular Fe — los 8 Fe de costo hacen que no puedas spamearla. Loop táctico: Luz Restauradora × 3 en aliados (= 9 Fe acumulados) → 1 Égida Divina al aliado más amenazado. El +30% DEF + Shield hace que un Warrior con esto pueda absorber una bestia de daño mientras el resto del grupo posiciona. A Lvl 15, la inmunidad a 1 golpe letal convierte la Égida en el "último seguro" para el jugador que lleva al aliado al borde sin dejarlo morir.

---

## Tabla resumen — fields críticos

| Skill | cast_type | target_type | unlock_level | resource_type | secondary | cooldown_s | damage_formula |
|-------|-----------|-------------|--------------|---------------|-----------|------------|----------------|
| cleric_healing_light | 0 INSTANT | 1 SINGLE | 1 | 3 MP | 0 NONE | 1.5 | 3 HEAL |
| cleric_prayer | 1 CHANNELED | 0 SELF | 4 | 0 NONE | 0 NONE | 20.0 | 0 NONE |
| cleric_sacred_circle | 1 CHANNELED | 2 AOE | 8 | 3 MP | 0 NONE | 5.0 | 3 HEAL |
| cleric_divine_aegis | 0 INSTANT | 1 SINGLE | 12 | 3 MP | 2 FE | 20.0 | 0 NONE |

---

## Nota — Skill 5 (Juicio Sagrado, ult, gate lvl 20)

Fuera de scope Fase 1 (gate lvl 20 es post-Fase1), pero referenciada aquí para que B la incluya en el `.tres` a tiempo:

- `id = "cleric_holy_judgment"` | `unlock_level = 20` | `target_type = 6` DUAL_MODE
- Costo: 80 MP + 25 Fe | CD: 120s | cast_type: 1 CHANNELED (2s pose visible)
- DUAL_MODE: aliado caído en target → revive 50% HP / enemigo en target → AoE dmg sagrado 8m
- `damage_formula = 2` MAGIC_V2 | `base_damage = 150`
- No incluir en `_equip_default_skills()` hasta que la clase alcance lvl 20.

---

## Handoff

**B (gameplay)**:
- Crear 4 `.tres` en `game/shared/skills/resources/cleric/` siguiendo schema de este doc.
- Wire en `cleric.gd::_equip_default_skills()`.
- Plegaria: canal interrumpible por movimiento O por recibir daño. `tick_interval_s = 1.0` — cada tick acumula 5 Fe. Al completar 3 ticks: emit señal `canal_completado` con total Fe = 15.
- Égida Divina: lógica de doble-check recurso antes de cast — `MP >= 30 AND Fe >= 8`. Si cualquiera falla, el skill no activa. El +30% DEF es multiplicador temporal sobre stats del target; implementar como `BuffEffect` temporal en `StatusManager` del aliado.
- Círculo Sagrado: distinguir aliado vs undead en `_process` del canal — `Area3D` del círculo detecta layer 2 (player/aliados) y layer 3 (enemies). A aliados: HEAL. A undead: MAGIC_V2 sagrado. Generar +1 Fe por aliado healeado en cada tick.
- QA: `test_cleric_skills_phase1.gd` — cobertura: Fe acumula correctamente por heal a aliado vs self, Plegaria interrumpida vs completada, costo doble de Égida, shield absorbiendo daño correcto.

**D (art)**:
- 4 SVG icons en `game/assets/ui/icons/skills/cleric/`: `healing_light.svg`, `prayer.svg`, `sacred_circle.svg`, `divine_aegis.svg`.
- Paleta: blanco limpio + dorado apagado (cobre oxidado) como base. Acento azul volcánico (Sanador), rojo copihue (Buffer), naranja llama (Exorcista) — para generales usar paleta base sin acento de rama.
- VFX: pilares de luz, runas en suelo, hexágonos dorados. Referencia `_class_lore_cleric.md §4` + `cleric.md §8`.

**QA**:
- `test_cleric_skills_phase1.gd`.
- Casos clave: generación Fe por aliado vs self, canal Plegaria interrupted vs complete, dual resource Égida, Círculo heal vs dmg undead.

---

*Spec Fase 1 Cleric — dept/design C, 2026-04-18. 3 ramas excepción canon `_system.md §7`.*
