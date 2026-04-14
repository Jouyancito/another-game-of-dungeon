# Skill System — Canon

**Versión**: 1.0
**Fecha**: 2026-04-14
**Estado**: Canon. Reemplaza modelo previo de `class_skills.md` (6 skills/clase, cap 5, rama modifica).
**Depende**: `balance_v2.md` (fórmulas, niveles 1-100, ascendencia lvl 25)
**Scope**: define REGLAS del sistema. Contenido (skills concretas) vive en `{clase}.md`.

---

## 0. Filosofía

Analogía médico: todos los jugadores de una clase comparten la **base técnica** (skills generales). La **ascendencia** (lvl 25) es una especialización que agrega skills específicas — no modifica las generales. Un Necromancer Maldiciones y un Necromancer Creador ambos saben invocar esqueletos básicos y lanzar maldiciones básicas; lo que cambia es qué **skills extra** desbloquean.

Referencias de diseño: Diablo 2 (árboles + skill points), Last Epoch (mini-trees por skill), Metin2 (libro desplegable + loadouts).

---

## 1. Estructura del pool por clase

```
                    POOL TOTAL (~25 skills por clase, target endgame)
                                    │
        ┌───────────────────────────┴───────────────────────────┐
        │                                                       │
  GENERALES                                          ESPECIALIZADAS
  (lvl 1-24, disponibles                             (lvl 25+, desbloqueadas
   desde el inicio al subir                          al elegir rama de
   la clase al lvl que                               ascendencia)
   requiere cada skill)                                          │
                                                  ┌──────────────┴──────────────┐
                                                  │                             │
                                               RAMA A                        RAMA B
                                               8-10 skills                   8-10 skills
                                               exclusivas                    exclusivas

  ~10-12 generales                            (Cleric tiene 3 ramas por excepción canon)
```

**Fase actual (prototipo, pisos 1-5 en dev)**: 10-12 skills totales por clase (6-8 generales + 2-4 por rama). Se expande a ~25 cuando haya 25+ pisos jugables.

**Generales compartidas**: ambas ramas acceden al MISMO set de generales. Elegir rama A no bloquea las generales; solo agrega el set de la rama A encima.

---

## 2. Skill points y nivel de skill

- **1 skill point por nivel de personaje** (100 points totales a lvl 100, canon balance_v2)
- Cada point se invierte en UNA skill, sube su nivel +1
- **Cap por skill**: **15**
- Gating por nivel de personaje (canon D2-like):
  - Generales: desbloqueo escalonado lvl 1, 4, 8, 12, 16, 20
  - Rama: desbloqueo escalonado lvl 25, 30, 35, 40, 50, 60, 75
- **Respec**: cuesta oro incremental. Cambiar rama = ítem raro "Tomo del Renacer" (canon `class_skills.md` §11.4).

### 2.1 Escalado por nivel de skill (1-15)

Reemplaza la escala vieja 1-5 + Master. Cada nivel aporta poco, pero compound:

```
poder_skill(lvl) = base * (1 + (lvl - 1) * 0.08)
```

| Lvl | Poder | Notas |
|-----|-------|-------|
| 1 | 100% | base |
| 5 | 132% | |
| 10 | 172% | |
| 15 | 212% | **cap — forma base** |
| 15 + char lvl 50 | **evolución desbloqueable** | ver §3 |

Efectos cualitativos (no solo stats) se desbloquean en lvl 5, 10, 15:
- Lvl 5: primer efecto secundario (ej: crit +10%, slow 20%)
- Lvl 10: upgrade del efecto (ej: crit +20%, slow 40%)
- Lvl 15: efecto maestro (ej: aplica status único)

---

## 3. Evolución de skill (lvl 15 + char 50)

Una skill en cap 15 solo es "dormida" hasta que el personaje llega a **lvl 50**. En ese punto se puede activar la **evolución** de esa skill — una forma alternativa que sustituye la original.

