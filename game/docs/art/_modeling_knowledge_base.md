# Modeling Knowledge Base — Blender → Godot toon game + corpóreo

> Research base (ultracode `modeling-knowledge-base`, 13 agents, ~55 official refs, 2026-07-07). What Claude must KNOW to model MANY assets of different forms — structures, mechanisms, natural mobs, sci-fi, RPG loot, clothing, accessories, environments — for the stylized game AND the corpóreo mascot (office / grow-room scenes). Filter: anticipate the whole pipeline, don't grind per-model.

> **This file is the SINGLE SOURCE OF TRUTH for modeling knowledge.** The skills [[blender-asset-smith]] (hard-surface) and [[corporeo-3d]] (organic) are THIN routers that point here — the knowledge lives here once, cross-linked, so activating any one concept pulls in its neighbors instead of firing in isolation. Retrieval architecture = **knowledge unified + linked, activation fragmented**: one lookup into this linked doc, never N lookups stitched across disconnected skills. The concepts form ONE web — every per-category cheat-sheet leans on the four foundations (Topology · Rigging · Shading · Pipeline) and on the two cross-cutting gates (pre-export validation · silhouette/eye-review) and the automate-vs-interactive division. Read the foundation a category depends on, not just the category.

## The one mental model

Every game/mascot asset is judged on **four coupled properties**: how it **DEFORMS** (topology / edge-flow), how it **SHADES** (normals / smoothing), how it **TEXTURES** (UVs / texel density), how it **PERFORMS** (poly budget / LOD). Through-line: **author in QUADS** (loops, subdiv, edge-slide behave), route loops along deformation + silhouette lines, then **triangulate on export** (the GPU only renders tris). "Good topology" = the MINIMUM mostly-quad flow that deforms + shades cleanly within budget — dense where it bends or the silhouette curves, sparse on flat panels — **not** maximum density.

**The pipeline is a one-way lossy conveyor.** Blender → glTF (.glb) → Godot re-import. glTF carries a FIXED PBR payload only: mesh, skin, morph targets, baseColor / metallic-roughness / normal / emissive / occlusion (ORM), vertex colors (COLOR_0). It does **NOT** carry toon/NPR shaders, procedural node graphs, modifier stacks, or **DRIVERS**. Anything stylized is re-authored engine-side or BAKED to texture/vertex-color first. Godot owns collision, physics, LOD (ship a clean LOD0). **Blender is Z-up, glTF/Godot are Y-up → APPLY ALL TRANSFORMS** (scale=1, rot=0, sane origin) before export — the single most common invisible bug.

**Toon inverts the PBR instinct.** A hard cel ramp ERASES normal-map micro-detail → budget goes into SILHOUETTE geometry, correct joint loops, and flat/gradient/AO-into-vertex-color texture — not sculpted pores. Exaggerate proportions (chunkier forms, ~2-3× bolder bevels) so shape + light-catch survive the small on-screen footprint. Read hierarchy: (1) big silhouette → (2) secondary forms + negative space → (3) surface trim/wear. **Validate with a flat-black thumbnail at real gameplay-camera distance BEFORE detailing.**

**Rigging reality (UniRig → per-limb GDScript).** Two layers must both be right: SKELETON (deform vs control bones) + SKINNING (per-vertex weights). Game hard-cap: **NORMALIZE + LIMIT TOTAL = 4** influences/vertex or parts explode in-engine while looking fine in Blender. Faces = hybrid jaw-BONE (cheap arcing open/close, exports everywhere) + BLENDSHAPES (lip/pucker/asymmetry). Any openable mouth needs a sealed **MOUTH-BAG** (interior island: upper teeth/palate → head bone, lower teeth/tongue/floor → jaw) or you see through the skull. **DRIVERS DO NOT EXPORT** — correctives + jaw-driven-blendshape links are lost. Shape keys FREEZE topology → finalize topology BEFORE blendshapes. Auto-weights get ~80%; joints/hems need a human pass.

