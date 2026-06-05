# World Coherence — Reglas de Coherencia de Mundo

**Versión**: 1.0
**Fecha**: 2026-06-05
**Estado**: CANON de coherencia auto-aplicable. Reglas que Claude consulta al construir **cualquier** mapa de Dungeon Party para que el estilo se genere solo, sin pedir feel a Joan caso por caso.
**Audiencia**: principalmente Claude (placement, spawn, escala procedural). Secundario: Art, Gameplay, Design.
**Depende de**: `_art_canon.md` v2.0 (jerarquía visual, atmósferas, lighting por piso), `_world_canon.md` v2.0 (tono, naming, biomas), `balance_v2.md` (escalado enemigos vigente).
**Implementado en (referencia viva)**: `game/scenes/levels/floor1_prairie.gd` — este doc formaliza lo que ese script ya hace bien y llena los huecos.

> **Filtro scope reset 2026-05-18**: este doc NO es canon expansion. No afirma lore nuevo. Solo define **cómo se acomodan los assets que ya existen** para que el mundo se lea coherente. Si una regla no cambia lo que la cámara graba, no está acá.

---

## §0. Cómo usar este doc (protocolo para Claude)

Cuando se te pida construir, poblar o ajustar un mapa:

1. **Leé §1 (escala) primero** — es el ancla. Todo lo demás cuelga de la proporción real.
2. **Identificá el bioma** y su atmósfera canon (`_art_canon.md` §4). Eso fija paleta + lighting (§8 acá).
3. **Aplicá las reglas en orden de dependencia**: geología (§7) → hidrología (§2) → vegetación (§3) → spawns (§4) → transiciones (§5) → densidad (§6) → luz (§8).
4. **Cada regla es un SI/ENTONCES con números reales del proyecto.** No inventes valores nuevos; usá los de las tablas. Si falta un número, usá el de P1 como base y dejalo anotado en `open_questions`, no lo inventes como canon.
5. **Cuando dudes entre "lindo" y "coherente", gana coherente.** La belleza del mapa sale de que las cosas estén donde la física las pondría (Joan: "esto sale en el video de 10 min").

**Eje rector del alfa** (de `_world_seeds_postalpha.md`, fase descubrimiento): el Piso 1 es el **ancla de familiaridad** — físicas reales, proporciones reales, lógica conocida. Todo lo raro/surreal viene en pisos profundos. Estas reglas asumen mundo familiar por default; el gradiente de realidad (§9) dice cuándo y cuánto romperlas.

---

## §1. Proporciones reales — el ancla (REGLA MAESTRA)

Todo se mide contra el jugador. Si la escala se rompe, ninguna otra regla salva el mapa.

| Entidad | Altura real | Múltiplo del player | Fuente |
|---|---|---|---|
| **Player** | **1.8 m** | 1× (ANCLA) | cápsula CharacterBody3D |
| Arbusto / matorral | 0.5–1.5 m | 0.3–0.8× | pool bushes |
| Árbol joven | ~4.5 m | ~2.5× | sesgo de edad bajo |
| Árbol maduro (mayoría) | 5.4–9 m | **3–5×** | birch 5.45 / maple 6.64 / common 7.26 m nativo |
| Árbol patriarca (añoso) | ~11 m | ~6× | tope del sesgo de edad |
| Roca chica / pebble | 0.3–1 m | 0.2–0.6× | pool rocks |
| Roca grande / acantilado | 2–8 m | 1–4× | scatter rocks scale up a 2.9 |
| Pilar landmark | 30–50 m | 17–28× | `PILLAR_MIN/MAX_HEIGHT` |
| Árbol gigante (POI) | ~28 m (trunk 20 + canopy) | ~15× | `_build_giant_tree` |
| Cristales del techo | 32–42 m | colgados, no escala player | `CRYSTAL_MIN/MAX_HEIGHT` |
| Techo de caverna | 45 m | 25× | `CEILING_HEIGHT` |

