# Dungeon Party — Métricas de Escala del Mapa

**Departamento**: Game Design  
**Fecha**: 2026-04-08  
**Estado**: v2.0 — REESCRITURA MAYOR: de dungeon de salas a mundos abiertos con POIs

> **Cambio de visión**: La v1.x modelaba cada piso como una secuencia de salas conectadas por pasillos. Feedback de prototipo confirmó que esa escala se siente "un pueblo dentro del piso, no el piso entero". La v2.0 adopta la visión de **cada piso es un mundo** — ecosistemas completos al estilo de los pisos de Aincrad (SAO), el Dungeon de Orario (Danmachi) y los mapas de zonas de Metin2.  
> Las secciones 1 y 11 se mantienen con ajustes; el resto es nuevo.

---

## 1. Referencia: Unidad Humana (Player como metro patrón)

Todas las métricas parten del jugador como unidad de referencia. Godot usa metros reales: 1 unidad = 1 metro.

| Medida | Valor | Fuente |
|--------|-------|--------|
| Radio de cápsula (jugador) | 0.35 m | `player.tscn` — CapsuleShape3D |
| Altura de cápsula (parado) | 1.8 m | `player.tscn` — CapsuleShape3D |
| Altura de cápsula (agachado) | 0.9 m | `base_player.gd` — `crouch_height` |
| Altura de cámara (ojos) | 0.8 m sobre pivot | `player.tscn` — Head Y = 0.8 |
| Altura de ojos real | ~1.6 m sobre el piso | cápsula centrada en Y=0 → centro a 0.9m, ojos a 0.8m sobre eso |
| Ancho visual del jugador | ~0.7 m diámetro | radio × 2 |

| Medida | Valor | Fuente |
|--------|-------|--------|
| Altura enemigo básico | 1.6 m | `enemy_basic.tscn` — BoxMesh |
| Ancho/profundidad enemigo | 0.8 m | `enemy_basic.tscn` — BoxMesh |
| Rango ataque melee | 3.0 m | `base_player.gd` — `attack_range` |

| Medida | Valor | Fuente |
|--------|-------|--------|
| Arena prototipo | 20 × 20 m | `main.tscn` — BoxShape3D piso |
| Altura paredes prototipo | 4.0 m | `main.tscn` — BoxShape3D paredes |

**Relación jugador/pared**: el jugador mide 1.8m de alto contra paredes de 4m → ratio 1:2.2. Proporción correcta para first-person: el techo se siente alto sin perder escala humana.

**Velocidades de referencia para calcular tiempos de cruce**:

| Modo | Velocidad |
|------|-----------|
| Caminar normal | 5 m/s |
| Sprint | 8 m/s |

---

## 2. Nueva Filosofía de Escala — El Piso como Mundo

### 2.1 Referentes de Diseño

**SAO — Sword Art Online (Aincrad)**  
Cada uno de los 100 pisos de Aincrad es un mundo entero: praderas enormes, ciudades con habitantes, bosques con ríos, lagos navegables, ruinas antiguas. Los jugadores viven semanas dentro de un solo piso. El "dungeon" está al fondo del mundo, no ES el mundo.  
→ **Lección**: el piso es el continente. El dungeon principal es uno de sus POIs, no el contenedor de todo.

**Danmachi — Is It Wrong to Try to Pick Up Girls in a Dungeon?**  
Los pisos del Dungeon debajo de Orario son ecosistemas completos: cielos propios, biomas distintos, fauna autónoma, ríos subterráneos, ciudades de monstruos en pisos profundos. Los aventureros pueden perderse genuinamente.  
→ **Lección**: cada piso tiene identidad ecológica propia. La escala genera pérdida de orientación como mechanic intencional.

**Metin2**  
Mapas masivos con zonas temáticas diferenciadas (City 1, City 2, Map 1, Map 2) dentro de un mundo continuo. Las zonas son áreas con identidad propia pero comparten el mismo espacio de mundo. El jugador tarda minutos en cruzar cada mapa a pie.  
→ **Lección**: zonas diferenciadas dentro de un espacio masivo continuo. El tamaño crea sensación de mundo habitable.

### 2.2 El Principio Fundamental

> **Un piso NO es una secuencia de salas. Un piso es un ecosistema con Points of Interest (POIs) distribuidos en un campo abierto.**

La diferencia conceptual:

| Modelo v1.x (salas) | Modelo v2.0 (mundo abierto) |
|--------------------|-----------------------------|
| El mapa ES los pasillos y salas | Los pasillos y salas son POIs dentro del mapa |
| El jugador siempre sabe dónde está | El jugador puede perderse — eso es parte del juego |
| Cruzar un piso toma minutos contados | Cruzar un piso toma 10-40 minutos |
| El boss está "al final del dungeon" | El boss está en un POI específico del mundo |
| El espacio vacío es error de diseño | El campo abierto entre POIs ES contenido |

