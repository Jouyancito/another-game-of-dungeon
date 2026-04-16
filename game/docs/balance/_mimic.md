# Mímico — Canon

**Versión**: 1.0
**Fecha**: 2026-04-16
**Estado**: Canon cross-piso. Depto Design establece stats + spawn + drops + achievement. Gameplay (B) implementa state machine; Art (D) implementa mesh/reveal/VFX.
**Depende**: `balance_v2.md §3.1-3.2` (sub-tier B multiplicadores), `_drop_ownership_canon.md` (canon v2 ownership), `_status_effects.md` (status canon), `p1_economy.md §5` (chest loot).
**Referencian**: `p1_loot_table.md §M` (mimic), `game/scenes/loot/loot_chest.gd` (disfraz source), `game/scripts/title_tracker.gd` (achievement).
**Audiencia**: dept Gameplay (B: `mimic.gd` state machine + signals), dept Art (D: mesh + reveal anim + VFX), dept Design (C: esta fuente), dept UI (Journal entry lore).

**Issue**: #60.

---

## 0. Filosofía

El mímico es **una promesa rota**. El cofre enseña "abre, recibís loot". El mímico rompe esa expectativa una vez, y el jugador nunca vuelve a abrir un cofre sin pensar.

Objetivos:
1. **Tensión cognitiva**: cada cofre post-primer-mímico pesa distinto.
2. **Recompensa justa por survivar**: si lo matás, drop superior a cofre normal (feeling "ganaste el juego con él").
3. **Anti-farm**: no re-disguise, no regen, no stack en escena. Un mímico es un evento, no una fuente farmeable.
4. **Humor referencial**: achievement "La Suerte de Frieren" (ref anime Frieren, cofres y mímicos como running gag) cierra el loop con sonrisa.

**Frase-ley**: *"El cofre que te miraba de vuelta."*

---

## 1. Tier y stats canon

### 1.1 Clasificación

- **Sub-tier**: **B** (depredador — per `balance_v2.md §3.1-3.2`).
- **Tipo**: TRAMPA (no fauna, no humanoide). Flag para IA/ecosistema — no aparece en packs, no grupa.
- **Categoría drop**: enemigo sub-B (regla `p1_loot_table.md §2`), **sin** `bind_on_drop` en loot regular. Ver §4.

### 1.2 Stats por piso (derivado canon)

Fórmula: **`mimic_stat(piso) = sub_A(piso) × sub_B_mult`** per `balance_v2.md §3.2`.

| Piso | HP | DMG | DEF | XP base | XP total (+encounter bonus) |
|------|----|----|----|---------|----------------------------|
| 1 | 86 | 8 | 3 | 22 | **42** |
| 10 | 173 | 16 | 14 | 36 | 56 |
| 25 | 400 | 32 | 32 | 60 | 80 |
| 50 | 960 | 72 | 62 | 100 | 120 |
| 75 | 1920 | 136 | 92 | 140 | 160 |
| 100 | 3840 | 248 | 122 | 180 | 200 |

**Encounter XP bonus**: +20 XP flat por matarlo (aplica bono "Descubrir POI nuevo" de `p1_economy.md §3`). Mímico es encuentro excepcional, no kill común.

### 1.3 Resistencias canon

| Tipo | Valor | Razón |
|------|-------|-------|
| Knockback resist | **0.9** | Cofre pesado, anclado. No volar al primer golpe. |
| Stun resist | **0.5** | Tapa cerrada, difícil aturdir. |
| Slow resist | 0.0 | No es rápido, no requiere especial. |
| Resistencias elementales | neutrales (0%) | Sin flavor elemental. Respeta `balance_v2 §resist cap 75%`. |

Knockback/stun están en `_status_effects.md` catálogo global. No se inventa nada.

### 1.4 TTK target

- Sub-B target: **4-6 hits solo / 3-5s coop 4p** (`balance_v2 §4.1`). Sin ajuste.
- En P1 (piso 1): jugador L1 con DMG 57 (Warrior) → 86/57 = 2 hits. Dentro de sweet spot (teniendo en cuenta DMG reducido por DEF 3 = 54 efectivo → 2 hits).

---

## 2. Spawn rules

### 2.1 Gate por piso

