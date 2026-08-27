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

# Energy of the cool sky-fill DirectionalLight (the cool-shadow half of the
# golden-hour contrast). Dim by design: the warm FocusLight is the hero. This is
# the single owner of CeilingLight.light_energy — _apply_bioma seeds it from here.
@export_range(0.0, 3.0, 0.1) var light_energy: float = 0.5:
	set(value):
		light_energy = value
		if is_inside_tree() and _light != null:
			_light.light_energy = light_energy

## Altura del techo sobre el piso (Y). La luz direccional apunta hacia abajo
## desde arriba del cristal.
@export_range(5.0, 80.0, 0.5) var height: float = 15.0:
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

## When false, hides the emissive ceiling PLANE but KEEPS the lights. Floor 1 has a
## separate full-size CavernCeiling rock roof, so this small 120x120 plane just read
## as a "white square cloud" floating mid-map. Hidden there; lights stay.
## Caverna-DIA (2026-08-27, PO decision luz/piso1-caverna-dia): the crystal
## ceiling EMITS daylight — the plane becomes an opaque UNSHADED luminous sky
## (sampled from Joan's prairie photos) sitting just under the rock roof, so
## looking up reads as bright day instead of storm-dark stone. Crystals stay
## as accents above/through it.
@export var daylight_sky: bool = false:
	set(value):
		daylight_sky = value
		if _material != null:
			_apply_bioma()
		if _mesh != null and daylight_sky:
			_mesh.visible = true
			# The sky is LIGHT, not matter: an opaque plane above the whole
			# map with the sun's shadows on plunged the prairie into one giant
			# shadow (caught by histogram p50 0.35 -> 0.06). The sky never
			# casts.
			_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_apply_height()

@export var show_ceiling_plane: bool = true:
	set(value):
		show_ceiling_plane = value
		if is_inside_tree() and _mesh != null:
			# daylight_sky NEEDS the plane (it IS the luminous sky): the
			# legacy show_ceiling_plane=false writes (proc_lab reconciliation)
			# must not be able to hide it — caught live 2026-08-27 (generate()
			# set daylight true, then re-hid the plane two lines later).
			_mesh.visible = show_ceiling_plane or daylight_sky

## Task 3 (2026-07-20) ceiling reconciliation: when true, builds a solid rock-roof
## CSGBox3D sized to `size` (+100m padding, same margin the old geometry used) at
## `height` — the floor's actual VISIBLE cave ceiling. This used to be a separate
## duplicate system (floor1_prairie.gd's old _build_ceiling(), unrelated to this
## component's tint/light system) — merged in here so ONE object owns the roof
## mesh + tint + both ambient lights instead of four independently-authored pieces.
@export var build_rock_roof: bool = true:
	set(value):
		build_rock_roof = value
		if is_inside_tree():
			_apply_rock_roof()

## Task 3 (2026-07-20): when true, builds the warm shadow-casting-turned-soft key
## light that used to be floor1_prairie.gd's standalone `_build_key_light()`
## (node name "CavernKeyLight", art_canon.md still refers to it by that name).
## Merged in here — single ceiling-lighting owner, per spec §4 item 2 full merge.
@export var build_key_light: bool = true:
	set(value):
		build_key_light = value
		if is_inside_tree():
			_apply_key_light()

# ── Merged CavernKeyLight — D2-ACT-1 HYBRID: warm gold key vs cool-dark fill.
# Key is the HERO light (warm gold #F5D8A0); fill stays cool-dark from CeilingLight.
@export var key_light_energy: float = 0.8:
	set(value):
		key_light_energy = value
		if _key_light != null:
			_key_light.light_energy = value

## Daylight canon (2026-07-27, Joan): open-prairie floors want a real sun with
## hard shadows (Valheim fidelity model). Default false preserves the soft
## crystal-sky read the DanMachi reference synthesis asked for on cavern floors.
@export var key_light_shadow: bool = false:
	set(value):
		key_light_shadow = value
		if _key_light != null:
			_key_light.shadow_enabled = value

@export var key_light_pitch: float = -52.0:
	set(value):
		key_light_pitch = value
		if _key_light != null:
			_key_light.rotation_degrees = Vector3(key_light_pitch, key_light_yaw, 0.0)

