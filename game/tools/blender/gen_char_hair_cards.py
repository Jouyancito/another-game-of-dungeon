"""gen_char_hair_cards -- the warrior's undercut as alpha hair cards.

This is the technique the project's own contract calls for, and the two files
that define it were written on 2026-08-15 precisely because the hair had failed
three times:

  _asset_creation_contract.md 3b   ceiling is SKYRIM -> "cards con alpha,
                                   mechones translucidos". Opaque shells are
                                   the RDR1 row, one rung below.
  _asset_creation_contract.md 402  hair_polygon_shells/ is marked TECNICA
                                   DESCARTADA (anime).
  _modeling_knowledge_base.md      the three-layer method, below.

Three layers, in this order, because each one has ONE job:

  1. scalp cap    opaque shell in the hair colour, grown from the `scalp`
                  group's own faces. Coverage is 100% BY CONSTRUCTION and
                  never depends on cards happening to touch. Measured on this
                  warrior: 30.3% -> 0.1% exposed in a single step.
  2. cards        volume and silhouette, NEVER coverage. Sizing cards for
                  coverage is the documented trap: the original plates had
                  3.8x the scalp's area and still had holes, because total
                  area says nothing about WHERE a plate lands.
  3. loose        few, asymmetric, for identity. Last.

Hard rule from Joan, same document: hair falls AROUND the ear, it never cuts
across it. The ear group is read off the model and every card is traced to
avoid it.

A card is a strip that starts at a root on the scalp, is dragged backward along
the skull by raycast while there is skull under it, and falls under gravity
once it runs past the head. That is what makes a lock hang instead of hover.
"""
from __future__ import annotations

import argparse
import importlib.util
import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE = os.path.dirname(os.path.abspath(__file__))

_spec = importlib.util.spec_from_file_location(
    "sketch_char_hair", os.path.join(HERE, "sketch_char_hair.py"))
sk = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sk)
cc = sk.cc


# ----------------------------------------------------------------- material

def hair_material(name, atlas_path, tint_hex):
    """Alpha-cutout material sampling the strand atlas.

    The tint multiplies the atlas so one greyscale atlas serves every hair
    colour in the roster; only the value variation between strands is baked.
    """
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    mix = nt.nodes.new("ShaderNodeMixRGB")
    img = bpy.data.images.load(os.path.abspath(atlas_path))
    img.alpha_mode = "CHANNEL_PACKED"
    tex.image = img
    tex.interpolation = "Closest" if False else "Linear"
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    mix.inputs[2].default_value = (*sk.srgb_to_linear(tint_hex), 1.0)
    nt.links.new(tex.outputs["Color"], mix.inputs[1])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.88
    for slot in ("Specular IOR Level", "Specular"):
        if slot in bsdf.inputs:
            bsdf.inputs[slot].default_value = 0.04
            break
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    # Blender renamed the alpha pipeline between 4.1 and 4.2; set whichever
    # this build exposes rather than assuming, and never let it fail silently.
    ok = []
    for attr, val in (("blend_method", "CLIP"), ("shadow_method", "CLIP"),
                      ("surface_render_method", "DITHERED")):
        if hasattr(mat, attr):
            try:
                setattr(mat, attr, val)
                ok.append(attr)
            except TypeError:
                pass
    mat.use_backface_culling = False
    print("  material %s: alpha via %s" % (name, ", ".join(ok) or "ninguno (!)"))
    return mat


def flat_material(name, hex_col):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*sk.srgb_to_linear(hex_col), 1.0)
    bsdf.inputs["Roughness"].default_value = 0.92
    for slot in ("Specular IOR Level", "Specular"):
        if slot in bsdf.inputs:
            bsdf.inputs[slot].default_value = 0.04
            break
    return mat


# --------------------------------------------------------------- scalp cap

def build_scalp_cap(body, keep_fn, name, mat, inflate=0.0035):
    """Copy the scalp group's own faces and inflate them along their normals.

    Grown from the model's topology rather than a raycast grid: the cap then
    fits the skull exactly, and the border follows real edges instead of a
    sampling artefact -- which is what produced the staircase in the shell
    attempt.
    """
    vg = body.vertex_groups.get("scalp")
    idx = {v.index for v in body.data.vertices
           if any(g.group == vg.index for g in v.groups)}

    W, N = cc.morphed_coords(body)
    bm = bmesh.new()
    vmap = {}
    faces = 0
    for poly in body.data.polygons:
        vs = list(poly.vertices)
        if not all(i in idx for i in vs):
            continue
        pts = [W[i] for i in vs]
        if not keep_fn(np.mean(pts, axis=0)):
            continue
        ring = []
        for i in vs:
            if i not in vmap:
                vmap[i] = bm.verts.new(Vector(W[i] + N[i] * inflate))
            ring.append(vmap[i])
        try:
            bm.faces.new(ring)
            faces += 1
        except ValueError:
            pass
    if faces == 0:
        raise SystemExit("%s: el cap salió vacío" % name)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    print("  %-16s %4d caras" % (name, faces))
    return obj


