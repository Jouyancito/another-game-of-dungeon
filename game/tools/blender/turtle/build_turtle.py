# build_turtle.py — pond/water-edge turtle: heavy plod, "flinch IS hiding" retract, fast bite.
# Mirrors build_slime.py structure: single joined mesh, shape-key vocabulary per body part,
# object-transform (rotation/location) for whole-body weight, NLA export, ficha render rig.
#   idle-loop   slow breathing + head looking side to side
#   move-loop   slow heavy plod — body rocks as diagonal leg pairs step
#   attack      long anticipation, fast forward bite snap
#   hit         head + legs retract into shell, then peek back out
#   death       legs splay, shell settles flat, head droops
# "-loop" suffix => Godot glTF import auto-loops. Export mode: NLA tracks.
# Run: blender -b --python build_turtle.py
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import _carapace          # noqa: E402
import _carapace_texture  # noqa: E402
import _skin_texture      # noqa: E402

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- geometry: single mesh, built part by part, joins recorded as index ranges ----------
R = 0.25          # shell base radius -> ~0.5m dome width

# Scale is a DECISION, written down so nobody "corrects" it later in either
# direction. A real pond terrapin's carapace is 0.20-0.28 m; this mob is ~3.4x
# that, which puts its shell at the player's knee. Undeclared, it is
# indistinguishable from an error -- which is exactly how tree_pack ended up at
# bush scale for weeks (_references/turtle/_synthesis.md 3).
MOB_SCALE = 3.4

# Allometry, measured on real carapaces (MDPI Animals 2024): small specimens
# are proportionally HIGHER-domed, large ones flatter. At 3.4x this shell must
# therefore be FLATTER than a real turtle's, not rounder. Enlarging a small
# turtle's dome is what makes a model read as a toy.
#   0.62 -> height/length 0.360  (original, out of range)
#   0.52 -> height/length 0.330  (better, still out)
#   0.46 -> height/length ~0.30  (target band 0.28-0.32)
# Note the height being measured is the WHOLE body, not just the dome, so the
# dome factor and the ratio do not move one-for-one.
DOME_FLATTEN = 0.46

# Carapace width as a fraction of its length. A terrapin's shell is markedly
# longer than wide; a sphere flattened only on Z still reads as a dome from
# above -- which is exactly what the top-down view showed on 2026-08-24.
SHELL_WIDTH_RATIO = 0.78
PARTS = {}         # name -> (start_idx, end_idx) in the final joined mesh


def finish_part(obj):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def join_part(base, part):
    bpy.ops.object.select_all(action='DESELECT')
    part.select_set(True)
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    start = len(base.data.vertices)
    bpy.ops.object.join()
    end = len(base.data.vertices)
    return start, end


# ---------- shell: built OUT OF ITS SCUTES (see _carapace.py) ----------
# Until 2026-08-24 this was a UV sphere with the plates displaced and painted
# on top of it. That has a ceiling, and the ceiling was measured: the sphere's
# edge flow does not follow the plates, so every boundary cut polygons in half
# (visible staircase) and every growth ring shared the sphere's centre, which
# rendered as a radial sun rather than thirteen scutes. Relief reached 2.2 mm
# on a 520 mm shell -- invisible in silhouette. The pattern was colour only.
#
# `_carapace` builds one continuous mesh whose GRID LINES ARE the plate
# boundaries, so the borders are real edges, neighbours share them, and the
# rings are concentric about each plate's own outline.
CARAPACE = _carapace.CarapaceSpec(
    length=R * 2.0 * 1.06,          # matches the old shell's footprint
    width_ratio=SHELL_WIDTH_RATIO,
    height_ratio=0.30,              # ficha: alto/largo 0.28-0.32 by allometry
    skirt_drop=0.045,               # turn down to meet the plastron
)

_bm = bmesh.new()
_uv = _bm.loops.layers.uv.new("UVMap")
_stats = _carapace.build(_bm, CARAPACE, uv_layer=_uv)
me = bpy.data.meshes.new("turtle")
bmesh.ops.recalc_face_normals(_bm, faces=_bm.faces)
_bm.to_mesh(me)
_bm.free()
turtle = bpy.data.objects.new("turtle", me)
bpy.context.scene.collection.objects.link(turtle)
bpy.context.view_layer.objects.active = turtle
for p in me.polygons:
    p.use_smooth = True

PARTS["shell"] = (0, len(me.vertices))
SHELL_ZMIN = min(v.co.z for v in me.vertices)
SHELL_ZMAX = max(v.co.z for v in me.vertices)

# Visibility assert (CREATION_PROTOCOL 2d): relief below the shading noise
# floor is relief that does not exist. Measure what the build ACTUALLY made,
# against the bare dome, rather than the constant that was asked for.
_dev = [v.co.z - _carapace.dome_z(CARAPACE,
                                  v.co.x / CARAPACE.half_wid,
                                  v.co.y / CARAPACE.half_len)
        for v in me.vertices if v.co.z > -0.001]
_dz = max(_dev) - min(_dev) if _dev else 0.0
print("[turtle] carapacho por escudos: %d placas, %d caras, relieve %.1f mm"
      % (_stats["scutes"], _stats["faces"], _dz * 1000))
if _stats["scutes"] != 37:
    raise SystemExit("[turtle] la gramatica de escudos no cierra: %d placas "
                     "(van 1 nucal + 4 vertebrales + 8 pleurales + 24 "
                     "marginales)" % _stats["scutes"])
if _dz < 0.008:
    raise SystemExit("[turtle] el relieve de escudos es plano -- no capta luz")

# ---------- plastron + bony bridges ----------
# What was here: a cylinder of radius R*1.10, wider than the carapace skirt and
# centred on z = -0.030 -- which is exactly where the four shoulder joints sit.
# So it crossed every limb as a cream band, and from below it was one smooth
# tan disc with no anatomy on it at all. Joan orbited the mob in Godot and
# found both in one look; neither was visible from any angle this repo's own
# judgement set rendered, which is why `bajo` is now in that set.
#
# What a plastron actually is (_references/turtle/_synthesis.md 2b): a SEPARATE
# bony plate, NARROWER than the carapace, joined to it by lateral BRIDGES --
# and the gaps left fore and aft of those bridges are the limb openings. Build
# it that way and the limbs stop being crossed by anything: they come out
# through the holes the anatomy already provides. The ficha lists the bridge
# under "que capturar" and it had never been built.
PLASTRON_HX = 0.150        # half width -- inside the leg anchors at +-0.135
PLASTRON_HY = 0.215        # half length
PLASTRON_Z = -0.028        # its rim, where it meets the bridges
PLASTRON_BELLY = 0.030     # how far the middle bulges DOWN below that rim
PLASTRON_N = 22

_bmp = bmesh.new()
_pg = {}
for _j in range(PLASTRON_N + 1):
    for _i in range(PLASTRON_N + 1):
        _u = (_i / PLASTRON_N) * 2.0 - 1.0
        _v = (_j / PLASTRON_N) * 2.0 - 1.0
        _du, _dv = _carapace.square_to_disc(_u, _v)
        _r2 = min(1.0, _du * _du + _dv * _dv)
        # Convex DOWNWARD. A plastron is not a lid: it is slightly bulged, and
        # that bulge is what catches a highlight instead of reading as a disc.
        _z = PLASTRON_Z - PLASTRON_BELLY * (1.0 - _r2)
        # The 6 scute PAIRS: gular, humeral, pectoral, abdominal, femoral,
        # anal, split by a midline suture. Seams sink INTO the plate, so they
        # hold a shadow line the way the carapace seams do.
        _uy = _dv * 0.5 + 0.5
        _cross = abs(math.sin(6.0 * math.pi * min(0.999, max(0.0, _uy))))
        _mid = min(1.0, abs(_du) / 0.16)
        _d = min(_cross, _mid)
        if _d < 0.30:
            _z += 0.0075 * (1.0 - _d / 0.30)
        _pg[(_i, _j)] = _bmp.verts.new((_du * PLASTRON_HX, _dv * PLASTRON_HY, _z))
for _j in range(PLASTRON_N):
    for _i in range(PLASTRON_N):
        try:
            _bmp.faces.new([_pg[(_i, _j)], _pg[(_i + 1, _j)],
                            _pg[(_i + 1, _j + 1)], _pg[(_i, _j + 1)]])
        except ValueError:
            pass