| Piso | Chance spawn por `loot_chest` | Condición extra |
|------|------------------------------|-----------------|
| 1 sub-A (arena intro/early) | **0%** | OFF — el jugador está aprendiendo "chest = loot". No romper la lección. |
| 1 sub-B+ (arena con al menos 1 enemigo sub-B spawned) | **5%** | Primera exposición controlada. |
| 2 | 7% | Ramp suave. |
| 3-5 | 8-10% | Pico P1-tier. |
| 6+ | 10% | Steady state. Ajuste futuro por tier. |

**Definición "arena sub-B+"**: arena cuyo spawner incluye al menos 1 enemigo sub-B en el roster. Interpretación operativa para B: flag `arena.has_sub_b_enemies == true` habilita pool mimic en los chests de esa arena.

### 2.2 Cooldown global

- **Máximo 1 mímico activo en escena simultáneo**. Si ya hay uno spawneado (cualquier estado), el siguiente loot_chest spawn roll del mimic falla automáticamente.
- **No re-roll**. Fallado por cooldown = cofre normal spawnea en su lugar.
- **Scope**: escena actual (piso cargado). Al cargar piso nuevo, cooldown resetea.

### 2.3 Restricciones de tipo chest

Mímico **solo puede disfrazarse de chest pequeño** (per `p1_economy.md §5`, el tier más común). Razones:
1. Chest pequeño es el que el jugador abre con más confianza (hay 3 fijos por arena).
2. Chest mediano (40%) y chest grande (15%) tienen visual/posicionamiento distintivo — un mimic mediano rompería la promesa visual más que el valor agregado.
3. Simplifica el disguise visual (1 mesh a copiar, no 3).

**Futuro T2+**: considerar mímicos mediano/grande post-P5 cuando el jugador ya domina el sistema. Documentado pero no implementar.

### 2.4 Posición spawn

- Mímico ocupa la misma posición que un `loot_chest` regular habría ocupado.
- Pool de spawn = mismo pool de spots del spawner procedural de la arena.
- Transform, rotación y escala idénticos a chest pequeño.

---

## 3. Behavior canon

### 3.1 Estados (contrato para state machine — B implementa)

| Estado | Trigger entrada | Duración | Salida |
|--------|-----------------|----------|--------|
| **DISGUISED** | Spawn | Indefinida hasta interact | → REVEALING |
| **REVEALING** | Player interact (E) | 0.4-0.8s (anim reveal, tunning D) | → AGGRESSIVE |
| **AGGRESSIVE** | Fin reveal | Hasta muerte o escape player | → DYING |
| **DYING** | HP ≤ 0 | 1.0s (death anim + loot drop) | → liberado |

### 3.2 Reglas estado DISGUISED

- **Indistinguible visualmente** de `loot_chest` normal del tier pequeño. Mesh, material, label `Cofre [E]`, outline interactable — todo idéntico.
- **No emite sonido propio**. No tiene "tell" audio que lo delate.
- **No se mueve**. No idle sway.
- **Tooltip idéntico** al del chest normal.
- **Reveal trigger único**: interact (E) del player dentro de `interaction_range = 2.5` (matchea `loot_chest.gd`).
- **Inmune a daño en DISGUISED**. No se puede "matar desde lejos" — eso rompe el gag.

### 3.3 Reglas estado REVEALING

- Anim de reveal: tapa se abre violentamente, mesh transiciona de chest a criatura. VFX por D (reveal particle + sound stinger).
- **Target lock**: el jugador que hizo interact queda marcado como `aggro_target`. Persiste toda la vida del mímico salvo muerte o escape de rango (§3.5).
- **Daño empieza a recibir al 100% fin reveal** (no durante anim). Anti-cheese: no se puede matar mid-reveal.

### 3.4 Reglas estado AGGRESSIVE

- **Persigue al `aggro_target`**. No cambia de target salvo que el target muera (→ re-target a cualquier player en rango).
- **No regenera HP**. `regen_rate = 0`. Intencional — recompensa chip damage.
- **No se re-disguise**. Una vez revelado, siempre revelado. Incluso si escapa y vuelve, sigue visible.
- **Velocidad**: sub-B baseline (`balance_v2`). Acelera leve al aggro (≈ 1.15x), sin ser hunter.
- **Ataque**: melee sub-B canon (mordida tapa). Área frontal cono 1.5m, DMG per §1.2.

### 3.5 Escape y timeout (opcional — ajuste futuro)

Por P1, **sin escape**. Mímico persigue hasta muerte o player muerte.

