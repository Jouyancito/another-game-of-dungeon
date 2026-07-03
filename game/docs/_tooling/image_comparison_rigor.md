# Image Comparison Rigor — render vs target

Proposal + method for making Claude's render-vs-target visual judgment **quantitative and reproducible**, not a single eyeball pass.

Status: proposal (2026-06-28). Scope: corpóreo (oso Lawen) + DP game assets (hard-surface, organic, accessories). Backend: WSL2 Ubuntu + GTX 1080 8GB, Python outside Blender. All claims below survived adversarial verification (two research streams); nothing in the "cut" list — there was none — but every item carries its honest blind spot.

---

## 1. Honest framing — where we are and why it's below par

**What Claude native vision CAN do:** read a render, name gross gaps (broken hand, wrong stance, washed color), and run the `art-ref-critic` 6-axis rubric + Naturalness Audit. That qualitative read is genuinely useful and stays the final arbiter.

**What it CANNOT do reliably:**
- Produce a **stable, monotonic number** — "is pass 7 closer to target than pass 6?" is currently vibes. We can't detect small regressions or know when to STOP iterating.
- Judge **palette** precisely. "Acid-lime vs sage vs #8DAB42" has burned us repeatedly; the eye (and an auto-critic) wrongly demanded sage once. Color needs a perceptual ΔE number, not adjectives.
- Resist **its own confident-but-wrong calls.** On record: `corporeo-3d` "verified with my eyes, was wrong" — the bear's left arm was webbed to the torso and the hand broken by can-removal trim, yet it got "aprobado para placeholder" (that failure is exactly why the Naturalness Audit + no-vibe-approval rule were added).

**Why current state is below where it should be:** the only computed scaffolding we built — `corporeo-3d/blender/silhouette_separation.py` (v0.1) — gave **false negatives** because it hardcoded the arm Z-band to a stale coordinate frame. So today the loop is: tweak one param → re-render → vibe-check → thrash 10+ rounds (the golem solidity marathon, the motion saga). One hand-rolled scalar is **gameable** and we proved it twice. The fix is not "a better single number" — it's **multiple complementary metrics + mandatory alignment + a localizing heatmap**, feeding (never overriding) the eye.

**The honest ceiling (stated up front):** a broken/unnatural hand can still score great on SSIM/LPIPS/DISTS if it's well-textured. These metrics quantify the **nameable axes** and catch **regressions** — they do NOT certify naturalness. The Naturalness Audit stays human/adversarial. The eye remains final judge.

---

## 2. The proposed method — a closed render → critique → score loop

A three-stage pipeline. Stage 1 is pure Python (mostly CPU). Stage 2 is Claude (cloud). Stage 3 is the orchestration that makes it a loop.

### Stage 1 — Align, compute metrics, build the overlay (script: `compare_render.py`)

1. **Render the preview in EEVEE, not Cycles.** EEVEE renders headless on this Blender 5.1.2 build (engine id `BLENDER_EEVEE`; the old "EEVEE needs a GL context" claim was corrected in `corporeo-3d`). This kills the Cycles non-determinism (T101561) that makes pixel metrics read device/sampling noise as "difference." Use `film_transparent` for a free alpha mask (stable bpy API). If a pass MUST be Cycles, pin `cycles.device` + `seed` + `samples`.
2. **ALIGN FIRST — the linchpin.** Every metric below is garbage-in without this. Two paths, in priority order:
   - **Controlled camera (best):** drive the bpy preview camera to the ref's framing/scale so registration is *upstream and deterministic*. When the ref is itself a render, render the asset from the SAME camera and skip 2D registration entirely.
   - **ECC fallback:** `cv2.findTransformECC(MOTION_AFFINE)` + `warpAffine`, after a bbox pre-center (ECC diverges otherwise).
   - **DO NOT use feature matching** (ORB/SIFT/LoFTR) on flat-toon DP_ToonGrounded clay renders — too few keypoints, it fails. A hand-drawn 2D ref (the bear illustration) will never pixel-align; accept silhouette-level alignment and judge proportion, not pixels.
3. **Compute the metric panel** (details in §3) and emit one JSON blob: silhouette IoU + matchShapes + bbox-aspect, per-zone CIEDE2000 ΔE, DISTS, SSIM scalar, optional DreamSim.
4. **Build the grounding overlay board** (anti-hallucination layer): aligned side-by-side, alpha-IoU overlay, SSIM/FLIP heatmap, palette swatches (target vs render with ΔE). Label every panel; few readable panels beat many low-res ones.

### Stage 2 — Claude reads images + metrics against a FIXED RUBRIC

