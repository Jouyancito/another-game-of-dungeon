# Class Skills — Dungeon Party

**Versión**: 1.0 (PLACEHOLDERS — rellenar iterando)
**Fecha**: 2026-04-12
**Estado**: Draft — estructura completa con skills por llenar
**Departamento**: Game Design
**Relacionado**: `stats_system.md`, `balance_v2.md`, `systems_v2.md`, `DESIGN_BRIEF.md`

---

## 0. Cómo usar este doc

Cada clase tiene **6 skills**:
- **4 fijas** (siempre disponibles para cualquier build de la clase)
- **2 variables** (dependen del **weapon type** equipado)

La especialización del lvl 25 (rama) NO agrega skills nuevas — **modifica cómo funcionan las 4 fijas** (y a veces las variables también).

Además existen **skills pasivas** desbloqueables por quest/drop raro. Se listan aparte.

---

## 1. Estructura de una skill (template)

Cada skill se completa con:

```
### [Nombre de la skill]
- **Tipo**: activa / pasiva / canalizada / toggle
- **Slot**: fija (1-4) / variable (weapon: X)
- **Costo**: X MP (o 0 si gratis)
- **Cooldown**: X s
- **Cast time**: X s (0 si instantáneo)
- **Efecto base**: descripción corta del efecto
- **Fórmula daño/heal**: alineada con balance_v2 compound
- **Escalado por uso (XP 1-5)**:
    - Lvl 1: base
    - Lvl 2: +15% poder / -10% cost
    - Lvl 3: +30% poder / -20% cost
    - Lvl 4: +45% poder / efecto nuevo
    - Lvl 5: +60% poder / efecto maestro
- **Maestría**: condición para desbloquear lvl Master (drop boss / quest / item)
- **Versión acuática**: si aplica (reemplazo subacuático)
- **Sinergias coop**: combos con otras clases
- **FX visual**: referencia (Demon Slayer / JJK / One Piece)
```

---

## 2. Modificadores por especialización (lvl 25)

Cada clase elige 1 de 2-3 ramas al nivel 25. La rama modifica las 4 skills fijas y desbloquea **1 pasiva de rama única**.

| Clase | Ramas | Pasiva de rama (ejemplos) |
|-------|-------|----------------------------|
| Warrior | Tank / Berserker | Tank: "Postura de Muralla" — 50% más block chance con escudo |
| | | Berserker: "Furia Creciente" — +2% daño por cada 10% HP perdido |
| Mage | Elementalista / Arcano | Elementalista: elige sub-elemento (Fuego/Hielo/Rayo) al lvl 25, +30% daño de ese elemento |
| | | Arcano: "Distorsión Espacial" — teleport corto como dash (cooldown 12s) |
| Archer | Ranger / Artillero | Ranger: "Ojo del Águila" — crit chance +15% permanente |
| | | Artillero: "Munición Experimental" — cada 5º disparo aplica efecto elemental random |
| Necromancer | Maldiciones / Creador | Maldiciones: "Aura de Plaga" — enemigos en 5m reciben -10% DEF |
| | | Creador: "Séquito" — +1 invocación máxima |
| Cleric | Sanador / Buffer / Exorcista | Sanador: "Gracia Infinita" — heals críticos al 50% chance |
| | | Buffer: "Aura de Resguardo" — +5% resist cap aliados en 20m (ya canon balance_v2) |
| | | Exorcista: "Luz Sagrada" — daño a undead/void +50% |
| Danzante | TBD | TBD |

---

## 3. WARRIOR — 6 skills (4 fijas + 2 variables)

### 3.1 Skills fijas

#### SKILL 1: `[TBD — ataque básico mejorado]`
- Tipo:
- Slot: fija 1
- Costo:
- Cooldown:
- Cast time:
- Efecto base:
- Fórmula:
- Escalado 1-5:
- Maestría:
- Versión acuática:
- Sinergias coop:
- FX visual:

*Notas*: placeholder. Probable = mejora del ataque click básico (puñetazo pesado + combo ya implementado en prototipo).

#### SKILL 2: `[TBD — carga / embestida]`
- Tipo:
- Slot: fija 2
- (llenar)

*Notas*: movement + daño. Posible reemplazo acuático = Puño de Marea (systems_v2 §1.5).

#### SKILL 3: `[TBD — grito de guerra / aura]`
- Tipo: toggle o activa
- Slot: fija 3
- (llenar)

*Notas*: aura buff/debuff. Buff aliados o debuff enemigos cercanos.

#### SKILL 4: `[TBD — ultimate, habilidad grande]`
- Tipo: activa ultimate
- Slot: fija 4
- (llenar)

