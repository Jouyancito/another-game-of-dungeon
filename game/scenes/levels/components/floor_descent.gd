class_name FloorDescent
extends Node3D

# El paso al piso siguiente, abierto cuando muere el boss del piso.
#
# Canon `lore/_alpha_5_maps.md` §"P1 → P2: Boss + Transición":
#   1. el cuerpo del King Slime se derrama por el borde del acantilado → MUESTRA el camino
#   2. queda el NÚCLEO flotando — cristal condensado de bioluminiscencia
#   3. tomar el núcleo registra el desbloqueo world-state (ya lo hace mark_floor_cleared)
#   4. descenso por el acantilado
#   5. salida al bosque bajo luna llena → P2
#
# Por eso esto no es un agujero en el piso: es EL NÚCLEO. El boss se plantó a comer la
# fuente de la luz, y comerse la luz es lo mismo que taponar el paso — la ecología ES el
# level design. Matarlo devuelve el paso, y el núcleo es la prueba física de eso.
#
# La interacción reusa el contrato de loot_chest/mimic tal cual: grupo "interactables" +
# open(player). BasePlayer._try_interact_nearby() hace el resto.

## Piso del que se DESCIENDE. El destino se resuelve desde acá.
@export var from_floor: int = 1

## Adónde lleva cada piso. Un piso sin destino cierra la demo con el cliffhanger en vez de
## mandar al jugador a una escena que no existe.
const FLOOR_SCENES: Dictionary = {
	2: "res://scenes/levels/floor2_forest.tscn",
}

var _used := false


func _ready() -> void:
	add_to_group("interactables")
	_build_visuals()


## El núcleo: un cristal flotando donde estaba el boss, latiendo. Es lo único con luz propia
## en el claro ahora que el boss dejó de comerse la fuente.
func _build_visuals() -> void:
	var core := MeshInstance3D.new()
	core.name = "Core"
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	mesh.radial_segments = 10   # facetado: es cristal, no una pelota
	mesh.rings = 5
	core.mesh = mesh
	core.position = Vector3(0, 1.4, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.90, 0.95, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.90, 0.95)
	mat.emission_energy_multiplier = 3.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core.material_override = mat
	add_child(core)

	var glow := OmniLight3D.new()
	glow.name = "CoreGlow"
	glow.light_color = Color(0.45, 0.90, 0.95)
	glow.light_energy = 2.2
	glow.omni_range = 16.0
	glow.position = Vector3(0, 1.4, 0)
	add_child(glow)

	# Late y flota. Un cristal quieto es un prop; uno que respira es algo que dejó un cuerpo.
	var bob := create_tween().set_loops()
	bob.tween_property(core, "position:y", 1.75, 2.0).set_trans(Tween.TRANS_SINE)
	bob.tween_property(core, "position:y", 1.40, 2.0).set_trans(Tween.TRANS_SINE)

	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "light_energy", 3.4, 1.3).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "light_energy", 2.2, 1.3).set_trans(Tween.TRANS_SINE)

	var spin := create_tween().set_loops()
	spin.tween_property(core, "rotation:y", TAU, 9.0).from(0.0)


## Hook de interacción de BasePlayer. Una sola vez: acá termina el piso.
func open(_player: Node) -> void:
	if _used:
		return
	_used = true
	remove_from_group("interactables")

	if AudioManager:
		AudioManager.play_sfx(&"level_up")

	var next_floor: int = from_floor + 1
	var next_scene: String = FLOOR_SCENES.get(next_floor, "")

	var hud := get_tree().get_first_node_in_group("hud")
	if next_scene == "":
		# No hay piso siguiente construido — la demo corta acá, con el cliffhanger.
		if hud and hud.has_method("show_demo_ending"):
			hud.show_demo_ending(from_floor)
		else:
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return

	if hud and hud.has_method("show_descent") and next_floor == 2:
		# El descenso ES la pantalla de carga (canon floor_transitions.md: "la animación de
		# transición ES la pantalla de carga"). El HUD la sostiene y carga el piso al final.
		hud.show_descent(next_scene)
	else:
		get_tree().change_scene_to_file(next_scene)
