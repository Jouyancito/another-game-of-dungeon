# Necromancer — Skill Set Canon

> Lore + identidad cultural: ver `game/docs/lore/_class_lore_necromancer.md`

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0.
**Depende**: `_system.md`, `_status_effects.md` (Plague único Necro §2.1), `balance_v2.md`.
**Class mult mágico**: 1.3 | **Base stats**: INT 11 / STR 5 / DEX 5 / DEF 4 / VIT 6
**Recurso único**: **Vida como recurso** — ver §1.

---

## 0. Identidad

Necromancer es el "pagas con sangre" del party. Gasta HP (no solo MP) para skills de alto impacto. Fantasía visual: **venas negras** en el personaje mientras hay invocaciones activas. Dos ramas: **Maldiciones** (debuffs persistentes, DEF shred cross-party) y **Creador** (summons escalables, séquito tanquea mientras el Necro casteaba detrás).

---

## 1. Recurso único — Vida (HP cost)

Canon `_system.md §5ter`:

- **Algunas skills cuestan HP directa en vez de MP** (o además):
  - Llamar Esqueleto: **-15% HP max** (tope baja mientras invocación viva, retorna al morir la invocación)
  - Pacto de Invocación: -10% HP current instantáneo
  - Maldición Marchita upgrade: drain 2% HP/s durante duración
- **Lifesteal** de Tajo de Hueso restaura gradual
- MP gasta: tajos, maldiciones, auras
- **Fantasía visual**: venas negras en el personaje mientras tiene invocaciones activas (intensifica con stack de summons)

---

## 2. Pool total (10 skills)

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Tajo de Hueso | general | — | 1 | `[magic][projectile][lifesteal][bone]` |
| 2 | Llamar Esqueleto | general | — | 4 | `[summon][persistent][hp_cost]` |
| 3 | Maldición Marchita | general | — | 8 | `[magic][curse][DoT][debuff]` |
| 4 | Rito del Abismo (ult) | general | — | 12 | `[magic][ultimate][dual_mode]` |
| M1 | Aura de Plaga (pasiva) | rama | Maldiciones | 25 | `[passive][aura][def_shred]` |
| M2 | Aliento de Plaga | rama | Maldiciones | 30 | `[magic][AoE][plague][cone]` |
| M3 | El Pacto de la Marchita (oculta) | rama quest | Maldiciones | 50 + quest | `[magic][AoE][curse_chain]` |
| C1 | Séquito (pasiva) | rama | Creador | 25 | `[passive][summon_cap]` |
| C2 | Pacto de Invocación | rama | Creador | 30 | `[summon][buff][hp_cost]` |
| C3 | El Señor de los Caídos (oculta) | rama quest | Creador | 50 + quest | `[summon][mass][persistent]` |

---

## 3. Skills generales

### SKILL 1 — Tajo de Hueso
Proyectil básico con lifesteal. Identidad "pagar con sangre, recuperar con sangre".

- **Tags**: `[magic][projectile][lifesteal][bone]`
- **Tipo**: proyectil | **Costo**: 5 MP | **CD**: animación (0.5s) | **Cast**: 0.2s | **Velocidad**: `PROJ_MED` 20 m/s
- **Efecto base**: proyectil óseo, **lifesteal 15% del daño**
- **Fórmula**: `magic_v2(14, weapon_dmg, INT, level, 1.3)`
- **Lvl 5**: lifesteal 20%
- **Lvl 10**: al kill restaura 5 MP
- **Lvl 15**: aplica `Marked` 3s al target (próximo hit +20% dmg). **Forma base — cap**.
- **Evolución (+ ítem *Tajo del Vacío* boss P50)**: atraviesa paredes finas (<1m) y armaduras (ignora 30% armor_reduction).
- **Acuática**: **Dardo de Sal** — dmg +20% contra enemigos marinos (corrosión).

### SKILL 2 — Llamar Esqueleto
Invocación persistente. Core identity.

