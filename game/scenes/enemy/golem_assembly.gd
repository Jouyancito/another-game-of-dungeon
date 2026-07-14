class_name GolemAssembly
extends BaseEnemy

## Golem de Piedra — JOINT-POSITIONED SKELETON ARCHITECTURE (2026-06-14 RE-ARCH v3)
##
## APPROACH HISTORY:
##   v1 — Per-limb Node3D groups: pivots sat at MODEL ORIGIN → rotated chunks
##        orbited the origin = explosion / scattering.
##   v2 — Single _body_root mass: cohesive but DEAD ("un png sólido moviéndose").
##        One transform = zero articulation.
##   v3 (THIS) — Joint-positioned skeleton: each bone Node3D sits AT the
##        anatomical joint it rotates around. Chunks are rigid children of their
##        bone. Rotating shoulder_L swings arm chunks around the shoulder joint,
##        NOT the body center. This gives BOTH cohesion (chunks follow their bone)
##        AND life (each bone articulates independently).
##
## SKELETON HIERARCHY (positions in _model-local space, set at runtime):
##
##   _skel_root  (pelvis — at ~hip height, center)
##   ├── bone_spine  (mid-torso joint — where spine meets pelvis)
##   │   ├── bone_neck   (base of neck)
##   │   │   └── bone_head   (atlas joint — top of neck)
##   │   ├── bone_shoulder_L  (left shoulder socket)
##   │   │   └── bone_upperarm_L  (elbow joint)
##   │   │       └── bone_forearm_L  (wrist joint)
##   │   │           └── bone_fist_L   (knuckle — terminal)
##   │   └── bone_shoulder_R  (right shoulder socket)
##   │       └── bone_upperarm_R
##   │           └── bone_forearm_R
##   │               └── bone_fist_R
##   ├── bone_hip_L   (left hip socket)
##   │   └── bone_thigh_L  (knee joint)
##   │       └── bone_foot_L  (ankle — terminal)
##   └── bone_hip_R
##       └── bone_thigh_R
##           └── bone_foot_R
##
## CHUNK → BONE MAPPING:
##   _skel_root:    chunk_pelvis, chunk_rubble
##   bone_spine:    chunk_chest, chunk_back_hump
##   bone_neck:     chunk_neck
##   bone_head:     chunk_head, chunk_face_brow, chunk_face_jaw, chunk_eye
##   bone_shoulder_L: chunk_shoulder_L, chunk_shoulder_L_knob
##   bone_upperarm_L: chunk_arm_L_upper
##   bone_forearm_L:  chunk_arm_L_forearm
##   bone_fist_L:     chunk_arm_L_fist
##   bone_shoulder_R: chunk_shoulder_R
##   bone_upperarm_R: chunk_arm_R_upper
##   bone_forearm_R:  chunk_arm_R_forearm
##   bone_fist_R:     chunk_arm_R_fist
##   bone_hip_L:      chunk_leg_L_thigh
##   bone_thigh_L:    chunk_leg_L_foot
##   bone_hip_R:      chunk_leg_R_thigh
##   bone_thigh_R:    chunk_leg_R_foot
##
## AWAKEN / DEATH: still move individual chunk nodes (the two moments where
## separation is correct). During awaken, bones are at identity; chunks animate
## from pile→stand as before. Death uses RigidBody3D impulses.
##
## Tree-gated moveset:
##   WITH tree:  trunk_rip → trunk_sweep x3
##   WITHOUT:    stomp, rock_throw
##   BOTH:       idle, lumber, attack_basic, attack_charged, root_snare,
##               hit_react, death

const EYE_COLOR   := Color(0.373, 0.847, 1.0)   # #5FD8FF cyan jewel (canon)
const EYE_ENERGY  := 1.6

const TOON_SHADER: Shader    = preload("res://scenes/levels/dp_toon_grounded.gdshader")
const TOON_SHADER_2S: Shader = preload("res://scenes/levels/dp_toon_grounded_2sided.gdshader")
const OUTLINE_SHADER: Shader = preload("res://assets/art/shaders/toon_outline.gdshader")

const CHUNKS_GLB := "res://assets/art/piso1_pradera/enemies/big/golem_dp_chunks_01.glb"

const BACK_TREE_GLBS := [
	"res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_01.gltf",
	"res://assets/art/piso1_pradera/vegetation/maple/env_tree_maple_02.gltf",
	"res://assets/art/piso1_pradera/vegetation/birch/env_tree_birch_02.gltf",
]

const FLOWER_GLBS := [
	"res://assets/art/piso1_pradera/enemies/big/golem_flower_pink_01.glb",
	"res://assets/art/piso1_pradera/enemies/big/golem_flower_white_01.glb",
	"res://assets/art/piso1_pradera/enemies/big/golem_flower_yellow_01.glb",
]

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var is_dormant     := true
var awaken_tween: Tween
var attack_index   := 0
var stomp_range    := 3.0
var throw_range    := 10.0

var _eye_mats: Array[StandardMaterial3D] = []

## Per-chunk data for the assembly animation
class ChunkData:
	var node: Node3D
	var stand_pos: Vector3    # position in BONE-local space (assembled)
	var stand_rot: Vector3    # rotation in BONE-local space (assembled)
	var pile_pos: Vector3     # dormant scatter position in _skel_root-local space
	var pile_rot: Vector3     # dormant scatter rotation
	var pile_pos_model: Vector3  # pile pos in _model-local space (for dormant reparent)
	var pile_rot_model: Vector3
	var rb_node: RigidBody3D  # pre-frozen physics body (used on death)
	var bone: Node3D          # the bone this chunk is parented to at runtime

	# SOUL spring — per-chunk secondary spring state.
	# The chunk's actual transform SPRING-FOLLOWS its bone's world transform
	# instead of being rigidly parented. This gives magical floating-rock lag.
	var soul_pos: Vector3        # current spring position (world-space)
	var soul_rot: Quaternion     # current spring rotation (world-space)
	var soul_vel_pos: Vector3    # position spring velocity (world-space)
	var soul_vel_rot: Vector3    # rotation spring angular velocity (world-space, axis*angle/s)
	var soul_omega: float        # spring frequency (rad/s) — varies per chunk
	var soul_zeta: float         # damping ratio — varies per chunk

var _chunks: Array[ChunkData] = []
var _model: Node3D            # root of the instantiated GLB

# ---------------------------------------------------------------------------
# SKELETON — joint-positioned Node3D bones
# Each bone is positioned AT the anatomical joint it rotates around.
# Rotating a bone swings its chunks around that joint, not the body center.
# ---------------------------------------------------------------------------
var _skel_root: Node3D      # pelvis — the root of the skeleton (replaces _body_root)

# Spine chain (children of _skel_root)
var bone_spine: Node3D
var bone_neck: Node3D
var bone_head: Node3D

# Left arm chain (spine → shoulder → upperarm → forearm → fist)
var bone_shoulder_L: Node3D
var bone_upperarm_L: Node3D
var bone_forearm_L: Node3D
var bone_fist_L: Node3D

# Right arm chain
var bone_shoulder_R: Node3D
var bone_upperarm_R: Node3D
var bone_forearm_R: Node3D
var bone_fist_R: Node3D

# Left leg chain (pelvis → hip → thigh → foot)
var bone_hip_L: Node3D
var bone_thigh_L: Node3D
var bone_foot_L: Node3D

# Right leg chain
var bone_hip_R: Node3D
var bone_thigh_R: Node3D
var bone_foot_R: Node3D

# Convenience reference — kept for back-tree attachment
var _back_chunk: Node3D       # "chunk_back_hump" live node
var _back_tree_root: Node3D
var _trunk_weapon: Node3D
var _has_tree := true

# Animation state
var _anim_active := false

# Spring-damper: secondary sway applied to _skel_root rotation after big moves.
var _spring_vel := Vector3.ZERO
var _spring_target := Vector3.ZERO
const SPRING_OMEGA := 5.0
const SPRING_ZETA  := 0.72

# SOUL LAYER — per-chunk spring-follow state.
# When active, each chunk's actual transform LAGS BEHIND its bone's global transform
# with a critically-damped-ish spring. The rocks float and wobble magically.
#
# Per-chunk omega/zeta are seeded from the chunk name for natural variation (no lockstep).
# Base values — outer/lighter chunks (fists, head) lag MORE (lower omega).
# Core chunks (pelvis, chest) are tighter (heavier, less float).
const SOUL_OMEGA_BASE  := 7.5    # rad/s — position spring frequency (mid-range float)
const SOUL_OMEGA_VAR   := 0.15   # ±15% variation per chunk (seeded)
const SOUL_ZETA_BASE   := 0.68   # damping ratio — slightly under 1 = small alive overshoot
const SOUL_ZETA_VAR    := 0.06   # ±variation per chunk