# The two bridges. They sit at mid-body, BETWEEN the fore and hind limbs, and
# they are what actually holds the shell together on a real chelonian.
for _sx in (-1.0, 1.0):
    _x0 = _sx * PLASTRON_HX * 0.92
    _x1 = _sx * (CARAPACE.half_wid * 0.98)
    _ring = []
    for _t in (0.0, 1.0):
        for _yy in (-0.062, 0.062):
            _ring.append((_x0 + (_x1 - _x0) * _t, _yy,
                          PLASTRON_Z + 0.016 * _t))
    _v00 = _bmp.verts.new(_ring[0]); _v01 = _bmp.verts.new(_ring[1])
    _v10 = _bmp.verts.new(_ring[2]); _v11 = _bmp.verts.new(_ring[3])
    _lo = [_bmp.verts.new((v.co.x, v.co.y, v.co.z - 0.030))
           for v in (_v00, _v01, _v11, _v10)]
    _top = [_v00, _v01, _v11, _v10]
    try:
        _bmp.faces.new(_top)
        _bmp.faces.new(list(reversed(_lo)))
    except ValueError:
        pass
    for _k in range(4):
        _k2 = (_k + 1) % 4
        try:
            _bmp.faces.new([_top[_k], _top[_k2], _lo[_k2], _lo[_k]])
        except ValueError:
            pass

bmesh.ops.recalc_face_normals(_bmp, faces=_bmp.faces)
_bme = bpy.data.meshes.new("belly")
_bmp.to_mesh(_bme)
_bmp.free()
belly = bpy.data.objects.new("belly", _bme)
bpy.context.scene.collection.objects.link(belly)
for p in _bme.polygons:
    p.use_smooth = True
finish_part(belly)
start, end = join_part(turtle, belly)
PARTS["belly"] = (start, end)

# GATE: the plastron must not reach the limb anchors, or it crosses them again.
_ply = 0.135
if PLASTRON_HX >= _ply + 0.055:
    raise SystemExit("[turtle] el plastron llega hasta el hombro (%.3f contra "
                     "%.3f) -- va a cruzar las patas otra vez"
                     % (PLASTRON_HX, _ply))
print("[turtle] plastron %.0fx%.0f mm, panza %.0f mm, 2 puentes; hombros a "
      "%.0f mm -- libre" % (PLASTRON_HX * 2000, PLASTRON_HY * 2000,
                            PLASTRON_BELLY * 1000, _ply * 1000))

# ---------- neck (short, angled up-forward; front = -Y) ----------
bpy.ops.mesh.primitive_cone_add(radius1=0.040, radius2=0.033, depth=0.13,
                                 location=(0, -0.32, 0.02), rotation=(math.radians(80), 0, 0))
neck = bpy.context.object
neck.name = "neck"
for p in neck.data.polygons:
    p.use_smooth = True
finish_part(neck)
start, end = join_part(turtle, neck)
PARTS["neck"] = (start, end)

# ---------- head ----------
# A turtle head is a WEDGE with an angled preorbital snout and a marked jaw
# line -- not a sphere. Joan: "la cabeza no es solamente un círculo". Cranial
# morphology of testudines describes the snout region as acutely angled; the
# skull narrows toward the nose and the mouth is a horizontal cut, not a dimple.
bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.066, location=(0, -0.445, 0.055))
head = bpy.context.object
head.name = "head"
hd = head.data
HEAD_C = 0.066
for v in hd.vertices:
    # t: 0 at the back of the skull, 1 at the tip of the snout (-Y is forward)
    t = max(0.0, min(1.0, (-v.co.y / HEAD_C) * 0.5 + 0.5))
    v.co.y *= 1.55                       # longer than it is wide
    # Taper toward the snout: the wedge. A sphere scaled on one axis stays an
    # egg -- the narrowing has to depend on how far forward the vertex is.
    narrow = 1.0 - 0.42 * (t ** 1.6)
    v.co.x *= narrow
    v.co.z *= 0.78 * (1.0 - 0.22 * (t ** 2))
    # Flat crown, so the skull reads as a plate rather than a ball.
    if v.co.z > 0:
        v.co.z *= 0.86
    # Jaw line: everything below the mid-plane pulls in and flattens, which
    # leaves a visible horizontal edge where the mouth sits.
    if v.co.z < -0.004:
        v.co.z *= 0.72
        v.co.x *= 0.93
# SOCKETS. The eye spheres were pressed in on Y only, so from three-quarter
# and from the front they read as two black mushrooms stuck on the crown --
# Joan's Godot screenshots show it plainly. A socket is a hollow in the SKULL,
# so it has to be carved out of the head, not faked by shrinking the bead.
# Same lesson the eyeball/eyelid pass paid for on the warrior.
for v in hd.vertices:
    for _sx in (-1.0, 1.0):
        _c = Vector((_sx * 0.0455, -0.002, 0.024))
        _d = (v.co - _c).length
        if _d < 0.028 and _d > 1e-6:
            _w = 1.0 - _d / 0.028
            v.co += (_c - v.co).normalized() * 0.012 * (_w ** 1.3)

for p in hd.polygons:
    p.use_smooth = True
finish_part(head)
start, end = join_part(turtle, head)
PARTS["head"] = (start, end)

# ---------- eyes ----------
# The single cheapest thing that turns a shape into an animal, and the model
# did not have them. Set INTO the skull rather than stuck on it: a sphere
# sitting proud of the head reads as a bead. Slightly forward and high, where
# a turtle's orbits actually sit.
EYE_R = 0.0126
for _side in (-1.0, 1.0):
    # y: back from the snout tip (tip is around -0.545 after the wedge taper)
    # z: high on the skull, above the jaw line
    # x: wide -- a turtle looks sideways, its eyes are not forward-facing
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=EYE_R,
                                         location=(_side * 0.0455, -0.4432, 0.0706))
    eye = bpy.context.object
    _eye_name = "eye_%s" % ("L" if _side < 0 else "R")
    eye.name = _eye_name
    for v in eye.data.vertices:
        v.co.y *= 0.72                    # pressed into the socket
    for p in eye.data.polygons:
        p.use_smooth = True
    finish_part(eye)
    start, end = join_part(turtle, eye)
    PARTS[_eye_name] = (start, end)

    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.0205,
                                         location=(_side * 0.0452, -0.4415, 0.0790))
    brow = bpy.context.object
    _brow_name = "brow_%s" % ("L" if _side < 0 else "R")
    brow.name = _brow_name
    for v in brow.data.vertices:
        v.co.z *= 0.26                    # a ridge, not a ball -- and it was
                                          # still a ball at 0.42, which is
                                          # what gave the eye its stalk
        v.co.y *= 0.85
    for p in brow.data.polygons:
        p.use_smooth = True
    finish_part(brow)
    start, end = join_part(turtle, brow)
    PARTS[_brow_name] = (start, end)

for _side in (-1.0, 1.0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=0.0052,
                                         location=(_side * 0.0105, -0.5385, 0.062))
    nos = bpy.context.object
    _nos_name = "nostril_%s" % ("L" if _side < 0 else "R")
    nos.name = _nos_name
    finish_part(nos)
    start, end = join_part(turtle, nos)
    PARTS[_nos_name] = (start, end)

NECK_BASE_Y = -0.27
HEAD_TIP_Y = -0.51

# ---------- legs: SPRAWLING, two segments, one quadrant each ----------
# The previous build had four identical cones on the same base rotation, all
# pointing roughly the same way. Joan, looking at the model: "las patas están
# todas en la misma dirección... una tortuga tiene las cuatro patas en
# direcciones opuestas, como puntos cardinales". He was describing sprawling
# posture, which is a measured fact:
#
#   "the movement of the humerus occurs predominantly in the HORIZONTAL plane
#    while the movements of the distal limb occur predominantly in the VERTICAL
#    plane, hence a typical sprawled posture"   -- J. Exp. Biol.
#
# So a leg is TWO segments, not one cone: an upper bone that leaves the shell
# sideways and near-level, and a lower one that drops to the ground. The elbow
# between them is what makes each leg point into its own quadrant.
# Structural parameters: _references/turtle/_synthesis.md, ESTRUCTURA.
# The elbow has to clear the shell's overhang or the sprawl is invisible.
# Measured on the first attempt: shoulder at 0.148 + humerus 0.105 put the
# elbow at ~0.25, INSIDE a shell of radius 0.295 -- the horizontal humerus was
# there in the data and hidden under the carapace. A structural parameter that
# cannot be seen is a structural parameter that is not there.
UPPER_LEN = 0.115        # humerus / femur -- travels outward, near-horizontal
                         # yaw 40 deg keeps only cos(40)=0.77 of it as lateral
                         # reach, so this has to be longer than it reads
LOWER_LEN = 0.058        # antebrachium / crus -- drops vertically
HUMERUS_PITCH = -8.0     # deg below horizontal; measured range -13..-2
# BOTH POSITIVE. `build_leg` already turns the magnitude into a direction with
# `side * fore`; making the hind constant negative applied a SECOND flip and
# the two cancelled, so all four legs ended up using only two directions --
# left pair parallel, right pair parallel, no X. Joan, top-down in Godot: "las
# patas de abajo estan bien posicionadas, las de arriba estan como juntas".
# Measured before the fix: FL +40, BL +40, FR -40, BR -40.
LEG_YAW_FRONT = 40.0     # front legs point forward-and-out, into their quadrant
LEG_YAW_BACK = 40.0      # hind legs point backward-and-out

