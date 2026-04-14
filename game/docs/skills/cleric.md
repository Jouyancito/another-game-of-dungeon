# Cleric — Skill Set Completo

**Versión**: 1.0 — canon
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md` (Aura Resguardo +5% resist cap canon §2.6), `class_skills.md` §7
**Class mult**: 1.2 heal / 1.1 dmg | **Base stats**: INT 11 / STR 5 / DEX 5 / DEF 7 / VIT 8

**Nota**: Cleric tiene **3 ramas** (Sanador / Buffer / Exorcista), excepción del modelo 2-ramas.

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Luz Restauradora | heal target | 15 | 1.5s | heal directo |
| 2 fija | Círculo Sagrado | heal AoE canal | 15/s | 5s post | zona sostenida |
| 3 fija | Égida Divina | buff defensivo | 30 | 20s | resist + escudo |
| 4 fija | Juicio Sagrado | ultimate | 80 | 120s | revive / dmg undead |
| 5a var | Toque Vital | Báculo Sagrado | 20 | 6s | heal burst + cleanse |
| 5b var | Verso Sagrado | Libro Oraciones | 25 | 12s | buff/debuff según rama |

---

## SKILL 1 — Luz Restauradora (fija)

- **Tipo**: heal directo target único (incluye self)
- **Costo**: 15 MP | **CD**: 1.5s | **Cast**: 0.4s | **Rango**: 20m
- **Efecto base**: heal instantáneo
- **Fórmula heal**: `(25 + INT*2) * (1 + level*0.03) * 1.2`
- **Escalado 1-5**:
  - L2: +15% heal
  - L3: +30% heal, CD 1.2s
  - L4: +45% heal, aplica regen 3% HP/s por 4s post-heal
  - L5: +60% heal, heal critico 30% chance (×1.5)
- **Maestría "Luz del Alba"**: drop boss P50. Heals críticos stackean regen; target puede acumular 3 capas.
- **Acuática**: **Burbuja Vivificante** — heal + escudo temporal 30 HP (systems_v2)
- **Sinergia**: Warrior Taunt + Luz recurrente = tank inmortal vs fodder.

## SKILL 2 — Círculo Sagrado (fija, canalizado)

- **Tipo**: heal AoE canalizado
- **Costo**: 15 MP/s | **CD**: 5s post-canal | **Rango**: 6m radio centrado en caster
- **Efecto base**: tick cada 0.5s, heal a aliados dentro + daño a undead
- **Fórmula heal/tick**: `(10 + INT*1.5) * (1 + level*0.03)`
- **Fórmula dmg undead/tick**: `magic_v2(6, 0, INT, level, 1.1)` (sagrado, ignora resist void)
- **Escalado**: L2 +15%, L3 radio 7m, L4 tick 0.4s, L5 aliados dentro +10% resist cap temporal
- **Maestría "Círculo Eterno"**: drop Tier III. Canal gratis primeros 3s (sin MP).

## SKILL 3 — Égida Divina (fija)

- **Tipo**: buff defensivo target
- **Costo**: 30 MP | **CD**: 20s | **Cast**: 0.5s | **Duración**: 8s
- **Efecto base**: target recibe +30% DEF + escudo absorbe `50 + INT*3`
- **Escalado**: L2 +15% escudo, L3 duración 10s, L4 +40% DEF, L5 al romperse el escudo libera heal pulse (20% daño absorbido distribuido a aliados 6m)
- **Maestría "Égida de los Siete Sellos"**: drop boss P75. Inmune a 1 golpe letal durante duración (1 uso por buff).

## SKILL 4 — Juicio Sagrado (fija, ULTIMATE)

- **Tipo**: ultimate (dual: revive / daño sagrado AoE)
- **Costo**: 80 MP | **CD**: 120s | **Cast**: 2s (canto Demon Slayer)
- **Modos pre-cast**:
  - **Resurrección**: revive aliado caído a 50% HP (no usable si no hay caídos). Si no, modo se bloquea.
  - **Juicio**: AoE 8m alrededor, daño sagrado
- **Fórmula Juicio**: `magic_v2(150, 0, INT, level, 1.2)` × 1.5 vs undead/void
- **Escalado**: L2 revive 60% HP / +15% dmg, L3 CD 100s, L4 revive otorga inmunidad 3s / dmg +45%, L5 Juicio stun 1.5s a sobrevivientes
- **Maestría "Juicio del Cielo"**: drop boss P100. Revive a **todos** los aliados caídos en 15m + dispara Juicio simultáneo.
- **Sinergia**: Warrior Forma del Titán + Égida del Cleric + Aura Resguardo = tank con resist 80% + escudo + DEF 50% + invul 1x muerte.

## SKILL 5a — Toque Vital (variable, BÁCULO SAGRADO — Sanador)

- **Tipo**: heal burst melee + cleanse
- **Costo**: 20 MP | **CD**: 6s | **Cast**: 0.2s | **Rango**: 3m melee
- **Efecto base**: heal burst + limpia 1 debuff no-boss
- **Fórmula heal**: `(40 + INT*3) * (1 + level*0.03) * 1.2`
- **Escalado**: L2 +15%, L3 limpia 2 debuffs, L4 +45%, L5 overheal → escudo temporal equivalente 3s
- **Maestría "Mano de la Diosa"**: drop Tier III. Heal cura también al Cleric por 50% del valor otorgado.

## SKILL 5b — Verso Sagrado (variable, LIBRO — Buffer / Exorcista)

- **Tipo**: toggle dual (modo pre-selección)
- **Costo**: 25 MP | **CD**: 12s | **Cast**: 0.8s | **Duración**: 8s
- **Modos**:
  - **Verso del Guardián (Buffer)**: aliados 10m +20% DMG + 10% resist cap
  - **Verso del Exorcismo (Exorcista)**: enemigos 10m -20% DMG saliente, undead -40%
- **Escalado**: L2 duración 10s, L3 +25% efecto, L4 radio 12m, L5 ambos modos activos simultáneos (pero CD doble, 24s)
- **Maestría "Liturgia Perfecta"**: drop boss P75. El verso persiste 3s extra tras cambio de zona.

---

## Modificadores de rama (lvl 25)

### Sanador
- **Pasiva única**: *Gracia Infinita* — heals con 50% chance de ser críticos (×1.5).
- SKILL 1 → heal crea enlace 4s, aliado curado rebota 30% heal al Cleric
- SKILL 2 → aliados dentro ganan regen extra 2% HP/s
- SKILL 3 → el escudo no tiene tope absorb (escala con HP max del target, 30%)
- SKILL 4 → Resurrección sin caído → se convierte en heal masivo AoE (150% heal base a todos los aliados en 15m)

### Buffer
- **Pasiva única**: *Aura de Resguardo* — aliados en 20m +5% resist cap (80% total, canon balance_v2 §2.6). Se pierde al caer.
- SKILL 1 → heal aplica +10% DMG 5s al curado
- SKILL 2 → aliados dentro +15% atk speed
- SKILL 3 → Égida stackea con aura: target gana +10% resist cap extra (cap total 90% exclusivo solo para el target de la Égida)
- SKILL 4 → Juicio (modo) también buffea aliados en AoE en vez de dañar (+30% DMG 8s)

### Exorcista
- **Pasiva única**: *Luz Sagrada* — daño sagrado +50% vs undead/void. Todas las skills del Cleric pueden hacer dmg a enemigos.
- SKILL 1 → puede lanzarse contra undead como daño puro (no heal)
- SKILL 2 → tick dmg undead +50% adicional, pulso 3m ciega undead 1s
- SKILL 3 → Égida en aliado también refleja 20% dmg a atacantes undead
- SKILL 4 → Juicio dmg +100% vs undead, AoE 12m, aplica weak-to-holy 10s

---

## XP por uso

Curva `50 * 1.4^n`. XP base:
- Luz Restauradora: 5 xp/uso (0 si overheal sin daño recibido; 10 si heal crítico en emergencia <20% HP)
- Círculo: 1 xp/tick (heal o dmg a undead)
- Égida: 12 xp/uso, +5 si el escudo se consume completo
- Juicio: 60 xp/uso (revive) / 50 xp (dmg, +5 por undead muerto)
- Toque Vital: 8 xp/uso, +5 si cleansea
- Verso Sagrado: 10 xp/uso

---

## Sinergias coop

| Con | Combo |
|-----|-------|
| Warrior | Buffer + Forma del Titán = tank inmortal. Égida + Embestida = escudo y carga. Sanador heals continuos mantienen Berserker activo al bajar HP estratégicamente. |
| Mage | Buffer Verso + Supernova = +20% dmg final masivo. Exorcista + Mage = combo elemento+sagrado doble status. |
| Archer | Sanador Círculo sobre zona de Archer permite mantener distancia sostenida. Buffer +DMG = crits devastadores. |
| Necromancer | Aura Resguardo aplica a invocaciones. Exorcista funciona AL REVÉS con Necromancer (undead aliados reciben dmg) — avisar UI. |
| Danzante | Sanador mantiene Danzante fuera de stealth. Buffer + Danzante burst = ventana de 8s de daño masivo. |

---

## FX visual

- Luz Restauradora: pilar de luz dorada sobre target
- Círculo Sagrado: runas en suelo que giran, partículas doradas ascendiendo
- Égida Divina: placas de luz hexagonales sobre target (estilo Frieren barrera)
- Juicio Sagrado: rayo vertical desde cielo (Demon Slayer Pilar Amor), revive = aliado emerge de luz
- Toque Vital: mano brillante del Cleric al target
- Verso Sagrado: libro flotante con páginas girando, runas emitidas

---

*Canon Cleric.*
