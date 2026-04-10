# Sistema de Tiers de Enemigos — Dungeon Party

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document
**Departamento**: Game Design

---

## 1. Filosofia del Sistema

Los enemigos no escalan por formula generica. Cada piso tiene un **tier** que define el poder base de sus criaturas, y dentro de cada piso las criaturas se dividen en **sub-tiers** (A/B/C) que crean una curva de dificultad interna.

**Principios**:
- El tier de un piso = numero de piso. Piso 1 = Tier 1, Piso 15 = Tier 15
- Sub-tier define el ROL del enemigo, no solo sus stats
- Los packs de mobs (grupos) crean dificultad emergente por composicion
- El boss de cada piso es un GATE: sus stats base igualan al tier siguiente sub-A, pero su dificultad viene de mecanicas, combos y fases
- Salto claro entre tiers — sin overlap. Si superaste el tier 1, el tier 2 se SIENTE mas fuerte

---

## 2. Bandas de Dificultad

100 pisos divididos en 5 bandas. Cada banda define el rango de niveles del jugador y la complejidad de las mecanicas de los enemigos.

| Banda | Pisos | Complejidad | Nivel jugador | Descripcion |
|-------|-------|-------------|---------------|-------------|
| **1** | 1-20 | Baja | 1 → 20 | Tutorial expandido. Aprendes mecanicas basicas. Enemigos con patrones simples y predecibles |
| **2** | 21-40 | Media | 20 → 30 | Enemigos con 2+ ataques, esquivan, se protegen. Packs mas complejos |
| **3** | 41-60 | Alta | 30 → 38 | Enemigos con habilidades especiales, interaccion con el ambiente. Packs con roles diferenciados |
| **4** | 61-80 | Muy Alta | 38 → 45 | Enemigos con combos, contraataques, resistencias situacionales. Requieren estrategia de grupo |
| **5** | 81-100 | Extrema | 45 → 50 | Enemigos con mecanicas unicas, fases, adaptacion al jugador. Cada encuentro es un puzzle |

### Progresion de nivel por banda

| Banda | Pisos | Niveles ganados | Ritmo |
|-------|-------|-----------------|-------|
| 1 | 20 pisos | 20 niveles | 1 nivel/piso (rapido, enganchador) |
| 2 | 20 pisos | 10 niveles | 1 nivel/2 pisos |
| 3 | 20 pisos | 8 niveles | 1 nivel/2.5 pisos |
| 4 | 20 pisos | 7 niveles | 1 nivel/~3 pisos |
| 5 | 20 pisos | 5 niveles | 1 nivel/4 pisos (grind intencional) |

**Total**: 50 niveles en 100 pisos. Rapido al principio para enganchar, lento al final para que cada nivel importe.

### Biomas por banda

Los biomas no estan atados a pisos fijos, pero si a bandas de dificultad. Un bioma de Banda 1 puede aparecer en cualquier piso del 1 al 20, con sus enemigos escalados al tier de ese piso.

**Excepcion**: Piso 1 es SIEMPRE Pradera Interior (tutorial).

| Banda | Biomas posibles |
|-------|----------------|
| 1 | Pradera Interior, Bosque Denso, Sabana, Costa |
| 2 | Desierto, Pantano, Cavernas de Hielo, Montania |
| 3 | Volcan, Selva Profunda, Hongos, Catacumbas |
| 4 | Tormenta/Cielo, Abismo, Dimension Astral, Oceano Profundo |
| 5 | Vacio, Pradera Marchita, Laboratorio, Santuario del Umbral |

---

## 3. Sub-tiers: A, B, C

Dentro de cada piso, los enemigos se clasifican en tres sub-tiers que definen su rol en el ecosistema.

| Sub-tier | Nombre | Rol | Comportamiento | Distribucion en el mapa |
|----------|--------|-----|----------------|------------------------|
| **A** | Fauna basica | Fodder, aprendes a pelear | Pasivo o poco agresivo, patrones simples, 1-2 ataques | Abundante por todo el mapa, en packs grandes |
| **B** | Depredadores | Amenaza moderada, te obligan a moverte | Agresivo, patron de ataque definido, puede flanquear | Zonas intermedias, packs medianos |
| **C** | Alfa / Inteligente | Peligro real, requiere pensar | Mecanicas especiales, roles en grupo, puede esquivar | Zonas especificas (ruinas, caminos, cuevas), packs con formacion |
| **BOSS** | Jefe de piso | Gate al siguiente tier | Fases, combos, habilidades unicas, puede invocar mobs | Arena dedicada, 1 por piso |

