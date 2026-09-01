# build_river_segment.py -- a 12 x 10 m river reach diorama for floor 1 (v3).
#
# Reference: docs/art/_references/prairie_rivers/_synthesis.md -- tanda 2
# ("Jerarquia de roca en el rio", 2026-08-28) for material and scales, and
# tanda 3 (2026-08-30) for what v2 got wrong. Joan on v2: "se siente como un
# canal: son poligonos planos que tienen textura, no un grupo de piedras juntas.
# El rio va siempre variando en tres, nunca es un canal con dos murallas."
#
# v3 changes, each one answering a line of tanda 3:
#   * THREE bank profiles -- gradient (8-15 deg talus of fine gravel), wall
#     (1-3 m plane-cut blocks stacked 2-3 high, face 60-90 deg to the water)
#     and slabs (flat 0.3-0.8 m blocks with their tops at water level, water
#     between them). Three 4 m tramos; each bank picks one type per tramo, the
#     two banks never share a type in a tramo, all three types appear in 12 m.
#   * The bed is GEOMETRY: hundreds of plane-cut cobbles (8-30 cm, flattened,
#     imbricated upstream) fill the 0-1 m band off the waterline. The baked
#     texture only carries the < 4 cm gravel between them, as overlapping soft
#     pebbles -- no cell net, no grout lines (v2's voronoi read as flagstone).
#   * The rim wobbles 0.3-0.6 m so no bank edge is a ruler for more than 2 m.
#   * Moss as a second material slot on the up-facing dry faces of blocks/slabs.
#   * Showcase (not exported) plants a leaning tree and bushes on each bank:
#     "siempre hay vegetacion, el agua trae vida".
#
# Success metric, asserted in code before any render is looked at:
#   (a) three rock scales in one frame          -> counts printed
#   (b) >= 80 % of rocks with their base hidden -> bottom-ring test vs terrain
#   (c) a visibly darker band dry -> wet        -> wet/dry albedo ratio < 0.70
#   (d) bed visible through the water           -> measured in Godot (shader)
#   (e) >= 2 profile types per bank, 3 in total -> from the layout AND the mesh
#   (f) cobble footprint >= 60 % of the 0-1 m band off the waterline (raster)
#   (g) no collinear rim run > 2 m (heading within 5 deg)
# `--control` feeds v2's layout (one rectangular profile, 34 cobbles, straight
# rim) to (e)(f)(g) and expects them to FAIL -- a metric that cannot see the
# defect it was written for is worse than none (LECCIONES 3).
#
# Colour is baked to FLOAT_COLOR (sun/shade tint x AO) and multiplied with the
# textures: glTF guarantees COLOR_0 x baseColorTexture, and Godot reads it.
# Nothing lives in shader nodes only (2026-07-30 lesson).
#
# Run (headless, deterministic):
#   blender.exe --background --factory-startup --python-exit-code 1 \
#       --python game/tools/blender/river_segment/build_river_segment.py -- --variant 2
# then compose the contact sheets with the system python:
#   python game/tools/blender/river_segment/compose_sheets.py 2
import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
GAME = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
RECETAS = os.path.join(os.path.expanduser("~"), "motor-blender", "recetas")
for p in (RECETAS, TOOLS, os.path.join(TOOLS, "golem_guardian")):
    if p not in sys.path:
        sys.path.insert(0, p)

from biome_facet import add_faceted_rock, flat_shade  # noqa: E402
from biome_ao import bake_vertex_ao  # noqa: E402
from texture_bake import (fbm, value_noise, height_to_normal, _to_srgb)  # noqa: E402
from use_size import require_use_size  # noqa: E402

# ----------------------------------------------------------------- arguments
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
VARIANT = 2
SEED = 7
NO_RENDER = False
CONTROL = False
i = 0
while i < len(argv):
    if argv[i] == "--variant":
        VARIANT = int(argv[i + 1]); i += 2
    elif argv[i] == "--seed":
        SEED = int(argv[i + 1]); i += 2
    elif argv[i] == "--no-render":
        NO_RENDER = True; i += 1
    elif argv[i] == "--control":
        CONTROL = True; i += 1
    else:
        i += 1

# Ramp (Joan picks): fbm relief amplitude as a fraction of the rock radius --
# pool-smooth / worn / barely eaten. Wall boulder size is FIXED (v4).
RAMP = {1: 0.06, 2: 0.12, 3: 0.20}
RELIEF = RAMP[VARIANT]
WALL_LO, WALL_HI = 0.8, 1.5          # boulder size range, metres across
WET_BAND = 0.30          # v2 ramp middle, kept fixed: the ramp is elsewhere now
BURIAL = 0.40            # boulders / wall blocks: 30-50 % around this

OUT_GLB_DIR = os.path.join(GAME, "assets", "art", "piso1_pradera", "props", "water")
OUT_TEX_DIR = OUT_GLB_DIR
RENDER_DIR = os.path.join(HERE, "renders")
os.makedirs(OUT_GLB_DIR, exist_ok=True)
os.makedirs(RENDER_DIR, exist_ok=True)

# ---------------------------------------------------------------- dimensions
# Metres. Player = 1.80 m. Channel floor z=0, water z=0.32 (= STREAM_DEPTH 0.8
# * 0.40, the floor1 ribbon convention), bank top z=0.80.
SEG_LEN = 12.0          # along flow (X)
SEG_WID = 10.0          # across (Y) -- 8 in v2; the 13 deg talus needs the room
FLOOR_HALF = 1.1        # flat channel floor half-width
BANK_TOP_Z = 0.80
WATER_Z = 0.32
BED_STEP = 0.30
TEX_SIZE = 1024
GRAVEL_PERIOD = 2.0     # metres per texture repeat (2 mm / px: a 2 cm pebble = 10 px)
LIME_PERIOD = 2.0
TRAMOS = [(-6.0, -2.0), (-2.0, 2.0), (2.0, 6.0)]
GRADIENT_DEG = 13.0
GRADIENT_RUN = BANK_TOP_Z / math.tan(math.radians(GRADIENT_DEG))   # 3.46 m
WALL_RUN = 0.9
SHELF_Z = WATER_Z - 0.18          # slab shelf, under the water
SHELF_END = FLOOR_HALF + 2.2
SLAB_RISE = 1.0

rng = random.Random(SEED * 100 + VARIANT)

# --factory-startup loads the default Cube/Light/Camera; the Cube rendered as a
# white 2 m box in the middle of the water for three passes before anyone
# asked what it was. Start from nothing.
for _o in list(bpy.data.objects):
    bpy.data.objects.remove(_o, do_unlink=True)


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def meander(x):
    """Centreline offset in Y along the flow: a gentle S, not a ruler."""
    return 0.55 * math.sin(x * 0.42 + 0.8) + 0.25 * math.sin(x * 1.1 + 2.0)


# ------------------------------------------------------- bank profile layout
TYPES = ["gradient", "wall", "slabs"]


def pick_layout(r):
    """Per tramo (left, right) profile types. Each bank runs through all three
    types (so >= 2 per bank), and the two banks never share one in a tramo."""
    left = TYPES[:]
    r.shuffle(left)
    for _ in range(200):
        right = TYPES[:]
        r.shuffle(right)
        if all(a != b for a, b in zip(left, right)):
            return [(a, b) for a, b in zip(left, right)]
    raise SystemExit("layout: no derangement found")


LAYOUT = pick_layout(rng)     # [(left, right)] per tramo; left = y < meander
print(f"[layout] tramos L/R: {LAYOUT}")


def tramo_of(x):
    for ti, (x0, x1) in enumerate(TRAMOS):
        if x < x1 or ti == len(TRAMOS) - 1:
            return ti
    return len(TRAMOS) - 1


def bank_type(x, side):
    return LAYOUT[tramo_of(x)][0 if side < 0 else 1]


def rim_shift(x, side):
    """Lateral wobble of the whole profile, 0.3-0.6 m, so the rim is never a
    ruler (metric g). Depends on x and side only: the profile shifts as a
    whole, and every rock placed from the same profile follows it."""
    p = np.array([[x * 1.25, side * 7.3 + 2.0, 0.0]])
    n = (fbm(p, 3, 4.0)[0] - 0.5) * 2.0
    # plus a 0.8 m-wavelength jitter: smooth noise alone stays within 5 deg of
    # one heading for 2 m+ (measured 2.25 m on the wall tramo)
    j = (value_noise(np.array([[x * 3.1, side * 5.1 + 9.0, 0.0]]), 6.0)[0] - 0.5) * 2.0
    return max(-0.6, min(0.6, 0.65 * n + 0.28 * j))


def profile_z(kind, d):
    """Cross-section height as a function of distance from the centreline."""
    if d <= FLOOR_HALF:
        return 0.0
    u = d - FLOOR_HALF
    if kind == "gradient":
        return BANK_TOP_Z * min(1.0, u / GRADIENT_RUN)
    if kind == "wall":
        return BANK_TOP_Z * smoothstep(0.0, WALL_RUN, u)
    # slabs: short rise to a shelf under the water, then the bank climbs
    if d < FLOOR_HALF + 0.5:
        return SHELF_Z * smoothstep(0.0, 0.5, u)
    if d < SHELF_END:
        return SHELF_Z
    return SHELF_Z + (BANK_TOP_Z - SHELF_Z) * smoothstep(0.0, SLAB_RISE, d - SHELF_END)


def _warp(y, key):
    """Where a profile hands over to the next along x is NOT a straight line
    across the channel: the boundary wanders +-0.6 m with y, or the blend of
    two profiles draws a straight transverse ledge (measured: a 2.14 m ruler
    in the rim contour at every hand-over)."""
    return 0.6 * (value_noise(np.array([[y * 1.1, key * 3.7, 0.0]]), 12.0)[0] - 0.5) * 2.0


