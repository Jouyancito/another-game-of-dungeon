class_name MannequinBuilder
## Construye piezas de maniquí articulado low-poly (crash test dummy style).
## Usado por ViewModel (brazos FP) y WorldModel (cuerpo completo para otros jugadores).

# Visibility layers
const LAYER_VIEW_MODEL := 2   # bit 1 — solo cámara local
const LAYER_WORLD_MODEL := 4  # bit 2 — solo otros jugadores

static func create_material(color: Color, darker := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var c := color.darkened(0.3) if darker else color
	mat.albedo_color = c
	mat.roughness = 0.8
	return mat

static func create_sphere(radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mi.mesh = mesh
	mi.material_override = mat
	return mi

static func create_cylinder(radius: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.material_override = mat
	return mi

static func create_box(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	return mi

## Construye un brazo completo con pivotes para animación.
## _side: 1.0 = derecho, -1.0 = izquierdo (reservado — mirroring se hace en el caller vía position)
## Retorna: Node3D (shoulder pivot) con estructura:
##   ShoulderPivot → [ShoulderJoint, UpperArm, ElbowPivot → [ElbowJoint, Forearm, Hand]]
static func build_arm(color: Color, _side: float) -> Node3D:
	var body_mat := create_material(color)
	var joint_mat := create_material(color, true)

	var shoulder := Node3D.new()
	shoulder.name = "ShoulderPivot"

	# Articulación del hombro
	var shoulder_joint := create_sphere(0.04, joint_mat)
	shoulder_joint.name = "ShoulderJoint"
	shoulder.add_child(shoulder_joint)

	# Brazo superior (cuelga hacia abajo desde el hombro)
	var upper_arm := create_cylinder(0.03, 0.22, body_mat)
	upper_arm.name = "UpperArm"
	upper_arm.position = Vector3(0, -0.13, 0)
	shoulder.add_child(upper_arm)

	# Pivote del codo (para doblar el antebrazo)
	var elbow_pivot := Node3D.new()
	elbow_pivot.name = "ElbowPivot"
	elbow_pivot.position = Vector3(0, -0.24, 0)
	shoulder.add_child(elbow_pivot)

	var elbow_joint := create_sphere(0.035, joint_mat)
	elbow_joint.name = "ElbowJoint"
	elbow_pivot.add_child(elbow_joint)

	# Antebrazo
	var forearm := create_cylinder(0.025, 0.20, body_mat)
	forearm.name = "Forearm"
	forearm.position = Vector3(0, -0.12, 0)
	elbow_pivot.add_child(forearm)

	# Mano
	var hand := create_sphere(0.04, joint_mat)
	hand.name = "Hand"
	hand.position = Vector3(0, -0.24, 0)
	elbow_pivot.add_child(hand)

	return shoulder

## Construye una pierna completa con pivotes.
## side: 1.0 = derecha, -1.0 = izquierda
static func build_leg(color: Color, _side: float) -> Node3D:
	var body_mat := create_material(color)
	var joint_mat := create_material(color, true)

	var hip := Node3D.new()
	hip.name = "HipPivot"

	var hip_joint := create_sphere(0.045, joint_mat)
	hip_joint.name = "HipJoint"
	hip.add_child(hip_joint)

	var thigh := create_cylinder(0.04, 0.28, body_mat)
	thigh.name = "Thigh"
	thigh.position = Vector3(0, -0.16, 0)
	hip.add_child(thigh)

	var knee_pivot := Node3D.new()
	knee_pivot.name = "KneePivot"
	knee_pivot.position = Vector3(0, -0.30, 0)
	hip.add_child(knee_pivot)

	var knee_joint := create_sphere(0.038, joint_mat)
	knee_joint.name = "KneeJoint"
	knee_pivot.add_child(knee_joint)

	var shin := create_cylinder(0.035, 0.28, body_mat)
	shin.name = "Shin"
	shin.position = Vector3(0, -0.16, 0)
	knee_pivot.add_child(shin)

	# Pie
	var foot := create_box(Vector3(0.06, 0.04, 0.12), joint_mat)
	foot.name = "Foot"
	foot.position = Vector3(0, -0.32, 0.03)
	knee_pivot.add_child(foot)

	return hip

static func build_torso(color: Color) -> MeshInstance3D:
	var mat := create_material(color)
	return create_box(Vector3(0.30, 0.38, 0.18), mat)

static func build_head_mesh(color: Color) -> MeshInstance3D:
	var mat := create_material(color, true)
	return create_sphere(0.12, mat)

## Aplica visibility layer a todos los MeshInstance3D hijos recursivamente.
static func set_visual_layer_recursive(node: Node, layer: int) -> void:
	if node is MeshInstance3D:
		node.layers = layer
	for child in node.get_children():
		set_visual_layer_recursive(child, layer)
