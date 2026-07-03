# Reference Library

Durable store for visual references that drive asset/art/UI/motion work.

**Why this exists:** engram/memory holds *text only*. Pasted images vanish between sessions (the 06-09 golem refs were lost this way). The actual image must live HERE, in the repo, versioned.

## Convention (both halves required)

1. **SAVE** — for each reference Joan sends, for subject `X`:
   - Commit the image: `_references/<X>/<name>.png`
   - Synthesize: `_references/<X>/_synthesis.md` with **Idea/Concepto · Colores · Forma/Silueta · Movimiento/Feel · Qué capturar · Fuente/Fecha**
   - Engram pointer: `topic_key reference/<X>` → points here.
2. **USE** — BEFORE building/iterating asset `X`, LOAD `_references/<X>/` first and build FROM it (not from memory of a description).

Enforced in `blender-asset-smith` SKILL.md → "Reference-driven workflow (MANDATORY)".
