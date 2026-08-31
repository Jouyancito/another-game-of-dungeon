"""Print per-mesh bounds and COLOR_0 statistics for one or more .glb files.

Pure Python — no Blender, no dependencies. Blender startup costs ~4s per file and
this answers the two questions that keep coming up when tuning scatter and shaders:

  * How big is this asset in metres?  (scatter scale ranges are meaningless
    without the native size — see _asset_inventory_p1.md)
  * Does it carry baked vertex colour, and what is the actual value range?
    A shader that multiplies by COLOR needs to know whether the mesh ships
    near-white (unpainted) or a real painterly gradient, or it will blow out.

Usage:
    python _glb_stats.py <file.glb> [more.glb ...]
"""
from __future__ import annotations

import json
import struct
import sys

# glTF accessor componentType -> (struct format, size in bytes, normalisation divisor)
COMPONENT = {
    5120: ("b", 1, 127.0),
    5121: ("B", 1, 255.0),
    5122: ("h", 2, 32767.0),
    5123: ("H", 2, 65535.0),
    5125: ("I", 4, 1.0),
    5126: ("f", 4, 1.0),
}
TYPE_COUNT = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load_glb(path: str) -> tuple[dict, bytes]:
    with open(path, "rb") as fh:
        data = fh.read()
    magic, _version, _length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise ValueError(f"{path} is not a binary glTF container")
    offset = 12
    gltf: dict | None = None
    binary = b""
    while offset < len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        body = data[offset + 8 : offset + 8 + chunk_len]
        if chunk_type == 0x4E4F534A:  # 'JSON'
            gltf = json.loads(body.decode("utf-8"))
        elif chunk_type == 0x004E4942:  # 'BIN'
            binary = body
        offset += 8 + chunk_len + (-chunk_len % 4)
    if gltf is None:
        raise ValueError(f"{path} has no JSON chunk")
    return gltf, binary


def read_accessor(gltf: dict, binary: bytes, index: int) -> list[tuple[float, ...]]:
    acc = gltf["accessors"][index]
    fmt, comp_size, divisor = COMPONENT[acc["componentType"]]
    n = TYPE_COUNT[acc["type"]]
    count = acc["count"]
    view = gltf["bufferViews"][acc["bufferView"]]
    base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    # A byteStride only appears on interleaved views; tightly packed is the default.
    stride = view.get("byteStride") or comp_size * n
    normalized = acc.get("normalized", False) and divisor != 1.0

    out: list[tuple[float, ...]] = []
    for i in range(count):
        raw = struct.unpack_from("<" + fmt * n, binary, base + i * stride)
        out.append(tuple(v / divisor for v in raw) if normalized else tuple(float(v) for v in raw))
    return out


def describe(path: str) -> None:
    gltf, binary = load_glb(path)
    print(f"\n=== {path.rsplit('/', 1)[-1]} ===")

    lo = [1e9, 1e9, 1e9]
    hi = [-1e9, -1e9, -1e9]
    colour_channels: list[list[float]] = [[], [], [], []]
    vertex_total = 0
    meshes_with_colour = 0

    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            attrs = prim.get("attributes", {})
            if "POSITION" in attrs:
                acc = gltf["accessors"][attrs["POSITION"]]
                # glTF requires min/max on POSITION accessors, so trust them when present.
                if "min" in acc and "max" in acc:
                    for i in range(3):
                        lo[i] = min(lo[i], acc["min"][i])
                        hi[i] = max(hi[i], acc["max"][i])
                vertex_total += acc["count"]
            if "COLOR_0" in attrs:
                meshes_with_colour += 1
                acc = gltf["accessors"][attrs["COLOR_0"]]
                comp_name = {5121: "u8", 5123: "u16", 5126: "FLOAT"}.get(
                    acc["componentType"], str(acc["componentType"]))
                print(f"  COLOR_0: {acc['type']} {comp_name} "
                      f"normalized={acc.get('normalized', False)} count={acc['count']}")
                for vals in read_accessor(gltf, binary, attrs["COLOR_0"]):
                    for c in range(min(len(vals), 4)):
                        colour_channels[c].append(vals[c])

    if lo[0] < 1e9:
        # glTF is Y-up, metres. Godot shares that convention, so these are the
        # numbers the scatter scale ranges multiply.
        print(f"  DIMS (glTF Y-up, m): X={hi[0]-lo[0]:.3f}  "
              f"Y={hi[1]-lo[1]:.3f}  Z={hi[2]-lo[2]:.3f}")
        print(f"  Y range: [{lo[1]:.3f}, {hi[1]:.3f}]")
    print(f"  vertices: {vertex_total}   primitives with COLOR_0: {meshes_with_colour}")

    if not colour_channels[0]:
        print("  NO vertex colour — a shader multiplying by COLOR would read white.")
        return
    for name, vals in zip("RGBA", colour_channels):
        if not vals:
            continue
        mean = sum(vals) / len(vals)
        print(f"  {name}: min={min(vals):.3f} max={max(vals):.3f} mean={mean:.3f}")
    luma = [0.299 * r + 0.587 * g + 0.114 * b
            for r, g, b in zip(colour_channels[0], colour_channels[1], colour_channels[2])]
    print(f"  luma: min={min(luma):.3f} max={max(luma):.3f} "
          f"mean={sum(luma)/len(luma):.3f}   <- shader normalisation divisor")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(1)
    for arg in sys.argv[1:]:
        describe(arg)
