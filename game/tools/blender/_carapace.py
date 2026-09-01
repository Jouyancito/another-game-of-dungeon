"""_carapace -- a chelonian carapace whose scutes ARE the mesh, not a paint job.

WHY THIS SHAPE OF SOLUTION, and what the two previous ones got wrong.

v1 (until 2026-08-24) was a UV sphere with the scute layout computed
analytically and displaced/painted on top. It cannot read as a carapace, for a
structural reason rather than a tuning one: the mesh's edge flow is a sphere's,
so plate boundaries cut polygons in half -- the staircase edges -- and every
growth ring shares the sphere's centre, which renders as a radial sun instead
of thirteen plates. Measured on the deployed model, the relief was 2.2 mm on a
520 mm shell: invisible in silhouette. The whole pattern was colour.

v2 generated each scute as its OWN patch and assembled them. That fixed the
rings and broke the surface: rectangles clipped radially, plus a separate wedge
band, is not a partition of the disc, so the shell came out with holes; and at
5x5 samples per plate the per-face ring tone read as a checkerboard.

v3, here, keeps v2's insight and drops its construction. The carapace is ONE
continuous mesh whose grid lines are PLACED ON the scute boundaries:

  * plate borders are real mesh edges -- nothing to cut, no staircase;
  * neighbouring plates SHARE those vertices -- no holes, by construction;
  * the seam crease is a displacement of shared vertices, so it stays welded;
  * rings are concentric about each plate's own outline, because they are
    computed from where the vertex sits INSIDE ITS OWN PLATE.

That last point is worth stating plainly: a scute's growth rings follow the
plate's OUTLINE, not a circle. Ref `_references/turtle_terrestrial/`: "cada
escudo no es una placa lisa: es una piramide truncada con anillos concentricos
grabados". Deriving the ring index from distance-to-own-border reproduces that
for free, and reproduces it correctly for plates that are not square.

Layout, the one every chelonian shares (`_references/turtle/_synthesis.md`):
    1 nuchal - 5 vertebral - 4 pleural PAIRS - 12 marginal PAIRS

Interior topology: the square [-1,1]^2 is mapped onto the disc with the
elliptical grid mapping, which sends the square's boundary exactly onto the
circle. That is what lets the marginal band weld to the interior -- the band's
inner ring IS the interior's boundary loop, the same vertices, not a copy.
"""
from __future__ import annotations

import math

# No bpy/bmesh import at module scope on purpose: the layout and profile
# functions are pure maths, and the texture bake calls them from plain Python.
# A module that can only be imported inside Blender cannot be probed.


def _partition(n, k):
    """Split n grid rows into k bands, returning the cut indices (0..n)."""
    base, extra = divmod(n, k)
    cuts, acc = [0], 0
    for i in range(k):
        acc += base + (1 if i < extra else 0)
        cuts.append(acc)
    return cuts


class CarapaceSpec:
    """Everything that distinguishes one species' shell from another's."""

    def __init__(self,
                 length=0.52,          # front-to-back, metres
                 width_ratio=0.78,     # width as a fraction of length
                 height_ratio=0.30,    # height as a fraction of length
                 dome_power=0.62,      # <1 flattens the top, >1 peaks it
                 rim_frac=0.82,        # where the marginal band starts
                 vertebral_cols=8,     # grid columns spanned by the midline
                 scute_rise=0.085,      # plate swell, as a fraction of height
                 seam_drop=0.055,      # crease depth at a plate border, ditto
                 rings=5,              # growth annuli per scute
                 ring_groove=0.016,    # groove depth, ditto
                 rim_flare=0.02,       # marginals kick outward at the very edge
                 n=36,                 # grid divisions per side (4n must be a
                      # multiple of 24: 12 marginal PAIRS)
                 band=4,               # rings of quads in the marginal band
                 skirt_drop=0.0,       # how far the rim turns DOWN
                 skirt_rows=2):        # rows of quads in that turn
        self.length = length
        self.width_ratio = width_ratio
        self.height_ratio = height_ratio
        self.dome_power = dome_power
        self.rim_frac = rim_frac
        self.vertebral_cols = vertebral_cols
        self.scute_rise = scute_rise
        self.seam_drop = seam_drop
        self.rings = rings
        self.ring_groove = ring_groove
        self.rim_flare = rim_flare
        self.n = n
        self.band = band
        self.skirt_drop = skirt_drop
        self.skirt_rows = skirt_rows
        # 5 vertebral bands over n rows, and 4 pleural bands over the same n.
        # They do not divide evenly and they do not have to: real vertebrals
        # are not equal either. What matters is that every boundary lands ON a
        # grid line, which is what these integer partitions guarantee.
        self.vert_bands = _partition(n, 5)
        self.pleu_bands = _partition(n, 4)

    @property
    def half_len(self):
        return self.length * 0.5

    @property
    def half_wid(self):
        return self.length * self.width_ratio * 0.5

    @property
    def height(self):
        return self.length * self.height_ratio


