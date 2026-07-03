# Code-Quality Tooling Proposal — DungeonParty-A

Status: **DRAFT / NOT APPLIED.** This document and the files under
`game/docs/_tooling/configs/` are proposals only. No source file has been
reformatted, no live config or git hook has been touched. The user approves the
actual rollout later.

---

## 1. TL;DR

Two tools, scoped to the two languages that actually live in this repo:

- **GDScript → [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit)**
  (`gdformat` + `gdlint`). It is the de-facto formatter/linter for Godot and is
  TAB-aware, matching the codebase's existing canon style.
- **Python → [ruff](https://docs.astral.sh/ruff/)** (`ruff format` + `ruff check`).
  Single zero-dependency binary that replaces black + isort + flake8, ideal for
  the 9 headless-Blender scripts under `game/tools/blender/`.

**Why not Prettier / ultracode?**

- **Prettier** has no GDScript support and no meaningful Python support (it is a
  JS/TS/CSS/MD/YAML formatter). The repo has effectively no web stack to format —
  bringing in Node + Prettier would add a toolchain for almost nothing. Markdown
  is the only Prettier-eligible content, and docs here are hand-authored prose
  where auto-reflow hurts more than it helps.
- **"ultracode"** is the project's own multi-agent orchestration mode (see
  `CLAUDE.md` → "Ultracode / effort selectivo"), reserved for large architectural
  jumps. It is **not** a formatter/linter and is explicitly *not* to be left on by
  default. Wiring code-quality gates is exactly the kind of fine, mechanical work
  the project's own conventions say to keep OFF ultracode.

**The single most important finding:** the codebase is *already* in canon style.
The only real inconsistency is **line endings (114 CRLF vs 41 LF)**. The first,
highest-value, lowest-risk move is an `.editorconfig` + `.gitattributes` to lock
in **tabs + LF** — NOT a mass reformat. Formatters come second, after EOL is
normalized, so the first format diff is small instead of 114-file EOL noise.

---

## 2. Current State

### GDScript (155 game `.gd` files; `addons/` and `.godot/` excluded)

| Aspect | Finding |
|---|---|
| Indentation | **TABS** on 153/155 files. 0 space-indented files. The 1 "mixed" file (`crystal_ceiling.gd`) is a false positive — a space-aligned inline comment on L75. |
| Line endings | **INCONSISTENT — 114 CRLF / 41 LF.** This is the only real deviation. |
| Naming | Canon: `class_name` PascalCase, funcs/vars snake_case, consts UPPER_SNAKE, enums PascalCase + UPPER_SNAKE members, privates `_`-prefixed. **0 violations.** |
| Idioms | Godot 4.x throughout (`@export`/`@export_range`/`@export_enum`, `:=` inference, typed signals, setters, enums, `##` doc-comments). |
| Comments | Spanish (project convention per `CLAUDE.md`), dense 14.5% (1496 `##` + 3661 `#`). Linters do not police comment language — keep as-is. |
| Line length | 64 files have lines >100 chars — heaviest are **embedded shader string literals** (e.g. `king_slime.gd`) and dev/throwaway scripts. |
| `;` lines | 53 detected, almost all **inside embedded shader strings** or vendored VFX — NOT real GDScript statement separators. |

### Python (9 files, all under `game/tools/blender/`)

> `game/tools/godot/**/*.py` matched **zero** files — that subtree is `.gd` +
> PNG anim-capture artifacts. All Python is the headless-Blender pipeline.

| Aspect | Finding |
|---|---|
| Indentation | 4 spaces, no tabs. Uniform. |
| Naming | snake_case funcs, UPPER_CASE module constants (`SEED`, `OUTPUT_DIR`). |
| Line length | Mixed — generators reach 114–130 cols (geometry literals), previews ~94–113. |
| Docstrings | 8/9 files have a module docstring (`preview_rigged.py` lacks one). |
| Imports | Split: `gen_*` use PEP8 one-per-line; small scripts use combined `import bpy, sys, os, math, mathutils` (E401). |
| One-liners | Deliberate `;`-compound + `if x: continue` in terse setup blocks (E701/E702). |
| `bpy`/`bmesh`/`mathutils` | Runtime-injected by Blender. Static ruff won't flag them as unresolved; they are NOT pip-installable. |

### Existing config

**None.** No `.gdlintrc`, `.editorconfig`, `.gitattributes`, `pyproject.toml`,
`ruff.toml`, `.flake8`, or gdtoolkit config exists anywhere.

Existing git hooks (`.githooks/`, verified):

- **`pre-push`** — Phase 1 `validate.ps1` (headless import + compile sweep),
  Phase 2 full GUT suite (387 tests). **No style/lint gate.**
- **`commit-msg`** — enforces that `feat:` commits ship a test/spec ref.
  **No style/lint gate.**

---

## 3. Install + Run (Windows / user's env)

The user's shell is PowerShell (primary) with Git Bash available. gdtoolkit and
ruff are both Python packages.

### Install

```powershell
# gdtoolkit — gdformat + gdlint (Godot GDScript)
pip install "gdtoolkit==4.*"     # match Godot 4.x

# ruff — Python formatter + linter
pip install ruff
```

`pipx install gdtoolkit` / `pipx install ruff` is equally fine and keeps them out
of the global site-packages.

### Check-only (no writes) — safe to run anytime

```powershell
# GDScript: would-be format diff, no changes written
gdformat --check --diff game/scenes game/shared

# GDScript: lint (reads .gdlintrc when present)
gdlint game/scenes game/shared

# Python: would-be format diff + lint, no changes written
ruff format --check --diff game/tools/blender
ruff check game/tools/blender
```

