"""Sanity harness for measure_skin_spectrum -- synthetic signals of known scale.

The probe claims to say WHERE colour variation lives by scale. Before believing
any number it prints about the warrior, feed it three signals whose correct
answer is known by construction:

    a smooth global gradient   -> must land in MACRO
    a ~1.5 cm checker          -> must land in MESO
    per-vertex white noise     -> must land in MESH

If a band does not dominate the signal built to live in it, the decomposition
is wrong and every verdict it produces is decoration.

    blender -b --factory-startup --python-exit-code 1 \
        --python _test_skin_spectrum.py
"""
from __future__ import annotations

import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_skin_spectrum import (R_MACRO, R_MESO, blur, edge_array, rms,
                                   steps_for)

FAILURES: list[str] = []


def bands(col, edges, spacing):
    k_meso = steps_for(R_MESO, spacing)
    k_macro = steps_for(R_MACRO, spacing)
    local_meso = blur(col, edges, k_meso)
    local_macro = blur(local_meso, edges, max(1, k_macro - k_meso))
    g = col.mean(axis=0)
    e = {
        "macro": rms(local_macro - g),
        "meso": rms(local_meso - local_macro),
        "mesh": rms(col - local_meso),
    }
    tot = sum(e.values()) or 1.0
    return {k: v / tot for k, v in e.items()}


def expect(label, share, want):
    got = max(share, key=share.get)
    ok = got == want
    print("  %-4s %-34s dominant %-5s (%.0f%%)  | macro %.0f meso %.0f mesh %.0f"
          % ("OK" if ok else "FAIL", label, got, 100 * share[got],
             100 * share["macro"], 100 * share["meso"], 100 * share["mesh"]))
    if not ok:
        FAILURES.append("%s: dominant %s, expected %s" % (label, got, want))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # A dense flat grid 1 m across: ~4 mm spacing, so both radii are many
    # steps away and the three bands are cleanly separable.
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=250, y_subdivisions=250,
                                    size=1.0)
    obj = bpy.context.object
    me = obj.data
    edges = edge_array(me)

    co = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3).astype(np.float64)
    d = co[edges[:, 0]] - co[edges[:, 1]]
    spacing = float(np.mean(np.linalg.norm(d, axis=1)))
    print("  grid: %d verts, mean edge %.2f mm, meso=%d steps macro=%d steps"
          % (len(co), spacing * 1000, steps_for(R_MESO, spacing),
             steps_for(R_MACRO, spacing)))

    x, y = co[:, 0], co[:, 1]

    # 1. Global gradient -- one full swing across the whole 1 m grid.
    grad = np.repeat(((x - x.min()) / (x.max() - x.min()))[:, None], 3, axis=1)
    expect("global gradient", bands(grad, edges, spacing), "macro")

    # 2. A SINE at the meso scale -- not a checker.
    #    The first version of this test used a binary checker and it failed,
    #    correctly: a square wave has hard edges, and an edge that crosses in
    #    one vertex IS mesh frequency. Its harmonics (3f, 5f, ...) run all the
    #    way down to Nyquist and dumped 90% of the energy into `mesh`. A sine
    #    carries exactly one frequency, which is what a band test needs.
    #
    #    Period is picked from the RADII, not from anatomy: it must survive the
    #    meso blur (which kills under ~2*R_MESO = 20 mm) and die in the macro
    #    blur (which passes over ~4*R_MACRO = 240 mm). 40 mm sits between.
    period = 0.040
    sine = 0.5 + 0.5 * np.sin(2 * np.pi * x / period)
    expect("%.0f mm sine" % (period * 1000),
           bands(np.repeat(sine[:, None], 3, axis=1), edges, spacing), "meso")

    # 3. Per-vertex noise -- exactly what the v1 pore hash was.
    rng = np.random.default_rng(0)
    noise = rng.random((len(co), 3))
    expect("per-vertex noise (the v1 hash)",
           bands(noise, edges, spacing), "mesh")

    print("\n" + "=" * 66)
    if FAILURES:
        print("  %d FAILED -- the spectrum probe cannot be trusted:"
              % len(FAILURES))
        for f in FAILURES:
            print("    - " + f)
        raise SystemExit(1)
    print("  all bands isolate their own signal -- probe is trustworthy")


if __name__ == "__main__":
    main()
