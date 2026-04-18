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

# VFX hooks — D engancha VFX aquí sin tocar lógica de skills.
signal dash_started(skill_id: StringName)
signal dash_ended(skill_id: StringName, hit_enemy: Node)
signal skill_hit(skill_id: StringName, enemy: Node, hit_position: Vector3)

# Tuneables dash polish (canon playtest 2026-04-18 — embestida teletransporte fix).
@export var dash_tween_duration_s: float = 0.3
@export var dash_fov_pulse_deg: float = 5.0


func _ready() -> void:
	# Inicializar 8 slots null
	hotbar.resize(HOTBAR_SIZE)


func setup(player: Node, resource: ClassResource = null) -> void:
	_owner_player = player
	class_resource = resource
	# Defensive: resize aunque _ready todavía no haya corrido (tests, flujos alternos).
	if hotbar.size() != HOTBAR_SIZE:
		hotbar.resize(HOTBAR_SIZE)


## Asigna una skill a un slot del hotbar (0-7). Reemplaza lo que había.
func set_slot(slot: int, skill: SkillResource) -> void:
	if slot < 0 or slot >= HOTBAR_SIZE:
		return
	hotbar[slot] = skill
	hotbar_changed.emit()


## Intercambia dos slots del hotbar (drag&drop reorder).
func swap_slots(a: int, b: int) -> void:
	if a < 0 or b < 0 or a >= HOTBAR_SIZE or b >= HOTBAR_SIZE or a == b:
		return
	var tmp: SkillResource = hotbar[a]
	hotbar[a] = hotbar[b]
	hotbar[b] = tmp
	hotbar_changed.emit()


## Layout actual como PackedStringArray de IDs (persistencia SaveManager v3).
func get_hotbar_layout() -> PackedStringArray:
	var out := PackedStringArray()
	for s in hotbar:
		if s != null:
			out.append(String(s.id))
		else:
			out.append("")
	return out


## Restaura layout desde IDs usando SkillDB autoload. Slots sin match quedan null.
func load_hotbar_layout(ids: Array) -> void:
	var db = null
	if _owner_player != null:
		db = _owner_player.get_tree().get_root().get_node_or_null("SkillDB")
	for i in range(min(ids.size(), HOTBAR_SIZE)):
		var sid := String(ids[i])
		if sid == "" or db == null:
			hotbar[i] = null
			continue
		var s: SkillResource = db.get_skill(StringName(sid)) if db.has_method("get_skill") else null
		hotbar[i] = s
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
	# G11: quest-gated check
	if skill.quest_gate != &"" and not _is_quest_completed(skill.quest_gate):
		skill_cast.emit(skill.id, false, "quest_locked")
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
	# Recurso (G1 dual + G3 HP) — validar TODO antes de consumir
	if not _can_pay_all_costs(skill):
		skill_cast.emit(skill.id, false, "insufficient_resource")
		return false
	# Pagar atómico. Si algo falla inesperadamente, rollback.
	if not _pay_all_costs(skill):
		skill_cast.emit(skill.id, false, "payment_failed")
		return false
	# Cooldown set
	if skill.cooldown_s > 0.0:
		cooldowns[skill.id] = skill.cooldown_s
	# G2: resource gen al castear (Fe pre-heal, Rage pre-charge, etc)
	if skill.resource_gen_on_cast > 0:
		_gen_resource(skill, skill.resource_gen_on_cast)
	# Ejecutar
	_execute(skill)
	skill_cast.emit(skill.id, true, "")
	return true


# ---------------------------------------------------------------------------
# G1 + G3: validación + pago atómico con rollback
# ---------------------------------------------------------------------------

func _can_pay_all_costs(skill: SkillResource) -> bool:
	# Primary resource
	if skill.resource_cost > 0:
		if not _can_pay_single(skill.resource_cost, skill.resource_type):
			return false
	# G1: secondary resource
	if skill.secondary_resource_cost > 0:
		if not _can_pay_single(skill.secondary_resource_cost, skill.secondary_resource_type):
			return false
	# G3: HP cost (FIXED / PERCENT_MAX — DRAIN_PER_SECOND valida al activar toggle)
	if skill.hp_cost_type == SkillResource.HpCostType.FIXED or skill.hp_cost_type == SkillResource.HpCostType.PERCENT_MAX:
		var hp_needed: float = _compute_hp_cost(skill)
		if _owner_player == null:
			return false
		if _owner_player.health <= hp_needed:  # min 1 HP preservado
			return false
	return true


