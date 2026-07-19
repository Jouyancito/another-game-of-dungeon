# build_golem.py — Floating-Stone Golem: a glowing core mass with separate
# rock chunks that FLOAT/orbit around it (torso cluster, shoulders, fists,
# crown). PO canon 2026-07-17 (_estado_vivo.md decision #4): "piedras
# FLOTANTES... los huecos entre cubos... pasan de bug a DISENO (gaps =
# magia)." No rigid full-body anatomy — the stones' motion IS the
# articulation. Built FROM game/docs/art/_references/golem/ (07 refs: tree,
# spirals, vines, knuckle-drag stacked rock, glow held between stone hands)
# and the motion spec's weight principles (lag, asymmetric ease, impact
# holds, gravity fall on death), scoped down to the standard 5-clip mob set
# per _mob_style_contract.md:
#   idle-loop   stones slowly orbit/breathe around the core, gentle bob
#   move-loop   heavy plod: core advances-in-place, stones lag then catch up
#   attack      fist-stones pull back then SLAM forward together
#   hit         stones scatter outward briefly then snap back
#   death       core glow dies, ALL stones fall to the ground and rest
# Mirrors game/tools/blender/slime/build_slime.py + king_slime's secondary-
# object-vs-body pattern (crown), generalized to many independently
# lagging floating stones. Run: blender -b --python build_golem.py
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector
from mathutils import noise as mnoise

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
FPS = 24
scene.render.fps = FPS

SEED = 20260719
SCALE = 1.15  # global size tune knob — torso ~2m tall * this, total presence ~3m


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def ease_in_cubic(t):
    t = max(0.0, min(1.0, t))
    return t * t * t


def ease_out_cubic(t):
    t = max(0.0, min(1.0, t))
    return 1.0 - (1.0 - t) ** 3


def ease_in_expo(t):
    t = max(0.0, min(1.0, t))
    return 0.0 if t <= 0.0 else 2.0 ** (10.0 * (t - 1.0))


def ease_out_expo(t):
    t = max(0.0, min(1.0, t))
    return 1.0 if t >= 1.0 else 1.0 - 2.0 ** (-10.0 * t)


# =============================================================================
# ROCK CHUNK GENERATOR — icosphere (dense, per style contract §1.1) + Perlin
# displacement for jagged/crevice silhouette (not a smooth blob) + painterly
# vertex-color stone (dark/light noise-mix + top-facing moss/lichen accent).
# =============================================================================
def make_rock(name, radius=0.5, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
              taper=0.0, noise_scale=2.6, noise_strength=0.34,
              moss=True, moss_bias=0.22, flat=True,
              dark=(0.145, 0.135, 0.140), light=(0.56, 0.53, 0.49),
              moss_col=(0.38, 0.46, 0.20)):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))
    for v in bm.verts:
        co = v.co.copy()
        n1 = mnoise.noise(co * noise_scale + seed_v)
        n2 = mnoise.noise(co * noise_scale * 2.4 + seed_v + Vector((5.0, 5.0, 5.0)))
        ridged = 1.0 - abs(n1 * 2.0 - 1.0)          # ridge-ish: crevices between bumps
        d = (n2 * 2.0 - 1.0) * 0.55 + (ridged - 0.5) * 0.9
        v.co += v.normal * (d * noise_strength * radius)
        v.co.x *= elongate[0]
        v.co.y *= elongate[1]
        v.co.z *= elongate[2]
    if taper:
        zs = [v.co.z for v in bm.verts]
        zmin, zmax = min(zs), max(zs)
        h = max(1e-5, zmax - zmin)
        for v in bm.verts:
            t = (v.co.z - zmin) / h
            s = 1.0 + taper * (1.0 - t)
            v.co.x *= s
            v.co.y *= s
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    col_layer = bm.loops.layers.color.new("Col")
    bm.verts.ensure_lookup_table()
    vcol = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)  # ~[0,1] painterly variation
        t_ao = max(0.0, min(1.0, 0.20 + 0.55 * (nrm.z * 0.5 + 0.5) + 0.35 * paint))
        base = [dark[i] + (light[i] - dark[i]) * t_ao for i in range(3)]
        if moss and nrm.z > moss_bias:
            mt = min(1.0, (nrm.z - moss_bias) / (1.0 - moss_bias))
            mt *= 0.55 + 0.45 * paint  # patchy, not a uniform cap
            base = [base[i] + (moss_col[i] - base[i]) * mt * 0.85 for i in range(3)]
        vcol[v.index] = base
    for f in bm.faces:
        for loop in f.loops:
            c = vcol[loop.vert.index]
            loop[col_layer] = (c[0], c[1], c[2], 1.0)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = not flat
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


