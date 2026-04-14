---
name: worktree-merge-coordinator
description: Guía para A (master) al mergear ramas dept/* de B/C/D usando el semáforo de hooks. Se activa cuando estás en worktree A (master) y llega pedido de merge desde rama dept/{code}/{feature}.
type: pattern
---

# Worktree Merge Coordinator (A = master)

Sos coordinador. NO escribís código de feature — orquestás merges B/C/D, resolvés conflictos, mantenés árbol limpio.

## Trigger

- Worktree **A** (branch `master`).
- B/C/D pide mergear su `dept/{code}/{feature}`.
- O push 🟡/🔴 del semáforo requiere coordinación.

## Pre-merge — ORDEN OBLIGATORIO

NO saltear. NO cambiar orden.

### 1. Estado deptos (engram)

```
mem_search(query: "dept-status")
```

| Dept | Branch | Estado | Último commit | Archivos activos |
|------|--------|--------|---------------|------------------|
| B | dept/... | INICIADO/INACTIVO | hash | ... |
| C | ... | ... | ... | ... |
| D | ... | ... | ... | ... |

### 2. Sync remoto

```bash
git fetch --all --prune
```

### 3. Archivos tocados por worktree activo

```bash
bat .dept-status/b.json .dept-status/c.json .dept-status/d.json 2>/dev/null
```

Extraer `files_touched`.

### 4. Overlap check

```bash
git diff --name-only master...dept/design/skill-balance
```

Cruzar con `files_touched` de deptos ACTIVOS (INICIADO).

## Árbol de decisión

### 🟢 VERDE — sin overlap / depto inactivo / archivos disjuntos

```bash
git merge --no-ff dept/{code}/{feature} -m "merge: {feature} desde dept/{code}"
git push origin master
```

```
mem_save(
  title: "Merge {feature} dept/{code} → master",
  type: "decision",
  topic_key: "merge-log/{fecha}-{feature}",
  content: "Archivos: ...\nCommits: ...\nSin conflictos."
)
```

### 🟡 AMARILLO — overlap pero merge limpio

```bash
git diff master...dept/{code}/{feature} -- <archivos-overlap>
```

Mostrar diff + **preguntar** antes. Si OK:

```bash
git merge --no-ff dept/{code}/{feature}
git push origin master
```

Luego **broadcast re-sync** (template abajo).

### 🔴 ROJO — conflicto real

**BLOQUEAR merge**. No correr `git merge`.

Generar prompts copy-paste para deptos afectados (template). Usuario los pega en B/C/D. Cuando confirman rebase + push, reintentar paso 1.

## Post-merge

```bash
# 1. mem_save (ver arriba)
# 2. Renombrar rama → idle (en worktree del depto, vía broadcast)
# 3. Borrar remota
git push origin --delete dept/{code}/{feature}
# 4. Broadcast pull a deptos activos
```

## Template — broadcast re-sync 🟢/🟡

```
Master se movió. Rebaseá antes de seguir:

cd <tu-worktree>
git fetch origin
git pull --rebase origin master

Conflictos → avisá a A antes de tocar.
Commits: {lista-hashes}
Archivos: {lista}
```

## Template — 🔴 ROJO conflicto

```
ALTO. Conflicto real con master.

Archivos: {lista}
Tu rama: dept/{code}/{feature}
Último commit: {hash}

EN ORDEN:
1. cd <tu-worktree>
2. git status  # working tree clean?
3. git fetch origin
4. git rebase origin/master
5. Resolvé: {archivos}
6. git add <resueltos>
7. git rebase --continue
8. git push --force-with-lease origin dept/{code}/{feature}
9. Avisá a A.

NO git merge master. NO git reset --hard sin preguntar.
```

## Template — depto INACTIVO con rama viva

```
Dept {CODE} INACTIVO pero dept/{code}/{feature} tiene {N} commits sin mergear.

Opciones:
  a) Mergear ahora (sin overlap) → 🟢
  b) Esperar que {CODE} vuelva
  c) Descartar (git push origin --delete)

Preguntar al usuario.
```

## Checklist cierre

- [ ] `mem_save` topic_key `merge-log/{fecha}-{feature}`
- [ ] Rama remota `dept/*` borrada
- [ ] Rama local renombrada `idle/{code}` en worktree depto
- [ ] Broadcast enviado
- [ ] `.dept-status/{code}.json` reflejará estado en próximo commit del depto

## Reglas duras

- NUNCA `git push --force` a master.
- NUNCA mergear con depto 🔴 sin resolver.
- NUNCA saltear paso 1 (mem_search dept-status).
- Merges siempre `--no-ff`.
- Hook `pre-push` bloquea → NO `--no-verify`. Resolver.
