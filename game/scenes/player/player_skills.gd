class_name PlayerSkills extends Node

# Componente del BasePlayer — owns hotbar 1-8, cooldowns, casting logic.
# Fase 0: solo INSTANT + SINGLE_ENEMY + PHYSICAL_V2 (Shield Bash pattern).
# Fases siguientes: CHANNELED, TOGGLE, PASSIVE, AOE, CONE, LINE, MAGIC_V2, HEAL.

const HOTBAR_SIZE := 8

signal hotbar_changed
signal skill_cast(skill_id: StringName, success: bool, reason: String)
signal cooldown_tick(skill_id: StringName, remaining_s: float, total_s: float)

var hotbar: Array[SkillResource] = []       # 8 slots — null = vacío
var cooldowns: Dictionary = {}              # skill_id → float seconds remaining
var class_resource: ClassResource = null    # referencia al recurso único (Rage/Fe/etc)
var _owner_player: Node = null              # se setea via setup(player)


func _ready() -> void:
	# Inicializar 8 slots null
	hotbar.resize(HOTBAR_SIZE)


func setup(player: Node, resource: ClassResource = null) -> void:
	_owner_player = player
	class_resource = resource


## Asigna una skill a un slot del hotbar (0-7). Reemplaza lo que había.
func set_slot(slot: int, skill: SkillResource) -> void:
	if slot < 0 or slot >= HOTBAR_SIZE:
		return
	hotbar[slot] = skill
	hotbar_changed.emit()


## Intenta castear el slot. Retorna true si tuvo éxito.
## Falla silenciosa: emite skill_cast(id, false, reason).
func cast_slot(slot: int) -> bool:
	if slot < 0 or slot >= HOTBAR_SIZE:
		return false
	var skill: SkillResource = hotbar[slot]
	if skill == null:
		return false
	return cast_skill(skill)


func cast_skill(skill: SkillResource) -> bool:
	if skill == null:
		return false
	# Cooldown
	if cooldowns.get(skill.id, 0.0) > 0.0:
		skill_cast.emit(skill.id, false, "cooldown")
		return false
	# Recurso
	if not _can_pay_cost(skill):
		skill_cast.emit(skill.id, false, "insufficient_resource")
		return false
	# Pagar costo
	_pay_cost(skill)
	# Cooldown set
	if skill.cooldown_s > 0.0:
		cooldowns[skill.id] = skill.cooldown_s
	# Ejecutar
	_execute(skill)
	skill_cast.emit(skill.id, true, "")
	return true


func _can_pay_cost(skill: SkillResource) -> bool:
	if skill.resource_cost <= 0:
		return true
	match skill.resource_type:
		SkillResource.ResourceCostType.NONE:
			return true
		SkillResource.ResourceCostType.MP:
			if _owner_player == null:
				return false
			return _owner_player.mana >= float(skill.resource_cost)
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource == null:
				return false
			return class_resource.get_current() >= skill.resource_cost
		SkillResource.ResourceCostType.VIDA:
			if _owner_player == null:
				return false
			return _owner_player.health > float(skill.resource_cost)
	return false


func _pay_cost(skill: SkillResource) -> void:
	if skill.resource_cost <= 0:
		return
	match skill.resource_type:
		SkillResource.ResourceCostType.MP:
			if _owner_player and _owner_player.has_method("use_mana"):
				_owner_player.use_mana(float(skill.resource_cost))
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource:
				class_resource.consume(skill.resource_cost)
		SkillResource.ResourceCostType.VIDA:
			if _owner_player:
				# No usar take_damage (triggerea regen delay + death) — restar directo
				_owner_player.health = maxf(_owner_player.health - float(skill.resource_cost), 1.0)
				if _owner_player.has_signal("health_changed"):
					_owner_player.health_changed.emit(_owner_player.health, _owner_player.max_health)


# ---------------------------------------------------------------------------
# Ejecución — Fase 0 soporta INSTANT + SINGLE_ENEMY + PHYSICAL_V2.
# Resto de target_types / damage_formulas quedan como TODO para fases 1-2.
# ---------------------------------------------------------------------------
func _execute(skill: SkillResource) -> void:
	match skill.cast_type:
		SkillResource.CastType.INSTANT:
			_execute_instant(skill)
		SkillResource.CastType.CHANNELED, \
		SkillResource.CastType.TOGGLE, \
		SkillResource.CastType.PASSIVE:
			push_warning("PlayerSkills: cast_type %d no implementado (Fase 0 solo INSTANT)" % skill.cast_type)