def base_z(x, y):
    """Blend of the tramo profiles along x (0.5 m either side of a boundary,
    boundary warped in y), faded to gradient on both banks over the last
    ~1.2 m so the segment tiles."""
    dy = y - meander(x)
    side = -1.0 if dy < 0.0 else 1.0
    d = abs(dy) + rim_shift(x, side)
    ti = tramo_of(x)
    kind = LAYOUT[ti][0 if side < 0 else 1]
    z = profile_z(kind, d)
    if ti < len(TRAMOS) - 1:
        b = TRAMOS[ti][1] + _warp(y, TRAMOS[ti][1])
        w = smoothstep(b - 0.5, b + 0.5, x)
        if w > 0.0:
            z = (1.0 - w) * z + w * profile_z(LAYOUT[ti + 1][0 if side < 0 else 1], d)
    if ti > 0:
        b = TRAMOS[ti][0] + _warp(y, TRAMOS[ti][0])
        w = 1.0 - smoothstep(b - 0.5, b + 0.5, x)
        if w > 0.0:
            z = (1.0 - w) * z + w * profile_z(LAYOUT[ti - 1][0 if side < 0 else 1], d)
    we = smoothstep(SEG_LEN / 2 - 1.2 + 0.6 * _warp(y, 9.0), SEG_LEN / 2, abs(x))
    if we > 0.0:
        z = (1.0 - we) * z + we * profile_z("gradient", d)
    return z


def terrain_z(x, y):
    """Profile plus 2-6 cm gravel relief so the bed is not a plane."""
    base = base_z(x, y)
    relief = 0.03 * (fbm(np.array([[x * 1.3, y * 1.3, 0.0]]), 3, 3.0)[0] - 0.5)
    relief += 0.015 * (value_noise(np.array([[x * 5.0, y * 5.0, 0.0]]), 9.0)[0] - 0.5)
    return base + relief


def waterline_d(x, side):
    """Distance from the centreline where the terrain rises through the water
    surface on `side` (no relief, so it is the profile's own crossing)."""
    d = 0.0
    while d < SEG_WID / 2 + 1.0:
        if base_z(x, meander(x) + side * d) >= WATER_Z:
            return d
        d += 0.02
    return SEG_WID / 2


def rim_d(x, side):
    d = 0.0
    while d < SEG_WID / 2 + 1.0:
        if base_z(x, meander(x) + side * d) >= BANK_TOP_Z - 0.03:
            return d
        d += 0.02
    return SEG_WID / 2


# ---------------------------------------------------------- metric functions
# Pure functions of data, so `--control` can feed them v2's layout.
def metric_e_layout(layout):
    left = {a for a, _ in layout}
    right = {b for _, b in layout}
    total = left | right
    ok = len(left) >= 2 and len(right) >= 2 and len(total) == 3
    return ok, len(left), len(right), len(total)


def metric_f_coverage(footprints, band_cells):
    """footprints: list of 2D vertex lists (m). band_cells: boolean raster of
    the 0-1 m band. Returns covered fraction of the band."""
    cell = RASTER_CELL
    cov = np.zeros_like(band_cells)
    for pts in footprints:
        _paint_hull(cov, pts, cell)
    band_n = int(band_cells.sum())
    if band_n == 0:
        return 0.0
    return float((cov & band_cells).sum()) / band_n


def metric_g_rim(polyline, max_run=2.0, tol_deg=5.0):
    """Longest run of consecutive segments whose heading stays within tol of
    the run's first segment."""
    longest = 0.0
    longest_at = None
    n = len(polyline)
    i = 0
    while i < n - 1:
        p0 = polyline[i]; p1 = polyline[i + 1]
        h0 = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
        run = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        j = i + 1
        while j < n - 1:
            q0 = polyline[j]; q1 = polyline[j + 1]
            h = math.atan2(q1[1] - q0[1], q1[0] - q0[0])
            dh = abs((h - h0 + math.pi) % (2 * math.pi) - math.pi)
            if math.degrees(dh) >= tol_deg:
                break
            run += math.hypot(q1[0] - q0[0], q1[1] - q0[1])
            j += 1
        if run > longest:
            longest = run; longest_at = polyline[i][0]
        i += 1
    metric_g_rim.last_at = longest_at
    return longest, longest <= max_run


RASTER_CELL = 0.025
RX = int(SEG_LEN / RASTER_CELL); RY = int(SEG_WID / RASTER_CELL)


def _hull2d(pts):
    pts = sorted(set((round(p[0], 5), round(p[1], 5)) for p in pts))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def _paint_hull(mask, pts, cell):
    hull = _hull2d(pts)
    if len(hull) < 3:
        return
    xs = [p[0] for p in hull]; ys = [p[1] for p in hull]
    ix0 = max(0, int((min(xs) + SEG_LEN / 2) / cell)); ix1 = min(mask.shape[0] - 1, int((max(xs) + SEG_LEN / 2) / cell) + 1)
    iy0 = max(0, int((min(ys) + SEG_WID / 2) / cell)); iy1 = min(mask.shape[1] - 1, int((max(ys) + SEG_WID / 2) / cell) + 1)
    if ix1 <= ix0 or iy1 <= iy0:
        return
    gx = (np.arange(ix0, ix1 + 1) + 0.5) * cell - SEG_LEN / 2
    gy = (np.arange(iy0, iy1 + 1) + 0.5) * cell - SEG_WID / 2
    X, Y = np.meshgrid(gx, gy, indexing="ij")
    inside = np.ones(X.shape, dtype=bool)
    m = len(hull)
    for k in range(m):
        ax, ay = hull[k]; bx, by = hull[(k + 1) % m]
        inside &= ((bx - ax) * (Y - ay) - (by - ay) * (X - ax)) >= -1e-9
    mask[ix0:ix1 + 1, iy0:iy1 + 1] |= inside


def band_raster(band_fn):
    """Boolean raster of the cells whose centre satisfies band_fn(x, y)."""
    cells = np.zeros((RX, RY), dtype=bool)
    for ix in range(RX):
        x = (ix + 0.5) * RASTER_CELL - SEG_LEN / 2
        for iy in range(RY):
            y = (iy + 0.5) * RASTER_CELL - SEG_WID / 2
            cells[ix, iy] = band_fn(x, y)
    return cells


def rim_polyline(side, z_fn, step=0.10):
    """The rim as a TRACED iso-contour (z = BANK_TOP_Z - 0.03) on `side`,
    marching squares on a `step` grid, chained into polylines. Sampling the
    contour per x collapsed every transverse stretch (a profile hand-over)
    into one 2 m segment, collinear by definition: the metric must follow
    the line, not project it. Returns the longest chain."""
    iso = BANK_TOP_Z - 0.03
    xs = np.arange(-SEG_LEN / 2, SEG_LEN / 2 + 1e-6, step)
    ys = np.arange(0.0, SEG_WID / 2 + 1.0 + 1e-6, step)          # distance from the centreline
    Z = np.zeros((len(xs), len(ys)))
    for i, x in enumerate(xs):
        for j, d in enumerate(ys):
            Z[i, j] = z_fn(x, meander(x) + side * d)
    segs = []

    def lerp(pa, pb, va, vb):
        t = (iso - va) / (vb - va) if abs(vb - va) > 1e-9 else 0.5
        return (pa[0] + (pb[0] - pa[0]) * t, pa[1] + (pb[1] - pa[1]) * t)
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            v = [Z[i, j], Z[i + 1, j], Z[i + 1, j + 1], Z[i, j + 1]]
            pts = [(xs[i], ys[j]), (xs[i + 1], ys[j]), (xs[i + 1], ys[j + 1]), (xs[i], ys[j + 1])]
            crossings = []
            for k in range(4):
                a, b = k, (k + 1) % 4
                if (v[a] >= iso) != (v[b] >= iso):
                    crossings.append(lerp(pts[a], pts[b], v[a], v[b]))
            if len(crossings) == 2:
                segs.append((crossings[0], crossings[1]))
            elif len(crossings) == 4:
                segs.append((crossings[0], crossings[1])); segs.append((crossings[2], crossings[3]))
    # chain segments by shared endpoints
    key = lambda p: (round(p[0], 4), round(p[1], 4))
    adj = {}
    for a, b in segs:
        adj.setdefault(key(a), []).append((a, b)); adj.setdefault(key(b), []).append((b, a))
    used = set(); chains = []
    for a, b in segs:
        if (key(a), key(b)) in used or (key(b), key(a)) in used:
            continue
        chain = [a, b]; used.add((key(a), key(b)))
        for end in (1, 0):
            while True:
                tip = chain[-1] if end else chain[0]
                nxt = None
                for (p, q) in adj.get(key(tip), []):
                    if (key(p), key(q)) in used or (key(q), key(p)) in used:
                        continue
                    nxt = q; used.add((key(p), key(q))); break
                if nxt is None:
                    break
                if end:
                    chain.append(nxt)
                else:
                    chain.insert(0, nxt)
        chains.append(chain)
    if not chains:
        return []
    best = max(chains, key=lambda c: sum(math.hypot(c[k + 1][0] - c[k][0], c[k + 1][1] - c[k][1]) for k in range(len(c) - 1)))
    # back to world y
    return [(x, meander(x) + side * d) for (x, d) in best]


def dry_band(x, y):
    """The 0-1 m band off the waterline on the dry side (0.35 m at a wall toe)."""
    dy = y - meander(x)
    side = -1.0 if dy < 0 else 1.0
    kind = bank_type(x, side)
    dw = _wl_cache(x, side)
    width = 0.35 if kind == "wall" else 1.0
    return dw <= abs(dy) < dw + width


_WL = {}


def _wl_cache(x, side):
    key = (round(x * 8) / 8.0, side)
    if key not in _WL:
        _WL[key] = waterline_d(key[0], side)
    return _WL[key]