Requisitos de evolución:
1. Skill al lvl 15
2. Personaje lvl ≥ 50
3. Ítem de evolución específico por skill (drop boss / quest / evento raro)

La evolución:
- Cambia fórmulas y a veces el tipo de skill (ej: un proyectil pasa a ser AoE canalizado)
- No se puede revertir sin Tomo del Renacer
- Es única por skill — no hay "evolución A vs B"

**Ejemplo hipotético**: *Bolita Inestable* del Mage al lvl 15 es proyectil mejorado. Evolucionada (lvl 50 char + ítem *Fragmento de Supernova*) → *Orbe de Colapso*: esfera estacionaria que atrae enemigos 3s y explota.

---

## 4. Hotbar y loadouts (goal UI, estilo Metin2)

**Estado actual prototipo**: 8 slots lineales en HUD, drag&drop simple.

**Target final** (diseño UI, no implementar hasta fase post-balance):

### 4.1 Libro de skills (grimorio lateral)
- Panel desplegable a la izquierda o derecha (tecla `K` o similar)
- Muestra TODAS las skills del pool de la clase, clasificadas: Generales / Rama
- Cada skill: ícono + nivel actual + descripción + botón `+` para subir punto
- Drag&drop desde el libro hacia un slot del hotbar

### 4.2 Hotbar con loadouts
- **4 loadouts guardados** (estilo Metin2): Loadout 1 / 2 / 3 / 4
- Cada loadout = set completo de 8 slots (6 skills + 2 consumibles)
- **Swap con tecla modificadora** (Alt por defecto, configurable)
- Uso típico:
  - Loadout 1: build boss (single-target burst)
  - Loadout 2: build farm (AoE sostenido)
  - Loadout 3: utility (escape, buffs, heals)
  - Loadout 4: libre

### 4.3 Reglas del swap
- Swap entre loadouts: instantáneo **fuera de combate**
- Swap en combate: global cooldown 2s en skills recién equipadas (evita abuso de CDs)
- Cambiar **weapon** (afecta slots variables 5a/5b) no rompe loadout — el loadout guarda la referencia por slot, no por weapon fijo

---

## 5. Esquema visual

```
  CLASE ELEGIDA
       │
       ▼
  [Lvl 1-24]  Pool GENERALES desbloqueable gradualmente
       │     skills 1, 4, 8, 12, 16, 20 (nivel PJ)
       │
       ▼
  [Lvl 25]  ASCENDENCIA — elige RAMA
       │     ┌─ Rama A ─────────┐
       │     │                  │
       │     ▼                  ▼
       │  +8-10 skills A     +8-10 skills B
       │  (Rama B bloqueada si elegí A)
       │
       ▼
  [Lvl 25-100]  seguís poniendo points en cualquier skill
       │        (generales + rama elegida)
       │
       ▼
  [Lvl 50]  Evoluciones de skills en cap 15 desbloqueables (con drop)
```

---

## 5bis. Skills ocultas de ascendencia (quest-gated)

Cada rama tiene **1-2 skills ocultas** que NO aparecen en el libro hasta que se desbloquean por quest durante el viaje por la torre.

### Requisitos para desbloquear
1. **Char lvl ≥ 50** (mínimo absoluto — son skills de ascendencia profunda)
2. Rama de ascendencia **activa** (elegida al lvl 25 y no revertida)
3. **Prerrequisitos contextuales** cumplidos — trigger de la quest
4. Completar la quest asociada

### Triggers de quest (ejemplos por clase)

