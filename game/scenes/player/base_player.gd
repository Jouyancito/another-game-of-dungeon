extends CharacterBody3D
class_name BasePlayer

# Movimiento
@export var speed := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.003
@export var crouch_height := 0.9
@export var stand_height := 1.8

# Combate (los valores se sobreescriben en cada clase)
@export var attack_range := 3.0
@export var heavy_cooldown := 0.6

# Atributos
@export var str_stat := 5
@export var int_stat := 5
@export var dex_stat := 5
@export var def_stat := 5
@export var vit_stat := 5

# Resistencias elementales (0.0 a 0.75)
@export var res_fire := 0.0
@export var res_ice := 0.0
@export var res_lightning := 0.0
@export var res_poison := 0.0
@export var res_void := 0.0

# HP/MP base (antes de aplicar VIT/INT)
@export var base_health := 100.0
@export var base_mana := 80.0

# Multiplicadores de daño por clase — canon balance_v2.md §2.3-2.4.
# Warrior 1.5 físico, Mage 1.5 mágico. Cada clase los ajusta en _on_class_ready().
@export var class_mult_physical: float = 1.0
@export var class_mult_magic: float = 1.0

# Regeneración
@export var hp_regen_delay := 15.0

# Stats calculados
var max_health: float
var max_mana: float
var health: float
var mana: float

# Progresión
var level := 1
var xp := 0.0
var xp_to_next_level := 100.0
var stat_points := 0

# Señales para el HUD
signal health_changed(new_value: float, max_value: float)
signal mana_changed(new_value: float, max_value: float)
signal xp_changed(xp: float, xp_max: float, level: int)
signal player_died
signal level_up(new_level: int, points: int)
# Downed state (canon MVP #5) — player entra downed antes de morir.
signal player_downed(player: BasePlayer)
signal player_revived(player: BasePlayer, healer: Node)

# Identidad persistente — canon drop-ownership v2.
# profile_id sobrevive a reload/respawn. Futuro MMO: asignado server-side.
var profile_id: String = ""

# Support window — cleric/buffer registra heal/buff aca.
# Dict: supporter_profile_id → timestamp unix del ultimo support.
# Nunca se limpia: check es now-ts<10s, entries viejas se ignoran solas.
var last_support_ts: Dictionary = {}

# Loot / Inventario / Equipamiento
var inventory: Inventory
var equipment: Equipment
var gold := 0
@export var pickup_range := 3.0
signal gold_changed(amount: int)
signal item_picked_up(item_id: String, quantity: int)
signal equipment_changed

# Estado interno
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_attack := true
var is_dead := false
# Downed state (canon MVP #5): el player entra acá ANTES de muerte real.
# Si no revive en downed_time_s, _actual_die() se ejecuta y drop/loot se dispara.
# Canon 2026-04-23 v2: total 15s en 3 tramos de arrastre, más lento que v1.
#   15s-5s restantes  → speed × 0.3 (arrastre normal, 10s)
#   5s-2s restantes   → speed × 0.2 (agotándose, 3s)
#   2s-0s restantes   → speed × 0.1 (apenas se mueve, 2s)
var is_downed := false
@export var downed_time_s: float = 15.0
var _downed_time_left: float = 0.0
var is_holding_attack := false
var dash_locked := false  # PlayerSkills lo alza durante tween de Embestida — WASD y vel enemy overrides OFF.
var is_crouching := false
var time_since_last_hit := 0.0
var _reloading := false
var _mouse_delta := Vector2.ZERO  # Input acumulado del mouse — se aplica en _process

# Knockback — aplicado por enemigos como golem, jefes, etc.
var knockback_velocity := Vector3.ZERO
@export var knockback_resistance := 0.0  # 0.0 = sin resistencia, 1.0 = inmune
@export var mass := 1.0  # influencia cuánto empuja el knockback

# Torch system (phase 1 — sin sombras. Phase 2: shadow_enabled por setting de calidad)
var _torch_light: OmniLight3D = null  # Instancia de luz activa
var _torch_item_id: String = ""       # ID del item de luz activo
var _torch_time_remaining: float = 0.0  # Segundos restantes (0 = infinito)
var _torch_flicker_time: float = 0.0    # Timer para flicker effect

# Skills — hotbar 1-8 + recurso único de clase (Rage/Fe/etc). ClassResource null
# para clases sin recurso único (Mage solo usa MP).
var skills: PlayerSkills = null
var class_resource: ClassResource = null

# Modelos del jugador
var view_model: ViewModel
var world_model: WorldModel

# Referencias
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var capsule_mesh: MeshInstance3D = $MeshInstance3D
# Animation pipeline (wave3). Opcionales — si el rig Mixamo no está importado, degradan a no-op.
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var anim_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var animation_controller: AnimationController3D = get_node_or_null("AnimationController")
@onready var foot_ik: FootIKController = get_node_or_null("FootIKController")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_on_class_ready()
	_load_character_stats()
	recalculate_stats()
	health = max_health
	mana = max_mana
	_setup_player_models()
	_setup_inventory()
	_setup_skills()
	_setup_animation_pipeline()


