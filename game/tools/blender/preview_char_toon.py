"""preview_char_toon — render a character with the GAME's toon look, not a studio look.

The point is fidelity to Godot, not a flattering image. `toon_basic.gdshader`
does the shading with a hard 3-band ramp, a 0.55 shadow floor and a gold rim,
so a Blender preview lit like a photo studio would lie about the result: the
soft gradient it shows is exactly what the game shader will quantise away.

So this rebuilds the shader's maths in nodes -- same band count, same shadow
floor, same rim -- and feeds it a FLAT albedo. Nothing is painted into the
colour: no baked shadow, no baked highlight. Anything painted there would add
to the shader's own shading and read as dirt.

    blender.exe -b <char.blend> --python preview_char_toon.py -- \
        --obj char_warrior_male_mh --skin "#96613F" --out <dir>
"""

import argparse
import math
import os
import sys

import bpy

# Read straight out of game/assets/art/materials/toon_player_warrior.tres and
# shaders/toon_basic.gdshader. If those change, change these -- a preview that
# silently drifts from the game material is worse than no preview.
RAMP_STEPS = 3
SHADOW_INTENSITY = 0.55
RIM_COLOR = (0.83, 0.63, 0.25)
RIM_POWER = 3.5
RIM_INTENSITY = 1.2

# Cool violet shadow. Mirrors the shadow_tint uniform added to
# toon_basic.gdshader: a cel shade that only darkens leaves the shadow at the
# same hue as the light, which reads muddy on warm skin. White here reproduces
# the previous behaviour exactly.
SHADOW_TINT = (0.58, 0.60, 0.86)


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_linear(h):
    h = h.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4)) + (1.0,)


