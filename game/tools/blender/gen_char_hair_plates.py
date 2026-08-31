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
LEN_SCALE = 1.0          # multiplicador de largo, seteado desde el CLI
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
    """Reparto uniforme sobre el cuero cabelludo, sin agrupamientos."""
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


def layered_roots(pts, n, layers=3):
    """Raices en CAPAS, de abajo hacia arriba.

    farthest_points() sola reparte las raices lo mas LEJOS posible unas de
    otras -- exactamente lo contrario de solapar. Su comentario original decia
    que eso era "lo que la referencia pide"; la referencia
    (`_references/hair_polygon_shells/_synthesis.md`) dice otra cosa:

        "Se superponen en CAPAS -- la de atras asoma entre las de adelante.
         Ahi esta el volumen."
        "Superposicion en capas con un orden claro: nuca -> laterales -> frente"

    Asi que el scalp se corta en bandas por altura y cada banda se puebla por
    separado. Las de abajo se construyen primero y las de arriba caen encima,
    que es el orden de la referencia y tambien el de una cabeza real: el pelo
    de la coronilla tapa el de la nuca, no al reves.

    Devuelve [(punto, indice_de_capa)], de la capa mas baja a la mas alta.
    """
    zs = [p.z for p in pts]
    lo, hi = min(zs), max(zs)
    span = max(hi - lo, 1e-6)
    bands = [[] for _ in range(layers)]
    for p in pts:
        k = min(int((p.z - lo) / span * layers), layers - 1)
        bands[k].append(p)

    out = []
    for k, band in enumerate(bands):
        if not band:
            continue
        # Reparto proporcional al tamano de la banda, minimo 2 por capa para
        # que ninguna quede representada por una sola placa.
        share = max(2, round(n * len(band) / float(len(pts))))
        for p in farthest_points(band, min(share, len(band))):
            out.append((p, k))
    return out


def plate_width_for_coverage(scalp_area, n_plates, plate_len, overlap=1.7):
    """Semi-ancho que hace falta para CUBRIR, calculado -- no elegido.

    El pelo del guerrero salio agujereado porque el ancho era un numero puesto
    a mano (ROOT_W = 0.036) sin relacion con el area a cubrir. Si N placas de
    largo L y ancho 2W tienen que tapar un area A con factor de solape S:

        N * L * 2W >= A * S   ->   W >= A * S / (2 * N * L)

    `overlap` 1.7 = 70% mas de superficie de placa que de craneo. Debajo de
    ~1.4 el pelo se abre en cuanto la cabeza se curva, porque una placa plana
    sobre una superficie convexa cubre menos de lo que mide.
    """
    if n_plates <= 0 or plate_len <= 0:
        return ROOT_W
    return (scalp_area * overlap) / (2.0 * n_plates * plate_len)


def scalp_area(obj, gname="scalp"):
    """Area real del grupo de vertices, sumando las caras que le pertenecen.

    SILENCIA EL MASK ANTES DE EVALUAR, igual que scalp_points(). Sin eso la
    malla evaluada trae 13380 verts contra 19158 de la base, los indices no
    mapean, y la funcion caia SIEMPRE -- en toda corrida real, no en un caso
    raro -- al fallback de estimar por bbox. El ancho de placa que este archivo
    dice "derivar" del area salia entonces de una estimacion cruda, y el print
    de autochequeo no podia delatarlo porque `cobertura teorica` cancela el
    area por construccion y devuelve overlap*width pase lo que pase.
    """
    gi = {g.name: g.index for g in obj.vertex_groups}.get(gname)
    if gi is None:
        return 0.0

    states = [(m, m.show_viewport) for m in obj.modifiers if m.type == "MASK"]
    for m, _ in states:
        m.show_viewport = False
    bpy.context.view_layer.update()

    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    mw = obj.matrix_world
    inside = {v.index for v in obj.data.vertices
              if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)}
    total = 0.0
    if len(me.vertices) == len(obj.data.vertices):
        for poly in me.polygons:
            vs = list(poly.vertices)
            if sum(1 for v in vs if v in inside) * 2 > len(vs):
                total += poly.area
    else:
        # Los indices no mapean: estimar por el bbox del grupo como semiesfera.
        # Con el MASK silenciado arriba esto ya no deberia ocurrir; si ocurre,
        # que se vea en la consola en vez de pasar por medicion buena.
        print("  AVISO scalp_area: indices no mapean (%d evaluados vs %d base)"
              " -- estimando por bbox, el ancho derivado sera aproximado"
              % (len(me.vertices), len(obj.data.vertices)))
        pts = [mw @ obj.data.vertices[i].co for i in inside]
        if pts:
            xs = [p.x for p in pts]; ys = [p.y for p in pts]
            r = max(max(xs) - min(xs), max(ys) - min(ys)) * 0.5
            total = 2.0 * math.pi * r * r
    ev.to_mesh_clear()

    for m, was in states:
        m.show_viewport = was
    bpy.context.view_layer.update()
    return total * (mw.to_scale().x ** 2)


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


