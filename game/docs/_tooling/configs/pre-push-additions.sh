# DRAFT — pre-push additions for DungeonParty-A. NOT APPLIED.
# Splice this block into `.githooks/pre-push` during rollout step 5
# (see ../code-quality-proposal.md §6), placed ABOVE the existing
# "[pre-push gate] 1/2 validate.ps1..." line.
#
# Design: SOFT / WARN-ONLY. This phase NEVER blocks the push. The authoritative
# hard gate stays the existing Phase 1 (validate.ps1) + Phase 2 (GUT suite) below.
# If gdlint / ruff aren't installed, the phase skips cleanly — no false failures.
#
# REPO_ROOT is already defined by the existing hook (line 11). Do not redefine it.

# ---------------------------------------------------------------------------
# Phase 0 (soft) — style lint: gdlint (GDScript) + ruff (Python). Warn-only.
# ---------------------------------------------------------------------------
echo "[pre-push gate] 0/2 style lint (warn-only)..."

if command -v gdlint >/dev/null 2>&1; then
  gdlint \
    "$REPO_ROOT/game/scenes" \
    "$REPO_ROOT/game/shared" \
    || echo "  [warn] gdlint reported issues (non-blocking)."
else
  echo "  [skip] gdlint not installed (pip install 'gdtoolkit==4.*')."
fi

if command -v ruff >/dev/null 2>&1; then
  ruff check "$REPO_ROOT/game/tools/blender" \
    || echo "  [warn] ruff reported issues (non-blocking)."
else
  echo "  [skip] ruff not installed (pip install ruff)."
fi

# Soft phase: always continue to the hard gate. Do NOT exit here.
# ---------------------------------------------------------------------------