Claude is handed: the aligned render, the target, the overlay board, AND the metric JSON. It fills the rubric below — **per-axis score + evidence + concrete action BEFORE any aggregate.** Independent per-criterion scoring is the documented cure for verbosity/halo bias. The prompt MUST force Claude to **reconcile eye-vs-metric and flag disagreement** — numbers never silently override a clear eye read, and the eye never silently ignores a number.

### Stage 3 — Scored, actionable output + loop control

Aggregate with **min-gate, not average** (a broken pose cannot be averaged away by a great palette). Record the headline number (DreamSim or IoU) each pass into a monotonic log. **Stop condition:** plateau on the headline number, or all axes ≥ threshold. This is what ends the 10+ round thrash with an auditable record.

> The flaky part is the **Editor** step (map "arms too short" → a deterministic bpy/material edit). That needs a maintained parameter table per generator or the loop flails. Organic detail stays Joan-in-the-loop: Claude = plumbing + scoring, Joan = art.

### The FIXED RUBRIC

| Axis | What it grades | Computed metric(s) that ground it | Score | Blind spot the eye must cover |
|------|----------------|-----------------------------------|-------|-------------------------------|
| **Silhouette** | Read-at-a-glance shape, limb length, mass | Alpha-IoU + `matchShapes(I1)` + bbox-aspect | 1–5 | Reads shape only; a correct silhouette can still hide a broken hand inside it |
| **Proportion** | Head:body, limb:torso, prop:hand ratios | bbox-aspect + IoU over a **bounds-normalized** Z-band | 1–5 | Band must be normalized to THIS mesh's bounds (the v0.1 false-negative cause) |
| **Palette** | Hue/sat/value per brand zone | KMeans-LAB centroids + **CIEDE2000 ΔE** (alpha-masked) | 1–5 | Compare against the RENDER-OUTPUT target (post-lightening), not the raw 2D sample |
| **Material / value** | Does the surface READ the same | **DISTS** (texture-tolerant) + SSIM scalar | 1–5 | High score ≠ correct geometry; texture can fake a missing shape |
| **Pose / naturalness** | Stance + anatomical plausibility | DreamSim (progress only) + overlay heatmap | 1–5 | **Mostly the eye.** Naturalness Audit is NOT a metric — broken digits score fine |

Min-aggregate verdict = `min(axis scores)`. Any axis ≤ 2 ⇒ FAIL regardless of the rest.

---

## 3. Recommended local tooling stack (minimal, free, GTX 1080 / WSL2)

**Hard rule: separate env.** Do NOT install into the UniRig conda env — it pins a fragile torch/torch-scatter/spconv tree and adding `dreamsim`/`lpips`/`pyiqa`/`open_clip`/`peft` risks breaking the one working auto-rigger. Build an isolated `critic` venv/conda env. None of these are bpy APIs, so Blender 5.1.2 churn is irrelevant to the toolchain — the only Blender dependency is the render setup (EEVEE + `film_transparent`).

### Tier 0 — pure CPU, zero model, adopt FIRST

| Tool | Metric | Why we want it | Blind spot |
|------|--------|----------------|------------|
| **OpenCV** `findTransformECC` + `warpAffine` | Alignment (ECC affine) | THE precondition — upgrades every other metric from noise to signal | Diverges without bbox pre-center; fails on feature-matching for flat toon (use ECC/controlled-camera) |
| **OpenCV/numpy** alpha mask | Silhouette **IoU** | #1 axis; principled replacement for the untrusted `silhouette_separation.py` | Shape-only; normalize to mesh bounds + same camera |
| **OpenCV** `matchShapes(CONTOURS_MATCH_I1)` | Contour shape distance | Pairs with IoU so the silhouette number isn't a single gameable scalar | Rotation/scale invariant — pair with bbox-aspect to keep proportion error visible |
| **scikit-image** `rgb2lab` + **sklearn** `KMeans` + `deltaE_ciede2000` | Per-zone **CIEDE2000 ΔE** | Turns the brand-fur axis (`#9DBB4D`) into a perceptual number; kills eyeballed color calls | Cluster in LAB; mask alpha>0 first or BG pollutes centroids; compare post-lightening target |
| **scikit-image** `structural_similarity(full=True)` | SSIM scalar **+ free heatmap** | Cheap value/structure number; the map is a two-for-one overlay | Colourblind (never palette); 1px shift tanks it (needs alignment); EEVEE to avoid noise |
| **OpenCV** `calcHist` + `compareHist` | L-channel histogram | One-line pre-filter for **global value/exposure drift** (the Cycles-lightening artifact) | Blind to all spatial info; redundant with palette — keep only as a tripwire, not a gate |
| **OpenCV** `Canny`→`distanceTransform` Chamfer | Edge-map / Chamfer | Compares a GREY clay render vs a COLORED 2D ref on pure structure (cross-domain) | Canny over-fires on procedural texels — blur first or use HED; compare Chamfer, not pixel-IoU |
| **NVIDIA FLIP** (`pip install flip-evaluator`) | Perceptual error map | Purpose-built render-vs-ref localizer; mean + heatmap | Import is `import flip_evaluator as flip` (not `import flip`); needs alignment; inherits its metric's blind spots |
| **ImageMagick** `compare -metric RMSE` | Dependency-free tripwire | Batch gate before spending GPU on the deep panel | On WSL2 it's often IMv6 → command is `compare`/`convert` with **no `magick` prefix**; skip pHash for grading |

