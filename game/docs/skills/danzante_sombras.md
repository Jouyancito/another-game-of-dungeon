# Danzante de Sombras — Skill Set Canon

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0 (clase nueva, from scratch en 2026-04-14).
**Depende**: `_system.md`, `_status_effects.md`, `balance_v2.md`, `DESIGN_BRIEF.md §8.15` (masa 2.0, liviano).
**Class mult físico**: 1.2 (DEX-based, velocidad alta, bajo sustain) | **Base stats**: DEX 13 / STR 7 / INT 4 / DEF 3 / VIT 5 | **HP base**: 85 | **MP base**: 80
**Recurso único**: **Combo Points** — ver §1.

**Rol**: asesino burst + movilidad extrema + stealth. Frágil, premiado por timing y lectura.

---

## 0. Identidad

Danzante es la clase de **tempo + decisión**. No aguanta, no sana, no invoca. Lo que hace es **elegir el momento** y ejecutar. Combo Points recompensan encadenar hits sin perder target, finishers gastan los puntos para burst. Ramas: **Sombra** (asesino puro, crits brutales) y **Trickster** (evasión, clones, control caótico).

---

## 1. Recurso único — Combo Points

Canon `_system.md §5ter`:

- **No regenera por tiempo**, se acumulan con hits
- **Max 5 puntos**
- **Generación**:
  - Corte Fugaz hit: **+1**
  - Hit desde stealth: **+2**
  - Crit: **+1 extra** (adicional al hit normal)
- **Reset**: cambiar target o 8s sin hitear
- **Gasta en finishers** (Flor de Sangre, Lluvia de Acero). Daño escala con puntos:
  - 1 punto: ×1.0
  - 3 puntos: ×1.8
  - 5 puntos: ×3.0 (sweet spot)
- MP gasta: utility (Velo Nocturno, Paso de Sombra)
- Referencia: WoW Rogue / FF14 Monk

---

## 2. Pool total (10 skills)

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Corte Fugaz | general | — | 1 | `[physical][melee][chain][combo_gen]` |
| 2 | Paso de Sombra | general | — | 4 | `[physical][mobility][invul][decoy]` |
| 3 | Velo Nocturno | general | — | 8 | `[stealth][buff][crit_setup]` |
| 4 | Danza de Mil Sombras (ult) | general | — | 12 | `[physical][ultimate][multihit][invul]` |
| S1 | Golpe Letal (pasiva) | rama | Sombra | 25 | `[passive][crit_mult]` |
| S2 | Flor de Sangre | rama | Sombra | 30 | `[physical][melee][combo_spend][bleed]` |
| S3 | La Sombra Elegida (oculta) | rama quest | Sombra | 50 + quest | `[stealth][execute][shadow]` |
| T1 | Reflejo Sombrío (pasiva) | rama | Trickster | 25 | `[passive][evade][auto_stealth]` |
| T2 | Lluvia de Acero | rama | Trickster | 30 | `[physical][ranged][poison][multihit]` |
| T3 | El Baile del Espejo (oculta) | rama quest | Trickster | 50 + quest | `[illusion][clone][control]` |

---

## 3. Skills generales

### SKILL 1 — Corte Fugaz
Ataque básico con cadena 3-hit y Combo Points generator.

- **Tags**: `[physical][melee][chain][combo_gen]`
- **Tipo**: melee rápido | **Costo**: 0 MP | **Combo gen**: +1/hit, +2 si desde stealth, +1 extra en crit | **CD**: 0.25s entre hits | **Rango**: `MELEE_SHORT` 2m cono 80°
- **Efecto base**: 3er hit de la cadena aplica `Bleed` 3s
- **Fórmula por hit**: `physical_v2(8, weapon_dmg, DEX, level, 1.2)`
- **Fórmula bleed/s**: `physical_v2(5, 0, DEX, level, 0.8)` — ignora armor_reduction (canon `_status_effects.md §2.1`)
- **Lvl 5**: cadena 4 hits
- **Lvl 10**: cada hit crit chance +5% por hit previo en la cadena (build-up)
- **Lvl 15**: la cadena no se resetea al cambiar de target (chainable entre enemigos si <3m). **Forma base — cap**.
- **Evolución (+ ítem *Corte del Hilo* boss P50)**: `Bleed` aplicado stackea hasta x5 (en vez de x3 catálogo).
- **Acuática**: **Hilo Silencioso** — corte con cuchillo curvado, +20% dmg si atacas desde detrás.

