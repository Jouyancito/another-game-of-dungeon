# Archer — Skill Set Canon

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0.
**Depende**: `_system.md`, `_status_effects.md`, `balance_v2.md`.
**Class mult físico**: 1.3 (DEX-based) | **Base stats**: DEX 12 / STR 7 / INT 4 / DEF 5 / VIT 6
**Recurso único**: **Concentración** — ver §1.

Daño Archer usa variante DEX: `physical_v2(base, weapon, DEX_total, level, 1.3)` — DEX reemplaza STR en el multiplicador.

---

## 0. Identidad

Archer es precisión pura. Premia al jugador que apunta: headshots, full charge, hits >15m. **Concentración** es el knob que separa al spammer del sniper. Ramas: **Ranger** (single-target, crit, distancia) y **Artillero** (explosivos, AoE pesado, single devastador).

---

## 1. Recurso único — Concentración

Canon `_system.md §5ter`:

- Cap 100, decae 3/s tras 10s sin disparar
- **Genera por CALIDAD de disparo** (premia skill del jugador):
  - Headshot: +10
  - Flecha full charge: +15
  - Hit a >15m: +3
  - Miss: **−5**
- **Gasta en**: skills de precisión (segunda flecha automática, crit garantizado, armor-pierce bonus)
- MP gasta: skills utility (Voltereta, Tormenta de Flechas)
- **Regla clave**: el spam no genera recurso. Premia decisiones conscientes.

---

## 2. Pool total (10 skills)

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Disparo Preciso | general | — | 1 | `[physical][projectile][single][headshot]` |
| 2 | Flecha Cargada | general | — | 4 | `[physical][projectile][charge][single]` |
| 3 | Voltereta Evasiva | general | — | 8 | `[physical][mobility][invul][AoE]` |
| 4 | Tormenta de Flechas (ult) | general | — | 12 | `[physical][ultimate][AoE][rain]` |
| R1 | Ojo del Águila (pasiva) | rama | Ranger | 25 | `[passive][crit]` |
| R2 | Ráfaga | rama | Ranger | 30 | `[physical][multishot][conc_spend]` |
| R3 | Ojo Verdadero (oculta) | rama quest | Ranger | 50 + quest | `[physical][projectile][armor_pierce]` |
| AR1 | Munición Experimental (pasiva) | rama | Artillero | 25 | `[passive][elemental][random]` |
| AR2 | Proyectil Explosivo | rama | Artillero | 30 | `[physical][AoE][explosive]` |
| AR3 | Ingeniería del Caos (oculta) | rama quest | Artillero | 50 + quest | `[physical][AoE][trap][chain]` |

---

## 3. Skills generales

### SKILL 1 — Disparo Preciso
Base del Archer. Detección de headshot del engine.

- **Tags**: `[physical][projectile][single][headshot]`
- **Tipo**: proyectil flecha | **Costo**: 0 MP | **Concentración gen**: +3 hit / +10 headshot / −5 miss | **CD**: animación (0.3s) | **Velocidad**: `PROJ_FAST` (40 m/s)
- **Fórmula**: `physical_v2(12, weapon_dmg, DEX, level, 1.3)`
- **Efecto base**: headshot detectado = crit ×1.5
- **Lvl 5**: velocidad `PROJ_FAST` 50 m/s (menos lead-time a larga distancia)
- **Lvl 10**: headshot crit ×2.0
- **Lvl 15**: atraviesa 2 enemigos en línea (dmg -20% por enemigo extra). **Forma base — cap**.
- **Evolución (+ ítem *Pergamino Ojo Verdadero* boss P50)**: **Ojo Verdadero** — crits ignoran armor_reduction.
- **Acuática**: **Arpón Ancla** — proyectil encadenado, `Slow` 50% 3s.

### SKILL 2 — Flecha Cargada
Canalización de burst single.

- **Tags**: `[physical][projectile][charge][single]`
- **Tipo**: canalizada charge | **Costo**: 5 MP al release | **Concentración gen**: +15 full charge | **CD**: 2s post-release | **Max charge**: 2s
- **Efecto base**: charge 0→100% escala dmg 1.0× → 3.5×, pierce +1 enemigo a full charge
- **Fórmula**: `physical_v2(25, weapon_dmg, DEX, level, 1.3) * charge_mult`
- **Lvl 5**: max charge 1.5s (llega más rápido al pico)
- **Lvl 10**: full charge aplica `Knockback` 3m
- **Lvl 15**: full charge = crit garantizado. **Forma base — cap**.
- **Evolución (+ ítem *Flecha del Cosmos* boss P75)**: full charge crea trail arcano, atraviesa hasta 6 enemigos.

### SKILL 3 — Voltereta Evasiva
Kiting + escape. Lo que mantiene al Archer vivo.

