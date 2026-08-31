# terrain_valley

**Joan dijo (2026-07-29):** "ahora es un valle hacia el centro que esta en caida, le habia dicho ya
que eso debia ser un terreno irregular, subidas, bajadas, quebradas pequeñas, monticulos, piedras,
rocas, arboles pequeños, grandes, maleza creciendo, flores de diferentes tamaños y
concentraciones/densidades"

**Corrección del mismo día:** "no quiero un valle que en centro sea bajo, quiero que sea un valle,
normal" → el objetivo es un **valle LINEAL con eje**, NO un cuenco radial. El agua corre A LO LARGO
del eje y sale del mapa; no se estanca en un punto central.

- **Idea**: un valle normal — dos laderas que caen hacia un fondo que corre a lo largo de un eje,
  con pendiente longitudinal suave. Terreno irregular a escala de paso humano: subidas, bajadas,
  quebradas, montículos, piedras y vegetación en densidades desiguales.
- **Colores**: verde vivo en el fondo húmedo y en la ladera norte (umbría); pasto seco/pajizo en la
  ladera sur (solana); gris-piedra donde la pendiente supera el ángulo que el pasto aguanta.
- **Forma**: sección transversal en V suave (exponente ~1.3), fondo plano de 100-140 m, laderas
  asimétricas, quebradas perpendiculares al eje que bajan la ladera y entran al canal principal en
  ángulo agudo apuntando aguas abajo.
- **Movimiento/Feel**: el eje da una dirección natural de marcha (entrada → jefe). Las laderas
  cierran el horizonte lateralmente y hacen que el mapa se lea como un lugar, no como un disco.
- **Qué capturar**: que el suelo NUNCA sea plano bajo los pies, y que la irregularidad sea
  jerárquica — grandes formas del heightfield, formas medianas de quebradas/montículos, y detalle
  fino de geometría colocada (no del heightfield).
- **Fuente**: Wikimedia Commons, 14 fotos (licencias en `_sources.json`, todas CC BY-SA / PD).

**Precedente que hay que honrar**: `game/docs/_prairie_environment_rework.md` (2026-07-18, resuelto
2026-07-20) YA registró este pedido y su resolución — "reshape the WHOLE ring into an irregular,
non-climbable MOUNTAIN SLOPE" — y **nunca se implementó**. Ese es el "le había dicho ya". El
diagnóstico de ese doc (líneas 62-64) sigue siendo exacto: *"the only large-scale vertical feature
in the geometry is a uniform depression."*

---

## Las imágenes — qué muestra cada una

| File | Qué muestra | Para qué la usamos |
|---|---|---|
| `valley_u_shaped_trough.jpg` | Coire Gabhail, Glencoe. Fondo de valle casi plano, laderas empinadas a ambos lados, bloques de roca sueltos sobre el pasto del fondo | **La referencia madre.** Es literalmente el objetivo: eje lineal, fondo caminable, flancos que cierran el horizonte |
| `valley_v_shaped_fluvial.jpg` | Valle en V con río corriendo por el eje, laderas secas escalonadas | Sección en V + agua a lo largo del eje (no estancada) |
| `scree_talus_slope.jpg` | Ladera verde con afloramientos de roca gris rompiendo el pasto en la parte alta | **El umbral pasto→roca.** Se ve exactamente dónde el pasto deja de agarrar |
| `valley_dale_grass_flanks.jpg` | Ladera de pasto seco con arbustos dispersos, matorral en el pie | Vegetación rala en solana; densidad desigual |
| `valley_green_pasture_flanks.jpg` | Valle verde cerrado con laderas boscosas | Cierre lateral del horizonte |
| `terracettes_hillslope.jpg` | Ladera verde con terracillas horizontales (pisadas de ganado) | Micro-escalonado — sub-métrico, NO va en el heightfield |
| `gully_erosion_grassland.jpg` | Quebrada real cortada en suelo vegetado, paredes rojizas expuestas | Perfil de quebrada; suelo expuesto en las paredes, verde arriba |
| `erosion_rill_network_badland.jpg` | Red densa de surcos de erosión en ladera | **El patrón de ramificación** del drenaje — cómo se organizan las quebradas |
| `hummocky_moraine.jpg` | Terreno de montículos suaves con quitamiedos dando escala | Montículos: tamaño y espaciado reales |
| `hummock_tussock_moor.jpg` | Pradera de matas irregulares, superficie nunca lisa | Rugosidad de superficie a escala de paso |
| `rock_outcrop_grass_slope.jpg` | Ladera de pastoreo con afloramientos rocosos y aliaga | Roca emergiendo del pasto, no apoyada encima |
| `valley_axis_water_aerial.jpg` | Aéreo: cuerpo de agua alargado siguiendo un eje de valle | Agua ALINEADA al eje |
| `drainage_network_aerial.jpg` | Aéreo: red de drenaje dendrítica | Ángulos de confluencia de tributarios |
| `valley_network_aerial.jpg` | Aéreo: valles ramificados en relieve | Jerarquía de valles principal/tributario |