---

## 3. Tamaño Total del Mapa por Piso

### 3.1 Dimensiones Base

| Piso | Mundo | Dimensiones | Área total | Tiempo de cruce diagonal (sprint) |
|------|-------|------------|------------|----------------------------------|
| 1 | Pradera Interior | 600 × 600 m | 360.000 m² | ~106 s (~1.8 min) |
| 2 | Bosque / Selva | 700 × 700 m | 490.000 m² | ~124 s (~2.1 min) |
| 3 | Hielo / Cavernas | 650 × 500 m | 325.000 m² | ~102 s (~1.7 min) |
| 4 | Tormenta / Cielo | 800 × 400 m | 320.000 m² | ~111 s (~1.9 min) |
| 5 | Dimensión Rota | 700 × 700 m | 490.000 m² | ~124 s (~2.1 min) |

> **Tiempo de cruce diagonal** = diagonal del rect. ÷ 8 m/s (sprint). No incluye obstáculos, encuentros ni navegación — es el mínimo físico posible. En juego real, cruzar un piso toma **10-40 minutos** dependiendo de la cantidad de POIs explorados y combates encontrados.

### 3.2 Justificación de Escala

**600 × 600 m como baseline (Piso 1)**:
- Diagonal: ~849 m. En sprint constante sin obstáculos: ~106 segundos. En juego real con encuentros y exploración: 15-30 minutos mínimo para cruzar de punta a punta.
- Comparación humana: 600 m es la distancia de un estadio de fútbol completo × 6. No es un campo — es un municipio.
- Comparación con v1.x: el piso 1 anterior era 110 × 70 m (7.700 m²). La v2.0 es 47× más grande en área.

**¿Por qué no más grande (ej. 2000 × 2000)?**
- Performance: un mundo de 2km² con assets 3D en Godot 4 sin streaming de LOD y sin mundo abierto optimizado es un problema técnico real en esta fase del proyecto.
- Densidad: 600 × 600 m con ~15-20 POIs distribuidos da densidad de 1 POI cada ~40 m promedio — suficiente para que el campo abierto se sienta habitado sin estar saturado.
- El tamaño puede escalar a 1000 × 1000 m en producción si se implementa occlusion culling y LOD agresivo. La métrica de 600 × 600 es el target para prototipo playable.

---

## 4. Points of Interest (POIs) — Los Nodos del Mundo

Los POIs reemplazan el concepto de "salas". Cada POI es una zona con identidad, contenido propio y radio de influencia. Entre POIs hay campo abierto.

### 4.1 Clasificación de POIs

| Categoría | Descripción | Obligatorio |
|-----------|-------------|------------|
| **POI Ancla** | Define el POI principal del run — siempre presente, siempre único | Sí |
| **POI Mayor** | Zona de contenido sustancial — combate + loot + contexto | Sí (mínimo 3) |
| **POI Menor** | Zona pequeña de oportunidad — puede estar o no según semilla | No (0-4 por run) |
| **POI Secreto** | Oculto — el jugador tiene que buscarlo activamente | No (0-2 por run) |

### 4.2 Tamaños de POI

**POI Ancla** (boss, punto de entrada/salida):

| POI Ancla | Tamaño | Radio de influencia | Descripción |
|-----------|--------|--------------------|-|
| Portal de Entrada | 30 × 30 m | 50 m de campo libre a su alrededor | Zona segura inicial, sin enemigos dentro |
| Arena del Boss | 80 × 80 m | 100 m de campo libre | Combate de boss. El campo libre a su alrededor es zona de "pre-boss" con patrullas fuertes |
| Portal de Salida | 20 × 20 m | 30 m de campo libre | Aparece tras matar el boss. Puede estar cerca del boss o al otro extremo del mapa |

**POI Mayor**:

| Tipo de POI Mayor | Tamaño | Radio de influencia |
|-------------------|--------|---------------------|
| Ruinas / Estructura | 60 × 60 m — 80 × 80 m | 40 m |
| Asentamiento (pueblo, campamento) | 80 × 100 m — 100 × 120 m | 60 m |
| Feature Natural (lago, peñasco, bosque denso) | 40 × 60 m — 100 × 100 m | 30 m |
| Dungeon Interno (cueva, cripta) | 30 × 50 m (entrada) + interior | 20 m de entrada |

**POI Menor**:

| Tipo de POI Menor | Tamaño | Radio de influencia |
|-------------------|--------|---------------------|
| Campamento abandonado | 15 × 15 m — 25 × 25 m | 15 m |
| Altar / Santuario | 10 × 10 m — 15 × 15 m | 10 m |
| Emboscada de patrulla | No tiene estructura física | Radio de detección del grupo |
| Loot Disperso | Sin zona — varios items en el terreno | — |

