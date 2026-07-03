# Blender Force-Multiplier Playbook — Dungeon Party + Lawen corpóreo

**Intent.** This is the prioritized, empirically-verified list of Blender techniques that turn hours of manual modeling into minutes of `bpy` script, scoped to OUR modality: **headless `blender --background --python` is primary**, GUI-only tricks are deprioritized. Every item below was probed on the real stack (`blender-5.1.2-windows-x64 --background --factory-startup`) — items that exist but fail headless (`poll() failed` / `context is incorrect`) are excluded per the verification. All survivors are **free GPL, CPU/RAM-bound, near-zero VRAM** — they run CONCURRENTLY with the GPU UniRig/Ollama path, so you do NOT close Ollama for any of this (only rigging/Cycles needs the GPU). Build FROM reference images, pin every seed for reproducible eye-review.

---

## TOP-10 "adopt now" (sorted by leverage)

| # | Technique | Replaces (manual hours) | Asset type | bpy headless? | Priority |
|---|-----------|-------------------------|------------|:-------------:|:--------:|
| 1 | **GN Scatter** (Distribute Points → Instance on Points → Realize) | Hand-placing rocks/grass/debris across a whole map | Hard-surface / Environment | ✅ | HIGH |
| 2 | **Shrinkwrap-conform** (modifier, depsgraph-bake) | Hand-conforming glasses/hat/armor to body curvature, per character | Accessories / Organic | ✅ | HIGH |
| 3 | **Data Transfer — vertex weights** (auto-skin) | Hand-weight-painting every cloth/soft-armor piece to the rig | Accessories | ✅ | HIGH |
| 4 | **Bone / Vertex parent** (pure data API) | Manually rigging+keying a rigid prop to follow a bone | Accessories | ✅ | HIGH |
| 5 | **Solidify** (one-property thickness) | Extrude-and-cap chore on every flat shell (frames, plates, brims, walls) | Accessories / Hard-surface | ✅ | HIGH |
| 6 | **Deform-modifier stack** (Displace/Cast/SimpleDeform/Smooth) | ~80% of GUI sculpt mass-brushes (Inflate/Smooth/Bend bulk shaping) | Organic / Hard-surface | ✅ | HIGH |
| 7 | **Bevel modifier** (ANGLE-limit chamfer pass) | Hand-bmesh chamfer loops — the DP_ToonGrounded signature edge | Hard-surface | ✅ | HIGH |
| 8 | **Skin modifier + Subdivision** (edge-skeleton → organic base) | Box-modeling a rough creature/limb body block from scratch | Organic | ✅ | HIGH |
| 9 | **Non-destructive modifier stack + depsgraph-bake / `export_apply`** | The substrate that makes 1–8 re-tunable; runs while GPU is busy | All | ✅ | HIGH |
| 10 | **NumPy `foreach_get/set`** vectorized mesh I/O | Python-loop vertex edits on dense meshes (jitter, masks, deforms) | All / Batch | ✅ | HIGH |

> Also HIGH but section-scoped (not in the top-10 because narrower): BVHTree raycast seating, Collection API, the Godot-correct glTF export loop, `ensure_lookup_table` hygiene, and the 5.1.2 API cheat-sheet. See sections below.

---

## Organic — oso Lawen, creatures, enemies

> **Scope honesty (carried from verification):** this chain is a **blocking / proxy / simple-creature generator** — rough bear body-block, worms, larvae, lizards, tentacles, ooze variants. It does NOT overturn the rule that **finished HERO organic = pack / AI base (SF3D/TRELLIS/Meshy) + look from AI-2D or Joan.** The 503-param runevision study (in `blender-asset-smith`) still stands: random organic generation produces mostly-invalid quadrupeds.

**The organic base-mesh chain (every step verified headless):**
`Skin/Metaball → Subsurf → voxel_remesh → quadriflow + symmetrize → deform-stack → lattice → shrinkwrap`, with **eyes/snout/horns as separate child meshes** (not sculpted in).