- **Tags**: `[physical][mobility][invul][AoE]`
- **Tipo**: dash evasivo | **Costo**: 10 MP | **CD**: 6s | **Distancia**: 5m hacia atrás o dirección apuntada
- **Efecto base**: `Invul` 0.4s durante el dash, limpia un debuff no-boss al activar
- **Lvl 5**: distancia 6m, CD 5s
- **Lvl 10**: `Invul` 0.6s
- **Lvl 15**: al terminar libera flechas 360° (8 flechas, 30% dmg base skill 1). **Forma base — cap**.
- **Evolución (+ ítem *Paso del Viento* Tier III)**: **Paso del Viento** — 2 cargas, regen 3s independiente por carga.

### SKILL 4 — Tormenta de Flechas (ULTIMATE)
- **Tags**: `[physical][ultimate][AoE][rain]`
- **Tipo**: ultimate AoE con duración | **Costo**: 60 MP + 30 Concentración | **CD**: 100s | **Cast**: 1.5s (pose One Piece, nombre visible)
- **Duración**: 6s lluvia `AOE_HUGE` 12m radio target
- **Fórmula por flecha**: `physical_v2(20, weapon_dmg*0.5, DEX, level, 1.3)` — ~2 flechas/s por enemigo dentro del área
- **Lvl 5**: duración 8s
- **Lvl 10**: aplica `Slow` 40% continuo dentro del área
- **Lvl 15**: al final explota todo el área (dmg = suma 50% de todos los impactos). **Forma base — cap**.
- **Evolución (+ ítem *Cielo de Agujas* boss P100)**: radio `AOE_HUGE` 20m, duración 10s.

---

## 4. Rama Ranger (char lvl 25+)

### R1 — Ojo del Águila (pasiva única)
- **Tags**: `[passive][crit]`
- **Efecto base**: crit chance +15% permanente. Hits a >15m crit chance +25% adicional.
- **Lvl 5-15**: cada lvl +1% crit base (cap +30%)
- **Integración**:
  - Disparo Preciso → segunda flecha automática 50% dmg si headshot
  - Flecha Cargada → charge 50% más rápida
  - Voltereta → post-dash primer disparo crit garantizado
  - Tormenta → la lluvia sigue al caster (movés dentro, la lluvia te acompaña)

### R2 — Ráfaga
- **Tags**: `[physical][multishot][conc_spend]`
- **Desbloqueo**: rama Ranger lvl 30 (requiere Arco)
- **Tipo**: multi-shot rápido | **Costo**: 15 MP + 20 Concentración | **CD**: 5s | **Cast**: 0s, dispara 5 flechas en 1s
- **Fórmula por flecha**: `physical_v2(10, weapon_dmg*0.7, DEX, level, 1.3)`
- **Lvl 5**: 6 flechas
- **Lvl 10**: CD 4s
- **Lvl 15**: la última flecha es crit garantizado + aplica `Bleed`. **Forma base — cap**.
- **Evolución (+ ítem *Ráfaga Infinita* Tier IV)**: mantener click prolonga ráfaga hasta 10 flechas (consume 2 MP extra/flecha).

### R3 — Ojo Verdadero (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "25 headshots consecutivos a enemigos tier B+".

- **Tags**: `[physical][projectile][armor_pierce]`
- **Trigger quest**: 25 headshots consecutivos a enemigos tier B+
- **Quest**: *"Ojo Verdadero"* — torre de vigía P55
- **Tipo**: disparo apuntado | **Costo**: 20 MP + 40 Concentración | **CD**: 25s | **Cast**: 1s zoom | **Rango**: ilimitado (line-of-sight)
- **Efecto base**: ignora walls ≤1m, ignora armor_reduction, crit ×4.0 garantizado si el disparo es headshot
- **Fórmula**: `physical_v2(80, weapon_dmg*2, DEX, level, 1.3)` × 4.0 si headshot, × 2.0 si torso
- **Lvl 5**: CD 20s
- **Lvl 10**: aplica `Marked` 6s al target si sobrevive
- **Lvl 15**: si el target muere con este disparo, el siguiente Ojo Verdadero dentro de 10s tiene CD 0. **Forma base — cap**.

---

## 5. Rama Artillero (char lvl 25+)

### AR1 — Munición Experimental (pasiva única)
- **Tags**: `[passive][elemental][random]`
- **Efecto base**: cada 5º disparo aplica efecto elemental random (Fuego `Burn` / Hielo `Slow` / Rayo chain 2 enemigos). Visible con color del proyectil.
- **Lvl 5-15**: cada 4º disparo a lvl 5, cada 3º a lvl 15
- **Integración**:
  - Disparo Preciso → aplica debuff stackeable -2% DEF por hit (max 10 stacks)
  - Flecha Cargada → full charge genera mini-explosión en impacto (`AOE_SMALL` 2m, 30% dmg)
  - Voltereta → deja trampa en origen (5s, AoE explosiva 3m al pisar)
  - Tormenta → reemplazada por **bombardeo**: menos proyectiles pero AoE individual 4m cada uno

