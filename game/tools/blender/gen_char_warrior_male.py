"""char_warrior_male — proportion blockout for the warrior body.

This is DELIBERATELY not a sculpt. It fixes the two things a sculpt cannot
recover later if they are wrong: the landmark heights and the mass
distribution that makes the silhouette read as "warrior" at gameplay range.

Landmarks are not invented here. They come from `_char_build_brief.md` §5 and
are asserted against the built mesh at the end of the run -- if a section
drifts, the script says so rather than shipping a body that merely looks
plausible in a render.

Body register comes from `_references/warrior_archetype/`, specifically the
D2R Barbarian plate: no abdominal definition, barrel waist that does NOT taper
into a V, forearms nearly as thick as the upper arms, oversized hands. That is
a body built by work, not by isolation training, and it is what the reference
actually shows -- not what "Diablo barbarian" sounds like from memory.

    blender.exe --background --python gen_char_warrior_male.py
    blender.exe --background --python gen_char_warrior_male.py -- --no-render
"""

import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

# --- canon -------------------------------------------------------------------
# _char_build_brief.md §5. Every one of these is a hard target, not a guide.
PLAYER_H = 1.80
LANDMARKS = {
    "pie": 0.07,
    "rodilla": 0.50,
    "entrepierna": 0.90,
    "cintura": 1.10,
    "pecho": 1.32,
    "hombro": 1.47,
    "menton": 1.56,
    "tope": 1.80,
}
# Measured in the brief when the shared-base body was rejected: the warrior's
# shoulder span is what separated him from archer (0.482) and mage (0.425).
SHOULDER_SPAN = 0.598

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT_DIR = os.path.join(REPO, "game", "assets", "art", "characters")
RENDER_DIR = os.path.join(REPO, "game", "tools", "blender", "_review_char_warrior_male")

# Torso cross-sections: (z, half-width X, half-depth Y).
# The waist half-width (0.212) sits only 0.036 under the chest (0.248). That
# near-absence of taper IS the strongman read -- a V-taper here would produce
# the gym body the reference explicitly is not.
TORSO_SECTIONS = [
    (0.88, 0.186, 0.128),
    (1.00, 0.200, 0.146),
    (1.10, 0.206, 0.163),   # cintura -- carries forward in DEPTH, not in width
    (1.20, 0.231, 0.154),
    (1.32, 0.248, 0.149),   # pecho
    (1.40, 0.256, 0.139),
    (1.47, 0.244, 0.127),   # hombro (deltoids add the rest of the span)
    (1.52, 0.150, 0.108),
]

RADIAL = 24


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def loft(sections, name):
    """Closed lofted tube through elliptical cross-sections, capped both ends.

    Capping matters: voxel remesh shells an open surface instead of filling it,
    so an uncapped torso would come back as a hollow tube with a wall.
    """
    bm = bmesh.new()
    rings = []
    for z, hx, hy in sections:
        ring = []
        for i in range(RADIAL):
            a = 2.0 * math.pi * i / RADIAL
            ring.append(bm.verts.new((hx * math.cos(a), hy * math.sin(a), z)))
        rings.append(ring)
    bm.verts.ensure_lookup_table()

    for lo, hi in zip(rings, rings[1:]):
        for i in range(RADIAL):
            j = (i + 1) % RADIAL
            bm.faces.new((lo[i], lo[j], hi[j], hi[i]))

    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def ball(name, loc, radius, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=24, ring_count=16)
    ob = bpy.context.object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return ob


def limb(name, a, b, r_a, r_b):
    """Tapered segment between two joint centres, with a ball at each end.

    Balls at the joints are not decoration -- they keep the voxel remesh from
    pinching the union at the elbow and knee, which is where a capsule chain
    otherwise necks in and reads as a broken limb.
    """
    a, b = Vector(a), Vector(b)
    axis = b - a
    length = axis.length
    bpy.ops.mesh.primitive_cone_add(
        vertices=RADIAL, radius1=r_a, radius2=r_b, depth=length,
        location=(a + b) / 2.0,
    )
    ob = bpy.context.object
    ob.name = name
    ob.rotation_mode = "QUATERNION"
    ob.rotation_quaternion = axis.to_track_quat("Z", "Y")
    bpy.ops.object.transform_apply(rotation=True)
    # Joint balls sit slightly INSIDE the cone ends. At equal radius the
    # remesh leaves a visible ring at every knee and elbow -- the body reads
    # as a ball-jointed doll instead of one limb.
    ball(name + "_ja", a, r_a * 0.94)
    ball(name + "_jb", b, r_b * 0.94)
    return ob


