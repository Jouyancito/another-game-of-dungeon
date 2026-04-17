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

# Toggles activos — {skill_id: {skill: SkillResource, tick_timer: float}}
var active_toggles: Dictionary = {}

# Ventanas reactivas abiertas — {skill_id: time_left_s}
var active_reactives: Dictionary = {}

# Multiplicador de daño saliente del player (aura Grito +15%, buffs futuros).
# Se suma cada buff activo al mult; se lee via outgoing_damage_mult().
var _damage_buff_sources: Dictionary = {}  # skill_id → float bonus (ej 0.15 para +15%)

signal toggle_changed(skill_id: StringName, active: bool)
signal reactive_window_opened(skill_id: StringName, duration: float)
signal reactive_triggered(skill_id: StringName, absorbed: float, reflected: float)


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
	# TOGGLE: si ya activo, apagar (no paga costo ni cooldown)
	if skill.cast_type == SkillResource.CastType.TOGGLE and active_toggles.has(skill.id):
		_deactivate_toggle(skill.id)
		skill_cast.emit(skill.id, true, "toggle_off")
		return true
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
		SkillResource.CastType.TOGGLE:
			_activate_toggle(skill)
		SkillResource.CastType.CHANNELED:
			push_warning("PlayerSkills: CHANNELED no implementado (Fase 2 Mage)")
		SkillResource.CastType.PASSIVE:
			push_warning("PlayerSkills: PASSIVE no implementado (Fase por rama)")


func _execute_instant(skill: SkillResource) -> void:
	# DASH: si dash_distance_m > 0, mover player + hit al impactar.
	if skill.dash_distance_m > 0.0:
		_execute_dash(skill)
		return
	# REACTIVE: si reactive_window_s > 0, abrir ventana parry.
	if skill.reactive_window_s > 0.0:
		_execute_reactive(skill)
		return
	match skill.target_type:
		SkillResource.TargetType.SINGLE_ENEMY:
			_execute_single_enemy(skill)
		SkillResource.TargetType.CONE:
			_execute_cone(skill)
		SkillResource.TargetType.AOE:
			_execute_aoe(skill)
		SkillResource.TargetType.SELF:
			_execute_self(skill)
		_:
			push_warning("PlayerSkills: target_type %d no implementado" % skill.target_type)


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


# ---------------------------------------------------------------------------
# CONE / AOE multi-target — Puño de Guerra (cono 60° 2m), Escudo Vengador futuro
# ---------------------------------------------------------------------------
func _execute_cone(skill: SkillResource) -> void:
	var targets: Array = _enemies_in_cone(skill.range_m, skill.cone_angle_deg)
	_apply_skill_to_targets(skill, targets)


func _execute_aoe(skill: SkillResource) -> void:
	var targets: Array = _enemies_in_sphere(skill.radius_m if skill.radius_m > 0.0 else skill.range_m)
	_apply_skill_to_targets(skill, targets)


func _apply_skill_to_targets(skill: SkillResource, targets: Array) -> void:
	var dmg: float = _compute_damage(skill)
	var attacker_str: int = 0
	if _owner_player and _owner_player.has_method("get_effective_stat"):
		attacker_str = _owner_player.get_effective_stat("str")
	for t in targets:
		if dmg > 0.0 and t.has_method("take_damage"):
			var hit_dir: Vector3 = Vector3.FORWARD
			if _owner_player and t is Node3D:
				hit_dir = (t.global_position - _owner_player.global_position).normalized()
				hit_dir.y = 0
			t.take_damage(dmg, hit_dir, 0.0, attacker_str, _owner_player)
		_apply_status_effects(skill, t)


func _enemies_in_cone(range_m: float, cone_deg: float) -> Array:
	var result: Array = []
	if _owner_player == null:
		return result
	var origin: Vector3 = _owner_player.global_position
	var forward: Vector3 = -_owner_player.global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.01:
		return result
	forward = forward.normalized()
	var half_cone_rad: float = deg_to_rad(cone_deg * 0.5)
	for e in _owner_player.get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or ("is_dead" in e and e.is_dead):
			continue
		var to_e: Vector3 = (e.global_position - origin)
		to_e.y = 0
		if to_e.length() > range_m:
			continue
		if to_e.length() < 0.01:
			result.append(e)
			continue
		var angle: float = acos(clampf(forward.dot(to_e.normalized()), -1.0, 1.0))
		if angle <= half_cone_rad:
			result.append(e)
	return result


