# build_hawk.py -- red-tailed hawk (buteo), built OUT OF ITS FEATHERS.
#
# Why a rebuild, measured: the previous attempt (`bird_prey/build_bird.py`)
# shipped wings as flat scalloped PLANES floating beside an egg-shaped body --
# no talons at all, head a smooth ball. That is the same shape of failure as
# the hair and the carapace v1: a continuous surface with the structure painted
# or notched on top never reads as the structure. A wing is a stack of
# individual feathers whose roots hide under covert masses, so here every
# primary, secondary and tail feather is its own piece -- the same move that
# fixed the shell (each scute its own geometry).
#
# Identity: BUTEO, per `_references/hawk/_synthesis.md` -- broad rounded wings
# with emarginated "fingers", short fan tail, 1.22 m wingspan. Field marks of
# the red-tail, all field-visible from BELOW (the view the player actually has
# of a mob circling at 14 m): rufous tail, dark patagial marks on the
# underwing leading edge, streaked belly band. Claws big enough to read as a
# predator -- "es el rasgo que dice depredador incluso posado".
#
# This pass is FORM ONLY: no animation clips. Flight (soar/flap/dive) needs
# its own motion spec before any key is authored, same contract as the turtle
# and the golem. The GLB exports static in the glide pose.
#
# Run: blender -b --factory-startup --python-exit-code 1 --python build_hawk.py
import json
import math
import os
import struct
import sys

import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import _deploy  # noqa: E402
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _feather_texture  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------------- dimensions (ficha hawk/_synthesis.md) ----------------------
WINGSPAN = 1.22          # tip to tip, metres -- REAL scale; in-game scale is a
                         # separate decision Joan makes on the 1.0/1.3/1.6 ramp
BODY_LEN = 0.32          # torso only; bill-to-tail lands near 0.50
DIHEDRAL = math.radians(8.0)   # a soaring buteo holds a shallow V

N_PRIMARIES = 10         # per wing -- fixed anatomy, asserted below
N_SECONDARIES = 12       # per wing
N_RECTRICES = 12         # the tail fan
N_FINGERS = 5            # outer emarginated primaries: the slotted tips

FWD = Vector((0.0, -1.0, 0.0))   # project convention: the front is -Y

PARTS = {}
PIECES = []              # (obj, tone) collected until the join
TONES = {}               # vertex-range -> rgb after join


def _tone(rgb):
    """Linear-space albedo. Values picked for the rig that multiplies them --
    the turtle paid twice for choosing 'screen' colours here."""
    return tuple(rgb)


# Plumage palette, linear. R > G > B keeps it reading as feather, not slate.
DORSAL = _tone((0.100, 0.066, 0.036))     # dark brown back and wing top
BREAST = _tone((0.300, 0.255, 0.185))     # pale cream underside
BAND = _tone((0.150, 0.110, 0.070))       # the streaked belly band
RUFOUS = _tone((0.240, 0.075, 0.038))     # THE red tail
PRIM = _tone((0.130, 0.100, 0.070))
PRIM_TIP = _tone((0.048, 0.038, 0.028))   # dark wing tips
SECOND = _tone((0.165, 0.135, 0.095))
PATAGIAL = _tone((0.055, 0.042, 0.030))   # dark leading-edge mark, underwing
COVERT_U = _tone((0.270, 0.230, 0.165))   # pale underwing coverts
BEAK = _tone((0.050, 0.045, 0.045))
CERE = _tone((0.300, 0.220, 0.050))       # yellow cere
EYE = _tone((0.028, 0.022, 0.016))
TALON = _tone((0.040, 0.036, 0.032))
LEG = _tone((0.290, 0.230, 0.075))        # yellow tarsus


def add_piece(obj, tone):
    for p in obj.data.polygons:
        p.use_smooth = True
    PIECES.append((obj, tone))
    return obj


def sphere(loc, r, scale=(1, 1, 1), seg=14, ring=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring,
                                         radius=r, location=loc)
    o = bpy.context.object
    for v in o.data.vertices:
        v.co.x *= scale[0]
        v.co.y *= scale[1]
        v.co.z *= scale[2]
    return o


