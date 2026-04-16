# Cleric — Skill Set Canon

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0.
**Depende**: `_system.md`, `_status_effects.md`, `balance_v2.md` (Aura Resguardo +5% resist cap canon §2.6).
**Class mult**: 1.2 heal / 1.1 dmg | **Base stats**: INT 11 / STR 5 / DEX 5 / DEF 7 / VIT 8
**Recurso único**: **Fe** — ver §1.

**Nota excepción**: Cleric tiene **3 ramas** (Sanador / Buffer / Exorcista) — única clase con 3 ascendencias. Canon documentado en `_system.md §7` y `balance_v2 §2.6`.

---

## 0. Identidad

Cleric es el soporte del grupo. No es pasivo: la **Fe** le obliga a participar (heals, buffs, cleanses) para generar el recurso que alimenta skills poderosas. Tres ramas definen filosofía del apoyo:

- **Sanador**: heals directos + regen, "mantener el grupo vivo"
- **Buffer**: pre-empoderar aliados + Aura Resguardo (canon balance_v2), "hacer al grupo inmortal"
- **Exorcista**: daño sagrado vs undead/void + cleanse agresivo, "apoyo ofensivo"

---

## 1. Recurso único — Fe

Canon `_system.md §5ter`:

- Cap **50** (más chico que Rage/Concentración — cada punto pesa)
- **No regenera por tiempo**
- Generación (coop = principal):
  - Heal efectivo a aliado: **+3**
  - Buff a aliado: **+2**
  - Cleanse a aliado: **+5**
- Generación (solo-viable, valores reducidos):
  - Heal a sí mismo: +1
  - Buff a sí mismo: +1
  - Ataque básico vs cualquier enemigo: +0.5
  - Hit con Verso del Exorcismo vs undead: +1
- **Plegaria** (skill general lvl 4): canal 3s estacionario, regen 15 Fe, CD 20s, interrumpible
- Gear uniques: afixes `+Fe regen/s`, `+% Fe generada por heals`
- Gasta: skills sagradas poderosas (Juicio Sagrado, Resurrección, Égida Divina)
- MP gasta: skills básicas (Luz Restauradora, Círculo Sagrado)

---

## 2. Pool total (14 skills — excepción Cleric 3 ramas)

Canon `_system.md §7`: Cleric mantenida con 3 ramas. Pool más grande que target 10-12 para cubrir las 3 direcciones sin diluir.

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Luz Restauradora | general | — | 1 | `[holy][heal][single]` |
| 2 | Plegaria | general | — | 4 | `[channel][faith_gen]` |
| 3 | Círculo Sagrado | general | — | 8 | `[holy][heal][AoE][channel]` |
| 4 | Égida Divina | general | — | 12 | `[holy][shield][buff]` |
| 5 | Juicio Sagrado (ult) | general | — | 20 | `[holy][ultimate][revive/dmg]` |
| S1 | Gracia Infinita (pasiva) | rama | Sanador | 25 | `[passive][heal_crit]` |
| S2 | Toque Vital | rama | Sanador | 30 | `[holy][heal][cleanse]` |
| S3 | Gracia Perpetua (oculta) | rama quest | Sanador | 50 + quest | `[holy][revive][AoE]` |
| B1 | Aura de Resguardo (pasiva) | rama | Buffer | 25 | `[passive][aura][resist]` |
| B2 | Verso del Guardián | rama | Buffer | 30 | `[holy][buff][empower]` |
| B3 | El Guardián Silencioso (oculta) | rama quest | Buffer | 50 + quest | `[holy][aura][invul]` |
| X1 | Luz Sagrada (pasiva) | rama | Exorcista | 25 | `[passive][holy_dmg][anti-undead]` |
| X2 | Verso del Exorcismo | rama | Exorcista | 30 | `[holy][debuff][silence]` |
| X3 | Luz sobre Voidsign (oculta) | rama quest | Exorcista | 50 + quest | `[holy][AoE][banish]` |

---

## 3. Skills generales

### SKILL 1 — Luz Restauradora
Heal directo básico. Sin esto no hay Cleric.