# Omega multipliers by chunk role (relative to base — <1.0 = more float, >1.0 = tighter)
const SOUL_CHUNK_MULTIPLIERS: Dictionary = {
	"pelvis": 1.25,   "chest": 1.20,   "back_hump": 1.15,
	"hip":    1.10,   "thigh": 1.05,   "foot": 1.00,
	"shoulder": 0.95, "upperarm": 0.90, "forearm": 0.85,
	"fist":   0.78,   "head": 0.80,    "neck": 0.88,
	"face":   0.72,   "eye":  0.68,    "rubble": 0.90,
}

var _soul_active := false   # false during awaken/death sequences

# ---------------------------------------------------------------------------
# DORMANT PILE RULES
# Offsets applied to stand_pos/stand_rot to get pile pose.
# These are in _model-local space (the pre-skeleton collect phase uses them).
# ---------------------------------------------------------------------------
const PILE_RULES: Dictionary = {
	"chunk_pelvis":          [Vector3( 0.00,  0.05, -0.70), Vector3( 15.0,   5.0,  -8.0)],
	"chunk_chest":           [Vector3( 0.06,  0.12, -1.18), Vector3( 25.0,   8.0, -12.0)],
	"chunk_back_hump":       [Vector3(-0.08, -0.08, -1.54), Vector3( 18.0, -12.0,  10.0)],
	"chunk_leg_L_thigh":     [Vector3(-0.10,  0.06, -0.42), Vector3(  5.0,  -5.0,  10.0)],
	"chunk_leg_L_foot":      [Vector3(-0.14,  0.10, -0.05), Vector3(  2.0,  -8.0,  15.0)],
	"chunk_leg_R_thigh":     [Vector3( 0.08,  0.04, -0.42), Vector3(  4.0,   5.0, -10.0)],
	"chunk_leg_R_foot":      [Vector3( 0.12,  0.08, -0.05), Vector3(  2.0,   8.0, -14.0)],
	"chunk_shoulder_L":      [Vector3(-0.20,  0.12, -1.62), Vector3( 18.0,   0.0,  20.0)],
	"chunk_shoulder_L_knob": [Vector3(-0.28,  0.08, -1.86), Vector3( 22.0,  -5.0,  25.0)],
	"chunk_shoulder_R":      [Vector3( 0.18,  0.10, -1.54), Vector3( 12.0,   0.0, -18.0)],
	"chunk_arm_L_upper":     [Vector3(-0.40,  0.20, -1.22), Vector3( 20.0,  -8.0,  28.0)],
	"chunk_arm_L_forearm":   [Vector3(-0.55,  0.28, -0.44), Vector3( 16.0, -10.0,  32.0)],
	"chunk_arm_L_fist":      [Vector3(-0.68,  0.34, -0.12), Vector3( 10.0, -15.0,  38.0)],
	"chunk_arm_R_upper":     [Vector3( 0.36,  0.18, -1.22), Vector3( 16.0,   8.0, -25.0)],
	"chunk_arm_R_forearm":   [Vector3( 0.50,  0.26, -0.44), Vector3( 12.0,  10.0, -30.0)],
	"chunk_arm_R_fist":      [Vector3( 0.62,  0.32, -0.12), Vector3(  8.0,  15.0, -35.0)],
	"chunk_neck":            [Vector3( 0.02,  0.18, -1.64), Vector3( 30.0,   2.0,   0.0)],
	"chunk_head":            [Vector3( 0.04,  0.28, -1.84), Vector3( 35.0,  -5.0,   8.0)],
	"chunk_face_brow":       [Vector3( 0.03,  0.32, -1.90), Vector3( 38.0,   0.0,   5.0)],
	"chunk_face_jaw":        [Vector3( 0.02,  0.30, -1.82), Vector3( 28.0,   3.0,  -4.0)],
	"chunk_eye":             [Vector3( 0.04,  0.30, -1.88), Vector3( 40.0,   0.0,   2.0)],
	"chunk_rubble":          [Vector3( 0.0,   0.04, -0.04), Vector3(  0.0,   0.0,   0.0)],
}

## Awaken stagger delays (seconds from awaken start).
const PILE_TO_STAND_DELAYS: Dictionary = {
	"chunk_rubble":       0.00,
	"chunk_leg_L_foot":   0.10,
	"chunk_leg_R_foot":   0.13,
	"chunk_leg_L_thigh":  0.18,
	"chunk_leg_R_thigh":  0.22,
	"chunk_pelvis":       0.32,
	"chunk_chest":        0.44,
	"chunk_back_hump":    0.50,
	"chunk_shoulder_L":   0.56,
	"chunk_shoulder_R":   0.56,
	"chunk_shoulder_L_knob": 0.60,
	"chunk_arm_L_fist":   0.40,
	"chunk_arm_R_fist":   0.40,
	"chunk_arm_L_forearm":0.48,
	"chunk_arm_R_forearm":0.48,
	"chunk_arm_L_upper":  0.58,
	"chunk_arm_R_upper":  0.58,
	"chunk_neck":         0.64,
	"chunk_head":         0.70,
	"chunk_face":         0.72,
	"chunk_eye":          0.74,
}

# ---------------------------------------------------------------------------
# BONE JOINT POSITIONS (in _model-local space, y-up, authored from GLB anatomy)
# These are the pivot points — where each bone Node3D is placed.
# They represent the anatomical JOINT CENTER, not the chunk center.
#
# Golem anatomy reference (from chunk stand positions in the GLB):
#   Feet at y≈0.0, pelvis/hips at y≈0.75, chest at y≈1.35, shoulders at y≈1.80,
#   elbows at y≈1.40, wrists at y≈0.95, fists at y≈0.55,
#   neck at y≈2.10, head center at y≈2.35
# ---------------------------------------------------------------------------
const BONE_JOINTS: Dictionary = {
	# Spine chain — all on center X/Z
	"skel_root":     Vector3( 0.00, 0.75,  0.00),  # hip center (pelvis pivot)
	"bone_spine":    Vector3( 0.00, 1.30,  0.00),  # lumbar-thoracic joint
	"bone_neck":     Vector3( 0.00, 2.00,  0.00),  # cervical base (where neck meets chest)
	"bone_head":     Vector3( 0.00, 2.20,  0.00),  # atlas — top of neck

	# Left arm (negative X = golem's left side)
	"bone_shoulder_L": Vector3(-0.55, 1.80,  0.00),  # left shoulder socket
	"bone_upperarm_L": Vector3(-0.72, 1.45,  0.00),  # left elbow
	"bone_forearm_L":  Vector3(-0.80, 1.05,  0.00),  # left wrist
	"bone_fist_L":     Vector3(-0.80, 0.65,  0.00),  # left knuckle (terminal)

	# Right arm (positive X = golem's right side)
	"bone_shoulder_R": Vector3( 0.55, 1.80,  0.00),
	"bone_upperarm_R": Vector3( 0.72, 1.45,  0.00),
	"bone_forearm_R":  Vector3( 0.80, 1.05,  0.00),
	"bone_fist_R":     Vector3( 0.80, 0.65,  0.00),

	# Left leg (negative X = golem's left)
	"bone_hip_L":   Vector3(-0.30, 0.75,  0.00),  # left hip socket
	"bone_thigh_L": Vector3(-0.30, 0.38,  0.00),  # left knee
	"bone_foot_L":  Vector3(-0.30, 0.05,  0.00),  # left ankle (terminal)

	# Right leg
	"bone_hip_R":   Vector3( 0.30, 0.75,  0.00),
	"bone_thigh_R": Vector3( 0.30, 0.38,  0.00),
	"bone_foot_R":  Vector3( 0.30, 0.05,  0.00),
}


func _on_enemy_ready() -> void:
	enemy_type = "golem"
	personality = AggroPersonality.JUGGERNAUT_SLOW
	default_color = Color(0.5, 0.5, 0.5)
	mass = 3.0
	knockback_resistance = 0.7
	mesh.visible = false
	var old_head: Node = get_node_or_null("Head")
	if old_head:
		old_head.visible = false

	var packed: PackedScene = load(CHUNKS_GLB) if ResourceLoader.exists(CHUNKS_GLB) else null
	if packed == null:
		push_warning("GolemAssembly: chunks GLB not found, using proc fallback")
		var fallback := EnemyModelBuilder.build_humanoid(default_color, 1.5, 1.4)
		fallback.name = "Model"
		add_child(fallback)
		return

	_model = packed.instantiate()
	_model.name = "Model"
	add_child(_model)

	EnemyModelFitter.fit(self, _model, 5.0, "box", 0.22, 1.0)

	# Phase 1: collect chunks + record their stand transforms (model-local) BEFORE skeleton
	_collect_chunks_pre_skeleton(_model)

	# Phase 2: build the joint-positioned skeleton hierarchy
	_build_skeleton()

	# Phase 3: assign each chunk to its bone (reparent under bone, keeping world transform)
	_assign_chunks_to_bones()

	# Attach trees to back AFTER chunk assignment
	_attach_back_trees()
	_build_trunk_weapon()
	_grow_flowers(_model)

	_apply_golem_materials(_model)
	_build_death_rigidbodies()

	# Initialize per-chunk soul spring state + apply joint-overlap tweak
	_init_soul_springs()

	# Start in pile/dormant state
	_apply_pile_transforms(true)