func _can_pay_single(amount: int, rtype: int) -> bool:
	match rtype:
		SkillResource.ResourceCostType.NONE:
			return true
		SkillResource.ResourceCostType.MP:
			if _owner_player == null:
				return false
			return _owner_player.mana >= float(amount)
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource == null:
				return false
			return class_resource.get_current() >= amount
		SkillResource.ResourceCostType.VIDA:
			if _owner_player == null:
				return false
			return _owner_player.health > float(amount)
	return false


func _pay_all_costs(skill: SkillResource) -> bool:
	# Rollback-safe: primero consumir primary; si falla 2ndary, devolver primary.
	var primary_paid: bool = false
	if skill.resource_cost > 0:
		primary_paid = _pay_single(skill.resource_cost, skill.resource_type)
		if not primary_paid:
			return false
	# G1: secondary
	if skill.secondary_resource_cost > 0:
		var ok: bool = _pay_single(skill.secondary_resource_cost, skill.secondary_resource_type)
		if not ok:
			# Rollback primary
			if primary_paid:
				_refund_single(skill.resource_cost, skill.resource_type)
			return false
	# G3: HP cost (FIXED / PERCENT_MAX)
	if skill.hp_cost_type == SkillResource.HpCostType.FIXED or skill.hp_cost_type == SkillResource.HpCostType.PERCENT_MAX:
		var hp_needed: float = _compute_hp_cost(skill)
		if _owner_player:
			_owner_player.health = maxf(_owner_player.health - hp_needed, 1.0)
			if _owner_player.has_signal("health_changed"):
				_owner_player.health_changed.emit(_owner_player.health, _owner_player.max_health)
	return true


func _pay_single(amount: int, rtype: int) -> bool:
	if amount <= 0:
		return true
	match rtype:
		SkillResource.ResourceCostType.MP:
			if _owner_player and _owner_player.has_method("use_mana"):
				return _owner_player.use_mana(float(amount))
			return false
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource:
				return class_resource.consume(amount)
			return false
		SkillResource.ResourceCostType.VIDA:
			if _owner_player:
				_owner_player.health = maxf(_owner_player.health - float(amount), 1.0)
				if _owner_player.has_signal("health_changed"):
					_owner_player.health_changed.emit(_owner_player.health, _owner_player.max_health)
				return true
			return false
	return true


func _refund_single(amount: int, rtype: int) -> void:
	if amount <= 0:
		return
	match rtype:
		SkillResource.ResourceCostType.MP:
			if _owner_player:
				_owner_player.mana = minf(_owner_player.mana + float(amount), _owner_player.max_mana)
				if _owner_player.has_signal("mana_changed"):
					_owner_player.mana_changed.emit(_owner_player.mana, _owner_player.max_mana)
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource:
				class_resource.add(amount)
		SkillResource.ResourceCostType.VIDA:
			if _owner_player:
				_owner_player.health = minf(_owner_player.health + float(amount), _owner_player.max_health)
				if _owner_player.has_signal("health_changed"):
					_owner_player.health_changed.emit(_owner_player.health, _owner_player.max_health)


func _compute_hp_cost(skill: SkillResource) -> float:
	if _owner_player == null:
		return 0.0
	match skill.hp_cost_type:
		SkillResource.HpCostType.FIXED:
			return skill.hp_cost_value
		SkillResource.HpCostType.PERCENT_MAX:
			return _owner_player.max_health * skill.hp_cost_value
	return 0.0


# ---------------------------------------------------------------------------
# G2: generación de recurso — usa resource_gen_type (con fallback a class_resource)
# ---------------------------------------------------------------------------