def hairline_offset(p, crown, half_w):
    """Cuanto BAJA la linea de nacimiento en este punto, en metros.

    El borde crudo del grupo `scalp` es una banda de altura constante y se lee
    como vincha. Una linea de nacimiento real no es recta: baja en el centro
    de la frente (pico de viuda) y sube en las sienes (entradas), y por detras
    baja bastante mas que por delante.

    Devuelve un desplazamiento en Z que se aplica a los vertices del borde, de
    modo que el contorno queda con forma sin tener que cortar caras.
    """
    dx = abs(p.x) / max(half_w, 1e-6)          # 0 al centro, 1 en la sien
    frontness = max(0.0, -(p.y - crown.y)) / max(abs(crown.y) + 0.09, 1e-6)
    frontness = min(1.0, frontness)

    # Frente: pico en el centro, entradas a los lados. El coseno da la V.
    peak = math.cos(min(dx, 1.0) * math.pi * 0.5)      # 1 centro -> 0 sien
    front_drop = (0.016 * peak) - (0.011 * (1.0 - peak))

    # Nuca: baja parejo hacia el cuello, que es donde el pelo sigue mas abajo.
    back_drop = -0.021

    return front_drop * frontness + back_drop * (1.0 - frontness)


def make_ponytail(bm, crown, pts, mat_index, length=0.115, w0=0.021, w1=0.009,
                  segs=6, drop=0.55, cross=True):
    """Coleta: la masa del peinado, que en las referencias NO esta en el craneo.

    Miradas por el PELO y no por la armadura, las cuatro referencias realistas
    del repo (D2R Barbarian, Farkas de Skyrim, y los dos veteranos del lote de
    Joan) coinciden en tres cosas: el pelo del craneo va APLASTADO contra el
    hueso, la masa vive en una coleta o trenza, y la barba pesa mas que el pelo.
    Un casquete inflado lee peluca por mas que cubra al 100%.

    Nace en la nuca alta y cae hacia atras y abajo. Cinta de quads que se
    afina, no un tubo: mas barata y se lee igual a la distancia de juego.
    """
    back = max(pts, key=lambda p: p.y)          # el punto mas trasero del scalp
    # Nace METIDA bajo el cap, no pegada en la superficie: una coleta arranca
    # del pelo, no del aire. Sin esto se ve una correa saliendo de la nada.
    root = Vector((0.0, back.y * 0.90 + crown.y * 0.10,
                   back.z * 0.62 + crown.z * 0.38))

    # Seccion en CRUZ: dos cintas perpendiculares. Una sola cinta es un plano y
    # desde el costado desaparece o se lee como correa; la cruz da volumen por
    # dos triangulos mas, que es el truco barato de siempre.
    planes = ((1.0, 0.0), (0.0, 1.0)) if cross else ((1.0, 0.0),)
    made = 0
    for ax, ay in planes:
        ring_prev = None
        for s in range(segs + 1):
            t = s / float(segs)
            # Cae atras y abajo, curvandose: recta seria un palo, no pelo.
            y = root.y + length * t * 0.55
            z = root.z - length * (t ** 1.35) * (1.0 + drop)
            # Se ensancha un poco antes de afinar -- una coleta atada tiene su
            # parte mas gruesa despues del nudo, no en la raiz.
            bulge = 1.0 + 0.35 * math.sin(min(t, 1.0) * math.pi)
            w = (w0 + (w1 - w0) * (t ** 0.8)) * bulge
            c = Vector((0.0, y, z))
            off = Vector((ax * w, ay * w * 0.75, 0.0))
            a = bm.verts.new(c - off)
            b = bm.verts.new(c + off)
            if ring_prev is not None:
                f = bm.faces.new((ring_prev[0], ring_prev[1], b, a))
                f.material_index = mat_index
                made += 1
            ring_prev = (a, b)
    return made