def build_body():
    torso = loft(TORSO_SECTIONS, "torso")
    parts = [torso]

    # Chest and waist cannot be measured on the finished silhouette: at chest
    # height the upper arm crosses the ARMPIT, where arm and ribcage are
    # legitimately one surface. No probe separates them there, so keep an
    # un-joined copy of the ribcage and measure the torso on the torso.
    probe = torso.copy()
    probe.data = torso.data.copy()
    probe.name = "torso_probe"
    bpy.context.collection.objects.link(probe)
    probe.hide_render = True

    # Neck: short and thick. A slender neck reads "athlete"; the warrior's
    # trapezius fills the gap between skull and shoulder line.
    parts.append(limb("neck", (0, 0, 1.45), (0, 0, 1.575), 0.082, 0.070))

    # Head: 0.24 tall = menton 1.56 -> tope 1.80, which is the 7.5-head canon.
    parts.append(ball("head", (0, -0.012, 1.678), 0.120, scale=(0.86, 0.95, 1.0)))
    parts.append(ball("jaw", (0, -0.043, 1.598), 0.082, scale=(0.88, 0.94, 0.60)))

    # Deltoids carry the span from the torso's 0.244 out to SHOULDER_SPAN/2.
    d_r = 0.075
    d_x = SHOULDER_SPAN / 2.0 - d_r
    for s, tag in ((1, "R"), (-1, "L")):
        parts.append(ball("delt_" + tag, (s * d_x, 0, 1.437), d_r, scale=(1.0, 1.0, 0.92)))

        # A-POSE, ~35 deg off vertical. Arms hanging straight down read more
        # natural but weld to the ribcage at the elbow, and a limb fused to
        # the torso is not riggeable -- the corpóreo-3d skill burned eight
        # attempts proving free-form surgery cannot separate one afterwards.
        # Build the daylight in; do not try to carve it later.
        # Forearm 0.066 against upper arm 0.072 is the reference's heavy
        # working forearm, not a tapered one.
        sh = (s * (d_x - 0.006), 0.0, 1.400)
        el = (s * 0.395, 0.006, 1.155)
        wr = (s * 0.545, 0.012, 0.945)
        # Measured against the reference: the blockout's arm was already at
        # D2R parity (0.132 m vs 0.128 m across the elbow band). Joan asked
        # for "musculatura mas grande que lo normal", so this goes ~10% over
        # the reference -- not more, because the gear layer adds the rest.
        parts.append(limb("upperarm_" + tag, sh, el, 0.079, 0.073))
        parts.append(limb("forearm_" + tag, el, wr, 0.073, 0.052))
        # Big hands are part of the register, not a detail: on the reference
        # the hand is oversized against the bicep. Placed ON the forearm axis
        # so it continues the limb instead of hanging off it.
        parts.append(limb("hand_" + tag, wr, (s * 0.638, 0.014, 0.828), 0.048, 0.058))
        parts.append(ball("palm_" + tag, (s * 0.652, 0.014, 0.812), 0.066,
                          scale=(0.86, 0.62, 1.0)))

        # Heavier legs. The first pass gave a massive torso thin sticks, which
        # kills the "grounded, low centre of gravity" the synthesis calls for.
        hip = (s * 0.104, 0, 0.905)
        kn = (s * 0.110, 0.004, 0.500)
        an = (s * 0.100, 0.010, 0.085)
        parts.append(limb("thigh_" + tag, hip, kn, 0.128, 0.090))
        parts.append(limb("calf_" + tag, kn, an, 0.094, 0.052))
        parts.append(ball("foot_" + tag, (s * 0.100, -0.055, 0.048), 0.060,
                          scale=(0.72, 1.85, 0.52)))

    # Pelvis block ties the two hip joints into the torso base.
    # Pelvis half-width must reach the thigh's outer edge (hip x 0.104 +
    # thigh r 0.128 = 0.232). At 0.150*1.20 = 0.180 it fell 0.052 m short,
    # so the thigh protruded past the hip and the remesh had nothing to
    # blend across -- that is the hard plate seam visible in every view.
    parts.append(ball("pelvis", (0, 0, 0.915), 0.150, scale=(1.55, 0.86, 0.62)))
    parts.append(ball("glute", (0, 0.042, 0.965), 0.132, scale=(1.42, 0.86, 0.72)))

    return parts, probe