## Wire AnimationController3D + FootIKController si existen en la escena.
## Si AnimationPlayer carece de anims Mixamo, ambos quedan inactive — fallback Tween WorldModel.
func _setup_animation_pipeline() -> void:
	if animation_controller != null:
		animation_controller.tree = anim_tree
		animation_controller.setup(self, anim_player)
		if anim_tree != null and not anim_tree.animation_finished.is_connected(animation_controller._on_tree_anim_finished):
			anim_tree.animation_finished.connect(animation_controller._on_tree_anim_finished)
	if foot_ik != null:
		foot_ik.setup(self)


## Override en clases derivadas si necesitan setup custom de skills / recursos.
## BasePlayer monta PlayerSkills + (opcionalmente) un ClassResource seteado por _on_class_ready.
func _setup_skills() -> void:
	skills = PlayerSkills.new()
	skills.name = "PlayerSkills"
	add_child(skills)
	if class_resource != null and class_resource.get_parent() == null:
		class_resource.name = "ClassResource"
		add_child(class_resource)
	skills.setup(self, class_resource)
	# Equipar skills default de la clase (override en player.gd / mage.gd)
	_equip_default_skills()
	# VFX wire layer — conecta signals de skills a spawn de VFX
	_setup_skill_vfx_hooks()


## Override en cada clase para rellenar hotbar inicial.
func _equip_default_skills() -> void:
	pass


## Wire layer VFX — conecta signals de PlayerSkills a spawn de VFX .tscn.
## Clases hijas pueden override para registrar sus propias SkillVFXHooks.
func _setup_skill_vfx_hooks() -> void:
	var hooks := SkillVFXHooks.new()
	hooks.name = "SkillVFXHooks"
	add_child(hooks)
	hooks.setup(self)

# Override en cada clase para combat values (speed, base_health, attack_range, etc.)
func _on_class_ready() -> void:
	pass

# Override en cada clase para el color del maniquí
func get_class_color() -> Color:
	return Color(0.7, 0.7, 0.7)  # gris por defecto

func _setup_player_models() -> void:
	# Ocultar la cápsula vieja
	capsule_mesh.visible = false

	var color := get_class_color()

	# ViewModel: brazos en primera persona (hijo de Camera3D)
	view_model = ViewModel.new()
	view_model.name = "ViewModel"
	camera.add_child(view_model)
	view_model.setup(color)

	# WorldModel: cuerpo completo (hijo del player root)
	world_model = WorldModel.new()
	world_model.name = "WorldModel"
	add_child(world_model)
	world_model.setup(color)

	# Configurar cámara: ve world (layer 1) + viewmodel (layer 2), NO ve worldmodel (layer 4)
	camera.cull_mask = 1 | MannequinBuilder.LAYER_VIEW_MODEL  # bits 0 + 1

func _setup_inventory() -> void:
	# Cargar inventario y equipamiento desde save o crear nuevos
	inventory = Inventory.new()
	equipment = Equipment.new()
	GameManager.player_inventory = inventory
	var idx = GameManager.selected_character_index
	if idx >= 0:
		var data = SaveManager.get_character(idx)
		var inv_data: Dictionary = data.get("inventory", {})
		if not inv_data.is_empty():
			inventory.from_save_data(inv_data)
		var eq_data: Dictionary = data.get("equipment", {})
		if not eq_data.is_empty():
			equipment.from_save_data(eq_data)
		gold = data.get("gold", 0)
	GameManager.player_coins = gold
	# Aplicar bonus de equipo existente
	recalculate_stats()

func add_gold(amount: int) -> void:
	gold += amount
	GameManager.player_coins = gold
	gold_changed.emit(gold)
	_save_inventory()

func pickup_item(drop: Node) -> bool:
	# Acepta ItemDrop (legacy), GroundItem (DropController), GoldDrop (sin inventory).
	if drop.has_method("can_pickup_by") and not drop.can_pickup_by(self):
		return false
	# Gold no pasa por inventario — pickup() distribuye entre party.
	if drop is GoldDrop:
		drop.pickup(self)
		return true
	if inventory.auto_place_item(drop.item_id, drop.item_quantity):
		item_picked_up.emit(drop.item_id, drop.item_quantity)
		drop.pickup()
		_save_inventory()
		return true
	return false

func _try_pickup_nearby() -> void:
	var drops: Array[Node] = get_tree().get_nodes_in_group("drops")
	var closest_drop: Node3D = null
	var closest_dist := pickup_range

	for drop_node: Node in drops:
		var item_drop: Node3D = drop_node as Node3D
		if item_drop == null:
			continue
		if not (drop_node is ItemDrop or drop_node is GroundItem or drop_node is GoldDrop):
			continue
		var dist := global_position.distance_to(item_drop.global_position)
		if dist <= pickup_range:
			var to_drop: Vector3 = (item_drop.global_position - camera.global_position).normalized()
			var forward: Vector3 = -camera.global_basis.z
			if to_drop.dot(forward) > 0.5 and dist < closest_dist:
				closest_dist = dist
				closest_drop = item_drop

	if closest_drop:
		pickup_item(closest_drop)


