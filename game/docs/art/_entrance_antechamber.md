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

## Pendientes

1. **El vano queda tapado por la loma desde afuera.** Con el marco ya resuelto, la captura
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