**POI Secreto**:

| Tipo de POI Secreto | Tamaño | Señal de descubrimiento |
|--------------------|--------|------------------------|
| Cripta oculta | 20 × 30 m (interior) | Entrada semi-cubierta por vegetación o geometría |
| Tesoro de explorador | Sin zona | Cuerpo visible si el jugador se desvía >30 m del camino principal |
| Zona de lore | 10 × 10 m | Señal ambiental sutil (luz diferente, sonido extraño) |

---

## 5. Generación Procedural con Semillas

### 5.1 Qué Controla la Semilla

La semilla (`seed`) de cada run determina:

| Elemento | ¿Controlado por seed? | Notas |
|----------|-----------------------|-------|
| Posición de POIs Mayores | **Sí** | Dentro de zonas válidas (ver reglas de colocación) |
| Posición de POIs Menores | **Sí** | Pueden no aparecer — la seed define cuáles del pool están activos |
| Posición de POIs Secretos | **Sí** | — |
| Tipo de POI Mayor | **No** | El pool de tipos es fijo por piso; la seed elige posición, no tipo |
| Contenido interno del POI | **No** | Cada POI tiene su contenido definido (mismo pool de enemigos, mismo tier de loot) |
| Posición de spawn de enemigos dentro de un POI | **Sí** | Varía entre runs |
| Patrullas de campo abierto | **Sí** | Rutas y composición |
| Loot disperso en campo | **Sí** | Posición de items sueltos entre POIs |
| Seed visible al jugador | **Sí** | El jugador ve la seed en la pantalla de carga — puede compartirla con otros |

**Invariante de la seed**: dos jugadores con la misma seed en el mismo piso ven exactamente el mismo mundo. Esto permite: compartir runs memorables, comparar rutas, speedruns con seed conocida.

### 5.2 Reglas de Colocación de POIs (Constraints del Generador)

El generador ubica los POIs satisfaciendo estas reglas en orden de prioridad:

**Reglas absolutas (no se violan nunca)**:

| Regla | Valor |
|-------|-------|
| Distancia mínima entre cualquier par de POIs (borde a borde) | 80 m |
| Distancia mínima POI Mayor — borde del mapa | 100 m |
| Distancia mínima POI Ancla (boss) — Portal de Entrada | 350 m |
| El Portal de Entrada siempre en uno de los 4 cuadrantes de borde | Norte, Sur, Este u Oeste — nunca centro |
| El Portal de Salida nunca en el mismo cuadrante que la Entrada | — |

**Reglas de proximidad temática (preferencias del generador, no absolutas)**:

| Regla | Descripción |
|-------|-------------|
| Feature natural cerca de asentamiento | Un lago o bosque a 100-200 m de un pueblo da contexto |
| Dungeon Interno lejos del camino principal | Mínimo 150 m del eje Entrada→Boss para ser realmente "secreto" |
| POIs Menores distribuidos a lo largo del eje Entrada→Boss | Al menos 1 cada 150 m de camino |
| Zonas de emboscada no adyacentes entre sí | Mínimo 100 m entre dos emboscadas para no saturar |

**POIs que NO pueden estar cerca entre sí**:

| Par de POIs | Distancia mínima obligatoria |
|------------|------------------------------|
| Dos asentamientos | 300 m |
| Arena del Boss + cualquier otro POI Mayor | 150 m |
| Dos Dungeons Internos | 250 m |

### 5.3 Número de POIs por Run

| Categoría | Piso 1-2 | Piso 3-4 | Piso 5 |
|-----------|----------|----------|--------|
| POI Ancla | 2 (entrada + boss) | 2 | 2 + 1 sub-boss |
| POI Mayor | 3 – 5 | 4 – 6 | 5 – 7 |
| POI Menor | 0 – 3 | 1 – 4 | 2 – 5 |
| POI Secreto | 0 – 1 | 0 – 2 | 1 – 2 |
| **Total POIs** | **5 – 11** | **7 – 14** | **10 – 17** |

Con un mapa de 600 × 600 m y hasta 11 POIs → densidad promedio de 1 POI cada 3.600 m² (radio de influencia promedio de ~33 m). El resto es campo abierto.

---

## 6. El Campo Abierto Entre POIs

El campo abierto NO es espacio vacío. Es el tejido conectivo del mundo y tiene su propio sistema de contenido.

### 6.1 Capas del Campo Abierto

