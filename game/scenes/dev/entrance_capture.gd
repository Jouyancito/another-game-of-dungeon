extends Node3D
## DEV HARNESS — renders the floor-1 entrance antechamber from fixed viewpoints.
##
## The antechamber is the first thing a player sees on every run, and it is built
## from procedural terrain (a carved trench) plus hand-placed stone. Whether those
## two actually meet cannot be read off the source: a slab can float, the roof can
## surface, the mouth can end up buried. So it gets looked at.
##
## Instantiates the real floor1_prairie with the player and enemies off, resolves
## the entrance anchor through the SAME POISystem call the level uses, and shoots
## the four views that can each hide a different failure:
##   00 inside, facing the exit     — is the doorway clear and the room lit?
##   01 inside, facing the portal   — does the far end read as a destination?
##   02 outside on the ramp         — does the mouth read as a way in?
##   03 high oblique                — does the trench sit in the prairie or gash it?
##
## Run:
##   Godot_v4.6.2-stable_win64_console.exe --path game \
##       res://scenes/dev/entrance_capture.tscn -- --seed=12345
##
## Output: game/tools/godot/entrance_capture/*.png

const OUT_DIR := "res://tools/godot/entrance_capture/"
const SV_SIZE := Vector2i(1280, 720)
const EYE := 1.7

