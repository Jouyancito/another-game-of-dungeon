# build_bird.py — bird of prey (eagle base, recolorable to crow/hawk): fusiform
# body with chest mass, distinct head + real curved hooked-beak geometry, broad
# scalloped wings (feather suggestion via silhouette notches, not textures),
# fan tail, small tucked talons. Wingspan ~1.2m, hovers/soars ~1m above origin.
#   idle-loop   soaring glide: wings extended, subtle tip flex, slow body bob
#   move-loop   powered flight: full wing flaps, body rises/falls per beat
#   attack      tuck wings, dive forward-down (stoop), pull up (one-shot)
#   hit         tumble flinch: brief roll + quick wing jitter (one-shot)
#   death       wings crumple, falls to z=0, ends resting on its side (one-shot)
# Mirrors game/tools/blender/wasp/build_wasp.py (flying template, shape-key
# wings, per-clip camera override) + slime/build_slime.py (NLA export flow).
# Run: blender -b --python build_bird.py
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

HOVER_Z = 1.0  # soars above the origin ground plane, per brief


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def add_key(obj, name):
    """Contract §5 gotcha: shape_key_add defaults value=1.0 + from_mix=True ->
    catastrophic silent contamination on multi-key mobs. ALWAYS from_mix=False
    + value=0 immediately."""
    k = obj.shape_key_add(name=name, from_mix=False)
    k.value = 0.0
    return k


def make_part(op, **kwargs):
    op(**kwargs)
    return bpy.context.object


# ---------------------------------------------------------------------------
# BODY — fusiform torso (chest mass forward, tapers to tail), built along
# local -Y = front/beak direction (matches wasp/slime camera convention).
# ---------------------------------------------------------------------------
def build_torso():
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=18, radius=0.185)
    torso = bpy.context.object
    torso.name = "torso"
    me = torso.data
    for v in me.vertices:
        x, y, z = v.co
        if y < 0.0:  # chest / front half
            t = min(1.0, -y / 0.185)
            ny = y * 1.55
            bulge = 1.0 + 0.24 * math.sin(t * math.pi) * (1.0 - t * 0.25)
            nx = x * bulge
            nz = z * bulge
            if z < 0.0:
                nz *= 1.10  # belly slightly heavier
        else:  # tail half, taper toward rear
            t = min(1.0, y / 0.185)
            ny = y * 1.70
            taper = 1.0 - 0.58 * t ** 1.25
            nx = x * taper
            nz = z * taper
        v.co = Vector((nx, ny, nz))
    for p in me.polygons:
        p.use_smooth = True
    return torso


def build_head():
    head = make_part(bpy.ops.mesh.primitive_uv_sphere_add, radius=0.095,
                      location=(0.0, -0.345, 0.028), segments=22, ring_count=14)
    head.name = "head"
    head.scale = (0.92, 1.05, 0.96)
    return head