func _enemies_in_sphere(radius: float) -> Array:
	var result: Array = []
	if _owner_player == null:
		return result
	var origin: Vector3 = _owner_player.global_position
	for e in _owner_player.get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or ("is_dead" in e and e.is_dead):
			continue
		if origin.distance_to(e.global_position) <= radius:
			result.append(e)
	return result


# ---------------------------------------------------------------------------
# DASH — mover player + hit al impactar (Embestida)
# ---------------------------------------------------------------------------
func _execute_dash(skill: SkillResource) -> void:
	if _owner_player == null or not (_owner_player is Node3D):
		return
	var forward: Vector3 = -_owner_player.global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.01:
		return
	forward = forward.normalized()
	var start: Vector3 = _owner_player.global_position
	var end: Vector3 = start + forward * skill.dash_distance_m
	# Detectar primer enemy en el path (distancia ≤ dash_distance, ángulo ≤ 30° del forward)
	var hit_enemy: Node = null
	var closest_dist: float = skill.dash_distance_m
	for e in _owner_player.get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or ("is_dead" in e and e.is_dead):
			continue
		var to_e: Vector3 = e.global_position - start
		to_e.y = 0
		var d: float = to_e.length()
		if d > skill.dash_distance_m or d < 0.1:
			continue
		if forward.dot(to_e.normalized()) < 0.85:  # ~30° cone
			continue
		if d < closest_dist:
			hit_enemy = e
			closest_dist = d
	# Mover player al punto de impacto (o end si no hubo hit)
	if hit_enemy != null:
		var stop_pos: Vector3 = (hit_enemy as Node3D).global_position - forward * 1.2
		stop_pos.y = start.y
		_owner_player.global_position = stop_pos
		var dmg: float = _compute_damage(skill)
		var attacker_str: int = _owner_player.get_effective_stat("str") if _owner_player.has_method("get_effective_stat") else 0
		hit_enemy.take_damage(dmg, forward, 0.0, attacker_str, _owner_player)
		_apply_status_effects(skill, hit_enemy)
	else:
		_owner_player.global_position = end


# ---------------------------------------------------------------------------
# TOGGLE — aura recurrente (Grito de Guerra)
# ---------------------------------------------------------------------------
func _activate_toggle(skill: SkillResource) -> void:
	active_toggles[skill.id] = {
		"skill": skill,
		"tick_timer": skill.tick_interval_s,  # primer drain en el próximo tick
	}
	# Aplicar buff de daño del aura al caster (aliados = party, no implementado — caster cuenta).
	if skill.ally_damage_bonus_pct > 0.0:
		_damage_buff_sources[skill.id] = skill.ally_damage_bonus_pct
	# Aplicar Weak a enemigos en radio inicialmente
	_apply_aura_enemy_debuff(skill)
	toggle_changed.emit(skill.id, true)


func _deactivate_toggle(skill_id: StringName) -> void:
	active_toggles.erase(skill_id)
	_damage_buff_sources.erase(skill_id)
	toggle_changed.emit(skill_id, false)


func _apply_aura_enemy_debuff(skill: SkillResource) -> void:
	# Grito aplica Weak a enemies en radius_m (10m para AOE_LARGE).
	if skill.status_applied.is_empty() or skill.status_duration_s <= 0.0:
		return
	var radius: float = skill.radius_m if skill.radius_m > 0.0 else skill.range_m
	var targets: Array = _enemies_in_sphere(radius)
	for t in targets:
		if t.has_method("apply_status"):
			for status in skill.status_applied:
				t.apply_status(status, skill.status_duration_s)


## Retorna multiplicador total de daño saliente del caster (1.0 + suma de buffs).
func outgoing_damage_mult() -> float:
	var mult: float = 1.0
	for v in _damage_buff_sources.values():
		mult += float(v)
	return mult


# ---------------------------------------------------------------------------
# REACTIVE — ventana parry (Bloqueo Perfecto)
# ---------------------------------------------------------------------------
func _execute_reactive(skill: SkillResource) -> void:
	active_reactives[skill.id] = skill.reactive_window_s
	reactive_window_opened.emit(skill.id, skill.reactive_window_s)


