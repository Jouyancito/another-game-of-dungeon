"""_bake_vcol -- resolve procedural shading into vertex colour before export.

The bug this closes, measured 2026-08-22 across the mob set:

    snake, turtle, wasp, bird, king_slime   ->  COLOR_0: 0 primitives
    rat, slime                              ->  COLOR_0: present

The broken ones shade with ShaderNodeTexNoise / TexVoronoi / NewGeometry. Those
are FUNCTIONS evaluated by Blender's renderer, and glTF has no way to express a
node graph -- so `export_scene.gltf` silently drops them and writes
baseColorFactor 1,1,1. The build script's own showcase render still shows every
scale and stripe, because it renders WITH the graph. The game gets a white mob.

The fix is to turn the function into DATA: bake the diffuse colour down to a
FLOAT_COLOR attribute, then point Base Color at that attribute instead. What
ships is then what was rendered.

FLOAT_COLOR, never BYTE_COLOR: the byte layer applies an sRGB decode on read
that the write does not encode, crushing hand-picked tones by roughly 12x
(measured on golem_guardian). `rat.glb` still uses BYTE_COLOR and should be
migrated.

LIMIT, and it is a hard one: vertex colour resolves at the VERTEX. A pattern
finer than the mesh cannot survive -- snake has 152 vertices, so its scale
pattern needs a texture bake, not this. Call `enough_vertices()` first and
believe the answer.

Usage from a build script, immediately before export:

    import _bake_vcol
    _bake_vcol.bake(obj, samples=8)
"""
from __future__ import annotations

import bpy


def enough_vertices(obj, need=600):
    """Is the mesh dense enough for per-vertex colour to carry its pattern?

    A blunt gate on purpose. The point is to refuse silently-useless bakes: a
    152-vertex snake baked to vertex colour returns a muddy average of its scale
    pattern and looks 'fixed' in the stats while reading as a green tube.
    """
    n = len(obj.data.vertices)
    return n >= need, n


def bake(obj, samples=8, name="Col"):
    """Bake DIFFUSE colour into a FLOAT_COLOR attribute and rewire the material.

    Returns the measured (min, max, mean) luma so the caller can prove the bake
    produced a real range rather than a flat fill -- a bake that writes one
    constant is indistinguishable from the bug it was meant to fix.
    """
    me = obj.data
    if name in me.color_attributes:
        me.color_attributes.remove(me.color_attributes[name])
    me.color_attributes.new(name=name, type="FLOAT_COLOR", domain="CORNER")
    me.color_attributes.active_color_index = me.color_attributes.find(name)

    scene = bpy.context.scene
    prev_engine = scene.render.engine
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.device = "CPU"          # deterministic; GPU bakes vary per driver
    bk = scene.render.bake
    bk.target = "VERTEX_COLORS"
    bk.use_pass_direct = False           # albedo only -- lighting is Godot's job
    bk.use_pass_indirect = False
    bk.use_pass_color = True

    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.bake(type="DIFFUSE")
    scene.render.engine = prev_engine

    # Rewire: Base Color now reads the baked attribute, so the exported glTF
    # carries the same colour the bake produced.
    for slot in obj.material_slots:
        mat = slot.material
        if mat is None or not mat.use_nodes:
            continue
        nt = mat.node_tree
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue

        # An IMAGE TEXTURE survives glTF perfectly well -- it is procedural
        # node GRAPHS the exporter drops. Rewiring one of those to vertex
        # colour throws away real detail and replaces it with mesh-resolution
        # colour, which is the exact opposite of why the texture exists.
        # Measured on the turtle 2026-08-24: the carapace's baked growth-ring
        # map reached the GLB as a flat green, because this loop unlinked it.
        feeds = [l.from_node for l in bsdf.inputs["Base Color"].links]
        if any(nd.type == "TEX_IMAGE" for nd in feeds):
            print("[bake_vcol] %s ya usa una imagen -- se deja como esta"
                  % mat.name)
            continue

        attr = nt.nodes.new("ShaderNodeAttribute")
        attr.attribute_name = name
        for link in list(bsdf.inputs["Base Color"].links):
            nt.links.remove(link)
        nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])

    ca = me.color_attributes[name]
    lum = [0.2126 * d.color[0] + 0.7152 * d.color[1] + 0.0722 * d.color[2]
           for d in ca.data]
    return min(lum), max(lum), sum(lum) / max(len(lum), 1)


def flatten_to_base_colour(obj, fallback=(0.55, 0.55, 0.58)):
    """Give a too-small mesh a flat non-white baseColorFactor.

    Refusing to bake is right; leaving the mesh WHITE afterwards is not. glTF
    writes baseColorFactor 1,1,1 for a dropped node graph, which is precisely
    the unpainted white the colour gate exists to catch -- so a rejected mesh
    that keeps its default material fails the gate for a reason that has
    nothing to do with the pattern it could not hold.

    Flat colour is the honest floor: it is not the procedural detail, but it is
    a deliberate tone rather than an accident. Wasp and bird wings hit this on
    2026-08-23, the day the gate went in.
    """
    done = []
    for slot in obj.material_slots:
        mat = slot.material
        if mat is None or not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        inp = bsdf.inputs["Base Color"]
        # If a node still feeds Base Color, sample nothing -- just take the
        # socket's own default, which the exporter would have used anyway.
        cur = tuple(inp.default_value)[:3]
        if all(abs(c - 1.0) < 0.02 for c in cur):
            cur = fallback
        for link in list(inp.links):
            mat.node_tree.links.remove(link)
        inp.default_value = (*cur, 1.0)
        done.append(mat.name)
    return done


def bake_and_report(obj, label, samples=8, need=600):
    """Bake with the vertex-count gate and print evidence, or refuse loudly."""
    ok, n = enough_vertices(obj, need)
    if not ok:
        flat = flatten_to_base_colour(obj)
        print("  [%s] SIN BAKE: %d verts (<%d). El patrón no cabe en los vértices"
              " -- necesita bake a TEXTURA." % (label, n, need))
        if flat:
            print("  [%s] color plano aplicado a %s para que no salga BLANCO"
                  % (label, ", ".join(flat)))
        return None
    lo, hi, mean = bake(obj, samples=samples)
    spread = hi - lo
    print("  [%s] bake vcol: %d verts  luma min=%.3f max=%.3f media=%.3f  rango=%.3f%s"
          % (label, n, lo, hi, mean, spread,
             "" if spread > 0.02 else "   <-- PLANO, el bake no capturó nada"))
    return lo, hi, mean
