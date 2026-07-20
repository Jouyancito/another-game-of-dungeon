# Golem — Motion Reference Spec
**Version**: 1.0 · **Date**: 2026-06-14 · **Author**: Claude (text base) — Joan annexes visual clips
**Parent canon**: `_bestiary_visual_bible.md §6.5` · `_synthesis.md` · engram `blender/research-animation-weight`

> **What this is**: The textual "target" every golem animation is built against and compared to.
> Key poses, timings, arc shapes, weight cues, reference touchstones, and common mistakes — per move.
> Joan annexes actual video clips inside `motion/clips/` and links them in the "Visual annex" field below each move.
>
> **What this is NOT**: code, scripts, or implementation tasks. Pure reference base.
> Build notes (Godot curves, tween names) are included for convenience — they are the SAME ones
> from `blender/research-animation-weight` (engram #1625) and are reproduced here so this doc
> is self-contained.

---

## Golem identity — the motion signature

Before any individual move: what makes the golem's motion RECOGNIZABLE as this specific creature.

- **Everything moves as if it weighs 8–10 tonnes.** No part starts or stops quickly unless it has been thrown by that mass.
- **Serene guardian, not frantic attacker.** The golem doesn't rush. Long anticipations are not a flaw — they are the character. Speed would break the "ancient spirit" read.
- **The ecosystem moves with it.** Flowers, vines, the tree on its back, the orbital rocks — all have their own inertia and lag behind the body. When they settle they make the golem feel BIGGER, not lighter.
- **Each attack has a recovery cost.** The punish window after every move is part of the design. A golem that recovers instantly is a broken promise.
- **Escalation is built into the combo.** The trunk sweeps get more committed each time. The arc widens, the recovery lengthens. The third swing is almost a stumble.

---

## Boss encounter structure (PO decisions, Joan 2026-07-19/20)

The prairie's floor-1 **sub-boss** (roaming encounter, distinct from the floor's gated
final boss). Confirms and extends the moveset above with the missing piece: the
awaken/reveal, and the phase thresholds that connect the moves into one fight.

### Dormant form — add a cave

The mound is not just moss-and-rock: it has a small cave-like hollow ("mini gruta")
the player can peek into before the fight starts. This was NOT in the original 7
refs — new detail, no reference image yet (gap, flag for Joan to bring one if a
specific look matters). Combine with ref 02's "indistinguishable from terrain" read
— the cave should look like ordinary rock shadow until the awaken, not an obvious
"boss door."

### Awaken — refine the existing 6-beat build with 3 additions

The `golem_guardian` build (`game/tools/blender/golem_guardian/`) already has a
6-beat awaken. Joan's 2026-07-19/20 description adds specificity to beats 2 and 4:

- **Eyes open as an explicit early beat**, not just "the look" at the end. The golem
  opens its eyes and looks at the player BEFORE it finishes standing up — the look
  starts early and holds through the rise, not a single beat at the very end.
- **Each arm is a separately buried mass**, not part of the torso's own silhouette.
  Right arm assembles/rises FROM THE GROUND first (its own dirt-fall, its own
  crunch/creak), then left arm assembles the same way, sequentially not
  simultaneously. This is more dramatic than "the shoulders emerge from the mound" —
  it should read as two more golem-pieces climbing out of the earth to join the body.
- **Scale/dread feel**: the player should feel small in comparison, aware it could
  crush them if it gets close. Slow camera, no rush, low angle read — a
  direction/staging note as much as an animation one.