@export var key_light_yaw: float = -35.0:
	set(value):
		key_light_yaw = value
		if _key_light != null:
			_key_light.rotation_degrees = Vector3(key_light_pitch, key_light_yaw, 0.0)

@export var key_light_color: Color = Color(0.961, 0.847, 0.627):  # #F5D8A0 warm gold
	set(value):
		key_light_color = value
		if _key_light != null:
			_key_light.light_color = value

# Tints canon por bioma — ver game/docs/art/crystal_ceiling.md para justificación.
const BIOMA_TINTS := {
	"pradera":        Color("#C8E68A"),  # verde-amarillo cálido — día primaveral
	"bosque":         Color("#4A7A3E"),  # verde profundo — dosel denso, sombras
	"hielo":          Color("#A8D8FF"),  # azul-cyan claro — frío, luz dura
	"tormenta":       Color("#7868A8"),  # violeta-gris — nubes eléctricas
	"dimension_rota": Color("#C84AC8"),  # magenta corrupto — wrong, glitchy
}

# Golden-hour light story — overrides the flat bioma tint for the LIGHTS (see
# _apply_bioma). The FocusLight is the dominant warm "diamond cave-sun" hero; the
# CeilingLight is a dim cool sky-fill = the cool-shadow half of the contrast.
const HERO_WARM := Color(0.99, 0.93, 0.81)  # #FDEDCF — warm WHITE sun (was #F5D576 gold;
                                            # the saturated gold turned the whole map mustard)
const SKY_COOL := Color(0.55, 0.62, 0.78)   # cool sky-fill (cool-shadow half)
const HERO_ENERGY := 1.8   # dropped 2.6->1.8 — the gold pool was still desertifying the ground

@onready var _mesh: MeshInstance3D = $CeilingMesh
@onready var _light: DirectionalLight3D = $CeilingLight
@onready var _focus_light: OmniLight3D = $FocusLight

var _material: StandardMaterial3D = null
var _rock_roof: CSGBox3D = null
var _key_light: DirectionalLight3D = null


func _ready() -> void:
	# Duplicar material_override para que cada instancia tenga su tint propio
	# (si no, todas las ceilings comparten la misma referencia y el último gana).
	if _mesh.material_override != null:
		_material = (_mesh.material_override as StandardMaterial3D).duplicate()
		_mesh.material_override = _material

	_apply_size()
	_apply_height()
	_apply_bioma()
	_apply_rock_roof()
	_apply_key_light()
	if _focus_light != null:
		_focus_light.visible = enable_focus_light
	if _mesh != null:
		_mesh.visible = show_ceiling_plane or daylight_sky


func _apply_bioma() -> void:
	var tint: Color = BIOMA_TINTS.get(bioma, Color(1, 1, 1, 1))
	# Warm-cozy story: lights are NO LONGER bioma-tinted (that flattened the contrast
	# and made everything one cold/green wash). Only the ceiling plane keeps a bioma
	# hue; the warm hero + cool fill come from the constants above.
	if _material != null and daylight_sky:
		# Luminous CRYSTAL day-sky (2026-08-27, PO: "el cielo es azul completo
		# — la idea era que fueran cristales, la referencia de DanMachi"): the
		# plane carries the generated crystal-sky texture (pale white-cyan
		# haze, vertical crystalline striations, sparkle motes — ref
		# danmachi_18f_under_resort.png), unshaded + soft emission so it
		# reads as the glowing ceiling that lights the floor.
		_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		_material.albedo_texture = load("res://assets/art/piso1_pradera/textures/sky_crystal_01.png")
		_material.emission_enabled = true
		_material.emission = Color(1.0, 1.0, 1.0)
		_material.emission_texture = _material.albedo_texture
		_material.emission_energy_multiplier = 0.3
	elif _material != null:
		_material.albedo_color = Color(tint.r, tint.g, tint.b, 0.55)
		_material.emission = HERO_WARM   # warm glowing "sky" (blooms via env glow)
	if _light != null:
		_light.light_color = SKY_COOL    # cool sky-fill, dim
		_light.light_energy = light_energy  # owned by the export, not hardcoded
	if _focus_light != null:
		_focus_light.light_color = HERO_WARM   # the diamond cave-sun
		_focus_light.light_energy = HERO_ENERGY