# ---------------------------------------------------------------------------
# SKELETON CONSTRUCTION
# ---------------------------------------------------------------------------

## Phase 1: collect chunk stand transforms in model-local space + pile offsets.
## No reparenting here — just read the authored GLB positions.
func _collect_chunks_pre_skeleton(model: Node3D) -> void:
	for child in model.get_children():
		if not child is Node3D:
			continue
		var cname: String = child.name.to_lower()
		if not cname.begins_with("chunk"):
			continue

		var cd := ChunkData.new()
		cd.node = child as Node3D

		# Stand transform in model-local space (authored by GLB)
		cd.stand_pos = child.position
		cd.stand_rot = child.rotation_degrees

		# Pile offsets in model-local space
		cd.pile_pos_model = cd.stand_pos
		cd.pile_rot_model = cd.stand_rot
		for key in PILE_RULES.keys():
			if cname.contains(key):
				var rule: Array = PILE_RULES[key]
				cd.pile_pos_model = cd.stand_pos + (rule[0] as Vector3)
				cd.pile_rot_model = cd.stand_rot + (rule[1] as Vector3)
				break

		_chunks.append(cd)

		if cname.contains("chunk_back_hump"):
			_back_chunk = child


## Phase 2: build the joint-positioned skeleton as Node3D hierarchy.
## Each bone is positioned AT the anatomical joint in _model-local space.
## This is the critical invariant — a bone Node3D sits at the pivot point
## it rotates around, so rotating it swings children around THAT point.
func _build_skeleton() -> void:
	# Helper to create and position a bone in a parent
	var mk := func(parent: Node3D, bone_key: String, bone_name: String) -> Node3D:
		var b := Node3D.new()
		b.name = bone_name
		parent.add_child(b)
		# Position in parent-local space = BONE_JOINTS[bone_key] - BONE_JOINTS[parent_key]
		# But since each bone is added to _model first then reparented, we set world pos.
		# Actually: we add directly to parent, so position is parent-relative.
		# We compute: bone_world = BONE_JOINTS[bone_key], parent_world = parent.position
		# bone_local = bone_world - parent.position (parent has no rotation yet)
		# This works because all BONE_JOINTS are in model-local space and bones
		# have zero rotation at construction time.
		# The parent chain: _model → _skel_root → bone_spine → bone_neck → bone_head etc.
		# So parent.position here is already in model-local space.
		return b

	# Root of skeleton — attached to _model
	_skel_root = Node3D.new()
	_skel_root.name = "SkelRoot"
	_skel_root.position = BONE_JOINTS["skel_root"]
	_model.add_child(_skel_root)

	# Spine chain — children of _skel_root (positions relative to _skel_root)
	bone_spine = mk.call(_skel_root, "bone_spine", "BoneSpine")
	bone_spine.position = BONE_JOINTS["bone_spine"] - BONE_JOINTS["skel_root"]

	bone_neck = mk.call(bone_spine, "bone_neck", "BoneNeck")
	bone_neck.position = BONE_JOINTS["bone_neck"] - BONE_JOINTS["bone_spine"]

	bone_head = mk.call(bone_neck, "bone_head", "BoneHead")
	bone_head.position = BONE_JOINTS["bone_head"] - BONE_JOINTS["bone_neck"]

	# Left arm chain — children of bone_spine
	bone_shoulder_L = mk.call(bone_spine, "bone_shoulder_L", "BoneShoulderL")
	bone_shoulder_L.position = BONE_JOINTS["bone_shoulder_L"] - BONE_JOINTS["bone_spine"]

	bone_upperarm_L = mk.call(bone_shoulder_L, "bone_upperarm_L", "BoneUpperarmL")
	bone_upperarm_L.position = BONE_JOINTS["bone_upperarm_L"] - BONE_JOINTS["bone_shoulder_L"]

	bone_forearm_L = mk.call(bone_upperarm_L, "bone_forearm_L", "BoneForearmL")
	bone_forearm_L.position = BONE_JOINTS["bone_forearm_L"] - BONE_JOINTS["bone_upperarm_L"]

	bone_fist_L = mk.call(bone_forearm_L, "bone_fist_L", "BoneFistL")
	bone_fist_L.position = BONE_JOINTS["bone_fist_L"] - BONE_JOINTS["bone_forearm_L"]

	# Right arm chain — children of bone_spine (mirror of left)
	bone_shoulder_R = mk.call(bone_spine, "bone_shoulder_R", "BoneShoulderR")
	bone_shoulder_R.position = BONE_JOINTS["bone_shoulder_R"] - BONE_JOINTS["bone_spine"]

	bone_upperarm_R = mk.call(bone_shoulder_R, "bone_upperarm_R", "BoneUpperarmR")
	bone_upperarm_R.position = BONE_JOINTS["bone_upperarm_R"] - BONE_JOINTS["bone_shoulder_R"]

	bone_forearm_R = mk.call(bone_upperarm_R, "bone_forearm_R", "BoneForearmR")
	bone_forearm_R.position = BONE_JOINTS["bone_forearm_R"] - BONE_JOINTS["bone_upperarm_R"]

	bone_fist_R = mk.call(bone_forearm_R, "bone_fist_R", "BoneFistR")
	bone_fist_R.position = BONE_JOINTS["bone_fist_R"] - BONE_JOINTS["bone_forearm_R"]

	# Left leg chain — children of _skel_root
	bone_hip_L = mk.call(_skel_root, "bone_hip_L", "BoneHipL")
	bone_hip_L.position = BONE_JOINTS["bone_hip_L"] - BONE_JOINTS["skel_root"]

	bone_thigh_L = mk.call(bone_hip_L, "bone_thigh_L", "BoneThighL")
	bone_thigh_L.position = BONE_JOINTS["bone_thigh_L"] - BONE_JOINTS["bone_hip_L"]

	bone_foot_L = mk.call(bone_thigh_L, "bone_foot_L", "BoneFootL")
	bone_foot_L.position = BONE_JOINTS["bone_foot_L"] - BONE_JOINTS["bone_thigh_L"]

	# Right leg chain
	bone_hip_R = mk.call(_skel_root, "bone_hip_R", "BoneHipR")
	bone_hip_R.position = BONE_JOINTS["bone_hip_R"] - BONE_JOINTS["skel_root"]

	bone_thigh_R = mk.call(bone_hip_R, "bone_thigh_R", "BoneThighR")
	bone_thigh_R.position = BONE_JOINTS["bone_thigh_R"] - BONE_JOINTS["bone_hip_R"]

	bone_foot_R = mk.call(bone_thigh_R, "bone_foot_R", "BoneFootR")
	bone_foot_R.position = BONE_JOINTS["bone_foot_R"] - BONE_JOINTS["bone_thigh_R"]


## Phase 3: reparent each chunk to its bone.
## keep_global_transform=true so chunks stay in their authored world positions
## after reparenting — they just become local to a different parent.
## After reparenting, record the bone-local stand position so reset_to_stand works.
func _assign_chunks_to_bones() -> void:
	for cd in _chunks:
		var cname := cd.node.name.to_lower()
		var target_bone := _resolve_bone_for_chunk(cname)
		cd.bone = target_bone
		cd.node.reparent(target_bone, true)   # keep_global_transform = true
		# Re-read stand pos/rot now in bone-local space
		cd.stand_pos = cd.node.position
		cd.stand_rot = cd.node.rotation_degrees
		# Pile positions: apply model-local pile offset relative to bone world pos.
		# Simplest approach: pile = stand + offset (same delta, now in bone-local space).
		# This gives a reasonable scatter without needing to transform through the bone chain.
		var cn := cname
		cd.pile_pos = cd.stand_pos
		cd.pile_rot = cd.stand_rot
		for key in PILE_RULES.keys():
			if cn.contains(key):
				var rule: Array = PILE_RULES[key]
				cd.pile_pos = cd.stand_pos + (rule[0] as Vector3)
				cd.pile_rot = cd.stand_rot + (rule[1] as Vector3)
				break


