# Necromancer — Skill Set Completo

**Versión**: 1.0 — canon
**Fecha**: 2026-04-14
**Depende**: `balance_v2.md`, `class_skills.md` §6, `systems_v2.md`
**Class mult mágico**: 1.3 | **Base stats**: INT 11 / STR 5 / DEX 5 / DEF 4 / VIT 6

---

## Resumen

| Slot | Skill | Tipo | MP | CD | Rol |
|------|-------|------|----|----|-----|
| 1 fija | Tajo de Hueso | proyectil | 5 | 0.5s | básico + lifesteal |
| 2 fija | Llamar Esqueleto | invocación | 35 | 12s | summon persistente |
| 3 fija | Maldición Marchita | debuff | 20 | 8s | DoT + -DEF |
| 4 fija | Rito del Abismo | ultimate | 80 | 150s | summon masivo / marca |
| 5a var | Aliento de Plaga | Báculo Hueso | 25 | 10s | AoE debuff |
| 5b var | Pacto de Invocación | Cetro | 30 | 15s | buff undead |

**Max invocaciones activas**: 2 base, +1 con rama Creador.

---

## SKILL 1 — Tajo de Hueso (fija)

- **Tipo**: proyectil
- **Costo**: 5 MP | **CD**: 0.5s | **Cast**: 0.2s | **Velocidad**: 20 m/s
- **Efecto base**: proyectil óseo, lifesteal 15% del daño
- **Fórmula**: `magic_v2(14, weapon_dmg, INT, level, 1.3)`
- **Escalado**: L2 +15%, L3 lifesteal 20%, L4 +45% + al kill restaura 5 MP, L5 +60% + aplica debuff "Marcado" (próximo hit +20% dmg)
- **Maestría "Tajo del Vacío"**: drop boss P50. Atraviesa paredes finas (< 1m) y armaduras (ignora 30% armor_reduction).
- **Acuática**: **Dardo de Sal** — daño +20% contra enemigos marinos (corrosión).
- **Sinergia**: Warrior aplica taunt, Necro farmea MP y HP desde distancia.

## SKILL 2 — Llamar Esqueleto (fija)

- **Tipo**: invocación persistente
- **Costo**: 35 MP | **CD**: 12s | **Cast**: 1.5s | **Duración**: persiste hasta muerte o 60s fuera de combate
- **Stats invocación (escalan con INT + level del caster)**:
  - HP = `50 + INT*4 + level*5`
  - DMG = `magic_v2(8, 0, INT, level, 0.8)`
  - Velocidad: 4 m/s, ataque melee 1.5m
- **Escalado**: L2 stats +15%, L3 al summon explota si el anterior murió (AoE 3m 30 dmg), L4 puede bloquear 1 golpe letal al caster, L5 suelta al morir restos que curan al Necro 10% HP si los recoge
- **Maestría "Capitán Esqueleto"**: drop boss P75. El esqueleto gana armadura +50% HP +30% DMG, lidera.
- **Acuática**: **Cardumen Famélico** — reemplazo = 3 pirañas con 30% stats cada una, atacan en grupo.

## SKILL 3 — Maldición Marchita (fija)

- **Tipo**: debuff ranged
- **Costo**: 20 MP | **CD**: 8s | **Cast**: 0.8s | **Rango**: 15m | **Duración**: 8s
- **Efecto base**: target recibe DoT + -15% DEF
- **Fórmula DoT**: `magic_v2(8, 0, INT, level, 1.0)` cada 1s
- **Escalado**: L2 +15% DoT, L3 duración 10s, L4 -20% DEF, L5 aplica a enemigos en 3m alrededor del primer target (spread)
- **Maestría "Marchitar del Alma"**: drop Tier III. Si target muere con maldición activa, refresca en otro enemigo cercano sin consumir MP.

## SKILL 4 — Rito del Abismo (fija, ULTIMATE)

- **Tipo**: ultimate (dual: marca o invocación masiva)
- **Costo**: 80 MP | **CD**: 150s | **Cast**: 2.5s (nombre visible, canto JJK)
- **Modos pre-cast** (toggle):
  - **Marca de Muerte**: target boss/élite recibe debuff 20s → cuando se acaba detona: `magic_v2(300, 0, INT, level, 1.3)`
  - **Legión**: invoca 4 esqueletos + 2 wraiths temporales 20s, inmortales durante duración
- **Escalado**: L2 +15% dmg marca / +2s duración legión, L3 Marca detona a full HP si el enemigo no murió dentro (refund parcial MP), L4 Legión gana +30% stats, L5 ambos modos tienen un segundo efecto espejo (Marca suelta Wraith 1; Legión deja Marca de 10s)
- **Maestría "Rito Prohibido"**: drop boss P100. Al activar, el Necro también se marca a sí mismo: gana +50% dmg por 15s pero muere si no mata 1 enemigo antes del expire.