def mat_stone():
    m = bpy.data.materials.new("golem_stone")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.88
    n.inputs["Specular IOR Level"].default_value = 0.25
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    return m


def mat_glow(color=(0.16, 0.60, 0.70), strength=1.6):
    m = bpy.data.materials.new("golem_glow")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (*color, 1.0)
    n.inputs["Emission Color"].default_value = (*color, 1.0)
    n.inputs["Emission Strength"].default_value = strength
    n.inputs["Roughness"].default_value = 0.25
    return m, n


STONE_MAT = mat_stone()
GLOW_MAT, GLOW_BSDF = mat_glow()
GLOW_BASE_STRENGTH = GLOW_BSDF.inputs["Emission Strength"].default_value

# =============================================================================
# BUILD — core cluster (torso mass, bottom-weighted, asymmetric break) +
# glow core (visible in the gaps BETWEEN chunks — canon: gaps = magic, not a
# bug) + 7 orbiting stones (2 shoulder / 2 fist / 3 crown).
# =============================================================================
CORE_CENTER = Vector((0.0, 0.02, 1.05)) * SCALE

CORE_CHUNK_DEFS = [
    dict(name="core_base", base=Vector((0.0, 0.06, 0.62)), radius=0.62, subdiv=3,
         elongate=(0.95, 0.9, 1.35), taper=0.26, seed=1),
    dict(name="core_midL", base=Vector((-0.24, -0.06, 1.18)), radius=0.36, subdiv=3,
         elongate=(1.0, 1.0, 1.0), taper=0.0, seed=2),
    dict(name="core_midR", base=Vector((0.26, -0.02, 1.24)), radius=0.34, subdiv=3,
         elongate=(1.0, 1.0, 1.0), taper=0.0, seed=3),
    dict(name="core_head", base=Vector((0.03, 0.11, 1.96)), radius=0.24, subdiv=3,
         elongate=(1.0, 1.0, 1.0), taper=0.0, seed=4),
]

STONE_DEFS = [
    dict(name="shoulder_L", base=Vector((-0.78, 0.10, 1.52)), radius=0.38, subdiv=2,
         group="shoulder", phase=0.0, orbit_r=0.06, orbit_h=0.04, lag=0.03, seed=5),
    dict(name="shoulder_R", base=Vector((0.80, 0.08, 1.56)), radius=0.36, subdiv=2,
         group="shoulder", phase=math.pi, orbit_r=0.06, orbit_h=0.04, lag=0.03, seed=6),
    dict(name="fist_L", base=Vector((-1.15, -0.24, 0.42)), radius=0.46, subdiv=2,
         group="fist", phase=0.6, orbit_r=0.05, orbit_h=0.05, lag=0.05, seed=7),
    dict(name="fist_R", base=Vector((1.18, -0.22, 0.44)), radius=0.44, subdiv=2,
         group="fist", phase=0.6 + math.pi, orbit_r=0.05, orbit_h=0.05, lag=0.05, seed=8),
    dict(name="crown_A", base=Vector((0.0, 0.16, 2.42)), radius=0.13, subdiv=2,
         group="crown", phase=0.0, orbit_r=0.07, orbit_h=0.03, lag=0.08, seed=9),
    dict(name="crown_B", base=Vector((-0.24, 0.04, 2.34)), radius=0.11, subdiv=2,
         group="crown", phase=2.094, orbit_r=0.07, orbit_h=0.03, lag=0.08, seed=10),
    dict(name="crown_C", base=Vector((0.23, 0.06, 1.95)), radius=0.16, subdiv=2,
         group="crown", phase=4.188, orbit_r=0.07, orbit_h=0.03, lag=0.08, seed=11),
]

