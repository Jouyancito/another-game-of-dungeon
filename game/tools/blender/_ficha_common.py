# _ficha_common.py — shared hero-still helpers for the mob build scripts.
# Style contract §4 (2026-07-19, PO Joan, "Pokedex rule"): every hero still
# (1024x1280) must show a true-relative-scale player silhouette next to the
# mob, and the hero camera must reframe to include BOTH. Animation GIF
# renders stay mob-only / unchanged — this module is ONLY imported around
# the hero-still render call, never around the anim-frame loop.
#
# Usage from a build_*.py script, right before its hero-still render(s):
#
#   import sys, os
#   sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
#   import _ficha_common as ficha
#
#   sil = ficha.add_scale_silhouette(location=(sil_x, 0.0, 0.0))
#   old_t, old_c = ficha.frame_hero_camera(cam, target, mob_x=0.0, silhouette_x=sil_x,
#                                           pullback=1.5)
#   <render hero still(s)>
#   ficha.restore_hero_camera(cam, target, old_t, old_c)
#   ficha.remove_scale_silhouette(sil)
#
# The silhouette MUST be removed before any GLB export or gameplay-anim
# render — it is a ficha-only prop, it must never ship in a mob's GLB.
import bpy
import math
from mathutils import Vector

SILHOUETTE_NAME = "player_scale_silhouette"
SILHOUETTE_MAT_NAME = "player_silhouette_mat"
SIL_SHOULDER_HALF_FRAC = 0.145  # must match add_scale_silhouette's shoulder_w fraction


def _silhouette_material():
    """Matte near-black, no specular — per contract §4: (0.02, 0.02, 0.025),
    roughness 0.9. Reused across mobs (single shared datablock) rather than
    re-created every run, so re-running a build script doesn't pile up
    orphan materials."""
    m = bpy.data.materials.get(SILHOUETTE_MAT_NAME)
    if m is None:
        m = bpy.data.materials.new(SILHOUETTE_MAT_NAME)
    m.use_nodes = True
    nt = m.node_tree
    n = next(nd for nd in nt.nodes if nd.type == 'BSDF_PRINCIPLED')
    n.inputs["Base Color"].default_value = (0.02, 0.02, 0.025, 1.0)
    n.inputs["Roughness"].default_value = 0.9
    n.inputs["Metallic"].default_value = 0.0
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.0
    return m


def _cyl(name, radius, depth, location, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location,
                                         vertices=vertices, end_fill_type='NGON')
    ob = bpy.context.object
    ob.name = name
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def _sphere(name, radius, location, segments=14, ring_count=8):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location,
                                          segments=segments, ring_count=ring_count)
    ob = bpy.context.object
    ob.name = name
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def add_scale_silhouette(location=(1.0, 0.0, 0.0), height=1.75):
    """Builds a clean, stylized 1.75 m humanoid silhouette (Pokedex-style
    size-chart figure — capsule-ish torso, sphere head, simple limb
    suggestion; NOT a detailed character) and returns the single joined
    object. Feet touch z=location[2] (normally the ground, z=0), the figure
    stands on the local +Z axis (Blender Z-up, matches every mob generator
    in this pipeline). `location` only needs (x, y, z_ground) — x is
    typically `mob_half_width + 0.4` so it clears the mob's silhouette."""
    ox, oy, oz = location
    H = float(height)

    leg_top = 0.50 * H
    hip_w = 0.115 * H
    shoulder_z = 0.82 * H
    shoulder_w = 0.145 * H
    neck_top = 0.87 * H
    head_r = 0.065 * H
    head_c = H - head_r
    torso_len = shoulder_z - leg_top

    parts = []
    leg_r = 0.052 * H
    for side in (-1, 1):
        leg_x = ox + side * hip_w * 0.55
        parts.append(_cyl(f"sil_leg_{side}", leg_r, leg_top, (leg_x, oy, oz + leg_top / 2.0)))
        parts.append(_sphere(f"sil_foot_{side}", leg_r, (leg_x, oy, oz + leg_r * 0.3)))

    # torso: two stacked cylinders (hip-width -> shoulder-width) approximate a taper
    parts.append(_cyl("sil_torso_lo", hip_w, torso_len * 0.5,
                       (ox, oy, oz + leg_top + torso_len * 0.25)))
    parts.append(_cyl("sil_torso_hi", shoulder_w, torso_len * 0.5,
                       (ox, oy, oz + leg_top + torso_len * 0.75)))

    # neck + head
    neck_len = neck_top - shoulder_z
    parts.append(_cyl("sil_neck", head_r * 0.55, neck_len,
                       (ox, oy, oz + shoulder_z + neck_len / 2.0)))
    parts.append(_sphere("sil_head", head_r, (ox, oy, oz + head_c)))

    # arms: straight drop from shoulder to mid-thigh, simple hand cap
    arm_r = 0.038 * H
    arm_top = shoulder_z
    arm_bot = 0.30 * H
    arm_len = arm_top - arm_bot
    for side in (-1, 1):
        arm_x = ox + side * (shoulder_w + arm_r * 1.05)
        parts.append(_cyl(f"sil_arm_{side}", arm_r, arm_len,
                           (arm_x, oy, oz + (arm_top + arm_bot) / 2.0)))
        parts.append(_sphere(f"sil_hand_{side}", arm_r, (arm_x, oy, oz + arm_bot)))

    mat = _silhouette_material()
    for p in parts:
        p.data.materials.append(mat)

    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    sil = bpy.context.view_layer.objects.active
    sil.name = SILHOUETTE_NAME
    return sil


