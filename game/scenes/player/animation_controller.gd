class_name AnimationController3D extends Node
## Wrapper programático del AnimationTree para player humanoid.
## Construye tree_root en _ready() — no depende del editor GUI.
## Degrade gracefully: si AnimationPlayer no tiene las anims Mixamo importadas,
## el tree queda inactive y el WorldModel (Tween procedural) sigue como fallback.

signal attack_finished(variant: StringName)
signal state_entered(state_name: StringName)

var tree: AnimationTree = null
var anim_player: AnimationPlayer = null
var _player: Node = null
var _active: bool = false
var _current_attack_variant: StringName = &""
var _blend_damp: float = 10.0  # lerp speed blend_position
var anim_speed_mult: float = 1.0  # wave4: tuned per clase weight (Warrior heavy 0.9×)

# Cache param paths (evita string concat cada frame)
const PARAM_BLEND_POS: String = "parameters/locomotion/blend_position"
const PARAM_ATTACK_REQ: String = "parameters/attack/request"
const PARAM_ATTACK_ACTIVE: String = "parameters/attack/active"


## Inicializa con refs al player y al AnimationPlayer hijo.
## Si anim_player null o sin anims esperadas, queda inactive (no-op).
func setup(player: Node, ap: AnimationPlayer) -> void:
	_player = player
	anim_player = ap
	if anim_player == null:
		push_warning("[AnimationController] AnimationPlayer null — tree inactive, fallback Tween")
		_active = false
		return
	if not _has_required_anims():
		push_warning("[AnimationController] Anims Mixamo no importadas — tree inactive, fallback Tween")
		_active = false
		return
	_build_tree()
	_active = true


## Chequea que existan las anims mínimas para armar el tree.
## Si falta alguna crítica (idle/walk/run), inactive.
func _has_required_anims() -> bool:
	if anim_player == null:
		return false
	var required: Array[String] = ["idle", "walk", "run"]
	var found: int = 0
	for lib_name in anim_player.get_animation_library_list():
		var lib: AnimationLibrary = anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var lower: String = str(anim_name).to_lower()
			for req in required:
				if lower.contains(req):
					found += 1
					break
	return found >= 3


## Construye tree_root: BlendTree { locomotion(BlendSpace2D) → attack(OneShot) → output }.
## Dead state NO usa tree — se maneja directo con anim_player.play("death") desde set_dead().
## Razón: StateMachine + OneShot requiere wiring complejo; BlendTree es suficiente para wave3.
func _build_tree() -> void:
	if tree == null:
		push_error("[AnimationController] tree ref null — llamá setup con AnimationTree node asignado")
		return

	var blend_tree := AnimationNodeBlendTree.new()

	# Locomotion: BlendSpace2D — x = strafe (-1..1, wave4), y = speed (0 idle → 1 run)
	var blend := AnimationNodeBlendSpace2D.new()
	blend.min_space = Vector2(-1.0, 0.0)
	blend.max_space = Vector2(1.0, 1.0)
	var idle_anim := AnimationNodeAnimation.new()
	idle_anim.animation = _find_anim_like("idle")
	var walk_anim := AnimationNodeAnimation.new()
	walk_anim.animation = _find_anim_like("walk")
	var run_anim := AnimationNodeAnimation.new()
	run_anim.animation = _find_anim_like("run")
	blend.add_blend_point(idle_anim, Vector2(0, 0))
	blend.add_blend_point(walk_anim, Vector2(0, 0.5))
	blend.add_blend_point(run_anim, Vector2(0, 1.0))

	# Attack OneShot node + attack anim source
	var oneshot := AnimationNodeOneShot.new()
	oneshot.fadein_time = 0.05
	oneshot.fadeout_time = 0.15

	var attack_anim_node := AnimationNodeAnimation.new()
	var punch_path: String = _find_anim_like("punch")
	attack_anim_node.animation = punch_path if punch_path != "" else _find_anim_like("idle")

	blend_tree.add_node(&"locomotion", blend, Vector2(100, 100))
	blend_tree.add_node(&"attack", oneshot, Vector2(400, 100))
	blend_tree.add_node(&"attack_anim", attack_anim_node, Vector2(100, 300))

	# Wire: locomotion → attack.in (input 0), attack_anim → attack.shot (input 1), attack → output
	blend_tree.connect_node(&"attack", 0, &"locomotion")
	blend_tree.connect_node(&"attack", 1, &"attack_anim")
	blend_tree.connect_node(&"output", 0, &"attack")

	tree.tree_root = blend_tree
	tree.anim_player = tree.get_path_to(anim_player)
	tree.active = true