| Clase / Rama | Prerrequisito trigger | Quest |
|---|---|---|
| Warrior / Tank | Completar piso 50 sin que ningún aliado muera en tu radio 8m | "El Muro Inquebrantable" — hablar con NPC P50 |
| Warrior / Berserker | Matar 50 enemigos con <20% HP propio | "Sangre que Llama Sangre" — evento P45 |
| Mage / Elementalista | Aplicar los 3 sub-elementos a un mismo boss | "Armonía Rota" — biblioteca escondida P55 |
| Mage / Arcano | Usar Blink 100 veces sin morir | "El Camino entre Espacios" — ermitaño P60 |
| Archer / Ranger | 25 headshots consecutivos a enemigos tier B+ | "Ojo Verdadero" — torre de vigía P55 |
| Archer / Artillero | Kill 5 enemigos con una sola explosión | "Ingeniería del Caos" — taller P50 |
| Necromancer / Maldiciones | Matar 100 enemigos con maldiciones activas | "El Pacto de la Marchita" — altar P60 |
| Necromancer / Creador | Mantener 3 invocaciones vivas por 10 min reales | "El Señor de los Caídos" — cripta P55 |
| Cleric / Sanador | Revivir 10 aliados diferentes en un run | "Gracia Perpetua" — santuario P55 |
| Cleric / Buffer | Mantener Aura Resguardo activa 30 min combate | "El Guardián Silencioso" — NPC P60 |
| Cleric / Exorcista | Matar 50 undead con daño sagrado | "Luz sobre Voidsign" — templo P65 |
| Danzante / Sombra | 20 kills desde stealth sin romper combate | "La Sombra Elegida" — pacto P55 |
| Danzante / Trickster | Esquivar 100 ataques con Reflejo Sombrío | "El Baile del Espejo" — evento P60 |

Todos los triggers son **trackers pasivos** — el jugador cumple condiciones jugando normal, se notifica al cumplir.

### Qué son estas skills

Skills **poderosas y de identidad de rama** — no simples upgrades. Son el "momento épico" de la rama. Ejemplos:

- Warrior/Tank: *Último Bastión* — al recibir daño letal quedás en 1 HP con invul 3s, aliados en 10m +50% DEF. CD 300s.
- Mage/Arcano: *Singularidad* — AoE 8m atrae TODO (enemigos, proyectiles enemigos, items, aliados), detona 2s después. CD 180s.
- Necromancer/Creador: *Alzamiento* — revive a TODOS los enemigos humanoides muertos en 30m radio como undead temporales 60s. CD 400s.

Son **1 skill oculta por rama** (algunas ramas tendrán 2 si el diseño lo justifica). Cada una ocupa un slot del hotbar normal y sube con skill points como cualquier otra (cap 15).

### Diseño del sistema de quest

- Las quests son **silenciosas hasta completar el prerrequisito**. No spoilea que existen.
- Al cumplir el trigger: notificación discreta, NPC aparece en safe zone, diálogo revela la quest.
- No son skippeables con oro — obligan a jugar la rama real.
- Una vez desbloqueada, permanece en la cuenta (no se pierde al morir).

### Pendiente de definir
- Diseño concreto de cada skill oculta (1 por rama mínimo) — fase Alpha
- Localización exacta de NPCs y safe zones de entrega — fase Alpha
- Narrativa de cada quest (lore integrado al biome) — dept Design futuro

---

## 5ter. Recursos por clase

**Regla base**: MP es recurso universal (todas las clases lo tienen, gasta skills genéricas, regenera pasivo). Encima, cada clase tiene **recurso único** para identidad jugable.

### MP (universal)
- Pool base 100, escala con INT (canon balance_v2 §2.2)
- Regen: 5/s fuera combate, 2/s en combate
- Full regen en safe zones

### Rage — Warrior
- NO regenera por tiempo
- Genera: +5 por hit conectado, +10 por cada 10% HP perdido recibido
- Cap 100, decae 5/s tras 8s sin combate (tentativo, ajuste en playtest)
- Gasta: skills ofensivas pesadas (Giro de Espada, Forma del Titán)
- MP: skills utility (Embestida, Bloqueo Perfecto, Grito)
- **Rama Berserker**: Rage ≥80% → +30% dmg pasivo

