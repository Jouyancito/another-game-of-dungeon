class_name FootIKController extends Node
## Manager de 2 SkeletonIK3D (left_foot + right_foot) con target raycast al terreno.
## Requiere Skeleton3D descendant del player (post-import Mixamo GLB).
## Si no hay skeleton (prototipo cápsula), queda inactive — no-op.
##
## Canon _animation_canon.md §4 — foot placement:
## - Raycast desde cadera Y hacia abajo (max 0.6m)
## - Si hit: target global = hit_pos + offset_up (0.05m pie evita z-fighting)
## - Si no hit (jump/fall): desactiva IK, pierna anim normal
## - Lerp Y del offset para evitar snap al subir/bajar step

@export var ray_length: float = 0.6
@export var foot_offset_y: float = 0.05
@export var lerp_speed: float = 12.0
@export var left_foot_bone: StringName = &"LeftFoot"
@export var right_foot_bone: StringName = &"RightFoot"

var skeleton: Skeleton3D = null
var player_body: CharacterBody3D = null
var left_ik: SkeletonIK3D = null
var right_ik: SkeletonIK3D = null
var left_target: Node3D = null
var right_target: Node3D = null
var _active: bool = false
var _left_smoothed_y: float = 0.0
var _right_smoothed_y: float = 0.0


## Busca Skeleton3D como descendant, arma los SkeletonIK3D + targets.
## Si no hay skeleton, inactive (prototipo sin rig).
func setup(player: CharacterBody3D) -> void:
	player_body = player
	skeleton = _find_skeleton(player)
	if skeleton == null:
		push_warning("[FootIK] Skeleton3D no encontrado — IK inactive (prototipo cápsula)")
		_active = false
		return
	_create_ik_nodes()
	_active = true


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _create_ik_nodes() -> void:
	# Targets = Node3D standalone en world-space (no parentados al skeleton)
	left_target = Node3D.new()
	left_target.name = "LeftFootTarget"
	player_body.add_child(left_target)

	right_target = Node3D.new()
	right_target.name = "RightFootTarget"
	player_body.add_child(right_target)

	left_ik = _build_ik(left_foot_bone, left_target)
	right_ik = _build_ik(right_foot_bone, right_target)


func _build_ik(tip_bone: StringName, target: Node3D) -> SkeletonIK3D:
	var ik := SkeletonIK3D.new()
	ik.tip_bone = tip_bone
	# Root bone: padre 2 niveles arriba (hip). Se resuelve en runtime via SkeletonProfile.
	var root_bone_name: StringName = _resolve_root_bone(tip_bone)
	ik.root_bone = root_bone_name
	ik.use_magnet = false
	ik.max_iterations = 10
	ik.interpolation = 1.0
	skeleton.add_child(ik)
	ik.target_node = ik.get_path_to(target)
	return ik


## Sube 2 bones en el rig Humanoid: LeftFoot → LeftLeg (knee) → LeftUpLeg (hip).
## Similar RightFoot → RightUpLeg.
func _resolve_root_bone(tip_bone: StringName) -> StringName:
	var hip_name: String = str(tip_bone).replace("Foot", "UpLeg")
	if skeleton.find_bone(hip_name) >= 0:
		return StringName(hip_name)
	# Fallback heurístico SkeletonProfileHumanoid-standard
	return &"Hips"


## Llamar desde _physics_process del player. Actualiza targets via raycast.
## En aire (is_on_floor false): desactiva IK (pierna vuelve a anim normal).
func update(is_on_floor: bool) -> void:
	if not _active:
		return
	if not is_on_floor:
		_set_ik_active(false)
		return
	_set_ik_active(true)
	_update_foot_target(left_ik, left_target, &"LeftFoot", true)
	_update_foot_target(right_ik, right_target, &"RightFoot", false)


func _set_ik_active(active: bool) -> void:
	if left_ik != null:
		if active and not left_ik.is_running():
			left_ik.start()
		elif not active and left_ik.is_running():
			left_ik.stop()
	if right_ik != null:
		if active and not right_ik.is_running():
			right_ik.start()
		elif not active and right_ik.is_running():
			right_ik.stop()


func _update_foot_target(ik: SkeletonIK3D, target: Node3D, bone: StringName, is_left: bool) -> void:
	if skeleton == null or ik == null or target == null:
		return
	var bone_idx: int = skeleton.find_bone(str(bone))
	if bone_idx < 0:
		return
	var bone_global: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx)
	var from: Vector3 = bone_global.origin + Vector3.UP * 0.1
	var to: Vector3 = bone_global.origin + Vector3.DOWN * ray_length

	var space_state: PhysicsDirectSpaceState3D = player_body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player_body.get_rid()]
	query.collision_mask = 1  # World layer only
	var hit: Dictionary = space_state.intersect_ray(query)

	var target_y: float = bone_global.origin.y
	if not hit.is_empty():
		target_y = float(hit.position.y) + foot_offset_y

	# Smooth lerp Y (evita snap en steps)
	var delta: float = get_process_delta_time()
	if is_left:
		_left_smoothed_y = lerpf(_left_smoothed_y, target_y, clampf(delta * lerp_speed, 0.0, 1.0))
		target.global_position = Vector3(bone_global.origin.x, _left_smoothed_y, bone_global.origin.z)
	else:
		_right_smoothed_y = lerpf(_right_smoothed_y, target_y, clampf(delta * lerp_speed, 0.0, 1.0))
		target.global_position = Vector3(bone_global.origin.x, _right_smoothed_y, bone_global.origin.z)


func is_active() -> bool:
	return _active
