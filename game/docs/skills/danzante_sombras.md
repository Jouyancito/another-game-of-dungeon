# Danzante de Sombras — Skill Set Completo

**Versión**: 1.0 — canon (clase nueva, from scratch)
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md`, `class_skills.md` §8, `DESIGN_BRIEF.md` §8.15 (masa 2.0, liviano)
**Class mult físico**: 1.2 (DEX-based, alta velocidad, bajo sustain) | **Base stats**: DEX 13 / STR 7 / INT 4 / DEF 3 / VIT 5 | **HP base**: 85 | **MP base**: 80

**Rol**: asesino burst + movilidad extrema + stealth. Fragil, premiado por timing y lectura.

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Corte Fugaz | melee rápido | 0 | 0.25s | ataque básico |
| 2 fija | Paso de Sombra | dash/clon | 10 | 4s | movilidad + trick |
| 3 fija | Velo Nocturno | stealth | 25 | 25s | stealth + crit setup |
| 4 fija | Danza de Mil Sombras | ultimate | 70 | 110s | burst AoE multi-hit |
| 5a var | Flor de Sangre | Dagas | 15 | 7s | sangrado + backstab |
| 5b var | Lluvia de Acero | Shurikens | 10 | 3s | multi-throw veneno |

---

## SKILL 1 — Corte Fugaz (fija)

- **Tipo**: melee rápido, cadena 3 hits
- **Costo**: 0 MP | **CD**: 0.25s entre hits | **Rango**: 2m cono 80°
- **Efecto base**: 3er hit de la cadena aplica bleeding 3s
- **Fórmula por hit**: `physical_v2(8, weapon_dmg, DEX, level, 1.2)`
- **Fórmula bleed/s**: `physical_v2(5, 0, DEX, level, 0.8)` — ignora armor_reduction
- **Escalado**: L2 +15% por hit, L3 cadena 4 hits, L4 +45%, L5 cada hit crit chance +10% por cada hit previo en la cadena (build-up)
- **Maestría "Corte del Hilo"**: drop boss P50. La cadena no se resetea al cambiar de target (chainable entre enemigos si <3m).
- **Acuática**: **Hilo Silencioso** — corte con cuchillo curvado, +20% dmg si atacas desde detrás (agua amortigua).
- **Sinergia**: Warrior taunt → Danzante encadena libre por detrás.

## SKILL 2 — Paso de Sombra (fija)

- **Tipo**: dash + clon decoy
- **Costo**: 10 MP | **CD**: 4s | **Distancia**: 7m
- **Efecto base**: dash invul 0.3s, deja clon 2s en origen que tanquea 1 golpe y replica Corte Fugaz al morir
- **Escalado**: L2 dist 8m, L3 CD 3s, L4 clon HP 50 (aguanta más de 1 golpe si el golpe es débil), L5 al aterrizar primer ataque del Danzante crit garantizado
- **Maestría "Paso del Vacío"**: drop Tier III. 2 cargas con CD independiente.
- **Sinergia**: Mage Blink + Paso de Sombra = teletransportarse cada uno usa el otro como ancla (permite escape extremo).

## SKILL 3 — Velo Nocturno (fija)

- **Tipo**: stealth activa
- **Costo**: 25 MP | **CD**: 25s | **Cast**: 0.2s | **Duración**: 6s (o hasta atacar)
- **Efecto base**: invisibilidad, movimiento +20% velocidad, primer ataque desde stealth = crit ×2.5
- **Escalado**: L2 duración 7s, L3 velocidad +30%, L4 salir con ataque no rompe stealth si fue backstab (aguanta 1 hit extra), L5 el backstab desde stealth aplica daño "true" 30% del total (ignora armor + resist)
- **Maestría "Velo del Olvido"**: drop boss P75. Al romper stealth con ataque, los enemigos en 10m pierden target de vos por 2s (aunque no te re-oculta).

## SKILL 4 — Danza de Mil Sombras (fija, ULTIMATE)

- **Tipo**: ultimate burst multi-hit AoE
- **Costo**: 70 MP | **CD**: 110s | **Cast**: 0.5s (nombre visible, Demon Slayer forma rápida)
- **Efecto base**: 4s de duración. El Danzante se vuelve incorpóreo, realiza 20 cortes a enemigos dentro de 8m, distribuidos. Inmune a daño durante duración.
- **Fórmula por corte**: `physical_v2(25, weapon_dmg*0.4, DEX, level, 1.2)`
- **Escalado**: L2 +15% corte, L3 cortes = 25, L4 +45%, L5 al terminar deja 3 clones 3s que replican Corte Fugaz (1 vez cada uno)
- **Maestría "Danza de la Luna Roja"**: drop boss P100. Duración 6s, cortes 40, lifesteal 15% del total.
- **Sinergia**: Necromancer Aura Plaga + Danza = enemigos -DEF devastación. Mage Supernova encima simultáneo = Danzante inmune al Mage, todos los demás mueren.

## SKILL 5a — Flor de Sangre (variable, DAGAS DUALES)

- **Tipo**: combo melee finisher
- **Costo**: 15 MP | **CD**: 7s | **Cast**: 0.3s | **Rango**: 2m
- **Efecto base**: 5 cortes rápidos en 0.8s al mismo target, el 5º aplica bleed pesado
- **Fórmula por corte**: `physical_v2(18, weapon_dmg, DEX, level, 1.2)`
- **Fórmula bleed pesado/s**: `physical_v2(15, 0, DEX, level, 1.0)` 6s, stack hasta 3
- **Escalado**: L2 +15% por corte, L3 cortes = 6, L4 backstab bonus +40%, L5 si target < 30% HP, ejecuta (kill directo si daño final >= HP restante)
- **Maestría "Flor del Loto Carmesí"**: drop Tier III. Los bleed stackeados explotan al morir el target (AoE 3m = suma de stacks × 30% dmg).

## SKILL 5b — Lluvia de Acero (variable, SHURIKENS)

- **Tipo**: multi-throw ranged
- **Costo**: 10 MP | **CD**: 3s | **Cast**: 0.2s | **Rango**: 15m
- **Efecto base**: lanza 3 shurikens en cono 30°, aplican veneno (DoT)
- **Fórmula por shuriken**: `physical_v2(10, weapon_dmg*0.5, DEX, level, 1.2)`
- **Fórmula veneno/s**: `magic_v2(4, 0, DEX, level, 1.0)` 5s (usa DEX como stat de veneno, excepción)
- **Escalado**: L2 +15%, L3 cono 45° (5 shurikens), L4 veneno stack x2, L5 shurikens rebotan al siguiente enemigo si kill
- **Maestría "Tormenta de Agujas"**: drop Tier III. Mantener click dispara continuo mientras haya MP (2 MP/segundo, ritmo 3 shurikens/s).

---

## Modificadores de rama (lvl 25)

### Sombra (asesino puro)
- **Pasiva única**: *Golpe Letal* — crits ×2.75 (en vez de ×1.5 base). Hits post-stealth crits ×3.5.
- SKILL 1 → 3er hit cadena aplica silenciar 1.5s (sin skills enemigas)
- SKILL 2 → clon explota al final (AoE 3m dmg = 50% daño que el clon absorbió, min 30)
- SKILL 3 → duración +2s, pero romper antes = refund 50% MP
- SKILL 4 → cortes +20% dmg pero no-AoE (todos al target más cercano, single-target devastador)

### Trickster (evasión + control)
- **Pasiva única**: *Reflejo Sombrío* — primer golpe letal por encuentro, 50% chance de esquivar automáticamente + entrar en stealth 1s.
- SKILL 1 → cada hit de cadena aplica slow stackeable 5% (max 30%)
- SKILL 2 → clon imita al Danzante 3s (enemigos atacan al clon random-chance 50%)
- SKILL 3 → Velo también hace clones falsos (2 copias que se mueven erráticas 4s)
- SKILL 4 → Danza deja 6 clones en vez de 3 al final, cada uno dura 5s

---

## XP por uso

Curva `50 * 1.4^n`. XP base:
- Corte Fugaz: 2 xp/hit (bonus +2 si completás cadena 3)
- Paso de Sombra: 6 xp/uso, 12 si evita golpe letal, 15 si clon tanquea
- Velo Nocturno: 15 xp/uso (+10 si primer ataque fue crit backstab)
- Danza de Mil Sombras: 55 xp/uso + 1 por corte conectado (max +20)
- Flor de Sangre: 10 xp/uso, +15 si ejecutás con L5
- Lluvia de Acero: 3 xp/shuriken conectado

---

## Sinergias coop

| Con | Combo |
|-----|-------|
| Warrior | Warrior taunt → Danzante backstab libre. Warrior Forma Titán + Danza simultánea = warrior absorbe, Danzante corta. |
| Mage | Mage Supernova + Danza = Danzante inmune por Danza, todos los demás frita. Mage Manipulación atrae enemigos a zona de Danzante stealth. |
| Archer | Archer marca target + Danzante backstab = daño "true" masivo. Voltereta del Archer + Paso de Sombra = combo evasivo dúo. |
| Necromancer | Danzante stealth + invocaciones del Necro generan confusión (enemigos no saben a quién atacar). Aura Plaga + Danza burst = decisivo. |
| Cleric | Buffer sobre Danzante = ventana 8s de burst masivo. Sanador heal rápido compensa HP bajo del Danzante. |

---

## FX visual

- Corte Fugaz: trails de sombra violeta-negra, hits encadenados = afterimages
- Paso de Sombra: disolución en partículas negras, reaparición en origen con chispa
- Velo Nocturno: el Danzante se desvanece entre sombras tipo Demon Slayer forma viento
- Danza de Mil Sombras: 4s de afterimages superpuestos, grid de cortes visibles, nombre flotante
- Flor de Sangre: pétalos rojos flotando al finalizar el 5º corte
- Lluvia de Acero: destellos metálicos en trayectoria, impacto silencioso

---

*Canon Danzante de Sombras. Clase nueva — stats base son estimación, playtest puede ajustar.*