- **Tags**: `[holy][heal][single]`
- **Tipo**: heal directo target único (incluye self) | **Costo**: 15 MP | **Fe gen**: +3 aliado / +1 self | **CD**: 1.5s | **Cast**: 0.4s | **Rango**: `ALLY_RANGED` 20m
- **Fórmula heal**: `(25 + INT*2) * (1 + level*0.03) * 1.2`
- **Lvl 5**: CD 1.2s, aplica `Regen` 3% HP/s por 4s post-heal
- **Lvl 10**: heal crítico 30% chance (×1.5)
- **Lvl 15**: overheal se convierte en `Shield` temporal 3s (hasta 50 HP cap). **Forma base — cap**.
- **Evolución (+ ítem *Luz del Alba* boss P50)**: heals críticos stackean `Regen`; target puede acumular 3 capas.
- **Acuática**: **Burbuja Vivificante** — heal + `Shield` temporal 30 HP.

### SKILL 2 — Plegaria
Canal estacionario que regenera Fe. Knob que obliga al Cleric a gestionar positioning.

- **Tags**: `[channel][faith_gen]`
- **Tipo**: canal estacionario | **Costo**: 0 MP | **Fe gen**: +15 tras 3s de canal | **CD**: 20s | **Cast**: 3s (interrumpible)
- **Efecto base**: canal 3s sin moverse ni recibir daño. Si se rompe, regen proporcional (ej: interrumpido a 2s = 10 Fe).
- **Lvl 5**: canal 2.5s
- **Lvl 10**: durante canal `Shield` 30 HP absorbe-dmg (si rompe el shield, sigue el canal)
- **Lvl 15**: al completar, aliados en 10m reciben +5 Fe cada uno (si son Cleric del grupo — multi-cleric raro pero soportado). **Forma base — cap**.

### SKILL 3 — Círculo Sagrado
Zona heal canalizada + anti-undead.

- **Tags**: `[holy][heal][AoE][channel]`
- **Tipo**: heal AoE canalizado | **Costo**: 15 MP/s | **Fe gen**: +1 por aliado heal/tick | **CD**: 5s post-canal | **Rango**: `AOE_MEDIUM` 6m centrado en caster
- **Efecto base**: tick cada 0.5s, heal aliados + daño a undead dentro
- **Fórmula heal/tick**: `(10 + INT*1.5) * (1 + level*0.03)`
- **Fórmula dmg undead/tick**: `magic_v2(6, 0, INT, level, 1.1)` (sagrado, ignora resist void)
- **Lvl 5**: radio `AOE_MEDIUM` 7m
- **Lvl 10**: tick 0.4s
- **Lvl 15**: aliados dentro +10% resist cap temporal. **Forma base — cap**.
- **Evolución (+ ítem *Círculo Eterno* Tier III)**: canal gratis primeros 3s (sin MP).

### SKILL 4 — Égida Divina
Buff defensivo dirigido.

- **Tags**: `[holy][shield][buff]`
- **Tipo**: buff defensivo target | **Costo**: 30 MP + 8 Fe | **Fe gen**: +2 al aplicar sobre aliado | **CD**: 20s | **Cast**: 0.5s | **Duración**: 8s
- **Efecto base**: target recibe +30% DEF + `Shield` absorb `50 + INT*3`
- **Lvl 5**: duración 10s
- **Lvl 10**: al romperse el escudo libera heal pulse (20% daño absorbido distribuido a aliados 6m)
- **Lvl 15**: inmune a 1 golpe letal durante duración (1 uso por buff). **Forma base — cap**.
- **Evolución (+ ítem *Sello de los Siete* boss P75)**: 3 sellos visibles que se consumen uno por golpe letal bloqueado (hasta 3 letales prevenidos).

### SKILL 5 — Juicio Sagrado (ULTIMATE)
Dual-mode: revivir o daño masivo.

- **Tags**: `[holy][ultimate][revive/dmg]`
- **Tipo**: ultimate dual | **Costo**: 80 MP + 25 Fe | **CD**: 120s | **Cast**: 2s (canto Demon Slayer)
- **Modos pre-cast**:
  - **Resurrección**: revive aliado caído a 50% HP (no usable si no hay caídos — modo se bloquea)
  - **Juicio**: `AOE_MEDIUM` 8m alrededor, daño sagrado
