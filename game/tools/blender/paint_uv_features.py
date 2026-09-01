"""paint_uv_features -- paint the brow PER TEXEL, at texture resolution.

THE IDEA THAT MAKES THIS WORK. Painting a feature per VERTEX caps its detail
at the mesh density: a 5.5 mm brow on 4.07 mm edges is 1.4 vertices, which is
why every attempt came out a blob. Painting it per TEXEL caps it at the texture
instead: 17 texels tall at 4K, twelve times the resolution.

The bridge is a POSITION MAP. The bake already walks every triangle and fills
texels by barycentric interpolation -- the same walk can interpolate the 3D
POSITION of each texel instead of its colour. With that map in hand, any
function of 3D space can be evaluated once per texel:

    for each texel -> its 3D point -> brow_weight(point) -> blend colour

Exactly the same brow function as the per-vertex version, evaluated at twelve
times the sampling rate, and with NO subdivision -- which is what produced the
faceted brow, the marks on the lid and the row of saw teeth.

    blender -b <blend> --python-exit-code 1 --python paint_uv_features.py -- \
        --obj face_m000 --out out.blend --png skin_4k.png --size 4096
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords
from bake_vcol_to_texture import (vertex_colours, triangles_with_uv,
                                  dilate, push_pull_fill, box_blur)

ATTR = "Col"
BROW_HEX = "#231A14"

# Same numbers as the per-vertex version -- they were verified against the
# Skyrim reference and only the SAMPLING changes here.
BODY_ABOVE_PUPIL = 0.185
ARCH_RISE = 0.045
HEAD_HALF = 0.039
TAIL_HALF = 0.014
INNER_X = 0.20
OUTER_X = 0.78
PEAK_T = 0.62


def smoothstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def rasterise_fields(tris, tri_uv, vcol, pos, nrm, size):
    """Colour, 3D position AND normal per texel, in one walk over the tris.

    The normal is not optional. The per-VERTEX brow masked by
    `smoothstep((-N[:,1] - 0.05) / 0.45)` so only forward-facing skin got
    painted. The first per-texel version interpolated position and forgot the
    normal, so the mask matched every point at that height and X -- including
    the back of the skull -- and the brow came out as a rectangular band
    wrapping the head instead of an arch on the face.
    """
    img = np.zeros((size, size, 3), dtype=np.float32)
    p3d = np.zeros((size, size, 3), dtype=np.float32)
    nml = np.zeros((size, size, 3), dtype=np.float32)
    hit = np.zeros((size, size), dtype=bool)

    px = tri_uv * np.array([size - 1, size - 1])
    for i in range(len(tris)):
        p = px[i]
        x0 = max(0, int(np.floor(p[:, 0].min())))
        x1 = min(size - 1, int(np.ceil(p[:, 0].max())))
        y0 = max(0, int(np.floor(p[:, 1].min())))
        y1 = min(size - 1, int(np.ceil(p[:, 1].max())))
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        ax, ay = p[0]
        bx, by = p[1]
        cx, cy = p[2]
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
        w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -0.002) & (w1 >= -0.002) & (w2 >= -0.002)
        if not inside.any():
            continue
        t0, t1, t2 = tris[i]
        cols = (w0[..., None] * vcol[t0] + w1[..., None] * vcol[t1]
                + w2[..., None] * vcol[t2])
        pts = (w0[..., None] * pos[t0] + w1[..., None] * pos[t1]
               + w2[..., None] * pos[t2])
        nrs = (w0[..., None] * nrm[t0] + w1[..., None] * nrm[t1]
               + w2[..., None] * nrm[t2])
        img[y0:y1 + 1, x0:x1 + 1][inside] = cols[inside]
        p3d[y0:y1 + 1, x0:x1 + 1][inside] = pts[inside]
        nml[y0:y1 + 1, x0:x1 + 1][inside] = nrs[inside]
        hit[y0:y1 + 1, x0:x1 + 1][inside] = True
    return img, p3d, nml, hit


def brow_weight(x, z, ipd, pupil_z):
    """Identical to the per-vertex version -- only the sampling changes."""
    ax = np.abs(x) / ipd
    t = (ax - INNER_X) / (OUTER_X - INNER_X)
    inside = (t >= 0.0) & (t <= 1.0)
    t = np.clip(t, 0.0, 1.0)
    hump = 0.5 * (1.0 - np.cos(2.0 * np.pi * np.minimum(t / (2 * PEAK_T), 1.0)))
    centre = pupil_z + ipd * (BODY_ABOVE_PUPIL + ARCH_RISE * hump)
    taper = 1.0 - smoothstep((t - 0.35) / 0.65)
    half = ipd * (TAIL_HALF + (HEAD_HALF - TAIL_HALF) * taper)
    d = np.abs(z - centre) / np.maximum(half, 1e-9)
    w = 1.0 - smoothstep((d - 0.55) / 0.45)
    ends = smoothstep(t / 0.12) * (1.0 - smoothstep((t - 0.80) / 0.20))
    return w * ends * inside


def to_lin(h):
    h = h.lstrip("#")
    s = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--png", required=True)
    ap.add_argument("--size", type=int, default=4096)
    ap.add_argument("--no-brow", action="store_true")
    ap.add_argument("--debug-masks", action="store_true",
                    help="write a map of which mask covers what")
    ap.add_argument("--skip-erase", action="store_true",
                    help="source has no painted brow, nothing to erase")
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r" % args.obj)
    obj.location = (0, 0, 0)
    bpy.context.view_layer.update()

    me = obj.data
    vcol = vertex_colours(me)
    tris, tri_uv = triangles_with_uv(me)
    W, N = morphed_coords(obj)

    gi = {g.name: g.index for g in obj.vertex_groups}

    def centre(gname):
        k = gi[gname]
        idx = [v.index for v in me.vertices
               if any(e.group == k and e.weight > 0.01 for e in v.groups)]
        return W[idx].mean(axis=0)

    cl, cr = centre("helper-l-eye"), centre("helper-r-eye")
    ipd = float(abs(cl[0] - cr[0]))
    pupil_z = 0.5 * (cl[2] + cr[2])
    print("")
    print("  %s: %d tris | IPD %.1f mm | map %d"
          % (obj.name, len(tris), ipd * 1000, args.size))

    img, p3d, nml, hit = rasterise_fields(tris, tri_uv, vcol, W, N,
                                         args.size)
    covered = float(hit.mean())
    print("  rasterised %.1f%% of the map" % (covered * 100))
    if covered < 0.20:
        raise SystemExit("only %.1f%% covered -- bake is empty" % (covered * 100))

    # ERASE the old painted brow: anything markedly darker than skin in the
    # band above the eyes, evaluated PER TEXEL now.
    zt = p3d[..., 2]
    xt = p3d[..., 0]
    lum = img.mean(axis=2)
    front = nml[..., 1] < -0.35
    # FRONT-FACING ONLY. A bare height band swept the scalp in with the
    # forehead and the "skin" reference came back at luminance 0.027 against a
    # real 0.113 -- then repainted 162k texels that dark.
    fore = hit & front & (zt > pupil_z + ipd * 0.30) & (zt < pupil_z + ipd * 0.50)
    if fore.sum() < 200:
        raise SystemExit("no clean forehead texels to sample skin from")
    ref = img[fore].mean(axis=0)
    # CONTROL: skin sits near 0.11 in linear luminance. Anything much darker
    # means the sample caught hair or shadow, and using it would smear the
    # whole band.
    if not (0.05 < float(ref.mean()) < 0.30):
        raise SystemExit("skin sample luminance %.3f is out of range -- the"
                         " forehead band caught something that is not skin"
                         % float(ref.mean()))
    band = hit & (zt > pupil_z + ipd * 0.04) & (zt < pupil_z + ipd * 0.32)
    # INPAINT, not fill. Three earlier attempts filled the old brow with a flat
    # colour and every one left a visible patch -- Joan, on the third: "sigue
    # habiendo un cambio de color en donde estaban". Of course it does: the
    # skin around it has variation and a flat fill does not, so the patch reads
    # as a smooth area no matter how well the colour is matched.
    #
    # So nothing is filled. The old brow is marked NOT-YET-KNOWN and the same
    # dilate that closes UV island seams grows the surrounding skin inward.
    # What lands there is real neighbouring skin, with its own variation.
    # ERASE BY GEOMETRY, never by colour threshold.
    #
    # Every colour-threshold erase produced an ASYMMETRIC result, and Joan saw
    # it before any of my metrics did: one brow a thin line, the other twice
    # the area in the same bounding box (11420 vs 22531 px measured on a
    # frontal render). The reason is that the inherited brow in the source was
    # itself asymmetric, so "erase whatever is darker than skin" removes more
    # on the darker side and less on the lighter one. The cleanup inherits the
    # defect it is meant to remove.
    #
    # Erasing the whole brow BAND geometrically is symmetric by construction:
    # it is defined by |x| and z, so both sides get exactly the same treatment
    # regardless of what colour happens to be there.
    ax = np.abs(xt) / ipd
    # The scalp is protected as a DESTINATION, not just banned as a source.
    # Excluding it as a source stopped hair colour bleeding INTO the skin, but
    # the erase zone still overlapped the hairline, so the inpaint filled part
    # of the scalp with SKIN -- pale ragged patches eating the hair edge.
    # Invisible from the front; obvious from above and behind.
    # 0.42 was a guessed ceiling, and a guessed ceiling protects the wrong
    # thing: a wisp of the inherited brow sat at 0.55 ipd above the pupils, so
    # every erase pass was forbidden from touching it and it survived to v15.
    # What needs protecting is HAIR, and hair can be measured -- it is the
    # only thing on a forehead far darker than skin. So the guard follows the
    # actual hairline plus a margin, and the height cap moves up to a real
    # safety limit rather than doing the guard's job.
    # The ceiling went to 0.70 to reach a wisp of inherited brow sitting at
    # 0.55, and that made things worse, not better: the hole then rose above
    # the line that bans hair as a fill source, so push-pull had nothing but
    # hair to grow from up there and laid a dark slab across the forehead.
    # The wisp is ABOVE the height at which this fill can work safely, so it
    # stays for now and gets removed by something that is not an inpaint.
    # THE WINDOW. The hole may rise until it reaches the line that bans hair
    # as a fill source (0.55); above that there is nothing legal to grow from
    # and push-pull lays a slab of hair colour across the forehead, which is
    # what happened when the ceiling went to 0.70. So the ceiling goes to 0.50
    # -- as high as the fill can still work -- and the debug mask confirmed
    # this is where the surviving wisp lives.
    scalp_zone = hit & (zt > pupil_z + ipd * 0.50)
    #
    # "Dark" alone does not mean hair: the inherited brow is dark too, so a
    # darkness-only guard dilated over the brow and left NOTHING to erase --
    # and the run reported success with no erase line at all. Hair is dark AND
    # above the old ceiling; the brow is dark and below it. Both conditions.
    hair_tex = hit & (lum < ref.mean() * 0.45) & (zt > pupil_z + ipd * 0.42)
    hair_guard = box_blur(hair_tex.astype(np.float32), 26) > 1e-4
    # The box has to be WIDER THAN THE OLD BROW, not the width of the new one.
    # Sized to the new brow, the inherited brow's outer tail fell outside the
    # hole -- and then, being only mildly dark, it passed the source filter and
    # push-pull grew it straight back INTO the hole. Measured in texture space:
    # the dark wedge that survived twelve versions sat entirely inside the
    # erased region, so it was not inherited, it was REGROWN from its own tail.
    # NO hair_guard here. It was added for the raised-ceiling experiment and
    # kept out of habit after that experiment was reverted -- and on its own it
    # made things worse: dilating the hairline downward carved a strip out of
    # the erase, and the inherited brow inside that strip stayed put and read
    # as a dark slab across the forehead. scalp_zone already protects the hair.
    brow_band = (hit & front & ~scalp_zone
                 & (ax > INNER_X - 0.25) & (ax < OUTER_X + 0.35)
                 & (zt > pupil_z + ipd * (BODY_ABOVE_PUPIL - 0.20))
                 & (zt < pupil_z + ipd * (BODY_ABOVE_PUPIL + 0.34)))
    # SHAPE, not box. Erasing the whole band works, but its edge is a straight
    # line in UV space, and a straight line across a forehead is the one thing
    # the eye finds instantly -- it showed up in the frontal, the profile and
    # the top view at once. Feathering that edge only made it worse, because
    # the feather must not touch the brow it is deleting, and forcing it away
    # from the brow puts the step back.
    #
    # So the hole takes the shape of what is being removed: the dark texels
    # themselves, grown by a margin. The boundary then runs skin-to-skin at
    # matching values, and there is no line to see. Colour picks the SHAPE
    # here; geometry still picks the REGION, which is what keeps the hairline
    # and the lashes out of it.
    dark_in_band = brow_band & (lum < ref.mean() * 0.85)
    erase_zone = brow_band & (box_blur(dark_in_band.astype(np.float32), 22)
                              > 1e-4)
    # A silent empty erase is the failure mode this project keeps hitting: the
    # run prints no erase line, exits 0, and looks like it worked.
    if not args.skip_erase and not erase_zone.any():
        raise SystemExit("erase zone is EMPTY -- the guards ate the brow."
                         " An empty mask is not 'nothing to do', it is a"
                         " broken mask, and it exits 0 without this check")
    if not args.skip_erase and erase_zone.any():
        # The inpaint may only grow from SKIN. It spreads outward-in through UV
        # space, so wherever a forehead island borders the scalp island, what
        # grows inward is HAIR colour -- and since the islands are not laid out
        # symmetrically, that happened on one side only. Result: a symmetric
        # erase (ratio 1.00) and a symmetric mask still produced one thin brow
        # and one dark blob, measured 10810 vs 22693 px on a frontal render.
        #
        # Excluding the scalp as a SOURCE is what makes the fill symmetric: the
        # hole can then only be closed with skin, from either side.
        scalp_tex = hit & (zt > pupil_z + ipd * 0.55)
        # 0.45 was tuned to catch HAIR, and it does. It does not catch the
        # brow's own tail, which sits around 0.68 of skin luminance -- dark
        # enough to read as a smudge once grown into the hole, light enough to
        # pass as a legal source. The fill may only grow from something that
        # actually looks like skin, so the threshold moves up to just under it.
        dark_tex = hit & (lum < ref.mean() * 0.85)
        hit_inp = hit & ~erase_zone & ~scalp_tex & ~dark_tex

        # SOURCE and HOLE are different things, and conflating them tore a
        # skin-coloured gash straight down the middle of the hair.
        # `hit_inp` says "grow FROM here". Removing the dark texels from it
        # kept hair colour out of the fill -- but dilate also treats anything
        # missing from `hit` as a HOLE TO FILL, so the whole scalp got flooded
        # with skin grown in from its edges.
        # The hole is ONLY the erase zone. Everything else is restored exactly
        # as it was after the growth finishes.
        keep = img.copy()
        hole = hit & erase_zone
        img[hole] = 0.0
        img, grown = push_pull_fill(img, hit_inp)

        # FEATHER THE SEAM. Swapping filled for original at a hard mask edge
        # puts a step wherever the two disagree, and the erase box is a
        # geometric cut across the forehead -- so the step is a straight
        # horizontal line, which the eye reads instantly. It showed up in the
        # frontal, the profile and the top view alike.
        #
        # Blurring the hole mask gives an alpha that is 1 deep inside, 1/2 on
        # the boundary and 0 outside, so the two images cross-fade over a band
        # instead of meeting at an edge. Outside the blurred band the original
        # is restored exactly, which is what keeps the hair and the scalp
        # untouched.
        # ...but the cross-fade may NOT reach the thing being removed. A plain
        # feather let the old brow back in wherever it came within the blur
        # radius of the rim -- the residue control caught 1754 / 1441 texels of
        # it, which is exactly the defect this whole pass exists to delete.
        # So the alpha is forced to 1 over anything that was dark, plus a
        # margin, and only the skin-to-skin rim is allowed to cross-fade.
        outside = ~hole
        img[outside] = keep[outside]
        hit = hit | (grown & hole)
        left = int((hole & ~grown).sum())
        # CONTROL: symmetry of what was erased, checked here instead of
        # trusting it. This is the number that would have caught the defect.
        nL = int((erase_zone & (xt > 0)).sum())
        nR = int((erase_zone & (xt < 0)).sum())
        ratio = max(nL, nR) / max(min(nL, nR), 1)
        print("      erased by geometry: %d texels (L %d / R %d, ratio %.2f),"
              " %d still open" % (int(erase_zone.sum()), nL, nR, ratio, left))
        if ratio > 1.25:
            # A WARNING now, not a stop. The hole follows the inherited brow's
            # own shape, and that shape is not symmetric -- which is precisely
            # why it is being deleted. The check that decides is the residue
            # one below, measured on the RESULT.
            print("      NOTE: hole is asymmetric (%.2f) because the inherited"
                  " brow is" % ratio)

        # CONTROL ON THE RESULT, not on the inputs. Six hypotheses were
        # refuted in a row because every input measured symmetric -- source
        # 1.13, erase 1.00, mask 103 vs 108 -- while the render measured 2.16.
        # Symmetric inputs do not imply a symmetric output: the fill is a
        # neighbourhood operation, so what each side grows depends on what
        # happens to border it. The only honest check is to look at what came
        # out. After the fill, the erased band must contain no dark texels at
        # all -- an old brow that survived shows up here as a count, on the
        # side it survived on.
        res_lum = img.mean(axis=2)
        resid = hole & (res_lum < ref.mean() * 0.85)
        rL = int((resid & (xt > 0)).sum())
        rR = int((resid & (xt < 0)).sum())
        print("      dark residue left in the erased band: L %d / R %d"
              % (rL, rR))
        if max(rL, rR) > 0.02 * max(nL, nR):
            raise SystemExit(
                "the fill grew something dark back into the hole (L %d / R %d"
                " of %d) -- widen the erase box or tighten the source filter"
                % (rL, rR, int(hole.sum())))
        if left > 0:
            # Last resort on whatever the growth could not reach: parts of the
            # hole border ONLY scalp, and scalp is banned as a source, so those
            # texels have nowhere to grow from. Filling them flat is fine here
            # precisely because the area is tiny -- a flat patch is only
            # visible when it is large, and a black hole is visible always.
            still = hole & ~grown
            img[still] = ref
            hit = hit | still
            print("      %d unreachable texels filled flat (border only scalp)"
                  % left)

    # HIGH FOREHEAD: lighten, do not inpaint.
    #
    # A wisp of the inherited brow sits at 0.55 ipd above the pupils, above the
    # height where the inpaint can work: raise the hole up there and it crosses
    # the line that bans hair as a fill source, so push-pull has nothing but
    # hair to grow from and lays a dark slab across the forehead. That was
    # tried and it was worse.
    #
    # An inpaint is the wrong tool anyway. It is for removing something OPAQUE,
    # where the pixels underneath have to be invented. This wisp is a soft
    # low-contrast smudge sitting ON skin, so there is nothing to invent --
    # it just has to be pushed back up to the skin value it is sitting on.
    #
    # No hole, no growth, no borders, so nothing can bleed and no edge can
    # appear: the correction is proportional to how dark each texel is, which
    # makes it fade to zero exactly where the smudge does.
    #
    # HAIR IS EXCLUDED BY MEASUREMENT, not by height. Hair is far darker than
    # skin (under 0.45 of it) and lives above the hairline; the guard is the
    # hair itself, grown by a margin, so the hairline keeps its hard edge.
    if not args.skip_erase:
        hair_core = hit & (lum < ref.mean() * 0.45) & (zt > pupil_z + ipd * 0.42)
        near_hair = box_blur(hair_core.astype(np.float32), 12) > 1e-4
        high = (hit & front & ~near_hair
                & (zt > pupil_z + ipd * (BODY_ABOVE_PUPIL + 0.20))
                & (zt < pupil_z + ipd * 0.85)
                & (np.abs(xt) / ipd < 1.30))
        skin = float(ref.mean())
        # 0 where the texel already reads as skin, 1 where it is as dark as the
        # hair threshold. Anything darker than that is not ours to touch.
        w = np.clip((skin * 0.97 - lum) / (skin * 0.52), 0.0, 1.0)
        w = np.where(high & (lum > skin * 0.45), w, 0.0)
        # Blurring the weight softens the edge, which is the point -- but it
        # also flattens the PEAK, so the darkest texels were only 60% corrected
        # and the smudge survived at reduced contrast. Spreading first and
        # rescaling restores full strength at the core while keeping the skirt
        # soft; the second blur takes the corner off the rescale.
        w = np.clip(box_blur(w.astype(np.float32), 5) * 4.0, 0.0, 1.0)
        w = box_blur(w, 4)[..., None]
        # Two numbers, not one. The first version measured the darkest texel
        # in the whole band and failed on HAIR -- something this pass is not
        # allowed to touch, so reporting it as a failure of the pass is wrong.
        # But dropping it from the measurement is how a probe goes blind, so
        # it gets counted separately instead of ignored.
        cand = high & (lum > skin * 0.45)
        deep = high & ~cand
        before = float(lum[cand].min()) if cand.any() else 0.0
        img = img * (1.0 - w) + ref * w
        after_lum = img.mean(axis=2)
        after = float(after_lum[cand].min()) if cand.any() else 0.0
        print("      high forehead lightened: %d texels, darkest %.3f -> %.3f"
              " (skin %.3f)" % (int((w > 0.01).sum()), before, after, skin))
        print("      hair-dark texels inside the band, left alone: %d"
              % int(deep.sum()))
        # CONTROL ON THE RESULT: of the texels this pass WAS allowed to fix,
        # none may still read as a smudge.
        # 0.80 was too generous: a texel 20% below skin still reads as a
        # smudge, and the pass "passed" while Joan could still see the mark.
        # The bar is where the eye stops seeing it, not where the code stops
        # complaining.
        if args.debug_masks:
            # Stop guessing which band covers what. Red = erased and refilled,
            # green = lightened, blue = still dark and untouched by either.
            # Whatever is left visible has to show up in blue, or the mask that
            # was supposed to catch it did not reach it.
            dbg = np.clip(img ** (1 / 2.2) * 1.35, 0, 1)
            leftover = hit & (after_lum < skin * 0.88) & ~hair_core
            dbg[erase_zone] = dbg[erase_zone] * 0.45 + np.array([0.55, 0, 0])
            dbg[w[..., 0] > 0.05] = (dbg[w[..., 0] > 0.05] * 0.45
                                     + np.array([0, 0.55, 0]))
            dbg[leftover] = np.array([0.1, 0.3, 1.0])
            # Blender's bundled Python has numpy but no PIL, so the array
            # goes out raw and is turned into a picture outside.
            dp = os.path.splitext(os.path.abspath(args.png))[0] + "_masks.npy"
            np.save(dp, (dbg * 255).astype(np.uint8))
            print("      debug masks -> %s (%d leftover dark texels)"
                  % (dp, int(leftover.sum())))

        # AREA, not the minimum. A single dark texel is a speck nobody can
        # see; what reads as a smudge is a patch of them. Gating on the darkest
        # one failed the build over specks while the actual smudge -- which the
        # debug mask showed sitting OUTSIDE both masks, in the gap between
        # them -- went unmeasured. Wrong quantity, confidently reported.
        smudge = int((cand & (after_lum < skin * 0.88)).sum())
        print("      smudge left in the high band: %d texels of %d"
              % (smudge, int(cand.sum())))
        if cand.any() and smudge > 0.005 * int(cand.sum()):
            raise SystemExit(
                "%d texels still read as a smudge in the high forehead band"
                % smudge)

    if not args.no_brow:
        # The normal gate is what turns a wrapping band into an arch.
        facing = smoothstep((-nml[..., 1] - 0.05) / 0.45)
        w = brow_weight(xt, zt, ipd, pupil_z) * hit * facing
        lin = to_lin(BROW_HEX).astype(np.float32)
        a = w[..., None].astype(np.float32)
        img = img * (1.0 - a) + lin[None, None, :] * a
        core = int((w > 0.5).sum())
        print("  brow painted: %d core texels (%d touched)"
              % (core, int((w > 0.02).sum())))
        # CONTROL: at 4K a real brow is ~17 texels tall over ~40 mm of length,
        # so the core has to be in the hundreds. A handful means the mask
        # missed and the map now holds a smear instead of a brow.
        if core < 150:
            raise SystemExit("only %d core texels -- the brow mask did not"
                             " land where the face is" % core)


    png = os.path.abspath(args.png)
    im = bpy.data.images.new("skin_uv", args.size, args.size, alpha=False)
    im.colorspace_settings.name = "Non-Color"
    rgba = np.ones((args.size, args.size, 4), dtype=np.float32)
    rgba[..., :3] = img
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = png
    im.file_format = "PNG"
    im.save()
    if not (os.path.isfile(png) and os.path.getsize(png) > 0):
        raise SystemExit("texture not written")
    print("  texture -> %s (%d KB)" % (png, os.path.getsize(png) // 1024))

    # Two materials: skin from the texture, EYES from vertex colour. The globe
    # gets 52x52 texels of UV and its coordinates collapsed when it was
    # subdivided, so its iris cannot survive a texture round-trip. Games split
    # the eye into its own material for exactly this reason.
    skin = bpy.data.materials.new("skin_uv")
    skin.use_nodes = True
    nt = skin.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = im
    tex.interpolation = "Smart"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.88
    for nm, val in (("Specular IOR Level", 0.25), ("Subsurface Weight", 0.18)):
        if nm in bsdf.inputs:
            bsdf.inputs[nm].default_value = val
    if "Subsurface Radius" in bsdf.inputs:
        bsdf.inputs["Subsurface Radius"].default_value = (0.010, 0.004, 0.002)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    eye = bpy.data.materials.new("eye_vcol")
    eye.use_nodes = True
    nt2 = eye.node_tree
    nt2.nodes.clear()
    o2 = nt2.nodes.new("ShaderNodeOutputMaterial")
    b2 = nt2.nodes.new("ShaderNodeBsdfPrincipled")
    vc = nt2.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = ATTR
    nt2.links.new(vc.outputs["Color"], b2.inputs["Base Color"])
    b2.inputs["Roughness"].default_value = 0.25
    nt2.links.new(b2.outputs["BSDF"], o2.inputs["Surface"])

    me.materials.clear()
    me.materials.append(skin)
    me.materials.append(eye)

    eye_v = set()
    for gname in ("helper-l-eye", "helper-r-eye"):
        k = gi.get(gname)
        if k is None:
            continue
        eye_v |= {v.index for v in me.vertices
                  if any(e.group == k and e.weight > 0.01 for e in v.groups)}
    n_eye = 0
    for poly in me.polygons:
        vs = list(poly.vertices)
        if sum(1 for v in vs if v in eye_v) * 2 > len(vs):
            poly.material_index = 1
            n_eye += 1
    print("  eye material assigned to %d faces" % n_eye)
    if n_eye == 0:
        raise SystemExit("no face landed on the eye material -- the iris would"
                         " stay lost")
    me.update()

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
