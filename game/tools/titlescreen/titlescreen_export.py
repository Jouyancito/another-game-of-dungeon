"""titlescreen_export.py -- export the title screen's logo and room blockout to .glb.

Run through the motor (start_asset.py manifest first):
  blender -b --python titlescreen_export.py -- inspect
  blender -b --python titlescreen_export.py -- export

Logo: procedural node materials are baked to FLOAT_COLOR (recetas/bake_procedural.py)
before export, because glTF drops node graphs. Room: geometry only.
Nothing new is modeled here.
"""
import os
import sys

import bpy

MOTOR = "/home/jouyan/proyectos/motor-blender"
sys.path.insert(0, MOTOR)
from recetas.bake_procedural import bake_procedural_to_float_color  # noqa: E402
from recetas.glb_export import export_glb  # noqa: E402
from recetas.motor_stamp import stamp_object  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
LOGO_DIR = os.path.join(HERE, "..", "logo")
OUT_DIR = os.path.join(HERE, "..", "..", "assets", "art", "titlescreen")
MODE = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "inspect"

# Filled after `inspect`: object names to export per source file.
LOGO_OBJECTS = (
    ["gate_arch", "gate_jamb_L", "gate_jamb_R", "gate_leaf_L", "gate_leaf_R",
     "glyph_bigA", "glyph_gee", "glyph_me", "glyph_nother", "glyph_of"]
    + ["glyph_L%d" % i for i in (0, 2, 3, 4, 5, 6)]
    + ["vine_bloommass_bloom", "vine_bloommass_core", "vine_bloommass_leaf", "vine_bloommass_stem"]
    + ["vine_glyph_L%d_%s" % (i, k) for i in (2, 4, 6) for k in ("leaf", "stem")]
)
ROOM_OBJECTS = ["ts_floor", "ts_walls", "ts_walls_r", "ts_ceiling", "ts_corridor", "ts_debris",
                "ts_props", "ts_firering"]


def list_objects(tag):
    for o in bpy.data.objects:
        mats = [m.name for m in o.data.materials] if o.type == "MESH" else []
        nv = len(o.data.vertices) if o.type == "MESH" else 0
        print("OBJ", tag, o.name, o.type, "verts=%d" % nv, tuple(round(x, 2) for x in o.dimensions), mats,
              "parent=" + (o.parent.name if o.parent else "-"), "hidden=%s" % o.hide_render)


def main():
    if MODE == "inspect":
        bpy.ops.wm.open_mainfile(filepath=os.path.join(LOGO_DIR, "titlescreen.blend"))
        from mathutils import Vector
        for o in bpy.data.objects:
            if o.type == "MESH":
                pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
                lo = [round(min(p[i] for p in pts), 2) for i in range(3)]
                hi = [round(max(p[i] for p in pts), 2) for i in range(3)]
                print("BB", o.name, lo, hi, "rot", tuple(round(x, 2) for x in o.rotation_euler),
                      "mods", [m.type for m in o.modifiers])
            elif o.type == "LIGHT":
                print("LIGHT", o.name, o.data.type, round(o.data.energy, 1), tuple(round(x, 2) for x in o.location))
            elif o.type == "CAMERA":
                print("CAM", o.name, tuple(round(x, 2) for x in o.location), tuple(round(x, 2) for x in o.rotation_euler))
        return
    if MODE == "mats":
        bpy.ops.wm.open_mainfile(filepath=os.path.join(LOGO_DIR, "titlescreen.blend"))
        for m in bpy.data.materials:
            if not m.use_nodes:
                continue
            kinds = sorted({n.type + (":" + n.image.filepath if n.type == "TEX_IMAGE" and n.image else "") for n in m.node_tree.nodes})
            bsdf = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            print("MAT", m.name, "users=%d" % m.users, bsdf.inputs["Base Color"].default_value[:3] if bsdf else None, kinds)
        nt = bpy.data.materials["gate_stone"].node_tree
        for l in nt.links:
            print("LINK", l.from_node.name, l.from_socket.name, "->", l.to_node.name, l.to_socket.name)
        for n in nt.nodes:
            if n.type in ("TEX_NOISE", "TEX_VORONOI", "RGB", "MAP_RANGE", "MIX"):
                print("NODE", n.name, [(i.name, getattr(i, "default_value", None) if i.type in ("VALUE",) else None) for i in n.inputs if i.type == "VALUE"][:6])
        for n in ("glyph_bigA", "glyph_gee", "gate_arch"):
            o = bpy.data.objects[n]
            print("OBJMAT", n, [s.material.name for s in o.material_slots], "uv", [u.name for u in o.data.uv_layers],
                  "verts", len(o.data.vertices))
        return
    os.makedirs(OUT_DIR, exist_ok=True)
    # --- logo (titlescreen.blend holds the room, the wordmark and the U-gate together)
    bpy.ops.wm.open_mainfile(filepath=os.path.join(LOGO_DIR, "titlescreen.blend"))
    logo = [bpy.data.objects[n] for n in LOGO_OBJECTS]
    for o in logo:
        try:
            part = "logo" if len(o.data.vertices) >= 600 else "logo_sparse"
            r = bake_procedural_to_float_color(o, part=part, samples=8)
        except SystemExit as e:  # recipe refuses flat bakes: record it, do not hide it
            r = "REJECTED_FLAT: %s" % e
        print("BAKE", o.name, len(o.data.vertices), r)
    export_glb(os.path.join(OUT_DIR, "titlescreen_logo.glb"), logo)
    # --- room (geometry only: materials are rebuilt in Godot, nothing new is baked)
    room = [bpy.data.objects[n] for n in ROOM_OBJECTS]
    for o in room:
        stamp_object(o, "room", "export_only")
    export_glb(os.path.join(OUT_DIR, "titlescreen_room.glb"), room)
    keep = set(LOGO_OBJECTS) | set(ROOM_OBJECTS)
    for o in list(bpy.data.objects):  # the saved work file holds only what this asset exports
        if o.type == "MESH" and o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "titlescreen_logo_baked.blend"))


main()