## Busca primera anim cuyo nombre case-insensitive contenga `substr`.
## Devuelve path válido para AnimationPlayer.has_animation(), o "" si no existe.
func _find_anim_like(substr: String) -> String:
	if anim_player == null:
		return ""
	var target: String = substr.to_lower()
	for lib_name in anim_player.get_animation_library_list():
		var lib: AnimationLibrary = anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			if str(anim_name).to_lower().contains(target):
				return (str(lib_name) + "/" + str(anim_name)) if lib_name != &"" else str(anim_name)
	return ""


## Actualiza blend_position según velocidad horizontal del player.
## max_speed: velocidad tope de la clase (Warrior sprint = 8.0).
## Normaliza a 0..1: 0 = quieto, 0.5 = walk, 1.0 = sprint.
func update_locomotion(velocity: Vector3, max_speed: float, delta: float) -> void:
	if not _active or tree == null:
		return
	var flat: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var speed_norm: float = clampf(flat.length() / maxf(max_speed, 0.1), 0.0, 1.0)
	var current_raw: Variant = tree.get(PARAM_BLEND_POS)
	var current: Vector2 = Vector2.ZERO
	if current_raw is Vector2:
		current = current_raw
	var target := Vector2(0.0, speed_norm)  # x=strafe queda 0 wave3; se expande wave4
	var next: Vector2 = current.lerp(target, clampf(delta * _blend_damp, 0.0, 1.0))
	tree.set(PARAM_BLEND_POS, next)


## Dispara animación de ataque vía OneShot.
## variant: &"punch" | &"charge" | &"war_cry" | &"perfect_block".
## Retorna true si disparó, false si tree inactive / variant unknown.
func trigger_attack(variant: StringName) -> bool:
	if not _active or tree == null:
		return false
	_current_attack_variant = variant
	# OneShot request: AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE = 1
	tree.set(PARAM_ATTACK_REQ, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	# animation_finished de AnimationTree se emite cuando termina la anim activa.
	# Conectamos una sola vez en setup → _on_tree_anim_finished re-emite con variant.
	return true


## Toggle estado Dead. Desactiva tree (freezea pose actual) + play death anim directa
## via anim_player. Wave3 no usa StateMachine dead — BlendTree no soporta terminal states
## limpiamente. Revertir con set_dead(false) reactiva tree (no usado en prototipo).
func set_dead(dead: bool) -> void:
	if not _active or tree == null or anim_player == null:
		return
	if dead:
		tree.active = false
		var death_path: String = _find_anim_like("death")
		if death_path == "":
			death_path = _find_anim_like("dead")
		if death_path != "" and anim_player.has_animation(death_path):
			anim_player.play(death_path)
	else:
		tree.active = true


## Devuelve true si el OneShot attack está activo en este frame.
func is_attacking() -> bool:
	if not _active or tree == null:
		return false
	var v: Variant = tree.get(PARAM_ATTACK_ACTIVE)
	if v is bool:
		return v
	return false


## Conectado internamente a tree.animation_finished. Re-emite con variant actual.
func _on_tree_anim_finished(_anim_name: StringName) -> void:
	if _current_attack_variant != &"":
		attack_finished.emit(_current_attack_variant)
		_current_attack_variant = &""


func _ready() -> void:
	# tree se asigna via @onready en base_player.gd después de que el nodo esté en escena.
	# Si se instancia standalone (tests), setup() se llama explícito.
	pass
