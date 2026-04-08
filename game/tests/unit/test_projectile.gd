extends GutTest

# Tests para MageProjectile — movimiento, alcance máximo, destrucción

var proj_scene: PackedScene = preload("res://scenes/projectile/mage_projectile.tscn")


func _create_projectile(dmg := 20.0, dir := Vector3.FORWARD) -> Area3D:
	var p = proj_scene.instantiate()
	p.damage = dmg
	p.direction = dir
	add_child_autofree(p)
	return p


# ─── Valores por defecto ───

func test_default_speed() -> void:
	var p = _create_projectile()
	assert_eq(p.speed, 20.0)


func test_default_max_range() -> void:
	var p = _create_projectile()
	assert_eq(p.max_range, 15.0)


func test_initial_distance_zero() -> void:
	var p = _create_projectile()
	assert_eq(p.distance_traveled, 0.0)


# ─── Movimiento ───

func test_moves_in_direction() -> void:
	var p = _create_projectile(20.0, Vector3.FORWARD)
	var start_pos = p.global_position
	p._physics_process(0.1)
	# FORWARD = -Z en Godot
	assert_ne(p.global_position, start_pos, "Se movió de su posición inicial")


func test_distance_tracked() -> void:
	var p = _create_projectile(20.0, Vector3(0, 0, -1))
	p._physics_process(0.5)
	# speed=20, delta=0.5 → movement = 10 units
	assert_almost_eq(p.distance_traveled, 10.0, 0.01, "Registra distancia recorrida")


func test_damage_is_configurable() -> void:
	var p = _create_projectile(55.0)
	assert_eq(p.damage, 55.0, "Daño se setea correctamente")


func test_direction_is_normalized_movement() -> void:
	var p = _create_projectile(20.0, Vector3(1, 0, 0))
	var start_x = p.global_position.x
	p._physics_process(0.1)
	assert_gt(p.global_position.x, start_x, "Se mueve en +X")


func test_frees_at_max_range() -> void:
	var p = _create_projectile(20.0, Vector3(0, 0, -1))
	# speed=20, max_range=15 → a delta=0.8: distance = 16 >= 15 → queue_free
	p._physics_process(0.8)
	await get_tree().process_frame
	assert_false(is_instance_valid(p), "Se destruye al superar max_range")


func test_does_not_free_before_max_range() -> void:
	var p = _create_projectile(20.0, Vector3(0, 0, -1))
	# speed=20, delta=0.5 → distance = 10 < 15
	p._physics_process(0.5)
	assert_true(is_instance_valid(p), "Sigue vivo antes de max_range")
	assert_almost_eq(p.distance_traveled, 10.0, 0.01)