def remove_scale_silhouette(obj):
    """Deletes the silhouette object + its mesh datablock. MANDATORY before
    any GLB export or gameplay-anim render — the silhouette is ficha-only."""
    if obj is None:
        return
    me = obj.data
    bpy.data.objects.remove(obj, do_unlink=True)
    if me is not None and me.users == 0:
        bpy.data.meshes.remove(me)


def camera_right_vector(cam, target):
    """The camera's actual on-screen 'right' direction in world space, given
    its CURRENT (pre-reframe) position/target. Many of this pipeline's ficha
    rigs are genuine 3/4 views — camera offset on BOTH X and Y, not just
    pulled back along -Y — so world-X does NOT reliably track screen-right
    (caught on the snake: a pure world-X silhouette offset landed almost
    directly in front of the camera's view of the mob instead of beside it,
    because that camera's real 'right' axis is mostly -Y). Call this BEFORE
    add_scale_silhouette / frame_hero_camera so the silhouette placement
    actually reads as 'beside the mob' on screen, whatever the camera angle."""
    forward = Vector(target.location) - Vector(cam.location)
    if forward.length < 1e-6:
        forward = Vector((0.0, 1.0, -0.3))
    forward.normalize()
    world_up = Vector((0.0, 0.0, 1.0))
    right = forward.cross(world_up)
    if right.length < 1e-6:
        right = Vector((1.0, 0.0, 0.0))
    right.normalize()
    return right


def silhouette_bbox(location=(1.0, 0.0, 0.0), height=1.75, depth=0.15):
    """World-space (x_min, x_max, y_min, y_max, z_min, z_max) the silhouette
    occupies, given the same location/height passed to add_scale_silhouette —
    so callers can fold it into a combined mob+silhouette bounding box
    without re-deriving the shoulder-width constant. `depth` is a generous
    front-back half-thickness guess (arms/torso), since the figure is built
    at a single Y."""
    ox, oy, oz = location
    half_w = SIL_SHOULDER_HALF_FRAC * height
    return (ox - half_w, ox + half_w, oy - depth, oy + depth, oz, oz + height)


