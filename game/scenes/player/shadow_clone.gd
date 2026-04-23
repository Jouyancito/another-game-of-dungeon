extends CharacterBody3D
class_name ShadowClone

# Clon decoy del Danzante — spawneado por Paso de Sombra.
# Canon _fase1_spec_danzante.md SKILL 2: tanquea 1 golpe, dura 2s, al morir
# replica Corte Fugaz (CONE 80° 2m) con 100% base_dmg del caster.

@export var life_time_s: float = 2.0
@export var replicate_range_m: float = 2.0
@export var replicate_cone_deg: float = 80.0
@export var replicate_base_damage: float = 8.0

var owner_player: Node = null
var _alive: bool = true


func _ready() -> void:
	add_to_group(&"shadow_clones")
	var t := Timer.new()
	t.wait_time = life_time_s
	t.one_shot = true
	t.timeout.connect(_on_expire)
	add_child(t)
	t.start()


# Firma compatible con take_damage de BaseEnemy/BasePlayer — absorbe 1 hit y replica.
func take_damage(_amount: float, _dir: Vector3 = Vector3.ZERO, _kb: float = 0.0, _str: int = 0, _attacker: Node = null) -> void:
	if not _alive:
		return
	_die_replicate()


func _on_expire() -> void:
	if _alive:
		_die_replicate()


func _die_replicate() -> void:
	_alive = false
	_replicate_swift_cut()
	queue_free()


func _replicate_swift_cut() -> void:
	var base_dmg: float = replicate_base_damage
	if owner_player != null and owner_player.has_method("get_physical_damage"):
		base_dmg = owner_player.get_physical_damage(replicate_base_damage)
	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return
	forward = forward.normalized()
	var half_cone: float = deg_to_rad(replicate_cone_deg * 0.5)
	var origin: Vector3 = global_position
	for e in get_tree().get_nodes_in_group(&"enemies"):
		if not (e is Node3D) or ("is_dead" in e and e.is_dead):
			continue
		var to_e: Vector3 = (e as Node3D).global_position - origin
		to_e.y = 0.0
		var dist: float = to_e.length()
		if dist > replicate_range_m or dist < 0.01:
			continue
		var angle: float = acos(clampf(forward.dot(to_e.normalized()), -1.0, 1.0))
		if angle <= half_cone and e.has_method("take_damage"):
			var str_eff: int = 0
			if owner_player != null and owner_player.has_method("get_effective_stat"):
				str_eff = owner_player.get_effective_stat("dex")
			e.take_damage(base_dmg, to_e.normalized(), 0.0, str_eff, owner_player)
