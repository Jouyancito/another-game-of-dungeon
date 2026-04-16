class_name MimicEnemy
extends BaseEnemy

## Mímico — cofre trampa. State machine DISGUISED → REVEALING → AGGRESSIVE.
## Issue #60. Canon stats/drops sync pendiente con C (dept/design).
## Mesh + reveal anim reemplazados por D (dept/art/drop-vfx).

enum State { DISGUISED, REVEALING, AGGRESSIVE }

## Signals contract cluster:
## D (art) escucha disguise_revealed para gatillar VFX reveal (partículas + sonido).
## C (design) escucha mimic_died para achievement Frieren.
signal disguise_revealed(mimic: Node)
signal mimic_died(mimic: Node)

@export var reveal_duration := 0.6      # Fallback si AnimationPlayer no tiene "reveal"
@export var bite_range := 1.5
@export var bite_cooldown := 1.2

var state: State = State.DISGUISED

@onready var _anim: AnimationPlayer = get_node_or_null("AnimationPlayer")


func _on_enemy_ready() -> void:
	enemy_type = "mimic"
	display_name = "Mímico"
	# TODO: sync con canon C (balance_v2 §3.1 sub-tier B)
	health = 110.0
	damage = 15.0
	xp_reward = 50.0
	attack_range = bite_range
	attack_cooldown = bite_cooldown
	speed = 3.5
	aggression = AggressionType.AGGRESSIVE  # aplica post-reveal

	# DISGUISED setup: parecer cofre real para el player
	add_to_group("interactables")


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

	# Anim placeholder — D reemplaza. Fallback Timer si no hay AnimationPlayer.
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
	# Target = player que disparó el reveal (quien abrió el "cofre")
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