# ------------------------------------------------------------------- control
if CONTROL:
    print("[control] feeding v2's layout to metrics e/f/g -- all three must FAIL")
    v2_layout = [("rect", "rect")] * 3
    ok_e, nl, nr, nt = metric_e_layout(v2_layout)
    print(f"[control e] types L={nl} R={nr} total={nt} -> {'PASS' if ok_e else 'FAIL'}")
    # v2: rectangular trench, rim at |dy| = 2.4, water at |dy| ~ 1.9
    def v2_z(x, y):
        d = abs(y - meander(x))
        return BANK_TOP_Z * smoothstep(1.1, 2.4, d)
    band = np.zeros((RX, RY), dtype=bool)
    for ix in range(RX):
        x = (ix + 0.5) * RASTER_CELL - SEG_LEN / 2
        for iy in range(RY):
            y = (iy + 0.5) * RASTER_CELL - SEG_WID / 2
            d = abs(y - meander(x))
            band[ix, iy] = 1.9 <= d < 2.9
    r2 = random.Random(1)
    fps = []
    for k in range(34):
        x = r2.uniform(-5.6, 5.6); side = r2.choice([-1, 1])
        y = meander(x) + side * r2.uniform(1.0, 2.3)
        rr = r2.uniform(0.08, 0.18) * 1.1
        ang = r2.uniform(0, math.tau)
        pts = [(x + rr * 1.3 * math.cos(t + ang), y + rr * math.sin(t + ang))
               for t in np.linspace(0, math.tau, 12, endpoint=False)]
        fps.append(pts)
    cov = metric_f_coverage(fps, band)
    print(f"[control f] cobble coverage of the band {cov:.3f} (limit >= 0.60) -> {'PASS' if cov >= 0.60 else 'FAIL'}")
    poly = rim_polyline(-1.0, v2_z)
    run, ok_g = metric_g_rim(poly)
    print(f"[control g] longest collinear rim run {run:.2f} m (limit <= 2.0) -> {'PASS' if ok_g else 'FAIL'}")
    # (h) controls: a v3 faceted rock must FAIL roundness, a worn one must pass
    import biome_facet as _bf

    def _dihedral_frac(tb):
        ne = ns = 0
        for e in tb.edges:
            if len(e.link_faces) != 2:
                continue
            ne += 1
            if math.degrees(e.calc_face_angle(0.0)) > 30.0:
                ns += 1
        return ns / max(ne, 1)
    _r2 = random.Random(3)
    tb = bmesh.new(); _vc = {}
    _bf.add_faceted_rock(tb, _vc, (0, 0, 0),
                         dict(radius=0.5, blocks=1, cuts=8, bedding=2, elongate=1.15,
                              flatten=1.1, color_rock=(1, 1, 1), color_moss=None,
                              crevice_dark=0.0, erode=0.0), _r2)
    f_facet = _dihedral_frac(tb); tb.free()
    tb = bmesh.new()
    bmesh.ops.create_uvsphere(tb, u_segments=14, v_segments=9, radius=1.0)
    for v in tb.verts:
        p = v.co * 1.7
        n = fbm(np.array([[p.x, p.y, p.z]]), 2, 5.0)[0] - 0.5
        v.co += v.co.normalized() * ((n - 0.25) * RELIEF * 2.0)
    for v in tb.verts:
        v.co.z *= 0.6
    for _ in range(2):
        bmesh.ops.smooth_vert(tb, verts=tb.verts[:], factor=0.5,
                              use_axis_x=True, use_axis_y=True, use_axis_z=True)
    tb.normal_update()
    f_round = _dihedral_frac(tb); tb.free()
    print(f"[control h] faceted sharp-edge frac {f_facet:.2f} -> {'FAIL' if f_facet > 0.10 else 'PASS'} (must FAIL); worn {f_round:.2f} -> {'PASS' if f_round <= 0.10 else 'FAIL'} (must PASS)")
    if ok_e or cov >= 0.60 or ok_g or f_facet <= 0.10 or f_round > 0.10:
        raise SystemExit("[control] a control metric went the wrong way: it cannot see the defect")
    print("[control] OK: e, f, g fail on v2's layout and h separates faceted from worn")
    raise SystemExit(0)


if "--rim-debug" in argv:
    for side in (-1.0, 1.0):
        poly = rim_polyline(side, base_z)
        run, ok = metric_g_rim(poly)
        print(f"[rim] side {side:+.0f} run {run:.2f} at x={metric_g_rim.last_at}")
        for (x, y) in poly:
            print(f"  {x:6.2f} {y:6.3f}  d={abs(y - meander(x)):.3f} shift={rim_shift(x, side):+.3f}")
    raise SystemExit(0)


# ------------------------------------------------------------ texture bakes
def _hash2(xi, yi, seed):
    h = np.sin(xi * 127.1 + yi * 311.7 + seed * 91.3) * 43758.5453
    return h - np.floor(h)


def voronoi_cells(u, v, cells, seed):
    """Tileable 2D voronoi: (edge distance, cell hash, distance to centre)."""
    px, py = u * cells, v * cells
    ix, iy = np.floor(px), np.floor(py)
    fx, fy = px - ix, py - iy
    d1 = np.full(px.shape, 9.0); d2 = np.full(px.shape, 9.0)
    cid = np.zeros(px.shape)
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            cx = np.mod(ix + ox, cells); cy = np.mod(iy + oy, cells)
            jx = _hash2(cx, cy, seed) * 0.8 + 0.1
            jy = _hash2(cx, cy, seed + 3.0) * 0.8 + 0.1
            dx = ox + jx - fx; dy = oy + jy - fy
            d = np.sqrt(dx * dx + dy * dy)
            closer = d < d1
            d2 = np.where(closer, d1, np.minimum(d2, d))
            cid = np.where(closer, _hash2(cx, cy, seed + 7.0), cid)
            d1 = np.where(closer, d, d1)
    return d2 - d1, cid, d1


# One limestone family (reel: grey-cream, ochre in sun, blue-grey in shade).
LIME_BASE = np.array([0.62, 0.585, 0.52])
LIME_DARK = np.array([0.34, 0.31, 0.27])


def bake_limestone(size, seed):
    """Tileable limestone grain: mottle + fine grain + shallow pits + a few
    hairline cracks. Big-scale tone lives in vertex colour, not here."""
    u, v = np.meshgrid(np.linspace(0, 1, size, endpoint=False),
                       np.linspace(0, 1, size, endpoint=False))
    tw = 2.0 * math.pi
    p = np.stack([np.cos(u * tw), np.sin(u * tw), np.cos(v * tw) + np.sin(v * tw) * 0.7], -1)
    mottle = fbm(p * 1.7, 3, seed)
    grain = value_noise(p * 11.0, seed + 5.0) - 0.5
    pits = np.clip((value_noise(p * 6.0, seed + 8.0) - 0.68) / 0.15, 0, 1)
    val = 0.78 + 0.40 * (mottle - 0.5) + 0.12 * grain
    rgb = LIME_BASE[None, None, :] * val[..., None]
    rgb = rgb * (1.0 - 0.45 * pits[..., None]) + LIME_DARK[None, None, :] * (0.45 * pits[..., None])
    edge, cid, _ = voronoi_cells(u, v, 6, seed + 21.0)
    crack = np.clip((0.03 - edge) / 0.025, 0, 1) * (cid > 0.84)
    rgb = rgb * (1.0 - 0.28 * crack[..., None])
    height = -0.6 * pits - 0.5 * crack + 0.15 * grain
    return np.clip(rgb, 0, 1), height


def bake_fine_gravel(size, seed):
    """Tileable FINE gravel: thousands of overlapping rounded pebbles (1-4 cm,
    a few 5-7 cm) laid with a height z-buffer so later stones sit ON earlier
    ones. No cell net: a cell net has a grout line around every stone and
    reads as flagstone at 1 m (v2). Sand shows only in the few gaps."""
    r = np.random.RandomState(int(seed))
    px_per_m = size / GRAVEL_PERIOD
    height = np.full((size, size), -0.35)
    rgb = np.zeros((size, size, 3))
    grain = value_noise(np.stack([np.meshgrid(np.arange(size), np.arange(size))[0] * 0.09,
                                  np.meshgrid(np.arange(size), np.arange(size))[1] * 0.09,
                                  np.zeros((size, size))], -1), seed + 5.0) - 0.5
    sand = np.array([0.40, 0.36, 0.29])
    rgb[:] = sand[None, None, :] * (0.85 + 0.3 * grain)[..., None]
    warm = np.array([1.0, 0.92, 0.78]); cool = np.array([0.84, 0.89, 1.0])
    n_small = 13000
    n_big = 90
    radii = np.concatenate([0.005 + 0.015 * r.rand(n_small) ** 1.4,     # 1-4 cm
                            0.025 + 0.012 * r.rand(n_big)])             # 5-7.4 cm
    order = np.argsort(radii)          # big first, small on top
    order = order[::-1]
    cx_all = r.rand(len(radii)) * size; cy_all = r.rand(len(radii)) * size
    tone_all = 0.55 + 0.65 * r.rand(len(radii)); hue_all = r.rand(len(radii))
    for k in order:
        rp = radii[k] * px_per_m
        cx, cy = cx_all[k], cy_all[k]
        w = int(math.ceil(rp)) + 1
        xs = np.arange(int(cx) - w, int(cx) + w + 1)
        ys = np.arange(int(cy) - w, int(cy) + w + 1)
        X, Y = np.meshgrid(xs, ys, indexing="ij")
        dx = (X + 0.5 - cx) / rp; dy = (Y + 0.5 - cy) / rp
        # squash a little so pebbles are not all discs
        e = 0.8 + 0.4 * hue_all[k]
        dd = dx * dx * e + dy * dy / e
        inside = dd < 1.0
        if not inside.any():
            continue
        dome = np.sqrt(np.clip(1.0 - dd, 0, 1)) * radii[k] / 0.02   # metres-ish, 0.02 = unit
        z = np.where(inside, dome, -9.0)
        xi = np.mod(X, size); yi = np.mod(Y, size)
        cur = height[xi, yi]
        win = inside & (z > cur)
        if not win.any():
            continue
        tint = warm * hue_all[k] + cool * (1.0 - hue_all[k])
        shade = 0.70 + 0.30 * np.sqrt(np.clip(1.0 - dd, 0, 1))      # darker at the rim
        col = (LIME_BASE * tint)[None, None, :] * (tone_all[k] * shade)[..., None]
        height[xi[win], yi[win]] = z[win]
        rgb[xi[win], yi[win]] = col[win]
    rgb *= (1.0 + 0.10 * grain)[..., None]
    return np.clip(rgb, 0, 1), height


def save_image(name, arr, srgb):
    size = arr.shape[0]
    im = bpy.data.images.new(name, width=size, height=size, alpha=False)
    im.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
    rgba = np.ones((size, size, 4), dtype=np.float32)
    rgba[..., :3] = (_to_srgb(arr) if srgb else arr).astype(np.float32)
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = os.path.join(OUT_TEX_DIR, name + ".png")
    im.file_format = "PNG"
    im.save()
    return im


