extends SceneTree
## Where is the water? Reports, per stream, the ribbon mesh that actually got
## built (vertex count + AABB) and the solved waterline width along the run,
## so "the water is invisible" can be told apart from "the water is not there".

const WORLD_SEED := 912999


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fl: Node3D = load("res://scenes/levels/floor1_prairie.tscn").instantiate()
	fl.set("world_seed", WORLD_SEED)
	fl.set("skip_game_ui", true)
	root.add_child(fl)
	for _i in range(10):
		await process_frame

	var ribbons: Node = fl.get_node_or_null("StreamRibbons")
	print("=== ribbon probe seed=%d ===" % WORLD_SEED)
	if ribbons == null:
		print("NO StreamRibbons node")
		quit()
		return
	for c in ribbons.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			print("%s: no mesh" % c.name)
			continue
		var aabb: AABB = mi.mesh.get_aabb()
		var vcount: int = 0
		for s in range(mi.mesh.get_surface_count()):
			vcount += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("%s: %d verts | AABB pos %s size %s" % [c.name, vcount, str(aabb.position), str(aabb.size)])

	# Solved waterline width sampled along stream 0.
	var polys: Array = fl.get("_stream_polylines")
	var poly: Array = polys[0]
	print("-- stream 0 waterline half-width vs channel half-width --")
	for i in range(1, poly.size()):
		var a: Vector2 = poly[i - 1] as Vector2
		var b: Vector2 = poly[i] as Vector2
		var m: Vector2 = (a + b) * 0.5
		var dirv: Vector2 = (b - a).normalized()
		var perp := Vector2(-dirv.y, dirv.x)
		var wy: float = float(fl.call("_stream_water_y_at", m.x, m.y))
		var hw: float = float(fl.call("_stream_hw_at", m.x, m.y))
		var wl: float = float(fl.call("_stream_waterline_hw", m.x, m.y, perp, wy, hw))
		var floor_y: float = float(fl.call("_compute_height_at", m.x, m.y))
		print("  seg %2d: hw %.2f | waterline %.2f | water_y %.2f | floor %.2f | column %.2f" % [
			i, hw, wl, wy, floor_y, wy - floor_y])

	# Cross-section: is it a U? Walk rim-to-rim and check the ground rises
	# monotonically away from the centre. A flat or reversed stretch means the
	# water has no single low line to follow and would leave the bed.
	var mi2: int = int(poly.size() / 2)
	var a2: Vector2 = poly[mi2 - 1] as Vector2
	var b2: Vector2 = poly[mi2] as Vector2
	var mid: Vector2 = (a2 + b2) * 0.5
	var dv: Vector2 = (b2 - a2).normalized()
	var pp := Vector2(-dv.y, dv.x)
	var hwm: float = float(fl.call("_stream_hw_at", mid.x, mid.y))
	var wym: float = float(fl.call("_stream_water_y_at", mid.x, mid.y))
	print("-- cross-section at mid-run (hw %.2f, water_y %.2f) --" % [hwm, wym])
	var prev_h: float = INF
	var flat_or_falling := 0
	for k in range(0, 21):
		var t: float = float(k) / 20.0
		var d: float = t * hwm * 1.15
		var wx: float = mid.x + pp.x * d
		var wz: float = mid.y + pp.y * d
		var hh: float = float(fl.call("_compute_height_at", wx, wz))
		var mark: String = "~~" if hh < wym else "  "
		print("   t %.2f  d %5.2f m  y %.3f  rel %+.3f %s" % [t, d, hh, hh - wym, mark])
		if prev_h != INF and hh <= prev_h + 0.001:
			flat_or_falling += 1
		prev_h = hh
	print("   concavity: %d of 20 steps NOT rising outward → %s" % [
		flat_or_falling, "FLAT/REVERSED" if flat_or_falling > 0 else "U (PASS)"])
	quit()