def build_beak(base_center):
    """Real curved geometry (a loft along a hooking path), not a cone — the
    silhouette signature. Base blends into the head, tip hooks sharply down."""
    path = [
        (0.0, 0.032, 0.0),
        (-0.045, 0.025, 0.006),
        (-0.082, 0.018, 0.003),
        (-0.112, 0.011, -0.012),
        (-0.132, 0.005, -0.030),
    ]
    N = 8
    rings = []
    for yoff, r, zc in path:
        center = base_center + Vector((0.0, yoff, zc))
        ring = [center + Vector((r * math.cos(2 * math.pi * i / N), 0.0,
                                  r * math.sin(2 * math.pi * i / N) * 0.72))
                for i in range(N)]
        rings.append(ring)
    tip = base_center + Vector((0.0, path[-1][0] - 0.014, path[-1][2] - 0.016))

    verts = []
    for ring in rings:
        verts.extend(ring)
    tip_idx = len(verts)
    verts.append(tip)

    faces = []
    for r in range(len(rings) - 1):
        for i in range(N):
            a = r * N + i
            b = r * N + (i + 1) % N
            c = (r + 1) * N + (i + 1) % N
            d = (r + 1) * N + i
            faces.append([a, b, c, d])
    last = (len(rings) - 1) * N
    for i in range(N):
        faces.append([last + i, last + (i + 1) % N, tip_idx])

    mesh = bpy.data.meshes.new("beak_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for p in mesh.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new("beak", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def build_eyes():
    eyes = []
    for side in (-1, 1):
        e = make_part(bpy.ops.mesh.primitive_uv_sphere_add, radius=0.016,
                       location=(side * 0.058, -0.375, 0.045), segments=10, ring_count=6)
        e.name = f"eye_{'L' if side < 0 else 'R'}"
        eyes.append(e)
    return eyes


def build_tail():
    """Fan tail: flat scalloped card, wide at the rear tip, root at the torso
    base. Built the same double-sided-card idiom as the wings."""
    root_y, tip_y = 0.30, 0.58
    half_width = 0.16
    outline = [
        (0.0, root_y),
        (half_width * 0.55, root_y + 0.04),
        (half_width * 0.85, root_y + 0.14),
        (half_width, tip_y - 0.05),
        (half_width * 0.55, tip_y),
        (0.0, tip_y + 0.02),
        (-half_width * 0.55, tip_y),
        (-half_width, tip_y - 0.05),
        (-half_width * 0.85, root_y + 0.14),
        (-half_width * 0.55, root_y + 0.04),
    ]
    thickness = 0.0006
    verts = []
    for lz in (thickness * 0.5, -thickness * 0.5):
        for (lx, ly) in outline:
            verts.append(Vector((lx, ly, 0.02 + lz)))
    n = len(outline)
    faces = [[i for i in range(n)], [n + i for i in reversed(range(n))]]
    mesh = bpy.data.meshes.new("tail_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for p in mesh.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new("tail", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def build_talon(root, side):
    """Small tucked foot: a stub + 3 tiny claw spikes, tucked against the
    belly (raptors fly with feet retracted, not dangling)."""
    parts = []
    rx, ry, rz = root
    stub = make_part(bpy.ops.mesh.primitive_cylinder_add, radius=0.014, depth=0.03,
                      location=(rx, ry, rz), rotation=(0.0, math.radians(20) * side, 0.0),
                      vertices=8)
    stub.name = f"talon_stub_{side}"
    parts.append(stub)
    for i, ang in enumerate((-18, 0, 18)):
        cx = rx + side * 0.006
        cy = ry - 0.018 + 0.006 * math.sin(math.radians(ang))
        cz = rz - 0.016
        claw = make_part(bpy.ops.mesh.primitive_cone_add, radius1=0.007, radius2=0.0,
                          depth=0.026, location=(cx, cy, cz),
                          rotation=(math.radians(100), 0.0, math.radians(ang)), vertices=6)
        claw.name = f"claw_{side}_{i}"
        parts.append(claw)
    return parts


# ---------------------------------------------------------------------------
# WINGS — broad, smooth surfaces with a scalloped trailing edge (3-5 scallops
# suggesting primary feathers). One pair, double-sided card idiom (wasp
# pattern): front ring + reversed-winding back ring, thin shell so backface
# culling never shows a hollow gap.
# ---------------------------------------------------------------------------
def wing_outline_local(span, chord, scallops=4, samples_per_scallop=6):
    leading = [
        (0.0, 0.0),
        (0.14 * span, 0.34 * chord),
        (0.38 * span, 0.50 * chord),
        (0.66 * span, 0.46 * chord),
        (0.90 * span, 0.28 * chord),
        (span, 0.10 * chord),
    ]
    # trailing edge: smooth root-deep -> tip-shallow taper, DENSELY sampled
    # with a cosine ripple layered on top (scallops bumps across the span) so
    # the primary-feather suggestion reads as rounded lobes, not a blocky
    # zigzag (a sparse 2-point-per-scallop version rendered as ugly notches).
    n = scallops * samples_per_scallop
    trailing = []
    for i in range(n, -1, -1):
        t = i / n  # 1 at tip .. 0 at root
        x = t * span
        taper = 0.30 * chord * (0.35 + 0.65 * t)
        scallop = 0.16 * chord * (0.5 - 0.5 * math.cos(2 * math.pi * scallops * t))
        trailing.append((x, -(taper + scallop)))
    return leading + trailing


def build_wing(hinge, span, chord, sweep_deg, dihedral_deg, side, flap_deg,
               scallops=4, thickness=0.0007):
    outline = wing_outline_local(span, chord, scallops)
    sweep = math.radians(sweep_deg)
    dihedral = math.radians(dihedral_deg)
    cy, sy = math.cos(dihedral), math.sin(dihedral)
    cz, sz = math.cos(sweep), math.sin(sweep)
    cf, sf = math.cos(math.radians(flap_deg)), math.sin(math.radians(flap_deg))
    ct, st = math.cos(math.radians(-58)), math.sin(math.radians(-58))    # tuck fold angle
    cc, sc = math.cos(math.radians(-95)), math.sin(math.radians(-95))    # crumple (death) fold

    def place(local):
        # local x is UNSIGNED (always built for the +side template) — side
        # mirroring happens LAST, after dihedral/sweep, so both wings get an
        # IDENTICAL symmetric V, not one drooping and one rising. (Gotcha:
        # baking `side` into lx BEFORE the dihedral rotation flips the sign of
        # the z1 = -lx*sy term on one side only -> asymmetric wing collapse.)
        lx, ly, lz = local
        x1 = lx * cy + lz * sy
        z1 = lx * sy + lz * cy   # + sign: positive dihedral raises the tip (soaring V), not anhedral droop
        y1 = ly
        x2 = x1 * cz - y1 * sz
        y2 = x1 * sz + y1 * cz
        z2 = z1
        return Vector(hinge) + Vector((side * x2, y2, z2))

    rest, flap, tip_flex, tuck, crumple = [], [], [], [], []
    for lz in (thickness * 0.5, -thickness * 0.5):
        for (lx, ly) in outline:
            rest.append(place((lx, ly, lz)))
            # move-loop: rigid up/down swing around the hinge line
            flap.append(place((lx * cf, ly, lx * sf + lz)))
            # idle-loop: only the OUTER third flexes, root stays flat (glide feel)
            span_t = min(1.0, lx / max(span, 1e-6))
            flex_amt = max(0.0, (span_t - 0.55) / 0.45) * 14.0
            ctf, stf = math.cos(math.radians(flex_amt)), math.sin(math.radians(flex_amt))
            tip_flex.append(place((lx * ctf, ly, lx * stf + lz)))
            # attack: wing folds back+in against the body (stoop tuck)
            tuck.append(place((lx * ct * 0.35, ly * 0.45 + lx * st * 0.35, lx * st * 0.35 + lz)))
            # death: limp asymmetric crumple, folded further and drooping
            crumple.append(place((lx * cc * 0.30, ly * 0.35 + lx * sc * 0.30, lx * sc * 0.55 + lz - 0.03)))
    return rest, flap, tip_flex, tuck, crumple


def build_wings():
    specs = [
        # hinge, span, chord, sweep_deg, dihedral_deg, flap_deg
        # hinge pushed CLEAR of the torso's own surface (~0.22 radius at this
        # Y) — a hinge embedded inside the body mesh causes the wing card to
        # pierce the torso shell near-coplanar with it, reading as a thin
        # dark Z-fighting seam sliced across the chest (found this build).
        dict(hinge=(0.205, -0.075, 0.100), span=0.44, chord=0.215, sweep=10, dihedral=24, flap=52),
    ]
    verts_rest, verts_flap, verts_tipflex, verts_tuck, verts_crumple, faces = [], [], [], [], [], []
    for spec in specs:
        for side in (1, -1):
            hinge = (spec["hinge"][0] * side, spec["hinge"][1], spec["hinge"][2])
            rest, flap, tip_flex, tuck, crumple = build_wing(
                hinge, spec["span"], spec["chord"], spec["sweep"], spec["dihedral"], side, spec["flap"])
            base_idx = len(verts_rest)
            verts_rest.extend(rest)
            verts_flap.extend(flap)
            verts_tipflex.extend(tip_flex)
            verts_tuck.extend(tuck)
            verts_crumple.extend(crumple)
            n = len(rest) // 2
            faces.append([base_idx + i for i in range(n)])
            faces.append([base_idx + n + i for i in reversed(range(n))])

    mesh = bpy.data.meshes.new("bird_wings_mesh")
    mesh.from_pydata(verts_rest, [], faces)
    mesh.update()
    for p in mesh.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new("bird_wings", mesh)
    bpy.context.collection.objects.link(obj)
    return obj, verts_flap, verts_tipflex, verts_tuck, verts_crumple


# ---------------------------------------------------------------------------
# assembly helpers
# ---------------------------------------------------------------------------
def join_objects(objs, final_name):
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = final_name
    return joined


def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def _base_mat(name, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        if hasattr(m, "surface_render_method"):
            m.surface_render_method = 'BLENDED'
        if hasattr(m, "blend_method"):
            m.blend_method = 'BLEND'
        m.use_backface_culling = True
    return m, nt, n


# ---------------------------------------------------------------------------
# PALETTE — parametric so a crow variant is a color swap (contract rule 1:
# max 3 colors per mob). EAGLE = rich brown body, lighter cream-tan head,
# yellow beak+talons. CROW = near-black body+head, dark beak+talons.
# ---------------------------------------------------------------------------
PALETTES = {
    "eagle": dict(
        body_dark=(0.16, 0.085, 0.045, 1.0),
        body_light=(0.30, 0.17, 0.09, 1.0),
        head_color=(0.72, 0.60, 0.42, 1.0),
        beak_color=(0.85, 0.60, 0.08, 1.0),
        talon_color=(0.80, 0.56, 0.07, 1.0),
        eye_color=(0.04, 0.03, 0.02, 1.0),
    ),
    "crow": dict(
        body_dark=(0.015, 0.015, 0.020, 1.0),
        body_light=(0.05, 0.045, 0.06, 1.0),
        head_color=(0.03, 0.03, 0.04, 1.0),
        beak_color=(0.05, 0.045, 0.045, 1.0),
        talon_color=(0.04, 0.035, 0.035, 1.0),
        eye_color=(0.30, 0.05, 0.03, 1.0),
    ),
}


def build_body_material(palette):
    m, nt, n = _base_mat("bird_body")
    n.inputs["Roughness"].default_value = 0.55

    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])

    # torso gradient: dark chest -> slightly lighter dorsal streaking (painterly,
    # §1.1 — 2-tone variation via noise, not flat color)
    tone_map = nt.nodes.new("ShaderNodeMapRange")
    tone_map.inputs["From Min"].default_value = -0.45
    tone_map.inputs["From Max"].default_value = 0.55
    nt.links.new(sep.outputs["Z"], tone_map.inputs["Value"])
    tone_mix, ta, tb, tout = _mix_rgba(nt)
    ta.default_value = palette["body_dark"]
    tb.default_value = palette["body_light"]
    nt.links.new(tone_map.outputs["Result"], tone_mix.inputs["Factor"])

    # head cap: light color only past the neck, deep in head territory. Torso
    # spans roughly y=[-0.29, +0.31] (chest tip to tail tip) and the head mass
    # sits further forward at y<=-0.30 — the range below is INVERTED on
    # purpose (From Min > From Max) so higher/torso-side Y -> 0 (dark) and
    # deeper/head-side Y -> 1 (light). A same-direction range here previously
    # caught almost the WHOLE torso (everything y > -0.20) as light — the
    # torso's own Y span extends well past that threshold toward the tail.
    head_map = nt.nodes.new("ShaderNodeMapRange")
    head_map.inputs["From Min"].default_value = -0.24
    head_map.inputs["From Max"].default_value = -0.34
    nt.links.new(sep.outputs["Y"], head_map.inputs["Value"])
    head_mix, ha, hb, hout = _mix_rgba(nt)
    hb.default_value = palette["head_color"]
    nt.links.new(tout, ha)
    nt.links.new(head_map.outputs["Result"], head_mix.inputs["Factor"])

    # painterly noise mottling (visible, subtle) so nothing reads flat
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 7.0
    noise.inputs["Detail"].default_value = 3.5
    mott, ma, mb, mout = _mix_rgba(nt)
    ma.default_value = (1.0, 1.0, 1.0, 1.0)
    mb.default_value = (0.82, 0.80, 0.78, 1.0)
    fac = nt.nodes.new("ShaderNodeMath")
    fac.operation = 'MULTIPLY'
    fac.inputs[1].default_value = 0.16
    nt.links.new(noise.outputs["Fac"], fac.inputs[0])
    nt.links.new(fac.outputs[0], mott.inputs["Factor"])
    mult = nt.nodes.new("ShaderNodeVectorMath")
    mult.operation = 'MULTIPLY'
    nt.links.new(hout, mult.inputs[0])
    nt.links.new(mout, mult.inputs[1])
    nt.links.new(mult.outputs[0], n.inputs["Base Color"])
    return m


def build_wing_material(palette):
    """Wings share the body's brown/tone family but add a stronger streak
    pattern along the span so the scalloped feather-suggestion silhouette is
    reinforced by paint, not just geometry (§1.1 painterly material)."""
    m, nt, n = _base_mat("bird_wing")
    n.inputs["Roughness"].default_value = 0.85
    # flat card at grazing angle: specular sheen washed it cream — kill it
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.0
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])
    stripe = nt.nodes.new("ShaderNodeMath")
    stripe.operation = 'MULTIPLY'
    stripe.inputs[1].default_value = 26.0
    nt.links.new(sep.outputs["X"], stripe.inputs[0])
    sine = nt.nodes.new("ShaderNodeMath")
    sine.operation = 'SINE'
    nt.links.new(stripe.outputs[0], sine.inputs[0])
    band = nt.nodes.new("ShaderNodeMath")
    band.operation = 'MULTIPLY'
    band.inputs[1].default_value = 0.10
    nt.links.new(sine.outputs[0], band.inputs[0])
    add = nt.nodes.new("ShaderNodeMath")
    add.operation = 'ADD'
    add.inputs[1].default_value = 0.18   # bias toward the dark brown: wings match the body
    nt.links.new(band.outputs[0], add.inputs[0])
    mix, wa, wb, wout = _mix_rgba(nt)
    wa.default_value = palette["body_dark"]
    wb.default_value = palette["body_light"]
    nt.links.new(add.outputs[0], mix.inputs["Factor"])
    nt.links.new(wout, n.inputs["Base Color"])
    return m


