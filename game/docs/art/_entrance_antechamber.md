# Antesala de entrada — diseño y decisiones

Estado: **funcional, sin terminar visualmente** (2026-08-01).
Código: `floor1_prairie.gd` → `_build_entrance()`, `_build_entrance_mound()`, `_entrance_shape()`.
Verificación visual: `scenes/dev/entrance_capture.tscn` → `tools/godot/entrance_capture/*.png`.

## Qué es

El jugador **emerge del subsuelo** hacia la pradera. Aparece dentro de una sala
enterrada; al fondo, el portal; sale caminando por un corredor a cielo abierto.

Canon (`_world_canon.md:81`): *"cada piso es portal dimensional... el piso ES otra capa
de realidad que la torre CONECTA"*. No hay distancia física hasta la Ciudad de la Torre,
así que el pasillo **no va** a la ciudad — el portal del fondo **es** la conexión. Joan
(2026-08-01): *"una antesala, no que sea una puerta que conecte ambas altiro"*. Es un
lugar donde se está, no un umbral que se cruza.

## Medidas (contra el maniquí de 1.80 m)

| | |
|---|---|
| Sala | 16 × 14 m, 4.5 m de alto (2.5 jugadores) |
| Vano | 6 m de ancho × 3.5 m de alto (pasan seis de frente) |
| Tierra sobre el techo | ~1.5 m |
| Corredor | 32 m hasta la pradera, pendiente media ~15° |

## La restricción que manda sobre todo

`TERRAIN_RESOLUTION = 96` sobre 600 m ⇒ **un vértice cada 6.25 m**.

Consecuencia dura, aprendida a los golpes en esta sesión: **el mapa de alturas no puede
sostener a la vez una sala enterrada y una puerta**. Cualquier transición del terreno
ocupa una celda entera, y una celda cae dentro de un cuarto de 16 m y lo atraviesa en
diagonal. Las dos ramas del intento:

- Dejar tierra sobre el techo ⇒ la ladera cruza **adentro** de la habitación.
- Sacar la transición de la habitación ⇒ no queda tierra encima: **galpón** sobre el pasto.

**Resolución**: el terreno se excava bajo TODA la huella construida (para que nunca se
meta adentro), y la tierra sobre el techo pasa a ser **geometría** (`_build_entrance_mound`),
que sí puede cortar a filo contra la fachada.

Corolario que costó otra ronda: **la geometría corta en seco solo si le alineás la costura
a mano**. La loma también se muestrea en grilla; una celda a caballo del filo generó una
rampa de tierra SÓLIDA dentro del vano y el jugador no podía salir caminando. Se construye
en dos tramos que se tocan exactamente en la fachada.

Y una tercera de la misma familia: la **boca se alinea a un vértice del terreno**. Si cae
entre dos, la interpolación contra el vecino sin excavar deja el umbral enterrado ~1.8 m
aunque el tallado sea correcto.

## Decisión de material — progresión por piso (Joan, 2026-08-01)

> *"como primer piso, no debería haber cemento quizás, o al menos unos pilares de madera
> más parecido a minas, y a medida que avance los pisos cambiarlo"*

La entrada del piso 1 **no es piedra trabajada ni hormigón**: es un **socavón de mina con
entibado de madera** — postes, dintel de viga, tablones. Rústico, humano, precario.

El material de la entrada **escala con el piso**, y es un termómetro de a dónde llegó el
jugador:

| piso | lenguaje de la entrada |
|---|---|
| 1 — Pradera | madera de entibado, socavón de mina |
| 2-5 | progresivamente más labrado / antiguo / ajeno — a definir |

### Las tres etapas de obra (Joan, 2026-08-19) — el "a definir" resuelto

> *"lo ideal sería que tuviera tres formas la antesala. Primero sería como una cueva bien
> picada a mano, la segunda quizá ya con unos soportes más bonitos, y la tercera ya un
> túnel hecho con techo, con luces, con antorchas, con todo, bien diseñado por humanos.
> Esas tres etapas las podríamos dividir según qué tanto avanzan los primeros cinco pisos."*

