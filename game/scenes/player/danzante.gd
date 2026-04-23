extends BasePlayer
class_name Danzante

# Danzante de Sombras — clase DEX-based, recurso único Combo Points (max 5).
# Canon: danzante_sombras.md v2.0, _fase1_spec_danzante.md, _system.md §5ter COMBO.

const SKILL_SWIFT_CUT: StringName = &"danzante_swift_cut"
const SKILL_SHADOW_STEP: StringName = &"danzante_shadow_step"
const SKILL_NIGHT_VEIL: StringName = &"danzante_night_veil"
const SKILL_THOUSAND_SHADOWS: StringName = &"danzante_thousand_shadows"

const POST_STEALTH_CRIT_MULT: float = 2.5
const STEALTH_SPEED_BONUS: float = 0.20
const COMBO_RESET_TIME_S: float = 8.0        # Canon §5ter: 8s sin hitear → combo = 0
const CHAIN_RESET_TIME_S: float = 0.5        # Canon swift_cut: 0.5s sin cast → chain reset
const ULTIMATE_DURATION_S: float = 4.0       # Canon thousand_shadows: 4s de cortes

# Chain state — Corte Fugaz 3-hit (bleed en hit 3 = index 2)
var chain_index: int = 0
var _chain_timer: float = 0.0

# Stealth state
var is_in_stealth: bool = false
var _stealth_time_left: float = 0.0
var post_stealth_crit_ready: bool = false
var _speed_base: float = 0.0
var _sprint_base: float = 0.0

# Combo idle tracker (var distinta a time_since_last_hit de BasePlayer, que es HP regen)
var _combo_idle_time: float = 0.0

# Ultimate tracker — apaga el canal tras ULTIMATE_DURATION_S (fire-and-forget).
var _ultimate_active: bool = false
var _ultimate_time_left: float = 0.0

signal stealth_changed(active: bool)

var shadow_clone_scene: PackedScene = preload("res://scenes/player/shadow_clone.tscn")


func get_class_color() -> Color:
	return Color(0.25, 0.1, 0.35)  # negro-violeta canon


func _on_class_ready() -> void:
	# Stats base canon (_fase1_spec_danzante.md handoff §B — DEX 13 / STR 7 / INT 4 / DEF 3 / VIT 5)
	speed = 5.5
	sprint_speed = 8.5
	crouch_speed = 2.8
	base_health = 85.0
	base_mana = 80.0
	attack_range = 2.0
	heavy_cooldown = 0.25
	class_mult_physical = 1.2
	class_mult_magic = 1.0

	_speed_base = speed
	_sprint_base = sprint_speed

	# Combo Points — canon _system.md §5ter. Max 5, NO regen pasivo, reset manual 8s sin hit.
	# decay_delay_s alto para deshabilitar decay automático del ClassResource — manejamos reset acá.
	class_resource = ClassResource.new()
	class_resource.type = ClassResource.Type.COMBO
	class_resource.max_value = 5
	class_resource.regen_rate = 0.0
	class_resource.combat_decay_rate = 0.0
	class_resource.decay_delay_s = 1.0e9


func _equip_default_skills() -> void:
	var db = get_node_or_null("/root/SkillDB")
	if db == null:
		return
	var swift: SkillResource = db.get_skill(SKILL_SWIFT_CUT)
	var step: SkillResource = db.get_skill(SKILL_SHADOW_STEP)
	var veil: SkillResource = db.get_skill(SKILL_NIGHT_VEIL)
	var ulti: SkillResource = db.get_skill(SKILL_THOUSAND_SHADOWS)
	if swift != null:
		skills.set_slot(0, swift)
	if step != null:
		skills.set_slot(1, step)
	if veil != null:
		skills.set_slot(2, veil)
	if ulti != null:
		skills.set_slot(3, ulti)

	if not skills.skill_hit.is_connected(_on_skill_hit):
		skills.skill_hit.connect(_on_skill_hit)
	if not skills.skill_cast.is_connected(_on_skill_cast):
		skills.skill_cast.connect(_on_skill_cast)


func _on_attack_pressed() -> void:
	# LMB = Corte Fugaz slot 0. Cadena 3-hit se controla por chain_index.
	is_holding_attack = true
	if skills != null:
		skills.cast_slot(0)


