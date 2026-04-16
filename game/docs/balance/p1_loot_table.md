# P1 Pradera — Loot Table por Enemigo

**Scope**: Drops específicos por tipo de enemigo en P1. Deriva de `p1_economy.md` §4 (probabilidades por sub-tier) y `p1_enemies.md` (lista canónica de 9 enemigos + sub-tier).

**Fase**: 1 — design doc, NO implementación. Flag cualquier drift a A antes de aplicar.

**Ownership & bind**: reglas globales en `_drop_ownership_canon.md`. Columna `bind_on_drop` en las tablas abajo indica items que ignoran el reparto floor+random y se asignan al jugador trigger específico (ver canon §5).

---

## 0. Reglas generales

1. **Un roll por enemigo** (no múltiples rolls independientes).
2. **Roll resuelto en orden**: Legendary → Epic → Rare → Common → Material → Oro → Nada. Primer hit gana. (En P1 no hay Legendary, ver `p1_economy.md §5`.)
3. **Drop de material + equip**: sub-B y sub-C dropean material **garantizado** además del roll de equip (ver tablas abajo).
4. **Drop de oro**: independiente del roll principal, se tira aparte según `p1_economy.md §6`.
5. **Veterano**: override total — drop garantizado único, sin tabla.
6. **Coop ownership**: ver `_drop_ownership_canon.md`. Resumen: party-auto pool (sin damage gate), reparto floor+random, timer owner-lock 180s → free-for-all 120s → despawn 300s total. Items `bind_on_drop=TRUE` van al jugador trigger específico (no floor+random), timer 300s owner-only sin free phase.

---

## 1. Sub-A — Fodder (slime, mini_slime, rat, bird, fox)

Probabilidades base de `p1_economy.md §4 sub-A`:

| Resultado | Chance |
|-----------|--------|
| Nada | 70% |
| Material común | 20% |
| Common item | 8% |
| Rare item | 2% |

### slime
| Drop | Detalle |
|------|---------|
| Material común (20%) | `gel_slime` ×1-2 — crafting base poción |
| Common item (8%) | Pool: `amuleto_gel` (+2 VIT), `bota_slime` (+1 DEF, slot feet) |
| Rare item (2%) | `nucleo_slime_pequeno` — crafting gate arma Rare P1 |
| Oro | 0 |

### mini_slime
| Drop | Detalle |
|------|---------|
| Material común (15%) ⚠ | `gel_slime_fragmento` ×1 — reduce chance por ser invocado (anti-farm King Slime) |
| Common item (5%) | Solo `gel_slime` extra material |
| Rare item (0%) | No dropea Rare (anti-farm) |
| Oro | 0 |

**Nota anti-farm**: mini_slime invocado por boss. Si dropeara igual que slime, el boss se convierte en loot piñata. Drop reducido a 20% total (vs 30%+ estándar sub-A).

### rat
| Drop | Detalle |
|------|---------|
| Material común (20%) | `cola_rata` ×1 (material cuero P1), `hueso_pequeno` ×1 (50/50) |
| Common item (8%) | Pool: `guante_cuero_rata` (+1 DEX), `capucha_rata` cosmético |
| Rare item (2%) | `diente_rata_reina` — flag "vino de pack", requiere matar 3+ en misma run |
| Oro | 1 (5% chance) |

### bird
| Drop | Detalle |
|------|---------|
| Material común (20%) | `pluma_pradera` ×1-2 — material fletching arco P1 |
| Common item (8%) | Pool: `pluma_decorativa` cosmético, `amuleto_viento` (+1 DEX) |
| Rare item (2%) | `pluma_azul` — crafting gate flecha Rare |
| Oro | 0 |

### fox (NEUTRAL)
| Drop | Detalle |
|------|---------|
| Material común (25%) ↑ | `piel_zorro` ×1 — material cuero premium P1. Chance boost por ser cazada activa. |
| Common item (10%) ↑ | Pool: `capa_zorro` cosmético, `bota_zorro` (+1 DEX, +1 DEF) |
| Rare item (4%) ↑ | `cola_zorro` — crafting capa Rare P1 |
| Oro | 2-3 (20% chance) |

**Nota fox**: drop boosteado +5% en cada tier vs sub-A base. Razón: fox es NEUTRAL — matarlo es decisión activa del jugador, no loot gratis del camino. Premia skill expression.

---

## 2. Sub-B — Depredador (wasp, wolf)

Probabilidades base de `p1_economy.md §4 sub-B`:

| Resultado | Chance |
|-----------|--------|
| Nada | 40% |
| Material común (2-3 unidades) | 30% |
| Common item | 20% |
| Rare item | 8% |
| Epic item | 2% |

**Material garantizado adicional**: sub-B dropea `material_pack_liderado` (1 unidad fija, thematic por enemigo) al 100% — INDEPENDIENTE del roll.