def feather(root, tip, width, thick=0.006, taper=1.0, row=None):
    """One feather from root to tip. `taper` < 1 narrows the tip
    (emargination). `row` selects the tinted barb band in the atlas; the UV is
    written HERE, at creation, in the feather's own frame -- after the join
    the local axes are gone.

    Root width raised 0.35 -> 0.60: at 0.35 the vanes only met near their
    middles and light leaked between the roots -- Joan: "hay unas plumas que
    estan como bien separadas de la otra"."""
    root, tip = Vector(root), Vector(tip)
    d = tip - root
    length = d.length
    mid = root + d * 0.5
    o = sphere(mid, 1.0, seg=8, ring=4)
    half_w = {}
    for v in o.data.vertices:
        t = v.co.z * 0.5 + 0.5              # 0 at root end, 1 at tip end
        w = width * (0.60 + 0.40 * math.sin(math.pi * min(1.0, t * 1.05)))
        w *= (1.0 - (1.0 - taper) * t)
        half_w[v.index] = max(1e-5, w)
        v.co.x *= w
        v.co.y *= thick
        v.co.z *= length * 0.5
    if row is not None:
        v0, v1 = row
        uvl = o.data.uv_layers.new(name="FeatherUV")
        for poly in o.data.polygons:
            for li, vi in zip(poly.loop_indices, poly.vertices):
                co = o.data.vertices[vi].co
                u = 0.5 + (co.x / half_w[vi]) * 0.5
                t = (co.z / (length * 0.5)) * 0.5 + 0.5
                uvl.data[li].uv = (min(1.0, max(0.0, u)),
                                   v0 + (v1 - v0) * min(1.0, max(0.0, t)))
    o.rotation_mode = 'QUATERNION'
    o.rotation_quaternion = d.normalized().to_track_quat('Z', 'Y')
    return o


# ---------------- feather atlas ----------------------------------------------
ATLAS_TONES = [("RUFOUS", RUFOUS), ("PRIM", PRIM), ("PRIM_TIP", PRIM_TIP),
               ("SECOND", SECOND), ("DORSAL", DORSAL), ("COVERT_U", COVERT_U)]
_ATLAS, _ROWS = _feather_texture.bake_atlas(ATLAS_TONES)


# ---------------- body -------------------------------------------------------
body = sphere((0.0, 0.02, 0.115), 0.085, scale=(1.0, 1.9, 0.95))
for v in body.data.vertices:
    # Taper toward the tail; a raptor torso is a teardrop, deepest at the chest.
    t = max(0.0, v.co.y / (0.085 * 1.9))
    v.co.x *= (1.0 - 0.38 * t * t)
    v.co.z *= (1.0 - 0.30 * t * t)
add_piece(body, BREAST)          # zone tones repainted per-vertex after join

# ---------------- head: brow, carved sockets, forward eyes, short hook -------
head = sphere((0.0, -0.205, 0.150), 0.052, scale=(0.94, 1.12, 0.92))
hd = head.data
for v in hd.vertices:
    if v.co.z > 0.012:
        v.co.z *= 0.82               # flat crown -- raptor skull, not a ball
# Carve the orbits BEFORE placing eyes: an eye resting on the surface reads as
# a bead (turtle lesson, paid twice).
for v in hd.vertices:
    for sx in (-1.0, 1.0):
        c = Vector((sx * 0.030, -0.038, 0.012))
        dd = (v.co - c).length
        if 1e-6 < dd < 0.026:
            v.co += (c - v.co).normalized() * 0.009 * (1.0 - dd / 0.026) ** 1.3
add_piece(head, DORSAL)
neck = sphere((0.0, -0.150, 0.140), 0.045, scale=(0.95, 1.3, 0.85),
               seg=10, ring=6)
add_piece(neck, DORSAL)

for sx in (-1.0, 1.0):
    # Supraorbital ridge: the ledge over the eye IS the fierce look.
    # Flatter and lower: at z-scale 0.34 the brows read as bear ears
    # from behind in Joan's captures.
    brow = sphere((sx * 0.029, -0.243, 0.169), 0.018, scale=(1.0, 1.15, 0.20),
                  seg=10, ring=6)
    add_piece(brow, DORSAL)
    eye = sphere((sx * 0.0295, -0.243, 0.160), 0.0135, seg=12, ring=8)
    for v in eye.data.vertices:
        v.co.y *= 0.75               # pressed into the carved socket
    add_piece(eye, EYE)