### AR2 — Proyectil Explosivo
- **Tags**: `[physical][AoE][explosive]`
- **Desbloqueo**: rama Artillero lvl 30 (requiere Ballesta)
- **Tipo**: AoE pesado | **Costo**: 20 MP + 15 Concentración | **CD**: 8s | **Cast**: 0.8s | **Velocidad**: `PROJ_SLOW` (18 m/s)
- **Fórmula**: `physical_v2(50, weapon_dmg, DEX, level, 1.3)` + `AOE_SMALL` 4m
- **Lvl 5**: radio `AOE_MEDIUM` 5m
- **Lvl 10**: fragmentación (3 sub-explosiones 50% dmg + `Knockback` 3m)
- **Lvl 15**: sticky (pega al primero y detona 1s después — timing dmg ×1.5). **Forma base — cap**.
- **Evolución (+ ítem *Artillería Prototipo* Tier III)**: 3 cargas consecutivas sin CD entre ellas.

### AR3 — Ingeniería del Caos (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Kill 5 enemigos con una sola explosión".

- **Tags**: `[physical][AoE][trap][chain]`
- **Trigger quest**: kill 5 enemigos con una sola explosión
- **Quest**: *"Ingeniería del Caos"* — taller P50
- **Tipo**: deploy explosivos en cadena | **Costo**: 50 MP + 40 Concentración | **CD**: 60s | **Cast**: 0.5s
- **Efecto base**: deploy 5 cargas explosivas en el área 8m alrededor del caster. Cada carga dura 10s estática. Al detonar una (manual o por contacto), las otras detonan en cadena 0.2s delay.
- **Fórmula por carga**: `physical_v2(120, weapon_dmg, DEX, level, 1.3)` + `AOE_SMALL` 3m
- **Lvl 5**: 6 cargas
- **Lvl 10**: cada detonación aplica `Stun` 0.5s en `AOE_SMALL`
- **Lvl 15**: al detonar en cadena las 6, explota un anillo de fuego `AOE_HUGE` 12m con `Burn` 6s. **Forma base — cap**.

---

## 6. Sinergias coop (ver `_synergies.md`)

| Con | Combo |
|-----|-------|
| Warrior | Warrior taunt → Archer free-fire + headshots garantizados (target inmóvil). |
| Mage | Flecha atraviesa Tormenta Arcana → aplica elemento del Mage. Proyectil Explosivo + Barrera Prismática aliado = kiting zona segura. |
| Necromancer | Invocaciones tanquean, Archer dispara detrás. Aura Plaga (-DEF) + Ojo Verdadero = armor pierce efectivo ×2. |
| Cleric Buffer | Aura Resguardo + Archer a distancia = sustentable, Buffer Verso +20% DMG sobre Archer ventana burst. |
| Danzante | Danzante aplica `Marked` + Archer ejecuta desde distancia. Voltereta + Paso de Sombra = dúo evasivo. |

---

## 7. FX visual

- Disparo Preciso: trail fino, sonido whip
- Flecha Cargada: acumulación visible en la cuerda, glow azul → blanco → dorado según charge
- Voltereta: after-image leve, plumas verdes al aterrizar
- Tormenta de Flechas: cielo oscurece, silbido ascendente, lluvia coreana estilo One Piece
- Ráfaga: blur de brazo (Gear Second)
- Ojo Verdadero: zoom dramático con iris rojo visible, trail de luz al disparar
- Proyectil Explosivo: mecha encendida visible antes del disparo
- Ingeniería del Caos: cargas visibles como cajas con mecha, cadena visual de chispas

---

## 8. Tabla rápida — costos y CDs

| Skill | MP | Conc | CD | Gate char |
|-------|----|------|----|-----------|
| Disparo Preciso | 0 | +3/+10/-5 | anim | 1 |
| Flecha Cargada | 5 | +15 full | 2s post | 4 |
| Voltereta Evasiva | 10 | — | 6s | 8 |
| Tormenta Flechas (ult) | 60 | -30 | 100s | 12 |
| Ojo del Águila (R) | — passive | — | — | 25 |
| Ráfaga (R) | 15 | -20 | 5s | 30 |
| Ojo Verdadero (R) | 20 | -40 | 25s | 50 + quest |
| Munición Exp (AR) | — passive | — | — | 25 |
| Proyectil Explosivo (AR) | 20 | -15 | 8s | 30 |
| Ingeniería Caos (AR) | 50 | -40 | 60s | 50 + quest |

---

## 9. Deprecated

- XP por uso descartado (canon `_system.md §7`)
- Maestría por drop lvl 6 → reemplazada por evolución lvl 15 + char 50

Nombres originales preservados (Disparo Preciso, Flecha Cargada, Voltereta, Tormenta Flechas, Ráfaga, Proyectil Explosivo).

---

*Canon Archer v2.0.*
