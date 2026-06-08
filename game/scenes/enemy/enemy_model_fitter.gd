class_name EnemyModelFitter
## Single source of truth for visual<->hitbox consistency on gltf-backed enemies.
##
## Problem this solves: enemies were authored with a placeholder primitive whose
## CollisionShape3D matched that primitive. When the visual was later swapped to a
## real gltf model (often at a different scale), the collision shape was NOT
## updated -> the player hits air where the model has no hitbox, and models from
## different packs end up wildly different sizes.
##
## CRITICAL GOTCHA (measured in Godot 4.6, see scenes/dev/measure_aabb.gd):
## for SKINNED gltf models, BOTH Mesh.get_aabb() AND MeshInstance3D.get_aabb()
## return the BIND-POSE (T-pose) bounds, and animation does NOT change them. The
## T-pose has the arms spread, so the HORIZONTAL (X/Z) extents are garbage for a
## hitbox (orc bind width = 4.68m, ninja = 4.65m — for ~0.6m-wide characters).
## Only the VERTICAL (Y) extent is reliable (T-pose height ~= standing height).
##
## Therefore fit() derives the HEIGHT from the measured Y, but the horizontal
## GIRTH from an explicit ratio of target_height — never from measured X/Z.
##
## All methods are static. Call fit() in _on_enemy_ready() AFTER add_child(model).

## Fit `model` to `target_height` (meters) and resize `body`'s collision shape.
##
## body              : the CharacterBody3D (or any CollisionObject3D) that owns the shape.
## model             : the gltf model root (already instantiated).
## target_height     : desired world-space height of the model, in meters.
## shape_kind        : "capsule" (default, humanoids/beasts) or "box" (blocky golems).
## girth_ratio       : horizontal half-extent as a fraction of target_height
##                     (e.g. 0.18 -> radius ~0.33m for a 1.85m humanoid).
## model_width_mult  : optional VISUAL-only horizontal stretch on the model (does
##                     NOT affect the hitbox; use for a stockier silhouette).
## collision_node    : name of the CollisionShape3D child on `body`.
static func fit(
		body: CollisionObject3D,
		model: Node3D,
		target_height: float,
		shape_kind: String = "capsule",
		girth_ratio: float = 0.18,
		model_width_mult: float = 1.0,
		collision_node: String = "CollisionShape3D"
) -> void:
	if model == null or body == null:
		return

	# Measure at unit scale. Only the Y (height) extent is trustworthy for skinned
	# models — see the class header. Horizontal extents are intentionally ignored.
	model.scale = Vector3.ONE
	var aabb := _local_aabb(model)
	if aabb.size.y <= 0.0001:
		push_warning("EnemyModelFitter: '%s' has zero-height AABB, skipping fit." % model.name)
		return

	# Uniform height scale; optional visual-only width stretch for bulk.
	var s := target_height / aabb.size.y
	model.scale = Vector3(s * model_width_mult, s, s * model_width_mult)

	var col := body.get_node_or_null(collision_node) as CollisionShape3D
	if col == null:
		push_warning("EnemyModelFitter: '%s' not found on '%s'." % [collision_node, body.name])
		return

	# Horizontal half-extent from an EXPLICIT ratio, clamped sane vs height.
	var half := minf(target_height * girth_ratio, target_height * 0.45)

	match shape_kind:
		"box":
			var bs := BoxShape3D.new()
			bs.size = Vector3(half * 2.0, target_height, half * 2.0)
			col.shape = bs
		_:
			var cs := CapsuleShape3D.new()
			cs.radius = half
			# Capsule height includes both caps; never below 2*radius (won't trigger
			# given the 0.45 clamp, but kept for safety).
			cs.height = maxf(target_height, half * 2.0)
			col.shape = cs

	# Center the shape vertically on the scaled visual (feet at the scaled AABB
	# bottom). Shape total height == target_height, so center = bottom + h/2.
	var bottom_y := aabb.position.y * s
	var t := col.transform
	t.origin.y = bottom_y + target_height * 0.5
	col.transform = t


## Local-space AABB of every MeshInstance3D under `model`, WITHOUT relying on the
## scene tree. gltf models are skinned: mesh nodes live under a Skeleton3D, not as
## direct children -> recurse the whole subtree. global_transform is invalid until
## the node is inside the tree, so we accumulate LOCAL transforms by hand.
## NOTE: only the returned AABB's Y extent is used by fit() (see class header).
static func _local_aabb(model: Node3D) -> AABB:
	var combined := AABB()
	var has_any := false
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		if m == null:
			continue
		var mesh_aabb := m.get_aabb()
		var xf := _relative_transform(model, mi)
		var world_aabb := xf * mesh_aabb
		if not has_any:
			combined = world_aabb
			has_any = true
		else:
			combined = combined.merge(world_aabb)
	return combined


## Transform of `node` expressed in `ancestor`'s local space, by multiplying the
## local transforms up the chain (excludes `ancestor`'s own transform). Safe to
## call before the nodes are added to the scene tree.
static func _relative_transform(ancestor: Node3D, node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != ancestor:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
