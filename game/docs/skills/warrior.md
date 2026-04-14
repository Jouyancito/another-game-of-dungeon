# Warrior — Skill Set Completo

**Versión**: 1.0 — canon
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md` (fórmulas compound), `class_skills.md` §3 (estructura), `systems_v2.md` §1.5 (acuáticas)
**Class mult físico**: 1.5 | **Base stats**: STR 12 / VIT 10 / DEF 10 / INT 3 / DEX 6

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Puño de Guerra | activa melee | 0 | 0.5s | ataque básico |
| 2 fija | Embestida | activa movilidad | 10 | 8s | gap-closer + stun |
| 3 fija | Grito de Guerra | toggle aura | 20/5s | 0s | buff/debuff zona |
| 4 fija | Forma del Titán | ultimate | 60 | 90s | transformación 12s |
| 5a var | Bloqueo Perfecto | reactiva | 0 | 4s | Escudo 1H |
| 5b var | Giro de Espada | activa AoE | 15 | 6s | Espadón 2H |

---

## SKILL 1 — Puño de Guerra (fija)

- **Tipo**: activa melee
- **Costo**: 0 MP | **CD**: 0.5s | **Cast**: instantáneo | **Rango**: 2m cono 60°
- **Efecto base**: golpe pesado single-target
- **Fórmula**: `physical_v2(15, weapon_dmg, STR_total, level, 1.5)`
- **Escalado 1-5**:
  - L1: base (15 dmg flat)
  - L2: +15% daño
  - L3: +30% daño
  - L4: +45% daño + knockback 2m
  - L5: +60% daño + crit chance +15%
- **Maestría "Puño del Titán"**: drop Pergamino — boss Rey Slime P25. Cada 3er golpe dispara onda sísmica AoE 4m (50% dmg base).
- **Acuática**: **Puño de Marea** — shockwave radial 3m en vez de cono (systems_v2 §1.5)
- **Sinergia**: Mage encanta arma → el puño aplica el elemento (fuego/hielo/rayo) por 3s

## SKILL 2 — Embestida (fija)

- **Tipo**: activa dash ofensivo
- **Costo**: 10 MP | **CD**: 8s | **Cast**: 0.2s | **Rango**: dash 6m
- **Efecto base**: carga linear, aturde al primer enemigo impactado
- **Fórmula**: `physical_v2(20, 0, STR_total, level, 1.3)` | **stun**: 0.8s
- **Escalado**: L2 +15%, L3 +30%, L4 stun 1.2s, L5 atraviesa hasta 3 enemigos
- **Maestría "Carga del Jabalí Blindado"**: drop boss P50. Gana super-armor durante el dash (inmune a interrupts).
- **Acuática**: **Arpón de Placaje** — lanza cadena, arrastra 4m al enemigo hacia vos
- **Sinergia**: con Archer (enemigo con arrow-slow) → crit garantizado. Con Necro → empuja invocaciones enemigas fuera de zona.

## SKILL 3 — Grito de Guerra (fija)

- **Tipo**: toggle aura
- **Costo**: 20 MP cada 5s activo | **CD**: 0s | **Rango**: 10m radio
- **Efecto base**: aliados +15% DMG, enemigos -10% DMG saliente
- **Escalado**: L1→L5 radio +0/1/2/3/4m, L5 aliados +20% DMG
- **Maestría "Corazón de León"**: drop evento Tier III. Aliados inmunes a miedo/shout enemigo.
- **Acuática**: funciona igual pero radio reducido a 6m (agua absorbe sonido)
- **Sinergia**: stackea aditivamente con Cleric Buffer (no multiplicativo). Necromancer absorbe el buff hacia invocaciones.

## SKILL 4 — Estilo de Hierro: Forma del Titán (fija, ULTIMATE)

- **Tipo**: ultimate transformación
- **Costo**: 60 MP | **CD**: 90s | **Cast**: 1.5s con nombre visible (canon brief §3)
- **Duración**: 12s
- **Efecto base**: +50% DMG físico, +50% DEF, -30% velocidad, inmune knockback/stun
- **Escalado**: duración L1→L5 = 12/13/14/15/16s. L4 +60% DEF. L5 al activar restaura 30% HP.
- **Maestría "Titán Inmortal"**: drop boss P75. Si morís durante buff → revivís 1 vez con 25% HP. 1 uso por run.
- **Sinergia**: Cleric Buffer + Forma del Titán = resist cap 80% + DEF 50% + Aura Resguardo = tanque absoluto contra boss tier.

## SKILL 5a — Bloqueo Perfecto (variable, ESCUDO 1H)

- **Tipo**: reactiva (ventana)
- **Costo**: 0 MP | **CD**: 4s | **Ventana activa**: 0.4s tras apretar
- **Efecto base**: dentro de ventana, absorbe 100% del próximo golpe + refleja 50% dmg + stun 0.5s al atacante
- **Fórmula reflejo**: `physical_v2(raw_blocked * 0.5, 0, STR, level, 1.0)`
- **Escalado**: L1→L5 ventana 0.4/0.5/0.6/0.7/0.8s. L5 absorbe 2 golpes consecutivos.
- **Maestría "Muralla Divina"**: drop boss P50. Refleja 100% + aliados detrás del escudo invulnerables 1s.

## SKILL 5b — Giro de Espada (variable, ESPADÓN 2H)

- **Tipo**: activa AoE
- **Costo**: 15 MP | **CD**: 6s | **Cast**: 0.6s
- **Efecto base**: giro 360° radio 3m, hit único
- **Fórmula**: `physical_v2(30, weapon_dmg*1.2, STR, level, 1.5)`
- **Escalado**: L1→L5 radio 3/3.3/3.6/4/4.5m. L5 el giro dura 2s (2 hits, CD pasa a 9s).
- **Maestría "Huracán de Acero"**: drop Tier III. Giro continuo 4s canalizado, consume 5 MP/s.

---

## Modificadores de rama (lvl 25)

Cada rama **transforma** las 4 fijas. No agrega skills.

### Tank
- **Pasiva única**: *Postura de Muralla* — con Escudo 1H: +50% block chance + 20% DEF total mientras Bloqueo Perfecto está en ventana
- SKILL 1 → aplica **taunt** 3s al golpear
- SKILL 2 → al impactar genera escudo temporal 200 HP absorbe-dmg (decae 10s)
- SKILL 3 → radio +5m, aliados además +10% DEF
- SKILL 4 → cambia: +100% DEF en vez de +50% DMG. Redirige 30% daño recibido por aliados en 8m hacia el Warrior.

### Berserker
- **Pasiva única**: *Furia Creciente* — +2% daño por cada 10% HP perdido, cap +20%. Visible con glow rojo progresivo.
- SKILL 1 → +30% DMG extra, cost self-dmg 2% HP por golpe
- SKILL 2 → sin cast time (instantáneo), atraviesa hasta 5 enemigos, consume 15% HP actual
- SKILL 3 → deja de ser aura (solo afecta al Warrior): +40% DMG, +30% attack speed
- SKILL 4 → cambia a **Forma Berserker**: +100% DMG, -50% DEF, lifesteal 25%, 10s duración

---

## XP por uso (canon §11.2)

Curva común a todas las skills de la clase:

```
xp_to_next(n) = 50 * 1.4^n
```

| Nivel skill | XP requerida | XP acumulada |
|-------------|--------------|--------------|
| 1→2 | 50 | 50 |
| 2→3 | 70 | 120 |
| 3→4 | 98 | 218 |
| 4→5 | 137 | 355 |
| 5→Master | solo drop/quest | — |

Multiplicadores situacionales: kill ×2.0, hit boss ×1.5, miss ×0.3, no enemigo ×0.1.

XP base por uso:
- Puño de Guerra: 4 xp/hit
- Embestida: 8 xp/uso
- Grito de Guerra: 1 xp/s activo (solo con enemigo en rango)
- Forma del Titán: 40 xp/uso
- Bloqueo Perfecto: 10 xp/bloqueo exitoso (0 si no bloqueó nada)
- Giro de Espada: 6 xp/uso + 2 por enemigo extra impactado

---

## Sinergias coop (extracto matriz §9)

| Con | Combo |
|-----|-------|
| Mage | Encanta arma → Puño/Giro aplican elemento. Mage dispara Supernova sobre Warrior en Forma del Titán → Warrior inmune + enemigos en 8m full dmg |
| Archer | Flecha slow + Embestida = crit garantizado. Warrior taunta, Archer dispara libre. |
| Necromancer | Invocaciones del Necro + Grito de Guerra reciben el buff. Warrior empuja con Embestida, undead persigue. |
| Cleric | Buffer sobre Warrior + Forma del Titán = resist 80% + lifesteal pasivo 5% (si Sanador). Exorcista sobre Warrior anti-undead = bono dmg. |
| Danzante | Danzante stealth + Warrior Grito = enemigos rompen stealth check sobre Warrior, Danzante backstab crítico. |

---

## FX visual (ref)

- Puño de Guerra: shockwave tierra (Demon Slayer Pilar de Piedra)
- Embestida: trail de polvo amarillo (One Piece Gear Second)
- Grito de Guerra: onda sonora concéntrica dorada (JJK Domain preview)
- Forma del Titán: aura piedra/hierro envolvente, vapor al activar (Demon Slayer Gyomei)
- Bloqueo Perfecto: flash blanco + grieta en el escudo
- Giro de Espada: trail circular de acero + chispas

---

*Canon Warrior. Cualquier ajuste se versiona aquí primero.*