# -------------------------------------------------------------------- card

def trace_card(bvh, root, normal, steps, step_len, gravity, ear_guard):
    """Drag a lock backward over the skull, then let it fall off the end.

    While a raycast finds skull beneath the advancing point the lock stays
    glued to it (offset by a hair's thickness); once the ray misses, the head
    is behind us and the lock hangs. That single rule is what separates hair
    that lies on a head from a shell floating over one.
    """
    pts, nrm = [], []
    p = Vector(root) + Vector(normal) * 0.004
    d = Vector((0.0, 1.0, -0.12)).normalized()
    vel = 0.0
    for k in range(steps):
        pts.append(p.copy())
        # Probe straight at the skull from just outside it.
        hit, hn, _, _ = bvh.ray_cast(p + Vector(normal) * 0.05, -Vector(normal))
        if hit is not None and (hit - p).length < 0.05:
            n = Vector(hn)
            nrm.append(n)
            # Slide along the surface: remove the component into the skull.
            d = (d - n * d.dot(n)).normalized()
            p = hit + n * (0.0030 + 0.0045 * (k / max(steps - 1, 1)) ** 2)
            vel = 0.0
        else:
            n = nrm[-1] if nrm else Vector(normal)
            nrm.append(n)
            vel += gravity
            d = (d + Vector((0.0, 0.0, -vel))).normalized()
        # Never cross the ear: push the path outward if it would enter it.
        if ear_guard is not None:
            c, r = ear_guard
            for sgn in (1.0, -1.0):
                cc_ = Vector((sgn * c[0], c[1], c[2]))
                off = p - cc_
                if off.length < r:
                    p = cc_ + off.normalized() * r
        p = p + d * step_len
    return pts, nrm


