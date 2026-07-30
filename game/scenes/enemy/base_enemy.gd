class_name BaseEnemy
extends CharacterBody3D

## Tipos de agresividad
enum AggressionType { AGGRESSIVE, NEUTRAL }

## Personalidad de aggro — define cómo reacciona ante el jugador.
## DEFAULT reproduce el comportamiento original exacto (ningún cambio).
enum AggroPersonality {
	DEFAULT,         # Comportamiento original (todos los enemies existentes)
	HUNTER_FAST,     # Cazador veloz: detection grande, speed alta, persistencia máxima (wolf, hawk)
	JUGGERNAUT_SLOW, # Lento imparable: speed baja, jamás abandona la persecución (golem)
	CURIOUS,         # Curioso: se acerca lento, solo ataca si el jugador entra en close_attack_range o provoca (slime, mini_slime)
	SKITTISH,        # Esquivo: huye cuando el jugador se acerca, ataca solo si acorralado (fox, goat)
	TERRITORIAL,     # Territorial: solo aggro dentro del territorio de spawn, leash de vuelta (scorpion)
}

## Sub-tier dentro de un piso — define el rol del enemigo en el ecosistema
enum SubTier { A, B, C, BOSS }

# Stats base
@export var speed := 3.0
@export var health := 100.0
@export var damage := 10.0
@export var attack_range := 2.0
@export var detection_range := 15.0
@export var xp_reward := 30.0
@export var attack_cooldown := 1.0
@export var aggression: AggressionType = AggressionType.AGGRESSIVE
@export var enemy_type: String = "enemy_basic"  # Clave para LootTable

# Tier — define la peligrosidad y el badge en el target frame
@export var enemy_tier: int = 1  # Tier = piso de procedencia (1-100)
@export var sub_tier: SubTier = SubTier.A  # A=fauna, B=depredador, C=alfa, BOSS=jefe
@export var habitat_type: String = "open_field"  # "open_field" | "water_edge" | "cave" | "aerial" | "boss_arena"

# Knockback
@export var mass := 1.0  # 0.5 = liviano (slime), 1.0 = normal, 5.0 = pesado (boss)
@export var knockback_resistance := 0.0  # 0.0 = sin resistencia, 1.0 = inmune

# ── Personalidad de aggro ─────────────────────────────────────────────────────
# DEFAULT = sin cambios (todos los enemies existentes).
# Los demás perfiles se resuelven en _apply_personality() durante _ready.
@export var personality: AggroPersonality = AggroPersonality.DEFAULT

# Multiplicadores y radios — _apply_personality() los inicializa según el perfil.
# Son @export para permitir ajuste fino desde el inspector o subclases.
@export var detection_mult := 1.0         # Multiplica detection_range efectivo
@export var speed_mult := 1.0             # Multiplica speed efectivo en persecución
@export var pursue_persistence := 0.0     # Distancia extra que persigue antes de abandonar (0 = solo detection_range)
@export var flee_radius := 0.0            # SKITTISH: distancia a la que empieza a huir
@export var territorial_radius := 0.0     # TERRITORIAL: radio desde spawn_home para agredir
@export var curiosity_approach_speed := 0.5  # CURIOUS: fracción de speed para acercarse

# Pack flag — composable con cualquier personalidad (wolf: HUNTER_FAST + is_pack)
# No es un enum separado para evitar explosión de combinaciones.
@export var is_pack := false

# Estado interno de personalidad (no exportado — se calcula en runtime)
var _home_position := Vector3.ZERO       # TERRITORIAL / SKITTISH: punto de referencia para leash
var _is_fleeing_skittish := false        # SKITTISH: flag de huida activa
var _cornered_timer := 0.0              # SKITTISH: tiempo sin poder huir → ataca
const _CORNERED_TIMEOUT := 1.5          # segundos sin escapar → cornered

# Estado
var target: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var knockback_velocity := Vector3.ZERO
var is_dead := false
var can_attack := true
var is_provoked := false  # Para neutrales: se activa al recibir daño

# Alerta por daño — si recibí hit, persigo al attacker incluso fuera del
# detection_range normal. Se resetea tras _alert_time_s sin recibir daño
# más O al perder target.
var _alert_time_left: float = 0.0
const _ALERT_DURATION_S: float = 15.0

# Nameplate
@export var display_name: String = ""
@export var enemy_level: int = 1

# Offset para target frame (altura del "centro visible").
# Enemigos bajos (rat, slime): 0.8. Bosses grandes (king_slime): 3.0+.
@export var target_frame_offset: Vector3 = Vector3(0, 0.8, 0)
const NAMEPLATE_VISIBLE_RANGE := 15.0
const NAMEPLATE_AIM_RANGE := 30.0

# Referencia al mesh — cada hijo define su nodo
@onready var mesh: MeshInstance3D = $MeshInstance3D

# Color original del mesh (cada hijo lo define)
var default_color := Color(0.8, 0.2, 0.2)