### §1.1 Reglas de escala (auto-aplicables)

- **REGLA E1 — Escala nativa de árboles**: los gltf de árbol ya vienen a proporción real (~5.4–7.3 m). El factor de escala en placement es **0.8–1.7**, NUNCA fijo en 1.0. Eso produce la convivencia jóvenes/medianos/patriarcas.
- **REGLA E2 — Sesgo de edad, no uniforme**: la distribución de escala es ~45% jóvenes (extremo bajo del rango), ~35% medianos, ~20% añosos (extremo alto). Implementado en `_age_scale()`. **Nunca uses `randf_range` plano para escala de vegetación** — se ve artificial.
- **REGLA E3 — Rotación Y siempre random**: toda instancia rota `randf() * TAU` en Y. Cero clones idénticos alineados.
- **REGLA E4 — El player debe poder leer la escala de un vistazo**: si un asset rompe la proporción (un arbusto de 4 m, una roca del tamaño de una casa sin razón geológica), es bug de dirección. Verificá contra esta tabla.

```gdscript
# Patrón canon de instanciado (de _place_instance + _age_scale)
var s: float = _age_scale(scale_min, scale_max)   # sesgo edad, no uniforme
var rot_y: float = _rng.randf() * TAU
inst.transform = Transform3D(Basis(Vector3.UP, rot_y).scaled(Vector3(s, s, s)), pos)
```

---

## §2. Hidrología — el agua manda sobre todo lo demás

El agua define dónde hay vida. Es la primera capa después de la geología. **Reglas físicas, no decorativas.**

### §2.1 Reglas de agua (SI/ENTONCES)

- **REGLA H1 — El agua va en depresiones**: lagos, estanques y charcos se colocan SOLO en el terreno bajo (altura `< 0.3 × TERRAIN_MAX_HEIGHT`, o sea `< ~2.7 m` en P1). Nunca un lago en una colina o un acantilado. Consultá `get_terrain_height()` antes de colocar agua.
- **REGLA H2 — Fluye de alto a bajo**: si hay un río o arroyo, su trazado va SIEMPRE descendiendo. Un río necesita **fuente aguas arriba** (manantial en zona alta, deshielo, base de acantilado) y **destino** (lago, salida del mapa, sumidero). Un río que nace y muere en plano = bug.
- **REGLA H3 — Caudal coherente**: el ancho del agua crece aguas abajo, no al revés. Arroyo angosto arriba → más ancho al juntarse con otros → lago en la depresión final.
- **REGLA H4 — El pozo/well solo donde hay napa creíble**: un pozo (`well` POI) vive en zona baja-media cerca de asentamiento, no en la cima de una colina.

### §2.2 Halo de humedad (el agua irradia vida)

- **REGLA H5 — Anillo húmedo**: TODO cuerpo de agua genera un anillo de mayor densidad vegetal a su alrededor. Radio del halo ≈ **1.5× a 3× el radio del agua**.
  - Anillo 0–1× radio agua: juncos, flores, hongos (ground pool), densidad ALTA.
  - Anillo 1×–2.5×: arbustos + árboles que bordean, densidad MEDIA-ALTA.
  - Más allá de 2.5×: densidad normal del campo.
- Implementado para `pond` en `_generate_vegetation`: anillo de árboles `r+2..r+12`, ground `r-1..r+6`, bushes `r+1..r+8`, + halo de árboles ralos `r+12..r+32` que deshilacha hacia el campo (ver §5).

```gdscript
# Patrón canon halo de humedad (de la rama "pond")
_scatter_cluster(POOL_TREES,  16, c, r + 2.0, r + 12.0, 0.85, 1.6, container)  # borde frondoso
_scatter_cluster(POOL_GROUND, 24, c, r - 1.0, r + 6.0,  0.7,  1.6, container)  # juncos/flores al ras
_scatter_cluster(POOL_BUSHES,  8, c, r + 1.0, r + 8.0,  0.6,  1.6, container)
_scatter_cluster(POOL_TREES,  12, c, r + 12.0, r + 32.0, 0.7, 1.15, container) # halo deshilachado
```