### Skin modifier + Subdivision — edge-skeleton → organic base `[HIGH]`
- **What:** lay an edge "skeleton", give per-vertex radius, and the Skin modifier inflates a watertight tube-body; Subsurf smooths it.
- **Leverage:** the single biggest NEW headless organic capability in the batch — a rough limbed/tubular body in seconds, no box-modeling.
- **How:**
  ```python
  m = obj.modifiers.new("skin", 'SKIN')
  sv = obj.data.skin_vertices[0].data
  sv[i].radius = (0.3, 0.3); sv[root_i].use_root = True   # use_loose for stray verts
  obj.modifiers.new("sub", 'SUBSURF').levels = 2
  # bake: bpy.data.meshes.new_from_object(obj.evaluated_get(dg), depsgraph=dg)
  ```
- **Gotchas:** branch joints produce ugly pole clusters — **ALWAYS follow with `voxel_remesh` then `quadriflow`** (this fix is the real extension). Don't ship it as hero geometry.

### Deform-modifier stack — the headless sculpt-mass-brush substitute `[HIGH]`
- **What:** `Displace` (puff), `Cast` (sphere-ify), `SimpleDeform` (bend/taper/twist), `Smooth` — deterministic bulk shaping that reaches ~80% of the GUI mass-brushes.
- **Leverage:** replaces the **GUI-only** Pose/Elastic/Cloth/Inflate brushes (confirmed `poll() failed` headless) for everything except a hero freehand grab.
- **How:**
  ```python
  d = obj.modifiers.new("puff", 'DISPLACE')
  d.direction = 'NORMAL'; d.mid_level = 0.0; d.strength = 0.05   # NO texture = real inflate (verified)
  obj.modifiers.new("ball", 'CAST').cast_type = 'SPHERE'
  obj.modifiers.new("bend", 'SIMPLE_DEFORM').deform_method = 'BEND'
  ```
- **Gotchas:** Displace-along-NORMAL puffs each island **separately** on a non-watertight mesh → **remesh BEFORE inflating.** SimpleDeform's axis is local **Z** (orient via an origin empty). Not a 1:1 of artist freehand — hero gesture goes to Joan in GUI.

### Metaballs — blobby fused base via implicit surfaces `[MEDIUM]`
- **What:** BALL/ELLIPSOID/CAPSULE/CUBE elements fuse into one smooth surface; polygonize via depsgraph.
- **Leverage:** NEW oozes / king-slime / soft-mass variants + the bear's gross body block. (Slimes already ship as pack gltf — this adds, doesn't displace.)
- **How:** add a `MetaBall`, append `elements.new(type='BALL')`, then `mb_obj.evaluated_get(dg)` + `new_from_object`. Do NOT `to_mesh` a non-basis member directly.
- **Gotchas:** metaball topology **fights flat-toon shading** (the documented reason blobs are "pack"). Metaballs solve only GEOMETRY — the toon-shader problem stays separate and unsolved.

### Lattice / Cage deform — fast global proportion variants `[MEDIUM]`
- **What:** bind a mesh to a low-res lattice; move lattice points to scale/squash/stretch GLOBALLY.
- **Leverage:** spin N size variants (small/fat/tall enemies) from one base + squash-stretch, non-destructive.
- **How:** `lat = bpy.data.lattices.new(...)` with `points_u/v/w=3`, `interpolation_type_u='KEY_BSPLINE'`; write `LatticePoint.co_deform`; add `LATTICE` modifier on the mesh.
- **Gotchas:** **cannot un-fold/un-fuse a webbed limb** (corpóreo 2026-06-19 proof) — only smooths GLOBAL proportion. It's a refinement multiplier, not a base generator.

### Voxel Remesh — watertight fuse (chain cleanup) `[MEDIUM, already adopted]`
- **What:** `bpy.ops.object.voxel_remesh` rebuilds a uniform-tri watertight surface, dissolving Skin/metaball branch-joint poles.
- **Note:** already documented+proven in both skills (corpóreo: size 0.012 fused 473 islands into one 48k surface). New value = its **chain role** (the fuse stage). Uniform tris, no edge-flow → **must follow with quadriflow for rigged meshes**; destroys UV/material → remesh BEFORE texturing.

### QuadriFlow — quad game topology (chain edge-flow) `[MEDIUM, already adopted]`
- **What:** `bpy.ops.object.quadriflow_remesh` → ~100% quads for clean deformation.
- **Gotchas:** **hangs on dirty input → run `voxel_remesh` first + a timeout.** Down-targeting **shatters thin features/heads into spikes** (judge from 3/4 + face close-up). GLB stores tris only → quads do NOT survive a GLB round-trip (**save FBX/.blend**; FBX also for Mixamo). Mandatory `mesh.symmetrize` after.

