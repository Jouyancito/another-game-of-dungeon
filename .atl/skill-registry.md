# Skill Registry — Dungeon Party

**Generated**: 2026-04-07
**Project**: another-game-of-dungeon

## Project Context

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Architecture**: CharacterBody3D hierarchy, signal-driven, BasePlayer inheritance
- **Testing**: No test runner (Godot GUT not installed)
- **CI/CD**: None
- **Linter/Formatter**: None

## User Skills

| Skill | Trigger | Source |
|-------|---------|--------|
| memory | Always active — persistent memory | global |
| judgment-day | Parallel adversarial review | global |
| go-testing | Go tests, Bubbletea TUI | global |
| skill-creator | Creating new AI skills | global |
| branch-pr | PR creation workflow | global |
| issue-creation | Issue creation workflow | global |

## SDD Skills

sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard

## Compact Rules

### GDScript Conventions (from CLAUDE.md)
- Herencia BasePlayer para todas las clases
- Senales para comunicar estado entre sistemas
- @export para todo valor de balance
- Grupos para identificar entidades ("player", "enemies")
- CharacterBody3D para player y enemigos
- Raycast para melee, Area3D para proyectiles
- StandardMaterial3D para feedback visual
- Variables @export para tunear balance

### Project Conventions
- GDD en GDD_DungeonParty.md es fuente de verdad para diseno
- Estilo visual: low-poly, modelos simples, texturas planas
- Godot standalone en la raiz del proyecto
- Physics layers: 1=World, 2=Player, 3=Enemies
