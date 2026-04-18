class_name UnstableOrbVFX
extends VFXBase

## Unstable Orb — proyectil de energía púrpura inestable.
## Más dramático que mage_projectile: tamaño mayor, emisión pulsante, distorsión.
## Instancia volátil que viaja hacia el objetivo y explota en impacto.
##
## Uso: spawn en origin, luego mover via Tween o mage.gd al objetivo.

@export var orb_color: Color = Color(0.7, 0.1, 1.0, 1.0)      # violeta canon
@export var orb_emission: Color = Color(0.5, 0.0, 1.0, 1.0)   # glow púrpura
@export var orb_scale: float = 0.35                             # metros radio
@export var pulse_speed: float = 3.0                            # Hz del pulso
@export var pulse_amplitude: float = 0.12                       # amplitud del pulso de escala

var _mesh: MeshInstance3D = null
var _particles: GPUParticles3D = null
var _pulse_time: float = 0.0
var _base_scale: Vector3


func _on_play() -> void:
	_build_orb()
	_base_scale = Vector3.ONE * orb_scale
	scale = _base_scale
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
	# Pulso de escala — simula inestabilidad de la orba
	_pulse_time += delta * pulse_speed
	var pulse: float = 1.0 + sin(_pulse_time) * pulse_amplitude
	scale = _base_scale * pulse


func _build_orb() -> void:
	# Mesh esférico principal
	_mesh = MeshInstance3D.new()
	_mesh.name = "OrbMesh"
	var sphere := SphereMesh.new()
	sphere.radius = orb_scale
	sphere.height = orb_scale * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6

	var mat := StandardMaterial3D.new()
	mat.albedo_color = orb_color
	mat.emission_enabled = true
	mat.emission = orb_emission
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	sphere.material = mat
	_mesh.mesh = sphere
	add_child(_mesh)

	# Partículas de chispas orbitales
	_particles = GPUParticles3D.new()
	_particles.name = "OrbSparks"
	_particles.amount = 24
	_particles.lifetime = 0.4
	_particles.explosiveness = 0.0
	_particles.randomness = 0.6
	_particles.one_shot = false

	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 0, 0)
	proc.initial_velocity_min = 0.3
	proc.initial_velocity_max = 0.8
	proc.gravity = Vector3.ZERO
	proc.color = Color(0.8, 0.2, 1.0, 0.9)
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = orb_scale * 1.2
	_particles.process_material = proc
	add_child(_particles)
