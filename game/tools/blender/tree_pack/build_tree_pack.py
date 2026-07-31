"""build_tree_pack.py — TEXTURED tree pack for Piso 1 Pradera.

v2 REBUILD (2026-07-30). Pilot of the textured-vegetation family per
`_art_canon.md` §17.5. Replaces the flat-shaded / vertex-colour-only v1
(2026-07-28) which violated 13 of 21 patterns measured in
`game/docs/art/_references/tree_poe/_synthesis.md`.

WHAT CHANGED, AND WHY (every item traces to a pattern ID in that synthesis):

  GEOMETRY — silhouette is now the SKELETON, not a lollipop.
  P1  root flare: 3-5 lobed buttresses, base radius 1.5-2.2x the radius at
      10% height, decaying to a circular section by 12-15% height.
  P2  segmented taper: neiloid flare / paraboloid body / conic top. The v1
      `r = base_r + (top_r-base_r)*u` straight line WAS the perfect cone.
  P3  8-12 deg lean per variant + a fixed per-side radius flute (0.16-0.20),
      not v1's sub-perceptual +-6% per-ring noise.
  P4  pipe model: branch radius derived from the DROP in trunk cross-section
      across its node, i.e. r_branch = sqrt(r_below^2 - r_above^2). A
      symmetric 2-split reproduces 1/sqrt(2) by construction.
  P5  branch angle from the trunk axis lerps 85 deg (bottom) -> 18 deg (top)
      by insertion height.
  P6  radial placement by the golden angle 137.5 deg (+-18 deg), never
      v1's `2*pi*i/n` wheel.
  P7  first live branch at 10-30% of height, LCR 0.65-0.85 (open-grown
      prairie form, not the closed-forest LCR ~0.45 v1 produced).
  P8  3-5 primary branches (art choice, flagged as such in the synthesis).
  P9  crown interior is EMPTY. v1's solid nucleus at R*0.62 is deleted;
      foliage anchors to branch tips only.
  P10 sky holes: `enforce_overlap` and the safety stitch are DELETED, not
      tuned — §17.5 says a "no gaps" invariant violates the canon.
  P11 crown centroid offset toward the light by 10-25% of crown radius.
  P12 crown diameter sized from DBH at the 24-27x target (19x for the
      columnar `tall`, per P12's own conifer note).
  P19 dead branch stubs — the best read-per-triangle item on the list.

  MATERIAL — the half §17 mandated and v1 never had.
  P15 trunk + branches: UV unwrapped (per-LOOP UVs, so no duplicated seam
      verts and the smooth normals stay continuous) with PolyHaven CC0
      `bark_brown_01` albedo + normal map. Per P15, 3-8 sides is FINE once a
      bark normal map exists — so the triangles go to branches, not sides.
  P14 foliage: alpha-cutout CARDS, not solid clumps. Reuses the CC0 leaf
      alpha already shipping in this repo (`env_tree_common_leaves.png`),
      recoloured at build time so the atlas supplies leaf SHAPE and the
      vertex colour supplies the palette (glTF can only express
      baseColorFactor x texture x COLOR_0 — no mixes — so the tint has to
      live in one of those three).
  P17 sphere-transferred normals on every foliage clump: flat cards shade as
      one rounded volume. v1's pack-wide `use_smooth = False` is gone
      (§17.3 retired the hard-shaded environment look).
  ---  value separation is VERTICAL now (crown top warm/lit -> underside near
      black), keyed to height. v1 keyed brightness to radial distance, which
      lit the canopy underside as brightly as its top.

Vertex colour: FLOAT_COLOR only, dict keyed by the BMVert object — both
gotchas from the blender-asset-smith skill (BYTE_COLOR sRGB round-trip,
stale BMVert.index).

Triangle budget: <=800 tris/variant (§17.1 — detail goes to MATERIAL and
LIGHT, not polycount). Printed per variant at build time.

Run:
  blender.exe --background --factory-startup --python-exit-code 1 \
      --python build_tree_pack.py [-- --seed 21]
"""
import bpy
import bmesh
import json
import math
import os
import random
import sys

import numpy as np
from mathutils import Vector, Matrix

# =============================================================================
# CONFIG
# =============================================================================
SEED = 21
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(SCRIPT_DIR, "renders")
TEX_CACHE = os.path.join(SCRIPT_DIR, "_tex")
os.makedirs(REN_DIR, exist_ok=True)
os.makedirs(TEX_CACHE, exist_ok=True)

ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera",
    "vegetation", "tree_pack"))
os.makedirs(ASSET_DIR, exist_ok=True)

# PolyHaven CC0 library (27 textures + MANIFEST.json) — §17.2.2's named source.
POLYHAVEN_DIR = r"C:\Users\the_j\motor-blender\_textures"
BARK_DIFF_SRC = os.path.join(POLYHAVEN_DIR, "bark_brown_01_diff.jpg")
BARK_NOR_SRC = os.path.join(POLYHAVEN_DIR, "bark_brown_01_nor.jpg")

# CC0 leaf alpha already shipping in this repo (legacy texture-card trees).
LEAF_SRC = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera",
    "vegetation", "common", "env_tree_common_leaves.png"))

TEX_RES = 512          # GLB payload control: 1024 sources -> 512 in-asset
BARK_TILE_M = 0.80     # metres of world per bark texture tile

sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
import _ground_common as groundlib  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# =============================================================================
# PALETTES
# Vertex colour MULTIPLIES the texture (glTF: baseColorFactor x tex x COLOR_0),
# so these are modulations, not final screen colours.
# =============================================================================
# Trunk: cool + dark against a warm bright crown (refs measure ~3:1 or more in
# luminance between trunk and lit canopy). bark_brown_01 is a warm mid brown,
# so the tint desaturates and cools it, and the AO ramp buries the base.
BARK_TINT = (0.40, 0.41, 0.47)
BARK_TINT_DRY = (0.60, 0.55, 0.44)
BARK_AO_BASE = 0.34     # multiplier at z=0 (P18: baked AO where trunk meets soil)
BARK_AO_TOP = 1.00
BARK_AO_HEIGHT = 0.22   # fraction of trunk height the AO ramp spans

# Foliage: the vertical value axis. LIGHT is warm (sun-bleached lime/gold),
# DARK is a near-black green for the canopy underside.
FOL_DARK = (0.150, 0.180, 0.125)
FOL_LIGHT = (1.000, 0.985, 0.760)
FOL_DARK_DRY = (0.185, 0.150, 0.100)
FOL_LIGHT_DRY = (1.000, 0.880, 0.520)

LEAF_TINT_GREEN = (0.255, 0.400, 0.115)   # sRGB, painted into the atlas RGB
LEAF_TINT_GOLD = (0.560, 0.420, 0.115)


# =============================================================================
# TEXTURE PREPARATION
# =============================================================================
def _cache_resized(src_path, out_name, fmt="JPEG", quality=88):
    """Downscale a source texture into the pack's own cache so the GLB payload
    stays sane (six GLBs each embed the bark set). Deterministic: skipped when
    the cache file already exists."""
    out = os.path.join(TEX_CACHE, out_name)
    if os.path.exists(out):
        return out
    img = bpy.data.images.load(src_path)
    img.scale(TEX_RES, TEX_RES)
    img.filepath_raw = out
    img.file_format = fmt
    img.save(quality=quality)
    bpy.data.images.remove(img)
    return out


def _box_blur(a, passes=1):
    for _ in range(passes):
        a = (a
             + np.roll(a, 1, 0) + np.roll(a, -1, 0)
             + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5.0
    return a


def _leaf_sprites():
    """Cut the eleven individual leaves out of the CC0 source atlas.

    Flood-fill labelling on the alpha channel; each component is returned as
    its own cropped alpha bitmap so it can be scattered independently.
    """
    src = bpy.data.images.load(LEAF_SRC)
    src.scale(512, 512)
    buf = np.empty(512 * 512 * 4, dtype=np.float32)
    src.pixels.foreach_get(buf)
    a = buf.reshape(512, 512, 4)[..., 3].astype(np.float64)
    bpy.data.images.remove(src)

    mask = a > 0.35
    seen = np.zeros_like(mask, dtype=bool)
    sprites = []
    H, W = mask.shape
    for sy in range(0, H, 4):
        for sx in range(0, W, 4):
            if not mask[sy, sx] or seen[sy, sx]:
                continue
            stack = [(sy, sx)]
            seen[sy, sx] = True
            pts = []
            while stack:
                y, x = stack.pop()
                pts.append((y, x))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            if len(pts) < 400:
                continue
            ys = [p[0] for p in pts]
            xs = [p[1] for p in pts]
            y0, y1, x0, x1 = min(ys), max(ys) + 1, min(xs), max(xs) + 1
            sub = np.zeros((y1 - y0, x1 - x0))
            for (y, x) in pts:
                sub[y - y0, x - x0] = a[y, x]
            sprites.append(sub)
    return sprites


def _resize_rot(sprite, size, angle):
    """Nearest-neighbour rotate+scale of one leaf into a square canvas.
    scipy is not available inside Blender, and a leaf silhouette does not
    need better filtering than this at 40-60 px."""
    S = int(size * 1.45) | 1
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float64)
    cy = cx = (S - 1) * 0.5
    ca, sa = math.cos(angle), math.sin(angle)
    h, w = sprite.shape
    scale = size / max(h, w)
    sy = ((yy - cy) * ca - (xx - cx) * sa) / scale + h * 0.5
    sx = ((yy - cy) * sa + (xx - cx) * ca) / scale + w * 0.5
    iy = np.clip(np.round(sy).astype(int), 0, h - 1)
    ix = np.clip(np.round(sx).astype(int), 0, w - 1)
    out = sprite[iy, ix]
    inside = (sy >= 0) & (sy < h) & (sx >= 0) & (sx < w)
    return out * inside