### Tier 1 — small GPU models (Ollama must be closed to free ~4.7GB)

| Tool | Metric | Why we want it | Blind spot |
|------|--------|----------------|------------|
| **DISTS** (`pip install DISTS-pytorch`, or via pyiqa/torchmetrics) | Structure + texture similarity | **Best single "does the material/value READ the same" metric** for procedural low-poly that's never pixel-identical; most alignment-forgiving deep metric. VGG16 <1GB VRAM | High score on a well-textured broken shape; surface is the LAST axis to fix |
| **DreamSim** (`pip install dreamsim`, MIT) | Holistic human-aligned distance | Best single "reads-as-same-to-a-human" **progress/regression tracker**. ViT-B single-branch a few hundred MB; ensemble ~1.5–2GB | Background-sensitive (mask subject); NOISY for cross-domain 2D-concept-vs-3D — use edge/silhouette there; weights research-only, never ship |
| **pyiqa** (`pip install pyiqa`) | One-install backbone | `create_metric('dists'/'lpips'/'ms_ssim')` behind one factory — the practical core of `compare_render.py` | CLI is **per-metric** (loop or use the Python factory in one process); some weights non-commercial; no DreamSim/IoU/ΔE — pair with Tier 0 |
| **DINOv2** (`torch.hub` vitb14) — optional | Alignment-free "same construct/stance" cosine | Coarse category/style guardrail, resize-only | Doesn't move any of the 4 graded axes — guardrail only. **Drop CLIP** (too coarse: "two different golems score high") |

### Deliberately deprioritized (mechanically run, but not adopted as gates)
- **LPIPS** — largely redundant with DISTS for toon, and over-penalizes a *correct* stylization shift (reads "far" when artistically right). Keep at most as a cheap second perceptual opinion, never a gate.
- **Reward models** (HPSv2/3, ImageReward, PickScore) — trained on photoreal/illustration aesthetics; a deliberately flat toon render scores LOW despite being on-style. Actively misleading as an absolute gate. Only legit use: relative ranking of N variants of the SAME asset (toon-bias constant). Closest-to-cut.
- **pHash** — near-duplicate detector; a real iterative change reads "perceptually same." Weak as a fidelity grade.

**Minimal concrete stack to start:** Tier 0 (OpenCV + scikit-image + sklearn + Pillow + ImageMagick) **+ DISTS**. That alone covers alignment, silhouette, palette, value, and material. Add DreamSim for the progress number once the loop exists; add pyiqa when you want LPIPS/MS-SSIM behind one API.

---

## 4. Local vs cloud — the answer for Joan

| Component | Where it runs | Verdict |
|-----------|---------------|---------|
| Render (bpy headless, EEVEE) | **Local**, free | Always local |
| All metrics + alignment + overlay (Tier 0/1) | **Local**, free, fits 8GB | Always local |
| The actual VERDICT (rubric judgment) | **Cloud — Claude vision API** | The one paid/non-local piece. Acceptable and disclosed; Joan already uses it |
| Cheap inner-loop gate (optional) | **Local small VLM** | Feasible but low value — see below |