def build_accent_mats(palette):
    beak_m, _, bn = _base_mat("bird_beak")
    bn.inputs["Base Color"].default_value = palette["beak_color"]
    bn.inputs["Roughness"].default_value = 0.30
    talon_m, _, tn = _base_mat("bird_talon")
    tn.inputs["Base Color"].default_value = palette["talon_color"]
    tn.inputs["Roughness"].default_value = 0.35
    eye_m, _, en = _base_mat("bird_eye")
    en.inputs["Base Color"].default_value = palette["eye_color"]
    en.inputs["Roughness"].default_value = 0.12
    return beak_m, talon_m, eye_m


def set_palette(body_mat, wing_mat, beak_mat, talon_mat, eye_mat, palette):
    """Swap the color sockets in-place so an already-built shader graph can
    repaint for the crow render without rebuilding nodes."""
    def find(nt, node_type, factor_default=None):
        return [nd for nd in nt.nodes if nd.type == node_type]

    body_mixes = [nd for nd in body_mat.node_tree.nodes if nd.bl_idname == "ShaderNodeMix" and nd.data_type == 'RGBA']
    # order created: tone_mix, head_mix, mott (skip mott — greyscale multiplier)
    tone_mix, head_mix = body_mixes[0], body_mixes[1]
    [s for s in tone_mix.inputs if s.name == 'A' and s.type == 'RGBA'][0].default_value = palette["body_dark"]
    [s for s in tone_mix.inputs if s.name == 'B' and s.type == 'RGBA'][0].default_value = palette["body_light"]
    [s for s in head_mix.inputs if s.name == 'B' and s.type == 'RGBA'][0].default_value = palette["head_color"]

    wing_mixes = [nd for nd in wing_mat.node_tree.nodes if nd.bl_idname == "ShaderNodeMix" and nd.data_type == 'RGBA']
    wmix = wing_mixes[0]
    [s for s in wmix.inputs if s.name == 'A' and s.type == 'RGBA'][0].default_value = palette["body_dark"]
    [s for s in wmix.inputs if s.name == 'B' and s.type == 'RGBA'][0].default_value = palette["body_light"]

    beak_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = palette["beak_color"]
    talon_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = palette["talon_color"]
    eye_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = palette["eye_color"]