### Relacion stats entre sub-tiers (dentro del mismo tier)

| Sub-tier | HP | DMG | DEF | XP |
|----------|----|-----|-----|----|
| A | 1.0x | 1.0x | 0x | 1.0x |
| B | 1.6x | 1.6x | base + 2 | 2.0x |
| C | 2.4x | 2.4x | base + 5 | 3.5x |
| BOSS | 3.0x | 3.0x (= tier+1 A) | base + 8 | 10x |

---

## 4. Formulas de Escalado por Tier

### Stats base por tier (sub-tier A)

```
HP(tier)  = 50 + (tier - 1) * 30 + (tier - 1)^1.3 * 5
DMG(tier) = 5  + (tier - 1) * 4  + (tier - 1)^1.2 * 1.5
DEF(tier) = floor((tier - 1) * 1.5)
XP(tier)  = 10 + (tier - 1) * 8
```

### Tabla de referencia (sub-tier A, valores calculados)

| Tier | Piso | HP | DMG | DEF | XP |
|------|------|----|-----|-----|----|
| 1 | 1 | 50 | 5 | 0 | 10 |
| 2 | 2 | 85 | 10 | 1 | 18 |
| 3 | 3 | 120 | 16 | 3 | 26 |
| 4 | 4 | 160 | 22 | 4 | 34 |
| 5 | 5 | 200 | 28 | 6 | 42 |
| 10 | 10 | 380 | 57 | 13 | 82 |
| 15 | 15 | 580 | 88 | 21 | 122 |
| 20 | 20 | 800 | 121 | 28 | 162 |
| 50 | 50 | 2200 | 340 | 73 | 402 |
| 100 | 100 | 4800 | 720 | 148 | 802 |

### Salto entre tiers (ejemplo completo tier 1 → tier 2)

```
TIER 1 (Pradera, Piso 1):
  Sub-A (Slime verde):    HP 50,   DMG 5,   DEF 0,  XP 10
  Sub-B (Pajaro):         HP 80,   DMG 8,   DEF 2,  XP 20
  Sub-C (Bandido):        HP 120,  DMG 12,  DEF 5,  XP 35
  BOSS  (Rey Slime):      HP 150,  DMG 15,  DEF 8,  XP 100
  ─── SALTO CLARO ───
TIER 2 (Bosque, Piso 2):
  Sub-A (Slime musgo):    HP 85,   DMG 10,  DEF 1,  XP 18
  Sub-B (Lobo):           HP 136,  DMG 16,  DEF 3,  XP 36
  Sub-C (Treant):         HP 204,  DMG 24,  DEF 6,  XP 63
  BOSS  (Oso corrupto):   HP 255,  DMG 30,  DEF 9,  XP 180
```

**Nota sobre el boss**: El boss de tier 1 tiene HP 150 y DMG 15. El sub-A de tier 2 tiene HP 85 y DMG 10. El boss es MAS FUERTE en stats puros que el fodder del siguiente tier — pero el boss es UNO SOLO con mecanicas, mientras que en tier 2 enfrentas PACKS de sub-A. La dificultad del boss viene de sus combos, fases y habilidades, no de ser un saco de HP.

---

## 5. El Boss como Gate

### Filosofia

El boss NO es un enemigo con numeros mas altos. Es un EXAMEN que testa si dominaste las mecanicas del piso. Sus stats base equivalen al tier+1 sub-A, pero la dificultad real viene de:

1. **Combos**: secuencias de ataques que requieren timing para esquivar
2. **Fases**: cambia comportamiento al bajar de HP (ej: 75%, 50%, 25%)
3. **Habilidades especiales**: mecanicas que no tienen los mobs normales
4. **Invocaciones**: puede llamar mobs del piso como adds durante la pelea

### Stats del boss

