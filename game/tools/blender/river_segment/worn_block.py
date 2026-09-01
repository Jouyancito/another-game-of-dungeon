# worn_block.py -- the v5 river stone (fracture block worn selectively) +
# the shared textured material, extracted from build_river_segment.py so the
# rock kit builder can reuse them without importing the whole scene build.
# CALLER CONTRACT: sys.path must already include the motor recetas dir and
# this dir (biome_facet, texture_bake) before importing this module.
import math

import bmesh
import bpy
import numpy as np

from biome_facet import _convex_chunk  # noqa: E402
from texture_bake import fbm  # noqa: E402


def make_worn_block(radius, wear, rng2, cuts=7, bedding=1, elongate=1.25, flatten=0.85,
                    subdiv_rounds=2, subth=0.15, passes=4, jitter=0.08, nscale=5.0):
    """A river stone per Joan's v5 correction: an angular fracture block worn
    SELECTIVELY. Probed (probe_wear2): bevel-based wear leaves its own sharp
    corner patches (h1 stuck at 0.3+); this version densifies the block and
    Laplacian-smooths ONLY the most exposed vertices (dihedral-ranked, the
    `wear` fraction), so worn shoulders go round while face interiors stay
    planar, get flat shading and a roughness jitter. 1-2 crack seams survive
    unsanded. Flats AND rounds AND cracks on the same stone."""
    coords, faces_idx = _convex_chunk(rng2, radius, cuts=cuts, bedding=bedding,
                                      bedding_jitter=0.12, elongate=elongate,
                                      flatten=flatten)
    tb = bmesh.new()
    vs = [tb.verts.new(c) for c in coords]
    for idx in faces_idx:
        try:
            tb.faces.new([vs[k] for k in idx])
        except ValueError:
            continue
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces[:])
    tb.normal_update()
    for f in tb.faces:
        f.smooth = False
    # 1-2 crack seams along the longest edges: thin bevel strip pushed inward,
    # protected from all later wear. Seam membership ALSO goes in a vert int
    # layer (2 = seam): topology ops below realloc verts and dead BMVert refs
    # raise on data access, while a layer survives and subdivision interpolates
    # it (seam-seam midpoint -> 2, seam-face midpoint -> 1 = natural falloff).
    lay_ck = tb.verts.layers.int.new("crackdark")
    crack_verts = set()
    n_crack = rng2.choice([1, 2])
    for _ in range(n_crack):
        cand = [e for e in tb.edges
                if not any(v in crack_verts for v in e.verts)]
        if not cand:
            break
        ce = max(cand, key=lambda e: e.calc_length())
        res = bmesh.ops.bevel(tb, geom=[ce], offset=0.045 * radius,
                              offset_type='OFFSET', segments=1, profile=0.5,
                              affect='EDGES', clamp_overlap=True)
        strip = {v for f in res["faces"] for v in f.verts}
        crack_verts |= strip
        tb.normal_update()
        for v in strip:
            v.co -= v.normal * (0.035 * radius)
            v[lay_ck] = 2
        for f in res["faces"]:
            f.smooth = False
    # densify so the smoothing has room to carve round shoulders
    bmesh.ops.triangulate(tb, faces=tb.faces[:])
    for _ in range(subdiv_rounds):
        longe = [e for e in tb.edges if e.calc_length() > subth * radius]
        if longe:
            bmesh.ops.subdivide_edges(tb, edges=longe, cuts=1, use_grid_fill=False)
        bmesh.ops.triangulate(tb, faces=tb.faces[:])
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces[:])
    tb.normal_update()
    # exposure-ranked selective smoothing: eat the `wear` fraction of the
    # sharpest vertices (max adjacent dihedral), plus one ring for shoulders
    sharp_v = {}
    for v in tb.verts:
        if v in crack_verts:
            continue
        mx = 0.0
        for e in v.link_edges:
            if len(e.link_faces) == 2:
                mx = max(mx, e.calc_face_angle(0.0))
        if mx > math.radians(24):
            sharp_v[v] = mx
    order = sorted(sharp_v, key=lambda v: -sharp_v[v])
    sel = set(order[:int(round(len(order) * min(0.95, wear)))])
    ring = {n2 for v in sel for e in v.link_edges for n2 in e.verts} - crack_verts
    zone = list(sel | ring)
    if zone:
        for _ in range(passes):
            bmesh.ops.smooth_vert(tb, verts=zone, factor=0.55,
                                  use_axis_x=True, use_axis_y=True, use_axis_z=True)
    zset = set(zone)
    for f in tb.faces:
        f.smooth = sum(1 for v in f.verts if v in zset) >= 2
    # the surviving flats are aspera, not polished glass: a small normal jitter
    for v in tb.verts:
        if v in zset or v in crack_verts:
            continue
        # wavelength capped ABSOLUTE: on a 0.9 m wall boulder an r-scaled
        # jitter leaves coherent patches over the 0.02 m2 floor (size effect
        # measured in probe 3: h2 0.71 at r=0.8 vs 0.33 at r=0.5)
        pp = v.co * (nscale / min(radius, 0.45))
        nse = fbm(np.array([[pp.x, pp.y, pp.z]]), 2, 3.0)[0] - 0.5
        # big stones: vert spacing grows with r but the 8 deg patch tolerance
        # does not -- boost amplitude past r=0.5 so the tilt clears it
        amp = jitter * radius * (1.0 + 0.9 * max(0.0, radius - 0.5))
        v.co += v.normal * (nse * amp)
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces[:])
    tb.normal_update()
    # ring falloff: unmarked neighbours of seam verts (live verts, post-ops)
    for v in tb.verts:
        if v[lay_ck] == 2:
            for e in v.link_edges:
                for n2 in e.verts:
                    if n2[lay_ck] == 0:
                        n2[lay_ck] = 1
    return tb


def textured_material(name, albedo_img, normal_img, roughness, use_vcol=True, rough_img=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    if rough_img is not None:
        rt = nt.nodes.new("ShaderNodeTexImage"); rt.image = rough_img
        nt.links.new(rt.outputs["Color"], bsdf.inputs["Roughness"])
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