- **Fórmula Juicio**: `magic_v2(150, 0, INT, level, 1.2)` × 1.5 vs undead/void
- **Lvl 5**: revive 60% HP / +15% dmg
- **Lvl 10**: CD 100s, revive otorga `Invul` 3s al aliado revivido
- **Lvl 15**: Juicio `Stun` 1.5s a sobrevivientes + aplica `Weak` 5s. **Forma base — cap**.
- **Evolución (+ ítem *Juicio del Cielo* boss P100)**: revive a **todos** los aliados caídos en 15m + dispara Juicio simultáneo.

---

## 4. Rama Sanador (char lvl 25+)

### S1 — Gracia Infinita (pasiva única)
- **Tags**: `[passive][heal_crit]`
- **Efecto base**: heals con 50% chance de ser críticos (×1.5)
- **Lvl 5-15**: cada lvl +2% chance (cap 80% a lvl 15)
- **Integración**:
  - Luz Restauradora → heal crea enlace 4s, aliado curado rebota 30% heal al Cleric
  - Círculo → aliados dentro ganan `Regen` extra 2% HP/s
  - Égida → el escudo no tiene tope absorb (escala con HP max del target, 30%)
  - Juicio Resurrección sin caído → se convierte en heal masivo AoE (150% heal base a todos los aliados en 15m)

### S2 — Toque Vital
- **Tags**: `[holy][heal][cleanse]`
- **Desbloqueo**: rama Sanador lvl 30 (requiere Báculo Sagrado)
- **Tipo**: heal burst melee + cleanse | **Costo**: 20 MP + 3 Fe | **Fe gen**: +5 por cleanse | **CD**: 6s | **Cast**: 0.2s | **Rango**: `MELEE_LONG` 3m
- **Efecto base**: heal burst + limpia 1 debuff no-boss (excluye `Cursed` de boss)
- **Fórmula heal**: `(40 + INT*3) * (1 + level*0.03) * 1.2`
- **Lvl 5**: limpia 2 debuffs
- **Lvl 10**: overheal → `Shield` temporal 3s
- **Lvl 15**: cura también al Cleric por 50% del valor otorgado. **Forma base — cap**.

### S3 — Gracia Perpetua (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Revivir 10 aliados diferentes en un run".

- **Tags**: `[holy][revive][AoE]`
- **Trigger quest**: revivir 10 aliados diferentes en un run
- **Quest**: *"Gracia Perpetua"* — santuario P55
- **Tipo**: pasiva + trigger | **Costo**: automático al morir aliado cercano | **CD**: 180s
- **Efecto base**: cuando un aliado dentro de 15m muere, hay 50% chance de revivirlo instantáneamente a 25% HP con `Invul` 2s. Cooldown por aliado individual 120s.
- **Lvl 5**: 60% chance
- **Lvl 10**: radio 20m
- **Lvl 15**: 80% chance, revive con 40% HP + `Empower` 6s. **Forma base — cap**.

---

## 5. Rama Buffer (char lvl 25+)

### B1 — Aura de Resguardo (pasiva única)
Canon `balance_v2 §2.6`. Pasiva única más estratégica del juego.

- **Tags**: `[passive][aura][resist]`
- **Efecto base**: aliados en `PULSO_AURA` 20m radio reciben **+5% resist cap** (75% → 80%) mientras Buffer vivo. Se pierde al caer.
- **Lvl 5-15**: cada lvl +0.3% resist cap extra (cap +9.5% a lvl 15, total 84.5%)
- **Integración**:
  - Luz Restauradora → heal aplica `Empower` +10% DMG 5s al curado
  - Círculo → aliados dentro ganan `Haste` +15% atk speed
  - Égida → target gana +10% resist cap extra (cap total 90% exclusivo solo para el target de la Égida)
  - Juicio modo Juicio también buffea aliados en AoE en vez de dañar (+30% DMG 8s). El Buffer puede elegir pre-cast.