**Referencias cruzadas ya en el repo** (cargar también, no duplicar):
`_references/biome_landscape/` (fotos de pradera de Joan: verde saturado + derivas de flores),
`_references/rocks/` (bloques de granito), `_references/prairie_rivers/` (arroyos con bolones).

---

## Reglas con números — implementables por el generador

Todos los valores son para el mapa de 600×600 m. Fuentes en la sección final.

### 1. Eje del valle

| Parámetro | Valor | Razón |
|---|---|---|
| Orientación | **Oeste → Este** | La entrada YA se coloca en el borde oeste y el jefe en el este (`poi_system.gd:59-63, 44, 88`). El eje ya existe en el layout; sólo falta que el terreno lo diga |
| Caída longitudinal | **12 m sobre 600 m = 2.0% (1.15°)** | Entre el rango de tramo aluvial bajo (<0.5%) y cabecera (10-35%). 0.5% no se lee; 2% se lee y es trivialmente caminable |
| Perfil longitudinal | Cóncavo hacia arriba, `S = ks·A^-θ`, **θ ≈ 0.45** | Forma estándar de perfil fluvial (θ típico 0.3-0.6) |
| Sinuosidad del eje | **1.05-1.10** — una S suave, amplitud lateral ±35 m | Un eje perfectamente recto se lee artificial |
| Sinuosidad del canal dentro del fondo | **λ ≈ 82 m** (λ = 10.23 × ancho de canal; canal = 8 m) | Relación empírica sobre 438 sitios. Dos escalas anidadas: el fondo curva a ~600 m, el arroyo serpentea a ~82 m |

### 2. Sección transversal

| Parámetro | Valor | Razón |
|---|---|---|
| Caída borde→fondo | **30 m** | Rango razonable 10-40 m para un valle templado de 600 m. 30 m cabe en el envelope actual (`CEILING_HEIGHT=68`) |
| Forma de la ladera | `z = a·y^b` con **b = 1.3** | b=1 → V recta (fluvial), b=1.5-2.0 → U parabólica (glaciar). 1.3 = fluvial poco modificado: suave abajo (donde se camina), empinándose hacia el borde |
| Ancho del fondo plano | **120 m** (semiancho 60 m) | Ratio de confinamiento 6-29× el ancho de canal en tramos no confinados; 120/8 = 15× → lectura aluvial abierta |
| Asimetría de flancos | Flanco norte **×1.25**, flanco sur **×0.8** | Los valles reales son asimétricos (insolación + socavación de meandro). El contraste medido por insolación es sólo 1-1.5°, así que la mayor parte se justifica por socavación |
| Quiebre de pendiente fondo/ladera | Pie de la ladera — inflexión del ángulo | Es el límite correcto para la máscara "fondo" del generador |

### 3. Quebradas (gullies)

