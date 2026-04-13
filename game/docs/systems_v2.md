# Systems v2.0 — Dungeon Party

**Versión**: 2.0
**Fecha**: 2026-04-12
**Estado**: Design Document — sistemas nuevos aprobados en sesión 2026-04-12
**Departamento**: Game Design
**Relacionado**: `balance_v2.md` (curvas numéricas), `DESIGN_BRIEF.md`, `stats_system.md`, `party_activities.md`, `tower_biome_system.md`

---

## 0. Propósito

Documento hermano de `balance_v2.md`. Mientras `balance_v2` define curvas numéricas (HP/DMG/XP/etc), este doc define los **sistemas nuevos** decididos en sesión 2026-04-12:

1. Biomas acuáticos + snorkel + habilidades
2. Sistema de temperatura del personaje
3. Journal expandido (Bestiario + Herbario + Codex + Stats)
4. Polimorfismo (Shards de Alma, ref Tensei Slime + Solo Leveling)
5. Buffs por actividad (tabla completa)
6. Descanso + Crafteo (RDR2-style)
7. Estructura de bosses (narrativos + bioma + mini)

Todas las decisiones acá son **canon**. Conflictos con docs anteriores se resuelven a favor de este.

---

## 1. Biomas Acuáticos — Snorkel y Habilidades

### 1.1 Gate de acceso

**Los biomas acuáticos solo aparecen a partir del Piso 50.**

Razón de diseño:
- El agua no es early-game (prevención de frustración)
- El snorkel es progresión, no default
- El jugador llega preparado con gear del Tier I-II

Biomas afectados:
- **Océano Sumergido** — rango P50-75, parcialmente acuático (plataformas secas + zonas de agua)
- **Abismo Abismal** — rango P80-100, >60% acuático
- Lagos y ríos en otros biomas (Pantano, Selva) existen pero son **opcionales**, no requieren snorkel

### 1.2 Misión "Prueba del Aliento Profundo"

**Trigger**: al entrar al primer piso acuático (típicamente un Océano Sumergido post-P50).

**Objetivo**: obligatoria para desbloquear acceso completo al bioma. Sin completarla, el jugador solo puede moverse en la zona superficial del piso (~30% del mapa).

**Estructura**:
1. NPC sobreviviente en plataforma seca entrega **Snorkel Básico**
2. Enseña mecánicas de nado (3 waypoints subacuáticos para visitar)
3. Pelea tutorial contra 3 medusas (enemigo acuático básico)
4. Recompensa: snorkel se equipa permanentemente, acceso completo al piso

**Futuro coop**: si un jugador del party ya completó la misión, los demás heredan el acceso pero deben conseguir snorkel individualmente (mercader en piso acuático vende snorkel básico por 200 oro).

### 1.3 Equipamiento acuático — 3 tiers

#### Tier I — Snorkel Básico
- **Slot**: casco (alternativo, ocupa ese slot)
- **Obtención**: drop garantizado de la misión Prueba del Aliento Profundo / compra 200 oro
- **Efecto**: respirar infinito bajo agua, velocidad de nado 0.6×
- **Visual**: tubo simple de caña

#### Tier II — Aletas de Coral
- **Slot**: botas
- **Obtención**: drop raro de enemigos acuáticos del Océano Sumergido
- **Efecto**: +40% velocidad de nado, habilita **Dash Acuático** (cooldown 8s, distancia 6m)
- **Visual**: botas con aletas de coral luminiscente

#### Tier III — Snorkel Encantado
- **Slot**: casco (reemplaza Snorkel Básico)
- **Obtención**: drop legendario de jefes de bioma acuático (Kraken Menor, Sirena Ancestral)
- **Efecto**:
  - Todo lo del Básico
  - Visión nocturna bajo agua (aura de luz 5m, útil en Abismo)
  - Inmune a corrientes negativas (arrastre, vórtices)
  - Respiración compartida: aliados dentro de 3m reciben oxígeno si no tienen snorkel
- **Visual**: cristal arcano incrustado en la máscara, brillo azul

### 1.4 Montura acuática — Mantarraya Gigante

- **Slot**: montura (no stack con grifo/dragón terrestre)
- **Obtención**: drop legendario de evento raro en Océano Sumergido (post-P75)
- **Efecto**:
  - Solo se invoca en agua (zonas profundas)
  - +80% velocidad nado
  - **Planea bajo agua** como grifo plana en aire (movimiento 3D libre)
  - Puede cargar 2 jugadores (1 conductor + 1 pasajero) estilo carro cabras mini

