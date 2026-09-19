"""Audit Claude Code transcripts: where do the tokens actually go.

Reads the real `usage` block that Claude Code records on each assistant message,
so these are measured tokens, not chars/4 estimates. Also breaks down what is
FILLING the context by content bytes per producer, which is what makes every
later turn expensive.

Usage: python audit_tokens.py [days]
"""
from __future__ import annotations

import collections
import json
import os
import sys
import time

ROOT = r"C:\Users\the_j\.claude\projects"
DAYS = int(sys.argv[1]) if len(sys.argv) > 1 else 30
CUTOFF = time.time() - DAYS * 86400

# Real token counters, summed from message.usage
tok = collections.Counter()
per_session = collections.defaultdict(collections.Counter)

# Content-byte counters: what is taking up room in the context window
bytes_by_source = collections.Counter()
calls_by_tool = collections.Counter()
result_bytes_by_tool = collections.Counter()
images = collections.Counter()


def walk(path, session):
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            if not line.strip():
                continue
            try:
                rec = json.loads(line)
            except Exception:
                continue
            msg = rec.get("message") or {}
            usage = msg.get("usage") or {}
            for k in ("input_tokens", "output_tokens",
                      "cache_read_input_tokens", "cache_creation_input_tokens"):
                v = usage.get(k)
                if isinstance(v, int):
                    tok[k] += v
                    per_session[session][k] += v

            content = msg.get("content")
            if isinstance(content, str):
                bytes_by_source["assistant/user text"] += len(content)
                continue
            if not isinstance(content, list):
                continue
            for blk in content:
                if not isinstance(blk, dict):
                    continue
                btype = blk.get("type")
                if btype == "text":
                    role = rec.get("type", "?")
                    bytes_by_source[f"{role} text"] += len(blk.get("text") or "")
                elif btype == "thinking":
                    bytes_by_source["thinking"] += len(blk.get("thinking") or "")
                elif btype == "tool_use":
                    name = blk.get("name", "?")
                    calls_by_tool[name] += 1
                    bytes_by_source["tool_use inputs"] += len(json.dumps(blk.get("input") or {}))
                elif btype == "tool_result":
                    c = blk.get("content")
                    n = 0
                    if isinstance(c, str):
                        n = len(c)
                    elif isinstance(c, list):
                        for sub in c:
                            if not isinstance(sub, dict):
                                continue
                            if sub.get("type") == "text":
                                n += len(sub.get("text") or "")
                            elif sub.get("type") == "image":
                                src = sub.get("source") or {}
                                data = src.get("data") or ""
                                images["count"] += 1
                                images["b64_bytes"] += len(data)
                    bytes_by_source["tool_result"] += n
                    result_bytes_by_tool[rec.get("toolUseName") or "unknown"] += n
                elif btype == "image":
                    src = blk.get("source") or {}
                    images["count"] += 1
                    images["b64_bytes"] += len(src.get("data") or "")


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


files = []
for dirpath, _dirs, names in os.walk(ROOT):
    for nm in names:
        if nm.endswith(".jsonl"):
            p = os.path.join(dirpath, nm)
            try:
                st = os.stat(p)
            except OSError:
                continue
            if st.st_mtime >= CUTOFF:
                files.append((st.st_mtime, st.st_size, p))

files.sort(reverse=True)
print(f"transcripts touched in last {DAYS}d: {len(files)}   "
      f"total on disk: {human(sum(f[1] for f in files))}")

for _mt, _sz, p in files:
    walk(p, os.path.basename(p)[:8])

print("\n=== REAL TOKENS (from message.usage) ===")
total_in = tok['input_tokens'] + tok['cache_read_input_tokens'] + tok['cache_creation_input_tokens']
print(f"  output           {tok['output_tokens']:>14,}")
print(f"  input (fresh)    {tok['input_tokens']:>14,}")
print(f"  cache created    {tok['cache_creation_input_tokens']:>14,}")
print(f"  cache read       {tok['cache_read_input_tokens']:>14,}")
print(f"  input total      {total_in:>14,}")

print("\n=== TOP SESSIONS by output tokens ===")
rank = sorted(per_session.items(), key=lambda kv: -kv[1]['output_tokens'])[:8]
for sid, c in rank:
    print(f"  {sid}  out {c['output_tokens']:>10,}  cache_read {c['cache_read_input_tokens']:>13,}")

print("\n=== WHAT FILLS THE CONTEXT (content bytes) ===")
tot = sum(bytes_by_source.values()) or 1
for k, v in bytes_by_source.most_common():
    print(f"  {k:<24} {human(v):>10}  {100.0*v/tot:5.1f}%")
print(f"  {'images (base64)':<24} {human(images['b64_bytes']):>10}  "
      f"{100.0*images['b64_bytes']/tot:5.1f}%   count={images['count']:,}")

print("\n=== TOOL CALLS by count ===")
for k, v in calls_by_tool.most_common(14):
    print(f"  {k:<28} {v:>7,}")
