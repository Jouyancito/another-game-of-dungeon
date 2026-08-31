# texture_bake.py — procedural REALISTIC stone albedo baked to per-part UV
# textures for the golem guardian (PO 2026-08-27: "mas ancestrales, musgos,
# grietas, realistas, no unas cosas muy poligonales — necesito realismo para
# darle profundidad"). This is Art Canon §17 (Valheim model: silhouette =
# geometry, surface = TEXTURE) applied to the sub-boss.
#
# Method (extends bake_vcol_to_texture.py's deterministic rasterizer — no
# Cycles black box): every texel interpolates its triangle's LOCAL-SPACE
# position + normal barycentrically, then a fully-vectorized numpy noise
# stack evaluates albedo(p, n): large mottling, voronoi-edge cracks with
# dirt, cavity grime, patchy moss on up-facing surfaces, lichen speckle,
# fine grain. Because color is a function of 3D position, UV seams are
# invisible by construction — adjacent texels across any seam sample nearby
# 3D points.
import math

import bmesh
import bpy
import numpy as np
from mathutils import Vector

# ---------------------------------------------------------------- numpy noise
def _hash3(xi, yi, zi, seed):
    h = np.sin(xi * 127.1 + yi * 311.7 + zi * 74.7 + seed * 91.3) * 43758.5453
    return h - np.floor(h)


def _smooth(t):
    return t * t * (3.0 - 2.0 * t)


def value_noise(p, seed=0.0):
    """Trilinear value noise, p: (...,3) array, returns (...,) in [0,1]."""
    pf = np.floor(p)
    xi, yi, zi = pf[..., 0], pf[..., 1], pf[..., 2]
    tx, ty, tz = (_smooth(p[..., i] - pf[..., i]) for i in range(3))
    c = {}
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                c[(dx, dy, dz)] = _hash3(xi + dx, yi + dy, zi + dz, seed)
    x00 = c[(0, 0, 0)] * (1 - tx) + c[(1, 0, 0)] * tx
    x10 = c[(0, 1, 0)] * (1 - tx) + c[(1, 1, 0)] * tx
    x01 = c[(0, 0, 1)] * (1 - tx) + c[(1, 0, 1)] * tx
    x11 = c[(0, 1, 1)] * (1 - tx) + c[(1, 1, 1)] * tx
    y0 = x00 * (1 - ty) + x10 * ty
    y1 = x01 * (1 - ty) + x11 * ty
    return y0 * (1 - tz) + y1 * tz


def fbm(p, octaves=3, seed=0.0):
    out = np.zeros(p.shape[:-1], dtype=np.float64)
    amp, freq, norm = 1.0, 1.0, 0.0
    for o in range(octaves):
        out += amp * value_noise(p * freq, seed + o * 17.7)
        norm += amp
        amp *= 0.5
        freq *= 2.1
    return out / norm


def voronoi_edge(p, seed=0.0):
    """F2-F1 edge distance (small near cell borders = crack lines)."""
    pf = np.floor(p)
    d = []
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                cell = pf + np.array([dx, dy, dz], dtype=np.float64)
                ox = _hash3(cell[..., 0], cell[..., 1], cell[..., 2], seed)
                oy = _hash3(cell[..., 0], cell[..., 1], cell[..., 2], seed + 31.7)
                oz = _hash3(cell[..., 0], cell[..., 1], cell[..., 2], seed + 57.3)
                feat = cell + np.stack([ox, oy, oz], axis=-1)
                diff = feat - p
                d.append(np.sqrt((diff * diff).sum(axis=-1)))
    d = np.stack(d, axis=0)
    d.sort(axis=0)
    return d[1] - d[0]


# ------------------------------------------------------------------- albedo
STONE_BASE = np.array([0.47, 0.455, 0.43])
CRACK_DIRT = np.array([0.24, 0.20, 0.155])
CAVITY_DIRT = np.array([0.33, 0.28, 0.21])
MOSS_A = np.array([0.155, 0.30, 0.095])   # mid green
MOSS_B = np.array([0.235, 0.315, 0.085])  # dry yellow-green
MOSS_C = np.array([0.085, 0.21, 0.075])   # deep shade green
LICHEN_COL = np.array([0.55, 0.57, 0.46])


