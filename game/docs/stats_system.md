# Sistema de Stats, Habilidades y Gemas — Dungeon Party

> Documento de diseño v1.0. Fuente de verdad para balance, fórmulas, habilidades y progresión.

## Filosofía

- **Stats primarios = poder general.** Te hacen más fuerte en todo.
- **Items = especialización de rol.** Un amuleto de curación potencia al Healer, un amuleto de invocación al Necro.
- **Simple de entender, profundo de optimizar.** Pocos stats, muchas combinaciones.
- **Habilidades crecen con uso.** Practicar = mejorar. Maestría = logro especial.
- **Gemas de soporte = bonos de stats.** No modifican habilidades, potencian al personaje.

---

## Stats Primarios

5 atributos universales. Todas las clases los tienen, todas se benefician, pero con PESO diferente.

| Stat | Efecto Universal | Fórmula |
|------|-----------------|---------|
| **STR** | +Daño físico | `daño_fisico = base + (STR × 2)` |
| **INT** | +Daño mágico, +Max MP, +MP regen | `daño_magico = base + (INT × 2)`, `max_mp = base_mp + (INT × 3)`, `mp_regen = (1.0 + INT × 0.1)/s` |
| **DEX** | +Evasión, +Velocidad de ataque | `evasion = DEX × 0.5%` (soft cap), `atk_speed_bonus = DEX × 0.3%` |
| **DEF** | +Reducción daño físico | `daño_recibido = max(daño - DEF, 1)` |
| **VIT** | +Max HP, +HP regen | `max_hp = base_hp + (VIT × 5)`, `hp_regen = (0.5 + VIT × 0.15)/s` (fuera de combate) |

### Bonos Especiales por Clase

Los stats primarios dan un efecto EXTRA dependiendo de la clase. Esto es lo que diferencia un Warrior con 20 STR de un Mage con 20 STR.

| Stat | Warrior | Mage | Archer | Necromancer | Healer |
|------|---------|------|--------|-------------|--------|
| **STR** | **×1.5 multiplicador** de daño físico | ×1.0 (normal) | ×1.0 (normal) | ×1.0 (normal) | ×1.0 (normal) |
| **INT** | Solo MP (no daño mágico) | **Daño mágico + MP** | Solo MP | **Daño mágico + MP** | **Poder curación base + MP** |
| **DEX** | Solo evasión | Solo evasión | **Evasión + daño físico** (×1.0) | Solo evasión | Solo evasión |
| **DEF** | **Reducción mejorada + chance bloqueo** (con escudo) | Reducción normal | Reducción normal | Reducción normal | Reducción normal |
| **VIT** | HP normal | HP normal | HP normal | HP normal | HP normal |

#### Especialización: Berserker (rama de Warrior)

- **VIT → +Daño**: las habilidades del Berserker cuestan HP. Más VIT = más HP = más daño sostenido. Fórmula propuesta: `berserk_bonus = VIT × 0.5` añadido al daño físico.

#### Especialización: Ranger (rama de Archer)

- **DEX → +Evasión extra**: el Ranger tiene un multiplicador de evasión superior. `evasion_ranger = DEX × 0.8%` en lugar de `0.5%`.

#### Especialización: Sanador (rama de Healer)

- **INT → +Poder de curación mejorado**: buffs grupales (escudos, regen), curación directa más fuerte.

#### Especialización: Exorcista (rama de Healer)

- **INT → +Daño sagrado**: daño bonus contra muertos vivientes y enemigos de Vacío. Puede purificar debuffs del equipo. Counter natural a enemigos oscuros.

#### Especialización: Maldiciones (rama de Necromancer)

- **INT → +Efecto de maldiciones**: debuffs más fuertes, mayor duración, reducción de resistencias enemigas.

#### Especialización: Creador (rama de Necromancer)

- **INT → +Poder de invocaciones**: invocaciones con más HP/daño. Combinado con items de invocación extra para más minions.

---

## Stats Secundarios (Derivados)

Se calculan a partir de stats primarios + equipamiento. NO se asignan puntos directamente.