LEG_DEF = {              # name: (side_sign, fore_sign, yaw)
    "leg_FL": (-1.0, -1.0, LEG_YAW_FRONT),
    "leg_FR": (+1.0, -1.0, LEG_YAW_FRONT),
    "leg_BL": (-1.0, +1.0, LEG_YAW_BACK),
    "leg_BR": (+1.0, +1.0, LEG_YAW_BACK),
}


def build_leg(name, side, fore, yaw_deg):
    """Upper bone out sideways, lower bone down. Returns the joined leg object."""
    # Shoulder/hip sits on the shell's edge, not under its middle.
    ax, ay, az = 0.135 * side, 0.150 * fore, -0.030
    pitch = math.radians(HUMERUS_PITCH)

    # Direction the upper bone travels: outward by `side`, fore-or-aft by
    # `fore`, dipping slightly by pitch. THIS is the vector that makes each leg
    # different from the other three, and it was wrong in a way no single view
    # could show. The old form built a signed `yaw` and then read the fore-aft
    # component as `sin(yaw) * -fore`; with `yaw` itself already carrying a
    # `side * fore`, the two `fore` factors cancelled and dy collapsed to
    # `-side * sin(A)` -- a term with NO fore-aft dependence at all. Both left
    # legs pointed back, both right legs pointed forward: parallel pairs, never
    # an X. Measured before the fix: FL -80.6 deg, FR +46.3, BL -133.7, BR
    # +99.4, where a mirrored X wants FL/-FR and BL/-BR equal and opposite.
    #
    # Written straight, there is no cancellation to make: out is out, and
    # forward is -Y for the front pair, +Y for the hind pair.
    a = math.radians(yaw_deg)
    d = Vector((math.cos(a) * side,
                math.sin(a) * fore,
                math.tan(pitch))).normalized()

    elbow = Vector((ax, ay, az)) + d * UPPER_LEN
    pieces = []

    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.055,
                                         location=(ax, ay, az))
    sh = bpy.context.object
    for v in sh.data.vertices:
        v.co.z *= 0.80
    pieces.append(sh)

    # upper: a tapered cylinder from shoulder to elbow
    mid = Vector((ax, ay, az)) + d * (UPPER_LEN * 0.5)
    bpy.ops.mesh.primitive_cone_add(radius1=0.058, radius2=0.046, depth=UPPER_LEN,
                                    location=mid)
    up = bpy.context.object
    up.rotation_mode = 'QUATERNION'
    up.rotation_quaternion = d.to_track_quat('Z', 'Y')
    pieces.append(up)

    # lower: drops from the elbow straight down -- the vertical plane
    foot_z = -(az + d.z * UPPER_LEN) - 0.012
    drop = max(LOWER_LEN, foot_z)
    bpy.ops.mesh.primitive_cone_add(radius1=0.048, radius2=0.038, depth=drop,
                                    location=(elbow.x, elbow.y, elbow.z - drop * 0.5))
    pieces.append(bpy.context.object)

    # Elbow mass. Without a swelling at the joint the two cones read as one
    # bent pipe; a limb hinges around something.
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.043,
                                         location=elbow)
    pieces.append(bpy.context.object)

    # foot: a flat pad, splayed outward like the limb it hangs from
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=8, radius=0.040,
                                         location=(elbow.x + d.x * 0.012,
                                                   elbow.y + d.y * 0.012,
                                                   elbow.z - drop + 0.012))
    foot = bpy.context.object
    for v in foot.data.vertices:
        v.co.z *= 0.42                       # flattened against the ground
        v.co.x *= 1.15
    pieces.append(foot)

    # Claws. A terrapin has them and they break the foot's outline, which is
    # the whole job of a silhouette notch (style contract: detail lives in the
    # silhouette, not on the surface). Three per foot, splayed along the
    # leading edge and pointing the way the limb points.
    # TOES, then claws on them. The old foot was one flattened sphere with a
    # scalloped fringe and three 8 mm splinters: at any distance that reads as
    # a pad with crumbs on it, not as a foot. A toe is a MASS -- give it one,
    # and the claw becomes the tip of something instead of a floating spike.
    for ci in (-1, 0, 1):
        spread = math.radians(26.0 * ci)
        cd = Vector((d.x * math.cos(spread) - d.y * math.sin(spread),
                     d.x * math.sin(spread) + d.y * math.cos(spread), 0.0)).normalized()
        toe_pt = Vector((elbow.x, elbow.y, elbow.z - drop + 0.012)) + cd * 0.030
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=7,
                                             radius=0.0165, location=toe_pt)
        toe = bpy.context.object
        for v in toe.data.vertices:
            v.co.z *= 0.55
        for pp in toe.data.polygons:
            pp.use_smooth = True
        pieces.append(toe)

        base_pt = Vector((elbow.x, elbow.y, elbow.z - drop + 0.011)) + cd * 0.042
        bpy.ops.mesh.primitive_cone_add(radius1=0.0125, radius2=0.0022, depth=0.040,
                                        location=base_pt + cd * 0.016)
        claw = bpy.context.object
        claw.rotation_mode = 'QUATERNION'
        claw.rotation_quaternion = Vector((cd.x, cd.y, -0.34)).normalized().to_track_quat('Z', 'Y')
        pieces.append(claw)

    for pc in pieces:
        for p in pc.data.polygons:
            p.use_smooth = True
        finish_part(pc)
    base = pieces[0]
    base.name = name
    for extra in pieces[1:]:
        bpy.ops.object.select_all(action='DESELECT')
        extra.select_set(True)
        base.select_set(True)
        bpy.context.view_layer.objects.active = base
        bpy.ops.object.join()
    return base


SHELL_OVERHANG = R * 1.10 * SHELL_WIDTH_RATIO   # the rim, AFTER the oval narrowing
_elbow_out = []
# Where each limb pivots. The walk keys rotate a leg ABOUT this point instead
# of translating it as a block, which is what made the limb tear away from the
# body when it stepped -- a leg does not slide out of its shoulder.
LEG_ANCHOR = {}
LEG_AXIS = {}
for name, (side, fore, yaw) in LEG_DEF.items():
    LEG_ANCHOR[name] = Vector((0.135 * side, 0.150 * fore, -0.030))
    _a = math.radians(yaw)
    LEG_AXIS[name] = Vector((math.cos(_a) * side, math.sin(_a) * fore,
                             math.tan(math.radians(HUMERUS_PITCH)))).normalized()
    leg = build_leg(name, side, fore, yaw)
    finish_part(leg)
    start, end = join_part(turtle, leg)
    PARTS[name] = (start, end)
    _reach = 0.135 + UPPER_LEN * math.cos(math.radians(LEG_YAW_FRONT))
    _elbow_out.append(_reach)
print("[turtle] codo a %.3f m del eje, borde del caparazon %.3f m -> %s"
      % (max(_elbow_out), SHELL_OVERHANG,
         "ASOMA, el sprawl se ve" if max(_elbow_out) > SHELL_OVERHANG
         else "TAPADO por el caparazon, el sprawl es invisible"))
if max(_elbow_out) <= SHELL_OVERHANG:
    raise SystemExit("[turtle] el codo queda bajo el caparazon -- la postura esparrancada no se lee")


# THE X GATE. Joan, top-down in Godot: "las patas deben estar en forma de x".
# A sprawling chelonian puts one foot in each quadrant -- front pair forward
# and out, hind pair back and out -- and the reference photo he sent shows
# exactly that. The previous build had all four legs sharing TWO directions,
# because `LEG_YAW_BACK` was negative AND `build_leg` already derived the
# direction from `side * fore`: two flips that cancelled. Nothing caught it,
# because from any angle except straight down a wrong leg still looks like a
# leg. So it is measured here, at build time, per quadrant.
_QUAD = {}
for _n in LEG_DEF:
    _ax, _ay, _az = LEG_ANCHOR[_n]
    _lo, _hi = PARTS[_n]
    _far = max(range(_lo, _hi),
               key=lambda k: math.hypot(me.vertices[k].co.x - _ax,
                                        me.vertices[k].co.y - _ay))
    _fx = me.vertices[_far].co.x
    _fy = me.vertices[_far].co.y
    # Angle from straight ahead (-Y), positive toward the model's right (+X).
    _ang = math.degrees(math.atan2(_fx, -_fy))
    # Relative to ITS OWN anchor, not to the body's origin: the four anchors
    # already sit in four quadrants, so an absolute-sign test passes even when
    # every leg points the same way. That weaker gate passed on parallel legs
    # -- it had to be told what an X actually means.
    _side, _fore = LEG_DEF[_n][0], LEG_DEF[_n][1]
    _out = (_fx - _ax) * _side          # >0 = away from the spine
    _along = (_fy - _ay) * _fore        # >0 = toward this leg's own end
    _QUAD[_n] = (_out > 0, _along > 0)
    print("[turtle] %s  pie %+.3f m hacia afuera, %+.3f m hacia %s   "
          "%+6.1f deg respecto al frente"
          % (_n, _out, _along, "atras" if _fore > 0 else "adelante", _ang))
    if _out <= 0.02 or _along <= 0.02:
        raise SystemExit(
            "[turtle] %s no apunta a su cuadrante (afuera %+.3f, hacia su "
            "extremo %+.3f) -- las patas no forman una X" % (_n, _out, _along))