def build_leaf_cluster_atlas(out_name, tint, seed, n_leaves=58, leaf_px=(34, 58)):
    """Composite a BRANCH-CLUSTER card: one quad = a whole spray of ~58 small
    leaves, not one leaf and not the raw eleven-leaf source sheet.

    Two defects from the first textured build drove this, both found by
    opening the render rather than by reading code:

      1. Cards were UV-windowed into the source sheet, and the window borders
         SLICED leaves in half — every card showed a straight cut edge, so the
         crown read as green rectangles. A composited atlas keeps an empty
         margin all the way round, so a card edge can never cut a leaf.
      2. On a ~1.6 m card, the source sheet's eleven leaves came out ~0.5 m
         across. Compositing ~58 leaves at 34-58 px inside 512 puts them at
         ~0.12-0.18 m — actual leaf scale.

    P14 sanctions exactly this: "Un card puede ser una hoja o un racimo entero
    de rama."

    RGB is authored rather than taken from the source, because glTF's base
    colour is only `baseColorFactor x baseColorTexture x COLOR_0` — no mix
    node survives the exporter — and the source is a fully saturated
    yellow-green with a ZERO blue channel, which no multiply can undo.
    Authoring it frees COLOR_0 for the job it is good at: the vertical light
    gradient.
    """
    out = os.path.join(TEX_CACHE, out_name)
    if os.path.exists(out):
        return out
    sprites = _leaf_sprites()
    rng = np.random.default_rng(seed)
    R = TEX_RES
    alpha = np.zeros((R, R))
    value = np.zeros((R, R))
    margin = int(R * 0.035)

    for _ in range(n_leaves):
        sp = sprites[rng.integers(0, len(sprites))]
        size = int(rng.integers(leaf_px[0], leaf_px[1]))
        rot = _resize_rot(sp, size, rng.uniform(0.0, 2.0 * math.pi))
        S = rot.shape[0]
        # radial falloff -> a rounded mass with a ragged edge, not a square
        rad = (R * 0.5 - margin - S * 0.5) * (rng.random() ** 0.55)
        ang = rng.uniform(0.0, 2.0 * math.pi)
        cy = int(R * 0.5 + math.sin(ang) * rad)
        cx = int(R * 0.5 + math.cos(ang) * rad)
        y0 = max(margin, cy - S // 2)
        x0 = max(margin, cx - S // 2)
        y1 = min(R - margin, y0 + S)
        x1 = min(R - margin, x0 + S)
        if y1 - y0 < 4 or x1 - x0 < 4:
            continue
        patch = rot[:y1 - y0, :x1 - x0]
        # leaves higher up the card catch more light (the card's own +V is up)
        v = rng.uniform(0.58, 1.0) * (0.72 + 0.42 * (cy / R))
        win = patch > alpha[y0:y1, x0:x1]
        value[y0:y1, x0:x1] = np.where(win, v, value[y0:y1, x0:x1])
        alpha[y0:y1, x0:x1] = np.maximum(alpha[y0:y1, x0:x1], patch)

    soft = _box_blur(alpha, passes=3)
    edge = 0.60 + 0.40 * np.clip(soft, 0.0, 1.0)      # rim darker than core
    shade = np.clip(value * edge, 0.0, 1.3)[..., None]
    rgb = np.clip(np.array(tint, dtype=np.float64)[None, None, :] * shade, 0.0, 1.0)

    out_px = np.empty((R, R, 4), dtype=np.float32)
    out_px[..., :3] = rgb
    out_px[..., 3] = alpha
    dst = bpy.data.images.new(out_name, R, R, alpha=True)
    dst.alpha_mode = 'STRAIGHT'
    dst.pixels.foreach_set(out_px.reshape(-1))
    dst.filepath_raw = out
    dst.file_format = 'PNG'
    dst.save()
    bpy.data.images.remove(dst)
    print(f"[tree_pack] atlas {out_name}: coverage {(alpha > 0.45).mean():.3f}")
    return out


BARK_DIFF = _cache_resized(BARK_DIFF_SRC, f"bark_brown_01_diff_{TEX_RES}.jpg")
BARK_NOR = _cache_resized(BARK_NOR_SRC, f"bark_brown_01_nor_{TEX_RES}.jpg")
LEAF_GREEN = build_leaf_cluster_atlas(f"leaf_green_{TEX_RES}.png", LEAF_TINT_GREEN, 4711)
LEAF_GOLD = build_leaf_cluster_atlas(f"leaf_gold_{TEX_RES}.png", LEAF_TINT_GOLD, 4712,
                                     n_leaves=40, leaf_px=(30, 50))


# =============================================================================
# MATERIALS
# Both are texture x COLOR_0. Verified against the exporter before writing
# this file: a Mix(MULTIPLY) of an Image Texture and an Attribute("Col") node
# exports as baseColorTexture + a COLOR_0 attribute, and blend_method='CLIP'
# exports as alphaMode MASK.
# =============================================================================
def _tex_node(nt, path, colorspace='sRGB'):
    img = bpy.data.images.load(path, check_existing=True)
    img.colorspace_settings.name = colorspace
    n = nt.nodes.new("ShaderNodeTexImage")
    n.image = img
    return n


def make_bark_material(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.88
    bsdf.inputs["Metallic"].default_value = 0.0
    spec = bsdf.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.22

    diff = _tex_node(nt, BARK_DIFF)
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs["Factor"].default_value = 1.0
    nt.links.new(diff.outputs["Color"], mix.inputs[6])
    nt.links.new(attr.outputs["Color"], mix.inputs[7])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])

    nor = _tex_node(nt, BARK_NOR, colorspace='Non-Color')
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nmap.inputs["Strength"].default_value = 1.15
    nt.links.new(nor.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])

    m.use_backface_culling = True
    return m


def make_leaf_material(name, atlas_path):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.72
    bsdf.inputs["Metallic"].default_value = 0.0
    spec = bsdf.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.10

    diff = _tex_node(nt, atlas_path)
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    mix.blend_type = 'MULTIPLY'
    mix.inputs["Factor"].default_value = 1.0
    nt.links.new(diff.outputs["Color"], mix.inputs[6])
    nt.links.new(attr.outputs["Color"], mix.inputs[7])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])

    # ALPHA CUTOUT -> glTF alphaMode MASK.
    # Setting `blend_method = 'CLIP'` is NOT enough on Blender 5.1: the
    # exporter stopped reading the EEVEE blend method and now derives the
    # alpha mode from the node graph itself
    # (io_scene_gltf2/blender/exp/material/search_node_tree.py:
    #  "Alpha mode is determined by the nodes too (previously it used the
    #  Eevee blend_method)"). Without the explicit clip node the GLB shipped
    # alphaMode BLEND — sorted transparency on a 400-card crown, which is
    # both wrong and expensive. `detect_alpha_clip` recognises
    # `alpha > cutoff`, so that is what gets built here.
    clip = nt.nodes.new("ShaderNodeMath")
    clip.operation = 'GREATER_THAN'
    clip.inputs[1].default_value = 0.45
    nt.links.new(diff.outputs["Alpha"], clip.inputs[0])
    nt.links.new(clip.outputs["Value"], bsdf.inputs["Alpha"])

    m.blend_method = 'CLIP'          # EEVEE preview parity with the node clip
    m.alpha_threshold = 0.45
    # Blender 5.x dropped Material.shadow_method; EEVEE Next takes the cutout
    # from surface_render_method instead.
    if hasattr(m, "surface_render_method"):
        m.surface_render_method = 'DITHERED'
    m.use_backface_culling = False   # cards must read from both sides
    return m


# =============================================================================
# SMALL MATH
# =============================================================================
def lerp(a, b, t):
    return a + (b - a) * t


