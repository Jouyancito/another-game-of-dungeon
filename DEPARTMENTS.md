# Dungeon Party — Studio Departments

Sistema de departamentos para desarrollo paralelo. Cada departamento trabaja en su propia branch (worktree), aislado del resto. Master solo se toca después de QA.

## Workflow

```
1. Router (esta sesión) identifica el departamento correcto
2. Usuario abre/va a la ventana del departamento
3. Departamento trabaja en branch: dept/{code}/{feature}
4. Departamento hace commits y push
5. QA revisa la branch (tests, conflictos, calidad)
6. Si pasa → merge a master
7. Si no pasa → feedback al departamento
```

## Convenciones de Branch

- `dept/ui/{feature}` — ej: `dept/ui/inventory-screen`
- `dept/design/{feature}` — ej: `dept/design/skill-tree-balance`
- `dept/gameplay/{feature}` — ej: `dept/gameplay/archer-class`
- `dept/art/{feature}` — ej: `dept/art/particle-system`
- `dept/levels/{feature}` — ej: `dept/levels/floor1-generator`
- `dept/audio/{feature}` — ej: `dept/audio/combat-sfx`
- `dept/narrative/{feature}` — ej: `dept/narrative/boss-intro`
- `dept/network/{feature}` — ej: `dept/network/steam-lobby`
- `dept/perf/{feature}` — ej: `dept/perf/enemy-pooling`
- `dept/qa/{review}` — ej: `dept/qa/review-archer-class`

## Departamentos Activos

### Fase 1 — Prototipo (actual)

| # | Departamento | Código | Experto en... | Estado |
|---|-------------|--------|---------------|--------|
| 1 | **UI/UX** | `ui` | Menús, HUD, inventario, tooltips, navegación, Control nodes, themes | Activo |
| 2 | **Game Design** | `design` | Balance, stats, fórmulas, tablas, GDD, curvas de progresión, referencias a otros juegos | Activo |
| 3 | **Gameplay** | `gameplay` | Mecánicas, combate, habilidades, IA, colisiones, CharacterBody3D, signals | Activo |
| 4 | **Art & VFX** | `art` | Shaders, partículas, materiales, Blender, iluminación, estilo low-poly | Activo |
| 5 | **QA & Integration** | `qa` | Revisar branches, detectar conflictos, merge a master, testing manual | Activo |

### Fase 2 — Contenido (futuro)

| # | Departamento | Código | Experto en... | Estado |
|---|-------------|--------|---------------|--------|
| 6 | **Level Design** | `levels` | Generación procedural, room layouts, spawns, trampas, decoración | Pendiente |
| 7 | **Audio** | `audio` | SFX (sfxr, Audacity), música, FMOD/Wwise, ambientación por piso | Pendiente |
| 8 | **Cinematics & Narrative** | `narrative` | Cutscenes, lore, diálogos, AnimationPlayer, textos in-game | Pendiente |

### Fase 3 — Multiplayer (futuro)

| # | Departamento | Código | Experto en... | Estado |
|---|-------------|--------|---------------|--------|
| 9 | **Networking** | `network` | GodotSteam, MultiplayerAPI, sincronización, lobby, netcode | Pendiente |
| 10 | **Performance** | `perf` | Profiling, LOD, culling, object pooling, carga async de assets | Pendiente |

## Cómo abrir un departamento

Cada departamento es una sesión de Claude Code en su propia worktree:

1. Abrí una nueva ventana de Claude Code
2. Decile: "Soy el departamento {nombre}. Mi branch es dept/{code}/{feature}. Creá la worktree y empezá a trabajar en {tarea}."
3. El departamento trabaja aislado en su branch
4. Cuando termina, hace push y avisa al QA

## Routing — Cómo saber qué departamento necesitás

| Si tu pregunta es sobre... | Va a... |
|---------------------------|---------|
| Menús, botones, pantallas, HUD, barras | **UI/UX** |
| Stats, balance, fórmulas, cuánto daño, progresión | **Game Design** |
| Implementar habilidades, IA, mecánicas de combate | **Gameplay** |
| Cómo se ve, shaders, partículas, modelos, colores | **Art & VFX** |
| Generar pisos, rooms, spawns de enemigos | **Level Design** |
| Sonidos, música, efectos de audio | **Audio** |
| Historia, diálogos, cutscenes | **Cinematics** |
| Multijugador, Steam, lobbies | **Networking** |
| Lag, FPS, memoria, carga | **Performance** |
| Revisar trabajo, mergear, testear | **QA & Integration** |

## Notas

- Los departamentos se activan a medida que el juego los necesite
- Nuevos departamentos se pueden crear en cualquier momento
- Si algo cruza departamentos, el Router (sesión coordinadora) decide el orden
- Master SIEMPRE es la versión estable
