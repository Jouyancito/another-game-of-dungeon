class_name EnemyModelBuilder
## Construye modelos low-poly para enemigos reutilizando los primitivos de MannequinBuilder.
## Todos los métodos son estáticos y devuelven un Node3D raíz con los meshes como hijos.
## Objetivo: siluetas reconocibles a distancia — no detalle, sino legibilidad.

# ---------------------------------------------------------------------------
# QUADRUPED — lobo, zorro, cabra, rata, etc.
# ---------------------------------------------------------------------------

## Construye un cuerpo cuadrúpedo.
## Retorna Node3D con: body, 4 legs, head, optional tail.
## body_length: largo del torso (eje Z). body_height: alto del torso. body_width: ancho (eje X).
## leg_height: largo de cada pata. leg_radius: radio de la pata.
static func build_quadruped(
		color: Color,
		body_length: float,
		body_height: float,
		body_width: float,
		leg_height: float,
		leg_radius: float,
		has_tail: bool,
		tail_length: float = 0.3
) -> Node3D:
	var root := Node3D.new()
	root.name = "QuadrupedModel"

	var mat := MannequinBuilder.create_material(color)
	var dark_mat := MannequinBuilder.create_material(color, true)

	# --- Cuerpo ---
	var body := MannequinBuilder.create_box(Vector3(body_width, body_height, body_length), mat)
	body.name = "Body"
	# El cuerpo se ubica elevado sobre el suelo: patas cuelgan hacia abajo desde aquí
	body.position = Vector3(0.0, leg_height + body_height * 0.5, 0.0)
	root.add_child(body)

	# --- 4 patas (esquinas del cuerpo) ---
	var half_w := body_width * 0.5 - leg_radius
	var half_l := body_length * 0.5 - leg_radius
	var leg_y := leg_height * 0.5  # centro del cilindro desde el suelo
	var body_bottom_y := leg_height + 0.0  # justo donde termina la pata, empieza el cuerpo

	var leg_positions: Array[Vector3] = [
		Vector3( half_w, leg_y,  half_l),  # delantera derecha
		Vector3(-half_w, leg_y,  half_l),  # delantera izquierda
		Vector3( half_w, leg_y, -half_l),  # trasera derecha
		Vector3(-half_w, leg_y, -half_l),  # trasera izquierda
	]
	var leg_names: Array[String] = ["LegFR", "LegFL", "LegBR", "LegBL"]

	for i in range(4):
		var leg := MannequinBuilder.create_cylinder(leg_radius, leg_height, mat)
		leg.name = leg_names[i]
		leg.position = leg_positions[i]
		root.add_child(leg)

	# --- Cabeza (esfera al frente, centrada en Y del cuerpo) ---
	var head_radius := body_height * 0.55
	var head := MannequinBuilder.create_sphere(head_radius, dark_mat)
	head.name = "Head"
	head.position = Vector3(0.0, body_bottom_y + body_height * 0.5, body_length * 0.5 + head_radius * 0.7)
	root.add_child(head)

	# --- Cola opcional (cilindro trasero inclinado ~35 grados hacia arriba) ---
	if has_tail:
		var tail := MannequinBuilder.create_cylinder(leg_radius * 0.7, tail_length, mat)
		tail.name = "Tail"
		# Posición: detrás del cuerpo, a mitad de altura
		tail.position = Vector3(0.0, body_bottom_y + body_height * 0.5, -body_length * 0.5 - tail_length * 0.35)
		tail.rotation_degrees = Vector3(35.0, 0.0, 0.0)
		root.add_child(tail)

	return root


# ---------------------------------------------------------------------------
# HUMANOID — bandido, golem, etc.
# ---------------------------------------------------------------------------

