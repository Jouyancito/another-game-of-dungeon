# Fauna Ambient Spec

**Estado**: DRAFT — open questions pendientes
**Última edición**: 2026-05-07
**Owner**: dept/design (asignar)

## Concepto

Distinguir 2 categorías de criaturas vivas en el mundo:

- **Combat enemies** — bandit, golem, slime, etc. Existen para ser combatidos. HP/daño visible. Aggro normal.
- **Fauna ambient** — hawk, fox, bird (small), futuros: ciervo, lobo, conejo, peces. Existen para dar vida al mundo. Cadena alimenticia. Solo combatibles bajo condiciones específicas.

La fauna ambient NO es contenido principal — es **inmersión + loot oportunista + skill check**.

## Pilares

1. **Vivir su vida**: cazar, comer, descansar, vagar. El player es secundario.
2. **Visible pero NO siempre alcanzable**: ves halcones arriba pero no podés matarlos a discreción.
3. **Ventanas de oportunidad**: bajan a cazar, descansar, beber → ahí los podés atacar.
4. **Skill check + recompensa**: matarlos requiere timing/posición. Recompensa: loot raro o crafting material.

## Especies en Piso 1 (Pradera)

### Halcón (`hawk`)

- **Estado actual**: bug fly_height=5m (parece murciélago), atacable siempre que te detecte, mesh chico.
- **Spec target**:
  - `fly_height`: 10-12m (real halcón, fuera de range de arco normal ~20m horizontal pero altura +12m = arc difícil)
  - **Mesh más grande**: alas 0.7m+, body 0.4m+ → visible desde abajo a 12m
  - **Hunting autónomo**: si detecta `prey` (rata, slime mini) en radio 30m horizontal + 12m vertical → picada. Mata prey, sube.
  - **Window de ataque**: durante DIVING → atacable. Durante CIRCLING/IDLE arriba → out of range para todos menos arquero con flecha cargada.
  - **Provocación**: si player atacante → circla y dive provocada (comportamiento actual). NO se queda arriba esperando si lo agreden.
  - **Name plate gate**: distancia >15m → invisible nombre/HP. <15m → visible. Refuerza "no es enemigo común".
  - **Loot drop** (opcional Fase 2): pluma de halcón (crafting), garra rara.

### Bird (small bird, ya existe)

- Estado actual: igual a hawk pero más chico.
- **Spec target**: queda como "fauna decorativa" — vuela, no ataca, no atacable. Future loot opcional.

### Fauna futura (Pradera)

- Ciervo (huye del player, cazable con bow para meat)
- Conejo (madriguera, scavenge food)
- Lobo (manada, ataca prey + agresivo si te acercás de noche)
- Peces (ríos del piso 2)

## Comportamiento de Hunting (hawks/predadores)

```
Estado base: CIRCLING o WANDER alto.
Sense (cada 1.5s):
  for prey in get_nodes_in_group("prey"):
    if distance_horizontal(prey) <= 30 and prey is alive:
      target = prey
      transition → DIVING_HUNT (no DIVING normal — diferenciar)
      break

DIVING_HUNT:
  → bajar hacia prey con dive_speed
  → si distance <= attack_range: kill prey instant (1 hit), grab
  → transition → RETREATING (sube con prey)
  → al llegar a fly_height: prey desaparece (efecto "se la llevó")

DIVING_HUNT interrumpible si player ataca al hawk en mitad de la picada.
```

**Group "prey"** — agregar a rata, slime mini, conejo (futuro). NO a slime grande, golem, bandit (no son prey).

## Open Questions

- [ ] **Q1**: ¿Hawks respawnean tras morir? Si sí, ¿cooldown? ¿O son finitos por run?
- [ ] **Q2**: ¿Loot del hawk se balancea o es trash drop? (decisión balance dept)
- [ ] **Q3**: ¿Hunting prey afecta cantidad de prey en el mundo? Si hawks matan ratas → ¿menos ratas para player? Tradeoff inmersión vs gameplay.
- [ ] **Q4**: ¿Cómo se telegrafía la picada para que player la note? (sonido, sombra en suelo, vocalización)
- [ ] **Q5**: ¿Hay versión nocturna distinta? (búho? murciélago real?)
- [ ] **Q6**: ¿El sistema de Evolución (DESIGN_NOTES_2026-05-06-1.md) afecta fauna? Hawks aprenden a evitar player con arco?

## Decisiones Tomadas

- ✅ Fauna ambient ≠ combat enemy (categoría conceptual diferente)
- ✅ Hawks viven su vida — hunting autónomo de prey
- ✅ Atacables solo durante windows específicos (picada principalmente)
- ✅ Loot decision postpone a balance dept (no bloqueante)

## Implementación — Fases sugeridas

### Fase 1 — Fix visual + altura (1-2h)
- `fly_height`: 5 → 10
- Mesh sizes: alas 0.4 → 0.7, body 0.2 → 0.35
- Name plate gate: si distance > 15m → ocultar (cambio en HUD/target_frame)

### Fase 2 — Hunting autónomo (3-5h)
- Agregar group "prey" a rata + slime mini
- Sense loop en hawk: detectar prey, transition DIVING_HUNT
- Kill prey 1-hit, grab anim, retreat

### Fase 3 — Polish + fauna nueva (futuro)
- Loot drops
- Nuevas especies (ciervo, lobo, conejo)
- Audio/VFX picada (telegraph)

## Archivos afectados

- `game/scenes/enemy/hawk.gd` — fly_height, mesh, hunt logic
- `game/scenes/enemy/hawk.tscn` — mesh sizes en EnemyModelBuilder call
- `game/scenes/enemy/rat.gd` (y similares prey) — agregar a group "prey"
- `game/scenes/hud/target_frame.gd` (o equivalente) — gate de distancia para nameplate

## Cross-canon

- `_world_canon.md` — pradera ambient
- `_class_lore_*.md` — clases hunters (archer/ranger) podrían tener interacción especial
- `DESIGN_NOTES_2026-05-06-1.md` (Evolución) — Q6 cross-tension

---

*Doc vivo — actualizar cuando se respondan open questions o se asigne a dept.*