print("[turtle] patas en X: las 4 apuntan a su propio cuadrante  OK")

# ---------- tail ----------
bpy.ops.mesh.primitive_cone_add(radius1=0.035, radius2=0.008, depth=0.09,
                                 location=(0, 0.275, -0.01), rotation=(math.radians(-100), 0, 0))
tail = bpy.context.object
tail.name = "tail"
for p in tail.data.polygons:
    p.use_smooth = True
finish_part(tail)
start, end = join_part(turtle, tail)
PARTS["tail"] = (start, end)

me = turtle.data  # refresh after joins

# ---------- ground the whole body at Z=0 ----------
zmin = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= zmin
SHELL_ZMIN -= zmin
SHELL_ZMAX -= zmin
for _n in LEG_ANCHOR:                    # the pivots move with the body
    LEG_ANCHOR[_n].z -= zmin

LEG_RANGES = [PARTS["leg_FL"], PARTS["leg_FR"], PARTS["leg_BL"], PARTS["leg_BR"]]
DIAG_A = [PARTS["leg_FL"], PARTS["leg_BR"]]
DIAG_B = [PARTS["leg_FR"], PARTS["leg_BL"]]


def in_ranges(i, ranges):
    return any(a <= i < b for a, b in ranges)


# ---------- shape keys: the turtle vocabulary ----------
# GOTCHA (paid for hard, 2026-07-18): shape_key_add() defaults value=1.0 AND from_mix
# copies the CURRENT blended mesh. Every previously-created key is still sitting at
# value=1.0 at that moment, so each new key's "untouched" vertices silently inherit
# the SUM of every prior key's delta instead of pure Basis -- compounding into wild
# multi-metre spikes on parts a later key never even targets. Fix: force from_mix=False
# (pin the copy source to Basis) AND immediately zero .value after every add.
def add_key(name):
    k = turtle.shape_key_add(name=name, from_mix=False)
    k.value = 0.0
    return k


add_key("Basis")
base_co = [v.co.copy() for v in me.vertices]

HEAD_PARTS = ("neck", "head", "eye_L", "eye_R",
              "brow_L", "brow_R", "nostril_L", "nostril_R")
HEAD_RANGE = [PARTS[k] for k in HEAD_PARTS if k in PARTS]
_missing = [k for k in HEAD_PARTS if k not in PARTS]
print("[turtle] cabeza: %d piezas siguen las shape keys%s"
      % (len(HEAD_RANGE), "" if not _missing else "  FALTAN: %s" % _missing))
if _missing:
    raise SystemExit("[turtle] piezas de la cabeza fuera del rango -- van a quedar flotando")


def head_factor(y):
    # 0 at neck base, 1 at head tip — head/snout moves more than the neck root
    return max(0.0, min(1.0, (NECK_BASE_Y - y) / (NECK_BASE_Y - HEAD_TIP_Y)))


# The NECK extends; the head travels forward RIGID. Joan: "el ataque me agrada,
# pero se alarga la cara -- debería hacer que el cuello se estire solamente,
# como una tortuga". The old key scaled the displacement by head_factor across
# the whole head range, so the snout moved further than the skull base and the
# face stretched like rubber. A turtle's skull is bone: it does not deform.
# Only the neck is extensible, and that is the entire point of the strike.
_NECK_LO, _NECK_HI = PARTS["neck"]
_HEAD_ONLY = [PARTS[k] for k in HEAD_PARTS if k != "neck" and k in PARTS]

# WHERE THE NECK ACTUALLY ENDS, measured off the geometry rather than assumed.
# This is the whole bug Joan kept reporting as "se despega la cabeza".
# `head_factor` normalises from the neck base to the HEAD TIP, but the neck
# stops long before the head tip -- so at the neck's own front rim the factor
# is only ~0.47. Every head key then moved the skull by the full delta and the
# neck's rim by less than half of it: on `head_bite` that is 155 mm against
# 73.6 mm, an 81 mm hole in a neck whose radius is 33 mm. The head flew off.
#
# So: the NECK deforms, normalised over the NECK, reaching exactly 1.0 at its
# front rim; the skull and its features travel as ONE RIGID BLOCK by the same
# delta. They meet at 1.0, which is what keeps them welded, and the skull never
# stretches -- it is bone. The previous build fixed exactly this for the bite
# and left retract, droop and look with the old factor: the same half-fix that
# has now been paid for three times on this model.
NECK_TIP_Y = min(base_co[i].y for i in range(_NECK_LO, _NECK_HI))
HEAD_BACK_Y = max(base_co[i].y for a, b in _HEAD_ONLY for i in range(a, b))
print("[turtle] cuello: base %.3f  punta %.3f   cabeza empieza en %.3f"
      % (NECK_BASE_Y, NECK_TIP_Y, HEAD_BACK_Y))


def neck_factor(y):
    """0 at the neck base, EXACTLY 1 at the neck's front rim."""
    span = NECK_BASE_Y - NECK_TIP_Y
    return max(0.0, min(1.0, (NECK_BASE_Y - y) / span)) if span > 1e-6 else 0.0


def head_key(name, delta, neck_narrow=0.0):
    """Neck stretches to meet the skull; skull moves rigid. Asserts the weld.

    `neck_narrow` pinches the neck toward its axis (used by the retraction,
    where the neck folds into the shell) and is applied to the NECK ONLY --
    narrowing the skull would deform bone.
    """
    sk = add_key(name=name)
    for i, co in enumerate(base_co):
        if _NECK_LO <= i < _NECK_HI:
            f = neck_factor(co.y)
            t = co + delta * f
            t.x *= (1.0 - neck_narrow * f)
            sk.data[i].co = t
        elif in_ranges(i, _HEAD_ONLY):
            sk.data[i].co = co + delta

    # THE GATE. The neck's front rim and the skull's back must travel the same
    # distance, or a hole opens where they overlap. Checked per key, at build
    # time, because in a still frame a detached head just looks like a head.
    rim = [i for i in range(_NECK_LO, _NECK_HI)
           if base_co[i].y < NECK_TIP_Y + 0.008]
    skull = [i for a, b in _HEAD_ONLY for i in range(a, b)
             if base_co[i].y > HEAD_BACK_Y - 0.008]
    if rim and skull:
        d_rim = sum((Vector(sk.data[i].co) - base_co[i]).length
                    for i in rim) / len(rim)
        d_skull = sum((Vector(sk.data[i].co) - base_co[i]).length
                      for i in skull) / len(skull)
        gap = abs(d_rim - d_skull) * 1000.0
        print("[turtle] %-14s borde del cuello %6.1f mm, craneo %6.1f mm, "
              "desfase %5.1f mm" % (name, d_rim * 1000, d_skull * 1000, gap))
        if gap > 6.0:
            raise SystemExit(
                "[turtle] %s despega la cabeza del cuello: %.1f mm de desfase"
                % (name, gap))
    return sk


BITE_REACH = 0.155
head_key("head_bite", Vector((0.0, -BITE_REACH, -0.012)))
head_key("head_retract", Vector((0.0, 0.16, -0.05)), neck_narrow=0.35)
head_key("head_droop", Vector((0.0, -0.02, -0.11)))
head_key("head_look_L", Vector((-0.075, 0.0, 0.0)))
head_key("head_look_R", Vector((0.075, 0.0, 0.0)))

# BREATHING moves the SOFT parts only. A turtle's shell is fused bone and
# cannot expand, which is precisely why chelonians pump their throat to
# ventilate -- the anatomy dictates the animation.
_BREATHE_RANGE = [PARTS[k] for k in ("neck", "head") if k in PARTS]
sk = add_key(name="breathe")
_breathed = 0
for i, co in enumerate(base_co):
    if in_ranges(i, _BREATHE_RANGE):
        # Throat pump: widens and drops slightly, strongest under the jaw.
        # neck_factor, not head_factor: on the old normalisation the SKULL
        # inflated more than the neck rim it sits on (1-f is larger behind the
        # joint than in front of it), which is the same shear that detached the
        # head, only smaller. And a skull does not inflate -- so the pump dies
        # at the neck's rim and the head is left alone entirely.
        f = neck_factor(co.y)
        sk.data[i].co = co + Vector((co.x * 0.10 * (1.0 - f),
                                     0.0,
                                     -0.007 * (1.0 - f)))
        _breathed += 1
