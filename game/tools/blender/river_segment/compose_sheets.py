# compose_sheets.py -- contact sheets for river_segment renders (system
# python + Pillow; Blender's python has no PIL).
#
#   python compose_sheets.py v4 2        -> renders/river_v4_a2_contact_sheet.png
#   python compose_sheets.py v4 ramp     -> renders/river_v4_ramp_contact_sheet.png
#   python compose_sheets.py 2           -> v3 (compat): renders/river_v3_r2_contact_sheet.png
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
RENDERS = os.path.join(HERE, "renders")
SHOTS = ["hero", "player_eye", "cenital", "waterline_1m", "downstream_low", "behind_wall"]
LABELS = {
    "hero": "hero (3/4 overview)",
    "player_eye": "player eye, 1.65 m, 6 m off the bank",
    "cenital": "top-down (vegetation hidden)",
    "waterline_1m": "waterline at 1 m (slabs)",
    "downstream_low": "downstream, 0.6 m over the water",
    "behind_wall": "from behind the wall bank",
}
VER = {
    "v3": dict(stem="river_v3_r", ramp={1: "r1: wall blocks 0.8-1.5 m", 2: "r2: wall blocks 1.2-2.2 m", 3: "r3: wall blocks 1.8-3.0 m"},
               ramp_title="river_segment_v3 ramp: wall block size r1 / r2 / r3 (Joan picks)"),
    "v4": dict(stem="river_v4_a", ramp={1: "a1: relief 0.06 (pool-smooth)", 2: "a2: relief 0.12 (worn)", 3: "a3: relief 0.20 (barely eaten)"},
               ramp_title="river_segment_v4 ramp: how much the river wore the stone a1 / a2 / a3 (Joan picks)"),
    "v5": dict(stem="river_v5_w", ramp={1: "w1: 30 % of the edge network eaten", 2: "w2: 50 % eaten", 3: "w3: 70 % eaten"},
               ramp_title="river_segment_v5 ramp: wear degree w1 / w2 / w3 (Joan picks)"),
}


def grid(cells, cols, title, out, cell_w=1280, cell_h=800):
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h + 44), (22, 22, 22))
    d = ImageDraw.Draw(sheet)
    d.text((10, 12), title, fill=(255, 255, 255))
    for k, (label, path) in enumerate(cells):
        x = (k % cols) * cell_w; y = (k // cols) * cell_h + 44
        if os.path.exists(path):
            im = Image.open(path).convert("RGB")
            im = im.resize((cell_w, cell_h))
            sheet.paste(im, (x, y))
        else:
            d.rectangle([x, y, x + cell_w, y + cell_h], outline=(200, 60, 60))
            d.text((x + 20, y + 20), f"MISSING {os.path.basename(path)}", fill=(255, 80, 80))
        d.rectangle([x, y, x + 8 + 7 * len(label), y + 18], fill=(0, 0, 0))
        d.text((x + 4, y + 3), label, fill=(255, 255, 255))
    sheet.save(out)
    print(out, sheet.size)


def variant_sheet(ver, v):
    c = VER[ver]
    cells = [(LABELS[s], os.path.join(RENDERS, f"{c['stem']}{v}_{s}.png")) for s in SHOTS]
    grid(cells, 3, f"river_segment_{ver}_{'a' if ver == 'v4' else 'r'}{v}.glb -- {c['ramp'][v]} -- red post = 1.8 m player",
         os.path.join(RENDERS, f"{c['stem']}{v}_contact_sheet.png"))


CRACKDARK = {1: ("d1", "x0.70 subtle"), 2: ("d2", "x0.55 mid"), 3: ("d3", "x0.40 marked")}


def crackdark_sheet():
    cells = []
    for shot in ("waterline_1m", "player_eye"):
        for v in (1, 2, 3):
            tag, label = CRACKDARK[v]
            cells.append((f"{tag}: seam albedo {label} -- {shot}",
                          os.path.join(RENDERS, f"river_v5_w2_{tag}_{shot}.png")))
    grid(cells, 3, "river_segment_v5 w2 crack darkening ramp d1 / d2 / d3 (Joan picks) -- red post = 1.8 m player",
         os.path.join(RENDERS, "river_v5_crackdark_ramp_contact_sheet.png"))


def kit_sheet():
    cells = [("board 3/4", os.path.join(RENDERS, "river_rock_kit_board_34.png")),
             ("board front", os.path.join(RENDERS, "river_rock_kit_board_front.png")),
             ("board low", os.path.join(RENDERS, "river_rock_kit_board_low.png"))]
    for k in range(1, 7):
        cells.append((f"close-up {k:02d}", os.path.join(RENDERS, f"river_rock_kit_close_{k:02d}.png")))
    grid(cells, 3, "river_rock_worn_kit.glb -- 6 loose w2/d2 stones for the runtime scatter -- red post = 1.8 m player",
         os.path.join(RENDERS, "river_rock_kit_contact_sheet.png"))


def ramp_sheet(ver):
    c = VER[ver]
    cells = []
    for v in (1, 2, 3):
        cells.append((f"{c['ramp'][v]} -- hero", os.path.join(RENDERS, f"{c['stem']}{v}_hero.png")))
    for v in (1, 2, 3):
        cells.append((f"{c['ramp'][v]} -- player eye", os.path.join(RENDERS, f"{c['stem']}{v}_player_eye.png")))
    grid(cells, 3, c["ramp_title"],
         os.path.join(RENDERS, f"river_{ver}_ramp_contact_sheet.png"))


if __name__ == "__main__":
    args = sys.argv[1:]
    ver = "v3"
    if args and args[0] in VER:
        ver = args[0]; args = args[1:]
    arg = args[0] if args else "2"
    if arg == "ramp":
        ramp_sheet(ver)
    elif arg == "crackdark":
        crackdark_sheet()
    elif arg == "kit":
        kit_sheet()
    else:
        variant_sheet(ver, int(arg))