def albedo(p, n, part_tone=1.0, seed=0.0):
    """p: (...,3) local positions, n: (...,3) normals ->
    ((...,3) linear RGB, (...) height field for the normal map).

    v16 crack realism (PO 2026-08-27, verbatim: "grietas uniformes... eso
    realmente no pasa. Hay piedras que no tienen, otras mucho mas grandes.
    Esa grieta se ve reflejada EN la piedra"): crack frequency, width and
    PRESENCE all vary per REGION via very-low-frequency noise — some stones
    end up uncracked, others carry one deep wide fault — and the same crack
    field feeds a height map baked to a tangent normal map, so the groove
    reads in the lighting, not as a decal."""
    mottle = fbm(p * 0.85, 3, seed)                       # large tonal patches
    val = (0.72 + 0.55 * mottle) * part_tone
    rgb = STONE_BASE[None, :] * val[..., None]

    grain = value_noise(p * 13.0, seed + 5.0) - 0.5       # fine speckle
    rgb *= (1.0 + 0.10 * grain)[..., None]

    # per-region crack character (freq/width/presence vary stone to stone)
    zone = value_noise(p * 0.28, seed + 7.0)
    crack_freq = 0.9 + 2.0 * value_noise(p * 0.22, seed + 9.0)
    crack_w = 0.030 + 0.065 * value_noise(p * 0.31, seed + 13.0)
    edge = voronoi_edge(p * crack_freq[..., None], seed + 11.0)
    crack = np.clip((crack_w - edge) / (crack_w * 0.8), 0.0, 1.0)
    crack *= (zone > 0.38)                                # some stones: none
    deep = (zone > 0.78)                                  # some: one deep fault
    crack_depth = crack * np.where(deep, 1.0, 0.55)
    rgb = rgb * (1.0 - 0.62 * crack_depth[..., None]) \
        + CRACK_DIRT[None, :] * (0.30 * crack_depth[..., None])

    cav = fbm(p * 2.3, 3, seed + 41.0)                    # grime pockets
    cav_m = np.clip((cav - 0.58) / 0.20, 0.0, 1.0) * 0.45
    rgb = rgb * (1.0 - cav_m[..., None]) + CAVITY_DIRT[None, :] * cav_m[..., None]

    up = np.clip(n[..., 2], 0.0, 1.0)                     # patchy real moss
    moss_field = fbm(p * 2.1, 3, seed + 61.0)
    moss_m = np.clip((moss_field * 0.75 + up * 0.65 - 0.62) / 0.30, 0.0, 1.0)
    # v17 (PO: "el musgo tiene 1 puro color"): patch-level HUE variation —
    # dry yellowish patches next to deep-shade ones, plus the brightness mix.
    hue_t = fbm(p * 1.3, 2, seed + 67.0)
    moss_base = (MOSS_A[None, :] * np.clip(1.0 - np.abs(hue_t - 0.5) * 2.0, 0, 1)[..., None]
                 + MOSS_B[None, :] * np.clip((hue_t - 0.5) * 2.0, 0, 1)[..., None]
                 + MOSS_C[None, :] * np.clip((0.5 - hue_t) * 2.0, 0, 1)[..., None])
    moss_shade = 0.75 + 0.5 * fbm(p * 6.5, 2, seed + 71.0)
    moss_rgb = moss_base * moss_shade[..., None]
    rgb = rgb * (1.0 - 0.9 * moss_m[..., None]) + moss_rgb * (0.9 * moss_m[..., None])

    lich = value_noise(p * 8.5, seed + 83.0)              # lichen speckle
    lich_m = ((lich > 0.80) & (up > 0.05) & (moss_m < 0.4)).astype(np.float64) * 0.55
    rgb = rgb * (1.0 - lich_m[..., None]) + LICHEN_COL[None, :] * lich_m[..., None]

    # height: cracks carve DOWN (deep faults carve harder), moss puffs UP a
    # touch, grain adds micro-relief
    height = (-0.85 * crack_depth * np.where(deep, 1.6, 1.0)
              + 0.18 * moss_m + 0.06 * grain - 0.10 * cav_m)
    return np.clip(rgb, 0.0, 1.0), height


