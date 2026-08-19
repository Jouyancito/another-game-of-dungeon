"""truth_showcase.py — multi-angle showcase rendered FROM THE SHIPPED GLBs.

`_glb_truth_render.py` is the numeric probe (VCOL / mats / tris / height) and
it is authoritative for "what does the file actually contain". Its camera
rig, however, frames one hero asset plus a scale silhouette parked at
`x_max + height*0.9`; on an 8 m asymmetric tree that bbox pushes the subject
into a corner, so its PNG is not usable as a look verdict.

This script covers the other half: it imports the five shipped per-variant
GLBs — nothing from the build scene, no Blender-side materials — lays them
out with the 1.8 m player-reference post, and renders the multi-angle set
plus close-ups the review protocol requires. Everything visible here came out
of the .glb.

It also measures crown porosity (P10) off a transparent-film silhouette pass,
because "no number, no verdict".

Run:
  blender.exe --background --factory-startup --python-exit-code 1 \
      --python truth_showcase.py
"""
import bpy
import bmesh
import math
import os
import sys

import numpy as np

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(SCRIPT_DIR, "renders", "_truth")
os.makedirs(REN_DIR, exist_ok=True)
ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera",
    "vegetation", "tree_pack"))

import glob as _glob, os as _os
_here = _os.path.dirname(_os.path.abspath(__file__))
_glbdir = _os.path.join(_here, "..", "..", "..", "assets", "art", "piso1_pradera",
                        "vegetation", "tree_pack")
VARIANTS = sorted(
    _os.path.splitext(_os.path.basename(f))[0].removeprefix("env_")
    for f in _glob.glob(_os.path.join(_glbdir, "env_tree_*.glb")))
print(f"[truth_showcase] {len(VARIANTS)} variants discovered")

# Spacing and the lineup camera both scale with the variant count now. They were
# hardcoded for a 5-variant pack; at 17 variants and a 21 m ancient crown the old
# numbers cropped most of the pack out of frame and overlapped the rest.
SPACING = 13.0

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'   # 5.1 renamed the enum back
scene.eevee.taa_render_samples = 96
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.view_settings.view_transform = 'Standard'

world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.40, 0.53, 0.66, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    scene.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')


add_light("key", (-14.0, -30.0, 26.0), 5000, 14.0)
add_light("fill", (18.0, -22.0, 12.0), 900, 12.0)
add_light("rim", (4.0, 24.0, 18.0), 3200, 10.0)

# ground
# Ground must outrun the lineup, or the end variants stand off the grass and
# the render reads as floating geometry -- a showcase bug that looks like an
# asset bug. Sized from the variant count, like the camera.
bpy.ops.mesh.primitive_plane_add(
    size=max(140.0, SPACING * (len(VARIANTS) - 1) + 90.0), location=(0.0, 0.0, 0.0))
gp = bpy.context.object
gmat = bpy.data.materials.new("g")
gmat.use_nodes = True
gmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.075, 0.105, 0.045, 1.0)
gmat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.95
gp.data.materials.append(gmat)

# 1.8 m player-reference post (mandatory on every showcase render)
ref_mesh = bpy.data.meshes.new("player_ref")
rb = bmesh.new()
bmesh.ops.create_cube(rb, size=1.0)
for v in rb.verts:
    v.co.x *= 0.36
    v.co.y *= 0.36
    v.co.z = v.co.z * 1.8 + 0.9
rb.to_mesh(ref_mesh)
rb.free()
rmat = bpy.data.materials.new("ref")
rmat.use_nodes = True
rmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.22, 0.18, 1.0)
ref_mesh.materials.append(rmat)


def spawn_ref(loc):
    o = bpy.data.objects.new("player_ref", ref_mesh)
    o.location = loc
    scene.collection.objects.link(o)
    return o


groups = {}
for i, name in enumerate(VARIANTS):
    path = os.path.join(ASSET_DIR, f"env_{name}.glb")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    x = (i - (len(VARIANTS) - 1) / 2.0) * SPACING
    for o in new:
        if o.parent is None:
            o.location.x += x
            o.location.z -= 0.06
    groups[name] = [o for o in new if o.type == 'MESH']
    print(f"[truth_showcase] imported {name}: {len(groups[name])} mesh obj(s) at x={x:.1f}")

ref_main = spawn_ref(((-(len(VARIANTS) - 1) / 2.0) * SPACING - 4.5, 0.0, 0.0))