func _gen_resource(skill: SkillResource, amount: int) -> void:
	if amount <= 0:
		return
	var rtype: int = skill.resource_gen_type
	if rtype == SkillResource.ResourceCostType.NONE and class_resource != null:
		# Fallback: si no especifica, usa el recurso único de la clase.
		rtype = _class_resource_type_to_cost_type(class_resource.type)
	match rtype:
		SkillResource.ResourceCostType.MP:
			if _owner_player:
				_owner_player.mana = minf(_owner_player.mana + float(amount), _owner_player.max_mana)
				if _owner_player.has_signal("mana_changed"):
					_owner_player.mana_changed.emit(_owner_player.mana, _owner_player.max_mana)
		SkillResource.ResourceCostType.RAGE, \
		SkillResource.ResourceCostType.FE, \
		SkillResource.ResourceCostType.COMBO, \
		SkillResource.ResourceCostType.CONCENTRACION:
			if class_resource:
				class_resource.add(amount)


func _class_resource_type_to_cost_type(ct: int) -> int:
	match ct:
		ClassResource.Type.RAGE: return SkillResource.ResourceCostType.RAGE
		ClassResource.Type.FE: return SkillResource.ResourceCostType.FE
		ClassResource.Type.COMBO: return SkillResource.ResourceCostType.COMBO
		ClassResource.Type.CONCENTRACION: return SkillResource.ResourceCostType.CONCENTRACION
		ClassResource.Type.VIDA: return SkillResource.ResourceCostType.VIDA
	return SkillResource.ResourceCostType.NONE


func _is_quest_completed(quest_id: StringName) -> bool:
	# QuestSystem no existe aún — stub. Cuando exista, wirear acá.
	var qs = _owner_player.get_tree().get_root().get_node_or_null("QuestSystem") if _owner_player else null
	if qs != null and qs.has_method("is_completed"):
		return qs.is_completed(quest_id)
	return false  # gate activo — skill bloqueada hasta que QuestSystem wireé


