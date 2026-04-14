# P1 Pradera — Economía XP y Loot

**Scope**: Diseño de economía del Piso 1 (Pradera). Tier I, primer contacto del jugador con el loop.

**Depende de**: `balance_v2.md` §3 (HP/DMG/DEF/XP canon) y §5 (curva XP piecewise).
**Coordina con**: Dept B (HP por enemigo, pack composition).

---

## 1. Target de pacing

| Hito | Tiempo real | Pisos recorridos | Nivel esperado |
|------|-------------|------------------|----------------|
| Primera muerte de mob | ~2 min | P1 arranque | L1 |
| Primer chest abierto | ~5 min | P1 | L1 |
| Subida a L2 | ~25-35 min | fin P1 / inicio P2 | L2 |
| Subida a L3 | ~90-120 min | fin P2 / inicio P3 | L3 |

**Premisa**: jugador nuevo, sin coop optimizado, incluye deaths y exploración. Un grupo veterano puede llegar a L3 en ~60 min; está OK.

---

## 2. XP por enemigo (P1)

Derivado de `balance_v2.md` §3.1 con `piso = 1`. Valores redondeados:

| Sub-tier | Nombre ejemplo P1 | HP | DMG | XP | TTK target (solo L1) |
|----------|-------------------|----|----|----|----------------------|
| A (fodder) | Mini-slime / lobezno | 54 | 5 | **11** | 1-2 hits |
| B (líder pack) | Slime grande / lobo adulto | 86 | 8 | **22** | 4-6 hits |
| C (alfa/élite) | Alfa de pack / Bandit leader | 130 | 12 | **39** | 8-12 hits |
| Veterano | Nombre propio persistente | 155 | 14 | **44 + drop único** | 10-15 hits |
| Mini-boss | Campamento bandit (P4 pool) | 216 | 10 | **55** | 20-30 hits |
| Boss tier (P24) | Rey Slime | 270 | 10 | **165** | Fuera de scope P1 |

**Nota**: XP canon = `10 * (1 + piso * 0.08)` → P1 base 10.8 ≈ 11. Multiplicadores sub-tier de §3.2 aplicados.

### Pack composition (coordinar con B)

| Tipo de encuentro | Frecuencia por arena | Composición |
|-------------------|----------------------|-------------|
| Pack estándar | 60% | 1 sub-B + 3-4 sub-A |
| Mob suelto | 25% | 1-2 sub-A |
| Pack élite | 10% | 1 sub-C + 2 sub-A |
| Encuentro especial | 5% | Veterano (si aplica seed) o mini-boss |

**Expected P1 run (1 piso, ~25 min)**:
- ~20 sub-A + ~5 sub-B + ~1 sub-C
- XP total ≈ 20×11 + 5×22 + 1×39 = **369 XP**
- Suficiente para L1→L2 (100 XP) + avance parcial a L3 (~70% de 115 XP).

---

## 3. Curva XP L1→L3

Canon `balance_v2.md` §5 sin cambios:

| Nivel | XP req (this lvl) | XP acumulado |
|-------|-------------------|--------------|
| 1→2 | 100 | 100 |
| 2→3 | 115 | 215 |
| 3→4 | 132 | 347 |

**L1→L3 total = 215 XP**. Alcanzable en ~1 run de P1 clear completo. A dos horas reales, esperamos L3 sólido con buffer para L4 en P3.

### Bonos de XP aplicables en P1

| Fuente | Bonus | Notas |
|--------|-------|-------|
| Kill solo (último golpe) | +0% (base) | XP ya está calibrado |
| Kill en coop (party 2-4) | +15% | Incentiva cooperación |
| Buff "Calor del Fuego" (P5 fogata) | +5% | Dura 30 min real |
| Buff "Bendición Hermana" (P3 altar) | +10% | Dura 30 min real |
| Descubrir POI nuevo (primera vez en run) | +20 XP flat | Exploración |
| Completar piso sin morir | +50 XP flat | Al cargar P2 |

Los bonos son **multiplicativos entre sí** salvo los flat (suman al final).

---

## 4. Drops por kill — P1

Drop roll por mob muerto. Un único roll, tabla por sub-tier:

### Sub-A (fodder)

| Resultado | Chance | Contenido típico |
|-----------|--------|------------------|
| Nada | 70% | — |
| Material común | 20% | Gel de slime, piel de lobezno, hierba P1 (1-2 unidades) |
| Common item | 8% | Pieza de equip Common piso 1 |
| Rare item | 2% | Pieza de equip Rare piso 1 |

### Sub-B (líder pack)

