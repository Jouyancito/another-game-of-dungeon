# Skills Archive Log

Registro de `.tres` movidos a `game/shared/skills/resources/_archive/` porque ya no son canon vigente pero se conservan como referencia histórica.

`SkillDB` ignora carpetas que empiezan con `_` (skip `_archive`, futuras `_deprecated`, etc.) para evitar que se registren como skills activas.

---

## 2026-04-18 — `shield_bash.tres` (Warrior)

**Razón del archive**: no cumplía con el schema completo P0/P1 del `SkillResource` canon 2026-04-16 (falta tags, gate level, resource_gen_* explícitos, hp_cost_type, quest_gate). Fue creado como primer test del framework de skills antes de la canonización.

**Reemplazado por**: las 4 skills canon Fase 1 del Warrior (`punch.tres`, `charge.tres`, `war_cry.tres`, `perfect_block.tres`) en `warrior/`. Cubrir:
- Melee cono (Punch, ex shield_bash que era cono físico)
- Dash ofensivo (Charge)
- Aura toggle (War Cry)
- Reactive parry (Perfect Block)

**Detección**: Judgment Day 2026-04-18 — la skill no estaba en `warrior.md` v2.0 como canon, no estaba wireada al hotbar default de `player.gd::_equip_default_skills()`, pero seguía siendo cargada por SkillDB pudiendo aparecer en el libro de skills futuro.

**Acción tomada**:
1. Movido a `resources/_archive/shield_bash.tres` (git mv).
2. `SkillDB._load_all_skills` ignora carpetas que empiezan con `_`.
3. Sin re-write del schema — si alguna vez se quiere reactivar, se necesita migrate P0/P1 completo.

---

## Cómo archivar una skill

1. `git mv game/shared/skills/resources/{class}/{skill}.tres game/shared/skills/resources/_archive/{skill}.tres`
2. Update este doc con razón + reemplazo + detección.
3. Sacar del hotbar default si la clase la referenciaba.
4. Commit en rama dept + mensaje `chore(skills): archive {skill}.tres ({razón})`.