- **Tags**: `[summon][persistent][hp_cost]`
- **Tipo**: invocación | **Costo**: 35 MP + **-15% HP max** (tope baja mientras esqueleto vivo, retorna al morir) | **CD**: 12s | **Cast**: 1.5s | **Duración**: persiste hasta muerte o 60s fuera de combate
- **Stats invocación** (escalan con INT + level del caster):
  - HP = `50 + INT*4 + level*5`
  - DMG = `magic_v2(8, 0, INT, level, 0.8)`
  - Velocidad: 4 m/s, ataque melee 1.5m
- **Max invocaciones activas**: 2 base (3 con pasiva Séquito rama Creador, +1 con Pacto = 4)
- **Lvl 5**: stats invocación +15%
- **Lvl 10**: al summon si el anterior murió, explota en `AOE_SMALL` 3m (30 dmg + `Fear` 1s)
- **Lvl 15**: el esqueleto puede bloquear 1 golpe letal al Necro (se sacrifica, dies). **Forma base — cap**.
- **Evolución (+ ítem *Capitán Esqueleto* boss P75)**: gana armadura +50% HP +30% DMG, lidera (otras invocaciones +10% DMG cerca).
- **Acuática**: **Cardumen Famélico** — 3 pirañas con 30% stats cada una, atacan en grupo.

### SKILL 3 — Maldición Marchita
Debuff ranged. Setup para DPS del party.

- **Tags**: `[magic][curse][DoT][debuff]`
- **Tipo**: debuff ranged | **Costo**: 20 MP | **CD**: 8s | **Cast**: 0.8s | **Rango**: 15m | **Duración**: 8s
- **Efecto base**: target recibe DoT + `-15% DEF` (stackea con aura Plaga rama)
- **Fórmula DoT**: `magic_v2(8, 0, INT, level, 1.0)` cada 1s — aplica `Plague` canon `_status_effects.md §2.1`
- **Lvl 5**: duración 10s
- **Lvl 10**: -20% DEF
- **Lvl 15**: aplica a enemigos en 3m alrededor del primer target (spread inicial). **Forma base — cap**.
- **Evolución (+ ítem *Marchitar del Alma* Tier III)**: si target muere con maldición activa, refresca en otro enemigo cercano sin consumir MP.

### SKILL 4 — Rito del Abismo (ULTIMATE)
Dual-mode: marcar a un solo boss o invocar legión.

- **Tags**: `[magic][ultimate][dual_mode]`
- **Tipo**: ultimate dual | **Costo**: 80 MP + **-10% HP current** | **CD**: 150s | **Cast**: 2.5s (nombre visible, canto JJK)
- **Modos pre-cast** (toggle):
  - **Marca de Muerte**: target boss/élite recibe debuff 20s → cuando se acaba detona: `magic_v2(300, 0, INT, level, 1.3)` + aplica `Vulnerable` 8s a sobrevivientes
  - **Legión**: invoca 4 esqueletos + 2 wraiths temporales 20s, inmortales durante duración
- **Lvl 5**: +15% dmg marca / +2s duración legión
- **Lvl 10**: Marca detona a full HP si el enemigo no murió dentro (refund 50% MP). Legión +30% stats.
- **Lvl 15**: ambos modos tienen un segundo efecto espejo (Marca suelta Wraith 1 al detonar; Legión deja Marca de 10s al expirar sobre el enemigo con más HP). **Forma base — cap**.
- **Evolución (+ ítem *Rito Prohibido* boss P100)**: al activar el Necro también se marca a sí mismo: gana +50% dmg por 15s pero muere si no mata 1 enemigo antes del expire.

---

## 4. Rama Maldiciones (char lvl 25+)

### M1 — Aura de Plaga (pasiva única)
- **Tags**: `[passive][aura][def_shred]`
- **Efecto base**: enemigos en `PULSO_AURA` 5m reciben `-10% DEF` pasivo mientras el Necro vivo
- **Lvl 5-15**: cada lvl +1% DEF shred (cap -25% a lvl 15)
- **Integración**:
  - Tajo de Hueso → aplica mini-maldición 3s (-5% DEF adicional)
  - Llamar Esqueleto → el esqueleto aplica `Plague` al golpear
  - Maldición Marchita → radio spread +2m, duración +3s
  - Rito Marca → se vuelve AoE 6m (marca a todos los enemigos cerca del target)