**Automation reality (headless bpy).** Build with the **DATA API + bmesh, NOT bpy.ops** (operators poll for context that doesn't exist headless → flaky — this is why our `vertex_group_smooth` op failed and quadriflow bailed). Determinism: `--factory-startup`, PINNED Blender version, seeded RNG, sorted iteration, fixed modifier order. bpy initializes ONCE per process and leaks datablocks → **subprocess-per-asset isolation**. Keep a non-destructive SOURCE .blend separate from the lossy .glb.

**The load-bearing skill** is knowing which side of the automate/interactive line each task is on (see the division map below).

---

## Foundations

### Topology / UV / Normals / LODs
**Approach:** author quads, route loops along deformation + silhouette; retopo a clean low/mid mesh over any dense source (sculpt, scan, AI base); UV at consistent texel density; triangulate deliberately on export; ship LOD0, let Godot auto-LOD.
- **Tricks:** 2-3 edge loops across every joint + concentric loops around eyes/mouth · hide poles (3-/5-valence) in FLAT regions · manual retopo = shrinkwrap + quad strips + mirror, even quad sizing · seams hidden under arms/inside limbs, more UV area to deforming regions, always a non-overlapping UV2 for lightmaps · Triangulate modifier so YOU pick the diagonal · one texel-density target enforced library-wide.
- **Gotchas:** auto-retopo (Quadriflow/QuadRemesh/Instant Meshes) ignores anatomy — loops never land on joints/orifices, drifts on thin features → **characters still need manual loop routing** · glTF splits verts at UV seams + sharp edges → budget by EXPORTED tris · missing UV/tangents = broken normal maps · ngons only on flat faces · overlapping/mirrored UVs corrupt directional bakes · non-manifold/flipped/zero-area faces silently break bakes+collision — run a fixed cleanup pass.

### Rigging / Deformation
**Approach:** deform skeleton → auto-weights draft → clean joint weights → shape keys for face+correctives. Face = jaw BONE (open/close) + blendshapes (lips) + sealed mouth-bag. Scriptable except interactive brush weight-paint.
- **Tricks:** weight cleanup every export = Normalize All → Limit Total 4 → Clean → Mirror · Preserve Volume (dual quaternion) + twist bones kill candy-wrapper · correctives = pose→sculpt fix→New Shape from Mix→ROTATION_DIFF driver · jaw pivot at the ear/condyle (real arc beats a straight-line blendshape) · mouth-bag = one interior island, upper→head@1, lower→jaw@1, dark sock tube · weight a low-res proxy then Data Transfer to the hero mesh.
- **Gotchas:** **DRIVERS DON'T EXPORT** · weights >4 or un-normalized explode in-engine · shape keys freeze topology · "Bone Heat failed" = non-manifold/doubles/interior faces · unapplied scale breaks deform+driver math · re-parenting with Auto Weights RESETS hand-painted weights · no mouth-bag = see-through skull.

### Shading / Texturing
**Approach:** author PBR through Principled BSDF (exactly what survives glTF into Godot StandardMaterial3D); bake everything else (procedural nodes, Shader-to-RGB cel) to image/vertex-color first. Toon: metallic ~0, low roughness, push character into albedo + outlines; EEVEE toon = look-dev/bake tool, the runtime cel + outline are re-authored in Godot.
- **Tricks:** **palette/gradient-map** (256×1 strip driven by vertex colors) → a whole enemy/prop set shares one micro-texture — the definitive headless stylized workflow · bake AO + curvature INTO vertex colors (no UVs, no files, fully bpy) · inverted-hull outline (Solidify negative + flip normals + dark unlit + backface cull), mirror in Godot next_pass · channel-pack ORM · bake in Cycles even when look-dev is EEVEE · trim sheets + atlas collapse draw calls.
- **Gotchas:** **Non-Color colorspace** on normal/rough/metallic = #1 silent bug · Shader-to-RGB is EEVEE-only, does NOT export · vertex colors only render if material has "vertex color as albedo" (pick byte-vs-float + corner-vs-vertex convention) · bake seam bleed needs margin · inverted-hull tears at hard edges (store smooth normals) · atlas kills tiling, trim tiles one axis · texel-density mismatch = sharp-next-to-mushy.

### Pipeline / Automation
**Approach:** Blender as a scriptable geometry server — build with bpy.data+bmesh, non-destructive source .blend, bake/apply only at export, explicit glTF settings dict. Automate deterministic batch; flag judgment-bound work for a human.
- **Tricks:** data API + bmesh over bpy.ops · determinism recipe · subprocess-per-asset + build log · keep modifier stack live, bake via evaluated depsgraph · provenance stamp (source hash, version, seed, stats) + base-name tag · auto-skin = ~80% draft flagged for human joint cleanup.
- **Gotchas:** bpy leaks datablocks per process · no framebuffer headless (Cycles fine, EEVEE historically needs GL) · backface culling defaults OFF → enable per-material · non-deform bones export & break skinning · name collisions (.001) break res:// paths · decimate ≠ retopo · Godot .blend-direct import still runs the glTF exporter (all gotchas apply).

---

## Per-category cheat-sheets

### Modular structures & architecture
One base grid unit → interlocking pieces (walls/floors/corners/doors/trims) → assemble in Godot GridMap/MeshLibrary. **Tricks:** pick ONE module size, derive everything as whole multiples · rotational symmetry (one corner covers 4 orientations) · invest in connective-tissue pieces (Skyrim reused its cave kit 200+×) · one toon material + palette/atlas + vertex-color AO · post-process/screen-space outlines (not inverted-hull) on grid-heavy scenes · script grid-origin/scale/naming/export. **Gotchas:** unapplied scale = snap drift · GridMap cells are cubic (offset origins for non-cubic modules) · coplanar faces leak light (overlap or trim) · instances need UV2 for lightmaps · box collision per tile · "art fatigue" is the #1 failure — plan variety as budget.

### Hard-surface mechanisms & moving parts
Non-destructive stack: blockout → Boolean (cutters in hidden collection) → Bevel (weight/angle) → Weighted Normal → optional Subdiv held by support loops. **Tricks:** Boolean→Bevel(Harden Normals)→Weighted Normal = crisp machined edges no bake · Bevel Weight + Custom Profile for grooves · light Bevel UNDER Subdiv auto-generates holding loops · Fast solver viewport / Exact+Self-Intersection final · gears = Empties at pivots + Drivers by tooth ratio · in bpy `obj.modifiers.new(...)` bake via depsgraph. **Gotchas:** apply scale first · booleans hate coplanar/overlap/non-manifold · boolean output = ngons+poles, clean before subdiv · beveled-flat shading gradient = missing weighted normals · applying transforms moves origin · toon: real bevels + panel lines, not micro-normal detail.

### Natural mobs / creatures (bestiary)
Deformation-and-silhouette first. Design shape language → flat-black thumbnail at gameplay distance (~5-30 m) → ground in real anatomy → base-mesh → sculpt (Dyntopo explore / Multires refine) → retopo joint-topology → UV → bake → texture → UniRig → per-limb GDScript. **Never animate the sculpt.** **Tricks:** silhouette-first (name it from the black outline or nothing saves it; round=prey, angular=predator, tall=threat) · Skin modifier over an edge skeleton for the base · Dyntopo→Voxel-Remesh→Multires · model limbs slightly bent, pivots at true joints · sculpt symmetric then break it · toon bakes broad forms + AO only. **Gotchas:** **digitigrade error** (the backward hind "knee" is the ANKLE; true knee is high/tucked) · auto-retopo never gives joint loops · sim hair does NOT export → bake to cards/shells · even-tube limbs = balloon animals (taper + mass) · flat ramp erases sculpt micro-detail.

### Sci-fi hard-surface
Rigid forms that read as scaled + assembled: strong silhouette + mechanical repetition + layered greebles implying function. **Tricks:** 60/30/10 detail hierarchy with rest areas · scale via greeble DENSITY + panel SIZE · floating geometry (hero-asset bakes only) · trim-sheet + modular · procedural greebling via Geometry Nodes from a curated kit (one vocabulary) · toon: skip bake, exaggerate chamfers 2-3×, panel lines as material inset/vertex color, tight emissive + rim. **Gotchas:** apply scale before boolean/bevel/bake · ngons explode under subdiv · over-greebling destroys scale (keep negative space) · hard edge = UV seam · **normal-map detail DISAPPEARS under a hard cel shader** (bake time wasted) · kitbash incoherence (normalize greeble scale).

### RPG weapons / armor / loot
Silhouette-first at GAME scale. Flat-black shape must say "sword vs axe vs staff" in one glance. Exaggerate for toon, bake wear into gradients/AO/curvature not geometry, encode rarity on ≥2 axes (form complexity + material/color tier + emissive). Origin at the grip, aligned to the hand socket. **Tricks:** silhouette ritual (ortho + 3/4 flat-black thumbnail + gameplay distance) · curvature/cavity edge wear (chips on convex, grime in concave) · weighted-normals + small bevels catch the toon light-line · rarity in 3 stacked axes (iron→steel→gold-trim→arcane + wings/spikes up-tier) · tight emissive mask for legendary glow · atlas small props, vertex-color tint masks for rarity variants. **Gotchas:** origin at center not grip = #1 equip bug · over-detail = noise at scale · uniform wear reads as texture · mirrored UVs double baked wear · rarity by hue alone fails colorblind (pair brightness + non-color axis) · uncontrolled bloom flattens forms · thin blades alias (min width/bevel/two-sided).

### Clothing / garments
Game/toon default = hand-modeled SHELL (duplicate covered body faces, push out, hard-model big folds, deform via transferred weights or Surface-Deform). Reserve cloth-sim / Marvelous Designer for capes/skirts or a drape you stylize+freeze. **Keep the corpóreo costume pipeline SEPARATE.** **Tricks:** shell with NO thickness, Solidify only on free edges (collar/cuff/hem) · mirror body loops at joints · Data Transfer body weights → garment (then hand-fix hems) · Surface Deform binds a tabard/cape with no weights of its own · cloth-sim→pin→freeze as shape key · folds: BIG=geometry, MEDIUM=normal, MICRO=texture. **Gotchas:** poke-through #1 (offset + DELETE covered faces + correctives) · Surface Deform silently fails on bad topology · Data Transfer needs target groups to exist · scale matters for sim · Solidify self-intersects at bends · frozen drape is pose-specific · **corpóreo caveat: real thickness + seam allowances + UV-as-sewing-pattern, never the game-shell method.**

### Small accessories / gear / tools
Two attach models: RIGID (weapons/torch/tools/amulets) bone-parented → BoneAttachment3D/Marker3D, and SKINNED (capes/chains) weighted. Fix socket + naming convention, origin at contact point, align to bone axis, enlarge/chunk for readability. **Tricks:** socket-space authoring (origin at contact, forward = bone axis → zero per-prop offset) · Marker3D under BoneAttachment3D for in-editor nudge · dynamic attach via Child-Of toggle / re-parent · weighted normals + bevels for toon bands · atlas jewelry, match body texel density · merge static never-moving accessories into the mesh. **Gotchas:** **Blender bones point +Y** (a +Z prop rotates 90°) · origin at center floats off the hand · unapplied scale = shear · BoneAttachment3D shows REST pose in-editor (verify at runtime) · bone-name attach breaks after a UniRig rename (keep names stable) · real-scale props vanish (enlarge) · thin straps z-fight under outlines.

### Scene staging / set dressing / lighting (corpóreo in office / grow-room)
A hero render is 20% modeling, 80% staging: dress the set to tell who the mascot is, flattering camera, small MOTIVATED light rig (key/fill/rim + practicals), ground with contact shadows, tone-map so practicals roll off. Script the whole rig headless. **Tricks:** 3-point + key:fill ~2:1 (soft/friendly) + warm-key/cool-fill · shadow softness = light SIZE+distance (biggest "expensive" lever) · Light Linking for a face/rim light that only hits the mascot · shadow-catcher + composite onto a real photo plate · ~50-85mm, slight low angle, Focus Object on the eyes · scripted camera Track-To + lights/HDRI/color-mgmt for batchable turntables. **Gotchas:** **grow-room "blurple" trap** (cannabis LED bars = magenta/red+blue; as the only light they clip radioactive and erase the mascot's colors — mix a neutral/warm face key, pull LED saturation down, AgX rolls off) · rendering in "Standard" view transform instead of AgX/Filmic = #1 cheap-looking cause · floating feet (no contact shadow) · prop grid regularity (jitter/cluster) · import-scale sabotage (0.3 m vs 30 m lights totally differently — fix scale before lighting) · over-lighting flattens · EEVEE without probes = flat/dead · fireflies from small emitters (increase size, clamp, denoise).

---

## Process improvements to make NOW (anticipate, don't grind per-model)

1. **A single pre-export VALIDATION + CLEANUP GATE** (reusable bpy fn on EVERY asset): apply transforms · recalc normals · merge by distance · delete loose · dissolve degenerates · triangulate · `mesh.validate()` · assert UV + tangents · Limit Total 4 + Normalize · per-material backface cull · sanitize/dedup names. Kills the majority of silent in-engine breakage.
2. **Standardize the headless engine:** bpy.data+bmesh (not ops), subprocess-per-asset, locked determinism recipe. Converts one-off .glb into reproducible batch.
3. **Codify the DP_ToonGrounded style as a scriptable material/outline/vertex-color LIBRARY** (one toon material + palette lookup + baked-AO/curvature vertex color + one outline fn). Makes a whole bestiary read as ONE hand — fully headless.
4. **Fix ONE grid unit + ONE origin/socket/naming convention library-wide,** enforced in-script (grid multiples · origin-at-grip · +Y bone alignment · stable bone names · base-name tagging).
5. **Lock ONE texel-density target** (px/m) via automatic UV-island scaling across the library.
6. **Two-file discipline + provenance stamping** (non-destructive source .blend ≠ lossy .glb + sidecar log per export).
7. **Scriptable high→low BAKE harness** (UV → Cycles bake normal/AO/curvature → optionally vertex colors), with the low mesh's joint loops FLAGGED as a human checkpoint.
8. **Automated silhouette/eye-review GATE** before "done" (flat-black render at thumbnail + true gameplay distance/lighting per biome; route pass/fail to Joan). The loose-chunk golem failed exactly here.
9. **Keep the corpóreo (physical-costume) pipeline formally SEPARATE** from the game-shell pipeline.
10. **Make the reference-driven gate mechanical** (load `_references/<X>/` before building — already a CLAUDE.md rule — wired into the blender-asset-smith skill as a hard first step).

---

## Automate-by-Claude vs Interactive-by-Joan (the division map)

**Claude (automatable):** parametric/kit-bash construction · boolean/array/mirror/bevel/solidify/weighted-normal stacks · apply transforms + set origin + axis-align · UV unwrap + island packing · high→low normal/AO/curvature bake · **AO/curvature into vertex colors + palette/gradient texturing** (the headless stylized workflow) · toon material + outline application · decimation/LOD1-2 · atlas + trim-UV snapping · glTF export + naming/provenance · pre-export validation gate · marketing-render staging (camera/lights/HDRI/color-mgmt/A-B/turntables) · socket/bone-attachment given the convention.

**Hybrid (Claude drafts → Joan finalizes):** UniRig auto-rig + auto-weights (~80% → Joan cleans joints) · clean edge-loop RETOPO for deformation (Claude auto-retopo → Joan fixes joint loops) · facial correctives (Joan sculpts the shape → Claude scripts the driver — remember drivers don't export) · Marvelous-Designer drape (Joan drapes/directs → Claude bakes + weight-transfers).

**Joan (interactive — do NOT script blind):** sculpted surface detail + final silhouette/shape-language approval (the "does it READ / FEEL right" eye-review) · rarity visual-language + creature shape-language design · hand-painted texture (design around vertex colors/palette/baked-AO when headless) · corpóreo panel flattening + seam allowances.

> **This is the lesson from the Filomeno mouth marathon:** crisp edge-loop retopo + art-directed delineation are Joan's side of the line. Claude thrashing blind on them (quadriflow bails headless, per-face paint speckles) is the anti-pattern. Encode the line INTO the tools, not into memory.

---

## Master reference library (official / backed)

**Foundations — mesh/topology/UV/normals**
- Blender Manual — Modeling ▸ Meshes · https://docs.blender.org/manual/en/latest/modeling/meshes/index.html
- Blender Manual — UV Unwrapping · https://docs.blender.org/manual/en/latest/modeling/meshes/uv/unwrapping/index.html
- Blender Manual — Retopology & Remeshing · https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html
- Polycount Wiki — Topology · http://wiki.polycount.com/wiki/Topology
- Polycount Wiki — Texel · http://wiki.polycount.com/wiki/Texel
- QuadriFlow paper (SGP 2018) — why auto-retopo drifts · https://github.com/hjwdzh/QuadriFlow

**Rigging / deformation**
- Blender Manual — Skinning (Armatures) · https://docs.blender.org/manual/en/latest/animation/armatures/skinning/index.html
- Blender Manual — Shape Keys · https://docs.blender.org/manual/en/latest/animation/shape_keys/index.html
- Blender Manual — Drivers · https://docs.blender.org/manual/en/latest/animation/drivers/index.html
- Blender Studio — Advanced Facial Rigging (Storm) · https://studio.blender.org/training/facial-rigging/
- Polycount Wiki — Face Topology · http://wiki.polycount.com/wiki/FaceTopology

**Shading / texturing**
- Blender Manual — Principled BSDF · https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html
- Blender Manual — Render Baking (Cycles) · https://docs.blender.org/manual/en/latest/render/cycles/baking.html
- Polycount Wiki — Texture Baking · http://wiki.polycount.com/wiki/Texture_Baking
- Polycount Wiki — Normal Map Modeling · http://wiki.polycount.com/wiki/Normal_Map_Modeling
- GuiltyGear Xrd Art Style (GDC Vault) · https://www.gdcvault.com/play/1022031/GuiltyGearXrd-s-Art-Style-The
- Illustrative Rendering in TF2 (NPAR '07, Valve) · https://dl.acm.org/doi/10.1145/1274871.1274883
- Substance 3D Painter — Smart Materials/Masks · https://helpx.adobe.com/substance-3d-painter/features/smart-materials-and-masks.html
- The Ultimate Trim — Sunset Overdrive (GDC Vault) · https://www.gdcvault.com/play/1022324/The-Ultimate-Trim-Texturing-Techniques

**Pipeline / automation**
- Godot Docs — Exporting 3D scenes (Blender→glTF) · https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/exporting_3d_scenes.html
- Blender Manual — glTF 2.0 Import/Export · https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html
- Blender Python API — Quickstart (headless) · https://docs.blender.org/api/current/info_quickstart.html
- Blender Studio — Pipeline Overview · https://studio.blender.org/tools/pipeline-overview/introduction
- Godot Docs — Mesh LOD · https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html

**Hard-surface / mechanisms / sci-fi**
- Blender Manual — Bevel · https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/bevel.html
- Blender Manual — Boolean · https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/booleans.html
- Blender Manual — Subdivision Surface · https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/subdivision_surface.html
- Blender Manual — Weighted Normal · https://docs.blender.org/manual/en/latest/modeling/modifiers/normals/weighted_normal.html
- Polycount Wiki — Subdivision Surface Modeling · http://wiki.polycount.com/wiki/Subdivision_Surface_Modeling
- Blender API — BooleanModifier · https://docs.blender.org/api/current/bpy.types.BooleanModifier.html

**Modular structures**
- Blender Manual — Snapping · https://docs.blender.org/manual/en/latest/editors/3dview/controls/snapping.html
- Godot Docs — Using GridMaps · https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
- Polycount Wiki — Modular Environments · http://wiki.polycount.com/wiki/Modular_environments
- GDC 2016 — Modular Level Design of Fallout 4 · https://media.gdcvault.com/gdc2016/Presentations/Burgess_Joel_Modular%20Level%20Design.pdf
- The Level Design Book — Modular Kit metrics · https://book.leveldesignbook.com/process/blockout/metrics/modular

**Creatures / stylized character / fur**
- Blender Manual — Sculpting: Dyntopo vs Multires · https://docs.blender.org/manual/en/latest/sculpt_paint/sculpting/introduction/adaptive.html
- Blender Studio — Stylized Character Workflow · https://studio.blender.org/training/stylized-character-workflow/
- GDC Masterclass — Creating Iconic Creatures (Jonah Lobe) · https://gdconf.com/masterclass/creating-iconic-creatures
- Blender Manual — Curves Sculpting (Hair) · https://docs.blender.org/manual/en/latest/sculpt_paint/curves_sculpting/introduction.html

**Weapons / armor / clothing**
- Blender Studio — Game Asset Creation · https://studio.blender.org/training/game-asset-creation/
- Blender Manual — Cloth Simulation · https://docs.blender.org/manual/en/latest/physics/cloth/index.html
- Blender Manual — Surface Deform · https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/surface_deform.html
- Blender Manual — Data Transfer · https://docs.blender.org/manual/en/latest/modeling/modifiers/modify/data_transfer.html
- Marvelous Designer — Official Manual · https://support.marvelousdesigner.com/hc/en-us/categories/51985515993625-Manual

**Accessories / attach**
- Blender Manual — Parenting (Bone) · https://docs.blender.org/manual/en/latest/scene_layout/object/editing/parent.html
- Blender Manual — Child Of Constraint · https://docs.blender.org/manual/en/latest/animation/constraints/relationship/child_of.html
- Godot — BoneAttachment3D · https://docs.godotengine.org/en/stable/classes/class_boneattachment3d.html

**Scene staging / lighting**
- Blender Studio — Blender Fundamentals 4.5 LTS · https://studio.blender.org/training/blender-fundamentals-45-lts/
- Blender Manual — Light Objects · https://docs.blender.org/manual/en/latest/render/lights/light_object.html
- Blender Studio — Sprite Fright Master Class: Lighting · https://studio.blender.org/blog/Sprite-Fright-Master-Class-Lighting-Rendering/
- Polycount Wiki — Concept Fundamentals (composition) · http://wiki.polycount.com/wiki/Concept_Fundamentals
- Godot Docs — Environment & Post-Processing · https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