rng = random.Random(SEED)

CORE_CHUNKS = []
for d in CORE_CHUNK_DEFS:
    base = d["base"] * SCALE
    radius = d["radius"] * SCALE
    obj = make_rock(d["name"], radius=radius, subdiv=d["subdiv"], seed=d["seed"],
                     elongate=d["elongate"], taper=d["taper"])
    obj.location = base
    obj.data.materials.append(STONE_MAT)
    CORE_CHUNKS.append(dict(name=d["name"], obj=obj, base=base, radius=radius, is_core=True))

ORBIT_STONES = []
for d in STONE_DEFS:
    base = d["base"] * SCALE
    radius = d["radius"] * SCALE
    obj = make_rock(d["name"], radius=radius, subdiv=d["subdiv"], seed=d["seed"])
    obj.location = base
    obj.data.materials.append(STONE_MAT)
    fdir = Vector((base.x, base.y, 0.0))
    fdir = fdir.normalized() if fdir.length > 1e-4 else Vector((1.0, 0.0, 0.0))
    ORBIT_STONES.append(dict(name=d["name"], obj=obj, base=base, radius=radius, is_core=False,
                              group=d["group"], phase=d["phase"],
                              orbit_r=d["orbit_r"] * SCALE, orbit_h=d["orbit_h"] * SCALE,
                              lag=d["lag"], fall_dir=fdir,
                              fall_dist=rng.uniform(0.55, 1.35) * SCALE,
                              death_stagger=rng.uniform(0.0, 0.22),
                              fall_rot_axis=Vector((rng.uniform(-1, 1), rng.uniform(-1, 1),
                                                     rng.uniform(-1, 1))).normalized(),
                              fall_rot_amount=rng.uniform(1.2, 3.4)))

# core chunks also fall on death — same physics vocabulary, just closer to
# the ground already (base_core barely moves, the head chunk falls the most)
for c in CORE_CHUNKS:
    fdir = Vector((c["base"].x - CORE_CENTER.x, c["base"].y - CORE_CENTER.y, 0.0))
    fdir = fdir.normalized() if fdir.length > 1e-4 else Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0.0)).normalized()
    c["fall_dir"] = fdir
    c["fall_dist"] = rng.uniform(0.15, 0.55) * SCALE
    c["death_stagger"] = rng.uniform(0.0, 0.12)
    c["fall_rot_axis"] = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))).normalized()
    c["fall_rot_amount"] = rng.uniform(0.3, 1.1)

ALL_ROCKS = CORE_CHUNKS + ORBIT_STONES

glow_obj = make_rock("golem_core_glow", radius=0.30 * SCALE, subdiv=2, seed=0,
                      noise_strength=0.0, moss=False, flat=False)
glow_obj.location = CORE_CENTER
glow_obj.data.materials.append(GLOW_MAT)
GLOW = dict(obj=glow_obj, base=CORE_CENTER.copy())

# =============================================================================
# ANIMATION — per-clip samplers. Weight principles from
# _references/golem/motion/_motion_spec.md, scoped to the 5-clip mob set:
# asymmetric ease (slow build / fast release), impact holds, lag/inertia on
# the floating stones, gravity fall + low-bounce settle on death.
# =============================================================================
def core_idle(t):
    z = 0.045 * math.sin(2 * math.pi * t) * SCALE
    x = 0.02 * math.sin(2 * math.pi * t * 0.5 + 0.3) * SCALE
    return Vector((x, 0.0, z)), 1.0, 1.0


def core_move(t):
    ph = (t * 2.0) % 1.0
    if ph < 0.22:
        z = -0.16 * ease_in_expo(ph / 0.22)
    else:
        u = (ph - 0.22) / 0.78
        z = -0.16 * (1.0 - ease_out_cubic(u))
    x = 0.06 * math.sin(2 * math.pi * t) * SCALE
    return Vector((x, 0.0, z * SCALE)), 1.0, 1.0