| etapa | pisos | qué es | qué la delata de un vistazo |
|---|---|---|---|
| **A — picada a mano** | 1-2 | socavón crudo. Roca irregular, entibado mínimo y desparejo, piso de escombro | ninguna superficie repetida, ningún ángulo recto en la roca |
| **B — apuntalada** | 3-4 | marcos regulares y bien cortados, tablonería completa, piso emparejado | el ritmo: los marcos se repiten a paso constante |
| **C — obra de ingeniería** | 5 | túnel con bóveda construida, luminarias fijas, revestimiento | la roca ya no se ve: la obra la tapa |

**Rieles y durmientes: recién en B** (Joan, 2026-08-19). Aparecen en las cuatro fotos
de mina de `_references/mine_adit/` y son la firma más fuerte de "esto lo hizo
alguien" — precisamente por eso **no van en el piso 1**. Un socavón picado a mano es
anterior a que alguien invierta en vía. Ponerlos en la etapa A gastaría de una la
señal que tiene que aparecer cuando el jugador sube.

### Ancho: 7 m, no 14 (Joan, 2026-08-19)

> *"que se sienta más como un túnel, quizás de un ancho se debía el cincuenta por
> ciento... que deje un poquito más grande que la puerta"*

`ENTRANCE_HALL_HALF_W` 7.0 → 3.5. Siete metros de sala alrededor de un vano de seis.

Y arregla un razonamiento que yo había hecho mal: descarté el marco de mina clásico
—postes de pared a pared con su collar— porque un marco de tres piezas es de galería
angosta y esto era una sala de 14 m. **A 7 m ES una galería.** Un túnel y un salón
piden carpintería distinta; angostarlo es el punto, no un efecto secundario.

### La regla que atraviesa todo esto

> Joan, 2026-08-19: *"todo lo que me hace es como muro, piedra, muralla, vigas, todo
> eso lo hace perfecto, y eso no es así en la vida real"*

**La irregularidad tiene que vivir en la GEOMETRÍA.** Una textura de tablas sobre una
losa plana es una foto de carpintería, no carpintería: se lee como empapelado. Vale
igual para el cascote (ruido suave da dunas, no roca partida — la piedra se fractura,
no se erosiona) y para el entablado (tablas de anchos distintos, cada una un
centímetro adelantada o atrasada respecto a la vecina, ninguna a plomo).

Es un **termómetro narrativo**: el jugador lee cuánto avanzó la civilización en la torre por
cómo está hecha la puerta, sin que nadie se lo cuente. Encaja con el modelo
Descubrimiento → Conquista → Civilización de `_world_seeds_postalpha.md`.

### ⚠️ Etapa de obra y nivel de acabado son EJES DISTINTOS

La confusión es fácil y saldría cara, así que queda escrita:

- **`ENTRANCE_FINISH` (0-3) = fidelidad de render.** Cuánta textura, cuánta irregularidad de
  malla. Es **temporal**: existe para que el owner elija un punto sobre una rampa, y una vez
  elegido se congela y la perilla desaparece.
- **Etapa A/B/C = calidad de la obra EN EL MUNDO.** Es **permanente**, narrativa, y escala
  con el piso.

Un piso 1 en etapa A tiene que estar **groseramente construido y completamente renderizado**:
roca picada a mano, con toda la textura y la luz que el motor pueda dar. Si las dos perillas
se funden en una, "el piso 1 es tosco" se convierte en "el piso 1 está peor renderizado", que
es un bug con cara de estilo.

Encaja con el gradiente de realidad P1→P5 de `_world_seeds_postalpha.md` (familiar → imposible)
y con §17 del canon: **silueta = geometría, superficie = textura**.

## El entibado (2026-08-07)