Reservado para T2+ (no implementar P1):
- Si `aggro_target` sale de rango visual > 25m por > 20s → mímico vuelve a spawn point.
- NO re-disguise al volver.
- Mímico en idle post-escape mantiene posición y sigue hostil a cualquiera que se acerque.

### 3.6 Muerte

- **No drop durante AGGRESSIVE**. Drops solo al morir (DYING).
- **Death animation**: 1s — colapsa, tapa abre, "escupe" drops en dispersión radial canon (ver `_drop_ownership_canon.md §0` y loot_chest emit).
- **Ownership**: drops siguen canon v2 ownership — party-first pool + floor+random + timer 180/120/300s. **No bind** (items del mimic son loot regular).
- **Despawn del cadáver**: 3s post-death para dar tiempo a pickup / ver VFX. Drops permanecen según timer canon.

---

## 4. Drops canon

### 4.1 Regla general

Al morir un mímico, se resuelve **un roll de tier sub-B elevado** + **oro 2x chest pequeño** + **material flag**. Todo entra al reparto floor+random canon v2 (sin bind, a menos que se indique).

### 4.2 Tabla drops mimic (piso 1)

| Slot | Garantía | Contenido |
|------|----------|-----------|
| **Item principal** | 100% | 1 item rareza **≥ Rare**, tabla §4.3 |
| **Oro** | 100% | 20-50 oro (2× chest pequeño P1, ver `p1_economy.md §5`) |
| **Material flag** | 100% | `dentellada_mimica` ×1 — crafting gate futuro + prueba del kill |
| **Drop extra (Legendary roll)** | 5% | Legendary item (en P1 **sustituido por Epic**, regla `p1_economy.md §5`) |

### 4.3 Roll item principal (skew Rare+)

| Resultado | Chance | Notas |
|-----------|--------|-------|
| Rare item | **60%** | Pool gear sub-B Rare del piso actual (`p1_loot_table.md §2` pool Rare wolf/wasp). |
| Epic item | **35%** | Pool gear sub-B Epic del piso. |
| Legendary item | **5%** | Sustituido por Epic en P1 (regla p1_economy §5 "NO Legendary en P1"). Activo de verdad piso T2+. |

**Total rolls esperados**: ~75% Epic (Rare 60% + Epic 35% + "Leg→Epic" en P1 = 95% rare-or-better). Es un jackpot por survivar.

### 4.4 Bind-on-drop — NO (por defecto)

Los drops de mímico **no son bind**. Razón: el mímico no es evento ritual, es sub-B con twist. Canon ownership v2 estándar.

**Excepción futura**: si en el futuro se decide que el item Legendary del mímico (5% roll) sea bind (para momento "tuyo por haberlo matado"), se evalúa en ese momento. Por ahora **no**.

### 4.5 Pergamino Auto-Revive (cross-ref futuro)

Relacionado con **issue #55 backlog** (downed state + revive, fuera scope P1 — ver engram decision 2026-04-16).

- Cuando exista downed state, se introducirá item consumible **`Pergamino Auto-Revive`** (rare consumible).
- **Mímico podría dropearlo en chance baja** (~2-3% drop extra) — feel "recompensa narrativa" por matar al cofre.
- **No implementar P1**. Solo reserva de schema — B puede dejar slot en `loot_table.gd` flagged `if auto_revive_enabled`.

---

## 5. Achievement — "La Suerte de Frieren"

### 5.1 Definición

| Campo | Valor |
|-------|-------|
| **Key** | `frieren_luck` |
| **Nombre display** | "La Suerte de Frieren" |
| **Descripción** | "Tu primer mímico. Frieren estaría orgullosa." |
| **Trigger** | `tracker_stats.mimics_killed == 1` (primer mímico matado cuenta persistente del personaje) |
| **Reward** | Entrada en `Journal` (lore + flavor text, ver §5.3). Sin gameplay reward — puro flavor. |
| **Anti-cheese** | No aplica. Primer mímico es primer mímico. Counter persiste en save del personaje, no se resetea por run. |

### 5.2 Flavor — lore entry Journal

**Título**: "La Suerte de Frieren"
**Body**:
> Frieren, la maga milenaria, abre cada cofre con la fe inquebrantable de que ESTE sí va a darle un tesoro. Siempre la muerde un mímico. Siempre.
>
> Vos también. Pero vos ganaste.
>
> *(ref: Sousou no Frieren — el running gag del cofre-mímico recurrente.)*

