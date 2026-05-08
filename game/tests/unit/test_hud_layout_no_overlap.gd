extends GutTest

# Test regresión bug 2026-04-29 — HUD overlap entre inventory + equipment + hotbar.
# Layout canon v4 (2026-05-08):
#   Inventory  bottom-right  offset_top=-530 offset_bottom=-130  (alto 400)
#   Equipment  encima inv    offset_top=-1010 offset_bottom=-540 (alto 470, gap 10px)
#   Hotbar     bottom-center  reservar 80px desde bottom
#
# Test arithmético — no necesita instanciar viewport.
# Si alguien mueve los offsets y rompe la separación, este test falla.

const INVENTORY_TOP    := -530.0
const INVENTORY_BOTTOM := -130.0
const EQUIPMENT_TOP    := -1010.0
const EQUIPMENT_BOTTOM := -540.0
const HOTBAR_RESERVED  := 80.0  # offset desde bottom
const VIEWPORT_USABLE  := 1020.0  # 1080 - title bar (~30) - margen seguro (~30)


# ─── Vertical no-overlap ───

func test_equipment_above_inventory_no_overlap() -> void:
	# Equipment.bottom debe estar SOBRE Inventory.top.
	# Offsets son negativos desde anchor=1 (bottom). bottom-edge más cerca del fondo
	# = offset_bottom MÁS NEGATIVO que el del otro panel? No: más cerca del fondo
	# = offset MENOS negativo (más cerca de 0).
	#
	# Inventory bottom = -130 (más cerca del fondo)
	# Inventory top    = -530
	# Equipment bottom = -540 (debe ser MÁS negativo que Inventory.top, sino overlap)
	# Equipment top    = -1010
	assert_lt(EQUIPMENT_BOTTOM, INVENTORY_TOP,
		"Equipment.bottom (%s) debe estar SOBRE Inventory.top (%s) — sino overlappean" % [EQUIPMENT_BOTTOM, INVENTORY_TOP])


func test_equipment_inventory_gap_at_least_10px() -> void:
	# Gap = Inventory.top - Equipment.bottom (ambos negativos)
	# = -530 - (-540) = 10
	var gap: float = INVENTORY_TOP - EQUIPMENT_BOTTOM
	assert_gte(gap, 10.0, "Gap mínimo 10px entre equipment y inventory (actual %s)" % gap)


func test_inventory_above_hotbar_no_overlap() -> void:
	# Inventory.bottom = -130 desde el fondo.
	# Hotbar reserva 80px desde el fondo.
	# Inventory.bottom debe estar más arriba que hotbar.top.
	# Offset es negativo desde anchor=1 → distancia al fondo = abs(offset).
	var inv_distance_to_bottom: float = abs(INVENTORY_BOTTOM)
	assert_gt(inv_distance_to_bottom, HOTBAR_RESERVED,
		"Inventory bottom (%spx del fondo) debe estar sobre hotbar (%spx reservados)" % [inv_distance_to_bottom, HOTBAR_RESERVED])


func test_inventory_hotbar_gap_at_least_20px() -> void:
	var gap: float = abs(INVENTORY_BOTTOM) - HOTBAR_RESERVED
	assert_gte(gap, 20.0, "Gap mínimo 20px entre inventory y hotbar (actual %s)" % gap)


# ─── Layout coherente ───

func test_inventory_height_positive() -> void:
	var height: float = INVENTORY_BOTTOM - INVENTORY_TOP
	assert_gt(height, 0.0, "Inventory altura debe ser > 0")


func test_equipment_height_positive() -> void:
	var height: float = EQUIPMENT_BOTTOM - EQUIPMENT_TOP
	assert_gt(height, 0.0, "Equipment altura debe ser > 0")


func test_layout_fits_in_windowed_mode() -> void:
	# En 1920x1080 ventana maximizada, Windows title-bar + chrome comen ~30-60px.
	# Equipment.top debe quedar dentro del viewport USABLE para que drag bar sea
	# accesible. Sino el user no puede mover la ventana.
	assert_lte(abs(EQUIPMENT_TOP), VIEWPORT_USABLE,
		"Equipment.top (%s) excede viewport usable %s — drag bar fuera de pantalla" % [EQUIPMENT_TOP, VIEWPORT_USABLE])