func _try_interact_nearby() -> bool:
	var interactables: Array[Node] = get_tree().get_nodes_in_group("interactables")
	for node: Node in interactables:
		var node3d: Node3D = node as Node3D
		if node3d == null:
			continue
		var dist := global_position.distance_to(node3d.global_position)
		if dist <= pickup_range:
			var to_obj: Vector3 = (node3d.global_position - camera.global_position).normalized()
			var forward: Vector3 = -camera.global_basis.z
			if to_obj.dot(forward) > 0.5:
				if node3d.has_method("open"):
					node3d.call("open", self)
					return true
	return false


var _save_pending := false

func _save_inventory() -> void:
	if _save_pending:
		return
	_save_pending = true
	_do_save_inventory.call_deferred()

func _do_save_inventory() -> void:
	_save_pending = false
	var idx = GameManager.selected_character_index
	if idx >= 0:
		SaveManager.update_character(idx, {
			"inventory": inventory.to_save_data(),
			"equipment": equipment.to_save_data(),
			"gold": gold,
		})

## Equipa un item desde el inventario. Lo saca de la grilla y lo pone en el slot.
## Si ya había algo en el slot, vuelve al inventario.
func equip_item(item_id: String, inventory_pos: Vector2i) -> bool:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
	var slot: String = item_data.get("slot", "")
	if slot == "":
		return false

	# Verificar si el slot tiene item equipado que necesitaría volver al inventario
	# Usar el MISMO resolver que Equipment.equip() para evitar mismatch ring_1/ring_2
	var resolved_slot: String = equipment.resolve_slot(item_data)
	# Guard: slot no reconocido por Equipment.SLOT_NAMES → rechazar ANTES de tocar
	# el inventario. Evita perder el ítem si el .gd de Equipment no conoce el slot.
	if resolved_slot == "":
		push_warning("equip_item: slot '%s' no reconocido para '%s' — item NO equipado, queda en inventario" % [slot, item_id])
		return false
	var would_displace: Dictionary = equipment.slots.get(resolved_slot, {})
	if not would_displace.is_empty():
		var displaced_id: String = would_displace.get("item_id", "")
		if displaced_id != "" and not inventory.has_space_for(displaced_id):
			return false  # No hay espacio para el item desplazado — rechazar antes de modificar nada

	# Sacar del inventario
	var removed: Dictionary = inventory.remove_item_at(inventory_pos)
	if removed.is_empty():
		return false

	# Equipar (puede devolver item desplazado)
	var displaced: Dictionary = equipment.equip(item_id)

	# Si había algo equipado, devolverlo al inventario (espacio ya verificado arriba)
	if not displaced.is_empty():
		var displaced_id: String = displaced.get("item_id", "")
		if displaced_id != "":
			inventory.auto_place_item(displaced_id, 1)

	recalculate_stats()
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	equipment_changed.emit()
	_save_inventory()

	# UX: al equipar una antorcha (o cualquier item de slot "light"), si no hay
	# luz activa, prenderla inmediato — un solo gesto "equipar y encender".
	# El usuario todavía puede apagar/prender con F.
	if slot == "light" and _torch_light == null:
		toggle_torch()

	return true

## Desequipa un item de un slot y lo devuelve al inventario.
func unequip_slot(slot_key: String) -> bool:
	if not equipment.has_item_in_slot(slot_key):
		return false

	var entry: Dictionary = equipment.get_slot(slot_key)
	var item_id: String = entry.get("item_id", "")
	if item_id == "":
		return false

	# Verificar que hay espacio en el inventario
	if not inventory.has_space_for(item_id):
		return false

	equipment.unequip(slot_key)
	inventory.auto_place_item(item_id, 1)
	recalculate_stats()
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	equipment_changed.emit()
	_save_inventory()
	return true

# Carga stats del personaje guardado, o defaults de la clase si es nuevo
func _load_character_stats() -> void:
	var idx = GameManager.selected_character_index
	if idx >= 0:
		var data = SaveManager.get_character(idx)
		if not data.is_empty():
			profile_id = str(data.get("profile_id", ""))
			str_stat = data.get("str_stat", str_stat)
			int_stat = data.get("int_stat", int_stat)
			dex_stat = data.get("dex_stat", dex_stat)
			def_stat = data.get("def_stat", def_stat)
			vit_stat = data.get("vit_stat", vit_stat)
			stat_points = data.get("stat_points", 0)
			level = data.get("level", 1)
			xp = data.get("xp", 0.0)
			xp_to_next_level = Progression.xp_for_level(level)
			return
	# Sin personaje guardado: usar ClassBaseStats.DEFAULTS según la escena
	var scene_path = GameManager.selected_class_scene
	var defaults = ClassBaseStats.DEFAULTS.get(scene_path, {})
	if not defaults.is_empty():
		str_stat = defaults.get("str_stat", str_stat)
		int_stat = defaults.get("int_stat", int_stat)
		dex_stat = defaults.get("dex_stat", dex_stat)
		def_stat = defaults.get("def_stat", def_stat)
		vit_stat = defaults.get("vit_stat", vit_stat)

