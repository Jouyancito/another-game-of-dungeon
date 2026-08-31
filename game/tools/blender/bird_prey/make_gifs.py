# make_gifs.py — assemble renders/anim/<clip>_###.png sequences into
# renders/bird_<clip>.gif (512x640, matches build_bird.py's anim frame render
# resolution). Run: python make_gifs.py
import glob
import os
from PIL import Image

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
ANIM_DIR = os.path.join(OUT_DIR, "renders", "anim")
REN_DIR = os.path.join(OUT_DIR, "renders")

CLIPS = ["idle", "move", "attack", "hit", "death"]
FPS = 24
FRAME_STEP = 2  # build_bird.py renders every 2nd frame
DURATION_MS = round(1000 * FRAME_STEP / FPS)

for clip in CLIPS:
    paths = sorted(glob.glob(os.path.join(ANIM_DIR, f"{clip}_*.png")))
    if not paths:
        print(f"[make_gifs] SKIP {clip}: no frames found")
        continue
    frames = [Image.open(p).convert("RGBA") for p in paths]
    out_path = os.path.join(REN_DIR, f"bird_{clip}.gif")
    frames[0].save(
        out_path,
        save_all=True,
        append_images=frames[1:],
        duration=DURATION_MS,
        loop=0,
        disposal=2,
    )
    print(f"[make_gifs] wrote {out_path} ({len(frames)} frames)")
