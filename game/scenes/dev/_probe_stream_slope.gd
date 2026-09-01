extends SceneTree
## Hydrology probe: is the water surface physically possible?
## Instantiates floor1_prairie headless and walks each stream centreline at 2 m
## steps, checking the two properties real water has and geometry alone does not:
##   A. the surface never climbs going downstream (uphill flow is impossible);
##   B. the rendered channel floor stays BELOW the surface, i.e. the water is
##      actually in a bed instead of surfacing as disconnected patches.
## Run:
##   godot --headless --path game --script res://scenes/dev/_probe_stream_slope.gd

const WORLD_SEED := 912999
const STEP := 2.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_scene: PackedScene = load("res://scenes/levels/floor1_prairie.tscn")
	var fl: Node3D = floor_scene.instantiate()
	fl.set("world_seed", WORLD_SEED)
	fl.set("skip_game_ui", true)
	root.add_child(fl)
	for _i in range(10):
		await process_frame

	var polys: Array = fl.get("_stream_polylines")
	print("=== hydrology probe seed=%d — %d streams ===" % [WORLD_SEED, polys.size()])
	var all_ok := true
	for si in range(polys.size()):
		var poly: Array = polys[si]
		# Densify the centreline so the probe sees between control points.
		var line: Array[Vector2] = []
		for pi in range(poly.size() - 1):
			var a: Vector2 = poly[pi] as Vector2
			var b: Vector2 = poly[pi + 1] as Vector2
			var steps: int = maxi(1, int(ceil(a.distance_to(b) / STEP)))
			for s in range(steps):
				line.append(a.lerp(b, float(s) / float(steps)))
		line.append(poly[poly.size() - 1])

		var uphill := 0
		var worst_climb := 0.0
		var dry := 0
		var worst_dry := 0.0
		var drop := 0.0
		var prev := INF
		for p in line:
			var w: float = float(fl.call("_stream_water_y_at", p.x, p.y))
			var g: float = float(fl.call("get_render_surface_height", p.x, p.y))
			if prev != INF:
				var d: float = w - prev
				if d > 0.01:
					uphill += 1
					worst_climb = maxf(worst_climb, d)
				drop += -d
			prev = w
			# Floor above the surface = the water is buried there.
			var emerge: float = g - w
			if emerge > 0.0:
				dry += 1
				worst_dry = maxf(worst_dry, emerge)

		var ok: bool = (uphill == 0 and dry == 0)
		all_ok = all_ok and ok
		print("stream %d: %d samples | drop %.2f m | A uphill:%d (worst +%.3f m) | B floor-above-water:%d (worst %.3f m) | %s" % [
			si, line.size(), drop, uphill, worst_climb, dry, worst_dry,
			"PASS" if ok else "FAIL"])
	print("VERDICT: %s" % ("PASS" if all_ok else "FAIL"))
	quit()