func _apply_size() -> void:
	if _mesh != null and _mesh.mesh is PlaneMesh:
		(_mesh.mesh as PlaneMesh).size = size
	_apply_rock_roof()


func _apply_height() -> void:
	if _mesh != null and daylight_sky:
		# Day-sky plane hangs UNDER the rock roof slab. The CSGBox is CENTERED
		# at `height` with 2m thickness, so its underside sits at height-1 —
		# height-0.8 put the sky INSIDE the slab and the roof occluded it
		# (pixel-probed 2026-08-27: dark with roof, perfect celeste without).
		_mesh.position.y = height - 1.8
		if _focus_light != null:
			_focus_light.position.y = height * 0.5
		return
	if _mesh != null:
		_mesh.position.y = height
	if _focus_light != null:
		_focus_light.position.y = height * 0.5
	_apply_rock_roof()


## Task 3 (2026-07-20): builds/updates the solid rock-roof CSGBox3D — the floor's
## actual visible cave ceiling, moved in from floor1_prairie.gd's old
## _build_ceiling(). +100m padding on each axis matches that function's own margin
## (roof must extend past the border so there's never a visible gap/void at the edge).
func _apply_rock_roof() -> void:
	if not build_rock_roof:
		if _rock_roof != null:
			_rock_roof.visible = false
		return
	if _rock_roof == null:
		_rock_roof = CSGBox3D.new()
		_rock_roof.name = "RockRoof"
		_rock_roof.use_collision = false
		_rock_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := StandardMaterial3D.new()
		# Joan (2026-07-20): with the key light gone, the roof must NOT self-glow —
		# a bright uniform emissive slab is exactly what read as a flat "mancha
		# café" dominating the frame. The rock ceiling is now dark bare stone;
		# it only shows form where the crystals' own light happens to graze it.
		# The crystal FIELD is the ceiling's visual identity now, not this box.
		mat.albedo_color = Color(0.10, 0.09, 0.08)
		mat.emission_enabled = false
		mat.roughness = 0.95
		_rock_roof.material_override = mat
		add_child(_rock_roof)
	_rock_roof.visible = true
	_rock_roof.size = Vector3(size.x + 100.0, 2.0, size.y + 100.0)
	_rock_roof.position = Vector3(0, height, 0)


## Task 3 (2026-07-20): the merged CavernKeyLight — moved in from floor1_prairie.gd's
## old _build_key_light(). shadow_enabled is OFF (was ON in the standalone version):
## the crystal_ceiling reference synthesis (5 DanMachi screenshots) found the
## crystal-sky reads as soft/near-absent shadow, not one hard directional cut —
## applying that finding now that the ceiling itself is being reconciled, per the
## reference doc's own note ("aplicar DESPUÉS del remodelado del techo").
func _apply_key_light() -> void:
	if not build_key_light:
		if _key_light != null:
			_key_light.visible = false
		return
	if _key_light == null:
		_key_light = DirectionalLight3D.new()
		_key_light.name = "CavernKeyLight"
		add_child(_key_light)
	_key_light.visible = true
	_key_light.shadow_enabled = key_light_shadow
	_key_light.rotation_degrees = Vector3(key_light_pitch, key_light_yaw, 0.0)
	_key_light.light_color = key_light_color
	_key_light.light_energy = key_light_energy


## Task 3 (2026-07-20): repositions FocusLight's XZ (the "diamond cave-sun") to sit
## above the crystal field's designated CORE cluster — formalizes the two-tier
## crystal hierarchy (CORE=brightest/sun, SKY=cooler accents) by making this
## component's own light and the crystal field's brightest cluster agree on where
## the "sun" is, instead of each picking an independent position. Y is left alone
## (owned by _apply_height/height*0.5 — that's a lighting-practicality height, not
## meant to match the crystal's own decorative height near the roof).
func anchor_focus_light(world_xz: Vector2) -> void:
	if _focus_light != null:
		_focus_light.position.x = world_xz.x
		_focus_light.position.z = world_xz.y
