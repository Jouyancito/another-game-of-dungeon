# Sección "Departamentos" para CLAUDE.md

> Pegá esto en CLAUDE.md (después de "Próximos Pasos", antes de "Convenciones") cuando reactives el setup multi-worktree.

---

## Departamentos — Status Tracking (OBLIGATORIO)

### Worktrees y roles

- **A** (`master`) — 🔴 Main/coordinador. Esta ventana decide estrategia y coordina conflictos entre B/C/D.
- **B** (`idle/b` → `dept/{code}/{feature}` al asignar tarea) — 🟢
- **C** (`idle/c` → `dept/{code}/{feature}` al asignar tarea) — 🔵
- **D** (`idle/d` → `dept/{code}/{feature}` al asignar tarea) — 🟡

Cuando se asigna tarea a B/C/D: `git branch -m idle/x dept/{code}/{feature}`.

### Protocolo obligatorio al ARRANCAR sesión (cualquier worktree)

**SIEMPRE al iniciar una sesión en B, C o D, hacer en ESTE orden:**

1. **Leer `.dept-status/*.json`** — todos los archivos que hay en la carpeta.
2. Por cada archivo válido, **sincronizar a engram**:
   ```
   mem_save(
     title: "Dept {CODE} — estado actual",
     type: "config",
     scope: "project",
     topic_key: "dept-status/{code}",
     content: <contenido del JSON formateado como markdown>
   )
   ```
3. Reportar estado propio con `mem_save` y topic_key `dept-status/{tu-código}` + estado `INICIADO`.

En **A (master)**: al arrancar, ADEMÁS hacer `mem_search(query: "dept-status")` y mostrar tabla resumida del estado de B/C/D.

### Al hacer commit (automático)

Hook `post-commit` escribe `.dept-status/{code}.json` con branch, último commit, archivos tocados. No hay que hacer nada manual.

### Al hacer push (automático)

Hook `pre-push` aplica semáforo de conflictos:
- 🟢 Verde → push libre
- 🟡 Amarillo → overlap de archivos, merge limpio, pide confirmación
- 🔴 Rojo → conflicto real, bloquea push. Lista worktrees a coordinar.

Cuando A (master) detecta rojo/amarillo, debe generar **prompts copy-paste** para las ventanas afectadas con instrucciones concretas de qué tocar.

### Al cerrar sesión

1. `mem_save` con topic_key `dept-status/{code}` + estado `INACTIVO`.
2. Si hay commits sin pushear → `git push` (para sincronizar local ↔ remoto).

Detalle completo en `DEPARTMENTS.md` → sección "Protocolo de Estado".

Para ver estado de todos: `mem_search(query: "dept-status")`.