def lerp3(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def clamp01(x):
    return 0.0 if x < 0.0 else (1.0 if x > 1.0 else x)


def basis_from(direction):
    """Orthonormal frame with `direction` as the third axis."""
    d = Vector(direction).normalized()
    ref = Vector((0.0, 0.0, 1.0))
    if abs(d.dot(ref)) > 0.95:
        ref = Vector((1.0, 0.0, 0.0))
    u = d.cross(ref).normalized()
    v = d.cross(u).normalized()
    return u, v, d


# =============================================================================
# P1 + P2 — TRUNK PROFILE
# =============================================================================
FLARE_TOP = 0.12        # flare has fully decayed to a circular section by here


def taper_radius(u, r_ref, top_r, u_ref=0.08):
    """Segmented taper: paraboloid body blending into a conic top.

    P2's rule, verbatim: "el perfil es POR TRAMOS, no una recta — neiloide en
    el 0-10% inferior (flare), paraboloide en el cuerpo, conico en la punta.
    Un `r = base_r + (top_r-base_r)*u` recto es exactamente lo que produce el
    'cono perfecto'."

    s = normalised distance from the tip. s**0.55 is the paraboloid (convex,
    fat low down), s**1.25 the cone (concave, quick taper at the tip); the
    weight `w` hands over between them across the trunk. Both terms are
    monotone in u and s**0.55 >= s**1.25 for s <= 1, so the profile is
    strictly decreasing — no pinch, no bulge.
    """
    s = clamp01((1.0 - u) / (1.0 - u_ref))
    w = clamp01((0.72 - u) / 0.72)
    shape = w * (s ** 0.55) + (1.0 - w) * (s ** 1.25)
    return top_r + (r_ref - top_r) * shape


def flare_mean_mul(u, flare_min):
    """Neiloid root flare, mean (inter-buttress) multiplier over the taper.

    P1: base radius 1.5-2.2x the radius at 10% height, decaying to a circular
    section by 10-15% of height. `flare_min` is the value BETWEEN buttresses;
    the lobes below push individual verts out to the top of that range.
    """
    if u >= FLARE_TOP:
        return 1.0
    t = (FLARE_TOP - u) / FLARE_TOP
    return 1.0 + (flare_min - 1.0) * (t ** 1.7)


def flare_lobe_mul(u, theta, n_lobes, phase, big_dir, amp=0.52):
    """3-5 buttresses radiating from the base, asymmetrically larger on one
    side (P1: "69.57% tienen 3-5 raices contrafuerte ... asimetricamente mas
    grandes del lado de mayor carga"). Decays with the same envelope as the
    mean flare so the section is a clean circle above FLARE_TOP."""
    if u >= FLARE_TOP:
        return 1.0
    t = (FLARE_TOP - u) / FLARE_TOP
    lobe = max(0.0, math.cos(n_lobes * (theta - phase))) ** 1.4
    bias = 1.0 + 0.42 * max(0.0, math.cos(theta - big_dir))   # the loaded side
    return 1.0 + amp * lobe * bias * (t ** 1.5)


# =============================================================================
# TUBE BUILDER (trunk, branches, stubs all share it)
# =============================================================================
def build_tube(bm, uv_layer, vcol, path, radii, sides, col_fn,
               flute=None, flare=None, cap_top=True, v_offset=0.0):
    """Tapered tube through `path` (list of Vector centres) with `radii` per
    point.

    UVs are written PER LOOP, not per vertex: the wrap-around column gets
    u = circumference instead of u = 0, so the texture is continuous with NO
    duplicated seam verts. That matters because duplicated seam verts would
    split the smooth normals and put a visible hard crease down the trunk —
    exactly what P15's "smooth cylinder + good normals" recipe must not have.

    `flute` = fixed per-side radius multipliers (P3: a consistent irregular
    section running up the trunk reads; v1's per-ring random noise did not).
    `flare` = (n_lobes, phase, big_dir, flare_min) for the root buttresses.
    """
    rings = []
    v_run = v_offset
    prev = None
    for i, (centre, r) in enumerate(zip(path, radii)):
        if i == 0:
            fwd = (path[1] - path[0]).normalized()
        elif i == len(path) - 1:
            fwd = (path[-1] - path[-2]).normalized()
        else:
            fwd = (path[i + 1] - path[i - 1]).normalized()
        ax, ay, _ = basis_from(fwd)

        if prev is not None:
            v_run += (centre - prev).length / BARK_TILE_M
        prev = centre

        u_frac = i / max(1, len(path) - 1)
        ring = []
        for s in range(sides):
            theta = 2.0 * math.pi * s / sides
            rr = r
            if flute is not None:
                rr *= flute[s]
            if flare is not None:
                n_lobes, phase, big_dir, flare_min = flare
                rr *= flare_mean_mul(u_frac, flare_min)
                rr *= flare_lobe_mul(u_frac, theta, n_lobes, phase, big_dir)
            p = centre + ax * (math.cos(theta) * rr) + ay * (math.sin(theta) * rr)
            v = bm.verts.new(p)
            vcol[v] = col_fn(u_frac, p)
            ring.append(v)
        rings.append((ring, v_run, r))

    circ = 2.0 * math.pi * max(radii) / BARK_TILE_M
    faces = []
    for i in range(len(rings) - 1):
        a_ring, va, _ = rings[i]
        b_ring, vb, _ = rings[i + 1]
        for s in range(sides):
            s2 = (s + 1) % sides
            f = bm.faces.new((a_ring[s], a_ring[s2], b_ring[s2], b_ring[s]))
            ua = circ * s / sides
            ub = circ * (s + 1) / sides          # wraps to full circumference
            for loop, (uu, vv) in zip(f.loops, ((ua, va), (ub, va), (ub, vb), (ua, vb))):
                loop[uv_layer].uv = (uu, vv)
            faces.append(f)

    if cap_top:
        top_ring, vt, rt = rings[-1]
        centre = bm.verts.new(sum(((v.co for v in top_ring)), Vector()) / sides)
        vcol[centre] = col_fn(1.0, centre.co)
        for s in range(sides):
            s2 = (s + 1) % sides
            f = bm.faces.new((centre, top_ring[s], top_ring[s2]))
            for loop, (uu, vv) in zip(
                    f.loops, ((circ * 0.5, vt + rt / BARK_TILE_M),
                              (circ * s / sides, vt), (circ * (s + 1) / sides, vt))):
                loop[uv_layer].uv = (uu, vv)
            faces.append(f)
    return faces


# =============================================================================
# P14 + P17 — FOLIAGE CARDS
# =============================================================================
def add_leaf_clump(bm, uv_layer, vcol, rng, centre, radius, axis, colour_fn,
                   cards=3, droop=0.22):
    """One foliage clump = `cards` alpha-cutout quads crossed around the
    branch axis.

    P14: alpha cards are the industry answer for foliage silhouette, and the
    Valheim references are unambiguously cards. A card is 2 tris, so a clump
    costs 6 — an order of magnitude cheaper per unit of silhouette than v1's
    icosphere blobs, which is what funds the branch skeleton.

    The cards are anchored on the branch tip and pulled DOWN by `droop`, per
    the refs' rule 6: "el follaje cuelga hacia abajo o hacia afuera desde las
    puntas. Nunca una esfera centrada en un punto."

    Returns the clump centre so the caller can register it for the custom
    normal pass (P17 — normals transferred from an invisible sphere).
    """
    ax, ay, az = basis_from(axis)
    cen = Vector(centre) - Vector((0.0, 0.0, radius * droop))
    made = []
    for k in range(cards):
        roll = math.pi * k / cards + rng.uniform(-0.25, 0.25)
        if k == 0:
            # facing along the branch: the frontal mass
            n = az
            e1 = ax * math.cos(roll) + ay * math.sin(roll)
            e2 = n.cross(e1).normalized()
        else:
            e1 = az
            e2 = (ax * math.cos(roll) + ay * math.sin(roll)).normalized()
        w = radius * rng.uniform(0.90, 1.25)
        h = radius * rng.uniform(0.80, 1.10)
        off = (ax * rng.uniform(-0.30, 0.30) + ay * rng.uniform(-0.30, 0.30)
               + az * rng.uniform(-0.25, 0.25)) * radius
        c = cen + off
        corners = [c - e1 * w - e2 * h, c + e1 * w - e2 * h,
                   c + e1 * w + e2 * h, c - e1 * w + e2 * h]
        vs = [bm.verts.new(p) for p in corners]
        f = bm.faces.new(vs)
        # Whole atlas per card — the cluster texture keeps its own empty
        # margin, so no card edge can ever cut a leaf. Mirroring in U is the
        # only variation needed; rotating would tilt the atlas's own top-lit
        # value gradient away from up.
        uvs = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
        if rng.random() < 0.5:
            uvs = [uvs[1], uvs[0], uvs[3], uvs[2]]
        for loop, t in zip(f.loops, uvs):
            loop[uv_layer].uv = t
        for v in vs:
            vcol[v] = colour_fn(v.co)
        made.append(f)
    return made, cen


# =============================================================================
# TREE ASSEMBLY
# =============================================================================
GOLDEN_ANGLE = math.radians(137.5)


def build_tree(spec, rng):
    """One tree. Everything below is driven by `spec`; the numbers in TREES
    are the per-variant knobs, the STRUCTURE is the same for all five so the
    other packs can inherit it (§17.5 calls tree_pack the family pilot)."""
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    vcol = {}

    H = spec["height"]
    light_az = spec["light_az"]                          # P11: crown asymmetry
    # v2.1 — the lean azimuth was drawn INDEPENDENTLY of the light azimuth, so
    # a tree would lean one way while its crown biased the other. On the 8.5 m
    # `tall` that put the trunk's top over a metre from where the crown sat:
    # measured against the trunk axis at the crown centroid's own height, the
    # crown hung 60% of a crown radius off the trunk. Phototropism says these
    # are the SAME direction — an open-grown tree leans into its light — so the
    # lean now follows the light with a little scatter. P3's 8-12 deg magnitude
    # is untouched; only the direction is no longer uncorrelated noise.
    lean_az = light_az + rng.uniform(-0.5, 0.5)
    lean_deg = rng.uniform(*spec["lean_deg"])           # P3: 8-12 deg

    # ---- trunk profile ------------------------------------------------------
    # P12: crown diameter is 24-27x DBH. Solve the trunk's reference radius
    # BACKWARDS from that, instead of picking a trunk and hoping — v1's
    # measured ratio was 9.6x, i.e. the trunk was ~2.6x too fat for its crown.
    crown_d = spec["crown_radius"] * 2.0
    dbh = crown_d / spec["crown_dbh_ratio"]
    r_at_breast = dbh * 0.5
    u_breast = min(0.85, 1.30 / H)
    top_r = spec["top_r"]
    shape_breast = ((clamp01((1.0 - u_breast) / (1.0 - 0.08)) ** 0.55)
                    * clamp01((0.72 - u_breast) / 0.72)
                    + (clamp01((1.0 - u_breast) / (1.0 - 0.08)) ** 1.25)
                    * (1.0 - clamp01((0.72 - u_breast) / 0.72)))
    r_ref = top_r + (r_at_breast - top_r) / max(1e-4, shape_breast)

    n_lobes = rng.randint(3, 5)                          # P1: 3-5 buttresses
    flare_min = rng.uniform(1.55, 1.80)
    flare = (n_lobes, rng.uniform(0.0, 2.0 * math.pi), light_az + math.pi, flare_min)

    flute_sides = spec["sides"]
    flute = [1.0 + rng.uniform(-1.0, 1.0) * spec["flute"] for _ in range(flute_sides)]

    def trunk_centre(u):
        """Lean + one kink. A straight axis is P3's headline failure."""
        lat = math.tan(math.radians(lean_deg)) * H * (u ** 1.15)
        kx = 0.0
        ku = spec["kink_u"]
        if u > ku:
            kx = spec["kink_mag"] * (u - ku) / (1.0 - ku)
        kaz = lean_az + spec["kink_turn"]
        return Vector((math.cos(lean_az) * lat + math.cos(kaz) * kx,
                       math.sin(lean_az) * lat + math.sin(kaz) * kx,
                       H * u))

    def trunk_radius(u):
        return taper_radius(u, r_ref, top_r)

    def bark_colour(u_local, p):
        ao = lerp(BARK_AO_BASE, BARK_AO_TOP,
                  clamp01(p.z / (H * BARK_AO_HEIGHT)) ** 0.75)
        tint = spec["bark_tint"]
        return [clamp01(tint[i] * ao) for i in range(3)]

    # Ring distribution is front-loaded: the profile curves hardest in the
    # flare, and a ring spent up in the straight leader buys nothing.
    ring_us = [0.0, 0.035, 0.075, 0.135, 0.26, 0.44, 0.66, 1.0]
    path = [trunk_centre(u) for u in ring_us]
    radii = [trunk_radius(u) for u in ring_us]
    bark_faces = build_tube(bm, uv_layer, vcol, path, radii, spec["sides"],
                            bark_colour, flute=flute, flare=flare, cap_top=True)

    # ---- P7 + P8 — primary branches ----------------------------------------
    n_prim = spec["primaries"]
    u_first = spec["first_branch_u"]                     # P7: 10-30% of height
    u_last = 0.90
    crown_bottom = H * u_first
    crown_top = H * 1.02
    lcr = (crown_top - crown_bottom) / crown_top         # reported below

    def fol_colour(p):
        """VERTICAL value separation. v1 keyed brightness to radial distance,
        so the canopy underside came out as bright as its top; the refs put
        the darkest value of the whole frame on the underside."""
        t = clamp01((p.z - crown_bottom) / max(1e-4, (crown_top - crown_bottom)))
        # remapped off zero: the crown is ~7 m tall, so a raw 0..1 height
        # ramp leaves its whole lower two thirds in the shadow tone and the
        # mass reads as one dark lump. 0.28 is the floor the underside gets.
        t = 0.28 + 0.72 * (t ** 0.82)
        d, l = spec["fol_dark"], spec["fol_light"]
        j = rng.uniform(-0.05, 0.05)
        return [clamp01(lerp3(d, l, t)[i] + j) for i in range(3)]

    # Foliage is QUEUED, never emitted inline. finalize() splits bark from
    # foliage on a single face-index boundary, so every bark face must be
    # created before every card face. The first build ignored that (the P19
    # stubs run last) and shipped a crown of bark-textured slabs — the render
    # caught it, the code read fine.
    pending = []
    branch_report = []

    # ---- P6 primaries, and the compass gaps they leave ----------------------
    # Drawn up front so the forks can be aimed at the widest gaps (see the fork
    # block in grow_branch). Sorted widest-first, so with fewer forks than gaps
    # the worst holes are still the ones that get filled.
    prim_az = [(i * GOLDEN_ANGLE + rng.uniform(-0.31, 0.31)) % (2.0 * math.pi)
               for i in range(n_prim)]
    _srt = sorted(prim_az)
    _gaps = []
    for k in range(len(_srt)):
        a0 = _srt[k]
        a1 = _srt[(k + 1) % len(_srt)] + (2.0 * math.pi if k == len(_srt) - 1 else 0.0)
        _gaps.append((a1 - a0, (a0 + a1) * 0.5))
    _gaps.sort(key=lambda g: -g[0])
    fork_targets = [g[1] for g in _gaps]
    fork_i = [0]

    def emit_clump(centre, radius, axis):
        pending.append((Vector(centre), radius, Vector(axis)))

    def grow_branch(origin, u_ins, azimuth, r_branch, length, depth=0):
        """One branch as a 3-segment tapered tube, then foliage on its outer
        half. P5 sets the DEPARTURE angle from the insertion height; the branch
        then ARCS UP along its run.

        v2.1 — the arc used to be a 24% reduction of the departure angle across
        the whole branch, which is not an arc, it is a straight ray with a
        slight tilt. A primary leaving at u=0.22 departs at 70 deg from the
        trunk axis (20 deg above horizontal) and, with only a 24% sweep, was
        still 34 deg above horizontal at its tip after 5-6 m of run. That limb
        reads as structurally impossible: near-horizontal, long, thick and
        loaded with foliage, with nothing counterbalancing it.

        `BRANCH_ARC` now bends the branch by `arc` of its departure angle with
        an f**1.25 profile, so the same 70 deg departure ends near 36 deg from
        the axis (54 deg above horizontal). The limb still LEAVES the trunk at
        P5's angle — the emergence angle is untouched, per the pattern — but it
        lifts along its run the way a real load-bearing limb does, which is
        both what the refs show and what makes the load look carried."""
        ang0 = math.radians(lerp(85.0, 18.0, clamp01(u_ins)))   # P5 — unchanged
        arc = spec["branch_arc"] * (0.85 if depth else 1.0)
        segs = 3 if depth == 0 else 2
        pts = [origin]
        radii_b = [r_branch]
        pos = Vector(origin)
        for k in range(segs):
            f = (k + 0.5) / segs
            ang = ang0 * (1.0 - arc * (f ** 1.25))       # arc upward along the run
            step = length / segs
            d = Vector((math.cos(azimuth) * math.sin(ang),
                        math.sin(azimuth) * math.sin(ang),
                        math.cos(ang)))
            d.x += rng.uniform(-0.10, 0.10)
            d.y += rng.uniform(-0.10, 0.10)
            pos = pos + d.normalized() * step
            pts.append(pos.copy())
            radii_b.append(r_branch * (1.0 - 0.72 * (k + 1) / segs))
        build_tube(bm, uv_layer, vcol, pts, radii_b, spec["branch_sides"],
                   bark_colour, cap_top=True)
        axis = (pts[-1] - pts[-2]).normalized()
        branch_report.append((u_ins, math.degrees(ang0), r_branch, length, depth))

        # Foliage lives on the OUTER HALF of the branch and on its tip.
        # Nothing near the trunk, nothing in the interior — P9's empty core
        # holds by construction, not by a rule that has to be enforced.
        # Density is spread ALONG the limb, not balled at the end: the beech
        # and birch refs read as a veil over a skeleton precisely because the
        # foliage follows the branch lines out.
        # The tip cluster is FANNED around the branch axis rather than jittered
        # inside a box. A box jitter of +-0.45 r keeps every clump inside one
        # small solid angle, so a branch contributes one blob to one azimuth;
        # fanning the same clump count around the axis makes each branch cover
        # a WEDGE of the compass instead of a point, which is what turns four
        # separate masses into one canopy without spending a triangle.
        tip_r = spec["clump_r"] * (0.82 if depth else 1.0)
        fan_u, fan_v, _ = basis_from(axis)
        n_tip = spec["clumps_per_tip"]
        fan_phase = rng.uniform(0.0, 2.0 * math.pi)
        for j in range(n_tip):
            roll = fan_phase + 2.0 * math.pi * j / max(1, n_tip) + rng.uniform(-0.35, 0.35)
            rad = tip_r * spec["tip_fan"] * rng.uniform(0.70, 1.15)
            off = (fan_u * math.cos(roll) + fan_v * math.sin(roll)) * rad
            off += axis * rng.uniform(-0.30, 0.22) * tip_r
            emit_clump(pts[-1] + off, tip_r * rng.uniform(0.85, 1.15), axis)
        for j in range(spec["clumps_along"]):
            t = lerp(0.34, 0.96, (j + rng.uniform(0.12, 0.88)) / spec["clumps_along"])
            k = t * segs
            i0 = min(segs - 1, int(k))
            seg_dir = (pts[i0 + 1] - pts[i0])
            p = pts[i0].lerp(pts[i0 + 1], k - i0)
            side = seg_dir.normalized().cross(Vector((0.0, 0.0, 1.0)))
            if side.length < 1e-4:
                side = Vector((1.0, 0.0, 0.0))
            # alternating sides, wide: same reason as the tip fan — a branch
            # has to spread its foliage ACROSS the compass, not along one ray.
            lat = spec["side_spread"] * (1.0 if (j % 2) else -1.0) * rng.uniform(0.55, 1.0)
            p = p + side.normalized() * lat * tip_r \
                  + Vector((0.0, 0.0, rng.uniform(-0.30, 0.38) * tip_r))
            emit_clump(p, tip_r * lerp(0.60, 0.95, t), seg_dir.normalized())

        # P4 — fork. A symmetric 2-split is r_child = r_parent/sqrt(2); the
        # jitter is the +-10-15% per-bifurcation spread the synthesis flags as
        # an estimate rather than a measured constant.
        #
        # v2.1 — the fork azimuth is no longer uniform noise around the parent.
        # P6 puts the PRIMARIES on the golden angle, and it should: that is the
        # phyllotaxis rule. But 3-5 samples of a 137.5 deg progression still
        # leave 50-85 deg gaps on the compass, and a fork drawn from
        # `azimuth + uniform(-1, 1)` lands anywhere, frequently back on top of
        # its own parent — which is how the pack ended up with 3-4 distinct
        # masses and a 60-70 deg hole. The gaps are computable up front, so the
        # forks are aimed at the widest ones, largest first. The primaries keep
        # P6 untouched; the forks are what CLOSES the canopy.
        if depth == 0 and rng.random() < spec["fork_chance"]:
            share = rng.uniform(0.42, 0.58)
            r_child = r_branch * math.sqrt(share) * rng.uniform(0.88, 1.12)
            target = fork_targets[fork_i[0] % len(fork_targets)]
            fork_i[0] += 1
            grow_branch(pts[-2], min(0.95, u_ins + 0.18),
                        target + rng.uniform(-0.18, 0.18),
                        r_child, length * 0.62, depth=1)

    # ---- P19 — dead branch stubs (BEFORE the live branches: bark first) ----
    # "~8-12 tris cada uno. Es la mejor relacion lectura/triangulo de toda la
    # lista." They sit on the BARE trunk, below the first live branch, which
    # is exactly where the Black Forest pines carry theirs.
    for i in range(spec["stubs"]):
        u_s = rng.uniform(0.13, max(0.18, u_first * 0.92))
        az = rng.uniform(0.0, 2.0 * math.pi)
        r_s = trunk_radius(u_s) * rng.uniform(0.38, 0.52)
        c = trunk_centre(u_s)
        d = Vector((math.cos(az), math.sin(az), rng.uniform(-0.14, 0.26))).normalized()
        L = rng.uniform(0.9, 1.5) * trunk_radius(u_s) * 2.4
        build_tube(bm, uv_layer, vcol,
                   [c - d * trunk_radius(u_s) * 0.5, c + d * L],
                   [r_s, r_s * 0.20], 4, bark_colour, cap_top=True)

    # ---- P4 — how much wood each primary gets ------------------------------
    # Deriving each branch from the local taper interval (first attempt) made
    # every primary the same size. Real crowns are bottom-heavy: the lowest
    # limb is a structural member, the top ones are twigs. So distribute the
    # WHOLE cross-section the leader gives up across the crown, with weights
    # that fall off going up. Da Vinci still holds in aggregate — sum of the
    # daughters' areas equals the mother's loss, exactly — and the lowest
    # branch lands near the 1/sqrt(2) figure for a dominant split.
    a_total = max(1e-6, trunk_radius(u_first) ** 2 - trunk_radius(0.95) ** 2)
    weights = [(n_prim - i) ** 1.4 for i in range(n_prim)]
    w_sum = sum(weights)

    for i in range(n_prim):
        u_ins = lerp(u_first, u_last, i / max(1, n_prim - 1))
        azimuth = prim_az[i]                                    # P6: 137.5 deg
        share = weights[i] / w_sum * rng.uniform(0.88, 1.12)    # P4 jitter
        r_branch = math.sqrt(a_total * share)

        # P11 — crown asymmetry: branches on the lit side reach further, so
        # the crown centroid slides toward the light.
        #
        # v2.1 — `light_bias` was 0.42-0.95, i.e. a length ratio of up to
        # 0.45x : 1.95x between the shaded and the lit flank. That is not a
        # bias, it is a relocation: the shaded branches became stubs and the
        # whole mass moved to one side, which is exactly the "cone lying on its
        # side" read. P11's own wording is a crown that still SURROUNDS the
        # trunk with its centroid nudged 10-25% of the crown radius toward the
        # light. For n branches at spread azimuths the centroid offset lands
        # near light_bias/2 of the radius, so 0.26-0.34 is the whole legal
        # range and anything above it is off-pattern.
        bias = 1.0 + spec["light_bias"] * math.cos(azimuth - light_az)
        # v2.1 — reach profile. Was lerp(1.05 -> 0.46): the LOWEST primary was
        # the longest branch on the tree, and it is also the one P5 makes leave
        # nearly horizontal, so it swept 5-6 m sideways at chest height. Real
        # open-grown crowns are the other way round: the lowest limb is SHORT
        # and thick (a structural member), the widest point of the crown sits
        # at mid-crown, and the branches near the leader are twigs. A sine hump
        # over the insertion range gives exactly that, and `low_reach` caps the
        # bottom limb as a fraction of the crown radius.
        t_ins = clamp01((u_ins - u_first) / max(1e-4, u_last - u_first))
        lo = spec["low_reach"]
        reach = lo + (1.0 - lo) * math.sin(math.pi * (t_ins ** 0.80))
        span = spec["crown_radius"] * reach
        length = span * bias * rng.uniform(0.92, 1.08)

        c = trunk_centre(u_ins)
        inward = Vector((math.cos(azimuth), math.sin(azimuth), 0.0)) * trunk_radius(u_ins) * 0.55
        grow_branch(c + inward * -0.4, u_ins, azimuth, r_branch, length)

    # leader tip foliage (the apical cluster)
    tip = trunk_centre(1.0)
    for j in range(spec["leader_clumps"]):
        emit_clump(tip + Vector((rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6),
                                 rng.uniform(-0.5, 0.25))) * spec["clump_r"],
                   spec["clump_r"] * rng.uniform(0.7, 1.05), Vector((0.0, 0.0, 1.0)))

    # ---- foliage LAST, so the bark/card face-index boundary is exact -------
    clump_centres = []
    for (centre, radius, axis) in pending:
        _, cen = add_leaf_clump(bm, uv_layer, vcol, rng, centre, radius, axis,
                                fol_colour, cards=spec["cards_per_clump"])
        clump_centres.append(cen)

    # crown centroid offset (P11) measured against the CROWN'S OWN AXIS, not
    # the trunk base — the tree leans 8-12 deg, which at 7 m is over a metre
    # of horizontal travel and would swamp the asymmetry signal entirely.
    crown_mid_u = (u_first + 1.0) * 0.5
    axis_xy = trunk_centre(crown_mid_u)
    if clump_centres:
        cx = sum(c.x for c in clump_centres) / len(clump_centres)
        cy = sum(c.y for c in clump_centres) / len(clump_centres)
        offset = math.hypot(cx - axis_xy.x, cy - axis_xy.y)
        span_meas = 2.0 * max(math.hypot(c.x - axis_xy.x, c.y - axis_xy.y)
                              for c in clump_centres)
    else:
        offset, span_meas = 0.0, 0.0
    dbh_meas = 2.0 * trunk_radius(u_breast) * (sum(flute) / len(flute))

    return bm, uv_layer, vcol, clump_centres, {
        "r_ref": r_ref, "dbh_design": dbh, "dbh_measured": dbh_meas,
        "crown_d_design": crown_d, "crown_d_measured": span_meas,
        "crown_dbh_ratio": span_meas / max(1e-6, dbh_meas),
        "lcr": lcr, "first_branch_m": crown_bottom,
        "first_branch_frac": u_first, "lean_deg": lean_deg,
        "n_lobes": n_lobes, "flare_min": flare_min,
        "flare_peak": flare_min * (1.0 + 0.52 * 1.42),
        "branches": branch_report, "clumps": len(clump_centres),
        "light_az": light_az,
        "centroid_offset": offset,
        "centroid_offset_frac": offset / spec["crown_radius"],
    }


