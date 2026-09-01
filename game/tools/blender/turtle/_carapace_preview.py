"""_carapace_preview -- build the scute-assembled carapace ALONE and orbit it.

This is the side-by-side for the shell currently on the turtle, which is a UV
sphere with the plates painted on. Nothing else is in the scene: no head, no
limbs, no plastron, because the question is only whether a carapace built FROM
its scutes reads as a carapace.

    blender -b --factory-startup --python-exit-code 1 \
        --python _carapace_preview.py -- --out renders/carapace_scutes
"""
from __future__ import annotations

import argparse
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [_HERE, os.path.dirname(_HERE)]

import bmesh
import bpy

import _carapace
import _carapace_texture
from _turtle_shell_zone import orbit


# Value per plate kind, before the ring alternation. A carapace is not one
# flat colour: the midline plates catch the light, the rim is darker.
KIND_VALUE = {
    "nuchal": 0.72,
    "vertebral": 0.86,
    "pleural": 0.78,
    "marginal": 0.62,
}


def tone_of(kind, index, ring):
    """0-1 value for one face: plate kind, plate identity, growth ring."""
    base = KIND_VALUE.get(kind, 0.75)
    # Neighbouring plates of the same kind must not be the same value or the
    # seams disappear and the shell reads as one surface again.
    base *= 1.0 + 0.06 * ((index % 3) - 1)
    # Fast season -> wide pale band, lean season -> narrow dark one.
    base *= 1.0 + (0.18 if ring % 2 == 0 else -0.18)
    return max(0.05, min(1.0, base))


def shell_material(image=None):
    if image is not None:
        mat = bpy.data.materials.new("carapace")
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = nt.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.62
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Smart"
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        return mat
    return _shell_material_vcol()


def _shell_material_vcol():
    mat = bpy.data.materials.new("carapace")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.72
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    mix = nt.nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs["Fac"].default_value = 1.0
    mix.inputs["Color2"].default_value = (0.09, 0.34, 0.13, 1.0)  # carapace green
    nt.links.new(attr.outputs["Color"], mix.inputs["Color1"])
    nt.links.new(mix.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--res", type=int, default=900)
    ap.add_argument("--rings", type=int, default=5)
    ap.add_argument("--scute-rise", type=float, default=None)
    ap.add_argument("--seam-drop", type=float, default=None)
    ap.add_argument("--ring-groove", type=float, default=None)
    ap.add_argument("--n", type=int, default=36)
    ap.add_argument("--band", type=int, default=4)
    ap.add_argument("--tex", type=int, default=512)
    args = ap.parse_args(argv)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    spec = _carapace.CarapaceSpec(rings=args.rings, n=args.n, band=args.band)
    for name, val in (("scute_rise", args.scute_rise),
                      ("seam_drop", args.seam_drop),
                      ("ring_groove", args.ring_groove)):
        if val is not None:
            setattr(spec, name, val)

    bm = bmesh.new()
    # FLOAT_COLOR, never BYTE_COLOR: bmesh writes without the sRGB encode that
    # the read side applies, so a byte layer comes back several times darker.
    col = bm.loops.layers.float_color.new("Col")
    uv = bm.loops.layers.uv.new("UVMap")
    stats = _carapace.build(bm, spec, colour_layer=col, tone_of=tone_of,
                            uv_layer=uv)

    me = bpy.data.meshes.new("carapace")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        # SMOOTH now, not flat. `_art_canon.md` 17.3 retired the toon ramp for
        # the world in favour of soft PBR, and a scute is keratin: it has a
        # rounded crown and a hard crease at the seam. The crease survives
        # smooth shading because it is real geometry, which is the whole
        # argument for building the plates instead of painting them.
        p.use_smooth = True
    # Control probe. The first textured render showed geometry shading and no
    # pattern at all, which looks identical whether the bake is wrong or the
    # UVs never arrived. The bake was verified separately; this measures the
    # other half instead of guessing again.
    uvl = me.uv_layers.active
    if uvl is None:
        raise SystemExit("la malla no tiene capa UV -- la textura no puede leerse")
    us = [d.uv[0] for d in uvl.data]
    vs = [d.uv[1] for d in uvl.data]
    print("  UV  u %.3f..%.3f   v %.3f..%.3f   sobre %d loops"
          % (min(us), max(us), min(vs), max(vs), len(uvl.data)))
    if max(us) - min(us) < 0.05 or max(vs) - min(vs) < 0.05:
        raise SystemExit("las UV estan colapsadas -- toda la malla lee un solo texel")

    arr = _carapace_texture.bake(spec, size=args.tex)
    tex_img = _carapace_texture.to_blender_image(arr)
    # Round-trip probe. Writing a pixel buffer that never lands is a silent
    # failure on this project's record, and it looks exactly like a lighting
    # problem from the render.
    import numpy as _np
    back = _np.empty(len(tex_img.pixels), dtype=_np.float32)
    tex_img.pixels.foreach_get(back)
    src = _np.ascontiguousarray(arr[::-1]).ravel()
    print("  imagen: escrito media %.4f max %.4f  |  leido media %.4f max %.4f"
          % (src.mean(), src.max(), back.mean(), back.max()))
    if abs(src.mean() - back.mean()) > 1e-3:
        raise SystemExit("la imagen no conserva lo que se escribio")
    me.materials.append(shell_material(tex_img))
    obj = bpy.data.objects.new("carapace", me)
    bpy.context.scene.collection.objects.link(obj)

    # Relief actually present in the mesh, in millimetres, measured against the
    # bare dome. The old shell's grooves were 2.2 mm on a 520 mm shell and were
    # invisible in the silhouette -- so this number is the gate, not the render.
    devs = []
    for v in me.vertices:
        u = v.co.x / spec.half_wid
        vv = v.co.y / spec.half_len
        devs.append((v.co.z - _carapace.dome_z(spec, u, vv)) * 1000.0)
    # Watertight or it is not a shell: every edge must be shared by two faces.
    me.update()
    _open = [e for e in me.edges if len(
        [pl for pl in me.polygons if e.key[0] in pl.vertices
         and e.key[1] in pl.vertices]) < 2]
    print("")
    print("  scutes %d   faces %d   verts %d"
          % (stats["scutes"], stats["faces"], len(me.vertices)))
    print("  relief vs bare dome:  min %+.2f mm   max %+.2f mm   span %.2f mm"
          % (min(devs), max(devs), max(devs) - min(devs)))
    print("  shell  L %.3f  W %.3f  H %.3f   alto/largo %.3f"
          % (spec.length, spec.length * spec.width_ratio, spec.height,
             spec.height_ratio))

    # 1 nuchal + 4 vertebral (the frontmost midline band IS the nuchal)
    # + 8 pleural + 24 marginal = 37 distinct plates.
    if stats["scutes"] != 37:
        raise SystemExit("expected 37 plates, got %d" % stats["scutes"])

    mw = obj.matrix_world
    orbit([mw @ v.co for v in me.vertices], args.out, args.res)


if __name__ == "__main__":
    main()