if _breathed == 0:
    raise SystemExit("[turtle] la respiracion no movio nada")

# Visibility/correctness assert: not one shell vertex may move. The shell is
# bone; if it breathes the animal reads as a balloon.
_shell_lo2, _shell_hi2 = PARTS["shell"]
_moved_shell = sum(1 for i in range(_shell_lo2, _shell_hi2)
                   if (Vector(sk.data[i].co) - base_co[i]).length > 1e-6)
print("[turtle] respiracion: %d verts blandos, %d del caparazon" % (_breathed, _moved_shell))
if _moved_shell > 0:
    raise SystemExit("[turtle] el caparazon respira -- es hueso, SHELL_DEFORM=0")

# THREE KEYS PER LEG: protraction, retraction, lift.
#
# The previous build had ONE key per leg that translated every leg vertex by
# the same (0, -0.045, +0.045). Two things were wrong with it, and Joan caught
# both by watching: the limb slid out of its shoulder instead of pivoting, and
# -- worse -- the key was driven 0 -> 1 -> 0 inside the swing and left at 0 for
# the rest of the cycle, so the foot came back to where it started and STOOD
# STILL while planted. Measured on the deployed clip: fore-aft drag while
# planted = +0.0 mm. That is not a walk, it is a wave.
#
# Joan, describing what it should be: "cuando pisa, esa misma se tiene que
# tirar hacia atrás por el movimiento de arrastre... funcionar de pivote, de
# apoyo, y a medida que hace el impulso para moverse, esa pierna derecha
# termina quedando atrás". The stock clip agrees: the hind foot ends up behind
# the rear edge of the carapace (_references/turtle_terrestrial/motion).
#
# A sprawling limb protracts and retracts by SWEEPING in the horizontal plane
# about the shoulder -- the humerus is near-horizontal on a chelonian -- so the
# two sweep keys are a yaw about the pivot, not a translation. A vertex near
# the shoulder barely moves and the foot moves the most, for free.
SWEEP_DEG = 21.0     # half-amplitude of the fore-aft sweep, per direction
FOOT_LIFT = 0.022    # clearance in the swing. The reference foot SCUFFS the
                     # gravel; the old 76.8 mm was a third of the body height.

for _leg in ("leg_FL", "leg_FR", "leg_BL", "leg_BR"):
    _ax, _ay, _az = LEG_ANCHOR[_leg]
    _side = LEG_DEF[_leg][0]
    # Forward is -Y. Yawing by -side*angle carries the foot forward on either
    # side of the body; the mirrored sign is why this cannot be one key.
    for _dir, _pref in ((-1.0, "prot_"), (+1.0, "retr_")):
        sk = add_key(name=_pref + _leg)
        _a = math.radians(SWEEP_DEG) * _side * _dir
        _ca, _sa = math.cos(_a), math.sin(_a)
        for i, co in enumerate(base_co):
            if in_ranges(i, [PARTS[_leg]]):
                dx, dy = co.x - _ax, co.y - _ay
                sk.data[i].co = Vector((_ax + dx * _ca - dy * _sa,
                                        _ay + dx * _sa + dy * _ca,
                                        co.z))
    # Lift, weighted by distance from the pivot so the shoulder stays put.
    _reach_leg = max(0.001, max(math.hypot(co.x - _ax, co.y - _ay)
                                for i, co in enumerate(base_co)
                                if in_ranges(i, [PARTS[_leg]])))
    sk = add_key(name="lift_" + _leg)
    for i, co in enumerate(base_co):
        if in_ranges(i, [PARTS[_leg]]):
            w = min(1.0, math.hypot(co.x - _ax, co.y - _ay) / _reach_leg)
            sk.data[i].co = co + Vector((0.0, 0.0, FOOT_LIFT * w))

# Legs tuck UNDER the shell, never above it. Joan: "me agrada que se encojan
# las patas, pero cuando se encogen quedan por sobre el caparazón, es rarísimo".
# The old key added a flat +0.10 on Z to every leg vertex, which pushed them
# straight through the carapace. A turtle folds its limbs INTO the shell's
# hollow: they move inward and slightly up, and they must stay BELOW the
# carapace's underside.
_TUCK_CEILING = SHELL_ZMIN - 0.012      # never rise above the shell's floor
sk = add_key(name="legs_retract")
for i, co in enumerate(base_co):
    if in_ranges(i, LEG_RANGES):
        target = co.copy()
        target.x = co.x * 0.42           # pull inward toward the body axis
        target.y = co.y * 0.55
        target.z = min(co.z + 0.055, _TUCK_CEILING)
        sk.data[i].co = target

sk = add_key(name="legs_splay")    # flat, splayed out (death)
for i, co in enumerate(base_co):
    if in_ranges(i, LEG_RANGES):
        target = co.copy()
        target.x *= 1.45
        target.y *= 1.25
        target.z = SHELL_ZMIN + 0.01
        sk.data[i].co = target

sk = add_key(name="shell_settle")  # dome compresses + widens (death)
for i, co in enumerate(base_co):
    if in_ranges(i, [PARTS["shell"], PARTS["belly"]]):
        f = max(0.0, (co.z - SHELL_ZMIN) / max(0.001, (SHELL_ZMAX - SHELL_ZMIN)))
        target = co.copy()
        target.z = SHELL_ZMIN + (co.z - SHELL_ZMIN) * 0.45
        target.x *= (1.0 + 0.08 * f)
        target.y *= (1.0 + 0.08 * f)
        sk.data[i].co = target

kb = me.shape_keys.key_blocks
_GAIT_KEYS = tuple(p + l for l in ("leg_FL", "leg_FR", "leg_BL", "leg_BR")
                   for p in ("prot_", "retr_", "lift_"))
ALL_KEYS = ("head_bite", "head_retract", "head_droop", "head_look_L", "head_look_R",
            "breathe") + _GAIT_KEYS + (
            "legs_retract", "legs_splay", "shell_settle")
FPS = 24
scene.render.fps = FPS


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------- animation samplers: t in [0,1) -> {shapekey: value, rot_y:, loc_z:} ----------
def anim_idle(t):
    breathe = 0.5 + 0.5 * math.sin(2 * math.pi * t)
    look = math.sin(2 * math.pi * t + math.pi / 2)
    return {
        "breathe": 0.65 * breathe,
        "head_look_L": max(0.0, look) * 0.75,
        "head_look_R": max(0.0, -look) * 0.75,
    }


# Lateral-sequence diagonal-couplet: the real chelonian gait, measured in
# Journal of Experimental Biology (Testudo hermanni) and SICB (giant tortoise
# biomechanics). Spec: _references/turtle/motion/_motion_spec.md, Movimiento 2.
#
# The order is what makes it lateral-sequence rather than a trot: a front foot,
# then the DIAGONALLY OPPOSITE hind foot, then the other front, then the last
# hind. One foot at a time.
# Phase at which each foot swings. NOT four evenly spaced quarters: the gait
# is "lateral sequence, DIAGONAL COUPLET" (Hildebrand 1966), and the couplet
# half is what the first implementation missed. Joan, watching it in Godot:
# "sube una pata por sí sola; en una tortuga generalmente son dos patas que se
# mueven en conjunto". He was right, and the source agrees -- the four
# footfalls "are clearly NOT evenly distributed at 25% intervals; they cluster
# into a diagonal-pair pattern".
#
# So a forefoot and its DIAGONAL hindfoot go together with only a short lag,
# and then a long wait before the other pair. Neither the original trot (pairs
# exactly simultaneous) nor the first fix (one foot every 25%): in between.
COUPLET_LAG = 0.11              # within a diagonal pair
FOOTFALL_PHASE = {
    "leg_FL": 0.00,
    "leg_BR": 0.00 + COUPLET_LAG,   # diagonal partner of FL
    "leg_FR": 0.50,
    "leg_BL": 0.50 + COUPLET_LAG,   # diagonal partner of FR
}
FOOTFALL = tuple(FOOTFALL_PHASE.keys())

# Fraction of the cycle each foot spends OFF the ground. At 0.25 exactly one
# foot would swing at any instant; below that there are stretches with all four
# down. Duty factor = 1 - SWING >= 0.78, which is what produces the long
# tripedal support the measurements describe -- never fewer than three feet
# planted.
SWING = 0.22