## Initialize per-chunk soul spring parameters + apply joint-overlap offset tweak.
## Called once after all chunks are assigned to bones and stand_pos is final.
##
## JOINT OVERLAP TWEAK: push each chunk 10–12% toward the direction of its parent
## bone (toward the skeletal chain root). This closes resting gaps so they read as
## intentional floating-stone spacing rather than broken separation.
func _init_soul_springs() -> void:
	var rng := RandomNumberGenerator.new()

	for cd in _chunks:
		var cname := cd.node.name.to_lower()

		# Seed per chunk for deterministic but varied omega/zeta
		rng.seed = cname.hash() ^ 0xF00D1234

		# Resolve role multiplier
		var role_mult := 1.0
		for role_key in SOUL_CHUNK_MULTIPLIERS.keys():
			if cname.contains(role_key):
				role_mult = SOUL_CHUNK_MULTIPLIERS[role_key]
				break

		# omega: base * role_mult ± SOUL_OMEGA_VAR%
		var omega_jitter := 1.0 + rng.randf_range(-SOUL_OMEGA_VAR, SOUL_OMEGA_VAR)
		cd.soul_omega = SOUL_OMEGA_BASE * role_mult * omega_jitter

		# zeta: base ± SOUL_ZETA_VAR
		var zeta_jitter := rng.randf_range(-SOUL_ZETA_VAR, SOUL_ZETA_VAR)
		cd.soul_zeta = clampf(SOUL_ZETA_BASE + zeta_jitter, 0.50, 0.90)

		# Initialize soul transform to current world transform of the chunk
		cd.soul_pos = cd.node.global_position
		cd.soul_rot = cd.node.global_transform.basis.get_rotation_quaternion()
		cd.soul_vel_pos = Vector3.ZERO
		cd.soul_vel_rot = Vector3.ZERO

		# JOINT OVERLAP TWEAK:
		# Push stand_pos 10% toward origin in bone-local space (toward the bone center).
		# This tightens resting gaps so the floating-stone spacing reads as intentional.
		# Only apply to non-root chunks (rubble stays at floor).
		if not cname.contains("rubble"):
			var overlap := 0.11    # 11% push toward bone center
			cd.stand_pos = cd.stand_pos.lerp(Vector3.ZERO, overlap)
			# Update the chunk node's actual position immediately
			cd.node.position = cd.stand_pos

	_soul_active = false  # will be enabled after awaken completes


## Maps a chunk name to its target bone Node3D.
## The mapping implements the skeleton's chunk → bone table in the header comment.
func _resolve_bone_for_chunk(cname: String) -> Node3D:
	# Arm right chain (check before generic "arm" patterns)
	if cname.contains("arm_r_fist") or cname.contains("arm_r_fis"):
		return bone_fist_R
	if cname.contains("arm_r_forearm"):
		return bone_forearm_R
	if cname.contains("arm_r_upper"):
		return bone_upperarm_R
	if cname.contains("shoulder_r"):
		return bone_shoulder_R

	# Arm left chain
	if cname.contains("arm_l_fist") or cname.contains("arm_l_fis"):
		return bone_fist_L
	if cname.contains("arm_l_forearm"):
		return bone_forearm_L
	if cname.contains("arm_l_upper"):
		return bone_upperarm_L
	if cname.contains("shoulder_l"):
		return bone_shoulder_L

	# Leg right chain
	if cname.contains("leg_r_foot"):
		return bone_thigh_R
	if cname.contains("leg_r_thigh") or cname.contains("leg_r"):
		return bone_hip_R

	# Leg left chain
	if cname.contains("leg_l_foot"):
		return bone_thigh_L
	if cname.contains("leg_l_thigh") or cname.contains("leg_l"):
		return bone_hip_L

	# Head / face
	if cname.contains("face_brow") or cname.contains("face_jaw") \
			or cname.contains("chunk_eye") or cname.contains("chunk_head"):
		return bone_head
	if cname.contains("chunk_neck"):
		return bone_neck

	# Torso
	if cname.contains("chunk_chest") or cname.contains("back_hump"):
		return bone_spine

	# Default — pelvis / rubble → skel_root
	return _skel_root


# ---------------------------------------------------------------------------
# TREE ON BACK — 3 layered trees for a lush canopy
# ---------------------------------------------------------------------------
func _attach_back_trees() -> void:
	var parent: Node3D = _back_chunk if _back_chunk != null else bone_spine
	var root := Node3D.new()
	root.name = "BackTreeCanopy"
	root.position = Vector3(0.0, 0.0, 0.0)
	parent.add_child(root)
	_back_tree_root = root

	var placements := [
		[0, Vector3( 0.00, 0.60, 0.00),   0.0,  0.36],
		[1, Vector3(-0.14, 0.52, 0.05),   22.0, 0.30],
		[2, Vector3( 0.12, 0.48, -0.04), -18.0, 0.24],
	]

	for p in placements:
		var glb_path: String = BACK_TREE_GLBS[p[0]]
		if not ResourceLoader.exists(glb_path):
			push_warning("GolemAssembly: back tree GLB not found: " + glb_path)
			continue
		var ps := load(glb_path) as PackedScene
		if ps == null:
			continue
		var t := ps.instantiate() as Node3D
		t.position = p[1] as Vector3
		t.rotation_degrees = Vector3(0.0, float(p[2]), 0.0)
		var sc := float(p[3])
		t.scale = Vector3(sc, sc, sc)
		root.add_child(t)
		_tint_tree(t)


func _tint_tree(tree: Node3D) -> void:
	for mi in tree.find_children("*", "MeshInstance3D", true, false):
		var gi := mi as MeshInstance3D
		if gi.mesh == null:
			continue
		var all_bark := true
		for s in range(gi.mesh.get_surface_count()):
			var bm := gi.mesh.surface_get_material(s)
			if bm != null:
				var mn := bm.resource_name.to_lower()
				if mn.contains("leave") or mn.contains("leaf") or mn.contains("foliag"):
					all_bark = false
					break
		var tm := ShaderMaterial.new()
		tm.shader = TOON_SHADER_2S
		tm.set_shader_parameter("use_vertex_color", false)
		if all_bark:
			tm.set_shader_parameter("albedo_color", Color(0.34, 0.25, 0.16))
			tm.set_shader_parameter("rim_intensity", 0.04)
			tm.set_shader_parameter("shadow_darkness", 0.32)
		else:
			tm.set_shader_parameter("albedo_color", Color(0.16, 0.46, 0.34))
			tm.set_shader_parameter("rim_intensity", 0.05)
			tm.set_shader_parameter("shadow_darkness", 0.30)
		gi.material_override = tm


func _build_trunk_weapon() -> void:
	var glb_path := BACK_TREE_GLBS[0]
	if not ResourceLoader.exists(glb_path):
		return
	var ps := load(glb_path) as PackedScene
	if ps == null:
		return
	var t := ps.instantiate() as Node3D
	t.name = "TrunkWeapon"
	t.visible = false
	_model.add_child(t)   # direct model child — independent of skeleton
	_tint_tree(t)
	t.scale = Vector3(0.22, 0.22, 0.22)
	_trunk_weapon = t


func _get_chunk_by_name(partial: String) -> Node3D:
	for cd in _chunks:
		if cd.node.name.to_lower().contains(partial.to_lower()):
			return cd.node
	return null


func _grow_flowers(model: Node3D) -> void:
	var spots := [
		Vector3(0.00, 2.36, -0.06), Vector3(-0.22, 2.30,  0.04),
		Vector3(-0.66, 2.06,  0.00), Vector3(-0.44, 2.06,  0.14),
		Vector3(-0.30, 1.96,  0.28), Vector3( 0.60, 1.92,  0.00),
		Vector3( 0.48, 1.86,  0.16), Vector3( 0.00, 2.12, -0.28),
		Vector3(-0.34, 2.00, -0.24), Vector3(-0.96, 1.52,  0.04),
		Vector3( 0.92, 1.46,  0.02), Vector3( 0.04, 1.60,  0.34),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xC0FFEE
	for a in spots:
		if rng.randf() > 0.72:
			continue
		var path: String = FLOWER_GLBS[rng.randi() % FLOWER_GLBS.size()]
		if not ResourceLoader.exists(path):
			continue
		var ps := load(path) as PackedScene
		if ps == null:
			continue
		var f := ps.instantiate() as Node3D
		f.position = a
		var sc := rng.randf_range(0.42, 0.62)
		f.scale = Vector3(sc, sc, sc)
		f.rotation.y = rng.randf() * TAU
		model.add_child(f)
		_make_solid(f)


# ---------------------------------------------------------------------------
# MATERIALS
# ---------------------------------------------------------------------------
func _apply_golem_materials(model: Node3D) -> void:
	var stone_mat := ShaderMaterial.new()
	stone_mat.shader = TOON_SHADER_2S
	stone_mat.set_shader_parameter("albedo_color", Color(1, 1, 1))
	stone_mat.set_shader_parameter("use_vertex_color", true)
	stone_mat.set_shader_parameter("rim_intensity", 0.08)
	stone_mat.set_shader_parameter("shadow_darkness", 0.28)
	stone_mat.next_pass = _make_outline(0.012)

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.42, 0.40, 0.36)
	eye_mat.roughness = 0.95
	eye_mat.emission_enabled = true
	eye_mat.emission = EYE_COLOR
	eye_mat.emission_energy_multiplier = 0.0
	eye_mat.next_pass = _make_outline()
	_eye_mats.append(eye_mat)

	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var surf_mesh: Mesh = (mi as MeshInstance3D).mesh
		if surf_mesh == null:
			continue
		var matched_eye := false
		for s in range(surf_mesh.get_surface_count()):
			var smat := surf_mesh.surface_get_material(s)
			var sname := smat.resource_name.to_lower() if smat != null else ""
			if sname.contains("eye"):
				(mi as MeshInstance3D).set_surface_override_material(s, eye_mat)
				matched_eye = true
			else:
				(mi as MeshInstance3D).set_surface_override_material(s, stone_mat)
		if not matched_eye and (mi as MeshInstance3D).name.to_lower().contains("eye"):
			for s in range(surf_mesh.get_surface_count()):
				(mi as MeshInstance3D).set_surface_override_material(s, eye_mat)


