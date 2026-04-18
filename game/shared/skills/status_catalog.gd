class_name StatusCatalog extends RefCounted

# Validador canónico de status effects según _status_effects.md.
# Uso: StatusCatalog.is_valid(&"stun") → true
#      StatusCatalog.is_implemented(&"stun") → true (Fase 1 stun/bleed/weak)
#
# Se usa desde SkillResource._validate_property (Godot 4 hook) para flag
# temprano si una skill referencia status inexistente en canon. También
# PlayerSkills puede llamar is_implemented antes de apply_status en enemies.

# Canon _status_effects.md §2 — TODOS los status definidos en canon.
const CANON_STATUSES: Array[StringName] = [
	# §2.1 DoT
	&"bleed", &"burn", &"poison", &"plague",
	# §2.2 Control
	&"freeze", &"stun", &"knockback", &"silence", &"taunt",
	# §2.3 Debuff
	&"slow", &"weak", &"vulnerable", &"fear", &"miss_chance", &"marked",
	# §2.4 Buff
	&"regen", &"shield", &"empower", &"haste", &"resist_cap_boost", &"invul",
	# §2.5 Especiales
	&"cursed", &"stealth", &"charm",
]

# Fase 1 — status con runtime implementado en BaseEnemy.apply_status.
# El resto vendrá en fases por-clase que los apliquen.
const IMPLEMENTED_STATUSES: Array[StringName] = [
	&"stun", &"bleed", &"weak",
]


## ¿Este status_id está definido en canon?
static func is_valid(status_id: StringName) -> bool:
	return CANON_STATUSES.has(status_id)


## ¿Este status_id tiene runtime implementado (aplicable hoy)?
static func is_implemented(status_id: StringName) -> bool:
	return IMPLEMENTED_STATUSES.has(status_id)


## Valida lista de status — retorna array de keys inválidos (vacío si todos OK).
static func validate_list(status_list: Array) -> Array:
	var invalid: Array = []
	for s in status_list:
		if not is_valid(s):
			invalid.append(s)
	return invalid
