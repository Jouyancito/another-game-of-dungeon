# make_gifs.py — assemble renders/anim/<clip>_###.png sequences into
# renders/guardian_<clip>.gif (512x640, matches build_golem_guardian.py's anim
# frame render resolution). awaken renders every 3rd frame (7s clip would be
# huge otherwise); all other clips render every 2nd frame. Run: python make_gifs.py
import glob
import os
from PIL import Image

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
ANIM_DIR = os.path.join(OUT_DIR, "renders", "anim")
REN_DIR = os.path.join(OUT_DIR, "renders")

FPS = 24
CLIP_STEP = {
    "idle": 2,
    "awaken": 3,
    "move": 2,
    "attack": 2,
    "hit": 2,
    "death": 2,
}

for clip, step in CLIP_STEP.items():
    paths = sorted(glob.glob(os.path.join(ANIM_DIR, f"{clip}_*.png")))
    if not paths:
        print(f"[make_gifs] SKIP {clip}: no frames found")
        continue
    frames = [Image.open(p).convert("RGBA") for p in paths]
    duration_ms = round(1000 * step / FPS)
    out_path = os.path.join(REN_DIR, f"guardian_{clip}.gif")
    frames[0].save(
        out_path,
        save_all=True,
        append_images=frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
    )
    print(f"[make_gifs] wrote {out_path} ({len(frames)} frames)")
