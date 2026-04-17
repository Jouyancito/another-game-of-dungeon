# Warrior — Skill Set Canon

> Lore + identidad cultural: ver `game/docs/lore/_class_lore_warrior.md`

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0 (modelo viejo XP por uso + Maestría drop, descartado).
**Depende**: `_system.md` (reglas sistema, gating, recursos, aliases), `_status_effects.md` (catálogo status), `balance_v2.md` (fórmulas, resist cap, armor_reduction_v2), `class_skills.md` (histórico — deprecated).
**Class mult físico**: 1.5 | **Base stats**: STR 12 / VIT 10 / DEF 10 / INT 3 / DEX 6
**Recurso único**: **Rage** (además de MP universal) — ver §1.

---

## 0. Identidad

Warrior es la roca del grupo. Aguanta, tauntea, devuelve golpes pesados. Dos ramas abren direcciones opuestas: **Tank** (fortaleza, control de aggro, protección de aliados) y **Berserker** (riesgo = reward, furia que sube con daño recibido).

---

## 1. Recurso único — Rage

Canon `_system.md` §5ter. Resumen operativo:

- Cap 100, **no regenera por tiempo**
- Gana: +5 por hit conectado, +10 por cada 10% HP perdido recibido
- Decae 5/s tras 8s sin combate
- Gasta: skills ofensivas pesadas (Giro de Espada, Forma del Titán, Furia Berserk)
- MP gasta: skills utility (Embestida, Bloqueo Perfecto, Grito)
- **Rama Berserker**: Rage ≥80% → +30% DMG pasivo mientras supere el umbral

Regla: ninguna skill "fijada 1-4" del hotbar gasta rage exclusivamente salvo la ultimate y la skill 2H. Rage es el knob que premia sostener combate agresivo.

---

## 2. Pool total (10 skills fase prototipo)

Target fase prototipo: **10 skills** (§6 `_system.md`). 4 generales (core identidad) + 3 exclusivas rama Tank + 3 exclusivas rama Berserker.

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Puño de Guerra | general | — | char lvl 1 | `[physical][melee][single][strike]` |
| 2 | Embestida | general | — | char lvl 4 | `[physical][mobility][single][stun]` |
| 3 | Grito de Guerra | general | — | char lvl 8 | `[aura][buff][debuff][fear]` |
| 4 | Bloqueo Perfecto | general | — | char lvl 12 | `[physical][reactive][parry][stun]` |
| T1 | Postura de Muralla (pasiva) | rama | Tank | char lvl 25 | `[passive][defensive]` |
| T2 | Escudo Vengador | rama | Tank | char lvl 30 | `[physical][melee][taunt][AoE]` |
| T3 | Último Bastión (oculta) | rama quest | Tank | char lvl 50 + quest | `[physical][reactive][invul][aura]` |
| B1 | Giro de Espada | rama | Berserker | char lvl 25 | `[physical][AoE][rage_spend]` |
| B2 | Forma del Titán (ult) | rama | Berserker | char lvl 30 | `[physical][ultimate][transform]` |
| B3 | Sangre que Llama Sangre (oculta) | rama quest | Berserker | char lvl 50 + quest | `[physical][channel][lifesteal]` |

**Gating detallado** (`_system.md` §2):
- Generales char lvl 1, 4, 8, 12 → 4 slots core disponibles antes del lvl 25
- Rama selection char lvl 25 → abre set de 3 skills exclusivas por rama (lvl 25, 30, 50-con-quest)
- Evolución lvl 15 skill + char lvl 50 → ítem raro desbloquea forma alterna (§3)

---

## 3. Skills generales (las 4 core, ambas ramas acceden)

### SKILL 1 — Puño de Guerra
Ataque básico de puño. Identidad "el primer golpe que todos reciben en la cara".

