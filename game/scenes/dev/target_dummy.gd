extends CharacterBody3D
## target_dummy -- a stand-in "player" for mob_lab's G mode.
##
## Exists so enemy AI has something real to aggro: it is in the "player"
## group, it has a position and a body, and it absorbs the calls an enemy
## makes on its victim without dying or fighting back. Nothing else.

var health := 99999.0


# Signature copied from the PLAYER, argument order included: BaseEnemy
# calls take_damage(amount, "", self), and a mismatched typed parameter
# aborts the CALLER mid-frame with a type error -- which pinned the hawk
# in DIVING beside the post (2026-08-25).
func take_damage(amount: float, _kind: String = "", _attacker: Node = null) -> void:
	# Absorb and report; the dummy never dies, so the loop can be watched.
	print("[target_dummy] recibio %.1f de dano" % amount)


func apply_knockback(_force: Vector3) -> void:
	pass