| Capa | Descripción | Densidad |
|------|-------------|---------|
| **Terreno base** | Geometría del suelo — elevaciones suaves, depresiones, senderos marcados por el uso | Continua |
| **Vegetación decorativa** | Pasto, arbustos, flores — assets estáticos | Alta (70-80% de la superficie) |
| **Elementos de escala** | Árboles aislados, rocas, ruinas menores, postes caídos — dan verticalidad y orientación | Media (cada 15-30 m promedio) |
| **Senderos naturales** | Caminos de tierra entre POIs — el terreno "recuerda" el paso de gente | Entre POIs conectados |
| **Patrullas errantes** | Grupos de 2-4 enemigos que recorren rutas entre POIs | Ver sección 7 |
| **Loot disperso** | Items sueltos, bolsas, cuerpos — no garantizados, seed-dependiente | Baja (cada 80-150 m) |
| **Encuentros aleatorios** | Eventos que se activan al pasar por zonas específicas | Ver sección 6.3 |

### 6.2 Senderos Naturales

Los senderos son el sistema de "pasillos" del mundo abierto — pero no son paredes, son sugerencias de ruta.

| Tipo de sendero | Ancho | Función |
|----------------|-------|---------|
| Camino principal | 4 – 6 m | Eje Entrada → Boss. El más visible, más transitado por patrullas |
| Camino secundario | 2 – 3 m | Conecta POIs adyacentes fuera del eje principal |
| Sendero de exploración | 1 – 2 m | Lleva a POIs Menores y Secretos — el jugador tiene que buscarlo |

**El jugador nunca está obligado a seguir un sendero.** Puede cruzar campo abierto directamente. Los senderos ofrecen:
- Terreno más plano (menos obstáculos)
- Densidad de patrullas mayor (más riesgo + más loot)
- Señales de navegación naturales (mojones de piedra, postes)

**Lo que NUNCA debe pasar**: senderos con paredes invisibles. El jugador puede abandonar el sendero en cualquier punto.

### 6.3 Encuentros Aleatorios en Campo Abierto

Los encuentros aleatorios son eventos seed-dependientes que se activan cuando el jugador entra en un radio de 20-30 m de una zona marcada en el generador. No son POIs (no tienen estructura física) pero sí tienen contenido propio.

| Tipo de encuentro | Probabilidad base | Contenido |
|-------------------|------------------|-----------|
| Patrulla reforzada | 30% | 4-6 enemigos, composición variada. Sin estructura. Loot de combate. |
| Mercader errante | 10% | NPC con tienda básica. Sin combate. |
| Trampa ambiental | 20% | Zona marcada visualmente (pasto quemado, suelo diferente). Daño o ralentización si se ignora. |
| Cuerpo de aventurero | 25% | Item de tier medio visible en el piso. Sin combate. |
| Evento de fauna | 15% | Manada de criaturas pasivas que huye — señal de que hay enemigos cerca. No hay combate directo. |

### 6.4 Densidad de Patrullas en Campo Abierto

Las patrullas son grupos de enemigos que recorren rutas fijas entre POIs o dentro de zonas del campo abierto.

| Zona | Densidad de patrullas | Composición típica |
|------|----------------------|-------------------|
| Eje principal (Entrada→Boss) | Alta — 1 patrulla cada 80-100 m de ruta | 3-4 enemigos básicos |
| Caminos secundarios | Media — 1 patrulla cada 120-150 m | 2-3 enemigos básicos |
| Campo abierto fuera de senderos | Baja — 1 patrulla cada 200-250 m | 2 enemigos básicos o 1 élite solo |
| Radio de influencia de POI Mayor | Alta dentro del radio — patrullas circulares | 4-6 enemigos, posible élite |

**Comportamiento de patrullas**:
- Ruta fija determinada por la seed
- Si detectan al jugador, rompen la ruta y pursuien (igual que `enemy_basic.gd` actual)
- Tras perder al jugador, vuelven a la ruta original (no se quedan perdidos)
- No se regeneran en el mismo run — si se matan, esa ruta queda libre

---

## 7. Navegación del Jugador Sin Minimapa

El jugador no tiene minimapa al comienzo. La orientación depende de señales del mundo.

### 7.1 Sistema de Landmarks

Cada mapa tiene 3-5 landmarks de escala masiva visibles desde cualquier punto del mapa. No son decoración — son el sistema de navegación primario.

| Tipo de landmark | Altura visible | Escala | Ejemplo en Piso 1 (Pradera) |
|------------------|---------------|--------|------------------------------|
| Pilar de la Torre | 40-80 m sobre el suelo | 3-5 pilares en el mapa | Columnas colosales que sostienen el techo del piso — siempre visibles |
| Feature natural extremo | 20-40 m | 1-2 en el mapa | Árbol de 30m de altura, peñasco masivo |
| Estructura del Boss | 15-25 m | 1 en el mapa | Ruinas imponentes o formación anormal en el horizonte |

**Regla de diseño**: el jugador debe poder ver al menos 2 landmarks desde cualquier punto del mapa. Si un landmark no es visible desde el 80% del mapa, está mal diseñado o es demasiado bajo.