# ---------------------------------------------------------------------------
# Ejecución — Fase 0 soporta INSTANT + SINGLE_ENEMY + PHYSICAL_V2.
# Resto de target_types / damage_formulas quedan como TODO para fases 1-2.
# ---------------------------------------------------------------------------
func _execute(skill: SkillResource) -> void:
	# G9: invul frames (Danzante dashes) — abre ventana de invul al castear
	if skill.invul_duration_s > 0.0 and _owner_player != null:
		_owner_player.set_meta("invul_time_left", skill.invul_duration_s)
	# G10: summon — si skill tiene summon_data, instancia antes del execute main
	if skill.summon_data != null:
		_execute_summon(skill)
	match skill.cast_type:
		SkillResource.CastType.INSTANT:
			_execute_instant(skill)
		SkillResource.CastType.TOGGLE:
			_activate_toggle(skill)
		SkillResource.CastType.CHANNELED:
			_activate_channeled(skill)
		SkillResource.CastType.CHARGED:
			# G6: para Archer Flecha Cargada. Fase 4 Archer wirea charge_progress per-frame.
			# MVP: cast directo con mult máximo (stub — se puede refinar con hold tracking).
			_execute_instant(skill)
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
		var hit_dir: Vector3 = Vector3.FORWARD
		if _owner_player and target is Node3D:
			hit_dir = (target.global_position - _owner_player.global_position).normalized()
			hit_dir.y = 0
		var str_effective: int = 0
		if _owner_player and _owner_player.has_method("get_effective_stat"):
			str_effective = _owner_player.get_effective_stat("str")
		target.take_damage(dmg, hit_dir, 0.0, str_effective, _owner_player)
		# G2: gen on hit
		if skill.resource_gen_on_hit > 0:
			_gen_resource(skill, skill.resource_gen_on_hit)
		# VFX hook — impact
		if target is Node3D:
			skill_hit.emit(skill.id, target, (target as Node3D).global_position)
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
	var hits: int = 0
	for t in targets:
		if dmg > 0.0 and t.has_method("take_damage"):
			var hit_dir: Vector3 = Vector3.FORWARD
			if _owner_player and t is Node3D:
				hit_dir = (t.global_position - _owner_player.global_position).normalized()
				hit_dir.y = 0
			t.take_damage(dmg, hit_dir, 0.0, attacker_str, _owner_player)
			hits += 1
			# VFX hook — impact (multi-target cone/aoe)
			if t is Node3D:
				skill_hit.emit(skill.id, t, (t as Node3D).global_position)
		_apply_status_effects(skill, t)
	# G2: gen on hit (por cada target impactado) + gen per_target (aliados curados, etc)
	if hits > 0 and skill.resource_gen_on_hit > 0:
		_gen_resource(skill, skill.resource_gen_on_hit * hits)
	if targets.size() > 0 and skill.resource_gen_per_target > 0:
		_gen_resource(skill, skill.resource_gen_per_target * targets.size())


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
	var stop_pos: Vector3
	if hit_enemy != null:
		stop_pos = (hit_enemy as Node3D).global_position - forward * 1.2
		stop_pos.y = start.y
	else:
		stop_pos = end

	dash_started.emit(skill.id)

	# Fallback sync: sin tree o duration 0 → mover+aplicar inmediato (tests, edge cases).
	if not _owner_player.is_inside_tree() or dash_tween_duration_s <= 0.0:
		_owner_player.global_position = stop_pos
		_apply_dash_hit(skill, hit_enemy, forward)
		dash_ended.emit(skill.id, hit_enemy)
		return

	# Lock input/movement durante el dash — BasePlayer lee dash_locked en _physics_process.
	if "dash_locked" in _owner_player:
		_owner_player.dash_locked = true

	# Position tween — ease_in_out para entrada suave y stop "pegajoso".
	var pos_tween: Tween = _owner_player.create_tween()
	pos_tween.set_ease(Tween.EASE_IN_OUT)
	pos_tween.set_trans(Tween.TRANS_SINE)
	pos_tween.tween_property(_owner_player, "global_position", stop_pos, dash_tween_duration_s)
	pos_tween.tween_callback(_on_dash_finished.bind(skill, hit_enemy, forward))

	# Camera FOV pulse — parallel tween (no bloquea si no hay camera).
	var cam: Camera3D = _get_player_camera()
	if cam != null and dash_fov_pulse_deg > 0.0:
		var fov_base: float = cam.fov
		var half: float = dash_tween_duration_s * 0.5
		var fov_tween: Tween = _owner_player.create_tween()
		fov_tween.tween_property(cam, "fov", fov_base + dash_fov_pulse_deg, half).set_trans(Tween.TRANS_SINE)
		fov_tween.tween_property(cam, "fov", fov_base, half).set_trans(Tween.TRANS_SINE)


func _on_dash_finished(skill: SkillResource, hit_enemy: Node, forward: Vector3) -> void:
	if _owner_player != null and "dash_locked" in _owner_player:
		_owner_player.dash_locked = false
	_apply_dash_hit(skill, hit_enemy, forward)
	dash_ended.emit(skill.id, hit_enemy)


func _apply_dash_hit(skill: SkillResource, hit_enemy: Node, forward: Vector3) -> void:
	if hit_enemy == null or not is_instance_valid(hit_enemy):
		return
	if "is_dead" in hit_enemy and hit_enemy.is_dead:
		return
	var dmg: float = _compute_damage(skill)
	var attacker_str: int = 0
	if _owner_player and _owner_player.has_method("get_effective_stat"):
		attacker_str = _owner_player.get_effective_stat("str")
	if hit_enemy.has_method("take_damage"):
		hit_enemy.take_damage(dmg, forward, 0.0, attacker_str, _owner_player)
	_apply_status_effects(skill, hit_enemy)
	var hit_pos: Vector3 = Vector3.ZERO
	if hit_enemy is Node3D:
		hit_pos = (hit_enemy as Node3D).global_position
	skill_hit.emit(skill.id, hit_enemy, hit_pos)