**Uso coop**: escenario épico — jugador sin snorkel monta como pasajero y tiene oxígeno compartido. Alternativa al snorkel Tier III pero dependiente de aliado.

### 1.5 Habilidades acuáticas por clase

**Regla**: mientras el jugador esté sumergido (cabeza bajo agua), **una** habilidad terrestre se reemplaza por su versión acuática. Al salir del agua, vuelve la habilidad terrestre.

| Clase | Hab. terrestre reemplazada | Habilidad acuática | Efecto |
|-------|---------------------------|---------------------|--------|
| **Warrior** | Carga/Embestida | **Puño de Marea** | Puñetazo pesado usando corriente submarina como empuje. Knockback ×2 del normal, no cuesta stamina, impulsa al jugador 3m hacia el enemigo |
| **Mage** | Bola de fuego | **Lanza de Agua Presurizada** | Proyectil perforante, daño `INT×3`, atraviesa hasta 3 enemigos alineados |
| **Archer** | Flecha cargada | **Arpón Ancla** | Dispara arpón que engancha al enemigo. Modo 1 (shift): te tira hacia el enemigo. Modo 2: tira al enemigo hacia vos |
| **Necromancer** | Invocar esqueleto | **Cardumen Famélico** | Invoca cardumen de pirañas fantasmales (8 pirañas, vida 25s, daño en área, siguen al target más cercano) |
| **Cleric** | Sanación directa | **Burbuja Vivificante** | Crea burbuja en ubicación, radio 6m. Aliados dentro: oxígeno infinito + regen HP `INT×0.5/s` + **bloquea 50% daño recibido**. Duración 15s, cooldown 30s |

### 1.6 Reglas globales del agua

**Elementos**:
- **Fuego**: APAGADO bajo agua. Habilidades de fuego no hacen daño (el agua las extingue). Mensaje UI: "Ahogado por el agua". Diseño: el Mago Elementalista Fuego debe cambiar build o salir del agua.
- **Rayo**: AoE MASIVA en toda el agua continua del piso. Si conectás rayo con un enemigo en agua, daño se propaga a **todos los enemigos y aliados** en el mismo cuerpo de agua. Fuego amigo devastador. Pilar coop: comunicación vital.
- **Hielo**: al impactar, congela **2×2m de agua** creando plataforma temporal de 10s. Permite puzzles ambientales, movilidad creativa, trampas.
- **Viento**: crea burbuja de aire que arrastra al caster en la dirección del hechizo (movimiento impulsado).
- **Veneno/Vacío**: daño normal, sin modificación por agua.

**Combate**:
- Melee (sin hab acuática): velocidad de ataque ×0.5, daño igual
- Arco (sin hab acuática): drop gravitacional fuerte, rango -40%, penetración anulada
- Las **habilidades acuáticas listadas arriba** ignoran estas penalizaciones

**Movimiento**:
- Vel nado base: 0.6× terrestre
- Con Aletas de Coral: 0.84×
- Con Mantarraya: 1.08×
- Corrientes naturales empujan al jugador (dirección por piso, mapeable en exploración)

---

## 2. Sistema de Temperatura del Personaje

### 2.1 Medidor HUD

Termómetro vertical a la izquierda del HP/MP. 5 estados visibles:

| Estado | Rango (°C conceptual) | Efecto |
|--------|----------------------|--------|
| **Frío extremo** | < -10° | DoT 1% HP/s + vel mov -30% + vel ataque -30% |
| **Frío leve** | -10° a 10° | Vel ataque -10% |
| **Neutral** | 10° a 30° | Sin efecto |
| **Calor leve** | 30° a 45° | Stamina regen -20% |
| **Calor extremo** | > 45° | DoT 0.5% HP/s + stamina regen -50% + vel ataque -15% |

### 2.2 Fuentes ambientales

Ya definidas en `procedural_ecology.md`. Se integran al jugador con atenuación por distancia:

| Fuente | Temp base | Efecto en jugador según distancia |
|--------|-----------|-----------------------------------|
| Río de lava | +200 | A 5m: +100 (calor extremo), a 20m: +50 (calor leve) |
| Glaciar | -60 | A 5m: -40 (frío extremo), a 20m: -15 (frío leve) |
| Fogata | +40 | A 5m: +25, a 10m: +5 |
| Cristal de techo (día) | +15 | Global, neutral |
| Cueva de hielo interior | -40 | Constante mientras estés dentro |