**What a local VLM could do (and why it's `low` priority):** Qwen2.5-VL-3B or Qwen3-VL-2B GGUF runs via `llama.cpp` (`llama-mtmd-cli -m model.gguf --mmproj mmproj.gguf --image ...`). 2B/3B Q4 ≈ 2–4GB, fits 8GB once Ollama's ~4.7GB is freed. Notes: GTX 1080 is Pascal (sm_61, no native FP16) → use INT quant (Q4/Q5_K_M), the FP16 vision encoder is slow so batch-only; Ollama mishandles `mmproj` → use llama.cpp / LM Studio / Jan and sanity-probe that it actually "sees" the image.

**The honest tradeoff:** small open VLMs sit ~64% on multimodal reward benches — weakest exactly on the **fine naturalness tells** that historically fooled the eye on the bear. So a local VLM is a **cheap inner-loop gate only** (cull obviously-bad variants before spending Claude tokens), **never the verdict.** Even frontier VLMs are only ~70–76% on multimodal reward, so **Joan stays final arbiter** regardless.

**Bottom line:** everything is local and free except the verdict, which must stay Claude-cloud-vision. A local VLM is a cost optimization on the inner loop, not core.

---

## 5. Calibration plan — validate on the bear renders

**Goal:** make the loop's numbers match Joan's eye, closing the "¿de verdad creés que está bien? se ve deforme" gap.

**The data gap, stated honestly:** `C:\Users\the_j\Desktop\bear_presenter_preview\` holds **only 6 renders** — `gesture_mid`, `gesture_mid_face`, `head_turned`, `head_turned_full`, `rest_face`, `rest_front` — NOT a labeled iteration set, and **there is NO 2D target image committed for the bear** (the brand/silhouette reference). 6 samples is far too few for stable thresholds or a Spearman correlation. Two prerequisites before calibration is meaningful:
1. **Commit the 2D target** (the bear concept art) into `corporeo-3d/_refs/` per the reference-library convention — without it, silhouette/proportion/palette have nothing to score against (only the render-vs-render progress metrics work).
2. **Generate a variant set** (~20–40 deliberate good/bad variants of the same pose) and collect Joan's PASS/FAIL + worst-offender label per variant. Labeling itself consumes Claude API.

**Then calibrate (all local, free):**
1. Run `compare_render.py` over every labeled variant → metric vector per image.
2. **Spearman correlation** (`scipy.stats.spearmanr`, CPU) between each metric and Joan's ordering. Keep the metrics that track her eye; demote the ones that don't.
3. Set **conservative per-axis thresholds** (small-sample → expect overfit; keep them loose and re-validate the band **per mesh frame** — the v0.1 lesson).
4. Optional, later: a light **DreamSim LoRA fine-tune** (`peft`, fits the 1080) to nudge the headline metric toward Joan's preference. Only after the core scaffold is proven.

**Sequencing:** this is the trust-closer, NOT "adopt now." Build alignment + IoU + ΔE + DISTS + overlay + rubric FIRST; calibrate once enough labeled bear variants exist.

---

## 6. Upgrade `art-ref-critic` with this

The skill (`C:\Users\the_j\.claude\skills\art-ref-critic\SKILL.md`) already has the right *doctrine* — 6 axes (silhouette first), the Naturalness Audit, no-vibe-approval, viewer-faithful renders as ground truth. This proposal makes that doctrine **measured** instead of prose. Concrete upgrades:

- **Add a `compare_render.py` invocation as step 0** of the method: align + compute the metric panel + build the overlay board, THEN run the 6 axes — the skill currently says "Read both images first," which this automates and grounds.
- **Attach a computed number to each of the 6 axes** using the §2 rubric table (IoU+matchShapes → silhouette/proportion; CIEDE2000 → color; DISTS → material/value; DreamSim → progress). The axes stay; they gain evidence.
- **Replace the untrusted `silhouette_separation.py`** with the bounds-normalized alpha-IoU + matchShapes pair, and bank the lesson explicitly: normalize the band to the mesh's OWN bounds, render at the SAME controlled camera/scale as the ref, never one scalar.
- **Keep the Naturalness Audit fully human/adversarial** — add a one-line caveat that metrics do NOT cover it (a textured broken hand scores fine), so no future pass treats a green metric panel as naturalness approval.
- **Add min-aggregate + monotonic-log discipline** so "is this pass better?" is answered by the headline number plus a plateau STOP, ending the thrash the skill's own anti-patterns already warn about.
- **Disclose the one cloud dependency** (the verdict) and the env-isolation rule (separate `critic` env, not UniRig) in the skill's setup notes.

Net: the skill stops being "look carefully and don't lie to yourself" and becomes "look carefully, *with a grounded panel that makes lying to yourself hard*."

---

### Cross-cutting non-negotiables (do not skip)
1. **Separate `critic` env** — never pollute UniRig's torch tree.
2. **EEVEE or pinned-Cycles renders** — pixel metrics read device noise otherwise.
3. **Align before everything** — controlled camera ideal, ECC fallback, no feature-matching on toon.
4. **Multiple metrics + heatmap, min-aggregate, never one number** — single scalars are gameable (proven twice).
5. **Eye wins on eye-vs-metric disagreement until the metric is proven on that mesh frame.**