def square_to_disc(u, v):
    """Elliptical grid mapping: [-1,1]^2 -> unit disc, square edge -> circle."""
    return (u * math.sqrt(max(0.0, 1.0 - v * v * 0.5)),
            v * math.sqrt(max(0.0, 1.0 - u * u * 0.5)))


def dome_z(spec, du, dv):
    """Height of the bare shell surface over a point of the unit disc."""
    r = min(1.0, math.hypot(du, dv))
    return spec.height * (max(0.0, 1.0 - r * r) ** spec.dome_power)


def plate_of_cell(spec, i, j):
    """Which plate owns grid cell (i, j)? -> (kind, id, i0, i1, j0, j1).

    j runs front(0) to back(n); i runs left to right.
    """
    n = spec.n
    half = (n - spec.vertebral_cols) // 2
    mid0, mid1 = half, n - half
    if mid0 <= i < mid1:
        cuts = spec.vert_bands
        for k in range(len(cuts) - 1):
            if cuts[k] <= j < cuts[k + 1]:
                # The frontmost midline band is the nuchal, not a vertebral.
                kind = "nuchal" if k == 0 else "vertebral"
                return kind, k, mid0, mid1, cuts[k], cuts[k + 1]
    else:
        left = i < mid0
        i0, i1 = (0, mid0) if left else (mid1, n)
        cuts = spec.pleu_bands
        for k in range(len(cuts) - 1):
            if cuts[k] <= j < cuts[k + 1]:
                return ("pleural", k + (0 if left else 4), i0, i1,
                        cuts[k], cuts[k + 1])
    return "vertebral", 0, mid0, mid1, 0, n


def _plate_local(i, j, i0, i1, j0, j1):
    """Position inside a plate: 0 at its border, 0.5 at its middle."""
    s = (i - i0) / max(1, (i1 - i0))
    t = (j - j0) / max(1, (j1 - j0))
    return min(s, 1.0 - s, t, 1.0 - t)


def scute_relief(spec, edge_d):
    """Height above the bare dome, from distance-to-own-border (0..0.5).

    Three things stack, and each is a real property of keratin rather than a
    decoration: the plate swells toward its middle (a scute is a truncated
    pyramid, not a tile), it falls away into the seam at its border, and the
    growth rings cut grooves PARALLEL TO THAT BORDER. Fast season -> raised
    band, lean season -> groove; the grooves are what the eye reads as rings.
    """
    h = spec.height
    e = max(0.0, min(0.5, edge_d)) * 2.0          # 0 at border, 1 at middle
    swell = spec.scute_rise * h * (e ** 0.35)
    seam = -spec.seam_drop * h * math.exp(-e / 0.035)
    ring_phase = ((1.0 - e) * spec.rings) % 1.0
    groove = math.exp(-((ring_phase - 0.5) ** 2) / 0.010)
    rings = -spec.ring_groove * h * groove * min(1.0, e / 0.10)
    return swell + seam + rings


def ring_index(spec, edge_d):
    e = max(0.0, min(0.5, edge_d)) * 2.0
    return int((1.0 - e) * spec.rings)