def core_attack(t):
    if t < 0.30:
        u = t / 0.30
        y = 0.05 * ease_in_cubic(u)
        z = 0.04 * ease_in_cubic(u)
    elif t < 0.46:
        u = (t - 0.30) / 0.16
        y = lerp(0.05, -0.12, ease_in_expo(u))
        z = lerp(0.04, -0.07, ease_in_expo(u))
    elif t < 0.55:
        y, z = -0.12, -0.07
    else:
        u = (t - 0.55) / 0.45
        y = lerp(-0.12, 0.0, ease_out_cubic(u))
        z = lerp(-0.07, 0.0, ease_out_cubic(u))
    return Vector((0.0, y * SCALE, z * SCALE)), 1.0, 1.0


def core_hit(t):
    y = 0.15 * math.sin(math.pi * min(1.0, t * 1.6))
    z = -0.09 * math.sin(math.pi * t)
    return Vector((0.0, y * SCALE, z * SCALE)), 1.0, 1.0


CORE_FN = {"idle-loop": core_idle, "move-loop": core_move, "attack": core_attack, "hit": core_hit}


def orbit_wobble(info, t, speed=0.5, amp=1.0):
    ang = 2 * math.pi * t * speed + info["phase"]
    r, h = info["orbit_r"] * amp, info["orbit_h"] * amp
    return Vector((r * math.sin(ang), r * 0.5 * math.cos(ang), h * math.sin(2 * ang)))


def fist_attack_offset(t, side):
    # side: -1 for the left fist, +1 for the right. Windup RISES the fists
    # well above the crown (big, unambiguous silhouette change regardless
    # of camera-forward foreshortening) and pulls back; the wrench sweeps
    # them inward-and-down into a converged slam in front, low; recovery
    # settles with a small overshoot. Per _motion_spec.md's anticipation ->
    # explosive-release -> overshoot/settle shape.
    if t < 0.28:
        u = ease_in_cubic(t / 0.28)
        x = lerp(0.0, side * 0.30, u)
        y = lerp(0.0, 0.20, u)
        z = lerp(0.0, 0.60, u)
    elif t < 0.42:
        u = ease_in_expo((t - 0.28) / 0.14)
        x = lerp(side * 0.30, -side * 0.22, u)
        y = lerp(0.20, -0.60, u)
        z = lerp(0.60, -0.16, u)
    elif t < 0.50:
        x, y, z = -side * 0.22, -0.60, -0.16
    else:
        u = ease_out_cubic((t - 0.50) / 0.50)
        ov = 0.06 * math.sin(2 * math.pi * ((t - 0.50) / 0.50) * 2.2) * (1.0 - u)
        x = lerp(-side * 0.22, 0.0, u)
        y = lerp(-0.60, 0.0, u) + ov
        z = lerp(-0.16, 0.0, u)
    return Vector((x * SCALE, y * SCALE, z * SCALE))


def jostle_offset(t):
    bump = math.exp(-((t - 0.46) ** 2) / (2 * 0.03 ** 2))
    wob = math.sin(2 * math.pi * (t - 0.46) * 14.0)
    val = 0.10 * bump * wob * SCALE
    return Vector((val * 0.4, 0.0, val))


def stone_offset(info, clip, t, core_val):
    if clip == "idle-loop":
        return orbit_wobble(info, t, speed=0.5) + core_val * 0.4
    if clip == "move-loop":
        lag_t = max(0.0, t - info["lag"])
        delayed, _, _ = core_move(lag_t)
        return orbit_wobble(info, t, speed=1.0, amp=0.6) + delayed * 0.7
    if clip == "attack":
        if info["group"] == "fist":
            side = -1.0 if info["base"].x < 0 else 1.0
            return fist_attack_offset(t, side)
        return jostle_offset(t)
    if clip == "hit":
        cdir = info["base"] - CORE_CENTER
        cdir = cdir.normalized() if cdir.length > 1e-4 else Vector((1.0, 0.0, 0.0))
        env = math.sin(math.pi * min(1.0, t * 1.6))
        return cdir * (0.36 * SCALE * env)
    return Vector((0.0, 0.0, 0.0))


