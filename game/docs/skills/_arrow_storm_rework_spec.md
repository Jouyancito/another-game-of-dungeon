# Lluvia de Flechas — Rework AoE preview parábola (spec)

**Estado:** Pendiente — referencia user 2026-05-07. Sale del scope de "fix bugs",
es feature de UX/VFX nueva. Retomar cuando se cierre playtest actual.

**Inspiración:** Forspoken aim-circle, PoE meteor, Game Forge style ground-target spells.

---

## Comportamiento deseado

1. Player apunta con cursor a un punto en el suelo.
2. Mientras mantiene apretado el botón (o canaliza), un **círculo en el suelo** marca
   el área donde van a caer las flechas.
3. Las flechas vienen desde arriba en **arco parabólico** (no desde el player horizontal).
4. Caen dentro del círculo distribuidas semialeatoriamente.
5. Mover el mouse → mover el círculo.
6. Soltar / re-apretar `4` → para el canal y aplica cooldown.

---

## Componentes técnicos

### Visual
- **Decal circular en el suelo** en posición del cursor (raycast world).
  - Color amarillo/naranja translúcido, anim pulsante 0.5s loop.
  - Diámetro = `radius_m * 2` (12 × 2 = 24m del .tres actual).
- **Flechas projectile parabólicas:** spawn en `target_pos + Vector3(0, 15, 0)`,
  velocity inicial `(random_offset, -fall_speed, 0)`, gravity natural.
  - 2-3 flechas/segundo dentro del círculo.
  - On hit ground → despawn + decal pequeño impacto (opcional).
  - On hit enemy → damage + despawn.

### Lógica
- **Reemplazar** `_channeled_tick` AoE actual: en vez de damage_formula directo a enemies
  in sphere cada 0.5s, **spawn projectiles** que viajan + impactan.
- Damage por flecha menor que tick actual (cada flecha hace 6-8, vs tick 18).
- Concentración gen on hit: cada flecha que impacta enemy → +2 CONC (con cap por canal).

### Restricciones
- Range_m del skill (30m) clampea cursor → si user apunta más lejos, círculo queda en el
  borde de los 30m alrededor del player.
- Visual del círculo solo visible mientras canalizando.
- En modo edit/paused → preview no se muestra.

---

## Archivos involucrados (estimado)

- `game/scenes/player/player_skills.gd` — `_channeled_tick` rework + preview spawn/despawn.
- `game/scenes/projectile/falling_arrow.tscn` (nuevo) — projectile parabólico.
- `game/scenes/vfx/aoe_circle_preview.tscn` (nuevo) — decal o mesh circular.
- `game/shared/skills/resources/archer/arrow_storm.tres` — ajustar damage por flecha,
  resource_gen_on_hit, tags.
- Posible: `game/scripts/aoe_aim_helper.gd` — utility para raycast cámara → ground +
  clamp range + spawn preview.

---

## Issues open referidos

- Issue #9 (sesión 2026-04-29): "Lluvia de flechas rework AoE target cursor (preview en
  cursor + click confirma drop) — restaurar canon CONC=30 cuando se haga".
- Confirma escencialmente lo mismo. Esta spec lo formaliza.

---

## NO hacer aún

- NO implementar hasta que: (a) se cierre el batch de bugs actual, (b) user confirme
  scope (full rework vs simple decal preview).
- Damage actual (18/tick AoE 12m) es **temporal**. Si rework cambia a per-arrow damage,
  el balance cambia entero.