Fórmula: `temp_jugador = temp_ambiente + Σ(fuente_cercana * atenuacion)` actualizado cada 1s.

### 2.3 Ropa afecta temperatura base

| Tipo armadura | Modificador temp |
|---------------|------------------|
| Placa pesada (metal) | +10° (cálido, mata en desierto) |
| Malla | +5° |
| Cuero | 0° (neutral) |
| Túnica/tela | -5° (fresco, vulnerable en tundra) |
| **Capa Térmica Gélida** (item especial) | -15° (inmune casi total a calor) |
| **Capa Térmica Abrasadora** (item especial) | +15° (inmune casi total a frío) |

Capas térmicas son items de slot secundario, drop Tier II-III de biomas específicos.

### 2.4 Consumibles térmicos

| Consumible | Efecto | Duración |
|------------|--------|----------|
| Sopa caliente | +20° | 5min |
| Poción de hielo | -20° | 5min |
| Pimienta del Dragón | Inmune a calor extremo | 3min |
| Hoja de Invierno | Inmune a frío extremo | 3min |
| Té ambarino (craft) | Mantiene temp en neutral sin importar ambiente | 2min |

### 2.5 Resistencias por clase/rama

| Clase/Rama | Inmunidad |
|------------|-----------|
| Mage Elementalista Fuego | Inmune a calor extremo |
| Mage Elementalista Hielo | Inmune a frío extremo |
| Warrior Berserker | Inmune a calor (la furia lo mantiene regulado) |
| Warrior Tank | Resist térmico general -5° a los modificadores de ropa pesada |
| Necromancer | -10° natural (afinidad con la muerte, frío es aliado) |
| Healer Buffer con skill "Equilibrio Térmico" (post-MVP) | Reduce 50% efectos térmicos a aliados en 20m |

### 2.6 Interacción con Aura de Resguardo

Separada. Aura de Resguardo = +5% resist cap elemental (no térmico). Equilibrio Térmico es otra skill del árbol Buffer, futura expansión.

---

## 3. Journal Expandido

### 3.1 UI principal

Tecla **J** abre Journal con 4 pestañas:
1. Bestiario
2. Herbario
3. Codex
4. Estadísticas

### 3.2 Bestiario

**Grid de portraits**. Silueta gris si no descubierto, imagen color si sí.

**Al clickear entrada**:
- Ficha: HP/DMG/DEF base del mob en el tier donde lo descubriste
- Habilidades conocidas (lista crece con kills)
- Drops conocidos (lista crece con drops obtenidos)
- Piso/bioma de avistamiento
- **Contador de kills acumulados**
- Biografía corta (lore de 2-3 párrafos)
- **Áreas donde aparece** (mapa con heatmap de biomas)

**Progresión por conocimiento**:

| Kills | Desbloqueo |
|-------|-----------|
| 1 | Entrada visible, silueta revelada |
| 10 | Stats base visibles |
| 50 | Drops rates visibles |
| 100 | Debilidad elemental visible + animaciones de ataque en la ficha |
| 500 | **Transformación desbloqueada** (ver §4 Polimorfismo) |

**Entradas especiales**:
- **Retirados** ⭐: marca especial, frase única de codex, "visto 1 vez el 2026-04-XX en P17"
- **Veteranos nombrados**: su nombre propio persiste ("Gorok el Cicatrizado — derrotado en P23 tras 2 encuentros")
- **Bosses únicos**: ficha extendida con fases y mecánicas

### 3.3 Herbario

Lista de plantas descubiertas.

**Por planta**:
- Imagen + nombre + descripción botánica
- **Condiciones de crecimiento**: rango temp/humedad/luz/nutrientes (exacto tras 10 recolecciones)
- Propiedades alquímicas conocidas (desbloqueo por experimentación en crafteo)
- Recetas que la usan como ingrediente
- Biomas donde crece

**Trigger desbloqueo**: primera recolección.

**Completismo**: recolectar todas (25+ plantas) desbloquea título "El Naturalista" + receta Elixir del Botánico.

### 3.4 Codex

Lore escrito coleccionable.

