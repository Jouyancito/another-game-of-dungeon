class_name FloatingDamageNumber
extends Node3D

## Número de daño flotante — aparece sobre el enemigo golpeado.
## Uso:
##   var fdn = preload("res://scenes/fx/floating_damage_number.tscn").instantiate()
##   scene.add_child(fdn)
##   fdn.global_position = enemy.global_position + Vector3(0, 1.5, 0)
##   fdn.setup(42, false, "physical")

# ── Config tuneable ────────────────────────────────────────────────────────────
@export var rise_amount: float = 1.5       # metros que sube durante la animación
@export var rise_duration: float = 0.8     # duración total del movimiento
@export var fade_delay: float = 0.3        # segundos antes de empezar el fade
@export var pixel_size: float = 0.01       # tamaño del Label3D en world-space
@export var crit_scale_mult: float = 1.4   # escala extra en críticos

## Colores por tipo de elemento (tuneable)
@export var color_physical:  Color = Color(1.0, 1.0, 1.0, 1.0)    # blanco
@export var color_magical:   Color = Color(0.3, 0.9, 1.0, 1.0)    # cyan
@export var color_fire:      Color = Color(1.0, 0.45, 0.1, 1.0)   # naranja
@export var color_ice:       Color = Color(0.6, 0.9, 1.0, 1.0)    # cyan claro
@export var color_lightning: Color = Color(1.0, 0.95, 0.1, 1.0)   # amarillo
@export var color_poison:    Color = Color(0.4, 1.0, 0.2, 1.0)    # verde
@export var color_void:      Color = Color(0.7, 0.1, 1.0, 1.0)    # violeta
@export var color_crit:      Color = Color(1.0, 0.85, 0.0, 1.0)   # dorado

var _label: Label3D = null


func _ready() -> void:
	_label = Label3D.new()
	_label.name = "DmgLabel"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = pixel_size
	_label.no_depth_test = true
	_label.font_size = 48
	_label.outline_size = 8
	_label.outline_modulate = Color(0, 0, 0, 0.85)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


## Configura y lanza la animación del número de daño.
## amount: valor de daño a mostrar.
## is_crit: si es crítico → color dorado + escala mayor.
## element: "physical", "magical", "fire", "ice", "lightning", "poison", "void".
func setup(amount: int, is_crit: bool = false, element: String = "physical") -> void:
	if _label == null:
		await ready

	_label.text = str(amount)
	_label.modulate = _get_color(element, is_crit)

	# Escala base; críticos son más grandes
	var target_scale := Vector3.ONE
	if is_crit:
		target_scale = Vector3.ONE * crit_scale_mult
		_label.text = "!" + str(amount) + "!"
		_label.modulate = color_crit

	scale = target_scale

	# ── Tween: subir + fade out ────────────────────────────────────────────────
	var tween := create_tween()
	tween.set_parallel(false)

	# Subir suavemente
	tween.tween_property(self, "position:y", position.y + rise_amount, rise_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUAD)

	# Esperar antes del fade (en paralelo con el rise — comenzar fade_delay s después)
	tween.set_parallel(true)
	tween.tween_interval(fade_delay)

	# Fade alpha de 1 a 0 durante el tiempo restante
	var fade_duration := rise_duration - fade_delay
	tween.tween_property(_label, "modulate:a", 0.0, fade_duration)\
		.set_delay(fade_delay)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)

	tween.set_parallel(false)
	tween.tween_callback(queue_free)


func _get_color(element: String, is_crit: bool) -> Color:
	if is_crit:
		return color_crit
	match element:
		"physical":  return color_physical
		"magical":   return color_magical
		"fire":      return color_fire
		"ice":       return color_ice
		"lightning": return color_lightning
		"poison":    return color_poison
		"void":      return color_void
		_:           return color_physical