---

## §3. Vegetación por humedad y luz

La vegetación NO es scatter uniforme. Cada planta tiene un nicho. **El "dónde" lo decide humedad + luz + altura.**

### §3.1 Tabla de nichos (auto-aplicable)

| Tipo planta | Humedad | Luz | Altura terreno | Pool / asset |
|---|---|---|---|---|
| Hongos | ALTA (cerca agua, sombra) | BAJA (sombrío) | baja | `mushroom`, `clover` |
| Juncos / flores densas | ALTA | media-alta | baja (orilla) | `flowers`, `clover` |
| Arbustos floridos | media-alta | alta | baja-media | `bush_flowers` |
| Árboles frondosos (birch/maple/common) | media | media-alta | baja-media | `POOL_TREES` vivos |
| Pasto / clover disperso | media | alta | media | `grass`, `clover` |
| Arbustos secos / matorral ralo | baja | alta | media-alta | `bush` chico |
| Árbol muerto (`dead`) | baja | cualquiera | alta/rocosa | `env_tree_dead_01` |
| Vegetación rala / nula | muy baja | dura | alta/seca/rocosa | (casi vacío) |

### §3.2 Reglas de vegetación (SI/ENTONCES)

- **REGLA V1 — Hongos solo en húmedo y sombrío**: colocá `mushroom`/`clover` cerca del agua, bajo dosel denso (giant_tree, bosque), o a la sombra norte de rocas grandes. NUNCA hongos en campo abierto soleado y seco.
- **REGLA V2 — Más vida cerca del agua, menos en lo alto**: la densidad de vegetación es función inversa de la altura del terreno y directa de la cercanía al agua. Zona alta/seca/rocosa (`altura > 0.75 × TERRAIN_MAX_HEIGHT`) → vegetación RALA, predominan rocas y algún árbol muerto.
- **REGLA V3 — Árboles muertos marcan tierra pobre**: el `dead` tree va en lo alto, seco o pedregoso. Es señal ambiental de "acá no llega el agua". Nunca un árbol muerto al lado de un estanque.
- **REGLA V4 — Sotobosque coherente**: bajo árboles densos va sotobosque de sombra (hongos, arbustos chicos, clover), no pasto de sol pleno.
- **REGLA V5 — Las flores marcan el claro y la orilla**: clumps de flores densas en bordes de agua y claros soleados (entrance grove), no en sombra profunda.

### §3.3 Proporción de pools por bioma (densidad relativa)

Base P1 (de las llamadas `_scatter_pool` actuales, tejido conectivo del campo abierto):

| Pool | Cantidad base P1 | Nota |
|---|---|---|
| Árboles | `TREE_COUNT * 0.7` (~140) | dominante en pradera |
| Rocas | `ROCK_COUNT * 0.45` (~54) | medio |
| Arbustos | `ROCK_COUNT * 0.4` (~48) | medio |
| Ground (flores/hongos) | `TALL_GRASS_COUNT * 0.7` (~56) | sotobosque/orilla |

> Para otros biomas, ajustá la mezcla según atmósfera: bosque sube árboles+hongos, hielo baja todo menos rocas, tormenta casi sin vegetación viva.

---

## §4. Spawns por nicho ecológico (bestiario endémico — criterio de curaduría)