- **Tags**: `[physical][melee][single][strike]`
- **Tipo**: activa melee | **Costo**: 0 MP | **Rage gen**: +5 hit | **CD**: animación (0.5s) | **Rango**: `MELEE_SHORT` (2m, cono 60°)
- **Fórmula**: `physical_v2(15, weapon_dmg, STR_total, level, 1.5)`
- **Escalado cuant** (lvl 1→15, canon `_system.md` §2.1): poder 100% → 212% compound
- **Lvl 5**: crit chance +10%
- **Lvl 10**: knockback 2m en hit
- **Lvl 15**: aplica `Bleed` (`_status_effects.md §2.1`) 5s en crit. **Forma base — cap**.
- **Evolución (lvl 15 + char 50 + ítem *Gauntlet del Titán*)**: **Puño del Titán** — cada 3er golpe dispara onda sísmica `AOE_SMALL` (3m radio, 50% dmg base, aplica `Stun` 0.5s).
- **Acuática**: **Puño de Marea** — shockwave radial 3m (`systems_v2 §1.5`). Compat.

### SKILL 2 — Embestida
Gap-closer que fija el inicio del encuentro.

- **Tags**: `[physical][mobility][single][stun]`
- **Tipo**: activa dash ofensivo | **Costo**: 10 MP | **CD**: 8s | **Cast**: 0.2s | **Rango**: dash 6m
- **Fórmula**: `physical_v2(20, 0, STR_total, level, 1.3)` | aplica `Stun` 0.8s (`_status_effects.md §2.2`)
- **Lvl 5**: stun 1.2s
- **Lvl 10**: atraviesa hasta 3 enemigos (stun a cada uno)
- **Lvl 15**: super-armor durante el dash (inmune a interrupts). **Forma base — cap**.
- **Evolución (+ ítem *Cuerno del Jabalí Blindado* boss P50)**: **Carga del Jabalí** — dist 10m, al impactar genera escudo temporal 200 HP absorbe-dmg (decae 10s).
- **Acuática**: **Arpón de Placaje** — lanza cadena, arrastra 4m al enemigo hacia vos.

### SKILL 3 — Grito de Guerra
Aura de presencia. Buffa aliados, intimida enemigos.

- **Tags**: `[aura][buff][debuff][fear]`
- **Tipo**: toggle aura | **Costo**: 20 MP cada 5s activo | **CD**: 0s | **Rango**: `AOE_LARGE` (10m radio)
- **Efecto base**: aliados +15% DMG saliente, enemigos `Weak` (-25% DMG saliente, `_status_effects.md §2.3`)
- **Lvl 5**: radio +2m
- **Lvl 10**: aliados inmunes a `Fear`
- **Lvl 15**: enemigos tier sub-A reciben `Fear` 3s al entrar al aura. **Forma base — cap**.
- **Evolución (+ ítem *Corazón de León* evento Tier III)**: **Rugido del León** — aliados ganan `Haste` 5s al activar, cooldown de re-activación 20s.
- **Acuática**: funciona igual pero radio reducido a 6m.

### SKILL 4 — Bloqueo Perfecto
Parry. Identidad tank-capable incluso pre-rama.

- **Tags**: `[physical][reactive][parry][stun]`
- **Tipo**: reactiva (ventana) | **Costo**: 0 MP | **Rage gen**: +10 en parry exitoso | **CD**: 4s | **Ventana activa**: 0.4s tras apretar
- **Efecto base**: dentro de ventana absorbe 100% del próximo golpe + refleja 50% dmg + `Stun` 0.5s al atacante
- **Fórmula reflejo**: `physical_v2(raw_blocked * 0.5, 0, STR, level, 1.0)`
- **Lvl 5**: ventana 0.6s
- **Lvl 10**: absorbe 2 golpes consecutivos dentro de ventana extendida (0.8s)
- **Lvl 15**: aliados detrás del Warrior (cono 90° 4m) reciben `Shield` 40 HP temporal 3s tras bloqueo exitoso. **Forma base — cap**.
- **Evolución (+ ítem *Muralla Divina* boss P50)**: **Muralla Divina** — refleja 100% dmg + aliados detrás inmunes 1s.

---

## 4. Rama Tank (char lvl 25+) — fortaleza de grupo

### T1 — Postura de Muralla (pasiva única rama)
- **Tags**: `[passive][defensive]`
- **Desbloqueo**: al elegir rama Tank, lvl 25
- **Efecto base**: con Escudo 1H equipado, +50% block chance + 20% DEF total mientras Bloqueo Perfecto esté en ventana
- **Escalado por skill points**: cada lvl +2% DEF total cap (nivel 15 = +50% DEF). Pasiva AoE aplica al Warrior solamente (no a aliados).
- **Evolución (+ ítem *Piedra del Rey Montaña* boss P75)**: la pasiva pasa a aplicar +10% DEF a aliados en 8m mientras Bloqueo esté en ventana.