func recalculate_stats() -> void:
	var bonus: Dictionary = _get_equipment_bonuses()
	var total_vit: int = vit_stat + int(bonus.get("vit", 0))
	var total_int: int = int_stat + int(bonus.get("int", 0))
	# Canon balance_v2 §2.1-2.2 — fórmulas compound decelerada con level.
	max_health = Progression.max_health_v2(base_health, total_vit, level)
	max_mana = Progression.max_mana_v2(base_mana, total_int, level)

func _get_equipment_bonuses() -> Dictionary:
	if equipment:
		return equipment.get_total_bonuses()
	return {}

func get_effective_stat(stat_name: String) -> int:
	var base_val: int
	match stat_name:
		"str": base_val = str_stat
		"int": base_val = int_stat
		"dex": base_val = dex_stat
		"def": base_val = def_stat
		"vit": base_val = vit_stat
		_: return 0
	var bonus: Dictionary = _get_equipment_bonuses()
	return base_val + int(bonus.get(stat_name, 0))

func get_physical_damage(base_dmg: float) -> float:
	var bonus: Dictionary = _get_equipment_bonuses()
	var total_str: int = str_stat + int(bonus.get("str", 0))
	var weapon_dmg: int = equipment.get_weapon_damage() if equipment else 0
	# Canon balance_v2 §2.3 — compound con level + class_mult.
	return DamageFormula.physical_v2(base_dmg, weapon_dmg, total_str, level, class_mult_physical) * _skill_buff_mult()

func get_magic_damage(base_dmg: float) -> float:
	var bonus: Dictionary = _get_equipment_bonuses()
	var total_int: int = int_stat + int(bonus.get("int", 0))
	var weapon_dmg: int = equipment.get_weapon_damage() if equipment else 0
	# Canon balance_v2 §2.4 — compound con level + class_mult.
	return DamageFormula.magic_v2(base_dmg, weapon_dmg, total_int, level, class_mult_magic) * _skill_buff_mult()

func get_dex_damage(base_dmg: float) -> float:
	var bonus: Dictionary = _get_equipment_bonuses()
	var total_dex: int = dex_stat + int(bonus.get("dex", 0))
	var weapon_dmg: int = equipment.get_weapon_damage() if equipment else 0
	return DamageFormula.dex(base_dmg, total_dex, weapon_dmg) * _skill_buff_mult()


## Multiplicador de daño saliente por buffs activos de skills (ej Grito +15%).
## Retorna 1.0 si no hay buffs.
func _skill_buff_mult() -> float:
	if skills == null:
		return 1.0
	return skills.outgoing_damage_mult()

func apply_physical_defense(raw_damage: float, attacker_level: int = 1) -> float:
	var total_def: int = get_effective_stat("def")
	# Canon balance_v2 §2.5 — armor self-capping por attacker_level.
	return DamageFormula.apply_armor_v2(raw_damage, total_def, attacker_level)

func apply_elemental_damage(raw_damage: float, element: String) -> float:
	var res: float = get_effective_resistance(element)
	return DamageFormula.apply_elemental_resistance(raw_damage, res)


## Resistencia efectiva = base + suma items equipados.
## Capeada en DamageFormula.apply_elemental_resistance (cap 0.75 canon balance_v2).
func get_effective_resistance(element: String) -> float:
	var base_res: float = 0.0
	match element:
		"fire": base_res = res_fire
		"ice": base_res = res_ice
		"lightning": base_res = res_lightning
		"poison": base_res = res_poison
		"void": base_res = res_void
		_:
			push_warning("get_effective_resistance: unknown element '%s'" % element)
			return 0.0
	var item_res: float = 0.0
	if equipment:
		var totals: Dictionary = equipment.get_total_resistances()
		item_res = float(totals.get("res_" + element, 0.0))
	return base_res + item_res

