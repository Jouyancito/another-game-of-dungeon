"""measure_hair_coverage — cuánto cuero cabelludo queda a la vista, en números.

El pelo del guerrero se juzgó tres veces de ojo y dos de esas se declaró "casi
bien". El criterio real es binario y sale de qué ES el pelo: en una cabeza con
pelo NO se ve cuero cabelludo, salvo en la raya. Así que se mide.

Método: se pinta el grupo `scalp` de blanco puro EMISIVO, el resto del cuerpo
de gris medio y el pelo de negro, sin luces ni view transform. Después cada
píxel es una respuesta:

    blanco  -> scalp expuesto           (el defecto)
    negro   -> pelo                     (lo que debería taparlo)
    gris    -> resto del cuerpo         (no cuenta)

Métrica = blanco / (blanco + negro), por vista. Cero es el objetivo.

Emisivo y `view_transform='Standard'` a propósito: con luz de por medio se
estaría midiendo el sombreado, no la cobertura, y un scalp en penumbra pasaría
por cubierto.
"""
import argparse
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))


def flat_mat(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return mat


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--body", default="char_warrior_male_mh")
    ap.add_argument("--hair", default="char_warrior_male_hair")
    ap.add_argument("--out", required=True)
    ap.add_argument("--tag", default="cov")
    ap.add_argument("--res", type=int, default=420)
    args = ap.parse_args(argv)

    body = bpy.data.objects.get(args.body)
    hair = bpy.data.objects.get(args.hair)
    if body is None or hair is None:
        raise SystemExit("faltan objetos: body=%r hair=%r" % (body, hair))

    # Todo lo que no sea cuerpo ni pelo se saca: un plano de piso o el poste de
    # referencia meterían píxeles que no son ninguna de las tres categorías.
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o not in (body, hair):
            bpy.data.objects.remove(o, do_unlink=True)

    me = body.data
    gi = {g.name: g.index for g in body.vertex_groups}.get("scalp")
    if gi is None:
        raise SystemExit("el cuerpo no tiene grupo 'scalp'")
    scalp_verts = {v.index for v in me.vertices
                   if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)}

    me.materials.clear()
    me.materials.append(flat_mat("m_body", (0.35, 0.35, 0.35)))
    me.materials.append(flat_mat("m_scalp", (1.0, 1.0, 1.0)))
    n_scalp_faces = 0
    for poly in me.polygons:
        vs = list(poly.vertices)
        if sum(1 for v in vs if v in scalp_verts) * 2 > len(vs):
            poly.material_index = 1
            n_scalp_faces += 1
        else:
            poly.material_index = 0
    hair.data.materials.clear()
    hair.data.materials.append(flat_mat("m_hair", (0.0, 0.0, 0.0)))
    print("  caras de scalp: %d" % n_scalp_faces)

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = args.res
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = False
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.5, 0.0, 0.5, 1)

    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    tmp = ev.to_mesh()
    top = max((body.matrix_world @ v.co).z for v in tmp.vertices)
    ev.to_mesh_clear()

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 0.30
    hz = top - 0.085

    shots = [
        ("frente", (0.0, -1.0, hz), (90, 0, 0)),
        ("perfil_i", (-1.0, 0.0, hz), (90, 0, -90)),
        ("perfil_d", (1.0, 0.0, hz), (90, 0, 90)),
        ("nuca", (0.0, 1.0, hz), (90, 0, 180)),
        ("tresq", (0.72, -0.72, hz), (90, 0, 45)),
        ("cenital", (0.0, -0.05, top + 0.55), (12, 0, 0)),
    ]

    os.makedirs(os.path.abspath(args.out), exist_ok=True)
    rows = []
    for label, loc, rot in shots:
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)
        path = os.path.join(os.path.abspath(args.out),
                            "%s_%s.png" % (args.tag, label))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        if not (os.path.isfile(path) and os.path.getsize(path) > 0):
            raise SystemExit("no se escribio %s" % path)

        img = bpy.data.images.load(path)
        px = list(img.pixels)
        bpy.data.images.remove(img)
        w = b = 0
        for i in range(0, len(px), 4):
            r, g, bl = px[i], px[i + 1], px[i + 2]
            if r > 0.75 and g > 0.75 and bl > 0.75:
                w += 1
            elif r < 0.12 and g < 0.12 and bl < 0.12:
                b += 1
        tot = w + b
        # Un encuadre roto no captura ni scalp ni pelo, y `tot == 0` daria
        # 0% expuesto: el MEJOR resultado posible, indistinguible de una
        # medicion perfecta. Es el "un cero no prueba ausencia" del CLAUDE.md,
        # y esta sonda existe justamente para no creerle al ojo.
        if tot == 0:
            raise SystemExit(
                "vista %r no capturo ni scalp ni pelo (%d px) -- encuadre roto,"
                " la medicion no vale" % (label, tot))
        pct = 100.0 * w / tot
        rows.append((label, w, b, pct))
        print("  %-9s scalp %6d px | pelo %6d px | EXPUESTO %5.1f%%"
              % (label, w, b, pct))

    worst = max(rows, key=lambda r: r[3])
    tw = sum(r[1] for r in rows)
    tb = sum(r[2] for r in rows)
    total = (100.0 * tw / (tw + tb)) if (tw + tb) else 0.0
    print("\n  TOTAL expuesto %.1f%%   |  peor vista: %s con %.1f%%"
          % (total, worst[0], worst[3]))

    measure_bulk(body, hair)