| Parámetro | Valor | Razón |
|---|---|---|
| Umbral formal quebrada | Sección **> 929 cm²**, mínimo **0.3 × 0.3 m** | Criterio del "pie cuadrado" (Hauge 1977 / Poesen 1993), estándar |
| Ancho superior (diseño) | **8-18 m** — NO 2-6 m | Ver "decisión de resolución": una quebrada de 4 m es irrepresentable. 8-18 m sigue siendo un landform real |
| Profundidad | **1.0-2.5 m** | Relación ancho/profundidad medida 0.92-10.69, media 3.33 |
| Sección | **V** en pendiente >16°, **U** en pendiente <10° | Material cohesivo: la forma depende del gradiente |
| Dónde se forman | Umbral pendiente-área: **S·A^b < a**, con **b = 0.35**, `a` calibrado | Meta-análisis 2026 (127 datasets): global `S·A^0.269 = 0.014`. Pastizal necesita umbral MÁS ALTO que cultivo |
| Cabecera (headcut) | Donde la pendiente local **>30%** y ≥2× la pendiente aguas abajo | Rengers et al. 2014 |
| Cantidad | **4-6 por flanco → 8-12 total** | Ley de Horton: ratio de bifurcación Rb ≈ 4 (3-5 casi universal) |
| Espaciado | **~120 m** a lo largo del flanco | Da densidad de drenaje ~2.7 km/km², dentro del rango templado |
| Ángulo de confluencia con el eje | **40-70°**, apuntando aguas abajo | Rango natural 30-135°; agudo aguas abajo es lo que se lee correcto |

### 4. Montículos

| Parámetro | Valor | Razón |
|---|---|---|
| Análogo correcto | **Mima mounds** (bioturbación en pradera templada) | Los *thúfur* son periglaciares — biome equivocado |
| Diámetro (heightfield) | **10-30 m** | Mima: 3-50 m, media de sitio ~14 m |
| Altura | **1.0-2.5 m** | Mima: 0.3-2+ m, media ~45 cm; usamos el extremo alto para que se lea |
| Densidad | **~1.5 / ha → ~50 en el mapa** | Densidad real 20-25/ha, pero a esos tamaños son sub-métricos → van como geometría colocada |
| Distribución de tamaños | **Lognormal**, no uniforme | Las distribuciones de tamaño naturales son lognormales; muchos chicos, pocos grandes |
| Hummocks sub-métricos | **0.25-0.6 m alto, 0.7-1.5 m diámetro** → geometría colocada, NO heightfield | Ver decisión de resolución |
| Terracillas | tread <1 m, riser <0.5 m, espaciado ~3.4 m, en pendientes 9-60° | **Imposibles en heightfield a cualquier resolución viable** → normal map / geometría |

### 5. Pendiente: qué crece y qué se camina

| Pendiente | Lectura | Vegetación | Caminable |
|---|---|---|---|
| **0-5°** | Fondo del valle | Pasto denso, flores en derivas, juncos cerca del agua | Sí, cómodo (ADA cómodo = 4.76°) |
| **5-15°** | Ladera baja — la zona de juego principal | Pasto + arbustos + árboles | Sí, sin esfuerzo (hasta 15-20° sin equipo) |
| **15-26.6°** | Ladera alta | Pasto ralo, roca dispersa, árboles aferrados | Sí, lento |
| **26.6-33°** | El pasto falla | Suelo expuesto, escombro, primeros afloramientos | Marginal |
| **>33°** | **Roca desnuda** | Afloramientos, sin sotobosque | No pretendido |
| **>45°** | Muro | — | Godot `floor_max_angle` por defecto = 45° |

Umbrales de origen: pasto establecido máx **26.6° (2H:1V)**; ángulo de reposo suelo suelto **30-40°**;
escree ~33-40°. El umbral "aparece roca en vez de pasto" = **>30-35°** (inferido del cruce de ambos,
no citado directamente).

### 6. Amplitud por octava (cuánto relieve a cada escala)

Espectro de potencia del terreno real: `S(k) ∝ k^-β`, con **β ≈ 2** de base y **2.8-3.1** medido en
sitios concretos. Amplitud ∝ `k^(-β/2)` → con β=2, **cada vez que la longitud de onda se divide a la
mitad, la amplitud también** (persistencia ≈ 0.5, el default clásico de fBm).

