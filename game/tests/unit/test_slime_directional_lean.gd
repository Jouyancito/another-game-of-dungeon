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


func _drive(vel: Vector3, seconds: float) -> void:
	## Avanza la deformación con un delta FIJO, en vez de esperar frames reales.
	##
	## Esperar frames no sirve acá: en headless corren sin vsync, así que 30 frames
	## pueden ser 30 ms de tiempo simulado y el suavizado exponencial apenas
	## arranca. Medido: el test de movimiento lateral llegaba a 0.051 en la suite
	## completa y a más de 0.3 corriendo solo — el mismo código, distinto
	## framerate. Con un paso fijo el resultado es el mismo siempre.
	const STEP := 1.0 / 60.0
	_slime.velocity = vel
	var elapsed := 0.0
	while elapsed < seconds:
		_slime._process(STEP)
		elapsed += STEP


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
	_drive(Vector3(0.0, 0.0, -3.0), 1.0)
	assert_gt(mi.get_blend_shape_value(idx), 0.3,
		"avanzar (-Z local) tiene que inclinar el gel hacia adelante, no hacia atrás")


func test_moving_backward_leans_the_gel_backward() -> void:
	# El signo opuesto, para que un valor absoluto no pase por correcto.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_drive(Vector3(0.0, 0.0, 3.0), 1.0)
	assert_lt(mi.get_blend_shape_value(idx), -0.3,
		"retroceder (+Z local) tiene que inclinar el gel hacia atrás")


func test_standing_still_settles_back_to_no_lean() -> void:
	# Un slime quieto con el gel torcido se ve roto. Tiene que volver al reposo.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_drive(Vector3(0.0, 0.0, -3.0), 1.0)
	_drive(Vector3.ZERO, 1.5)
	assert_almost_eq(mi.get_blend_shape_value(idx), 0.0, 0.1,
		"al frenar, el gel tiene que asentarse en reposo")


func test_the_lean_is_capped_so_the_blob_never_lies_down() -> void:
	# Muy por encima de la velocidad de saturación: la inclinación no puede seguir creciendo,
	# o a velocidades altas el domo se ve tumbado en vez de derramado.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	_drive(Vector3(0.0, 0.0, -40.0), 2.0)
	assert_lte(mi.get_blend_shape_value(idx), 0.81,
		"la inclinación tiene que estar topeada en LEAN_MAX")


func test_sideways_movement_uses_the_other_axis() -> void:
	# Moverse de costado no debe leerse como avanzar: son shape keys distintos.
	var mi := _mesh_with_shapes(_slime)
	var idx_x := _shape_index(mi, "lean_x")
	var idx_y := _shape_index(mi, "lean_y")
	_drive(Vector3(3.0, 0.0, 0.0), 1.0)
	assert_gt(absf(mi.get_blend_shape_value(idx_x)), 0.3,
		"moverse en X tiene que inclinar sobre lean_x")
	assert_almost_eq(mi.get_blend_shape_value(idx_y), 0.0, 0.1,
		"moverse de costado no debe inclinar hacia adelante")


func test_the_gel_overshoots_before_settling() -> void:
	# Lo que separa "gelatina" de "sólido verde": la masa PASA DE LARGO y vuelve.
	# Una interpolación suave llega a su destino y se queda; un resorte
	# subamortiguado se pasa primero. Si alguien cambia el resorte por un lerp
	# "porque es más simple", el bamboleo desaparece sin que nada falle — salvo
	# esto.
	var mi := _mesh_with_shapes(_slime)
	var idx := _shape_index(mi, "lean_y")
	const STEP := 1.0 / 60.0
	_slime.velocity = Vector3(0.0, 0.0, -3.0)
	var peak := 0.0
	var elapsed := 0.0
	while elapsed < 1.2:
		_slime._process(STEP)
		peak = maxf(peak, mi.get_blend_shape_value(idx))
		elapsed += STEP
	var settled: float = mi.get_blend_shape_value(idx)
	assert_gt(peak, settled + 0.02,
		"el gel tiene que sobrepasar su inclinación de reposo antes de asentarse")


func test_the_overshoot_has_a_ceiling() -> void:
	# El sobrepaso es deseado, pero sin techo el domo se vuelca en vez de
	# bambolearse. Arranque violento, en el peor caso.
	var mi := _mesh_with_shapes(_slime)
	var idx_x := _shape_index(mi, "lean_x")
	var idx_y := _shape_index(mi, "lean_y")
	const STEP := 1.0 / 60.0
	var elapsed := 0.0
	while elapsed < 2.0:
		# Invertir la dirección a cada rato es lo que más excita el resorte.
		var flip: float = -1.0 if fmod(elapsed, 0.4) < 0.2 else 1.0
		_slime.velocity = Vector3(0.0, 0.0, -40.0 * flip)
		_slime._process(STEP)
		var magnitude := Vector2(mi.get_blend_shape_value(idx_x),
			mi.get_blend_shape_value(idx_y)).length()
		assert_lte(magnitude, 1.06,
			"la inclinación nunca puede pasar el techo de sobrepaso")
		elapsed += STEP


func test_moving_wobbles_the_perpendicular_axis() -> void:
	# Avanzando en línea recta, el resorte solo se asienta y el gel volvería a
	# leer como sólido. El bamboleo sostenido vive en el eje perpendicular.
	var mi := _mesh_with_shapes(_slime)
	var idx_x := _shape_index(mi, "lean_x")
	const STEP := 1.0 / 60.0
	_slime.velocity = Vector3(0.0, 0.0, -3.0)
	var lo := 999.0
	var hi := -999.0
	var elapsed := 0.0
	while elapsed < 1.6:
		_slime._process(STEP)
		if elapsed > 0.8:      # tras el asentamiento inicial del resorte
			var x: float = mi.get_blend_shape_value(idx_x)
			lo = minf(lo, x)
			hi = maxf(hi, x)
		elapsed += STEP
	assert_gt(hi - lo, 0.03,
		"desplazándose en recta, el eje perpendicular tiene que seguir oscilando")


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
	_drive(Vector3(0.0, 0.0, -3.0), 1.0)
	assert_gt(mi.get_blend_shape_value(idx), 0.3,
		"con un clip reproduciéndose, la inclinación tiene que sobrevivir")