**Por qué esto funciona (referencia Danmachi)**: los aventureros del Dungeon conocen el piso por landmarks, no por mapas. "Girá a la derecha del Árbol Roto" es comunicación válida de navegación. Los landmarks crean vocabulario compartido entre jugadores cooperativos.

### 7.2 Brújula (UI mínima)

Sin minimapa, el jugador tiene una brújula simple en el HUD:
- Solo muestra los 4 puntos cardinales + dirección de "objetivo activo" si hay uno
- El objetivo activo es el POI más relevante de la ruta actual (configurable por el jugador)
- NO muestra posición de enemigos, POIs ni nada más

La brújula es suficiente para orientación macro. La exploración detallada se hace con landmarks y memoria.

### 7.3 Señales Naturales de Peligro

El mundo usa señales ambientales para comunicar peligro sin UI:

| Señal | Significado | Ejemplo |
|-------|-------------|---------|
| Fauna que huye | Enemigos cerca (<30 m) | Pájaros que levantan vuelo, ciervos que corren |
| Silencio repentino | Enemigo emboscado o zona de boss | El sonido ambiente se corta |
| Olor de humo / partículas | POI cercano con actividad | Humo de campamento, polvo de ruinas |
| Cambio de iluminación | Transición a zona de mayor dificultad | Sombras más duras, luz más fría |
| Rastros en el suelo | Sendero hacia POI Secreto | Huellas, pasto aplastado, piedras acomodadas |

---

## 8. Distribución de Enemigos: Mundo Abierto vs. POIs

### 8.1 Principio de Distribución

El mundo tiene dos densidades de enemigos:

| Zona | Densidad | Rol |
|------|----------|-----|
| Campo abierto (entre POIs) | Baja-media | Tensión de travesía — el viaje no es seguro |
| Dentro de POI | Alta | Encuentro principal — el POI es donde se combate |
| Radio de influencia de POI | Media | Zona de aviso — el jugador sabe que se acerca a algo |

### 8.2 Cantidades por Piso

**Piso 1 (Pradera) — referencia de balance**:

| Zona | Enemigos totales en el mapa |
|------|-----------------------------|
| Campo abierto (patrullas + encuentros) | 25 – 40 |
| POIs Mayores (suma de todos) | 30 – 60 |
| Radio de influencia de POIs | 15 – 25 |
| Arena del Boss (pre-boss + boss) | 5 – 10 + 1 boss |
| **Total en el mapa** | **75 – 135 enemigos** |

Comparación con v1.x: el piso 1 anterior tenía 3 enemigos en una arena de 20×20m. La v2.0 tiene entre 75 y 135 en un mundo de 600×600m — pero distribuidos, no todos al mismo tiempo en la pantalla.

**Escalado por piso**:

| Piso | Multiplicador de cantidad | Cambio en composición |
|------|--------------------------|----------------------|
| 1 — Pradera | × 1.0 (baseline) | Solo básicos + 1-2 élites en POIs |
| 2 — Bosque | × 1.4 | 20% élites, grupos más compactos |
| 3 — Hielo | × 1.8 | 30% élites, enemigos de rango en cavernas |
| 4 — Tormenta | × 2.2 | 40% élites, patrullas en plataformas |
| 5 — Dimensión | × 2.8 | 50% élites, enemigos con mecánicas especiales |

### 8.3 Encuentros Dentro de POIs

Los POIs tienen encuentros estructurados (no aleatorios — definidos por el tipo de POI):

| Tipo de POI Mayor | Encuentros típicos | Enemigos totales en el POI |
|-------------------|-------------------|-----------------------------|
| Ruinas | 2-3 grupos de 3-5 enemigos, 1 élite | 10-18 |
| Asentamiento (pueblo en ruinas) | 3-4 grupos, distribución en "calles" | 15-25 |
| Feature Natural (lago, peñasco) | 1-2 grupos + 1 élite | 6-12 |
| Dungeon Interno | 3-5 grupos en espacio cerrado, boss de mini-dungeon | 15-30 |

---

## 9. Checklist de Validación — Mundo Abierto

Antes de marcar un piso como "playtest-ready":

### Escala y navegación
- [ ] ¿El mapa tiene al menos 500 × 500 m?
- [ ] ¿Hay al menos 3 landmarks visibles desde el punto de entrada?
- [ ] ¿El jugador puede ver al menos 2 landmarks desde cualquier punto del mapa?
- [ ] ¿El Portal de Entrada y la Arena del Boss están a más de 350 m de distancia?
- [ ] ¿La brújula muestra el objetivo activo correctamente?