### wasp
| Drop | Detalle |
|------|---------|
| Material garantizado (100%) | `aguijón_avispa` ×1 |
| Material común (30%) | `miel_salvaje` ×1-3 — consumible HP regen, o crafting antídoto |
| Common item (20%) | `anillo_veneno_leve` (+1 DMG), `vendaje_miel` consumible |
| Rare item (8%) | `armadura_quitina` (Rare chest, +4 DEF) |
| Epic item (2%) | `reina_avispa_ambra` (+3 DMG, +5% crit) — jackpot moment |
| Oro | 2-5 (50% chance) |

### wolf
| Drop | Detalle |
|------|---------|
| Material garantizado (100%) | `colmillo_lobo` ×1 |
| Material común (30%) | `piel_lobo` ×1-2 — armaduras cuero P1 |
| Common item (20%) | `cuchillo_colmillo` (+2 DMG cuchillo), `capa_lobo` (+2 DEF, +1 STR) |
| Rare item (8%) | `garra_alfa` — crafting gate arma de cuerpo Rare |
| Epic item (2%) | `colmillo_alfa_eterno` (+5 DMG, +2 STR) |
| Oro | 1-3 (40% chance) |

---

## 3. Sub-C — Alfa / Líder (bandit_archer, bandit_melee)

Probabilidades base de `p1_economy.md §4 sub-C`:

| Resultado | Chance |
|-----------|--------|
| Material raro | 40% |
| Common item | 25% |
| Rare item | 25% |
| Epic item | 10% |

**Material raro garantizado adicional**: sub-C dropea `material_identidad` (1 unidad fija, thematic) al 100%. No es el mismo slot que el roll 40% — son dos drops.

### bandit_archer
| Drop | Detalle |
|------|---------|
| Material identidad (100%) | `emblema_bandido` ×1 — quest item, entregable en outpost **[BIND]** |
| Material raro (40%) | `cuerda_arco_bandido` ×1, `flecha_barbada` ×3 (50/50) |
| Common item (25%) | `arco_corto_bandido` (+3 DMG arco), `carcaj_cuero` slot |
| Rare item (25%) | `arco_cazador_bandido` (+5 DMG, +1 DEX) |
| Epic item (10%) | `arco_ojo_aguila` (+7 DMG, +2 DEX, +3% crit) |
| Oro | 5-10 (100%) |

### bandit_melee
| Drop | Detalle |
|------|---------|
| Material identidad (100%) | `emblema_bandido` ×1-2 (líder dropea más) **[BIND]** |
| Material raro (40%) | `hebilla_bandolera` ×1 — material gear identity |
| Common item (25%) | `hacha_bandido` (+3 DMG hacha), `coraza_cuero_tachonada` (+3 DEF) |
| Rare item (25%) | `espada_corta_lider` (+5 DMG, +1 STR), `escudo_madera_reforzado` (+4 DEF, block +10%) |
| Epic item (10%) | **`Corona Oxidada (menor)`** — cosmético + (+2 STR, +5% XP local) — flagged en `tier_1_pool P1 §peligro` **[BIND]** |
| Oro | 8-15 (100%) |

**Nota Corona Oxidada**: `tier_1_pool.md` la menciona como drop del bandit leader (versión menor de la del boss Tier I). Epic drop P1 más icónico — 10% del 10% = 1% efectivo (muy raro), momento de celebración grupal.

---

## 4. Veterano — Drop garantizado

Sub-A/B/C que escapó con <30% HP y volvió. Regla canon `balance_v2 §3.3`.

| Condición | Drop |
|-----------|------|
| Veterano sub-A (ej. "Slime Cicatrizado") | 1 Rare del pool sub-A + entrada codex |
| Veterano sub-B (ej. "Lyra la Tuerta" wolf alfa) | 1 Rare garantizado + 30% upgrade a Epic + entrada codex |
| Veterano sub-C (ej. "Gorok Cicatrizado" bandit) | 1 Epic garantizado + nombre propio flag + entrada codex |

**Item único nombrado**: cada Veterano dropea con sufijo "del Cicatrizado" / "del Tuerto" (nombre propio persiste en seed del bioma). No hay stack — si ya lo tenés del mismo Veterano, convierte a XP bonus +50 o oro. **[BIND]** — va al jugador que dio el killing blow al Veterano, sin entrar al reparto floor+random (regla canon `_drop_ownership_canon.md §5.2`).

---

## 5. Ambushes — loot bonus

Ver §6 de `p1_economy.md` actualizado. Los enemigos en ambush dropean con **+10% roll quality** (resultado bumped 1 tier en la tabla de su sub-tier):

| Roll original | Roll con bump ambush |
|---------------|----------------------|
| Nada | Material común |
| Material común | Common item |
| Common item | Rare item |
| Rare item | Epic item |
| Epic item | Epic item (cap) |

**Razón**: ambush castiga al jugador con daño sorpresa; recompensa al matarlo. Compensación emocional.

---

