# turtle_aquatic — tortuga ACUÁTICA (2026-08-24)

Hermana de `_references/turtle_terrestrial/`. **Este es el eje que sigue nuestro mob**, decidido
en `_references/turtle/_synthesis.md`: galápago de borde de agua.

## Imágenes

| # | Archivo | Qué muestra |
|---|---|---|
| 01 | `01_game_sea_turtle_beach_stylized.png` | Tortuga marina estilizada de juego móvil. Caparazón liso rosado, **piel verde con escamas grandes y legibles** en cuello y aletas |
| 02 | `02_game_sea_turtle_underwater.png` | Marina bajo el agua. **Escudos muy marcados** verde/negro y **moteado de alto contraste** en cabeza y aletas |
| 03 | `03_alligator_snapping_turtle_britannica.png` | **Tortuga caimán** — el extremo agresivo del eje. Lámina científica con escala de 30 cm |

## ESTRUCTURA

### Caparazón: BAJO e hidrodinámico
| Parámetro | Valor |
|---|---|
| `SHELL_H_LEN_RATIO` | **0,28–0,32** (vs 0,60–0,75 de la terrestre) |
| `SHELL_SILHOUETTE` | plato/lente, no domo |
| `SCUTE_PROFILE` | **placas planas** con costura marcada — sin las pirámides de la terrestre |

### La tortuga caimán — un mob distinto, no una variante de color
La ref 03 es la más útil para el juego, porque es **un depredador** y su anatomía lo dice:

| Rasgo | Valor | Por qué importa |
|---|---|---|
| `KEELS` | **tres quillas de púas** recorriendo el carapacho de adelante a atrás | silueta agresiva, dentada — nada que ver con el domo liso |
| `SCUTE_PATTERN` | escudos **radiados**, como abanicos, no anillos concéntricos | textura propia |
| `HEAD_SIZE` | **enorme** respecto del cuerpo, no cabe en el caparazón | por eso NO se retrae: su defensa es morder |
| `BEAK` | pico ganchudo, muy curvo, boca que abre casi 90° | |
| `TAIL` | **larga y con cresta**, tipo cocodrilo | otro perfil completo |
| `SKIN` | tubérculos y púas carnosas en cuello y patas | |
| escala | 30 cm de carapacho (barra en la lámina) | |

**Si el roster quiere una tortuga agresiva, es ESTA, y no se hace agrandando la nuestra.** La
que tenemos no ataca porque puede esconderse; la caimán ataca porque no puede.

### Piel y textura (las dos refs de juego)
- **Escamas grandes y legibles** en cuello y patas — no piel lisa. En 01 son placas nítidas;
  en 02 son moteado de alto contraste.
- **Contraste fuerte** entre caparazón y piel: la piel es más clara y más saturada.
- Patas: **palmeadas con garras** visibles (01), o aletas planas si es marina (02).

## Qué capturar para nuestro mob
1. **Escamas en cuello y patas** — hoy nuestra piel es un tono liso por región. Es la mejora de
   textura más grande disponible sin salir de vertex colour.
2. **Más contraste** caparazón ↔ piel.
3. Garras visibles en el pie palmeado (ya están).
4. Mantener el caparazón bajo — confirmado contra la terrestre.

## Decisión pendiente para Joan
Las tres refs cubren **tres animales distintos**: marina estilizada, marina realista y caimán.
Nuestro mob es un **galápago de borde de agua**, que es un cuarto. Si querés que el roster
tenga más de una tortuga, la caimán es la que más aporta — es un depredador con silueta propia
y una razón anatómica para no esconderse.

**Fuente/fecha**: capturas de juegos móviles y lámina de Encyclopædia Britannica, aportadas por
Joan, 2026-08-24.