| Stat Secundario | Fuente Base | Fuente Item | Cap |
|----------------|-------------|-------------|-----|
| **Crit Chance** | 5% base + DEX × 0.2% | Arma, accesorios | 100% |
| **Crit Damage** | 150% base (×1.5) | Solo arma y accesorios | Sin cap |
| **Evasión** | DEX × 0.5% | Armadura ligera, botas, accesorios | Soft cap ~60% |
| **Velocidad de Ataque** | Base por clase | Arma, DEX parcial | TBD |
| **Velocidad de Movimiento** | Base por clase | Botas | TBD |
| **Chance de Bloqueo** | 0% base (solo Tank con escudo) | Escudo | TBD |
| **Poder de Curación** | INT base (solo Healer) | Amuleto, anillos | Sin cap |
| **Invocaciones Extra** | 0 base (solo Necro) | Amuleto, anillos | TBD |
| **Res. Estados** | 0% base | Armadura, accesorios | Soft cap ~60% |
| **Item Rarity** | 0% base | Cualquier slot (raro en armas) | Sin cap |

### Sistema de Críticos

- **Crit Chance**: probabilidad de asestar golpe crítico (0-100%)
- **Crit Damage**: multiplicador al daño en golpe crítico. Base = ×1.5
  - Ejemplo: 10 de daño × 1.5 = 15 de daño crítico
- Solo armas y accesorios pueden subir crit damage. Los stats primarios NO lo afectan directamente.

### Resistencia a Estados

Reduce la duración y/o probabilidad de efectos de estado (burn, freeze, poison, etc.).

```
duracion_efectiva = duracion_base × (1.0 - res_estados / 100.0)
```

Usa la misma curva de soft cap que resistencias elementales pero con cap ~60%. No lo anula del todo — siempre te afecta un poco.

### Item Rarity (contribución ponderada en grupo)

Aumenta la probabilidad de que los drops sean de mayor raridad. En co-op se calcula con un sistema de **contribución ponderada** — único de Dungeon Party.

**Fórmula de contribución por jugador:**

```
contribucion = daño_hecho × 1.0
             + daño_tankeado × 0.2
             + curación_hecha × 0.15
```

**Rarity efectiva del drop:**

```
rarity_efectiva = Σ (contribucion_jugador / contribucion_total × rarity_jugador)
```

**Pesos de contribución:**
- **Daño hecho × 1.0** — el core. El que mata al bicho tiene el mayor peso.
- **Daño tankeado × 0.2** — el Tank contribuye pero no puede farmear rarity sin pelear.
- **Curación hecha × 0.15** — el Healer tiene representación sin poder inflarlo (curarse a sí mismo no cuenta, o cuenta reducido).

**Ejemplo con boss:**

| Jugador | Daño | Tankeado | Curación | Contribución | % | Rarity | Aporta |
|---------|------|----------|----------|-------------|---|--------|--------|
| Tank | 200 | 1500 | 0 | 200 + 300 = 500 | 28% | 20 | 5.6 |
| Mage | 800 | 100 | 0 | 800 + 20 = 820 | 46% | 10 | 4.6 |
| Healer | 100 | 200 | 600 | 100 + 40 + 90 = 230 | 13% | 50 | 6.5 |
| Archer | 900 | 0 | 0 | 900 | 13% | 0 | 0 |
| **Total** | | | | **1790** | **100%** | | **16.7** |

> El Healer con 50 de rarity aporta MÁS que el Tank con 20 y el Mage con 10, a pesar de hacer menos daño. Pero el Archer con 0 rarity no aporta nada sin importar cuánto pegue. Todos los roles importan.

**Regla anti-exploit:** la auto-curación cuenta al 50% para evitar que un Healer se haga daño y se cure para inflar contribución.

**¿Por qué este sistema?**

Ningún ARPG mainstream usa contribución ponderada:
- Diablo 2: último hit (egoísta)
- Diablo 3/4: loot personal (desconectado del grupo)
- Path of Exile: promedio por proximidad (no premia contribución)
- Monster Hunter: todos igual (premia no hacer nada)

Dungeon Party premia a los que PARTICIPAN, en CUALQUIER rol. Pilar: "coordinación es poder".

---

## Elementos y Resistencias

5 elementos. Cada uno asociado a biomas de la torre.

| Elemento | Color | Biomas Asociados | Efecto Temático |
|----------|-------|-----------------|-----------------|
| **Fuego** | Rojo/naranja | Volcán, Desierto, Forja | Daño over time (burn) |
| **Hielo** | Celeste | Tundra, Glaciar, Cuevas heladas | Slow / freeze |
| **Rayo** | Amarillo | Tormenta, Flotante, Ruinas | Daño burst / chain |
| **Veneno** | Verde | Pantano, Bosque profundo, Cripta | DoT + debuff stats |
| **Vacío** | Púrpura | Dimensión Rota, Abismo, Ruinas antiguas | Daño % max HP / debuff defensa |