*Notas*: ultimate cinemático. Nombre visible al cast (canon brief §3 estilo Demon Slayer). Ejemplo placeholder: "Estilo de Hierro: Forma del Titán".

### 3.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con ESCUDO]`
- Tipo:
- Slot: variable (weapon: Escudo, 1-hand)
- (llenar)

*Notas*: bloqueo activo, taunt, escudo lanzable. Referencia "Bloqueo Perfecto" stats_system.md.

#### SKILL 5b: `[TBD — variable con ESPADÓN]`
- Tipo:
- Slot: variable (weapon: Espadón, 2-hand)
- (llenar)

*Notas*: giro de espada, corte pesado. Referencia "Giro de Espada" stats_system.md.

### 3.3 Pasivas de rama (lvl 25)

- **Tank**: "Postura de Muralla" — [definir]
- **Berserker**: "Furia Creciente" — [definir, VIT → daño bonus ya canon]

---

## 4. MAGE — 6 skills (4 fijas + 2 variables)

### 4.1 Skills fijas

#### SKILL 1: `[TBD — proyectil básico arcano]`
- Tipo:
- Slot: fija 1
- (llenar)

*Notas*: ya implementado como "bolita de energía". Base de cualquier build de Mago.

#### SKILL 2: `[TBD — AoE / control]`
- Tipo:
- Slot: fija 2
- (llenar)

*Notas*: daño de área, control de muchedumbre. Canalizado tipo rayo ya implementado.

#### SKILL 3: `[TBD — defensivo / escudo]`
- Tipo:
- Slot: fija 3
- (llenar)

*Notas*: escudo mágico, barrera temporal, reflejo de hechizos.

#### SKILL 4: `[TBD — ultimate]`
- Tipo: activa ultimate
- Slot: fija 4
- (llenar)

*Notas*: ultimate grande. Ejemplo placeholder: "Arte Arcano: Supernova". Referencia JJK cast dramático.

### 4.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con BASTÓN elementalista]`
- Tipo:
- Slot: variable (weapon: Bastón)
- (llenar)

*Notas*: enfoca elemento. Fuego/Hielo/Rayo intercambiables. Daño puro.

#### SKILL 5b: `[TBD — variable con LIBRO arcano]`
- Tipo:
- Slot: variable (weapon: Libro/Tomo)
- (llenar)

*Notas*: manipulación espacial, portales, teleport, empuje/atracción.

### 4.3 Pasivas de rama (lvl 25)

- **Elementalista**: sub-elemento fijo + "Maestría Elemental" — [definir]
- **Arcano**: "Distorsión Espacial" — [definir]

---

## 5. ARCHER — 6 skills (4 fijas + 2 variables)

### 5.1 Skills fijas

#### SKILL 1: `[TBD — disparo básico mejorado]`
- Tipo:
- Slot: fija 1
- (llenar)

*Notas*: ya implementado como flecha básica. Base DEX.

#### SKILL 2: `[TBD — flecha cargada / especial]`
- Tipo: canalizada (carga)
- Slot: fija 2
- (llenar)

*Notas*: carga = más daño. Referencia "Flecha Cargada" de stats_system. Reemplazo acuático = Arpón Ancla.

#### SKILL 3: `[TBD — movilidad / dash / salto]`
- Tipo:
- Slot: fija 3
- (llenar)

*Notas*: kiting, escape, reposicionamiento. El Archer necesita distancia.

#### SKILL 4: `[TBD — ultimate]`
- Tipo: activa ultimate
- Slot: fija 4
- (llenar)

*Notas*: ultimate. Ejemplo: "Tormenta de Flechas" (Ranger) o "Bombardeo" (Artillero). Estilo One Piece (pose + nombre visible).

### 5.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con ARCO]`
- Tipo:
- Slot: variable (weapon: Arco, Ranger)
- (llenar)

*Notas*: rapid fire, dual shot, precisión. Drop-off mínimo.

#### SKILL 5b: `[TBD — variable con BALLESTA / ARTILLERÍA]`
- Tipo:
- Slot: variable (weapon: Ballesta o Artillería, Artillero)
- (llenar)

*Notas*: explosivos, proyectiles pesados, single-target devastador. Lento pero letal.

### 5.3 Pasivas de rama (lvl 25)

- **Ranger**: "Ojo del Águila" — [definir]
- **Artillero**: "Munición Experimental" — [definir]

---

## 6. NECROMANCER — 6 skills (4 fijas + 2 variables)

### 6.1 Skills fijas

#### SKILL 1: `[TBD — proyectil de muerte / vida-drenadora]`
- Tipo:
- Slot: fija 1
- (llenar)

*Notas*: ya implementado como `necro_projectile`. Base INT.

#### SKILL 2: `[TBD — invocación básica]`
- Tipo: activa
- Slot: fija 2
- (llenar)

