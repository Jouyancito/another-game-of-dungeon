# Disciplina de tokens — cómo trabajamos y por qué

Medido el 2026-08-09 sobre **437 transcripts reales** (60 días, 1,2 GB en disco), leyendo
los bloques `usage` que Claude Code graba en cada mensaje. No son estimaciones.

Este doc existe porque Joan pidió que el estilo de trabajo quedara **versionado y cableado**,
no en la cabeza de nadie: *"que queden también hookeados para evitar salirme de esa forma de
trabajo"*.

---

## 1. Los números

| | 60 días |
|---|---|
| Output | 26,1 M tokens |
| **Cache read** | **7.374 M tokens** |
| Cache creado | 349 M |
| Input fresco | 2,9 M |

**Proyección a 2 meses sin cambiar nada**: 28 M de output y **8.600 M de cache read**.

### Concentración — el hallazgo principal

| | |
|---|---|
| Sesiones analizadas | 44 |
| Sesiones que concentran el 50% del output | **5 (11%)** |
| La peor sesión, sola | **33% del total** |
| Mediana de sesión | 362 mil output |
| Peor sesión | 9,0 M output — **25× la mediana** |

---

## 2. La corrección que cambia la recomendación

La primera lectura de estos datos dijo *"las imágenes son el 95% del gasto"*. **Era el 95% de
los BYTES, y los bytes mienten para imágenes.**

- Una imagen cuesta ≈ `ancho × alto / 750` tokens. Un render de 1800×900 ≈ **2.160 tokens**.
- 264 KB de **texto** ≈ **66.000 tokens**.

Por byte, el texto es unas treinta veces más denso. Recalculado en tokens:

| | tokens aprox. |
|---|---|
| Texto (resultados de herramienta + llamadas) | ~12,7 M |
| Imágenes | ~3,8 M |

**El texto pesa el triple que las imágenes.** Es el mismo error que aparece una y otra vez en
este proyecto: *una métrica sólo es evidencia de lo que mide*. Ver
`~/.claude/projects/C--/memory/feedback_look_before_you_report.md`.

---

## 3. Las palancas, ordenadas por efecto real

### 1º — Largo de sesión (la dominante, y la que no es intuitiva)

El costo de cache es **contexto × turnos**. Una sesión que crece paga su historia entera en
cada turno siguiente, así que el gasto es cuadrático en el largo. La peor sesión acumuló
**2.024 M de cache read** ella sola.

Partir el mismo trabajo en cuatro sesiones cuesta aproximadamente **un cuarto**.

> **Regla**: una tarea, una sesión. Al cambiar de tema, `/compact` o sesión nueva.

### 2º — Relecturas (desperdicio puro, cero costo de calidad)

- **946 de 1.921 lecturas de imagen fueron relecturas** — el 49%.
- En una sola sesión, **205 de 416 `Read` fueron el mismo archivo otra vez**:
  `floor1_prairie.gd` **49 veces**, `facet_closeup.png` 11 veces.

> **Regla**: nada se lee dos veces sin haber cambiado. Si necesitás otra parte, pedí esa parte.

### 3º — Resolución de imagen

Los renders crudos van a 1,5–2 MB y 1800 px. Bajados a 900 px q80 pesan 40–80 KB y **cuestan
un cuarto de los tokens**, sin perder nada del veredicto.

> **Regla**: ninguna imagen entra al contexto sin pasar por el downscale.

### 4º — Recortar la captura (Joan, 2026-08-09)

> *"lo ideal sería que si te saca un pantallazo, te sacara el pantallazo específicamente lo
> que quiero cambiar"*

El ahorro de tokens es modesto — ya vimos que las imágenes no son la palanca grande. **El
beneficio real es de precisión**: un recorte dice exactamente qué mirar. Varias capturas de
pantalla completa de esta sesión obligaron a adivinar cuál era el detalle.

### Descartado con datos

**Bash no es un problema**: 5.104 llamadas en 30 días con **0,8 KB de salida promedio**. No
hay nada que optimizar ahí. Se midió antes de proponer.

---

## 4. Lo que está cableado

`~/.claude/hooks/token-guard.py` (copia versionada en `workflow/hooks/`), enganchado en
`~/.claude/settings.json`:

| Hook | Evento | Qué hace |
|---|---|---|
| Tope de imagen | `PreToolUse` / `Read` | Bloquea imágenes >120 KB y devuelve el comando exacto de downscale |
| Anti-relectura | `PreToolUse` / `Read` | Bloquea leer lo mismo sin cambios. La clave incluye `offset`/`limit`, así que otra rebanada sí pasa, y editar el archivo desbloquea solo |
| Aviso de sesión larga | `UserPromptSubmit` | A los 60, 120, 200 turnos avisa que conviene `/compact` o sesión nueva. **Nunca bloquea** — cerrar la sesión es decisión de Joan |
| Peso de contexto | `Stop` | Reporta imágenes y archivos que entraron |

Los cuatro caminos fueron probados con payload sintético y después **en vivo**: una segunda
lectura de `MEMORY.md` fue denegada en sesión.

**Instalar en otra máquina**: copiar `workflow/hooks/token-guard.py` a `~/.claude/hooks/` y
agregar las cuatro entradas a `~/.claude/settings.json` (ver `workflow/hooks/settings-snippet.json`).

---

## 5. Cómo medir de nuevo

```bash
python workflow/tools/audit_tokens.py 30      # dónde se fue, por herramienta y por fuente
python workflow/tools/project_savings.py 60   # concentración, relecturas, tendencia, proyección
```

Ambos leen los transcripts locales. **Ninguna conclusión de este doc se aceptó sin correrlos.**

---

## 6. Deuda acumulada que conviene consolidar

Joan, 2026-08-09: *"hay varias cosas que hemos desarrollado estos meses, que ya deben estar
más pulidas, así que se pueden optimizar"*. Lo que ya está documentado como deuda:

1. **Helpers del motor copy-pasteados entre 5 packs** — `_motor_tiers.md` §"Deuda de
   infraestructura" lo admite explícito: `tree_pack/build_tree_pack.py:21-26` dice que copió
   el archivo. Falta que los 5 packs consuman `motor-blender/recetas/` en vez de forkear.
2. **Un generador de roca único** — hoy forkeado en `rock_pack`, `river_pack`, `gen_golem.py`
   y `golem_guardian` con firmas distintas. `biome_facet.py` es el candidato a unificarlos.
3. **Los tiers miden el MEDIO, no el FIN** — un pack puede ser M3 y no leerse como la cosa que
   representa (`bush_pack`). Falta un check de resultado, no sólo de técnica.

---

## 7. Fuera de alcance por ahora

**DeepSeek**: Claude Code no puede correr un modelo que no sea de Anthropic como propio. El
lugar de DeepSeek es el trabajo a granel —borradores, tests, docs, análisis de logs— llamado
por MCP o CLI propio y dirigido desde acá. Sin empezar.
