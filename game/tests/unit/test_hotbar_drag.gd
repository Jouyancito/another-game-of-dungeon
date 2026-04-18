extends GutTest

# Drag&drop hotbar: swap entre slots + drop skill tree → PlayerSkills.set_slot.
# Canon warrior.md §3 slots 0..3 son los defaults del Warrior.

const HotbarSlotScript = preload("res://scenes/hud/hotbar_slot.gd")

var skills: PlayerSkills
var _owner_stub: Node


func before_each() -> void:
	# No necesitamos BasePlayer — set_slot/swap_slots son independientes del player.
	_owner_stub = Node.new()
	add_child_autofree(_owner_stub)
	skills = PlayerSkills.new()
	skills.setup(_owner_stub, null)
	_owner_stub.add_child(skills)


func _make_skill(id: StringName) -> SkillResource:
	var s := SkillResource.new()
	s.id = id
	return s


# ─── PlayerSkills swap ───────────────────────────────────────────────────────

func test_swap_slots_exchanges_two_slots() -> void:
	var s0 := _make_skill(&"warrior_punch")
	var s3 := _make_skill(&"warrior_perfect_block")
	skills.set_slot(0, s0)
	skills.set_slot(3, s3)
	skills.swap_slots(0, 3)
	assert_eq(skills.hotbar[0], s3, "Slot 0 ahora tiene la skill que estaba en 3")
	assert_eq(skills.hotbar[3], s0, "Slot 3 ahora tiene la skill que estaba en 0")


func test_swap_slots_ignores_same_index() -> void:
	var s0 := _make_skill(&"warrior_punch")
	skills.set_slot(0, s0)
	skills.swap_slots(0, 0)
	assert_eq(skills.hotbar[0], s0, "Swap mismo slot no rompe nada")


func test_swap_slots_ignores_out_of_range() -> void:
	var s0 := _make_skill(&"warrior_punch")
	skills.set_slot(0, s0)
	skills.swap_slots(0, 99)  # 99 fuera
	assert_eq(skills.hotbar[0], s0, "Out of range no modifica layout")


func test_swap_slots_emits_hotbar_changed() -> void:
	var s0 := _make_skill(&"warrior_punch")
	var s1 := _make_skill(&"warrior_charge")
	skills.set_slot(0, s0)
	skills.set_slot(1, s1)
	watch_signals(skills)
	skills.swap_slots(0, 1)
	assert_signal_emit_count(skills, "hotbar_changed", 1)


# ─── HotbarSlot drag&drop API ────────────────────────────────────────────────

func _make_slot(idx: int) -> HotbarSlot:
	var slot := HotbarSlot.new()
	slot.slot_index = idx
	add_child_autofree(slot)
	return slot


func test_get_drag_data_returns_payload_when_skill_present() -> void:
	var slot: HotbarSlot = _make_slot(2)
	var s := _make_skill(&"warrior_war_cry")
	slot.set_skill(s)
	var data = slot._get_drag_data(Vector2.ZERO)
	assert_eq(typeof(data), TYPE_DICTIONARY, "drag_data es Dictionary")
	assert_eq(data.get("type", ""), "hotbar_skill", "type correcto")
	assert_eq(data.get("from_slot", -1), 2, "from_slot matchea")
	assert_eq(data.get("skill", null), s, "skill referenciada")


func test_get_drag_data_returns_null_when_empty() -> void:
	var slot: HotbarSlot = _make_slot(0)
	assert_null(slot._get_drag_data(Vector2.ZERO), "Slot vacío no emite drag_data")


func test_can_drop_accepts_hotbar_skill_and_skill_tree() -> void:
	var slot: HotbarSlot = _make_slot(0)
	assert_true(slot._can_drop_data(Vector2.ZERO, {"type": "hotbar_skill"}))
	assert_true(slot._can_drop_data(Vector2.ZERO, {"type": "skill_tree"}))
	assert_false(slot._can_drop_data(Vector2.ZERO, {"type": "inventory_item"}))
	assert_false(slot._can_drop_data(Vector2.ZERO, "not a dict"))


func test_drop_hotbar_skill_emits_slot_swap() -> void:
	var slot: HotbarSlot = _make_slot(5)
	var captured := []
	slot.slot_swap_requested.connect(func(f, t): captured.append([f, t]))
	slot._drop_data(Vector2.ZERO, {
		"type": "hotbar_skill",
		"from_slot": 1,
		"skill": _make_skill(&"warrior_charge"),
	})
	assert_eq(captured.size(), 1, "slot_swap_requested emitido 1 vez")
	assert_eq(captured[0], [1, 5], "Params del swap correctos (from=1 → to=5)")


func test_drop_skill_tree_emits_skill_dropped() -> void:
	var slot: HotbarSlot = _make_slot(3)
	var s := _make_skill(&"warrior_perfect_block")
	var captured := []
	slot.skill_dropped.connect(func(idx, sk): captured.append([idx, sk]))
	slot._drop_data(Vector2.ZERO, {"type": "skill_tree", "skill": s})
	assert_eq(captured.size(), 1)
	assert_eq(captured[0][0], 3, "slot_index correcto")
	assert_eq(captured[0][1], s, "skill ref correcta")


func test_drop_same_slot_does_not_emit() -> void:
	var slot: HotbarSlot = _make_slot(2)
	watch_signals(slot)
	slot._drop_data(Vector2.ZERO, {"type": "hotbar_skill", "from_slot": 2, "skill": _make_skill(&"x")})
	assert_signal_not_emitted(slot, "slot_swap_requested", "Drop en propio slot no intercambia")


# ─── Layout serialization (SaveManager v3 persist) ───────────────────────────

func test_get_hotbar_layout_returns_ids_per_slot() -> void:
	skills.set_slot(0, _make_skill(&"warrior_punch"))
	skills.set_slot(2, _make_skill(&"warrior_war_cry"))
	var layout: PackedStringArray = skills.get_hotbar_layout()
	assert_eq(layout.size(), 8, "Layout fijo 8 entradas")
	assert_eq(layout[0], "warrior_punch")
	assert_eq(layout[1], "", "Slot vacío = string vacío")
	assert_eq(layout[2], "warrior_war_cry")