```
BOSS_HP  = tier+1 Sub-A HP * 3.0
BOSS_DMG = tier+1 Sub-A DMG * 1.0  (mismo danio base, la peligrosidad viene de los combos)
BOSS_DEF = tier+1 Sub-A DEF + 8
BOSS_XP  = tier Sub-A XP * 10
```

**El boss pega igual que un mob basico del siguiente tier** — pero tiene combos de 3-4 golpes seguidos, habilidades de area, y puede invocar refuerzos. Un jugador que le gana demuestra que puede SOBREVIVIR el siguiente piso.

### Estructura de fases (template)

| Fase | HP restante | Comportamiento |
|------|-------------|----------------|
| 1 | 100%-75% | Patron basico, 1-2 ataques. El jugador aprende los movimientos |
| 2 | 75%-50% | Agrega 1 habilidad nueva, acelera ataques |
| 3 | 50%-25% | Invoca mobs (2-3 sub-A del mismo tier), combo de 3 golpes |
| 4 | 25%-0% | Modo furia: todos los ataques, velocidad maxima, ultimo esfuerzo |

---

## 6. Pack Composition (sistema Metin2)

### Filosofia

Los enemigos NO aparecen solos. Aparecen en PACKS (grupos) con formacion y composicion que define la dificultad del encuentro. La dificultad emerge de la COMBINACION, no del individuo.

**Referencia**: Metin2 (grupos de mobs dispersos por zonas), Dragon Ball MMRPG (formaciones de enemigos), SAO (pack wolves, pack insects).

### Tipos de packs

| Tipo | Composicion | Comportamiento | Ejemplo Pradera |
|------|-------------|----------------|-----------------|
| **Manada** | 3-5 del mismo sub-tier A | Se mueven juntos, agrean juntos, huyen juntos | 4 slimes pastando |
| **Patrulla** | 2-3 del mismo sub-tier B | Ruta fija, deteccion amplia, persiguen | 3 pajaros volando en circulo |
| **Escuadra** | 2 sub-tier C + apoyo | Roles: tanque + DPS o tanque + rango | 2 bandidos melee + 1 bandido arquero |
| **Mixto** | Mezcla de A + B | Convivencia natural, agrean por separado | 3 slimes + 1 pajaro (se ayudan pero no coordinan) |
| **Nido/Guarida** | 5-8 del mismo tipo A/B, respawnean | Zona fija, defienden area | Nido de avispas (8 avispas, respawn lento) |
| **Pre-boss** | Mix de A + B + C | Zona antes del boss, maxima dificultad normal | 2 bandidos + 3 slimes + 1 pajaro |

### Reglas de spawn

1. **Densidad por zona**: cada zona del mapa tiene una densidad de packs definida
2. **Distancia minima entre packs**: 15m (para que no se junten todos)
3. **Radio de agro**: los mobs de un pack comparten agro. Si atacas a uno, todo el pack reacciona
4. **Agro entre packs**: los packs CERCANOS (<8m) pueden unirse. Los lejanos NO
5. **Respawn**: los packs respawnean despues de X minutos. El mundo nunca queda vacio
6. **Variacion por seed**: la seed determina composicion y posicion de packs, no la cantidad total

### Tabla de dificultad efectiva de packs

| Pack | Mobs | Dificultad efectiva |
|------|------|---------------------|
| 4 × Sub-A | 4 slimes | ~ Sub-B (por volumen) |
| 2 × Sub-A + 1 × Sub-B | 2 slimes + 1 pajaro | ~ Sub-B+ |
| 3 × Sub-B | 3 pajaros | ~ Sub-C (flanqueo) |
| 2 × Sub-C + 1 apoyo | 2 bandidos + 1 arquero | ~ Mini-boss |
| Mix pre-boss | 2C + 3A + 1B | ~ Boss (sin mecanicas) |

---

## 7. Comportamiento por Sub-tier

### Sub-tier A — Fauna basica

- **IA**: Simple. Idle + perseguir si el jugador se acerca. Ataque basico al rango.
- **Ataques**: 1 ataque basico, sin combo
- **Reaccion al danio**: retrocede, puede huir si HP < 20%
- **Agro**: corto (8m), pierde interes rapido (15m de distancia)
- **En pack**: atacan al mismo target, no coordinan

### Sub-tier B — Depredadores