# =============================================================================
# FINALIZE — two material slots, smooth shading, P17 sphere normals
# =============================================================================
def finalize(name, bm, uv_layer, vcol, clump_centres, cards_per_clump,
             bark_mat, leaf_mat):
    """Bark faces were all created before any foliage card, so the split is a
    single face-index boundary (the same trick the flower_pack emissive fix
    used). Foliage loops then get custom normals pointing away from their own
    clump centre — P17's sphere transfer, done by arithmetic instead of a
    Data Transfer modifier, which does not exist headless."""
    n_cards = len(clump_centres) * cards_per_clump
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    col_layer = bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        for loop in f.loops:
            c = vcol.get(loop.vert, (0.5, 0.5, 0.5))
            loop[col_layer] = (c[0], c[1], c[2], 1.0)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate(verbose=False)

    n_faces = len(me.polygons)
    bark_end = n_faces - n_cards
    for i, p in enumerate(me.polygons):
        p.use_smooth = True                       # §17.3: soft PBR shading
        p.material_index = 0 if i < bark_end else 1

    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    me.materials.append(bark_mat)
    me.materials.append(leaf_mat)

    # ---- custom split normals ----------------------------------------------
    # Bark keeps what smooth shading computed (continuous, because the UV seam
    # lives on the loops and never split a vertex). Foliage is overwritten
    # with the sphere transfer.
    try:
        base = [tuple(cn.vector) for cn in me.corner_normals]
    except Exception:
        base = None
    if base is not None:
        card_centre_of_loop = {}
        for ci, cen in enumerate(clump_centres):
            for k in range(cards_per_clump):
                fi = bark_end + ci * cards_per_clump + k
                if fi < n_faces:
                    card_centre_of_loop[fi] = cen
        normals = list(base)
        for fi, cen in card_centre_of_loop.items():
            poly = me.polygons[fi]
            for li in range(poly.loop_start, poly.loop_start + poly.loop_total):
                v = me.vertices[me.loops[li].vertex_index].co
                n = (Vector(v) - Vector(cen))
                if n.length < 1e-5:
                    continue
                normals[li] = tuple(n.normalized())
        try:
            me.normals_split_custom_set(normals)
        except Exception as exc:
            print(f"[tree_pack] custom normals skipped on {name}: {exc}")
    return obj, bark_end, n_cards


