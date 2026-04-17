# Skills Framework Audit — Fase 0 Schema vs Canon 64 Skills

**Versión**: 1.0
**Fecha**: 2026-04-17
**Estado**: Audit Fase 0 — gaps detectados entre schema `SkillResource` y canon skills v2.0.
**Depende**: `_system.md`, `_status_effects.md`, los 6 per-class docs, `balance_v2.md`.
**Audiencia**: dept Gameplay (B — implementar fixes de schema), dept Design (C — este doc).

---

## §1. Scope audit

Verificación del framework actual (`game/shared/skills/`) contra las **64 skills canon** documentadas en los 6 per-class docs + `_system.md`.

**Archivos framework actuales**:
- `skill_resource.gd` — Resource data-driven (schema SkillResource)
- `class_resource.gd` — Recurso único por clase (Rage/Fe/Combo/Concentración/Vida)
- `skill_definitions.gd` — AutoLoad SkillDB (registry + loader .tres)
- `resources/warrior/shield_bash.tres` — único stub existente

**Estado de cobertura**: **1/64 skills** tiene stub (shield_bash Warrior). Framework base OK, pero schema tiene **gaps mecánicos** que deben cerrarse antes de escalar a 64 stubs.

---

## §2. Gaps detectados en SkillResource schema

### CRÍTICOS (bloquean stubs correctos)

#### G1. Resource dual cost (MP + Rage / MP + Fe / MP + Combo)
Canon ejemplos: Warrior Forma del Titán cuesta `60 MP + 50 Rage`. Cleric Juicio Sagrado `80 MP + 25 Fe`. Mage Supernova `70 MP + 30 Conc`. Necromancer Rito del Abismo `80 MP + -10% HP current`.

**Schema actual**: 1 `resource_cost` + 1 `resource_type`. **Solo modela un recurso.**

**Fix propuesto**:
```gdscript
# Reemplazar resource_cost + resource_type por:
@export var mp_cost: int = 0
@export var secondary_cost: int = 0
@export var secondary_resource_type: ResourceCostType = ResourceCostType.NONE
```

#### G2. Resource generation per-skill
Canon: Warrior Puño `+5 Rage gen/hit`, Bloqueo Perfecto `+10 Rage/parry exitoso`. Archer headshot `+10 Conc`, full charge `+15 Conc`. Cleric Luz Restauradora `+3 Fe/aliado curado`. Danzante Corte Fugaz `+1 Combo/hit`, `+2 desde stealth`.

**Schema actual**: solo modela costo, NO generación.

**Fix**:
```gdscript
@export var resource_gen_on_hit: int = 0
@export var resource_gen_on_crit: int = 0
@export var resource_gen_on_kill: int = 0
@export var resource_gen_bonus_conditional: Dictionary = {}  # ej {"headshot": 10, "from_stealth": 2}
```

#### G3. HP cost / HP max drain (Necromancer)
Canon: Llamar Esqueleto `-15% HP max mientras invocación viva`. Pacto de Invocación `-10% HP current`. Sangre que Llama Sangre `drain 2% HP/s self durante canal`. El Pacto de la Marchita `-5% HP max 15s`.

**Schema actual**: enum ResourceCostType.VIDA existe pero **no modela** diferencia entre HP current / HP max / HP drain/s.

**Fix**:
```gdscript
@export var hp_current_cost_pct: float = 0.0     # % HP actual al cast
@export var hp_max_drain_pct: float = 0.0        # % HP max reservado mientras efecto activo
@export var hp_drain_per_sec_pct: float = 0.0    # drain continuo durante canal
```

#### G4. Combo Points variable cost + damage multiplier
Canon Danzante Flor de Sangre / Lluvia de Acero: gasta 1-5 combo, damage mult = 1.0× / 1.8× / 3.0× según gastado.

**Schema actual**: `resource_cost` es int fijo. No modela "gasta TODOS los combo actuales" ni el mult.

