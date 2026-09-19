"""_char_common -- the two things every script touching the character needs.

Both exist because the same two mistakes keep getting made, a session apart.

MISTAKE 1 -- reading me.vertices and calling it geometry.
    char_warrior_male_mh carries 41 active shape keys. Measured:

        base    z max 1.6664
        eval    z max 1.8153
        shift   mean 102.2 mm, max 182.7 mm  -- and NOT uniform

    The character is 1.80 m; the base cage lives at 1.67 m. Anything derived
    from `me.vertices.foreach_get("co")` is therefore in the wrong space by
    ~10 cm on average, with distortion on top. It fails silently: the numbers
    look plausible, the paint lands somewhere believable, and the error only
    shows up as "the colour is a bit off".

    This is gotcha #2 in the motor recipe paint_por_geometria.py -- "shape
    keys: pintar colors SI llega al render, mover me.vertices NO" -- and it
    was walked into anyway while building the thirds ramp.

MISTAKE 2 -- evaluating with a MASK still on.
    `Hide helpers` drops 19158 verts to 13380. Any index computed against the
    evaluated mesh then points at a different vertex than the same index on
    the base, so masks land on the wrong body part. Also silent.

morphed_coords() does both correctly and REFUSES to return a mismatched
result, which is the part that matters: a wrong answer here is invisible.
"""
from __future__ import annotations

import bpy
import numpy as np


class masks_muted:
    """Turn off MASK modifiers for the duration of a block."""

    def __init__(self, *objs):
        self.objs = [o for o in objs if o is not None]
        self.states: list[tuple] = []

    def __enter__(self):
        for o in self.objs:
            for m in o.modifiers:
                if m.type == "MASK" and m.show_viewport:
                    self.states.append((m, m.show_viewport))
                    m.show_viewport = False
        bpy.context.view_layer.update()
        return self

    def __exit__(self, *exc):
        for m, was in self.states:
            m.show_viewport = was
        bpy.context.view_layer.update()
        return False


def morphed_coords(obj):
    """(W, N): world positions and normals that line up 1:1 with BASE indices.

    This is what the model actually LOOKS LIKE -- shape keys applied, masks
    muted so the vertex count still matches the base cage.
    """
    with masks_muted(obj):
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        me = ev.to_mesh()
        n = len(me.vertices)
        co = np.empty(n * 3, dtype=np.float32)
        me.vertices.foreach_get("co", co)
        no = np.empty(n * 3, dtype=np.float32)
        me.vertices.foreach_get("normal", no)
        ev.to_mesh_clear()

    nb = len(obj.data.vertices)
    if n != nb:
        raise RuntimeError(
            "mask not muted: %d evaluated vs %d base. Without a 1:1 mapping"
            " every group index points at the wrong vertex." % (n, nb))

    M = np.array(obj.matrix_world)
    W = co.reshape(n, 3).astype(np.float64) @ M[:3, :3].T + M[:3, 3]
    N = no.reshape(n, 3).astype(np.float64) @ np.linalg.inv(M[:3, :3])
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    return W, N


def shapekey_drift(obj) -> float:
    """Mean base-to-evaluated displacement in metres. 0.0 means no morphing.

    Call it to PROVE the morphed path is needed rather than assuming it, and
    to catch the reverse case -- a mesh with no shape keys where someone added
    an expensive evaluated read for nothing.
    """
    W, _ = morphed_coords(obj)
    me = obj.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    M = np.array(obj.matrix_world)
    base = co.reshape(-1, 3).astype(np.float64) @ M[:3, :3].T + M[:3, 3]
    return float(np.mean(np.linalg.norm(W - base, axis=1)))
