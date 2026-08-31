#!/usr/bin/env python
"""Assemble animated GIFs from numbered PNG frame sequences.

Motion cannot be judged from stills — a sparse strip of frames hides exactly the
timing and weight problems that matter (the golem lesson: chunk animations "se
entienden pero no se ven bien" passed every still review). A looping GIF is the
cheapest artefact that shows the motion itself, and it opens in a browser with
no tooling.

Usage:
  python _make_gifs.py --dir renders/anim --out renders --fps 24 \\
      --clip idle --clip hop --clip hit --clip attack --clip death

Each --clip NAME globs NAME_*.png in --dir, sorted by the numeric suffix.
"""
import argparse
import glob
import os
import re
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("_make_gifs: Pillow required (pip install pillow)")

NUM = re.compile(r"_(\d+)\.png$", re.IGNORECASE)


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True, help="directory holding the frames")
    ap.add_argument("--out", required=True, help="directory to write the GIFs to")
    ap.add_argument("--fps", type=float, default=24.0,
                    help="frame rate the frames were rendered at")
    ap.add_argument("--step", type=int, default=1,
                    help="frames were rendered every Nth frame (affects timing)")
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--clip", action="append", default=[], required=True)
    ap.add_argument("--pattern", default="{clip}_*.png")
    ap.add_argument("--name", default="{clip}.gif")
    return ap.parse_args()


def frame_key(path):
    m = NUM.search(os.path.basename(path))
    return int(m.group(1)) if m else 0


def is_frame(path):
    """A frame file ends in _<number>.png.

    Without this check a glob like slime_death_*.png also swallows
    slime_death_showcase.png — the contact sheet for that very clip — and it
    lands as frame 0 of the GIF.
    """
    return NUM.search(os.path.basename(path)) is not None


def main():
    args = parse_args()
    os.makedirs(args.out, exist_ok=True)
    # Each rendered frame stands in for `step` source frames, so the GIF's
    # per-frame duration has to account for that or the motion plays too fast.
    duration_ms = max(20, int(round(1000.0 * args.step / args.fps)))
    made = 0
    for clip in args.clip:
        pattern = os.path.join(args.dir, args.pattern.format(clip=clip))
        paths = sorted((p for p in glob.glob(pattern) if is_frame(p)), key=frame_key)
        if not paths:
            print(f"[gif] {clip}: no frames matched {pattern} — skipped")
            continue
        frames = []
        for p in paths:
            img = Image.open(p).convert("RGB")
            if args.scale != 1.0:
                img = img.resize((int(img.width * args.scale),
                                  int(img.height * args.scale)), Image.LANCZOS)
            frames.append(img)
        out_path = os.path.join(args.out, args.name.format(clip=clip))
        frames[0].save(out_path, save_all=True, append_images=frames[1:],
                       duration=duration_ms, loop=0, optimize=True,
                       disposal=2)
        kb = os.path.getsize(out_path) / 1024.0
        print(f"[gif] {out_path} — {len(frames)} frames @ {duration_ms}ms "
              f"({kb:.0f} KB)")
        made += 1
    if made == 0:
        sys.exit("_make_gifs: no GIFs produced")


if __name__ == "__main__":
    main()