# Re-entrancy guard for _flash_damage — prevents overlapping flashes from
# saving the red tint as the "original" material (stuck-red regression).
var _is_flashing := false

# Animation helper — null when no AnimationPlayer is found (procedural enemies).
# Type is intentionally untyped (Variant) to avoid class_name load-order issues.
# Subclasses expose a gltf model root via _get_anim_model_root(); base = null → no-op.
var _anim = null  # EnemyAnimator or null

# Nameplate nodes
var _nameplate: Node3D
var _name_label: Label3D
var _hp_bar_bg: MeshInstance3D
var _hp_bar_fill: MeshInstance3D
var _max_health: float
var _sighted_once := false  # flag para Journal.sight — evitar spam cada frame

# Killing blow — canon drop-ownership v2.
# profile_id del ultimo attacker que puso el HP a 0. "" = kill por ambiente.
var _killer_profile_id: String = ""

# Status effects activos — canon _status_effects.md §2.
# Schema por efecto:
#   stun  → {time_left: float}
#   bleed → {time_left: float, tick_timer: float, dmg_per_tick: float, source}
#   weak  → {time_left: float, dmg_mult: float}
# Refresh-to-max al reapply (sin stacks en Fase 1 — bleed stacks son futuros).
var status_effects: Dictionary = {}

signal status_applied(status_name: StringName, duration: float)
signal status_removed(status_name: StringName)
## Emitted once, from die(), before the corpse tween starts. Levels listen to this
## to react to a specific kill (e.g. the boss dying opens the descent).
signal died(enemy: BaseEnemy)


func _ready() -> void:
	await get_tree().process_frame
	var is_preview: bool = has_meta("is_preview")
	if not is_preview:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	_on_enemy_ready()
	# Aplicar personalidad DESPUÉS de _on_enemy_ready para que subclases puedan
	# sobreescribir stats (speed, detection_range) antes de que los multiplicadores se resuelven.
	_apply_personality()
	_max_health = health
	if not is_preview:
		_setup_nameplate()
	# Set up animation after _on_enemy_ready so the model node exists.
	_setup_anim()


func get_tier_label() -> String:
	var tier_names := {SubTier.A: "A", SubTier.B: "B", SubTier.C: "C", SubTier.BOSS: "BOSS"}
	return "T%d %s" % [enemy_tier, tier_names.get(sub_tier, "?")]


func get_display_name() -> String:
	if display_name != "":
		return display_name
	return scene_file_path.get_file().get_basename().capitalize()


## Override en subclases para setup específico
func _on_enemy_ready() -> void:
	pass


## Override in subclasses that use a gltf model.
## Return the Node3D that is the root of the imported gltf scene
## (the node that CONTAINS an AnimationPlayer somewhere in its subtree).
## Default returns null → EnemyAnimator is not created → all animation calls are no-ops.
## Procedural enemies (wolf, fox, goat, etc.) must NOT override this.
func _get_anim_model_root() -> Node3D:
	return null


## Called after _on_enemy_ready so the model node already exists in the tree.
func _setup_anim() -> void:
	var root: Node3D = _get_anim_model_root()
	if root == null:
		return
	# Use load() to avoid a hard class_name reference at parse time
	# (prevents load-order issues when base_enemy compiles before enemy_animator).
	const ANIM_SCRIPT := "res://scenes/enemy/enemy_animator.gd"
	var animator_class = load(ANIM_SCRIPT)
	if animator_class == null:
		push_warning("BaseEnemy: enemy_animator.gd not found — animations disabled")
		return
	_anim = animator_class.new(root)


# ── Personalidad de aggro ─────────────────────────────────────────────────────