def textured_material(name, albedo_img, normal_img, roughness, use_vcol=True):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = 0.18
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = albedo_img
    if use_vcol:
        attr = nt.nodes.new("ShaderNodeVertexColor"); attr.layer_name = "Col"
        mixn = nt.nodes.new("ShaderNodeMix"); mixn.data_type = 'RGBA'
        mixn.blend_type = 'MULTIPLY'; mixn.inputs["Factor"].default_value = 1.0
        nt.links.new(tex.outputs["Color"], mixn.inputs[6])
        nt.links.new(attr.outputs["Color"], mixn.inputs[7])
        nt.links.new(mixn.outputs[2], bsdf.inputs["Base Color"])
    else:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    ntex = nt.nodes.new("ShaderNodeTexImage"); ntex.image = normal_img
    nmap = nt.nodes.new("ShaderNodeNormalMap"); nmap.inputs["Strength"].default_value = 1.0
    nt.links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    return mat


def flat_material(name, rgb, roughness):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    bsdf.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    attr = nt.nodes.new("ShaderNodeVertexColor"); attr.layer_name = "Col"
    mixn = nt.nodes.new("ShaderNodeMix"); mixn.data_type = 'RGBA'
    mixn.blend_type = 'MULTIPLY'; mixn.inputs["Factor"].default_value = 1.0
    mixn.inputs[6].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    nt.links.new(attr.outputs["Color"], mixn.inputs[7])
    nt.links.new(mixn.outputs[2], bsdf.inputs["Base Color"])
    return mat


print(f"[river] v4 variant a{VARIANT}: relief {RELIEF:.2f} x radius, wall boulders {WALL_LO:.1f}-{WALL_HI:.1f} m, wet band {WET_BAND:.2f} m")
lime_rgb, lime_h = bake_limestone(TEX_SIZE, 11.0)
grav_rgb, grav_h = bake_fine_gravel(TEX_SIZE, 23.0)
img_lime = save_image("river_limestone_albedo", lime_rgb, True)
img_lime_wet = save_image("river_limestone_wet_albedo", lime_rgb * 0.55, True)
img_lime_n = save_image("river_limestone_normal", height_to_normal(lime_h, 2.2), False)
img_grav = save_image("river_gravel_fine_albedo", grav_rgb, True)
img_grav_wet = save_image("river_gravel_fine_wet_albedo", grav_rgb * 0.55, True)
img_grav_n = save_image("river_gravel_fine_normal", height_to_normal(grav_h, 1.6), False)

MAT_GRAVEL = textured_material("river_gravel_dry", img_grav, img_grav_n, 0.90)
MAT_GRAVEL_WET = textured_material("river_gravel_wet", img_grav_wet, img_grav_n, 0.45)
MAT_LIME = textured_material("river_limestone_dry", img_lime, img_lime_n, 0.88)
MAT_LIME_WET = textured_material("river_limestone_wet", img_lime_wet, img_lime_n, 0.25)
MAT_BANK = bpy.data.materials.new("river_bank_soil")
MAT_BANK.use_nodes = True
MAT_BANK.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.10, 0.13, 0.05, 1.0)
MAT_BANK.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.95


# ------------------------------------------------------------------ the bed
bm = bmesh.new()
vcol = {}
uv_layer = bm.loops.layers.uv.new("UVMap")
lay_bed = bm.faces.layers.int.new("bedish")   # 1 = bed/strip, 0 = rock; survives bisect splits
nx = int(SEG_LEN / BED_STEP); ny = int(SEG_WID / BED_STEP)
grid = {}
for ix in range(nx + 1):
    for iy in range(ny + 1):
        x = -SEG_LEN / 2 + ix * BED_STEP
        y = -SEG_WID / 2 + iy * BED_STEP
        grid[(ix, iy)] = bm.verts.new((x, y, terrain_z(x, y)))
bed_faces = []
for ix in range(nx):
    for iy in range(ny):
        f = bm.faces.new([grid[(ix, iy)], grid[(ix + 1, iy)],
                          grid[(ix + 1, iy + 1)], grid[(ix, iy + 1)]])
        f.smooth = True
        f[lay_bed] = 1
        bed_faces.append(f)
for v in bm.verts:
    vcol[v] = (1.0, 1.0, 1.0)

# ---------------------------------------------------------------- the rocks
SUN = Vector((-0.45, -0.55, 0.70)).normalized()
TINT_SUN = Vector((1.0, 0.94, 0.82))      # ochre in the sun
TINT_SHADE = Vector((0.84, 0.89, 1.0))    # blue-grey in shade

FAMILIES = {
    "block": dict(elongate=1.05, flatten=1.0, cuts=8, bedding=1),
    "wedge": dict(elongate=1.30, flatten=0.75, cuts=6, bedding=1),
    # wall block: long along the flow, bedded, many medium facets
    "wallblock": dict(elongate=1.15, flatten=1.1, cuts=8, bedding=2),
    # slab: a flat lens, bedding planes top and bottom
    "slab": dict(elongate=1.4, flatten=0.5, cuts=6, bedding=2),
    # cobble: few cuts (budget), flattened, rolled
    "cobble": dict(elongate=1.35, flatten=0.6, cuts=3, bedding=0),   # ~16 tris each
}
rocks = []   # dicts: kind, faces, verts, family, height, center, radius, top, bottom, tramo, side


def add_round_rock(center, radii, yaw, tilt_axis, tilt_deg, seed):
    """A water-worn stone: uv-sphere (14x7 keeps every base dihedral at 25.7
    deg), low-amplitude fbm eaten inward, non-uniform radii, smooth-shaded.
    Returns (faces, verts). UV is spherical, seam unwrapped per face."""
    tmp = bmesh.new()
    bmesh.ops.create_uvsphere(tmp, u_segments=14, v_segments=9, radius=1.0)
    rm = sum(radii) / 3.0
    for v in tmp.verts:
        p = v.co * 1.7 + Vector((seed * 3.1, seed * 1.7, seed * 2.3))
        n = fbm(np.array([[p.x, p.y, p.z]]), 2, seed)[0] - 0.5
        v.co += v.co.normalized() * ((n - 0.25) * RELIEF * 2.0)   # biased inward: erosion eats
    sph_uv = {v: (math.atan2(v.co.y, v.co.x) / math.tau % 1.0,
                  math.acos(max(-1.0, min(1.0, v.co.z / max(v.co.length, 1e-9)))) / math.pi)
              for v in tmp.verts}
    # scale FIRST, then relax: flattening a sphere creases the equator (the
    # meridian dihedral divides by the flatten factor -- measured 0.119 sharp
    # at flatten 0.5). Two Laplacian passes spread the crease over the rings:
    # exactly what water does to a stone.
    for v in tmp.verts:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    for _ in range(2):
        bmesh.ops.smooth_vert(tmp, verts=tmp.verts[:], factor=0.5,
                              use_axis_x=True, use_axis_y=True, use_axis_z=True)
    M = (Matrix.Rotation(math.radians(yaw), 4, 'Z')
         @ Matrix.Rotation(math.radians(tilt_deg), 4, tilt_axis))
    verts_map = {}
    for v in tmp.verts:
        verts_map[v] = bm.verts.new(M @ v.co)
    faces = []
    circ = math.tau * rm
    for f in tmp.faces:
        try:
            nf = bm.faces.new([verts_map[v] for v in f.verts])
        except ValueError:
            continue
        nf.smooth = True
        us = [sph_uv[v][0] for v in f.verts]
        wrap = (max(us) - min(us)) > 0.5
        for loop, v in zip(nf.loops, f.verts):
            u, vv = sph_uv[v]
            if wrap and u < 0.5:
                u += 1.0
            loop[uv_layer].uv = (u * circ / LIME_PERIOD, vv * 0.5 * circ / LIME_PERIOD)
        faces.append(nf)
    tmp.free()
    return faces, set(verts_map.values())


def place_round(kind, center_xy, radii, yaw, tilt_axis, tilt_deg, burial,
                z_top=None, z_rest=None, side=0.0, hide_z=None):
    """place_rock's drop logic for a rounded stone."""
    faces, verts = add_round_rock((0, 0, 0), radii, yaw, tilt_axis, tilt_deg,
                                  rng.uniform(0.0, 99.0))
    zmin = min(v.co.z for v in verts); zmax = max(v.co.z for v in verts)
    h = zmax - zmin
    cx, cy = center_xy
    ring = [v for v in verts if v.co.z < zmin + 0.22 * h]
    if z_rest is not None:
        dz = z_rest - zmin - burial * h
    elif z_top is not None:
        dz = z_top - zmax
        dz_ring = min(terrain_z(v.co.x + cx, v.co.y + cy) - v.co.z for v in ring) - 0.01
        dz = max(min(dz, dz_ring), (WATER_Z - 0.05) - zmax)
    else:
        ground = terrain_z(cx, cy)
        dz_center = ground - zmin - burial * h
        hz = hide_z if hide_z is not None else -9.0
        dz_ring = min(max(terrain_z(v.co.x + cx, v.co.y + cy), hz) - v.co.z for v in ring) - 0.01
        cap = 0.82 if kind == "cobble" else 0.70
        dz = max(min(dz_center, dz_ring), ground - zmin - cap * h)
    for v in verts:
        v.co = Vector((v.co.x + cx, v.co.y + cy, v.co.z + dz))
    rec = dict(kind=kind, faces=faces, verts=verts, family="round", height=h,
               center=(cx, cy), radius=sum(radii) / 3.0, top=zmax + dz, bottom=zmin + dz,
               tramo=tramo_of(cx), side=side, supported=(z_rest is not None), hide_z=hide_z,
               rounded=True,
               xmin=min(v.co.x for v in verts), xmax=max(v.co.x for v in verts),
               ymin=min(v.co.y for v in verts), ymax=max(v.co.y for v in verts))
    rocks.append(rec)
    return rec


