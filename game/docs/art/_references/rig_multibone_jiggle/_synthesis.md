# rig_multibone_jiggle — one soft part, several bones (Zamgoodnight, "Battle Cruiser Jiggle Physics")

**Joan dijo (2026-08-29, textual):** "hice otra grabación con screenshots sobre un riggeo para
partes móviles, que es bueno tener varios puntos."

Source: Instagram reel by @2amgoodnight, "3D Modeling Tip: Battle Cruiser Jiggle Physics" (Blender,
anime chest as the demo subject; the principle is general). Captured 2026-08-29 20:44, 344 frames
full-screen, reel cropped at bbox (460,132)-(944,1000). Audio not captured — the sentence below
is reconstructed from the on-screen captions in order: STOP · USING · [one bone] · FOR · YOUR ·
PHYSICS · AND · INSTEAD · USE · [a cluster] · LIKE · EVELYN · [each] · HAS · [its own] · BONE ·
TOP · DYNAMIC · SOME · VARIATION.

## Idea / Concepto

A soft part driven by **one bone** can only move as a rigid lump: the whole mass swings together,
which reads as a rubber ball glued on. The fix is **not** more physics — it is more **points**:

1. **Cluster, not pivot.** A center bone plus a ring of 4-6 satellite bones around the mass
   (frames 03, 05, 06, 08). Each satellite owns a wedge of the surface.
2. **Each bone has its own weight falloff** (frame 04: heat-map per bone, hot at its own patch,
   cold at the neighbours'). Weights overlap softly so the surface stays continuous.
3. **Variation per bone.** Satellites get slightly different spring parameters (stiffness / drag /
   mass) so they don't move in phase. Out-of-phase neighbours = the surface *ripples* instead of
   *swinging*. This is the whole trick: the eye reads "soft" from phase difference, not from
   amplitude.
4. **Result** (frame 07): the mass deforms as a surface, secondary to the body's motion, and
   settles back to the rest pose.

Same principle as the reference `golem` SOUL spring layer already in the repo (per-chunk omega
varies so the rocks don't wobble in unison) — there it was reinvented for rigid chunks; here it
is the canonical rig version for soft surfaces.

## Forma / Silueta

- Center bone at the mass centroid, aligned with the direction of hang.
- Satellites placed on the mass surface at ~60-70 % of the radius, evenly spaced; one more at the
  tip if the mass is elongated.
- Satellites parented to the center bone, center bone parented to the body bone that carries it.
  Simulation runs on the chain body → center → satellite.

## Movimiento / Feel

- Body moves → center lags (low stiffness, medium drag) → satellites lag the center with
  *different* lag each → ripple. Return to rest must overshoot once, not oscillate forever
  (drag ≈ critical).
- Gravity on the chain gives sag at rest; without it the part looks inflated.

## Qué capturar (translation to Dungeon Party)

| Subject | Today | With this |
|---|---|---|
| Slime / King Slime | whole-body `scale` tween (`slime.gd:262-270`) — rigid squash | 1 center + 6 ring bones in the Blender builder; ripple on land/hit; King Slime gets two rings |
| Hair shells (warrior, mage) | static shells | 1 chain of 2-3 bones per shell group, own stiffness per group |
| Cloth: mage robe hem, necro cape, danzante sash | static | 3-5 hanging chains around the hem, varied drag |
| Fauna soft parts: turtle neck skin, moth abdomen, rat belly | keyframed only | center + 4 satellites, low amplitude |
| Golem rock chunks | hand-rolled SOUL spring (`golem_assembly.gd:110-174`) | keep — it already applies the per-part variation rule |

## Engine (Godot 4.6 — native, verified)

`SpringBoneSimulator3D` (SkeletonModifier3D, added in Godot 4.4): child of `Skeleton3D`, pick
root bone → end bone, per-joint `stiffness / drag / gravity / radius`, collisions optional, returns
to the rest pose. Several simulators can stack on one skeleton — one per cluster, so each cluster
carries its own variation. Nothing in the repo uses it yet (rg `SpringBone|SkeletonModifier` → 0;
control probe `Skeleton3D` positive).

Pipeline consequence: the bones must exist **in the GLB**. The builders (`build_slime*`, hair
generators) have to emit the cluster armature + per-bone vertex groups; Godot only animates what
Blender exported.

## Métrica de éxito (defined before building)

Move the body 0.5 m sideways in 0.2 s and stop. PASS when: (a) the soft surface keeps moving after
the body stops, (b) at least two satellites are visibly out of phase in the first 0.3 s, (c) the
surface is back within 2 % of rest pose by 1.2 s with a single overshoot. A rigid lump fails (b);
a jelly that never settles fails (c).

## Fuente / Fecha

- @2amgoodnight (Instagram / YouTube / X / TikTok), reel "3D Modeling Tip: Battle Cruiser Jiggle
  Physics", ~2026-08-26. Demo character: Evelyn (Zenless Zone Zero) cited as the multi-bone example.
- Godot docs: https://docs.godotengine.org/en/stable/classes/class_springbonesimulator3d.html
- Captured 2026-08-29, Joan's screenshot session `2026-08-29_20-44-05`.