## Intenta gatillar un parry activo ante un incoming damage.
## Retorna Dictionary: {"absorbed": bool, "reflect_dmg": float, "stun_duration": float}
## Llamado desde base_player.take_damage antes de aplicar dmg.
func try_trigger_reactive(incoming_damage: float, attacker: Node) -> Dictionary:
	if active_reactives.is_empty():
		return {"absorbed": false, "reflect_dmg": 0.0, "stun_duration": 0.0}
	# Buscar la skill reactiva en hotbar
	for sid in active_reactives.keys():
		var skill: SkillResource = _find_hotbar_skill(sid)
		if skill == null:
			continue
		# Apagar ventana (se consume al primer golpe)
		active_reactives.erase(sid)
		# Reflejo: physical_v2(incoming * reflect_ratio, STR, lvl, class_mult 1.0)
		var str_eff: int = _owner_player.get_effective_stat("str") if _owner_player.has_method("get_effective_stat") else 0
		var reflect_base: float = incoming_damage * skill.reflect_ratio
		var reflect_dmg: float = reflect_base + float(str_eff) * 2.0  # reuso fórmula physical simplificada
		# Aplicar stun + reflejo al attacker si existe
		if attacker != null and attacker.has_method("apply_status") and skill.status_duration_s > 0.0:
			for status in skill.status_applied:
				attacker.apply_status(status, skill.status_duration_s)
		if attacker != null and attacker.has_method("take_damage") and reflect_dmg > 0.0:
			var dir: Vector3 = Vector3.ZERO
			if _owner_player is Node3D and attacker is Node3D:
				dir = (attacker.global_position - _owner_player.global_position).normalized()
				dir.y = 0
			attacker.take_damage(reflect_dmg, dir, 0.0, str_eff, _owner_player)
		# Rage bonus por parry exitoso (canon Bloqueo Perfecto)
		if class_resource != null and skill.reactive_rage_on_success > 0:
			class_resource.add(skill.reactive_rage_on_success)
		reactive_triggered.emit(sid, incoming_damage, reflect_dmg)
		return {"absorbed": true, "reflect_dmg": reflect_dmg, "stun_duration": skill.status_duration_s}
	return {"absorbed": false, "reflect_dmg": 0.0, "stun_duration": 0.0}


func _find_hotbar_skill(skill_id: StringName) -> SkillResource:
	for s in hotbar:
		if s != null and s.id == skill_id:
			return s
	return null


## Helper para tests + UI
func is_toggle_active(skill_id: StringName) -> bool:
	return active_toggles.has(skill_id)


func is_reactive_open(skill_id: StringName) -> bool:
	return active_reactives.has(skill_id)


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
			var total: float = 0.0
			for s in hotbar:
				if s != null and s.id == id:
					total = s.cooldown_s
					break
			cooldown_tick.emit(id, remaining, total)
	for id in to_clear:
		cooldowns.erase(id)
		cooldown_tick.emit(id, 0.0, 0.0)

	# Toggles activos — tick drain + re-aplicar Weak a enemies en aura
	var toggles_to_stop: Array = []
	for id in active_toggles.keys():
		var data: Dictionary = active_toggles[id]
		var skill: SkillResource = data["skill"]
		var tt: float = float(data["tick_timer"]) - delta
		if tt <= 0.0:
			# Drain recurso
			if skill.tick_resource_cost > 0:
				var paid: bool = false
				match skill.resource_type:
					SkillResource.ResourceCostType.MP:
						if _owner_player and _owner_player.has_method("use_mana"):
							paid = _owner_player.use_mana(float(skill.tick_resource_cost))
					SkillResource.ResourceCostType.RAGE, \
					SkillResource.ResourceCostType.FE, \
					SkillResource.ResourceCostType.COMBO, \
					SkillResource.ResourceCostType.CONCENTRACION:
						if class_resource:
							paid = class_resource.consume(skill.tick_resource_cost)
					_:
						paid = true
				if not paid:
					toggles_to_stop.append(id)
					continue
			# Re-aplicar aura enemy debuff
			_apply_aura_enemy_debuff(skill)
			tt = skill.tick_interval_s
		data["tick_timer"] = tt
	for id in toggles_to_stop:
		_deactivate_toggle(id)

	# Reactive windows — decrementar, cerrar al expirar
	var reactives_to_close: Array = []
	for id in active_reactives.keys():
		var remaining: float = active_reactives[id] - delta
		if remaining <= 0.0:
			reactives_to_close.append(id)
		else:
			active_reactives[id] = remaining
	for id in reactives_to_close:
		active_reactives.erase(id)


## Helper para tests — devuelve cooldown restante de una skill.
func get_cooldown(skill_id: StringName) -> float:
	return cooldowns.get(skill_id, 0.0)