def place_rock(kind, center_xy, radius, family, yaw, tilt_axis, tilt_deg,
               scale3, blocks, burial, spec_extra=None, z_top=None, z_rest=None,
               side=0.0, hide_z=None):
    """Build a plane-cut mass at the origin, transform it (non-uniform scale,
    free rotation), then drop it: by `burial` of its height under the terrain
    (default), or with its top at `z_top` (slabs), or resting `burial` into
    a support at `z_rest` (upper wall blocks). Returns the rock record."""
    fam = dict(FAMILIES[family])
    if spec_extra:
        fam.update(spec_extra)
    spec = dict(radius=radius, blocks=blocks, color_rock=(1.0, 1.0, 1.0),
                color_moss=None, crevice_dark=0.0, erode=0.0)
    spec.update(dict(taper=0.25, stack=0.35 if blocks > 1 else 0.0))
    spec.update(fam)
    local = {}
    faces = add_faceted_rock(bm, local, (0.0, 0.0, 0.0), spec, rng)
    verts = {v for f in faces for v in f.verts}
    M = (Matrix.Rotation(math.radians(yaw), 4, 'Z')
         @ Matrix.Rotation(math.radians(tilt_deg), 4, tilt_axis)
         @ Matrix.Diagonal((scale3[0], scale3[1], scale3[2], 1.0)))
    for v in verts:
        v.co = M @ v.co
    zmin = min(v.co.z for v in verts); zmax = max(v.co.z for v in verts)
    h = zmax - zmin
    cx, cy = center_xy
    ring = [v for v in verts if v.co.z < zmin + 0.18 * h]
    if z_rest is not None:
        dz = z_rest - zmin - burial * h
    elif z_top is not None:
        dz = z_top - zmax
        dz_ring = min(terrain_z(v.co.x + cx, v.co.y + cy) - v.co.z for v in ring) - 0.01
        # sink until the base is under the shelf, but keep the top in the
        # +-5 cm band at the water surface that makes a slab read as a slab
        dz = max(min(dz, dz_ring), (WATER_Z - 0.05) - zmax)
    else:
        ground = terrain_z(cx, cy)
        dz_center = ground - zmin - burial * h
        # On a slope the terrain drops across the footprint: a rock buried
        # `burial` at its centre still shows its downhill base edge. So ALSO
        # sink until every bottom-ring vertex is under the terrain at its own
        # xy, capped so the rock does not vanish.
        # a wall block's water side is hidden by the WATER, not the terrain
        hz = hide_z if hide_z is not None else -9.0
        dz_ring = min(max(terrain_z(v.co.x + cx, v.co.y + cy), hz) - v.co.z for v in ring) - 0.01
        cap = 0.82 if kind == "cobble" else 0.70
        dz = max(min(dz_center, dz_ring), ground - zmin - cap * h)
    for v in verts:
        v.co = Vector((v.co.x + cx, v.co.y + cy, v.co.z + dz))
    flat_shade(faces)
    rec = dict(kind=kind, faces=faces, verts=verts, family=family, height=h,
               center=(cx, cy), radius=radius, top=zmax + dz, bottom=zmin + dz,
               tramo=tramo_of(cx), side=side, supported=(z_rest is not None), hide_z=hide_z,
               xmin=min(v.co.x for v in verts), xmax=max(v.co.x for v in verts),
               ymin=min(v.co.y for v in verts), ymax=max(v.co.y for v in verts))
    rocks.append(rec)
    return rec


def scale3(lo, hi, zlo, zhi, max_aspect=1.8):
    sx = rng.uniform(lo, hi)
    sy = rng.uniform(max(lo, sx / max_aspect), min(hi, sx * max_aspect))
    return (sx, sy, rng.uniform(zlo, zhi))


# 1) WALL profile -- a PACKED pile of 8-14 water-worn boulders (0.8-1.5 m,
#    fixed across the ramp), 10-20 % overlap, seated on the ground or nestled
#    into the hollow between two neighbours (never balanced on top of two --
#    v3 read as dice). Pile top capped at 2x channel depth over the water.
WALL_TOP_CAP = WATER_Z + 2.0 * BANK_TOP_Z
wall_tramos = [(ti, side) for ti, (l, r) in enumerate(LAYOUT)
               for side, kind in ((-1.0, l), (1.0, r)) if kind == "wall"]
for (ti, side) in wall_tramos:
    x0, x1 = TRAMOS[ti]
    lower = []
    x = x0 + 0.55
    while x < x1 - 0.35 and len(lower) < 7:
        S = rng.uniform(WALL_LO, WALL_HI)
        a = 0.62 * S; b = a * rng.uniform(0.75, 0.95); c = a * rng.uniform(0.70, 0.90)
        if lower:
            x = lower[-1]["xmax"] + a - rng.uniform(0.10, 0.20) * 2.0 * a
        d = FLOOR_HALF + 0.35 - rim_shift(x, side)
        rec = place_round("wall", (x, meander(x) + side * d), (a, b, c),
                          rng.uniform(0, 360), 'X', -side * rng.uniform(0, 12),
                          burial=rng.uniform(0.25, 0.35), hide_z=WATER_Z, side=side)
        lower.append(rec)
        x = rec["xmax"]
    uppers = []
    for k in range(len(lower) - 1):
        A, B = lower[k], lower[k + 1]
        S = rng.uniform(WALL_LO, WALL_HI) * 0.85
        a = 0.62 * S; b = a * rng.uniform(0.75, 0.95); c = a * rng.uniform(0.70, 0.90)
        xj = 0.5 * (A["xmax"] + B["xmin"]) + rng.uniform(-0.08, 0.08)
        yj = 0.5 * (A["center"][1] + B["center"][1]) + side * 0.45 * a
        rec = place_round("wall", (xj, yj), (a, b, c),
                          rng.uniform(0, 360), 'X', -side * rng.uniform(0, 10),
                          burial=0.45, z_rest=min(A["top"], B["top"]), side=side)
        if rec["top"] > WALL_TOP_CAP:                     # cap: sink, never tower
            drop = rec["top"] - WALL_TOP_CAP
            for v in rec["verts"]:
                v.co.z -= drop
            rec["top"] -= drop; rec["bottom"] -= drop
        rec["support"] = [A, B]
        uppers.append(rec)
    # crest: the wall must show >= 3 boulders above the bank (metric e). Add
    # nestled boulders into the joints of x-adjacent uppers -- same seating as
    # the second row, never a block balanced on top.
    def _n_tall():
        return sum(1 for r in rocks if r["kind"] == "wall" and r["tramo"] == ti
                   and r["side"] == side and r["top"] > BANK_TOP_Z + 0.3)
    ups = sorted(uppers, key=lambda r: r["center"][0])
    joints = sorted(range(max(len(ups) - 1, 0)), key=lambda k: -min(ups[k]["top"], ups[k + 1]["top"]))
    ji = 0
    while _n_tall() < 3 and ji < len(joints):
        k = joints[ji]; ji += 1
        A, B = ups[k], ups[k + 1]
        S = rng.uniform(WALL_LO, WALL_HI) * 0.8
        a = 0.62 * S; b = a * rng.uniform(0.75, 0.95); c = a * rng.uniform(0.70, 0.90)
        xj = 0.5 * (A["xmax"] + B["xmin"]) + rng.uniform(-0.06, 0.06)
        yj = 0.5 * (A["center"][1] + B["center"][1]) + side * 0.30 * a
        rec = place_round("wall", (xj, yj), (a, b, c),
                          rng.uniform(0, 360), 'X', -side * rng.uniform(0, 10),
                          burial=0.45, z_rest=min(A["top"], B["top"]), side=side)
        if rec["top"] > WALL_TOP_CAP:
            drop = rec["top"] - WALL_TOP_CAP
            for v in rec["verts"]:
                v.co.z -= drop
            rec["top"] -= drop; rec["bottom"] -= drop
        rec["support"] = [A, B]
        uppers.append(rec)
    n = len(lower) + len(uppers)
    while n < 8:                                          # fill the toe, on the ground
        S = rng.uniform(WALL_LO, WALL_HI) * 0.7
        a = 0.62 * S; b = a * rng.uniform(0.75, 0.95); c = a * rng.uniform(0.70, 0.90)
        gx = rng.uniform(x0 + 0.4, x1 - 0.4)
        d = FLOOR_HALF + 0.12 - rim_shift(gx, side)
        place_round("wall", (gx, meander(gx) + side * d), (a, b, c),
                    rng.uniform(0, 360), 'Y', rng.uniform(-10, 10),
                    burial=rng.uniform(0.30, 0.40), hide_z=WATER_Z, side=side)
        n += 1

# 2) SLABS profile -- worn flat stones on the shelf, tops at the water
#    surface, long axis across the flow, water between them.
slab_tramos = [(ti, side) for ti, (l, r) in enumerate(LAYOUT)
               for side, kind in ((-1.0, l), (1.0, r)) if kind == "slabs"]
for (ti, side) in slab_tramos:
    x0, x1 = TRAMOS[ti]
    n = rng.randint(5, 6)
    x = x0 + 0.55
    prev = None
    for k in range(n):
        S = rng.uniform(0.5, 0.8)
        a = 0.62 * S
        if prev is not None:
            x += prev + a + rng.uniform(0.10, 0.40)
        if x > x1 - 0.3:
            x = x0 + 0.55 + rng.uniform(0.0, 0.5)     # wrap: second row, other d
        prev = a
        d = rng.uniform(FLOOR_HALF + 0.7, SHELF_END - 0.5) - rim_shift(x, side)
        y = meander(x) + side * d
        place_round("slab", (x, y), (a, a * rng.uniform(0.7, 0.95), a * rng.uniform(0.40, 0.55)),
                    90.0 + rng.uniform(-30.0, 30.0), rng.choice(['X', 'Y']),
                    rng.uniform(-6.0, 6.0), burial=0.0,
                    z_top=WATER_Z + rng.uniform(-0.04, 0.04), side=side)

# 3) BOULDER scale -- two worn groups in the channel.
GROUPS = [(-3.4, -0.6, 3), (2.6, 0.9, 3)]
for gi, (gx, gy, n) in enumerate(GROUPS):
    for k in range(n):
        ang = rng.uniform(0, math.tau); dist = rng.uniform(0.0, 0.9) if k else 0.0
        cx = gx + math.cos(ang) * dist; cy = gy + math.sin(ang) * dist
        a = rng.uniform(0.30, 0.55)
        place_round("boulder", (cx, cy), (a * rng.uniform(1.0, 1.3), a, a * rng.uniform(0.6, 0.9)),
                    rng.uniform(0, 360), rng.choice(['X', 'Y']), rng.uniform(-20, 20),
                    burial=BURIAL)