func _get_player_camera() -> Camera3D:
	if _owner_player == null:
		return null
	if "camera" in _owner_player:
		var c = _owner_player.camera
		if c is Camera3D:
			return c
	return null


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
		# G2: resource_gen_on_cast en path reactive = ganancia por parry exitoso
		# (reemplaza el legacy reactive_rage_on_success, que queda como fallback).
		if skill.resource_gen_on_cast > 0:
			_gen_resource(skill, skill.resource_gen_on_cast)
		elif class_resource != null and skill.reactive_rage_on_success > 0:
			# Fallback legacy para compat — .tres con solo reactive_rage_on_success
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
	var base: float = float(skill.base_damage)
	if _owner_player != null:
		match skill.damage_formula:
			SkillResource.DamageFormulaType.PHYSICAL_V2:
				if _owner_player.has_method("get_physical_damage"):
					base = _owner_player.get_physical_damage(float(skill.base_damage))
			SkillResource.DamageFormulaType.MAGIC_V2:
				if _owner_player.has_method("get_magic_damage"):
					base = _owner_player.get_magic_damage(float(skill.base_damage))
			SkillResource.DamageFormulaType.HEAL, \
			SkillResource.DamageFormulaType.TRUE_DAMAGE:
				base = float(skill.base_damage)
	# G4: combo points damage multiplier (Danzante finishers).
	# Si combo_damage_multipliers no vacío, lee current combo del class_resource.
	if skill.combo_damage_multipliers.size() > 0 and class_resource != null:
		var points: int = class_resource.get_current()
		if points > 0:
			var idx: int = clampi(points - 1, 0, skill.combo_damage_multipliers.size() - 1)
			base *= skill.combo_damage_multipliers[idx]
		if skill.combo_consume_all:
			class_resource.consume(points)
	# G6: charge damage multiplier (Archer Flecha Cargada — full charge si CHARGED)
	if skill.cast_type == SkillResource.CastType.CHARGED and skill.charge_damage_multiplier_max > 1.0:
		base *= skill.charge_damage_multiplier_max
	return base


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

	# G3: HP drain per second para toggles con hp_cost_type DRAIN_PER_SECOND
	# (Aura Marchita Necromancer pattern — mismo loop de toggles abajo cubre MP/Rage/etc
	#  pero HP drain es per-frame, no per-tick).
	var hp_drain_to_stop: Array = []
	for id in active_toggles.keys():
		var skill: SkillResource = active_toggles[id]["skill"]
		if skill.hp_cost_type == SkillResource.HpCostType.DRAIN_PER_SECOND and _owner_player:
			var drain: float = skill.hp_cost_value * delta
			if _owner_player.health - drain <= 1.0:
				hp_drain_to_stop.append(id)  # apagar en vez de matar
			else:
				_owner_player.health -= drain
				if _owner_player.has_signal("health_changed"):
					_owner_player.health_changed.emit(_owner_player.health, _owner_player.max_health)
	for id in hp_drain_to_stop:
		_deactivate_toggle(id)

	# G9: decrementar invul_time_left del player
	if _owner_player != null and _owner_player.has_meta("invul_time_left"):
		var t: float = float(_owner_player.get_meta("invul_time_left")) - delta
		if t <= 0.0:
			_owner_player.remove_meta("invul_time_left")
		else:
			_owner_player.set_meta("invul_time_left", t)

	# Toggles + channeled — tick drain + efecto per-tick
	var toggles_to_stop: Array = []
	for id in active_toggles.keys():
		var data: Dictionary = active_toggles[id]
		var skill: SkillResource = data["skill"]
		var tt: float = float(data["tick_timer"]) - delta
		if tt <= 0.0:
			# Drain recurso (G5: tick_resource_cost para channeled + toggle)
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
			# Efecto per-tick: channeled aplica damage, toggle aplica aura debuff
			if data.get("is_channeled", false):
				_channeled_tick(skill)
			else:
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


# ---------------------------------------------------------------------------
# G5: CHANNELED — hold-to-cast recurrente (Mage Tormenta, Cleric Círculo, Necro Aura)
# MVP: reusa active_toggles pero marca is_channeled=true. Cada tick aplica el
# damage_formula a targets en cono/AoE. stop_channel() al soltar input o MP out.
# Fase 2 Mage refinará con hold-tracking (input release detection).
# ---------------------------------------------------------------------------
func _activate_channeled(skill: SkillResource) -> void:
	active_toggles[skill.id] = {
		"skill": skill,
		"tick_timer": skill.tick_interval_s,  # próximo tick
		"is_channeled": true,
	}
	toggle_changed.emit(skill.id, true)