def count_tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# =============================================================================
# CROWN COMPOSITION — the metric v2 was missing
# =============================================================================
# P11's centroid offset measured 12-24% (inside its band) on a pack whose whole
# foliage mass sat in a diagonal lobe on one flank. It could not have caught it:
# the centroid is an AVERAGE, so a long limb reaching one way and a lobe leaning
# the other cancel to a small number while the tree reads as a cone lying on its
# side. What separates a crown from a lobe is whether the foliage SURROUNDS the
# trunk, so that is what gets measured here — and the same maths runs against
# the shipped GLB in `_crown_metrics.py`, which is the authoritative pass.
N_AZ_BINS = 36
COV_MIN_SHARE = 0.25          # of the even-crown share, 1/N_AZ_BINS
COVERAGE_TARGET = 0.75
BALANCE_TARGET = 0.20


def _poly_area_centre(me, poly):
    vs = [me.vertices[vi].co for vi in poly.vertices]
    area = 0.0
    acc = Vector((0.0, 0.0, 0.0))
    for k in range(1, len(vs) - 1):
        a = (vs[k] - vs[0]).cross(vs[k + 1] - vs[0]).length * 0.5
        area += a
        acc += (vs[0] + vs[k] + vs[k + 1]) / 3.0 * a
    if area <= 1e-12:
        return 0.0, sum(vs, Vector()) / len(vs)
    return area, acc / area