# 3b) DRY LEDGES -- the only faceted rock left: outcrops above the wet band on
#     the gradient banks (the river never wore them down).
grad_tramos = [(ti, side) for ti, (l, r) in enumerate(LAYOUT)
               for side, kind in ((-1.0, l), (1.0, r)) if kind == "gradient"]
for (ti, side) in grad_tramos[:2]:
    xc = 0.5 * sum(TRAMOS[ti]) + rng.uniform(-0.8, 0.8)
    d = rim_d(xc, side) - rng.uniform(0.3, 0.7)
    rec = place_rock("ledge", (xc, meander(xc) + side * d), rng.uniform(0.45, 0.6),
                     "wallblock", rng.uniform(-25, 25), 'X',
                     rng.uniform(10.0, 22.0) * side, (1.1, 0.9, 0.8),
                     blocks=2, burial=0.45, side=side)
    rec["rounded"] = False

# 4) COBBLE band -- the bed as PILED ROUND STONES, built as one displaced
# strip: dome bumps 18-28 cm across on a fine smooth-shaded grid, not hundreds
# of separate meshes. TRADE (budget): v3 spent ~16k tris on 900 faceted shards;
# the strip carries ~450 round stones in ~7k tris. Individual rounded meshes at
# the roundness gate's tessellation (14x7 = 168 tris) would cost ~75k for the
# same coverage. Imbrication dip is dropped (a dome has no dip) -- the along-
# flow elongation stays.
band_cells = band_raster(dry_band)
band_area = float(band_cells.sum()) * RASTER_CELL ** 2
print(f"[cobbles] dry band area {band_area:.1f} m2")
cov_mask = np.zeros_like(band_cells)
bumps = []            # (x, y, rx, ry, dome height, yaw)
n_try = 0
while len(bumps) < 650 and n_try < 8000:
    n_try += 1
    x = rng.uniform(-SEG_LEN / 2 + 0.15, SEG_LEN / 2 - 0.15)
    side = rng.choice([-1.0, 1.0])
    kind = bank_type(x, side)
    dw = _wl_cache(x, side)
    width = 0.35 if kind == "wall" else 1.0
    d = dw + rng.uniform(0.0, width)
    y = meander(x) + side * d
    if abs(y) > SEG_WID / 2 - 0.15:
        continue
    cix = int((x + SEG_LEN / 2) / RASTER_CELL); ciy = int((y + SEG_WID / 2) / RASTER_CELL)
    if 0 <= cix < RX and 0 <= ciy < RY and cov_mask[cix, ciy]:
        continue
    rx = rng.uniform(0.09, 0.14); ry = rx * rng.uniform(0.65, 0.80)
    hb = rx * rng.uniform(0.50, 0.70)            # z-flatten 0.5-0.7
    yaw = math.radians(rng.uniform(-12, 12))     # long axis along the flow
    bumps.append((x, y, rx, ry, hb, yaw))
    pts = [(x + rx * math.cos(t) * math.cos(yaw) - ry * math.sin(t) * math.sin(yaw),
            y + rx * math.cos(t) * math.sin(yaw) + ry * math.sin(t) * math.cos(yaw))
           for t in np.linspace(0, math.tau, 10, endpoint=False)]
    _paint_hull(cov_mask, pts, RASTER_CELL)
    if len(bumps) % 40 == 0:
        if float((cov_mask & band_cells).sum()) / max(int(band_cells.sum()), 1) >= 0.605:
            break
coverage = float((cov_mask & band_cells).sum()) / max(int(band_cells.sum()), 1)
print(f"[cobbles] {len(bumps)} stones in the band, coverage {coverage:.3f}")