# Beak: SHORT and strongly hooked -- the ficha is explicit that a long thin
# bill reads as a songbird. Cere first, then the hooked upper mandible.
cere = sphere((0.0, -0.252, 0.146), 0.016, scale=(0.85, 0.7, 0.7))
add_piece(cere, CERE)
# Shorter and straighter: at depth 0.048 with a 16 mm droop the beak read as
# a grey banana in Joan's captures -- a buteo bill is SHORT.
bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.0125, radius2=0.0030,
                                depth=0.034, location=(0.0, -0.270, 0.142),
                                rotation=(math.radians(-95), 0, 0))
beak = bpy.context.object
for v in beak.data.vertices:
    t = max(0.0, (v.co.z / 0.024) * 0.5 + 0.5)   # 0 base, 1 tip (local Z)
    v.co.y -= 0.009 * (t ** 2)                   # the HOOK: tip curls down
add_piece(beak, BEAK)

# ---------------- tail: 12 rectrices in a fan --------------------------------
TAIL_ROOT = Vector((0.0, 0.175, 0.105))
for i in range(N_RECTRICES):
    t = i / (N_RECTRICES - 1)
    ang = math.radians(-28.0 + 56.0 * t)
    d = Vector((math.sin(ang), math.cos(ang), -0.10)).normalized()
    f = feather(TAIL_ROOT + d * 0.02, TAIL_ROOT + d * 0.24, 0.022,
                row=_ROWS["RUFOUS"])
    # Central pair rides highest; the fan overlaps outward from the middle.
    f.location.z += 0.004 * (1.0 - abs(t - 0.5) * 2.0)
    add_piece(f, RUFOUS)
    PARTS.setdefault("rectrices", []).append(f)

# Upper tail coverts: hide the rectrix roots -- roots in sight is the
# glued-on look this whole build exists to avoid.
cov = sphere((0.0, 0.19, 0.112), 0.048, scale=(1.1, 1.5, 0.55))
add_piece(cov, DORSAL)

# ---------------- wings ------------------------------------------------------
PRIM_TIPS = {"L": [], "R": []}
WING_PIECES = {"L": [], "R": []}
SHOULDER = {}
for side, sx in (("L", -1.0), ("R", 1.0)):
    _wing_start = len(PIECES)
    shoulder = Vector((sx * 0.070, -0.030, 0.150))
    wrist = Vector((sx * 0.300, -0.055,
                    0.150 + math.tan(DIHEDRAL) * (0.300 - 0.070)))

    # Arm mass (coverts over humerus+forearm): one flattened spar. The
    # secondaries hang off its trailing edge, primaries fan from its far end.
    arm = sphere(((shoulder + wrist) * 0.5), 1.0, seg=12, ring=6)
    span = (wrist - shoulder).length
    for v in arm.data.vertices:
        v.co.x *= span * 0.62
        v.co.y *= 0.048
        v.co.z *= 0.016
    arm.rotation_mode = 'QUATERNION'
    arm.rotation_quaternion = (wrist - shoulder).normalized().to_track_quat('X', 'Z')
    add_piece(arm, DORSAL)
    PARTS.setdefault("arm_" + side, []).append(arm)

    # Secondaries: hang backward off the forearm, a solid overlapping row.
    for i in range(N_SECONDARIES):
        t = i / (N_SECONDARIES - 1)
        root = shoulder.lerp(wrist, 0.18 + 0.78 * t)
        root = Vector((root.x, root.y + 0.030, root.z - 0.004))
        d = Vector((sx * 0.10, 1.0, -0.06)).normalized()
        ln = 0.195 - 0.025 * abs(t - 0.5) * 2.0
        f = feather(root, root + d * ln, 0.030, row=_ROWS["SECOND"])
        f.rotation_mode = 'QUATERNION'
        roll = f.rotation_quaternion.to_euler()
        roll.rotate_axis('Z', math.radians(14.0) * (1 if sx > 0 else -1))
        f.rotation_euler = roll
        f.rotation_mode = 'XYZ'
        add_piece(f, SECOND)

    # Primaries: fan from the wrist. The outer N_FINGERS are emarginated --
    # narrower tips with real gaps: the slotted fingertips ARE the buteo
    # silhouette, and they must exist as geometry, not as notches in a plane.
    for i in range(N_PRIMARIES):
        t = i / (N_PRIMARIES - 1)
        # t**1.35 clusters the inner primaries against the secondaries
        # and spends the spread on the fingertips -- gaps belong to the
        # emarginated tips ONLY (Joan: plumas separadas entre si).
        sweep = math.radians(-8.0 + 66.0 * (t ** 1.35))       # forward-out -> back
        d = Vector((sx * math.cos(sweep), math.sin(sweep),
                    math.sin(DIHEDRAL) * 0.6)).normalized()
        ln = 0.235 + 0.105 * math.sin(math.pi * min(1.0, t * 0.9))
        finger = i >= N_PRIMARIES - N_FINGERS
        f = feather(wrist + d * 0.015, wrist + d * (0.015 + ln),
                    0.034 if not finger else 0.024,
                    taper=1.0 if not finger else 0.45,
                    row=_ROWS["PRIM_TIP" if finger else "PRIM"])
        tone = PRIM_TIP if finger else PRIM
        add_piece(f, tone)
        PRIM_TIPS[side].append(wrist + d * (0.015 + ln))

    # Underwing covert sheet: pale, and it carries the PATAGIAL mark -- the
    # dark leading-edge bar that identifies a red-tail from below.
    uc = sphere(((shoulder + wrist) * 0.5 + Vector((0, 0.012, -0.014))), 1.0,
                seg=10, ring=6)
    for v in uc.data.vertices:
        v.co.x *= span * 0.58
        v.co.y *= 0.042
        v.co.z *= 0.010
    uc.rotation_mode = 'QUATERNION'
    uc.rotation_quaternion = (wrist - shoulder).normalized().to_track_quat('X', 'Z')
    add_piece(uc, COVERT_U)
    PARTS.setdefault("ucov_" + side, []).append(uc)
    WING_PIECES[side] = list(range(_wing_start, len(PIECES)))
    SHOULDER[side] = shoulder.copy()