*Notas*: esqueleto guerrero o similar. Reemplazo acuático = Cardumen Famélico (pirañas).

#### SKILL 3: `[TBD — debuff / maldición]`
- Tipo:
- Slot: fija 3
- (llenar)

*Notas*: aplica status a enemigos (slow, weakness, poison). Tematiza la clase.

#### SKILL 4: `[TBD — ultimate]`
- Tipo: activa ultimate
- Slot: fija 4
- (llenar)

*Notas*: ejemplo: "Rito del Abismo" (invoca múltiples undead a la vez) o "Marcado de la Muerte". Estilo JJK.

### 6.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con BÁCULO DE HUESO (Maldiciones)]`
- Tipo:
- Slot: variable (weapon: Báculo de Hueso)
- (llenar)

*Notas*: maldiciones fuertes, debuffs de largo alcance.

#### SKILL 5b: `[TBD — variable con CETRO DE INVOCACIÓN (Creador)]`
- Tipo:
- Slot: variable (weapon: Cetro)
- (llenar)

*Notas*: invocaciones mejoradas, +1 slot de invocación activa.

### 6.3 Pasivas de rama (lvl 25)

- **Maldiciones**: "Aura de Plaga" — [definir]
- **Creador**: "Séquito" — [definir]

---

## 7. CLERIC / HEALER — 6 skills (4 fijas + 2 variables)

### 7.1 Skills fijas

#### SKILL 1: `[TBD — heal directo básico]`
- Tipo:
- Slot: fija 1
- (llenar)

*Notas*: heal instantáneo target único. Base INT. Reemplazo acuático = Burbuja Vivificante (heal+escudo).

#### SKILL 2: `[TBD — heal AoE / regen]`
- Tipo: canalizada o instantánea
- Slot: fija 2
- (llenar)

*Notas*: heal en área, regen prolongado.

#### SKILL 3: `[TBD — buff / protección]`
- Tipo: toggle o activa
- Slot: fija 3
- (llenar)

*Notas*: resist temporal, escudo, inmunidad status breve.

#### SKILL 4: `[TBD — ultimate]`
- Tipo: activa ultimate
- Slot: fija 4
- (llenar)

*Notas*: ultimate. Ejemplo: "Resurrección" (revive aliado caído una vez por run) o "Juicio Sagrado" (Exorcista, daño masivo a undead). Referencia Demon Slayer estilo canto.

### 7.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con BÁCULO SAGRADO (Sanador)]`
- Tipo:
- Slot: variable (weapon: Báculo Sagrado)
- (llenar)

*Notas*: heal enfocado. Aumenta efectividad de heals fijos.

#### SKILL 5b: `[TBD — variable con LIBRO DE ORACIONES (Buffer / Exorcista)]`
- Tipo:
- Slot: variable (weapon: Libro de Oraciones)
- (llenar)

*Notas*: buffs o daño sagrado según rama lvl 25.

### 7.3 Pasivas de rama (lvl 25)

- **Sanador**: "Gracia Infinita" — [definir]
- **Buffer**: **Aura de Resguardo** — +5% resist cap aliados radio 20m, pierde al caer (canon balance_v2 §2.6)
- **Exorcista**: "Luz Sagrada" — [definir]

---

## 8. DANZANTE DE SOMBRAS — 6 skills (PLACEHOLDER — clase nueva)

**Nota**: clase mencionada en brief §8.15 (masa 2.0, más liviano). Sin definición previa. **Skills a crear from scratch**.

Concepto propuesto (editar):
- Rol: mobilidad extrema, asesino burst, stealth
- Stats base estimados: DEX muy alto, STR medio, INT bajo, DEF bajo, VIT medio
- HP base: 85, MP base: 80

### 8.1 Skills fijas

#### SKILL 1: `[TBD — ataque rápido / combo ligero]`
- Slot: fija 1
- (llenar)

#### SKILL 2: `[TBD — dash / sombra / teleport corto]`
- Slot: fija 2
- (llenar)

*Notas*: movilidad característica. Quizás "Paso de Sombra" — dash que deja clon breve.

#### SKILL 3: `[TBD — stealth / invisibilidad temporal]`
- Slot: fija 3
- (llenar)

*Notas*: entra en stealth X s, primer ataque es crítico.

#### SKILL 4: `[TBD — ultimate]`
- Slot: fija 4
- (llenar)

*Notas*: ultimate. Ejemplo: "Danza de Mil Sombras" (múltiples golpes en área). Estilo Demon Slayer forma rápida.

### 8.2 Skills variables (por weapon)

#### SKILL 5a: `[TBD — variable con DAGAS]`
- Slot: variable (weapon: Dagas duales)
- (llenar)

*Notas*: melee rápido, sangrado, backstab.