func _unhandled_input(event: InputEvent) -> void:
	# TEST: respawn con R (temporal para prototipo)
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and is_dead:
		if not _reloading:
			_reloading = true
			get_tree().reload_current_scene()
		return

	# Bloqueo de acciones en dead/downed — no atacar, no recoger, no castear.
	# Canon downed (MVP #5): player caído espera revive. Mientras, el HUD
	# captura R para respawn temprano (ver hud.gd).
	# La cámara (mouse motion) SIGUE libre — el user puede mirar alrededor.
	if is_dead or is_downed:
		if not (event is InputEventMouseMotion):
			return

	# Interactuar con E — recoger items o abrir cofres
	if event.is_action_pressed("interact"):
		if not _try_interact_nearby():
			_try_pickup_nearby()
		return

	# Toggle antorcha con F
	if event.is_action_pressed("toggle_torch"):
		toggle_torch()
		return

	# Hotbar skills 1-8 — Fase 0 framework. D wirea iconos después.
	if event is InputEventKey and event.pressed and not event.echo and skills != null:
		var kc: int = event.keycode
		if kc >= KEY_1 and kc <= KEY_8:
			var slot: int = kc - KEY_1
			skills.cast_slot(slot)
			return

	# Atacar — cada clase maneja el input de ataque
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				_on_attack_pressed()
		else:
			_on_attack_released()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Durante dash (Embestida): NO rotar el body horizontalmente — el dash sigue
		# el forward inicial. Sí permitimos mover cabeza (pitch) para no frizar la vista.
		if not dash_locked:
			rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

# Override en cada clase
func _on_attack_pressed() -> void:
	pass

func _on_attack_released() -> void:
	is_holding_attack = false

## Aplica knockback al jugador — golem punch, jefes, etc.
## Mismo patrón que base_enemy.apply_knockback() para mantener consistencia.
func apply_knockback(hit_direction: Vector3, force: float) -> void:
	if is_dead:
		return
	var effective_force = force * (1.0 - knockback_resistance) / maxf(mass, 0.3)
	knockback_velocity = hit_direction.normalized() * effective_force

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Downed state — tickear timer + permitir arrastre con speed decreciente.
	# Ver constantes arriba (línea ~92) para los tramos canon del crawl.
	if is_downed:
		_downed_time_left -= delta
		if _downed_time_left <= 0.0:
			_actual_die()
			return
		var crawl_mult: float = 0.3
		if _downed_time_left <= 2.0:
			crawl_mult = 0.1
		elif _downed_time_left <= 5.0:
			crawl_mult = 0.2
		# Gravedad simple (sin jump, sin knockback nuevo durante downed).
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		# WASD básico — el player puede arrastrarse hacia aliados/salida.
		# NO sprint, NO crouch, NO jump.
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed * crawl_mult
			velocity.z = direction.z * speed * crawl_mult
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		move_and_slide()
		return

	_regenerate(delta)

	# Dash activo — tween controla global_position directo. Cortamos WASD/knockback.
	if dash_locked:
		velocity = Vector3.ZERO
		knockback_velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Knockback — si hay velocidad activa, la aplicamos como impulso y decae rápido
	var being_knocked := knockback_velocity.length() > 0.1
	if being_knocked:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		if knockback_velocity.y > 0:
			velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 10.0)
	else:
		knockback_velocity = Vector3.ZERO

	# Agacharse — lerp suave para que no se sienta como caída
	var target_head_y: float
	var target_collider_h: float
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		target_head_y = 0.3
		target_collider_h = crouch_height
	else:
		is_crouching = false
		target_head_y = 0.8
		target_collider_h = stand_height

	var crouch_lerp_speed := 12.0
	head.position.y = lerpf(head.position.y, target_head_y, crouch_lerp_speed * delta)
	collider.shape.height = lerpf(collider.shape.height, target_collider_h, crouch_lerp_speed * delta)

	# Saltar (no agachado)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# Velocidad según estado
	var current_speed := speed
	if is_crouching:
		current_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Si está en knockback, el input NO manda — prevalece la velocidad del golpe
	if not being_knocked:
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Sincronizar modelos con estado de movimiento
	var moving := direction.length() > 0.1
	var sprinting := Input.is_action_pressed("sprint") and not is_crouching
	if view_model:
		view_model.set_moving(moving, sprinting)
	if world_model:
		world_model.set_moving(moving, sprinting)
		world_model.sync_head_rotation(head.rotation.x)

	# AnimationTree blend + foot IK (wave3). No-op si rig Mixamo no importado.
	if animation_controller != null:
		animation_controller.update_locomotion(velocity, sprint_speed, delta)
	if foot_ik != null:
		foot_ik.update(is_on_floor())

	# Mostrar label de item drops cercanos que miramos
	_update_drop_labels()
	# Target frame MMO — panel con nombre/HP/tier del enemigo apuntado
	_update_target_frame()
	_update_torch(delta)