**Categorías**:
- **NPCs conocidos**: Capitán Valdo, Señora de Gatos, Operador de Transporte, etc. Diálogos registrados, ficha del NPC
- **Historia de la torre**: fragmentos encontrados en piedras, libros, murales. Arma la narrativa del mundo
- **Retirados**: cada uno con su frase única y ubicación
- **POIs especiales**: altares, tumbas con carta, fragmentos de mural, anomalías visitadas
- **Eventos vividos**: primera vez que activaste fiesta del pueblo, ritual completado, heist exitoso, etc.
- **Seeds especiales visitadas**: registro de dailies completadas, weekly challenges

### 3.5 Estadísticas

Métricas del personaje:
- Runs completados
- Piso máximo alcanzado
- Kills totales (por tipo de mob)
- Muertes totales + causas (fuego, caída, boss, etc.)
- Tiempo jugado
- Oro ganado, oro gastado
- Items únicos obtenidos
- Logros/títulos desbloqueados
- Tiempo de run más rápido por tramo
- Puente frágil: cuántas veces se rompió por tu culpa (meta-joke)

### 3.6 Recompensas por completar

| Completismo | Recompensa |
|-------------|------------|
| Bestiario 100% | Título "El Naturalista" + shard final raro + desbloqueo de transformación de boss final |
| Herbario 100% | Receta "Elixir del Botánico" (+3 todos stats por 30min) |
| Codex 100% | Acceso a piso secreto P50.5 "Archivo del Primer Aventurero" |
| Todos al 100% | Título legendario "El Completo" + cosmético único |

---

## 4. Polimorfismo — Shards de Alma

### 4.1 Lore

Referencia a *Tensei Slime* (Rimuru copia habilidades) y *Solo Leveling* (Jinwoo invoca sombras). Versión propia: el jugador **absorbe la esencia** de enemigos matados, no los invoca como súbditos. La transformación es temporal, es **su cuerpo cambiando**.

Narrativa: el Primer Aventurero descubrió que la torre "recuerda" a sus criaturas. Al matar muchos del mismo tipo, el jugador aprende a **imitar** su forma. Drop "Corazón Voraz" en quest del P50 desbloquea el sistema.

### 4.2 Obtención de Shards de Alma

**Drop por kill** (cantidad = 1 por drop):

| Tipo enemigo | Chance de drop shard |
|--------------|---------------------|
| Sub-A fodder | 0.5% |
| Sub-B depredador | 2% |
| Sub-C alfa | 5% |
| Veterano | 10% garantizado primer kill |
| Mini-boss | 10% |
| Boss de bioma | 20% |
| Boss narrativo (P25/50/75/95/100) | 20% chance primera vez, sube a 100% en el 5º kill |

**Milestone de kills** (forzado, no shard):

| Kills acumulados del mismo tipo | Efecto |
|---------------------------------|--------|
| 500 kills de sub-A | Transformación desbloqueada AUTOMÁTICAMENTE (sin shard) |
| 100 kills de sub-B | Transformación desbloqueada AUTOMÁTICAMENTE |
| 50 kills de sub-C | Transformación desbloqueada AUTOMÁTICAMENTE |
| 5 kills de boss | Transformación desbloqueada AUTOMÁTICAMENTE |

Esto asegura que el jugador dedicado SIEMPRE desbloquea (no luck-gate puro).

### 4.3 Shards requeridos para desbloquear

**Cuando obtenés un shard**, se acumula en el inventario de shards (JSON persistente del personaje).

| Enemigo | Shards necesarios |
|---------|-------------------|
| Sub-A | 10 shards o 500 kills |
| Sub-B | 5 shards o 100 kills |
| Sub-C | 3 shards o 50 kills |
| Mini-boss | 2 shards o ya-no-aplica (no se farmean) |
| Boss bioma | 2 shards o 3 kills |
| Boss narrativo | 1 shard o 5 kills |

### 4.4 Transformación en sí

**Requisito**: skill pasiva "**Corazón Voraz**" desbloqueada (drop quest P50).

**Activación**: menú de polimorfismo (tecla P). Selector con lista de transformaciones disponibles. Activación consume 1 uso (cooldown global 120s).

**Mientras transformado**:
- Tu HP/MP se reemplazan por los del mob (con proporción: 100% HP del mob máximo)
- Tus stats primarios se reemplazan por los del mob al tier del piso actual
- Tus habilidades se reemplazan por las del mob
- Tu movimiento/animación es del mob
- Si el mob vuela, volás. Si nada, nadás. Si tiene sprint especial, lo tenés.

**Duración por tier**:
- Sub-A: 60s
- Sub-B: 45s
- Sub-C: 30s
- Mini-boss: 45s
- Boss bioma: 60s
- Boss narrativo: 90s con habilidades completas del boss