# ---------------- legs and talons -------------------------------------------
# Tucked under the tail in flight, but PRESENT and hanging low enough to read
# from below: no talons was the old build's loudest failure.
CLAWS = 0
LEG_PIECES = {}
HIP = {}
for sx in (-1.0, 1.0):
    _leg_start = len(PIECES)
    _leg_side = "L" if sx < 0 else "R"
    HIP[_leg_side] = Vector((sx * 0.040, 0.085, 0.050))
    thigh = sphere((sx * 0.040, 0.085, 0.050), 0.027, scale=(0.9, 1.2, 0.85))
    add_piece(thigh, BREAST)
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.010, radius2=0.007,
                                    depth=0.052,
                                    location=(sx * 0.044, 0.105, 0.020),
                                    rotation=(math.radians(25), 0, 0))
    tarsus = bpy.context.object
    add_piece(tarsus, LEG)
    # Four toes: three forward, one back (anisodactyl), each ending in a claw.
    for k, ang in enumerate((-24.0, 0.0, 24.0, 180.0)):
        a = math.radians(ang)
        d = Vector((math.sin(a) * 0.6 * (1 if sx > 0 else -1) if abs(ang) < 90
                    else math.sin(a), -math.cos(a), -0.25)).normalized()
        base = Vector((sx * 0.046, 0.118, 0.000))
        ln = 0.030 if abs(ang) < 90 else 0.020
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.0052,
                                        radius2=0.0028, depth=ln,
                                        location=base + d * (ln * 0.5))
        toe = bpy.context.object
        toe.rotation_mode = 'QUATERNION'
        toe.rotation_quaternion = d.to_track_quat('Z', 'Y')
        add_piece(toe, LEG)
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.0034,
                                        radius2=0.0008, depth=0.020,
                                        location=base + d * ln
                                        + Vector((0, 0, -0.006)))
        claw = bpy.context.object
        cd = (d * 0.5 + Vector((0, 0, -1.0))).normalized()
        claw.rotation_mode = 'QUATERNION'
        claw.rotation_quaternion = cd.to_track_quat('Z', 'Y')
        add_piece(claw, TALON)
        CLAWS += 1
    LEG_PIECES[_leg_side] = list(range(_leg_start, len(PIECES)))

# ---------------- join, paint, gates ----------------------------------------
base_obj, base_tone = PIECES[0]
ranges = []
offset = 0
for obj, tone in PIECES:
    n = len(obj.data.vertices)
    ranges.append((offset, offset + n, tone, obj.name))
    offset += n
for obj, _tone in PIECES[1:]:
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    base_obj.select_set(True)
    bpy.context.view_layer.objects.active = base_obj
    bpy.ops.object.join()