## Resuelve los parámetros de comportamiento según el perfil asignado.
## Llamado en _ready DESPUÉS de _on_enemy_ready — subclases pueden cambiar
## stats en _on_enemy_ready y los multiplicadores se aplican correctamente.
## DEFAULT: no modifica nada → comportamiento original intacto.
func _apply_personality() -> void:
	# Guardar posición home SIEMPRE — usada por TERRITORIAL y SKITTISH.
	# _on_enemy_ready puede haber movido global_position (hawk sube a fly_height),
	# así que leemos la posición real después de ese setup.
	_home_position = global_position

	match personality:
		AggroPersonality.DEFAULT:
			# Sin cambios — todos los parámetros quedan en sus valores export por defecto.
			pass

		AggroPersonality.HUNTER_FAST:
			detection_mult = 1.8        # Detection 80% más grande
			speed_mult = 1.4            # 40% más rápido en persecución
			pursue_persistence = 30.0   # Persigue hasta 30m extra antes de rendirse
			print("[AggroPersonality] %s → HUNTER_FAST (det×%.1f spd×%.1f persist=%.0fm)" % [
				get_display_name(), detection_mult, speed_mult, pursue_persistence])

		AggroPersonality.JUGGERNAUT_SLOW:
			detection_mult = 0.9        # Detección ligeramente reducida (no vigila lejos)
			speed_mult = 0.7            # 30% más lento
			pursue_persistence = 999.0  # Jamás abandona (efectivamente infinito)
			print("[AggroPersonality] %s → JUGGERNAUT_SLOW (det×%.1f spd×%.1f NEVER_GIVES_UP)" % [
				get_display_name(), detection_mult, speed_mult])

		AggroPersonality.CURIOUS:
			detection_mult = 1.0        # Detection normal
			speed_mult = 1.0
			curiosity_approach_speed = 0.4   # Se acerca al 40% de la speed base
			# CURIOUS solo ataca cuando el jugador entra en attack_range*1.5 o provoca.
			# La lógica de ataque se mantiene en _physics_process vía is_provoked.
			print("[AggroPersonality] %s → CURIOUS (approach=%.0f%% speed)" % [
				get_display_name(), curiosity_approach_speed * 100.0])

		AggroPersonality.SKITTISH:
			detection_mult = 1.2        # Detección 20% mayor (nervioso, muy alerta)
			speed_mult = 1.3            # 30% más rápido al huir
			flee_radius = 6.0           # Huye si el jugador se acerca a < 6m
			print("[AggroPersonality] %s → SKITTISH (flee_r=%.1fm spd×%.1f)" % [
				get_display_name(), flee_radius, speed_mult])

		AggroPersonality.TERRITORIAL:
			detection_mult = 1.0
			speed_mult = 1.0
			territorial_radius = 12.0   # Territorio de 12m desde el spawn
			pursue_persistence = 0.0    # No persigue fuera del territorio
			print("[AggroPersonality] %s → TERRITORIAL (radius=%.1fm home=%s)" % [
				get_display_name(), territorial_radius, str(_home_position)])


func _setup_nameplate() -> void:
	# Determinar nombre para mostrar
	var show_name: String = display_name
	if show_name == "":
		# Auto-detect from scene filename
		show_name = scene_file_path.get_file().get_basename().capitalize()

	# Root del nameplate (billboard — siempre mira la cámara)
	_nameplate = Node3D.new()
	_nameplate.name = "Nameplate"
	add_child(_nameplate)

	# Posicionar encima del enemigo
	var height_offset := 2.0
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col:
		height_offset = col.position.y + 1.2
	_nameplate.position = Vector3(0, height_offset, 0)
	_nameplate.visible = false

	# Nombre + Nivel
	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.text = "%s  Lv.%d" % [show_name, enemy_level]
	_name_label.font_size = 32
	_name_label.pixel_size = 0.00055  # ajuste final — legible sin saturar
	_name_label.fixed_size = true
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.width = 600.0  # ancho suficiente para "Bandido Arquero Lv.1"
	_name_label.modulate = Color(1, 1, 1, 0.9)
	_name_label.outline_modulate = Color(0, 0, 0, 0.8)
	_name_label.outline_size = 6
	_name_label.position = Vector3(0, 0.12, 0)
	_nameplate.add_child(_name_label)

	# Barra HP — fondo (gris oscuro)
	var bar_width := 0.8
	var bar_height := 0.06
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test = true
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_hp_bar_bg = MeshInstance3D.new()
	_hp_bar_bg.name = "HPBarBG"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width, bar_height)
	bg_mesh.material = bg_mat
	_hp_bar_bg.mesh = bg_mesh
	_nameplate.add_child(_hp_bar_bg)

	# Barra HP — relleno (verde → rojo según vida)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.8, 0.2, 0.9)
	fill_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.no_depth_test = true
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_hp_bar_fill = MeshInstance3D.new()
	_hp_bar_fill.name = "HPBarFill"
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(bar_width, bar_height)
	fill_mesh.material = fill_mat
	_hp_bar_fill.mesh = fill_mesh
	_nameplate.add_child(_hp_bar_fill)


func _update_nameplate() -> void:
	if _nameplate == null or target == null:
		return
	# No actualizar el nameplate si el enemigo está muerto (evita que el tween
	# de muerte arrastre también el nameplate encogiéndolo)
	if is_dead:
		_nameplate.visible = false
		return

	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		_nameplate.visible = false
		return

	var dist: float = global_position.distance_to(cam.global_position)

	# Siempre visible si está cerca (<12m)
	# Visible hasta 25m si el jugador apunta al enemigo (centro de pantalla)
	var show := false
	if dist <= NAMEPLATE_VISIBLE_RANGE:
		show = true
	elif dist <= NAMEPLATE_AIM_RANGE:
		# Check si la cámara apunta hacia este enemigo (dot product)
		var to_enemy: Vector3 = (global_position - cam.global_position).normalized()
		var cam_forward: Vector3 = -cam.global_transform.basis.z.normalized()
		if to_enemy.dot(cam_forward) > 0.95:  # ~18 grados
			show = true

	_nameplate.visible = show

	# Registrar avistamiento en el diario UNA SOLA VEZ (no cada frame)
	if show and not _sighted_once and Journal:
		Journal.sight(enemy_type)
		_sighted_once = true

	if not show:
		return

	# Actualizar barra de HP
	var hp_ratio: float = health / _max_health if _max_health > 0 else 0.0
	hp_ratio = clampf(hp_ratio, 0.0, 1.0)

	# Escala horizontal del fill según vida
	_hp_bar_fill.scale.x = hp_ratio
	# Offset para que la barra se vacíe de derecha a izquierda
	_hp_bar_fill.position.x = -(1.0 - hp_ratio) * 0.25

	# Color: verde → amarillo → rojo
	var fill_mat: StandardMaterial3D = _hp_bar_fill.mesh.material as StandardMaterial3D
	if fill_mat:
		if hp_ratio > 0.5:
			fill_mat.albedo_color = Color(0.2, 0.8, 0.2, 0.9)  # verde
		elif hp_ratio > 0.25:
			fill_mat.albedo_color = Color(0.9, 0.8, 0.1, 0.9)  # amarillo
		else:
			fill_mat.albedo_color = Color(0.9, 0.2, 0.1, 0.9)  # rojo