### Resistencias Elementales

Cada elemento tiene su resistencia individual. Los valores vienen SOLO de equipamiento y pasivas de clase.

**Curva asintótica (soft cap 80%)**:

```
resistencia_efectiva = 80 × (1 - e^(-0.025 × resistencia_raw))
```

| Res Raw | Res Efectiva | Nota |
|---------|-------------|------|
| 10 | 17.7% | Poco equipo |
| 20 | 31.5% | Equipo decente |
| 40 | 50.6% | Bien equipado |
| 60 | 62.2% | Muy bien equipado |
| 80 | 69.2% | Diminishing returns notorio |
| 100 | 73.0% | Casi cap |
| 150 | 78.8% | Cerca del límite |
| ∞ | 80.0% | Nunca se alcanza |

La curva incentiva diversificar resistencias en vez de apilar una sola.

**Fórmula de daño elemental**:
```
daño_final = daño_raw × (1.0 - resistencia_efectiva / 100.0)
```

---

## Bonos de Equipamiento

### Filosofía de Slots

Cada slot de equipamiento tiene un POOL de bonos posibles. Los items no dan cualquier cosa — dan lo que tiene sentido para ese slot. Estilo Diablo 2: simple y lógico.

| Slot | Bonos Posibles |
|------|---------------|
| **Arma** | +Daño, +Vel. ataque, +Crit chance, +Crit damage, +Daño elemental |
| **Armadura (pecho)** | +DEF, +HP, +Resistencias elementales |
| **Casco** | +DEF, +HP, +Resistencia específica |
| **Botas** | +Vel. movimiento, +Evasión, +DEF menor |
| **Guantes** | +Vel. ataque, +Crit chance, +DEX menor |
| **Escudo** | +DEF, +Chance bloqueo, +Resistencias, +HP |
| **Anillo (×2)** | +Stats flat (cualquiera), +Crit, +Evasión — comodín |
| **Amuleto** | +Stats flat, bonos de ROL (curación, invocación, furia) |

### Tipo de Bonos

Todos los bonos son **flat** (sumatorios). No hay porcentuales por ahora.

```
Ejemplos:
  Espada Oxidada:     +3 Daño, +1 STR
  Anillo de Sabio:    +4 INT, +10 MP
  Amuleto del Nigromante: +1 Invocación extra, +3 INT
  Botas de Explorador: +0.5 Vel. movimiento, +5% Evasión
```

---

## Stats Base por Clase (Nivel 1)

| Stat | Warrior | Mage | Archer | Necromancer | Healer |
|------|---------|------|--------|-------------|--------|
| STR | 12 | 4 | 7 | 3 | 5 |
| INT | 3 | 12 | 3 | 10 | 11 |
| DEX | 6 | 5 | 12 | 4 | 4 |
| DEF | 10 | 3 | 5 | 4 | 7 |
| VIT | 10 | 5 | 6 | 5 | 8 |
| HP base | 100 | 70 | 80 | 65 | 90 |
| MP base | 80 | 120 | 70 | 110 | 115 |
| Velocidad | 5.0 | 4.5 | 5.5 | 4.0 | 4.5 |
| Sprint | 8.0 | 7.0 | 9.0 | 6.5 | 7.0 |

### Stats Calculados Nivel 1

| Derivado | Warrior | Mage | Archer | Necromancer | Healer |
|----------|---------|------|--------|-------------|--------|
| Max HP | 150 | 95 | 110 | 90 | 130 |
| Max MP | 89 | 156 | 79 | 140 | 148 |
| Crit Chance | 6.2% | 6.0% | 7.4% | 5.8% | 5.8% |
| Evasión | 3.0% | 2.5% | 6.0% | 2.0% | 2.0% |

---

## Progresión

- **Niveles**: 1-50
- **XP por nivel**: `100 × 1.15^(nivel-1)`
- **Stat points por nivel**: 3 (total: 147 puntos asignables en nivel 50)
- **Especialización**: nivel 10 (elige 1 de 2 ramas)
- **Resets**: máximo 6 — después la clase se convierte en "The Lost"

### Distribución Sugerida (Warrior ejemplo)