func _make_outline(thickness := 0.03) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OUTLINE_SHADER
	m.set_shader_parameter("outline_color", Color(0.05, 0.05, 0.07))
	m.set_shader_parameter("outline_thickness", thickness)
	return m


func _make_solid(inst: Node3D) -> void:
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var smesh: Mesh = (mi as MeshInstance3D).mesh
		if smesh == null:
			continue
		for s in range(smesh.get_surface_count()):
			var base := smesh.surface_get_material(s)
			var col := Color(1, 1, 1)
			if base is BaseMaterial3D:
				col = (base as BaseMaterial3D).albedo_color
			var tm := ShaderMaterial.new()
			tm.shader = TOON_SHADER_2S
			tm.set_shader_parameter("albedo_color", col)
			tm.set_shader_parameter("use_vertex_color", false)
			(mi as MeshInstance3D).set_surface_override_material(s, tm)


# ---------------------------------------------------------------------------
# PHYSICS DEATH — pre-build frozen RigidBody3D per major chunk
# ---------------------------------------------------------------------------
func _build_death_rigidbodies() -> void:
	for cd in _chunks:
		var cname := cd.node.name.to_lower()
		if cname.contains("rubble") or cname.contains("eye") or cname.contains("face"):
			continue
		var rb := RigidBody3D.new()
		rb.name = cd.node.name + "_rb"
		rb.freeze = true
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		rb.mass = _get_chunk_mass(cname)
		rb.linear_damp = 1.2
		rb.angular_damp = 1.8
		rb.gravity_scale = 1.15
		var shape_owner: CollisionShape3D = CollisionShape3D.new()
		var box := BoxShape3D.new()
		var mi := cd.node.find_child("*", true, false)
		if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
			var aabb := (mi as MeshInstance3D).mesh.get_aabb()
			box.size = aabb.size * cd.node.scale * 0.9
		else:
			box.size = Vector3(0.4, 0.4, 0.4)
		shape_owner.shape = box
		rb.add_child(shape_owner)
		rb.global_transform = cd.node.global_transform
		get_tree().current_scene.add_child(rb)
		rb.visible = false
		cd.rb_node = rb


func _get_chunk_mass(cname: String) -> float:
	if cname.contains("chest") or cname.contains("pelvis"):
		return 18.0
	if cname.contains("shoulder"):
		return 10.0
	if cname.contains("fist"):
		return 12.0
	if cname.contains("leg"):
		return 14.0
	if cname.contains("head"):
		return 8.0
	if cname.contains("back"):
		return 8.0
	return 6.0


# ---------------------------------------------------------------------------
# PILE / STAND transforms
# During awaken/sleep, chunks move relative to their bone (bone stays at identity).
# This keeps the scatter local to each limb.
# ---------------------------------------------------------------------------
func _apply_pile_transforms(instant: bool = false) -> void:
	# Reset all bones to identity before piling
	_reset_bones_to_identity(instant)

	for cd in _chunks:
		if instant:
			cd.node.position = cd.pile_pos
			cd.node.rotation_degrees = cd.pile_rot
		else:
			create_tween().tween_property(cd.node, "position", cd.pile_pos, 0.85)\
				.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			create_tween().tween_property(cd.node, "rotation_degrees", cd.pile_rot, 0.80)\
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _reset_bones_to_identity(instant: bool = false) -> void:
	## Resets every bone to zero rotation/zero translation offset.
	## Called before pile transitions and on reset_to_stand.
	if _skel_root == null:
		return
	var all_bones := [
		_skel_root, bone_spine, bone_neck, bone_head,
		bone_shoulder_L, bone_upperarm_L, bone_forearm_L, bone_fist_L,
		bone_shoulder_R, bone_upperarm_R, bone_forearm_R, bone_fist_R,
		bone_hip_L, bone_thigh_L, bone_foot_L,
		bone_hip_R, bone_thigh_R, bone_foot_R,
	]
	for b in all_bones:
		if b == null:
			continue
		if instant:
			b.rotation_degrees = Vector3.ZERO
		else:
			create_tween().tween_property(b, "rotation_degrees", Vector3.ZERO, 0.5)


# ---------------------------------------------------------------------------
# ASSEMBLY AWAKEN — heavy staggered assembly from pile to stand.
# Bones at identity during awaken; individual chunks fly to stand_pos.
# After awaken completes the skeleton is ready for combat articulation.
# ---------------------------------------------------------------------------
func _awaken() -> void:
	if awaken_tween and awaken_tween.is_running():
		return

	awaken_tween = create_tween()

	# Ensure bones are at identity before assembly
	_reset_bones_to_identity(true)

	# Anticipation: pebbles rattle
	awaken_tween.tween_property(_model, "scale", Vector3(1.05, 0.96, 1.05), 0.10)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	awaken_tween.tween_property(_model, "scale", Vector3.ONE, 0.20)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for cd in _chunks:
		var cname := cd.node.name.to_lower()
		var delay := _get_awaken_delay(cname)
		var dur := _get_awaken_duration(cname)

		var pos_tw := create_tween()
		pos_tw.tween_interval(delay)
		pos_tw.tween_property(cd.node, "position", cd.stand_pos, dur)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		var rot_tw := create_tween()
		rot_tw.tween_interval(delay)
		rot_tw.tween_property(cd.node, "rotation_degrees", cd.stand_rot, dur * 0.88)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		if cname.contains("chunk_eye"):
			var eye_tw := create_tween()
			eye_tw.tween_interval(delay + dur * 0.80)
			eye_tw.tween_callback(_light_up_eyes)

	# Eye-reveal squash at the end
	awaken_tween.tween_interval(0.95)
	awaken_tween.tween_property(_model, "scale", Vector3(1.08, 0.93, 1.08), 0.07)\
		.set_trans(Tween.TRANS_SINE)
	awaken_tween.tween_property(_model, "scale", Vector3.ONE, 0.18)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	awaken_tween.tween_callback(func():
		is_dormant = false
		is_provoked = true
		_soul_snap_to_bones()   # seed soul state from current bone transforms
		_soul_active = true     # enable per-chunk spring-follow after awaken
	)


func _get_awaken_delay(cname: String) -> float:
	for key in PILE_TO_STAND_DELAYS.keys():
		if cname.contains(key):
			return PILE_TO_STAND_DELAYS[key]
	return 0.30


func _get_awaken_duration(cname: String) -> float:
	if cname.contains("chest") or cname.contains("pelvis"):
		return 0.62
	if cname.contains("shoulder"):
		return 0.55
	if cname.contains("fist"):
		return 0.50
	if cname.contains("head"):
		return 0.55
	if cname.contains("rubble") or cname.contains("foot"):
		return 0.28
	return 0.44


func _sleep() -> void:
	if awaken_tween and awaken_tween.is_running():
		awaken_tween.kill()
	_soul_active = false   # disable soul springs during sleep transition
	is_dormant = true
	is_provoked = false
	for em in _eye_mats:
		em.emission_energy_multiplier = 0.0
		em.albedo_color = Color(0.42, 0.40, 0.36)
	if _back_tree_root != null:
		_back_tree_root.visible = true
	if _trunk_weapon != null:
		_trunk_weapon.visible = false
	_has_tree = true
	_reset_bones_to_identity(false)
	_apply_pile_transforms(false)
	_spring_vel = Vector3.ZERO
	_spring_target = Vector3.ZERO


func _light_up_eyes() -> void:
	for em in _eye_mats:
		em.emission = EYE_COLOR
		create_tween().tween_property(em, "albedo_color", EYE_COLOR, 0.35)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		create_tween().tween_property(em, "emission_energy_multiplier", EYE_ENERGY, 0.45)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Snap all per-chunk soul state to their current bone target transforms.
## Call this before enabling _soul_active so the spring starts from rest
## (no velocity, no position error) — avoids a jarring catch-up snap on enable.
func _soul_snap_to_bones() -> void:
	for cd in _chunks:
		if cd.node == null or cd.bone == null:
			continue
		var bone_xf := cd.bone.global_transform
		cd.soul_pos     = bone_xf * cd.stand_pos
		cd.soul_rot     = bone_xf.basis.get_rotation_quaternion() \
			* Quaternion.from_euler(deg_to_rad(cd.stand_rot.x) * Vector3(1,0,0) \
			+ deg_to_rad(cd.stand_rot.y) * Vector3(0,1,0) \
			+ deg_to_rad(cd.stand_rot.z) * Vector3(0,0,1))
		cd.soul_vel_pos = Vector3.ZERO
		cd.soul_vel_rot = Vector3.ZERO