func _physics_process(delta: float) -> void:
	if has_meta("is_preview"):
		return
	_update_nameplate()

	if is_dead:
		return

	_tick_statuses(delta)
	_apply_gravity(delta)
	# Tickear alerta: si fue atacado hace poco, el flag persiste X segundos
	# e ignora detection_range en _should_pursue. Al llegar a 0, vuelve a
	# depender de la distancia normal.
	if _alert_time_left > 0.0:
		_alert_time_left = maxf(_alert_time_left - delta, 0.0)
	_validate_target()

	# Stun pausa AI (movement + attack). Gravedad + knockback siguen aplicando arriba.
	if has_status(&"stun"):
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if target == null:
		# Re-scan: player pudo haber spawneado DESPUÉS del _ready del enemy
		# (change_scene + instanciación diferida). Intentamos adquirir cada frame en idle.
		_try_acquire_target()
	if target == null:
		_idle_behavior(delta)
		move_and_slide()
		return

	var distance = global_position.distance_to(target.global_position)
	var should_chase = _should_pursue(distance)

	# _should_pursue ya gestiona detection_range + alert flag internamente.
	# Antes teníamos un doble check `and distance <= detection_range` acá que
	# reintroducía el límite incluso cuando había alert por daño.
	if should_chase:
		# ── SKITTISH: huir del jugador en lugar de perseguir ──────────────────
		if personality == AggroPersonality.SKITTISH:
			_process_skittish(delta, distance)
			move_and_slide()
			return

		# ── CURIOUS: acercarse lento, atacar solo si muy cerca o provocado ────
		if personality == AggroPersonality.CURIOUS:
			_look_at_target()
			var attack_threshold := attack_range * 1.5
			if distance > attack_threshold and not is_provoked:
				_move_toward_target_curious(delta)
			elif distance > attack_range:
				_move_toward_target(delta)
			else:
				velocity.x = 0
				velocity.z = 0
				if (is_provoked or distance <= attack_range) and can_attack and target.has_method("take_damage"):
					perform_attack()
			move_and_slide()
			return

		_look_at_target()

		if distance > attack_range:
			_move_toward_target(delta)
		else:
			velocity.x = 0
			velocity.z = 0
			if can_attack and target.has_method("take_damage"):
				perform_attack()
	else:
		# ── TERRITORIAL: volver al home cuando el jugador sale del territorio ─
		if personality == AggroPersonality.TERRITORIAL:
			_process_territorial_leash(delta)
			move_and_slide()
			return
		_idle_behavior(delta)

	move_and_slide()
	# Drive animation state from actual horizontal speed after physics step.
	if _anim != null and not is_dead:
		var hspeed := Vector2(velocity.x, velocity.z).length()
		_anim.play_state(hspeed)


# ---------------------------------------------------------------------------
# Status Effects — canon _status_effects.md §2
# Fase 1 soporta stun / bleed / weak. Otros (burn/slow/fear/silence/taunt)
# vendrán en fases por-clase que los apliquen.
# ---------------------------------------------------------------------------

## Aplica un status effect. duration = segundos (refresh-to-max si ya activo).
## source es el Node atacante — usado para bleed (STR source).
func apply_status(name: StringName, duration: float, source: Node = null) -> void:
	if is_dead or duration <= 0.0:
		return
	match name:
		&"stun":
			_apply_stun(duration)
		&"bleed":
			_apply_bleed(duration, source)
		&"weak":
			_apply_weak(duration)
		_:
			push_warning("BaseEnemy.apply_status: '%s' no implementado (Fase 1 soporta stun/bleed/weak)" % name)


func has_status(name: StringName) -> bool:
	return status_effects.has(name)


func get_status_time_left(name: StringName) -> float:
	if not status_effects.has(name):
		return 0.0
	return float(status_effects[name].get("time_left", 0.0))