hawk = base_obj
hawk.name = "hawk"
me = hawk.data

# FLOAT_COLOR, corner domain -- BYTE_COLOR loses ~12x value on the bmesh
# write path (golem_guardian lesson) and this project does not use it again.
col = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
vert_tone = {}
for lo, hi, tone, _name in ranges:
    for vi in range(lo, hi):
        vert_tone[vi] = tone

# Body zone repaint: dorsal dark above, cream below, streak band across the
# belly, patagial bar on the underwing covert leading edge.
body_lo, body_hi = ranges[0][0], ranges[0][1]
for vi in range(body_lo, body_hi):
    co = me.vertices[vi].co
    # BODY-LOCAL space: world = local + (0, 0.02, 0.115).
    if co.z > 0.030:
        vert_tone[vi] = DORSAL
    elif 0.02 < co.y < 0.13 and co.z < -0.015:
        vert_tone[vi] = BAND
for lo, hi, tone, name in ranges:
    if tone is COVERT_U:
        for vi in range(lo, hi):
            if me.vertices[vi].co.y < -0.075:     # leading edge (body-local)
                vert_tone[vi] = PATAGIAL

for poly in me.polygons:
    for li, vi in zip(poly.loop_indices, poly.vertices):
        r, g, b = vert_tone.get(vi, BREAST)
        col.data[li].color = (r, g, b, 1.0)

# ---- GATES: each one aimed at a failure this asset has already had ----------
xs = [v.co.x for v in me.vertices]
span = max(xs) - min(xs)
print("[hawk] envergadura %.3f m (objetivo 1.18-1.28)" % span)
if not (1.18 <= span <= 1.28):
    raise SystemExit("[hawk] envergadura fuera de banda")

n_prim = sum(1 for _lo, _hi, t, _n in ranges if t in (PRIM, PRIM_TIP))
n_sec = sum(1 for _lo, _hi, t, _n in ranges if t is SECOND)
n_rect = sum(1 for _lo, _hi, t, _n in ranges if t is RUFOUS)
print("[hawk] plumas: %d primarias, %d secundarias, %d rectrices, %d garras"
      % (n_prim, n_sec, n_rect, CLAWS))
if n_prim != 2 * N_PRIMARIES or n_sec != 2 * N_SECONDARIES \
        or n_rect != N_RECTRICES or CLAWS != 8:
    raise SystemExit("[hawk] conteo de plumas/garras no cierra")

# The slots between the outer primaries must be REAL GAPS, or the wingtip is a
# scalloped plane again -- the exact failure being replaced.
for side in ("L", "R"):
    tips = PRIM_TIPS[side][-N_FINGERS:]
    gaps = [(tips[k + 1] - tips[k]).length for k in range(len(tips) - 1)]
    print("[hawk] ranuras ala %s: %s mm"
          % (side, ["%.0f" % (g * 1000) for g in gaps]))
    if min(gaps) < 0.015:
        raise SystemExit("[hawk] las puntas emarginadas no dejan ranura")

# Forward-facing eyes: prey birds look sideways, raptors look AT you.
eye_centers = []
for lo, hi, tone, _name in ranges:
    if tone is EYE:
        c = Vector((0, 0, 0))
        for vi in range(lo, hi):
            c += me.vertices[vi].co
        eye_centers.append(c / max(1, hi - lo))
head_c = Vector((0.0, -0.225, 0.035))   # body-local, not world
for c in eye_centers:
    fwd_dot = (c - head_c).normalized().dot(FWD)
    if fwd_dot < 0.45:
        raise SystemExit("[hawk] ojo mirando de costado (dot %.2f)" % fwd_dot)
print("[hawk] ojos frontales: dot %.2f y %.2f" %
      tuple((c - head_c).normalized().dot(FWD) for c in eye_centers))

# Patagial contrast, measured off the written layer, not off intent.
pat = [vert_tone[vi] for lo, hi, t, _n in ranges if t is COVERT_U
       for vi in range(lo, hi) if vert_tone[vi] is PATAGIAL]
if not pat:
    raise SystemExit("[hawk] la marca patagial no pinto ningun vertice")
print("[hawk] patagial: %d verts oscuros bajo el ala" % len(pat))