# ---------------------------------------------------------------------------
# SPRING-DAMPER — secondary sway (root) + per-chunk SOUL springs
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _skel_root == null or is_dormant:
		return

	# --- Secondary sway on _skel_root (unchanged) ---
	var omega := SPRING_OMEGA
	var damp   := 2.0 * SPRING_ZETA * omega
	var force  := -omega * omega * (_skel_root.rotation_degrees - _spring_target) - damp * _spring_vel
	_spring_vel  += force * delta
	_skel_root.rotation_degrees += _spring_vel * delta

	# --- SOUL LAYER: per-chunk spring-follow ---
	# Each chunk's actual world transform FOLLOWS its bone's current world transform
	# with a critically-damped spring. The bone represents the "soul/intent" (animation);
	# the chunk is the physical rock lagging behind with magical float.
	if not _soul_active:
		return

	for cd in _chunks:
		if cd.node == null or cd.bone == null:
			continue

		# TARGET: the chunk's ideal position if it were rigidly parented to the bone.
		# = bone.global_transform applied to the chunk's bone-local stand offset.
		var bone_xf := cd.bone.global_transform
		var target_pos := bone_xf * cd.stand_pos
		var target_rot := bone_xf.basis.get_rotation_quaternion() \
			* Quaternion.from_euler(deg_to_rad(cd.stand_rot.x) * Vector3(1,0,0) \
			+ deg_to_rad(cd.stand_rot.y) * Vector3(0,1,0) \
			+ deg_to_rad(cd.stand_rot.z) * Vector3(0,0,1))

		var w  := cd.soul_omega
		var dw := 2.0 * cd.soul_zeta * w

		# Position spring: F = -w²*(pos - target) - dw*vel
		var pos_force := -w * w * (cd.soul_pos - target_pos) - dw * cd.soul_vel_pos
		cd.soul_vel_pos += pos_force * delta
		cd.soul_pos     += cd.soul_vel_pos * delta

		# Rotation spring: operate on quaternion error → angular velocity correction.
		# error_quat = target * current.inverse() → axis-angle → spring force on angular vel.
		var err_q := target_rot * cd.soul_rot.inverse()
		# Normalize and extract axis-angle (error angle and axis)
		err_q = err_q.normalized()
		if err_q.w < 0.0:
			err_q = -err_q    # shortest-path convention
		var err_angle := 2.0 * acos(clampf(err_q.w, -1.0, 1.0))
		var err_axis  := Vector3(err_q.x, err_q.y, err_q.z)
		if err_axis.length_squared() > 0.0001:
			err_axis = err_axis.normalized()
		else:
			err_axis = Vector3.ZERO
		var err_vec := err_axis * err_angle   # axis*angle in world space

		var rot_force := -w * w * (-err_vec) - dw * cd.soul_vel_rot
		cd.soul_vel_rot += rot_force * delta
		# Integrate: apply angular velocity as a small rotation delta
		var rot_delta := cd.soul_vel_rot * delta
		var delta_q := Quaternion(rot_delta.normalized(), rot_delta.length()) \
			if rot_delta.length() > 0.0001 else Quaternion.IDENTITY
		cd.soul_rot = (delta_q * cd.soul_rot).normalized()

		# Write back to the chunk node via global_transform
		cd.node.global_transform = Transform3D(
			Basis(cd.soul_rot),
			cd.soul_pos
		)


# ===========================================================================
# COMBAT ANIMATIONS — JOINT-POSITIONED SKELETON APPROACH
#
# The skeleton gives us TWO animation modes:
#   a) Whole-body lean: rotate _skel_root = pelvis tips, ALL bones/chunks follow
#      (same as the old body_root, but pelvis is now at anatomical hip position)
#   b) Per-limb articulation: rotate individual bones around their joint pivots
#      e.g. bone_shoulder_L.rotation_degrees.z = -50° swings the left arm DOWN
#      around the SHOULDER JOINT — not the body center.
#
# For idle: subtle per-bone wobble (shoulders, head) gives the "alive" read.
# For attack_basic: arm slams by rotating shoulder bone → elbow bone → impact.
#
# INVARIANT: Chunk positions within a bone are NEVER animated during combat.
# Only bone rotation_degrees change. Cohesion is guaranteed because each chunk
# is rigidly parented to its bone and moves with it.
# ===========================================================================

# ---------------------------------------------------------------------------
# idle — ALIVE motion via per-bone subtle articulation.
# This directly tests "feels alive again" — shoulder/arm/head move independently
# but stay connected because each bone pivots at the joint.
# ---------------------------------------------------------------------------
func play_idle() -> void:
	if _model == null or _anim_active:
		return

	# Root gentle sway — the whole mass breathes
	if _skel_root:
		var tw := create_tween().set_loops(0)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-1.5, 2.5, 0.0), 2.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees", Vector3.ZERO, 2.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-1.5, -2.5, 0.0), 2.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees", Vector3.ZERO, 2.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Head nod — independent of shoulders, staggered phase
	if bone_head:
		var htw := create_tween().set_loops(0)
		htw.tween_interval(0.6)  # phase offset so head and body don't sync
		htw.tween_property(bone_head, "rotation_degrees",
			Vector3(-3.0, 2.0, 0.0), 2.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		htw.tween_property(bone_head, "rotation_degrees", Vector3.ZERO, 2.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		htw.tween_property(bone_head, "rotation_degrees",
			Vector3(-2.0, -1.5, 0.0), 2.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		htw.tween_property(bone_head, "rotation_degrees", Vector3.ZERO, 2.8)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Left shoulder droop — arms hang with slight independent sway
	# This is the key "alive" test: shoulder_L rotates around the shoulder JOINT.
	# The arm chunks should swing as a connected unit from that pivot.
	if bone_shoulder_L:
		var sltw := create_tween().set_loops(0)
		sltw.tween_interval(0.3)
		sltw.tween_property(bone_shoulder_L, "rotation_degrees",
			Vector3(4.0, 0.0, 3.0), 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sltw.tween_property(bone_shoulder_L, "rotation_degrees", Vector3.ZERO, 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sltw.tween_property(bone_shoulder_L, "rotation_degrees",
			Vector3(2.0, 0.0, -2.0), 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sltw.tween_property(bone_shoulder_L, "rotation_degrees", Vector3.ZERO, 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Right shoulder — opposite phase for natural counterbalance
	if bone_shoulder_R:
		var srtw := create_tween().set_loops(0)
		srtw.tween_interval(1.5)  # half-period offset = opposite phase
		srtw.tween_property(bone_shoulder_R, "rotation_degrees",
			Vector3(4.0, 0.0, -3.0), 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		srtw.tween_property(bone_shoulder_R, "rotation_degrees", Vector3.ZERO, 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		srtw.tween_property(bone_shoulder_R, "rotation_degrees",
			Vector3(2.0, 0.0, 2.0), 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		srtw.tween_property(bone_shoulder_R, "rotation_degrees", Vector3.ZERO, 3.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Spine breathe — rib-cage expand/compress feel
	if bone_spine:
		var spw := create_tween().set_loops(0)
		spw.tween_property(bone_spine, "rotation_degrees",
			Vector3(-1.0, 1.0, 0.0), 3.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		spw.tween_property(bone_spine, "rotation_degrees", Vector3.ZERO, 3.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		spw.tween_property(bone_spine, "rotation_degrees",
			Vector3(-1.0, -1.0, 0.0), 3.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		spw.tween_property(bone_spine, "rotation_degrees", Vector3.ZERO, 3.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------------------
# lumber — weighted walk cycle. Hip drop via skel_root Z lean + leg bones.
# ---------------------------------------------------------------------------
func play_lumber() -> void:
	if _model == null:
		return

	# Root tilts left/right per step (hip drop simulation)
	if _skel_root:
		var tw := create_tween().set_loops(0)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, 0.0, -4.0), 0.40)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, 0.0, -4.0), 0.05)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, 0.0, 4.0), 0.55)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, 0.0, 4.0), 0.05)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 0.45)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_spring_target = Vector3(-1.5, 0.0, 0.0)


# ---------------------------------------------------------------------------
# trunk_rip — signature setup move.
# Body leans via _skel_root (whole mass), trunk weapon is active element.
# ---------------------------------------------------------------------------
func play_trunk_rip() -> Signal:
	if _model == null or not _has_tree:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-14.0, 0.0, 2.5), 0.50)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	if _trunk_weapon:
		_trunk_weapon.visible = false

	if _skel_root:
		var tw := create_tween()
		tw.tween_interval(0.50)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-14.0, 0.0, 2.5), 0.16)\
			.set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-16.0, 0.0, 3.5), 0.085)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-14.0, 0.0, 2.5), 0.085)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-15.0, 0.0, 3.0), 0.085)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _skel_root:
		var tw := create_tween()
		tw.tween_interval(0.92)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(8.0, 0.0, -2.0), 0.17)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(12.0, 0.0, -3.0), 0.08)\
			.set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-4.0, 0.0, 0.0), 0.28)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(2.0, 0.0, 0.0), 1.03)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var rip_tw := create_tween()
	rip_tw.tween_interval(0.92)
	rip_tw.tween_callback(_on_tree_ripped_new)

	var trunk_tw := create_tween()
	trunk_tw.tween_interval(0.92)
	trunk_tw.tween_callback(func():
		if _trunk_weapon == null:
			return
		_trunk_weapon.position = Vector3(-0.2, 2.8, 0.6)
		_trunk_weapon.rotation_degrees = Vector3(60.0, 0.0, 20.0)
	)
	trunk_tw.tween_interval(0.01)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.2, 1.2, -0.4), 0.17)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	trunk_tw.tween_property(_trunk_weapon, "rotation_degrees",
		Vector3(-30.0, 20.0, -10.0), 0.17)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.4, 0.8, -0.6), 0.08)\
		.set_trans(Tween.TRANS_LINEAR)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.8, 0.2, -0.2), 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trunk_tw.tween_property(_trunk_weapon, "rotation_degrees",
		Vector3(-60.0, 15.0, -5.0), 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.1, 0.5, 0.3), 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	trunk_tw.tween_property(_trunk_weapon, "rotation_degrees",
		Vector3(-20.0, 15.0, 0.0), 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.3, 0.4, 0.1), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	trunk_tw.tween_property(_trunk_weapon, "rotation_degrees",
		Vector3(-25.0, 15.0, -2.0), 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	trunk_tw.tween_property(_trunk_weapon, "position",
		Vector3(-1.1, 0.5, 0.3), 0.26)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	trunk_tw.tween_property(_trunk_weapon, "rotation_degrees",
		Vector3(-20.0, 15.0, 0.0), 0.26)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	create_tween().tween_callback(func():
		_spring_target = Vector3(2.5, 0.0, 0.0)
	).set_delay(0.92)
	create_tween().tween_callback(func(): _spring_target = Vector3.ZERO)\
		.set_delay(1.20)

	var done_tween := create_tween()
	done_tween.tween_interval(2.20)
	done_tween.tween_callback(func():
		_anim_active = false
		_spring_target = Vector3.ZERO
	)
	return done_tween.finished


func _on_tree_ripped_new() -> void:
	_has_tree = false
	if _back_tree_root != null:
		_back_tree_root.visible = false
	if _trunk_weapon != null:
		_trunk_weapon.visible = true


# ---------------------------------------------------------------------------
# trunk_sweep — 3 escalating lateral sweeps.
# ---------------------------------------------------------------------------
func play_trunk_sweep() -> Signal:
	if _model == null or _trunk_weapon == null:
		return Signal()
	_anim_active = true

	_do_one_sweep_group(0.0,  0.75, 0.55, 0.65, 1.0)
	_do_one_sweep_group(2.0,  0.52, 0.50, 0.80, 1.30)
	_do_one_sweep_group(3.85, 0.28, 0.58, 1.10, 1.55)

	var done_tween := create_tween()
	done_tween.tween_interval(6.0)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


func _do_one_sweep_group(
		offset: float,
		anticipation_dur: float,
		sweep_dur: float,
		recover_dur: float,
		arc: float) -> void:
	if _skel_root:
		var tw := create_tween()
		tw.tween_interval(offset)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, 22.0 * arc, 2.0 * arc), anticipation_dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, -30.0 * arc, 0.0), sweep_dur)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, recover_dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if _trunk_weapon:
		var held_pos := Vector3(-1.1, 0.5, 0.3)
		var held_rot := Vector3(-20.0, 15.0, 0.0)
		var tw := create_tween()
		tw.tween_interval(offset + 0.12)
		tw.tween_property(_trunk_weapon, "rotation_degrees",
			held_rot + Vector3(0.0, 28.0 * arc, 0.0), anticipation_dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_trunk_weapon, "rotation_degrees",
			held_rot + Vector3(0.0, -42.0 * arc, 0.0), sweep_dur + 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_trunk_weapon, "rotation_degrees",
			held_rot, recover_dur)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	create_tween().tween_callback(func():
		_spring_target = Vector3(0.0, -8.0 * arc, 0.0)
	).set_delay(offset + anticipation_dur * 0.5)
	create_tween().tween_callback(func(): _spring_target = Vector3.ZERO)\
		.set_delay(offset + anticipation_dur + sweep_dur)