def _true_fov(cam):
    """(horizontal_fov, vertical_fov) in radians, ACTUALLY matching the
    current scene render resolution — cam.data.angle_x/angle_y do NOT do
    this: they are just the raw sensor_width- and sensor_height-based angles
    and do not swap for sensor_fit='AUTO' on a portrait render (confirmed
    empirically on Blender 5.1.2: a 1024x1280 render with the default 36x24mm
    sensor still reports angle_x=39.6 deg / angle_y=27.0 deg — i.e. the WIDE
    36mm-based angle stays on angle_x even though AUTO fit is supposed to
    apply it to whichever pixel axis is larger, which here is Y). Using
    angle_x/angle_y directly under-computed the horizontal distance needed
    and over-computed the vertical one, silently cropping the wider side of
    the frame (caught on king_slime — the silhouette's arm/leg got clipped).
    This reproduces AUTO fit by hand from sensor_width/height + lens +
    render resolution, deriving the non-dominant axis via the aspect ratio."""
    scene = bpy.context.scene
    lens = cam.data.lens
    sw = cam.data.sensor_width
    sh = cam.data.sensor_height
    rx = max(1, scene.render.resolution_x)
    ry = max(1, scene.render.resolution_y)
    fit = cam.data.sensor_fit
    horizontal_dominant = (fit == 'HORIZONTAL') or (fit == 'AUTO' and rx >= ry)
    if horizontal_dominant:
        hfov = 2.0 * math.atan(sw / (2.0 * lens))
        vfov = 2.0 * math.atan(math.tan(hfov / 2.0) * ry / rx)
    else:
        vfov = 2.0 * math.atan(sw / (2.0 * lens))
        hfov = 2.0 * math.atan(math.tan(vfov / 2.0) * rx / ry)
    return hfov, vfov


def frame_hero_camera(cam, target, x_min, x_max, y_min, y_max, z_min, z_max, margin=1.18):
    """Reframes an existing TRACK_TO ficha camera rig so the world-space box
    [x_min,x_max] x [y_min,y_max] x [z_min,z_max] (mob + scale silhouette,
    combined) fits in frame with `margin` headroom.

    Many of this pipeline's ficha rigs are genuine 3/4 views (camera offset
    on BOTH X and Y, not just pulled back along -Y) — a framing calc that
    only looks at world-X/world-Z bounds silently assumes a front-on camera
    and puts the silhouette in the wrong place on screen for anything more
    oblique (caught on the snake: silhouette ended up overlapping the mob
    instead of beside it). Fix: project the bbox corners onto the camera's
    OWN right/up axes (derived from its current view direction + world Z-up,
    matching the TRACK_TO 'UP_Y' convention) to get the true on-screen
    half-width/half-height, then size the distance from angle_x/angle_y
    (resolution- and sensor-fit-aware) same as before. Preserves the shot's
    existing angle, only pulls back + re-centers along it.
    Returns (old_target_loc, old_cam_loc) — pass to restore_hero_camera after
    the hero still is rendered."""
    old_target_loc = Vector(target.location)
    old_cam_loc = Vector(cam.location)
    forward = old_target_loc - old_cam_loc
    if forward.length < 1e-6:
        forward = Vector((0.0, 1.0, -0.3))
    forward.normalize()
    world_up = Vector((0.0, 0.0, 1.0))
    right = forward.cross(world_up)
    if right.length < 1e-6:
        right = Vector((1.0, 0.0, 0.0))
    right.normalize()
    up = right.cross(forward)
    up.normalize()

    # Project every bbox corner onto the camera's OWN (right, up, forward)
    # basis and re-center there — NOT on the naive world-space bbox center.
    # For an oblique camera, the world-XYZ bbox center is not the same point
    # as the on-screen center, which left one side of the frame comfortably
    # inside margin and the other side clipped (caught on king_slime: a
    # world-center recentering cropped the silhouette's right arm/leg).
    corners = [Vector((x, y, z))
               for x in (x_min, x_max) for y in (y_min, y_max) for z in (z_min, z_max)]
    r_vals = [c.dot(right) for c in corners]
    u_vals = [c.dot(up) for c in corners]
    f_vals = [c.dot(forward) for c in corners]
    r_lo, r_hi = min(r_vals), max(r_vals)
    u_lo, u_hi = min(u_vals), max(u_vals)
    f_mid = (min(f_vals) + max(f_vals)) / 2.0
    half_w = max(1e-4, (r_hi - r_lo) / 2.0)
    half_h = max(1e-4, (u_hi - u_lo) / 2.0)

    hfov, vfov = _true_fov(cam)
    d_h = half_w / math.tan(hfov / 2.0)
    d_v = half_h / math.tan(vfov / 2.0)
    d = max(d_h, d_v) * margin

    center = right * ((r_lo + r_hi) / 2.0) + up * ((u_lo + u_hi) / 2.0) + forward * f_mid
    target.location = center
    cam.location = center - forward * d
    return old_target_loc, old_cam_loc


def restore_hero_camera(cam, target, old_target_loc, old_cam_loc):
    target.location = old_target_loc
    cam.location = old_cam_loc