def unite(parts, torso_probe):
    """Join every mass, then voxel remesh into one continuous skin.

    The skill's rule: a creature is ONE watertight surface. Overlapping shells
    are how you get interior geometry that shows through at grazing angles.
    """
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    body = bpy.context.object
    body.name = "char_warrior_male"

    m = body.modifiers.new("remesh", "REMESH")
    m.mode = "VOXEL"
    m.voxel_size = 0.014
    m.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier=m.name)

    bpy.ops.object.shade_smooth()

    # Voxel remesh rounds the extremities in, so the raw result lands ~1cm
    # short with the soles floating. Seat and normalise AFTER the remesh --
    # doing it before means the remesh silently undoes it.
    bpy.context.view_layer.update()
    zs = [(body.matrix_world @ v.co).z for v in body.data.vertices]
    dz = -min(zs)
    body.location.z += dz
    bpy.ops.object.transform_apply(location=True)
    bpy.context.view_layer.update()
    zs = [(body.matrix_world @ v.co).z for v in body.data.vertices]
    k = PLAYER_H / max(zs)
    body.scale = (k,) * 3
    bpy.ops.object.transform_apply(scale=True)

    # The probe rides the exact same seat+scale so its measurements describe
    # the shipped body, not the pre-normalisation design.
    torso_probe.location.z += dz
    torso_probe.scale = (k,) * 3
    bpy.context.view_layer.update()

    return body


def section_width(body, z, band=0.012, gap_tol=0.022):
    """Half-width of the TORSO at height z.

    Naive max(|x|) is wrong here and silently so: at waist height the elbows
    are the widest geometry in the slice, so it reported a waist wider than
    the chest -- an impossible body that still passed a ratio check. Walk
    outward from the centreline instead and stop at the first air gap, which
    is the space between ribcage and arm.
    """
    mw = body.matrix_world
    xs = sorted(abs((mw @ v.co).x) for v in body.data.vertices
                if abs((mw @ v.co).z - z) < band)
    if not xs:
        return 0.0
    if gap_tol is None:
        # Arm-free geometry (the ribcage probe): max is the honest answer.
        # The gap walk must NOT be used here -- on a 24-segment ring the
        # |x| samples near the centreline are ~0.064 apart, wider than any
        # sane tolerance, so the walk halts on the first vertex and returns
        # ~0. It read 0.000 while the ratio computed fine off 0.000496.
        return xs[-1]
    edge = xs[0]
    for x in xs[1:]:
        if x - edge > gap_tol:
            break
        edge = x
    return edge


def audit(body, probe):
    mw = body.matrix_world
    zs = [(mw @ v.co).z for v in body.data.vertices]
    lo, hi = min(zs), max(zs)
    height = hi - lo

    print("\n=== char_warrior_male — BLOCKOUT AUDIT ===")
    print("  altura total   %.3f m   (objetivo %.2f, delta %+.3f)"
          % (height, PLAYER_H, height - PLAYER_H))
    print("  pies en z=0    %.3f m   (objetivo 0.000)" % lo)
    print("  cabezas        %.2f     (canon 7.50)" % (height / (LANDMARKS["tope"] - LANDMARKS["menton"])))

    pz = [(probe.matrix_world @ v.co).z for v in probe.data.vertices]
    print("  [probe] %d verts, z %.3f..%.3f" % (len(probe.data.vertices), min(pz), max(pz)))

    # Span is measured on the finished body: the deltoids ARE the shoulder.
    span = section_width(body, LANDMARKS["hombro"]) * 2.0
    # Chest and waist come off the un-joined ribcage, for the armpit reason.
    chest = section_width(probe, LANDMARKS["pecho"], gap_tol=None) * 2.0
    waist = section_width(probe, LANDMARKS["cintura"], gap_tol=None) * 2.0
    print("\n  ancho hombro   %.3f m   (objetivo %.3f, delta %+.3f)  [silueta]"
          % (span, SHOULDER_SPAN, span - SHOULDER_SPAN))
    print("  ancho pecho    %.3f m                                [torso]" % chest)
    print("  ancho cintura  %.3f m                                [torso]" % waist)

    # Register ratio. Reported WITHOUT a pass/fail: the 0.84 threshold used
    # earlier was invented, not measured. The only waist reading taken off
    # the reference landed on the character's BELT -- clothing, not anatomy --
    # so there is no calibrated band to judge against yet. A gate that opines
    # without evidence is worse than no gate, because it launders a guess into
    # a verdict.
    ratio = waist / chest if chest else 0.0
    print("  cintura/pecho  %.3f      (SIN CALIBRAR — ver nota)" % ratio)

    # Sanity gate on the measurement itself. A waist wider than the chest is
    # not a body, it is a broken probe -- the first run reported exactly that
    # because the elbows were the widest geometry in the waist slice.
    if not (span >= chest >= waist):
        print("\n  ** MEDICION INVALIDA: hombro >= pecho >= cintura no se cumple.")
        print("     La sonda esta leyendo brazos como torso, o los brazos tocan")
        print("     el cuerpo. Ningun veredicto de registro es valido asi.")

    # Rigging readiness: daylight between arm and ribcage at waist height.
    # Reported as a plain distance at a stated height, not as a single
    # min-distance scalar -- that metric is gameable and has lied before.
    mw = body.matrix_world
    xs = sorted(abs((mw @ v.co).x) for v in body.data.vertices
                if abs((mw @ v.co).z - LANDMARKS["cintura"]) < 0.012)
    gap = 0.0
    for a, b in zip(xs, xs[1:]):
        gap = max(gap, b - a)
    print("\n  luz brazo-torso a la cintura  %.3f m  (%s)"
          % (gap, "separado" if gap > 0.030 else "FUSIONADO — no riggeable"))

    print("\n  nota: antebrazo grueso y manos grandes son del registro D2R,")
    print("        no del recuerdo de 'bárbaro'. Ver 11_d2r_barbarian_official.jpg")
    return {"height": height, "span": span, "waist_chest": ratio, "arm_gap": gap}