# ---------------------------------------------------------------------------
# attack_basic — ARM SLAM via skeleton bones.
#
# This is the PRIMARY TEST of the joint-positioned skeleton:
#   1. Anticipation: shoulder_L raises (rotates -Z around shoulder joint)
#      → the entire left arm chain rises CONNECTED because bones parent each other
#   2. Slam: shoulder_L slams DOWN (+Z) + body leans forward (skel_root)
#      → arm crashes down, pivoting at the SHOULDER, not the body center
#   3. Recoil: bones return to identity
#
# Correct pivot test: bone_shoulder_L.rotation_degrees.z goes negative (raise),
# then swings positive (slam). The chunks under shoulder → upperarm → forearm →
# fist should all move together as ONE connected arm, rotating around shoulder.
# ---------------------------------------------------------------------------
func play_attack_basic() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true

	# Phase 1 — ANTICIPATION (0.0–0.55s): whole body leans BACK + arm RAISES
	# Body lean: skel_root tips back slightly (mass loading)
	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-8.0, 8.0, 0.0), 0.55)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Arm raise: bone_shoulder_R rotates BACK and UP around shoulder joint.
	# Z negative = arm swings back (away from target, loading the slam).
	# X positive = arm raises slightly upward.
	if bone_shoulder_R:
		var tw := create_tween()
		tw.tween_property(bone_shoulder_R, "rotation_degrees",
			Vector3(15.0, 0.0, -25.0), 0.55)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Elbow bends during raise (forearm lags behind — arm coils)
	if bone_upperarm_R:
		var tw := create_tween()
		tw.tween_property(bone_upperarm_R, "rotation_degrees",
			Vector3(-20.0, 0.0, 0.0), 0.55)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Phase 2 — SLAM (0.55–0.81s): arm CRASHES DOWN from shoulder joint
	# bone_shoulder_R swings forward+down: Z goes from -25° → +40° (slam arc)
	# This is the joint-pivot proof: the fist follows the shoulder bone through
	# the entire arc, staying CONNECTED to the arm chain.
	if bone_shoulder_R:
		var tw := create_tween()
		tw.tween_interval(0.55)
		tw.tween_property(bone_shoulder_R, "rotation_degrees",
			Vector3(-5.0, 0.0, 55.0), 0.26)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	if bone_upperarm_R:
		var tw := create_tween()
		tw.tween_interval(0.55)
		tw.tween_property(bone_upperarm_R, "rotation_degrees",
			Vector3(10.0, 0.0, 0.0), 0.26)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Body follows through on the slam
	if _skel_root:
		var tw := create_tween()
		tw.tween_interval(0.55)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(18.0, 8.0, 0.0), 0.26)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Phase 3 — IMPACT FREEZE + SQUASH at slam moment (0.81s)
	var sq := create_tween()
	sq.tween_interval(0.81)
	sq.tween_callback(func():
		var s := create_tween()
		s.tween_property(_model, "scale", Vector3(1.08, 0.92, 1.08), 0.05)
		s.tween_property(_model, "scale", Vector3(1.08, 0.92, 1.08), 0.03)
		s.tween_property(_model, "scale", Vector3.ONE, 0.18)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		Engine.time_scale = 0.15
		create_tween().tween_callback(func(): Engine.time_scale = 1.0).set_delay(0.04)
		_spring_target = Vector3(4.0, 0.0, 0.0)
		create_tween().tween_callback(func(): _spring_target = Vector3.ZERO).set_delay(0.4)
	)

	# Phase 4 — RECOIL + RECOVER (0.81s–1.5s): bones return to identity
	if _skel_root:
		var tw := create_tween()
		tw.tween_interval(0.81)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 0.70)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if bone_shoulder_R:
		var tw := create_tween()
		tw.tween_interval(0.81)
		tw.tween_property(bone_shoulder_R, "rotation_degrees",
			Vector3.ZERO, 0.70)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if bone_upperarm_R:
		var tw := create_tween()
		tw.tween_interval(0.81)
		tw.tween_property(bone_upperarm_R, "rotation_degrees",
			Vector3.ZERO, 0.70)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var done_tween := create_tween()
	done_tween.tween_interval(1.5)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# attack_charged — body leans BACK (raising energy) then CRASHES forward.