# ---------------------------------------------------------------------------
# MAIN BUILD
# ---------------------------------------------------------------------------
torso = build_torso()
head = build_head()
beak = build_beak(Vector((0.0, -0.345 - 0.088, 0.028)))
eye_parts = build_eyes()
tail = build_tail()
talon_parts = build_talon((0.05, -0.02, -0.16), 1) + build_talon((-0.05, -0.02, -0.16), -1)

palette = PALETTES["eagle"]
body_mat = build_body_material(palette)
wing_mat = build_wing_material(palette)
beak_mat, talon_mat, eye_mat = build_accent_mats(palette)

body_parts = [torso, head, tail]
for o in body_parts:
    o.data.materials.append(body_mat)
for o in eye_parts:
    o.data.materials.append(eye_mat)
beak.data.materials.append(beak_mat)
for o in talon_parts:
    o.data.materials.append(talon_mat)

for o in body_parts + eye_parts + talon_parts + [beak]:
    for p in o.data.polygons:
        p.use_smooth = True

body = join_objects(body_parts + eye_parts + talon_parts + [beak], "bird_body")
me = body.data

wings, wing_flap, wing_tipflex, wing_tuck, wing_crumple = build_wings()
wings.data.materials.append(wing_mat)
wings.parent = body

# ---------- wing shape keys ----------
add_key(wings, "Basis")
wsk_flap = add_key(wings, "flap")
for i, co in enumerate(wing_flap):
    wsk_flap.data[i].co = co