## 6. Eventos — loot especial

Ver §6 de `p1_economy.md` actualizado. Drops NO provienen de kills — provienen del trigger del evento. **TODOS los drops de evento son `bind_on_drop = TRUE`** (regla canon `_drop_ownership_canon.md §5`): *"Suerte de run = suerte tuya."*

| Tipo evento | Loot típico | Bind |
|-------------|-------------|------|
| POI pacífico (altar, árbol grande) | `Asta Antigua` cosmético pet (trigger específico, ver `tier_1_pool P1 §encuentros_hilo`) | **[BIND]** al trigger player |
| NPC itinerante (Cazador Perdido, mapache) | Quest start, recompensa en siguientes pisos | **[BIND]** al que aceptó quest |
| Fauna pacífica (mariposas, libélulas) | 5% chance material común pradera al interactuar | **[BIND]** al que interactuó |
| Altar principal P3 (referencia cross-piso) | `Bendición de la Hermana` buff temporal | **[BIND]** al invocador |
| Ruinas / diarios lore | Páginas de codex, entradas de bestiario | **[BIND]** al descubridor (persiste cuenta) |

**Los eventos NO cuentan como drop del sub-tier** — son contenido narrativo. Bind-on-drop protege el momento ritual: el jugador que encuentra el altar no pierde el buff porque otro pasó caminando.

---

## 7. Validación contra targets `p1_economy.md`

Expected P1 run clean (~25 min):
- 20 sub-A + 5 sub-B + 1 sub-C
- XP ≈ 369 ✓ matchea economy.md
- **Drops esperados**:
  - 20 sub-A × 30% = 6 drops (≈ 5 material, 1 Common, 0.4 Rare)
  - 5 sub-B × 60% = 3 drops (≈ 2 Common, 1 Rare, 0.3 Epic) + 5 materials garantizados
  - 1 sub-C × 100% = 1 drop + 1 material identidad (Rare+ esperado)
- **Total estimado**: ~10 items (5-6 Common, 2-3 Rare, 0-1 Epic) + ~12 materiales + oro ~40-70 pre-chests.

Sumando chests (§5 economy): run completa entrega ~15-20 items + ~18 materiales + 120-180 oro. Momento "sensación de lluvia de loot" al final del piso — by design.

---

## 8. Bind-on-drop — índice P1

Lista compacta de items `bind_on_drop = TRUE` en P1 (canon `_drop_ownership_canon.md §5`):

| Item | Fuente | Trigger del bind |
|------|--------|------------------|
| `emblema_bandido` | bandit_archer / bandit_melee drop garantizado | Kill ambient + owner asignado canon v2 (killing blow del player, ver `_drop_ownership_canon.md §5.2`) |
| `Corona Oxidada (menor)` | bandit_melee Epic roll (10%) | Kill ambient + owner asignado canon v2 (killing blow del player, ver `_drop_ownership_canon.md §5.2`) |
| Items Veterano (sufijo "del Cicatrizado" / "del Tuerto") | Veterano sub-A/B/C | Last hit al Veterano |
| `Asta Antigua` | Altar POI + trigger específico | Jugador que triggereó |
| Drops de quests NPC | Cazador Perdido, mapache, bardo P5 | Jugador que aceptó quest |
| Material evento fauna pacífica | Mariposas/libélulas al interactuar | Jugador interactor |
| `Bendición de la Hermana` (referencia) | Altar principal P3 | Invocador |
| Páginas codex / entradas lore | Ruinas, diarios | Descubridor (persiste cuenta) |

**Todo lo demás = reparto floor+random sobre pool de la party** (regla default canon v2, sin damage gate, ver `_drop_ownership_canon.md §2`).

---

## 9. Flags a A

1. **Corona Oxidada P1**: `tier_1_pool` la lista. 1% efectivo OK? ¿Subir a 2% para garantizar que ~1 de cada 2 runs un jugador de party lo vea? Decisión ritual. **Resuelta**: sigue 1% (decisión A 2026-04-15, bind-on-drop compensa rareza).
2. ~~**Drop instanced por jugador**~~ → **RESUELTO 2026-04-16**: canon v2 = party-auto pool + floor+random + timers 180/120/300s + bind-on-drop items evento/ritual. Ver `_drop_ownership_canon.md`.
3. **mini_slime anti-farm**: bajé drops a 20% total. Si afecta el feel de la fight boss P24, ajustar.
4. **XP +5% fox boost**: compensa por NEUTRAL. Revisar si conflicta con Diseño ecosistema "no matar todo".

---

## 10. Pendientes (Fase 2+)

- `p1_materials.md` — catalogar los 15+ materiales referenciados (nombre, stack, vendor price, uso crafting).
- Pool completo items Common/Rare P1 — `p1_items.md` con stats concretos.
- Weight tuning intra-pool (cuál Common es más frecuente que otro).
- Tabla de drops piso 24 King Slime (fuera scope P1).