def measure_bulk(body, hair):
    """Cuanto ENGORDA el pelo la cabeza, en mm por lado.

    Segunda metrica, y para el estilo realista importa mas que la cobertura:
    las cuatro referencias con pelo realista (D2R, Farkas, y los dos veteranos
    del lote de Joan) tienen el pelo APLASTADO contra el craneo. Un casquete
    inflado lee peluca por mas que cubra al 100%.

    Se compara el ancho de la silueta del cuerpo solo contra cuerpo+pelo, a la
    altura de la coronilla, en los tres ejes.
    """
    import bpy
    import numpy as np

    def extent(objs, z_lo, z_hi):
        pts = []
        dg = bpy.context.evaluated_depsgraph_get()
        for o in objs:
            ev = o.evaluated_get(dg)
            me = ev.to_mesh()
            mw = o.matrix_world
            for v in me.vertices:
                w = mw @ v.co
                if z_lo <= w.z <= z_hi:
                    pts.append((w.x, w.y))
            ev.to_mesh_clear()
        if not pts:
            return 0.0, 0.0
        a = np.array(pts)
        return float(a[:, 0].max() - a[:, 0].min()), float(a[:, 1].max() - a[:, 1].min())

    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    top = max((body.matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    lo, hi = top - 0.10, top - 0.02

    bw, bd = extent([body], lo, hi)
    hw, hd = extent([body, hair], lo, hi)
    print("\n  --- volumen (el pelo realista va PEGADO, no inflado) ---")
    print("  franja medida  z %.4f .. %.4f  (8 cm de coronilla)" % (lo, hi))
    print("  craneo         ancho %.4f m   fondo %.4f m" % (bw, bd))
    print("  con pelo       ancho %.4f m   fondo %.4f m" % (hw, hd))
    print("  engorda        %+.1f mm/lado ancho   %+.1f mm/lado fondo"
          % ((hw - bw) * 500.0, (hd - bd) * 500.0))

    # La franja de arriba sólo ve la coronilla. Una coleta nace bien por debajo
    # y cae desde ahí, así que ESTRUCTURALMENTE no entra en esa medición: sin
    # este aviso, el mensaje "va PEGADO, no inflado" se imprimiría igual con
    # una coleta enorme colgando, juzgando sólo el cap.
    dg = bpy.context.evaluated_depsgraph_get()
    ev = hair.evaluated_get(dg)
    hme = ev.to_mesh()
    hz = [(hair.matrix_world @ v.co).z for v in hme.vertices]
    ev.to_mesh_clear()
    if hz and min(hz) < lo:
        bajo = sum(1 for z in hz if z < lo)
        print("  AVISO: %d de %d verts del pelo caen BAJO la franja (hasta"
              " z %.4f). El numero de arriba juzga el cap, NO la coleta."
              % (bajo, len(hz), min(hz)))
    return (hw - bw) * 500.0, (hd - bd) * 500.0


if __name__ == "__main__":
    main()