def anim_move(t):
    """One full stride cycle. The stance phase is the whole point of it."""
    phase = t % 1.0
    v = {}
    for leg, start in FOOTFALL_PHASE.items():
        u = (phase - start) % 1.0
        if u < SWING:
            s = u / SWING
            # SWING -- the foot travels from fully retracted to fully
            # protracted, off the ground. Eased slightly front-loaded: the
            # limb snaps off the ground and settles into the plant. The old
            # build ran 0 -> 1 -> 0 here, which returned the foot to where it
            # started and produced no stride at all.
            sweep = -1.0 + 2.0 * (s ** 0.72)
            v["lift_" + leg] = math.sin(math.pi * s)
        else:
            s = (u - SWING) / (1.0 - SWING)
            # STANCE -- planted. The foot travels BACKWARD at a CONSTANT rate,
            # because the body is advancing over a foot that is not moving.
            # Linear on purpose: ease it and the foot skates against ground
            # that does not accelerate.
            sweep = 1.0 - 2.0 * s
            v["lift_" + leg] = 0.0
        # One signed sweep, expressed through the two directional keys.
        v["prot_" + leg] = max(0.0, sweep)
        v["retr_" + leg] = max(0.0, -sweep)

    # The body barely rises. In the reference clip the carapace height over
    # the ground reads CONSTANT across the whole walk -- what moves is the
    # legs. The old build pumped 12 mm FOUR times per cycle while each leg
    # swung once, so the eye saw four bounces per step: that mismatch is what
    # Joan read as "se balancea" and "en descompás", and no amount of leg work
    # would have fixed it. Two pumps, one per diagonal couplet, 3.5 mm.
    # 1.5 mm, not 12: measured, the body's own vertical motion LIFTS THE
    # PLANTED FOOT, because a foot 0.223 m off the roll axis rides whatever
    # the shell does. At 12 mm of pump and 4 deg of roll the planted foot
    # floated 11.3 mm -- it was skating in the air. The reference clip shows a
    # carapace whose height over the ground reads constant, which is the same
    # statement from the other side.
    v["loc_z"] = 0.0010 * (1.0 - math.cos(2 * math.pi * 2 * phase)) * 0.5

    # Roll AWAY from the corner whose foot is in the air: the weight shifts on
    # to the supporting tripod, which raises the swinging corner slightly.
    # The sign matters and was wrong first time round -- a positive rotation
    # about +Y pushes the LEFT side (x < 0) DOWN, so the body was leaning on
    # the very leg it was lifting, and the foot stayed 12 mm off the ground
    # for a third of the cycle after its swing had ended. Caught by the trace,
    # not by the render: in a still it just looks like a leg in the air.
    v["rot_y"] = -math.radians(0.35) * math.sin(2 * math.pi * (phase + COUPLET_LAG))
    return v


def anim_attack(t):
    v = {}
    if t < 0.55:                        # long anticipation: brace back
        u = t / 0.55
        v["head_retract"] = 0.32 * math.sin(math.pi * 0.5 * u)
    elif t < 0.72:                      # fast snap forward
        u = (t - 0.55) / 0.17
        v["head_retract"] = lerp(0.32, 0.0, u)
        v["head_bite"] = lerp(0.0, 1.0, u)
    else:                               # recover
        u = (t - 0.72) / 0.28
        v["head_bite"] = lerp(1.0, 0.0, u)
    return v


def anim_hit(t):
    v = {}
    if t < 0.28:
        u = t / 0.28
        v["head_retract"] = lerp(0.0, 1.0, u)
        v["legs_retract"] = lerp(0.0, 1.0, u)
    elif t < 0.50:
        v["head_retract"] = 1.0
        v["legs_retract"] = 1.0
    else:
        u = (t - 0.50) / 0.50
        v["head_retract"] = lerp(1.0, 0.0, u)
        v["legs_retract"] = lerp(1.0, 0.0, u)
    return v


_XZ = [(v.co.x, v.co.z) for v in me.vertices]
_LIFT_STEPS = 73                                   # every 2.5 deg over 180


def _lowest_after_roll(r):
    c, sn = math.cos(r), math.sin(r)
    return min(z * c - x * sn for x, z in _XZ)


# Table of the exact lift needed at each roll angle, plus a small skin so the
# mesh never grazes the floor.
_LIFT_TABLE = []
for _i in range(_LIFT_STEPS):
    _r = math.pi * _i / (_LIFT_STEPS - 1)
    _LIFT_TABLE.append(max(0.0, -_lowest_after_roll(_r)) + 0.002)
print("[turtle] elevacion del vuelco: pico %.1f mm a %.0f grados, final %.1f mm"
      % (max(_LIFT_TABLE) * 1000,
         math.degrees(math.pi * _LIFT_TABLE.index(max(_LIFT_TABLE)) / (_LIFT_STEPS - 1)),
         _LIFT_TABLE[-1] * 1000))


def roll_lift(roll_rad):
    """Exact height the body needs so a roll never pushes it through the floor."""
    a = min(max(abs(roll_rad), 0.0), math.pi)
    f = a / math.pi * (_LIFT_STEPS - 1)
    i = int(f)
    if i >= _LIFT_STEPS - 1:
        return _LIFT_TABLE[-1]
    t = f - i
    return _LIFT_TABLE[i] * (1 - t) + _LIFT_TABLE[i + 1] * t


def anim_death(t):
    """The turtle tips over and ends belly-up.

    Joan: "me gustaría que la animación de muerte fuera de que la tortuga se dé
    vuelta, y quede panza hacia arriba". The old one just flattened, which is
    the least interesting thing a shelled animal can do -- and it wastes the
    plastron, which is the side nobody ever sees.

    Five beats, because a fall has a point of no return and a settle:
      0.00-0.18  legs give, the body sags but holds
      0.18-0.42  leans, fighting it -- slow, still recoverable
      0.42-0.58  past the tipping point: fast, committed
      0.58-0.74  impact, with one small bounce
      0.74-1.00  belly-up, legs in the air, going still
    """
    # NO leg crushing. Joan: "no hay por qué aplastar las patas, eso no va a dar
    # realmente". `legs_splay` flattens them against the ground, which is a pose
    # for an animal collapsing onto its belly -- the opposite of what happens
    # here. A turtle that tips over keeps its legs OUT, and once inverted they
    # hang in the air. The only thing that changes is that they stop resisting.
    if t < 0.18:
        u = t / 0.18
        r = math.radians(6.0) * u
        return {"head_droop": 0.25 * u, "rot_y": r, "loc_z": roll_lift(r)}
    if t < 0.42:
        u = (t - 0.18) / 0.24
        # Slow lean. Ease-out: it is losing the fight, not being pushed.
        r = math.radians(6.0 + 62.0 * (u ** 0.7))
        return {"head_droop": 0.25 + 0.2 * u, "rot_y": r, "loc_z": roll_lift(r)}
    if t < 0.58:
        u = (t - 0.42) / 0.16
        # Past the tipping point. Ease-IN: gravity has it now.
        r = math.radians(68.0 + 104.0 * (u ** 1.9))
        return {"head_droop": 0.45 + 0.3 * u, "rot_y": r, "loc_z": roll_lift(r)}
    if t < 0.74:
        u = (t - 0.58) / 0.16
        # Impact and one bounce -- the shell is rigid, it does not absorb.
        bounce = math.sin(math.pi * u) * math.exp(-3.2 * u)
        r = math.radians(172.0 + 9.0 * bounce)
        return {"head_droop": 0.75 + 0.25 * u, "rot_y": r,
                "loc_z": roll_lift(r) + 0.008 * bounce}
    u = (t - 0.74) / 0.26
    # Belly-up, legs in the air. They twitch briefly and stop -- that last
    # motion after the body has settled is what makes it read as dying rather
    # than as an object being placed.
    twitch = math.sin(math.pi * 3.0 * u) * math.exp(-4.0 * u)
    return {"head_droop": 1.0, "rot_y": math.radians(180.0) + 0.05 * twitch,
            "loc_z": roll_lift(math.radians(180.0))}


ANIMS = {
    "idle-loop": (72, anim_idle),
    "move-loop": (64, anim_move),
    "attack": (26, anim_attack),
    "hit": (16, anim_hit),
    "death": (54, anim_death),
}

sk_ad = me.shape_keys.animation_data_create()
obj_ad = turtle.animation_data_create()
actions = {}
for name, (frames, sampler) in ANIMS.items():
    act_sk = bpy.data.actions.new(f"{name}_sk")
    sk_ad.action = act_sk
    act_obj = bpy.data.actions.new(f"{name}_obj")
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        vals = sampler(t)
        for k in ALL_KEYS:
            kb[k].value = vals.get(k, 0.0)
            kb[k].keyframe_insert("value", frame=f)
        turtle.rotation_euler.y = vals.get("rot_y", 0.0)
        turtle.keyframe_insert("rotation_euler", frame=f)
        turtle.location.z = vals.get("loc_z", 0.0)
        turtle.keyframe_insert("location", frame=f)
    actions[name] = (frames, act_sk, act_obj)
sk_ad.action = None
obj_ad.action = None

# ---------- materials: shell voronoi plates (2 greens), olive skin, lighter belly ----------


def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def _base(name, alpha):
    m = bpy.data.materials.new(f"turtle_{name}")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Alpha"].default_value = alpha
    return m, nt, n


