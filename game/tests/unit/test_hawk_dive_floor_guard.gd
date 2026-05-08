extends GutTest

# Test regresión bug 2026-04-29 — Halcón se hundía en el suelo durante DIVING.
# Root cause: _apply_gravity corre ANTES de _move_toward_target. El guard de altura
# en _apply_gravity DIVING branch quedaba override por _move_toward_target después
# (velocity.y = direction.y * dive_speed). Fix: guard movido ADENTRO del DIVING
# branch en _move_toward_target, después del set de velocity.

const HAWK_SCENE := preload("res://scenes/enemy/hawk.tscn")


class MockTarget extends Node3D:
	func _init() -> void:
		add_to_group("player")
	func take_damage(_amount: float, _dir: Vector3 = Vector3.ZERO, _kb: float = 0.0, _as: int = 0, _a = null) -> void:
		pass


func _make_hawk_with_target(hawk_y: float, target_pos: Vector3) -> Dictionary:
	var hawk = HAWK_SCENE.instantiate()
	add_child_autofree(hawk)
	var t := MockTarget.new()
	add_child_autofree(t)
	t.global_position = target_pos
	hawk.target = t
	hawk.global_position = Vector3(0, hawk_y, 0)
	# Bypass perform_attack para que test sea sync
	hawk.can_attack = false
	return {"hawk": hawk, "target": t}


# ─── Guard activo cuando y <= 1.5 ───

func test_dive_guard_clamps_velocity_y_at_low_altitude() -> void:
	var setup = _make_hawk_with_target(1.0, Vector3(5, 0, 0))
	var hawk = setup["hawk"]
	hawk.state = hawk.HawkState.DIVING
	hawk.velocity = Vector3.ZERO

	hawk._move_toward_target(0.016)

	# Guard: y<=1.5 → velocity.y >= 0 (no sigue bajando)
	assert_gte(hawk.velocity.y, 0.0,
		"Con y=1.0 (≤1.5) en DIVING, velocity.y NO debe ser negativa — sino atraviesa suelo")


func test_dive_guard_clamps_at_threshold_exact() -> void:
	var setup = _make_hawk_with_target(1.5, Vector3(8, 0, 0))
	var hawk = setup["hawk"]
	hawk.state = hawk.HawkState.DIVING
	hawk.velocity = Vector3.ZERO

	hawk._move_toward_target(0.016)

	assert_gte(hawk.velocity.y, 0.0,
		"En el threshold exacto y=1.5, guard debe activarse (<=, no <)")


# ─── Guard NO activo cuando y > 1.5 (dive normal) ───

func test_dive_normal_descent_above_guard_threshold() -> void:
	var setup = _make_hawk_with_target(8.0, Vector3(0, 0, 0))
	var hawk = setup["hawk"]
	hawk.state = hawk.HawkState.DIVING
	hawk.velocity = Vector3.ZERO

	hawk._move_toward_target(0.016)

	# Y alto + target en y=0 → debe descender (velocity.y < 0)
	assert_lt(hawk.velocity.y, 0.0,
		"En altura alta, dive debe descender (velocity.y < 0). Si guard se activa siempre, halcón nunca llega")


# ─── State transitions ───

func test_dive_to_retreating_on_ground_contact() -> void:
	var setup = _make_hawk_with_target(0.4, Vector3(0, 0, 0))
	var hawk = setup["hawk"]
	hawk.state = hawk.HawkState.DIVING
	hawk.velocity = Vector3.ZERO

	hawk._move_toward_target(0.016)

	# y<=0.5 → transición a RETREATING + impulso hacia arriba
	assert_eq(hawk.state, hawk.HawkState.RETREATING,
		"y<=0.5 debe disparar RETREATING — sino halcón se queda pegado al suelo")
	assert_gt(hawk.velocity.y, 0.0,
		"En transición a RETREATING, velocity.y > 0 (impulso de subida)")
