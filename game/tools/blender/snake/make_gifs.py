# make_gifs.py — assemble renders/anim/<clip>_NNN.png frames into renders/snake_<clip>.gif
# Run with system python (needs PIL), NOT blender's python:
#   python make_gifs.py
import os
import re
from PIL import Image

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")

FPS = 24
STEP = 2                                   # frames were rendered every 2nd frame
FRAME_MS = round(1000 * STEP / FPS)        # 83ms per frame

CLIPS = ["idle", "move", "attack", "hit", "death"]
LOOP_CLIPS = {"idle", "move"}              # -loop clips loop forever in Godot too


def frames_for(clip):
    pat = re.compile(rf"^{clip}_(\d+)\.png$")
    found = []
    for name in os.listdir(ANIM_DIR):
        m = pat.match(name)
        if m:
            found.append((int(m.group(1)), os.path.join(ANIM_DIR, name)))
    found.sort(key=lambda x: x[0])
    return [p for _, p in found]


for clip in CLIPS:
    paths = frames_for(clip)
    if not paths:
        print(f"[gif] SKIP {clip}: no frames found")
        continue
    imgs = [Image.open(p).convert("RGB") for p in paths]
    out_path = os.path.join(REN_DIR, f"snake_{clip}.gif")
    loop = 0 if clip in LOOP_CLIPS else 1   # 0 = infinite loop, 1 = play once then stop
    imgs[0].save(
        out_path,
        save_all=True,
        append_images=imgs[1:],
        duration=FRAME_MS,
        loop=loop,
        optimize=False,
    )
    print(f"[gif] {clip}: {len(imgs)} frames -> {out_path}")

print("[gif] DONE")
