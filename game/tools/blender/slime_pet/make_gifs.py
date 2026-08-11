# make_gifs.py -- assemble renders/anim/<clip>_NN.png into renders/slime_pet_<clip>.gif
#
# Run with SYSTEM python (needs PIL), NOT Blender's -- Blender ships its own
# interpreter and it has no Pillow:
#   python make_gifs.py
#
# The pet renders on a transparent film (it has to sit on the user's wallpaper),
# and a straight .convert("RGB") turns that transparency BLACK -- a pale blue-grey
# creature on black is judged against a contrast it will never actually have. So
# every frame is composited over the same light card the contact sheets use.
import os
import re

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(HERE, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")

FPS = 12
FRAME_MS = round(1000 / FPS)
CARD = (237, 240, 235)

CLIPS = ["idle", "hop"]


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
        print(f"[gif] SKIP {clip}: no frames in {ANIM_DIR}")
        continue
    imgs = []
    for p in paths:
        src = Image.open(p).convert("RGBA")
        card = Image.new("RGBA", src.size, CARD + (255,))
        imgs.append(Image.alpha_composite(card, src).convert("RGB"))
    out_path = os.path.join(REN_DIR, f"slime_pet_{clip}.gif")
    imgs[0].save(out_path, save_all=True, append_images=imgs[1:],
                 duration=FRAME_MS, loop=0, optimize=False)
    print(f"[gif] {clip}: {len(imgs)} frames @ {FPS}fps -> {out_path}")

print("[gif] DONE")