def death_fall(info, t):
    stagger = info["death_stagger"]
    local_t = max(0.0, min(1.0, (t - stagger) / max(1e-4, 1.0 - stagger)))
    height = info["base"].z
    ground = info["radius"] * 0.75
    target_xy = Vector((info["base"].x, info["base"].y)) + Vector((info["fall_dir"].x, info["fall_dir"].y)) * info["fall_dist"]
    if local_t < 0.55:
        u = local_t / 0.55
        z = lerp(height, ground, ease_in_expo(u))
        xy = Vector((info["base"].x, info["base"].y)).lerp(target_xy, ease_in_expo(u) * 0.9)
        rot_t = ease_in_expo(u)
    elif local_t < 0.68:
        u = (local_t - 0.55) / 0.13
        bounce_amt = min(0.16 * SCALE, max(0.02, (height - ground)) * 0.28)
        z = ground + bounce_amt * math.sin(math.pi * u)
        xy = target_xy
        rot_t = 1.0
    else:
        u = (local_t - 0.68) / 0.32
        decay = 1.0 - u
        wob = 0.025 * SCALE * decay * math.sin(2 * math.pi * u * 3.0)
        z = ground + wob
        xy = target_xy
        rot_t = 1.0
    pos = Vector((xy.x, xy.y, z))
    rot = info["fall_rot_axis"] * (info["fall_rot_amount"] * rot_t) if local_t > 0.0 else Vector((0, 0, 0))
    return pos, rot


ANIMS = {
    "idle-loop": 96,
    "move-loop": 48,
    "attack": 36,
    "hit": 16,
    "death": 72,
}

clip_actions = {}
for clip_name, frames in ANIMS.items():
    obj_actions = {}
    for info in ALL_ROCKS:
        obj = info["obj"]
        ad = obj.animation_data_create()
        act = bpy.data.actions.new(f"{clip_name}_{info['name']}")
        ad.action = act
        obj_actions[info["name"]] = (ad, act)

    gad = GLOW["obj"].animation_data_create()
    gact = bpy.data.actions.new(f"{clip_name}_glow_obj")
    gad.action = gact

    gm_ad = GLOW_MAT.node_tree.animation_data_create()
    gm_act = bpy.data.actions.new(f"{clip_name}_glow_mat")
    gm_ad.action = gm_act

    for f in range(1, frames + 1, 2):
        t = (f - 1) / max(1, frames - 1)
        if clip_name == "death":
            for info in ALL_ROCKS:
                pos, rot = death_fall(info, t)
                obj = info["obj"]
                obj.location = pos
                obj.keyframe_insert("location", frame=f)
                obj.rotation_euler = rot
                obj.keyframe_insert("rotation_euler", frame=f)
            # the glow rides DOWN with core_base's own fall (not a separate
            # sink) so it never ends up exposed/floating once the chunks
            # that used to hide it have scattered away — it also fades fast
            # (fully dark by t=0.35, well before the rocks finish settling)
            # so "the core's glow dies" reads unambiguously before the pile
            # comes to rest.
            core_base_pos, _ = death_fall(CORE_CHUNKS[0], t)
            gt = min(1.0, t / 0.35)
            GLOW["obj"].location = core_base_pos + Vector((0.0, 0.0, CORE_CHUNKS[0]["radius"] * 0.35))
            GLOW["obj"].keyframe_insert("location", frame=f)
            gscale = lerp(1.0, 0.20, gt)
            GLOW["obj"].scale = Vector((gscale, gscale, gscale))
            GLOW["obj"].keyframe_insert("scale", frame=f)
            GLOW_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH * (1.0 - gt)
            GLOW_BSDF.inputs["Emission Strength"].keyframe_insert("default_value", frame=f)
            continue

        core_val, core_sc, glow_mult = CORE_FN[clip_name](t)
        for info in CORE_CHUNKS:
            obj = info["obj"]
            obj.location = info["base"] + core_val
            obj.keyframe_insert("location", frame=f)
            obj.scale = Vector((1.0, 1.0, core_sc))
            obj.keyframe_insert("scale", frame=f)
        GLOW["obj"].location = GLOW["base"] + core_val
        GLOW["obj"].keyframe_insert("location", frame=f)
        GLOW["obj"].scale = Vector((core_sc, core_sc, core_sc))
        GLOW["obj"].keyframe_insert("scale", frame=f)
        pulse = 1.0 if clip_name != "idle-loop" else 1.0 + 0.10 * math.sin(2 * math.pi * t * 2.0)
        GLOW_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH * glow_mult * pulse
        GLOW_BSDF.inputs["Emission Strength"].keyframe_insert("default_value", frame=f)
        for info in ORBIT_STONES:
            obj = info["obj"]
            obj.location = info["base"] + stone_offset(info, clip_name, t, core_val)
            obj.keyframe_insert("location", frame=f)

    clip_actions[clip_name] = (frames, obj_actions, gact, gm_act)