### B2 — Verso del Guardián
- **Tags**: `[holy][buff][empower]`
- **Desbloqueo**: rama Buffer lvl 30 (requiere Libro de Oraciones)
- **Tipo**: aura buff | **Costo**: 25 MP + 5 Fe | **Fe gen**: +2 por aliado buffeado | **CD**: 12s | **Cast**: 0.8s | **Duración**: 8s | **Rango**: `AOE_LARGE` 10m
- **Efecto base**: aliados en rango +20% DMG saliente + 10% resist cap (stackea con Aura Resguardo)
- **Lvl 5**: duración 10s
- **Lvl 10**: +25% DMG + radio 12m
- **Lvl 15**: aliados también ganan `Haste` (`_status_effects.md §2.4`) 5s al activar. **Forma base — cap**.
- **Evolución (+ ítem *Liturgia Perfecta* boss P75)**: el verso persiste 3s extra tras cambio de zona.

### B3 — El Guardián Silencioso (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Mantener Aura Resguardo activa 30 min combate".

- **Tags**: `[holy][aura][invul]`
- **Trigger quest**: mantener Aura Resguardo activa 30 min combate acumulado
- **Quest**: *"El Guardián Silencioso"* — NPC P60
- **Tipo**: aura activable | **Costo**: 50 MP + 20 Fe | **CD**: 240s | **Cast**: 1s | **Duración**: 10s | **Rango**: 15m radio
- **Efecto base**: durante la duración, aliados en rango son inmunes a golpes letales (el siguiente golpe que los pondría a 0 HP los deja en 1 HP sin gastar). Cada aliado recibe el efecto 1 vez.
- **Lvl 5**: duración 12s
- **Lvl 10**: los aliados post-save reciben `Shield` 100 HP 5s
- **Lvl 15**: el Buffer también recibe el efecto (antes solo aliados). **Forma base — cap**.

---

## 6. Rama Exorcista (char lvl 25+)

### X1 — Luz Sagrada (pasiva única)
- **Tags**: `[passive][holy_dmg][anti-undead]`
- **Efecto base**: daño sagrado +50% vs undead/void. Todas las skills del Cleric pueden hacer dmg a enemigos (incluso heals modifican a daño a undead).
- **Lvl 5-15**: cada lvl +2% dmg sagrado (cap +80% a lvl 15)
- **Integración**:
  - Luz Restauradora → puede lanzarse contra undead como daño puro (no heal)
  - Círculo → tick dmg undead +50% adicional, pulso 3m `Silence` undead 1s
  - Égida → en aliado también refleja 20% dmg a atacantes undead
  - Juicio → dmg +100% vs undead, AoE 12m, aplica weak-to-holy 10s

### X2 — Verso del Exorcismo
- **Tags**: `[holy][debuff][silence]`
- **Desbloqueo**: rama Exorcista lvl 30 (requiere Libro de Oraciones)
- **Tipo**: aura debuff | **Costo**: 25 MP + 5 Fe | **Fe gen**: +1 hit undead | **CD**: 12s | **Cast**: 0.8s | **Duración**: 8s | **Rango**: `AOE_LARGE` 10m
- **Efecto base**: enemigos en rango -20% DMG saliente (`Weak`). Undead -40% DMG + `Silence` 2s inicial.
- **Lvl 5**: duración 10s
- **Lvl 10**: -25% DMG, aplica `Vulnerable` 5s
- **Lvl 15**: enemigos undead recibe `Fear` al entrar al aura. **Forma base — cap**.

### X3 — Luz sobre Voidsign (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Matar 50 undead con daño sagrado".

- **Tags**: `[holy][AoE][banish]`
- **Trigger quest**: matar 50 undead con daño sagrado
- **Quest**: *"Luz sobre Voidsign"* — templo P65
- **Tipo**: AoE banish | **Costo**: 60 MP + 15 Fe | **CD**: 90s | **Cast**: 1.5s | **Rango**: `AOE_HUGE` 15m radio caster
- **Efecto base**: pulso de luz sagrada. Undead/void en rango reciben `magic_v2(300, 0, INT, level, 1.5) * 2.0`. Enemigos normales reciben 50% dmg base + `Weak` 8s.
- **Lvl 5**: radio 18m
- **Lvl 10**: undead muertos por este skill no pueden ser re-animados (anti-necro hostile)
- **Lvl 15**: aliados en el pulso reciben `Shield` 80 HP 4s. **Forma base — cap**.

