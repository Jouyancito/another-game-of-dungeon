"""bake_vcol_to_texture -- vertex colour into a UV texture, by rasterising it.

WHY: everything painted per-vertex on this head has run into the same wall.
The mesh carries a 4.07 mm median edge on the face, so a pore (0.1 mm), a fine
wrinkle (1 mm) and a brow (5.5 mm) are all unrepresentable. Subdividing patches
of the face bought resolution and cost a visible SEAM -- the faceted brow, the
marks on the lid and the row of saw teeth are three symptoms of that one cause.

A texture removes the wall entirely. The mesh already ships a full `UVMap`
(range 0.009..0.994), so nothing has to be unwrapped. At 4096 the face occupies
hundreds of texels where it now has ~30 vertices.

WHY RASTERISE INSTEAD OF CYCLES BAKE: this walks the triangles and fills texels
by barycentric interpolation. It is deterministic, needs no render engine, and
every step is inspectable -- which matters after a session where eight separate
probes returned plausible wrong numbers. A Cycles bake is a black box that
fails quietly on a bad material setup.

The result is verified two ways before it is trusted:
  1. coverage -- how many texels of the used UV area actually got written
  2. round-trip -- sample the texture back at each vertex's UV and compare to
     that vertex's original colour

    blender -b <blend> --python-exit-code 1 --python bake_vcol_to_texture.py \
        -- --obj face_m000 --out baked.blend --png skin.png --size 4096
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

ATTR = "Col"


def vertex_colours(me) -> np.ndarray:
    attr = me.color_attributes.get(ATTR)
    if attr is None:
        raise SystemExit("no %r colour attribute" % ATTR)
    raw = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", raw)
    raw = raw.reshape(-1, 4)[:, :3].astype(np.float64)
    if attr.domain == "POINT":
        return raw
    n = len(me.vertices)
    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    s = np.zeros((n, 3))
    c = np.zeros(n)
    np.add.at(s, lv, raw)
    np.add.at(c, lv, 1.0)
    c[c == 0] = 1.0
    return s / c[:, None]


def triangles_with_uv(me):
    """(tri vertex indices, tri uv coords) using the loop triangles."""
    me.calc_loop_triangles()
    uvl = me.uv_layers.active
    if uvl is None:
        raise SystemExit("the mesh has no UV layer -- nothing to bake into")
    uv = np.empty(len(me.loops) * 2, dtype=np.float32)
    uvl.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)

    tris = np.array([t.vertices[:] for t in me.loop_triangles], dtype=np.int32)
    loops = np.array([t.loops[:] for t in me.loop_triangles], dtype=np.int32)
    return tris, uv[loops]


def rasterise(tris, tri_uv, vcol, size) -> tuple:
    """Fill a size x size RGB buffer by barycentric interpolation."""
    img = np.zeros((size, size, 3), dtype=np.float32)
    hit = np.zeros((size, size), dtype=bool)

    px = tri_uv * np.array([size - 1, size - 1])
    for i in range(len(tris)):
        p = px[i]
        x0 = max(0, int(np.floor(p[:, 0].min())))
        x1 = min(size - 1, int(np.ceil(p[:, 0].max())))
        y0 = max(0, int(np.floor(p[:, 1].min())))
        y1 = min(size - 1, int(np.ceil(p[:, 1].max())))
        if x1 < x0 or y1 < y0:
            continue

        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        ax, ay = p[0]
        bx, by = p[1]
        cx, cy = p[2]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1.0 - w0 - w1
        # A small negative tolerance closes the hairline cracks between
        # adjacent triangles that exact-edge tests leave behind.
        inside = (w0 >= -0.002) & (w1 >= -0.002) & (w2 >= -0.002)
        if not inside.any():
            continue
        cols = (w0[..., None] * vcol[tris[i, 0]]
                + w1[..., None] * vcol[tris[i, 1]]
                + w2[..., None] * vcol[tris[i, 2]])
        sub_img = img[y0:y1 + 1, x0:x1 + 1]
        sub_hit = hit[y0:y1 + 1, x0:x1 + 1]
        sub_img[inside] = cols[inside]
        sub_hit[inside] = True
    return img, hit


def dilate(img, hit, rounds=4):
    """Bleed colour outward past the UV islands.

    Without this, bilinear filtering at an island edge samples the empty
    background and draws a dark seam right down the middle of the face.
    """
    for _ in range(rounds):
        miss = ~hit
        if not miss.any():
            break
        acc = np.zeros_like(img)
        cnt = np.zeros(hit.shape, dtype=np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(img, dy, axis=0), dx, axis=1)
            sm = np.roll(np.roll(hit, dy, axis=0), dx, axis=1)
            acc += sh * sm[..., None]
            cnt += sm
        grow = miss & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][..., None]
        hit = hit | grow
    return img, hit


def box_blur(a, r):
    """Separable box blur by cumulative sums. Blender ships numpy, not scipy,
    and a mask feather is the only thing this is needed for."""
    if r < 1:
        return a
    out = a.astype(np.float32)
    for axis in (0, 1):
        n = out.shape[axis]
        pad = [(0, 0), (0, 0)]
        pad[axis] = (r + 1, r)
        c = np.cumsum(np.pad(out, pad, mode="edge"), axis=axis)
        lo = np.take(c, np.arange(0, n), axis=axis)
        hi = np.take(c, np.arange(2 * r + 1, n + 2 * r + 1), axis=axis)
        out = (hi - lo) / float(2 * r + 1)
    return out


def push_pull_fill(img, known, max_levels=12):
    """Fill unknown texels by pyramid push-pull. Converges; diffusion does not.

    Iterated neighbour averaging (what `dilate` does) fails on a hole with a
    PARTIAL border: with edges on only one side there is nothing to average
    against, so the fill drags rows across and leaves horizontal BANDING. That
    banding is what read as a second, fatter eyebrow on one side of the face
    for four passes -- the mask and the erase were both symmetric the whole
    time, so nothing upstream could explain it.

    Push-pull instead builds a pyramid: PUSH averages colour down to coarser
    levels using only known texels, then PULL walks back up filling unknowns
    from the level above. Every hole reaches a level where its whole
    neighbourhood is known, so the fill always converges and stays smooth.
    """
    pyr_img = [img.astype(np.float32).copy()]
    pyr_w = [known.astype(np.float32).copy()]

    # PUSH: halve until the map is tiny, weighting by how much is known.
    while (min(pyr_img[-1].shape[:2]) > 2 and len(pyr_img) < max_levels):
        src_i, src_w = pyr_img[-1], pyr_w[-1]
        h, w = src_w.shape
        h2, w2 = h // 2, w // 2
        si = src_i[:h2 * 2, :w2 * 2].reshape(h2, 2, w2, 2, 3)
        sw = src_w[:h2 * 2, :w2 * 2].reshape(h2, 2, w2, 2)
        acc_w = sw.sum(axis=(1, 3))
        acc_i = (si * sw[..., None]).sum(axis=(1, 3))
        safe = np.maximum(acc_w, 1e-8)
        pyr_img.append(acc_i / safe[..., None])
        pyr_w.append(np.minimum(acc_w / 4.0, 1.0))

    # PULL: from coarse to fine, unknown texels take the upper level.
    for lvl in range(len(pyr_img) - 2, -1, -1):
        up_i = np.repeat(np.repeat(pyr_img[lvl + 1], 2, axis=0), 2, axis=1)
        up_w = np.repeat(np.repeat(pyr_w[lvl + 1], 2, axis=0), 2, axis=1)
        h, w = pyr_w[lvl].shape
        up_i = up_i[:h, :w]
        up_w = up_w[:h, :w]
        a = pyr_w[lvl][..., None]
        pyr_img[lvl] = pyr_img[lvl] * a + up_i * (1.0 - a)
        pyr_w[lvl] = np.maximum(pyr_w[lvl], up_w)

    return pyr_img[0], pyr_w[0] > 0.001


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--png", required=True)
    ap.add_argument("--size", type=int, default=2048)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    me = obj.data
    vcol = vertex_colours(me)
    tris, tri_uv = triangles_with_uv(me)
    print("")
    print("  %s: %d verts, %d triangles, UV %.3f..%.3f"
          % (obj.name, len(me.vertices), len(tris),
             tri_uv.min(), tri_uv.max()))

    img, hit = rasterise(tris, tri_uv, vcol, args.size)
    covered = float(hit.mean())
    print("  rasterised: %.1f%% of the %d x %d map covered"
          % (covered * 100, args.size, args.size))
    # CONTROL: a UV layout for a whole body fills a good part of the square.
    # A few percent means the UVs are degenerate or the triangles were read
    # wrong, and every later step would build on a blank texture.
    if covered < 0.20:
        raise SystemExit("only %.1f%% covered -- the bake is essentially"
                         " empty, do not build on it" % (covered * 100))

    img, hit = dilate(img, hit, rounds=6)

    # ROUND-TRIP CHECK: read the texture back at each vertex's own UV and
    # compare with the colour it started from. This is what proves the bake
    # carries the work rather than merely producing a plausible image.
    uvl = me.uv_layers.active
    uv = np.empty(len(me.loops) * 2, dtype=np.float32)
    uvl.data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    xs = np.clip((uv[:, 0] * (args.size - 1)).astype(int), 0, args.size - 1)
    ys = np.clip((uv[:, 1] * (args.size - 1)).astype(int), 0, args.size - 1)
    sampled = img[ys, xs]
    err = np.abs(sampled - vcol[lv]).max(axis=1)
    print("  round-trip error: mean %.4f  p99 %.4f  max %.4f"
          % (err.mean(), np.percentile(err, 99), err.max()))
    if err.mean() > 0.02:
        raise SystemExit("mean round-trip error %.4f is too high -- the bake"
                         " does not reproduce the vertex colours" % err.mean())

    png = os.path.abspath(args.png)
    im = bpy.data.images.new("skin_baked", args.size, args.size, alpha=False)
    # NON-COLOR. The pixels written below are LINEAR, because that is what the
    # vertex colour attribute stores. A new image defaults to sRGB, so Blender
    # would apply sRGB->linear on data that is already linear and render the
    # skin dark and muddy -- which is exactly what the first bake looked like.
    im.colorspace_settings.name = "Non-Color"
    rgba = np.ones((args.size, args.size, 4), dtype=np.float32)
    rgba[..., :3] = img
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = png
    im.file_format = "PNG"
    im.save()
    if not (os.path.isfile(png) and os.path.getsize(png) > 0):
        raise SystemExit("texture was not written to %s" % png)
    print("  texture -> %s (%d KB)" % (png, os.path.getsize(png) // 1024))

    # Wire it into a material so the blend opens showing the texture, not the
    # vertex colours it came from.
    mat = bpy.data.materials.new("skin_tex")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = im
    tex.interpolation = "Smart"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.88
    for nm, val in (("Specular IOR Level", 0.25), ("Subsurface Weight", 0.18)):
        if nm in bsdf.inputs:
            bsdf.inputs[nm].default_value = val
    if "Subsurface Radius" in bsdf.inputs:
        bsdf.inputs["Subsurface Radius"].default_value = (0.010, 0.004, 0.002)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    me.materials.clear()
    me.materials.append(mat)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