for info in ALL_ROCKS:
    info["obj"].animation_data.action = None
for c in CORE_CHUNKS:
    c["obj"].location = c["base"]
    c["obj"].scale = Vector((1.0, 1.0, 1.0))
    c["obj"].rotation_euler = (0.0, 0.0, 0.0)
for s in ORBIT_STONES:
    s["obj"].location = s["base"]
    s["obj"].rotation_euler = (0.0, 0.0, 0.0)
GLOW["obj"].animation_data.action = None
GLOW["obj"].location = GLOW["base"]
GLOW["obj"].scale = Vector((1.0, 1.0, 1.0))
GLOW_MAT.node_tree.animation_data.action = None
GLOW_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH

# =============================================================================
# FICHA SHOWCASE SCENE — contract rig (§4), scaled up for the golem's ~2.5m
# presence (see king_slime for the scaling precedent).
# =============================================================================
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')


add_light("key", (-3.6, -2.3, 2.9), 530, 3.6)
add_light("fill", (3.2, -2.1, 1.1), 145, 3.4)
add_light("rim", (0.7, 3.7, 2.5), 630, 3.4)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 1.05 * SCALE)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-2.4, -6.0, 2.1)
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'

# =============================================================================
# RENDER — anim frames per clip, then reset, then the hero still.
# =============================================================================
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for clip_name, (frames, obj_actions, gact, gm_act) in clip_actions.items():
    for info in ALL_ROCKS:
        ad, act = obj_actions[info["name"]]
        ad.action = act
    GLOW["obj"].animation_data.action = gact
    GLOW_MAT.node_tree.animation_data.action = gm_act
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{clip_name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[golem] frames", clip_name)
for info in ALL_ROCKS:
    info["obj"].animation_data.action = None
GLOW["obj"].animation_data.action = None
GLOW_MAT.node_tree.animation_data.action = None
for c in CORE_CHUNKS:
    c["obj"].location = c["base"]
    c["obj"].scale = Vector((1.0, 1.0, 1.0))
    c["obj"].rotation_euler = (0.0, 0.0, 0.0)
for s in ORBIT_STONES:
    s["obj"].location = s["base"]
    s["obj"].rotation_euler = (0.0, 0.0, 0.0)
GLOW["obj"].location = GLOW["base"]
GLOW["obj"].scale = Vector((1.0, 1.0, 1.0))
GLOW_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.filepath = os.path.join(REN_DIR, "golem_hero.png")
bpy.ops.render.render(write_still=True)

# =============================================================================
# NLA PUSH + EXPORT
# =============================================================================
for clip_name, (frames, obj_actions, gact, gm_act) in clip_actions.items():
    for info in ALL_ROCKS:
        ad, act = obj_actions[info["name"]]
        tr = ad.nla_tracks.new()
        tr.name = clip_name
        tr.strips.new(clip_name, 1, act)
    tro = GLOW["obj"].animation_data.nla_tracks.new()
    tro.name = clip_name
    tro.strips.new(clip_name, 1, gact)
    trm = GLOW_MAT.node_tree.animation_data.nla_tracks.new()
    trm.name = clip_name
    trm.strips.new(clip_name, 1, gm_act)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "golem_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "golem.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=False,
    export_animation_mode='NLA_TRACKS',
)
print("[golem] DONE")