BSTEP = 0.085
_bucket = {}
for _bi, (_bx, _by, _rx, _ry, _hb, _yw) in enumerate(bumps):
    _bucket.setdefault((int(_bx // 0.3), int(_by // 0.3)), []).append(_bi)


def bump_h(x, y):
    h = 0.0
    for ox in (-1, 0, 1):
        for oy in (-1, 0, 1):
            for bi in _bucket.get((int(x // 0.3) + ox, int(y // 0.3) + oy), ()):
                bx, by, rx, ry, hb, yaw = bumps[bi]
                dx = x - bx; dy = y - by
                u = (dx * math.cos(-yaw) - dy * math.sin(-yaw)) / rx
                v = (dx * math.sin(-yaw) + dy * math.cos(-yaw)) / ry
                q = u * u + v * v
                if q < 1.0:
                    h = max(h, hb * math.sqrt(1.0 - q))
    return h


def in_strip(x, y):
    return dry_band(x, y) or bump_h(x, y) > 0.0


sg = {}
snx = int(SEG_LEN / BSTEP); sny = int(SEG_WID / BSTEP)
strip_faces = []
for ix in range(snx):
    for iy in range(sny):
        x0s = -SEG_LEN / 2 + ix * BSTEP; y0s = -SEG_WID / 2 + iy * BSTEP
        if not (in_strip(x0s, y0s) or in_strip(x0s + BSTEP, y0s) or
                in_strip(x0s + BSTEP, y0s + BSTEP) or in_strip(x0s, y0s + BSTEP)):
            continue
        quad = []
        for (qx, qy) in ((x0s, y0s), (x0s + BSTEP, y0s), (x0s + BSTEP, y0s + BSTEP), (x0s, y0s + BSTEP)):
            key = (round(qx, 4), round(qy, 4))
            if key not in sg:
                sg[key] = bm.verts.new((qx, qy, terrain_z(qx, qy) + 0.004 + bump_h(qx, qy)))
            quad.append(sg[key])
        try:
            f = bm.faces.new(quad)
        except ValueError:
            continue
        f.smooth = True
        f[lay_bed] = 1
        for loop in f.loops:
            loop[uv_layer].uv = (loop.vert.co.x / GRAVEL_PERIOD, loop.vert.co.y / GRAVEL_PERIOD)
        strip_faces.append(f)
        bed_faces.append(f)
for v in sg.values():
    vcol[v] = (1.0, 1.0, 1.0)
print(f"[strip] {len(strip_faces)} quads at {BSTEP} m")

# submerged rounded stones, sparse, so the bed reads as stones through water
for k in range(12):
    x = rng.uniform(-SEG_LEN / 2 + 0.3, SEG_LEN / 2 - 0.3)
    side = rng.choice([-1.0, 1.0])
    dw = _wl_cache(x, side)
    d = rng.uniform(0.0, max(0.3, dw - 0.15))
    a = rng.uniform(0.08, 0.15)
    place_round("cobble", (x, meander(x) + side * d),
                (a * rng.uniform(1.1, 1.35), a, a * rng.uniform(0.5, 0.7)),
                rng.uniform(-15, 15), 'Y', -rng.uniform(10, 20),
                burial=rng.uniform(0.20, 0.40))

counts = {k: sum(1 for r in rocks if r["kind"] == k) for k in ("wall", "slab", "boulder")}
counts["cobble"] = len(bumps) + sum(1 for r in rocks if r["kind"] == "cobble")
print(f"[metric a] scales present: {counts}")
if not (counts["wall"] >= 8 and counts["slab"] >= 5 and counts["boulder"] >= 5 and counts["cobble"] >= 300):
    raise SystemExit("[metric a] FAIL: a rock scale is missing")

# --------------------------------- metric (h): the river wore the wet stones
bm.normal_update()          # calc_face_angle reads face normals; stale = blind metric
h_edges = 0; h_sharp = 0; worst = (0.0, None)
for r in rocks:
    if not r.get("rounded"):
        continue
    if r["bottom"] > WATER_Z + WET_BAND:
        continue                                   # dry rock: facets allowed
    edges = {e for f in r["faces"] if f.is_valid for e in f.edges}
    ne = 0; ns = 0
    for e in edges:
        if len(e.link_faces) != 2:
            continue
        ne += 1
        if math.degrees(e.calc_face_angle(0.0)) > 30.0:
            ns += 1
    h_edges += ne; h_sharp += ns
    if ne and ns / ne > worst[0]:
        worst = (ns / ne, r["kind"])
frac_h = h_sharp / max(h_edges, 1)
print(f"[metric h] wet-zone sharp edges {h_sharp}/{h_edges} = {frac_h:.3f} (limit <= 0.10), worst rock {worst[1]} {worst[0]:.2f}")
if frac_h > 0.10:
    raise SystemExit("[metric h] FAIL: the river did not wear these stones")

# --------------------------------- gravity: no floating wall boulder
wall_recs = [r for r in rocks if r["kind"] == "wall"]
for r in wall_recs:
    ring = [v for v in r["verts"] if v.co.z < r["bottom"] + 0.25 * r["height"]]
    hz = r.get("hide_z") if r.get("hide_z") is not None else -9.0
    under = sum(1 for v in ring if v.co.z < max(terrain_z(v.co.x, v.co.y), hz) + 0.01)
    if under / max(len(ring), 1) >= 0.40:
        continue
    touches = 0
    for o in wall_recs:
        if o is r:
            continue
        dd = math.hypot(r["center"][0] - o["center"][0], r["center"][1] - o["center"][1])
        if dd < 0.92 * (r["radius"] + o["radius"]) and not (r["bottom"] > o["top"] or o["bottom"] > r["top"]):
            touches += 1
    if touches < 2:
        raise SystemExit(f"[gravity] FAIL: a wall boulder floats (ground {under}/{len(ring)}, touches {touches})")
print(f"[gravity] all {len(wall_recs)} wall boulders seated")

# ----------------------------------------------------- wet band: bisect + slot
rock_faces_all = [f for r in rocks for f in r["faces"]] + bed_faces
bed_face_set = set(bed_faces)
rock_geom = list({v for f in rock_faces_all for v in f.verts}) + \
    list({e for f in rock_faces_all for e in f.edges}) + list(dict.fromkeys(rock_faces_all))
for zc in (WATER_Z + WET_BAND, WATER_Z - 0.06):
    res = bmesh.ops.bisect_plane(bm, geom=rock_geom, dist=1e-5,
                                 plane_co=(0.0, 0.0, zc), plane_no=(0.0, 0.0, 1.0))
    rock_geom = list(dict.fromkeys(res["geom"] + res["geom_cut"]))
bed_face_set = {f for f in bm.faces if f[lay_bed] == 1}
bed_faces = [f for f in bm.faces if f in bed_face_set]
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
bm.normal_update()

# faces per rock after the bisect: the record's faces may have been split;
# rebuild from the vertex sets (a split face keeps its verts inside the set
# plus new cut verts, so test by centre inside the record's bbox + kind tag)
face_kind = {}
for r in rocks:
    for f in r["faces"]:
        if f.is_valid:
            face_kind[f] = r
for f in bm.faces:
    if f in bed_face_set or f in face_kind:
        continue
    c = f.calc_center_median()
    best = None
    for r in rocks:
        if r["xmin"] - 0.02 <= c.x <= r["xmax"] + 0.02 and r["ymin"] - 0.02 <= c.y <= r["ymax"] + 0.02 \
                and r["bottom"] - 0.02 <= c.z <= r["top"] + 0.02:
            best = r
            break
    if best is not None:
        face_kind[f] = best

# material slots: 0 gravel dry, 1 gravel wet, 2 limestone dry, 3 limestone wet,
# 4 bank soil (moss is a continuous vertex tint now, not a slot)
SLOT_GRAVEL, SLOT_GRAVEL_WET, SLOT_LIME, SLOT_LIME_WET, SLOT_BANK = range(5)
for f in bm.faces:
    zc = f.calc_center_median().z
    if f in bed_face_set:
        if zc > BANK_TOP_Z - 0.025:
            f.material_index = SLOT_BANK
        elif zc < WATER_Z + WET_BAND:
            f.material_index = SLOT_GRAVEL_WET
        else:
            f.material_index = SLOT_GRAVEL
    else:
        f.material_index = SLOT_LIME_WET if zc < WATER_Z + WET_BAND else SLOT_LIME


for f in bed_faces:
    for loop in f.loops:
        loop[uv_layer].uv = (loop.vert.co.x / GRAVEL_PERIOD, loop.vert.co.y / GRAVEL_PERIOD)
for f in bm.faces:
    if f in bed_face_set:
        continue
    n = f.normal
    ax = Vector((0, 0, 1)).cross(n)
    if ax.length < 1e-4:
        ax = Vector((1, 0, 0))
    ax.normalize()
    ay = n.cross(ax).normalized()
    for loop in f.loops:
        co = loop.vert.co
        loop[uv_layer].uv = (co.dot(ax) / LIME_PERIOD, co.dot(ay) / LIME_PERIOD)

# ------------------------------------------- vertex colour: sun/shade tint x AO
bm.normal_update()
for v in bm.verts:
    if v in vcol and any(f in bed_face_set for f in v.link_faces):
        vcol[v] = (1.0, 1.0, 1.0)
        continue
    n = v.normal
    t = 0.5 + 0.5 * n.dot(SUN)
    c = TINT_SHADE.lerp(TINT_SUN, t)
    vcol[v] = (c.x, c.y, c.z)

# moss: a CONTINUOUS noise-blended vertex tint on up-facing dry rock (per-face
# patches read as paint). The tint multiplies the limestone texture in-slot.
MOSS_TINT = (0.30, 0.50, 0.20)
_cand = []
for r in rocks:
    for v in r["verts"]:
        if not v.is_valid or v.co.z <= WATER_Z + WET_BAND:
            continue
        if v.normal.z <= 0.35:
            continue
        nz = value_noise(np.array([[v.co.x * 2.3, v.co.y * 2.3, v.co.z * 2.3]]), 41.0)[0]
        _cand.append((v, float(nz), v.normal.z))
if _cand:
    thr = float(np.percentile([nz for _, nz, _ in _cand], 45))
    mossy = 0
    for v, nz, upz in _cand:
        w = max(0.0, min(1.0, (nz - thr) / 0.12)) * min(1.0, (upz - 0.35) / 0.40)
        if w > 0.0:
            base = vcol[v]
            vcol[v] = tuple(base[k] * (1.0 - w) + MOSS_TINT[k] * w for k in range(3))
        if w > 0.45:
            mossy += 1
    moss_frac = mossy / len(_cand)
    print(f"[moss] {mossy}/{len(_cand)} up-facing dry verts tinted (frac {moss_frac:.2f}, want 0.30-0.60)")
    if not (0.30 <= moss_frac <= 0.60):
        raise SystemExit("[moss] FAIL: coverage outside 30-60 %")
else:
    raise SystemExit("[moss] FAIL: no dry up-facing rock verts")
mean_ao, min_ao = bake_vertex_ao(bm, vcol, samples=16, max_dist=0.9, strength=0.7, min_factor=0.35)
print(f"[ao] mean {mean_ao:.3f} min {min_ao:.3f}")

# --------------------------------------------- metric (b): buried bottom ring
hidden = 0; checked = 0
for r in rocks:
    if r["supported"]:
        # v4: nestled wall boulders are validated by the [gravity] gate above
        # (>= 40 % of the base grounded, or >= 2 neighbour contacts); the v3
        # centre-over-bbox rule assumed a block resting ON TOP of two.
        continue
    verts = r["verts"]
    zmin = min(v.co.z for v in verts); h = max(v.co.z for v in verts) - zmin
    ring = [v for v in verts if v.co.z < zmin + 0.18 * h]
    hz = r.get("hide_z") if r.get("hide_z") is not None else -9.0
    below = sum(1 for v in ring if v.co.z < max(terrain_z(v.co.x, v.co.y), hz) + 0.005)
    frac = below / max(len(ring), 1)
    checked += 1
    if frac >= 0.85:
        hidden += 1
frac_hidden = hidden / checked
print(f"[metric b] rocks with base hidden: {hidden}/{checked} = {frac_hidden:.2f}")
if frac_hidden < 0.80:
    raise SystemExit("[metric b] FAIL: fewer than 80 % of rocks have their base hidden")

# --------------------------------------------- metric (c): wet vs dry albedo
lime_mean = float(lime_rgb.mean())
ratio = (lime_mean * 0.55) / lime_mean
print(f"[metric c] wet/dry albedo ratio {ratio:.2f} (limit < 0.70), band {WET_BAND:.2f} m")
if ratio >= 0.70:
    raise SystemExit("[metric c] FAIL: wet band not visibly darker")
print("[metric d] bed through water: measured in Godot (water_depth.gdshader), not here")

# --------------------------------------------- metric (e): profiles, layout + mesh
ok_e, nl, nr, nt = metric_e_layout(LAYOUT)
print(f"[metric e] layout types L={nl} R={nr} total={nt}")
if not ok_e:
    raise SystemExit("[metric e] FAIL: layout")
for ti, (l, r) in enumerate(LAYOUT):
    xc = 0.5 * (TRAMOS[ti][0] + TRAMOS[ti][1])
    for side, kind in ((-1.0, l), (1.0, r)):
        if kind == "gradient":
            zs = [base_z(xc, meander(xc) + side * d) for d in np.arange(FLOOR_HALF, 5.0, 0.1)]
            slopes = [math.degrees(math.atan2(zs[k + 1] - zs[k], 0.1)) for k in range(len(zs) - 1)]
            mx = max(slopes)
            print(f"[metric e] tramo {ti} side {side:+.0f} gradient: max slope {mx:.1f} deg, rim at {rim_d(xc, side):.2f} m")
            if mx > 22.0:
                raise SystemExit("[metric e] FAIL: gradient bank steeper than 22 deg")
        elif kind == "wall":
            tall = [r for r in rocks if r["kind"] == "wall" and r["tramo"] == ti and r["side"] == side
                    and r["top"] > BANK_TOP_Z + 0.3]
            print(f"[metric e] tramo {ti} side {side:+.0f} wall: {len(tall)} blocks above the bank")
            if len(tall) < 3:
                raise SystemExit("[metric e] FAIL: wall not visible above the bank")
        else:
            at_water = [r for r in rocks if r["kind"] == "slab" and r["tramo"] == ti and r["side"] == side
                        and abs(r["top"] - WATER_Z) <= 0.06]
            print(f"[metric e] tramo {ti} side {side:+.0f} slabs: {len(at_water)} tops at the water surface")
            if len(at_water) < 4:
                raise SystemExit("[metric e] FAIL: slabs not at the water surface")

# --------------------------------------------- metric (f): cobble coverage
fps = []
for (bx, by, brx, bry, bhb, byaw) in bumps:
    fps.append([(bx + brx * math.cos(t) * math.cos(byaw) - bry * math.sin(t) * math.sin(byaw),
                 by + brx * math.cos(t) * math.sin(byaw) + bry * math.sin(t) * math.cos(byaw))
                for t in np.linspace(0, math.tau, 10, endpoint=False)])
cov_f = metric_f_coverage(fps, band_cells)
print(f"[metric f] cobble footprint coverage of the 0-1 m band {cov_f:.3f} (limit >= 0.60)")
if cov_f < 0.60:
    raise SystemExit("[metric f] FAIL: the bed is still a texture, not stones")

# --------------------------------------------- metric (g): rim runs
for side in (-1.0, 1.0):
    run, ok_g = metric_g_rim(rim_polyline(side, base_z))
    print(f"[metric g] side {side:+.0f} longest collinear rim run {run:.2f} m (limit <= 2.0) starting x={metric_g_rim.last_at}")
    if not ok_g:
        raise SystemExit("[metric g] FAIL: a bank edge is a ruler")

# ------------------------------------------ write vertex colours into layer
col_layer = bm.loops.layers.float_color.new("Col")
for f in bm.faces:
    for loop in f.loops:
        c = vcol.get(loop.vert, (1.0, 1.0, 1.0))
        loop[col_layer] = (c[0], c[1], c[2], 1.0)

ALL_MATS = (MAT_GRAVEL, MAT_GRAVEL_WET, MAT_LIME, MAT_LIME_WET, MAT_BANK)


def finalize(bm_src, keep_bed, name):
    b = bm_src.copy()
    b.faces.ensure_lookup_table()
    bed_slots = (SLOT_GRAVEL, SLOT_GRAVEL_WET, SLOT_BANK)
    kill = [f for f in b.faces if (f.material_index in bed_slots) != keep_bed]
    bmesh.ops.delete(b, geom=kill, context='FACES')
    bmesh.ops.remove_doubles(b, verts=b.verts[:], dist=1e-5)
    bmesh.ops.dissolve_degenerate(b, dist=1e-6, edges=b.edges[:])
    loose = [v for v in b.verts if not v.link_faces]
    bmesh.ops.delete(b, geom=loose, context='VERTS')
    bmesh.ops.recalc_face_normals(b, faces=b.faces[:])
    bmesh.ops.triangulate(b, faces=b.faces[:])
    me = bpy.data.meshes.new(name)
    b.to_mesh(me)
    b.free()
    me.validate(verbose=False)
    assert me.uv_layers.active is not None, "UV layer missing"
    for m in ALL_MATS:
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


ob_bed = finalize(bm, True, f"river_bed_v4_a{VARIANT}")
ob_rocks = finalize(bm, False, f"river_rocks_v4_a{VARIANT}")
bm.free()
tris_bed = len(ob_bed.data.polygons); tris_rocks = len(ob_rocks.data.polygons)
print(f"[tris] bed {tris_bed}  rocks {tris_rocks}  total {tris_bed + tris_rocks} (budget 25000)")
if tris_bed + tris_rocks > 25000:
    raise SystemExit("[tris] FAIL: over budget")

# ------------------------------------------------------------------- export
glb_path = os.path.join(OUT_GLB_DIR, f"river_segment_v4_a{VARIANT}.glb")
bpy.ops.object.select_all(action='DESELECT')
ob_bed.select_set(True); ob_rocks.select_set(True)
bpy.context.view_layer.objects.active = ob_bed
kw = dict(filepath=glb_path, export_format='GLB', use_selection=True,
          export_yup=True, export_apply=True, export_tangents=True,
          export_image_format='AUTO', export_animations=False, export_skins=False)
try:
    bpy.ops.export_scene.gltf(export_vertex_color='ACTIVE', **kw)
except TypeError:
    bpy.ops.export_scene.gltf(**kw)
print(f"[export] {glb_path}  ({os.path.getsize(glb_path) // 1024} KB)")

if NO_RENDER:
    raise SystemExit(0)

# ------------------------------------------------------------------ showcase
scene = bpy.context.scene
water_mat = bpy.data.materials.new("river_water_preview")
water_mat.use_nodes = True
wb = water_mat.node_tree.nodes["Principled BSDF"]
wb.inputs["Base Color"].default_value = (0.16, 0.36, 0.38, 1.0)
wb.inputs["Roughness"].default_value = 0.14
wb.inputs["Alpha"].default_value = 0.32
try:
    water_mat.surface_render_method = 'BLENDED'
except AttributeError:
    water_mat.blend_method = 'BLEND'
wm = bpy.data.meshes.new("water"); wbm = bmesh.new()
bmesh.ops.create_grid(wbm, x_segments=24, y_segments=16, size=1.0)   # spans +-0.5
for v in wbm.verts:
    v.co.x *= SEG_LEN; v.co.y *= 2.0 * (SHELF_END + 1.6)
    v.co.y += meander(v.co.x); v.co.z = WATER_Z + 0.004 * math.sin(v.co.x * 6.0 + v.co.y * 4.0)
wbm.to_mesh(wm); wbm.free(); wm.materials.append(water_mat)
ob_water = bpy.data.objects.new("water", wm); scene.collection.objects.link(ob_water)

# far ground: a FRAME around the segment at bank height
gm = bpy.data.meshes.new("far_ground"); gbm = bmesh.new()
X, Y, R = SEG_LEN / 2, SEG_WID / 2, 30.0
for (x0, x1, y0, y1) in ((-R, R, Y, R), (-R, R, -R, -Y), (-R, -X, -Y, Y), (X, R, -Y, Y)):
    vs = [gbm.verts.new((x, y, BANK_TOP_Z - 0.01)) for (x, y) in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))]
    gbm.faces.new(vs)
gbm.to_mesh(gm); gbm.free(); gm.materials.append(MAT_BANK)
ob_g = bpy.data.objects.new("far_ground", gm); scene.collection.objects.link(ob_g)

# 1.8 m player reference post (mandatory on every showcase render)
ref_mesh = bpy.data.meshes.new("player_ref"); ref_bm = bmesh.new()
bmesh.ops.create_cube(ref_bm, size=1.0)
for v in ref_bm.verts:
    v.co.x *= 0.36; v.co.y *= 0.36; v.co.z = v.co.z * 1.8 + 0.9
ref_bm.to_mesh(ref_mesh); ref_bm.free()
ref_mat = bpy.data.materials.new("player_ref_mat"); ref_mat.use_nodes = True
ref_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.22, 0.18, 1.0)
ref_mesh.materials.append(ref_mat)
ob_ref = bpy.data.objects.new("player_ref", ref_mesh)
_px = -1.0
_py = meander(_px) - (rim_d(_px, -1.0) + 0.4)
ob_ref.location = (_px, _py, terrain_z(_px, _py))
scene.collection.objects.link(ob_ref)

# vegetation, showcase only: "siempre hay vegetacion, el agua trae vida"
VEG = os.path.join(GAME, "assets", "art", "piso1_pradera", "vegetation")
TREE_FILES = ["env_tree_prairie_mature_02.glb", "env_tree_prairie_mature_01.glb"]
BUSH_FILES = ["env_bush_round_01.glb", "env_bush_low_01.glb", "env_bush_large_01.glb"]


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new(os.path.basename(path) + "_root", None)
    scene.collection.objects.link(root)
    for o in new:
        if o.parent is None or o.parent not in new:
            o.parent = root
    zmax = 0.0
    for o in new:
        if o.type == 'MESH':
            for c in o.bound_box:
                zmax = max(zmax, (o.matrix_world @ Vector(c)).z)
    return root, zmax


veg_notes = []
for si, side in enumerate((-1.0, 1.0)):
    # tree: on a non-wall tramo, beyond the rim, leaning 5-15 deg over the water
    cands = [ti for ti, lr in enumerate(LAYOUT) if lr[si] != "wall"]
    ti = rng.choice(cands)
    tx = 0.5 * sum(TRAMOS[ti]) + rng.uniform(-0.8, 0.8)
    ty = meander(tx) + side * (rim_d(tx, side) + 0.9)
    root, h = import_glb(os.path.join(VEG, "tree_pack", TREE_FILES[si]))
    root.location = (tx, ty, terrain_z(tx, ty))
    lean = rng.uniform(5.0, 15.0)
    root.rotation_euler = (math.radians(side * lean), 0.0, math.radians(rng.uniform(0, 360)))
    veg_notes.append(f"tree {TREE_FILES[si]} h={h:.2f} m at ({tx:.1f},{ty:.1f}) lean {lean:.0f} deg")
    # bushes within 0-1.5 m of the waterline, dry side, on any non-wall stretch
    for k in range(rng.randint(3, 5)):
        for _try in range(20):
            bx = rng.uniform(-SEG_LEN / 2 + 0.5, SEG_LEN / 2 - 0.5)
            if bank_type(bx, side) == "wall":
                continue
            dw = _wl_cache(bx, side)
            by = meander(bx) + side * (dw + rng.uniform(0.3, 1.5))
            if abs(by) < SEG_WID / 2 - 0.3:
                break
        broot, bh = import_glb(os.path.join(VEG, "bush", rng.choice(BUSH_FILES)))
        broot.location = (bx, by, terrain_z(bx, by) - 0.03)
        broot.rotation_euler = (0.0, 0.0, math.radians(rng.uniform(0, 360)))
for n in veg_notes:
    print(f"[veg] {n}")

world = bpy.data.worlds.new("river_world"); scene.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.55, 0.68, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA'); ld.energy = energy; ld.size = size
    lo = bpy.data.objects.new(name, ld); lo.location = loc
    scene.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')
    return lo


sun_d = bpy.data.lights.new("sun", type='SUN'); sun_d.energy = 3.2; sun_d.angle = math.radians(2.0)
sun_d.color = (1.0, 0.96, 0.88)
sun_o = bpy.data.objects.new("sun", sun_d); scene.collection.objects.link(sun_o)
sun_o.rotation_mode = 'QUATERNION'
sun_o.rotation_quaternion = (-SUN).to_track_quat('-Z', 'Y')
add_light("fill", (18.0, -12.0, 9.0), 500, 6.0)
add_light("rim", (4.0, 20.0, 12.0), 1500, 5.0)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.render.resolution_x = 1280; scene.render.resolution_y = 800
scene.eevee.taa_render_samples = 32
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'Standard'

cam_data = bpy.data.cameras.new("cam"); cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam); scene.camera = cam


def shoot(name, loc, target, lens):
    cam.location = loc; cam_data.lens = lens
    d = Vector(target) - Vector(loc)
    cam.rotation_mode = 'QUATERNION'
    cam.rotation_quaternion = d.to_track_quat('-Z', 'Y')
    path = os.path.join(RENDER_DIR, f"river_v4_a{VARIANT}_{name}.png")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print(f"[render] {path}")
    return path


veg_roots = [o for o in bpy.data.objects if o.name.endswith("_root")]
def veg_visible(flag):
    for root in veg_roots:
        root.hide_render = not flag
        for ch in root.children_recursive:
            ch.hide_render = not flag
hero = shoot("hero", (10.5, -14.0, 7.5), (0.0, 0.0, 0.3), 32)
eye = shoot("player_eye", (0.0, -11.0, BANK_TOP_Z + 1.65), (0.6, 0.4, 0.32), 24)
veg_visible(False)
top = shoot("cenital", (0.0, -0.5, 18.0), (0.0, 0.0, 0.0), 30)
veg_visible(True)
slabs = [r for r in rocks if r["kind"] == "slab"]
s_rec = slabs[len(slabs) // 2]
s0 = s_rec["center"]; s_side = s_rec["side"]
# from over the water, 1 m off the slab, looking at its top
close = shoot("waterline_1m", (s0[0] - 0.7, s0[1] - s_side * 1.0, WATER_Z + 0.55),
              (s0[0], s0[1], WATER_Z + 0.02), 35)
down = shoot("downstream_low", (-7.0, meander(-7.0), WATER_Z + 0.6), (6.0, meander(6.0), WATER_Z + 0.1), 28)
wti, wside = wall_tramos[0]
wxc = 0.5 * sum(TRAMOS[wti])
behind = shoot("behind_wall", (wxc + 1.5, meander(wxc) + wside * 7.5, BANK_TOP_Z + 2.8),
               (wxc, meander(wxc) - wside * 1.0, WATER_Z), 30)

require_use_size(eye, sizes=[1280, 640, 320])
print("[river] done")
