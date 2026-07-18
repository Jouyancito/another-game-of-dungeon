# _make_gifs.py — assemble renders/anim/<clip>_NNN.png frame sequences into
# renders/turtle_<clip>.gif (contract §4: 512x640 per-animation GIF).
# Run: python _make_gifs.py
import glob
import os

from PIL import Image

BASE = os.path.dirname(os.path.abspath(__file__))
ANIM_DIR = os.path.join(BASE, "renders", "anim")
OUT_DIR = os.path.join(BASE, "renders")

CLIPS = ["idle", "move", "attack", "hit", "death"]
DURATION_MS = 80

for clip in CLIPS:
    frames = sorted(glob.glob(os.path.join(ANIM_DIR, f"{clip}_*.png")))
    if not frames:
        print(f"[gif] SKIP {clip}: no frames found")
        continue
    imgs = [Image.open(f).convert("RGB") for f in frames]
    # loop-suffixed clips (idle/move) loop forever; one-shots (attack/hit/death) play once
    loop = 0 if clip in ("idle", "move") else 1
    out = os.path.join(OUT_DIR, f"turtle_{clip}.gif")
    imgs[0].save(out, save_all=True, append_images=imgs[1:], duration=DURATION_MS, loop=loop, disposal=2)
    print(f"[gif] wrote {out} ({len(imgs)} frames)")
