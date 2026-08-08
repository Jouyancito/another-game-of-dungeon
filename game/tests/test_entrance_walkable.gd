extends GutTest
## A door you cannot walk through is not a door.
##
## Joan, 2026-08-08, after a night of chasing an invisible barrier at the floor-1
## entrance: "la idea es que este tipo de diseño sea con este detalle listo, si
## haces una puerta, lo logico es que pueda pasar por ella, sin estamparme o
## imposibilidad de avanzar".
##
## That is a design rule, not a ticket, so it belongs in the gate. The bug it
## catches was a 0.30m vertical lip where the room's floor slab ended: Godot
## treats anything steeper than floor_max_angle (45 degrees) as a WALL, and that
## edge measured 71.6 degrees. Invisible, unjumpable, and it survived nine
## hypotheses and six broken probes because every one of them asked "is there
## space here?" instead of "can a body walk through here?".
##
## Those are different questions. This asks the second one.

const LEVEL := preload("res://scenes/levels/floor1_prairie.tscn")

## Godot's own limit for what counts as floor rather than wall.
const FLOOR_MAX_ANGLE_DEG := 45.0
## Headroom margin under the player's height, so a low beam fails too.
const PLAYER_HEIGHT := 1.8
const PLAYER_RADIUS := 0.35

var _level: Node3D


func before_each() -> void:
	_level = LEVEL.instantiate()
	_level.set("world_seed", 12345)
	# Everything that can physically block the player stays ON. A harness that
	# switches bodies off cannot answer a walkability question — that mistake made
	# the dev capture report the doorway clear while it was not.
	_level.set("active_layers", {
		"terrain": true, "pois": true, "vegetation": true, "border": true,
		"streams": true, "player": false, "enemies": true, "hud": false,
	})
	add_child_autofree(_level)
	for _i in range(30):
		await get_tree().process_frame


func _space() -> PhysicsDirectSpaceState3D:
	return _level.get_world_3d().direct_space_state


## Ground height by RAYCAST against the real collision mesh, started below the
## lintel. get_terrain_height() interpolates bilinearly and does not describe the
## surface the player collides with; a ray dropped from high up hits the door
## beams first and reads their edges as six-metre cliffs. Both mistakes were made.
func _ground_at(x: float, z: float, from_y: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, from_y, z), Vector3(x, from_y - 25.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = _space().intersect_ray(q)
	return hit["position"].y if not hit.is_empty() else NAN


func test_entrance_has_no_step_the_engine_reads_as_a_wall() -> void:
	if not _level.get("_entrance_anchor_valid"):
		pending("this seed produced no entrance")
		return
	var anchor: Vector3 = _level.get("_entrance_anchor")
	var floor_y: float = _level.get("_entrance_floor_y")
	var mouth_x: float = anchor.x + float(_level.get("ENTRANCE_HALL_LEN")) * 0.5

	var worst_deg := 0.0
	var worst_dx := 0.0
	var prev_y := NAN
	const STEP := 0.1
	for i in range(-20, 61):
		var dx: float = float(i) * STEP
		var gy: float = _ground_at(mouth_x + dx, anchor.z, floor_y + 1.0)
		if is_nan(gy):
			prev_y = NAN
			continue
		if not is_nan(prev_y):
			var deg: float = rad_to_deg(atan2(absf(gy - prev_y), STEP))
			if deg > worst_deg:
				worst_deg = deg
				worst_dx = dx
		prev_y = gy

	assert_lt(worst_deg, FLOOR_MAX_ANGLE_DEG,
		"El suelo del vano tiene una pendiente de %.1f grados en dx=%+.2f. Godot trata "
		% [worst_deg, worst_dx]
		+ "todo lo mas empinado que %.0f como PARED, asi que eso es una barrera "
		% [FLOOR_MAX_ANGLE_DEG]
		+ "invisible: el jugador no la sube ni la salta.")


func test_a_player_sized_body_fits_through_the_doorway() -> void:
	if not _level.get("_entrance_anchor_valid"):
		pending("this seed produced no entrance")
		return
	var anchor: Vector3 = _level.get("_entrance_anchor")
	var floor_y: float = _level.get("_entrance_floor_y")
	var mouth_x: float = anchor.x + float(_level.get("ENTRANCE_HALL_LEN")) * 0.5

	var cap := CapsuleShape3D.new()
	cap.radius = PLAYER_RADIUS
	cap.height = PLAYER_HEIGHT

	var blocked: Array[String] = []
	for i in range(-20, 61):
		var dx: float = float(i) * 0.1
		var px: float = mouth_x + dx
		var gy: float = _ground_at(px, anchor.z, floor_y + 1.0)
		if is_nan(gy):
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		# Feet ON the ground. Floating the capsule at a fixed height makes it miss
		# the very obstacles it is meant to find — that produced a false "clear".
		q.transform = Transform3D(Basis(), Vector3(px, gy + PLAYER_HEIGHT * 0.5 + 0.01, anchor.z))
		q.collide_with_areas = false
		for hit in _space().intersect_shape(q, 8):
			var n: String = str((hit["collider"] as Node).name)
			if n == "EntranceFloor":
				continue      # standing on the floor is not an obstruction
			blocked.append("dx=%+.1f: %s" % [dx, n])
			break

	assert_eq(blocked.size(), 0,
		"Un cuerpo del tamano del jugador choca al cruzar el vano: %s"
		% ", ".join(PackedStringArray(blocked)))
