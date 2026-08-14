"""gen_char_hair_plates — pelo como placas poligonales conformadas al craneo.

Construido desde `_references/hair_polygon_shells`, grabada por Joan el
2026-08-13. La sintesis de esa referencia dice:

    "El pelo no es una superficie continua ni una textura pintada: es un
     conjunto de PLACAS poligonales anchas -- pocas, grandes, deliberadamente
     facetadas -- que se apoyan sobre el craneo siguiendo su curvatura. Cada
     placa es un mechon. El volumen sale de como se superponen."

Nada aca se coloca escribiendo una coordenada. El cuerpo MPFB trae el grupo de
vertices `scalp` (376 verts), que ES la definicion anatomica de donde nace el
pelo, y cada placa parte de ahi. La direccion de crecimiento sale del remolino
de la coronilla, que es como crece el pelo de verdad: radialmente hacia afuera
desde el punto mas alto.

El resto es raycast. Cada segmento de la placa se apoya sobre la superficie
real de la cabeza, asi que el pelo abraza el craneo en lugar de flotar encima
-- que es el defecto que hace que un peinado poligonal se vea pegoteado.

    blender.exe -b <char.blend> --python gen_char_hair_plates.py -- \
        --obj char_warrior_male_mh --out <dir>
"""

import argparse
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

# Pocas y grandes, no muchas y finas. La referencia es explicita: si hacen
# falta muchas placas para que se vea bien, el enfoque es otro.
N_PLATES = 38
SEGMENTS = 4             # segmentos a lo largo de cada mechon
ROOT_W = 0.036           # semi-ancho en la raiz -- placas ANCHAS, no rastas
TIP_W = 0.016            # semi-ancho en la punta
STEP = 0.017             # avance por segmento sobre la superficie

# Cuanto se peina hacia atras. El pelo crece radial desde el remolino, pero
# despues se PEINA: el nacimiento frontal va hacia atras, no cae sobre la cara.
# Sin esto las placas delanteras bajan rectas sobre los ojos -- que es
# exactamente lo que se acababa de arreglar con la iluminacion.
BACK_BIAS = 1.35
LIFT = 0.0045            # separacion de la piel en la raiz
TIP_LIFT = 0.028         # cuanto se despega la punta
HAIR_HEX = "#241A14"