def make_plate(bm, root, flow, bvh, centre, mat_index, layer=0):
    """Una placa: tira de quads que sigue la superficie y despega en la punta."""
    pos = root.copy()
    dirv = flow.copy()
    ring_prev = None

    for s in range(SEGMENTS + 1):
        t = s / float(SEGMENTS)
        surf, nrm = surface_point(bvh, pos, centre)

        # La raiz se pega al craneo; la punta se separa. Eso es lo que da
        # volumen sin necesidad de mas geometria.
        # Cada capa se despega un poco mas que la de abajo, para apoyarse
        # SOBRE ella en vez de intersecarla.
        base_lift = LIFT + layer * 0.0055
        lift = base_lift + (TIP_LIFT - LIFT) * (t ** 1.6)
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
        pos = centre_pt + dirv * (STEP * LEN_SCALE)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--plates", type=int, default=N_PLATES)
    ap.add_argument("--layers", type=int, default=3)
    # Multiplicadores sobre los valores DERIVADOS, para poder rampear sin
    # volver a elegir numeros absolutos a mano.
    ap.add_argument("--width", type=float, default=1.0)
    ap.add_argument("--length", type=float, default=1.0)
    ap.add_argument("--overlap", type=float, default=1.7)
    ap.add_argument("--out-render", default=None)
    ap.add_argument("--no-cap", action="store_true")
    ap.add_argument("--cap-lift", type=float, default=0.0035)
    # Estilo. "shells" es el casquete de placas (lee anime/peluca sobre un
    # rostro realista); "realista" es cap ajustado + coleta, que es lo que
    # muestran D2R, Farkas y los dos veteranos del lote de Joan.
    # Default REALISTA: "shells" es el casquete de placas, y el comentario de
    # arriba ya dice que lee anime sobre un rostro realista. El contrato §0
    # fija rostro realista y §5 marca esa referencia como descartada, asi que
    # dejarlo de default era generar el estilo rechazado a quien no pase el flag.
    ap.add_argument("--style", default="realista", choices=("shells", "realista"))
    ap.add_argument("--tail-len", type=float, default=0.115)
    # Undercut: fraccion del ancho de cabeza que conserva pelo. El resto queda
    # RAPADO, que es piel oscurecida y se pinta -- no lleva geometria. 1.0
    # desactiva el undercut y vuelve al cap completo.
    ap.add_argument("--undercut", type=float, default=0.0)
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

    # ---- ancho DERIVADO del area a cubrir, no elegido a mano.
    area = scalp_area(obj)
    plate_len = SEGMENTS * STEP * args.length
    global ROOT_W, TIP_W, LEN_SCALE
    LEN_SCALE = args.length
    print("  scalp: area %.4f m2  |  coronilla z=%.3f" % (area, crown.z))

    # Todo esto es de las PLACAS, y en modo realista no se construye ninguna.
    # Antes se calculaba e imprimia siempre: al cambiar el default a realista,
    # la consola anunciaba "placas: 39 en 3 capas" y una cobertura teorica
    # mientras el contador final decia "placas construidas: 0". Un numero que
    # no corresponde a nada es peor que no imprimir nada.
    roots = []
    if args.style == "shells":
        roots = layered_roots(pts, args.plates, layers=args.layers)
        w_needed = plate_width_for_coverage(area, len(roots), plate_len, args.overlap)
        ROOT_W = w_needed * args.width
        TIP_W = ROOT_W * 0.45
        per_layer = {}
        for _p, k in roots:
            per_layer[k] = per_layer.get(k, 0) + 1
        print("  placas: %d en %d capas  %s"
              % (len(roots), args.layers,
                 " ".join("c%d=%d" % (k, v) for k, v in sorted(per_layer.items()))))
        print("  largo de placa %.4f m  |  semi-ancho %.4f m  (solape x%.2f)"
              % (plate_len, ROOT_W, args.overlap))
        print("  cobertura teorica: %.2f x el area del scalp"
              % (len(roots) * plate_len * 2.0 * ROOT_W / max(area, 1e-9)))

    bm = bmesh.new()
    hair_mat_idx = 0
    n_ok = 0

    # ---- SCALP CAP: la tapa opaca que va DEBAJO de las placas.
    #
    # Es la primera de las tres capas del metodo estandar de hair cards
    # (cap opaco -> cards en capas -> mechones sueltos), y es la que faltaba.
    # Sin ella la cobertura depende de que las placas se toquen entre si, que
    # es una apuesta: medido, ni con placas 2.6x mas anchas cerraba la corona
    # (18.9% de scalp expuesto en cenital). Con cap, la cobertura es 100% por
    # construccion y las placas solo aportan VOLUMEN y silueta, que es su
    # trabajo real.
    #
    # Se construye copiando las caras del propio grupo scalp e inflandolas por
    # la normal, asi sigue el craneo exactamente sin importar como cambien los
    # diales -- y cambiaron cinco veces en una sesion.
    if not args.no_cap:
        gi = {g.name: g.index for g in obj.vertex_groups}.get("scalp")
        states = [(m, m.show_viewport) for m in obj.modifiers if m.type == "MASK"]
        for m, _ in states:
            m.show_viewport = False
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        eme = ev.to_mesh()
        mw = obj.matrix_world
        inside = {v.index for v in obj.data.vertices
                  if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)}
        _sz = [(mw @ v.co).z for v in eme.vertices if v.index in inside]
        scalp_lo, scalp_hi = (min(_sz), max(_sz)) if _sz else (0.0, 1.0)
        vmap = {}
        n_cap = 0
        cap_faces = []
        for poly in eme.polygons:
            vs = list(poly.vertices)
            # CUALQUIER vertice del grupo, no la mayoria. Con el criterio de
            # mayoria quedaban caras sueltas sin incluir en el limite del
            # grupo, y esas eran las dos ranuras verticales de la nuca.
            if not any(v in inside for v in vs):
                continue
            # UNDERCUT: se rapa por ALTURA, no por lateralidad.
            #
            # El primer intento filtro por |x| -- "franja central" -- y salio
            # una tirita de pelo sobre una cabeza calva. Un undercut no es una
            # franja vertical: es una LINEA HORIZONTAL a la altura de la sien,
            # y se conserva TODO lo que queda por encima, coronilla incluida.
            # `undercut` es ahora esa altura, 0 = sin rapar, 1 = rapa hasta la
            # coronilla.
            if args.undercut > 0.001:
                cz = sum((mw @ eme.vertices[v].co).z for v in vs) / len(vs)
                # La linea sube hacia adelante y baja hacia la nuca, como en
                # las referencias: la sien queda mas rapada que el occipital.
                cy = sum((mw @ eme.vertices[v].co).y for v in vs) / len(vs)
                frontness = min(1.0, max(0.0, (crown.y - cy) / 0.09))
                line = scalp_lo + (scalp_hi - scalp_lo) * args.undercut * (
                    0.75 + 0.45 * frontness)
                if cz < line:
                    continue
            ring = []
            for vi in vs:
                if vi not in vmap:
                    co = mw @ eme.vertices[vi].co
                    nrm = (mw.to_3x3() @ eme.vertices[vi].normal).normalized()
                    vmap[vi] = bm.verts.new(co + nrm * args.cap_lift)
                ring.append(vmap[vi])
            try:
                f = bm.faces.new(ring)
                f.material_index = hair_mat_idx
                cap_faces.append(f)
                n_cap += 1
            except ValueError:
                pass

        # ---- CONTORNO: mover los vertices del BORDE segun la linea de
        # nacimiento. El borde crudo del grupo es una banda de altura casi
        # constante y se lee como vincha, con escalones donde salta de cara en
        # cara. Desplazar los verts frontera por un campo suave da un contorno
        # CON FORMA -- pico de viuda, entradas en las sienes, nuca mas baja --
        # sin tener que cortar geometria.
        border = [v for v in vmap.values()
                  if any(len(e.link_faces) < 2 for e in v.link_edges)]
        half_w = max((abs(v.co.x) for v in vmap.values()), default=0.05)
        for v in border:
            v.co.z += hairline_offset(v.co, crown, half_w)
        print("  contorno: %d vertices de borde reformados (media %d por cara)"
              % (len(border), 0))
        ev.to_mesh_clear()
        for m, was in states:
            m.show_viewport = was
        bpy.context.view_layer.update()
        print("  scalp cap: %d caras a %.4f m sobre la piel" % (n_cap, args.cap_lift))
    # De la capa mas baja a la mas alta: la de arriba cae ENCIMA de la de
    # abajo, como en una cabeza real y como pide la referencia.
    for r, layer in (roots if args.style == 'shells' else []):
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
            make_plate(bm, r, flow, bvh, centre, hair_mat_idx, layer)
            n_ok += 1
        except ValueError:
            pass

    if args.style == "realista":
        n_tail = make_ponytail(bm, crown, pts, hair_mat_idx,
                               length=args.tail_len)
        print("  coleta: %d segmentos, largo %.3f m" % (n_tail, args.tail_len))

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

    # --out se pedia como required y no se leia nunca: el .blend salia siempre
    # a la carpeta del archivo de ENTRADA, con nombre fijo. Con la metodologia
    # de rampa que exige el preflight eso es peor que un detalle: cada variante
    # pisaba a la anterior en silencio, y quien seguia el ejemplo del docstring
    # buscaba el resultado en un directorio donde nunca estuvo.
    out_dir = os.path.abspath(args.out) if args.out else (
        os.path.dirname(bpy.data.filepath) or ".")
    os.makedirs(out_dir, exist_ok=True)
    blend = os.path.join(out_dir, "char_warrior_male_hair.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    if not os.path.isfile(blend):
        raise SystemExit("no se escribio %s" % blend)
    print("  blend -> %s" % blend)
    return hair


if __name__ == "__main__":
    main()