# ---------------- material + export ------------------------------------------
# ---------------- shape keys + clips (motion/_motion_spec.md) ---------------
# The TRAJECTORY belongs to the AI (hawk.gd circles and dives); the clips
# animate the BODY only -- flap, tuck, talons, torso pitch. A clip that
# translated the bird would fight the state machine, so loc_x/loc_y are
# forbidden here by contract.
BODY_OFF = Vector((0.0, 0.02, 0.115))     # world -> body-local offset


def add_key(name):
    # from_mix=False and value=0.0, ALWAYS: the default from_mix=True plus
    # value=1.0 silently sums every prior key into the new one (turtle
    # 2026-07-18, cost hours).
    k = hawk.shape_key_add(name=name, from_mix=False)
    k.value = 0.0
    return k


add_key("Basis")
base_co = [v.co.copy() for v in me.vertices]
piece_range = {idx: (ranges[idx][0], ranges[idx][1])
               for idx in range(len(ranges))}


def wing_verts(side):
    for idx in WING_PIECES[side]:
        lo, hi = piece_range[idx]
        for vi in range(lo, hi):
            yield vi


def leg_verts(side):
    for idx in LEG_PIECES[side]:
        lo, hi = piece_range[idx]
        for vi in range(lo, hi):
            yield vi


def _rot_y(v, pivot, ang):
    r = v - pivot
    ca, sa = math.cos(ang), math.sin(ang)
    return pivot + Vector((r.x * ca + r.z * sa, r.y, -r.x * sa + r.z * ca))


def _rot_x(v, pivot, ang):
    r = v - pivot
    ca, sa = math.cos(ang), math.sin(ang)
    return pivot + Vector((r.x, r.y * ca - r.z * sa, r.y * sa + r.z * ca))


def _rot_z(v, pivot, ang):
    r = v - pivot
    ca, sa = math.cos(ang), math.sin(ang)
    return pivot + Vector((r.x * ca - r.y * sa, r.x * sa + r.y * ca, r.z))


# Wing flap: rotation about the fore-aft axis through the SHOULDER, so the
# tip travels the most and the root barely moves -- the turtle's leg lesson.
for name, deg in (("flap_up", 28.0), ("flap_dn", -22.0)):
    sk = add_key(name)
    for side, sgn in (("L", -1.0), ("R", 1.0)):
        piv = SHOULDER[side] - BODY_OFF
        ang = math.radians(deg) * (-sgn)
        for vi in wing_verts(side):
            sk.data[vi].co = _rot_y(base_co[vi], piv, ang)

# Tuck: wings sweep BACK about the shoulder and fold toward it. Death and the
# dive both use it -- "caer con las alas encogidas" is this key at 1.0.
sk = add_key("tuck")
for side, sgn in (("L", -1.0), ("R", 1.0)):
    piv = SHOULDER[side] - BODY_OFF
    sweep = math.radians(58.0) * (1.0 if side == "L" else -1.0)
    for vi in wing_verts(side):
        v = _rot_z(base_co[vi], piv, sweep)
        v = piv + (v - piv) * 0.55            # fold: mass pulls into the body
        v.z -= (base_co[vi] - piv).length * 0.10   # and sags, no muscle tone
        sk.data[vi].co = v

# Talons: the legs swing FORWARD past the head line -- a raptor strikes feet
# first. Rotation about the hip, plus a reach.
sk = add_key("talons")
for side in ("L", "R"):
    piv = HIP[side] - BODY_OFF
    for vi in leg_verts(side):
        v = _rot_x(base_co[vi], piv, math.radians(-115.0))
        v.y -= 0.030
        sk.data[vi].co = v

ALL_KEYS = ("flap_up", "flap_dn", "tuck", "talons")
kb = me.shape_keys.key_blocks
FPS = 24
scene.render.fps = FPS


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def anim_idle(t):
    # Soaring: NO flap. Micro-corrections only -- rot_y sway and an 8 mm bob.
    return {"rot_y": math.radians(2.5) * math.sin(2 * math.pi * t),
            "loc_z": 0.008 * math.sin(2 * math.pi * t + math.pi / 2)}