### M2 — Aliento de Plaga
- **Tags**: `[magic][AoE][plague][cone]`
- **Desbloqueo**: rama Maldiciones lvl 30 (requiere Báculo de Hueso)
- **Tipo**: AoE debuff cono | **Costo**: 25 MP | **CD**: 10s | **Cast**: 0.5s | **Rango**: cono 8m
- **Efecto base**: aplica `Plague` DoT débil + `Weak` -10% DMG saliente 5s
- **Fórmula DoT**: `magic_v2(5, weapon_dmg*0.2, INT, level, 1.2)` /s
- **Lvl 5**: cono 10m
- **Lvl 10**: `Weak` -15%
- **Lvl 15**: enemigos que mueren con plaga sueltan nube residual 3s (mismo DoT) — `Plagued Land` combo canon `_status_effects.md §3`. **Forma base — cap**.
- **Evolución (+ ítem *Plaga Viviente* Tier III)**: la plaga se propaga entre enemigos en 3m (infección).

### M3 — El Pacto de la Marchita (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Matar 100 enemigos con maldiciones activas".

- **Tags**: `[magic][AoE][curse_chain]`
- **Trigger quest**: matar 100 enemigos con maldiciones (Marchita o Plague) activas
- **Quest**: *"El Pacto de la Marchita"* — altar P60
- **Tipo**: AoE curse chain | **Costo**: 60 MP + **-5% HP max 15s** | **CD**: 90s | **Cast**: 1.2s | **Rango**: `AOE_HUGE` 12m radio
- **Efecto base**: todos los enemigos en rango reciben `Plague` máxima duración (+50% base) + `Cursed` (`_status_effects.md §2.5` — no se pueden curar durante 4s) + `-30% DEF` 10s. Cada muerte durante duración propaga status a enemigos en 5m.
- **Lvl 5**: `-35% DEF`
- **Lvl 10**: la propagación por kill se extiende a 8m
- **Lvl 15**: enemigos que mueren con el combo curse+plague sueltan un wraith temporal 8s (max 5 activos). **Forma base — cap**.

---

## 5. Rama Creador (char lvl 25+)

### C1 — Séquito (pasiva única)
- **Tags**: `[passive][summon_cap]`
- **Efecto base**: +1 slot de invocación máxima (3 total base, 4 con Pacto)
- **Lvl 5-15**: cada 3 lvl + 1 slot extra temporal (cap 4 base permanente + 2 temporales = 6 con setup completo)
- **Integración**:
  - Tajo de Hueso → al kill tiene 20% chance de summon esqueleto mini temporal 10s
  - Llamar Esqueleto → al morir una invocación, la próxima aparece con +15% stats (stack cap 3)
  - Maldición Marchita → reemplazada por **Huesos Vivientes** (`AOE_SMALL` 4m que levanta 2 esqueletos efímeros 8s)
  - Rito Legión → spawnea 6 unidades en vez de 4+2, todas con stats +20%

### C2 — Pacto de Invocación
- **Tags**: `[summon][buff][hp_cost]`
- **Desbloqueo**: rama Creador lvl 30 (requiere Cetro)
- **Tipo**: buff invocaciones | **Costo**: 30 MP + **-10% HP current** | **CD**: 15s | **Cast**: 0.5s | **Duración**: 10s
- **Efecto base**: todas las invocaciones activas +40% DMG, +30% velocidad, `Taunt` pulse cada 1s
- **Lvl 5**: duración 12s
- **Lvl 10**: invocaciones regen 5% HP/s durante buff + +50% DMG
- **Lvl 15**: al expirar, si la invocación sigue viva suelta explosión 3m (50% su dmg base). **Forma base — cap**.
- **Evolución (+ ítem *Comandante de los Caídos* boss P75)**: durante buff, max invocaciones +2 (hasta 6 activas temporalmente).