## Construye un cuerpo humanoide escalable reutilizando piezas de MannequinBuilder.
## height_scale: 1.0 = humano estándar, 1.5 = gigante, 0.7 = enano.
## width_scale: 1.0 = normal, 1.4 = corpulento (golem).
static func build_humanoid(
		color: Color,
		height_scale: float = 1.0,
		width_scale: float = 1.0
) -> Node3D:
	var root := Node3D.new()
	root.name = "HumanoidModel"

	# --- Torso ---
	var torso := MannequinBuilder.build_torso(color)
	torso.name = "Torso"
	# build_torso devuelve un box de 0.30 x 0.38 x 0.18
	# Escalamos conservando las proporciones y luego posicionamos
	torso.scale = Vector3(width_scale, height_scale, width_scale)
	var torso_half_h := 0.38 * height_scale * 0.5
	var torso_y := 0.60 * height_scale  # offset desde el suelo
	torso.position = Vector3(0.0, torso_y + torso_half_h, 0.0)
	root.add_child(torso)

	# --- Cabeza ---
	var head := MannequinBuilder.build_head_mesh(color)
	head.name = "Head"
	head.scale = Vector3(width_scale * 0.9, height_scale * 0.9, width_scale * 0.9)
	head.position = Vector3(0.0, torso_y + 0.38 * height_scale + 0.12 * height_scale, 0.0)
	root.add_child(head)

	# --- Brazos (izquierdo y derecho) ---
	var arm_r := MannequinBuilder.build_arm(color, 1.0)
	arm_r.name = "ArmRight"
	arm_r.scale = Vector3(width_scale, height_scale, width_scale)
	arm_r.position = Vector3(0.17 * width_scale, torso_y + 0.38 * height_scale * 0.9, 0.0)
	root.add_child(arm_r)

	var arm_l := MannequinBuilder.build_arm(color, -1.0)
	arm_l.name = "ArmLeft"
	arm_l.scale = Vector3(width_scale, height_scale, width_scale)
	arm_l.position = Vector3(-0.17 * width_scale, torso_y + 0.38 * height_scale * 0.9, 0.0)
	root.add_child(arm_l)

	# --- Piernas (derecha e izquierda) ---
	var leg_r := MannequinBuilder.build_leg(color, 1.0)
	leg_r.name = "LegRight"
	leg_r.scale = Vector3(width_scale, height_scale, width_scale)
	leg_r.position = Vector3(0.08 * width_scale, torso_y, 0.0)
	root.add_child(leg_r)

	var leg_l := MannequinBuilder.build_leg(color, -1.0)
	leg_l.name = "LegLeft"
	leg_l.scale = Vector3(width_scale, height_scale, width_scale)
	leg_l.position = Vector3(-0.08 * width_scale, torso_y, 0.0)
	root.add_child(leg_l)

	return root


# ---------------------------------------------------------------------------
# ARTHROPOD — escorpión, araña, insecto
# ---------------------------------------------------------------------------

## Construye un artrópodo: cuerpo plano, N patas, cola opcional, pinzas opcionales.
## leg_count: total de patas — se distribuyen simétricamente a los lados (debe ser par).
## has_tail: cola en segmentos curvada hacia arriba (escorpión).
## has_pincers: dos cajas pequeñas al frente (escorpión/cangrejo).
static func build_arthropod(
		color: Color,
		body_length: float,
		body_width: float,
		body_height: float,
		leg_count: int,
		has_tail: bool,
		has_pincers: bool
) -> Node3D:
	var root := Node3D.new()
	root.name = "ArthropodModel"

	var mat := MannequinBuilder.create_material(color)
	var dark_mat := MannequinBuilder.create_material(color, true)

	# --- Cuerpo plano ---
	var body := MannequinBuilder.create_box(Vector3(body_width, body_height, body_length), mat)
	body.name = "Body"
	body.position = Vector3(0.0, body_height * 0.5, 0.0)
	root.add_child(body)

	# --- Patas: cilindros delgados saliendo de los costados, angled down ~30 deg ---
	var pairs := leg_count / 2
	var leg_radius := body_height * 0.18
	var leg_len := body_width * 0.7
	for i in range(pairs):
		# Distribuir a lo largo del cuerpo
		var z_offset := 0.0
		if pairs > 1:
			z_offset = lerpf(-body_length * 0.35, body_length * 0.35, float(i) / float(pairs - 1))

		for side in [-1, 1]:
			var leg := MannequinBuilder.create_cylinder(leg_radius, leg_len, mat)
			leg.name = "Leg_%d_%s" % [i, "R" if side > 0 else "L"]
			leg.rotation_degrees = Vector3(0.0, 0.0, side * 60.0)  # 60 deg hacia afuera y abajo
			leg.position = Vector3(
				side * (body_width * 0.5 + leg_len * 0.3),
				body_height * 0.2,
				z_offset
			)
			root.add_child(leg)

	# --- Cola en 3 segmentos curvados hacia arriba (escorpión) ---
	if has_tail:
		var seg_len := body_length * 0.38
		var seg_radius := body_height * 0.22
		# Segmento 1: sale horizontal por detrás
		var seg1 := MannequinBuilder.create_cylinder(seg_radius, seg_len, dark_mat)
		seg1.name = "TailSeg1"
		seg1.rotation_degrees = Vector3(80.0, 0.0, 0.0)  # casi vertical hacia arriba
		seg1.position = Vector3(0.0, body_height * 0.5 + seg_len * 0.45, -body_length * 0.5 - seg_len * 0.05)
		root.add_child(seg1)

		# Segmento 2: más inclinado aún
		var seg2 := MannequinBuilder.create_cylinder(seg_radius * 0.8, seg_len * 0.8, dark_mat)
		seg2.name = "TailSeg2"
		seg2.rotation_degrees = Vector3(50.0, 0.0, 0.0)
		seg2.position = Vector3(0.0, body_height * 0.5 + seg_len * 1.2, -body_length * 0.5 + seg_len * 0.15)
		root.add_child(seg2)

		# Aguijón (esfera pequeña al final)
		var stinger := MannequinBuilder.create_sphere(seg_radius * 0.9, dark_mat)
		stinger.name = "Stinger"
		stinger.position = Vector3(0.0, body_height * 0.5 + seg_len * 1.85, -body_length * 0.5 + seg_len * 0.55)
		root.add_child(stinger)

	# --- Pinzas: dos cajas pequeñas al frente ---
	if has_pincers:
		var pincer_size := Vector3(body_width * 0.22, body_height * 0.7, body_length * 0.22)
		for side in [-1, 1]:
			var pincer := MannequinBuilder.create_box(pincer_size, dark_mat)
			pincer.name = "Pincer_%s" % ("R" if side > 0 else "L")
			pincer.position = Vector3(
				side * body_width * 0.32,
				body_height * 0.3,
				body_length * 0.5 + pincer_size.z * 0.5
			)
			root.add_child(pincer)

	return root