var _sv: SubViewport
var _cam: Camera3D
var _floor: Node3D
var _seed := 12345


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			_seed = int(a.split("=", true, 1)[1])

	var win := get_window()
	win.size = Vector2i(1, 1)
	win.position = Vector2i(-4000, -4000)
	win.set_flag(Window.FLAG_NO_FOCUS, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(SV_SIZE)
	add_child(svc)
	_sv = SubViewport.new()
	_sv.size = SV_SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_sv)

	_floor = (load("res://scenes/levels/floor1_prairie.tscn") as PackedScene).instantiate() as Node3D
	_floor.set("world_seed", _seed)
	# Player off: it would spawn inside the room and stand in every shot. Enemies off
	# for the same reason. Everything that SHAPES the entrance stays on.
	_floor.set("active_layers", {
		"terrain": true, "pois": true, "vegetation": true, "border": true,
		# enemies ENCENDIDO desde 2026-08-08. Estaba en false "para que no salgan en
		# las fotos", y eso hacía que el harness midiera un nivel que NO es el que se
		# juega: toda sonda de transitabilidad daba libre porque faltaban cuerpos.
		# Joan reporta una barrera INVISIBLE, y hay 24 enemigos que son primitivas
		# sin malla — invisibles con colisión. Un harness que apaga cuerpos no puede
		# responder "¿se puede caminar por acá?".
		"streams": true, "player": false, "enemies": true, "hud": false,
	})
	_sv.add_child(_floor)

	_cam = Camera3D.new()
	_cam.fov = 70.0
	_sv.add_child(_cam)
	_cam.current = true

	for _i in range(45):
		await get_tree().process_frame

	# Read the level's OWN anchor, not a second call to POISystem: the level snaps the
	# mouth to a terrain vertex after resolving it, so an independently recomputed
	# anchor lands a few metres off and every measurement below samples the wrong
	# spot — which is exactly how a "buried doorway" reading survived one round.
	var anchor: Vector3 = _floor.get("_entrance_anchor")
	var surface: float = _floor.call("get_terrain_height", anchor.x, anchor.z)
	var hall_len: float = _floor.get("ENTRANCE_HALL_LEN")
	var depth: float = _floor.get("ENTRANCE_DEPTH")
	var run: float = _floor.get("ENTRANCE_TRENCH_RUN")
	var floor_y: float = _floor.get("_entrance_floor_y")
	var mouth_x: float = anchor.x + hall_len * 0.5

	print("[entrance_capture] seed=%d anchor=(%.1f, %.1f) surface=%.2f floor=%.2f mouth_x=%.1f"
		% [_seed, anchor.x, anchor.z, surface, floor_y, mouth_x])
	# Terrain profile along the trench: the numbers that say whether the ramp is
	# walkable and whether the room actually ended up underground.
	for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var px: float = mouth_x + run * f
		print("[entrance_capture]   trench %3d%%  x=%7.1f  terrain=%6.2f  (%.2f under prairie)"
			% [int(f * 100.0), px, _floor.call("get_terrain_height", px, anchor.z),
			   surface - _floor.call("get_terrain_height", px, anchor.z)])

	# ── Perfil del UMBRAL ─────────────────────────────────────────────────────
	# El perfil de trinchera de arriba muestrea de la boca hacia AFUERA en pasos de
	# 8 m, así que se saltea entero el metro donde vive el bloqueo. Joan queda pegado
	# al salir caminando (reportado 2026-08-01 y otra vez el 2026-08-07), y lo que
	# decide eso es la altura del suelo CONTRA el piso de la sala en los pocos metros
	# alrededor de la costura. Un escalón mayor a ~0.35 m no se sube caminando.
	print("[entrance_capture] --- umbral (z = centro del vano) ---")
	print("[entrance_capture]     floor_y sala = %.2f" % floor_y)
	for dx in [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0]:
		var tx: float = mouth_x + dx
		var th: float = _floor.call("get_terrain_height", tx, anchor.z)
		var step: float = th - floor_y
		var flag: String = ""
		if step > 0.35:
			flag = "  <-- ESCALON, bloquea"
		elif step > 0.0:
			flag = "  (sube, se pasa)"
		print("[entrance_capture]   dx=%+5.1f  x=%8.2f  terreno=%7.2f  vs piso=%+6.2f%s"
			% [dx, tx, th, step, flag])

	# ── Qué cuerpo bloquea la salida ──────────────────────────────────────────
	# El perfil de arriba dice que el TERRENO no bloquea, así que teorizar sobre cuál
	# de las mallas es culpable ya falló una vez. Se le pregunta a la física: rayos a
	# tres alturas del cuerpo, desde adentro de la sala hacia afuera, reportando el
	# nombre del nodo golpeado. Eso nombra al culpable en vez de deducirlo.
	var space: PhysicsDirectSpaceState3D = _floor.get_world_3d().direct_space_state
	print("[entrance_capture] --- que bloquea la salida ---")
	# Un rayo por el eje central pasa limpio, pero Joan igual queda pegado: nadie
	# camina exactamente por el eje. Se barre a lo ancho del vano Y a tres alturas.
	for dz in [-2.5, -1.5, 0.0, 1.5, 2.5]:
		var blocked_at: String = ""
		for h in [0.30, 1.00, 1.70]:
			var from := Vector3(mouth_x - 6.0, floor_y + h, anchor.z + dz)
			var to := Vector3(mouth_x + 12.0, floor_y + h, anchor.z + dz)
			var q := PhysicsRayQueryParameters3D.create(from, to)
			q.collide_with_areas = false
			var hit: Dictionary = space.intersect_ray(q)
			if not hit.is_empty():
				var n: Node = hit["collider"]
				blocked_at += "  [y+%.2f] '%s' en dx%+.2f" % [h, n.name, hit["position"].x - mouth_x]
		print("[entrance_capture]   dz=%+5.1f %s" % [dz, blocked_at if blocked_at != "" else " LIBRE a las 3 alturas"])

	# Y con la CÁPSULA real del jugador, que es lo que de verdad se traba: un rayo
	# fino pasa por huecos que un cuerpo de 0.4 m de radio no pasa.
	# Medidas REALES del jugador (player.tscn: radius 0.35, height 1.8), no inventadas.
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	# Barrido 2D. La cápsula se planta APOYADA sobre lo que haya de suelo en cada
	# punto (terreno o losa, el que esté más alto), que es donde de verdad está el
	# jugador — plantarla a una altura fija la deja flotando fuera de la losa y
	# entonces no toca nada, que es como una primera pasada dio "libre" en falso.
	# Marca sólo lo que NO es piso legítimo.
	print("[entrance_capture]   -- barrido 2D con capsula r=0.40 h=1.80, apoyada en el suelo --")
	for dz2 in [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]:
		var row: String = ""
		for dx2 in [-1.0, 0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0]:
			var px2: float = mouth_x + dx2
			var pz2: float = anchor.z + dz2
			var ground: float = maxf(_floor.call("get_terrain_height", px2, pz2), floor_y)
			var pq := PhysicsShapeQueryParameters3D.new()
			pq.shape = cap
			# +0.90 = mitad de la cápsula, o sea los pies justo en el suelo.
			pq.transform = Transform3D(Basis(), Vector3(px2, ground + 0.90, pz2))
			pq.collide_with_areas = false
			var hits: Array[Dictionary] = space.intersect_shape(pq, 8)
			var bad: PackedStringArray = []
			for hh in hits:
				var nm: String = str((hh["collider"] as Node).name)
				if nm != "EntranceFloor":
					bad.append(nm)
			row += "  %s" % ("." if bad.is_empty() else "[%s]" % bad[0])
		print("[entrance_capture]     dz=%+5.1f %s" % [dz2, row])
	print("[entrance_capture]     (columnas dx = -1.0 0.0 0.5 1.0 1.5 2.0 3.0 4.0 ; '.' = paso libre)")

	# ── TECHO sobre el corredor ───────────────────────────────────────────────
	# Joan: "cuando voy saliendo y llego al marco, aparece el pedazo de tierra ENCIMA
	# y me bloquea". El barrido de arriba mira a la altura del cuerpo y da libre, así
	# que lo que sobra no está al lado: está arriba. Rayo hacia el cielo desde la
	# cabeza, reportando qué hay y a cuánto despeje. Menos de 1.8 m = no se pasa.
	print("[entrance_capture]   -- techo sobre el corredor (rayo hacia arriba) --")
	for dz3 in [-2.0, 0.0, 2.0]:
		var row2: String = ""
		for dx3 in [0.0, 1.0, 2.0, 3.0, 4.0, 6.0, 9.0]:
			var px3: float = mouth_x + dx3
			var pz3: float = anchor.z + dz3
			var g3: float = maxf(_floor.call("get_terrain_height", px3, pz3), floor_y)
			var q3 := PhysicsRayQueryParameters3D.create(
				Vector3(px3, g3 + 0.10, pz3), Vector3(px3, g3 + 12.0, pz3))
			q3.collide_with_areas = false
			var h3: Dictionary = space.intersect_ray(q3)
			if h3.is_empty():
				row2 += "   dx%+.0f:cielo" % dx3
			else:
				var clear: float = h3["position"].y - g3
				row2 += "   dx%+.0f:%s@%.2f%s" % [dx3, str((h3["collider"] as Node).name).replace("Entrance", ""),
					clear, "!!" if clear < 1.85 else ""]
		print("[entrance_capture]     dz=%+4.1f%s" % [dz3, row2])
	print("[entrance_capture]     ('!!' = despeje menor a 1.85 m, el jugador NO pasa)")

	# ── Barrido ANCHO ─────────────────────────────────────────────────────────
	# El barrido de arriba (dx -1..+4, dz +-3) dio limpio y Joan SIGUE trabado, con
	# la cámara metida dentro de la tierra ("no puedo moverme ni saltar" = embebido
	# en un collider, no chocando contra él). O sea el problema está fuera de la
	# ventana que se estaba mirando. Se abre a todo el corredor.
	print("[entrance_capture]   -- barrido ANCHO del corredor --")
	var cols: String = "         "
	for dxh in range(0, 15, 1):
		cols += "%2d" % dxh
	print("[entrance_capture]   dx->%s" % cols)
	for dzw in [-6.0, -5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]:
		var row3: String = ""
		var seen: Dictionary = {}
		for dxi in range(0, 15):
			var px4: float = mouth_x + float(dxi)
			var pz4: float = anchor.z + dzw
			var g4: float = maxf(_floor.call("get_terrain_height", px4, pz4), floor_y)
			var pq4 := PhysicsShapeQueryParameters3D.new()
			pq4.shape = cap
			pq4.transform = Transform3D(Basis(), Vector3(px4, g4 + 0.90, pz4))
			pq4.collide_with_areas = false
			var hits4: Array[Dictionary] = space.intersect_shape(pq4, 8)
			var mark: String = " ."
			for hh4 in hits4:
				var nm4: String = str((hh4["collider"] as Node).name)
				if nm4 == "EntranceFloor":
					continue
				seen[nm4] = true
				mark = " #" if nm4.contains("Terrain") or nm4.contains("Mound") else " o"
				break
			row3 += mark
		var legend: String = ", ".join(PackedStringArray(seen.keys())) if seen.size() > 0 else ""
		print("[entrance_capture]   dz=%+5.1f %s   %s" % [dzw, row3, legend])
	print("[entrance_capture]   ('#' = terreno/loma bloqueando, 'o' = madera, '.' = libre)")

	# ── ¿Hay LOMA encima? La trampa que un barrido de solapamiento no ve ───────
	# EntranceMoundBody usa ConcavePolygonShape3D: una superficie SIN volumen. Un
	# cuerpo que la atraviesa queda del otro lado y la física no lo expulsa — se
	# queda trabado sin poder moverse ni saltar, que es exactamente lo que reporta
	# Joan. Y el barrido de solapamiento marca ese punto como LIBRE, porque
	# técnicamente el jugador está en aire: el hueco entre el terreno excavado y la
	# loma que lo cubre. Por eso hay que mirar hacia ARRIBA en todo el ancho, no
	# sólo por el eje.
	print("[entrance_capture]   -- techo de LOMA sobre el corredor (m de despeje) --")
	var hdr: String = "         "
	for dxh2 in range(0, 15, 2):
		hdr += "%6d" % dxh2
	print("[entrance_capture]   dx->%s" % hdr)
	for dzc in [-6.0, -5.0, -4.0, -3.0, 0.0, 3.0, 4.0, 5.0, 6.0]:
		var row4: String = ""
		for dxc in range(0, 15, 2):
			var px5: float = mouth_x + float(dxc)
			var pz5: float = anchor.z + dzc
			var g5: float = maxf(_floor.call("get_terrain_height", px5, pz5), floor_y)
			var q5 := PhysicsRayQueryParameters3D.create(
				Vector3(px5, g5 + 0.10, pz5), Vector3(px5, g5 + 30.0, pz5))
			q5.collide_with_areas = false
			var h5: Dictionary = space.intersect_ray(q5)
			if h5.is_empty():
				row4 += "  cielo"
			else:
				var nm5: String = str((h5["collider"] as Node).name)
				var cl5: float = h5["position"].y - g5
				row4 += "  %s%4.1f" % ["M" if nm5.contains("Mound") else "?", cl5]
		print("[entrance_capture]   dz=%+5.1f%s" % [dzc, row4])
	print("[entrance_capture]   ('M' = LOMA encima = techo bajo el que se queda atrapado)")

	# ── get_terrain_height MIENTE vs la malla real ────────────────────────────
	# El reporte de la sesión de Joan: jugador a +2.27 m SOBRE get_terrain_height,
	# sin tocar nada, sin poder moverse, y después cayendo a y=-9808. Eso no es
	# chocar: es estar DENTRO de la malla. get_terrain_height interpola bilineal
	# dentro de la celda; la malla está triangulada y el triángulo corta la celda por
	# la diagonal. Si la superficie real queda por encima de lo que la función dice,
	# cualquier cosa colocada con esa altura nace enterrada — el jugador incluido.
	# Y es la razón por la que las CUATRO sondas anteriores dieron limpio: apoyaban
	# la cápsula usando la misma función equivocada.
	print("[entrance_capture]   -- get_terrain_height vs raycast contra la malla real --")
	var peor: float = 0.0
	for dzr in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		var row5: String = ""
		for dxr in range(0, 15, 2):
			var pxr: float = mouth_x + float(dxr)
			var pzr: float = anchor.z + dzr
			var bilineal: float = _floor.call("get_terrain_height", pxr, pzr)
			var rq2 := PhysicsRayQueryParameters3D.create(
				Vector3(pxr, bilineal + 40.0, pzr), Vector3(pxr, bilineal - 40.0, pzr))
			rq2.collide_with_areas = false
			var rr: Dictionary = space.intersect_ray(rq2)
			if rr.is_empty():
				row5 += "   n/a"
			else:
				var d: float = rr["position"].y - bilineal
				peor = maxf(peor, d)
				row5 += " %+5.2f" % d
		print("[entrance_capture]   dz=%+5.1f%s" % [dzr, row5])
	print("[entrance_capture]   (positivo = la malla REAL esta MAS ARRIBA de lo que dice la funcion)")
	print("[entrance_capture]   PEOR CASO: la malla esta %.2f m sobre get_terrain_height" % peor)

	# ── Barrido ADENTRO de la sala ────────────────────────────────────────────
	# Todas las sondas anteriores arrancaban en el vano hacia AFUERA. La última
	# captura de Joan lo muestra DENTRO del cuarto, con una cuña de tierra
	# atravesándolo. Nunca miré ahí. Se barre la sala entera.
	print("[entrance_capture]   -- barrido DENTRO de la sala (dx negativo = hacia el portal) --")
	for dzs in [-5.0, -2.5, 0.0, 2.5, 5.0]:
		var rows: String = ""
		var vistos: Dictionary = {}
		for dxs in range(-17, 3):
			var pxs: float = mouth_x + float(dxs)
			var pzs: float = anchor.z + dzs
			var pqs := PhysicsShapeQueryParameters3D.new()
			pqs.shape = cap
			pqs.transform = Transform3D(Basis(), Vector3(pxs, floor_y + 0.90, pzs))
			pqs.collide_with_areas = false
			var hs: Array[Dictionary] = space.intersect_shape(pqs, 8)
			var mk: String = "."
			for hh6 in hs:
				var nm6: String = str((hh6["collider"] as Node).name)
				if nm6 == "EntranceFloor":
					continue
				vistos[nm6] = true
				mk = "#" if (nm6.contains("Terrain") or nm6.contains("Mound")) else "o"
				break
			rows += mk
		print("[entrance_capture]   dz=%+5.1f  %s   %s"
			% [dzs, rows, ", ".join(PackedStringArray(vistos.keys()))])
	print("[entrance_capture]   (dx de -17 a +2 ; '#' = tierra DENTRO de la sala)")

	# ── Inventario CIEGO de colisionadores ────────────────────────────────────
	# Seis hipótesis muertas eligiendo dónde mirar. Esto no elige: lista TODO cuerpo
	# con colisión a menos de 30 m de la boca, con su altura, para que el culpable
	# aparezca solo en vez de tener que sospecharlo primero.
	print("[entrance_capture]   -- TODO cuerpo con colision a <30 m de la boca --")
	var mouth_v := Vector3(mouth_x, floor_y, anchor.z)
	# RECURSIVO. La primera versión miraba sólo hijos directos y listó UN cuerpo, lo
	# cual es imposible con paredes, techo, loma y terreno en la escena: los cuerpos
	# cuelgan de contenedores, no de la raíz del nivel.
	var pend: Array[Node] = [_floor]
	var found: int = 0
	while not pend.is_empty():
		var nd: Node = pend.pop_back()
		for c in nd.get_children():
			pend.append(c)
		if not (nd is CollisionObject3D or nd is CSGShape3D):
			continue
		var np: Vector3 = (nd as Node3D).global_position
		if np.distance_to(mouth_v) > 26.0:
			continue
		found += 1
		print("[entrance_capture]     %-26s %-18s pos=(%+7.2f,%+7.2f,%+7.2f)  dy vs piso=%+.2f"
			% [nd.name, nd.get_class(), np.x, np.y, np.z, np.y - floor_y])
	print("[entrance_capture]     total: %d cuerpos" % found)

	# ── ¿Se puede CRUZAR la puerta? ───────────────────────────────────────────
	# La pregunta que define a una puerta, y que ninguna sonda anterior hizo. Joan:
	# *"si haces una puerta, lo logico es que pueda pasar por ella, sin estamparme o
	# imposibilidad de avanzar"*. Su reporte en vivo puso la barrera en x=-315.52 con
	# la X clavada y la Z libre, o sea un plano vertical — y ese punto cae ENTRE los
	# muestreos gruesos de las sondas de arriba (dx = 0, 2, 4), por eso ninguna lo vio.
	# Paso de 5 cm, cápsula apoyada en el suelo real (raycast, no get_terrain_height).
	print("[entrance_capture]   -- CRUZAR la puerta: capsula cada 5 cm --")
	var bloqueo_en: float = -999.0
	for i2 in range(-40, 81):
		var dxf: float = float(i2) * 0.05
		var pxf: float = mouth_x + dxf
		# Suelo REAL bajo ese punto, por raycast. get_terrain_height no describe la
		# superficie con la que choca el jugador — ese fue el error de origen.
		var qg := PhysicsRayQueryParameters3D.create(
			Vector3(pxf, floor_y + 12.0, anchor.z), Vector3(pxf, floor_y - 12.0, anchor.z))
		qg.collide_with_areas = false
		var gh: Dictionary = space.intersect_ray(qg)
		var gy: float = (gh["position"].y if not gh.is_empty() else floor_y)
		var qf := PhysicsShapeQueryParameters3D.new()
		qf.shape = cap
		qf.transform = Transform3D(Basis(), Vector3(pxf, gy + 0.91, anchor.z))
		qf.collide_with_areas = false
		var hf: Array[Dictionary] = space.intersect_shape(qf, 8)
		var mal: PackedStringArray = []
		for h7 in hf:
			var n7: String = str((h7["collider"] as Node).name)
			if n7 == "EntranceFloor":
				continue
			mal.append(n7)
		if not mal.is_empty():
			if bloqueo_en < -900.0:
				bloqueo_en = dxf
			print("[entrance_capture]     dx=%+6.2f  suelo=%6.2f  BLOQUEA: %s"
				% [dxf, gy, ", ".join(mal)])
	if bloqueo_en < -900.0:
		print("[entrance_capture]     sin solapamiento en -2.0 .. +4.0 m")
	else:
		print("[entrance_capture]     PRIMER BLOQUEO en dx=%+.2f" % bloqueo_en)

	# ── PENDIENTE del suelo, que es lo que de verdad frena ────────────────────
	# "Hay espacio libre" NO es lo mismo que "se puede caminar". Un CharacterBody3D
	# trata como PARED cualquier superficie más empinada que floor_max_angle (45 por
	# defecto) — geométricamente pasás, y el motor te frena igual. Eso se lee como
	# barrera invisible, y ninguna sonda de solapamiento lo puede ver.
	print("[entrance_capture]   -- pendiente del suelo real (paso 10 cm) --")
	var prev_y: float = -9999.0
	var peor_ang: float = 0.0
	var peor_dx: float = 0.0
	for i3 in range(-20, 61):
		var dxs2: float = float(i3) * 0.1
		var pxs2: float = mouth_x + dxs2
		var qg2 := PhysicsRayQueryParameters3D.create(
			# Desde 1 m sobre el piso, NO desde 12: cayendo de arriba el rayo golpea el
			# dintel y la viga del marco antes que el suelo, y sus cantos se leen como
			# escalones de 6 m. Ese artefacto ya produjo una lectura falsa.
			Vector3(pxs2, floor_y + 1.0, anchor.z), Vector3(pxs2, floor_y - 12.0, anchor.z))
		qg2.collide_with_areas = false
		var gh2: Dictionary = space.intersect_ray(qg2)
		if gh2.is_empty():
			prev_y = -9999.0
			continue
		var gy2: float = gh2["position"].y
		if prev_y > -9000.0:
			var ang: float = rad_to_deg(atan2(absf(gy2 - prev_y), 0.1))
			if ang > peor_ang:
				peor_ang = ang
				peor_dx = dxs2
			if ang > 45.0:
				print("[entrance_capture]     dx=%+6.2f  salto=%+.3f m  =%5.1f deg  <-- PARED para el motor"
					% [dxs2, gy2 - prev_y, ang])
		prev_y = gy2
	print("[entrance_capture]     peor pendiente: %.1f deg en dx=%+.2f  (limite del motor: 45)"
		% [peor_ang, peor_dx])

	await _shot("00_inside_to_exit",
		Vector3(anchor.x - hall_len * 0.5 + 3.0, floor_y + EYE, anchor.z),
		Vector3(mouth_x + 8.0, floor_y + 2.0, anchor.z))
	await _shot("01_inside_to_portal",
		Vector3(mouth_x - 2.0, floor_y + EYE, anchor.z),
		Vector3(anchor.x - hall_len * 0.5, floor_y + 1.9, anchor.z))
	# Eye height from the ground UNDER THE CAMERA, not from the anchor: the anchor is
	# excavated now, so deriving it there put the camera below the mound, shooting the
	# underside of the mesh.
	var ramp_x: float = mouth_x + run * 0.7
	await _shot("02_outside_ramp",
		Vector3(ramp_x, _floor.call("get_terrain_height", ramp_x, anchor.z) + EYE, anchor.z),
		Vector3(mouth_x, floor_y + 2.2, anchor.z))
	await _shot("03_high_oblique",
		Vector3(mouth_x + run * 1.1, surface + 26.0, anchor.z + 30.0),
		Vector3(anchor.x, surface - 3.0, anchor.z))

	print("[entrance_capture] DONE -> %s" % OUT_DIR)
	get_tree().quit(0)


func _shot(name: String, eye: Vector3, look: Vector3) -> void:
	_cam.global_position = eye
	_cam.look_at(look, Vector3.UP)
	for _i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := _sv.get_texture().get_image()
	if img == null:
		print("[entrance_capture] [FATAL] %s: get_image() null" % name)
		return
	img.save_png(OUT_DIR + name + ".png")
	print("[entrance_capture] shot %s" % name)