wsk_tipflex = add_key(wings, "tip_flex")
for i, co in enumerate(wing_tipflex):
    wsk_tipflex.data[i].co = co
wsk_tuck = add_key(wings, "tuck")
for i, co in enumerate(wing_tuck):
    wsk_tuck.data[i].co = co
wsk_crumple = add_key(wings, "crumple")
for i, co in enumerate(wing_crumple):
    wsk_crumple.data[i].co = co
wing_kb = wings.data.shape_keys.key_blocks

FPS = 24
scene.render.fps = FPS

# ---------------------------------------------------------------------------
# animation samplers: body (object transform only) + wings (shape keys)
# ---------------------------------------------------------------------------
def anim_idle_body(t):
    return {"z": HOVER_Z + 0.05 * math.sin(2 * math.pi * t), "rx": math.radians(-4)}


def anim_idle_wing(t):
    return {"tip_flex": 0.5 + 0.5 * math.sin(2 * math.pi * 0.6 * t)}


def anim_move_body(t):
    w = math.sin(2 * math.pi * 2 * t)
    return {"z": HOVER_Z + 0.09 * w, "rx": math.radians(-10) + math.radians(6) * w,
            "y": 0.02 * math.sin(2 * math.pi * 2 * t + math.pi / 2)}


def anim_move_wing(t):
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 2 * t)}