**Si HP llega a 0 mientras transformado**: NO morís. Volvés a tu forma normal con 10% HP. Cooldown extendido a 240s.

**Cancelable**: podés volver a forma normal voluntariamente (tecla P otra vez).

### 4.5 Builds emergentes

Ejemplos de qué habilita el sistema:

- **Warrior + transform Golem T30**: tanque ultra-pesado, AoE suelo, knockback resist ∞
- **Mage + transform Dragon joven T80**: respiración de fuego área masiva, vuelo
- **Necromancer + transform Liche T70**: invocaciones masivas + teletransport
- **Archer + transform Hawk T15**: vuelo temporal + dive attack
- **Cleric + transform Fénix T90**: revive + aura daño de luz

Jugador de 500h+ tiene **biblioteca completa de transformaciones**. Rejugabilidad emergente.

### 4.6 No solapa con Necromancer

El Necro **invoca** criaturas (siguen al jugador, vida separada). El polimorfismo **transforma** al jugador (reemplaza su cuerpo). Son mecánicas distintas. El Necro incluso puede combinar: transformarse en Liche Y tener sus invocaciones activas (visual épico, balance por cooldown).

---

## 5. Buffs por Actividad — Tabla Completa

### 5.1 Regla anti-stack

Máximo **3 buffs de actividad** simultáneos. El 4º reemplaza el más antiguo. Evita "sesión de farmeo de buffs" antes de combates importantes.

Buffs de consumibles, pociones y equipamiento NO cuentan en este cap (son slots distintos).

### 5.2 Tabla maestra

| Actividad | Buff | Duración | Scope |
|-----------|------|----------|-------|
| **Banquete cocinado (5★)** | Regen HP +50% fuera combate + HP max +10% | 1h real | Grupo en el banquete |
| **Banquete cocinado (3-4★)** | Regen HP +25% | 30min | Grupo en el banquete |
| **Ritual de Invocación completo** | 1 invocación grupal compartida (bestia guardiana con HP+DMG escalado al tier actual) | 30min | Grupo ritual |
| **Concurso Humos Pipa (ganador)** | Regen MP +30% | 1h | Individual |
| **Concurso Humos Pipa (ganador, título)** | Título rotativo "Maestro del Humo" | 24h real | Individual |
| **Concurso de Tiro (ganador)** | Crit chance +10% | 1h | Individual |
| **Concurso de Tiro (ganador, item)** | Arco único "Ojo de Águila" + título | Permanente | Individual |
| **Duelos a 1 HP (ganador)** | +3 STR + título "Campeón del Puesto" | 30min + título 24h | Individual |
| **Lucha de Brazos del Campeón (completar 5 NPCs)** | +5 STR permanente + título "Brazo de Hierro" | Permanente | Individual |
| **Trago del Valiente (último en pie)** | Random 1 de 5: +3 a stat random, regen ×2, inmune 1 status, vel mov +15%, crit dmg +30% | 45min | Individual |
| **Fiesta del Pueblo (bailar)** | +1 Luck + moral (XP +15%) | 2h | Grupo local |
| **Fiesta del Pueblo (comer mesa)** | Heal completo + regen +30% | 30min | Individual |
| **Fiesta del Pueblo (escuchar juglar)** | 1 POI oculto revelado en mapa | Permanente este run | Individual |
| **Concurso de Pesca (ganador)** | Luck +10% | 2h | Individual |
| **Concurso de Pesca (ganador, item)** | Caña legendaria "Rey del Lago" | Permanente | Individual |
| **Noche de Estrellas Fugaces (deseo al ver estrella)** | 1 buff random potente (+5 stat, regen x3, inmune status, crit +20%, etc.) | 24h real | Individual |
| **Carrera del Jabalí Salvaje (ganar)** | Vel mov +10% | 1h | Individual |
| **Cocinar Banquete (colaborar como rol)** | +1 stat de tu elección | 30min | Individual |
| **Ritual Invocación (derrotar boss secreto)** | Item legendario único del altar | Permanente | Grupo |
| **Heist Huevo de la Dragona (completar)** | Pastel de Ogro legendario: +2 todos stats | 3h real | Grupo |
| **Heist Flauta del Cíclope (completar)** | Desbloquea instrumento flauta | Permanente | Individual |
| **Heist Boda del Ogro (completar)** | Pastel de Ogro: +2 todos stats | 3h real | Grupo |
| **Apuesta del Diablo (ganar)** | +1 stat permanente de tu elección | Permanente | Individual |
| **Apuesta del Diablo (perder)** | -1 stat permanente | Permanente | Individual |
| **Subasta del Tuerto (ganar puja)** | Item único de la subasta | Permanente | Individual |
| **Río Subterráneo (coop perfect)** | Acceso a zona oculta + cofre especial | Permanente | Grupo |
| **Meditar en fogata (5min sin moverse)** | Regen MP +100% | 10min | Individual |
| **Sentarse en fogata con 3+ aliados** | Buff "Hermandad": daño recibido -10% | 30min | Grupo local |
| **Brindar sincronizado (4+ jugadores)** | +1 Luck + Moral | 5min | Grupo cerca |
| **Rezar en altar** | Buff aleatorio (heal, regen, +crit, +vel) | 15min | Individual |