func _apply_stun(duration: float) -> void:
	var existing: Dictionary = status_effects.get(&"stun", {})
	var cur: float = float(existing.get("time_left", 0.0))
	status_effects[&"stun"] = {"time_left": maxf(cur, duration)}
	status_applied.emit(&"stun", duration)


func _apply_bleed(duration: float, source: Node) -> void:
	# Bleed ignora armor. Dmg/tick: canon physical_v2(8, 0, STR, level, 0.7).
	# Fase 1: cálculo simple — tomamos STR del source y lvl del player source.
	var source_str: int = 0
	var source_level: int = 1
	if source != null:
		if source.has_method("get_effective_stat"):
			source_str = source.get_effective_stat("str")
		if "level" in source:
			source_level = source.level
	var dmg_per_tick: float = 8.0 + float(source_str) * 0.7 * 2.0  # aprox physical_v2 con class_mult 0.7
	var existing: Dictionary = status_effects.get(&"bleed", {})
	var cur: float = float(existing.get("time_left", 0.0))
	status_effects[&"bleed"] = {
		"time_left": maxf(cur, duration),
		"tick_timer": 1.0,
		"dmg_per_tick": dmg_per_tick,
		"source_level": source_level,
	}
	status_applied.emit(&"bleed", duration)


func _apply_weak(duration: float) -> void:
	var existing: Dictionary = status_effects.get(&"weak", {})
	var cur: float = float(existing.get("time_left", 0.0))
	status_effects[&"weak"] = {
		"time_left": maxf(cur, duration),
		"dmg_mult": 0.75,  # canon −25% outgoing
	}
	status_applied.emit(&"weak", duration)


func _tick_statuses(delta: float) -> void:
	if status_effects.is_empty():
		return
	var to_remove: Array = []
	for name in status_effects.keys():
		var data: Dictionary = status_effects[name]
		data["time_left"] = float(data.get("time_left", 0.0)) - delta
		if name == &"bleed":
			var tt: float = float(data.get("tick_timer", 1.0)) - delta
			if tt <= 0.0:
				# Tick dmg, ignora armor (directo a health sin apply_physical_defense)
				var dmg: float = float(data.get("dmg_per_tick", 0.0))
				health -= dmg
				_flash_damage()
				tt = 1.0
			data["tick_timer"] = tt
		if data["time_left"] <= 0.0:
			to_remove.append(name)
		if health <= 0.0:
			break  # resto se limpia en die
	for name in to_remove:
		status_effects.erase(name)
		status_removed.emit(name)
	# Si bleed mató al enemy, disparar death normal
	if health <= 0.0 and not is_dead:
		die()


## Multiplicador de daño saliente — respeta Weak canon.
func outgoing_damage_mult() -> float:
	if has_status(&"weak"):
		return float(status_effects[&"weak"].get("dmg_mult", 0.75))
	return 1.0


## Determina si este enemigo debería perseguir al jugador
## Canon 2026-04-23: si está en alerta (recibió daño recientemente), persigue
## SIN importar distance — ya sabe quién lo atacó y va a buscarlo.
## DEFAULT path es idéntico al original — personalidades agregan sus propias reglas.
func _should_pursue(distance: float) -> bool:
	# Alerta por daño: override universal (incluye DEFAULT).
	if _alert_time_left > 0.0:
		return true

	# ── Ramas de personalidad (no-DEFAULT) ────────────────────────────────────
	match personality:
		AggroPersonality.HUNTER_FAST:
			var effective_range: float = detection_range * detection_mult
			if aggression == AggressionType.NEUTRAL and not is_provoked:
				return false
			# Persiste mientras no supere detection_range + pursue_persistence
			return distance <= effective_range + pursue_persistence

		AggroPersonality.JUGGERNAUT_SLOW:
			if aggression == AggressionType.NEUTRAL and not is_provoked:
				return false
			# pursuit_persistence = 999 → siempre persigue si alguna vez aggro
			var effective_range: float = detection_range * detection_mult
			return distance <= effective_range + pursue_persistence

		AggroPersonality.CURIOUS:
			# Solo ataca si está provocado (tomó daño) o el jugador está muy cerca.
			# La aproximación lenta se maneja en _move_toward_target.
			var effective_range: float = detection_range * detection_mult
			if is_provoked:
				return distance <= effective_range
			# Acercarse a curiosear si está en rango pero sin aggro real
			return distance <= effective_range

		AggroPersonality.SKITTISH:
			# SKITTISH no persigue — se aleja si el jugador se acerca.
			# El "ataque" ocurre solo cuando está acorralado (_cornered_timer).
			# Retornar true para que _physics_process ejecute el movimiento de huida
			# (que overrideamos en _move_toward_target).
			var effective_range: float = detection_range * detection_mult
			return distance <= effective_range

		AggroPersonality.TERRITORIAL:
			# Solo aggro si el jugador está dentro del territorio.
			if distance > territorial_radius:
				# Si ya había aggro y salió del territorio, leash de vuelta.
				return false
			if aggression == AggressionType.NEUTRAL and not is_provoked:
				return false
			return distance <= detection_range * detection_mult

	# ── DEFAULT: path original intacto ────────────────────────────────────────
	if aggression == AggressionType.AGGRESSIVE:
		return distance <= detection_range
	# NEUTRAL: solo si fue provocado
	return is_provoked and distance <= detection_range


