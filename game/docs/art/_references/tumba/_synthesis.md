# Reference — `tumba`

Base name: **`tumba_`**. Todo artefacto sobre la arquitectura de tumba del salón del título lleva ese prefijo. Relacionado: `[[titlescreen]]` (canon de escena, pase 2026-08-08), `[[dungeon_interior]]` (sensación sillería + dos temperaturas), `[[logo]]`.

Convención de certeza usada en TODO el doc: **[F]** = cifra leída en la fuente citada; **[F-sec]** = fuente secundaria/divulgación (usar como orden de magnitud); **[E]** = estimación mía, derivada de foto o de oficio, **sin fuente publicada accesible — validar antes de gatear**. Ninguna [E] debe entrar a un assert sin medir un control.

## Fuente

Investigación de 2026-11-03 (agente de referencia, sin modelado). Motivo: el motor Blender no tiene recetas de muro de piedra ni interior de tumba y el owner pidió investigar antes (historia, estructura real, material, técnica, iconografía), idealmente latinoamericana. El canon de mundo asigna a lo latinoamericano el rol de **"guardianes de ruinas"** (`game/docs/lore/_world_canon.md:64`).

10 fotos con licencia libre (Wikimedia Commons) en esta carpeta; tabla de licencias al final. Lo que NO se pudo obtener se declara como hueco, no se rellena en silencio (ver §"Huecos de la investigación").

## Idea

**La tumba del título no es "un dungeon de piedra": es una cámara funeraria precolombina — piedra tallada a mano, ensamblada en seco o con barro, techada con falsa bóveda o losas, con un frente decorado con relieve geométrico repetido.** Tres rasgos se repiten en todos los sitios revisados y son los que hacen que *lea* como tumba y no como muro cualquiera:

1. **Bloques con juntas finas pero visibles** (no hay muro liso; la piedra siempre es *piezas*).
2. **Techo que se cierra hacia arriba** (falsa bóveda maya, o galería de losas en Chavín): el pasillo se siente *comprimido*, no un tubo de sección constante.
3. **Un registro decorativo concentrado en un solo lugar** (friso de grecas en Mitla, estuco en nichos en Palenque, cabezas clava en Chavín/Tiwanaku), con el resto del muro liso — así la decoración es evento, no textura de fondo.

## Referencias elegidas y por qué

Elegidas 3, de lo que mejor encaja con *"salón-tumba con pasillo oscuro a la derecha iluminado por UNA antorcha"* (`titlescreen/_synthesis.md` §Arquitectura, §La antorcha).

### 1. Palenque — Templo de las Inscripciones y tumba de Pakal (Maya, Chiapas, ~683 d.C.)  → **ESTRUCTURA del salón y del techo**
Por qué: es **literalmente** un pasillo/escalera que baja hasta una cámara funeraria con falsa bóveda, y el Maya es el caso más documentado de bóveda en voladizo. Encaja con "pirámide" del canon (la tumba está DENTRO de una pirámide de 9 cuerpos).

### 2. Chavín de Huántar — galerías subterráneas del Templo Viejo / Castillo (Andes, ~1200–200 a.C.)  → **PASILLO oscuro y su luz**
Por qué: son corredores **estrechos, sin ventanas, techados con losas, con ductos de ventilación mínimos** — el análogo real del "pasillo con oscuridad y mobs mirando" donde solo una antorcha alcanza un tramo. Además tiene las **cabezas clava** (cabezas de piedra empotradas en el muro por una espiga) como motivo escultórico que mira desde la pared: coincide con *ojos que miran desde la oscuridad*.

### 3. Mitla — Grupo de las Columnas, tumbas cruciformes y grecas (Zapoteco/Mixteco, Oaxaca, ~1300–1400 d.C. para el Grupo de las Columnas)  → **ICONOGRAFÍA / frente / dintel**
Por qué: el friso de **grecas escalonadas en mosaico de piedra cortada, sin mortero, sobre estuco rojo** es el mejor motivo repetitivo y geométrico de toda Latinoamérica, y es **directamente construible** (módulo + relieve). Tiene tumbas cruciformes bajo los patios y dinteles monolíticos de hasta ~18 t.

### Complementarias (no son el eje, aportan un dato puntual)
- **Tiwanaku / Puma Punku** — bloques con cajas para grapas, junta casi nula; **Templete Semisubterráneo**: patio hundido con cabezas-espiga en sillares rojizos (foto `tumba_tiwanaku_templete_cabezas.jpg`).
- **Inca** — junta sin mortero, muros inclinados hacia adentro, **vanos trapezoidales** y jambas dobles. Muy bueno para la *puerta* del pasillo.
- **Monte Albán (Tumba 7 / 105)** — cámaras con nichos y murales; **no se consiguieron cifras** (ver huecos).

### Argumento de encaje contra el canon del título
| Requisito canon (titlescreen) | Qué lo cumple |
|---|---|
| "estructura antigua tipo tumba: losas, piedra de muralla, algún pedazo caído" | Palenque (falsa bóveda de lajas) + Chavín (galería de losas) |
| "una antorcha ilumina su tramo y deja el resto negro" | Chavín: galería **sin ventanas**, aire por ductos pequeños → la oscuridad es real |
| "ojos en la oscuridad" | cabezas clava / cabezas-espiga de Tiwanaku: rostros de piedra en el muro |
| Logo **frío** sobre piedra **cálida** | ver §Contradicciones: la piedra real es gris-parda de baja saturación → admite un logo frío |
| Muro con registro decorativo para que no sea plano | Mitla: friso de grecas en el dintel/zócalo |