Principio (de `_world_seeds_postalpha.md` #2, forma alpha-safe): **los monstruos PERTENECEN a su ambiente**. Esto cambia el *dónde* del spawn, no agrega un sistema adaptativo (eso es post-alfa). Inspiración: "El bestiario de Axlin" (Laura Gallego) + Tensura (variedad con carácter).

### §4.1 Tabla de nichos de spawn (auto-aplicable, P1)

| Criatura | Nicho (dónde pertenece) | Lógica ecológica | Implementación |
|---|---|---|---|
| Slimes | junto al **agua** (pond) + cristales | comen la bioluminiscencia de los cristales | `_pos_near_poi_type(pois, "pond", ...)` 50% del tiempo |
| Lobos | **bosque denso** (giant_tree) | cazan desde la cobertura, no en campo abierto | `_pos_near_poi_type(pois, "giant_tree", ...)` |
| Aves / pájaros | cerca de **pilares** y altura | anidan/posan en lo alto, vuelan sobre claros | spawn + offset Y `+3..+5 m` |
| Halcones | vuelo **alto** sobre campo abierto | depredador aéreo | offset Y `+5 m` |
| Avispas | **nidos** agrupados (4–8) | colonia, no individuos sueltos | packs cerca de un centro, offset Y `1.5–2.5 m` |
| Cabras | **colinas** (terreno alto-medio) | pastan en pendientes | packs lejos de POIs |
| Tortugas | cerca del **agua**, lentas | anfibias | sueltas, dist mínima de POI |
| Serpientes / ratas | **escondidas** (ruinas, maleza) | emboscada, refugio | sueltas / packs en ruins |
| Escorpiones | zona **seca/rocosa** | nicho árido | packs dispersos |
| King Slime (boss de zona) | **arena del boss**, gate oeste | culminación ecológica: "el que comió demasiada bioluminiscencia" | `BossSpawnTrigger` Area3D |

### §4.2 Reglas de spawn (SI/ENTONCES)

- **REGLA S1 — Spawn por pertenencia primero, scatter después**: intentá colocar cada criatura en su nicho (`_pos_near_poi_type`). Solo si no hay POI de ese tipo, caés a `_random_open_pos`. Patrón canon:

```gdscript
var center: Vector3 = _pos_near_poi_type(_pois, "pond", 10.0)   # nicho preferido
if center == Vector3.INF:
    center = _random_open_pos(_pois, 20.0)                       # fallback campo
if center == Vector3.INF:
    continue
```

- **REGLA S2 — Packs, no individuos sueltos** (salvo solitarios reales): slimes 1–5, lobos alfa+1–3, avispas nido 4–8, cabras 3–5. Los depredadores solitarios (serpiente, halcón) sí van sueltos.
- **REGLA S3 — Los voladores mantienen su Y**: pájaros/halcones/avispas no se pegan al suelo en `_snap_all_to_terrain` (preservan offset > 2.5 m). Toda criatura terrestre se snapea a `terrain_y + 1.0`.
- **REGLA S4 — El boss de zona es la culminación del bioma**, no un bicho random fuerte. Su framing sale del nicho dominante del piso (slimes → King Slime). Ver `_world_seeds_postalpha.md` modelo macro.
- **REGLA S5 — Escalado de stats**: HP/daño/DEF de enemigos salen de `balance_v2.md` (modelo 1–100 compound VIGENTE), NO de la tabla lineal vieja del GDD/CLAUDE.md (HP 100–700, DEPRECATED). Nunca hardcodees stats en el spawn.

---

## §5. Transiciones ecológicas entre biomas (deshilachar, no cortar)

Joan: los biomas se **deshilachan**, no se cortan en seco. Un borde duro entre pradera y bosque grita "videojuego". La naturaleza mezcla en una franja.

### §5.1 Reglas de transición (SI/ENTONCES)

- **REGLA T1 — Halo de deshilachado en cada cluster**: todo mini-bioma anclado a un POI tiene un **anillo exterior ralo** con escala menor y densidad decreciente que lo cose al campo. Implementado como segundo `_scatter_cluster` con escala `0.7..1.15/1.2` en radios `r+12..r+48`.
- **REGLA T2 — Gradiente, no escalón**: entre dos biomas, la densidad del A baja linealmente mientras la del B sube, solapándose en una franja de **20–40 m**. Nunca un metro de pradera y al siguiente bosque cerrado.
- **REGLA T3 — Especies puente**: en la franja de transición aparecen especies de ambos lados + las "generalistas" (arbustos, rocas, pasto) que viven en cualquier borde.
- **REGLA T4 — Tejido conectivo del campo**: el espacio muerto entre POIs se llena con scatter ralo (`_scatter_pool` evitando POIs) para que el mapa se lea continuo, no como islas. Densidad ~70% de la base.

```gdscript
# Patrón canon deshilachado (halo exterior de un cluster)
_scatter_cluster(POOL_TREES, 30, c, r * 0.4, r + 16.0, 0.85, 1.7, container)  # núcleo denso
_scatter_cluster(POOL_TREES, 22, c, r + 16.0, r + 48.0, 0.7, 1.2, container)  # halo que se deshilacha
```

---

## §6. Densidad y distribución

- **REGLA D1 — Densidad por atmósfera** (cruzar con `_art_canon.md` §5.1 "shape language"):

| Atmósfera / zona | Densidad visual | Referencia |
|---|---|---|
| Bosque denso / dosel | ALTA | giant_tree núcleo |
| Pradera media | MEDIA | campo abierto P1 |
| Claro / entrada | BAJA (apertura = asombro) | entrance grove |
| Orilla de agua | ALTA (halo húmedo §2.2) | pond |
| Zona alta/seca/rocosa | BAJA, predomina roca | acantilados §7 |

- **REGLA D2 — Distribución por anillos, no grilla**: el placement usa `angle = randf()*TAU` + `dist = randf_range(inner, outer)`. Nunca filas/columnas regulares (lee artificial). Excepción: estructuras humanas (cercas, empalizadas, caminos) que SÍ son geométricas.
- **REGLA D3 — Respetar el claro de la entrada**: la zona de spawn del player (radio ~50 m, terreno aplanado en `_compute_height_at`) queda abierta. Pocos árboles enmarcando, nada de bosque encima del player al aparecer.
- **REGLA D4 — Anti-solapamiento**: clusters no se montan unos sobre otros (chequeo de distancia mínima, ver monarcas de cristal `< 30 m`). Vegetación no spawnea dentro del footprint de un POI (`min_poi_dist`).
- **REGLA D5 — Variedad dentro del pool**: cada placement elige asset random del pool (`pool[randi() % size]`). Nunca un solo modelo repetido en toda una zona.

---

## §7. Geología — el relieve manda primero

La forma del terreno se calcula ANTES que cualquier asset. Todo lo demás (agua, vegetación, spawns) consulta `get_terrain_height()`. Geología = capa 0.

### §7.1 Reglas geológicas (SI/ENTONCES) — números reales P1

- **REGLA G1 — Relieve por noise, no plano**: el terreno es un heightmap (`FastNoiseLite` Perlin, freq `0.004` = colinas grandes suaves, octaves 3). Altura máxima `9 m`. **Nunca un piso plano** salvo arenas instanced (boss).
- **REGLA G2 — Centro aplanado para la entrada**: radio `50 m` desde el centro se aplana con `smoothstep` para que el spawn sea jugable. Toda zona de combate/entrada importante necesita su flatten local.
- **REGLA G3 — Acantilados hacia el borde**: a partir de `t > 0.7` (70% del radio hacia afuera) el terreno SUBE cuadráticamente (`TERRAIN_EDGE_RISE = 6 m`). Los bordes son naturalmente altos y rocosos → frontera diegética (`_world_seeds_postalpha.md` #5), no muro arbitrario.
- **REGLA G4 — Rocas en lo alto y seco**: las rocas grandes y los acantilados van en terreno alto (`altura > 0.75 × max`). El cúmulo rocoso del boss (`POOL_ROCKS` scale hasta 2.9) modela un acantilado natural rodeando la arena.
- **REGLA G5 — Color del terreno por altura** (ya implementado en `_height_to_color`): bajo = verde-oliva pradera, medio = oliva claro, alto = tierra/roca. **Verdes DESATURADOS** a propósito (respeta jerarquía Kimetsu: el bioma no compite con el color saturado de las skills). Nunca verde chillón saturado en el suelo.
- **REGLA G6 — La pendiente condiciona qué crece**: pendiente suave → vegetación normal; pendiente fuerte/acantilado → rocas + algún árbol aferrado/muerto, casi sin sotobosque.

```gdscript
# Decisión canon de altura (de _compute_height_at): noise + flatten centro + edge rise
var h: float = noise01 * TERRAIN_MAX_HEIGHT          # colinas
if dist_center < 50.0:                                # entrada jugable
    h = lerpf(0.0, h, smoothstep(0.0, 1.0, dist_center / 50.0))
if t > 0.7:                                           # acantilados al borde
    var edge_t := (t - 0.7) / 0.3
    h += TERRAIN_EDGE_RISE * edge_t * edge_t
```

---

## §8. Coherencia de luz por bioma

La luz cuenta dónde estás sin tutorial. Cada bioma tiene UNA receta de lighting canon en `_art_canon.md` §5 — **acá NO se duplica, se referencia + se dan las reglas de coherencia**.

### §8.1 Reglas de luz (SI/ENTONCES)

- **REGLA L1 — Fuente de luz diegética y única por bioma**: toda luz tiene un origen creíble en el mundo. P1 = **diamante/cristales del techo de la caverna** (NO sol exterior — P1 es caverna mineral, decisión Joan 2026-06-05, ver §10). Bosque = luz filtrada por dosel. Cada piso "fabrica su propio cielo".
- **REGLA L2 — Sombras coherentes con la fuente**: la dirección de las sombras apunta lejos de la fuente. Si la luz viene del techo (picado), las sombras son cortas y bajo los objetos. No metas sol lateral si la fuente es cenital.
- **REGLA L3 — Ambient para que NO se sienta mazmorra**: P1 usa `CrystalAmbient` (OmniLight rango 350 m, energy 0.25, color azul-lavanda frío) + emisión propia del techo. Sin esto, sin GI, Godot deja el techo negro. Toda caverna necesita ambient + emisión propia en superficies grandes que no reciben luz directa.
- **REGLA L4 — Contraste Kimetsu (canon `_art_canon.md` §2.4)**: el bioma de fondo va **desaturado / cálido en luminancia, no en saturación**. Las skills explotan en color saturado = hero asset. El mapa NUNCA debe competir en saturación con un cast. Subí calidez con luz (golden-hour), no subiendo el saturation del ambiente.
- **REGLA L5 — Contraste de color por temperatura de fuente**: fuentes cálidas (fogata naranja `1.0,0.6,0.2`) contra fríos del ambiente (cristal azul) crean profundidad y guían la mirada. Toda zona "segura" (camp, entrada) lleva una fuente cálida puntual.
- **REGLA L6 — Lighting escala con profundidad** (`_art_canon.md` §2.4): pisos 1–20 fondo colorido, 40–60 fondo gris, 80+ fondo negro neón. P1 = festivo/acogedor. No oscurezcas P1.
- **REGLA L7 — Emisión, no luces, para masa luminosa**: cristales y bioluminiscencia usan MultiMesh con material emisivo (`emission_energy` ~1.0–1.2), con luces reales OmniLight SOLO cada N clusters (`CRYSTAL_LIGHTS_EVERY = 3`). Regla de performance: pocas luces de rango grande > muchas luces chicas (escala mejor a 1–6 jugadores).

### §8.2 Receta de luz por bioma (puntero a canon)

| Piso / bioma | Atmósfera | Fuente diegética | Params completos |
|---|---|---|---|
| P1 Pradera (caverna) | Acogedor | Diamante + vía láctea de cristales (techo 45 m) | `_art_canon.md` §5.2 |
| P2 Bosque | Misterioso | Sol filtrado por dosel + hongos biolum | `_art_canon.md` §5.3 |
| P3 Hielo/Ruinas | Misterioso/Hostil | God rays duros entre columnas | `_art_canon.md` §5.4 |
| P4 Tormenta/Paso | Hostil | Sol ocluido + flashes de rayo | `_art_canon.md` §5.5 |
| P5 Dim. Rota | Surreal | Sin fuente identificable (procedural) | `_art_canon.md` §5.6 |

---

## §9. Gradiente de realidad — cuándo romper estas reglas

(De `_world_seeds_postalpha.md`: el descenso tiene un eje "lo normal → lo surreal".)

- **REGLA GR1 — Pisos bajos = reglas DURAS**: P1 obedece TODO lo de arriba sin excepción. Físicas reales, proporciones reales, hidrología real. Es el ancla de familiaridad.
- **REGLA GR2 — Profundidad relaja las reglas**: a más profundo, más se permite romper. P3 ya puede tener escalas titánicas (Jötunheim), P4 gravedad de tormenta, P5 (`Umbral Fragmentado`) puede violar CUALQUIER regla de este doc (gravedad invertida, agua que sube, proporciones imposibles, luz sin fuente).
- **REGLA GR3 — Romper con intención, no por accidente**: en pisos profundos, cada ruptura es legible como "esto está mal a propósito" (toon outline invierte a glow en P5, `_art_canon.md` §8). Una proporción rota en P1 es bug; en P5 es diseño.
- **Alfa**: solo P1 se entrega. Aplicá GR1 a rajatabla. Lo demás es brújula post-alfa.

---

## §10. Conflictos canon estacionados (NO resolver afirmativo)

- **Erindar vs caverna mineral**: `_world_canon.md` v2.0 nombra P1 "Valle de Erindar" (celta, exterior, megalitos, bruma verde). El código hace **caverna-cristal**. **Decisión Joan 2026-06-05: se mantiene la caverna**, no nos atamos a Erindar. Reconciliación posible (si algún día se decide): caverna + toques celtas bajo el domo (megalitos, círculos de piedra con musgo, bruma verde). **No tomar esta decisión dentro de un doc de feel.** Estacionado.
- **Doble canon de escalado de enemigos**: la tabla lineal HP 100–700 (CLAUDE.md + GDD) está OBSOLETA; vigente es el modelo compound 1–100 de `balance_v2.md`. Las reglas de spawn (§4) referencian SIEMPRE `balance_v2.md`.
- **World-state colectivo / civilización / jefe de Rango**: post-alfa, toca netcode (consultar `netcode-architect`). No entra en reglas de placement del alfa.

---

## §11. Checklist de auto-verificación (correr mentalmente antes de dar por hecho un mapa)

1. ¿Cada asset respeta la proporción del player 1.8 m? (§1)
2. ¿El agua está en depresiones y fluye alto→bajo con fuente? (§2)
3. ¿Hay más vida cerca del agua y menos en lo alto/seco? (§2.2, §3)
4. ¿Los hongos están en húmedo/sombrío y los árboles muertos en lo seco? (§3)
5. ¿Cada criatura spawnea en su nicho antes de caer a scatter? (§4)
6. ¿Los bordes entre biomas se deshilachan en 20–40 m? (§5)
7. ¿La densidad sigue la atmósfera (claro abierto, bosque denso)? (§6)
8. ¿El relieve se calculó primero y todo consulta `get_terrain_height`? (§7)
9. ¿La luz tiene fuente diegética única y el fondo está desaturado (Kimetsu)? (§8)
10. ¿Estoy en P1? → reglas duras. ¿Piso profundo? → gradiente de realidad. (§9)

Si alguna respuesta es "no" sin razón de diseño explícita, es bug de coherencia. Corregir antes de grabar.

---

*World Coherence v1.0 — 2026-06-05. Formaliza lo que `floor1_prairie.gd` ya hace bien y llena los huecos pedidos por Joan (hidrología, vegetación por humedad/luz, geología, luz por bioma). Reglas auto-aplicables con números reales del proyecto. No es canon expansion: acomoda assets existentes, no afirma lore nuevo.*
