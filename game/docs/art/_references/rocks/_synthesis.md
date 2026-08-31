# Reference: rocks — unique boulders for village_gen.py (2026-07-18)

Triggered by PO feedback: "no vas a encontrar piedras que sean muy
similares" — the vegetation-ring rocks and campfire stones were all the
same ico-sphere stamp with only radius jitter. Hunted MULTI-SOURCE real
boulder photography before touching the generator.

## Images

| File | What it shows |
|---|---|
| `granite_boulders_elrig.jpg` | Granite boulders, Elrig (Scotland) — eyeballed 2026-07-18 |
| `granite_boulders_trendrine_hill.jpg` | Granite boulders, Trendrine Hill (Cornwall) — eyeballed 2026-07-18 |
| `granite_boulders_beinn_an_eun.jpg` | Granite boulder, Beinn an Eun (Scotland) — eyeballed 2026-07-18 |

## Qué se VE (all three, cross-checked)

- **No two boulders share a silhouette**: Elrig shows angular fractured
  blocks; Trendrine Hill shows a flat STACKED slab (almost a "loaf" shape,
  clearly NOT a squashed sphere); Beinn an Eun shows one rounded,
  egg-like boulder sitting mostly ALONE. Real rock fields are a MIX of
  silhouette families, not one shape repeated at different sizes.
- **Non-uniform scale is the #1 tell**: every real boulder is longer on one
  axis than the others (never a uniform squash-sphere) — e.g. Trendrine's
  slab is wide+shallow, Beinn an Eun's is tall+narrow.
- **Surface**: faceted/fractured planes on the granite (flat-ish chipped
  faces meeting at hard edges), NOT a smooth bumpy blob — confirms
  low-poly + noise-displaced verts (hard facets) is closer to real than a
  smooth subdivided sphere.
- **Color**: base grey-tan granite (not neutral grey) with patchy
  lichen — pale sage-green and white-grey blotches, plus dark moss at the
  base where it meets soil. Sampled: base body ≈ `(0.52, 0.51, 0.46)`
  (warm light grey-tan), lichen patches ≈ `(0.58, 0.60, 0.48)` (pale
  sage). Previous code used a flat neutral grey `(0.42, 0.41, 0.38)` /
  `(0.40, 0.40, 0.42)` with no warmth or greenish cast — too dead/uniform.
- Boulders sit PARTLY embedded in the ground (grass/heather grows up
  against the base) — not floating spheres resting on top of the surface.

## Qué capturar (reusable takeaway for village_gen.py)

1. **Per-rock non-uniform scale**: independent random X/Y/Z scale factors
   (not one uniform squash value) — this alone breaks the "clone stamp"
   read.
2. **Per-rock random full rotation** (Z yaw + slight X/Y tilt), not just
   upright placement.
3. **Vertex displacement via noise** (bmesh, verts pushed along their
   normals by `mathutils.noise.noise()`) to fracture the smooth ico-sphere
   into hard faceted planes — matches the chipped-granite look better than
   a bare subdivided sphere.
4. Warm grey-tan base color + slight per-rock hue/value jitter (small
   material pool, not one flat grey) approximates the lichen patchiness
   cheaply without a full vertex-color pass.
5. Sink the rock slightly into the terrain (lower the placement Z a touch)
   so it reads as embedded, not resting on top.

## Fuentes

- [Granite boulders, Elrig — geograph.org.uk (Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:Granite_boulders,_Elrig_-_geograph.org.uk_-_1756754.jpg), CC BY-SA 2.0, Richard Webb, downloaded 2026-07-18.
- [Granite boulders on Trendrine Hill — geograph.org.uk (Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:Granite_boulders_on_Trendrine_Hill_-_geograph.org.uk_-_99401.jpg), CC BY-SA 2.0, downloaded 2026-07-18.
- [Granite boulders, Beinn an Eun — geograph.org.uk (Wikimedia Commons)](https://commons.wikimedia.org/wiki/File:Granite_boulders,_Beinn_an_Eun_-_geograph.org.uk_-_913445.jpg), CC BY-SA 2.0, Richard Webb, downloaded 2026-07-18.

## GAP

- All three sources are the same site type (geograph.org.uk, UK moorland
  granite) — same GEOGRAPHIC source diversity issue Joan warned about in
  principle ("si la primera fuente está mal..."). A 4th source from a
  different rock type/region (e.g. sedimentary/desert boulders) would
  cross-check whether "faceted planes" generalizes or is granite-specific.
  Not pulled this round — Wikimedia Commons rate-limited the session
  (429) before a broader search could run.