### C3 — El Señor de los Caídos (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Mantener 3 invocaciones vivas por 10 min reales".

- **Tags**: `[summon][mass][persistent]`
- **Trigger quest**: mantener 3 invocaciones vivas por 10 min reales acumulados
- **Quest**: *"El Señor de los Caídos"* — cripta P55
- **Tipo**: summon masivo persistente | **Costo**: 100 MP + **-20% HP max 30s** | **CD**: 240s | **Cast**: 2s | **Duración**: 20s invocaciones, persisten hasta muerte o expiración
- **Efecto base**: **Alzamiento** — revive a TODOS los enemigos humanoides muertos en 30m radio como undead temporales 60s. Cap 10 unidades.
- **Fórmula por unidad**: hereda 80% de los stats originales del enemigo muerto, sirve al Necro.
- **Lvl 5**: radio 35m
- **Lvl 10**: cap 12 unidades
- **Lvl 15**: 2 de las unidades invocadas son "champions" (150% stats). **Forma base — cap**.

---

## 6. Sinergias coop (ver `_synergies.md`)

| Con | Combo |
|-----|-------|
| Warrior | Invocaciones tanquean + Warrior flanquea. Embestida empuja enemigos hacia Maldición AoE. |
| Mage | Tormenta Arcana sobre invocaciones = nadie muere, enemigos doble dmg. Pacto + Supernova = esqueletos explotan al expirar dentro del AoE. |
| Archer | Archer snipea Marca de Muerte (Rito modo Marca) para acelerar detonación. Ojo Verdadero + Aura Plaga armor-shred = crit armor-pierce devastador. |
| Cleric | Aura Resguardo aplica a invocaciones (canon balance_v2). Exorcista funciona AL REVÉS (undead del Necro reciben dmg sagrado) — coord explícita. |
| Danzante | Danzante marca target, invocaciones priorizan, Necro suma Maldición = target eliminado. |

---

## 7. FX visual

- Tajo de Hueso: shard óseo rotando, trail negro-violeta, impacto en cruz de hueso
- Llamar Esqueleto: círculo de invocación en suelo, manos emergiendo (estilo Dark Souls)
- Maldición Marchita: hilos negros del Necro al target, target con veins violetas
- Rito del Abismo: círculo arcano gigante bajo el caster, apertura vertical al abismo
- Aliento de Plaga: niebla verde-violeta pulsante
- Pacto de Invocación: aura roja sobre cada invocación, ojos brillantes
- El Pacto de la Marchita: suelo se vuelve violeta-verde podrido en radio, enemigos con tinte marchito
- El Señor de los Caídos: manos emergen masivas del suelo, enemigos muertos se reaniman con glow violeta

---

## 8. Tabla rápida — costos y CDs

| Skill | MP | HP cost | CD | Gate char |
|-------|----|---------|----|-----------|
| Tajo de Hueso | 5 | — / +15% lifesteal | anim | 1 |
| Llamar Esqueleto | 35 | -15% HP max | 12s | 4 |
| Maldición Marchita | 20 | — | 8s | 8 |
| Rito del Abismo (ult) | 80 | -10% HP current | 150s | 12 |
| Aura Plaga (M) | — passive | — | — | 25 |
| Aliento Plaga (M) | 25 | — | 10s | 30 |
| Pacto Marchita (M) | 60 | -5% HP max 15s | 90s | 50 + quest |
| Séquito (C) | — passive | — | — | 25 |
| Pacto Invocación (C) | 30 | -10% HP current | 15s | 30 |
| Señor Caídos (C) | 100 | -20% HP max 30s | 240s | 50 + quest |

---

## 9. Deprecated

- XP por uso descartado (canon `_system.md §7`)
- Maestría por drop → reemplazada por evolución lvl 15 + char 50
- Modelo "4 fijas + 2 variables" → reemplazado por generales + rama

Nombres originales preservados (Tajo de Hueso, Llamar Esqueleto, Maldición Marchita, Rito del Abismo, Aura Plaga, Aliento Plaga, Séquito, Pacto Invocación).

---

*Canon Necromancer v2.0.*
