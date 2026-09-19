"""_deploy -- one declared home for every GLB the game loads.

Why this exists (2026-08-24). Every builder in this tree wrote its GLB next to
its own script, and the game loaded a SEPARATE copy under `game/assets/art/`.
Nothing connected the two: the copy was made by hand. So an asset could be
"in the game" and "two builds out of date in the game" at the same time, and
both look identical from Blender -- only the deployed file's date tells them
apart. It cost a session: the turtle Joan was judging in Godot was missing the
gait, the growth rings and three fixes, all present in the build he had just
approved.

Two copies of anything drift. So the fix is not a copy step -- it is to remove
the second copy: a builder exports STRAIGHT to the path the game loads. That
is also where the motor's showcase gate already looks (`game/assets/art`), so
the build, the evidence and the game finally agree on one file.

`audit()` needs no bpy and answers the question that had no instrument:
    python _deploy.py
"""
from __future__ import annotations

import hashlib
import os

_HERE = os.path.dirname(os.path.abspath(__file__))
ASSET_ROOT = os.path.abspath(os.path.join(_HERE, "..", "..", "assets", "art"))

# "<builder dir>/<file>.glb" -> path under game/assets/art/. Keyed by DIRECTORY
# and file, not by bare filename: two builders emit `king_slime.glb` (the live
# one is slime/ with IS_KING, king_slime/ is an abandoned earlier attempt), and
# a bare-name table reported the dead one as a deployment gone stale.
#
# Every entry is read off the code that LOADS it, never guessed:
#   turtle      scenes/enemy/turtle.gd:7   TURTLE_MODEL
#   slime       scenes/enemy/slime.tscn    ext_resource
#   king_slime  scenes/enemy/king_slime.tscn
# A builder missing from this table has no declared home, and audit() says so
# instead of inventing one.
DEPLOY = {
    "turtle/turtle.glb": "piso1_pradera/enemies/small/turtle_dp_01.glb",
    "slime/slime.glb": "piso1_pradera/enemies/slime/slime_dp_01.glb",
    "slime/king_slime.glb": "piso1_pradera/enemies/slime/king_slime_dp_01.glb",
    # hawk: scenes/enemy/hawk.gd HAWK_MODEL (wired 2026-08-25, glb-with-fallback)
    "hawk/hawk.glb": "piso1_pradera/enemies/flying/hawk_dp_01.glb",
}


def asset_path(name: str) -> str:
    """Absolute path the game loads for this builder output."""
    rel = DEPLOY.get(name)
    if rel is None:
        raise SystemExit(
            "_deploy: %r has no declared destination. Add it to DEPLOY, taking "
            "the path from the scene or script that loads it -- do not guess."
            % name)
    return os.path.join(ASSET_ROOT, rel.replace("/", os.sep))


# Hash parity manifest. Every export records the sha256 of what it wrote; the
# Stop hook (`motor-showcase-gate.ps1`) recomputes the deployed file's hash and
# BLOCKS if they differ or the entry is missing. This replaces trusting mtimes:
# the turtle spent two builds stale in the game with nothing able to notice,
# because "a file exists at the path" and "the file is the build" are different
# claims and only a hash distinguishes them. (2026-08-25 review, mejora P1.)
MANIFEST = os.path.join(_HERE, "_deploy_manifest.json")


def _sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _manifest_load() -> dict:
    import json

    if not os.path.isfile(MANIFEST):
        return {}
    try:
        with open(MANIFEST, encoding="utf-8") as fh:
            return json.load(fh)
    except (ValueError, OSError):
        # A corrupt manifest must not brick every build; it will be rewritten
        # on the next export and the gate treats missing entries as missing.
        return {}


def _manifest_record(rel: str, path: str) -> None:
    import json

    data = _manifest_load()
    data[rel.replace(os.sep, "/")] = {
        "sha256": _sha256(path),
        "size": os.path.getsize(path),
    }
    with open(MANIFEST, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)


def export_glb(name: str, **kwargs) -> str:
    """Export the current scene straight to the deployed path. Returns it."""
    import bpy

    out = asset_path(name)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, **kwargs)
    if not (os.path.isfile(out) and os.path.getsize(out) > 0):
        raise SystemExit("_deploy: export wrote nothing to %s" % out)
    rel = os.path.relpath(out, ASSET_ROOT)
    _manifest_record(rel, out)
    print("[deploy] %s -> %s (%.1f MB, sha %s)"
          % (name, rel, os.path.getsize(out) / 1e6, _sha256(out)[:10]))
    return out


def _md5(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def audit() -> int:
    """Check every declared destination, and flag leftover builder copies."""
    problems = 0
    print("")
    for name, rel in sorted(DEPLOY.items()):
        dst = os.path.join(ASSET_ROOT, rel.replace("/", os.sep))
        legacy = os.path.join(_HERE, name.replace("/", os.sep))
        if not os.path.isfile(dst):
            print("  NO DESPLEGADO  %-24s %s" % (name, rel))
            problems += 1
            continue
        entry = _manifest_load().get(rel)
        if entry is not None and entry["sha256"] != _sha256(dst):
            print("  HASH DISTINTO  %-24s %s  el archivo desplegado NO es el "
                  "que este builder exporto" % (name, rel))
            problems += 1
            continue
        if os.path.isfile(legacy):
            # A leftover copy beside the builder is the drift this module
            # exists to end: whichever is newer, somebody will judge the wrong
            # one. Same bytes today does not make it safe tomorrow.
            # md5 is a weak instrument here: measured 2026-08-24, two exports
            # of the SAME scene differ in 23.768 bytes, all inside the index
            # buffers -- identical size, tris, materials and clips, only the
            # triangle order moved. So a hash mismatch means "not the same
            # bytes", NOT "different asset". Same size + same probe is the
            # real check (_turtle_deploy_showcase.py prints it).
            same = _md5(legacy) == _md5(dst)
            note = "identica" if same else (
                "distinta -- puede ser solo orden de indices, el exportador "
                "glTF no es determinista byte a byte; confirmar con el probe")
            print("  COPIA LEGACY   %-24s %s  (%s -- borrar el de tools/)"
                  % (name, rel, note))
            problems += 1
        else:
            print("  ok             %-24s %s" % (name, rel))

    huerfanos = []
    for entry in sorted(os.listdir(_HERE)):
        d = os.path.join(_HERE, entry)
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if f.endswith(".glb") and ("%s/%s" % (entry, f)) not in DEPLOY:
                huerfanos.append("%s/%s" % (entry, f))
    print("")
    print("  %d sin destino declarado (no los carga ninguna escena, o falta "
          "la entrada): %s" % (len(huerfanos), ", ".join(huerfanos[:6])
                               + (" ..." if len(huerfanos) > 6 else "")))
    print("  %d problemas en los %d con destino declarado"
          % (problems, len(DEPLOY)))
    return problems


if __name__ == "__main__":
    raise SystemExit(1 if audit() else 0)