def anim_attack_body(t):
    v = {"z": HOVER_Z, "rx": 0.0}
    if t < 0.20:  # anticipation: level off, wings start tucking
        u = t / 0.20
        v["rx"] = lerp(0.0, math.radians(-8), u)
    elif t < 0.55:  # stoop dive: steep pitch forward-down
        u = (t - 0.20) / 0.35
        v["rx"] = lerp(math.radians(-8), math.radians(72), u)
        v["z"] = HOVER_Z - (HOVER_Z - 0.22) * u
        v["y"] = lerp(0.0, -0.28, u)
    else:  # pull up
        u = (t - 0.55) / 0.45
        v["rx"] = lerp(math.radians(72), math.radians(-6), u)
        v["z"] = lerp(0.22, HOVER_Z * 0.92, u)
        v["y"] = lerp(-0.28, -0.18, u)
    return v


def anim_attack_wing(t):
    if t < 0.20:
        u = t / 0.20
        return {"tuck": lerp(0.0, 0.85, u)}
    elif t < 0.55:
        return {"tuck": 0.95}
    else:
        u = (t - 0.55) / 0.45
        return {"tuck": lerp(0.95, 0.0, u), "flap": 0.5 + 0.5 * math.sin(2 * math.pi * 3 * u)}


def anim_hit_body(t):
    # roll (Y, the forward/roll axis) not yaw (Z) — yawing spins the bird's
    # nose to face sideways relative to the fixed camera and recreates the
    # nose-on foreshortening bug; rolling keeps the profile readable.
    return {"z": HOVER_Z, "ry": 0.55 * math.sin(math.pi * min(1.0, t * 1.5)),
            "x": 0.10 * math.sin(math.pi * t)}