## Comportamiento cuando no persigue — override para deambular
func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


## Movimiento hacia el target — override para movimiento custom (ej: saltos)
## speed_mult se aplica aquí para HUNTER_FAST / JUGGERNAUT_SLOW.
## DEFAULT (speed_mult=1.0) → idéntico al original.
func _move_toward_target(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed * speed_mult
	velocity.z = direction.z * speed * speed_mult


## CURIOUS: acercarse lento para investigar (no en ataque todavía)
func _move_toward_target_curious(_delta: float) -> void:
	var direction = (target.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed * curiosity_approach_speed
	velocity.z = direction.z * speed * curiosity_approach_speed


## SKITTISH: huir del jugador o atacar si acorralado.
## Se llama desde _physics_process cuando personality==SKITTISH y should_chase.
func _process_skittish(delta: float, distance: float) -> void:
	if distance <= flee_radius:
		# Intentar huir en dirección opuesta al jugador
		_is_fleeing_skittish = true
		var away := (global_position - target.global_position).normalized()
		away.y = 0
		# Verificar si hay espacio: raycast hacia la dirección de huida
		var can_flee := _has_escape_space(away)
		if can_flee:
			_cornered_timer = 0.0
			_look_at_target()
			velocity.x = away.x * speed * speed_mult
			velocity.z = away.z * speed * speed_mult
		else:
			# Acorralado — atacar después del timeout
			_cornered_timer += delta
			if _cornered_timer >= _CORNERED_TIMEOUT:
				_look_at_target()
				velocity.x = 0
				velocity.z = 0
				if can_attack and target.has_method("take_damage"):
					perform_attack()
	else:
		# Fuera del flee_radius — idle normal
		_is_fleeing_skittish = false
		_cornered_timer = 0.0
		_idle_behavior(delta)


## Verifica si hay espacio para escapar en la dirección dada (raycast 3m).
func _has_escape_space(direction: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_from := global_position + Vector3(0, 0.5, 0)
	var ray_to := ray_from + direction * 3.0
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collision_mask = 1  # Solo world geometry
	var hit := space.intersect_ray(query)
	return hit.is_empty()  # sin obstáculo = puede escapar


## TERRITORIAL: volver al home cuando el jugador salió del territorio.
func _process_territorial_leash(delta: float) -> void:
	var dist_from_home := global_position.distance_to(_home_position)
	if dist_from_home < 1.5:
		# Ya en casa — idle normal
		_idle_behavior(delta)
		return
	# Marchar de vuelta al home
	var direction := (_home_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Aplicar knockback como impulso directo (no acumulativo)
	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		if knockback_velocity.y > 0:
			velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 10.0)
	else:
		knockback_velocity = Vector3.ZERO


## Aplica knockback al enemigo. hit_direction = dirección del golpe, force = fuerza base
func apply_knockback(hit_direction: Vector3, force: float, attacker_str: int = 0) -> void:
	if is_dead:
		return
	var effective_force = force + (attacker_str * 0.05)
	effective_force *= (1.0 - knockback_resistance) / maxf(mass, 0.3)
	knockback_velocity = hit_direction.normalized() * effective_force
	_on_knockback(knockback_velocity)


func _validate_target() -> void:
	if target == null:
		return
	if not is_instance_valid(target):
		target = null
		return
	# Canon Danzante: enemies NO pueden mantener target en stealth (rompería la mecánica).
	# Cuando salga del stealth, la adquisición normal (idle → pursue) lo vuelve a fichar.
	var stealth: Variant = target.get("is_in_stealth")
	if stealth != null and stealth == true:
		target = null
		return
	# Canon downed (2026-04-23): player caído ya no es objetivo — enemies dropean
	# el agro y buscan otro. Al revivir, la adquisición normal lo ficha de nuevo.
	var downed: Variant = target.get("is_downed")
	if downed != null and downed == true:
		target = null


# Adquiere el primer player válido del grupo "player" — viv@, no-stealth, valid.
# Se llama desde _physics_process cuando target == null para re-scan continuo.
# Fix necesario para casos change_scene + spawn diferido donde el enemy hizo
# _ready antes que el player existiera en el tree.
func _try_acquire_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if not is_instance_valid(p):
			continue
		if p.get("is_dead") == true:
			continue
		if p.get("is_downed") == true:
			continue  # canon 2026-04-23: downed NO es objetivo
		var stealth: Variant = p.get("is_in_stealth")
		if stealth != null and stealth == true:
			continue
		target = p
		return


func _look_at_target() -> void:
	var look_pos: Vector3 = target.global_position
	look_pos.y = global_position.y
	# look_at() con origen y destino en la MISMA posición no tiene dirección que mirar y
	# emite error. Pasa de verdad: un spawn superpuesto, un teleport, un enemigo que alcanza
	# al jugador exacto. No hay a dónde girar — mantener el rumbo es la respuesta correcta.
	if global_position.distance_squared_to(look_pos) < 0.0001:
		return
	look_at(look_pos)


func perform_attack() -> void:
	if has_status(&"stun"):
		return  # stun pausa ataque (canon _status_effects.md §2.2)
	can_attack = false
	# Telegraph the attack with an animation (no-op when _anim is nil).
	if _anim != null:
		_anim.play_attack()
	if is_instance_valid(target):
		# Weak reduce dmg saliente −25% (canon §2.3).
		# Pasar self como attacker permite que el player gatille Bloqueo Perfecto reflejo.
		target.take_damage(damage * outgoing_damage_mult(), "", self)
		_on_post_attack_hit()
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self):
		return
	if not is_dead:
		can_attack = true


## Hook virtual — se llama justo después del take_damage exitoso de perform_attack().
## Default no-op. Override en subclases (bird) para push-back, knockback custom, etc.
## DRY-fix 2026-05-08: bird ya no necesita override perform_attack completo.
func _on_post_attack_hit() -> void:
	pass


func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0, attacker_str := 0, attacker: Node = null, element: String = "physical", is_crit: bool = false) -> void:
	if is_dead:
		return

	# Provocar si es neutral
	if aggression == AggressionType.NEUTRAL and not is_provoked:
		is_provoked = true

	# Aggro por daño — canon 2026-04-23. Si el attacker es un player válido
	# (vivo, no downed, no stealth), fichar target inmediato Y activar el flag
	# de alerta para ignorar detection_range durante _ALERT_DURATION_S. Sin el
	# flag, un arquero disparando desde 20m fichaba target pero _physics_process
	# no perseguía porque distance > detection_range (15m).
	if attacker != null and is_instance_valid(attacker) and attacker.is_in_group("player"):
		var atk_dead: bool = attacker.get("is_dead") == true
		var atk_downed: bool = attacker.get("is_downed") == true
		var atk_stealth_v: Variant = attacker.get("is_in_stealth")
		var atk_stealth: bool = atk_stealth_v != null and atk_stealth_v == true
		if not atk_dead and not atk_downed and not atk_stealth:
			target = attacker
			_alert_time_left = _ALERT_DURATION_S

	health -= amount
	_flash_damage()

	# ── Floating Damage Number ────────────────────────────────────────────────
	_spawn_damage_number(int(amount), is_crit, element)

	# ── SFX hit ──────────────────────────────────────────────────────────────
	if AudioManager:
		AudioManager.play_sfx(&"enemy_hit_flesh", global_position)

	if knockback_force > 0.0 and hit_direction != Vector3.ZERO:
		apply_knockback(hit_direction, knockback_force, attacker_str)

	# Killing blow tracking — solo el ultimo attacker cuenta (canon v2 party-auto).
	if health <= 0:
		if attacker != null and is_instance_valid(attacker) and attacker.has_method("get_profile_id"):
			_killer_profile_id = str(attacker.call("get_profile_id"))
		die()


func _flash_damage() -> void:
	# Re-entrancy guard: a 2nd call during the 0.2s await would snapshot the
	# red material as "original" → enemy stuck red permanently.
	if _is_flashing:
		return
	_is_flashing = true

	# Flash the procedural mesh (enemies without a gltf Model subtree).
	# Skip when mesh.visible == false (golem/bandits hide the proc mesh) to
	# avoid a wasted 0.2s await before the gltf flash below.
	if mesh and mesh.mesh and mesh.visible:
		var material = mesh.get_surface_override_material(0)
		if material == null:
			material = mesh.mesh.surface_get_material(0)
			if material:
				material = material.duplicate()
				mesh.set_surface_override_material(0, material)
		if material and material is StandardMaterial3D:
			material.albedo_color = Color(1, 0, 0)
			await get_tree().create_timer(0.2).timeout
			if not is_instance_valid(self) or is_dead:
				_is_flashing = false
				return
			material.albedo_color = default_color

	# Flash the gltf Model subtree (golem, bandits, slimes, and any enemy using
	# a loaded .gltf).  gltf models are SKINNED — MeshInstance3D nodes live under
	# a generated Skeleton3D, NOT as direct children of the model root.
	# find_children("*", "MeshInstance3D", true, false) recurses the full subtree.
	var model_root: Node3D = _get_anim_model_root()
	if model_root == null:
		_is_flashing = false
		return
	var mesh_nodes: Array = model_root.find_children("*", "MeshInstance3D", true, false)
	if mesh_nodes.is_empty():
		_is_flashing = false
		return
	# Save originals and apply red tint via material_override.
	# Originals are captured here (once, while _is_flashing guards re-entry) so
	# a concurrent call cannot overwrite them with the red material.
	var originals: Array = []
	for mi: MeshInstance3D in mesh_nodes:
		originals.append(mi.material_override)
		var red_mat := StandardMaterial3D.new()
		red_mat.albedo_color = Color(1.0, 0.2, 0.2)
		mi.material_override = red_mat
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(self) or is_dead:
		_is_flashing = false
		return
	# Restore originals (null = no override, correct to restore too).
	for i in range(mesh_nodes.size()):
		if is_instance_valid(mesh_nodes[i]):
			mesh_nodes[i].material_override = originals[i]
	_is_flashing = false


func die() -> void:
	is_dead = true
	remove_from_group("enemies")
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	if target and target.has_method("gain_xp"):
		target.gain_xp(xp_reward)
	# Registrar kill en el diario
	if Journal:
		Journal.record_kill(enemy_type)
	# Registrar kill en el tracker de títulos
	if TitleTracker:
		TitleTracker.on_enemy_killed(enemy_type)

	# ── SFX muerte + CameraShake ─────────────────────────────────────────────
	var is_boss: bool = sub_tier == SubTier.BOSS or enemy_tier >= 10
	if AudioManager:
		AudioManager.play_sfx(&"enemy_die_slime", global_position)
	if CameraShake:
		if is_boss:
			CameraShake.shake_heavy()
		else:
			CameraShake.shake_light()

	# ── Floor clear ──────────────────────────────────────────────────────────
	# Hooked here, not in king_slime.gd: every boss dies through die(), so the
	# floor-clear loop closes for future bosses without touching each one.
	if is_boss:
		_report_floor_cleared()

	died.emit(self)
	_spawn_loot()
	_on_death()
	# Play death animation if available (no-op when _anim is nil).
	# The shrink tween is delayed slightly so the death clip is visible before
	# the enemy shrinks away. 0.6s covers most death clips without feeling slow.
	if _anim != null and _anim.is_valid():
		_anim.play_death()
		await get_tree().create_timer(_death_anim_hold()).timeout
		if not is_instance_valid(self):
			return
	if not _death_clip_disposes_body():
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()


## How long to let the death clip play before the body is disposed of.
## Override alongside _death_clip_disposes_body when a clip needs its full run.
func _death_anim_hold() -> float:
	return 0.6


## Whether the death CLIP already removes the body from view on its own.
##
## The default shrink tween exists for mobs that just stop — it scales the whole
## node to nothing. On a mob whose death clip resolves the body itself (a slime
## bursting into droplets that soak into the ground) that tween shrinks the
## droplets mid-flight and destroys the effect, so those subclasses return true
## and get a plain queue_free once the clip is done.
func _death_clip_disposes_body() -> bool:
	return false


func _spawn_loot() -> void:
	var loot: Dictionary = LootTable.roll(enemy_type)
	# Canon v2: party-auto. Killer profile_id drive ownership; kill por ambiente → "".
	DropController.spawn_drops(global_position, loot, self, _killer_profile_id)


## Raycast hacia abajo desde pos para encontrar el suelo — evita que los drops floten.
func _ground_drop_position(pos: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_from: Vector3 = pos + Vector3(0, 2.0, 0)
	var ray_to: Vector3 = pos + Vector3(0, -5.0, 0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collision_mask = 1  # Layer World
	var hit: Dictionary = space.intersect_ray(query)
	if not hit.is_empty():
		return Vector3(pos.x, hit.position.y + 0.05, pos.z)
	# Fallback: 0.8m debajo (aprox feet level para la mayoría de enemigos)
	return pos - Vector3(0, 0.8, 0)


## Instancia un FloatingDamageNumber en world-space sobre este enemigo.
func _spawn_damage_number(amount: int, is_crit: bool, element: String) -> void:
	const FDN_PATH := "res://scenes/fx/floating_damage_number.tscn"
	if not ResourceLoader.exists(FDN_PATH):
		return
	var fdn_scene: PackedScene = ResourceLoader.load(FDN_PATH, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	if fdn_scene == null:
		return
	var fdn = fdn_scene.instantiate()
	if fdn == null:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	scene_root.add_child(fdn)
	fdn.global_position = global_position + Vector3(0, 1.5, 0)
	fdn.setup(amount, is_crit, element)


## Persists the floor clear on the active world and tells the HUD to celebrate it.
## enemy_tier is the floor this boss belongs to (1-100), so it IS the cleared floor.
## Guarded on WorldManager having an active world: a boss killed from a dev/test
## scene (no world selected) still dies normally, it just records nothing.
func _report_floor_cleared() -> void:
	if GameManager.world_index < 0:
		return
	var trophy := StringName("trophy_%s" % enemy_type)
	var is_first_clear: bool = WorldManager.mark_floor_cleared(enemy_tier, trophy)

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_floor_cleared"):
		hud.show_floor_cleared(enemy_tier, display_name if display_name != "" else enemy_type, is_first_clear)


## Override para efectos de muerte custom
func _on_death() -> void:
	pass


## Override para reacciones de knockback custom (ej: slime jelly bounce)
func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