### SKILL 2 — Paso de Sombra
Dash con clon decoy. Identidad "no sabés cuál es el real".

- **Tags**: `[physical][mobility][invul][decoy]`
- **Tipo**: dash + clon | **Costo**: 10 MP | **CD**: 4s | **Distancia**: 7m
- **Efecto base**: dash `Invul` 0.3s, deja clon 2s en origen que tanquea 1 golpe y replica Corte Fugaz al morir
- **Lvl 5**: distancia 8m, CD 3s
- **Lvl 10**: clon HP 50 (aguanta más de 1 golpe si el golpe es débil)
- **Lvl 15**: al aterrizar primer ataque del Danzante crit garantizado. **Forma base — cap**.
- **Evolución (+ ítem *Paso del Vacío* Tier III)**: 2 cargas con CD independiente.

### SKILL 3 — Velo Nocturno
Stealth activa. Setup para burst.

- **Tags**: `[stealth][buff][crit_setup]`
- **Tipo**: stealth activa | **Costo**: 25 MP | **CD**: 25s | **Cast**: 0.2s | **Duración**: 6s o hasta atacar
- **Efecto base**: aplica `Stealth` (`_status_effects.md §2.5` — invisible a enemigos, próximo ataque crit ×2.5), movimiento +20% velocidad
- **Lvl 5**: duración 7s
- **Lvl 10**: velocidad +30%
- **Lvl 15**: backstab desde stealth aplica daño "true" 30% del total (ignora armor + resist). **Forma base — cap**.
- **Evolución (+ ítem *Velo del Olvido* boss P75)**: al romper stealth con ataque, enemigos en 10m pierden target de vos por 2s.

### SKILL 4 — Danza de Mil Sombras (ULTIMATE)
Burst multi-hit AoE con invul.

- **Tags**: `[physical][ultimate][multihit][invul]`
- **Tipo**: ultimate burst | **Costo**: 70 MP + gasta TODOS los Combo Points actuales (min 0) | **CD**: 110s | **Cast**: 0.5s (nombre visible, Demon Slayer forma rápida)
- **Duración**: 4s. El Danzante se vuelve incorpóreo (`Invul`), realiza 20 cortes a enemigos dentro de `AOE_LARGE` 8m, distribuidos.
- **Fórmula por corte**: `physical_v2(25, weapon_dmg*0.4, DEX, level, 1.2)` × (1 + 0.2 × combo_points_gastados al activar)
- **Lvl 5**: 25 cortes
- **Lvl 10**: +45% dmg/corte
- **Lvl 15**: al terminar deja 3 clones 3s que replican Corte Fugaz (1 vez cada uno). **Forma base — cap**.
- **Evolución (+ ítem *Danza Luna Roja* boss P100)**: duración 6s, cortes 40, lifesteal 15% del total.

---

## 4. Rama Sombra (char lvl 25+) — asesino puro

### S1 — Golpe Letal (pasiva única)
- **Tags**: `[passive][crit_mult]`
- **Efecto base**: crits ×2.75 (en vez de ×1.5 base). Hits post-stealth crits ×3.5.
- **Lvl 5-15**: cada lvl +0.05× crit mult (cap ×3.5 base, ×4.5 post-stealth a lvl 15)
- **Integración**:
  - Corte Fugaz → 3er hit cadena aplica `Silence` 1.5s
  - Paso de Sombra → clon explota al final (`AOE_SMALL` 3m dmg = 50% daño absorbido, min 30)
  - Velo Nocturno → duración +2s, pero romper antes = refund 50% MP
  - Danza → cortes +20% dmg pero no-AoE (todos al target más cercano, single-target devastador)

### S2 — Flor de Sangre
Finisher melee. Gasta Combo Points para burst.