# ---------------------------------------------------------------------------
# FLYER — halcón, pájaro
# ---------------------------------------------------------------------------

## Construye una criatura voladora: cuerpo esférico, alas planas, pico.
## wing_span: largo total de un ala (de cuerpo a punta).
## wing_width: ancho de la caja del ala (grosor).
static func build_flyer(
		color: Color,
		body_radius: float,
		wing_span: float,
		wing_width: float
) -> Node3D:
	var root := Node3D.new()
	root.name = "FlyerModel"

	var mat := MannequinBuilder.create_material(color)
	var dark_mat := MannequinBuilder.create_material(color, true)

	# --- Cuerpo esférico ---
	var body := MannequinBuilder.create_sphere(body_radius, mat)
	body.name = "Body"
	body.position = Vector3(0.0, body_radius, 0.0)
	root.add_child(body)

	# --- Alas: cajas planas a los lados, levemente anguladas hacia abajo ---
	var wing_thickness := wing_width * 0.15  # ala muy plana
	for side in [-1, 1]:
		var wing := MannequinBuilder.create_box(
			Vector3(wing_span, wing_thickness, wing_width), mat
		)
		wing.name = "Wing_%s" % ("R" if side > 0 else "L")
		wing.rotation_degrees = Vector3(0.0, 0.0, side * -12.0)  # leve diedro
		wing.position = Vector3(
			side * (body_radius + wing_span * 0.5),
			body_radius,
			0.0
		)
		root.add_child(wing)

	# --- Pico: caja pequeña al frente ---
	var beak := MannequinBuilder.create_box(
		Vector3(body_radius * 0.3, body_radius * 0.2, body_radius * 0.55), dark_mat
	)
	beak.name = "Beak"
	beak.position = Vector3(0.0, body_radius * 1.05, body_radius + body_radius * 0.27)
	root.add_child(beak)

	# --- Cola: caja trasera plana ---
	var tail := MannequinBuilder.create_box(
		Vector3(body_radius * 0.7, wing_thickness, body_radius * 0.6), mat
	)
	tail.name = "Tail"
	tail.position = Vector3(0.0, body_radius * 0.85, -body_radius - body_radius * 0.3)
	root.add_child(tail)

	return root


# ---------------------------------------------------------------------------
# SNAKE — serpiente
# ---------------------------------------------------------------------------

