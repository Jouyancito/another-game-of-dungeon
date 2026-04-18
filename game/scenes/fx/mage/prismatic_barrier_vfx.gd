class_name PrismaticBarrierVFX
extends VFXBase

## Prismatic Barrier — dome prismático alrededor del caster.
## Visual: semiesfera traslúcida con color iridiscente + borde luminoso + partículas.
## Sostenido mientras la barrera esté activa (duration_s = 0).

@export var dome_radius: float = 1.4              # metros — envuelve al caster
@export var dome_segments: int = 16               # suavidad
@export var base_color: Color = Color(0.4, 0.8, 1.0, 0.18)   # base cyan translúcido
@export var rim_color: Color = Color(0.8, 0.4, 1.0, 0.9)     # borde violeta
@export var rim_emission: Color = Color(0.6, 0.2, 1.0, 1.0)  # glow del borde
@export var pulse_speed: float = 1.5              # Hz del pulso de opacidad
@export var pulse_amplitude: float = 0.06         # amplitud

var _dome: MeshInstance3D = null
var _rim_ring: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _dome_mat: StandardMaterial3D = null
var _pulse_time: float = 0.0


func _on_play() -> void:
	_build_dome()
	_build_rim()
	_build_particles()
	set_process(true)
	if _particles:
		_particles.emitting = true


func _on_stop() -> void:
	set_process(false)
	if _particles:
		_particles.emitting = false


func _process(delta: float) -> void:
	if not _playing:
		return
	# Pulso de opacidad — "respiración" del escudo
	_pulse_time += delta * pulse_speed
	if _dome_mat != null:
		var alpha: float = base_color.a + sin(_pulse_time) * pulse_amplitude
		var col: Color = base_color
		col.a = clampf(alpha, 0.05, 0.35)
		_dome_mat.albedo_color = col


func _build_dome() -> void:
	_dome = MeshInstance3D.new()
	_dome.name = "DomeMesh"

	# Semiesfera (upper half of SphereMesh) — usamos SphereMesh completo con cull FRONT
	var sphere := SphereMesh.new()
	sphere.radius = dome_radius
	sphere.height = dome_radius * 2.0
	sphere.radial_segments = dome_segments
	sphere.rings = dome_segments / 2

	_dome_mat = StandardMaterial3D.new()
	_dome_mat.albedo_color = base_color
	_dome_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dome_mat.cull_mode = BaseMaterial3D.CULL_FRONT  # ver interior
	_dome_mat.flags_unshaded = false
	sphere.material = _dome_mat
	_dome.mesh = sphere
	add_child(_dome)


func _build_rim() -> void:
	# Anillo brillante en la base del dome
	_rim_ring = MeshInstance3D.new()
	_rim_ring.name = "RimRing"

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(dome_segments + 1):
		var angle: float = TAU * float(i) / float(dome_segments)
		im.surface_add_vertex(Vector3(cos(angle) * dome_radius, 0.02, sin(angle) * dome_radius))
	im.surface_end()
	_rim_ring.mesh = im

	var mat := StandardMaterial3D.new()
	mat.albedo_color = rim_color
	mat.emission_enabled = true
	mat.emission = rim_emission
	mat.emission_energy_multiplier = 3.0
	mat.flags_unshaded = true
	_rim_ring.material_override = mat
	add_child(_rim_ring)


func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "BarrierShards"
	_particles.amount = 30
	_particles.lifetime = 2.0
	_particles.explosiveness = 0.05
	_particles.randomness = 0.5

	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 1, 0)
	proc.initial_velocity_min = 0.2
	proc.initial_velocity_max = 0.8
	proc.gravity = Vector3.ZERO
	proc.color = Color(0.6, 0.9, 1.0, 0.8)
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = dome_radius
	_particles.process_material = proc
	add_child(_particles)