### POIs y generación
- [ ] ¿Todos los POIs están a más de 80 m de distancia entre sí (borde a borde)?
- [ ] ¿El boss tiene al menos 80 × 80 m de arena con 100 m de campo libre alrededor?
- [ ] ¿Hay al menos un POI Menor cada 150 m en el eje Entrada→Boss?
- [ ] ¿El Dungeon Interno (si existe) está a más de 150 m del eje principal?
- [ ] ¿La seed produce el mismo mapa reproduciblemente?

### Campo abierto
- [ ] ¿El campo entre POIs tiene al menos 1 elemento de escala (árbol/roca/ruina menor) cada 15-30 m?
- [ ] ¿Las patrullas en el eje principal tienen separación de 80-100 m entre sí?
- [ ] ¿Hay al menos 1 encuentro aleatorio activo cada 200 m de campo abierto?
- [ ] ¿Las patrullas vuelven a su ruta después de perder al jugador?

### Orientación y señales
- [ ] ¿La fauna pasiva reacciona a enemigos cercanos (<30 m)?
- [ ] ¿La transición a la zona de boss tiene señal ambiental (silencio, cambio de luz, partículas)?
- [ ] ¿Los senderos son sugerencias — el jugador puede abandonarlos sin colisión invisible?

### Performance
- [ ] ¿Los enemigos fuera del rango de carga (~100 m del jugador) están en modo sleep/desactivado?
- [ ] ¿Los assets decorativos del campo usan instancing (MultiMeshInstance3D)?
- [ ] ¿Los POIs fuera del campo de visión tienen occlusion culling activo?

---

## 10. Resumen Rápido v2.0 (referencia de bolsillo)

```
ESCALA DE MAPA
  Piso 1 — Pradera    : 600 × 600 m (360.000 m²)
  Piso 2 — Bosque     : 700 × 700 m (490.000 m²)
  Piso 3 — Hielo      : 650 × 500 m (325.000 m²)
  Piso 4 — Tormenta   : 800 × 400 m (320.000 m²)
  Piso 5 — Dimensión  : 700 × 700 m (490.000 m²)

TIEMPO DE CRUCE REAL (con exploración y combate)
  Piso 1-2 : 15 – 30 minutos
  Piso 3-4 : 25 – 45 minutos
  Piso 5   : 40 – 70 minutos

POIs POR RUN
  Ancla (entrada + boss) : siempre 2
  Mayores                : 3-7 (según piso)
  Menores                : 0-5 (seed-dependiente)
  Secretos               : 0-2 (seed-dependiente)

REGLAS DE COLOCACIÓN
  Distancia mínima entre POIs (borde a borde) : 80 m
  Distancia mínima Entrada → Boss             : 350 m
  POI Mayor ↔ borde del mapa                  : 100 m

TAMAÑOS DE POI
  Asentamiento mayor   : 80-120 × 80-120 m
  Ruinas               : 60-80 × 60-80 m
  Arena del Boss       : 80 × 80 m + 100 m radio libre
  Portal de Entrada    : 30 × 30 m + 50 m radio seguro
  POI Menor            : 10-25 × 10-25 m

ENEMIGOS EN EL MAPA (Piso 1 baseline)
  Campo abierto (patrullas) : 25 – 40
  Dentro de POIs            : 30 – 60
  Radio de POIs             : 15 – 25
  Arena del Boss            : 5-10 + 1 boss
  Total                     : 75 – 135

VELOCIDADES JUGADOR
  Normal : 5 m/s
  Sprint : 8 m/s

TIPOLOGÍA POR PISO
  Piso 1 — Pradera    : Abierto simulado — cielo de diamante, campo verde
  Piso 2 — Bosque     : Abierto cerrado — dosel opaco, niebla baja
  Piso 3 — Hielo      : Cavernas masivas — techo de hielo, ríos subterráneos
  Piso 4 — Tormenta   : Archipiélago en el cielo — plataformas masivas conectadas
  Piso 5 — Dimensión  : Geometría imposible — reglas del espacio alteradas
```

---

## 11. Adaptación por Piso — Métricas en Contexto Temático

### 11.1 Tipología: Tipo de Mundo

| Piso | Mundo | Tipo | Cielo/Techo | Estructura dominante |
|------|-------|------|-------------|---------------------|
| 1 | Pradera Interior | **Abierto simulado** | Bóveda de diamante a 30-50 m — luz cálida | Praderas, senderos, ruinas dispersas, pilares de la torre |
| 2 | Bosque / Selva | **Abierto cerrado** | Dosel de árboles opaco a 15-20 m de altura | Árboles masivos, raíces, ríos, vegetación densa |
| 3 | Hielo / Cavernas | **Cavernas masivas** | Techo de hielo a 20-40 m — stalactitas | Cámaras enormes interconectadas, ríos subterráneos, cristales |
| 4 | Tormenta / Cielo | **Archipiélago flotante** | Sin techo — vacío tormentoso | Plataformas masivas (100-300 m de diámetro) con puentes |
| 5 | Dimensión Rota | **Geometría imposible** | Varía — puede haber múltiples "arribas" | Zonas que se doblan sobre sí mismas, portales internos |