def mat_shell():
    """Albedo from the baked carapace map, sampled through the shell's own UV."""
    m, nt, n = _base("shell", 1.0)
    # 0.74, not 0.62: in Godot the shell read as wet black plastic, because a
    # smooth dark surface is nearly all specular. Keratin is matte.
    n.inputs["Roughness"].default_value = 0.74
    arr = _carapace_texture.bake(CARAPACE, size=1024)
    img = _carapace_texture.to_blender_image(arr)
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], n.inputs["Base Color"])
    return m


def mat_skin():
    """Large legible scales, from a tileable sheet -- see _skin_texture.py."""
    m, nt, n = _base("skin", 1.0)
    n.inputs["Roughness"].default_value = 0.78
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _skin_texture.to_blender_image(_skin_texture.bake(size=512))
    tex.extension = "REPEAT"
    uvn = nt.nodes.new("ShaderNodeUVMap")
    uvn.uv_map = "SkinUV"
    nt.links.new(uvn.outputs["UV"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], n.inputs["Base Color"])
    return m


def _mat_skin_noise():
    m, nt, n = _base("skin", 1.0)
    n.inputs["Roughness"].default_value = 0.6
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 12.0
    noise.inputs["Detail"].default_value = 2.0
    ramp, ra, rb, rout = _mix_rgba(nt)
    # MEASURED against the shell in Joan's screenshot: skin on the head
    # sampled (240, 255, 177) against a carapace at (97, 97, 92) -- two and a
    # half times brighter, and nearly clipped. That is why the skin read as
    # "lower quality": not the modelling, the VALUE. It did not belong to the
    # same animal. Darker, and less yellow, so the shell stays the hero.
    ra.default_value = (0.058, 0.064, 0.034, 1.0)
    rb.default_value = (0.088, 0.094, 0.048, 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
    nt.links.new(rout, n.inputs["Base Color"])
    return m


def mat_belly():
    m, nt, n = _base("belly", 1.0)
    n.inputs["Roughness"].default_value = 0.5
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    ramp, ra, rb, rout = _mix_rgba(nt)
    ra.default_value = (0.34, 0.28, 0.15, 1.0)
    rb.default_value = (0.44, 0.38, 0.22, 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
    nt.links.new(rout, n.inputs["Base Color"])
    return m


mat_shell_data = mat_shell()
mat_skin_data = mat_skin()
mat_belly_data = mat_belly()
me.materials.append(mat_shell_data)   # slot 0
me.materials.append(mat_skin_data)    # slot 1
me.materials.append(mat_belly_data)   # slot 2

# ---------- scale UVs for the skin ----------
# A limb is a cylinder, so its natural parametrisation is angle-around-axis by
# distance-along-axis, and a TILEABLE scale sheet then needs no unwrap and no
# atlas. The carapace got a unique map because its pattern is unique per plate;
# skin is the opposite -- the same scale repeats, so repetition is the point.
#
# Why not vertex colour, which is what was here: a leg is a twelve-segment
# cone, and vertex colour resolution IS mesh resolution. Anything finer than
# one tone per facet could never have survived, which is why the skin rendered
# as a flat pale capsule however good the noise looked in Blender.
# Measured on the first bake: at 7 tiles around x (rows*4)/m along, a scale
# came out ~3 mm on a 280 mm animal -- rendered, that is vertical noise
# streaks, not scales. The reference is explicit that the scales are LARGE and
# legible ("escamas grandes y salientes"); at ~15 mm they read.
SCALE_COLS = 2.0        # texture tiles around a limb (x9 cells = ~18 scales)
SCALE_ROWS = 2.4        # tiles per metre along it

_skinuv = me.uv_layers.get("SkinUV") or me.uv_layers.new(name="SkinUV")
_HEAD_AXIS = Vector((0.0, -1.0, 0.0))
_axis_of = {"neck": (Vector((0.0, -0.27, 0.02)), _HEAD_AXIS),
            "head": (Vector((0.0, -0.27, 0.02)), _HEAD_AXIS)}
for _n in LEG_AXIS:
    _axis_of[_n] = (LEG_ANCHOR[_n], LEG_AXIS[_n])

_uv_written = 0
for _part, (_org, _ax) in _axis_of.items():
    if _part not in PARTS:
        continue
    _lo, _hi = PARTS[_part]
    # Any vector not parallel to the axis gives us the two perpendicular
    # directions the angle is measured in.
    _ref = Vector((0.0, 0.0, 1.0))
    if abs(_ref.dot(_ax)) > 0.9:
        _ref = Vector((1.0, 0.0, 0.0))
    _e1 = (_ref - _ax * _ref.dot(_ax)).normalized()
    _e2 = _ax.cross(_e1).normalized()
    for _poly in me.polygons:
        if not all(_lo <= _vi < _hi for _vi in _poly.vertices):
            continue
        for _li, _vi in zip(_poly.loop_indices, _poly.vertices):
            _r = me.vertices[_vi].co - _org
            _along = _r.dot(_ax)
            _ang = math.atan2(_r.dot(_e2), _r.dot(_e1))
            _skinuv.data[_li].uv = (_ang / (2.0 * math.pi) * SCALE_COLS,
                                    _along * SCALE_ROWS * 1.0)
            _uv_written += 1
print("[turtle] UV de escamas: %d loops en %d partes de piel"
      % (_uv_written, len(_axis_of)))
if _uv_written == 0:
    raise SystemExit("[turtle] no se escribio ninguna UV de piel -- las "
                     "escamas no van a leerse")

SKIN_RANGES = [PARTS["neck"], PARTS["head"], PARTS["leg_FL"], PARTS["leg_FR"],
               PARTS["leg_BL"], PARTS["leg_BR"], PARTS["tail"]]
BELLY_RANGES = [PARTS["belly"]]
for p in me.polygons:
    idx0 = p.vertices[0]
    if in_ranges(idx0, BELLY_RANGES):
        p.material_index = 2
    elif in_ranges(idx0, SKIN_RANGES):
        p.material_index = 1
    else:
        p.material_index = 0

# ---------- showcase-ficha scene (contract §4: purple bg, 50mm, key/fill/rim 110/30/130) ----------
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = (lo.location.to_track_quat('Z', 'Y'))


add_light("key", (-0.9, -0.55, 0.65), 28, 0.9)
add_light("fill", (0.8, -0.5, 0.22), 8, 0.85)
add_light("rim", (0.17, 0.9, 0.55), 32, 0.85)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.07)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.62, -1.60, 0.32)
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'
scene.render.use_motion_blur = False   # shape-key velocity streaks otherwise smear fast poses (retract/step)

# ---------- renders: preview frames per animation ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
scene.frame_set(1)
for k in ALL_KEYS:
    kb[k].value = 0.0

for name, (frames, act_sk, act_obj) in actions.items():
    sk_ad.action = act_sk
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[turtle] frames", name)
sk_ad.action = None
obj_ad.action = None
turtle.location = (0, 0, 0)
turtle.rotation_euler = (0, 0, 0)
for k in ALL_KEYS:          # actions leave the last evaluated values behind — reset to rest
    kb[k].value = 0.0

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY, MOB_ZMAX = 0.28, 0.52, 0.16  # turtle half-width / head-to-tail / low dome
SIL_DIST = (MOB_HX ** 2 + MOB_HY ** 2) ** 0.5 + 0.4 + 0.254
right_dir = ficha.camera_right_vector(cam, target)
sil_loc = (right_dir * SIL_DIST)
sil_loc.z = 0.0
sil = ficha.add_scale_silhouette(location=tuple(sil_loc))
sil_xmin, sil_xmax, sil_ymin, sil_ymax, sil_zmin, sil_zmax = ficha.silhouette_bbox(location=tuple(sil_loc))
old_target_loc, old_cam_loc = ficha.frame_hero_camera(
    cam, target,
    x_min=min(-MOB_HX, sil_xmin), x_max=max(MOB_HX, sil_xmax),
    y_min=min(-MOB_HY, sil_ymin), y_max=max(MOB_HY, sil_ymax),
    z_min=0.0, z_max=max(MOB_ZMAX, sil_zmax))

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.filepath = os.path.join(REN_DIR, "turtle_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- push all actions to NLA tracks (one glTF animation per track name) ----------
for name, (frames, act_sk, act_obj) in actions.items():
    tr = sk_ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act_sk)
    tr.mute = False
    tro = obj_ad.nla_tracks.new()
    tro.name = name
    tro.strips.new(name, 1, act_obj)
    tro.mute = False

# ---------- scute grammar + bake: the two things that make it read ----------
# A turtle's scutes are not decoration and not random: every species carries the
# same layout -- 1 nuchal, 5 VERTEBRAL down the midline, 4 pleural pairs, 12
# marginal pairs (_references/turtle/_synthesis.md 2a). Five central plates and
# a rim of marginals read as "turtle" in silhouette even at low poly, and this
# build had none: a smooth dome. It is the cheapest read available.
#
# Drawn as vertex colour, not geometry: 2816 verts is plenty of resolution for
# five large plates, and the budget says a shape that small does not earn faces
# (_asset_creation_contract.md 3c).
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _bake_vcol  # noqa: E402

