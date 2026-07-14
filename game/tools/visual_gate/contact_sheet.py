"""contact_sheet.py — compose the 2D REFERENCE + all render shots into ONE grid image.

THE KEY PIECE. Claude has NO absolute-quality alarm; it is strong at DIFFERENCES
(two images side by side) and weak at judging one image from memory of a reference.
Every wrong PASS on Filomeno came from "comparing from memory". This tool removes
that failure mode: it bakes the 2D ref and every angle into a SINGLE labeled image,
so the judgment call is always a side-by-side diff, never a recall.

NO PIL (not guaranteed in Blender's Python). Uses bpy.data.images + numpy only, with a
built-in 5x7 bitmap font so every cell is captioned and the reference is unmistakable
(bright green border + "REF-2D"). Runs inside Blender headless.

Colorspace: every image is loaded as Non-Color so .pixels give the raw stored bytes;
the sheet round-trips them without a tonemap shift (what you see = the source PNGs).

Run:
  blender.exe -b --factory-startup --python contact_sheet.py -- \
      --out sheet.png --ref REF-2D=/path/ref.png \
      --cols 4 --cell-h 360 \
      front=/path/orbit_000.png  low=/path/worm_00.png  face=/path/face_00.png ...

Or point it at an orbit_capture manifest to auto-collect the shots:
  ... --ref REF-2D=/path/ref.png --manifest /path/out/manifest.json --cols 4
"""
import bpy, sys, os, json
import numpy as np