def _trunk_centreline(bz, bxy, ba, nz=24):
    """z -> (x, y) of the trunk axis.

    Per z-slice, area-weight the bark centres, then re-weight three times with a
    Cauchy falloff in distance so branch tubes — thin and far off-axis — fade
    out and the trunk ring dominates. Needed because these trunks lean 8-12 deg,
    and a crown centroid compared against an axis sampled at the wrong height is
    charged for the lean, which is P3 behaving correctly.

    The falloff is SOFT on purpose. The first version used a hard "keep the 60%
    of polygons closest to the estimate", which is tessellation-sensitive:
    glTF export triangulates, so the shipped GLB has twice the polygons at
    different distances and the quantile lands on a different subset. Builder
    and GLB then disagreed by 12 points of crown radius on the same tree. A
    smooth weight has no such cliff, and builder/GLB agreement is now the
    check that the estimator is sound.
    """
    edges = np.linspace(bz.min(), bz.max(), nz + 1)
    zs, xs, ys = [], [], []
    for k in range(nz):
        sel = (bz >= edges[k]) & ((bz < edges[k + 1]) if k < nz - 1 else (bz <= edges[k + 1]))
        if sel.sum() < 3:
            continue
        w0, p = ba[sel], bxy[sel]
        cx = (p[:, 0] * w0).sum() / w0.sum()
        cy = (p[:, 1] * w0).sum() / w0.sum()
        for _ in range(3):
            d2 = (p[:, 0] - cx) ** 2 + (p[:, 1] - cy) ** 2
            s2 = max(float((d2 * w0).sum() / w0.sum()), 1e-12)
            w = w0 / (1.0 + d2 / s2)
            cx = (p[:, 0] * w).sum() / w.sum()
            cy = (p[:, 1] * w).sum() / w.sum()
        zs.append(0.5 * (edges[k] + edges[k + 1]))
        xs.append(cx)
        ys.append(cy)
    return np.array(zs), np.array(xs), np.array(ys)


def crown_composition(obj, bark_end):
    """Azimuthal coverage + gravity balance of one tree's foliage."""
    me = obj.data
    fol = [_poly_area_centre(me, p) for p in me.polygons[bark_end:]]
    bark = [_poly_area_centre(me, p) for p in me.polygons[:bark_end]]
    if not fol:
        return {}
    fa = np.array([a for a, _ in fol])
    fx = np.array([c.x for _, c in fol])
    fy = np.array([c.y for _, c in fol])
    fz = np.array([c.z for _, c in fol])
    crown_mid = 0.5 * (fz.min() + fz.max())

    # trunk axis at crown mid-height, NOT at the base: an 8-12 deg lean is over
    # a metre of horizontal travel at 7 m and would swamp the signal.
    bz = np.array([c.z for _, c in bark])
    bxy = np.array([[c.x, c.y] for _, c in bark])
    ba = np.array([a for a, _ in bark])
    band = 0.06 * max(1e-6, bz.max() - bz.min())
    sel = np.abs(bz - crown_mid) < band
    while sel.sum() < 8 and band < (bz.max() - bz.min()):
        band *= 1.6
        sel = np.abs(bz - crown_mid) < band
    ax = float((bxy[sel, 0] * ba[sel]).sum() / ba[sel].sum()) if sel.sum() else 0.0
    ay = float((bxy[sel, 1] * ba[sel]).sum() / ba[sel].sum()) if sel.sum() else 0.0

    # Crown radius from foliage VERTICES, not polygon centres. Centres move
    # outward when a quad is split into two triangles, and glTF export
    # triangulates, so a centre-based radius is 12% larger on the shipped GLB
    # than in this scene — which silently made every offset fraction disagree
    # between the builder and `_crown_metrics.py` by a factor of two. Vertices
    # are the same in both, and this is also the definition `crown_d_measured`
    # already uses.
    fvx, fvy = [], []
    for p in me.polygons[bark_end:]:
        for vi in p.vertices:
            co = me.vertices[vi].co
            fvx.append(co.x)
            fvy.append(co.y)
    crown_r = 0.25 * ((max(fvx) - min(fvx)) + (max(fvy) - min(fvy)))
    dx, dy = fx - ax, fy - ay
    ang = np.arctan2(dy, dx) % (2.0 * math.pi)
    idx = np.minimum((ang / (2.0 * math.pi) * N_AZ_BINS).astype(int), N_AZ_BINS - 1)
    mass = np.zeros(N_AZ_BINS)
    np.add.at(mass, idx, fa)
    share = mass / max(1e-12, mass.sum())
    ok = share >= COV_MIN_SHARE / N_AZ_BINS

    # longest contiguous run of failing bins, wrapped: a canopy with one 200 deg
    # hole and a canopy with twenty scattered thin spots score the same coverage
    # but only the first one reads as half a tree.
    gap = run = 0
    for b in np.concatenate([ok, ok]):
        run = 0 if b else run + 1
        gap = max(gap, run)
    gap = min(gap, N_AZ_BINS)

    quad = np.zeros(4)
    np.add.at(quad, np.minimum((ang / (math.pi / 2)).astype(int), 3), fa)
    quad = quad / max(1e-12, quad.sum())

    cx = float((fx * fa).sum() / fa.sum())
    cy = float((fy * fa).sum() / fa.sum())
    cz = float((fz * fa).sum() / fa.sum())
    zs, axs, ays = _trunk_centreline(bz, bxy, ba)
    if len(zs):
        # Reference point = the trunk axis sampled at every foliage polygon's
        # OWN height and averaged with the same mass weights as the centroid.
        #
        # Three candidates were tried and checked against the renders before
        # this one was kept:
        #   - axis at crown MID height (what the v2 audit used): charges the
        #     tree for its own 8-12 deg lean, since the crown legitimately
        #     travels with a leaning trunk.
        #   - axis at the CENTROID's height: charges the tree for the upward
        #     branch arc, because foliage sits well above the height where its
        #     branch attaches, so the crown's XY tracks the insertions while
        #     its Z tracks the tips.
        #   - this one: both the crown and its reference are averaged over the
        #     same mass distribution, so lean and arc cancel out and what is
        #     left is purely lateral asymmetry — the thing being measured.
        # Verdict check: it fails `tall` (visibly streaky and hanging off the
        # lean) and passes `wide` (visibly one canopy over its trunk), which is
        # what the renders say. The other two are kept in the report as
        # diagnostics rather than quietly dropped.
        axc = float((np.interp(fz, zs, axs) * fa).sum() / fa.sum())
        ayc = float((np.interp(fz, zs, ays) * fa).sum() / fa.sum())
        ax_cz = float(np.interp(cz, zs, axs))
        ay_cz = float(np.interp(cz, zs, ays))
    else:
        axc, ayc, ax_cz, ay_cz = ax, ay, ax, ay
    return dict(
        az_coverage=float(ok.mean()),
        az_coverage_any=float((mass > 0).mean()),
        az_max_gap_deg=float(gap * 360.0 / N_AZ_BINS),
        min_quadrant=float(quad.min()),
        quadrants=[float(q) for q in quad],
        # headline: crown centroid vs the mass-weighted trunk axis (above)
        balance_frac=float(math.hypot(cx - axc, cy - ayc) / max(1e-6, crown_r)),
        # diagnostics: the two rejected reference points, kept visible so the
        # choice above can be audited instead of taken on trust
        balance_frac_midaxis=float(math.hypot(cx - ax, cy - ay) / max(1e-6, crown_r)),
        balance_frac_cenz=float(math.hypot(cx - ax_cz, cy - ay_cz) / max(1e-6, crown_r)),
        crown_r_measured=float(crown_r),
    )