### 11.2 Características Ambientales por Piso

| Piso | Luz | Visibilidad de enemigos | Orientación por landmarks | Tensión primaria |
|------|-----|------------------------|--------------------------|-----------------|
| 1 — Pradera | Luz cálida (atardecer), sombras largas | Alta — ves patrullas a 20-30 m | Pilares de la torre + árbol gigante | Travesía expuesta, emboscadas en pasto alto |
| 2 — Bosque | Poca luz, rayos filtrados, niebla baja | Baja — 8-12 m de visibilidad | Troncos de 30m de diámetro, ríos luminosos | Sorpresa constante — el enemigo aparece de la nada |
| 3 — Hielo | Azul fría, rebotes en cristal | Media — 15-20 m pero confusa | Formaciones de cristal únicas, cascadas heladas | Terreno resbaloso + distancias engañosas por reflejos |
| 4 — Tormenta | Relámpagos intermitentes, oscuridad entre rayos | Alta pero fragmentada | Borde de plataforma = caída, relámpagos revelan posición | Peligro ambiental activo + caída al vacío |
| 5 — Dimensión | Imposible — múltiples fuentes sin sentido | Impredecible | Los landmarks pueden moverse entre visitas | Las reglas del espacio se alteran |

### 11.3 Escala de Features Naturales por Piso

| Piso | Landmark principal | Altura visible | Feature natural dominante |
|------|-------------------|---------------|--------------------------|
| 1 — Pradera | Pilares de la torre | 40-80 m | Árbol gigante (25-30 m), río visible |
| 2 — Bosque | Árboles madre | 30-40 m | Río luminoso, claros entre doseles |
| 3 — Hielo | Formaciones de cristal | 20-35 m | Cascadas heladas, cámaras con hielo traslúcido |
| 4 — Tormenta | Plataformas visibles a distancia | 50+ m (se ven flotando) | Bordes de plataforma, puentes colgantes |
| 5 — Dimensión | Estructura imposible (portal permanente) | Variable | Geometría que no cierra, espacio que se dobla |

---

## 12. Piso 1 — Pradera Interior: Diseño de Mundo Detallado

### 12.1 Contexto y Concepto

El Piso 1 es una **pradera interior gigante** — el primer nivel de la torre es un mundo completo encapsulado: bóveda de luz de diamante a 30-50 m de altura, praderas de kilómetros, ruinas de civilizaciones anteriores, pilares descomunales que sostienen el piso superior. No es un dungeon — es un reino.

**Referencia de sensación y escala**:
- SAO — Aincrad Piso 1: campo abierto con una ciudad en el centro, praderas alrededor, el dungeon al fondo. Los jugadores pasaban días explorando.
- Danmachi — Pisos superiores del Dungeon: ecosistemas con flora y fauna propia, cielos simulados, los monstruos son parte del ecosistema.
- Metin2 — Map 1: zona de entrada masiva con múltiples sub-zonas diferenciadas (aldea, bosque, campo), el jugador tarda minutos en atravesarla.
- Valheim — Meadows: bioma de entrada aparentemente calmado, peligroso si se subestima.

### 12.2 Mapa Conceptual del Piso 1

**Dimensiones**: 600 × 600 m  
**Pilar de la Torre**: 4 pilares distribuidos simétricamente (fijos, no seed-dependientes) a +150 m del borde — visibles desde cualquier punto.

**Pool de POIs Mayores (el generador elige 3-5 de esta lista)**:

| POI | Tamaño | Contenido |
|-----|--------|-----------|
| Pueblo en Ruinas | 100 × 80 m | 3-4 grupos de enemigos, 1 élite (capitán de bandidos), cofre garantizado, lore ambiental |
| Arboleda Densa | 80 × 80 m | Zona de pasto alto, 2 emboscadas, cofre oculto en raíces |
| Ruinas del Templo | 70 × 60 m | Estructura imponente, 2-3 grupos, 1 élite con mecánica especial, cofre épico posible |
| Lago Central | 100 × 60 m (irregular) | Sin combate activo dentro del agua — patrullas en los bordes. Loot visible bajo el agua. Cruzar el lago es más lento (0.5× velocidad) |
| Campamento de Bandidos | 60 × 60 m | 3-4 grupos, 1 élite (líder), drop de misión posible |
| Cripta Subterránea | 30 × 40 m entrada + 40 × 60 m interior | Mini-dungeon (techo 3.5 m), 3-4 grupos densos, cofre épico garantizado |