# --- compact 5x7 uppercase bitmap font (load-bearing: makes the sheet self-labeling)
_F = {
 'A':["01110","10001","10001","11111","10001","10001","10001"],
 'B':["11110","10001","11110","10001","10001","10001","11110"],
 'C':["01110","10001","10000","10000","10000","10001","01110"],
 'D':["11110","10001","10001","10001","10001","10001","11110"],
 'E':["11111","10000","11110","10000","10000","10000","11111"],
 'F':["11111","10000","11110","10000","10000","10000","10000"],
 'G':["01110","10001","10000","10111","10001","10001","01111"],
 'H':["10001","10001","10001","11111","10001","10001","10001"],
 'I':["01110","00100","00100","00100","00100","00100","01110"],
 'J':["00111","00010","00010","00010","10010","10010","01100"],
 'K':["10001","10010","10100","11000","10100","10010","10001"],
 'L':["10000","10000","10000","10000","10000","10000","11111"],
 'M':["10001","11011","10101","10101","10001","10001","10001"],
 'N':["10001","11001","10101","10011","10001","10001","10001"],
 'O':["01110","10001","10001","10001","10001","10001","01110"],
 'P':["11110","10001","10001","11110","10000","10000","10000"],
 'Q':["01110","10001","10001","10001","10101","10010","01101"],
 'R':["11110","10001","10001","11110","10100","10010","10001"],
 'S':["01111","10000","10000","01110","00001","00001","11110"],
 'T':["11111","00100","00100","00100","00100","00100","00100"],
 'U':["10001","10001","10001","10001","10001","10001","01110"],
 'V':["10001","10001","10001","10001","10001","01010","00100"],
 'W':["10001","10001","10001","10101","10101","11011","10001"],
 'X':["10001","10001","01010","00100","01010","10001","10001"],
 'Y':["10001","10001","01010","00100","00100","00100","00100"],
 'Z':["11111","00001","00010","00100","01000","10000","11111"],
 '0':["01110","10011","10101","10101","11001","10001","01110"],
 '1':["00100","01100","00100","00100","00100","00100","01110"],
 '2':["01110","10001","00001","00110","01000","10000","11111"],
 '3':["11110","00001","00001","01110","00001","00001","11110"],
 '4':["00010","00110","01010","10010","11111","00010","00010"],
 '5':["11111","10000","11110","00001","00001","10001","01110"],
 '6':["00110","01000","10000","11110","10001","10001","01110"],
 '7':["11111","00001","00010","00100","01000","01000","01000"],
 '8':["01110","10001","10001","01110","10001","10001","01110"],
 '9':["01110","10001","10001","01111","00001","00010","01100"],
 '-':["00000","00000","00000","11111","00000","00000","00000"],
 '_':["00000","00000","00000","00000","00000","00000","11111"],
 '/':["00001","00010","00010","00100","01000","01000","10000"],
 ':':["00000","00100","00100","00000","00100","00100","00000"],
 '.':["00000","00000","00000","00000","00000","01100","01100"],
 ' ':["00000","00000","00000","00000","00000","00000","00000"],
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    opts = {"out": "contact_sheet.png", "cols": 4, "cell-h": 360,
            "ref": None, "manifest": None}
    tiles = []          # list of (label, path)
    i = 0
    while i < len(argv):
        tok = argv[i]
        k = tok.lstrip("-")
        if k in opts and not (tok.count("=") and not tok.startswith("--")):
            opts[k] = argv[i + 1]; i += 2; continue
        if "=" in tok:                       # label=path tile
            lbl, pth = tok.split("=", 1)
            tiles.append((lbl, pth)); i += 1; continue
        i += 1
    opts["cols"] = int(opts["cols"]); opts["cell-h"] = int(opts["cell-h"])
    return opts, tiles


def load_rgb(path, cell_h):
    """Load PNG as raw RGB float array (top-down), nearest-resized to cell_h."""
    img = bpy.data.images.load(path, check_existing=False)
    try:
        img.colorspace_settings.name = "Non-Color"   # raw bytes, no tonemap
    except Exception:
        pass
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    arr = buf.reshape(h, w, 4)[::-1, :, :3]           # bottom-up -> top-down, drop A
    bpy.data.images.remove(img)
    # nearest-neighbor resize to cell_h (keep aspect)
    new_h = cell_h
    new_w = max(1, int(round(w * cell_h / h)))
    ys = (np.arange(new_h) * h / new_h).astype(np.int64)
    xs = (np.arange(new_w) * w / new_w).astype(np.int64)
    return arr[ys][:, xs]


def stamp_text(canvas, x, y, text, color, scale=2):
    """Draw uppercase text with the 5x7 font at top-left (x,y) into canvas (top-down)."""
    cx = x
    for ch in text.upper():
        glyph = _F.get(ch, _F[" "])
        for ry, row in enumerate(glyph):
            for rx, bit in enumerate(row):
                if bit == "1":
                    y0 = y + ry * scale; x0 = cx + rx * scale
                    canvas[y0:y0 + scale, x0:x0 + scale] = color
        cx += (5 + 1) * scale
    return cx


def main():
    opts, tiles = parse_args()
    cell_h = opts["cell-h"]

    cells = []   # (label, rgb_array, is_ref)
    if opts["ref"]:
        lbl, pth = opts["ref"].split("=", 1)
        cells.append((lbl, load_rgb(pth, cell_h), True))

    if opts["manifest"]:
        man = json.load(open(opts["manifest"]))
        for s in man["shots"]:
            cells.append((s["label"], load_rgb(s["path"], cell_h), False))
    for lbl, pth in tiles:
        cells.append((lbl, load_rgb(pth, cell_h), False))

    if not cells:
        raise SystemExit("[sheet] no tiles. pass --ref and/or label=path / --manifest")

    cell_w = max(c[1].shape[1] for c in cells)
    LABEL_H = 7 * 2 + 8               # font height*scale + padding
    PAD = 6
    cw = cell_w + PAD * 2
    ch = cell_h + LABEL_H + PAD
    cols = opts["cols"]
    rows = (len(cells) + cols - 1) // cols

    BG = np.array([0.12, 0.12, 0.13], dtype=np.float32)
    canvas = np.ones((rows * ch, cols * cw, 3), dtype=np.float32) * BG

    green = np.array([0.20, 0.95, 0.30], dtype=np.float32)
    grey = np.array([0.55, 0.55, 0.58], dtype=np.float32)
    white = np.array([0.95, 0.95, 0.95], dtype=np.float32)

    for idx, (label, rgb, is_ref) in enumerate(cells):
        r = idx // cols; c = idx % cols
        oy = r * ch; ox = c * cw
        # label strip
        col = green if is_ref else white
        stamp_text(canvas, ox + PAD, oy + 3, label[:16], col, scale=2)
        # image
        iy = oy + LABEL_H; ix = ox + PAD + (cell_w - rgb.shape[1]) // 2
        canvas[iy:iy + rgb.shape[0], ix:ix + rgb.shape[1]] = rgb
        # border: bright green for the REFERENCE, grey for renders
        bcol = green if is_ref else grey
        bt = 3 if is_ref else 1
        y1 = iy + cell_h; x1 = ix + rgb.shape[1]
        canvas[iy:iy + bt, ix:x1] = bcol
        canvas[y1 - bt:y1, ix:x1] = bcol
        canvas[iy:y1, ix:ix + bt] = bcol
        canvas[iy:y1, x1 - bt:x1] = bcol

    # write out via a new bpy image (Non-Color round-trip)
    H, W = canvas.shape[:2]
    rgba = np.ones((H, W, 4), dtype=np.float32)
    rgba[:, :, :3] = np.clip(canvas, 0.0, 1.0)
    out_img = bpy.data.images.new("contact_sheet", W, H, alpha=True, float_buffer=False)
    try:
        out_img.colorspace_settings.name = "Non-Color"
    except Exception:
        pass
    out_img.pixels.foreach_set(rgba[::-1].reshape(-1))   # top-down -> bottom-up
    out_img.filepath_raw = os.path.abspath(opts["out"])
    out_img.file_format = "PNG"
    out_img.save()
    print("[sheet] %d cells, grid %dx%d -> %s (%dx%d)"
          % (len(cells), cols, rows, opts["out"], W, H))


if __name__ == "__main__":
    main()