### 5.3 Buffs permanentes (stack illimitado)

Los que dicen "Permanente" NO cuentan para el cap de 3. Son logros del personaje, se acumulan en el Codex.

### 5.4 Pérdida de buffs

- Al morir: buffs temporales se pierden (excepto títulos)
- Al salir al menú principal: buffs temporales se pausan (su timer continúa en tiempo real igual, no se extienden)
- Al pasar entre pisos: buffs continúan (si corresponde: buffs grupales solo persisten si los aliados siguen cerca)

---

## 6. Descanso + Crafteo (RDR2-style)

### 6.1 Concepto

El jugador puede **descansar** en zonas seguras para abrir un menú de crafteo/mejora. Inspirado en Red Dead Redemption 2 (agacharse en fogata → cocinar). NO pausa el juego (canon §9 brief).

### 6.2 Activación

**Tecla**: Shift+E (agacharse/descansar)

**Requisitos**:
- Estar fuera de combate por 5s (no damage dado/recibido)
- Estar en **zona segura** o cerca de fogata/altar/fuente de recurso
- No estar montado

**Efecto de activación**:
- Personaje se agacha en animación de descanso
- Aparece UI radial con opciones:
  - Cocinar
  - Alquimia
  - Reparar
  - Mejorar (enhancement)
  - Meditar

### 6.3 Zonas seguras válidas

| Tipo | Ubicación | Opciones disponibles |
|------|-----------|----------------------|
| Fogata del Puesto (P1) | P1 outpost | Todas |
| Fogata improvisada (craft) | Cualquier piso con madera + pedernal | Cocinar, Meditar |
| Altar en POI | Cualquier piso con altar | Alquimia, Meditar, Rezar |
| Safe Zone ancla | P25, P50, P75, P95 | Todas + mercaderes |
| Taverna móvil | Eventos raros | Cocinar, Meditar |
| Zona sin enemigos + bedroll | Si llevás bedroll en inventario | Meditar, guardar |

### 6.4 Cocinar

**Ingredientes**: carnes de fauna + plantas del herbario + agua.

**Receta**: seleccionar 2-4 ingredientes, el sistema calcula el resultado.

**Outputs**:
- **Stew básico**: regen HP leve 5min
- **Stew avanzado** (con carne rara + planta rara): regen HP +50% 30min
- **Banquete** (varios stews + ingrediente legendario): buff grupal (ver §5.2)
- **Comida cruda**: 10% chance intoxicación (DoT 30s)

**Tiempo de crafteo**: 30s - 2min según receta. **NO pausa juego**. El jugador es vulnerable mientras cocina.

**Riesgo emergente**: si un enemigo aparece durante el crafteo, se cancela, pierde ingredientes crudos, pero recupera mitad de plantas.

### 6.5 Alquimia

Similar pero con plantas y agua.

**Outputs**:
- Pociones básicas (HP, MP, antídoto)
- Pociones avanzadas (regen, resistencia elemental temporal)
- Pociones térmicas (Sopa caliente, Poción de hielo, ver §2.4)
- Pociones experimentales (efectos random, high risk high reward)

**Experimentación**: mezclar 2 plantas nunca combinadas da efecto random. Se registra en Herbario si es útil.

### 6.6 Reparar

Requiere **kit de reparación** (item comprable o craftable).

- Reparación común: costo bajo, arma vuelve a 100% durabilidad
- Reparación mejorada (kit avanzado): arma gana +5% stats temporales 30min

**No rompe** el arma si falla. Diseño: fallos de enhancement son el único riesgo de pérdida (ver §6.7).