**Pool de POIs Menores (el generador activa 0-3 de esta lista)**:

| POI | Tamaño | Contenido |
|-----|--------|-----------|
| Altar Roto | 15 × 15 m | Ítem de buff temporal, sin combate |
| Campamento Abandonado | 20 × 20 m | Cuerpo de aventurero con ítem, 1 enemigo solitario |
| Pozo Seco | 10 × 10 m | Loot menor + lore inscrito |
| Carro Caído | 10 × 15 m | Loot menor, posible trampa |

**POI Secreto (0-1 activo por run)**:

| POI | Ubicación | Contenido |
|-----|-----------|-----------|
| Cueva del Guardián | Fuera del eje principal, entrada semi-oculta | Mini-boss + cofre legendario posible |
| Tumba del Explorador | Campo abierto, >80 m de cualquier sendero | Cuerpo con ítem épico garantizado |

### 12.3 Flujo No Lineal

A diferencia del flujo lineal de v1.x, el Piso 1 v2.0 no tiene un orden obligatorio. El jugador elige su ruta.

**Eje principal sugerido** (camino más directo al boss):
```
[Portal de Entrada] → [Campo abierto con patrullas] → [POI Mayor aleatorio] → 
[Más campo abierto] → [POI Mayor aleatorio] → [Campo abierto + patrullas] → [Arena del Boss]
```

**Exploración lateral** (maximiza loot y XP):
```
[Portal de Entrada] → [Todos los POIs Mayores] → [POIs Menores] → [POI Secreto] → 
[Arena del Boss]
```

El jugador nunca sabe exactamente qué POIs hay en el run hasta que los encuentra. El mapa se revela explorando.

### 12.4 El Campo Abierto de la Pradera — Qué Hay Entre POIs

No es pasto vacío. Cada 15-30 m hay algo que hace el mundo habitado:

| Elemento | Frecuencia | Propósito |
|----------|-----------|-----------|
| Árbol aislado (5-8 m) | Cada 20-30 m | Escala, orientación, cobertura en combate |
| Roca grande (1.5-2.5 m) | Cada 25-40 m | Cobertura, posible loot al lado |
| Pasto alto (1-1.5 m) | Zonas de 20-40 m de diámetro | Zona de emboscada potencial |
| Ruina menor (pedestal, muro caído) | Cada 80-120 m | Historia ambiental, separación visual de zonas |
| Cerca de piedra rota | Tramos de 10-30 m | Canal natural de movimiento, sensación de civilización anterior |
| Mariposas luminosas / fauna pasiva | Clusters de 3-5 | Inmersión + señal: huyen si hay enemigos cerca |
| Humo de ruina | Columnas visibles a 100+ m | Señal de POI cercano |

### 12.5 Ambiente y Mood del Piso 1

**Luz**: DirectionalLight3D, ángulo bajo (15-25°), color naranja (#FF9040), sombras activadas. Simula atardecer permanente.

**Por qué atardecer**:
1. Luz lateral larga → el terreno tiene volumen, los accidentes se leen bien
2. Cálido pero no festivo — hay belleza y hay peligro
3. Contrasta con Piso 2 (verde oscuro) y Piso 3 (azul frío) — la progresión de color es narrativa

**Techo de diamante**: geometría a 30-50 m de altura, material con emisión propia + refracción de la luz direccional. Partículas sutiles de destellos. Siempre visible, nunca protagonista.

### 12.6 Checklist de Validación — Piso 1

Adicional al checklist genérico (sección 9):

- [ ] ¿El mapa tiene exactamente 600 × 600 m?
- [ ] ¿Hay 4 pilares de la torre en posiciones fijas (no seed-dependientes)?
- [ ] ¿Los pilares son visibles desde el Portal de Entrada y desde la Arena del Boss?
- [ ] ¿El Portal de Entrada y la Arena del Boss están a más de 350 m de distancia?
- [ ] ¿El generador colocó entre 3 y 5 POIs Mayores del pool?
- [ ] ¿Todos los POIs tienen al menos 80 m de campo libre entre ellos (borde a borde)?
- [ ] ¿El campo abierto tiene al menos 1 árbol o roca cada 30 m en promedio?
- [ ] ¿Hay zonas de pasto alto claramente visibles (y diferenciables visualmente) antes de que el jugador entre?
- [ ] ¿La fauna pasiva reacciona a enemigos cercanos (<30 m)?
- [ ] ¿El lago (si aparece en el run) ralentiza el movimiento a 0.5× velocidad?
- [ ] ¿La Arena del Boss tiene bordes naturales claros (muralla caída, acantilado, ríos)?
- [ ] ¿La seed es visible en la pantalla de carga y reproducible?
- [ ] ¿Los enemigos fuera de 100 m del jugador están en modo inactivo?