Aviso importante: el terreno real **no es fractal puro** — hay quiebres espectrales donde un proceso
concreto (espaciado de drenaje) impone una longitud de onda preferida. No sumes octavas ciegas desde
600 m hasta 1 m: mete el eje del valle, las quebradas y los montículos como **capas deterministas**,
y usa el ruido fractal sólo para la rugosidad entre ellas.

---

## Coherencia con el canon existente

`_world_coherence.md` §7 (REGLA G1-G6) codifica el cuenco actual — **hay que actualizarlo junto al
código**, si no el doc y el código quedan contradictorios:

- **G2** ("centro aplanado, radio 50 m") → se elimina; la reemplaza "fondo de valle de 120 m de ancho
  a lo largo del eje".
- **G3** ("acantilados desde t>0.7, `TERRAIN_EDGE_RISE`") → se reemplaza por subida modulada por
  flanco (alta perpendicular al eje, baja en los extremos del eje).
- **G1** (`freq 0.004`, `octaves 3`, máx 9 m) → la altura máxima sube a ~30 m de caída borde→fondo, y
  las octavas tienen que llegar a longitudes de onda mucho más cortas.
- **H1** ("agua sólo donde altura < 0.3 × máx") → **el valle hace que esta regla se cumpla sola**: el
  fondo ES la zona baja. Hoy la regla pelea contra la geometría; con el valle, la describe.
- **G6** ("la pendiente condiciona qué crece") → hoy está escrita pero **no implementada**: ningún
  scatter lee la pendiente. La tabla de §5 arriba es su implementación.

`_art_canon.md` §17: modelo Valheim — geometría low-poly simple + materiales ricos + luz dramática.
Eso **no** justifica un suelo plano: en Valheim la geometría humilde es la de los *props*, el terreno
sí tiene relieve. La regla §17.2.6 ("suelo = mezcla de materiales por uso implícito, no una textura
tileada") apunta al mismo sitio que la tabla de pendientes.

---

## Fuentes de los números

Geomorfología: Poesen (umbral 929 cm²) · meta-análisis pendiente-área 2026, 127 datasets
(`S·A^0.269=0.014`) · Rengers et al. 2014 (headcut >30%) · Montgomery & Dietrich 1994 (b=0.5-0.86) ·
Yuanmou Dry-Hot Valley (ancho/profundidad 0.92-10.69) · Mima mounds (Wikipedia + Geomorphology) ·
terracettes (Royal Society Interface 2026) · perfiles transversales glaciares Tian Shan (b=1.03-3.50) ·
leyes de Horton (Rb 3-5) · λ=10.23·W sobre 438 sitios (AGU 2019) · β espectral (Perron et al. 2008).

Pendientes: límite de pasto 2H:1V y 3H:1V (guías de estabilización de taludes) · ángulo de reposo
25-45° · ADA 8.33% · grados de sendero sostenible ≤10% medio, 15-25% máximo.

Ecología de la distribución vegetal (para el veredicto de densidad): proceso de Thomas /
Neyman-Scott como modelo estándar de agregación · función de correlación de pares g(r) · aspecto
sur-norte = **1.4-5.6 °C** y **≥78 kPa** más seco en solana · suelo desnudo en pradera templada
**10-20%** · tamaño individual de planta **lognormal** · autoaclareo M̄ = ζ·n^γ, γ ≈ -3/2 (heurística,
exponente exacto discutido) · dispersión de semillas de forbias por viento: mayoría <30 m, cola larga.

**Marcados como NO verificados** (no tratarlos como hechos): densidad de drenaje en km/km² específica
de pradera templada; gradiente longitudinal típico de quebrada; umbral exacto de afloramiento rocoso
por bioma; caída borde-fondo específica para un valle de 600 m; asimetría típica en grados;
sinuosidad típica de eje de valle; parámetros calibrados del proceso de Thomas para forbias de
pradera; resolución real del heightmap de Valheim; si PoE2 pasó de tiles a terreno continuo.