def build(bm, spec, colour_layer=None, tone_of=None, uv_layer=None):
    """Write the carapace into `bm`. Returns counts for the caller to assert on.

    `tone_of(kind, plate_id, ring)` returns a 0-1 value per face, so the caller
    owns the palette while this module owns the form.
    """
    n, band = spec.n, spec.band

    def place(du, dv, edge_d, flare=0.0):
        x = du * spec.half_wid * (1.0 + flare)
        y = dv * spec.half_len * (1.0 + flare)
        z = dome_z(spec, du, dv) + scute_relief(spec, edge_d)
        return bm.verts.new((x, y, z))

    # ---- interior: the square grid, mapped onto the disc out to rim_frac ----
    grid = {}
    for j in range(n + 1):
        for i in range(n + 1):
            u = (i / n) * 2.0 - 1.0
            v = (j / n) * 2.0 - 1.0
            du, dv = square_to_disc(u, v)
            du, dv = du * spec.rim_frac, dv * spec.rim_frac
            # A vertex on a plate border gets edge_d = 0 from EITHER of the two
            # plates sharing it, so the crease is identical on both sides --
            # which is what keeps the surface watertight instead of split.
            ci, cj = min(i, n - 1), min(j, n - 1)
            _k, _id, i0, i1, j0, j1 = plate_of_cell(spec, ci, cj)
            grid[(i, j)] = place(du, dv, _plate_local(i, j, i0, i1, j0, j1))

    faces = 0
    plates = set()
    for j in range(n):
        for i in range(n):
            kind, pid, i0, i1, j0, j1 = plate_of_cell(spec, i, j)
            plates.add((kind, pid))
            quad = [grid[(i, j)], grid[(i + 1, j)],
                    grid[(i + 1, j + 1)], grid[(i, j + 1)]]
            try:
                f = bm.faces.new(quad)
            except ValueError:
                continue
            faces += 1
            # Evaluated at the face's own centre, not per vertex: a per-vertex
            # ring index on a coarse plate reads as a checkerboard, which is
            # exactly how v2 failed.
            e = _plate_local(i + 0.5, j + 0.5, i0, i1, j0, j1)
            if colour_layer is not None and tone_of is not None:
                tone = tone_of(kind, pid, ring_index(spec, e))
                for loop in f.loops:
                    loop[colour_layer] = (tone, tone, tone, 1.0)
            if uv_layer is not None:
                # The grid IS the UV: the interior maps to [0,0.85]^2 with one
                # texel column per grid column, so the texture can evaluate the
                # SAME plate/ring functions the geometry uses -- at pixel
                # resolution instead of face resolution. That is the whole
                # point of texturing this shell: the rings need more resolution
                # than the mesh has, and always will.
                for c, loop in zip(((i, j), (i + 1, j),
                                    (i + 1, j + 1), (i, j + 1)), f.loops):
                    loop[uv_layer].uv = (c[0] / n * 0.85, c[1] / n * 0.85)

    # ---- marginal band: welded to the interior's own boundary loop ----------
    # Walking the square's perimeter gives the interior's outer ring in order.
    # Those exact vertices are reused, so there is no seam to line up and no
    # gap to leave: the band grows OUT OF the interior rather than beside it.
    perim = ([(i, 0) for i in range(n)] +
             [(n, j) for j in range(n)] +
             [(n - i, n) for i in range(n)] +
             [(0, n - j) for j in range(n)])
    m = len(perim)                      # 4n samples around the rim
    per_marginal = max(1, m // 24)      # 12 pairs = 24 plates

    rows = [[grid[p] for p in perim]]
    for b in range(1, band + 1):
        t = b / band
        r = spec.rim_frac + (1.0 - spec.rim_frac) * t
        row = []
        for k, (i, j) in enumerate(perim):
            u = (i / n) * 2.0 - 1.0
            v = (j / n) * 2.0 - 1.0
            du, dv = square_to_disc(u, v)
            # Distance to this marginal's own border, across the band and
            # along it.
            along = (k % per_marginal) / per_marginal
            edge_d = min(t * 0.5, 0.5 * along, 0.5 * (1.0 - along))
            row.append(place(du * r, dv * r, edge_d,
                             flare=spec.rim_flare * (t ** 2)))
        rows.append(row)

    for b in range(band):
        for k in range(m):
            k2 = (k + 1) % m
            quad = [rows[b][k], rows[b][k2], rows[b + 1][k2], rows[b + 1][k]]
            try:
                f = bm.faces.new(quad)
            except ValueError:
                continue
            faces += 1
            pid = k // per_marginal
            plates.add(("marginal", pid))
            along = (k % per_marginal) / per_marginal
            t = (b + 0.5) / band
            e = min(t * 0.5, along, 1.0 - along)
            if colour_layer is not None and tone_of is not None:
                tone = tone_of("marginal", pid, ring_index(spec, e))
                for loop in f.loops:
                    loop[colour_layer] = (tone, tone, tone, 1.0)
            if uv_layer is not None:
                for c, loop in zip(((k, b), (k2, b), (k2, b + 1), (k, b + 1)),
                                   f.loops):
                    kk = c[0] if c[0] != 0 or k != m - 1 else m
                    loop[uv_layer].uv = (kk / m,
                                         0.87 + 0.13 * (c[1] / band))

    # ---- skirt: the rim turns DOWN to meet the plastron ---------------------
    # Without it the carapace ends as an open ring at z = 0 and the body shows a
    # gap between shell and belly. A real marginal curves under toward the
    # bridge, so the fix is the anatomy again rather than a cap: the last band
    # row is extruded downward and slightly inward.
    if spec.skirt_drop > 0.0:
        prev = rows[-1]
        for srow in range(1, spec.skirt_rows + 1):
            t = srow / spec.skirt_rows
            row = []
            for k, (i, j) in enumerate(perim):
                u = (i / n) * 2.0 - 1.0
                v = (j / n) * 2.0 - 1.0
                du, dv = square_to_disc(u, v)
                shrink = 1.0 - 0.10 * (t ** 2)
                x = du * spec.half_wid * (1.0 + spec.rim_flare) * shrink
                y = dv * spec.half_len * (1.0 + spec.rim_flare) * shrink
                row.append(bm.verts.new((x, y, -spec.skirt_drop * t)))
            for k in range(m):
                k2 = (k + 1) % m
                try:
                    bm.faces.new([prev[k], prev[k2], row[k2], row[k]])
                except ValueError:
                    continue
                faces += 1
                if uv_layer is not None:
                    pass
            prev = row

    return {"scutes": len(plates), "faces": faces, "verts": len(bm.verts)}
