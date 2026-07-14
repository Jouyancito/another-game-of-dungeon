# Visual Gate — render → compare → fix

The **COMPARE** step of the asset verification loop. Capture already works
(`scenes/dev/*_capture.gd` → `tools/godot/anim_capture/<clip>/frame_NNN.png`). This gate
puts an **objective, non-LLM metric** on top so the token-expensive visual critic
(`art-ref-critic`) only runs when a frame actually regressed.

> determinism = AUTHORITY (this gate) · VLM = ADVISOR (only on FAIL).
> A cheap pixel diff runs BEFORE the model, so unchanged frames never burn tokens.

Why this exists: the research into how agents drive desktop apps converged on one rule —
*the lever is the perception loop, not fancier actuation*. BlenderGym measured an LLM judge
aligns with humans only ~0.66 (vs ~0.79 human-human) and misses spatial artifacts, so a
deterministic metric must gate the loop. This is that metric for Dungeon Party assets.

## Setup (once)

```sh
cd game/tools/visual_gate
npm install        # pulls odiff-bin (native perceptual diff, MIT, Windows-native)
```

`node_modules/` and `_gate_out/` are gitignored.

## The loop

```
1. CAPTURE   Godot_v4.6.2-stable_win64.exe --path game res://scenes/dev/<x>_capture.tscn
                -> tools/godot/anim_capture/<clip>/frame_NNN.png   (run under test)

2. COMPARE   node visual_gate.mjs --current <capture-dir> --golden <golden-dir>
                exit 0 = no regression (done, 0 tokens)
                exit 1 = regression -> diff_NNN.png + report.json written

3. FIX       only on exit 1: hand the failing diff_NNN.png frames to art-ref-critic,
                read its PASS/FAIL-per-axis verdict, fix, re-run from step 1.
```

A **golden set** is a capture you've eyeballed and blessed as correct. Commit it under
`tools/godot/anim_capture/_golden/<clip>/` (TODO: establish goldens per blessed clip).

## Usage

```sh
node visual_gate.mjs --current <dir> --golden <dir> [options]

  --current <dir>           freshly captured frame_NNN.png (run under test)
  --golden <dir>            committed reference frame_NNN.png
  --out <dir>               diff images + report.json   (default <current>/_gate_out)
  --threshold-pct <n>       max % differing pixels per frame to PASS  (default 1.0)
  --pixel-threshold <0..1>  odiff per-pixel color tolerance           (default 0.1)
  --json                    print only the JSON report (machine consumption)
```

Exit code IS the gate: `0` all frames passed, `1` at least one failed. A pre-commit /
pre-push hook or a workflow can branch on it.

### report.json

```jsonc
{
  "gate": "PASS" | "FAIL",
  "summary": { "total", "passed", "failed", "thresholdPct", "pixelThreshold" },
  "failures": [ { "frame", "status", "reason", "diffPercentage", "diff" } ],
  "frames":   [ /* every frame's verdict */ ]
}
```

## Tuning

- **`--threshold-pct`** — frame-level tolerance. 1% absorbs lighting/AA jitter while still
  catching a moved limb or a missing chunk. Raise if captures are noisy, lower to be strict.
- **`--pixel-threshold`** — odiff's per-pixel color sensitivity (0 = exact, higher = looser).
- Frames present in golden but **missing in current** auto-FAIL (`missing-in-current`).
- A **size mismatch** auto-FAILs as `layout-diff` — keep capture `SV_SIZE` stable across runs.

## Known limits / next adds

- **No contact-sheet yet** (no ImageMagick/ffmpeg on this box). Diff images are written
  per-failing-frame for the critic to Read individually. A `montage` step (node `sharp`/`jimp`,
  or installing ImageMagick) is the next polish so the critic reads one image, not N.
- **Capture upgrade candidate:** Godot *Movie Maker* mode (`--write-movie out.png
  --fixed-fps 30 --quit-after N`) gives frame-perfect deterministic timing vs the current
  `delta`-accumulated SubViewport tick. Swap in later if frame timing drifts between runs.
- **Goldens not established yet** — the gate is ready; blessing reference sets per clip is
  the next manual step.