- **Tags**: `[physical][melee][combo_spend][bleed]`
- **Desbloqueo**: rama Sombra lvl 30 (requiere Dagas duales)
- **Tipo**: combo finisher melee | **Costo**: 15 MP + gasta Combo Points (min 1) | **CD**: 7s | **Cast**: 0.3s | **Rango**: `MELEE_SHORT` 2m
- **Efecto base**: 5 cortes rápidos en 0.8s al mismo target, el 5º aplica `Bleed` pesado stackeable
- **Fórmula por corte**: `physical_v2(18, weapon_dmg, DEX, level, 1.2)` × combo_mult (1.0 × / 1.8 × / 3.0 × según §1)
- **Fórmula bleed pesado/s**: `physical_v2(15, 0, DEX, level, 1.0)` 6s, stack hasta 3
- **Lvl 5**: cortes = 6
- **Lvl 10**: backstab bonus +40%
- **Lvl 15**: si target < 30% HP, ejecuta (kill directo si daño final ≥ HP restante). **Forma base — cap**.
- **Evolución (+ ítem *Flor del Loto Carmesí* Tier III)**: los bleed stackeados explotan al morir el target (`AOE_SMALL` 3m = suma de stacks × 30% dmg).

### S3 — La Sombra Elegida (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "20 kills desde stealth sin romper combate".

- **Tags**: `[stealth][execute][shadow]`
- **Trigger quest**: 20 kills desde stealth sin romper combate
- **Quest**: *"La Sombra Elegida"* — pacto P55
- **Tipo**: ultimate stealth execute | **Costo**: 50 MP + 3 Combo Points min | **CD**: 120s | **Cast**: 0.3s | **Rango**: `MELEE_SHORT`
- **Efecto base**: golpe único. Si target < 50% HP → ejecución directa (dmg = HP actual + 1). Si target ≥ 50% HP → dmg masivo + aplica `Marked` + entra en stealth automático 4s.
- **Fórmula fallback (si no ejecuta)**: `physical_v2(150, weapon_dmg*2, DEX, level, 1.5)` × combo_mult
- **Lvl 5**: ejecuta si target < 60% HP
- **Lvl 10**: el stealth post-hit dura 6s
- **Lvl 15**: ejecución cross-target — si ejecutás, el siguiente enemigo en 8m entra en modo "ejecutable" por 3s. **Forma base — cap**.

---

## 5. Rama Trickster (char lvl 25+) — evasión + control

### T1 — Reflejo Sombrío (pasiva única)
- **Tags**: `[passive][evade][auto_stealth]`
- **Efecto base**: primer golpe letal por encuentro, 50% chance de esquivar automáticamente + entrar en `Stealth` 1s
- **Lvl 5-15**: cada lvl +3% chance de esquive (cap 80% a lvl 15)
- **Integración**:
  - Corte Fugaz → cada hit aplica `Slow` stackeable 5% (max 30%)
  - Paso de Sombra → clon imita al Danzante 3s (enemigos atacan al clon random-chance 50%)
  - Velo Nocturno → al aplicar stealth, además crea 2 copias falsas que se mueven erráticas 4s
  - Danza → deja 6 clones en vez de 3 al final, cada uno dura 5s

### T2 — Lluvia de Acero
Ranged multi-hit + veneno. Finisher alterno.

- **Tags**: `[physical][ranged][poison][multihit]`
- **Desbloqueo**: rama Trickster lvl 30 (requiere Shurikens)
- **Tipo**: multi-throw ranged | **Costo**: 10 MP + gasta Combo Points (min 1, opcional) | **CD**: 3s | **Cast**: 0.2s | **Rango**: 15m
- **Efecto base**: lanza 3 shurikens en cono 30°, aplican `Poison` (canon `_status_effects.md §2.1`)
- **Fórmula por shuriken**: `physical_v2(10, weapon_dmg*0.5, DEX, level, 1.2)` × combo_mult
- **Fórmula veneno/s**: `magic_v2(4, 0, DEX, level, 1.0)` 5s (excepción — usa DEX como stat de veneno para que el Danzante tenga scaling propio)
- **Lvl 5**: cono 45° (5 shurikens)
- **Lvl 10**: veneno stack x2 (canon `Poison` stack x3 catálogo — Danzante es la clase que desbloquea max stack)
- **Lvl 15**: shurikens rebotan al siguiente enemigo si kill. **Forma base — cap**.
- **Evolución (+ ítem *Tormenta de Agujas* Tier III)**: mantener click dispara continuo mientras haya MP (2 MP/s, ritmo 3 shurikens/s).