**Fix**:
```gdscript
@export var combo_cost_type: int = 0  # 0=fixed, 1=all_available, 2=min_required
@export var combo_damage_mult_table: Array[float] = []  # [1.0, 1.3, 1.8, 2.3, 3.0] para combo 1..5
```

#### G5. Channel tick interval
Canon: Mage Tormenta Arcana `tick cada 0.25s`, Cleric Círculo Sagrado `tick cada 0.5s`, Grito de Guerra `20 MP/5s activo`.

**Schema actual**: `cast_type` = CHANNELED existe, pero no hay `tick_interval_s` ni `tick_damage`.

**Fix**:
```gdscript
@export var channel_tick_interval_s: float = 0.0  # s entre ticks (0 = N/A)
@export var channel_mp_per_sec: int = 0           # MP/s durante canal
@export var channel_max_duration_s: float = 0.0   # cap duración canal (0 = hasta que cancele)
```

### MEDIOS (comportamientos comunes no modelados)

#### G6. Charge scaling
Canon: Archer Flecha Cargada `charge 0→100% escala 1.0× → 3.5×`, max charge 2s.

**Fix**:
```gdscript
@export var is_chargeable: bool = false
@export var charge_max_duration_s: float = 0.0
@export var charge_damage_mult_max: float = 1.0  # 3.5 para Flecha Cargada
@export var charge_effects_at_full: Array[StringName] = []  # ej ["knockback", "pierce_plus_1"]
```

#### G7. Dual-mode pre-cast toggle
Canon: Cleric Juicio Sagrado (Resurrección / Juicio), Necromancer Rito (Marca / Legión), Mage Manipulación (Blink / Empuje / Atracción).

**Fix**:
```gdscript
@export var modes: Array[StringName] = []  # ej ["revive", "damage"] / ["mark", "legion"]
@export var mode_default: StringName = ""
# Cada mode es una skill hija con sus propios valores — o array de sub-resources
```

Alternativa: split cada modo en SkillResource separado con `parent_skill_id`.

#### G8. Reactive window (parry)
Canon: Bloqueo Perfecto `ventana 0.4s tras apretar`, L15 extended 0.8s.

**Fix**:
```gdscript
@export var is_reactive: bool = false
@export var reactive_window_s: float = 0.0  # ventana de activación tras input
```

#### G9. Invul frames
Canon: Voltereta Evasiva `Invul 0.4s`, Paso de Sombra `Invul 0.3s`, Danza de Mil Sombras `Invul 4s durante duración`.

**Fix**:
```gdscript
@export var grants_invul: bool = false
@export var invul_duration_s: float = 0.0
```

#### G10. Summon stats (Necromancer)
Canon Llamar Esqueleto: `HP = 50 + INT*4 + level*5`, `DMG = magic_v2(8, 0, INT, level, 0.8)`, `vel 4 m/s`.

**Fix**:
```gdscript
# Nuevo SummonResource hermano de SkillResource:
class_name SummonResource extends Resource
@export var summon_id: StringName
@export var hp_formula: String = ""  # ej "50 + INT*4 + level*5"
@export var damage_base: int = 0
@export var damage_formula: SkillResource.DamageFormulaType
@export var move_speed_mps: float = 4.0
@export var melee_range_m: float = 1.5
@export var duration_s: float = 0.0  # 0 = persistente hasta muerte
@export var max_active_count: int = 1
```

Y en SkillResource: `@export var summon: SummonResource`

#### G11. Quest-gated unlock
Canon `_system.md §5bis`: 13 skills ocultas requieren **quest completado** además de char lvl 50.

**Fix**:
```gdscript
@export var unlock_quest_id: StringName = ""  # empty = no quest required
@export var unlock_level: int = 1  # char level mínimo (ya existe)
```

