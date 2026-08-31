# prairie_nature_ingame — naturaleza realista in-game (monte seco: eucaliptos, pasto en matas, peñascos)

**Joan dijo (2026-08-28):** *"lo que a mí me interesa es el ambiente que tiene el dibujo, la
naturaleza: cómo son los árboles, cómo el pasto, cómo son las piedras. Lo encuentro muy, muy
adecuado. Ojalá esta pudiéramos realizar en la pradera. Y la diferencia [entre el entorno realista
y los personajes simples] se ve muy, muy bien."*

→ Manda sobre **cómo se ven árboles, pasto y rocas EN JUEGO** (no en render de Blender): un
entorno realista de estilo fotogramétrico conviviendo con personajes de formas simples y colores
planos. Seis capturas de gameplay de un juego cooperativo (cuerda/gancho + teleférico amarillo,
personajes esféricos rojos); título sin identificar.

| File | Qué muestra |
|---|---|
| `01_rope_gully_boulders` | quebrada con peñascos grises grandes, pasto seco dorado, arbusto verde oscuro; cuerda azul del jugador |
| `02_gully_shrubs_eucalypt` | ladera con eucaliptos de tronco pálido y retorcido, copas ralas, matorral verde-oliva, roca redondeada con liquen; cielo azul con cúmulos |
| `03_topdown_cablecar_rock` | cenital: teleférico amarillo sobre roca oscura con musgo y pasto; sombra dura del mediodía |
| `04_cabin_view_treeline` | desde la cabina: línea de árboles contra cielo, mar al fondo, peñasco a la derecha, personaje rojo simple en primer plano |
| `05_cabin_view_canopy` | copas ralas de eucalipto a contraluz, ramas finas visibles entre hojas |
| `06_cabin_view_boulders` | ladera de peñascos redondeados apilados con matorral entre ellos |

## Idea

Es **monte seco** (sclerophyll: eucalipto + granito + pasto de secano), no pradera húmeda — y por
eso lee tan "natural": la vegetación es **rala**, se ve el suelo, las copas dejan pasar cielo, las
rocas son masas grandes redondeadas y no piedritas sueltas. Lo que Joan reconoce como "adecuado" es
**la escala y el espaciado**, más que las especies. Y la lección compositiva: **entorno realista +
personajes simples de color plano** conviven bien; el contraste ayuda a leer a los jugadores.

## Cómo son (cada frase termina en un número o una orientación)

**Árboles (eucalipto)**
- Tronco **pálido** (gris-crema, con parches de corteza que se pela), **retorcido**: cambia de
  dirección 2-3 veces entre el suelo y la copa, inclinación 10-25° respecto de la vertical.
- Copa **rala**: se ve cielo a través en ~40-60 % de su área; hojas colgantes en racimos en las
  puntas, ramas finas visibles entre racimos. Altura 8-15 m, copa arranca a ~1/3 de la altura.
- Densidad: árboles **separados** 6-15 m entre sí; nunca bosque cerrado.

**Pasto**
- **Matas** (tussocks) de 30-50 cm, no alfombra continua: entre matas hay tierra y roca visibles.
- Color **seco**: dorado-paja con base verde-oliva; verde sólo en el arbusto y cerca de la sombra.
- Sin flores marcadas; la variación es por altura y color de mata, no por especie.

**Rocas**
- **Peñascos** de 1-4 m, redondeados (granito erosionado), apilados o semienterrados, con liquen
  gris-verde en la cara de sombra y musgo en las grietas.
- Van en **grupos** de 3-8, en laderas y quebradas; la roca chica suelta casi no existe.
- Escala de textura: grano y grietas visibles a 5 m (fotogrametría o tiles de 2-4 m).

**Arbustos**
- Matorral verde-oliva oscuro de 1-2 m, denso, en las hondonadas y al pie de las rocas.

**Luz / cielo**
- Sol **alto** (mediodía): sombras cortas y duras, contraste alto, AO fuerte bajo rocas y matas.
- Cielo azul saturado con cúmulos blancos definidos; sin bruma cerca, bruma sólo en el horizonte
  lejano (mar/lomas).

**Personajes**
- Esferas y cápsulas, colores planos saturados (rojo, amarillo, azul), sin textura. La lectura de
  jugador viene del **contraste** con el fondo detallado.

## Qué capturar para la pradera (traducido a nuestro floor1_prairie)

| # | Ref | Nuestro | Gap |
|---|---|---|---|
| 1 | árboles ralos, separados 6-15 m, copas con 40-60 % de cielo | pool `tree_pack` con copas de racimos cerrados y scatter más denso | **espaciado + copa rala**: bajar densidad, abrir copa (menos racimos, más rama visible) |
| 2 | pasto en matas con suelo visible | `_build_grass_carpet` alfombra continua 120k briznas | **matas**: agrupar briznas en tussocks con claros; tint seco-dorado en las zonas altas/secas, verde en húmedas (nichos de `FLORA_NICHES`) |
| 3 | peñascos 1-4 m en grupos, liquen en sombra | `rock_pack` | verificar escala y agrupamiento; liquen/musgo por orientación (cara norte/sombra) |
| 4 | sol alto, sombras duras, AO fuerte | caverna-día (0df661e): sol + fog pálida | subir contraste de sombra, AO más fuerte bajo rocas y matas |
| 5 | entorno realista vs personajes simples | clases con techo Skyrim | ya alineado: personajes más simples que el entorno es un rasgo, no una deuda |

**Ojo con la ecología**: esto es monte seco. En una pradera con ríos y humedales (dirección de Joan,
2026-08-28), este look aplica a las **zonas altas y secas** (laderas, afloramientos); las bajas
llevan pasto verde continuo y árboles ribereños. Cruzar con `prairie_ecology/` y los nichos de
humedad — no convertir toda la pradera en secano.

## Métrica de éxito (antes de construir)
Desde 1,7 m en una zona alta del piso 1: en un frame a 30 m se cuentan ≤ 6 árboles y en ≥ 40 % del
área de copa se ve cielo; el suelo muestra tierra/roca entre matas en ≥ 25 % de los píxeles de suelo;
los peñascos visibles miden ≥ 1 m y aparecen en grupos de ≥ 3.

## Fuente
Seis capturas de gameplay de un reel (juego cooperativo de cuerda + teleférico, título sin
identificar). Relacionadas: `prairie_ecology/`, `prairie_scene_scatter/` (técnica por elemento),
`tree_poe/`, `rocks/`, `rock_poe/`, `biome_landscape/`.
