class_name ArcaneStormVFX
extends VFXBase

## Arcane Storm — área AoE canalizada con rayos radiales.
## Visual: anillo de energía en el suelo + rayos que salen del centro + rotación.
## Duración controlada por el canal del Mago (0 = sostenido).

@export var storm_color: Color = Color(0.3, 0.6, 1.0, 1.0)      # azul arcano
@export var storm_emission: Color = Color(0.1, 0.4, 1.0, 1.0)   # glow azul
@export var storm_radius: float = 3.0                             # metros
@export var ring_segments: int = 32                               # suavidad del anillo
@export var ray_count: int = 6                                    # rayos radiales
@export var rotation_speed: float = 1.2                           # rad/s de rotación

var _ring_mesh: MeshInstance3D = null
var _rays_root: Node3D = null
var _particles: GPUParticles3D = null
var _rotation_time: float = 0.0


func _on_play() -> void:
	_build_ring()
	_build_rays()
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
	_rotation_time += delta
	if _rays_root:
		_rays_root.rotation.y = _rotation_time * rotation_speed


func _build_ring() -> void:
	# Anillo en el suelo usando ImmediateMesh (línea de segmentos)
	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.name = "StormRing"
	var im := ImmediateMesh.new()
	_ring_mesh.mesh = im

	var mat := StandardMaterial3D.new()
	mat.albedo_color = storm_color
	mat.emission_enabled = true
	mat.emission = storm_emission
	mat.emission_energy_multiplier = 2.0
	mat.flags_unshaded = true
	_ring_mesh.material_override = mat

	# Dibujar círculo
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(ring_segments + 1):
		var angle: float = TAU * float(i) / float(ring_segments)
		im.surface_add_vertex(Vector3(cos(angle) * storm_radius, 0.05, sin(angle) * storm_radius))
	im.surface_end()

	add_child(_ring_mesh)


func _build_rays() -> void:
	_rays_root = Node3D.new()
	_rays_root.name = "RaysRoot"
	add_child(_rays_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = storm_color
	mat.emission_enabled = true
	mat.emission = storm_emission
	mat.emission_energy_multiplier = 2.5
	mat.flags_unshaded = true

	for i in range(ray_count):
		var angle: float = TAU * float(i) / float(ray_count)
		var ray_mesh := MeshInstance3D.new()
		ray_mesh.name = "Ray%d" % i
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		im.surface_add_vertex(Vector3(0, 0.1, 0))
		im.surface_add_vertex(Vector3(cos(angle) * storm_radius, randf_range(0.1, 1.5), sin(angle) * storm_radius))
		im.surface_end()
		ray_mesh.mesh = im
		ray_mesh.material_override = mat
		_rays_root.add_child(ray_mesh)


func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "StormParticles"
	_particles.amount = 60
	_particles.lifetime = 1.2
	_particles.explosiveness = 0.0
	_particles.randomness = 0.7

	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0, 1, 0)
	proc.initial_velocity_min = 0.5
	proc.initial_velocity_max = 2.0
	proc.gravity = Vector3(0, -1.0, 0)
	proc.color = storm_color
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = storm_radius * 0.8
	_particles.process_material = proc
	add_child(_particles)