func _on_attack_released() -> void:
	is_holding_attack = false


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Combo reset 8s sin hitear
	if class_resource != null and class_resource.get_current() > 0:
		_combo_idle_time += delta
		if _combo_idle_time >= COMBO_RESET_TIME_S:
			class_resource.set_current(0)
			_combo_idle_time = 0.0

	# Chain reset — 0.5s sin cast → chain_index = 0
	if chain_index > 0:
		_chain_timer += delta
		if _chain_timer >= CHAIN_RESET_TIME_S:
			chain_index = 0
			_chain_timer = 0.0

	# Stealth timer — expira a 6s o al atacar (este path = timeout natural)
	if is_in_stealth:
		_stealth_time_left -= delta
		if _stealth_time_left <= 0.0:
			_end_stealth()

	# Ultimate auto-stop (CHANNELED fire-and-forget 4s)
	if _ultimate_active:
		_ultimate_time_left -= delta
		if _ultimate_time_left <= 0.0:
			_ultimate_active = false
			if skills != null:
				skills.stop_channel(SKILL_THOUSAND_SHADOWS)


func _on_skill_cast(skill_id: StringName, success: bool, _reason: String) -> void:
	if not success:
		return
	match skill_id:
		SKILL_SWIFT_CUT:
			_chain_timer = 0.0
		SKILL_SHADOW_STEP:
			_spawn_shadow_clone()
		SKILL_NIGHT_VEIL:
			_begin_stealth(6.0)
		SKILL_THOUSAND_SHADOWS:
			_ultimate_active = true
			_ultimate_time_left = ULTIMATE_DURATION_S


func _on_skill_hit(skill_id: StringName, enemy: Node, _hit_position: Vector3) -> void:
	_combo_idle_time = 0.0
	if skill_id == SKILL_SWIFT_CUT:
		_handle_swift_cut_hit(enemy)


func _handle_swift_cut_hit(enemy: Node) -> void:
	# chain_index refleja el hit ACTUAL (0, 1, 2). Bleed en index 2 = 3er hit.
	if chain_index == 2:
		_apply_bleed(enemy)

	# Combo gen extra desde stealth (.tres da +1 base, stealth total = +2 → +1 extra acá)
	var extra_combo: int = 0
	if is_in_stealth:
		extra_combo += 1
	if extra_combo > 0 and class_resource != null:
		class_resource.add(extra_combo)

	# Post-stealth crit ×2.5 — daño extra al target (PlayerSkills no soporta crit nativo).
	# Consumido en el PRIMER hit tras romper stealth, una vez.
	if post_stealth_crit_ready and enemy != null and enemy.has_method("take_damage"):
		post_stealth_crit_ready = false
		var extra_dmg: float = get_physical_damage(8.0) * (POST_STEALTH_CRIT_MULT - 1.0)
		var dir: Vector3 = Vector3.ZERO
		if enemy is Node3D:
			dir = ((enemy as Node3D).global_position - global_position).normalized()
			dir.y = 0.0
		enemy.take_damage(extra_dmg, dir, 0.0, get_effective_stat("dex"), self)

	# Stealth se rompe al atacar — Paso de Sombra NO la rompe (dash no pasa por acá).
	if is_in_stealth:
		_end_stealth()

	# Avance cadena — loop 0→1→2→0
	chain_index = (chain_index + 1) % 3
	_chain_timer = 0.0


func _apply_bleed(target: Node) -> void:
	if target == null:
		return
	if target.has_method("apply_status"):
		target.apply_status(&"bleed", 3.0)


func _begin_stealth(duration_s: float) -> void:
	if is_in_stealth:
		return
	is_in_stealth = true
	_stealth_time_left = duration_s
	post_stealth_crit_ready = true
	# Velocidad +20% mientras stealth activo
	speed = _speed_base * (1.0 + STEALTH_SPEED_BONUS)
	sprint_speed = _sprint_base * (1.0 + STEALTH_SPEED_BONUS)
	stealth_changed.emit(true)


func _end_stealth() -> void:
	if not is_in_stealth:
		return
	is_in_stealth = false
	_stealth_time_left = 0.0
	speed = _speed_base
	sprint_speed = _sprint_base
	stealth_changed.emit(false)
	# post_stealth_crit_ready NO se consume al romper stealth por timeout —
	# solo se consume al hitear. El canon dice "próximo ataque post-stealth crit ×2.5".


func _spawn_shadow_clone() -> void:
	if shadow_clone_scene == null:
		return
	var clone: Node = shadow_clone_scene.instantiate()
	if clone is Node3D:
		(clone as Node3D).global_transform = global_transform
	if "owner_player" in clone:
		clone.owner_player = self
	get_tree().current_scene.add_child(clone)
