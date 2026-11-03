#!/usr/bin/env sh
# validate.sh - Dungeon Party headless Godot validation (Linux/macOS port of validate.ps1).
#
# Imports all resources + compiles every GDScript and reports parse/import/script errors.
# Keep the error patterns in sync with validate.ps1.
#
# Usage: sh game/tools/godot/validate.sh            (uses $GODOT, else `godot` on PATH)
# Exit codes: 0 = clean / 1 = errors found / 2 = Godot not found.

PROJECT=$(cd "$(dirname "$0")/../.." && pwd)
GODOT=${GODOT:-godot}

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "[validate] Godot executable not found: $GODOT (set GODOT=/path/to/godot)" >&2
  exit 2
fi

echo "[validate] Godot   : $(command -v "$GODOT")"
echo "[validate] Project : $PROJECT"
echo "[validate] Running headless import + script compile..."

# Phase 1: --editor --quit imports every resource and compiles the scripts the editor loads.
LOG=$("$GODOT" --headless --editor --quit --path "$PROJECT" 2>&1)
ERRS=$(printf '%s\n' "$LOG" | grep -E 'SCRIPT ERROR|Parse Error|ERROR:|Failed to (load|parse)|Cannot open|Invalid|expected')
if [ -n "$ERRS" ]; then
  echo "=== VALIDATION FAILED ($(printf '%s\n' "$ERRS" | wc -l) line(s)) ==="
  printf '%s\n' "$ERRS" | sed 's/^/  /'
  exit 1
fi

# Phase 2: compile sweep - force-loads every .gd, catching orphan scripts no scene references.
echo "[validate] Running full script compile sweep..."
SWEEP=$("$GODOT" --headless --path "$PROJECT" --script res://tools/godot/compile_sweep.gd 2>&1)
FAILS=$(printf '%s\n' "$SWEEP" | grep -E 'SWEEP FAIL|SCRIPT ERROR|Parse Error')
if [ -n "$FAILS" ] || ! printf '%s\n' "$SWEEP" | grep -q 'SWEEP PASSED'; then
  echo "=== VALIDATION FAILED (compile sweep) ==="
  if [ -n "$FAILS" ]; then printf '%s\n' "$FAILS" | sed 's/^/  /'
  else echo "  Sweep did not report PASSED. Raw tail:"; printf '%s\n' "$SWEEP" | tail -10 | sed 's/^/  /'; fi
  exit 1
fi

echo "=== VALIDATION PASSED - no script/import errors ($(printf '%s\n' "$SWEEP" | grep '\[sweep\] scripts checked')) ==="
exit 0
