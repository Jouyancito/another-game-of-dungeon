extends GutTest

# La deformación direccional del slime: que el gel se derrame HACIA donde viaja.
#
# Esto se testea porque el signo es fácil de invertir y difícil de notar. Un slime que se
# deforma hacia ATRÁS al avanzar no crashea, no tira error, y en movimiento pasa por
# "cosa de gel rara" — la clase de bug que sobrevive meses. La cadena tiene tres eslabones
# donde el signo puede darse vuelta: el shape key en Blender apunta a -Y, `export_yup`
# lo manda a +Z, y el mesh está rotado 180°. Ya me equivoqué derivando eso a mano una vez.
#
# Y hay una segunda trampa, medida en vivo: glTF empaqueta TODOS los pesos de morph en UN
# canal de animación, así que un clip reescribe pesos que nunca fueron suyos. Con el
# AnimationPlayer en automático, poner lean_y en 0.8 se leía 0.000 dos frames después.
# El fix es que el script maneje el reloj del player; si alguien lo devuelve a automático,
# el último test de acá se cae.

const SLIME_SCENE := "res://scenes/enemy/slime.tscn"
const MESH_PATH := "res://assets/art/piso1_pradera/enemies/slime/slime_dp_01.glb"

var _slime: CharacterBody3D = null


func before_each() -> void:
	_slime = load(SLIME_SCENE).instantiate()
	add_child_autofree(_slime)
	# Dejar que _ready corra: ahí se cachean los índices de shape key.
	await wait_frames(2)


func _mesh_with_shapes(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.mesh.get_blend_shape_count() > 0:
			return mi
	for c in n.get_children():
		var found := _mesh_with_shapes(c)
		if found != null:
			return found
	return null


func _shape_index(mi: MeshInstance3D, shape_name: String) -> int:
	for i in mi.mesh.get_blend_shape_count():
		if String(mi.mesh.get_blend_shape_name(i)) == shape_name:
			return i
	return -1


func test_the_mesh_ships_both_lean_shape_keys() -> void:
	# Sin estas dos, la deformación direccional no tiene con qué deformar y el resto del
	# sistema queda no-op silencioso.
	var mi := _mesh_with_shapes(_slime)
	assert_not_null(mi, "el slime no trae ninguna malla con shape keys")
	assert_gt(_shape_index(mi, "lean_x"), -1, "falta el shape key 'lean_x' en el GLB")
	assert_gt(_shape_index(mi, "lean_y"), -1, "falta el shape key 'lean_y' en el GLB")


func test_moving_forward_leans_the_gel_forward() -> void:
	# El cuerpo mira a su objetivo, así que -Z local es adelante. Avanzar tiene que dar
	# lean_y POSITIVO: ese es el signo que corre la masa hacia la cara.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_slime.velocity = Vector3(0.0, 0.0, -3.0)
	await wait_frames(30)
	assert_gt(mi.get_blend_shape_value(idx), 0.3,
		"avanzar (-Z local) tiene que inclinar el gel hacia adelante, no hacia atrás")


func test_moving_backward_leans_the_gel_backward() -> void:
	# El signo opuesto, para que un valor absoluto no pase por correcto.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_slime.velocity = Vector3(0.0, 0.0, 3.0)
	await wait_frames(30)
	assert_lt(mi.get_blend_shape_value(idx), -0.3,
		"retroceder (+Z local) tiene que inclinar el gel hacia atrás")


func test_standing_still_settles_back_to_no_lean() -> void:
	# Un slime quieto con el gel torcido se ve roto. Tiene que volver al reposo.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_slime.velocity = Vector3(0.0, 0.0, -3.0)
	await wait_frames(30)
	_slime.velocity = Vector3.ZERO
	await wait_frames(40)
	assert_almost_eq(mi.get_blend_shape_value(idx), 0.0, 0.1,
		"al frenar, el gel tiene que asentarse en reposo")


func test_the_lean_is_capped_so_the_blob_never_lies_down() -> void:
	# Muy por encima de la velocidad de saturación: la inclinación no puede seguir creciendo,
	# o a velocidades altas el domo se ve tumbado en vez de derramado.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_slime.velocity = Vector3(0.0, 0.0, -40.0)
	await wait_frames(40)
	assert_lte(mi.get_blend_shape_value(idx), 0.81,
		"la inclinación tiene que estar topeada en LEAN_MAX")


func test_sideways_movement_uses_the_other_axis() -> void:
	# Moverse de costado no debe leerse como avanzar: son shape keys distintos.
	var mi := _mesh_with_shapes(_slime)
	var idx_x := _shape_index(mi, "lean_x")
	var idx_y := _shape_index(mi, "lean_y")
	_slime.velocity = Vector3(3.0, 0.0, 0.0)
	await wait_frames(30)
	assert_gt(absf(mi.get_blend_shape_value(idx_x)), 0.3,
		"moverse en X tiene que inclinar sobre lean_x")
	assert_almost_eq(mi.get_blend_shape_value(idx_y), 0.0, 0.1,
		"moverse de costado no debe inclinar hacia adelante")


func test_the_animation_player_does_not_overwrite_the_lean() -> void:
	# La trampa medida: glTF anima el array COMPLETO de pesos en un canal, así que un clip
	# reescribe lean_x/lean_y (en 0) cada vez que evalúa. El script se queda con el reloj
	# del player para que el orden sea explícito. Si alguien lo devuelve a automático, la
	# deformación se apaga sola y en silencio — este test lo caza.
	var ap: AnimationPlayer = null
	for n in _slime.find_children("*", "AnimationPlayer", true, false):
		ap = n as AnimationPlayer
		break
	assert_not_null(ap, "el slime debería traer un AnimationPlayer del GLB")
	assert_eq(ap.callback_mode_process,
		AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,
		"el AnimationPlayer tiene que estar en MANUAL o pisa la inclinación del script")

	# Y la prueba de que efectivamente sobrevive con un clip corriendo.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	if ap.has_animation("idle"):
		ap.play("idle")
	_slime.velocity = Vector3(0.0, 0.0, -3.0)
	await wait_frames(30)
	assert_gt(mi.get_blend_shape_value(idx), 0.3,
		"con un clip reproduciéndose, la inclinación tiene que sobrevivir")
