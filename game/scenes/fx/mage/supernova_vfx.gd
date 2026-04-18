class_name SupernovaVFX
extends VFXBase

## Supernova — explosión expansiva + shockwave.
## One-shot: duration_s define cuánto dura la animación total.
## Fases: flash inicial (0.1s) → expansión esfera (0.4s) → shockwave ring (0.3s) → fade (0.2s).

@export var explosion_color: Color = Color(1.0, 0.6, 0.1, 1.0)    # naranja explosión
@export var core_color: Color = Color(1.0, 0.95, 0.8, 1.0)        # núcleo blanco caliente
@export var shockwave_color: Color = Color(0.8, 0.3, 1.0, 0.85)   # borde violeta
@export var max_radius: float = 4.0                                 # radio máximo de la esfera
@export var shockwave_thickness: float = 0.15                       # grosor del anillo shockwave
@export var shockwave_segments: int = 32

var _flash: MeshInstance3D = null
var _explosion_sphere: MeshInstance3D = null
var _shockwave_ring: MeshInstance3D = null
var _particles_burst: GPUParticles3D = null
var _particles_debris: GPUParticles3D = null


func _ready() -> void:
	super._ready()
	# Supernova es siempre one-shot — forzar duration si es 0
	if duration_s <= 0.0:
		duration_s = 1.0


func _on_play() -> void:
	_build_flash()
	_build_explosion_sphere()
	_build_shockwave()
	_build_particles()
	_animate_sequence()


func _on_stop() -> void:
	set_process(false)


func _animate_sequence() -> void:
	var tween := create_tween()
	tween.set_parallel(false)

	# Fase 1: Flash blanco explosivo (0.0 → 0.1s)
	if _flash:
		_flash.scale = Vector3.ZERO
		tween.tween_property(_flash, "scale", Vector3.ONE * max_radius * 0.3, 0.1)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tween.tween_property(_flash, "scale", Vector3.ZERO, 0.1)\
			.set_ease(Tween.EASE_IN)

	# Fase 2: Expansión esfera naranja (0.1 → 0.5s)
	if _explosion_sphere:
		_explosion_sphere.scale = Vector3.ZERO
		tween.tween_property(_explosion_sphere, "scale", Vector3.ONE * max_radius, 0.4)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Shockwave ring expande paralelo a la esfera
	tween.set_parallel(true)
	if _shockwave_ring:
		_shockwave_ring.scale = Vector3.ZERO
		tween.tween_property(_shockwave_ring, "scale", Vector3.ONE * (max_radius * 1.2), 0.5)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.set_parallel(false)

	# Fase 3: Fade out esfera + shockwave (0.5 → 0.8s)
	if _explosion_sphere and _explosion_sphere.mesh and _explosion_sphere.mesh.material:
		var mat: StandardMaterial3D = _explosion_sphere.mesh.material as StandardMaterial3D
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)\
				.set_ease(Tween.EASE_IN)
	if _shockwave_ring:
		tween.tween_property(_shockwave_ring, "scale:y", 0.0, 0.3)\
			.set_ease(Tween.EASE_IN)

	# Partículas de debris
	if _particles_burst:
		_particles_burst.emitting = true
	if _particles_debris:
		_particles_debris.emitting = true


func _build_flash() -> void:
	_flash = MeshInstance3D.new()
	_flash.name = "FlashCore"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = core_color
	mat.emission_enabled = true
	mat.emission = core_color
	mat.emission_energy_multiplier = 8.0
	mat.flags_unshaded = true
	sphere.material = mat
	_flash.mesh = sphere
	_flash.scale = Vector3.ZERO
	add_child(_flash)


func _build_explosion_sphere() -> void:
	_explosion_sphere = MeshInstance3D.new()
	_explosion_sphere.name = "ExplosionSphere"
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = explosion_color
	mat.emission_enabled = true
	mat.emission = Color(explosion_color.r, explosion_color.g * 0.5, 0.0, 1.0)
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	sphere.material = mat
	_explosion_sphere.mesh = sphere
	_explosion_sphere.scale = Vector3.ZERO
	add_child(_explosion_sphere)


func _build_shockwave() -> void:
	_shockwave_ring = MeshInstance3D.new()
	_shockwave_ring.name = "ShockwaveRing"

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(shockwave_segments + 1):
		var angle: float = TAU * float(i) / float(shockwave_segments)
		im.surface_add_vertex(Vector3(cos(angle), 0.0, sin(angle)))
	im.surface_end()
	_shockwave_ring.mesh = im

	var mat := StandardMaterial3D.new()
	mat.albedo_color = shockwave_color
	mat.emission_enabled = true
	mat.emission = shockwave_color
	mat.emission_energy_multiplier = 4.0
	mat.flags_unshaded = true
	_shockwave_ring.material_override = mat
	_shockwave_ring.scale = Vector3.ZERO
	add_child(_shockwave_ring)


func _build_particles() -> void:
	# Burst inicial de energía
	_particles_burst = GPUParticles3D.new()
	_particles_burst.name = "BurstParticles"
	_particles_burst.amount = 80
	_particles_burst.lifetime = 0.8
	_particles_burst.explosiveness = 0.9
	_particles_burst.one_shot = true
	_particles_burst.emitting = false

	var proc_burst := ParticleProcessMaterial.new()
	proc_burst.direction = Vector3(0, 1, 0)
	proc_burst.spread = 180.0
	proc_burst.initial_velocity_min = 3.0
	proc_burst.initial_velocity_max = 8.0
	proc_burst.gravity = Vector3(0, -4.0, 0)
	proc_burst.color = explosion_color
	proc_burst.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	_particles_burst.process_material = proc_burst
	add_child(_particles_burst)

	# Debris flotantes más lentos
	_particles_debris = GPUParticles3D.new()
	_particles_debris.name = "DebrisParticles"
	_particles_debris.amount = 40
	_particles_debris.lifetime = 2.0
	_particles_debris.explosiveness = 0.7
	_particles_debris.one_shot = true
	_particles_debris.emitting = false

	var proc_deb := ParticleProcessMaterial.new()
	proc_deb.direction = Vector3(0, 0.5, 0)
	proc_deb.spread = 120.0
	proc_deb.initial_velocity_min = 1.0
	proc_deb.initial_velocity_max = 4.0
	proc_deb.gravity = Vector3(0, -2.0, 0)
	proc_deb.color = shockwave_color
	proc_deb.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_deb.emission_sphere_radius = 1.0
	_particles_debris.process_material = proc_deb
	add_child(_particles_debris)
