# Archer — Skill Set Completo

**Versión**: 1.0 — canon
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md`, `class_skills.md` §5, `systems_v2.md`
**Class mult físico**: 1.3 (DEX-based) | **Base stats**: DEX 12 / STR 7 / INT 4 / DEF 5 / VIT 6

Daño Archer usa variante DEX: `physical_v2(base, weapon, DEX_total, level, 1.3)` — DEX reemplaza STR en el multiplicador.

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Disparo Preciso | proyectil | 0 | 0.3s | ataque básico |
| 2 fija | Flecha Cargada | canalizada | 5 | 2s | burst single |
| 3 fija | Voltereta Evasiva | movilidad | 10 | 6s | kiting |
| 4 fija | Tormenta de Flechas | ultimate | 60 | 100s | AoE final |
| 5a var | Ráfaga | Arco, Ranger | 15 | 5s | multi-shot rápido |
| 5b var | Proyectil Explosivo | Ballesta, Artillero | 20 | 8s | AoE pesado |

---

## SKILL 1 — Disparo Preciso (fija)

- **Tipo**: proyectil flecha
- **Costo**: 0 MP | **CD**: 0.3s | **Cast**: 0.15s draw | **Velocidad**: 40 m/s
- **Efecto base**: headshot detectado = crit ×1.5
- **Fórmula**: `physical_v2(12, weapon_dmg, DEX, level, 1.3)`
- **Escalado 1-5**:
  - L2: +15% daño
  - L3: +30%, velocidad proyectil 50 m/s (menos lead-time)
  - L4: +45%, headshot crit ×2.0
  - L5: +60%, atraviesa 2 enemigos en línea (dmg -20% por enemigo extra)
- **Maestría "Ojo Verdadero"**: drop boss P50. Crits ignoran armor_reduction.
- **Acuática**: **Arpón Ancla** — proyectil encadenado, slow 50% 3s (systems_v2)
- **Sinergia**: Warrior taunt → headshots garantizados (enemigo inmóvil mirando al Warrior).

## SKILL 2 — Flecha Cargada (fija)

- **Tipo**: canalizada (charge)
- **Costo**: 5 MP al release | **CD**: 2s post-release | **Max charge**: 2s
- **Efecto base**: charge 0→100% escala daño 1.0×→3.5×, pierce +1 enemigo a full charge
- **Fórmula**: `physical_v2(25, weapon_dmg, DEX, level, 1.3) * charge_mult`
- **Escalado**: L2 +15% base, L3 max charge 1.5s (llega más rápido al pico), L4 charge lleno aplica knockback 3m, L5 charge lleno = crit garantizado
- **Maestría "Flecha del Cosmos"**: drop boss P75. Full charge crea trail arcano, atraviesa hasta 6 enemigos.
- **Acuática**: **Arpón de Plomada** — baja +50% dmg pero hunde al enemigo al fondo 2s.

## SKILL 3 — Voltereta Evasiva (fija)

- **Tipo**: dash evasivo
- **Costo**: 10 MP | **CD**: 6s | **Distancia**: 5m hacia atrás o dirección apuntada
- **Efecto base**: invul 0.4s durante el dash, limpia un debuff no-boss al activar
- **Escalado**: L2 CD 5s, L3 dist 6m, L4 invul 0.6s, L5 al terminar libera flechas 360° (8 flechas, 30% dmg base skill 1)
- **Maestría "Paso del Viento"**: drop Tier III. 2 cargas, regen 3s independiente por carga.
- **Sinergia**: Danzante stealth + Voltereta = ambos invisibles 2s post-dash.

## SKILL 4 — Tormenta de Flechas (fija, ULTIMATE)

- **Tipo**: ultimate AoE con duración
- **Costo**: 60 MP | **CD**: 100s | **Cast**: 1.5s (pose One Piece, nombre visible)
- **Duración**: 6s lluvia AoE 12m radio target
- **Fórmula por flecha**: `physical_v2(20, weapon_dmg*0.5, DEX, level, 1.3)` — ~2 flechas/s por enemigo dentro del área
- **Escalado**: L2 +15% flecha, L3 duración 8s, L4 +45% flecha, L5 al final explota todo el área (dmg = suma 50% de todos los impactos)
- **Maestría "Cielo de Agujas"**: drop boss P100. Radio 20m, duración 10s, aplica slow 40% continuo.
- **Sinergia**: Necromancer Aura de Plaga + Tormenta = enemigos con -DEF reciben devastación.

## SKILL 5a — Ráfaga (variable, ARCO — Ranger)

- **Tipo**: multi-shot rápido
- **Costo**: 15 MP | **CD**: 5s | **Cast**: 0s, dispara 5 flechas en 1s
- **Fórmula por flecha**: `physical_v2(10, weapon_dmg*0.7, DEX, level, 1.3)`
- **Escalado**: L2 +15% por flecha, L3 6 flechas, L4 CD 4s, L5 la última flecha es crit garantizado
- **Maestría "Ráfaga Infinita"**: drop Tier IV. Mantener click prolonga ráfaga hasta 10 flechas (consume 2 MP extra/flecha).

## SKILL 5b — Proyectil Explosivo (variable, BALLESTA — Artillero)

- **Tipo**: AoE pesado
- **Costo**: 20 MP | **CD**: 8s | **Cast**: 0.8s | **Proyectil lento** 18 m/s
- **Fórmula**: `physical_v2(50, weapon_dmg, DEX, level, 1.3)` + AoE 4m
- **Escalado**: L2 +15%, L3 radio 5m, L4 +45% + fragmentación (3 sub-explosiones 50% dmg), L5 sticky (pega al primero y detona 1s después)
- **Maestría "Artillería Prototipo"**: drop Tier III. 3 cargas consecutivas sin CD entre ellas (recarga solo al gastar las 3).

---

## Modificadores de rama (lvl 25)

### Ranger
- **Pasiva única**: *Ojo del Águila* — crit chance +15% permanente. Hits a >15m crit chance +25% adicional.
- SKILL 1 → segunda flecha automática 50% dmg si headshot
- SKILL 2 → charge 50% más rápida
- SKILL 3 → post-dash primer disparo crit garantizado
- SKILL 4 → Tormenta sigue al caster (movés dentro, la lluvia te acompaña)

### Artillero
- **Pasiva única**: *Munición Experimental* — cada 5º disparo aplica efecto elemental random (fuego DoT / hielo slow / rayo chain). Visible con color del proyectil.
- SKILL 1 → aplica debuff stackeable -2% DEF por hit (max 10 stacks)
- SKILL 2 → full charge genera mini-explosión en impacto (AoE 2m, 30% dmg)
- SKILL 3 → Voltereta deja trampa en origen (5s, AoE explosiva 3m al pisar)
- SKILL 4 → lluvia reemplazada por **bombardeo**: menos proyectiles pero AoE individual 4m cada uno

---

## XP por uso

Curva `50 * 1.4^n`. XP base:
- Disparo Preciso: 2 xp/hit, 5 xp/headshot
- Flecha Cargada: 4 xp/disparo, +1 por % de charge (max 7)
- Voltereta: 8 xp/uso, 15 xp si evita golpe letal detectado
- Tormenta: 60 xp/uso
- Ráfaga: 3 xp/flecha conectada
- Explosivo: 10 xp/uso + 2 por enemigo en AoE

---

## Sinergias coop

| Con | Combo |
|-----|-------|
| Warrior | Arrow-slow + Embestida = crit garantizado Warrior. Warrior taunt → Archer free-fire. |
| Mage | Flecha atraviesa Tormenta Arcana → aplica elemento. Explosivo + Barrera Prismática del Mage en aliado = kiting zona segura. |
| Necromancer | Invocaciones tanquean, Archer dispara detrás. Aura Plaga + Tormenta = devastación. |
| Cleric | Buffer sobre Archer = +15% DMG + sostenible. Exorcista + Artillero munición exp vs undead = resonancia. |
| Danzante | Danzante marca target (debuff +25% dmg recibido), Archer ejecuta desde distancia. |

---

## FX visual

- Disparo Preciso: trail fino, sonido whip
- Flecha Cargada: acumulación visible en la cuerda, glow azul → blanco → dorado según charge
- Voltereta: after-image leve, plumas verdes al aterrizar
- Tormenta de Flechas: cielo oscurece, silbido ascendente, lluvia coreana estilo One Piece
- Ráfaga: blur de brazo (Gear Second)
- Explosivo: mecha encendida visible antes del disparo

---

*Canon Archer.*