## Construye una serpiente como cadena de esferas en curva suave tipo S.
## length: largo total de la cadena. thickness: radio de cada segmento.
## segments: número de esferas (mínimo 3).
static func build_snake(
		color: Color,
		length: float,
		thickness: float,
		segments: int = 4
) -> Node3D:
	var root := Node3D.new()
	root.name = "SnakeModel"

	var mat := MannequinBuilder.create_material(color)
	var dark_mat := MannequinBuilder.create_material(color, true)

	var seg_count: int = maxi(segments, 3)

	for i in range(seg_count):
		var t := float(i) / float(seg_count - 1)  # 0.0 a 1.0 a lo largo del cuerpo

		# Curva S en el eje X (sin de dos períodos)
		var x_offset := sin(t * TAU) * (length * 0.12)

		# El radio decrece hacia la cola (0.6x al final)
		var radius: float = thickness * lerpf(1.0, 0.55, t)

		# La cabeza es más oscura
		var seg_mat := dark_mat if i == 0 else mat
		var seg := MannequinBuilder.create_sphere(radius, seg_mat)
		seg.name = "Seg_%02d" % i

		# La serpiente yace en el suelo (Y = radius)
		seg.position = Vector3(x_offset, radius * 0.8, (t - 0.5) * length)
		root.add_child(seg)

	return root


# ---------------------------------------------------------------------------
# SHELLED — tortuga
# ---------------------------------------------------------------------------

## Construye una criatura con caparazón: concha encima, cuerpo plano, patas cortas, cabeza.
## shell_radius: radio de la esfera escalada que forma la concha.
## body_height: grosor del cuerpo base.
## leg_count: número de patas (4 o 6).
static func build_shelled(
		color: Color,
		shell_color: Color,
		shell_radius: float,
		body_height: float,
		leg_count: int
) -> Node3D:
	var root := Node3D.new()
	root.name = "ShelledModel"

	var body_mat := MannequinBuilder.create_material(color)
	var shell_mat := MannequinBuilder.create_material(shell_color)
	var dark_mat := MannequinBuilder.create_material(color, true)

	var body_w := shell_radius * 1.6
	var body_l := shell_radius * 1.8
	var leg_h := shell_radius * 0.45
	var leg_r := shell_radius * 0.14

	# --- Cuerpo plano (box) ---
	var body := MannequinBuilder.create_box(Vector3(body_w, body_height, body_l), body_mat)
	body.name = "Body"
	body.position = Vector3(0.0, leg_h + body_height * 0.5, 0.0)
	root.add_child(body)

	# --- Concha (esfera aplastada en Y = hemisferio visual) ---
	var shell := MannequinBuilder.create_sphere(shell_radius, shell_mat)
	shell.name = "Shell"
	shell.scale = Vector3(1.0, 0.65, 0.95)  # aplanar verticalmente
	shell.position = Vector3(0.0, leg_h + body_height + shell_radius * 0.5, 0.0)
	root.add_child(shell)

	# --- Patas cortas en las esquinas ---
	var actual_legs := clampi(leg_count, 4, 6)
	var positions: Array[Vector3] = []

	if actual_legs == 4:
		var hw := body_w * 0.4
		var hl := body_l * 0.35
		positions = [
			Vector3( hw, leg_h * 0.5,  hl),
			Vector3(-hw, leg_h * 0.5,  hl),
			Vector3( hw, leg_h * 0.5, -hl),
			Vector3(-hw, leg_h * 0.5, -hl),
		]
	else:  # 6 patas
		var hw := body_w * 0.42
		positions = [
			Vector3( hw, leg_h * 0.5,  body_l * 0.35),
			Vector3(-hw, leg_h * 0.5,  body_l * 0.35),
			Vector3( hw, leg_h * 0.5,  0.0),
			Vector3(-hw, leg_h * 0.5,  0.0),
			Vector3( hw, leg_h * 0.5, -body_l * 0.35),
			Vector3(-hw, leg_h * 0.5, -body_l * 0.35),
		]

	for i in range(positions.size()):
		var leg := MannequinBuilder.create_cylinder(leg_r, leg_h, body_mat)
		leg.name = "Leg_%02d" % i
		leg.position = positions[i]
		root.add_child(leg)

	# --- Cabeza: esfera pequeña que asoma por el frente ---
	var head_r := shell_radius * 0.3
	var head := MannequinBuilder.create_sphere(head_r, dark_mat)
	head.name = "Head"
	head.position = Vector3(0.0, leg_h + body_height * 0.6, body_l * 0.5 + head_r * 0.6)
	root.add_child(head)

	return root