### Vida como recurso — Necromancer
- Algunas skills cuestan HP directa en vez de MP
- Llamar Esqueleto: -15% HP max (tope baja mientras invocación viva, retorna al morir la invocación)
- Pacto de Invocación: -10% HP current instantáneo
- Lifesteal de Tajo de Hueso restaura gradual
- MP: tajos, maldiciones, auras
- **Fantasía visual**: veins negras en el personaje mientras tiene invocaciones activas

### Fe — Cleric
- NO regenera por tiempo
- Cap 50
- Genera (coop principal):
  - Heal efectivo a aliado: +3
  - Buff a aliado: +2
  - Cleanse a aliado: +5
- Genera (solo-viable, valores reducidos):
  - Heal a sí mismo: +1
  - Buff a sí mismo: +1
  - Ataque básico vs cualquier enemigo: +0.5
  - Hit con Verso del Exorcismo vs undead: +1
- **Plegaria** (skill base del Cleric): canal 3s estacionario, regen 15 Fe, CD 20s, interrumpible
- Gear: uniques con afixes `+Fe regen/s`, `+% Fe generada por heals`
- Gasta: skills poderosas sagradas (Juicio Sagrado, Resurrección, Égida Divina)
- MP: skills básicas (Luz Restauradora, Círculo Sagrado)

### Combo Points — Danzante
- No regenera por tiempo, se acumulan con hits
- Max 5 puntos
- Generación: Corte Fugaz hit = +1, desde stealth = +2, crit = +1 extra
- Reset: cambiar target o 8s sin hitear
- Gasta en finishers (Flor de Sangre, Lluvia de Acero). Daño escala con puntos: 1pt ×1, 5pt ×3
- MP: utility (Velo Nocturno, Paso de Sombra)
- Referencia: WoW Rogue / FF14 Monk

### Concentración — Archer
- Cap 100, decae 3/s tras 10s sin disparar
- Genera por calidad de disparo:
  - Headshot: +10
  - Flecha full charge: +15
  - Hit a >15m: +3
  - Miss: −5
- Gasta en skills de precisión (segunda flecha automática, crit garantizado, armor-pierce bonus)
- MP: utility (Voltereta, Tormenta de Flechas)
- **Premia skill del jugador** — spam no genera recurso

### Mage — solo MP (fantasy lock)
Sin recurso único. Mage es el arquetipo clásico del mana puro. Pool grande, gestión intensa.

---

## 5quater. Status effects — reglas globales

### Stack y duración
- **NO suman**. Refresh-to-max: si aplicás status X sobre uno activo, queda la **mayor** de (tiempo restante, nueva duración).
- Ejemplo: freeze 2s activo con 1s restante + freeze 4s nuevo → queda **4s** (no 5s).
- Stacks distintos (ej bleed stackeable x3) son excepción explícita por skill.

### Inmunidad por gap de nivel
```
gap = nivel_enemigo - nivel_player
si gap ≤ 10  → duración 100%
si gap ≥ 25  → inmune total (duración 0%)
si 10 < gap < 25 → escala lineal: duración = 100% * (25 - gap) / 15
```
Ejemplo: gap 15 → duración 67% | gap 20 → duración 33%

### Resistencia por tier de enemigo (multiplicador encima del gap)

| Tier | Resist status (duración recibida) |
|------|----------------------------------|
| Sub-A fodder | 100% |
| Sub-B depredador | 80% |
| Sub-C alfa | 60% |
| Veterano | 50% |
| Elite / Mini-boss | 40% |
| Boss tier | 25% |

Fórmula final: `duración_final = duración_skill × multiplicador_gap × multiplicador_tier`

### Resistencia por bioma/temperatura
- Enemigos de bioma Hielo: -50% duración efectos frost
- Enemigos de bioma Fuego: -50% duración burn
- Enemigos de bioma Tormenta: -50% efectos shock
- Enemigos acuáticos: -30% efectos fuego, +30% vulnerabilidad rayo
- Reglas específicas por mob se documentan en `enemy_tier_system.md`

