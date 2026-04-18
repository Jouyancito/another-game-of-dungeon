class_name SkillResource extends Resource

# Datos puros de una skill — se serializa como .tres.
# La lógica vive en PlayerSkills._execute (dispatch por cast_type + flags).
# Refactor futuro a SkillBase jerarquía cuando Mage/Necro traigan estado complejo.

enum CastType { INSTANT, CHANNELED, TOGGLE, PASSIVE, CHARGED }
enum TargetType { SELF, SINGLE_ENEMY, AOE, CONE, LINE, SUMMON, DUAL_MODE }
enum ResourceCostType { NONE, RAGE, FE, MP, COMBO, CONCENTRACION, VIDA }
enum DamageFormulaType { NONE, PHYSICAL_V2, MAGIC_V2, HEAL, TRUE_DAMAGE }
enum HpCostType { NONE, FIXED, PERCENT_MAX, DRAIN_PER_SECOND }

# ── Identidad ───────────────────────────────────────────────────────────────
@export var id: StringName = ""
@export var class_id: StringName = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# ── Tipo de cast + targeting ────────────────────────────────────────────────
@export var cast_type: CastType = CastType.INSTANT
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var range_m: float = 5.0
@export var radius_m: float = 0.0
@export var cone_angle_deg: float = 0.0

# ── Costo recurso primario ──────────────────────────────────────────────────
@export var resource_cost: int = 0
@export var resource_type: ResourceCostType = ResourceCostType.NONE

# ── G1: Costo recurso secundario (MP + Rage, MP + Fe, etc) ──────────────────
@export var secondary_resource_cost: int = 0
@export var secondary_resource_type: ResourceCostType = ResourceCostType.NONE

# ── G3: Costo en HP (Necromancer pacts, sacrifice skills) ───────────────────
@export var hp_cost_type: HpCostType = HpCostType.NONE
@export var hp_cost_value: float = 0.0  # FIXED: pts HP, PERCENT_MAX: 0.10 = 10%, DRAIN_PER_SECOND: pts/s

# ── Cooldown + damage ───────────────────────────────────────────────────────
@export var cooldown_s: float = 0.0
@export var damage_formula: DamageFormulaType = DamageFormulaType.NONE
@export var base_damage: int = 0

# ── Status effects aplicados (canon _status_effects.md) ─────────────────────
@export var status_applied: Array[StringName] = []
@export var status_duration_s: float = 0.0

# ── G2: Generación de recurso (reemplaza hardcoded gen en player.gd) ────────
# on_hit: gen por cada target impactado (tick one-shot)
# on_cast: gen al iniciar cast (Fe pre-heal Cleric)
# per_target: gen × # targets afectados (Cleric mass heal +3 Fe/aliado)
# Nota: reactive parries usan on_cast cuando try_trigger_reactive triunfa.
@export var resource_gen_on_hit: int = 0
@export var resource_gen_on_cast: int = 0
@export var resource_gen_per_target: int = 0
@export var resource_gen_type: ResourceCostType = ResourceCostType.NONE

# ── Progresión ──────────────────────────────────────────────────────────────
@export var unlock_level: int = 1
@export var max_skill_level: int = 15
@export var evolution_id: StringName = ""
@export var tags: Array[StringName] = []

# ── DASH (cast_type INSTANT + mobility) ─────────────────────────────────────
@export var dash_distance_m: float = 0.0

# ── TOGGLE / CHANNELED (aura o canal recurrente) ────────────────────────────
@export var tick_interval_s: float = 0.0
@export var tick_resource_cost: int = 0

# ── REACTIVE (ventana parry/dodge) ──────────────────────────────────────────
@export var reactive_window_s: float = 0.0
@export var reflect_ratio: float = 0.0
@export var reactive_rage_on_success: int = 0  # DEPRECATED — usa resource_gen_on_cast + resource_gen_type en path reactive

# ── Aura / multi-target ─────────────────────────────────────────────────────
@export var ally_damage_bonus_pct: float = 0.0

# ── G4: Combo Points variable (Danzante finishers) ──────────────────────────
# combo_consume_all: finisher consume todos los combo points del ClassResource.
# combo_damage_multipliers: indexado por # de combo points (1pt→[0], 5pt→[4]).
# Ej Danzante canon: [1.0, 1.4, 1.8, 2.4, 3.0] para 1..5 pts.
@export var combo_consume_all: bool = false
@export var combo_damage_multipliers: PackedFloat32Array = PackedFloat32Array()

# ── G6: Charge scaling (Archer Flecha Cargada) ──────────────────────────────
# charge_max_seconds > 0 habilita modo charge (INSTANT hold-to-charge).
# charge_damage_multiplier_max: mult aplicado al full charge (1.0 si no se carga).
@export var charge_max_seconds: float = 0.0
@export var charge_damage_multiplier_max: float = 1.0

# ── G9: Invulnerability frames (Danzante dashes) ────────────────────────────
@export var invul_duration_s: float = 0.0

# ── G10: Summon (Necromancer Esqueleto Defensor, etc) ───────────────────────
# Si summon_data != null, el skill invoca la escena con las fórmulas del SummonResource.
@export var summon_data: Resource = null  # SummonResource — typed Resource para evitar ciclo class_name

# ── G11: Quest-gated unlock (13 ascendencia skills canon _system.md §5bis) ──
# quest_gate == "" → skill disponible. Si != "" → QuestSystem.is_completed(quest_gate) gate.
@export var quest_gate: StringName = ""

# ── DUAL_MODE (G7) ──────────────────────────────────────────────────────────
# Skills con target_type = DUAL_MODE se comportan según target en crosshair:
# ally → ability_a (ej heal), enemy → ability_b (ej smite).
# NO extiende schema — el dispatch vive en PlayerSkills._execute_dual_mode con
# handler específico por skill id. Pattern documentado acá para reference.
