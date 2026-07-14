#!/usr/bin/env node
// Dungeon Party — visual gate (render -> compare -> fix).
//
// Compares a freshly captured frame set against a committed golden set, frame by
// frame, using odiff (perceptual pixel diff). Produces a machine-checkable verdict
// so token-expensive VLM critique (art-ref-critic) only runs when a frame actually
// regressed. This is the "COMPARE" step that was missing from the capture pipeline:
// capture already works (SubViewport -> frame_NNN.png); this closes the loop.
//
// Decision model (the research-backed pattern):
//   determinism = AUTHORITY (this gate), VLM = ADVISOR (only on FAIL).
//   A cheap pixel diff runs BEFORE the model so unchanged frames never burn tokens.
//
// Usage:
//   node visual_gate.mjs --current <dir> --golden <dir> [--out <dir>]
//                        [--threshold-pct <n>] [--pixel-threshold <0..1>] [--json]
//
//   --current          dir of freshly captured frame_NNN.png (the run under test)
//   --golden           dir of committed reference frame_NNN.png
//   --out              where to write diff_NNN.png for failing frames + report.json
//                      (default: <current>/_gate_out)
//   --threshold-pct    max % of differing pixels a frame may have and still PASS
//                      (default: 1.0)
//   --pixel-threshold  odiff per-pixel color tolerance 0..1 (default: 0.1)
//   --json             print only the JSON report (for machine consumption)
//
// Exit code: 0 if every frame passed the gate, 1 if any frame failed (or inputs bad).
// The exit code is the gate; a CI / pre-commit hook can branch on it.

import { compare } from "odiff-bin";
import { readdir, mkdir, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, basename, resolve } from "node:path";

// ---------------------------------------------------------------- arg parsing
function parseArgs(argv) {
  const args = {
    current: null,
    golden: null,
    out: null,
    thresholdPct: 1.0,
    pixelThreshold: 0.1,
    json: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    switch (a) {
      case "--current": args.current = next(); break;
      case "--golden": args.golden = next(); break;
      case "--out": args.out = next(); break;
      case "--threshold-pct": args.thresholdPct = Number(next()); break;
      case "--pixel-threshold": args.pixelThreshold = Number(next()); break;
      case "--json": args.json = true; break;
      case "--help": case "-h": args.help = true; break;
      default:
        throw new Error(`unknown arg: ${a}`);
    }
  }
  return args;
}

const HELP = `dp visual-gate — render->compare->fix

  node visual_gate.mjs --current <dir> --golden <dir> [options]

  --current <dir>          freshly captured frame_NNN.png set (run under test)
  --golden <dir>           committed reference frame_NNN.png set
  --out <dir>              diff images + report.json   (default <current>/_gate_out)
  --threshold-pct <n>      max % differing pixels per frame to PASS  (default 1.0)
  --pixel-threshold <0..1> odiff per-pixel color tolerance           (default 0.1)
  --json                   print only the JSON report

exit 0 = all frames passed, 1 = at least one failed (escalate to art-ref-critic).`;

// ------------------------------------------------------------------ helpers
const FRAME_RE = /^frame_\d+\.png$/i;

async function listFrames(dir) {
  const entries = await readdir(dir);
  return entries
    .filter((f) => FRAME_RE.test(f))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
}

function fmtPct(n) {
  return (n == null ? "  n/a" : `${n.toFixed(2)}%`).padStart(7);
}

// --------------------------------------------------------------------- main
async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { console.log(HELP); process.exit(0); }

  if (!args.current || !args.golden) {
    console.error("ERROR: --current and --golden are required.\n");
    console.error(HELP);
    process.exit(1);
  }
  const currentDir = resolve(args.current);
  const goldenDir = resolve(args.golden);
  const outDir = resolve(args.out ?? join(currentDir, "_gate_out"));

  for (const [label, dir] of [["current", currentDir], ["golden", goldenDir]]) {
    if (!existsSync(dir)) {
      console.error(`ERROR: --${label} dir not found: ${dir}`);
      process.exit(1);
    }
  }
  await mkdir(outDir, { recursive: true });

  const goldenFrames = await listFrames(goldenDir);
  if (goldenFrames.length === 0) {
    console.error(`ERROR: no frame_NNN.png found in golden dir: ${goldenDir}`);
    process.exit(1);
  }
  const currentSet = new Set(await listFrames(currentDir));

  const results = [];
  for (const frame of goldenFrames) {
    const goldenPath = join(goldenDir, frame);
    const currentPath = join(currentDir, frame);
    const diffPath = join(outDir, `diff_${frame}`);

    if (!currentSet.has(frame)) {
      results.push({ frame, status: "FAIL", reason: "missing-in-current", diffPercentage: null });
      continue;
    }

    let cmp;
    try {
      cmp = await compare(goldenPath, currentPath, diffPath, {
        threshold: args.pixelThreshold,
        antialiasing: true,
        outputDiffMask: false,
      });
    } catch (err) {
      results.push({ frame, status: "FAIL", reason: `odiff-error: ${err.message}`, diffPercentage: null });
      continue;
    }

    // odiff returns { match: true } when identical-enough, else
    // { match: false, reason, diffCount, diffPercentage }.
    if (cmp.match) {
      results.push({ frame, status: "PASS", reason: "identical", diffPercentage: 0 });
      continue;
    }
    if (cmp.reason === "layout-diff") {
      results.push({ frame, status: "FAIL", reason: "layout-diff (size mismatch)", diffPercentage: null, diff: diffPath });
      continue;
    }
    const pct = cmp.diffPercentage ?? 100;
    const pass = pct <= args.thresholdPct;
    results.push({
      frame,
      status: pass ? "PASS" : "FAIL",
      reason: pass ? `within tolerance (${args.thresholdPct}%)` : `over tolerance`,
      diffPercentage: pct,
      // only keep the diff image when it actually failed — keeps the out dir small
      diff: pass ? undefined : diffPath,
    });
  }

  const failed = results.filter((r) => r.status === "FAIL");
  const gatePass = failed.length === 0;
  const report = {
    gate: gatePass ? "PASS" : "FAIL",
    summary: {
      total: results.length,
      passed: results.length - failed.length,
      failed: failed.length,
      thresholdPct: args.thresholdPct,
      pixelThreshold: args.pixelThreshold,
    },
    currentDir,
    goldenDir,
    outDir,
    failures: failed,
    frames: results,
  };

  await writeFile(join(outDir, "report.json"), JSON.stringify(report, null, 2));

  if (args.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log(`\n  visual-gate  ${report.gate}`);
    console.log(`  golden:  ${goldenDir}`);
    console.log(`  current: ${currentDir}`);
    console.log(`  ${report.summary.passed}/${report.summary.total} frames passed`
      + ` (threshold ${args.thresholdPct}% diff pixels)\n`);
    if (failed.length) {
      console.log("  FAILED frames (escalate these to art-ref-critic):");
      for (const f of failed) {
        console.log(`    ${f.frame}  ${fmtPct(f.diffPercentage)}  ${f.reason}`
          + (f.diff ? `  -> ${basename(f.diff)}` : ""));
      }
      console.log(`\n  diff images + report.json in: ${outDir}\n`);
    } else {
      console.log("  No regressions. VLM critique skipped (0 tokens spent).\n");
    }
  }

  process.exit(gatePass ? 0 : 1);
}

main().catch((err) => {
  console.error(`visual-gate crashed: ${err.stack ?? err}`);
  process.exit(1);
});
