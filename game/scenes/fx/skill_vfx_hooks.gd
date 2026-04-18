class_name SkillVFXHooks
extends Node

## Wire layer: conecta signals de PlayerSkills a spawn de VFX .tscn.
##
## Se agrega como child del BasePlayer en _setup_skills().
## NO toca player_skills.gd ni vfx_base.gd — solo consume su API pública.
##
## Patron replicable para Mage/Archer/etc: crear SkillVFXHooks en la clase
## hija con su propio VFX_MAP, o extender esta clase y redefinir VFX_MAP.

const VFX_MAP: Dictionary = {
	# Warrior
	&"warrior_charge":        preload("res://scenes/fx/warrior/charge_vfx.tscn"),
	&"warrior_war_cry":       preload("res://scenes/fx/warrior/war_cry_vfx.tscn"),
	&"warrior_punch":         preload("res://scenes/fx/warrior/punch_impact_vfx.tscn"),
	&"warrior_perfect_block": preload("res://scenes/fx/warrior/perfect_block_vfx.tscn"),
	# Mage — .tscn creados por D en feel-systems-wave2
	&"mage_unstable_orb":      preload("res://scenes/fx/mage/unstable_orb_vfx.tscn"),
	&"mage_arcane_storm":      preload("res://scenes/fx/mage/arcane_storm_vfx.tscn"),
	&"mage_prismatic_barrier": preload("res://scenes/fx/mage/prismatic_barrier_vfx.tscn"),
	&"mage_supernova":         preload("res://scenes/fx/mage/supernova_vfx.tscn"),
}

# Duración one-shot para charge_vfx adjunto al player (trail durante el dash).
@export var charge_trail_duration_s: float = 0.3

# Dict de instancias VFX sostenidas (toggle/reactive activos): skill_id → VFXBase
var _active_toggle_vfx: Dictionary = {}

var _owner_player: Node = null


func setup(player: Node) -> void:
	_owner_player = player
	var sk: PlayerSkills = player.skills
	if sk == null:
		push_error("SkillVFXHooks.setup: player.skills es null — ¿llamaste setup antes de _setup_skills()?")
		return
	sk.dash_started.connect(_on_dash_started)
	sk.dash_ended.connect(_on_dash_ended)
	sk.skill_hit.connect(_on_skill_hit)
	sk.toggle_changed.connect(_on_toggle_changed)
	sk.reactive_window_opened.connect(_on_reactive_window_opened)
	sk.reactive_triggered.connect(_on_reactive_triggered)


# ── Handlers ──────────────────────────────────────────────────────────────────

func _on_dash_started(skill_id: StringName) -> void:
	if skill_id != &"warrior_charge":
		return
	var vfx: VFXBase = _spawn_on_player(skill_id)
	if vfx == null:
		return
	vfx.duration_s = charge_trail_duration_s  # one-shot: auto_free cuando termina el dash
	vfx.play()
	# ── SFX ──────────────────────────────────────────────────────────────────
	if AudioManager:
		AudioManager.play_sfx(&"dash_whoosh")


func _on_dash_ended(skill_id: StringName, hit_enemy: Node) -> void:
	# El charge_vfx ya tiene duration_s > 0 → se auto-libera solo.
	# CameraShake si impactó a un enemigo.
	if hit_enemy != null and CameraShake:
		CameraShake.shake_medium()
	if hit_enemy != null and AudioManager:
		AudioManager.play_sfx(&"dash_impact")