- **IA**: Moderada. Patrullan, detectan a mayor rango, pueden flanquear.
- **Ataques**: 2 ataques distintos (ej: embestida + mordida), sin combo pero alternan
- **Reaccion al danio**: se reposicionan, pueden llamar al pack
- **Agro**: medio (12m), persistente (25m para perder)
- **En pack**: uno distrae, otros flanquean. Patron emergente, no scriptado

### Sub-tier C — Alfa / Inteligente

- **IA**: Avanzada. Posicion estrategica, esperan oportunidad, protegen a aliados.
- **Ataques**: 2-3 ataques + 1 habilidad especial (varia por criatura)
- **Reaccion al danio**: contraataque, esquiva, puede usar items (pocion, escudo)
- **Agro**: largo (15m), no pierde interes facil (35m)
- **En pack**: roles definidos (tanque/DPS/rango), coordina ataques

### Boss

- **IA**: Compleja. Fases, combos, invocaciones, mecanicas unicas.
- **Ataques**: 3-5 ataques + 2-3 habilidades + combo de 3-4 golpes
- **Reaccion al danio**: cambia de fase, enrage, invoca adds
- **Agro**: toda la arena, no pierde interes
- **Solo**: siempre pelea solo (pero puede invocar adds)

---

## 8. Escalado Visual por Tier

Los mobs del mismo tipo pero diferente tier se diferencian visualmente. El jugador SABE que un slime rojo es mas peligroso que uno verde sin leer stats.

### Esquema de color por banda (sugerido)

| Banda | Pisos | Color dominante | Sensacion |
|-------|-------|----------------|-----------|
| 1 | 1-20 | Verdes, azules, amarillos | Natural, amigable, fauna comun |
| 2 | 21-40 | Naranjas, marrones, grises | Agreste, peligroso, salvaje |
| 3 | 41-60 | Rojos, purpuras | Corrupto, magico, anormal |
| 4 | 61-80 | Negros, azul oscuro, plata | Oscuro, elitista, antinatural |
| 5 | 81-100 | Blanco, dorado, vacio | Trascendental, divino, imposible |

### Ejemplo: evolucion del Slime

| Tier | Variante | Color | Habilidad extra |
|------|----------|-------|-----------------|
| 1 | Slime verde | Verde translucido | Ninguna |
| 5 | Slime de pantano | Marron verdoso | Ralentiza al contacto |
| 10 | Slime acido | Amarillo brillante | Deja charco de acido (DoT) |
| 25 | Slime de cristal | Naranja/ambar | Explota al morir (AoE) |
| 50 | Slime de vacio | Purpura/negro | Absorbe hechizos, se divide |
| 80 | Slime espectral | Translucido plateado | Intangible intermitente |
| 100 | Slime primordial | Blanco/dorado | Todas las anteriores + regen |

---

## 9. Notas de Compatibilidad

### Con el GDD actual

El GDD v0.2 tiene una tabla de escalado por piso (5 pisos):

| Piso | HP | DMG | DEF |
|------|----|-----|-----|
| 1 | 100 | 10 | 0 |
| 2 | 200 | 20 | 5 |

Esta tabla queda **OBSOLETA**. El nuevo sistema de 100 pisos con tiers reemplaza esa tabla. Los valores del GDD eran para un modelo de 5 pisos; el nuevo sistema escala con formulas para 100 pisos.

### Con el sistema de stats del jugador

- Nivel 1 → stats base de clase (~50 HP guerrero con VIT 10)
- Tier 1 sub-A tiene 50 HP, 5 DMG → un guerrero nivel 1 puede matar un slime en ~3-4 golpes
- A nivel 20 el guerrero tiene ~150+ HP y hace ~50+ DMG → tier 20 sub-A con 800 HP requiere trabajo en grupo o gear bueno
- La curva de poder del jugador vs enemigos debe validarse con simulacion en el prototipo

### Con el sistema de loot

- Sub-tier A: drop comun (materiales basicos, pociones)
- Sub-tier B: drop mejorado (equipamiento Common, materiales raros)
- Sub-tier C: drop raro (equipamiento Rare, chance de Epic)
- Boss: drop garantizado (1 Epic + chance de Legendary)

El sistema de drop tables detallado se define en un documento separado.