### 6.7 Mejorar (Enhancement +1 a +9)

Solo disponible en herrerías de safe zones (P25, P50, P75, P95). NO en descanso improvisado.

Ya canon en sistema actual: arma con chance de romperse en +5+. Gemas se pierden con el arma.

### 6.8 Meditar

Sin requisitos extras.

**Efecto**:
- Regen MP +100% mientras meditás (no moverte)
- Interrumpible (cualquier acción la corta)
- Dura hasta que te muevas o pasen 5min (buff máximo)

### 6.9 Bedroll — guardar progreso fuera de safe zone

Item comprable/craftable. Permite guardar el progreso del run **una vez por piso** en cualquier zona sin combate.

Consume el bedroll (single-use). Útil para runs largas donde la safe zone siguiente está lejos.

### 6.10 UI radial de descanso (mockup)

```
         [Cocinar]
            |
[Alquimia]--•--[Reparar]
            |
         [Mejorar]
            |
         [Meditar]
```

Control: mouse o stick analógico. Selección con click/botón.

---

## 7. Estructura de Bosses — Narrativos + Bioma + Mini

### 7.1 Bosses fijos narrativos (anclas de tier)

**5 bosses inmutables**, siempre en el mismo piso, cierran cada Tier.

| Piso | Boss | Tier que cierra |
|------|------|-----------------|
| P25 | **Trono Viscoso** (Rey Slime poseyendo salón del trono devorado) | Tier I Ascenso Civilizado |
| P50 | **Midpoint Boss** (working title: "La Última Civilización" — guardián del último NPC humano) | Tier II Frontera |
| P75 | **Guardián del Salar** (working title — boss del Salar de los Espejos) | Tier III Wilderness |
| P95 | **El Otro** (working title — boss de Mundo Espejo o equivalente del Tier IV) | Tier IV Anomalía |
| P100 | **El Arquitecto** (boss final, 4 fases, cada fase un bioma visitado) | Tier V Mito |

Estos son **gate obligatorios**. No podés pasar al Tier siguiente sin derrotarlos.

Estructura de fases ya definida en tower_biome_system.md (4 fases: 100-75%, 75-50%, 50-25%, 25-0%).

### 7.2 Bosses de bioma (dinámicos, seed decide)

Cuando un bioma termina y va a cambiar, el **último piso de ese bioma** tiene un boss de bioma.

**Stats**: sub-tier C × 3. Fases mecánicas únicas. **Gate del bioma** (no del tier — podés elegir otra ruta si la cadena de adyacencia lo permite).

**Ejemplos por bioma**:

| Bioma | Boss de bioma (ejemplos) |
|-------|---------------------------|
| Pradera | Oso Corrupto, Capitán Bandido del Campamento |
| Bosque Denso | Treant Ancestral, Reina Araña |
| Cavernas de Cristal | Golem de Cuarzo Antiguo |
| Pantano | Hidra de Pantano |
| Tundra | Yeti Rey, Dragón de Escarcha |
| Volcán | Salamandra Ancestral, Golem de Obsidiana |
| Ruinas | Golem Guardian Mayor |
| Desierto | Esfinge, Rey Escorpión |
| Océano | Kraken Menor, Sirena Ancestral |
| Cielo | Dragón de Tormenta |
| Selva | Jaguar Sombra Ancestral |
| Forja | Araña Mecánica |
| Catacumbas | Liche Mayor |
| Jardín Corrompido | Bestia del Jardín |
| Ciudad | Rata Rey, Guardián de la Ciudad |
| Hongos | Colonia Madre |
| Reloj | Guardián del Reloj |
| Ceniza | Remanente del Cataclismo |
| Espejo | El Otro (variante, no confundir con P95) |
| Laboratorio | Archimago Loco |
| Salar de los Espejos | **Guardián del Reflejo** (nuevo, Tier III) |

**Densidad esperada**: 5-8 bosses de bioma por run (depende de cadena de biomas del seed).

### 7.3 Mini-bosses intra-bioma

Cada ~5 pisos, dentro del mismo bioma, un encuentro **elite opcional**.

**Características**:
- Stats = sub-tier C × 1.5
- Aparece en POI opcional (sub-dungeon, cueva, altar especial)
- Drop garantizado: 1 raro + posible shard de alma
- NO tiene fases complejas, solo 1-2 habilidades extras respecto al C normal
- NO bloquea avance (podés skipear)

