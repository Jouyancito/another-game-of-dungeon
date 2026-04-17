extends Node3D
class_name CrystalCeiling

## Techo de cristal bioma-teñido — filtra luz desde arriba con tinte del bioma.
## La torre es vertical: cada piso está TECHADO, no bajo cielo abierto.
## Este componente es la "skybox interna" de cada piso.
##
## Uso:
##   1. Instanciar crystal_ceiling.tscn en la escena del piso.
##   2. Setear @export bioma al valor del piso.
##   3. Setear @export size al bounding de la arena (default 50x50).
##
## Agregar nuevo bioma: extender el enum en la línea @export_enum + agregar
## entrada en BIOMA_TINTS con el Color canon. Documentar hex en
## game/docs/art/crystal_ceiling.md § "Paleta".

@export_enum("pradera", "bosque", "hielo", "tormenta", "dimension_rota") var bioma: String = "pradera":
	set(value):
		bioma = value
		if is_inside_tree():
			_apply_bioma()

@export var size: Vector2 = Vector2(50.0, 50.0):
	set(value):
		size = value
		if is_inside_tree():
			_apply_size()

@export_range(0.3, 3.0, 0.1) var light_energy: float = 1.2:
	set(value):
		light_energy = value
		if is_inside_tree() and _light != null:
			_light.light_energy = light_energy

## Altura del techo sobre el piso (Y). La luz direccional apunta hacia abajo
## desde arriba del cristal.
@export_range(5.0, 60.0, 0.5) var height: float = 15.0:
	set(value):
		height = value
		if is_inside_tree():
			_apply_height()

## Si true, habilita el OmniLight3D central que simula "foco del sol filtrado".
@export var enable_focus_light: bool = true:
	set(value):
		enable_focus_light = value
		if is_inside_tree() and _focus_light != null:
			_focus_light.visible = enable_focus_light

# Tints canon por bioma — ver game/docs/art/crystal_ceiling.md para justificación.
const BIOMA_TINTS := {
	"pradera":        Color("#C8E68A"),  # verde-amarillo cálido — día primaveral
	"bosque":         Color("#4A7A3E"),  # verde profundo — dosel denso, sombras
	"hielo":          Color("#A8D8FF"),  # azul-cyan claro — frío, luz dura
	"tormenta":       Color("#7868A8"),  # violeta-gris — nubes eléctricas
	"dimension_rota": Color("#C84AC8"),  # magenta corrupto — wrong, glitchy
}

@onready var _mesh: MeshInstance3D = $CeilingMesh
@onready var _light: DirectionalLight3D = $CeilingLight
@onready var _focus_light: OmniLight3D = $FocusLight

var _material: StandardMaterial3D = null


func _ready() -> void:
	# Duplicar material_override para que cada instancia tenga su tint propio
	# (si no, todas las ceilings comparten la misma referencia y el último gana).
	if _mesh.material_override != null:
		_material = (_mesh.material_override as StandardMaterial3D).duplicate()
		_mesh.material_override = _material

	_apply_size()
	_apply_height()
	_apply_bioma()
	if _focus_light != null:
		_focus_light.visible = enable_focus_light


func _apply_bioma() -> void:
	var tint: Color = BIOMA_TINTS.get(bioma, Color(1, 1, 1, 1))
	if _material != null:
		_material.albedo_color = Color(tint.r, tint.g, tint.b, 0.55)
		_material.emission = tint.lightened(0.3)
	if _light != null:
		_light.light_color = tint
		_light.light_energy = light_energy
	if _focus_light != null:
		_focus_light.light_color = tint.lightened(0.2)


func _apply_size() -> void:
	if _mesh != null and _mesh.mesh is PlaneMesh:
		(_mesh.mesh as PlaneMesh).size = size


func _apply_height() -> void:
	if _mesh != null:
		_mesh.position.y = height
	if _focus_light != null:
		_focus_light.position.y = height * 0.5
