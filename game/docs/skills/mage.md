# Mage — Skill Set Completo

**Versión**: 1.0 — canon
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md`, `class_skills.md` §4, `systems_v2.md`
**Class mult mágico**: 1.5 | **Base stats**: INT 12 / STR 4 / DEX 5 / DEF 3 / VIT 5

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Bolita Inestable | proyectil | 8 | 0.4s | básico a distancia |
| 2 fija | Tormenta Arcana | canalizada AoE | 20/s | 3s post | control zona |
| 3 fija | Barrera Prismática | escudo | 25 | 15s | defensivo |
| 4 fija | Arte Arcano: Supernova | ultimate | 70 | 120s | daño máximo AoE |
| 5a var | Furia Elemental | activa elemental | 30 | 10s | Bastón |
| 5b var | Manipulación Espacial | utilidad | 20 | 12s | Tomo |

---

## SKILL 1 — Bolita Inestable (fija)

- **Tipo**: proyectil activa
- **Costo**: 8 MP | **CD**: 0.4s | **Cast**: 0.15s | **Velocidad**: 22 m/s
- **Efecto base**: proyectil finger-guns (brief §3). Explota al impactar, AoE 1m.
- **Fórmula**: `magic_v2(18, weapon_dmg, INT_total, level, 1.5)`
- **Escalado 1-5**:
  - L2: +15% daño
  - L3: +30% daño, velocidad 25 m/s
  - L4: +45% daño, AoE 1.5m
  - L5: +60% daño, disparo doble (2 bolitas con 0.1s delay)
- **Maestría "Bolita Colapsada"**: drop boss P25. Al impactar crea singularidad 2s que atrae enemigos 4m.
- **Acuática**: **Presión Abisal** — proyectil viaja igual bajo agua, dmg +20% por compresión
- **Sinergia**: Warrior encanta puño → bolita aplica elemento al Warrior por 3s.

## SKILL 2 — Tormenta Arcana (fija, canalizada)

- **Tipo**: canalizada AoE (ya implementado como "rayo canalizado")
- **Costo**: 20 MP/s | **CD**: 3s post-canal | **Rango**: cono 8m / AoE 4m radio target
- **Efecto base**: tick 0.25s, daño continuo
- **Fórmula por tick**: `magic_v2(6, weapon_dmg*0.3, INT, level, 1.5) * 0.25`
- **Escalado**: L2 +15%, L3 tick cada 0.2s, L4 radio +1m, L5 aplica slow 30% a todo lo tickeado
- **Maestría "Tormenta Perpetua"**: drop boss P75. Canal gratis (sin MP) primeros 3s.

## SKILL 3 — Barrera Prismática (fija)

- **Tipo**: escudo activo
- **Costo**: 25 MP | **CD**: 15s | **Cast**: 0.3s | **Duración**: 6s o hasta romper
- **Efecto base**: escudo absorbe `80 + INT*3` daño (mágico o físico)
- **Escalado**: L2 +15% absorb, L3 +30%, L4 al romper suelta onda dmg 40% absorbida en 3m, L5 refleja 20% del daño absorbido al atacante
- **Maestría "Barrera Fractal"**: drop Tier III. 3 capas independientes, cada capa absorbe separadamente.
- **Sinergia**: Cleric Buffer + Barrera = absorb +25% (Aura Resguardo cap 80% resist se aplica a daño residual).

## SKILL 4 — Arte Arcano: Supernova (fija, ULTIMATE)

- **Tipo**: ultimate AoE
- **Costo**: 70 MP | **CD**: 120s | **Cast**: 2s (nombre visible, pose JJK)
- **Radio**: 10m alrededor del caster
- **Fórmula**: `magic_v2(200, weapon_dmg*2, INT, level, 1.5)` impacto único
- **Escalado**: L2 +15%, L3 radio 12m, L4 +45%, L5 tras explosión deja zona arcana 5s (tick 5% base/s)
- **Maestría "Colapso Estelar"**: drop boss P100. Segunda explosión 2s después, 50% del daño, doble radio.
- **Sinergia**: Warrior Forma del Titán + Supernova → Warrior inmune dentro del radio, enemigos dmg completo.

## SKILL 5a — Furia Elemental (variable, BASTÓN Elementalista)

- **Tipo**: activa elemental enfocada (elemento toggled out-of-combat)
- **Costo**: 30 MP | **CD**: 10s | **Cast**: 0.5s | **Elementos**: Fuego / Hielo / Rayo
- **Fórmula base**: `magic_v2(45, weapon_dmg*1.5, INT, level, 1.5)`
- **Efecto por elemento**:
  - Fuego: DoT 8% base/s por 4s
  - Hielo: freeze 1.5s (slow 60% 3s después)
  - Rayo: chain a 3 enemigos adicionales (50% dmg cada salto)
- **Escalado**: L2 +15%, L3 CD 8s, L4 +45%, L5 elemento híbrido (elige 2, aplica ambos efectos)
- **Maestría "Maestría de los 3 Elementos"**: drop boss P50. Aplica los 3 efectos simultáneamente.

## SKILL 5b — Manipulación Espacial (variable, TOMO Arcano)

- **Tipo**: utilidad (tele / empuje / atrae)
- **Costo**: 20 MP | **CD**: 12s | **Cast**: 0.2s | **Modos**: toggle pre-cast
- **Modos**:
  - **Blink**: teleport 8m dirección mirada, invul 0.2s al llegar
  - **Empuje**: cono 6m, knockback 4m + stun 0.5s
  - **Atracción**: cono 8m, arrastra enemigos 5m hacia vos
- **Escalado**: L2 rango +1m, L3 CD 10s, L4 Blink deja clon 2s que tanquea 1 golpe, L5 los 3 modos usables en 1 activación (secuencia rápida)
- **Maestría "Pliegue Dimensional"**: drop Tier IV. Blink sin CD primer uso de cada combate.

---

## Modificadores de rama (lvl 25)

### Elementalista
- **Pasiva única**: *Maestría Elemental* — al lvl 25 elegís sub-elemento fijo (Fuego/Hielo/Rayo), +30% dmg de ese elemento permanente en todas las skills. Cambiar requiere Tomo del Renacer.
- SKILL 1 → Bolita aplica el sub-elemento (DoT/freeze/chain según elección)
- SKILL 2 → Tormenta es del sub-elemento, tick +20% si el target ya tiene el debuff
- SKILL 3 → Barrera aplica status al atacante que la rompe
- SKILL 4 → Supernova del sub-elemento, daño +25%

### Arcano
- **Pasiva única**: *Distorsión Espacial* — dash teleport 5m cada 12s sin gasto MP. No interrumpe casts.
- SKILL 1 → Bolita curva hacia el target más cercano (homing leve, radio 3m)
- SKILL 2 → Tormenta se puede relocar durante canal (mueve centro con crosshair)
- SKILL 3 → Barrera teletransporta al caster 6m atrás al romperse
- SKILL 4 → Supernova implosión antes de explotar (atrae 5m, luego detona)

---

## XP por uso

Misma curva `50 * 1.4^n` (canon). XP base:
- Bolita: 3 xp/hit
- Tormenta: 0.5 xp/tick
- Barrera: 15 xp/rotura o fin de duración
- Supernova: 50 xp/uso
- Furia Elemental: 8 xp/uso + 2 por efecto aplicado
- Manipulación: 5 xp/uso (10 si Blink evita golpe letal)

---

## Sinergias coop

| Con | Combo |
|-----|-------|
| Warrior | Encanta Puño/Giro. Supernova sobre Warrior-Titán = enemigos incinerados, Warrior intacto. |
| Archer | Flecha atraviesa Tormenta → +elemento. Manipulación atrae enemigos a zona de Archer. |
| Necromancer | Tormenta + invocaciones = undead dentro del AoE reciben buff, enemigos reciben doble. |
| Cleric | Buffer + Barrera = absorb stackeado. Sanador heal-over-time combina con Barrera recurring. |
| Danzante | Danzante stealth + Supernova = Danzante intacto (inmune stealth), Mage limpia área. |

---

## FX visual

- Bolita Inestable: azul-violeta, trail de partículas arcanas, impacto = chispazo (Mago Frieren)
- Tormenta Arcana: rayo continuo canalizado (ya implementado), en Elementalista cambia color según elemento
- Barrera Prismática: hexágonos translúcidos iridiscentes (JJK Domain fragmentado)
- Supernova: pose finger-guns, luego esfera blanca que colapsa en explosión dorada-blanca-violeta
- Furia Elemental: aura del elemento envolviendo bastón
- Manipulación: runas flotantes + distorsión visual tipo heat-haze

---

*Canon Mage.*