Un Warrior nivel 50 con 147 puntos distribuidos agresivamente:
- STR 12 → 52 (+40): daño físico = base + 104
- VIT 10 → 50 (+40): max HP = 100 + 250 = 350
- DEF 10 → 77 (+67): reduce 77 de daño físico

Esto se combina con equipamiento para llegar a números más altos.

---

## Fórmulas Resumen

```gdscript
# Daño físico (universal)
func get_physical_damage(base_dmg: float) -> float:
    var class_mult = get_str_multiplier()  # 1.5 para Warrior, 1.0 para el resto
    return (base_dmg + str_stat * 2) * class_mult

# Daño mágico (Mage, Necro, Healer)
func get_magic_damage(base_dmg: float) -> float:
    return base_dmg + int_stat * 2  # Solo aplica si la clase usa magia ofensiva

# Daño DEX (Archer)
func get_dex_damage(base_dmg: float) -> float:
    return base_dmg + dex_stat * 2

# HP y MP
max_hp = base_hp + (vit_stat * 5)
max_mp = base_mp + (int_stat * 3)

# Regeneración
mp_regen = (1.0 + int_stat * 0.1) por segundo
hp_regen = (0.5 + vit_stat * 0.15) por segundo (fuera de combate, delay 15s)

# Crit
crit_chance = 5.0 + (dex_stat * 0.2) + bonos_equipo
crit_damage = 1.5 + bonos_equipo  # multiplicador
daño_critico = daño_final * crit_damage

# Evasión
evasion = dex_stat * 0.5 + bonos_equipo  # soft cap ~60%

# Resistencia elemental
res_efectiva = 80 * (1 - e^(-0.025 * res_raw))  # soft cap 80%

# Defensa física
daño_recibido = max(daño_raw - def_stat - bonos_equipo, 1)
```

---

## Sistema de Habilidades

### Estructura por Clase

Cada clase tiene **6 habilidades**:

- **4 fijas** — las tiene cualquier build de esa clase, siempre disponibles
- **2 variables** — dependen de equipamiento o especialización

Las 2 variables le dan identidad al build. Ejemplo:
- Warrior con escudo → tiene "Bloqueo Perfecto" (variable)
- Warrior con espadón → tiene "Giro de Espada" (variable)
- Ambos comparten las 4 fijas (golpe, carga, grito de guerra, etc.)

### Progresión por Uso

Las habilidades suben de nivel usándolas. NO con puntos de stats.

**Niveles 1-5**: XP de habilidad con curva propia por habilidad.

Cada uso de la habilidad otorga XP a ESA habilidad. Las habilidades más complejas/costosas dan más XP por uso.

```
xp_por_uso = base_xp_habilidad × multiplicador_situacional
xp_para_siguiente_nivel = xp_base_habilidad × curva^(nivel_actual)
```

| Nivel | Efecto Ejemplo (Flecha Cargada del Archer) |
|-------|---------------------------------------------|
| 1 | Dispara 1 flecha fuerte |
| 2 | +15% daño |
| 3 | +30% daño, menor tiempo de carga |
| 4 | Dispara 2 flechas |
| 5 | +50% daño, carga rápida |

### Maestría (Master)

La maestría es un nivel ESPECIAL por encima del nivel 5. NO se desbloquea con uso — requiere un logro específico:

- **Drop de boss**: un boss específico droppea "Pergamino de Maestría: [Habilidad]"
- **Quest**: completar una misión especial relacionada con la habilidad
- **Item consumible raro**: objeto de crafteo o evento que desbloquea la maestría

| Nivel | Efecto Ejemplo (Flecha Cargada del Archer) |
|-------|---------------------------------------------|
| Master | Dispara 3 flechas con penetración |

La maestría es un **momento memorable** — no es grinding, es un logro.

### Habilidades y Especialización

- **Nivel 1-9**: acceso a las 4 habilidades fijas + 2 variables (según equipo)
- **Nivel 10 (especialización)**: la rama elegida puede modificar cómo funcionan las habilidades fijas y desbloquea mejoras exclusivas

Ejemplo Warrior:
- **Tank**: "Golpe Pesado" gana efecto de aturdimiento
- **Berserker**: "Golpe Pesado" gana multiplicador de daño por HP perdido

---

## Sistema de Gemas de Soporte

### Concepto

Las gemas son **bonos de stats pasivos** que se colocan en sockets del equipamiento. NO modifican habilidades directamente — potencian al personaje como un todo.