### T2 — Escudo Vengador
Skill activa de rama Tank.

- **Tags**: `[physical][melee][taunt][AoE]`
- **Desbloqueo**: rama Tank lvl 30
- **Tipo**: activa AoE frontal | **Costo**: 15 MP | **CD**: 12s | **Cast**: 0.4s | **Rango**: `MELEE_LONG` (3m, cono 90°)
- **Fórmula**: `physical_v2(30, weapon_dmg*0.5, STR, level, 1.4)`
- **Efecto base**: golpe con escudo aplica `Taunt` 3s a todos los enemigos impactados
- **Lvl 5**: taunt 4s
- **Lvl 10**: refleja 30% dmg recibido durante taunt
- **Lvl 15**: genera `Shield` 150 HP sobre el Warrior al impactar al menos 1 enemigo. **Forma base — cap**.

### T3 — Último Bastión (skill oculta ascendencia — quest-gated)
Canon `_system.md` §5bis. Skill de identidad profunda.

- **Tags**: `[physical][reactive][invul][aura]`
- **Trigger quest**: completar piso 50 sin que ningún aliado muera en tu radio 8m (`_system.md §5bis` table)
- **Quest**: *"El Muro Inquebrantable"* — hablar con NPC safe zone P50
- **Tipo**: reactiva pasiva | **Costo**: trigger automático al recibir golpe letal | **CD**: 300s
- **Efecto base**: al recibir daño letal quedás en 1 HP con `Invul` 3s, aliados en `AOE_MEDIUM` (6m) +50% DEF durante los 3s
- **Lvl 5**: aliados +60% DEF
- **Lvl 10**: Warrior también recupera 30% HP al expirar la invul
- **Lvl 15**: los aliados reciben también `Empower` 8s tras el evento. **Forma base — cap**.
- **Evolución (no hay — ya es la forma épica de la rama)**

---

## 5. Rama Berserker (char lvl 25+) — riesgo compound

### B1 — Giro de Espada
Skill activa 2H AoE, gasta Rage.

- **Tags**: `[physical][AoE][rage_spend]`
- **Desbloqueo**: rama Berserker lvl 25 (requiere Espadón 2H)
- **Tipo**: activa AoE | **Costo**: 15 MP + 30 Rage | **CD**: 6s | **Cast**: 0.6s | **Rango**: `AOE_SMALL` (3m radio)
- **Fórmula**: `physical_v2(30, weapon_dmg*1.2, STR, level, 1.5)` — hit único
- **Lvl 5**: radio 3.6m
- **Lvl 10**: el giro dura 2s (2 hits, CD pasa a 9s)
- **Lvl 15**: cada enemigo impactado suma +5 Rage al Warrior (recupera parte del costo). **Forma base — cap**.
- **Evolución (+ ítem *Huracán de Acero* Tier III)**: **Huracán de Acero** — giro canalizado 4s (consume 5 Rage + 5 MP/s), radio 4.5m.

### B2 — Estilo de Hierro: Forma del Titán (ULTIMATE)
- **Tags**: `[physical][ultimate][transform]`
- **Desbloqueo**: rama Berserker lvl 30
- **Tipo**: ultimate transformación | **Costo**: 60 MP + 50 Rage | **CD**: 90s | **Cast**: 1.5s (nombre visible canon brief §3)
- **Duración**: 12s
- **Efecto base**: +50% DMG físico, +50% DEF, -30% velocidad, inmune a `Knockback`/`Stun`/`Fear`
- **Lvl 5**: duración 14s
- **Lvl 10**: +60% DEF
- **Lvl 15**: al activar restaura 30% HP. **Forma base — cap**.
- **Evolución (+ ítem *Titán Inmortal* boss P75)**: **Titán Inmortal** — si morís durante buff → revivís 1 vez con 25% HP. 1 uso por run.

