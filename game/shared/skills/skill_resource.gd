class_name SkillResource extends Resource

# Datos puros de una skill — se serializa como .tres.
# La lógica vive en PlayerSkills._execute (Fase 0) y futuramente en SkillBase por tipo.

enum CastType { INSTANT, CHANNELED, TOGGLE, PASSIVE }
enum TargetType { SELF, SINGLE_ENEMY, AOE, CONE, LINE, SUMMON }
enum ResourceCostType { NONE, RAGE, FE, MP, COMBO, CONCENTRACION, VIDA }
enum DamageFormulaType { NONE, PHYSICAL_V2, MAGIC_V2, HEAL, TRUE_DAMAGE }

@export var id: StringName = ""
@export var class_id: StringName = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var cast_type: CastType = CastType.INSTANT
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var range_m: float = 5.0
@export var radius_m: float = 0.0
@export var cone_angle_deg: float = 0.0
@export var resource_cost: int = 0
@export var resource_type: ResourceCostType = ResourceCostType.NONE
@export var cooldown_s: float = 0.0
@export var damage_formula: DamageFormulaType = DamageFormulaType.NONE
@export var base_damage: int = 0
@export var status_applied: Array[StringName] = []
@export var status_duration_s: float = 0.0
@export var unlock_level: int = 1
@export var max_skill_level: int = 15
@export var evolution_id: StringName = ""
@export var tags: Array[StringName] = []

# --- Campos por cast_type (opcionales — leídos según aplique) ---

# DASH (cast_type INSTANT + mobility): distancia que el player recorre.
@export var dash_distance_m: float = 0.0

# TOGGLE (aura recurrente): intervalo de tick + costo por tick.
@export var tick_interval_s: float = 0.0
@export var tick_resource_cost: int = 0

# REACTIVE (ventana parry/dodge): duración de ventana + ratio de reflejo.
@export var reactive_window_s: float = 0.0
@export var reflect_ratio: float = 0.0
@export var reactive_rage_on_success: int = 0  # Rage ganado al parry exitoso

# CONE / multi-target: filtro de afectados por aura / cono.
# ally_damage_bonus_pct: aliados en aura reciben +X% DMG (Grito de Guerra).
@export var ally_damage_bonus_pct: float = 0.0