### Cómo Funcionan

1. Las armas tienen **sockets** (1-3 según raridad del arma)
2. Cada socket acepta **1 gema**
3. La gema otorga un bono de stats mientras esté equipada
4. Cada gema tiene un **requisito mínimo de stat** para ser usada

### Sockets por Raridad de Arma

| Raridad | Sockets |
|---------|---------|
| Comun (blanco) | 1 |
| Raro (azul) | 2 |
| Magico (amarillo) | 2-3 |
| Unico (rojo vino) | 3 |

### Tipos de Gemas

| Gema | Bono | Requisito | Afinidad Natural |
|------|------|-----------|-------------------|
| **Gema de Fuerza** | +5 Daño físico | 10 STR | Warrior |
| **Gema de Poder Arcano** | +5 Daño mágico | 10 INT | Mage, Necro |
| **Gema de Precisión** | +4% Crit chance | 10 DEX | Archer |
| **Gema de Fortaleza** | +20 HP | 10 VIT | Warrior, Healer |
| **Gema de Resistencia Ígnea** | +15 Res. fuego raw | 8 DEF | Cualquiera |
| **Gema de Resistencia Gélida** | +15 Res. hielo raw | 8 DEF | Cualquiera |
| **Gema de Resistencia Eléctrica** | +15 Res. rayo raw | 8 DEF | Cualquiera |
| **Gema de Antídoto** | +15 Res. veneno raw | 8 DEF | Cualquiera |
| **Gema del Abismo** | +15 Res. vacío raw | 8 DEF | Cualquiera |
| **Gema de Brutalidad** | +10% Crit damage | 15 STR | Warrior, Archer |
| **Gema de Celeridad** | +5% Vel. ataque | 12 DEX | Archer |
| **Gema del Vacío** | +8 Daño mágico, -10 HP | 15 INT | Necro, Mage |

> Los valores son iniciales para balance. Se ajustan con playtesting.

### Autobalance por Requisitos

Los requisitos de stats hacen que las gemas graviten NATURALMENTE hacia la clase correcta:

- Un Mage con 12 INT y 4 STR → puede usar Gema de Poder Arcano, NO puede usar Gema de Brutalidad
- Un Warrior con 12 STR y 3 INT → puede usar Gema de Fuerza, NO puede usar Gema de Poder Arcano
- Un Archer con 12 DEX → puede usar Gema de Precisión y Gema de Celeridad

A medida que subís de nivel y asignás puntos, podés desbloquear gemas que normalmente no son de tu clase — eso permite builds híbridos para jugadores avanzados.

### Rareza de Gemas

Las gemas tienen las mismas 4 raridades que los items:

| Raridad | Color | Efecto |
|---------|-------|--------|
| Comun (blanco) | Blanco | Bono base |
| Raro (azul) | Azul | Bono mejorado (~1.5x) |
| Magico (amarillo) | Amarillo | Bono alto (~2x) + efecto secundario menor |
| Unico (rojo vino) | Rojo vino | Bono máximo + efecto especial único |

### Gemas y Equipamiento

- Las gemas se **engarzan permanentemente** en el arma (como Metin2)
- **Si el arma se rompe (enhancement fallido), las gemas se pierden con ella**
- Esto le da peso a la decisión de mejorar un arma con gemas valiosas
- Las gemas son **items dropeables** como cualquier otro loot
- Pueden aparecer en cualquier piso, pero gemas más fuertes/raras tienen mayor chance en pisos altos
- Se pueden intercambiar entre jugadores en co-op antes de engarzarlas

---

## Pendiente (definir en documentos futuros)

- [ ] Habilidades específicas por clase (las 6 de cada una)
- [ ] Qué boss/quest desbloquea cada maestría
- [ ] XP por uso: curva y valores base por habilidad
- [ ] Chance de bloqueo: fórmula y escudo stats
- [ ] Velocidad de ataque: fórmula y caps
- [ ] Bonos de rol por amuleto/anillo (curación, invocación, furia)
- [ ] Balance de items por piso (issue #24)
- [ ] Soft cap de evasión: ¿misma curva que resistencias?
- [ ] Berserker: fórmula exacta de VIT → daño
- [ ] Healer: fórmula de INT → poder de curación
- [ ] Costo de remover gemas de sockets
- [ ] Gemas mejoradas (Gema de Fuerza +1, +2, etc.) o solo variantes fijas
