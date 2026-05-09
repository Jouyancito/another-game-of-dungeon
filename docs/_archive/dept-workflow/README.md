# Multi-Worktree Dept Workflow — ARCHIVADO

**Estado**: DESACTIVADO desde 2026-05-09
**Razón**: solo dev (Bastián) trabajando secuencial con 1 agente AI a la vez. El overhead del semáforo + dept-status + 4 worktrees no se amortizaba.
**Reactivable**: cuando haya 2+ agentes/devs trabajando en paralelo en slices independientes.

## Qué había

Setup pensado para que 4 ventanas Claude Code colaboren en paralelo:

- **A** (`master`) — coordinador, decide estrategia + resuelve conflictos
- **B** (`dept/gameplay/*`) — mecánicas, combate, IA
- **C** (`dept/design/*`) — balance, lore, specs
- **D** (`dept/art/*`) — VFX, shaders, materiales

Cada uno en su propio worktree (clon liviano que comparte `.git`).

## Componentes

```
docs/_archive/dept-workflow/
├── README.md                    ← este archivo
├── DEPARTMENTS.md               ← protocolo completo + flujo
├── CLAUDE_section.md            ← sección que iba en CLAUDE.md raíz
└── githooks/
    ├── post-commit              ← shim sh
    ├── post-commit.ps1          ← genera .dept-status/{code}.json
    ├── pre-push                 ← shim sh
    └── pre-push.ps1             ← semáforo conflictos verde/amarillo/rojo
```

## Cómo reactivar (5 min)

1. Crear los 3 worktrees secundarios:
   ```
   git worktree add ../DungeonParty-B -b idle/b
   git worktree add ../DungeonParty-C -b idle/c
   git worktree add ../DungeonParty-D -b idle/d
   ```
2. Restaurar hooks en repo:
   ```
   mv docs/_archive/dept-workflow/githooks .githooks
   git config core.hooksPath "$(pwd)/.githooks"
   ```
   ⚠️ El path debe ser absoluto y CORRECTO. La última vez se rompió porque el repo se movió a `Desktop/Juego/` y `core.hooksPath` quedó apuntando al path viejo.
3. Recrear carpeta de estado:
   ```
   mkdir -p .dept-status
   ```
4. Restaurar la sección en CLAUDE.md raíz copiando `CLAUDE_section.md` adentro.
5. Recrear launchers `Godot-{B,C,D}-*.lnk` apuntando a cada worktree.

## Lecciones aprendidas

- **Hooks paths absolutos** se rompen si movés el proyecto de carpeta. Si volvés a usar este setup, considerá `core.hooksPath` relativo (`.githooks`) en vez de absoluto.
- **Semáforo de conflictos** valioso solo cuando hay overlap real entre ramas. Para slices bien aislados (un dept toca solo un dir), el rojo casi nunca aparece — se vuelve teatro.
- **dept-status JSONs** útiles para A (master) ver estado de B/C/D rápido. Pero requieren que cada worktree commitee seguido — sino la info se queda stale.
- **Reactivación condicional**: pulir este setup tiene sentido cuando te sientas más fluido con multi-agente. Mientras seas vos solo + 1 Claude, single-worktree gana.
