# turtle_terrestrial — motion reference: the walk

**Fuente**: clip de stock (Shutterstock, 0:35, con marca de agua), tortuga
terrestre tipo *Testudo* caminando sobre gravilla a pleno sol. Joan lo pausó en
5 momentos — 0:06, 0:11, 0:18, 0:22, 0:26 — y los pasó el 2026-08-24 para
comparar contra nuestro clip `move`.

**Los pantallazos no sobrevivieron** (Joan: *"yo no tengo ya esas imágenes, eran
pantallazos"*), así que esta lectura ES la referencia. Está escrita con el
detalle suficiente para construir contra ella sin la imagen: si algo acá no
alcanza para decidir un parámetro, hay que volver a buscar el clip, no adivinar.

## Movimiento / Feel — el campo primario

**1. La pata en apoyo BARRE HACIA ATRÁS, y termina detrás del caparazón.**
En 0:11 y en 0:26 la pata trasera queda extendida por detrás del borde posterior
del carapacho, con los dedos arrastrando. No es que la pata se levante y vuelva:
el pie se planta adelante, el cuerpo pasa por encima, y el pie termina atrás.
Joan lo dijo antes de mandar el clip, con las mismas palabras que usaría un
animador: *"esa misma se tiene que tirar hacia atrás por el movimiento de
arrastre... funcionar de pivote, de apoyo, y a medida que hace el impulso para
moverse, esa pierna derecha termina quedando atrás"*.
→ **El pie plantado viaja hacia atrás exactamente lo que el cuerpo avanza.**
   Si no, patina. Es EL número de un ciclo de caminata.

**2. El caparazón NO rebota.** En los 5 fotogramas la altura del carapacho sobre
el suelo se ve constante; el cuerpo va planeando. Lo que se mueve son las patas.
→ Cualquier bombeo vertical es de amplitud muy chica, y atado a las pisadas.

**3. El pie casi no despega.** Roza la gravilla; el vuelo es bajo y largo, no
alto y corto. Una pata que sube un tercio de la altura del cuerpo es un caballo
al trote, no un galápago.

**4. Postura BAJA y esparrancada.** Plastrón cerca del suelo, codos hacia
afuera, patas cortas y gruesas. La silueta es un domo apoyado, no un domo sobre
columnas: entre el borde del caparazón y el suelo casi no hay luz.

**5. La cabeza va adelante y NIVELADA.** Sale del caparazón horizontal y no
cabecea con los pasos: acompaña al cuerpo como bloque.

## Forma / Silueta — lo que agrega para el carapacho

Los escudos se leen con **anillos de crecimiento concéntricos por placa**: cada
vertebral y cada pleural tiene su propio centro y sus propios anillos, y los
surcos entre anillos son lo que dibuja el patrón. NO hay ningún patrón radial
compartido desde el centro del caparazón. Es la confirmación visual de por qué
el carapacho se rehace a partir de los escudos y no pintando sobre una esfera.

## Qué capturar (para DP)

| | Tortuga real | Nuestro `move` (medido 2026-08-24) |
|---|---|---|
| arrastre del pie en apoyo | barre hasta detrás del caparazón | **0.0 mm** |
| altura del pie en vuelo | roza el suelo | 76.8 mm = 32% de la altura del cuerpo |
| bombeo del cuerpo | imperceptible | 4 rebotes por ciclo |
| postura | baja, codos afuera | patas columnares, cuerpo alto |
| cabeza | nivelada, sin cabecear | (sin key en `move`) |

## Criterio de éxito, definido ANTES de construir

- `arrastre en apoyo` **≠ 0** y del orden del avance del cuerpo por ciclo.
- elevación del pie **≤ 10%** de la altura del cuerpo.
- bombeo vertical **≤ 5 mm**, y con la misma frecuencia que las pisadas.

Medibles con `game/tools/blender/turtle/_turtle_anim_strip.py`, que los imprime.