def render_to(path, cam_loc, target_loc, lens=35, res=(1920, 1080)):
    tgt = bpy.data.objects.new("t", None)
    tgt.location = target_loc
    scene.collection.objects.link(tgt)
    cd = bpy.data.cameras.new("c")
    cd.lens = lens
    cam = bpy.data.objects.new("c", cd)
    cam.location = cam_loc
    scene.collection.objects.link(cam)
    cam.constraints.new(type='TRACK_TO').target = tgt
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = os.path.join(REN_DIR, path)
    bpy.ops.render.render(write_still=True)
    print(f"[truth_showcase] -> {path}")
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(tgt, do_unlink=True)


def show_only(name):
    for k, objs in groups.items():
        for o in objs:
            o.hide_render = (k != name) if name else False
    gp.hide_render = False


_span_m = SPACING * (len(VARIANTS) - 1) + 24.0
_cam_d = _span_m * 1.02          # lens 36 on 36 mm film: ~53 deg horizontal FOV
render_to("TRUTH_lineup.png", (0.0, -_cam_d, _span_m * 0.16),
          (0.0, 0.0, 7.0), lens=36, res=(2400, 900))

# multi-angle turntable of the generalist, from the shipped GLB
HERO = "tree_prairie_mature_02"
show_only(HERO)
px = (VARIANTS.index(HERO) - (len(VARIANTS) - 1) / 2.0) * SPACING
rt = spawn_ref((px + 5.2, 0.0, 0.0))
for az in (0, 90, 180, 270):
    a = math.radians(az)
    r = 17.0
    render_to(f"TRUTH_prairie_angle_{az:03d}.png",
              (px + math.sin(a) * r, -math.cos(a) * r, 6.5), (px, 0.0, 4.0),
              lens=40, res=(1100, 1350))
render_to("TRUTH_prairie_playereye.png", (px + 2.4, -7.0, 1.65), (px, 0.0, 3.4),
          lens=24, res=(1200, 1400))
render_to("TRUTH_prairie_base.png", (px - 2.8, -3.6, 1.2), (px, 0.0, 0.6),
          lens=45, res=(1200, 1200))
render_to("TRUTH_prairie_crown.png", (px - 3.2, -7.5, 6.4), (px, 0.0, 5.6),
          lens=58, res=(1200, 1200))

# ---- P10 crown porosity, measured -----------------------------------------
# The ground plane and the scale post MUST be hidden for this pass: they are
# opaque, so on a transparent film they land in the same alpha mask as the
# tree and the first run reported 3.7% porosity for a crown that is visibly
# full of sky. Measuring the tree alone is the whole point.
scene.render.film_transparent = True
gp.hide_render = True
rt.hide_render = True
render_to("_sil_prairie.png", (px, -26.0, 4.6), (px, 0.0, 4.4), lens=48, res=(900, 1150))
scene.render.film_transparent = False
gp.hide_render = False
bpy.data.objects.remove(rt, do_unlink=True)

for name, tag in ((v, v.removeprefix("tree_")) for v in VARIANTS if v != HERO):
    show_only(name)
    idx = VARIANTS.index(name)
    ox = (idx - (len(VARIANTS) - 1) / 2.0) * SPACING
    rr = spawn_ref((ox + 5.2, 0.0, 0.0))
    render_to(f"TRUTH_{tag}.png", (ox - 5.0, -17.0, 6.0), (ox, 0.0, 3.6),
              lens=40, res=(1100, 1400))
    bpy.data.objects.remove(rr, do_unlink=True)
show_only(None)

# ---- porosity maths --------------------------------------------------------
img = bpy.data.images.load(os.path.join(REN_DIR, "_sil_prairie.png"))
w, h = img.size
buf = np.empty(w * h * 4, dtype=np.float32)
img.pixels.foreach_get(buf)
alpha = buf.reshape(h, w, 4)[..., 3] > 0.5

rows = np.where(alpha.any(axis=1))[0]
# crown = the upper 60% of the silhouette's vertical run; below that is the
# bare trunk, whose "holes" are just background and would inflate the number.
if len(rows):
    top, bot = rows.max(), rows.min()
    crown_lo = int(bot + (top - bot) * 0.40)
    filled = 0
    total = 0
    for y in range(crown_lo, top + 1):
        xs = np.where(alpha[y])[0]
        if len(xs) < 2:
            continue
        span = xs.max() - xs.min() + 1
        total += span
        filled += alpha[y, xs.min():xs.max() + 1].sum()
    hole = 1.0 - filled / max(1, total)
    print(f"[truth_showcase] P10 crown porosity (sky inside the crown outline) "
          f"= {hole*100:.1f}%  (reference target 20-40%)")
    print(f"[truth_showcase] silhouette rows {bot}..{top}, crown band from {crown_lo}")
print("[truth_showcase] DONE")