func _execute_instant(skill: SkillResource) -> void:
	match skill.target_type:
		SkillResource.TargetType.SINGLE_ENEMY:
			_execute_single_enemy(skill)
		SkillResource.TargetType.SELF:
			_execute_self(skill)
		_:
			push_warning("PlayerSkills: target_type %d no implementado (Fase 0)" % skill.target_type)


func _execute_single_enemy(skill: SkillResource) -> void:
	var target: Node = _acquire_enemy_target(skill.range_m)
	if target == null:
		return
	var dmg: float = _compute_damage(skill)
	if dmg > 0.0 and target.has_method("take_damage"):
		# BaseEnemy.take_damage firma: (amount, hit_direction, kb_force, attacker_str, attacker)
		var hit_dir: Vector3 = Vector3.FORWARD
		if _owner_player and target is Node3D:
			hit_dir = (target.global_position - _owner_player.global_position).normalized()
			hit_dir.y = 0
		var str_effective: int = 0
		if _owner_player and _owner_player.has_method("get_effective_stat"):
			str_effective = _owner_player.get_effective_stat("str")
		target.take_damage(dmg, hit_dir, 0.0, str_effective, _owner_player)
	# Aplicar status effects (stub Fase 0 — usa método del enemy si existe)
	_apply_status_effects(skill, target)


func _execute_self(skill: SkillResource) -> void:
	# Fase 0 stub: heals en SELF. Resto de self-buffs en fases siguientes.
	if skill.damage_formula == SkillResource.DamageFormulaType.HEAL and _owner_player:
		if _owner_player.has_method("heal"):
			_owner_player.heal(float(skill.base_damage))


func _acquire_enemy_target(range_m: float) -> Node:
	# Fase 0: usa el target frame del HUD (ya hay lógica en base_player._update_target_frame).
	# Fallback: primer enemy del grupo "enemies" en range.
	if _owner_player == null:
		return null
	var hud := _owner_player.get_tree().get_first_node_in_group("hud")
	if hud != null and "_current_target" in hud:
		var t: Node = hud._current_target
		if t != null and is_instance_valid(t) and "is_dead" in t and not t.is_dead:
			if _owner_player is Node3D and t is Node3D:
				var dist: float = (_owner_player as Node3D).global_position.distance_to((t as Node3D).global_position)
				if dist <= range_m:
					return t
	# Fallback por distancia
	var closest: Node = null
	var closest_dist: float = range_m
	for e in _owner_player.get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D):
			continue
		if "is_dead" in e and e.is_dead:
			continue
		var d: float = (_owner_player as Node3D).global_position.distance_to((e as Node3D).global_position)
		if d < closest_dist:
			closest = e
			closest_dist = d
	return closest


func _compute_damage(skill: SkillResource) -> float:
	if skill.damage_formula == SkillResource.DamageFormulaType.NONE:
		return 0.0
	if _owner_player == null:
		return float(skill.base_damage)
	match skill.damage_formula:
		SkillResource.DamageFormulaType.PHYSICAL_V2:
			if _owner_player.has_method("get_physical_damage"):
				return _owner_player.get_physical_damage(float(skill.base_damage))
		SkillResource.DamageFormulaType.MAGIC_V2:
			if _owner_player.has_method("get_magic_damage"):
				return _owner_player.get_magic_damage(float(skill.base_damage))
		SkillResource.DamageFormulaType.HEAL, \
		SkillResource.DamageFormulaType.TRUE_DAMAGE:
			return float(skill.base_damage)
	return float(skill.base_damage)


func _apply_status_effects(skill: SkillResource, target: Node) -> void:
	if target == null or skill.status_applied.is_empty():
		return
	for status in skill.status_applied:
		if target.has_method("apply_status"):
			target.apply_status(status, skill.status_duration_s)
		elif target.has_method("stun"):
			# Fallback para enemies legacy con stun() hardcodeado
			if status == &"stun":
				target.stun(skill.status_duration_s)


func _process(delta: float) -> void:
	# Decrementar cooldowns + emitir ticks para UI
	var to_clear: Array = []
	for id in cooldowns:
		var remaining: float = cooldowns[id] - delta
		if remaining <= 0.0:
			to_clear.append(id)
		else:
			cooldowns[id] = remaining
			# Buscar total para el tick — match id en hotbar
			var total: float = 0.0
			for s in hotbar:
				if s != null and s.id == id:
					total = s.cooldown_s
					break
			cooldown_tick.emit(id, remaining, total)
	for id in to_clear:
		cooldowns.erase(id)
		cooldown_tick.emit(id, 0.0, 0.0)


## Helper para tests — devuelve cooldown restante de una skill.
func get_cooldown(skill_id: StringName) -> float:
	return cooldowns.get(skill_id, 0.0)