def eval_mesh(obj):
    """Malla evaluada: las macros de MPFB son shape keys y la malla base no
    las tiene. Medir la base ya costo dos rondas de encuadre en este proyecto."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world.copy()
    verts = [mw @ v.co for v in me.vertices]
    tris = []
    me.calc_loop_triangles()
    for t in me.loop_triangles:
        tris.append(tuple(t.vertices))
    ev.to_mesh_clear()
    return verts, tris


def scalp_points(obj):
    """Puntos del grupo `scalp`, en coordenadas morfeadas.

    Los grupos indexan la malla BASE, asi que hay que apagar la mascara para
    que la evaluada conserve el mismo orden de indices y se puedan cruzar.
    """
    gi = {g.name: g.index for g in obj.vertex_groups}.get("scalp")
    if gi is None:
        raise SystemExit("el objeto no tiene grupo 'scalp'")

    states = [(m, m.show_viewport) for m in obj.modifiers if m.type == "MASK"]
    for m, _ in states:
        m.show_viewport = False
    bpy.context.view_layer.update()
    verts, _tris = eval_mesh(obj)
    for m, was in states:
        m.show_viewport = was
    bpy.context.view_layer.update()

    if len(verts) != len(obj.data.vertices):
        raise SystemExit("indices no alinean: %d evaluados vs %d base"
                         % (len(verts), len(obj.data.vertices)))

    return [verts[v.index] for v in obj.data.vertices
            if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)]


def build_bvh(obj):
    from mathutils.bvhtree import BVHTree
    verts, tris = eval_mesh(obj)
    return BVHTree.FromPolygons(verts, tris, all_triangles=True), verts


def farthest_points(pts, n):
    """Reparto uniforme sobre el cuero cabelludo, sin agrupamientos.

    Un muestreo al azar deja calvas y matas. Este toma el punto mas lejano de
    todos los ya elegidos, que es lo que produce cobertura pareja con pocas
    placas -- justo lo que la referencia pide.
    """
    chosen = [max(pts, key=lambda p: p.z)]     # arranca en la coronilla
    while len(chosen) < n:
        best, bestd = None, -1.0
        for p in pts:
            d = min((p - c).length for c in chosen)
            if d > bestd:
                best, bestd = p, d
        if best is None:
            break
        chosen.append(best)
    return chosen


def surface_point(bvh, p, centre):
    """Baja el punto a la superficie real de la cabeza."""
    d = (p - centre)
    if d.length < 1e-6:
        return p, Vector((0, 0, 1))
    d.normalize()
    hit, nrm, _i, _dist = bvh.ray_cast(centre + d * 0.001, d, 1.0)
    if hit is None:
        return p, d
    return hit, (nrm if nrm.length > 0 else d)


def make_plate(bm, root, flow, bvh, centre, mat_index):
    """Una placa: tira de quads que sigue la superficie y despega en la punta."""
    pos = root.copy()
    dirv = flow.copy()
    ring_prev = None

    for s in range(SEGMENTS + 1):
        t = s / float(SEGMENTS)
        surf, nrm = surface_point(bvh, pos, centre)

        # La raiz se pega al craneo; la punta se separa. Eso es lo que da
        # volumen sin necesidad de mas geometria.
        lift = LIFT + (TIP_LIFT - LIFT) * (t ** 1.6)
        centre_pt = surf + nrm * lift

        side = dirv.cross(nrm)
        if side.length < 1e-6:
            side = Vector((1, 0, 0))
        side.normalize()
        w = ROOT_W + (TIP_W - ROOT_W) * t

        a = bm.verts.new(centre_pt - side * w)
        b = bm.verts.new(centre_pt + side * w)
        if ring_prev is not None:
            f = bm.faces.new((ring_prev[0], ring_prev[1], b, a))
            f.material_index = mat_index
        ring_prev = (a, b)

        # Avanzar sobre la superficie, reproyectando la direccion al plano
        # tangente para que el mechon siga la curva del craneo.
        dirv = (dirv - nrm * dirv.dot(nrm))
        if dirv.length < 1e-6:
            break
        dirv.normalize()
        pos = centre_pt + dirv * STEP


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--plates", type=int, default=N_PLATES)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no existe %r" % args.obj)

    pts = scalp_points(obj)
    print("  scalp: %d verts" % len(pts))

    crown = max(pts, key=lambda p: p.z)
    centre = sum(pts, Vector((0, 0, 0))) / len(pts)
    centre.z -= 0.045                     # dentro del craneo, para el raycast

    bvh, _ = build_bvh(obj)
    roots = farthest_points(pts, args.plates)
    print("  placas: %d  |  coronilla z=%.3f" % (len(roots), crown.z))

    bm = bmesh.new()
    hair_mat_idx = 0
    n_ok = 0
    for r in roots:
        # Direccion de crecimiento: radial desde la coronilla. Es el remolino
        # real -- el pelo no baja recto, se abre desde un punto.
        flow = r - crown
        if flow.length < 0.012:
            flow = Vector((0.0, 1.0, -0.15))    # la coronilla se peina atras
        flow.normalize()

        # Sesgo hacia atras (+Y), mas fuerte cuanto mas adelante nace la placa.
        # Una raiz en la nuca casi no se toca; una en la frente se da vuelta.
        front = max(0.0, -(r - crown).normalized().y)
        flow = (flow + Vector((0.0, 1.0, 0.0)) * BACK_BIAS * front)
        flow.normalize()
        try:
            make_plate(bm, r, flow, bvh, centre, hair_mat_idx)
            n_ok += 1
        except ValueError:
            pass

    me = bpy.data.meshes.new("char_warrior_male_hair")
    bm.to_mesh(me)
    bm.free()
    hair = bpy.data.objects.new("char_warrior_male_hair", me)
    bpy.context.collection.objects.link(hair)
    print("  placas construidas: %d  |  %d verts, %d caras"
          % (n_ok, len(me.vertices), len(me.polygons)))

    # Material: el mismo toon del juego, para que el pelo no se vea de otro
    # mundo que el cuerpo.
    here = os.path.dirname(os.path.abspath(__file__))
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(here, "preview_char_toon.py"))
    toonmod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(toonmod)
    me.materials.append(toonmod.toon_material("toon_hair", HAIR_HEX))

    # Doble cara: una placa es una superficie sin espesor y de atras se veria
    # agujereada.
    me.polygons.foreach_set("use_smooth", [False] * len(me.polygons))
    sol = hair.modifiers.new("solid", "SOLIDIFY")
    sol.thickness = 0.004
    sol.offset = 0.0

    blend = os.path.join(
        os.path.dirname(bpy.data.filepath) or ".", "char_warrior_male_hair.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    print("  blend -> %s" % blend)
    return hair


if __name__ == "__main__":
    main()