### Catálogo base de status (pendiente doc dedicado `_status_effects.md`)

| Status | Efecto base | Stack | Generado por |
|--------|-------------|-------|--------------|
| **Bleed** | DoT físico ignora armor | x3 | físico crítico, dagas |
| **Burn** | DoT fuego | refresh | magia fuego |
| **Freeze** | inmóvil | refresh | magia hielo |
| **Slow** | −40% velocidad | refresh | hielo suave, trampas |
| **Stun** | aturdido (sin acción) | refresh | impactos pesados |
| **Silence** | sin skills (solo básico) | refresh | undead, exorcismo |
| **Taunt** | target forzado al taunter | refresh | tank skills |
| **Knockback** | desplazamiento físico | no-stack | explosivos, cargas |
| **Weak** | −25% DMG saliente | refresh | debuffs |
| **Vulnerable** | +25% DMG recibido | refresh | marcas, exorcismo |
| **Miedo** | −25% DMG saliente + huir 3s | refresh | gritos, skills oscuras |
| **Miss chance** | % de fallos aplicado | refresh | ilusiones, blind |
| **Poison** | DoT mágico, cura bloqueada | x3 | veneno, shurikens |

---

## 5quinquies. Cooldown philosophy

### Animación = cooldown principal
- La animación de la skill **ES** el cooldown base. No se puede spammear más rápido que la animación lo permita.
- Skills sin animación visible tienen CD explícito.
- Ultimates siempre tienen CD explícito encima de la animación (60-300s).

### Cancelaciones
- Permitidas con ciertas acciones (dash, weapon swap, movimiento direccional fuerte)
- **Recovery delay**: al cancelar, la próxima skill tiene +0.3s de delay (no parte de 0, hay penalización leve)
- Cancelar un ultimate devuelve 50% del costo de recurso (no 100%, penalización por wasted cast)

### No spam
Si el jugador aprieta la misma skill repetidamente antes de que termine la anim, se ignora. No queue infinito.

### Queue corta
Hay ventana de 0.2s al final de cada animación donde aceptás input de la próxima skill (combo feel), pero no infinito.

---

## 5sexies. Convenciones de rango/target (lenguaje global)

Todas las skills referencian estas categorías, no inventan números propios. Balance se afina una vez.

| Alias | Definición |
|-------|-----------|
| `MELEE_SHORT` | 2m, cono 60° |
| `MELEE_LONG` | 3m, cono 90° |
| `AOE_SMALL` | 3m radio |
| `AOE_MEDIUM` | 6m radio |
| `AOE_LARGE` | 10m radio |
| `AOE_HUGE` | 15m radio (ultimates) |
| `PROJ_FAST` | 40 m/s (flechas, magia precisión) |
| `PROJ_MED` | 22 m/s (bolas estándar) |
| `PROJ_SLOW` | 18 m/s (explosivos, pesados) |
| `CONE_CANAL` | 8m cono 45° (rayos canalizados) |
| `PULSO_AURA` | 10m radio pulso pasiva |
| `LINE_PIERCE` | 12m línea, atraviesa enemigos |
| `SELF_TARGET` | sobre el caster |
| `ALLY_RANGED` | aliado a 20m |

Si balance pide cambios, se ajusta el alias globalmente. No hay "puñetazo 2.1m" vs "corte 2.3m" arbitrarios.

---

## 6. Fases de contenido

Cantidad de skills objetivo por clase según madurez del juego:

| Fase juego | Pisos jugables | Skills/clase | Cap por skill | Loadouts Metin2 |
|------------|----------------|--------------|---------------|-----------------|
| **Prototipo (hoy)** | 1-5 en dev | 10-12 | 15 (regla ya canon) | no, hotbar simple |
| **Alpha** | 5-15 | 15-18 | 15 | en backlog |
| **Beta** | 15-25 | 20-22 | 15 + evolución activa | implementado |
| **Release** | 100 | ~25 | 15 + evolución full | full features |