func stop_channel(skill_id: StringName) -> void:
	# Llamado explícitamente al soltar tecla o MP out.
	if active_toggles.has(skill_id):
		# Arranca cooldown_s del skill al soltar (canon G5 brief).
		var data: Dictionary = active_toggles[skill_id]
		var skill: SkillResource = data.get("skill")
		if skill != null and skill.cooldown_s > 0.0:
			cooldowns[skill_id] = skill.cooldown_s
		_deactivate_toggle(skill_id)


func _channeled_tick(skill: SkillResource) -> void:
	# Aplica damage_formula a targets en cono o AoE según target_type.
	var targets: Array = []
	match skill.target_type:
		SkillResource.TargetType.CONE:
			targets = _enemies_in_cone(skill.range_m, skill.cone_angle_deg)
		SkillResource.TargetType.AOE:
			targets = _enemies_in_sphere(skill.radius_m if skill.radius_m > 0.0 else skill.range_m)
		SkillResource.TargetType.SINGLE_ENEMY:
			var t: Node = _acquire_enemy_target(skill.range_m)
			if t != null:
				targets = [t]
	_apply_skill_to_targets(skill, targets)


# ---------------------------------------------------------------------------
# G10: SUMMON — instanciar escena con HP/DMG formulas del SummonResource
# Fase 1: stub sólido — instancia y aplica formulas. Aggregar a
# player.active_summons dict para tracking + cap max_active.
# ---------------------------------------------------------------------------
func _execute_summon(skill: SkillResource) -> void:
	var sr = skill.summon_data
	if sr == null or _owner_player == null:
		return
	if not (sr is SummonResource):
		push_warning("PlayerSkills: summon_data no es SummonResource — skip")
		return
	var summon_res: SummonResource = sr
	if summon_res.summon_scene == null:
		push_warning("PlayerSkills: summon_scene null para '%s'" % summon_res.summon_id)
		return
	# Track active summons en player
	if not _owner_player.has_meta("active_summons"):
		_owner_player.set_meta("active_summons", {})
	var active: Dictionary = _owner_player.get_meta("active_summons")
	var key: StringName = summon_res.summon_id
	if not active.has(key):
		active[key] = []
	var list: Array = active[key]
	# Limpiar refs inválidas
	list = list.filter(func(n): return is_instance_valid(n))
	# Cap max_active: despawn el más viejo si excede
	while list.size() >= summon_res.max_active and list.size() > 0:
		var oldest: Node = list.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	# Instanciar
	var instance: Node = summon_res.summon_scene.instantiate()
	if instance is Node3D and _owner_player is Node3D:
		var fwd: Vector3 = -_owner_player.global_transform.basis.z
		fwd.y = 0
		(instance as Node3D).global_position = _owner_player.global_position + fwd.normalized() * 1.5
	# Aplicar formulas
	var hp: float = SummonResource.eval_formula(summon_res.hp_formula, _owner_player)
	var dmg: float = SummonResource.eval_formula(summon_res.dmg_formula, _owner_player)
	if "health" in instance:
		instance.health = hp
	if "_max_health" in instance:
		instance._max_health = hp
	if "damage" in instance:
		instance.damage = dmg
	if instance.has_method("set_ai_behavior"):
		instance.set_ai_behavior(summon_res.ai_behavior)
	_owner_player.get_tree().current_scene.add_child(instance)
	list.append(instance)
	active[key] = list
	# Duration — auto-despawn si > 0
	if summon_res.duration_s > 0.0:
		var timer := Timer.new()
		timer.wait_time = summon_res.duration_s
		timer.one_shot = true
		timer.timeout.connect(func():
			if is_instance_valid(instance):
				instance.queue_free()
			timer.queue_free()
		)
		instance.add_child(timer)
		timer.start()