- Sound cues (movement creaks/groans, dirt-fall) are explicitly wanted — audio scope,
  not yet built; flag for the audio pass (same placeholder-SFX pipeline as PR #67).

### Phase structure (PO decision, 2026-07-19/20)

Three-phase fight, confirmed thresholds:

| Phase | HP range | Moveset | Trigger move |
|---|---|---|---|
| 1 — Unarmed | 100% → 70% | Fists (`ground_pound`-style single-arm punches, not yet specced as a standalone move), thrown rocks with a telegraphed wind-up ("saca una piedra con aviso") | — |
| 2 — Armed | 70% → 25% | `trunk_rip` (once, on entering phase 2) → `trunk_sweep` x3 combo, repeatable | HP crosses 70% |
| 3 — Desperation | 25% → 0% | Tree breaks/is discarded (visual event, not yet specced) → `ground_pound` unlocked as the finisher | HP crosses 25% |

Combat pacing reference (Joan, 2026-07-19/20): Resident Evil Nemesis/Tyrant-class
enemy — NOT glacially slow, but every hit is a critical, high-consequence
commitment. This does not contradict the existing "serene guardian" identity line
above — it confirms the SAME read from a different touchstone (add alongside SotC/
GoW/Dark Souls in the reference touchstones per move).

**Open/unspecced**: the phase-1 unarmed punch (currently only `ground_pound` two-arm
slam is specced — a single-arm jab/punch for phase 1 needs its own move entry), the
telegraphed rock-throw ("aviso" wind-up), and the tree-break visual event that gates
phase 3. These are the next moves to spec before building.

---

## Move 1 — `rock_movement` (base physics: loose rock tumbles and settles)

> This is NOT a golem animation clip — it is the physical VOCABULARY that governs how EVERY stone
> part moves when displaced. The orbital rocks, falling debris, the crumble on death — all obey
> these rules. Get this right and everything downstream feels consistent.

### What good looks like

A loose rock dislodged from a surface passes through five distinct phases:

1. **Displacement** (0–0.1s): the rock breaks free. Velocity is nearly zero at release then jumps as gravity takes hold. No floating drift — immediate directional fall toward the low point.
2. **Free-fall arc** (0.1–0.5s depending on height): the rock rotates around its own center of mass as it falls. Rotation rate is proportional to the asymmetry of its shape — a flat disc tumbles fast on one axis, slow on another. A rounded river-rock (golem's limbs per ref 04/07) tumbles slowly and irregularly because its moment of inertia is more even.
3. **First impact** (~0.5s): the rock hits a surface with a velocity spike. The impact is NOT elastic — a stone rock on stone ground does not bounce high. Coefficient of restitution ≈ 0.2–0.35 (very low). Expect: small bounce (20–30% of fall height), then short hop, then rest. NOT bouncy. NOT floaty.
4. **Rolling settle** (0.5–1.5s): the rock rolls along its lowest rotational axis until friction kills it. This is the longest phase and the one animators most often skip. A rock does NOT stop abruptly — it decelerates as a logarithmic curve (fast deceleration at first contact, asymptotic toward rest).
5. **Final settle micro-oscillation** (1.5–2.0s): the last tiny rock against the ground as it finds its lowest-energy resting spot. 2–3 very small oscillations, each half the amplitude of the previous.

**Key poses**: (A) airborne tumble mid-fall; (B) first impact compressed on one face; (C) post-bounce hover; (D) rolling on-axis; (E) final micro-rock at rest.

**Timing reference at 24fps** (for a rock the size of a golem's head, ~0.8m, dropped from 2m):
- Release → first impact: 12–15 frames
- First impact → rolling stop: 18–25 frames
- Micro-settle oscillations: 3 cycles × 4 frames each = ~12 frames total after rolling stops

**Arc/ease shape**: TRANS_EXPO EASE_IN for the drop (pure gravity — exponential acceleration). TRANS_CUBIC EASE_OUT for the rolling deceleration. The final micro-settle: TRANS_SINE EASE_IN_OUT (gentle diminishing).

**Weight cues**:
- Low bounce height (≤30% of drop height). High bounce = hollow ceramic, not stone.
- Slow rotation during fall. Fast spin = light/hollow object.
- Dust release at first impact, not during roll.
- NO sliding along the ground — it's too heavy and too rough. It rolls or it stops.

### Physics reality

Real granite on granite: coefficient of friction ~0.65 (static), ~0.60 (kinetic). Restitution 0.2–0.35.
A 50kg boulder dropped from 2m reaches ~6.3 m/s at impact. Bounce: ~1.9 m/s upward (30% restitution), reaching ~18cm max height. Second bounce: ~5cm. Third: ~1.5cm. Then rolling friction dominates.

Source: Classical Mechanics (Goldstein) + measured data from rock-fall studies in geomechanics literature (Azzoni et al., "Analysis and prediction of rockfalls using a mathematical model," 1995 — cited at https://link.springer.com/article/10.1007/BF01045761).

### Reference touchstones

- **Shadow of the Colossus** — stone debris falls from Colossi during climbing. Note how the debris tumbles SLOWLY (the designers exaggerate the mass read by reducing tumble speed). The dust persists longer than the rock movement.
- **God of War (2018) — boulder traps** — when stone rolls past Kratos, it compresses against the ground on first impact before bouncing. The bounce-height restraint is noticeable.
- **Real-world**: quarry blast footage, rockfall studies from civil engineering. Search "rockfall simulation video" for free examples of realistic stone-settling behavior.

### Common mistakes

- **High bounce**: looks like rubber or hollow ceramic. Cap bounce at 30% of drop height.
- **Instant-stop on contact**: no rolling, no settle. Looks like an animation cut rather than physics.
- **Uniform tumble speed**: real rocks have irregular center of mass. The rotation should vary — fast on one axis, slow on another.
- **Floating drift in free-fall**: no horizontal drift without initial lateral velocity. Gravity is vertical.
- **Sliding instead of rolling**: on flat surfaces, stone rolls. Sliding is for a smoother material (ice, metal sheet).

### Build target for Godot

For orbital rocks (`_start_rock_orbit`): apply micro-displacement impulses (Tween, TRANS_EXPO EASE_IN for the push, TRANS_CUBIC EASE_OUT for return) rather than simulating full physics. This is cheaper and more controllable.

For debris on death or trunk-rip: use TRANS_EXPO EASE_IN on the fall channel, TRANS_CUBIC EASE_OUT on the rolling-deceleration channel, and TRANS_SINE EASE_IN_OUT for the final 3 micro-settle oscillations. Stagger each debris piece by 2–5 random frames so they don't all stop at once.

**Visual annex**: `motion/clips/rock_movement/` — Joan to add: (a) slow-motion rockfall footage, (b) GoW/SotC debris examples.

---

## Move 2 — `tree_fall` (a tree toppling — base physics for any long rigid body falling)

> This move underpins `trunk_rip` and `death_collapse`. A toppling tree is the canonical reference
> for a long rigid body that pivots at one end while gravity accelerates the other end.

### What good looks like

A tree falls in two mechanical stages:

**Stage A — The lean** (0–1.5s): once the base connection breaks (cut, ripped), the tree begins to rotate about the base. This is slow at first — the angular acceleration starts near-zero because the moment of inertia of a long beam is high. The tip moves barely perceptibly at the start, then accelerates. This is the famous "slow beginning" of tree falls that surprises people in real life.

**Stage B — The accelerating arc** (1.5s → impact): once past ~30° from vertical, gravity has full leverage. The tip is now moving FAST — a 10m tree tip can reach 15–20 m/s at impact. The last 50° of the fall takes only 0.8–1.0s — dramatically faster than the first 40°.

**Impact** (~2.5–3.5s total for a 10m tree): the base and lower trunk hit first (or simultaneously with the crown, depending on terrain). The impact is NOT a bounce — the tree compresses into the ground and the branches absorb the shock. There is a brief "bounce" of the crown (spring-back from branch flex), but the trunk itself stays down.

**Key poses**:
- A: vertical, base connection moment (root system visible, or in golem's case, the sockets on the golem's back where the tree was rooted)
- B: 20° lean — the "has it started yet?" moment
- C: 45° — visibly falling, tip accelerating
- D: impact — full contact, maximum compression of the "root" contact zone
- E: branch-bounce (crown rises ~5–10% of tree height) then final rest

**Timing at 24fps** (for a 3m tree — golem-scale):
- Vertical to 30° lean: 18–24 frames (slow, almost no movement at first)
- 30° to impact: 12–15 frames (rapid acceleration — less than half the time of the first stage)
- Impact hold: 2–3 frames (the trunk does not immediately stop — brief freeze reads impact)
- Branch/crown bounce: 8–12 frames up, 8–12 back down, 2–3 micro-oscillations

**Arc/ease shape**: TRANS_CUBIC EASE_IN for Stage A (slow lean, building slowly). TRANS_EXPO EASE_IN for Stage B (gravity-dominated acceleration). TRANS_LINEAR for the 2-frame impact. TRANS_CUBIC EASE_OUT for the branch-spring-back.

**Weight cues**:
- The asymmetric timing (Stage A slow / Stage B fast) is the signature read. If the whole fall takes the same time, it reads as a rigid stick being rotated, not a real tree.
- Dust/debris at base when the connection breaks (root tear moment).
- Ground shudder on impact (camera shake spike).
- Branch oscillation after impact, not before. If branches wave during the fall, it reads as wind.

### Physics reality

For a rigid uniform beam of length L pivoting at one end under gravity, the angular acceleration at angle θ is: α = (3g/2L)sin(θ). At 0°, sin(0)=0, so acceleration starts at zero. At 90°(horizontal), it peaks at 3g/2L. This is why real trees fall slowly at first then shockingly fast at the end.

A 10m tree (typical pine, ~400kg) with L=10m: at 45° the tip velocity ≈ sqrt(3gL(1-cos45°)) ≈ 8.3 m/s. At 90° (horizontal): ~12.1 m/s. Final tip velocity at ground (~100° fall): ~14 m/s (50 km/h).

Source: basic rigid body rotation mechanics. For visual reference of actual timings: search "tree falling slow motion" — the asymmetric timing of slow-start/fast-end is unmistakable.

### Reference touchstones

- **LOTR: The Two Towers (Treebeard + Ents sequence)**: The Ents toppling trees in Isengard. Note how each tree's fall starts nearly imperceptibly and then suddenly crashes. Also note: the trees don't bounce. They hit and stay.
- **LOTR: Battle for Middle-earth (game)**: Troll tree-rip move — the LOTR trolls (Peter Jackson style) tear a tree and swing it in one smooth chained motion. The tree's mass reads because the swing is SLOWER than you'd expect from the troll's arm speed.
- **Princess Mononoke**: Forest spirits + falling trees during the iron-forging scenes. Ghibli's trees fall with correct asymmetric timing.

### Common mistakes

- **Uniform speed throughout the fall**: the most common mistake. Makes the tree look like a 3D rotation of a static object, not a real falling mass.
- **Immediate full-speed after disconnecting**: no slow-start. The first frames of a real tree fall are almost motionless.
- **High bounce at impact**: if the trunk bounces significantly (>5% of tree height), it reads as hollow. Real trees do NOT bounce significantly.
- **Branch motion during fall**: branches only oscillate meaningfully AFTER impact, not during the fall. Mid-fall branch flutter reads as wind-driven, not physics-driven.

### Build target for Godot

Model the trunk-rip tree as a Node3D subtree with: a pivot at the golem's back socket point + a long "trunk" child. Animate the rotation channel from 0° → impact using two keyframe segments: TRANS_CUBIC EASE_IN for 0°–30° (long segment), TRANS_EXPO EASE_IN for 30°–impact (short, fast). Impact hold: 2 identical-value keyframes with TRANS_LINEAR between them. Then TRANS_CUBIC EASE_OUT for the branch spring-back.

**Visual annex**: `motion/clips/tree_fall/` — Joan to add: (a) slow-motion tree fall, (b) LOTR Ents sequence, (c) any Ghibli or SotC reference with toppling structures.

---

## Move 3 — `trunk_rip` (the golem tears its back-tree off — the signature setup move)

> The most narrative-rich animation in the set. This is when the player understands the golem's
> full moveset is about to change. It must read: "this changes everything."
> Reference archetype: LOTR/BFME trolls + Icelandic stone-giant iconography.

### What good looks like

Four phases, total ~2.2s (53 frames at 24fps):

**Phase 1 — GRIP ANTICIPATION (0–0.5s / frames 0–12)**
Both arms reach back and over the shoulders toward the tree growing from the golem's back. The torso leans FORWARD slightly, as if bowing — this is loading tension like a bow. The movement is deliberate and SLOW. The player reads: "it is about to do something deliberate and large."

Key pose A: arms extended back, splayed contact on trunk. Torso forward-lean ~15°. Floating rocks have settled slightly downward (all energy redirecting to the grip).

**Phase 2 — STRAIN / HELD EFFORT (0.5–0.9s / frames 12–22)**
NO primary movement for 10 frames. The golem is trying, but the tree is rooted. A micro-tremor: 2° oscillation on the torso (TRANS_SINE, 5-frame period). The trunk/branch bends very slightly toward the golem. Orbital rocks vibrate subtly.

This held-effort phase is the most important part of the animation for selling mass. A light creature would just yank the tree instantly. The golem strains. This is character.

**Phase 3 — THE WRENCH (0.9–1.15s / frames 22–28)**
Explosive release. Both arms pull FORWARD and DOWN simultaneously. The torso snaps upright then slightly back (recoil from the pull). This is the single fastest moment across the entire moveset — 6 frames of maximum velocity.

Key pose B: arms fully forward, torso snapped back, tree no longer in socket. Floating rocks spike OUTWARD (disturbed by the violent motion).

A root-tear dust/particle burst fires at frame 22 (the wrench frame). The socket on the golem's back tears open — if there are vines wrapping the socket, they snap.

**Phase 4 — TRUNK RECOVERY (1.15–2.2s / frames 28–53)**
Arms swing down and around to hold the trunk in front — like a warrior catching a massive weapon they just drew. The trunk overshoots its held position by ~20°, then settles back in 3 diminishing oscillations. Torso rocks slightly back from the momentum. Floating rocks scatter then gradually drift back to orbit.

Key pose C (end of trunk_rip): golem standing, trunk held horizontally in both arms, slightly off-balance. The next move is `trunk_sweep`.

**Ease curves**: Phase 1: TRANS_CUBIC EASE_IN. Phase 2: TRANS_SINE (micro-tremor only). Phase 3: TRANS_EXPO EASE_IN for 4 frames then TRANS_LINEAR for 2 frames (crack-impact feel). Phase 4 overshoot: TRANS_CUBIC EASE_OUT. Final settle: TRANS_SINE EASE_IN_OUT.

### Physics reality

Ripping a rooted trunk from a stone body requires overcoming: (a) the structural bond of the root system growing INTO the stone, and (b) the trunk's own resistance to bending at the break point. Real-world analog: a heavy timber extraction winch pulling a stump. The key observable: the effort is NOT linear — the connection holds for a long time then releases suddenly (not a gradual tear). This justifies the long STRAIN phase followed by the sudden WRENCH.

After release, a 100kg trunk would swing forward at approximately 5–8 m/s, overshooting by 20–30° easily for a creature that can barely control that much mass.

### Reference touchstones

- **LOTR: Battle for Middle-earth (2004)** — Troll unit tree-attack. The troll grabs a tree, there is a brief strain moment, then the tree rips free and swings. Joan named this specifically: "se ve bonito." This is the direct archetype. The strain phase in BFME is short (budget constraints) — our version should be LONGER (emphasize mass).
- **Shadow of the Colossus** — Valus (Colossus 1) arm raises. Not a tree-rip, but the way his arm travels backward before a slam — the deliberate, slow coil — is the right energy for the Phase 1 approach.
- **God of War (2018) — Troll slam wind-up**: the troll's stone slab is raised overhead very slowly before slamming. The two-second raise is almost too slow — which is exactly right. Steal the duration.
- **Dark Souls 2 — Ruin Sentinels**: their weapon-draw has a held-effort pose before swinging. The 10-frame "stuck" moment before the explosive release is very close to our Phase 2.

### Common mistakes

- **No strain phase**: the most common failure. Without Phase 2, the rip reads as a pull animation that "worked immediately." The strain is what makes the tree read as HEAVY and ROOTED.
- **Symmetric effort**: both arms moving identically. Real extraction has micro-asymmetries — one arm pulling more than the other. The trunk rotates slightly before releasing (one root tears first).
- **Too-fast recovery**: Phase 4 under 0.5s. The trunk is heavy; the golem's arms shouldn't snap back to ready-position. Recovery time = 1.0s minimum.
- **Rocks don't react**: the orbital rocks spiking outward on the wrench frame and then slowly drifting back is a key secondary action. Without it, the explosive moment looks isolated.
- **No dust/particle at root-tear**: the socket on the golem's back should emit a dust/fragment burst on frame 22. Without it, the rip looks like a model swap, not a physical event.

### Build target for Godot

The tree (branch_nest_01) is a child node of the golem body. trunk_rip removes it from the back-socket position and places it as a "held weapon" in both hands. Implementation:
- Phase 1–3: animate `branch_nest_01` local position (socket) + golem arm bones via AnimationPlayer.
- Phase 3 (wrench frame 22): reparent `branch_nest_01` from back-socket → "held" position between both hands. Emit dust particle burst.
- Phase 4: animate the "held" trunk overshooting its final rest position, TRANS_CUBIC EASE_OUT.
- Tween orbital rocks: `tween.tween_property(rock, "position", outward_pos, 0.1).set_trans(TRANS_EXPO).set_ease(EASE_IN)` at frame 22, then return TRANS_CUBIC EASE_OUT over 0.8s.

**Visual annex**: `motion/clips/trunk_rip/` — Joan to add: LOTR BFME troll tree-attack clip; GoW troll wind-up clip.
**Spec confidence**: HIGH — well-covered by engram #1625 + direct reference from Joan ("LOTR trolls").

---

## Move 4 — `trunk_sweep` x3 (heavy horizontal swings — escalating combo)

> The signature COMBAT move when the tree is in hand. Three swings with narrative escalation:
> Swing 1 = controlled. Swing 2 = committed. Swing 3 = barely in control.
> This escalation arc is what makes it read as a REAL creature, not a looping attack.

### What good looks like

**SWING 1 — Controlled (total ~1.8s / 43 frames at 24fps)**

Phase 1 — Coil anticipation (frames 0–18, ~0.75s):
The torso rotates AWAY from swing direction. If swinging right, the torso coils LEFT first. The trunk arm pulls back to the shoulder. The trunk tip is aimed away from the target. SLOW — telegraphing. The player needs to read this and decide to dodge.

Key pose A: torso coiled to max, trunk arm back, trunk tip pointing behind the golem. Floating rocks lag behind the torso rotation — they haven't "caught up" yet.

Phase 2 — The heavy arc (frames 18–30, ~0.5s):
The torso uncoils. The arm sweeps the trunk in a wide horizontal arc. The trunk LAGS the arm by 8–10 frames (drag). The arm leads, the trunk drags behind, then whips through the strike zone. The arc spans 180° of horizontal angle.

The trunk's path is NOT a straight sweep — it arcs downward at the midpoint (gravity pulls the free end down during the swing) then back up slightly at the end. This banana-arc is what makes it read as a real heavy object being swung, not a rigid stick rotation.

Key pose B: arm fully extended at the end of the arc. Trunk still catching up — tip is 8–10 frames behind the arm.

Phase 3 — Overshoot + settle (frames 30–43, ~0.55s):
Trunk overshoots by 25–35°. Arm/torso overshoot 10–15°. Two diminishing oscillations. Floating rocks finally catch up, overshoot orbit, settle. Ease: TRANS_CUBIC EASE_OUT.

**SWING 2 — Faster, wider (total ~1.5s)**

Anticipation shortened to 10 frames — momentum is already built. The arc is 200° instead of 180°. The golem commits more of its body. Overshoot increases to 35–45°. The torso dips slightly toward the swing direction at peak (being pulled by the trunk's weight). Floating rocks lag further behind than in Swing 1.

**SWING 3 — Over-committed (total ~1.6s but recovery is LONG: 0.8s)**

Very short anticipation: 5 frames. Almost no telegraph — this is the danger signal. Full 220° arc. The golem's feet drag on the ground through the swing — partial stumble. At swing-end: the golem's torso tips past balanced position. Both arms end up low. 0.8s recovery before next action. This recovery window is the PUNISH WINDOW — make it visually legible: hunched forward, arms low, head down.

**Ease curves for all three swings**: coil = TRANS_CUBIC EASE_IN. Arc first half = TRANS_CUBIC EASE_IN (building momentum). Arc strike zone = TRANS_LINEAR (sustained velocity — mass doesn't ease at contact). Overshoot = TRANS_CUBIC EASE_OUT. For Swing 3: arc = TRANS_EXPO EASE_IN (no ramp — momentum pre-loaded from previous swings).

### Physics reality

A trunk (200–300kg rough estimate for a 3m, 0.4m diameter hardwood log) being swung at arm's length by a creature of sufficient mass:

The moment of inertia for the trunk around the golem's shoulder axis is I = m·L²/3 ≈ 300 × 9 / 3 = 900 kg·m². To achieve a 180° sweep in 0.5s requires α = π/0.125 ≈ 25 rad/s², requiring torque = I·α ≈ 22,500 N·m. A 5m, 8-tonne golem can plausibly generate this, but it explains the PHYSICAL COST: after the swing, the stored rotational kinetic energy (E = ½·I·ω²) is substantial and must be absorbed by the golem's body (hence the overshoot and the stumble on Swing 3).

The banana-arc (downward dip at mid-swing) is real: the trunk is not rigidly connected at both ends — it sags under its own weight at the mid-point of the swing.

### Reference touchstones

- **LOTR BFME trolls** (primary, Joan-named): the horizontal sweep with a tree trunk. The key read is: the troll's ARM moves ahead of the trunk. By the time the arm is at 12 o'clock in the arc, the trunk tip is only at 8 o'clock. This lag is the weight.
- **Dark Souls 3 — Yhorm the Giant**: double horizontal swing. Notice how the second swing in the combo is wider and faster than the first. The escalation principle is directly visible. His recovery is conspicuously long — he hunches after both swings. (URL: numerous GDC and analysis breakdowns at https://www.youtube.com/watch?v=3t0TClilaaU — search "Yhorm animation breakdown")
- **God of War (2018) — Troll rock-slam combos**: the escalation from first hit to third hit is a textbook case. Each hit commits more of the troll's mass.
- **Sekiro — Seven Ashina Spears (great spear swipe)**: the horizontal polearm sweep where the weapon tip visibly lags the hands during the swing. The banana-arc is visible. Good for studying the lag/drag read.

### Common mistakes

- **Identical swings**: if all three sweeps are the same animation sped up, the combo reads as a loop and the escalation story is lost.
- **Trunk moves synchronously with arm**: the lag/drag between arm and trunk tip is the primary weight cue. If they move together, it reads as a rigid stick, not a heavy log.
- **Linear ease through the full arc**: smooth constant speed through the whole swing. It must build (EASE_IN) through the strike zone (LINEAR) and overshoot (EASE_OUT). Never one uniform curve.
- **No arc dip**: the trunk sweeps in a perfect horizontal plane. Real physics sag it downward at the mid-point. Without the sag, it looks like a rigid model rotation.
- **Quick recovery after Swing 3**: if the golem snaps back to idle immediately, it reads as a loop game. The 0.8s committed hunch is the punish window — respect it.
- **Rocks follow exactly**: the orbital rocks should ALWAYS be behind the torso rotation during the swing. If they orbit in sync, the secondary motion reads as part of the rig, not independent physics.

### Build target for Godot

`trunk_sweep` is a single AnimationPlayer clip with three swing segments. Use AnimationPlayer `markers` to mark Swing1End, Swing2End, Swing3End so the combat state machine can read which swing just completed and decide whether to start the next or transition to recovery.

The trunk lag: animate the trunk's LOCAL position within the held "weapon" node — translate it backward by 0.2–0.3 units at arc-start (lagging), then let it spring forward through the strike zone, then overshoot by 0.2 units, then settle. This simple translation gives the illusion of physical lag without actual physics.

Trunk's "banana-arc" downward dip: animate a small Y-translation dip of 0.1–0.15m at the midpoint of each arc, then back up. Subtle but reads correctly.

Recovery hunch at Swing 3 end: rotate the torso bone forward 20° and drop both arm bones low. Hold this for 0.8s. This is the punish window — do NOT cut it short.

**Visual annex**: `motion/clips/trunk_sweep/` — Joan to add: LOTR BFME troll sweep clip; Yhorm the Giant horizontal swing clips (both are well-documented on YouTube).
**Spec confidence**: HIGH.

---

## Move 5 — `lumber_walk` (weighted gait — fall-and-catch, hip drop)

> The most-played clip in the moveset — everything the golem does between attacks.
> The most COMMON place for weight illusion to break (uniform speed, no hip drop, "rocking" not
> "walking"). Get this right and everything else inherits the weight read.

### What good looks like

The underlying principle: **fall-and-catch gait**. The golem doesn't *step* — it *tips forward* and plants a foot to catch itself. This is controlled falling. Every heavy creature in real life and in good animation uses this. The center of mass tips forward, and the leading foot saves it.

One walk cycle: ~0.8s (19 frames at 24fps):

- **Frame 0**: Left foot plants. Torso dips LEFT (hip drops on planted side, the weight-bearing side). Right arm swings forward for counterbalance.
- **Frame 2**: Impact settling — hip drop peak (left hip 5–8% of body height lower than center). Head bobs DOWN. (Not up — heavy creatures compress under weight on foot plant, not spring up.)
- **Frame 6**: Right leg lifts — knee rises. Left leg carries full weight. Torso begins tipping right (toward the next fall).
- **Frame 10**: Midstride peak — torso is tallest (between steps). Floating rocks at highest orbit point in their cycle.
- **Frame 14**: Right foot swings forward, pre-plant (foot is FLAT, not pointed — stone feet don't point).
- **Frame 16**: Right foot HITS. Torso dips right. Left arm swings forward.
- **Frame 19**: Settle, cycle repeats.

**Key poses**:
- A: foot-plant + hip-drop (the most important single pose)
- B: single-leg support at full weight (left leg alone bearing ~8 tonnes)
- C: midstride float (between steps — tallest pose)
- D: foot-swing forward flat (stone foot geometry, not a pointed toe-kick)

**Arc/ease shape**:
- Foot-down impact: TRANS_EXPO EASE_IN (zero velocity then crash into ground)
- Foot-lift: TRANS_CUBIC EASE_OUT (slow start, momentum builds through the swing)
- Torso lateral lean: TRANS_SINE EASE_IN_OUT (smooth weight-shift, not jerky)
- Hip drop: TRANS_CUBIC EASE_IN (quick settle down, slow release back up)

**Weight cues**:
- Hip drop 5–8% of body height on the planted side. For a 5m golem, that's 0.25–0.4m of hip dip. This is substantial and visible.
- Head bobs DOWN on foot plant, not up. This is counterintuitive — reference your own walk or any heavy animal (horse, elephant) to confirm.
- Opposite arm counterbalance is WIDE. For a normal human walk it's subtle; for an 8-tonne creature, the counterswing must be exaggerated or it reads as top-heavy with no balance.
- Foot hits the ground with ZERO velocity — it freezes for 1–2 frames at the moment of contact, then the leg acts as a pivot. Any sliding or skidding of the foot breaks the weight read immediately.

### Physics reality

Elephants and large terrestrial animals (closest real-world analog to a bipedal creature of this mass) use a fall-and-catch gait at all speeds. A walking elephant at ~5 km/h has a vertical center-of-mass displacement of 5–8cm per step — visible hip drop. Head drops toward the supporting side on each step. Their walk has been extensively studied (Ren & Hutchinson, "Locomotor function of the hindlimb muscles in elephant walking and trotting," 2008).

For reference of the SOUND-motion sync: an elephant foot-fall is audible at 100m. The golem's equivalent is the visual micro-environment reaction (camera shake, dust, flowers bouncing on shoulders).

### Reference touchstones

- **Shadow of the Colossus — Colossus 2 (Quadratus) walking**: the most famous example of heavy gait in games. Each step has a visible hip-body sway, the fur ripples from each impact, and the head bobs down on each plant. The step timing is noticeably slower than you'd expect, making it read heavier.
- **Monster Hunter World — Diablos walking**: extremely well-studied heavy bipedal walk. The fall-and-catch principle is visible. Each foot plant has a visible hip drop on the planted side.
- **Dark Souls 3 — Cathedral Knight walking**: bipedal heavy armor. Exaggerated hip drop, arms swinging counterbalance. Good example of the principle applied to a bipedal construct (metal, not stone, but the mass-read principles transfer).
- **Real-world**: elephant walking gait videos. Watch specifically for: head bob direction (down, not up), hip drop per step, fall-and-catch rhythm. "Elephant walking slow motion" yields good footage.

### Common mistakes

- **Side-to-side rocking without hip drop**: torso sways left-right but hips stay level. This reads as a toy being rocked on a pivot. The hip DROP on the planted side is what reads as weight.
- **Head bobs UP on foot plant**: the opposite of reality. If the head rises when the foot hits, the creature reads as bouncy/light.
- **Foot slides on contact**: if the planted foot moves even slightly along the ground after contact, the weight illusion breaks. Use an IK constraint or lock the foot keyframe to zero velocity for 2 frames on contact.
- **Uniform speed throughout the step**: the step-speed should asymmetric — the lift phase (swing) has more speed variation (EASE_OUT as it rises, EASE_IN as it extends forward) than the plant phase (which freezes on contact).
- **Symmetric arm swing**: if both arms swing with identical timing, it reads as a marionette. The arms should have slightly different arc timing (the counterbalance arm is more reactive, slightly delayed vs the stepping leg).
- **No mass on floating rocks during walk**: if the rocks orbit perfectly smoothly through a walk, they're invisible as secondary action. Each foot-plant should jostle them slightly — a small perturbation that damps out between steps.

### Build target for Godot

19-frame cycle (0.79s at 24fps) in AnimationPlayer. Loop the clip. Add "method track" calls at frame 0 and frame 16 (each foot-plant) to trigger:
1. `_on_foot_plant(left/right)` → calls camera shake (0.02 units, 0.1s) + spawns foot-dust particle.
2. `_jostle_rocks(impulse=0.05)` → a small outward tween on the orbital rocks that damps in 0.3s.

Foot-plant lockout: the planted foot's position track should have identical values at frame 0 (plant) and frame 2 (settle) to enforce the zero-velocity freeze on contact. Use TRANS_LINEAR between these identical keyframes.

**Visual annex**: `motion/clips/lumber_walk/` — Joan to add: SotC Quadratus walk, Diablos walk, elephant walk in slow motion.
**Spec confidence**: HIGH.

---

## Move 6 — `ground_pound` / `stomp` (slam attack — the showpiece weight move)

> Available ONLY when the tree has been destroyed (phase 2 moveset). The ultimate demonstration
> of mass — arms overhead, full body commitment, seismic impact.
> Also serves as the "stagger" attack that opens the punish window for the party.

### What good looks like

Total duration: ~2.8s (67 frames at 24fps). The longest wind-up in the moveset. That's intentional.

**Phase 1 — WIND-UP RAISE (frames 0–30, ~1.25s)**
Both arms raise overhead. Torso leans BACK slightly (reverse-coil). Movement is slow and deliberate. 1.25s of build-up. The player sees this from across the room — that's the whole point.

Key pose A: arms fully raised, torso back-lean 10–15°, both fists above head. The silhouette change is dramatic: the golem goes from wide-bottom to tall-narrow.

The FLOATING ROCKS rise with the arms — pulled upward by the body energy concentration. They wobble. At peak, they are above their normal orbital plane. This is secondary action that amplifies the charge-up feeling.

Ease: TRANS_SINE EASE_IN. No acceleration spike during the raise — it should feel inexorable, not rushed.

**Phase 2 — PEAK HOLD (frames 30–36, ~0.25s)**
Arms at maximum height. 6-frame stillness. Floating rocks reach their highest point and begin to fall (they'll impact on the same frame as the slam). This is the "held breath." The room should go quiet before the crash.

Micro-tremor on the torso: 1–2° oscillation, TRANS_SINE. Just enough to read as effort being contained.

**Phase 3 — THE DROP (frames 36–44, ~0.33s)**
Explosive downward crash of arms + torso forward and DOWN. The legs bend slightly as the body loads impact (not jumping — pushing DOWN into the earth). This is the single fastest phase in the slam.

Ease: TRANS_EXPO EASE_IN for the first 6 frames (pure gravitational acceleration — the mass is in free-fall toward the ground), TRANS_LINEAR for the last 2 frames before contact (sustained velocity at impact — the mass does not slow before hitting).

Floating rocks are in free-fall, trailing the arms.

**Phase 4 — IMPACT FRAME (frames 44–46, ~0.08s)**
2-frame near-freeze at full compression. Maximum arm-down, body-forward pose. Ground-ring particle effect fires. Floating rocks HIT or bounce at exactly this frame. Camera shake: large spike (0.1 units, 0.15s — bigger than the walk plant).

This 2-frame hold is MANDATORY. Without it, the slam reads as a fast jab, not a crash.

**Phase 5 — RECOIL + SETTLE (frames 46–67, ~0.88s)**
Body rebounds UP slightly (5–8% of total arm-drop distance) — the golem did not punch through the earth; the earth pushed back. Torso oscillates 2–3 times before settling. Arms drop to sides slowly (TRANS_CUBIC EASE_OUT). Floating rocks drift back to their orbit slowly.

Recovery total: ~0.88s. This is the punish window after the slam. Make it legible: the golem is hunched, arms low, visually vulnerable.

**Ease curves**: Phase 1 raise: TRANS_SINE EASE_IN. Phase 3 drop: TRANS_EXPO EASE_IN then TRANS_LINEAR at contact. Phase 5 recoil-up: TRANS_CUBIC EASE_OUT. Phase 5 settle oscillations: TRANS_SINE EASE_IN_OUT, diminishing amplitude.

### Physics reality

An 8,000 kg mass with arms of ~3m length swinging down through ~120°: the gravitational potential energy at peak ≈ m·g·h ≈ 8000 × 9.8 × 1.5 ≈ 117,600 J. This is the energy delivered to the ground on impact. For comparison: a 1,500 kg car at 60 km/h has ~208,000 J of kinetic energy — so the slam is approximately 60% of a car crash. The ground-ring shockwave is entirely physically plausible.

The recoil (5–8% of drop distance) comes from Newton's 3rd law — the ground exerts an equal and opposite force. For a rigid body on a semi-elastic ground surface (soil, stone floor), some energy reflects back as upward momentum. This is NOT a bounce — it's an absorption and partial reflection.

### Reference touchstones

- **God of War (2018) — Troll ground slam**: the slow raise, peak hold, and explosive drop are textbook. Pause the GoW troll slam at the impact frame — you'll see a 2-frame hold. The dust ring fires on that exact frame. (Referenced broadly in GDC "Combat Feel" talks.)
- **Dark Souls 3 — Yhorm ground slam**: the 1.5-second wind-up, the held peak, the explosive drop. Yhorm is the gold standard for this move class. His slam has the longest anticipation of any boss in the Souls series — which makes it read as the heaviest.
- **Shadow of the Colossus — Valus fist slam**: Colossus 1 slams his fist into the ground. Note that the impact creates ground-plane rippling rather than a generic explosion. The ground REACTS to the mass, not just the creature.
- **Ico / SOTC postmortems**: Fumito Ueda's team specifically cited impact response and anticipated-delay as primary weight tools. (Referenced at multiple GDC talks; search "Shadow of the Colossus animation design GDC.")

### Common mistakes

- **Short wind-up**: if the raise takes under 0.8s, it reads as a normal heavy attack, not a ground-slam. The full 1.25s raise is what makes this move feel like a "special" commitment.
- **No peak hold**: if the animation transitions immediately from raise to drop, the "held breath" moment is lost. The 6-frame peak hold is the difference between a slam and a fast punch.
- **No impact freeze**: the 2-frame hold at full compression is the single most important keyframe in this animation. Without it: the slam reads as a jab, not a crash.
- **No ground reaction**: if the surrounding environment doesn't react (no particles, no camera shake, no light flicker), the mass reads as disconnected from the world.
- **Too-fast recovery**: recovery under 0.5s after a slam reads as a machine, not a creature. The 0.88s recovery is the punish window — it's a game-design decision as much as an animation one.
- **Rocks ignore the peak hold**: the rocks should be at their highest point during the peak-hold frames and begin to fall during the peak-hold. If they're still orbiting normally, the secondary action is missing.

### Build target for Godot

Wire the AnimationPlayer method tracks:
- Frame 44 (impact): `_on_slam_impact()` → triggers camera_shake (0.1 units, 0.15s) + dust_ring particle burst + optional screen-edge flash.
- Frame 30 (peak start): `_on_slam_peak()` → `tween_rocks_to_peak_height(0.3s)` — push rocks upward 0.5 units over 0.3s so they're at peak on frame 36.
- Frame 44 (impact): `_on_slam_impact()` → `tween_rocks_fall_and_bounce()` — rocks drop with TRANS_EXPO EASE_IN, micro-bounce at impact, then TRANS_CUBIC EASE_OUT back to orbit.

TRANS mappings: raise: TRANS_SINE EASE_IN. Drop-phase1: TRANS_EXPO EASE_IN. Impact 2-frame hold: TRANS_LINEAR between identical keyframes. Recoil: TRANS_CUBIC EASE_OUT. Settle oscillations: TRANS_SINE EASE_IN_OUT.

**Visual annex**: `motion/clips/ground_pound/` — Joan to add: GoW troll slam; Yhorm slam; SotC Valus fist plant.
**Spec confidence**: HIGH.

---

## Move 7 — `root_pull` / `snare` (vines erupt from ground — available in BOTH phases)

> The only "magical" move in the golem's set. All other moves are physical mass. This one is
> biological — the ecosystem the golem carries sends its roots into the ground.
> The golem does not throw anything: it channels through the earth. That's the character difference.

### What good looks like

This move has TWO parts: the GOLEM'S animation, and the VINE ERUPTION. They are separate objects but must feel synchronized.

**Golem body animation (total ~1.2s)**

Phase 1 — Ground channel (frames 0–12, ~0.5s):
The golem plants both hands flat on the ground OR lowers into a half-kneel with one hand touching. Head drops down (not forward — looking AT the ground, not at the target). The posture is one of concentration, not aggression.

Key pose A: low-stance, hand(s) on ground, head bowed. The orbital rocks SLOW their orbit and begin to descend — their energy is being redirected downward. Vines on the golem's arms pulse (if modeled as a separate mesh/shader: a subtle glow pulse, 2 cycles, then release).

Phase 2 — Release (frames 12–16, ~0.17s):
A short pulse through the torso — the golem "pushes" energy into the ground. This is a 4-frame micro-animation: torso compresses down 2° then springs back to neutral. Very subtle but essential for the read "it sent something into the earth."

Phase 3 — Recovery (frames 16–28, ~0.5s):
The golem rises back to standing (or lifts its hand from the ground). The rocks re-accelerate to normal orbit. Ease: TRANS_CUBIC EASE_OUT.

**Vine/root eruption animation** (separate: root VFX node or GPUParticles3D):
- Delay: vines erupt 6–8 frames AFTER the golem's "release" pulse (frame 18–20). This delay sells the travel time through the earth.
- Eruption: vines burst up from the ground around the target zone. The burst is fast (4–6 frames for the initial spike). Not simultaneous — they erupt in a radial stagger, like a shockwave expanding outward from the golem's hand position.
- Snare phase: vines hold the target for 2–3s. During hold: very subtle pulsing of the vine thickness (breathing).
- Release: vines retract into the ground in 0.5–0.7s — fast retraction, like they're being sucked back. They do NOT wither in place.

**Ease for vine eruption**: burst upward: TRANS_EXPO EASE_IN (zero then explosive). Snare hold: TRANS_SINE EASE_IN_OUT (pulsing). Retraction: TRANS_CUBIC EASE_IN (slow pull then fast retract).

### Physics reality

Root network propagation through soil is not instant — a root-growth signal travels at measurable speed (~1 cm/min in real biology). For the animation this is stylized: a "travel wave" from the golem's hand to the target zone that takes 6–8 frames (0.25–0.33s). This feels plausible without being literally biological.

Vine tendrils under tension (holding a snared target) exhibit slight stretch oscillation — the snared object pulls the vine, the vine pulls back. The pulsing during the snare hold is an approximation of this tension oscillation.

### Reference touchstones

- **Princess Mononoke — Forest Spirit / forest eruptions**: when the forest spirit walks, roots and growth erupt around its footsteps. The eruption has a staggered-radial pattern (not simultaneous), which is exactly the behavior we want. The "life energy traveling through the earth" feel is perfect for the golem's character.
- **Dark Souls 2 — Covetous Demon / Earthen Peak environments**: ground eruptions as snare attacks. Note how the target zone has a tell (visual ground crack or AoE indicator) before the eruption — this is good game design and should be referenced for the "how does the player know it's coming" design.
- **Elden Ring — Tree Sentinel / Erdtree Avatars**: rooted/vine attacks from large nature-aligned enemies. The Erdtree Avatars specifically have a "plant stance" before erupting. Good reference for the golem's channel posture.
- **Ori and the Will of the Wisps**: vine and root animations for environmental interactions. Exceptional quality of organic-root motion. While the creatures are not heavy, the VINE physics themselves are excellent references.

### Common mistakes

- **Golem looks aggressive during the channel**: the channel posture should be inward/downward, not forward-aggressive. The golem is concentrating, not attacking. If the chest rises and the arms go forward, it reads as a punch charge, not a root-channel.
- **Simultaneous vine eruption**: all vines erupting at the same frame. The staggered-radial eruption (near-to-far from the golem's hand point) is what makes it read as a wave traveling through the earth, not a particle effect firework.
- **Vines wither in place**: they should retract, not die. Withering reads as "the effect ends." Retraction reads as "the vine went back underground" — which is alive and more unsettling.
- **Rocks ignore the channel**: the orbital rocks slowing and descending during the channel is an essential secondary-action beat. Without it, the channel looks like the golem is just bending over.
- **No travel delay**: vine eruption same frame as the golem's release pulse. The 6–8 frame delay is the entire "traveling underground" read.

### Build target for Godot

Two independent animation sequences coordinated by the combat state machine:
1. `golem.gd` plays `root_snare` AnimationPlayer clip (golem body + rock-slow secondary).
2. At frame 20 of the golem animation: signal `emit_signal("root_eruption", target_position)` → spawns a `root_vfx` scene at target with its own AnimationPlayer (burst → hold → retract).

The vine eruption VFX: GPUParticles3D emitting upward with high initial velocity, or an AnimatedSprite3D / custom mesh that scales upward per-vine. If using mesh: animate scale.y from 0 → 1 with TRANS_EXPO EASE_IN per vine, staggered by 0.05s each in a radial pattern.

**Visual annex**: `motion/clips/root_snare/` — Joan to add: Princess Mononoke forest eruption; Elden Ring Erdtree Avatar vine attacks.
**Spec confidence**: MEDIUM — move type is well-understood but the specific golem posture during channel is thin on direct reference. Joan to annex nature-guardian channel poses.

---

## Move 8 — `death_collapse` (the golem falls — crumble, NOT reverse-assembly)

> Canon decision (§6.5): death = COLLAPSE BY GRAVITY, not the awaken in reverse.
> The golem dies as a creature, not as a puzzle being disassembled.
> A heavy thing toppling forward, hitting the ground, crumbling at the joints.

### What good looks like

Total duration: ~2.5s (60 frames at 24fps). Five phases:

**Phase 1 — RECOGNITION DELAY (frames 0–8, ~0.33s)**
Nothing happens immediately. The golem stands for 8 frames after the fatal hit. This is "mass refusing to believe it's dead." Light creatures die fast. This one takes a moment.

Micro-reaction: subtle knee-buckle (bend 5° at both knees), head drops very slightly forward. That's the entire Phase 1 motion. It's almost nothing. Which is everything.

**Phase 2 — THE LEAN (frames 8–24, ~0.67s)**
The golem begins tipping in one direction. STRONG PREFERENCE: forward, toward the player. Forward topple is more dramatic — the player must dodge. It also puts the face toward the camera for the death moment.

Ease: TRANS_CUBIC EASE_IN — slow start, accelerating like a felled tree. (This directly references the `tree_fall` physics from Move 2 above — a long rigid body beginning to rotate under gravity.)

Key pose A (frame 8): barely perceptible lean, maybe 5° off vertical.
Key pose B (frame 24): 35–40° lean — clearly falling now, accelerating.

Floating rocks begin drifting AWAY during this phase — they've lost the energy source that maintained their orbit. Each rock on its own trajectory. The ecosystem is breaking apart.

**Phase 3 — THE FALL (frames 24–38, ~0.58s)**
Increasing acceleration. TRANS_EXPO EASE_IN. Arms fly out to sides as the golem topples (instinctive loss-of-control, even for stone — this humanizes the fall). Floating rocks scatter in different directions, each at different velocity (stagger their separations by 2–5 random frames).

The vines/vegetation on the body react: they flatten against the direction of fall (air resistance / drag on the dressing as the body accelerates toward the ground).

**Phase 4 — IMPACT (frames 38–42, ~0.17s)**
Full body hits ground. 4-frame near-freeze. Every dressing element (flowers, moss clusters, orbital rocks) has its own micro-bounce (secondary action). This is the loudest sound moment in the entire enemy roster. Camera shake: 0.15 units / 0.2s (the biggest shake in the game).

The golem's BODY on impact: it does not stay as a solid mesh. The joints where rock-chunks connect CRUMBLE outward — pieces scatter 0.3–0.8m from the main body outline. This is the "crumble" part. Not a full disintegration — more like the mortar between stones giving way, loosening the structure.

Key pose C: full-prone, body outline on ground, arms spread, scattered debris around perimeter.

**Phase 5 — SETTLE + DUST (frames 42–60, ~0.75s)**
Minor oscillations of arms/head as the mass settles. Orbital rocks hit ground at VARIOUS times during frames 38–60 — staggered, not simultaneous. Each rock's landing uses the `rock_movement` physics from Move 1 (small bounce, roll, settle).

Ease on settle oscillations: TRANS_SINE EASE_IN_OUT, diminishing amplitude (2–3 cycles each).

At frame 60: full rest. Eyes/nucleus dims (the cyan emission fades over 0.5s — the last sign of life). Final state: the golem looks like a pile of large mossy rocks. Like it always has.

**The final rest reads like the dormant state.** This is an intentional poetic callback — the golem returns to looking like terrain.

### Physics reality

A rigid body of roughly 5m height, 8-tonne mass, falling forward (pivoting at feet):
- The center of mass is at ~2.5m height and must traverse approximately 2.5m of vertical fall.
- Using the rigid-body tree-fall model: final tip velocity ≈ sqrt(3gL/2) at 90° ≈ sqrt(3×9.8×5/2) ≈ 8.6 m/s for the tip.
- Impact energy ≈ 8000 × 9.8 × 2.5 / 2 ≈ 98,000 J (using center of mass drop). This is the equivalent of a mid-size car dropping from 1.25m.

The crumble at impact is mechanically plausible: the golem's structure is held together by mass compression from the weight of upper chunks onto lower ones. Once horizontal, that compression disappears and the outer joints lose their binding pressure. This is why stone structures crumble when tipped — gravity held them together vertically; horizontally they collapse at the joints.

### Reference touchstones

- **Shadow of the Colossus — virtually all Colossus death sequences**: the gold standard for heavy creature death. The recognition delay (they stand after being "killed" for 1–3 seconds), the slow lean, the accelerating fall, the ground-impact, and the gradual settling. Watch Colossus 2 (Quadratus) and Colossus 6 (Barba) specifically. Barba falls forward — the preferred direction for the golem.
- **LOTR: Return of the King — Mumakil (Oliphaunt) falls**: massive creatures toppling forward under their own weight. The asymmetric slow-start / fast-finish timing is extremely visible.
- **God of War (2018) — Troll death collapse**: very similar archetype. The troll does not disintegrate — it topples and the stone pieces scatter on impact. The crumble is at the joints, not a full explosion.
- **Titan Souls (indie)**: every boss death is a variation on the topple. Short game, all deaths. Excellent reference for minimalist heavy-death animation.
- **Dark Souls 3 — Yhorm death**: large boss crumbling forward. The recognition delay is visible (~0.5s of no reaction before the fall begins). The dust cloud on impact.

### Common mistakes

- **Immediate death**: no recognition delay. The golem should remain standing for 8 frames (0.33s) after the fatal blow. Without this delay, the death reads as a "switch off" rather than a massive body succumbing to damage.
- **Reverse awaken**: animating the fall as the exact reverse of the assembly. Canon explicitly rejects this — it would look like a puzzle being taken apart, not a creature dying. The fall is forward, not a disassembly.
- **Symmetric/clean topple**: if the golem falls cleanly like a felled log with no crumble, it reads as a prop being knocked over, not a creature dying. The joint-crumble (pieces scattering 0.3–0.8m) is what makes it read as organic.
- **Rocks all impact simultaneously**: all orbital rocks hitting the ground at the same frame reads as a triggered effect. Stagger their impacts across frames 38–60 — they had different trajectories.
- **No secondary action on dressing**: flowers, moss, vine clusters bouncing slightly after impact. Without this, the "ecosystem" character of the golem is invisible in its death.
- **No recognition delay**: see above — deserves repeating because it is the most commonly skipped beat and the most impactful one.
- **Nucleus doesn't dim**: the cyan eyes should fade out during the settle phase (frames 42–60). If they stay bright after the body hits the ground, the creature reads as still alive.

### Build target for Godot

`death` AnimationPlayer clip. At frame 38 (impact): `_on_death_impact()` → camera_shake(0.15, 0.2) + dust_ring + crumble_effect (spawn 4–6 rock_chunk detached nodes with random initial velocity using RigidBody3D for 2s, then queue_free).

Nucleus dim: at frame 42, start a Tween on the emission energy of the eye material from current → 0 over 0.5s, TRANS_SINE EASE_IN_OUT.

Orbital rocks: on Phase 2 start (frame 8), transition from `_start_rock_orbit()` tweens to individual gravity-simulated tweens — each rock gets: a random outward direction + slight downward velocity, TRANS_EXPO EASE_IN fall, `rock_movement`-physics impact on hit, then queue_free or static rest.

**Visual annex**: `motion/clips/death_collapse/` — Joan to add: SotC Colossus 2 death, SotC Colossus 6 (Barba) death, GoW troll death collapse.
**Spec confidence**: HIGH.

---

## Appendix A — Weightlessness Checklist (red flags — AVOID in every move)

From engram #1625. Reproduced here for use as a quality gate when reviewing any golem animation.

1. **Uniform speed** — any bone at constant velocity reads as floating. NEVER TRANS_LINEAR for whole motions.
2. **No anticipation** — attacks starting from rest pose read as teleported force. 4-frame minimum backwards shift before any attack.
3. **Symmetric timing** — raise takes same time as lower. For heavy objects: raise SLOWER, drop FASTER. Gravity is asymmetric.
4. **Lockstep parts** — torso, arm, and rocks all moving on the same keyframe = rigid puppet. Stagger: torso → shoulder (+2–3f) → elbow (+5–6f) → fist (+8–10f) → rocks (+12–16f).
5. **No impact hold** — attack without a 2–4 frame freeze at contact reads as passing through the ground, not hitting it. The freeze IS the impact.
6. **Too-fast recovery** — snapping back to idle in under 0.5s after a heavy swing. Recovery should be 30–50% of total attack duration.
7. **Dead dressing** — flowers and moss that don't react to golem movement (lag by 6–10 frames) read as painted on, not alive.
8. **Head doesn't lead** — head should telegraph intent 1–2 frames before the body. Head turns first, body follows.
9. **No escalation across multi-hit** — three identical trunk sweeps read as a loop. Animation itself must encode the escalation (shorter anticipation, wider arc, more overshoot, longer recovery each time).
10. **Hip sway without hip drop** — side-to-side lean without corresponding hip DROP reads as rocking, not carrying weight. Hip drops 5–8% of body height per step.

---

## Appendix B — Godot ease curve reference

| Motion type | TRANS_ | EASE_ | Notes |
|---|---|---|---|
| Gravity drop (free-fall, slam) | TRANS_EXPO | EASE_IN | Starts near-zero, accelerates dramatically |
| Settle / come to rest | TRANS_CUBIC | EASE_OUT | Fast start, slow brake |
| Both ends heavy (roll settle) | TRANS_CUBIC | EASE_IN_OUT | Symmetric heavy taper |
| Micro-oscillation / breathing | TRANS_SINE | EASE_IN_OUT | Gentle diminishing |
| Explosive release (wrench, crack) | TRANS_EXPO | EASE_IN (4f) + TRANS_LINEAR (2f) | Build then hard-stop |
| Weight shift / lean | TRANS_SINE | EASE_IN_OUT | Never jerky, always smooth |
| Impact hold (freeze) | TRANS_LINEAR | — | Identical keyframes: zero velocity |
| Foot plant (impact) | TRANS_EXPO | EASE_IN | Zero-to-crash |
| Foot lift (swing) | TRANS_CUBIC | EASE_OUT | Slow start, momentum builds |

---

## Appendix C — Reference clip wishlist for Joan

Organized by priority (most critical to the animation build first):

| Priority | Move | What to find | Why critical |
|---|---|---|---|
| 1 | `lumber_walk` | SotC Colossus 2 (Quadratus) walking | Gold standard heavy gait — hip drop, head bob |
| 1 | `ground_pound` | Yhorm the Giant (DS3) ground slam | Gold standard wind-up + peak-hold + impact |
| 1 | `trunk_rip` | LOTR BFME troll tree-attack | Joan-named reference — strain + wrench |
| 1 | `death_collapse` | SotC Colossus 6 (Barba) forward fall | Best heavy-creature forward topple in games |
| 2 | `trunk_sweep` | Yhorm horizontal double sweep | Escalation arc across multi-hit |
| 2 | `tree_fall` | Real slow-motion tree fall | Asymmetric timing — slow start / fast end |
| 2 | `rock_movement` | Real rockfall / quarry footage | Low bounce, rolling settle physics |
| 3 | `root_snare` | Princess Mononoke forest eruptions | Staggered-radial root eruption feel |
| 3 | `root_snare` | Elden Ring Erdtree Avatar vines | Channel posture + vine eruption |
| 3 | `trunk_sweep` | Sekiro Seven Ashina Spears sweep | Polearm lag/drag during horizontal arc |

---

## Spec confidence summary

| Move | Confidence | Notes |
|---|---|---|
| `rock_movement` | HIGH | Physics well-documented; visual ref clips = easy to find |
| `tree_fall` | HIGH | Classical rigid-body physics; LOTR/Ghibli refs well-known |
| `trunk_rip` | HIGH | Joan named BFME trolls directly; engram #1625 has full breakdown |
| `trunk_sweep` | HIGH | Engram #1625 full breakdown; Yhorm is perfect touchstone |
| `lumber_walk` | HIGH | Engram #1625 full breakdown; SotC Quadratus is ideal ref |
| `ground_pound` | HIGH | Engram #1625 full breakdown; Yhorm + GoW are ideal refs |
| `root_snare` | MEDIUM | Move type understood; golem-specific channel POSTURE is thin |
| `death_collapse` | HIGH | SotC + GoW troll death are ideal refs; canon decision documented |

**Moves needing Joan's visual annex most urgently**: `root_snare` (channel posture), `lumber_walk` (hip-drop confirmation), `trunk_rip` (BFME clip).