func _update_drop_labels() -> void:
	# Estilo Metin 2: labels de drops siempre visibles dentro de un rango amplio
	# (3x el pickup range) — no hace falta apuntar con el crosshair para verlos.
	var label_range := pickup_range * 3.0
	var forward: Vector3 = -camera.global_basis.z
	var hint_text := ""

	for drop_node: Node in get_tree().get_nodes_in_group("drops"):
		if not drop_node.has_method("show_label"):
			continue
		var drop_node3d: Node3D = drop_node as Node3D
		if drop_node3d == null:
			continue
		var dist := global_position.distance_to(drop_node3d.global_position)
		if dist <= label_range:
			drop_node3d.call("show_label")
		else:
			drop_node3d.call("hide_label")

		# Hint de pickup. Canon v2: oro tambien pickup manual con [E].
		if hint_text == "" and (drop_node is ItemDrop or drop_node is GroundItem or drop_node is GoldDrop) and dist <= pickup_range:
			var to_drop: Vector3 = (drop_node3d.global_position - camera.global_position).normalized()
			if to_drop.dot(forward) > 0.5:
				hint_text = "Presioná [E] para recoger"

	# Labels de interactuables (cofres, etc.) — se muestran al apuntarlos con el crosshair
	for node: Node in get_tree().get_nodes_in_group("interactables"):
		if not node.has_method("show_label"):
			continue
		var node3d: Node3D = node as Node3D
		if node3d == null:
			continue
		var dist := global_position.distance_to(node3d.global_position)
		if dist <= pickup_range:
			var to_obj: Vector3 = (node3d.global_position - camera.global_position).normalized()
			if to_obj.dot(forward) > 0.5:
				node3d.call("show_label")
				if hint_text == "":
					hint_text = "Presioná [E] para interactuar"
				continue
		node3d.call("hide_label")

	# Actualizar HUD con el hint (o ocultarlo si no hay nada apuntado)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("set_pickup_hint_visible"):
		hud.set_pickup_hint_visible(hint_text != "", hint_text)

# Target frame range y cone ahora viven en GameConstants (shared/constants.gd)

func _update_target_frame() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return

	# Buscar el enemigo más centrado y cercano dentro del cono del crosshair.
	# Usa el grupo "enemies" en vez de collision layers (más robusto + no requiere config de layers).
	var cam_pos := camera.global_position
	var cam_forward := -camera.global_basis.z

	var best_enemy: Node = null
	var best_dist := GameConstants.TARGET_FRAME_RANGE
	var current_target: Node = hud._current_target if "_current_target" in hud else null

	for enemy_node: Node in get_tree().get_nodes_in_group("enemies"):
		if not enemy_node is BaseEnemy:
			continue
		var enemy: BaseEnemy = enemy_node as BaseEnemy
		if enemy.is_dead:
			continue
		var enemy_center := enemy.global_position + enemy.target_frame_offset
		var dist := cam_pos.distance_to(enemy_center)
		if dist > GameConstants.TARGET_FRAME_RANGE:
			continue
		var to_enemy := (enemy_center - cam_pos).normalized()
		if to_enemy.dot(cam_forward) < GameConstants.TARGET_FRAME_CONE:
			continue
		# Line of sight — chequear que no haya pared entre la cámara y el enemigo
		var space := get_world_3d().direct_space_state
		var los_query := PhysicsRayQueryParameters3D.create(cam_pos, enemy_center)
		los_query.exclude = [get_rid(), enemy.get_rid()]
		los_query.collision_mask = 1  # Layer World solamente
		var los_hit := space.intersect_ray(los_query)
		if not los_hit.is_empty():
			continue  # hay una pared en el medio — no se ve
		# Es visible y más cercano que el anterior candidato
		if dist < best_dist:
			best_enemy = enemy
			best_dist = dist

	if best_enemy != null:
		if hud.has_method("set_target"):
			hud.set_target(best_enemy)
	else:
		# Sticky targeting: si el current target sigue vivo + en range (ignora cone),
		# lo mantenemos. Útil para bosses grandes que quedan fuera del cono al acercarte.
		if current_target != null and is_instance_valid(current_target) and current_target is BaseEnemy:
			var be: BaseEnemy = current_target as BaseEnemy
			if not be.is_dead:
				var sticky_center := be.global_position + be.target_frame_offset
				var sticky_dist := cam_pos.distance_to(sticky_center)
				if sticky_dist <= GameConstants.TARGET_FRAME_RANGE:
					return  # mantener, no limpiar
		if hud.has_method("clear_target"):
			hud.clear_target()


func _regenerate(delta: float) -> void:
	time_since_last_hit += delta

	# Maná: siempre regenera — usa INT efectivo (base + items)
	if mana < max_mana:
		var mp_regen = Progression.mp_regen_rate(get_effective_stat("int")) * delta
		mana = minf(mana + mp_regen, max_mana)
		mana_changed.emit(mana, max_mana)

	# Vida: solo fuera de combate — usa VIT efectivo (base + items)
	if time_since_last_hit >= hp_regen_delay and health < max_health:
		var hp_regen = Progression.hp_regen_rate(get_effective_stat("vit")) * delta
		health = minf(health + hp_regen, max_health)
		health_changed.emit(health, max_health)

