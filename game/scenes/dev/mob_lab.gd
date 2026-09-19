extends Node3D
## mob_lab — banco de pruebas EN VIVO de un mob, sobre piso plano y vacío.
##
## Por qué existe (Joan, 2026-08-24): "ideal para probar sea una superficie
## plana sin cosas alrededor, solo el mob". `proc_lab` trae el bioma entero y
## `mob_capture` renderiza a un SubViewport off-screen — ninguno deja MIRAR al
## bicho moverse y darle vueltas. Esto sí: piso plano, luz neutra, cámara libre
## y las animaciones a un tecla de distancia.
##
## No es parte del juego. El mob se instancia de su .tscn real, así que lo que
## se ve acá es lo que el juego va a spawnear — no una maqueta aparte.
##
## Correr:
##   Godot --path game res://scenes/dev/mob_lab.tscn [-- --mob res://scenes/enemy/turtle.tscn]
##
## Controles:
##   1..5      = idle / move / attack / hit / death
##   0         = detener animación (pose de reposo)
##   R         = respawnear el mob (reinicia estado y animación)
##   T         = ciclar entre los mobs de la lista
##   P         = poste de escala 1.75 m on/off
##   WASD/mouse= cámara libre (Shift rápido, ESC libera el mouse)

const DEFAULT_MOB := "res://scenes/enemy/turtle.tscn"
const POST_HEIGHT := 1.75

## Mobs propios del motor, para ciclar con T sin reiniciar.
const MOB_LIST := [
	"res://scenes/enemy/hawk.tscn",
	"res://scenes/enemy/turtle.tscn",
	"res://scenes/enemy/slime.tscn",
	"res://scenes/enemy/rat.tscn",
	"res://scenes/enemy/snake.tscn",
	"res://scenes/enemy/bird.tscn",
	"res://scenes/enemy/wasp.tscn",
]

var _mob_path := DEFAULT_MOB
var _mob: Node3D = null
var _post: Node3D = null
var _overlay: Label = null
var _mob_index := 0
var _clips: PackedStringArray = []
var _mob_list_ui: ItemList = null
var _target: Node3D = null   # dummy in group "player" so the real AI engages


func _ready() -> void:
	_parse_args()
	_build_world()
	_build_overlay()
	_spawn_mob()


func _parse_args() -> void:
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == "--mob" and i + 1 < argv.size():
			_mob_path = argv[i + 1]
	for i in MOB_LIST.size():
		if MOB_LIST[i] == _mob_path:
			_mob_index = i


func _build_world() -> void:
	# Neutral studio light, same recipe as char_lab: the point is to judge the
	# ASSET, not a mood. A level's lighting would flatter or hide it.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.44, 0.47, 0.52)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.58, 0.60, 0.64)
	e.ambient_light_energy = 0.65
	env.environment = e
	add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -38, 0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-22, 130, 0)
	fill.light_energy = 0.45
	add_child(fill)

	# Flat ground with real collision -- the mob is a CharacterBody3D and will
	# fall through a bare MeshInstance3D (paid for on the slime pet, 2026-07-30).
	var body := StaticBody3D.new()
	body.name = "Ground"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	body.add_child(shape)
	var vis := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.39, 0.37)
	mat.roughness = 0.95
	plane.material = mat
	vis.mesh = plane
	body.add_child(vis)
	add_child(body)

	# A grid of faint marks every metre, so motion has something to be measured
	# against -- a mob walking over featureless ground looks stationary.
	var grid := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var gmat := StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.albedo_color = Color(0.33, 0.32, 0.31)
	im.surface_begin(Mesh.PRIMITIVE_LINES, gmat)
	for i in range(-15, 16):
		im.surface_add_vertex(Vector3(i, 0.01, -15))
		im.surface_add_vertex(Vector3(i, 0.01, 15))
		im.surface_add_vertex(Vector3(-15, 0.01, i))
		im.surface_add_vertex(Vector3(15, 0.01, i))
	im.surface_end()
	grid.mesh = im
	add_child(grid)

	_post = _make_post()
	add_child(_post)

	var cam := preload("res://scenes/dev/free_cam.gd").new()
	cam.name = "FreeCam"
	cam.position = Vector3(1.6, 0.9, 1.9)
	cam.look_at_from_position(Vector3(1.6, 0.9, 1.9), Vector3(0, 0.2, 0), Vector3.UP)
	add_child(cam)
	cam.current = true


