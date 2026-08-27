# gen_prairie_textures.py — procedural textures for the prairie caverna-dia
# pass (PO 2026-08-27): the DanMachi-18F CRYSTAL SKY (pale luminous white-cyan
# with vertical crystalline striations + sparkle motes — ref
# _references/crystal_ceiling/danmachi_18f_under_resort.png) and a multi-tone
# GRASS albedo so the terrain stops reading as one flat green (Joan: "el pasto
# sigue siendo textura de un puro color... refeo").
#
# Pure numpy/PIL (no Blender). Deterministic. Both textures are TILEABLE via
# integer-lattice value noise with wrapped hashing.
#
#   python game/tools/textures/gen_prairie_textures.py
#
# Outputs (committed):
#   game/assets/art/piso1_pradera/textures/sky_crystal_01.png       (1024)
#   game/assets/art/piso1_pradera/textures/grass_albedo_01.png      (1024)
#   game/assets/art/piso1_pradera/textures/grass_normal_01.png      (1024)
import os

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "assets", "art", "piso1_pradera", "textures")
os.makedirs(OUT, exist_ok=True)
SIZE = 1024


def hash2(xi, yi, period, seed):
    xi = np.mod(xi, period)
    yi = np.mod(yi, period)
    h = np.sin(xi * 127.1 + yi * 311.7 + seed * 91.3) * 43758.5453
    return h - np.floor(h)


def smooth(t):
    return t * t * (3.0 - 2.0 * t)


def vnoise(u, v, freq, seed):
    """Tileable 2D value noise; u,v in [0,1), freq integer."""
    x, y = u * freq, v * freq
    xi, yi = np.floor(x), np.floor(y)
    tx, ty = smooth(x - xi), smooth(y - yi)
    a = hash2(xi, yi, freq, seed)
    b = hash2(xi + 1, yi, freq, seed)
    c = hash2(xi, yi + 1, freq, seed)
    d = hash2(xi + 1, yi + 1, freq, seed)
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def fbm(u, v, freq, octaves, seed):
    out = np.zeros_like(u)
    amp, norm = 1.0, 0.0
    f = freq
    for o in range(octaves):
        out += amp * vnoise(u, v, f, seed + o * 17)
        norm += amp
        amp *= 0.5
        f *= 2
    return out / norm


def save(name, rgb):
    img = (np.clip(rgb, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(img).save(os.path.join(OUT, name))
    print("[textures]", name, "saved")


yy, xx = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64) / SIZE

# ── Crystal sky (DanMachi 18F read) ────────────────────────────────────────
# v = 0 at texture top; on the ceiling plane this is just orientation-neutral
# haze, so the "gradient" is radial-ish mottling rather than strictly vertical.
CEN = np.array([0.55, 0.72, 0.80])   # cyan-celeste
PAL = np.array([0.86, 0.90, 0.92])   # pale luminous white
haze = fbm(xx, yy, 3, 3, 5.0)
base_t = np.clip(0.35 + 0.5 * haze, 0, 1)
sky = CEN[None, None, :] * (1 - base_t[..., None]) + PAL[None, None, :] * base_t[..., None]
# vertical crystalline striations: noise stretched hard along Y
stria = fbm(xx, yy * 0.06, 24, 2, 11.0) - 0.5
sky += stria[..., None] * np.array([0.05, 0.07, 0.08])[None, None, :]
# faceted shard patches: cellular-ish darker teal veils
shard = fbm(xx, yy, 9, 2, 23.0)
shard_m = np.clip((shard - 0.62) / 0.18, 0, 1) * 0.22
sky = sky * (1 - shard_m[..., None]) + np.array([0.42, 0.62, 0.70])[None, None, :] * shard_m[..., None]
# sparkle motes: rare bright white-cyan specks
spark = vnoise(xx, yy, 96, 41.0)
spark_m = np.clip((spark - 0.955) / 0.045, 0, 1)
sky = sky * (1 - spark_m[..., None]) + np.array([0.98, 1.0, 1.0])[None, None, :] * spark_m[..., None]
# clouds (refs 2a tanda 2026-08-27: every real prairie sky has cumulus, never
# a flat wash): billowy white masses with soft edges and a faint warm base.
cloud = fbm(xx, yy, 4, 4, 71.0)
cloud_m = np.clip((cloud - 0.52) / 0.22, 0, 1)
cloud_m = cloud_m * cloud_m * (3 - 2 * cloud_m)
cloud_col = (np.array([0.965, 0.975, 0.985])[None, None, :]
             - np.clip(0.5 - cloud, 0, 1)[..., None] * np.array([0.06, 0.05, 0.03])[None, None, :])
sky = sky * (1 - 0.85 * cloud_m[..., None]) + cloud_col * (0.85 * cloud_m[..., None])
save("sky_crystal_01.png", sky)

# ── Grass albedo (multi-tone, from Joan's photo greens) ────────────────────
LIT = np.array([0.45, 0.53, 0.11])    # lit yellow-green (photo sample 0.51/0.58/0.10, kept a hair deeper for the light rig)
MID = np.array([0.30, 0.42, 0.10])
DARK = np.array([0.20, 0.31, 0.09])
patch = fbm(xx, yy, 6, 4, 7.0)
g = np.where(patch[..., None] > 0.55,
             LIT[None, None, :] * (0.9 + 0.2 * patch[..., None]),
             MID[None, None, :])
deep_m = np.clip((0.42 - patch) / 0.2, 0, 1)[..., None]
g = g * (1 - deep_m) + DARK[None, None, :] * deep_m
# blade speckle: fine high-freq value jitter
blade = vnoise(xx, yy, 256, 13.0) - 0.5
g *= (1.0 + 0.22 * blade[..., None])
# sparse dry-yellow flecks + tiny white flowers
dry = vnoise(xx, yy, 48, 29.0)
dry_m = np.clip((dry - 0.90) / 0.1, 0, 1)[..., None] * 0.5
g = g * (1 - dry_m) + np.array([0.55, 0.50, 0.18])[None, None, :] * dry_m
flo = vnoise(xx, yy, 128, 37.0)
flo_m = np.clip((flo - 0.985) / 0.015, 0, 1)[..., None]
g = g * (1 - flo_m) + np.array([0.85, 0.85, 0.75])[None, None, :] * flo_m
save("grass_albedo_01.png", g)

# Modulation variant: mean-normalized so BLEND_MODE_MUL over the terrain's
# vertex-color zone ramp adds patch/blade variation WITHOUT darkening or
# repainting the zones (riverbank/dry-zone tints survive).
g_mean = g.mean(axis=(0, 1), keepdims=True)
g_mod = np.clip(g / g_mean * 0.92, 0.72, 1.22) / 1.22
save("grass_mod_01.png", g_mod)

# ── Grass normal (from a blade-scale height field) ─────────────────────────
h_field = fbm(xx, yy, 128, 3, 51.0) + 0.4 * (vnoise(xx, yy, 256, 13.0) - 0.5)
gy, gx = np.gradient(h_field)
strength = 6.0
n = np.stack([-gx * strength, gy * strength, np.ones_like(h_field)], axis=-1)
n /= np.linalg.norm(n, axis=-1, keepdims=True)
save("grass_normal_01.png", n * 0.5 + 0.5)

print("[textures] DONE")