def card_mesh(pts, nrm, width, cell, cols, rows, name, mat, taper=0.55):
    """Ribbon through the traced path, UV-mapped to one atlas cell."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    n = len(pts)
    cu, cv = cell
    u0, u1 = cu / cols, (cu + 1) / cols
    v0, v1 = 1.0 - (cv + 1) / rows, 1.0 - cv / rows
    rowsv = []
    for k, (p, nv) in enumerate(zip(pts, nrm)):
        t = k / (n - 1)
        fwd = (pts[min(k + 1, n - 1)] - pts[max(k - 1, 0)])
        if fwd.length < 1e-6:
            fwd = Vector((0, 1, 0))
        side = fwd.normalized().cross(nv).normalized()
        w = width * (1.0 - taper * t ** 1.4)
        a = bm.verts.new(p - side * w)
        b = bm.verts.new(p + side * w)
        rowsv.append((a, b, t))
    for k in range(n - 1):
        a0, b0, t0 = rowsv[k]
        a1, b1, t1 = rowsv[k + 1]
        f = bm.faces.new((a0, b0, b1, a1))
        for loop in f.loops:
            if loop.vert is a0:
                loop[uv].uv = (u0, v1 + (v0 - v1) * t0)
            elif loop.vert is b0:
                loop[uv].uv = (u1, v1 + (v0 - v1) * t0)
            elif loop.vert is b1:
                loop[uv].uv = (u1, v1 + (v0 - v1) * t1)
            else:
                loop[uv].uv = (u0, v1 + (v0 - v1) * t1)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


# -------------------------------------------------------------------- main

def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--atlas", required=True)
    ap.add_argument("--undercut-z", type=float, default=1.728)
    ap.add_argument("--line-tilt", type=float, default=0.022)
    ap.add_argument("--cards", type=int, default=34)
    ap.add_argument("--loose", type=int, default=6)
    ap.add_argument("--width", type=float, default=0.021)
    ap.add_argument("--steps", type=int, default=10)
    ap.add_argument("--step-len", type=float, default=0.017)
    ap.add_argument("--gravity", type=float, default=0.085)
    ap.add_argument("--hair-hex", default="#6B4A2B")
    ap.add_argument("--shave-hex", default="#40301F")
    ap.add_argument("--atlas-cols", type=int, default=4)
    ap.add_argument("--atlas-rows", type=int, default=2)
    ap.add_argument("--seed", type=int, default=5)
    args = ap.parse_args(argv)

    rng = random.Random(args.seed)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    body = max(meshes, key=lambda o: len(o.data.vertices))
    W, N = cc.morphed_coords(body)
    verts, polys = sk.body_mesh(body)
    bvh = BVHTree.FromPolygons(verts, polys)

    def group(nm):
        vg = body.vertex_groups.get(nm)
        if vg is None:
            return np.array([], dtype=int)
        return np.array([v.index for v in body.data.vertices
                         if any(g.group == vg.index for g in v.groups)], dtype=int)

    scalp_i = group("scalp")
    ear_i = group("ears")
    ear_c = None
    ear_r = None
    if len(ear_i):
        # MIRROR the ears onto one side BEFORE averaging. Averaging the raw x
        # of both ears gives ~0 -- the centre of the head -- and a radius that
        # spans ear to ear, so the guard would shove every card off the skull.
        E = W[ear_i].copy()
        E[:, 0] = np.abs(E[:, 0])
        ear_c = E.mean(axis=0)
        ear_r = float(np.linalg.norm(E - ear_c, axis=1).max()) + 0.007
        print("  oreja: centro |x|=%.3f y=%.3f z=%.3f  radio de guarda %.1f mm"
              % (*ear_c, ear_r * 1000))
    ear_guard = (ear_c, ear_r) if ear_c is not None else None

    def z_line_at(p):
        return args.undercut_z + args.line_tilt * float(
            np.clip((p[1] - 0.02) / 0.12, -1.0, 1.0))

    mat_hair = hair_material("hair_cards", args.atlas, args.hair_hex)
    mat_cap = flat_material("hair_cap", args.hair_hex)
    mat_cap.use_backface_culling = False
    mat_shave = flat_material("hair_shave", args.shave_hex)
    mat_shave.use_backface_culling = False

    made = []
    # LAYER 1 -- coverage, by construction.
    made.append(build_scalp_cap(body, lambda p: p[2] <= z_line_at(p) + 0.010,
                                "hair_shave_cap", mat_shave, inflate=0.0016))
    made.append(build_scalp_cap(body, lambda p: p[2] > z_line_at(p) - 0.012,
                                "hair_cap", mat_cap, inflate=0.0026))

    # LAYER 2 -- volume and silhouette. Roots only above the shave line.
    roots = [i for i in scalp_i if W[i][2] > z_line_at(W[i]) + 0.004]
    if not roots:
        raise SystemExit("sin raíces por encima de la línea -- nada que peinar")
    roots.sort(key=lambda i: (-W[i][1], abs(W[i][0])))

    # Ordered layers: nape first, then sides, then front, each riding slightly
    # higher than the one below so it rests on it instead of intersecting.
    n_layers = 3
    per = max(args.cards // n_layers, 1)
    made_cards = 0
    for layer in range(n_layers):
        lo = layer * len(roots) // (n_layers + 1)
        band = roots[lo:lo + 2 * len(roots) // (n_layers + 1)]
        if not band:
            continue
        for c in range(per):
            i = band[rng.randrange(len(band))]
            r = W[i] + N[i] * (0.0055 * layer)
            cell = (rng.randrange(args.atlas_cols), rng.randrange(min(args.atlas_rows, 2)))
            pts, nrm = trace_card(bvh, r, N[i], args.steps,
                                  args.step_len * rng.uniform(0.85, 1.15),
                                  args.gravity, ear_guard)
            o = card_mesh(pts, nrm, args.width * rng.uniform(0.8, 1.25), cell,
                          args.atlas_cols, args.atlas_rows,
                          "hair_card_%d_%02d" % (layer, c), mat_hair)
            made.append(o)
            made_cards += 1
    print("  cards: %d en %d capas (nuca -> laterales -> frente)" % (made_cards, n_layers))

    # LAYER 3 -- loose strands, few and asymmetric.
    for c in range(args.loose):
        i = roots[rng.randrange(len(roots))]
        cell = (rng.randrange(args.atlas_cols), args.atlas_rows - 1)
        pts, nrm = trace_card(bvh, W[i] + N[i] * 0.012, N[i],
                              args.steps + 3, args.step_len * 1.15,
                              args.gravity * 1.4, ear_guard)
        made.append(card_mesh(pts, nrm, args.width * 0.55, cell,
                              args.atlas_cols, args.atlas_rows,
                              "hair_loose_%02d" % c, mat_hair, taper=0.8))
    print("  sueltos: %d" % args.loose)

    tv = sum(len(o.data.vertices) for o in made)
    tf = sum(len(o.data.polygons) for o in made)
    print("  total: %d objetos  %d verts  %d caras" % (len(made), tv, tf))

    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.out))
    print("  guardado -> %s" % args.out)


if __name__ == "__main__":
    main()