### Proportional Edit — soft-falloff local bulges `[LOW]`
- **What:** survives ONLY via a bmesh substitute (per-vert distance-falloff loop `v.co += dir*weight`) — pure-data, headless, deterministic.
- **Gotchas:** the `transform.translate(use_proportional_edit=True)` operator path needs an edit-mode VIEW_3D override and is finicky in `--background` — **do NOT script the operator.** For any GLOBAL change the Lattice is cleaner; keep this only for tiny local bulges/tapers.

> **GUI-only boundary (do NOT script — substitute as noted):** Sculpt mass-brushes (Pose/Elastic/Cloth/Boundary), mesh/cloth **filters**, and **Dyntopo** all EXIST on 5.1.2 but `poll()`-fail headless (no PBVH/VIEW_3D). Substitute → deform-stack + lattice + voxel_remesh-at-small-voxel; reserve true sculpt for Joan's GUI polish. **Mask→Extract:** you CAN write the `.sculpt_mask` attribute headless, but `paint_mask_extract`/`paint_mask_slice` FAIL even with `temp_override` — to carve a backpack/armor sub-piece use a **bmesh predicate split** (`bmesh.ops.split`/duplicate → separate) + Solidify + Shrinkwrap-reseat. **Multires:** CUT — its whole payoff (micro-detail bake) is exactly what the flat-toon contract throws away.

---

## Hard-surface & Procedural — golem, props, weapons/tools, environment kit

### Non-destructive modifier stack + depsgraph-bake `[HIGH — the substrate]`
- **What:** `obj.modifiers.new(name, type)` builds a live, re-tunable stack; bake without GUI via depsgraph, or let the exporter apply it.
- **Leverage:** enables EVERY modifier below, and because it's CPU-only it runs **WHILE** the GPU does UniRig/Cycles.
- **How:**
  ```python
  dg = bpy.context.evaluated_depsgraph_get()
  me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), depsgraph=dg)  # +preserve_all_data_layers=True if you need vgroups/normals/UVs
  obj.data = me
  # or, for a single export: export_scene.gltf(export_apply=True)  # bakes ONLY into the GLB, source keeps its live stack
  ```
- **Gotchas:** `export_apply=True` applies **ALL** modifiers **including Armature → it destroys the skin on rigged meshes** (see export loop). `modifier_apply()` itself needs `temp_override`; depsgraph/`export_apply` are the robust default. Order (Mirror→Bevel→Solidify→Subsurf→Decimate) is a starting point, not canon — tune per asset.

### Bevel modifier — the DP chamfer signature `[HIGH]`
- **What:** the "ONE hard chamfer pass, 3–5% edge, 1 segment" DP_ToonGrounded signature as a re-tunable modifier instead of a hand chamfer loop.
- **How:** `bev = obj.modifiers.new("bev",'BEVEL'); bev.limit_method='ANGLE'; bev.angle_limit=radians(40); bev.width=0.03; bev.segments=1; bev.use_clamp_overlap=True`.
- **Gotchas:** only **ANGLE** mode is hands-off. **WEIGHT** mode still needs edges tagged programmatically — it reads the generic `bevel_weight_edge` attribute (moved from `bm.edges.layers.bevel_weight` in 4.0). **Harden Normals is MOOT for flat-shaded DP** (`use_smooth=False`) — only matters on the "rounded" family, and needs `shade_auto_smooth`/Smooth-by-Angle since `mesh.use_auto_smooth` was removed in 4.1.

### Solidify — thickness for flat shells `[HIGH]`
- **What:** one property turns a profile/plate into real thickness.
- **Leverage:** Joan's accessory need — glasses frames/lenses, hat brims, belt/shoulder plates — plus wall/roof/fence thickness for the kit. No manual extrude-and-cap.
- **How:** `s = obj.modifiers.new("solid",'SOLIDIFY'); s.thickness=0.02`. For accessories: **Shrinkwrap to surface THEN Solidify outward.**
- **Gotchas:** thickness is in LOCAL coords — **apply scale first** or non-uniform scale makes one side thicker.