# ------------------------------------------------------------- mesh plumbing
def smart_unwrap(obj, stone_slot):
    """Unwrap ONLY the stone-material faces. v18 bug: unwrapping everything
    re-mapped the leaf-card quads joined into the torso and their atlas UVs
    were destroyed — the bushes rendered as opaque dark squares. Cards keep
    their authored UVs; only the rocks get fresh islands."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    obj.active_material_index = stone_slot
    with bpy.context.temp_override(active_object=obj, object=obj,
                                   selected_objects=[obj],
                                   selected_editable_objects=[obj]):
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="DESELECT")
        bpy.ops.object.material_slot_select()
        bpy.ops.uv.smart_project(angle_limit=math.radians(60.0),
                                 island_margin=0.008, correct_aspect=True)
        bpy.ops.object.mode_set(mode="OBJECT")


def _mesh_arrays(me, stone_slot):
    """Triangulated (pos, normal, uv) arrays for STONE-material polys only."""
    me.calc_loop_triangles()
    uv_layer = me.uv_layers.active.data
    tris_uv, tris_pos, tris_nrm = [], [], []
    for lt in me.loop_triangles:
        if me.polygons[lt.polygon_index].material_index != stone_slot:
            continue
        tris_uv.append([uv_layer[l].uv[:] for l in lt.loops])
        tris_pos.append([me.vertices[v].co[:] for v in lt.vertices])
        tris_nrm.append([me.vertices[v].normal[:] for v in lt.vertices])
    return (np.array(tris_uv, dtype=np.float64),
            np.array(tris_pos, dtype=np.float64),
            np.array(tris_nrm, dtype=np.float64))


def rasterize_albedo(tri_uv, tri_pos, tri_nrm, size, part_tone, seed):
    img = np.zeros((size, size, 3), dtype=np.float64)
    hgt = np.zeros((size, size), dtype=np.float64)
    hit = np.zeros((size, size), dtype=bool)
    px = tri_uv * (size - 1)
    for i in range(len(px)):
        p = px[i]
        x0 = max(0, int(np.floor(p[:, 0].min())))
        x1 = min(size - 1, int(np.ceil(p[:, 0].max())))
        y0 = max(0, int(np.floor(p[:, 1].min())))
        y1 = min(size - 1, int(np.ceil(p[:, 1].max())))
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        (ax, ay), (bx, by), (cx, cy) = p
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -0.003) & (w1 >= -0.003) & (w2 >= -0.003)
        if not inside.any():
            continue
        pos = (w0[..., None] * tri_pos[i, 0] + w1[..., None] * tri_pos[i, 1]
               + w2[..., None] * tri_pos[i, 2])
        nrm = (w0[..., None] * tri_nrm[i, 0] + w1[..., None] * tri_nrm[i, 1]
               + w2[..., None] * tri_nrm[i, 2])
        cols, h = albedo(pos[inside], nrm[inside], part_tone, seed)
        sub_img = img[y0:y1 + 1, x0:x1 + 1]
        sub_hgt = hgt[y0:y1 + 1, x0:x1 + 1]
        sub_hit = hit[y0:y1 + 1, x0:x1 + 1]
        sub_img[inside] = cols
        sub_hgt[inside] = h
        sub_hit[inside] = True
    return img, hgt, hit


def dilate(img, hit, rounds=6):
    for _ in range(rounds):
        miss = ~hit
        if not miss.any():
            break
        acc = np.zeros_like(img)
        cnt = np.zeros(hit.shape, dtype=np.float64)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(img, dy, axis=0), dx, axis=1)
            sm = np.roll(np.roll(hit, dy, axis=0), dx, axis=1)
            acc += sh * sm[..., None]
            cnt += sm
        fill = miss & (cnt > 0)
        img[fill] = acc[fill] / cnt[fill][..., None]
        hit = hit | fill
    return img


def _to_srgb(lin):
    return np.where(lin <= 0.0031308, lin * 12.92,
                    1.055 * np.power(np.clip(lin, 0.0, 1.0), 1.0 / 2.4) - 0.055)


def height_to_normal(hgt, strength=3.0):
    """Tangent-space normal map from the baked height field. Texture-space
    gradients map onto the mesh's UV-derived tangent frame, so this is valid
    for any island layout smart_project produces."""
    gy, gx = np.gradient(hgt)
    n = np.stack([-gx * strength, gy * strength, np.ones_like(hgt)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def _save_normal_image(name, nrm_map):
    size = nrm_map.shape[0]
    im = bpy.data.images.new(name, width=size, height=size, alpha=False)
    im.colorspace_settings.name = "Non-Color"
    rgba = np.ones((size, size, 4), dtype=np.float32)
    rgba[..., :3] = nrm_map.astype(np.float32)
    im.pixels.foreach_set(rgba.ravel())
    im.pack()
    return im


def _save_image(name, img_lin):
    size = img_lin.shape[0]
    im = bpy.data.images.new(name, width=size, height=size, alpha=False)
    im.colorspace_settings.name = "sRGB"
    rgba = np.ones((size, size, 4), dtype=np.float32)
    rgba[..., :3] = _to_srgb(img_lin).astype(np.float32)
    im.pixels.foreach_set(rgba.ravel())
    im.pack()
    return im


def bake_part(obj, stone_mat, size, part_tone, seed):
    """Unwrap obj, bake albedo for its stone-material faces, swap that slot's
    material for a textured one. Neutralizes the 'Col' attribute to white so
    glTF's COLOR_0 multiply doesn't double-darken the texture."""
    me = obj.data
    stone_slot = -1
    for i, m in enumerate(me.materials):
        if m is stone_mat:
            stone_slot = i
            break
    if stone_slot < 0:
        return
    smart_unwrap(obj, stone_slot)
    tri_uv, tri_pos, tri_nrm = _mesh_arrays(me, stone_slot)
    if len(tri_uv) == 0:
        return
    img, hgt, hit = rasterize_albedo(tri_uv, tri_pos, tri_nrm, size, part_tone, seed)
    img = dilate(img, hit.copy())
    hgt3 = dilate(np.repeat(hgt[..., None], 3, axis=-1), hit.copy())
    nrm_map = height_to_normal(hgt3[..., 0], strength=3.2)
    image = _save_image(f"tex_{obj.name}", img)
    nimage = _save_normal_image(f"nrm_{obj.name}", nrm_map)

    mat = bpy.data.materials.new(f"stone_tex_{obj.name}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Specular IOR Level"].default_value = 0.18
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    ntex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    ntex.image = nimage
    nmap = mat.node_tree.nodes.new("ShaderNodeNormalMap")
    nmap.inputs["Strength"].default_value = 1.0
    mat.node_tree.links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    mat.node_tree.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    me.materials[stone_slot] = mat

    col = me.color_attributes.get("Col")
    if col is not None:
        n = len(col.data)
        col.data.foreach_set("color", [1.0] * (n * 4))


def bake_all(parts, stone_mat, sizes=None, seed_base=7.0):
    sizes = sizes or {}
    for i, (name, obj) in enumerate(parts.items()):
        size = sizes.get(name, 1024)
        tone = 0.92 + 0.16 * ((i * 0.37) % 1.0)
        print(f"[texture_bake] {name} -> {size}px")
        bake_part(obj, stone_mat, size, tone, seed_base + i * 13.7)
