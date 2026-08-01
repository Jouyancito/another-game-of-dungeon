# Foliage shimmer — why TAA, and why nothing else

Status: **TAA enabled** (`rendering/anti_aliasing/quality/use_taa=true`), 2026-07-31.
Harness: `game/scenes/dev/shimmer_probe.tscn` + `game/tools/godot/shimmer_probe/analyze.py`.

## The complaint

Vegetation boils under camera motion — enough to make the floor uncomfortable to look
at for long. Reported repeatedly during playtests as "shimmer / marea".

## How it was measured

A static screenshot cannot show shimmer, so the probe renders a fixed stage (one framed
tree, a second tree further back, a bush, a 676-instance grass carpet, one sun, one flat
sky) and sweeps the camera in **pure yaw with the position frozen**, saving one frame per
step. `analyze.py` then scores, per consecutive frame pair:

- **MAD** — mean absolute luminance difference, 0-255.
- **SPECKLE** — share of pixels whose luminance jumps more than 24/255 in one frame.
  This is the number that matters: a correctly filtered edge moves through intermediate
  values, a boiling one flips.

Pixels are split into **FOLIAGE** (alpha-scissor surfaces, via a rendered stencil) and
**WORLD** (everything else). WORLD is the control: a "fix" that just blurs the whole game
drags WORLD down too, and that shows.

### Two measurement traps, both hit

1. **Step size.** At 0.2 deg/frame the image slides ~2 px per frame, so any high-contrast
   texture produces huge deltas purely by *moving*. Every technique looked useless. The
   regime that separates boiling from motion is **sub-pixel**: 0.02 deg/frame (~0.2 px).
2. **Reimport.** Editing a `.import` and running the project changes nothing — the project
   run reads the already-cooked `.ctex`. `--headless --path game --import` first, or two
   runs return byte-identical numbers.

## Results (0.02 deg/frame, foliage region)

| config | FOLIAGE SPECKLE % | WORLD SPECKLE % |
|---|---|---|
| no AA (baseline) | 5.40 | 1.12 |
| MSAA 2x | 5.47 | 1.13 |
| MSAA 4x | 5.41 | 0.67 |
| MSAA 8x | **5.40** | 0.43 |
| FXAA | 6.41 | 0.92 |
| alpha-to-coverage @ MSAA 4x | 8.19 | 0.74 |
| render scale 150 % | 7.54 | 1.09 |
| render scale 200 % | 7.37 | 0.99 |
| **TAA** | **0.68** | **0.04** |
| TAA + render scale 150 % | 0.67 | 0.05 |

Whole-frame pixels boiling (max jump > 24/255 across the sweep): **12.70 % -> 2.29 %**.

## Why MSAA does nothing here

Alpha scissor is a per-**fragment** `discard`. When the shader rejects a leaf pixel it
takes *every one of its MSAA samples* with it — multisampling only ever antialiased the
geometry edge of the quad, which is invisible. That is why MSAA 8x moved WORLD by -62 %
and FOLIAGE by 0.0 %.

For the same reason this is **not** a resolution problem: rendering the same binary
decision at 2x just produces twice as many pixels flipping, which is why supersampling
scored *worse*. Only accumulating across frames recovers the sub-pixel coverage a single
frame cannot represent.

Alpha-to-coverage is the technique designed for this, and it scored worse — Godot resolves
it as a sample-coverage dither, and the dither pattern itself changes frame to frame.

## The cost

TAA ghosts behind fast movers. If enemies or projectiles smear, that is the trade to
revisit — not the setting's usefulness on vegetation. TAA also cannot fully fix motion
faster than its history rejection tolerates, so some residual shimmer while sprinting is
expected; the remaining lever there is art-side (fewer, larger leaf cards — canon §17.5).

## Do not put this in project.godot

The first version of this fix carried the table as comments inside `project.godot`. Two
problems: that file takes `;` comments, not `#` (a `#` block silently swallowed the setting
and TAA never turned on at all), and the Godot editor **rewrites `project.godot` and drops
comments** the first time anyone opens Project Settings. Rationale lives here; the file
carries a one-line pointer.
