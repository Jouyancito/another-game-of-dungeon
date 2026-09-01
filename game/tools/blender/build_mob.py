"""build_mob -- generate a mob, check it, and render what Godot will get. One command.

This is the atomicity fix from AUDIT_ACTIVACION_2026-08-23.md, and the principle
behind it was written down on 2026-07-12 and never applied outside the corpóreo:

    "el fix no es más explicación sino estructura: hacer atómico el ciclo
     editar→render→gate, para que 'ver' no sea un paso separado olvidable."

A step you have to remember is a step you will eventually skip. Four mobs shipped
white to Godot for a month because "verify the export" was its own optional step
that nobody ran -- while every build script happily rendered a showcase that
looked correct, because it renders WITH the node graph the export throws away.

So the three steps become one call:

    python game/tools/blender/build_mob.py turtle

    1. run the mob's build_*.py under headless Blender
    2. CHECK the exported .glb actually carries colour  -> hard fail if not
    3. render the truth view (only what ships inside the file)
    4. print the path so there is something to look at

Step 2 fails the whole command. That is the point: you cannot get to "done"
while the artefact is broken, and you do not have to remember to look, because
the thing to look at is handed to you.

    --skip-build   re-check and re-render an existing .glb without rebuilding
"""
from __future__ import annotations

import argparse
import glob
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BLENDER = r"C:\Users\the_j\blender\blender-5.1.2-windows-x64\blender.exe"


def find_build_script(mob: str) -> str:
    for cand in (os.path.join(HERE, mob, "build_%s.py" % mob),
                 os.path.join(HERE, mob, "build.py")):
        if os.path.isfile(cand):
            return cand
    hits = glob.glob(os.path.join(HERE, mob, "build_*.py"))
    if hits:
        return hits[0]
    raise SystemExit("no encuentro build script para '%s' en %s" % (mob, os.path.join(HERE, mob)))


def find_glb(mob: str) -> str:
    hits = [p for p in glob.glob(os.path.join(HERE, mob, "*.glb"))
            if not os.path.basename(p).startswith("_")]
    if not hits:
        raise SystemExit("el build no dejó ningún .glb en %s" % os.path.join(HERE, mob))
    return max(hits, key=os.path.getmtime)


def run(cmd: list[str], label: str) -> int:
    print("\n>>> %s" % label)
    print("    %s" % " ".join(os.path.basename(c) if os.path.sep in c else c for c in cmd))
    return subprocess.call(cmd)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("mob", help="carpeta del mob bajo game/tools/blender/ (turtle, wasp, rat...)")
    ap.add_argument("--skip-build", action="store_true",
                    help="no reconstruir; sólo verificar y renderizar el .glb existente")
    ap.add_argument("--outdir", default=os.path.join(HERE, "_truth"))
    args = ap.parse_args()

    if not args.skip_build:
        script = find_build_script(args.mob)
        rc = run([BLENDER, "--background", "--factory-startup",
                  "--python-exit-code", "1", "--python", script],
                 "BUILD  %s" % os.path.basename(script))
        if rc != 0:
            print("\n*** el build falló (código %d). Nada que verificar." % rc)
            return rc

    glb = find_glb(args.mob)
    print("\n>>> GLB: %s" % glb)

    # THE GATE. Not a suggestion, not a later step.
    rc = run([sys.executable, os.path.join(HERE, "_glb_color_check.py"), glb],
             "CHECK  ¿el archivo lleva color?")
    if rc != 0:
        print("\n*** SIN COLOR. Godot lo dibujaría blanco, así que esto NO está hecho.")
        print("    Arreglo: bakear el shading a vertex colour ->")
        print("      import _bake_vcol; _bake_vcol.bake_and_report(obj, 'nombre')")
        print("    antes del export, en el build script. Si la malla tiene pocos")
        print("    vértices el gate del módulo lo va a rechazar: ese caso necesita")
        print("    bake a TEXTURA, no a vértices.")
        return 1

    rc = run([BLENDER, "--background", "--factory-startup",
              "--python-exit-code", "1", "--python", os.path.join(HERE, "_glb_truth_render.py"),
              "--", "--glb", glb, "--outdir", args.outdir],
             "TRUTH  render de lo que recibe Godot")
    if rc != 0:
        print("\n*** el truth render falló. Sin evidencia no hay veredicto.")
        return rc

    name = os.path.splitext(os.path.basename(glb))[0]
    shot = os.path.join(args.outdir, "%s_TRUTH.png" % name)
    print("\n" + "=" * 66)
    print("  MIRALO:  %s" % shot)
    print("  Esto es lo que ve Godot, no lo que muestra el showcase del build.")
    print("=" * 66)
    return 0


if __name__ == "__main__":
    sys.exit(main())