#### SKILL 5b: `[TBD — variable con SHURIKENS / ARMAS ARROJADIZAS]`
- Slot: variable (weapon: Shurikens)
- (llenar)

*Notas*: rango corto, multi-target, aplica veneno.

### 8.3 Pasivas de rama (lvl 25)

- **Rama TBD 1**: TBD
- **Rama TBD 2**: TBD

---

## 9. Sinergias coop entre clases (matriz)

Tabla vacía para rellenar. Cada celda = combo específico entre 2 clases que da efecto emergente.

| Clase A → Clase B | Warrior | Mage | Archer | Necromancer | Cleric | Danzante |
|-------------------|---------|------|--------|-------------|--------|----------|
| **Warrior** | — | TBD | TBD | TBD | TBD | TBD |
| **Mage** | TBD | — | TBD | TBD | TBD | TBD |
| **Archer** | TBD | TBD | — | TBD | TBD | TBD |
| **Necromancer** | TBD | TBD | TBD | — | TBD | TBD |
| **Cleric** | TBD | TBD | TBD | TBD | — | TBD |
| **Danzante** | TBD | TBD | TBD | TBD | TBD | — |

Ejemplos del brief/stats_system para inspirar:
- **Mage + Warrior**: Mage encanta arma del Warrior con elemento por X s
- **Cleric Buffer + cualquier clase**: aliado recibe +5% resist cap (Aura de Resguardo)
- **Archer + Necro**: flechas del Archer atraviesan invocaciones sin dañarlas
- **Warrior Tank + Cleric**: Warrior taunts, Cleric heal en ráfaga al que tanqueó

---

## 10. Pasivas especiales desbloqueables (fuera del set de 6)

Skills pasivas que se desbloquean por quest/drop/milestone, no vienen con la clase:

| Pasiva | Cómo se desbloquea | Efecto | Clase |
|--------|---------------------|--------|-------|
| **Corazón Voraz** | Quest Piso 50 "El Primer Aventurero" | Habilita sistema polimorfismo (systems_v2 §4) | Cualquier clase |
| **Aura de Resguardo** | Pasiva de rama Buffer al lvl 25 | +5% resist cap aliados radio 20m (canon balance_v2) | Cleric Buffer |
| **Equilibrio Térmico** | Quest alternativa rama Buffer lvl 30 | -50% efectos temperatura a aliados en 20m | Cleric Buffer |
| **Maestría de Habilidad** | Drop pergamino de boss | Sube skill específica a nivel Master | Todas |
| **TBD** | | | |

---

## 11. Reglas transversales

### 11.1 Hotbar
- 8 slots en HUD (canon actual)
- 4 fijas en slots 1-4
- 2 variables en 5-6 (cambian según weapon equipado)
- Slots 7-8: consumibles (pociones, shards, transformaciones, fuegos artificiales)

### 11.2 Escalado por uso — XP de skill (balance_v2 §6)
Cada vez que usás una skill, gana XP. Cada habilidad tiene su propia curva:

```
xp_por_uso = base_xp_skill × multiplicador_situacional
xp_para_siguiente_nivel = base_skill × curva^nivel_actual
```

Multiplicadores situacionales:
- Kill con la skill: ×2.0
- Hit a boss: ×1.5
- Miss: ×0.3 (algo de XP igual — aprendés de errores)
- Uso sin enemigo cerca: ×0.1 (anti-farming)

### 11.3 Maestría
Nivel **6** por encima del nivel 5, NO se sube con uso. Requiere:
- Drop Pergamino de Maestría [Skill] (boss específico por skill, ver pool)
- O quest especial asociada
- O item consumible raro de evento

Una skill en nivel Master tiene efecto cualitativamente distinto, no solo más fuerte.

### 11.4 Respec / reset
- Resetear puntos de stats cuesta oro (incremental por reset)
- Resetear habilidad a lvl 1 (downgrade para cambiar build): gratis, pero perdés XP acumulado
- Cambiar rama de especialización: requiere item raro "Tomo del Renacer"

---

## 12. Cómo seguimos rellenando

Orden sugerido de iteración:

1. **Warrior completo** (ya hay base implementada: puñetazo pesado + combo rápido)
2. **Mage completo** (base: proyectil + rayo canalizado)
3. **Archer completo**
4. **Cleric completo** (crítico para coop)
5. **Necromancer completo**
6. **Danzante completo** (diseñar from scratch)
7. **Sinergias matriz** (sección 9)
8. **Pasivas especiales** (sección 10)
9. Revisión + balance cross-clase
10. FX visual por skill (ref Demon Slayer / JJK / One Piece)

---

*Documento preparado por Dept Design. Rellenar iterando. Canon cuando se complete y revise.*