### Geometry Nodes SCATTER — the "scenarios fast" lever `[HIGH]`
- **What:** `GeometryNodeDistributePointsOnFaces` (POISSON = min-distance) → `GeometryNodeInstanceOnPoints` → Rotate/Scale instances (`FunctionNodeRandomValue`) → `GeometryNodeRealizeInstances`. GN node-tree CONSTRUCTION is headless-safe.
- **Leverage:** single biggest multiplier for scenarios; maps directly to `floor1_prairie` scatter. Define the ecological rule once, populate deterministically.
- **Gotchas:** **PIN both the Distribute seed AND every Random Value seed** or the kit re-rolls each build and poisons the eye-review diff. Realize-before-export inflates tri-count fast — **for large fields prefer Godot-side MultiMesh**; Realize only for a small static baked kit, and scatter LOW-poly / decimated sources. NOT free on RAM: thousands of instances are RAM-bound on ~7.7 GB.

### Boolean — Exact/Manifold solver + GN Mesh Boolean node `[MEDIUM]`
- **What:** `BOOLEAN` modifier (operation/solver/object) or the `GeometryNodeMeshBoolean` node (cleaner headless — no second-object modifier).
- **Gotchas:** **EXACT stays the batch default;** MANIFOLD (added 4.5, present in 5.1) is an opt-in fast path **only for watertight-manifold operands with normals out.** The skill already owns boolean+mark-sharp+triangulate via bmesh — increment here is just the GN-node variant.

### Array modifier — linear + radial `[MEDIUM]`
- **What:** linear runs (fences, columns, chains, modular tiling) and radial rings (gear teeth, crystal rings) via an Empty.
- **How (radial, the guaranteed path):** `arr.use_object_offset=True; arr.offset_object=empty` where the Empty sits at the rotation **center**, rotated `360/N` on Z; `arr.use_merge_vertices=True` for watertight rings.
- **Gotchas:** a **native** circular-array property on 5.1.2 is **not confirmed** — probe `bl_rna` before using it; treat ONLY the Empty-offset path as runnable.

### Edge Crease + Subdivision — rounded forms, controllable sharps `[MEDIUM, niche]`
- **What:** a 6-face cube + creases + 2 subsurf levels = clean rounded river-stone (the named golem "rounded boulder" gap).
- **Gotchas:** **off-contract for the DEFAULT flat-shaded DP look** — subsurf gives SMOOTH-shaded rounded surfaces. Niche tool for the "rounded/eroded" family ONLY (boulders, worn altars). Crease moved to the generic `crease_edge` attribute in 4.0 — a 3.x `bm.edges.layers.crease` script writes nothing (verify via `mesh.attributes.keys()`). **Decimate after subsurf** to hit budgets; watch RAM (level 2 = 16× faces).

### Mirror modifier — build a half `[LOW — duplicative]`
- **What:** non-destructive symmetry (`use_axis`/`use_bisect_axis`/`use_clip`).
- **Note:** `bmesh.ops.symmetrize` is ALREADY in the skill and gives byte-exact headless symmetry; in a scripted generator you place verts in code anyway. Net-new = "keep live, asymmetrize later" for the DP "one asymmetric break." Mirrors across **object origin**, not world — set origin to the symmetry plane first.

### GN seeded VARIATION — one graph, N variants `[MEDIUM]`
- **What:** Random Value + instance-ID seed + Collection part-swap → many rock/crystal/mechanical golem reskins, mimic floor-keyed variants, prop break-states.
- **Gotchas:** **hard-surface families ONLY** (the skill bans organic/blob procedural variation). Vary **SEED across exports, ID across instances** (same ID+seed = same value). Clamp ranges to the style envelope (bottom-weighted silhouette, one asymmetric break) or you get off-model noise. Payoff is leverage-on-volume — author cost is real.

### GN PARAMETRIC props — input-driven kit pieces `[MEDIUM]`
- **What:** the whole fence/stair/pillar as an input-driven graph — "author logic once, stamp any size" for a GridMap kit.
- **Gotchas:** highest authoring cost, least immediate payoff for a single-map demo — **for "scenarios fast" NOW, Array + Scatter get most of the kit with far less graph complexity.** GN inputs are addressed by **socket identifier** (`mod['Socket_N']`) — **look it up from the node-group interface, don't hardcode the index.** Bake pivot discipline (wall pivot bottom-center, 1.0 BU = 1 m) into the graph output or GridMap snapping breaks.

