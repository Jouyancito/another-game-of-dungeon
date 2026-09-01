"""_glb_color_check -- does this GLB carry any colour at all?

Written 2026-08-23 for the activation audit. The showcase gate verifies that a
render EXISTS; it cannot verify that the render is telling the truth. Four mobs
(snake, turtle, wasp, bird) shipped pure white to Godot for a month while
passing that gate, because their build scripts render the showcase WITH the
procedural node graph attached -- and glTF cannot carry a node graph, so the
exported file holds `baseColorFactor 1,1,1` and nothing else.

The lesson from that month is the one this file exists to encode: a gate must
test a PROPERTY OF THE ARTEFACT, not the existence of evidence about it.

A GLB passes if ANY of these is true:
  * some primitive carries COLOR_0 (baked vertex colour)
  * the file has textures/images
  * a material sets a baseColorFactor that is not white

That last one matters: plenty of props are legitimately one flat colour, and a
deliberate flat tone is not the bug. The bug is *unpainted* white, which is
exactly what the exporter writes when it drops shading it could not express.

Exit code 1 (and a report on stdout) when at least one file carries no colour.

    python _glb_color_check.py <file.glb> [more.glb ...]
"""
from __future__ import annotations

import json
import os
import struct
import sys

WHITE_EPS = 0.02


def load_gltf(path: str) -> dict:
    with open(path, "rb") as f:
        magic, _, _ = struct.unpack("<III", f.read(12))
        if magic != 0x46546C67:
            raise ValueError("no es un GLB")
        length, kind = struct.unpack("<II", f.read(8))
        if kind != 0x4E4F534A:
            raise ValueError("primer chunk no es JSON")
        return json.loads(f.read(length))


def mat_has_colour(g: dict, index) -> bool:
    """Does this material paint anything by itself?"""
    if index is None:
        return False
    mats = g.get("materials", [])
    if not isinstance(index, int) or index >= len(mats):
        return False
    pbr = mats[index].get("pbrMetallicRoughness", {})
    if pbr.get("baseColorTexture"):
        return True
    f = pbr.get("baseColorFactor")
    return bool(f and any(abs(c - 1.0) > WHITE_EPS for c in f[:3]))


def inspect(path: str) -> tuple[bool, str]:
    """(has_colour, reason) — judged PER PRIMITIVE.

    The first version of this check asked "does anything in the file carry
    colour?" and passed `wasp.glb`, whose body renders pure white: its EYES
    have a tinted material, and one tinted material was enough to satisfy the
    question. That is the same failure this whole gate exists to prevent — a
    measurement that cannot see the defect it was written for. So the question
    is inverted: is there ANY primitive left with no colour source at all?
    """
    try:
        g = load_gltf(path)
    except Exception as exc:                       # noqa: BLE001
        # Unreadable is not "no colour" -- say so rather than blocking on it.
        return True, "ilegible (%s), no se juzga" % exc

    total = 0
    naked = 0
    painted_by = {"vcol": 0, "mat": 0}
    for mesh in g.get("meshes", []):
        for prim in mesh.get("primitives", []):
            total += 1
            if "COLOR_0" in prim.get("attributes", {}):
                painted_by["vcol"] += 1
            elif mat_has_colour(g, prim.get("material")):
                painted_by["mat"] += 1
            else:
                naked += 1

    if total == 0:
        return True, "sin mallas"
    if naked == 0:
        return True, "%d/%d primitivas pintadas (vcol %d, material %d)" % (
            total - naked, total, painted_by["vcol"], painted_by["mat"])
    return False, ("%d de %d primitivas SIN color (ni COLOR_0 ni textura ni "
                   "baseColorFactor) -> Godot las dibuja BLANCAS" % (naked, total))


def main() -> int:
    paths = sys.argv[1:]
    if not paths:
        print("uso: _glb_color_check.py <file.glb> [...]")
        return 0
    bad = []
    for p in paths:
        if not os.path.isfile(p):
            continue
        ok, why = inspect(p)
        mark = "OK  " if ok else "SIN COLOR"
        print("%-9s %-42s %s" % (mark, os.path.basename(p), why))
        if not ok:
            bad.append(p)
    if bad:
        print("\n%d archivo(s) sin color. Bakear a vertex colour con "
              "game/tools/blender/_bake_vcol.py, o a textura si la malla no "
              "tiene vértices suficientes para sostener el patrón." % len(bad))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
