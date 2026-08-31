# assemble_gifs.py — stitches the rendered anim/<clip>_NNN.png frames (from
# build_rat.py, rendered at stride 2 @ 24fps) into looping GIFs per the ficha
# showcase convention (_mob_style_contract.md §4). Plain python (PIL), not blender.
# Run: python assemble_gifs.py
import glob
import os
from PIL import Image

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")

FPS = 24
STRIDE = 2
DURATION_MS = round(1000 * STRIDE / FPS)  # frames rendered every 2nd tick @ 24fps

CLIPS = ["idle", "move", "attack", "hit", "death"]

for clip in CLIPS:
    paths = sorted(glob.glob(os.path.join(ANIM_DIR, f"{clip}_*.png")))
    if not paths:
        print(f"[gif] SKIP {clip}: no frames found")
        continue
    frames = [Image.open(p).convert("RGB") for p in paths]
    out_path = os.path.join(REN_DIR, f"rat_{clip}.gif")
    frames[0].save(
        out_path,
        save_all=True,
        append_images=frames[1:],
        duration=DURATION_MS,
        loop=0,
        optimize=False,
    )
    print(f"[gif] {clip}: {len(frames)} frames -> {out_path}")

print("[gif] DONE")