# =============================================================================
# VARIANT SPECS
# =============================================================================
BASE = dict(
    sides=8, branch_sides=4, flute=0.18, top_r=0.055,
    lean_deg=(8.0, 12.0), kink_u=0.55, kink_mag=0.10, kink_turn=2.4,
    crown_dbh_ratio=24.0, fork_chance=1.00,
    cards_per_clump=3, clumps_per_tip=2, clumps_along=2, leader_clumps=3,
    stubs=3, bark_tint=BARK_TINT, fol_dark=FOL_DARK, fol_light=FOL_LIGHT,
    leaf="green",
    # ---- v2.1 crown-composition knobs -------------------------------------
    # light_bias: P11 asymmetry. Centroid offset lands near light_bias/2 of the
    #   crown radius, so this is the whole 10-25% band. v2 ran 0.42-0.95 and
    #   relocated the crown instead of biasing it.
    light_bias=0.24,
    # branch_arc: fraction of the P5 departure angle the limb gives up along
    #   its run. 0.62 turns a 70 deg departure into a 36 deg tip.
    branch_arc=0.62,
    # low_reach: the lowest primary's length as a fraction of crown radius.
    #   The reach profile humps to 1.0 at mid-crown and returns here at the top.
    low_reach=0.55,
    # tip_fan / side_spread: how far the tip cluster and the along-branch
    #   clumps spread ACROSS the branch, in units of clump radius. These buy
    #   azimuthal coverage for free — they move foliage, they do not add it.
    tip_fan=1.05,
    side_spread=1.35,
)

TREES = {
    "tree_prairie_01": dict(
        BASE, height=5.1, crown_radius=3.20, primaries=4, first_branch_u=0.26,
        # crown_dbh_ratio is the DESIGN input that sets trunk thickness; the
        # printed ratio is measured off the built geometry. Re-solved for the
        # v2.1 crown, which is wider than v2's lobe was, to keep P12's 24-27x.
        crown_dbh_ratio=26.5,
        clump_r=0.92, clumps_per_tip=3, clumps_along=4, leader_clumps=4,
        light_az=math.radians(35.0),
    ),
    "tree_prairie_tall_01": dict(
        BASE, height=8.5, crown_radius=1.95, primaries=5, first_branch_u=0.26,
        # P12's own note: conifers/columnar forms carry crown LENGTH > crown
        # width, so the 24-27x broadleaf ratio is deliberately relaxed here.
        crown_dbh_ratio=20.5, top_r=0.05, clump_r=0.78, light_bias=0.26,
        clumps_per_tip=3, clumps_along=3, leader_clumps=4, stubs=3,
        low_reach=0.62,
        # P3's 8-12 deg lean is a broadleaf figure. On a 10 m columnar form it
        # walks the crown 1.4 m sideways — comparable to the whole crown radius
        # — and the render reads as a sapling bent over, not a tall tree. Same
        # relaxation P12 already takes for this variant, same reason: columnar
        # forms are not what the broadleaf references measured.
        lean_deg=(4.0, 6.5),
        light_az=math.radians(200.0),
    ),
    "tree_prairie_wide_01": dict(
        BASE, height=4.2, crown_radius=3.90, primaries=5, first_branch_u=0.26,
        crown_dbh_ratio=23.5, top_r=0.07, clump_r=0.98, light_bias=0.16,
        clumps_per_tip=3, clumps_along=3, leader_clumps=4,
        # the widest crown on the pack is also the one that split into two
        # floating masses; it needs the flattest reach profile of the five so
        # no single limb carries the silhouette.
        low_reach=0.66, branch_arc=0.58,
        light_az=math.radians(110.0),
    ),
    "tree_young_01": dict(
        BASE, height=2.3, crown_radius=1.00, primaries=3, first_branch_u=0.30,
        top_r=0.028, clump_r=0.40, clumps_per_tip=3, clumps_along=3,
        light_bias=0.28, leader_clumps=4, stubs=1,
        light_az=math.radians(300.0),
    ),
    "tree_dry_01": dict(
        BASE, height=3.4, crown_radius=1.90, primaries=4, first_branch_u=0.25,
        crown_dbh_ratio=21.5, top_r=0.04, clump_r=0.58, light_bias=0.30,
        clumps_per_tip=3, clumps_along=3, leader_clumps=3, stubs=5,
        bark_tint=BARK_TINT_DRY, fol_dark=FOL_DARK_DRY, fol_light=FOL_LIGHT_DRY,
        leaf="gold", light_az=math.radians(15.0),
    ),
}

TRI_BUDGET = 800

bark_mat = make_bark_material("tree_bark_mat")
bark_mat_dry = make_bark_material("tree_bark_dry_mat")
leaf_mat_green = make_leaf_material("tree_leaf_green_mat", LEAF_GREEN)
leaf_mat_gold = make_leaf_material("tree_leaf_gold_mat", LEAF_GOLD)

objects = []
metrics = {}
print(f"\n[tree_pack] seed={SEED}  budget={TRI_BUDGET} tris/variant\n")
for i, (name, spec) in enumerate(TREES.items()):
    rng = random.Random(SEED * 1000 + i * 131)
    bm, uvl, vcol, clumps, m = build_tree(spec, rng)
    obj, bark_end, n_cards = finalize(
        name, bm, uvl, vcol, clumps, spec["cards_per_clump"],
        bark_mat_dry if spec["leaf"] == "gold" else bark_mat,
        leaf_mat_gold if spec["leaf"] == "gold" else leaf_mat_green)
    tris = count_tris(obj)
    bark_tris = sum(len(p.vertices) - 2 for p in obj.data.polygons[:bark_end])
    dims = obj.dimensions

    # Crown diameter measured from the FOLIAGE geometry's own bbox. The first
    # metric used 2 x (max clump radius from the axis), which on an
    # asymmetric crown reports the long side twice and pushed a perfectly
    # legal tree out of P12's 24-27x band on paper only.
    me_ = obj.data
    fx, fy = [], []
    for poly in me_.polygons[bark_end:]:
        for vi in poly.vertices:
            co = me_.vertices[vi].co
            fx.append(co.x)
            fy.append(co.y)
    if fx:
        crown_meas = 0.5 * ((max(fx) - min(fx)) + (max(fy) - min(fy)))
        m["crown_d_measured"] = crown_meas
        m["crown_dbh_ratio"] = crown_meas / max(1e-6, m["dbh_measured"])
    m.update(dict(tris=tris, bark_tris=bark_tris, card_tris=tris - bark_tris,
                  height=dims.z, span=max(dims.x, dims.y)))
    m.update(crown_composition(obj, bark_end))
    metrics[name] = m
    objects.append(obj)
    status = "OK" if tris <= TRI_BUDGET else f"!! OVER {TRI_BUDGET}-TRI BUDGET !!"
    prim = [b for b in m["branches"] if b[4] == 0]
    ratio_txt = ""
    if prim:
        r0 = prim[0][2]
        ratio_txt = f" d_branch0/d_trunk={2*r0/max(1e-6,m['dbh_measured']):.2f}"
    print(f"[tree_pack] {name:24s} tris={tris:4d} "
          f"(bark {bark_tris} / cards {tris - bark_tris})  "
          f"h={dims.z:5.2f}m span={max(dims.x, dims.y):5.2f}m  {status}")
    print(f"             crown/DBH={m['crown_dbh_ratio']:.1f}x "
          f"(crown {m['crown_d_measured']:.2f}m / DBH {m['dbh_measured']*100:.1f}cm)  "
          f"LCR={m['lcr']:.2f}  1st branch={m['first_branch_m']:.2f}m "
          f"({m['first_branch_frac']*100:.0f}%)")
    print(f"             lean={m['lean_deg']:.1f}deg  buttresses={m['n_lobes']}  "
          f"flare mean={m['flare_min']:.2f}x peak={m['flare_peak']:.2f}x  "
          f"clumps={m['clumps']}{ratio_txt}")
    cov_ok = "OK" if m['az_coverage'] >= COVERAGE_TARGET else "FAIL"
    bal_ok = "OK" if m['balance_frac'] <= BALANCE_TARGET else "FAIL"
    print(f"             CROWN azimuthal coverage={m['az_coverage']*100:.1f}% "
          f"[{cov_ok}, target >={COVERAGE_TARGET*100:.0f}%]  "
          f"any={m['az_coverage_any']*100:.0f}%  max gap={m['az_max_gap_deg']:.0f}deg  "
          f"min quadrant={m['min_quadrant']*100:.1f}%")
    print(f"             CROWN gravity balance={m['balance_frac']*100:.1f}% of R "
          f"[{bal_ok}, target <={BALANCE_TARGET*100:.0f}%]  "
          f"(diag: mid-axis {m['balance_frac_midaxis']*100:.1f}%, "
          f"cen-z {m['balance_frac_cenz']*100:.1f}%)  "
          f"crown R={m['crown_r_measured']:.2f}m")
    for (u_ins, ang, rb, ln, dep) in m["branches"]:
        print(f"               {'  fork' if dep else 'branch'} u={u_ins:.2f} "
              f"angle={ang:.0f}deg r={rb*100:.1f}cm len={ln:.2f}m")