SCUTE_LINE = (0.30, 0.26, 0.20)      # dark keratin seam between plates


def _scute_tone(co):
    """Per-PLATE tone multiplier. Returns ~1.0 for a light plate, less for a dark one.

    Second approach, after the first failed twice. Drawing thin dark SEAMS put
    only 104 of the shell's 1514 verts on a line -- 7%, spread over six bands
    plus a rim -- so each seam came out dotted and drowned in the material's
    voronoi mottling. A line finer than the vertex spacing cannot be drawn in
    vertex colour, no matter how correct the layout is.

    Inverting it works with the resolution instead of against it: give each
    PLATE its own value. Neighbouring plates differ, so the boundaries appear
    on their own, and every vertex carries signal instead of 7% of them.
    """
    # Which of the 5 vertebral bands, front to back.
    u = min(0.999, max(0.0, co.y / (R * 1.15) * 0.5 + 0.5))
    band = int(u * 5)
    # Which column: midline (vertebral), pleural, or marginal rim.
    r = math.hypot(co.x, co.y) / (R * 1.09)
    ax = abs(co.x) / (R * 1.09)
    if r > 0.84:
        col = 2                       # marginal rim: darkest, frames the shell
    elif ax > 0.42:
        col = 1                       # pleural pair
    else:
        col = 0                       # vertebral, down the midline
    # Alternate along the band so adjacent plates never share a tone.
    step = (band + col * 2) % 3
    base = (1.35, 0.95, 0.60)[step] * (0.70 if col == 2 else 1.0)
    # Alternating annuli: a wide light band from a good season, a narrow dark
    # one from a lean one. This is the pattern that reads as "cut wood" on a
    # real carapace and is what the sulcata refs show most clearly.
    _rp, ri = _ring_phase(co)
    return base * (1.0 + 0.20 * (1 if ri % 2 == 0 else -1))


_shell_lo, _shell_hi = PARTS["shell"]
# The scute pattern moved OUT of vertex colour and INTO a baked texture
# (_carapace_texture.py). The reason is a measurement, not taste: face colour
# resolution IS mesh resolution, so five growth rings across a plate landed two
# faces apart and rendered as a checkerboard. A 1024 px map carries them for
# free, and it is generated from the very functions that shaped the geometry,
# so light and albedo cannot drift out of register.
#
# The layer stays, filled flat, because the skin and belly materials still read
# it and the bake pass expects every mesh to have one.
_col = me.color_attributes.new(name="Scute", type="FLOAT_COLOR", domain="CORNER")
_tone_of = {}
for poly in me.polygons:
    _tone_of[poly.index] = 1.0
    for li in poly.loop_indices:
        _col.data[li].color = (1.0, 1.0, 1.0, 1.0)
print("[turtle] escudos: el patron va en textura horneada, no en vertex colour")

# WIRE IT UP. Painting the attribute is not enough: the first version of this
# block wrote `Scute` and never connected it, so the bake captured the original
# voronoi material and the scutes were ignored entirely. The mesh reported "120
# verts on a seam" and rendered as mottling -- a count that proves the ATTRIBUTE
# exists, not that anything can SEE it.
#
# The seam layer multiplies the shell's existing colour, so plate interiors keep
# whatever the material already does and only the seams darken.
# REMOVED (2026-08-25): the "Scute multiply" wiring. It inserted an Attribute
# x MULTIPLY node between whatever fed Base Color and the BSDF -- and the glTF
# exporter only recognises specific graphs (a plain image, or image x Color
# Attribute as COLOR_0). Faced with this one it dropped EVERYTHING: the skin's
# scale texture never entered the GLB and the material exported as flat white.
# Probe evidence: turtle_skin baseColorTexture=NO, images=['turtle_carapace'].
# The block was also dead weight on its own terms -- the "Scute" attribute it
# multiplied by has been flat 1.0 since the shell pattern moved into the baked
# map. Region darkening, if it returns, goes INTO the baked textures where it
# survives export, not into the node graph where it kills it.
print("[turtle] materiales: sin nudos extra sobre Base Color -- lo que se ve "
      "es lo que exporta")

# Plastron seam tone: the sunken lines get a darker value so they read when
# the belly is lit head-on, which is exactly the death pose.
_belly_lo, _belly_hi = PARTS["belly"]
_seam_faces = 0
for poly in me.polygons:
    if not all(_belly_lo <= vi < _belly_hi for vi in poly.vertices):
        continue
    c = poly.center
    uy = (c.y / (R * 1.06)) * 0.5 + 0.5
    cross = abs(math.sin(6.0 * math.pi * min(0.999, max(0.0, uy))))
    midl = min(1.0, abs(c.x) / (R * 0.10))
    dd = min(cross, midl)
    f = 0.62 if dd < 0.26 else 1.0
    if f < 1.0:
        _seam_faces += 1
    for li in poly.loop_indices:
        _col.data[li].color = (f, f, f, 1.0)
print("[turtle] plastron: %d caras en costura" % _seam_faces)
if _seam_faces == 0:
    raise SystemExit("[turtle] el plastron quedo liso -- se ve en la animacion de muerte")

# Skin variation by region. Flat skin is what makes a model read as plastic;
# real hide is darker where the sun hits and pale in the folds. Cheap, and it
# rides on the attribute that already exists.
_skin_ranges = [PARTS[k] for k in ("neck", "head", "leg_FL", "leg_FR", "leg_BL", "leg_BR")
                if k in PARTS]
_body_top = max(v.co.z for v in me.vertices)
for poly in me.polygons:
    if not any(in_ranges(vi, _skin_ranges) for vi in poly.vertices):
        continue
    c = poly.center
    up = max(0.0, min(1.0, c.z / max(_body_top, 1e-6)))
    # dark on the exposed upper surface, pale underneath
    f = 0.72 + 0.42 * up
    # and darker where the limb tucks under the shell
    if math.hypot(c.x, c.y) < R * 0.95 and c.z < _body_top * 0.55:
        f *= 0.80
    # Scale cells: a 3-axis interference pattern gives irregular polygonal
    # cells, closer to real reptile scutellation than a regular grid. Reads as
    # texture at distance, as scales up close.
    sc = (math.sin(c.x * 78.0) + math.sin(c.y * 71.0 + 1.7)
          + math.sin(c.z * 83.0 + 3.1))
    f *= 1.0 + 0.16 * math.tanh(sc * 1.4)
    for li in poly.loop_indices:
        _col.data[li].color = (f, f, f, 1.0)

# Eyes: dark, so they actually read as eyes rather than as bumps.
_eye_ranges = [PARTS[k] for k in ("eye_L", "eye_R") if k in PARTS]
_eye_faces = 0
for poly in me.polygons:
    if all(in_ranges(vi, _eye_ranges) for vi in poly.vertices):
        _eye_faces += 1
        for li in poly.loop_indices:
            _col.data[li].color = (0.10, 0.10, 0.11, 1.0)
print("[turtle] ojos: %d caras oscurecidas" % _eye_faces)
if _eye_faces == 0:
    raise SystemExit("[turtle] los ojos no recibieron color -- serian bultos del color de la piel")

# Bake INSIDE the build, before the export. This turtle shipped WHITE to Godot
# for a month because the procedural shader could not survive glTF and
# "verify the export" was a separate, optional step (_mob_audit_2026-08-22.md).
_bake_vcol.bake_and_report(turtle, "turtle")

# Re-assert the rest pose as the LAST thing before saving. Mute every NLA
# track and zero every key, so the .blend opens with the animal standing still
# instead of frozen mid-step (golem_guardian, 2026-07-19).
for _holder in (turtle.animation_data, me.shape_keys.animation_data):
    if _holder:
        for _tr in _holder.nla_tracks:
            _tr.mute = True
for _k in ALL_KEYS:
    kb[_k].value = 0.0
turtle.rotation_euler = (0.0, 0.0, 0.0)
turtle.location = (0.0, 0.0, 0.0)
scene.frame_set(1)
for _holder in (turtle.animation_data, me.shape_keys.animation_data):
    if _holder:
        for _tr in _holder.nla_tracks:
            _tr.mute = False
print("[turtle] pose de reposo re-afirmada antes de guardar")

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "turtle_wip.blend"))
# Export STRAIGHT to the path the game loads. There is no second copy and no
# manual step: two copies drift, and this one drifted by two builds without
# anything able to notice (see _deploy.py). It is also where the motor's
# showcase gate looks, so build, evidence and game agree on one file.
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _deploy  # noqa: E402

_deploy.export_glb(
    "turtle/turtle.glb",
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[turtle] DONE")