Entry persiste en Journal del personaje. Cosmético puro.

### 5.3 Integración — contrato para B

**No implementar código** (eso es B). Este canon define **el contrato**:

1. **Agregar entry en `game/scripts/title_tracker.gd` TITLES const**:
   ```
   "frieren_luck": {
       "name": "La Suerte de Frieren",
       "desc": "Tu primer mímico. Frieren estaría orgullosa.",
   },
   ```

2. **Contador en stats**: `tracker_stats.mimics_killed` (int, persiste per-character).

3. **Nueva función público en title_tracker**:
   ```
   func on_mimic_killed() -> void:
       var stats := _get_stats()
       stats["mimics_killed"] = stats.get("mimics_killed", 0) + 1
       _save_stats(stats)
       if stats["mimics_killed"] == 1:
           _grant("frieren_luck")
   ```

4. **Emisión del hook**: `mimic.gd` emite `mimic_died(mimic)` → listener en `TitleTracker.on_mimic_killed()`.

5. **Journal entry**: Dept UI agrega lore §5.2 al `Journal` UI al recibir `title_unlocked("La Suerte de Frieren", ...)`.

---

## 6. Integración cross-dept

### 6.1 Signals — contrato B emite, C/D consumen

| Signal | Emisor (B) | Payload | Consumers |
|--------|-----------|---------|-----------|
| `disguise_revealed(mimic)` | `mimic.gd` al entrar REVEALING | `mimic: Node3D` (self) | D (VFX reveal), UI (sonido stinger) |
| `mimic_died(mimic)` | `mimic.gd` al entrar DYING | `mimic: Node3D` (self) | C (→ `TitleTracker.on_mimic_killed()`), D (death VFX), DropController (loot drop) |

### 6.2 Hooks que C documenta pero B implementa

- `TitleTracker.on_mimic_killed()` — agregar listener en `_ready()` de TitleTracker o conectar en spawner.
- `LootTable.resolve_mimic_drops(mimic, floor_n)` — función que devuelve Array de drops según §4.2. Tabla markdown abajo (§7) para que B traslade literal.

### 6.3 Archivos afectados

- **Nuevos** (B/D crean):
  - `game/scenes/enemy/mimic.gd` — state machine (B)
  - `game/scenes/enemy/mimic.tscn` — scene con mesh chest + mesh criatura (D)
  - `game/assets/art/...` — mesh criatura + reveal anim + VFX scenes (D)
- **Modifica**:
  - `game/scripts/title_tracker.gd` — entry `frieren_luck` + `on_mimic_killed()` (B)
  - `game/shared/systems/loot_table.gd` — entry `mimic` drop table (B, derivado de §7)
  - `game/docs/balance/p1_loot_table.md` — sección Mímico (C, este commit)
  - `game/scenes/ui/journal_ui.gd` — lore entry (UI futuro)

---

## 7. Tabla markdown — entry `loot_table.gd` mimic

**Formato canon para que B traslade literal a `loot_table.gd`**. No es código, es la tabla que alimenta al dict de drops.

```
# pseudo-entry para loot_table.gd
MIMIC_DROPS = {
    "gold_range": [20, 50],                 # 2× chest pequeño P1 (§4.2)
    "material_guaranteed": {
        "id": "dentellada_mimica",
        "count": 1,
    },
    "item_principal_roll": {
        "chances": [
            {"rarity": "rare", "chance": 0.60},
            {"rarity": "epic", "chance": 0.35},
            {"rarity": "legendary", "chance": 0.05},  # En P1 → Epic (regla p1_economy §5)
        ],
        "pool_source": "sub_b_loot_pool_piso_{N}",   # reuse pool sub-B del piso actual
    },
    "bind_on_drop": false,                  # canon ownership v2 estándar
    "pergamino_auto_revive_slot": null,     # reserva futura issue #55 (NO P1)
}
```

**Escalado por piso**: `gold_range` escala × chest pequeño del piso cuando se decida curva chest multi-piso. Por ahora P1 = 20-50.

---

## 8. Restricciones — NO hacer

Flags explícitas de diseño canon:

1. **NO re-disguise**. Un mímico revelado no vuelve a ser cofre. Romper esto convierte el mímico en pesadilla anti-fun.
2. **NO pack / grupo**. Mímico es solitario. No spawn en pair, no coop con otros enemies.
3. **NO regen HP** en AGGRESSIVE. Chip damage debe ser viable.
4. **NO daño pre-reveal**. Inmune durante DISGUISED a evitar cheese ranged "tiro a todos los chests".
5. **NO loot duplicable**. Si ya dropeó drops, no hay segundo ciclo (ej revive ⇒ sin drops segunda muerte).
6. **NO legendary real en P1**. Regla global `p1_economy.md §5`.
7. **NO mimic mediano/grande en P1**. Solo pequeño (§2.3).

---

## 9. Edge cases

### 9.1 Player muere durante AGGRESSIVE
- Mímico re-targeta al siguiente player en rango (si hay coop).
- Si no hay más players → mímico queda en idle en spawn position, HOSTIL a cualquiera que se acerque.
- No desaparece, no re-disguise.

### 9.2 Mímico escapa del rango arena
- No aplica — mímico no tiene escape behavior en P1 (§3.5).
- Si en futuro se activa escape/timeout, NO re-disguise al volver.

### 9.3 Player interactúa con mímico sin party → muere
- Canon v2 ownership: kill solo → solo killer owner. Si killer muere, mímico vivo → re-target. Si no hay más players y killer estaba solo → idle hostil (§9.1).
- Drops en caso de kill posterior: siguen regla canon solo-killer.

### 9.4 Múltiples players interactúan con el chest (race)
- Primer `interact(E)` gana. Trigger atómico en B.
- Subsiguientes interacts durante REVEALING → ignorados.
- `aggro_target` = primer player.

### 9.5 Mímico spawnea en arena donde el spawner falló sub-B
- Gate §2.1 requiere `arena.has_sub_b_enemies == true`.
- Si flag mal-seteado y spawnea sin enemies sub-B efectivos → funciona, pero B debe asegurar que el flag solo se activa post-spawn de sub-B real.

### 9.6 Save/load mid-fight
- `mimic.gd` serializa estado (DISGUISED / AGGRESSIVE) + HP actual.
- Reload: si en AGGRESSIVE, resume AGGRESSIVE en posición guardada, mismo aggro_target (por save_profile_id).
- No hay "reset a DISGUISED" por save.

---

## 10. Decisiones registradas

| Decisión | Fecha | Razón |
|----------|-------|-------|
| Sub-tier B canon puro (sin boost especial) | 2026-04-16 | No inventar mecánicas. Resistencias knockback/stun cubren el "cofre pesado". |
| Encounter XP bonus +20 flat | 2026-04-16 | Aplicar bono "Descubrir POI" de `p1_economy.md §3`. Mímico es encuentro excepcional. |
| Spawn 0% en arenas sub-A P1 | 2026-04-16 | Proteger lección "chest = loot gratis" primera hora. |
| Max 1 mímico activo en escena | 2026-04-16 | Anti-stack + preservar momento "especial". |
| Solo disguise de chest pequeño | 2026-04-16 | Simplicidad visual + pool más abundante. |
| Drops no-bind | 2026-04-16 | Mímico es sub-B con twist, no evento ritual. |
| Legendary 5% slot → Epic en P1 | 2026-04-16 | Respeta regla `p1_economy §5` "NO Legendary en P1". |
| Achievement trigger en primer kill (no primer encuentro) | 2026-04-16 | "Survivar" es la parte que cuenta, no "abrir". Consistente con flavor Frieren. |
| Pergamino Auto-Revive como slot reservado | 2026-04-16 | Cross-ref issue #55 downed state futuro. No implementar P1. |
| No re-disguise, no pack, no regen | 2026-04-16 | Anti-farm + protección de fun. |

---

## 11. Pendientes

- Schema Pergamino Auto-Revive cuando se implemente downed state (issue #55).
- Pool gear sub-B Rare/Epic piso-específico — ya existe en `p1_loot_table.md §2` para P1; futuros pisos necesitarán pool propio.
- Visual disguise audit por D (asegurar mesh chest pequeño idéntico pixel-perfect).
- Tuning final de spawn chance por piso (valores §2.1 son estimados iniciales — requiere playtest).
- Considerar mímicos mediano/grande T2+ post-P5.
- Decidir si Legendary drop del mímico (cuando T2+ lo habilite) será bind-on-drop especial o canon regular.
