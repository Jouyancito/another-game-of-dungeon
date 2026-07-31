# _motor.py -- bootstrap that puts the shared motor-blender layers on sys.path.
#
# The packs run as `blender.exe --background --python <pack>/build_x.py`, so there
# is no package context and no installed dependency: the motor is located at
# runtime and its flat module directories are prepended to sys.path.
#
# Usage from a pack (the packs already insert their parent dir on sys.path for
# _ground_common / _ficha_common, so nothing extra is needed):
#
#     sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
#     import _motor                     # noqa: F401 -- must come first
#     import biome_vcol, biome_stem, glb_export
#
# Resolution order:
#   1. $MOTOR_BLENDER_PATH   -- so CI or another machine can relocate the motor
#                               without editing code.
#   2. ~/motor-blender       -- the default checkout location.
#   3. a sibling of the game repo.
#
# Every candidate is probed for the SENTINEL FILE recetas/RECETAS.md rather than
# trusted blindly, so a stale path fails loudly here, with the tried candidates
# listed, instead of surfacing as a confusing ImportError deep inside a build.
import os
import subprocess
import sys

ENV = "MOTOR_BLENDER_PATH"
SENTINEL = os.path.join("recetas", "RECETAS.md")
LAYERS = ("recetas", "lookdev", "gate")

_CANDIDATES = (
    os.environ.get(ENV),
    os.path.join(os.path.expanduser("~"), "motor-blender"),
    os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                  "..", "..", "..", "..", "..", "motor-blender")),
)


def motor_root():
    for c in _CANDIDATES:
        if c and os.path.isfile(os.path.join(c, SENTINEL)):
            return os.path.abspath(c)
    raise RuntimeError(
        "motor-blender not found. Set %s=<path>. Tried: %s" % (ENV, _CANDIDATES))


ROOT = motor_root()

for _layer in LAYERS:
    _p = os.path.join(ROOT, _layer)
    if os.path.isdir(_p) and _p not in sys.path:
        sys.path.insert(0, _p)


def rev():
    """Short git rev of the motor checkout, for build provenance.

    A regenerated GLB whose bytes change WITHOUT the motor rev changing is a bug;
    a motor rev change obliges re-running the verification protocol for every
    pack that imports the touched module.
    """
    try:
        out = subprocess.check_output(
            ["git", "-C", ROOT, "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL)
        return out.decode().strip()
    except Exception:
        return "unknown"