func _make_post() -> Node3D:
	# Player-height reference. Without it every scale judgement is a guess --
	# the rule that came out of tree_pack shipping at bush scale.
	var n := Node3D.new()
	n.name = "ScalePost"
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.055
	cyl.bottom_radius = 0.055
	cyl.height = POST_HEIGHT
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.16, 0.14)
	cyl.material = mat
	m.mesh = cyl
	m.position = Vector3(1.1, POST_HEIGHT * 0.5, 0)
	n.add_child(m)
	return n


func _spawn_mob() -> void:
	if _mob != null and is_instance_valid(_mob):
		_mob.queue_free()
		_mob = null
	if not ResourceLoader.exists(_mob_path):
		push_error("[mob_lab] no existe %s" % _mob_path)
		_refresh_overlay()
		return
	var packed: PackedScene = load(_mob_path)
	_mob = packed.instantiate()
	add_child(_mob)
	_mob.global_position = Vector3.ZERO
	await get_tree().process_frame
	_freeze(_mob)
	_clips = _find_clips()
	_refresh_overlay()


func _freeze(node: Node) -> void:
	"""Stop the mob's own logic so it stands still and only plays clips."""
	node.set_physics_process(false)
	node.set_process(false)
	if node is CharacterBody3D:
		(node as CharacterBody3D).velocity = Vector3.ZERO
	for c in node.get_children():
		_freeze(c)


func _player() -> AnimationPlayer:
	if _mob == null or not is_instance_valid(_mob):
		return null
	for n in _mob.find_children("*", "AnimationPlayer", true, false):
		return n as AnimationPlayer
	return null


func _find_clips() -> PackedStringArray:
	var ap := _player()
	return ap.get_animation_list() if ap != null else PackedStringArray()


func _play(clip: String) -> void:
	var ap := _player()
	if ap == null:
		return
	if clip == "":
		ap.stop()
		_refresh_overlay("detenida")
		return
	if not ap.has_animation(clip):
		_refresh_overlay("no tiene '%s'" % clip)
		return
	ap.play(clip)
	_refresh_overlay("reproduciendo '%s'" % clip)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_G: _toggle_target()
		KEY_H: _release_rat()
		KEY_6: _kill_mob()
		KEY_1: _play("idle")
		KEY_2: _play("move")
		KEY_3: _play("attack")
		KEY_4: _play("hit")
		KEY_5: _play("death")
		KEY_0: _play("")
		KEY_R: _spawn_mob()
		KEY_P:
			_post.visible = not _post.visible
			_refresh_overlay()
		KEY_T:
			_toggle_mob_list()


func _toggle_target() -> void:
	"""The post becomes prey. A CharacterBody3D in group "player" at the post's
	base is everything BaseEnemy needs to aggro: the hawk detects it, circles
	it vulture-style and dives -- the REAL state machine, not a scripted demo.
	Toggling on also unfreezes the mob's AI (the lab freezes it by default so
	clips can be judged in isolation)."""
	if _target != null and is_instance_valid(_target):
		_target.queue_free()
		_target = null
		_spawn_mob()          # respawn frozen: back to clip-judging mode
		_refresh_overlay("target OFF — mob congelado de nuevo")
		return
	_target = CharacterBody3D.new()
	_target.add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.75
	capsule.radius = 0.3
	shape.shape = capsule
	shape.position = Vector3(0, 0.875, 0)
	_target.add_child(shape)
	_target.set_script(preload("res://scenes/dev/target_dummy.gd"))
	add_child(_target)
	var post_pos := _post.global_position if _post != null else Vector3(2, 0, 2)
	_target.global_position = Vector3(post_pos.x, 0.0, post_pos.z)
	if _post != null:
		_post.visible = true
	# Unfreeze the mob so its real AI runs against the dummy.
	if _mob != null and is_instance_valid(_mob):
		_unfreeze(_mob)
	# Un halcon es NEUTRAL: sin provocacion jamas circula ni pica -- Joan
	# activo el target y no vio nada. Un toque de dano lo provoca, y el show
	# (circulo de buitre -> picada -> agarre) arranca solo.
	if _mob != null and is_instance_valid(_mob) and _mob.has_method("take_damage"):
		_mob.take_damage(1.0, Vector3.ZERO, 0.0, 0, _target)
	_refresh_overlay("target ON — IA viva y provocada: mira el circulo y la picada")