def toon_material(name, albedo_hex):
    """Rebuild toon_basic.gdshader as Blender nodes.

    Shader-to-RGB is the piece that makes this possible: it turns the lighting
    result into a colour that a ColorRamp can quantise. It only works in EEVEE
    -- in Cycles the node has no defined lighting to read.
    """
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()

    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (900, 0)

    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.location = (-600, 0)
    diffuse.inputs["Color"].default_value = (1, 1, 1, 1)

    s2rgb = nt.nodes.new("ShaderNodeShaderToRGB")
    s2rgb.location = (-400, 0)
    nt.links.new(diffuse.outputs["BSDF"], s2rgb.inputs["Shader"])

    # CONSTANT interpolation is what makes it cel. Linear here gives a smooth
    # gradient with extra steps -- the look this style exists to avoid.
    # The ramp now carries COLOUR, not just value: each band is the shadow
    # tint blended toward white by how lit that band is. Same maths as the
    # shader's `mix(shadow_tint, vec3(1.0), shade)`, precomputed per band
    # because a ColorRamp stop is a colour anyway.
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.location = (-200, 0)
    ramp.color_ramp.interpolation = "CONSTANT"
    floor = 1.0 - SHADOW_INTENSITY
    els = ramp.color_ramp.elements
    while len(els) > 1:
        els.remove(els[-1])

    def band_colour(shade):
        t = tuple(SHADOW_TINT[c] + (1.0 - SHADOW_TINT[c]) * shade for c in range(3))
        return (shade * t[0], shade * t[1], shade * t[2], 1.0)

    els[0].position = 0.0
    els[0].color = band_colour(floor)
    for i in range(1, RAMP_STEPS):
        e = els.new(i / float(RAMP_STEPS))
        v = floor + (1.0 - floor) * (i / float(RAMP_STEPS - 1))
        e.color = band_colour(v)
    nt.links.new(s2rgb.outputs["Color"], ramp.inputs["Fac"])

    tint = nt.nodes.new("ShaderNodeMixRGB")
    tint.location = (60, 0)
    tint.blend_type = "MULTIPLY"
    tint.inputs["Fac"].default_value = 1.0
    tint.inputs["Color2"].default_value = hex_to_linear(albedo_hex)
    nt.links.new(ramp.outputs["Color"], tint.inputs["Color1"])

    # Rim: Fresnel^rim_power * rim_intensity, then GATED BY THE LIT SIDE.
    #
    # That gate is line 58 of toon_basic.gdshader:
    #     rim *= smoothstep(0.0, 0.3, lambert);
    # It is what makes a backlight draw a bright edge instead of glowing the
    # whole outline evenly. The first version of this replica left it out, so
    # the preview could not show contraluz at all -- and the reference's core
    # move is exactly contraluz. An ungated Fresnel is a halo, not a rim.
    fres = nt.nodes.new("ShaderNodeFresnel")
    fres.location = (-200, -280)
    fres.inputs["IOR"].default_value = 1.45

    power = nt.nodes.new("ShaderNodeMath")
    power.location = (-20, -280)
    power.operation = "POWER"
    power.inputs[1].default_value = RIM_POWER
    nt.links.new(fres.outputs["Fac"], power.inputs[0])

    scale = nt.nodes.new("ShaderNodeMath")
    scale.location = (160, -280)
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = RIM_INTENSITY
    nt.links.new(power.outputs["Value"], scale.inputs[0])

    # The gate: multiply the rim by the banded lighting, which is high exactly
    # where a light is hitting. Approximates the shader's per-light lambert
    # test with the information Shader-to-RGB actually exposes.
    gate = nt.nodes.new("ShaderNodeMath")
    gate.location = (160, -400)
    gate.operation = "MULTIPLY"
    nt.links.new(scale.outputs["Value"], gate.inputs[0])
    nt.links.new(ramp.outputs["Color"], gate.inputs[1])

    rim = nt.nodes.new("ShaderNodeMixRGB")
    rim.location = (340, -160)
    rim.blend_type = "MULTIPLY"
    rim.inputs["Fac"].default_value = 1.0
    rim.inputs["Color2"].default_value = RIM_COLOR + (1.0,)
    nt.links.new(gate.outputs["Value"], rim.inputs["Color1"])

    add = nt.nodes.new("ShaderNodeMixRGB")
    add.location = (540, 0)
    add.blend_type = "ADD"
    add.inputs["Fac"].default_value = 1.0
    nt.links.new(tint.outputs["Color"], add.inputs["Color1"])
    nt.links.new(rim.outputs["Color"], add.inputs["Color2"])

    emit = nt.nodes.new("ShaderNodeEmission")
    emit.location = (720, 0)
    nt.links.new(add.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return mat


def eval_bounds(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world
    co = [mw @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return (min(c.x for c in co), max(c.x for c in co),
            min(c.z for c in co), max(c.z for c in co))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--skin", default="#96613F")
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no existe el objeto %r. hay: %s"
                         % (args.obj, [o.name for o in bpy.data.objects]))

    obj.data.materials.clear()
    obj.data.materials.append(toon_material("toon_skin_preview", args.skin))

    # Drop the clay-render staging: floor, post and lamps belong to the other
    # tool's look. Keep one key light -- Shader-to-RGB needs something to read.
    for ob in list(bpy.data.objects):
        if ob is not obj and ob.type in {"MESH", "LIGHT", "CAMERA"}:
            bpy.data.objects.remove(ob, do_unlink=True)

    bpy.ops.object.light_add(type="AREA", location=(2.2, -3.0, 3.0))
    key = bpy.context.object
    key.data.energy = 600
    key.data.size = 3.0
    key.rotation_euler = (math.radians(48), 0, math.radians(34))

    world = bpy.data.worlds.new("w")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.07, 0.08, 0.10, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.35

    x0, x1, z0, z1 = eval_bounds(obj)
    mid = (z0 + z1) / 2.0
    res_x, res_y = 700, 940
    need = max((z1 - z0), (x1 - x0) / (res_x / float(res_y))) * 1.14

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = res_x, res_y
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"   # match Godot, not AgX

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam

    face_z = z0 + (z1 - z0) * 0.925
    shots = [
        ("front",   True,  need, (0, -4.0, mid), (90, 0, 0)),
        ("profile", True,  need, (4.0, 0, mid), (90, 0, 90)),
        ("tresq",   False, 55.0, (2.05, -2.70, mid + 0.55), (80, 0, 37)),
        ("face",    False, 85.0, (0.42, -1.05, face_z + 0.02), (86, 0, 21)),
    ]

    os.makedirs(args.out, exist_ok=True)
    for label, ortho, val, loc, rot in shots:
        cam_data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam_data.ortho_scale = val
        else:
            cam_data.lens = val
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)
        sc.render.filepath = os.path.join(args.out, "toon_%s.png" % label)
        bpy.ops.render.render(write_still=True)
        print("  render -> %s" % sc.render.filepath)

    print("\n  piel %s  ·  bandas %d  ·  sombra %.2f  ·  rim %s"
          % (args.skin, RAMP_STEPS, SHADOW_INTENSITY, RIM_COLOR))


if __name__ == "__main__":
    main()