# =============================================================================
# EXPORT
# =============================================================================
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)


def export(path, quality=88):
    kw = dict(filepath=path, use_selection=True, export_format='GLB',
              export_apply=True, export_animations=False, export_cameras=False,
              export_lights=False, export_yup=True,
              export_image_format='AUTO', export_image_quality=quality)
    try:
        bpy.ops.export_scene.gltf(**kw, export_vertex_color='MATERIAL')
    except TypeError:
        bpy.ops.export_scene.gltf(**kw)


export(os.path.join(ASSET_DIR, "tree_pack.glb"))
print(f"[tree_pack] EXPORTED -> {os.path.join(ASSET_DIR, 'tree_pack.glb')}")

for o in objects:
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    export(os.path.join(ASSET_DIR, f"env_{o.name}.glb"))
print(f"[tree_pack] per-variant GLBs -> {ASSET_DIR}")

with open(os.path.join(REN_DIR, "_metrics.json"), "w", encoding="utf-8") as fh:
    json.dump({k: {kk: vv for kk, vv in v.items() if kk != "branches"}
               for k, v in metrics.items()}, fh, indent=1)

# =============================================================================
# SHOWCASE — multi-angle + close-ups, ALWAYS with the 1.8 m player post
# =============================================================================
SPACING = 9.5
# Sunk 8 cm for the showcase only (exported GLBs keep base at z=0): the
# displaced ficha ground dips below z=0 and otherwise shows daylight under the
# root flare, which reads as a floating asset in the close-up.
for i, obj in enumerate(objects):
    obj.location = ((i - (len(objects) - 1) / 2.0) * SPACING, 0.0, -0.08)

ground_mat = bpy.data.materials.new("tree_ground_mat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes["Principled BSDF"]
gn.inputs["Base Color"].default_value = (0.075, 0.105, 0.045, 1.0)
gn.inputs["Roughness"].default_value = 0.95
groundlib.build_ground(scene, size=70.0, subdiv=60, roughness=0.25, scale=2.0,
                       material=ground_mat, name="tree_showcase_ground")

# 1.8 m PLAYER REFERENCE POST — mandatory on every showcase render
# (2026-07-28 lesson: a whole pack shipped at bush scale because no render
# carried a human-height marker).
ref_mesh = bpy.data.meshes.new("player_ref")
ref_bm = bmesh.new()
bmesh.ops.create_cube(ref_bm, size=1.0)
for v in ref_bm.verts:
    v.co.x *= 0.36
    v.co.y *= 0.36
    v.co.z = v.co.z * 1.8 + 0.9
ref_bm.to_mesh(ref_mesh)
ref_bm.free()
ref_mat = bpy.data.materials.new("player_ref_mat")
ref_mat.use_nodes = True
ref_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.22, 0.18, 1.0)
ref_mesh.materials.append(ref_mat)


def spawn_ref(location):
    o = bpy.data.objects.new("player_ref", ref_mesh)
    o.location = location
    scene.collection.objects.link(o)
    return o


ref_main = spawn_ref((-(len(objects) - 1) / 2.0 * SPACING - 4.2, 0.0, 0.0))

world = bpy.data.worlds.new("ficha")
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
    return lo


add_light("key", (-14.0, -34.0, 26.0), 5200, 14.0)
add_light("fill", (20.0, -24.0, 12.0), 900, 12.0)
add_light("rim", (4.0, 26.0, 17.0), 3400, 10.0)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 96
scene.view_settings.view_transform = 'Standard'


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
    print(f"[tree_pack] RENDERED -> renders/{path}")
    bpy.data.objects.remove(cam, do_unlink=True)
    bpy.data.objects.remove(tgt, do_unlink=True)


LABELS = {"tree_prairie_01": "prairie", "tree_prairie_tall_01": "tall",
          "tree_prairie_wide_01": "wide", "tree_young_01": "young",
          "tree_dry_01": "dry"}
label_mat = bpy.data.materials.new("label_mat")
label_mat.use_nodes = True
label_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.98, 0.98, 0.95, 1.0)
label_objs = []
for obj in objects:
    bpy.ops.object.text_add(location=(obj.location.x, -4.0, 0.05))
    txt = bpy.context.object
    txt.data.body = LABELS[obj.name]
    txt.data.size = 0.9
    txt.data.align_x = 'CENTER'
    txt.data.align_y = 'BOTTOM'
    txt.data.extrude = 0.012
    txt.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    txt.data.materials.append(label_mat)
    label_objs.append(txt)

render_to("tree_showcase.png", (0.0, -50.0, 10.0), (0.0, 0.0, 4.5), lens=34)


def solo(index, hide_labels=True):
    for o in objects:
        o.hide_render = (o is not objects[index])
    for l in label_objs:
        l.hide_render = hide_labels


def solo_off():
    for o in objects:
        o.hide_render = False
    for l in label_objs:
        l.hide_render = False


# ---- multi-angle turntable of the generalist (prairie) --------------------
pi_obj = objects[0]
px = pi_obj.location.x
solo(0)
ref_turn = spawn_ref((px + 4.6, 0.0, 0.0))
for az_deg in (0, 90, 180, 270):
    a = math.radians(az_deg)
    r = 16.0
    render_to(f"tree_prairie_angle_{az_deg:03d}.png",
              (px + math.sin(a) * r, -math.cos(a) * r, 6.0),
              (px, 0.0, 3.6), lens=40, res=(1100, 1300))
# ---- close-ups -------------------------------------------------------------
render_to("tree_macro_rootflare.png", (px - 2.6, -3.4, 1.15), (px, 0.0, 0.55),
          lens=42, res=(1200, 1200))
render_to("tree_macro_crown.png", (px - 3.0, -7.0, 5.6), (px, 0.0, 5.0),
          lens=55, res=(1200, 1200))
render_to("tree_playereye.png", (px + 2.2, -6.5, 1.65), (px, 0.0, 3.2),
          lens=24, res=(1200, 1400))
bpy.data.objects.remove(ref_turn, do_unlink=True)
solo_off()

for idx, tag in ((1, "tall"), (2, "wide"), (4, "dry")):
    solo(idx)
    ox = objects[idx].location.x
    rr = spawn_ref((ox + 4.6, 0.0, 0.0))
    hh = objects[idx].dimensions.z
    render_to(f"tree_macro_{tag}.png", (ox - 4.0, -hh * 1.9, hh * 0.62),
              (ox, 0.0, hh * 0.5), lens=42, res=(1100, 1400))
    bpy.data.objects.remove(rr, do_unlink=True)
solo_off()

# ---- SILHOUETTE / SKY-HOLE MEASUREMENT (P10) -------------------------------
# "No number, no verdict." Render the prairie tree on a transparent film and
# measure, per scanline of the crown, how much of the span between its own
# left and right edges is sky. That is the interior porosity the refs put at
# 20-40% for a canopy that reads as foliage rather than painted stone.
solo(0)
scene.render.film_transparent = True
render_to("_silhouette_prairie.png", (px, -22.0, 4.5), (px, 0.0, 4.2),
          lens=45, res=(900, 1100))
scene.render.film_transparent = False
solo_off()

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "tree_pack_wip.blend"))
print("[tree_pack] DONE")