def anim_move(t):
    # One flap per second, ASYMMETRIC: the downstroke is the power stroke and
    # takes 40% of the cycle; the upstroke recovers in 60%.
    u = t % 1.0
    if u < 0.40:
        f = math.sin(math.pi * (u / 0.40))          # 0 -> dn -> 0
        flap_dn, flap_up = f, 0.0
    else:
        f = math.sin(math.pi * ((u - 0.40) / 0.60))
        flap_dn, flap_up = 0.0, f
    return {"flap_dn": flap_dn, "flap_up": flap_up,
            "rot_x": math.radians(3.0) * math.sin(2 * math.pi * u),
            "loc_z": 0.015 * flap_dn}               # lift comes from the downstroke


def anim_attack(t):
    v = {}
    if t < 0.30:                       # anticipation: tuck + nose down
        u = t / 0.30
        v["tuck"] = 0.85 * u
        v["rot_x"] = math.radians(-45.0) * u
    elif t < 0.55:                     # the drop; talons launch at 45%
        v["tuck"] = 0.85
        v["rot_x"] = math.radians(-45.0)
        if t > 0.45:
            v["talons"] = lerp(0.0, 1.0, (t - 0.45) / 0.10)
    elif t < 0.75:                     # brake: wings snap open
        u = (t - 0.55) / 0.20
        v["tuck"] = lerp(0.85, 0.0, u * 2.0)
        v["talons"] = 1.0
        v["rot_x"] = math.radians(-45.0) * (1.0 - u)
        v["flap_dn"] = math.sin(math.pi * u)        # one hard brake-stroke
    else:                              # recover
        u = (t - 0.75) / 0.25
        v["talons"] = lerp(1.0, 0.0, u)
        v["flap_up"] = math.sin(math.pi * u) * 0.6
    return v


def anim_hit(t):
    if t < 0.4:
        u = t / 0.4
        return {"tuck": 0.4 * u, "rot_y": math.radians(8.0) * u}
    u = (t - 0.4) / 0.6
    return {"tuck": 0.4 * (1 - u), "rot_y": math.radians(8.0) * (1 - u)}


def anim_death(t):
    # "Literal caer con las alas encogidas": tuck to 1.0 fast, tumble, drop.
    # The clip sells the collapse; the game's gravity does the actual fall.
    v = {"tuck": lerp(0.0, 1.0, t / 0.20), "talons": 0.3}
    v["rot_x"] = math.radians(-120.0) * min(1.0, t / 0.8)
    v["rot_y"] = math.radians(40.0) * t
    v["loc_z"] = -0.30 * (t ** 2)
    return v


ANIMS = {"idle-loop": (96, anim_idle), "move-loop": (48, anim_move),
         "attack": (40, anim_attack), "hit": (14, anim_hit),
         "death": (40, anim_death)}

# --- spec asserts BEFORE writing keys: measure the samplers, not the intent --
_idle_flap = max(max(anim_idle(i / 95.0).get("flap_dn", 0),
                     anim_idle(i / 95.0).get("flap_up", 0)) for i in range(96))
if _idle_flap > 0.001:
    raise SystemExit("[hawk] el idle aletea (%.3f) -- el spec exige planeo" % _idle_flap)
_dn_frames = sum(1 for i in range(48) if anim_move(i / 48.0).get("flap_dn", 0) > 0.01)
_duty = _dn_frames / 48.0
print("[hawk] batida: bajada %.0f%% del ciclo (spec 40 +- 5)" % (_duty * 100))
if not (0.33 <= _duty <= 0.47):
    raise SystemExit("[hawk] la asimetria de batida esta fuera del spec")
_strike = anim_attack(0.54)
if _strike.get("talons", 0) < 0.8 or _strike.get("tuck", 0) < 0.5:
    raise SystemExit("[hawk] en el strike las garras no llegan con el pliegue puesto")
_dead = anim_death(1.0)
if _dead["tuck"] < 0.99:
    raise SystemExit("[hawk] la muerte no termina con las alas encogidas")
print("[hawk] spec de movimiento: 4/4 asserts OK")