Construido en `_build_entrance()`. Material nuevo `_make_timber_material()`: mismo enfoque
de ruido triplanar que la piedra, con el ruido más fino y **aplastado en Y** (`uv1_scale =
(1.6, 0.12, 1.6)`), así en un poste parado se estira en veta vertical y en una viga
acostada bandea como marcas de sierra — un material cubre los dos casos sin UVs por pieza.
Sin normal map a propósito: la tabla tiene que leerse seca y plana contra la piedra picada.

Piezas: marco de bocamina (dos postes + viga cabecera + tornapuntas + umbral) parado en la
trinchera, tres marcos de mina repetidos adentro de la sala, y tablonería oscura tapando
jambas y dintel. Más dos faroles colgados de los postes.

### Tres cosas que sólo se vieron mirando

1. **El marco quedaba enterrado.** Plantado contra la cara de la fachada caía justo en la
   costura de la loma (`mouth.x + 1.0`), y al oeste de ahí hay tierra maciza. Desde el
   camino la entrada seguía siendo una ranura negra bajo una tapa de madera. Va **al este
   de la costura**, parado en la trinchera abierta, como el castillete de una bocamina:
   el marco adelante, el socavón detrás.
2. **Sin luz afuera no existe.** Construido y todo, el entibado era una mancha negra. Los
   dos faroles hacen el trabajo doble: recortan la madera y dicen "acá hay alguien" desde
   el otro lado de la pradera. Fue el cambio con mejor relación esfuerzo/lectura de todos.
3. **`COLOR_ROCK` ERA el cemento.** Gris neutro 0.502. Cambiado a `COLOR_BORDER` (piedra de
   caverna, ya en la paleta, más cálida y oscura). No hizo falta constante nueva.

### El pavimento, y por qué hundirlo lo empeora

Cada losa lee la altura del terreno en su centro, y entre dos centros el terreno **sube**.
Con las losas a tope el pasto asoma por la junta. Hundirlas (espesor 1.5, enterrando 1.4)
parecía la solución obvia y salió **peor**: abre cuñas de pasto entre losa y losa. Lo que
funciona es **solaparlas** (`slab_len * 1.2`) — si no hay junta, no hay por dónde asomar.
Más losas y más cortas (14, no 9) siguen mejor la curva.

Sigue siendo geometría de caja. Lo correcto aguas arriba es una tira de malla continua
muestreando el terreno, como `_mound_strip()`.

## La puerta cruzable (2026-08-08) — DOS bugs encadenados

Joan confirmó caminando: *"ahora sí es una puerta cruzable"*. Costó una noche y **nueve
hipótesis**, así que queda escrito con todo el detalle, porque el modo de falla se repite.

### Bug 1 — la loma no tenía hueco para la puerta

`_mound_strip()` generaba una superficie **continua** sobre toda la huella, el vano
incluido. Al oeste de la costura vale la altura natural (tierra sobre la sala) y al este el
fondo de la trinchera, así que el primer quad pasada la costura bajaba **~7.4 m en 1.5 m**:
una pared de tierra casi vertical parada en la puerta, con colisión. Se saltean los quads
dentro de la huella del vano (`MOUND_DOOR_HALF = 4.0`). No hay que tapar el hueco: por ahí
se ve el vano, que es lo que tiene que verse.

**Lo encontró Joan mirando el juego**: *"hay que hacer un hoyo en esa malla o no?"*. Y era
mi hipótesis 6, descartada porque la sonda dio salida byte-idéntica — una sonda que tiraba
un rayo hacia ABAJO y chocaba contra la viga de madera antes de llegar a la tierra.
**Cuando descartás una hipótesis por una medición, verificá que esa medición podía verla.**

### Bug 2 — el canto de 0.30 m era PARED para el motor

`_entrance_shape()` tallaba el terreno bajo la sala a `_entrance_floor_y - 0.3` (margen para
que la tierra no asomara sobre la losa). La cara superior de la losa está en
`_entrance_floor_y`, así que donde la losa termina —en la boca, justo al salir— quedaba un
canto vertical de 0.30 m. **Godot trata como pared todo lo más empinado que
`floor_max_angle` (45°)**, y ese canto medía **71.6°**. Margen a 0.02 m: conserva la guarda
anti z-fighting y deja de ser obstáculo. Pendiente del vano **71.6° → 35.2°**.

