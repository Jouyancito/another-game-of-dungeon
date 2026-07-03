# Golem Motion — Visual Annex Guide (for Joan)

Each subfolder here is a move from `_motion_spec.md`. Drop video clips / screenshots / GIFs
here and update the table below so future Claude sessions know what's been covered.

## Priority order (from spec)

| Priority | Folder | What to drop | Source |
|---|---|---|---|
| 1 | `lumber_walk/` | SotC Colossus 2 (Quadratus) walking gait | YouTube / SotC PC |
| 1 | `ground_pound/` | Yhorm the Giant (DS3) ground slam | YouTube / DS3 |
| 1 | `trunk_rip/` | LOTR BFME troll tree-attack | YouTube / BFME clip |
| 1 | `death_collapse/` | SotC Colossus 6 (Barba) forward fall | YouTube / SotC PC |
| 2 | `trunk_sweep/` | Yhorm horizontal double sweep | YouTube / DS3 |
| 2 | `tree_fall/` | Real slow-motion tree fall | YouTube "tree fall slow motion" |
| 2 | `rock_movement/` | Real rockfall / quarry footage | YouTube "rockfall slow motion" |
| 3 | `root_snare/` | Princess Mononoke forest eruptions | YouTube / film |
| 3 | `root_snare/` | Elden Ring Erdtree Avatar vine attack | YouTube / Elden Ring |

## Annex status (Joan updates this)

| Move | Status |
|---|---|
| `rock_movement` | [ ] pending |
| `tree_fall` | [ ] pending |
| `trunk_rip` | [ ] pending |
| `trunk_sweep` | [ ] pending |
| `lumber_walk` | [ ] pending |
| `ground_pound` | [ ] pending |
| `root_snare` | [ ] pending |
| `death_collapse` | [ ] pending |

## How to add a reference

1. Drop the file in the correct subfolder: `motion/clips/<move>/<filename>.<ext>`
2. Mark the row above as `[x] done — <filename>`
3. If the file is a long video, note the timestamp range that's relevant.

Files here are REFERENCE ONLY — they are not imported by Godot (no .import sidecars needed).
Add them to `.gitignore` if they're too large for the repo.