sk_ad = me.shape_keys.animation_data_create()
obj_ad = hawk.animation_data_create()
for name, (frames, sampler) in ANIMS.items():
    act_sk = bpy.data.actions.new(name + "_sk")
    sk_ad.action = act_sk
    act_obj = bpy.data.actions.new(name + "_obj")
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        vals = sampler(t)
        for k in ALL_KEYS:
            kb[k].value = vals.get(k, 0.0)
            kb[k].keyframe_insert("value", frame=f)
        hawk.rotation_euler = (vals.get("rot_x", 0.0), vals.get("rot_y", 0.0), 0.0)
        hawk.keyframe_insert("rotation_euler", frame=f)
        hawk.location.z = vals.get("loc_z", 0.0)
        hawk.keyframe_insert("location", frame=f)
    for holder, act in ((sk_ad, act_sk), (obj_ad, act_obj)):
        holder.action = None
        tr = holder.nla_tracks.new()
        tr.name = name
        strip = tr.strips.new(name, 1, act)
        strip.name = name
        tr.mute = True                # muted while building; unmuted pre-export
    print("[hawk] clip %s listo (%d frames)" % (name, frames))

# Rest pose re-asserted LAST -- NLA tracks evaluate at the current frame the
# moment actions detach (golem_guardian 2026-07-19).
for k in ALL_KEYS:
    kb[k].value = 0.0
hawk.rotation_euler = (0.0, 0.0, 0.0)
hawk.location = Vector((0.0, 0.0, 0.0))
scene.frame_set(1)
for holder in (sk_ad, obj_ad):
    for tr in holder.nla_tracks:
        tr.mute = False

# Two materials, both export-proven patterns and nothing else: a plain image
# for the feathers (tint baked into its atlas row), vertex colour for the
# body. No mixing nodes -- this session measured what the exporter does to a
# graph it does not recognise: it ships white.
mat_f = bpy.data.materials.new("hawk_feathers")
mat_f.use_nodes = True
ntf = mat_f.node_tree
bsf = ntf.nodes["Principled BSDF"]
bsf.inputs["Roughness"].default_value = 0.85
tex = ntf.nodes.new("ShaderNodeTexImage")
tex.image = _feather_texture.to_blender_image(_ATLAS)
ntf.links.new(tex.outputs["Color"], bsf.inputs["Base Color"])
me.materials.append(mat_f)

mat_b = bpy.data.materials.new("hawk_body")
mat_b.use_nodes = True
ntb = mat_b.node_tree
bsb = ntb.nodes["Principled BSDF"]
bsb.inputs["Roughness"].default_value = 0.85
attr = ntb.nodes.new("ShaderNodeVertexColor")
attr.layer_name = "Col"
ntb.links.new(attr.outputs["Color"], bsb.inputs["Base Color"])
me.materials.append(mat_b)

# Feather polygons carry a FeatherUV; everything else is body.
uvl = me.uv_layers.get("FeatherUV")
for poly in me.polygons:
    has_uv = uvl is not None and any(
        uvl.data[li].uv.length_squared > 1e-9 for li in poly.loop_indices)
    poly.material_index = 0 if has_uv else 1

bpy.ops.object.select_all(action='DESELECT')
hawk.select_set(True)
bpy.context.view_layer.objects.active = hawk
bpy.ops.object.shade_smooth()

bpy.ops.wm.save_as_mainfile(
    filepath=os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "hawk_wip.blend"))
out = _deploy.export_glb("hawk/hawk.glb", use_selection=False,
                         export_animations=True, export_morph=True,
                         export_animation_mode='NLA_TRACKS')

# Post-export probe -- the silent-export family has five cases in 24 hours, so
# the builder verifies its own GLB instead of trusting the render.
with open(out, "rb") as fh:
    fh.read(12)
    clen, _ct = struct.unpack("<II", fh.read(8))
    g = json.loads(fh.read(clen))
prims = [p for m in g.get("meshes", []) for p in m.get("primitives", [])]
if not any("COLOR_0" in p.get("attributes", {}) for p in prims):
    raise SystemExit("[hawk] el GLB salio SIN COLOR_0 -- iba a dibujarse blanco")
anims = sorted(a.get("name", "?") for a in g.get("animations", []))
print("[hawk] clips en el GLB:", ", ".join(anims))
if len(anims) != 5:
    raise SystemExit("[hawk] el GLB tiene %d clips, van 5" % len(anims))
tris = sum(len(me.polygons) for _ in [0]) and len(me.loop_triangles)
me.calc_loop_triangles()
print("[hawk] GLB verificado: COLOR_0 presente, %d tris, %d piezas"
      % (len(me.loop_triangles), len(ranges)))
if len(me.loop_triangles) > 6000:
    raise SystemExit("[hawk] presupuesto excedido: %d tris (tope 6000, se ve "
                     "a 10-14 m)" % len(me.loop_triangles))
print("[hawk] DONE")