### Por qué nueve hipótesis y seis sondas no lo vieron

**Todas preguntaban "¿hay espacio acá?" cuando la pregunta era "¿un cuerpo puede CAMINAR
por acá?".** En un canto empinado esas dos difieren justo donde importa: el espacio está
vacío y el motor igual no te deja pasar.

Seis instrumentos devolvieron lecturas seguras y equivocadas, **ninguno tiró error**:
cápsula apoyada en `get_terrain_height` (no describe la superficie de colisión); inventario
de colisionadores recorriendo sólo hijos directos (listó 1 cuerpo de 26); `Input.get_vector`
con `"move_back"` en vez de `"move_backward"` (devuelve 0 en silencio); stdout de Godot
buffereado hasta cerrar el proceso; `CharacterBody3D.velocity` = velocidad DESEADA, no
lograda; y el rayo hacia abajo tapado por la viga. Más un error de proceso: **cuatro
ventanas del juego abiertas a la vez** escribiendo al mismo `user://` con líneas
intercaladas — lo delató el latido que se puso "por si el detector está roto".

### La regla, en el gate

`game/tests/test_entrance_walkable.gd` rompe el build si el vano tiene pendiente >45° o si
una cápsula del tamaño del jugador (r=0.35, h=1.8, **pies sobre la superficie de colisión
real**) choca al cruzar. Verificado en los dos sentidos: reintroducir el `0.3` lo hace
fallar imprimiendo el ángulo medido.

Joan lo puso como regla de diseño, no como ticket: *"si haces una puerta, lo lógico es que
pueda pasar por ella, sin estamparme o imposibilidad de avanzar"*. Por eso vive en CI y no
en un doc.

**Sondas permanentes** en `scenes/dev/entrance_capture.gd`: barrido 2D de cápsula, despeje
de techo, barrido ancho, techo de loma, `get_terrain_height` vs raycast, cruce cada 5 cm y
pendiente del suelo. **`enemies` quedó ENCENDIDO** — estaba en `false` "para que no salgan
en las fotos" y eso hacía que el harness midiera un nivel que nadie juega.

## Pendientes

1. ~~**El vano queda tapado por la loma desde afuera.**~~ RESUELTO arriba (bugs 1 y 2).
   Texto original conservado por contexto: Con el marco ya resuelto, la captura
   `02_outside_ramp.png` muestra que detrás del entibado se ve **tierra iluminada**, no el
   hueco negro de la puerta: sólo asoma una franja oscura abajo. Desde adentro el vano está
   limpio (`00_inside_to_exit.png`), así que es la rama `carved` de `_mound_height()` la que
   no baja hasta `_entrance_floor_y` en la garganta. **Medir antes de tocar** — esta costura
   ya generó dos bugs de bloqueo, no conviene ajustarla a ojo.
2. **Facetas** visibles en el sombreado del talud — la malla usa paso de 1.5 m.
3. **Pavimento como malla continua** en vez de losas solapadas (arriba).
4. El muro este visto desde adentro es una mancha negra: la tablonería de jambas y dintel
   no recibe luz. Falta un farol cerca de la boca, del lado de adentro.

## Hecho

- ~~Los taludes tapan la entrada~~ — la garganta mantiene el ancho de fachada por
  `ENTRANCE_THROAT_FRAC` (18% del run) y después el corte se abre **en dos ejes a la vez**:
  ancho y pendiente. Abrir sólo el ancho dejaba un cajón de paredes rectas. De paso los
  costados quedan bajo el `floor_max_angle`, así que ahora se sale caminando por ellos.
- ~~Entibado de madera en vez de las cajas grises~~
- ~~El pavimento es una cinta blanca lisa~~ — ya no es blanca ni discontinua; falta la malla.