func _on_skill_hit(skill_id: StringName, enemy: Node, hit_position: Vector3) -> void:
	# warrior_punch y warrior_charge comparten punch_impact_vfx
	if skill_id != &"warrior_punch" and skill_id != &"warrior_charge":
		return
	var scene: PackedScene = VFX_MAP.get(&"warrior_punch")
	if scene == null:
		return
	var vfx: VFXBase = scene.instantiate() as VFXBase
	if vfx == null:
		return
	# Spawn en world space — parent a scene root para no depender del player
	get_tree().current_scene.add_child(vfx)
	vfx.global_position = hit_position
	vfx.play()  # auto_free via duration_s del .tscn

	# ── SFX + feel ───────────────────────────────────────────────────────────
	if AudioManager:
		AudioManager.play_sfx(&"punch_hit", hit_position)

	# CameraShake leve en cada hit
	if CameraShake:
		CameraShake.shake_light()

	# HitStop — crit si el metadata lo indica
	if HitStop:
		var is_crit: bool = enemy != null and enemy.has_meta("last_hit_crit") and bool(enemy.get_meta("last_hit_crit"))
		if is_crit:
			HitStop.stop_crit()


func _on_toggle_changed(skill_id: StringName, active: bool) -> void:
	if skill_id != &"warrior_war_cry":
		return
	if active:
		if _active_toggle_vfx.has(skill_id):
			return  # ya activo, no duplicar
		var vfx: VFXBase = _spawn_on_player(skill_id)
		if vfx == null:
			return
		vfx.duration_s = 0.0  # sostenido — stop() manual al desactivar
		vfx.play()
		_active_toggle_vfx[skill_id] = vfx
		# ── SFX activación ───────────────────────────────────────────────────
		if AudioManager:
			AudioManager.play_sfx(&"war_cry_activate")
	else:
		_stop_toggle(skill_id)


func _on_reactive_window_opened(skill_id: StringName, duration: float) -> void:
	if skill_id != &"warrior_perfect_block":
		return
	# Si hay una ventana previa abierta, limpiarla primero
	if _active_toggle_vfx.has(skill_id):
		_stop_toggle(skill_id)
	var vfx: VFXBase = _spawn_on_player(skill_id)
	if vfx == null:
		return
	# Posicionar ligeramente adelante del player (frontal)
	vfx.position = Vector3(0.0, 0.0, -0.6)
	vfx.duration_s = duration  # auto_free cuando la ventana cierra
	vfx.play()
	_active_toggle_vfx[skill_id] = vfx


func _on_reactive_triggered(skill_id: StringName, _absorbed: float, _reflected: float) -> void:
	if skill_id != &"warrior_perfect_block":
		return
	# Limpiar la ventana si sigue activa
	_stop_toggle(skill_id)
	# Burst de éxito — re-instancia perfect_block_vfx como one-shot (flash rápido)
	var vfx: VFXBase = _spawn_on_player(skill_id)
	if vfx == null:
		return
	vfx.position = Vector3(0.0, 0.0, -0.6)
	# Duración corta para el burst — usa la del .tscn si es > 0, si no forzar 0.25s
	if vfx.duration_s <= 0.0:
		vfx.duration_s = 0.25
	vfx.play()

	# ── SFX + feel bloqueo perfecto ───────────────────────────────────────────
	if AudioManager:
		AudioManager.play_sfx(&"block_success")
	if CameraShake:
		CameraShake.shake_heavy()
	if HitStop:
		HitStop.stop_heavy()


# ── Helpers ───────────────────────────────────────────────────────────────────

## Instancia un VFX y lo agrega como child del owner_player.
## Devuelve null si el skill_id no tiene entrada en VFX_MAP.
func _spawn_on_player(skill_id: StringName) -> VFXBase:
	var scene: PackedScene = VFX_MAP.get(skill_id)
	if scene == null:
		push_warning("SkillVFXHooks: no VFX_MAP entry para '%s'" % skill_id)
		return null
	var vfx: VFXBase = scene.instantiate() as VFXBase
	if vfx == null:
		push_error("SkillVFXHooks: '%s'.tscn no tiene VFXBase como root script" % skill_id)
		return null
	_owner_player.add_child(vfx)
	return vfx


## Para un VFX sostenido y lo elimina del dict de activos.
func _stop_toggle(skill_id: StringName) -> void:
	var vfx: VFXBase = _active_toggle_vfx.get(skill_id)
	if vfx == null:
		return
	_active_toggle_vfx.erase(skill_id)
	if is_instance_valid(vfx):
		vfx.stop()
