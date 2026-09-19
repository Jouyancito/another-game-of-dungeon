"""Project token savings and profile the working style, from real transcripts.

Adds what the first audit could not answer:
  - how much of the image load is DUPLICATE reads (recoverable at zero quality cost)
  - how concentrated spend is across sessions (is it many small, or a few monsters)
  - the weekly trend, for a two-month projection
"""
from __future__ import annotations

import collections
import datetime
import json
import os
import sys
import time

ROOT = r"C:\Users\the_j\.claude\projects"
DAYS = int(sys.argv[1]) if len(sys.argv) > 1 else 60
CUTOFF = time.time() - DAYS * 86400

sess_out = collections.Counter()
sess_cache = collections.Counter()
sess_first = {}
week_out = collections.Counter()
week_cache = collections.Counter()

img_reads = collections.Counter()      # path -> times read
img_bytes_first = {}                   # path -> base64 bytes (first sighting)
img_total_b64 = 0
img_total_count = 0


def week_of(ts: float) -> str:
    d = datetime.date.fromtimestamp(ts)
    return f"{d.isocalendar()[0]}-W{d.isocalendar()[1]:02d}"


for dirpath, _dirs, names in os.walk(ROOT):
    for nm in names:
        if not nm.endswith(".jsonl"):
            continue
        p = os.path.join(dirpath, nm)
        try:
            st = os.stat(p)
        except OSError:
            continue
        if st.st_mtime < CUTOFF:
            continue
        sid = nm[:8]
        pending = {}
        with open(p, "r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if not line.strip():
                    continue
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                ts = rec.get("timestamp")
                tsec = st.st_mtime
                if isinstance(ts, str):
                    try:
                        tsec = datetime.datetime.fromisoformat(
                            ts.replace("Z", "+00:00")).timestamp()
                    except Exception:
                        pass
                sess_first.setdefault(sid, tsec)

                msg = rec.get("message") or {}
                u = msg.get("usage") or {}
                if u:
                    o = u.get("output_tokens", 0) or 0
                    c = u.get("cache_read_input_tokens", 0) or 0
                    sess_out[sid] += o
                    sess_cache[sid] += c
                    week_out[week_of(tsec)] += o
                    week_cache[week_of(tsec)] += c

                content = msg.get("content")
                if not isinstance(content, list):
                    continue
                for b in content:
                    if not isinstance(b, dict):
                        continue
                    if b.get("type") == "tool_use":
                        pending[b.get("id")] = (b.get("name"),
                                                (b.get("input") or {}).get("file_path"))
                    elif b.get("type") == "tool_result":
                        nm2, fp = pending.get(b.get("tool_use_id"), (None, None))
                        cc = b.get("content")
                        if not isinstance(cc, list):
                            continue
                        for s in cc:
                            if isinstance(s, dict) and s.get("type") == "image":
                                nb = len((s.get("source") or {}).get("data") or "")
                                global_key = fp or f"<inline:{sid}:{nb}>"
                                img_reads[global_key] += 1
                                img_bytes_first.setdefault(global_key, nb)
                                img_total_b64 += nb
                                img_total_count += 1


def mb(n):
    return n / 1048576


print(f"=== ventana: {DAYS} dias ===")

# ---- concentration -------------------------------------------------------
tot_out = sum(sess_out.values())
ranked = sorted(sess_out.values(), reverse=True)
cum = 0
for i, v in enumerate(ranked, 1):
    cum += v
    if cum >= tot_out * 0.5:
        print(f"\nCONCENTRACION: {i} sesiones de {len(ranked)} "
              f"({100.0*i/len(ranked):.0f}%) concentran el 50% del output")
        break
print(f"  sesion mas cara: {ranked[0]:,} output  "
      f"({100.0*ranked[0]/tot_out:.0f}% del total)")
print(f"  mediana de sesion: {ranked[len(ranked)//2]:,} output")

# ---- duplicate images ----------------------------------------------------
dup_reads = sum(v - 1 for v in img_reads.values() if v > 1)
dup_bytes = sum(img_bytes_first[k] * (v - 1) for k, v in img_reads.items() if v > 1)
print(f"\nIMAGENES: {img_total_count:,} lecturas, {mb(img_total_b64):.0f} MB base64")
print(f"  de esas, RELECTURAS: {dup_reads:,} ({100.0*dup_reads/max(img_total_count,1):.0f}%)"
      f"  -> {mb(dup_bytes):.0f} MB puro desperdicio")
print(f"  imagenes unicas: {len(img_reads):,}")

# ---- weekly trend --------------------------------------------------------
print("\nTENDENCIA SEMANAL (output / cache read):")
for wk in sorted(week_out)[-9:]:
    print(f"  {wk}  out {week_out[wk]:>10,}   cache {week_cache[wk]:>14,}")

weeks = sorted(week_out)[-4:]
if len(weeks) >= 2:
    avg_out = sum(week_out[w] for w in weeks) / len(weeks)
    avg_cache = sum(week_cache[w] for w in weeks) / len(weeks)
    print(f"\nPROMEDIO ultimas {len(weeks)} semanas: "
          f"out {avg_out:,.0f}  cache {avg_cache:,.0f}")
    print(f"PROYECCION 2 meses sin cambios (~8.7 semanas): "
          f"out {avg_out*8.7:,.0f}  cache {avg_cache*8.7:,.0f}")