### B3 — Sangre que Llama Sangre (skill oculta ascendencia — quest-gated)
- **Tags**: `[physical][channel][lifesteal]`
- **Trigger quest**: matar 50 enemigos con <20% HP propio (`_system.md §5bis`)
- **Quest**: *"Sangre que Llama Sangre"* — evento P45
- **Tipo**: canalizada lifesteal | **Costo**: 40 MP + drain 2% HP/s self | **CD**: 60s | **Cast**: continuo | **Rango**: `MELEE_LONG`
- **Fórmula/tick (0.3s)**: `physical_v2(18, weapon_dmg*0.7, STR, level, 1.5) * 0.3`, **lifesteal 80% del dmg causado**
- **Efecto base**: cuanto más bajo el HP del Warrior, más dmg +1% por cada 1% HP perdido (cap +50% a 0 HP)
- **Lvl 5**: drain self 1.5% HP/s (más sustentable)
- **Lvl 10**: golpes aplican `Bleed` stackeable x3
- **Lvl 15**: al romper el canal con al menos un kill, `Haste` 6s. **Forma base — cap**.

---

## 6. Sinergias coop (extracto — matriz completa en `_synergies.md`)

| Con | Combo |
|-----|-------|
| Mage | Mage Furia Elemental Fuego sobre enemigos con `Taunt` del Warrior → el Warrior recibe menos golpes, los enemigos arden mientras pegan. |
| Archer | Archer aplica `Marked` → Embestida apunta al target marcado = `Stun` + dmg crit garantizado. |
| Necromancer | Invocaciones + Grito de Guerra = el buff +15% DMG aplica a las invocaciones. |
| Cleric Buffer | Aura de Resguardo + Forma del Titán = resist cap 80% + DEF 50% + invul 1× muerte (con evolución) = tanque absoluto vs boss. |
| Danzante | Danzante stealth + Grito = enemigos con `Fear` rompen stealth check, Danzante backstab crit. |

---

## 7. FX visual (ref)

- Puño de Guerra: shockwave tierra low-poly naranja (Demon Slayer Pilar de Piedra)
- Embestida: trail de polvo amarillo (One Piece Gear Second)
- Grito de Guerra: onda sonora concéntrica dorada (JJK Domain preview)
- Bloqueo Perfecto: flash blanco + grieta en el escudo
- Escudo Vengador: impacto con runas rojas de taunt
- Último Bastión: pilar de luz dorada que baja sobre el Warrior, expansión aura en anillo
- Giro de Espada: trail circular de acero + chispas
- Forma del Titán: aura piedra/hierro envolvente, vapor al activar (Demon Slayer Gyomei)
- Sangre que Llama Sangre: trail rojo sangre, grietas rojas en el Warrior, glow creciente al bajar HP

---

## 8. Tabla rápida — costos y CDs

| Skill | MP | Rage | CD | Gate char |
|-------|----|------|----|-----------|
| Puño de Guerra | 0 | +5 gen | anim | 1 |
| Embestida | 10 | +5 gen | 8s | 4 |
| Grito de Guerra | 20/5s | — | toggle | 8 |
| Bloqueo Perfecto | 0 | +10 gen/parry | 4s | 12 |
| Escudo Vengador (T) | 15 | — | 12s | 30 (Tank) |
| Último Bastión (T) | — auto | — | 300s | 50 + quest |
| Giro de Espada (B) | 15 | -30 | 6s | 25 (Berserk) |
| Forma del Titán (B) | 60 | -50 | 90s | 30 (Berserk) |
| Sangre que Llama Sangre (B) | 40 + HP drain | — | 60s | 50 + quest |

---

## 9. Deprecated

Contenido de warrior.md v1.0 (2026-04-14):
- "Escalado 1-5 + Maestría por drop" — descartado (canon `_system.md` §7, cap 15 + evolución)
- "XP por uso de skill" — descartado (canon, skill points por nivel char)
- Modelo "4 fijas + 2 variables" — reemplazado por "generales + rama" (`_system.md` §1)

Los nombres de skills originales (Puño de Guerra, Embestida, Grito, Forma del Titán, Bloqueo, Giro de Espada) se preservan como base del pool general y rama.

---

*Canon Warrior v2.0. Cualquier ajuste se versiona aquí primero y se propaga a `_system.md` si afecta reglas del sistema.*