### T3 — El Baile del Espejo (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Esquivar 100 ataques con Reflejo Sombrío".

- **Tags**: `[illusion][clone][control]`
- **Trigger quest**: esquivar 100 ataques con Reflejo Sombrío
- **Quest**: *"El Baile del Espejo"* — evento P60
- **Tipo**: ilusión masiva control | **Costo**: 60 MP + 2 Combo Points | **CD**: 90s | **Cast**: 0.5s | **Duración**: 8s
- **Efecto base**: crea 5 clones idénticos al Danzante que se mueven erráticos en `AOE_LARGE` 10m. Enemigos tienen 83% chance de atacar clones en vez del real. Cada clon absorbe 1 golpe antes de desvanecer.
- **Lvl 5**: 6 clones
- **Lvl 10**: al morir un clon, explota en `AOE_SMALL` 2m (dmg = 40% del golpe absorbido)
- **Lvl 15**: el Danzante gana `Haste` +30% durante la duración + `Stealth` pasivo mientras al menos 1 clon esté vivo. **Forma base — cap**.

---

## 6. Sinergias coop (ver `_synergies.md`)

| Con | Combo |
|-----|-------|
| Warrior | Warrior `Taunt` → Danzante backstab libre. Warrior Forma Titán + Danza simultánea = warrior absorbe, Danzante corta. |
| Mage | Supernova + Danza = Danzante inmune por Danza (`Invul`), todos los demás frita. Manipulación Atracción agrupa enemigos en zona stealth. |
| Archer | Archer `Marked` + Danzante backstab = daño "true" masivo. Voltereta + Paso de Sombra = combo evasivo dúo. |
| Necromancer | Danzante stealth + invocaciones = confusión (enemigos no saben a quién atacar). Aura Plaga + Danza burst = decisivo vs boss. |
| Cleric | Buffer sobre Danzante = ventana 8s de burst masivo. Sanador heal rápido compensa HP bajo del Danzante. |

---

## 7. FX visual

- Corte Fugaz: trails de sombra violeta-negra, hits encadenados = afterimages
- Paso de Sombra: disolución en partículas negras, reaparición en origen con chispa
- Velo Nocturno: el Danzante se desvanece entre sombras (Demon Slayer forma viento)
- Danza de Mil Sombras: 4s de afterimages superpuestos, grid de cortes visibles, nombre flotante
- Flor de Sangre: pétalos rojos flotando al finalizar el 5º corte
- La Sombra Elegida: flash negro total en pantalla al activar, target se desintegra en sombras al ejecutar
- Lluvia de Acero: destellos metálicos en trayectoria, impacto silencioso
- El Baile del Espejo: reflejos superpuestos del Danzante difuminándose, sin sonido de pasos múltiples

---

## 8. Tabla rápida — costos y CDs

| Skill | MP | Combo | CD | Gate char |
|-------|----|-------|----|-----------|
| Corte Fugaz | 0 | +1/hit | anim | 1 |
| Paso de Sombra | 10 | — | 4s | 4 |
| Velo Nocturno | 25 | — | 25s | 8 |
| Danza Mil Sombras (ult) | 70 | -all | 110s | 12 |
| Golpe Letal (S) | — passive | — | — | 25 |
| Flor de Sangre (S) | 15 | -1 to -5 | 7s | 30 |
| Sombra Elegida (S) | 50 | -3 min | 120s | 50 + quest |
| Reflejo Sombrío (T) | — passive | — | — | 25 |
| Lluvia de Acero (T) | 10 | -1 opt | 3s | 30 |
| Baile del Espejo (T) | 60 | -2 | 90s | 50 + quest |

---

## 9. Deprecated

- XP por uso descartado (canon `_system.md §7`)
- Maestría por drop → reemplazada por evolución lvl 15 + char 50
- Modelo "4 fijas + 2 variables" → reemplazado por generales + rama

Nombres originales preservados (Corte Fugaz, Paso de Sombra, Velo Nocturno, Danza de Mil Sombras, Flor de Sangre, Lluvia de Acero, Golpe Letal, Reflejo Sombrío).

---

*Canon Danzante de Sombras v2.0. Stats base son estimación — playtest puede ajustar.*
