class_name SummonResource extends Resource

# G10 — Datos puros de una invocación (Necromancer Esqueleto Defensor, etc).
# Referenciado por SkillResource.summon_data. Si skill tiene summon_data != null,
# PlayerSkills._execute instancia la escena al castear, aplica las fórmulas
# de HP/DMG escaladas, y registra en player.active_summons.
#
# Fórmulas se expresan como String y se evalúan vía Expression (Godot 4).
# Vars disponibles en la expresión: INT, STR, DEX, VIT, DEF, level.

@export var summon_id: StringName = ""
@export var display_name: String = ""
@export var hp_formula: String = "50"     # ej "INT*5 + level*10"
@export var dmg_formula: String = "10"    # ej "INT*2 + level*3"
@export var duration_s: float = 30.0      # 0 = persistente hasta muerte
@export var max_active: int = 1           # cap de invocaciones simultáneas
@export var ai_behavior: StringName = &"guard_caster"  # "guard_caster" | "aggressive" | "passive"
@export var summon_scene: PackedScene     # escena a instanciar


## Evalúa una fórmula con contexto de stats del caster.
## Retorna 0.0 si la expresión es inválida.
static func eval_formula(formula: String, caster: Node) -> float:
	if formula.strip_edges() == "":
		return 0.0
	var expr := Expression.new()
	var vars: PackedStringArray = ["INT", "STR", "DEX", "VIT", "DEF", "level"]
	var err: Error = expr.parse(formula, vars)
	if err != OK:
		push_warning("SummonResource.eval_formula: parse error en '%s' — %s" % [formula, expr.get_error_text()])
		return 0.0
	var values: Array = [
		caster.get_effective_stat("int") if caster and caster.has_method("get_effective_stat") else 0,
		caster.get_effective_stat("str") if caster and caster.has_method("get_effective_stat") else 0,
		caster.get_effective_stat("dex") if caster and caster.has_method("get_effective_stat") else 0,
		caster.get_effective_stat("vit") if caster and caster.has_method("get_effective_stat") else 0,
		caster.get_effective_stat("def") if caster and caster.has_method("get_effective_stat") else 0,
		caster.level if caster and "level" in caster else 1,
	]
	var result = expr.execute(values, null, false)
	if expr.has_execute_failed():
		push_warning("SummonResource.eval_formula: exec failed en '%s'" % formula)
		return 0.0
	return float(result)