def anim_hit_wing(t):
    # quick chaotic jitter — feathers ruffle
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 10 * t), "tip_flex": 0.3 * math.sin(2 * math.pi * 14 * t)}


def anim_death_body(t):
    # "ends resting on its side" = ROLLS onto its side (rotate around the
    # forward/Y axis), NOT yaw (Z) — yaw would spin the long axis to point at
    # the camera and collapse the silhouette to a nose-on circle (caught this
    # exact bug on the first death render: the resting frame was a sphere).
    if t < 0.60:
        u = t / 0.60
        return {"z": HOVER_Z * (1.0 - u), "rx": lerp(0.0, math.radians(20), u),
                "ry": lerp(0.0, math.radians(70), u)}
    u = (t - 0.60) / 0.40
    return {"z": 0.0, "rx": lerp(math.radians(20), math.radians(10), u),
            "ry": lerp(math.radians(70), math.radians(88), u)}


def anim_death_wing(t):
    u = min(1.0, t / 0.6)
    return {"crumple": lerp(0.0, 1.0, u)}


ANIMS = {
    "idle-loop": (48, anim_idle_body, anim_idle_wing),
    "move-loop": (24, anim_move_body, anim_move_wing),
    "attack": (30, anim_attack_body, anim_attack_wing),
    "hit": (14, anim_hit_body, anim_hit_wing),
    "death": (32, anim_death_body, anim_death_wing),
}

WING_KEYS = ("flap", "tip_flex", "tuck", "crumple")

body_obj_ad = body.animation_data_create()
wing_sk_ad = wings.data.shape_keys.animation_data_create()

actions = {}
for name, (frames, bsamp, wsamp) in ANIMS.items():
    act_bobj = bpy.data.actions.new(f"{name}_body_obj")
    act_wsk = bpy.data.actions.new(f"{name}_wing_sk")
    body_obj_ad.action = act_bobj
    wing_sk_ad.action = act_wsk
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        bv = bsamp(t)
        wv = wsamp(t)
        body.location.x = bv.get("x", 0.0)
        body.location.y = bv.get("y", 0.0)
        body.location.z = bv.get("z", HOVER_Z)
        body.keyframe_insert("location", frame=f)
        body.rotation_euler.x = bv.get("rx", 0.0)
        body.rotation_euler.y = bv.get("ry", 0.0)
        body.rotation_euler.z = bv.get("rz", 0.0)
        body.keyframe_insert("rotation_euler", frame=f)
        for k in WING_KEYS:
            wing_kb[k].value = wv.get(k, 0.0)
            wing_kb[k].keyframe_insert("value", frame=f)
    actions[name] = (frames, act_bobj, act_wsk)
body_obj_ad.action = None
wing_sk_ad.action = None