### Decimate — game-ready LOD `[MEDIUM]`
- **What:** batch LOD0..LOD3 (`PLANAR`/`COLLAPSE`/`UNSUBDIV`) + vertex-group region-protect (`m.vertex_group` + `m.invert_vertex_group`).
- **Gotchas:** **NEVER COLLAPSE a deforming/skinned mesh** (canon). COLLAPSE destroys UVs/edge-flow → decimate **AFTER** UV/material. LOD chains are likely **premature for the 1-map demo** — polish/scale-out tool, not a near-term blocker.

---

## Accessories / Fitting — glasses, hats, armor, held tools (Joan's explicit need)

### ① The two-regime routing rule `[HIGH — decide this first]`
- **Rigid** (helmet, glasses, sword, horn) → **bone/vertex-parent** (item ②). **Deforming** (cloth, soft armor) → **weight-transfer** (item ④).
- **Load-bearing fact (confirmed):** glTF only supports armature-skin + morph targets as deformers. So **Surface/Mesh Deform CANNOT export as live deformers** — for ANYTHING entering Godot, route to weight-transfer, never Surface/Mesh Deform. The Surface-Deform branch applies ONLY to the Lawen render video.

### ② Bone / Vertex parent — pure data API `[HIGH]`
- **What:** `parent_type='BONE'`/`'VERTEX_3'`, `parent_bone`, `parent_vertices`, `matrix_parent_inverse` — all data properties, no operator, 100% headless.
- **Leverage:** the core rigid-fit primitive — zero weights, instant, swappable; Godot equivalent is `BoneAttachment3D` matching the bone NAME.
- **Gotchas:** **UniRig does NOT guarantee a fixed head-bone name** — DISCOVER the actual head bone per rig first (project ships `golem_bone_discover` tooling). Blender bone-parents to the bone **TAIL** by default — `matrix_parent_inverse` compensates, but verify seating.

### ③ Shrinkwrap-conform — fit accessory SHAPE to body `[HIGH]`
- **What:** snap an accessory's verts onto body curvature.
- **How:**
  ```python
  sw = acc.modifiers.new("conform",'SHRINKWRAP')
  sw.wrap_method='NEAREST_SURFACEPOINT'   # or TARGET_PROJECT; wrap_mode='OUTSIDE'
  sw.offset=0.006; sw.target=body; sw.vertex_group="contact"
  me = bpy.data.meshes.new_from_object(acc.evaluated_get(dg),
           preserve_all_data_layers=True, depsgraph=dg)   # ← REQUIRED if you reuse the vgroup/UVs after bake
  ```
- **Gotchas:** geometry-only bake is fine, but **add `preserve_all_data_layers=True`** if you rely on the contact vgroup/UVs afterward (T64794 drops them by default). NEAREST_SURFACEPOINT can suck thin parts through concave areas — use a vgroup/offset or PROJECT mode. Subdivide the accessory first for a clean conform (corpóreo proof: offset 0.006).

### ④ Data Transfer — vertex weights (auto-skin, the game-export winner) `[HIGH]`
- **What:** rig the body ONCE (UniRig), then every cloth/soft-armor piece inherits the skin by nearest-surface weight copy → it actually animates in Godot under the shared Skeleton3D.
- **How:**
  ```python
  dt = acc.modifiers.new("xfer",'DATA_TRANSFER')
  dt.object=body; dt.use_vert_data=True
  dt.data_types_verts={'VGROUP_WEIGHTS'}; dt.vert_mapping='POLYINTERP_NEAREST'
  # accessory MUST already contain matching-NAME vertex groups, then normalize after.
  me = bpy.data.meshes.new_from_object(acc.evaluated_get(dg),
           preserve_all_data_layers=True, depsgraph=dg)   # ← WITHOUT THIS THE WEIGHTS SILENTLY VANISH
  ```