Regla: **no expandimos pool sin contenido donde probarlo**. Cada tanda de skills nuevas debe tener al menos 3 pisos distintos donde se sienta diferente usarla.

---

## 7. Qué se conserva del modelo viejo (`class_skills.md`)

- Fórmulas compound (`physical_v2`, `magic_v2`, heals) → canon balance_v2, sin cambios
- Nombres de skills diseñadas en docs actuales → se reutilizan como base del pool general
- Ascendencias y ramas por clase: **se mantienen** (Warrior Tank/Berserker, Mage Elementalista/Arcano, etc.)
- Cleric con 3 ramas (Sanador/Buffer/Exorcista): excepción mantenida
- Aura de Resguardo del Buffer (+5% resist cap, canon balance_v2 §2.6): se mantiene como pasiva rama
- XP por uso: **descartado** — ahora sube por skill points puros (D2-like)
- "Maestría por drop" nivel 6: **descartado** — reemplazado por evolución lvl 15 + char 50

---

## 7bis. Pasivas — reglas

- Ocupan slot del pool general (suben con skill points igual que activas)
- Cap 15 igual que activas
- Son **AoE alrededor del personaje** con rango y duración configurables por skill
- Pueden ser:
  - **Buff aura**: aliados en radio X reciben beneficio
  - **Debuff aura**: enemigos en radio X reciben penalización
  - **Trigger pasivo**: se activa al cumplir condición (ej "al recibir crit, +20% DEF 4s")
- Varias pasivas pueden estar equipadas simultáneamente (hasta 3 del tipo aura, si se pisan la dominante es la activada más reciente)

---

## 7ter. Uniques y tag system

### Tag system (columna vertebral de builds)
Cada skill lleva tags explícitos. Ejemplos:
- *Bolita Inestable*: `[magic][projectile][single][arcane]`
- *Giro de Espada*: `[physical][melee][AoE][strike]`
- *Tormenta Arcana*: `[magic][channel][AoE][arcane]`

### Gear afixes con tags
- "+15% dmg magic"
- "+20% dmg projectile"
- "+30% AoE radius"
- "−15% CD de skills channel"
- "Las skills arcane aplican freeze 1s"

### Uniques
- **Del mismo tipo pueden existir varios uniques con stats distintos** (roll-dependent, farmeo constante)
- Uniques "buenos" y "uniques malos" (no hay BiS absoluto por slot — depende del build)
- Algunos uniques **modifican una skill específica** (ej: *Fragmento de Supernova* → Bolita Inestable pasa a ser esfera de colapso estacionaria)
- Uniques de skill se conectan con el sistema de **evolución lvl 15 + char 50** (§3) y con **quests de ascendencia** (§5bis)

---

## 8. Pendientes (próximas sesiones)

1. `_status_effects.md` — doc dedicado con efectos, durations estándar, animaciones VFX
2. `_resources.md` — doc dedicado si las reglas de §5ter crecen
3. Reescribir los 6 docs de clase con el nuevo modelo (10-12 skills/clase fase prototipo) usando alias de convenciones y recursos por clase
4. Definir las 6-8 **generales por clase** concretas
5. Definir 2-4 **por rama** concretas (fase prototipo)
6. Tabla de gating por nivel PJ (qué skill se desbloquea cuándo)
7. Lista concreta de tags por clase (draft)
8. Lista de ítems de evolución (lvl 15 + 50) — diferido hasta fase Beta
9. Spec UI del libro desplegable + loadouts — diferido hasta fase Alpha
10. Diseño concreto de skills ocultas de ascendencia (1 por rama) — fase Alpha

---

*Canon del sistema. Cualquier skill concreta se diseña contra este doc. Cambios al sistema se versionan aquí primero.*
