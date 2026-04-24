class_name MimicEnemy
extends BaseEnemy

## Mímico — cofre trampa. State machine DISGUISED → REVEALING → AGGRESSIVE.
## Issue #60. Canon completo `game/docs/balance/_mimic.md`.
## Mesh + anim `reveal`: `mimic_chest.tscn` (D). VFX reveal: `scenes/enemy/vfx/mimic_reveal_vfx.tscn`.

# TODO spawn gate: mimic debe spawnearse como reemplazo de 5% de chests sub-B+
# (canon _mimic.md §2.1-2.2). Requiere hook en loot_chest/spawner con flag
# `arena.has_sub_b_enemies` + cooldown global "max 1 activo por escena".
# Issue separado — no implementar en este merge.

enum State { DISGUISED, REVEALING, AGGRESSIVE }

## Signals contract cluster:
## D (art) escucha disguise_revealed para gatillar VFX (ya wireado acá).
## C (design) escucha mimic_died para achievement Frieren.
signal disguise_revealed(mimic: Node)
signal mimic_died(mimic: Node)

const MIMIC_REVEAL_VFX := preload("res://scenes/enemy/vfx/mimic_reveal_vfx.tscn")

@export var reveal_duration := 0.6      # Fallback si AnimationPlayer no tiene "reveal"
@export var bite_range := 1.5
@export var bite_cooldown := 1.2
@export var defense := 3                # Canon _mimic.md §1.2 piso 1 sub-B

var state: State = State.DISGUISED

@onready var _anim: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _on_enemy_ready() -> void:
	enemy_type = "mimic"
	display_name = "Mímico"
	# Canon _mimic.md §1.2 piso 1 sub-B
	health = 86.0
	damage = 8.0
	xp_reward = 42.0  # 22 base + 20 encounter bonus (canon §1.2)
	attack_range = bite_range
	attack_cooldown = bite_cooldown
	speed = 3.5
	aggression = AggressionType.AGGRESSIVE  # aplica post-reveal
	# Canon §1.3: cofre pesado, anclado. No volar al primer golpe.
	knockback_resistance = 0.9

	# DISGUISED setup: .tscn de D setea groups=[enemies, interactables].
	# Mientras DISGUISED, fuera de "enemies" para no aparecer en target frame
	# ni recibir raycasts. Se re-agrega al transicionar AGGRESSIVE.
	remove_from_group("enemies")


func _physics_process(delta: float) -> void:
	if has_meta("is_preview"):
		return
	match state:
		State.DISGUISED, State.REVEALING:
			# Quieto como cofre. Sin AI, sin nameplate, sin pursue.
			_apply_gravity(delta)
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
		State.AGGRESSIVE:
			super._physics_process(delta)


## Canon §3.2: inmune a daño durante DISGUISED/REVEALING (anti-cheese cheese).
## AGGRESSIVE aplica DEF canon sub-B P1 (defense=3) antes del super.
func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if state != State.AGGRESSIVE:
		return
	var effective := maxf(amount - float(defense), 1.0)
	super.take_damage(effective, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


## Hook de base_player._try_interact_nearby() — mismo path que loot_chest.open().
## El player presiona [E] → dispara reveal.
func open(player: Node3D) -> void:
	if state != State.DISGUISED:
		return
	_trigger_reveal(player)


## Label: mismo contrato que loot_chest.show_label/hide_label
## para que base_player._update_drop_labels lo trate idéntico.
func show_label() -> void:
	if state == State.DISGUISED:
		var label: Label3D = get_node_or_null("Label3D")
		if label:
			label.visible = true


func hide_label() -> void:
	var label: Label3D = get_node_or_null("Label3D")
	if label:
		label.visible = false


func _trigger_reveal(player: Node3D) -> void:
	state = State.REVEALING
	remove_from_group("interactables")
	hide_label()
	disguise_revealed.emit(self)

	# VFX burst púrpura — self-free a ~0.5s.
	var vfx = MIMIC_REVEAL_VFX.instantiate()
	get_tree().current_scene.add_child(vfx)
	vfx.global_position = global_position + Vector3(0, 0.5, 0)  # altura boca

	# Camera shake — TODO: camera del player aún no expone shake().
	# Crear issue follow-up cuando se implemente el sistema de shake.
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("shake"):
		cam.shake(0.3, 0.15)

	# Anim reveal (D). Fallback Timer si la anim no existe.
	if _anim != null and _anim.has_animation("reveal"):
		_anim.play("reveal")
		await _anim.animation_finished
	else:
		await get_tree().create_timer(reveal_duration).timeout

	if not is_instance_valid(self) or is_dead:
		return

	# Transición AGGRESSIVE
	state = State.AGGRESSIVE
	add_to_group("enemies")
	# Canon §3.3: target lock al jugador que hizo interact.
	if player != null and is_instance_valid(player):
		target = player
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]


func _on_death() -> void:
	mimic_died.emit(self)
	if TitleTracker and TitleTracker.has_method("notify_mimic_killed"):
		TitleTracker.notify_mimic_killed()
