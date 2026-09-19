#!/usr/bin/env python
"""Token discipline guard for Claude Code.

Built 2026-08-09 from a measured audit of 437 transcripts (30 days):

    images        563.9 MB of base64 across 2,119 reads  -- 95% of everything
    all text       48.5 MB (tool results, file reads, greps, prose)
    re-reads       205 of 416 Read calls in one session were the SAME file
                   (floor1_prairie.gd read 49 times, facet_closeup.png 11 times)
    cache read      7.37 BILLION tokens

The mechanism that makes this expensive is not the read itself: everything read
stays in the context and is re-sent as cache on EVERY later turn. A 280 KB image
opened at turn 10 is paid for again at turns 11 through 600. So the two rules
below are about what enters the context at all.

Modes:
  pre-read   PreToolUse/Read gate -- deny oversized images and identical re-reads
  report     Stop hook -- print what this session pulled in
"""
from __future__ import annotations

import json
import os
import sys

STATE_DIR = os.path.join(os.path.expanduser("~"), ".claude", ".token_guard")

# Metres of the problem: our own downscaled review images land at 40-80 KB, and a
# raw Blender render is 1.5-2 MB. 120 KB sits above the former and far below the
# latter, so it blocks exactly the unprepared read.
IMG_MAX_BYTES = 120 * 1024
IMG_EXT = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tif", ".tiff"}


def state_path(session_id: str) -> str:
    os.makedirs(STATE_DIR, exist_ok=True)
    safe = "".join(c for c in (session_id or "nosession") if c.isalnum() or c in "-_")
    return os.path.join(STATE_DIR, f"{safe}.json")


def load(session_id: str) -> dict:
    try:
        with open(state_path(session_id), "r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {"reads": {}, "image_bytes": 0, "image_count": 0, "text_bytes": 0}


def save(session_id: str, st: dict) -> None:
    try:
        with open(state_path(session_id), "w", encoding="utf-8") as fh:
            json.dump(st, fh)
    except Exception:
        pass


def deny(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def pre_read(payload: dict) -> None:
    tin = payload.get("tool_input") or {}
    path = tin.get("file_path")
    if not path:
        sys.exit(0)
    try:
        stat = os.stat(path)
    except OSError:
        sys.exit(0)                      # let Read produce its own error

    session = payload.get("session_id") or ""
    st = load(session)
    ext = os.path.splitext(path)[1].lower()
    is_image = ext in IMG_EXT

    # Slice-aware key: re-reading a DIFFERENT part of a big file is legitimate
    # work; re-reading the identical slice of an unchanged file is not.
    key = f"{path}|{tin.get('offset', '')}|{tin.get('limit', '')}|{tin.get('pages', '')}"
    prev = st["reads"].get(key)

    if is_image and stat.st_size > IMG_MAX_BYTES:
        deny(
            f"IMAGE TOO LARGE for context: {os.path.basename(path)} is "
            f"{stat.st_size/1024:.0f} KB (cap {IMG_MAX_BYTES//1024} KB).\n\n"
            "Images are ~95% of what fills the context, and every one of them is "
            "re-sent as cache on every later turn. Downscale first, then read the "
            "copy:\n\n"
            "  python -c \"from PIL import Image; im=Image.open(r'" + path + "').convert('RGB'); "
            "w,h=im.size; nw=900; im.resize((nw,round(h*nw/w))).save(r'<scratchpad>\\preview.jpg','JPEG',quality=80)\"\n\n"
            "A 900px q80 JPEG carries the same verdict at roughly a fifth of the cost."
        )

    if prev and prev.get("mtime") == stat.st_mtime and prev.get("size") == stat.st_size:
        deny(
            f"ALREADY READ, UNCHANGED: {os.path.basename(path)} was read "
            f"{prev.get('count', 1)}x this session and has not been modified since.\n\n"
            "It is already in your context -- scroll back instead of paying for it "
            "again. If you need a different part, pass offset/limit and this gate "
            "will let it through. If you edited it, the change will be detected "
            "automatically."
        )

    st["reads"][key] = {
        "mtime": stat.st_mtime,
        "size": stat.st_size,
        "count": (prev or {}).get("count", 0) + 1,
    }
    if is_image:
        st["image_bytes"] += stat.st_size
        st["image_count"] += 1
    else:
        st["text_bytes"] += stat.st_size
    save(session, st)
    sys.exit(0)


def nudge(payload: dict) -> None:
    """UserPromptSubmit: warn when a session is turning into a monster.

    Measured over 60 days: 5 sessions out of 44 carried 50% of all output, and
    the single worst carried 33% by itself -- 25x the median session. The reason
    is structural, not sloppiness: cache-read cost is context x requests, so a
    session that keeps growing pays for its whole history on every later turn.
    Splitting the same work across four sessions costs roughly a quarter.

    This is the lever the image cap and the re-read gate cannot touch, so it gets
    its own reminder. It never blocks -- ending a session is the user's call.
    """
    session = payload.get("session_id") or ""
    st = load(session)
    st["turns"] = st.get("turns", 0) + 1
    save(session, st)
    turns = st["turns"]
    reads = len(st.get("reads", {}))
    imgs = st.get("image_count", 0)
    if turns in (60, 120, 200) or (turns > 200 and turns % 100 == 0):
        print(json.dumps({"systemMessage":
            f"sesion larga: {turns} turnos, {reads} archivos, {imgs} imagenes. "
            f"El costo de cache crece con contexto x turnos -- considera /compact "
            f"o cerrar y abrir sesion nueva para la proxima tarea."}))
    sys.exit(0)


def report(payload: dict) -> None:
    st = load(payload.get("session_id") or "")
    n_img = st.get("image_count", 0)
    if not n_img and not st.get("reads"):
        sys.exit(0)
    img_mb = st.get("image_bytes", 0) / 1048576
    txt_mb = st.get("text_bytes", 0) / 1048576
    msg = (f"peso de contexto: {n_img} imagenes ({img_mb:.1f} MB) + "
           f"{len(st.get('reads', {}))} lecturas de archivo ({txt_mb:.1f} MB)")
    print(json.dumps({"systemMessage": msg, "suppressOutput": True}))
    sys.exit(0)


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "pre-read"
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)                      # never break the session over the guard
    if mode == "report":
        report(payload)
    elif mode == "nudge":
        nudge(payload)
    else:
        pre_read(payload)


if __name__ == "__main__":
    main()