---

## 7. Sinergias coop (ver `_synergies.md`)

| Con | Combo |
|-----|-------|
| Warrior | Buffer + Forma del Titán = tank con resist cap 80% + DEF 50% + Aura Resguardo = inmortal vs boss. Sanador heals mantienen Berserker activo al bajar HP estratégicamente. |
| Mage | Buffer Verso + Supernova = +20% dmg final masivo. Exorcista + Mage elemental = doble status (Burn holy combo). |
| Archer | Sanador Círculo sobre zona de Archer = distancia sostenida. Buffer +DMG Archer Ojo Verdadero = crits devastadores. |
| Necromancer | Aura Resguardo aplica a invocaciones (canon). Exorcista funciona **AL REVÉS** con Necromancer (undead aliados reciben dmg) — coord explícita required. |
| Danzante | Sanador mantiene Danzante fuera de stealth via heals rápidos. Buffer + Danzante burst = ventana 8s dmg masivo. |

---

## 8. FX visual

- Luz Restauradora: pilar de luz dorada sobre target
- Plegaria: runas doradas girando alrededor del Cleric, partículas ascendentes
- Círculo Sagrado: runas en suelo que giran, partículas doradas ascendiendo
- Égida Divina: placas de luz hexagonales sobre target (estilo Frieren barrera)
- Juicio Sagrado: rayo vertical desde cielo (Demon Slayer Pilar Amor). Revive = aliado emerge de luz
- Toque Vital: mano brillante del Cleric al target
- Verso del Guardián: libro flotante con páginas girando, runas doradas emitidas
- Verso del Exorcismo: libro flotante oscuro, runas violeta-dorada
- El Guardián Silencioso: domo dorado translúcido envolviendo a aliados
- Luz sobre Voidsign: flash blanco total en el área, eco musical sagrado

---

## 9. Tabla rápida — costos y CDs

| Skill | MP | Fe | CD | Gate char |
|-------|----|----|----|-----------|
| Luz Restauradora | 15 | +3 gen | 1.5s | 1 |
| Plegaria | 0 | +15 tras canal | 20s | 4 |
| Círculo Sagrado | 15/s | +1/tick gen | 5s post | 8 |
| Égida Divina | 30 | -8 / +2 gen | 20s | 12 |
| Juicio Sagrado (ult) | 80 | -25 | 120s | 20 |
| Gracia Infinita (S) | — passive | — | — | 25 |
| Toque Vital (S) | 20 | -3 / +5 cleanse | 6s | 30 |
| Gracia Perpetua (S) | — auto | — | 180s | 50 + quest |
| Aura Resguardo (B) | — passive | — | — | 25 |
| Verso del Guardián (B) | 25 | -5 / +2/aliado | 12s | 30 |
| Guardián Silencioso (B) | 50 | -20 | 240s | 50 + quest |
| Luz Sagrada (X) | — passive | — | — | 25 |
| Verso del Exorcismo (X) | 25 | -5 / +1/hit undead | 12s | 30 |
| Luz sobre Voidsign (X) | 60 | -15 | 90s | 50 + quest |

---

## 10. Deprecated

- XP por uso descartado (canon `_system.md §7`)
- Maestría por drop → reemplazada por evolución lvl 15 + char 50
- Modelo "4 fijas + 2 variables" → reemplazado por generales + 3 ramas (excepción Cleric)

Nombres originales preservados (Luz Restauradora, Círculo Sagrado, Égida Divina, Juicio Sagrado, Toque Vital, Verso del Guardián/Exorcismo, Aura Resguardo, Gracia Infinita, Luz Sagrada).

---

*Canon Cleric v2.0. 3 ramas excepción canon `_system.md §7`.*