**Ejemplos por bioma**:
- Pradera: Líder de Pack Bandido, Osezno Maduro
- Bosque: Araña Matriarca, Treant Joven
- Volcán: Diablillo Jefe, Salamandra Gigante
- Etc.

### 7.4 Distribución final típica por run

Run completo de 100 pisos esperado:

| Tipo | Cantidad | Distribución |
|------|----------|--------------|
| Bosses fijos narrativos | 5 | P25, P50, P75, P95, P100 |
| Bosses de bioma | 5-8 | Al final de cada tramo de bioma (seed decide) |
| Mini-bosses intra-bioma | 15-20 | Cada ~5 pisos, opcionales |
| **Total encuentros boss/miniboss** | **~25-33** | Densidad: uno cada 3-4 pisos |

Con pisos de 30min primera pasada, hay un encuentro epic cada ~2h de juego. Pacing satisfactorio.

### 7.5 Sistema de pool de bosses narrativos (post-MVP)

Ya definido en `DESIGN_BRIEF.md` §8.14. Resumen:

- MVP: 1 boss por tier (total 5).
- Update 1: +1 alternativo por tier (total 10).
- Update 2: +1 alternativo más por tier (total 15).
- Cada trío narrativamente conectado (mismo arco, distintos momentos).

Ejemplo Tier I trío:
- **Trono Viscoso** (MVP) — rey tragado por slime
- **La Corte Disuelta** — 3 mini-bosses simultáneos (Guardián+Bufón+Escriba)
- **El Eco del Rey** — fantasma verde con forma de corona

Seed determina cuál aparece en el run.

### 7.6 Boss telegraph + fairness

Regla canon del brief anti-pattern: TODOS los ataques de boss tienen telegraph visual/sonoro. TODOS los peligros ambientales tienen aviso. La muerte siempre es culpa del jugador, nunca RNG injusto.

- Telegraph mínimo: 0.5s antes del impacto
- Ataques lentos: telegraph 1-2s (dan tiempo de reacción)
- Ataques one-shot: telegraph 3s + aviso sonoro + zona marcada en suelo

---

## 8. Resumen de decisiones canon

Para referencia rápida, las decisiones consolidadas de esta sesión:

| Sistema | Decisión |
|---------|----------|
| Biomas acuáticos | Gate P50+. Misión obligatoria "Prueba del Aliento Profundo" al entrar al primero |
| Snorkel | 3 tiers (Básico → Aletas Coral → Encantado) |
| Montura acuática | Mantarraya Gigante (drop legendario post-P75) |
| Habilidades acuáticas | 1 por clase (Puño Marea, Lanza Presurizada, Arpón Ancla, Cardumen Famélico, Burbuja Vivificante heal+escudo) |
| Reglas agua | Fuego off, Rayo AoE masiva, Hielo hace plataformas, Viento arrastra |
| Temperatura personaje | 5 estados, ropa+consumibles+fuentes ambientales |
| Journal | 4 pestañas (Bestiario, Herbario, Codex, Stats) |
| Polimorfismo | Shards de Alma, 1 shard por drop, milestones forzados por kill count, boss 20% → 100% en 5º |
| Corazón Voraz | Pasiva desbloqueable en quest P50 |
| Buffs actividad | Cap 3 simultáneos |
| Descanso RDR2 | Shift+E, cocinar+alquimia+reparar+mejorar+meditar, no pausa |
| Bosses | 5 fijos (P25/50/75/95/100) + 5-8 bioma + 15-20 mini |
| Aura de Resguardo | Skill pasiva Healer-Buffer, +5% resist cap en radio 20m |

---

## 9. Próximas sesiones — pendientes

Sistemas documentados pero necesitan profundización:
1. Detalle de las 5 transformaciones prioritarias (balance de stats/habs)
2. Lista de plantas del herbario (25+ con condiciones)
3. Recetas de cocina (tabla completa ingredientes → resultado)
4. Pool de bosses de bioma (definir 3 variantes por bioma post-MVP)
5. NPCs específicos de safe zones P25/50/75/95 (diálogos, ofertas)
6. Sub-dungeons por bioma (entrada, layout, mini-boss, reward)
7. Nombres definitivos de bosses P50/75/95 (working titles actuales)
8. Animaciones + FX para transformaciones (art dept)

---

*Documento preparado por Dept Design, sesión 2026-04-12. Canon hasta que una sesión futura decida lo contrario.*