- **Gotchas (load-bearing):** the depsgraph bake **MUST** pass `preserve_all_data_layers=True` — default `False` drops the transferred weights and the whole technique no-ops (T64794). Pre-create matching-NAME vgroups (names must match the rig's ACTUAL bone names — see ②). Normalize weights after (`vertex_group_normalize_all`). Keep the Armature modifier present at export with `export_skins=True` — do NOT bake the armature away. Rigid pieces are better served by ②, not this.

### ⑤ BVHTree raycast — programmatic snap-to-surface seating `[HIGH]`
- **What:** cast a ray at the body to find the exact seat point (nose bridge for glasses, shoulder for a horn) and orient to the surface normal — deterministic across a batch.
- **How:** `bvh = mathutils.bvhtree.BVHTree.FromObject(body, dg); loc, nor, idx, dist = bvh.ray_cast(origin, direction)`; orient with `nor.to_track_quat('Z','Y')`. Pure math, headless. Pairs with ② to complete the "fit on N characters" loop.
- **Gotchas:** `BVHTree.ray_cast` returns `(loc, nor, idx, dist)` but `Object.ray_cast` returns `(hit, loc, nor, idx)` — **don't unpack them the same way.** Keep world-vs-local space consistent and **restrict the anchor region before casting** (avoids the "belly out-fronts the muzzle" bug).

### ⑥ Data Transfer — custom split normals (toon seam fix) `[MEDIUM]`
- **What:** copy the body's smooth normals onto the accessory so cel banding stays continuous across the seam.
- **How:** `dt.use_loop_data=True; dt.data_types_loops={'CUSTOM_NORMAL'}`. **In 4.1+ do NOT call `use_auto_smooth=True`/`create_normals_split()` — both dead; custom normals apply automatically.** Same `preserve_all_data_layers=True` on bake. Polish, not core fit.

### ⑦ GN Instance + Sample Nearest Surface — detail scatter `[MEDIUM]`
- **What:** studs, rivets, golem plating distributed and oriented to the surface. **Transfer Attribute was removed in 3.4 → use `Sample Nearest Surface`** (present in 5.1.2). Must **Realize before glTF** (no live GN survives export). Tangential to the core "fit glasses on a face."

### ⑧ Surface / Mesh Deform bind `[LOW — render-only]`
- **What:** zero-weight follow for loose cloth the skeleton can't capture. `surfacedeform_bind` runs via `temp_override` but is **finicky** (needs show_render/viewport ON + evaluated depsgraph; `assert m.is_bound`).
- **Note:** does NOT export to glTF → zero game value, and item ④ also runs headless and IS robust + exports. Keep only as a niche **Lawen render-only** fallback.

### ⑨ Asset Library mark + link/append `[LOW — infrastructure]`
- **What:** `obj.asset_mark()` + `bpy.data.libraries.load(link=True)` build a reusable wardrobe.
- **Gotchas:** **headless previews are broken** (T93893 — `asset_generate_preview` is async, ships blank thumbnails). You get a functional catalog, not a browsable visual one. Reuse infra, not a fitting technique.

---

## bpy Batch & 5.1.2 gotchas — the cross-cutting glue

### NumPy `foreach_get/set` vectorized mesh I/O `[HIGH]`
- **What:** read/write `co`, loop data, attributes as flat numpy arrays — the biggest speedup for any geometry-touching batch (golem vertex-color jitter, bear masks, scatter).
- **How:** `arr = np.empty(len(me.vertices)*3); me.vertices.foreach_get('co', arr)` → reshape/edit → `foreach_set` → **`me.update()`**.
- **Gotchas:** after `foreach_set('co')` call `me.update()` AND recompute normals (reading `normal` returns stale cache). Vertex-group **weights cannot foreach** — use the attribute API / per-vert `.groups`. numpy IS bundled in Blender's Python.

### bmesh index-table hygiene `[HIGH]`
- **What:** `bm.verts.ensure_lookup_table()` / `index_update()` / `normal_update()` — prevents the #1 unattended-batch crash ("outdated internal index table") that no GUI is there to catch.
- **Note:** iterating is always safe; only **indexed** access needs the table. Reuse `geom` returned by `bmesh.ops` to skip re-indexing.

### Prefer `bpy.data` over `bpy.ops` in loops `[HIGH]`
- **What:** data API is deterministic and CPU-only; `temp_override` (3.2+) only when an op is forced.
- **Gotchas:** `obj.copy()` **shares** mesh data → `obj.data = obj.data.copy()` for independence. A new object is **invisible until linked into a view-layer collection.** A few true-UI ops won't run in `--background` even with override — check the headless-safe table first.

### Modifier-stack API + auto-smooth replacement `[HIGH]`
- **What:** one generator emits Array+Mirror+Solidify+Bevel families parametrically; GN node-trees built in data.
- **Gotchas:** `use_auto_smooth` removed in 4.1. Both `shade_auto_smooth` (4.2, **appends** the "Smooth by Angle" GN modifier — an Essentials asset that may NOT resolve under `--factory-startup`) and `shade_smooth_by_angle` (4.1, applies directly) exist and differ. **For headless robustness prefer the pure-data path:** mark sharp edges (`edge.use_edge_sharp`) + `me.shade_smooth()` — zero asset-library dependency. Strip the Armature modifier when depsgraph-baking a rigged mesh.

### Collection API for batch org + per-collection export `[HIGH]`
- **What:** pure data API, the fix for the #1 silent batch bug — a fresh object that "doesn't export" because it was never linked into an active-view-layer collection (absent from the depsgraph).
- **Gotchas:** `scene.objects.link` was removed in 2.8 — link to a collection. `use_selection` export depends on the active VIEW LAYER selection — set it explicitly. Use `bpy.data.objects.remove(...)` to truly free memory across a long batch.

### Godot-correct glTF export loop `[HIGH]`
- **What:** one reusable function encoding the project AXIS rule + tangent trap.
- **Gotchas:** **`export_apply=True` applies the Armature → destroys the skin on rigged meshes** — for skinned assets do NOT use it; bake non-armature modifiers via depsgraph manually, keep `export_skins=True`. **Triangulate before export** or tangents are wrong and normal maps look flat in Godot (T81746). `export_yup` defaults True (harmless to set). Only Principled-BSDF-wired textures survive — **bake ramps, never the node tree.**

### Constraints from Python (preview only) `[MEDIUM]`
- **What:** `CHILD_OF`/`COPY_TRANSFORMS` with a manual inverse-matrix (replaces GUI "Set Inverse") for in-Blender clipping checks.
- **Gotchas:** **glTF does NOT export constraints** — Blender-side pose-test only; the real game attach is `BoneAttachment3D` by bone NAME. `CHILD_OF` without the inverse matrix teleports.

### True parallel batch — multiple headless processes `[MEDIUM]`
- **What:** `bbatch` (Blender Studio) / GNU parallel / `--python-expr`; each `--factory-startup` process is isolated + deterministic.
- **Gotchas:** leverage scales with batch size (small today). **GPU steps (Cycles preview, UniRig CUDA) MUST serialize on the single GTX 1080 with Ollama closed**, or OOM. Cap `-j` to fit RAM. Pass per-asset params via argv after `--`.

### Batch preview rendering — turntable + contact-sheet `[MEDIUM]`
- **What:** render N angles → tile → O(1) eye-review in a pipeline with no live viewport.
- **Gotchas (two false premises corrected):** (1) **Pillow is NOT bundled** in blender.org Windows builds — tile with numpy array slicing or the compositor, or `ensurepip`+pip Pillow into Blender's python. (2) **EEVEE does NOT render on a TRUE headless system** (no display) — **Cycles is required there** (corpóreo SKILL line 26 is correct: "headless can't use Eevee"). EEVEE-in-background only works with a display context (Windows-native desktop or WSL2+WSLg) — confirm empirically, don't assume. Safe default for reproducible eye-review = **Cycles with pinned device + seed.**

### GN scatter → bake instances `[MEDIUM]`
- **What:** read `depsgraph.object_instances`, apply `inst.matrix_world` per instance when realizing (else all copies stack at origin). Good for golem moss/flower dressing + prairie scatter.
- **Gotchas:** **PIN every seed** or eye-review reproducibility dies. Instances aren't real geometry until baked — keep baked counts game-sane or the GLB balloons.

> **CUT (runs but no leverage for us): Drivers (`driver_add`).** glTF drops them; in a generate→bake pipeline you already hold every value in Python (`obj.scale = ctrl*1.5` is simpler + debuggable); their only real payoff (live re-authoring by flipping one number in the .blend) is the interactive-GUI convenience our headless modality deprioritizes; they fail silently on a data_path typo. Skip unless we ship interactive .blend rigs (we don't).

---

## Blender 5.1.2 API watch-outs (these break SILENTLY in `--background` — add asserts)

- **`mesh.use_auto_smooth` / `auto_smooth_angle` REMOVED in 4.1** → replaced by the "Smooth by Angle" modifier; 4.1+ always honors custom normals if present (so DON'T port `create_normals_split()`/`use_auto_smooth=True`).
- **Edge bevel weight → generic `bevel_weight_edge` attribute (4.0).** A 3.x `bm.edges.layers.bevel_weight` script writes nothing.
- **Edge crease → generic `crease_edge` attribute (4.0).** A 3.x crease-layer script writes nothing. Verify via `mesh.attributes.keys()`.
- **Principled BSDF socket renames (4.0):** `Specular`→`Specular IOR Level`, `Subsurface`→`Subsurface Weight`, `Emission`→`Emission Color` + separate `Emission Strength`. Stale names = silent no-op → blank/flat assets.
- **`new_from_object` defaults `preserve_all_data_layers=False`** → drops vgroups/custom-normals/UVs (T64794). MUST pass `=True` for the weight-transfer + custom-normal + shrinkwrap-with-vgroup recipes, or they no-op.
- **`bpy.context.scene.objects.link` REMOVED (2.8)** → link to a collection; a new object is invisible/non-exporting until linked into an active view-layer collection.
- **EEVEE engine id is `BLENDER_EEVEE` on 5.1.2** (5.0 renamed `BLENDER_EEVEE_NEXT`→`BLENDER_EEVEE`) — this is settled, drop the "verify" hedge.
- **`scene.eevee.gtao_distance` → `view_layer.eevee.ambient_occlusion_distance` (5.0).**
- **Manifold boolean solver added 4.5** (present in 5.1) — manifold/watertight-only; **EXACT stays the batch default.**
- **GN modifier inputs by socket IDENTIFIER (`Socket_N`)** — look up from the node-group interface, never hardcode the index.
- **Native circular-array property on 5.1.2 = NOT confirmed** — probe `bl_rna`, fall back to Empty + object-offset.
- **GUI/PBVH-bound ops fail headless even with `temp_override`:** sculpt brushes, mesh/cloth filters, dyntopo, `paint_mask_extract`/`paint_mask_slice`. Use the documented substitutes.
- **Pillow NOT bundled** in blender.org Windows builds; **EEVEE needs a display** — both affect the contact-sheet/preview path.

---

## What `blender-asset-smith` (+ siblings) already covers — DON'T duplicate

- **Already in `blender-asset-smith`:** the headless-ops vs needs-VIEW_3D table; depsgraph-bake escape hatch; `bmesh.ops.symmetrize` for byte-exact symmetry; boolean+mark-sharp+triangulate workflow; voxel_remesh + quadriflow (both adopted, with caveats); Decimate PLANAR-vs-COLLAPSE rule + "never collapse a skinned mesh"; seed-pinning mandate; manual-skinning/UniRig pipeline; DP_ToonGrounded contract; the runevision 503-param creature-gen study ("finished hero organic = pack/AI base"); kit-bash combinatorial sanction; pivot/scale discipline (wall pivot bottom-center, 1 BU = 1 m). → This doc EXTENDS these with the **organic base-mesh chain**, the **deform-modifier mass-brush substitute**, the **accessory-fitting loop**, and the **5.1.2 silent-break cheat-sheet** — it does not re-document them.
- **Already in `corporeo-3d`:** 2D→AI base→Blender cleanup→rig→animate→render flow; shrinkwrap-on-face-plane conform (offset 0.006, subdivide-first); voxel_remesh fusing glasses+head; outfit-family lesson; **Cycles-headless / no-EEVEE** rule (line 26 — authoritative). → Reconcile the internal inconsistency (line 91's "EEVEE bear render" vs line 26) when next editing that skill.
- **Already in `motion-designer`:** `BoneAttachment3D` equivalence + exporter-bug notes.
- **Already in `art-ref-critic`:** the render-vs-target visual-diff method the eye-review here relies on.