#### G12. Self-damage (Berserker)
Canon: Warrior Berserker Skill 1 `+30% DMG extra, cost 2% HP por golpe`. Skill 2 `consume 15% HP actual`.

**Fix**: combinar con G3 (hp_current_cost_pct ya cubre el concepto en activación, pero "por hit" requiere field separado).

```gdscript
@export var hp_cost_per_hit_pct: float = 0.0
```

### MENORES (nice-to-have, no bloquean Fase 0)

#### G13. Rango / AOE shape aliases canon
Canon `_system.md §5sexies`: MELEE_SHORT / MELEE_LONG / AOE_SMALL / AOE_MEDIUM / AOE_LARGE / AOE_HUGE / PROJ_FAST / PROJ_MED / PROJ_SLOW / CONE_CANAL / PULSO_AURA / LINE_PIERCE / SELF_TARGET / ALLY_RANGED.

**Schema actual**: `range_m + radius_m + cone_angle_deg` — OK mecánicamente, pero **perdés el alias canon**. Drift potencial si alguien edita range_m manualmente vs el alias canónico.

**Fix**:
```gdscript
@export var range_alias: StringName = ""  # ej "MELEE_SHORT" — el loader resuelve a values
# range_m/radius_m/cone_angle_deg quedan como override manual si alias no aplica
```

O: tabla central `RangeAliases.gd` con dict `{MELEE_SHORT: {range: 2, cone: 60}, ...}`.

#### G14. Skill evolution gating
Canon: evolución lvl 15 skill + char lvl 50 + ítem raro (drop boss / quest).

**Schema actual**: `evolution_id` existe pero no hay gating condicional explícito.

**Fix**:
```gdscript
@export var evolution_required_skill_level: int = 15
@export var evolution_required_char_level: int = 50
@export var evolution_required_item_id: StringName = ""
```

#### G15. Status generation w/ duration override por nivel
Canon: Freeze L5 → 1.5s, L10 → shatter combo, L15 → +50% dmg trigger. Los status durations escalan con skill level.

**Schema actual**: `status_duration_s` es fijo.

**Fix**:
```gdscript
@export var status_duration_by_skill_level: Array[float] = []  # [1.0, 1.2, 1.5, 2.0, 3.0] para lvl 1-5, etc
```

Alternativa: tabla curve en lugar de 15 valores.

---

## §3. Cobertura por clase — stubs a crear

Con schema actualizado (§2 fixes aplicados), crear stubs `.tres`:

| Clase | Skills | Stubs requeridos |
|-------|--------|-----------------|
| Warrior | 10 | 10 (1 ya existe: shield_bash) |
| Mage | 10 | 10 |
| Archer | 10 | 10 |
| Cleric | 14 | 14 (excepción 3 ramas) |
| Necromancer | 10 | 10 + SummonResource de Esqueleto |
| Danzante | 10 | 10 |
| **Total** | **64** | **64 (63 restantes)** |

**Folder structure propuesta** (ya parcial):
```
game/shared/skills/resources/
├── warrior/
│   ├── puno_guerra.tres
│   ├── embestida.tres
│   ├── grito_guerra.tres
│   ├── bloqueo_perfecto.tres
│   ├── shield_bash.tres  (ya existe — renombrar a escudo_vengador.tres? chequear)
│   ├── ...
├── mage/
├── archer/
├── cleric/
├── necromancer/
├── danzante/
└── _shared/
    └── range_aliases.tres (canon tabla)
```

---

## §4. Validación cross-canon

Chequeos adicionales a correr post-schema-update:

1. **Status IDs coherentes con `_status_effects.md`**: Bleed / Burn / Poison / Plague / Freeze / Stun / Knockback / Silence / Taunt / Slow / Weak / Vulnerable / Fear / Miss_chance / Marked / Regen / Shield / Empower / Haste / Resist_cap_boost / Invul / Cursed / Stealth / Charm. **24 status IDs canon**. Schema `status_applied: Array[StringName]` acepta cualquier string — falta **enum o tabla de validación**.
   - **Fix**: exportar `StatusCatalog.gd` con enum + lookup, validar en SkillDB loader warning si un skill usa ID no registrado.