func take_damage(amount: float, element: String = "", attacker: Node = null) -> void:
	if is_dead or is_downed:
		return  # downed state = invul a más dmg (canon MVP #5)
	# G9: invul frames — si skill abrió ventana de invul, ignorar dmg.
	if has_meta("invul_time_left") and float(get_meta("invul_time_left")) > 0.0:
		return
	# Reactive parry (Bloqueo Perfecto) — si hay ventana activa absorbe+refleja.
	if skills != null:
		var parry: Dictionary = skills.try_trigger_reactive(amount, attacker)
		if parry.get("absorbed", false):
			return  # Dmg 100% absorbido — canon Bloqueo Perfecto
	time_since_last_hit = 0.0
	# Canon v2 §2.5 — armor reduction needs attacker level. Fallback 1 si el atacante no lo expone.
	var atk_level: int = 1
	if attacker != null and "level" in attacker:
		atk_level = int(attacker.level)
	var final_damage: float
	if element != "":
		final_damage = apply_elemental_damage(amount, element)
	else:
		final_damage = apply_physical_defense(amount, atk_level)
	health = clamp(health - final_damage, 0, max_health)
	health_changed.emit(health, max_health)
	# Rage gen por %HP perdido (canon _system.md §5ter: +10 por 10% HP perdido).
	# Fórmula canon: (final_damage / max_health) * 100 → +1 Rage por cada 1% HP perdido.
	# Este gen vive acá (no en skill .tres) porque es pasivo de la clase, no per-skill.
	# Solo Warriors con Rage. Otros recursos (Fe/Combo/Concentración/Vida) no escalan por daño recibido.
	if class_resource != null and class_resource.type == ClassResource.Type.RAGE:
		if max_health > 0.0:
			var rage_gained: int = int((final_damage / max_health) * 100.0)
			class_resource.add(rage_gained)
	# ── SFX daño recibido ─────────────────────────────────────────────────────
	if AudioManager:
		AudioManager.play_sfx(&"punch_hit", global_position)
	if health <= 0:
		die()

func heal(amount: float) -> void:
	if is_dead:
		return
	health = clamp(health + amount, 0, max_health)
	health_changed.emit(health, max_health)


## Canon drop-ownership v2: support window 10s.
## Cleric/Buffer llama cuando aplica heal/buff a este player.
func register_support(supporter_profile_id: String) -> void:
	if supporter_profile_id == "":
		return
	last_support_ts[supporter_profile_id] = Time.get_unix_time_from_system()


## Devuelve profile_id persistente. Sobrevive reload/respawn.
func get_profile_id() -> String:
	return profile_id

func use_mana(amount: float) -> bool:
	if mana < amount:
		return false
	mana = clamp(mana - amount, 0, max_mana)
	mana_changed.emit(mana, max_mana)
	return true

func restore_mana(amount: float) -> void:
	mana = clamp(mana + amount, 0, max_mana)
	mana_changed.emit(mana, max_mana)

func gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		stat_points += Progression.STAT_POINTS_PER_LEVEL
		xp_to_next_level = Progression.xp_for_level(level)
		level_up.emit(level, stat_points)
		if TitleTracker:
			TitleTracker.on_level_up(level)
		# ── SFX level up ─────────────────────────────────────────────────────
		if AudioManager:
			AudioManager.play_sfx(&"level_up")
	xp_changed.emit(xp, xp_to_next_level, level)
	save_progress()

func assign_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	match stat_name:
		"str": str_stat += 1
		"int": int_stat += 1
		"dex": dex_stat += 1
		"def": def_stat += 1
		"vit": vit_stat += 1
		_: return false
	stat_points -= 1
	recalculate_stats()
	health = minf(health, max_health)
	mana = minf(mana, max_mana)
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)
	save_progress()
	return true

# Persiste el progreso actual del personaje en SaveManager
func save_progress() -> void:
	var idx: int = GameManager.selected_character_index
	if idx < 0:
		return
	SaveManager.update_character(idx, {
		"level": level,
		"xp": xp,
		"str_stat": str_stat,
		"int_stat": int_stat,
		"dex_stat": dex_stat,
		"def_stat": def_stat,
		"vit_stat": vit_stat,
		"stat_points": stat_points,
	})

# ── Torch System (Phase 1 — sin sombras) ─────────────────────────────────────
# Phase 2 (futuro): agregar shadow_enabled como setting de calidad del shader system.

## Toggle: si no hay antorcha activa, buscar una (primero equipada en slot "light",
## después en inventario) y activarla. Si hay una activa, apagarla.
## Canon 2026-04-23 UX: la F debe encender lo que está equipado sin importar que
## el item ya no esté en la grilla del inventario.
func toggle_torch() -> void:
	if _torch_light != null:
		_remove_torch()
		return

	# 1) Primero el slot equipado "light" — si hay antorcha equipada, esa es la
	# que el user espera que se encienda al apretar F.
	if equipment != null:
		var equipped: Dictionary = equipment.get_slot("light")
		if not equipped.is_empty():
			var equipped_id: String = String(equipped.get("item_id", ""))
			if equipped_id != "":
				var equipped_data: Dictionary = ItemDatabase.get_item(equipped_id)
				if not equipped_data.is_empty() and equipped_data.get("type", "") == "light":
					_equip_torch_item(equipped_id, equipped_data)
					return

	# 2) Fallback — antorchas que quedaron en inventario sin equipar todavía.
	if inventory == null:
		return
	for entry in inventory.items:
		var item_data: Dictionary = ItemDatabase.get_item(entry["item_id"])
		if item_data.is_empty():
			continue
		if item_data.get("type", "") == "light":
			_equip_torch_item(entry["item_id"], item_data)
			return

