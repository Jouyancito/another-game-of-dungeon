"""titlescreen_showcase.py -- multi-angle showcase of the exported logo and room, with the 1.8 m
player-reference post. Helper only (renders, never builds). Reads titlescreen_logo_baked.blend.

  blender -b titlescreen_logo_baked.blend --factory-startup --python-exit-code 1 \
      --python titlescreen_showcase.py
"""
import os
import sys

import bpy

sys.path.insert(0, "/home/jouyan/proyectos/motor-blender")
from recetas import views  # noqa: E402
from recetas.scale_ref import build_mannequin  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
sh = scene.display.shading
sh.light = "STUDIO"
sh.color_type = "VERTEX"   # shows the baked FLOAT_COLOR the glb will carry
scene.render.film_transparent = False
if scene.world is None:
    scene.world = bpy.data.worlds.new("showcase_w")
scene.world.color = (0.08, 0.08, 0.09)

LOGO = [o for o in bpy.data.objects if o.type == "MESH" and
        (o.name.startswith(("glyph", "gate", "vine")))]
ROOM = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("ts_")]

# logo: mannequin beside the wordmark (it spans x 0..17.5 m in the Blender file)
m1 = build_mannequin(location=(-2.0, -1.5, 0.0), suffix="_logo")
for o in ROOM:
    o.hide_render = True
print("SHOWCASE logo", views.orbit_capture(OUT, "showcase_logo", LOGO + m1, res=900))
for o in ROOM:
    o.hide_render = False
for o in LOGO + m1:
    o.hide_render = True
# room: mannequin in the hall (x 54.5..65.5, y 0..8)
m2 = build_mannequin(location=(57.0, 2.0, 0.0), suffix="_room")
print("SHOWCASE room", views.orbit_capture(OUT, "showcase_room", ROOM + m2, res=900))