2. **Class IDs coherentes con lore**: `warrior`, `mage`, `archer`, `cleric`, `necromancer`, `danzante`. Schema `class_id: StringName` — validar que coincida con una de esas 6.

3. **Damage formula coherence**: PHYSICAL_V2 usa STR o DEX según clase. MAGIC_V2 usa INT. HEAL usa INT (Cleric canon). Schema no distingue el stat source — el `_execute` (Fase 0 PlayerSkills) debe resolverlo por class_id. **OK** pero documentar en código.

4. **Evolution items existence**: 18 evolution items mencionados en per-class docs v2.0 (Gauntlet del Titán, Cuerno del Jabalí Blindado, Muralla Divina, Titán Inmortal, Piedra del Rey Montaña, Fragmento de Supernova, Tormenta Perpetua, Prisma Fractal, Colapso Estelar, Tridente Elemental, Pliegue Dimensional, Paso del Viento, Cielo de Agujas, Ráfaga Infinita, Artillería Prototipo, Corte del Hilo, Paso del Vacío, Velo del Olvido, Flor del Loto Carmesí, Tormenta de Agujas, Luz del Alba, Círculo Eterno, Sello de los Siete, Juicio del Cielo, Mano de la Diosa, Liturgia Perfecta, Tajo del Vacío, Capitán Esqueleto, Marchitar del Alma, Rito Prohibido, Plaga Viviente, Comandante de los Caídos). Estos **no existen** en `_mimic.md` / `p1_loot_table.md` como drops canon. **Trabajo pendiente dept Design / Gameplay**: definir drop sources.

---

## §5. Recomendaciones prioridad

**P0 (bloquea Fase 0 stubs correctos)**:
- G1 resource dual cost
- G2 resource generation per-skill
- G3 HP cost variants (Necromancer)
- G4 combo variable cost + mult (Danzante)
- G5 channel tick interval

**P1 (antes de 64 stubs completos)**:
- G6 charge scaling (Archer)
- G7 dual mode (Cleric/Necro/Mage)
- G8 reactive window (Warrior parry)
- G9 invul frames (3 clases)
- G10 SummonResource separado (Necromancer)
- G11 quest-gated unlock

**P2 (post-Fase 0)**:
- G12 self-damage per hit (Berserker)
- G13 range aliases canon
- G14 evolution gating detallado
- G15 status duration por skill level

---

## §6. NO hice (scope C = audit only)

- NO modifiqué `skill_resource.gd` (dept Gameplay B implementa fixes — este doc es **brief para B**).
- NO creé los 63 stubs `.tres` restantes (dept B trabajo de Fase 0).
- NO escribí tests GUT del schema (dept B + QA).
- NO definí drop sources de los 32 evolution items (pendiente cluster design + gameplay).

---

## §7. Handoff para dept Gameplay (B)

**Input de B**: este doc + los 6 per-class skills docs + `_system.md`.

**Output esperado de B**:
1. `skill_resource.gd` actualizado con P0 + P1 fields
2. `SummonResource.gd` nuevo (P1 — G10)
3. `StatusCatalog.gd` nuevo (validación — §4.1)
4. 63 stubs `.tres` con campos completados per-class
5. Tests GUT: `skill_resource_test.gd` valida todos los fields requeridos + lookup SkillDB

**Pending cluster Design (C) + Gameplay (B) sincronizado**:
- Definir drops concretos de 32 evolution items — ¿bosses existentes o nuevos? ¿quest chains?

---

*Audit Fase 0 v1.0 — listo para dept B implementar schema fixes. 15 gaps identificados (P0: 5, P1: 6, P2: 4). Framework base OK, gaps mecánicos conocidos.*