### Apply (writes files) — only during the dedicated rollout commit

```powershell
gdformat game/scenes game/shared          # rewrites in place
ruff check --fix game/tools/blender        # autofixable lint
ruff format game/tools/blender             # rewrites in place
```

> Do **not** run `gdformat` repo-wide before EOL normalization (§6) or the diff
> is ~114 files of pure line-ending churn.

---

## 4. Recommended Config (conservative — match existing style)

The guiding rule: **the first reformat diff must be SMALL.** Config mirrors what
the code already does (tabs for GDScript, 120-col tolerance for Python geometry
literals) so the tools agree with the codebase rather than fight it.

### 4.1 `.editorconfig` (do this FIRST — the real win)

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.gd]
indent_style = tab
max_line_length = 100

[*.py]
indent_style = space
indent_size = 4
max_line_length = 120

[*.md]
trim_trailing_whitespace = false   # trailing 2-space = hard line break
```

### 4.2 `.gitattributes` (lock LF, fixes the 114-CRLF inconsistency)

```gitattributes
*.gd  text eol=lf
*.py  text eol=lf
*.gd  diff
```

Then a **one-time** `git add --renormalize .` rewrites the 114 CRLF files to LF.
This resolves the only real inconsistency WITHOUT a formatter.

### 4.3 `.gdlintrc` (GDScript lint) — see `configs/.gdlintrc` draft

Conservative: keep naming/structure rules (the code already passes them), relax
line-length to 100, and **exclude vendored / dev / shader-heavy** files so we
don't get noise from false positives:

- Exclude `game/assets/art/_raw/**` (vendored binbun3d VFX — different style, real `;`).
- Tolerate `game/scenes/dev/**` and `game/tools/**` (dev/throwaway, many long lines).
- `king_slime.gd` and other embedded-shader files: long lines are string literals;
  the `max-line-length` set to 100 plus dev-script tolerance covers them. If
  gdlint still flags a shader-string file, add an inline `# gdlint:ignore=...`
  at the top rather than loosening the global rule.

> Note on `gdformat`: it does NOT have a tab/space option — it emits **tabs by
> default**, which is exactly canon here. No config needed to keep tabs.

### 4.4 `pyproject.toml` ruff block — see `configs/pyproject-ruff-snippet.toml` draft

Conservative for procedural Blender scripts:

```toml
[tool.ruff]
line-length = 120
target-version = "py311"
extend-include = ["game/tools/blender/*.py"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]
ignore = ["E501"]   # generators carry long geometry literals
```

Deliberately **NOT** enabled: `D` (docstrings), `ANN` (annotations), `PLR`
(complexity), `T201` (`print()` is the intended output channel of these scripts).
The combined-import (E401) and one-liner (E701/E702) cleanups are the main things
format+lint will touch — accept them in the dedicated commit, or guard the terse
light-setup blocks with `# fmt: off` / `# fmt: on`.

---

## 5. Git Hook Wiring (alongside the existing pre-push GUT gate)

**Do not break the existing gate.** The current `pre-push`:

1. Runs `validate.ps1` (compile sweep), blocks on failure.
2. Runs the full GUT suite, blocks on failure.

The lint additions go in as a **soft (warn-only) phase 0** that runs FIRST and
**never blocks the push** — it prints findings and continues. This keeps the hard
gate (compile + tests) authoritative and makes lint a nudge, not a wall, while
the team gets used to it. Promote to a hard gate later only if desired.

See `configs/pre-push-additions.sh` for the exact snippet to splice in **above**
the existing Phase 1. It:

- skips cleanly if `gdlint` / `ruff` aren't installed (no false push failures),
- runs `gdlint` on `game/scenes game/shared` and `ruff check` on
  `game/tools/blender`,
- prints results, and **always exits its own block with success** (the real gate
  is still validate + GUT below it).

The `commit-msg` hook is left untouched.

---

## 6. Rollout Plan

Ordered so style work never pollutes feature diffs:

1. **Now (this proposal):** write config + hook snippet drafts into
   `game/docs/_tooling/`. Nothing live changes. ← *we are here.*

2. **EOL normalization (1 dedicated commit):**
   - Copy `.editorconfig` and `.gitattributes` to repo root.
   - Run `git add --renormalize .`.
   - Commit alone: `chore(tooling): lock tabs+LF via editorconfig/gitattributes`.
   - This fixes the 114-CRLF inconsistency and is the single highest-value step.

3. **Adopt configs (1 small commit, no reformat yet):**
   - Copy `.gdlintrc` to root; splice the ruff block into root `pyproject.toml`.
   - Run check-only commands to see the (now small) would-be diff.
   - Commit: `chore(tooling): add gdlint + ruff config (check-only)`.

4. **The dedicated reformat (1 commit, isolated):**
   - `gdformat game/scenes game/shared` + `ruff format` + `ruff check --fix`
     on `game/tools/blender`.
   - Run the full GUT suite to confirm zero behavior change.
   - Commit ALONE: `style: gdformat + ruff first pass (no logic change)`.
   - Because EOL is already LF, this diff is purely formatting (trailing-ws +
     long-line reflow + import/one-liner normalization) — reviewable, not noise.

5. **Wire the soft hook (1 commit):**
   - Splice `pre-push-additions.sh` into `.githooks/pre-push` above Phase 1.
   - Commit: `chore(hooks): add warn-only gdlint+ruff phase to pre-push`.

6. **(Optional, later):** once the team is comfortable, flip the lint phase from
   warn-only to a hard gate.

Keep steps 2, 4, and 5 as **separate commits** so reviewers never see formatting
churn mixed with logic.