def reset_rest_pose():
    body.location = (0.0, 0.0, HOVER_Z)
    body.rotation_euler = (0.0, 0.0, 0.0)
    for k in WING_KEYS:
        wing_kb[k].value = 0.0


reset_rest_pose()

# ---------- showcase-ficha scene (contract §4) ----------
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
    lo.rotation_quaternion = (Vector(loc) - Vector((0, 0, HOVER_Z))).to_track_quat('Z', 'Y')


add_light("key", (-1.9, -0.6, HOVER_Z + 1.5), 110, 1.6)
add_light("fill", (1.7, -0.5, HOVER_Z + 0.6), 30, 1.5)
add_light("rim", (0.4, 1.2, HOVER_Z + 1.3), 130, 1.5)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, HOVER_Z + 0.05)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-1.55, -1.25, HOVER_Z + 0.80)
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

BASE_TARGET_Z = HOVER_Z + 0.05
BASE_CAM_LOC = Vector((-1.55, -1.25, HOVER_Z + 0.80))


def frame_camera_for_clip(name):
    """attack dives from HOVER_Z down to ~0.22 and death falls to 0 — the base
    hover-framed camera loses the action past mid-clip (same problem as the
    wasp's death fall). Pull back + re-center vertically for both clips."""
    if name == "death":
        target.location = (0.0, 0.0, HOVER_Z * 0.35)
        cam.location = (-2.6, -0.75, HOVER_Z * 0.35 + 0.75)
    elif name == "attack":
        target.location = (0.0, -0.10, HOVER_Z * 0.55)
        cam.location = (-2.7, -0.85, HOVER_Z * 0.55 + 0.75)
    else:
        target.location = (0.0, 0.0, BASE_TARGET_Z)
        cam.location = BASE_CAM_LOC


# ---------- hero + crow stills: scale silhouette (mob style contract §4, Pokedex rule) ----------
# Bird SOARS (HOVER_Z=1.0) — the silhouette stands on the ground (z=0) so the
# still shows the TRUE height comparison. Silhouette is added ONCE and covers
# both palette stills (identical camera/framing), then removed before the
# anim-frame loop below (frame_camera_for_clip resets cam/target from the
# BASE_* constants on its first call regardless, but we restore explicitly
# for a clean .blend).
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY = 0.62, 0.62  # bird wingspan half-extent (dihedral-projected) / beak-to-tail
MOB_ZMAX = HOVER_Z + 0.30     # silhouette stands at z=0, bird soars — combined top is generous
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

# ---------- hero render (eagle palette) ----------
scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.filepath = os.path.join(REN_DIR, "bird_hero.png")
bpy.ops.render.render(write_still=True)

# ---------- crow palette still (one extra render, no separate GLB) ----------
set_palette(body_mat, wing_mat, beak_mat, talon_mat, eye_mat, PALETTES["crow"])
scene.render.filepath = os.path.join(REN_DIR, "bird_crow.png")
bpy.ops.render.render(write_still=True)
set_palette(body_mat, wing_mat, beak_mat, talon_mat, eye_mat, PALETTES["eagle"])

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- renders: preview frames per animation (eagle palette, shipped look) ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for name, (frames, act_bobj, act_wsk) in actions.items():
    body_obj_ad.action = act_bobj
    wing_sk_ad.action = act_wsk
    frame_camera_for_clip(name)
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[bird] frames", name)
body_obj_ad.action = None
wing_sk_ad.action = None
reset_rest_pose()  # gotcha: actions leave last evaluated values behind
target.location = (0.0, 0.0, BASE_TARGET_Z)
cam.location = BASE_CAM_LOC

# ---------- push all actions to NLA tracks (same name across data-blocks) ----------
for name, (frames, act_bobj, act_wsk) in actions.items():
    tro = body_obj_ad.nla_tracks.new()
    tro.name = name
    tro.strips.new(name, 1, act_bobj)
    trw = wing_sk_ad.nla_tracks.new()
    trw.name = name
    trw.strips.new(name, 1, act_wsk)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "bird_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "bird.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[bird] DONE")