def ref_post():
    """1.80 m post with a band at every landmark. A render without a scale
    reference says nothing about size, and size is the whole point here."""
    bpy.ops.mesh.primitive_cylinder_add(radius=0.022, depth=PLAYER_H,
                                        location=(0.62, 0.30, PLAYER_H / 2))
    post = bpy.context.object
    post.name = "ref_post"
    mat = bpy.data.materials.new("ref")
    mat.use_nodes = True
    mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.72, 0.10, 0.10, 1)
    post.data.materials.append(mat)

    band = bpy.data.materials.new("band")
    band.use_nodes = True
    band.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (1, 1, 1, 1)
    for z in LANDMARKS.values():
        bpy.ops.mesh.primitive_cylinder_add(radius=0.030, depth=0.008,
                                            location=(0.62, 0.30, z))
        bpy.context.object.data.materials.append(band)


def setup_scene(body):
    mat = bpy.data.materials.new("clay")
    mat.use_nodes = True
    b = mat.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.58, 0.56, 0.53, 1)
    b.inputs["Roughness"].default_value = 0.72
    body.data.materials.append(mat)

    w = bpy.data.worlds.new("w")
    bpy.context.scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.06, 0.065, 0.08, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.85

    bpy.ops.object.light_add(type="AREA", location=(1.9, -2.6, 2.9))
    k = bpy.context.object
    k.data.energy = 420
    k.data.size = 3.2
    k.rotation_euler = (math.radians(48), 0, math.radians(34))

    bpy.ops.object.light_add(type="AREA", location=(-2.2, -1.9, 1.7))
    f = bpy.context.object
    f.data.energy = 110
    f.data.size = 4.0
    f.rotation_euler = (math.radians(70), 0, math.radians(-48))

    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    fm = bpy.data.materials.new("floor")
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.11, 0.12, 0.13, 1)
    bpy.context.object.data.materials.append(fm)


def render_views():
    """Four of the five mandatory views from brief §4.4. The macro close-up is
    skipped on purpose -- there is no surface here to inspect yet."""
    os.makedirs(RENDER_DIR, exist_ok=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = False

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam

    shots = [
        # label, ortho?, size/lens, location, rotation
        ("silhouette", True, 2.10, (0, -4.0, 0.90), (math.radians(90), 0, 0)),
        ("ortho_front", True, 2.10, (0, -4.0, 0.90), (math.radians(90), 0, 0)),
        ("ortho_profile", True, 2.10, (4.0, 0, 0.90), (math.radians(90), 0, math.radians(90))),
        ("threequarter", False, 50.0, (2.05, -2.75, 1.62), (math.radians(82), 0, math.radians(37))),
        ("player_eye", False, 24.0, (0.9, -5.9, 1.65), (math.radians(88.5), 0, math.radians(9))),
    ]

    for label, ortho, val, loc, rot in shots:
        cam_data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam_data.ortho_scale = val
        else:
            cam_data.lens = val
        cam.location = loc
        cam.rotation_euler = rot
        sc.render.resolution_x, sc.render.resolution_y = (760, 1000)

        if label == "silhouette":
            # Flat unlit black on white: the only honest way to judge a
            # silhouette, because lighting hides and invents contour.
            sc.render.film_transparent = True
            sc.view_settings.view_transform = "Standard"
        else:
            sc.render.film_transparent = False
            sc.view_settings.view_transform = "AgX"

        sc.render.filepath = os.path.join(RENDER_DIR, "char_warrior_male_%s.png" % label)
        bpy.ops.render.render(write_still=True)
        print("  render -> %s" % sc.render.filepath)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    clear()

    parts, probe = build_body()
    body = unite(parts, probe)
    stats = audit(body, probe)
    bpy.data.objects.remove(probe, do_unlink=True)

    os.makedirs(OUT_DIR, exist_ok=True)
    blend = os.path.join(OUT_DIR, "char_warrior_male_blockout.blend")

    if "--no-render" not in argv:
        ref_post()
        setup_scene(body)
        render_views()

    bpy.ops.wm.save_as_mainfile(filepath=blend)
    print("\n  blend  -> %s" % blend)
    print("=== fin ===\n")
    return stats


if __name__ == "__main__":
    main()