### Chile / Cono Sur — dicho honestamente
**No mapea a arquitectura de tumba de piedra.** Lo que se encontró: el mapuche usa **chemamüll**, estatuas de madera de >2 m que se erigen sobre la tumba ([Wikipedia: Chemamüll](https://en.wikipedia.org/wiki/Chemam%C3%BCll)); la cultura **Chinchorro** (norte de Chile) practicó momificación de hace ~5000 años, no construyó cámaras ([Smithsonian](https://www.smithsonianmag.com/smart-news/can-the-worlds-oldest-mummies-survive-climate-cange-other-threats-coming-decades-180980146/)); la **chullpa** (torre funeraria de piedra) es del altiplano Titicaca (Perú/Bolivia), no confirmé que aplique a sitios atacameños. **Descartado para esta sala.** Si el owner quiere un guiño chileno, sirve como *objeto* (un tótem de madera tallada caído en el salón), no como arquitectura.

## Colores

Muestreados con cuantización mediana (PIL, 5 clusters) sobre los JPG de esta carpeta. Son fotos a **luz de día**, así que son *albedo aproximado*, no el valor bajo antorcha.

| Rol | sRGB | Foto de origen | Notas |
|---|---|---|---|
| Piedra caliza parda, tono medio | `#725D4D` | `tumba_chavin_galerias_castillo.jpg` | muro de galería, sat ≈32 %, tono ≈28° |
| Piedra, sombra profunda / junta | `#47372C` | idem | 22 % de la imagen; junta y hueco |
| Piedra, luz / cara iluminada | `#C0A79E`, `#E3CFC4` | idem | cantos que reciben luz rasante |
| Granito/toba gris casi neutra | `#6F6A60`, `#8B867C` | `tumba_mitla_grecas_interiores.jpg` | sat ≈13 %, tono ≈40°: la más **fría** de las piedras reales |
| Greca en sombra (hueco del relieve) | `#1C1815`, `#48433B` | idem | 27 % casi negro: el relieve se lee por sombra, no por color |
| Caliza dorada de muro con greca | `#8A7B68`, `#706559` | `tumba_mitla_grecas_columnas.jpg` | |
| Caliza de bóveda maya (ocre) | `#88775B`, `#6F5A3B`, `#A1957D` | `tumba_palenque_boveda_maya.jpg` | el más cálido/saturado de los sitios maya |
| Pirámide cubierta de verdín (humedad/musgo) | `#535846`, `#6E725E` | `tumba_palenque_templo_inscripciones.jpg` | **verde-gris**: el color de la piedra húmeda con musgo |
| Arenisca rojiza (Tiwanaku) | `#70443F`, `#8D625C`, `#4E2724` | `tumba_tiwanaku_templete_cabezas.jpg` | saturada y cálida: **EVITAR para muros** si el logo es frío |
| Estuco rojo de fondo (Palenque: "rojo oscuro" todo el edificio; Mitla: fondo de grecas) | no muestreado, ninguna foto lo conserva | — | [F] color: [mesoweb](https://www.mesoweb.org/palenque/structures/TI/temple.html) "deep dark red"; Mitla: [Wikipedia ES](https://es.wikipedia.org/wiki/Mitla) "estuco pintado de color rojo". Proponer `#6B2A22` [E] solo en nichos/fondo de greca |

Regla que sale de las fotos: **la piedra real es de croma bajo (sat 13–32 %) y varía de gris-pardo a ocre**; lo que la hace "tumba" es el valor (muy oscuro en juntas y huecos), no el tinte.

## Forma

### Palenque (estructura de tumba)
- Pirámide de 8 niveles + templo = **22,8 m** [F: [Wikipedia ES](https://es.wikipedia.org/wiki/Templo_de_las_Inscripciones)]; frente con cinco vanos y escalera de **9+19+19+13+9 = 69** peldaños [F: [mesoweb](https://www.mesoweb.org/palenque/structures/TI/temple.html)].
- Escalera interior en **dos tramos** hasta la cripta; hay **discrepancia**: 73 peldaños [F: [INAH](https://lugares.inah.gob.mx/en/pagina-de-elemento/2580)] vs 26+22 = 48 [F-sec: [delange.org](https://delange.org/PalenqueTomb/PalenqueTomb.htm)]. Profundidad de la cripta: **1,50 m** bajo el suelo [Wikipedia ES] vs **2 m** bajo la plaza [mesoweb]. Para el motor: usar la lógica "escalera de dos tramos con descanso", no la cuenta.
- Cripta: **≈9 × 4 × 7 m** (largo × ancho × alto de bóveda) [F-sec: [mayan.org](https://mayan.org/ruins/pakal-tomb/)]; variante 8,8 × 3,9 × 7. **Ninguna fuente primaria accesible dio estas cifras** → tratarlas como orden de magnitud: *proporción alto/ancho ≈ 1,75*, es decir **más alta que ancha**.
- Techo: "dos bóvedas rectas consecutivas, cruzadas por vigas de piedra"; la sur cubre la entrada, la norte (más alta) es el techo propio; dos nichos de bóveda cruzada en muros E y O [F: [Campiani, Stuardo & Lercari 2020, Ancient Mesoamerica](https://doi.org/10.1017/S0956536120000498)].
- Piso de grandes lajas de caliza con inclinación sur-norte [ídem]. Acceso a la cámara por una **puerta triangular** sellada con losa triangular [ídem].
- Tapa del sarcófago: **3,80 × 2,20 × 0,25 m**, ≈7 t [F: Wikipedia ES; delange.org confirma 3,8 × 2,2]; otras fuentes dicen ≈5 t [F-sec].
- Cámara con **5 nichos** (2 E, 2 O, 1 N), con **7 figuras de estuco** en nichos + 2 flanqueando el acceso (los Nueve Señores de la Noche) [F: INAH]. Sarcófago apoyado en 6 bloques; interior pintado con óxido de hierro/cinabrio [INAH].
- Psicoducto: tubo de piedra hueco paralelo a la escalera, desde el sarcófago hasta la losa del piso del templo [Campiani et al.]. **Cuadra para la antorcha**: un respiradero/tubo en el techo del pasillo.
- Los constructores terminaron la cripta **antes** de levantar la pirámide: sarcófago y tapa tallados *in situ* [mesoweb]. (Dato de oficio útil: el hueco de acceso es más estrecho que la tapa → esa pieza no puede ser "movida", solo está.)

### Chavín (estructura de pasillo)
- Castillo **71 × 71 m**; Plaza Cuadrangular 50,2 m; Plaza Circular 20,8 m diámetro; talud de los muros de plataforma **5,3°** [F: [Wikipedia ES](https://es.wikipedia.org/wiki/Chav%C3%ADn_de_Hu%C3%A1ntar)].
- **~35 galerías** hechas en distintos períodos; solo se conoce ≈15 % del monumento [F: John Rick vía [Andina/ProActivo](https://proactivo.com.pe/nuevos-hallazgos-en-chavin-de-huantar-uno-de-los-mas-importantes-en-50-anos/)]. Pasajes nuevos de **≈40 cm de diámetro** (ductos) [ídem].
- Galerías "techadas con losas pesadas y comunicadas al aire por ductos de ventilación" [F-sec: [UIC/EVL](https://www.evl.uic.edu/gotsis/huacas/explore_2.html)]; **sin ventanas**, solo ductos pequeños.
- Muro de piedra con **argamasa de barro** [Wikipedia ES]; granito blanco (granodiorita) traído de >30 km, caliza negra, arenisca/cuarcita en cabezas clava [ídem].
- Lanzón: **4,54 m**, "piso a techo" en la galería cruciforme [Wikipedia ES, [Wikipedia: Lanzón](https://en.wikipedia.org/wiki/Lanz%C3%B3n)].
- **Ancho y alto de galería: NO encontré cifra publicada accesible.** Estimación de la foto `tumba_chavin_galerias_castillo.jpg`: **[E] ancho ≈0,9–1,1 m, alto ≈1,8–2,2 m** (la sección es un rectángulo alto y angosto; el techo es de losas planas, sin bóveda). Es una **proporción** aproximada (alto/ancho ≈ 2), no una medida.

### Mitla (frente decorado y tumba cruciforme)
- Salón de las Columnas: **36,6 × 6,4 m**, 6 columnas monolíticas de roca volcánica [F: [Wikipedia](https://en.wikipedia.org/wiki/Mitla)]; hay otra cifra 38 × 7 m, columnas ≈2 m diámetro [F-sec: [Coggle](https://coggle.it/diagram/XoHzeEnCLiUO_Ok2/t/mitla), dudosa].
- Dinteles y columnas de hasta **18 t** [Wikipedia].
- Muro: **núcleo de barro y piedra revestido con estuco o con trachita bien cortada** [Wikipedia].
- Tumba cruciforme: antecámara; techo de **grandes vigas de piedra**; muros con tableros y grecas; una columna monolítica en el cruce [Wikipedia, [Wikipedia ES](https://es.wikipedia.org/wiki/Mitla)]. **Sin cifras de tumba.**
- Grecas: "miles de piedras cortadas y pulidas, encajadas **sin mortero**, sostenidas por el peso de las piedras vecinas, sobre fondo de estuco rojo"; en los dinteles, las "teselas" se empotran en la viga [Wikipedia]. **Módulo y relieve: no encontré cifra** (ver Tabla [E]).

### Tiwanaku e Inca (aportes puntuales)
- Puma Punku: bloque mayor **131 t**, segundo **85 t**; plataforma lítica 6,75 × 38,72 m [F: [Wikipedia](https://en.wikipedia.org/wiki/Tiwanaku)]. Acabado: capa blanquecina de **1–1,5 mm** posiblemente mortero [F-sec: reportado por Protzen & Nair vía [cavac](https://cavac.at/cavacopedia/Pumapunku)]; precisión ≈0,04 in ≈ **1 mm** [F-sec: [History.com](https://www.history.com/articles/pumapunku-ancient-site-tiwanaku)] — *no es verdad para todos los bloques*.
- Templete Semisubterráneo: patio cuadrado hundido, muros "cubiertos de cabezas-espiga de muchos estilos" (reutilizadas a lo largo del tiempo) [Wikipedia].
- Inca: piedra ajustada **sin mortero**; muros ligeramente inclinados hacia adentro y esquinas redondeadas (resistencia sísmica); vanos **trapezoidales**, jambas dobles o triples [F: [Wikipedia: Inca architecture](https://en.wikipedia.org/wiki/Inca_architecture)]. Subtipos de mampostería fina (Agurto): poligonal celular, poligonal de sillares grandes, almohadillada, en hiladas [ídem].

## Movimiento / Feel

La arquitectura es **estática**; lo que se mueve es la luz sobre ella. Comportamiento esperado de estos materiales bajo una antorcha/fogata rasante:

- **Piedra de grano grueso con juntas hondas (Chavín, Palenque):** la luz rasante rellena de sombra cada junta → el muro se lee como **retícula de rectángulos**; con el parpadeo de la llama la retícula "respira" porque la sombra de cada hueco se alarga y acorta. Hay que dejar la junta en **profundidad real** (relieve), no pintada.
- **Relieve de greca (Mitla):** el único motivo que **se lee solo por sombra** (en foto, 27 % de los píxeles son casi negro `#1C1815`). Con luz frontal desaparece; con luz rasante, aparece. En la sala eso significa: **la greca debe quedar del lado donde llega la antorcha en ángulo bajo**, no enfrentada a ella.
- **Estuco rojo (nichos, fondo de greca):** absorbe la luz cálida y la devuelve **más saturada** → es el elemento que "se enciende" en la penumbra. Úsese en poco área.
- **Bóveda en voladizo:** cada hilada que sobresale **proyecta su propia sombra sobre la hilada de abajo**; bajo luz de abajo hacia arriba (fogata) se ve una escalera invertida de bandas claras/oscuras. Eso es el movimiento más característico de la bóveda maya y gratis si las hiladas son geometría real.
- **Humedad/verdín:** en la foto de pirámide la piedra húmeda tira a **verde-gris** (`#535846`): sirve de contrapunto *frío* natural en la parte baja del muro.

## Qué capturar

1. **Proporción alto/ancho del pasillo ≈ 2** (Chavín) y **bóveda más alta que ancha ≈ 1,75** (Palenque): la compresión vertical hace la tumba. Un pasillo de sección cuadrada se lee "túnel de metro".
2. **Bloques con junta visible y a veces SIN hiladas rectas** (inca poligonal / Chavín irregular): variar altura de hilada, no un grid perfecto.
3. **Techo que se cierra** (voladizo escalonado o losas), no cielorraso plano.
4. **Un solo registro decorativo concentrado** (friso de greca sobre zócalo liso).
5. **Ojos/rostros de piedra que miran** (cabeza-espiga): el equivalente real del "ojo en la oscuridad" sin inventar nada.
6. **El desgaste real**: lo primero que se cae es el **dintel/losa de techo y la hilada superior del voladizo**; los bloques caen **hacia el lado libre** (hacia el salón); verdín abajo, eflorescencia/escurrimiento bajo cada junta de techo.
7. **La piedra no es sucia-marrón uniforme:** es gris-parda a ocre **de croma bajo**, con juntas casi negras (valor, no tinte).

## Tabla de parámetros

Escala de juego: jugador **1,80 m**. Columna "real" = lo encontrado; columna "propuesto" = valor para el motor, ya reescalado a "tumba para gente de 1,80 m" (el real maya/andino es para gente de ~1,60 m, así que se agranda 10–15 % para que el jugador no roce).

### A. Pasillo oscuro (Chavín + Palenque)
| Parámetro | Real | Propuesto motor | Estado |
|---|---|---|---|
| Ancho de pasillo | Chavín ≈0,9–1,1 m [E] | **1,30 m** (con 1,80 m de jugador de hombro ≈0,55 m, deja cruzar y deja ojos en las sombras laterales) | [E] |
| Alto de pasillo (hasta losa) | Chavín ≈1,8–2,2 m [E] | **2,60 m** (alto/ancho = 2,0) | [E] |
| Tipo de techo del pasillo | losas planas sobre ménsulas (Chavín) | **losas de caliza**, largo = ancho + 2×0,20 m de apoyo = **1,70 m** | derivado |
| Espesor de losa de techo | no hallado | **0,25 m** (guiado por la tapa de Pakal 0,25 m [F]) | [E] |
| Largo del pasillo visible | — | **9–12 m** hasta el negro (la antorcha alcanza ≈6 m útiles, ver `titlescreen`) | diseño |
| Ducto/respiradero | ≈0,40 m de diámetro [F-sec: Rick] | **1 ducto de Ø 0,40 m** en techo, a ~4 m de la entrada (por donde puede subir humo de antorcha) | [F-sec] |

### B. Salón (Palenque + Mitla)
| Parámetro | Real | Propuesto motor | Estado |
|---|---|---|---|
| Planta de cámara | Palenque ≈9 × 4 m | **salón 9 × 6 m** (más ancho que Pakal: caben fogata + grupo) | [F-sec] / diseño |
| Alto máximo bajo bóveda | ≈7 m [F-sec] | **5,5 m** (alto/ancho = 5,5/6 ≈ 0,9; **no** copiar 7 m: el título flota delante a ~2,5 m de altura y no debe tocar la bóveda) | [F-sec] / diseño |
| Tipo de bóveda | falsa bóveda (voladizo) con vigas de piedra cruzadas | **falsa bóveda de lajas, doble pendiente (longitudinal)** | [F] |
| Arranque de bóveda (muro vertical) | no hallado | **2,40 m** de muro vertical y luego voladizo | [E] |
| Voladizo por hilada | no hallado | **0,12 m** por hilada, hilada de **0,28 m** de alto → ángulo medio ≈ atan(0,28/0,12) = **67°** sobre la horizontal | [E] |
| Hiladas de voladizo | — | **11 hiladas** de 0,28 m = 3,08 m → cierre en la clave con **1 laja de 0,60 m** | derivado |
| Losa de piso | "grandes lajas de caliza" (Palenque) | lajas **0,90–1,40 m × 0,60–0,90 m × 0,15 m** | [E] |
| Espesor de muro | Mitla: núcleo + revestimiento; no hallado | **0,90 m** visibles en jambas del vano (se ve el corte en la entrada del pasillo) | [E] |
| Peldaños de escalera de acceso | no hallado | **huella 0,32 m / contrahuella 0,18 m**, 2 tramos con descanso 1,30 × 1,30 m | [E] |
| Vano de acceso al pasillo | Inca: trapezoidal; Palenque: triangular (puerta de la cripta) | **trapezoidal**: ancho base 1,30 m, ancho dintel 1,00 m (**inclinación jamba ≈ 5,7°**), alto 2,40 m | [F] forma / [E] cifras |

### C. Mampostería (bloque + junta + hilada)
| Parámetro | Real | Propuesto motor | Estado |
|---|---|---|---|
| Tipo | Chavín: piedra irregular + barro; Inca: poligonal sin mortero; Palenque: lajas | **Zona A (pasillo/muros):** sillar **semirregular** en hiladas de altura variable (Chavín/inca) ; **Zona B (bóveda):** lajas rectangulares planas | [F] |
| Altura de hilada (muro) | no hallado | **0,26–0,42 m**, variando ±20 % entre hiladas | [E] |
| Largo de bloque | no hallado | **0,50–1,30 m**, razón largo/alto 1,6–3,5 | [E] |
| Ancho de junta | Puma Punku ≈1 mm (extremo); Inca: sin mortero; Chavín: barro | **muro: 6–14 mm** (junta real, de barro); **bloque noble (dintel, jamba): 2–4 mm** | [E] |
| Profundidad de junta visible | — | **15–25 mm** de hueco (para que la luz rasante la rellene de sombra) | [E] |
| Redondeo de arista | Inca: esquinas redondeadas; Puma Punku: arista viva | radio **4–10 mm** en muro, **1–2 mm** en bloques de dintel | [E] |
| Bloque mayor (dintel de acceso) | Mitla hasta 18 t | **1 dintel monolítico** 2,00 × 0,45 × 0,55 m (el largo supera el vano 1,30 m en 0,35 m por lado) | [E] |
| Bloque grande de sillar único | Puma Punku 131 t | **no necesario** a escala de sala | — |

### D. Desgaste y caída (por zona)
Porcentajes = fracción de bloques de esa zona con daño ya visible. **Todos [E]**: ninguna fuente dio estadística; salen de qué se cae primero en sitios abandonados (dinteles, hilada superior) y de las fotos adjuntas.

| Zona | Arista saltada / mella | Bloque faltante (hueco) | Bloque caído al piso | Verdín/humedad (cobertura) |
|---|---|---|---|---|
| Hilada superior del voladizo y clave | 20 % | **8 %** | **4–6 bloques en el piso, a ≤2 m del muro** | 5 % (seco) |
| Muro medio (0,8–2,2 m) | 12 % | 2 % | 1–2 | 10 % |
| Zócalo (0–0,8 m) | 15 % | 1 % | — | **35–50 %** (humedad asciende) |
| Piso | 25 % (lajas partidas) | 3 % (laja hundida) | — | 30 % (charco leve en el borde del pasillo) |
| Jamba y dintel del vano | 8 % | 0 % | 0 | 3 % |
| Greca | 18 % en cada módulo (pieza saltada) | **1 de cada 12 módulos faltante** | 0 | 8 % |

Dirección de caída: **hacia el lado libre** (salón), nunca hacia dentro del muro. Eflorescencia/escurrimiento: franja vertical bajo cada junta del techo, ancho **0,05–0,12 m**, longitud **0,30–0,80 m**, tono `#C0A79E` más claro que la piedra.

### E. Relieve e iconografía (geometría)
| Parámetro | Real | Propuesto motor | Estado |
|---|---|---|---|
| Greca escalonada, módulo (alto de la fila) | Mitla: no hallado | **0,10 m** (2 escalones de 0,05 m) | [E] |
| Ancho del módulo (una "S" cuadrada de greca) | no hallado | **0,20 m**, ritmo de repetición **0,20 m** | [E] |
| Alto de la banda de greca | no hallado | **0,50 m** (5 filas) en friso de dintel; **0,80 m** en zócalo | [E] |
| Profundidad de relieve | no hallado | **0,03–0,05 m** (3–5 cm; menos no lee a 6 m con luz de antorcha) | [E] |
| Paso del fondo | Mitla: fondo de estuco rojo | fondo hundido, fondo `#6B2A22` [E] | [F] concepto |
| Cabeza clava | Chavín: 56 originales, solo 1 in situ [Wikipedia ES] | **Ø 0,28–0,35 m**, espiga empotrada **≥0,40 m**, saliente **0,25 m**; **1 cada 1,2 m** en una hilada a 1,95 m del piso | [E] |
| Nicho | Palenque: 5 nichos en cámara; Inca: trapezoidal | **0,45 × 0,70 × 0,35 m** (ancho × alto × profundidad), arriba más angosto 0,38 m | [E] |

### F. Paleta resumida (para `MATERIAL_PALETTE`)
`piedra_media #725D4D` · `piedra_sombra #47372C` · `piedra_luz #C0A79E` · `piedra_fria #6F6A60` · `junta #1C1815` · `verdin #535846` · `estuco_rojo #6B2A22 [E]` · `eflorescencia #C0A79E`. Fuente de cada una en §Colores.

## Iconografía

Motivos (en orden de prioridad) y dónde van en el salón:

| Motivo | Origen | Dónde va | Geometría |
|---|---|---|---|
| **Greca escalonada (stepped fret)** | Mitla | **Friso sobre el dintel** del vano al pasillo + **zócalo** corrido en el muro del fondo del salón | banda 0,50 m × largo del vano (~2,0 m) → **10 módulos de 0,20 m**; zócalo 0,80 m de alto; relieve 3–5 cm; fondo hundido; módulo **repetido sin espejo** para no verse generado |
| **Cabeza-espiga (clava)** | Chavín / Tiwanaku | **Hilada alta del muro del pasillo** (a 1,95 m): hacen de "ojos" que miran. Enlaza con los ojos pestañeantes del canon | 1 cada 1,2 m, saliente 0,25 m, **orientadas hacia el pasillo** |
| **Nicho trapezoidal** | Inca / Palenque | **Muro del salón, lado fogata** (nichos con las armas/el escudo apoyados: encaja con "escudo y espada apoyados contra la pared") | 0,45 × 0,70 × 0,35 m |
| **Estuco rojo** | Palenque / Mitla | solo **fondo de greca y fondo de nicho** | área ≤8 % del muro |
| **Glifos / tablero de inscripción** | Palenque (Templo de las Inscripciones: tableros glíficos en sala frontal y trasera) | **Un tablero** de 0,90 × 0,60 m en el muro del fondo, **tapado/erosionado**; no inventar texto legible | relieve 2 cm, ilegible (50 % de bloques saltados) |
| **Losa triangular de sello** | Palenque | **Opcional**: losa triangular caída al lado del vano | triángulo base 1,2 m, alto 1,6 m, espesor 0,25 m |

**Nota sobre "runas":** el owner usó la palabra (runas); lo real aquí es **glifos maya (Palenque)** y **grecas zapotecas (Mitla)**, **no** runas nórdicas. Recomiendo **no escribir texto** (no se puede leer y el riesgo de inventar glifos falsos es mayor que el beneficio): usar grecas (puro geométrico) + un tablero erosionado.

## Contradicciones con el canon

1. **"Pirámide, azteca"** (owner, 2026-08-08). Lo revisado: **no hay tumbas aztecas de piedra** comparables a las de Palenque o Mitla. Mi búsqueda sobre prácticas mexicas no devolvió una fuente confiable sobre dónde se enterraba a los gobernantes (el único hallazgo vinculado: un túnel hacia una plataforma circular donde se creía que se cremaba a gobernantes, [Fox News](https://www.foxnews.com/science/discovery-of-grisly-aztec-war-sacrifices-could-lead-to-long-lost-emperors-tomb-report), **fuente débil, no usar como hecho**). **Lo que realmente encaja con "pirámide + tumba"** es **Palenque** (maya, la tumba DENTRO de una pirámide de 9 cuerpos) y **Teotihuacan** (túnel bajo el Templo de la Serpiente Emplumada con cámaras al final; aún se discute si son tumbas, [historicalmx](https://historicalmx.org/items/show/40)). **Propuesta:** decir "tumba tipo Palenque/Mitla" y dejar "azteca" como sabor genérico, no como referencia arquitectónica.
2. **"Cemento viejo"** (canon). No existe cemento precolombino. Lo equivalente es **argamasa de barro** (Chavín [F]) o **estuco de cal** (Palenque, Mitla [F]) → cuando el owner dice "cemento viejo", leer "**estuco / barro, agrietado y despegado**". Impacto: las juntas del muro deben ser de *barro* (tono más oscuro que la piedra), no un gris cemento uniforme.
3. **"Losas"** (canon). Correcto para el techo del pasillo (Chavín) y el piso (Palenque). Pero en la sala principal lo característico es la **falsa bóveda**, no una losa plana de ~6 m de luz (no hay evidencia de losas así en techos mayas ni andinos; de Mitla solo sé que usa vigas/dinteles monolíticos de hasta 18 t, sin luz medida). → Sala: bóveda en voladizo. Pasillo: losas.
4. **Logo FRÍO sobre piedra CÁLIDA** (`titlescreen` §Cómo vive el título). **Verificación:** la piedra real muestreada es de croma bajo (sat 13–32 %; la más fría `#6F6A60` es casi neutra, la más cálida `#725D4D` ≈ tono 28°). Hay espacio: un logo en **basalto oscuro azulado** (p. ej. `#3E4A52`) o **bronce con pátina verdosa** (`#4F7A6E`) tiene tono ~180–200°, es decir **opuesto** al de la piedra (~30°). **PERO** dos advertencias:
   - **No usar la arenisca rojiza de Tiwanaku (`#70443F`)** en los muros: su croma es alto y su tono rojo-pardo compite con la fogata; entonces el logo frío pierde separación. Mantener los muros en la familia caliza-gris-ocre.
   - **Bajo una luz de ≈2000 K (antorcha, fogata), un albedo azulado NO sale azul**: sale oscuro y casi neutro, porque casi no hay componente azul que reflejar. La separación por temperatura **solo funciona si hay un relleno frío** (luz de borde/ambiente azul-verdoso, que es justo lo que pide `dungeon_interior`: "ámbar cerca contra azul-verde lejos"). Es una **hipótesis para el test de luz de Godot**, no un hecho: medir ΔE entre logo y muro en el render, con y sin relleno frío. Alternativa que no depende del relleno: separar por **valor** (logo más claro o más oscuro que el muro) y por **material** (pátina metálica con especular vs caliza mate).
5. **"Algún pedazo caído"**: coincide con la evidencia (Chavín y Mitla se conservan con bloques caídos; Mitla tiene grecas deliberadamente destruidas en una tumba, [Bernal vía UNAM](https://nahuatl.historicas.unam.mx/index.php/ecn/article/download/78608/69551/231725)). La tabla D fija cuántos y dónde.
6. **"Pasillo a la derecha con mobs"**: Chavín es el único con **galería realmente sin ventanas**; en Palenque la escalera interior tiene "respiraderos" (galerías angostas de ~8 m, [F: Campiani et al.]) pero no un pasillo largo. La fuente del pasillo es Chavín; la de la sala es Palenque.

## Huecos de la investigación (explícitos)

Lo que **no** pude confirmar con fuente accesible — no se rellena con cifras inventadas; está marcado [E] en las tablas:
- **Ancho/alto reales de las galerías de Chavín**, y el espesor de sus losas de techo. Probable fuente: publicaciones del Proyecto Chavín de Huántar (Stanford, J. Rick; Kembel) — no accesibles aquí (PDFs sin texto o 503).
- **Largo/ancho/alto exactos de la cripta de Pakal** con fuente primaria (Ruz Lhuillier 1973, "El Templo de las Inscripciones, Palenque"). Los 9 × 4 × 7 m vienen de divulgación.
- **Módulo y relieve de las grecas de Mitla** (cm). Probable fuente: INAH / Robles García (2016).
- **Dimensiones de tumbas de Monte Albán (7, 105)** y de las tumbas cruciformes de Mitla.
- **Teotihuacan talud-tablero**: no se consiguió una ficha con proporciones (el pedido lo mencionaba; queda fuera de las referencias elegidas).
- Un dato que cambia entre fuentes: **peso de la tapa de Pakal** (5 t vs 7 t) y **nº de peldaños interiores** (48 vs 73). No afecta al motor.

## Qué falta para una receta del motor

El motor no tiene nada de esto (`LECCIONES.md` §6: construir DESDE las piezas, no pintar sobre una superficie continua). Recetas que habría que diseñar, cada una con entradas/salidas:

| # | Receta | Entradas | Salidas | Gate propuesto |
|---|---|---|---|---|
| R1 | **`sillar_wall`** — generador de muro de bloques en hiladas | rectángulo del muro (W×H); rango alto de hilada, rango largo de bloque, ancho y profundidad de junta, redondeo de arista, semilla, % de variación | malla **por bloque** (un objeto/isla por sillar) con atributo `block_id`, `course_idx`; UV por bloque; opcional vertex color de valor por bloque | `material_swatch` sobre cubo; verificar que la junta tiene profundidad ≥15 mm (comparar bbox de bloque vs retícula); aristas visibles bajo luz rasante |
| R2 | **`corbel_vault`** — falsa bóveda en voladizo | largo, ancho de muro a muro, altura de arranque, nº de hiladas, voladizo por hilada, alto de hilada, espesor de laja, losa de cierre | bóveda de lajas apiladas con atributo `course_idx`; opcional vigas de piedra cruzadas | gate geométrico: **voladizo acumulado = ancho/2** (la bóveda cierra); ángulo medio dentro de ±5° de lo pedido |
| R3 | **`slab_ceiling`** — techo de losas para pasillo | largo, ancho, espesor, apoyo, ménsulas/escalón | losas apoyadas con hueco para ducto Ø0,40 | gate: losa apoya ≥0,15 m de cada lado |
| R4 | **`greca_stamp`** — sello de relieve de greca escalonada | patrón (matriz), módulo, ritmo, profundidad de relieve, fondo hundido, % de piezas saltadas, semilla | geometría desplazada (no solo normal map) sobre una cara de un bloque o banda; máscara de la zona | **medir profundidad real del relieve ≥3 cm** (lección 3: no "radio de esfera"); gate de que el relieve **se ve con luz rasante** (render a 15° con control positivo) |
| R5 | **`clava_head`** — cabeza-espiga empotrada | Ø, saliente, largo de espiga, estilo (3 variantes), orientación | malla de cabeza + marca en hilada | gate: la espiga queda dentro del muro (≥0,40 m) |
| R6 | **`fallen_block_scatter`** — dispersión de bloques caídos | zona de caída (cara del muro), nº de bloques, tamaño (usa los mismos de R1), radio ≤2 m, apilamiento | bloques con rotación realista, asentados al piso por BVH/raycast | gate: **ningún bloque flota** (altura mínima = piso); bloques caídos **provienen del hueco** del muro (coinciden con huecos faltantes) |
| R7 | **`wear_pass`** — desgaste por zona | tabla D (arista saltada %, faltante %, verdín %), por zona (hilada, zócalo…) | aristas mellar, bloques eliminados, mapa de verdín (alpha por altura), franjas de eflorescencia | porcentajes medidos en la malla ≈ los pedidos (±3 pt) |
| R8 | **`trapezoid_portal`** — vano inca/Palenque con jambas y dintel monolítico | ancho base, ancho dintel, alto, espesor muro, dintel monolítico | vano con dintel + 1–2 jambas dobles | gate: dintel supera el vano ≥0,30 m por lado |
| R9 | **`niche`** — nicho trapezoidal | ancho, alto, profundidad, taper | vano hundido en R1 | — |
| R10 | **`stucco_patch`** — parche de estuco rojo con agrietado | área, color, % de pérdida | decal/máscara + normal | verificar que se ve el borde de pérdida |

Orden sugerido: **R1 → R2 → R4 → R6 → R7** (con eso ya hay sala con bóveda, greca y escombro). Cada una necesita su control positivo y su vista de juicio orbitando la zona (feedback "orbitar antes de reportar").

Falta además (no es receta, es dato): **medir con un par de fotos de Chavín y Mitla con escala conocida** las [E] de las tablas A y E antes de gatear; y **decidir una sola altura/anchura de hilada** del muro para que R1 y R6 compartan.

## Licencias de imágenes

Todas descargadas con `Special:FilePath?width=1600`, verificadas con PIL, reescaladas a ≤1600 px y recomprimidas a JPEG q85. Las licencias **CC BY / CC BY-SA obligan a atribuir autor**; esta tabla es esa atribución. **No hay obra derivada incorporada al juego**; son referencias de estudio. Si alguna se usara como textura/base de un asset, **CC BY-SA obliga a licenciar la obra derivada igual**.

| Archivo local | Qué muestra | Autor | Licencia | Fuente |
|---|---|---|---|---|
| `tumba_chavin_galerias_castillo.jpg` | corredor interior de galería, Castillo (Chavín) | Dtarazona | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chavin_de_Huantar_Galerias_de_El_Castillo_06122009.jpg |
| `tumba_chavin_ingreso_galeria.jpg` | entrada a galería, aparejo de muro, Chavín | Dtarazona | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chavin_de_Huantar_Ingreso_a_Galeria_06122009.jpg |
| `tumba_chavin_cabeza_clava.jpg` | cabeza clava (museo) | Dtarazona | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Cabeza_clava_08_06122009.jpg |
| `tumba_palenque_boveda_maya.jpg` | bóveda en voladizo, interior | Ihiroalfonso | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:B%C3%B3vedas_Mayas.jpg |
| `tumba_palenque_templo_inscripciones.jpg` | Templo de las Inscripciones, exterior (verdín) | Rob Young | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Temple_of_the_Inscriptions_(8263759625).jpg |
| `tumba_mitla_grecas_interiores.jpg` | detalle de greca escalonada en sombra | Lsalgador82 | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Grecas_interiores_mitla.JPG |
| `tumba_mitla_grecas_columnas.jpg` | Grupo de las Columnas, muro con grecas | DavidConFran | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Grecas_Grupo_de_las_Columnas.JPG |
| `tumba_tiwanaku_templete_cabezas.jpg` | Templete Semisubterráneo, cabezas-espiga en sillares | Andrea Lastra | CC0 | https://commons.wikimedia.org/wiki/File:Templete_Semisubterr%C3%A1neo_%E2%80%94_Cabezas_talladas,_Tiwanaku,_Bolivia.jpg |
| `tumba_tiwanaku_pumapunku_H.jpg` | bloque en H, Puma Punku (junta de precisión) | Janikorpi | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Puma_Punku_H_profile_wall.JPG |
| `tumba_inca_sacsayhuaman_muro.jpg` | muro poligonal inca, Sacsayhuamán | Diego Delso | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Sacsayhuam%C3%A1n,_Cusco,_Per%C3%BA,_2015-07-31,_DD_05.JPG |

Cada archivo fue elegido tras mirar una hoja de contactos; la foto `Tumba de pakal, Chiapas.JPG` se descartó porque muestra el exterior de la pirámide, no la tumba. **Ninguna foto de la cripta de Pakal con licencia libre se encontró** (la cripta está cerrada al público desde 1994, [mayan.org](https://mayan.org/ruins/pakal-tomb/)): la bóveda se documenta con `tumba_palenque_boveda_maya.jpg`.