func _equip_torch_item(item_id: String, item_data: Dictionary) -> void:
	var stats: Dictionary = item_data.get("stats", {})

	_torch_light = OmniLight3D.new()
	_torch_light.name = "TorchLight"
	_torch_light.omni_range = float(stats.get("light_range", 6.0))
	_torch_light.light_energy = float(stats.get("light_energy", 1.5))
	_torch_light.light_color = Color(
		float(stats.get("light_color_r", 1.0)),
		float(stats.get("light_color_g", 0.7)),
		float(stats.get("light_color_b", 0.4))
	)
	_torch_light.shadow_enabled = false  # Phase 2: por setting de calidad
	_torch_light.omni_attenuation = 1.5
	# Posicionar ligeramente adelante y abajo de la cámara — como si fuera sostenido
	_torch_light.position = Vector3(0.3, -0.2, -0.3)
	head.add_child(_torch_light)

	_torch_item_id = item_id
	_torch_time_remaining = float(stats.get("light_duration", 0))
	_torch_flicker_time = 0.0

func _remove_torch() -> void:
	if _torch_light != null and is_instance_valid(_torch_light):
		_torch_light.queue_free()
	_torch_light = null
	_torch_item_id = ""
	_torch_time_remaining = 0.0

func _update_torch(delta: float) -> void:
	if _torch_light == null:
		return

	# Duración (0 = infinito)
	if _torch_time_remaining > 0.0:
		_torch_time_remaining -= delta
		if _torch_time_remaining <= 0.0:
			# Consumir el item y apagar
			if inventory != null and _torch_item_id != "":
				# Remover 1 del stack (busca primer entry matching)
				for entry in inventory.items:
					if entry["item_id"] == _torch_item_id:
						if entry["quantity"] > 1:
							entry["quantity"] -= 1
						else:
							inventory.remove_item_at(entry["grid_pos"])
						break
			_remove_torch()
			return

	# Flicker effect — variación sutil de energy para simular llama
	_torch_flicker_time += delta
	if _torch_flicker_time > 0.08:  # ~12hz
		_torch_flicker_time = 0.0
		var base_energy: float = 1.5  # Fallback
		var item_data: Dictionary = ItemDatabase.get_item(_torch_item_id)
		if not item_data.is_empty():
			base_energy = float(item_data.get("stats", {}).get("light_energy", 1.5))
		# Los orbes arcanos no titilan (magic_light)
		var subtype: String = item_data.get("subtype", "")
		if subtype == "magic_light" or subtype == "biolum":
			_torch_light.light_energy = base_energy
		else:
			_torch_light.light_energy = base_energy + randf_range(-0.25, 0.15)

## Canon MVP #5 — downed state antes de muerte real.
## Cuando HP ≤ 0, el player NO muere instant. Entra en downed, pueden revivirlo.
## Si nadie revive en downed_time_s, _actual_die() ejecuta (drop/loot, signal player_died).
##
## Nota: un player ya downed que recibe más daño NO re-dispara el estado (idempotente).
## Para forzar la muerte instantánea (ej: caer al abismo), usar _actual_die() directo.
func die() -> void:
	if is_dead or is_downed:
		return
	is_downed = true
	_downed_time_left = downed_time_s
	# HP visualmente a 0 — el player no puede accionar. Respawn frame sync.
	health = 0.0
	health_changed.emit(health, max_health)
	_remove_torch()  # Apagar antorcha en downed
	player_downed.emit(self)


## Revive un player downed. Restaura a 30% HP max y resetea el timer.
## Canon MVP #5 — healer (cleric, consumible) llama acá.
func revive(healer: Node = null) -> bool:
	if is_dead:
		return false  # muerte real — no se puede revivir
	if not is_downed:
		return false  # no estaba downed, nada que hacer
	is_downed = false
	_downed_time_left = 0.0
	health = max_health * 0.3
	health_changed.emit(health, max_health)
	player_revived.emit(self, healer)
	return true


## Ejecuta la muerte real (dispara drop/loot + player_died signal).
## Se llama internamente al expirar downed_time_s o desde _physics_process por
## casos de "muerte instantánea" (ej: abismo, scripts específicos).
func _actual_die() -> void:
	if is_dead:
		return
	is_dead = true
	is_downed = false
	# Emitir el signal PRIMERO — si algo más abajo explota (anim, title tracker),
	# el HUD ya se actualizó. Antes teníamos el emit al final y un silent error
	# dejaba al player en limbo sin death_screen.
	player_died.emit()
	_remove_torch()
	if animation_controller != null and animation_controller.has_method("set_dead"):
		animation_controller.set_dead(true)
	if TitleTracker and TitleTracker.has_method("on_player_death"):
		TitleTracker.on_player_death()