## SKILL 5a — Aliento de Plaga (variable, BÁCULO DE HUESO)

- **Tipo**: AoE debuff cono
- **Costo**: 25 MP | **CD**: 10s | **Cast**: 0.5s | **Rango**: cono 8m
- **Efecto base**: aplica DoT débil + -10% DMG saliente 5s
- **Fórmula DoT**: `magic_v2(5, weapon_dmg*0.2, INT, level, 1.2)` /s
- **Escalado**: L2 +15%, L3 cono 10m, L4 -15% DMG, L5 enemigos que mueren con plaga sueltan nube residual 3s (mismo DoT)
- **Maestría "Plaga Viviente"**: drop Tier III. La plaga se propaga entre enemigos en 3m (infección).

## SKILL 5b — Pacto de Invocación (variable, CETRO)

- **Tipo**: buff invocaciones
- **Costo**: 30 MP | **CD**: 15s | **Cast**: 0.5s | **Duración**: 10s
- **Efecto base**: todas las invocaciones activas +40% DMG, +30% velocidad, taunt pulse cada 1s
- **Escalado**: L2 duración 12s, L3 +50% DMG, L4 durante buff las invocaciones regen 5% HP/s, L5 al expirar, si la invocación sigue viva suelta explosión 3m (50% su dmg base)
- **Maestría "Comandante de los Caídos"**: drop boss P75. Durante el buff, máx invocaciones +2 (hasta 4-5 activas).
- **Sinergia**: Cleric Buffer aplica Aura Resguardo → las invocaciones también ganan +5% resist cap (canon balance_v2).

---

## Modificadores de rama (lvl 25)

### Maldiciones
- **Pasiva única**: *Aura de Plaga* — enemigos en 5m reciben -10% DEF pasivo mientras el Necro esté vivo.
- SKILL 1 → Tajo aplica mini-maldición 3s (-5% DEF)
- SKILL 2 → el esqueleto aplica Marchita al golpear
- SKILL 3 → radio spread +2m, duración +3s
- SKILL 4 → Marca se vuelve AoE 6m (marca a todos los enemigos cerca del target)

### Creador
- **Pasiva única**: *Séquito* — +1 slot de invocación máxima (3 total base, 4 con Pacto).
- SKILL 1 → al kill tiene 20% chance de summon esqueleto mini temporal 10s
- SKILL 2 → al morir una invocación, la próxima aparece con +15% stats (stack cap 3)
- SKILL 3 → no afecta: Maldición aquí es reemplazada por **Huesos Vivientes** (AoE 4m que levanta 2 esqueletos efímeros 8s)
- SKILL 4 → Legión spawnea 6 unidades en vez de 4+2, todas con stats +20%

---

## XP por uso

Curva `50 * 1.4^n`. XP base:
- Tajo: 3 xp/hit, 5 xp/lifesteal letal
- Esqueleto: 20 xp/summon exitoso (muere = no da bonus)
- Maldición: 6 xp/aplicación + 2 por tick conectado
- Rito: 70 xp/uso (ambos modos cuentan igual)
- Aliento: 8 xp/uso + 1 por enemigo debuffeado
- Pacto: 10 xp/uso (solo si hay invocaciones vivas)

---

## Sinergias coop

| Con | Combo |
|-----|-------|
| Warrior | Invocaciones tanquean + Warrior flanquea. Embestida empuja a enemigos hacia Maldición AoE. |
| Mage | Tormenta Arcana sobre invocaciones = nadie muere, enemigos doble dmg. Pacto + Supernova = esqueletos explotan con 50% de su dmg al expirar dentro del AoE Mage. |
| Archer | Archer snipea Marca de Muerte (Rito modo Marca) para acelerar detonación. |
| Cleric | Sanador cura invocaciones igual que aliados. Buffer Aura → invocaciones +resist cap. |
| Danzante | Danzante marca target, invocaciones priorizan, Necro suma Maldición = target gone. |

---

## FX visual

- Tajo de Hueso: shard óseo rotando, trail negro-violeta, impacto en cruz de hueso
- Llamar Esqueleto: círculo de invocación en suelo, manos emergiendo (estilo Dark Souls)
- Maldición Marchita: hilos negros del Necro al target, target con veins violetas
- Rito del Abismo: círculo arcano gigante bajo el caster, apertura vertical al abismo
- Aliento de Plaga: niebla verde-violeta pulsante
- Pacto: aura roja sobre cada invocación, ojos brillantes

---

*Canon Necromancer.*