| Resultado | Chance | Contenido |
|-----------|--------|-----------|
| Nada | 40% | — |
| Material común (2-3 unidades) | 30% | — |
| Common item | 20% | — |
| Rare item | 8% | — |
| Epic item | 2% | Raro momento "jackpot" primera hora |

### Sub-C (alfa/élite)

| Resultado | Chance | Contenido |
|-----------|--------|-----------|
| Material raro | 40% | Colmillo de alfa, núcleo de slime |
| Common item | 25% | — |
| Rare item | 25% | — |
| Epic item | 10% | — |

### Veterano

Drop **garantizado**: 1 Rare o Epic único (cosmético o item nombrado) + entrada en codex. Sin roll de vacío. Ver `balance_v2.md` §3.3.

### Boss P1 (Rey Slime, P24 real)

Fuera de scope — documentado en `boss_king_slime_spec.md`.

---

## 5. Chests — spawns y contenido

### Spawns por arena P1

| Tipo | Cantidad por arena | Spawn | Visibilidad |
|------|--------------------|-------|-------------|
| Chest pequeño | 3 fijos | Procedural (spots predefinidos, variación cosmética) | Visible |
| Chest mediano | 0-1 (40% chance) | Procedural | Escondido (1 raycast/exploración) |
| Chest grande | 0-1 (15% chance) | Detrás de puzzle/skill check leve | Requiere condición |
| Chest de boss | 1 garantizado al clear boss piso | Fixed | Drop directo |

### Contenido por tipo

**Chest pequeño** (3 rolls independientes):
- Slot 1 (material): 100% → 2-4 materiales comunes P1
- Slot 2 (oro): 100% → 10-25 oro
- Slot 3 (item roll):
  - 60% Common item
  - 30% Rare item
  - 8% Epic item
  - 2% nada (recompensa "dry" ocasional)

**Chest mediano**:
- Slot 1: 3-5 materiales (mix común/raro)
- Slot 2: 30-60 oro
- Slot 3 (garantizado item):
  - 45% Common
  - 40% Rare
  - 13% Epic
  - 2% Legendary (nunca en P1 regular, deferred)

**Chest grande**:
- Slot 1: 1 material raro P1 garantizado
- Slot 2: 80-150 oro
- Slot 3 (garantizado item raro+):
  - 55% Rare
  - 35% Epic
  - 10% Legendary (nunca en P1 regular, deferred)
- Slot 4: 1 consumible (poción, pergamino de retorno)

### Legendary en P1 — decisión

**NO hay Legendary drops en P1.** La raridad queda sembrada como rumor/visual en vendors pero sin drop. Razón: Legendary es momento pico de Tier II+. Bajarlo a P1 rompe la progresión emocional. Los slots "Legendary" en las tablas arriba están documentados para consistencia cross-tier, pero el pool real en P1 los sustituye por Epic.

---

## 6. Oro — drops y economía

Referencia, no diseño completo (deferred a doc de economía global).

| Fuente | Oro en P1 |
|--------|-----------|
| Kill sub-A | 0 (no drop directo) |
| Kill sub-B | 1-3 oro (50% chance) |
| Kill sub-C | 5-10 oro (100%) |
| Veterano | 20-40 oro |
| Chest pequeño | 10-25 |
| Chest mediano | 30-60 |
| Chest grande | 80-150 |
| Clear piso sin morir | +25 oro bonus |

**Expected oro por run P1 clean**: ~80-150 oro. Suficiente para 1-2 repairs o 1 enhancement +1 en taverna (referencia pendiente confirmar con Dept C economía global).

---

## 7. Abierto — pendientes

- **Tuning final XP por uso (§6 balance_v2)**: señales `on_hit_landed`, `on_spell_cast`, etc. Impacto en P1: bajo (early level los %XP uso son marginales).
- **Materiales P1 catalogados**: lista concreta (nombre, uso, vendor price). Separar a `p1_materials.md` si se complica.
- **Validación tooling**: necesitamos sim de 10 runs de P1 con composición promedio para confirmar que XP/loot del doc matchea target. Deferred a apply.
- **Death penalty**: si muere en P1, ¿se pierde % oro/materiales del run? Depende del doc de muerte global.

---

## 8. Checklist de coordinación

- [ ] **B (Gameplay)**: validar HP/DMG de mobs P1 matchea canon §3 tabla piso 1.
- [ ] **B**: implementar `xp_reward` por mob según sub-tier (sub-A=11, sub-B=22, sub-C=39).
- [ ] **B**: pack composition en spawner de arena P1.
- [ ] **D (Art)**: chest pequeño/mediano/grande — 3 props distintos visualmente (escala o detalle).
- [ ] **Design (esta ventana)**: `p1_materials.md` si se decide separar.