# ---------------------------------------------------------------------------
func play_attack_charged() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-22.0, 0.0, 0.0), 1.0)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-24.0, 0.0, 1.0), 0.20)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-22.0, 0.0, 0.0), 0.20)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(26.0, 0.0, 0.0), 0.42)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 1.08)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var sq_tw := create_tween()
	sq_tw.tween_interval(2.4)
	sq_tw.tween_callback(func():
		var sq := create_tween()
		sq.tween_property(_model, "scale", Vector3(1.14, 0.87, 1.14), 0.06)
		sq.tween_property(_model, "scale", Vector3(1.14, 0.87, 1.14), 0.04)
		sq.tween_property(_model, "scale", Vector3.ONE, 0.26)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		Engine.time_scale = 0.12
		create_tween().tween_callback(func(): Engine.time_scale = 1.0).set_delay(0.06)
		_spring_target = Vector3(8.0, 0.0, 0.0)
		create_tween().tween_callback(func(): _spring_target = Vector3.ZERO).set_delay(0.6)
	)

	var done_tween := create_tween()
	done_tween.tween_interval(3.4)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# stomp — body tips LEFT then crashes down.
# ---------------------------------------------------------------------------
func play_stomp() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(0.0, -10.0, -6.0), 0.60)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(8.0, 0.0, 0.0), 0.30)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 1.20)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var sq := create_tween()
	sq.tween_interval(0.88)
	sq.tween_callback(func():
		var s := create_tween()
		s.tween_property(_model, "scale", Vector3(1.10, 0.92, 1.10), 0.06)
		s.tween_property(_model, "scale", Vector3(1.10, 0.92, 1.10), 0.04)
		s.tween_property(_model, "scale", Vector3.ONE, 0.22)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		Engine.time_scale = 0.18
		create_tween().tween_callback(func(): Engine.time_scale = 1.0).set_delay(0.05)
		_spring_target = Vector3(3.0, 0.0, 0.0)
		create_tween().tween_callback(func(): _spring_target = Vector3.ZERO).set_delay(0.35)
	)

	var done_tween := create_tween()
	done_tween.tween_interval(2.1)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# rock_throw — body loads then throws from the shoulder rotation.
# ---------------------------------------------------------------------------
func play_rock_throw() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(12.0, -14.0, 0.0), 0.72)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(4.0, 26.0, 0.0), 0.36)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 0.70)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var done_tween := create_tween()
	done_tween.tween_interval(2.6)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# root_snare — body plants deep forward (knuckle-drag), then heaves up.
# ---------------------------------------------------------------------------
func play_root_snare() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(28.0, 0.0, 0.0), 0.85)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(28.0, 0.0, 0.0), 0.90)\
			.set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-14.0, 0.0, 0.0), 0.58)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 0.42)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var done_tween := create_tween()
	done_tween.tween_interval(3.2)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# hit_react — brief stagger.
# ---------------------------------------------------------------------------
func play_hit_react() -> Signal:
	if _model == null or _anim_active:
		return Signal()
	_anim_active = true

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(-6.0, 8.0, 0.0), 0.14)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3.ZERO, 0.50)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var done_tween := create_tween()
	done_tween.tween_interval(0.80)
	done_tween.tween_callback(func(): _anim_active = false)
	return done_tween.finished


# ---------------------------------------------------------------------------
# death — PHYSICS COLLAPSE.
# ---------------------------------------------------------------------------
func play_death() -> Signal:
	if _model == null:
		return Signal()
	_anim_active = true
	_soul_active = false   # let physics collapse move chunks freely

	_model.scale = Vector3.ONE

	if _skel_root:
		var tw := create_tween()
		tw.tween_property(_skel_root, "rotation_degrees",
			Vector3(4.0, 0.0, 0.0), 0.30)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var stagger := create_tween()
	stagger.tween_interval(0.35)
	stagger.tween_property(_model, "rotation_degrees",
		Vector3(0.0, 0.0, -6.0), 0.30)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stagger.tween_property(_model, "rotation_degrees",
		Vector3(18.0, 0.0, 4.0), 0.70)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	for em in _eye_mats:
		var etw := create_tween()
		etw.tween_interval(0.15)
		etw.tween_property(em, "emission_energy_multiplier", 0.0, 0.45)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		etw.tween_property(em, "albedo_color", Color(0.25, 0.23, 0.22), 0.3)

	var impact_tw := create_tween()
	impact_tw.tween_interval(1.05)
	impact_tw.tween_callback(_trigger_physics_collapse)

	if _trunk_weapon != null and _trunk_weapon.visible:
		var ttw := create_tween()
		ttw.tween_interval(0.35)
		ttw.tween_property(_trunk_weapon, "position",
			_trunk_weapon.position + Vector3(0.5, -2.5, 0.5), 0.70)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	impact_tw.tween_interval(0.15)
	impact_tw.tween_callback(func():
		if _model:
			_model.visible = false
	)

	impact_tw.tween_interval(3.35)
	impact_tw.tween_callback(_freeze_death_rigidbodies)

	var done_tween := create_tween()
	done_tween.tween_interval(2.2)
	done_tween.tween_callback(func():
		_anim_active = false
		is_dead = true
	)
	return done_tween.finished


func _trigger_physics_collapse() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xDEAD60

	for cd in _chunks:
		if cd.rb_node == null:
			continue
		cd.rb_node.global_transform = cd.node.global_transform
		cd.rb_node.visible = true
		cd.rb_node.freeze = false

		var center := global_position + Vector3(0.0, 1.8, 0.0)
		var outward := (cd.rb_node.global_position - center).normalized()
		var impulse_mag := rng.randf_range(2.5, 7.0)
		cd.rb_node.apply_central_impulse(
			outward * impulse_mag + Vector3(0.0, rng.randf_range(-1.0, 2.5), 0.0)
		)
		cd.rb_node.apply_torque_impulse(
			Vector3(rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0),
					rng.randf_range(-1.0, 1.0)) * 4.0
		)


func _freeze_death_rigidbodies() -> void:
	for cd in _chunks:
		if cd.rb_node != null:
			cd.rb_node.freeze = true
			cd.rb_node.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC


# ---------------------------------------------------------------------------
# reset_to_stand — used by the preview/capture to snap back cleanly
# ---------------------------------------------------------------------------
func reset_to_stand() -> void:
	_anim_active = false
	is_dead = false

	if _model:
		_model.visible = true
		_model.scale = Vector3.ONE
		_model.rotation_degrees = Vector3.ZERO

	# Reset all bones to identity (this also resets skel_root)
	_reset_bones_to_identity(true)

	# Reset all chunks to stand positions (inside their bones)
	for cd in _chunks:
		cd.node.position = cd.stand_pos
		cd.node.rotation_degrees = cd.stand_rot

	# Hide death rigidbodies
	for cd in _chunks:
		if cd.rb_node != null:
			cd.rb_node.freeze = true
			cd.rb_node.visible = false

	# Reset eyes
	for em in _eye_mats:
		em.emission = EYE_COLOR
		em.emission_energy_multiplier = EYE_ENERGY
		em.albedo_color = EYE_COLOR

	# Reset trees / trunk weapon
	if _back_tree_root != null:
		_back_tree_root.visible = true
	if _trunk_weapon != null:
		_trunk_weapon.visible = false
		_trunk_weapon.position = Vector3(-1.1, 0.5, 0.3)
		_trunk_weapon.rotation_degrees = Vector3(-20.0, 15.0, 0.0)
	_has_tree = true

	_spring_vel = Vector3.ZERO
	_spring_target = Vector3.ZERO
	_soul_snap_to_bones()
	_soul_active = true


# ===========================================================================
# ENEMY OVERRIDES (gameplay — untouched)
# ===========================================================================

func _should_pursue(distance: float) -> bool:
	if is_dormant:
		if distance <= detection_range:
			_awaken()
		return false
	return super._should_pursue(distance)


func _idle_behavior(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0


func _get_anim_model_root() -> Node3D:
	return get_node_or_null("Model")


func take_damage(amount: float, hit_direction := Vector3.ZERO, knockback_force := 0.0,
		attacker_str := 0, attacker: Node = null, element: String = "physical",
		is_crit: bool = false) -> void:
	if is_dormant:
		_awaken()
	super.take_damage(amount, hit_direction, knockback_force, attacker_str, attacker, element, is_crit)


func perform_attack() -> void:
	if not can_attack:
		return
	can_attack = false
	match attack_index:
		0: _attack_punch()
		1: _attack_stomp()
		2: _attack_rock_throw()
	attack_index = (attack_index + 1) % 3
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_dead:
		return
	can_attack = true


func _attack_punch() -> void:
	if not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage * outgoing_damage_mult())
	if target.has_method("apply_knockback"):
		var direction := (target.global_position - global_position).normalized()
		target.apply_knockback(direction, 12.0)


func _attack_stomp() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(player):
			continue
		if global_position.distance_to(player.global_position) <= stomp_range:
			if player.has_method("take_damage"):
				player.take_damage(damage * 0.8 * outgoing_damage_mult())


func _attack_rock_throw() -> void:
	if not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) <= throw_range:
		if target.has_method("take_damage"):
			target.take_damage(damage * 0.6 * outgoing_damage_mult())


func _on_death() -> void:
	pass


func _on_knockback(_kb_velocity: Vector3) -> void:
	pass