func _release_rat() -> void:
	"""Suelta una rata como presa. El halcon la caza solo (accion de
	naturaleza): la detecta, circula, pica, y el loot de la rata queda tirado
	donde murio -- su propia muerte lo suelta."""
	var rat_path := "res://scenes/enemy/rat.tscn"
	if not ResourceLoader.exists(rat_path):
		_refresh_overlay("no existe rat.tscn")
		return
	var rat: Node3D = (load(rat_path) as PackedScene).instantiate()
	add_child(rat)
	var ang := randf() * TAU
	rat.global_position = Vector3(cos(ang) * 5.0, 0.1, sin(ang) * 5.0)
	if _mob != null and is_instance_valid(_mob):
		_unfreeze(_mob)
	_refresh_overlay("rata suelta — el halcon deberia cazarla")


func _kill_mob() -> void:
	"""Muerte DE VERDAD: con la IA viva y gravedad, un volador muere cayendo
	al suelo -- el clip solo vende el desplome, la fisica hace la caida."""
	if _mob == null or not is_instance_valid(_mob):
		return
	_unfreeze(_mob)
	if _mob.has_method("take_damage"):
		_mob.take_damage(9999999.0)
	_refresh_overlay("muerte real — con fisica")


func _unfreeze(node: Node) -> void:
	node.set_physics_process(true)
	node.set_process(true)
	for c in node.get_children():
		_unfreeze(c)


func _toggle_mob_list() -> void:
	"""T abre una lista SELECCIONABLE en vez de ciclar a ciegas: Joan apreto T
	sin querer y perdio al halcon -- que ademas ni estaba en la lista."""
	if _mob_list_ui == null:
		var layer := CanvasLayer.new()
		layer.layer = 10
		add_child(layer)
		_mob_list_ui = ItemList.new()
		_mob_list_ui.position = Vector2(14, 150)
		_mob_list_ui.size = Vector2(260, 30 + MOB_LIST.size() * 30)
		for path in MOB_LIST:
			_mob_list_ui.add_item(path.get_file().get_basename())
		_mob_list_ui.item_activated.connect(_on_mob_picked)
		layer.add_child(_mob_list_ui)
	_mob_list_ui.visible = not _mob_list_ui.visible
	if _mob_list_ui.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mob_list_ui.select(_mob_index)
		_mob_list_ui.grab_focus()
		_refresh_overlay("elegi mob: flechas o click + Enter (doble click)")
	else:
		_refresh_overlay()


func _on_mob_picked(index: int) -> void:
	_mob_index = index
	_mob_path = MOB_LIST[index]
	_mob_list_ui.visible = false
	_spawn_mob()


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_overlay = Label.new()
	_overlay.position = Vector2(14, 12)
	_overlay.add_theme_color_override("font_color", Color(0.96, 0.95, 0.90))
	_overlay.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_overlay.add_theme_constant_override("outline_size", 5)
	layer.add_child(_overlay)


func _refresh_overlay(status: String = "") -> void:
	if _overlay == null:
		return
	var name := _mob_path.get_file().get_basename()
	var clips := ", ".join(_clips) if _clips.size() > 0 else "(sin AnimationPlayer)"
	_overlay.text = "mob_lab — %s\nclips: %s\n%s\n\n1 idle · 2 move · 3 attack · 4 hit · 5 death · 0 parar\nR respawn · T LISTA de mobs · P poste %s · G poste=TARGET (provoca) · H soltar rata (caza) · 6 muerte real" % [
		name, clips, status,
		"ON" if (_post != null and _post.visible) else "OFF",
	]
