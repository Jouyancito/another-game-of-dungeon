# ui_anim_jinx — animación de UI y selección de personaje (2026-08-13)

**Joan dijo:** *"es sobre una animación de UI. Me agrada esa animación, está bastante bonita... ¿se puede usar como la selección de personaje? o en menús... más podría ser quizá para selección de personaje, cuando te lo creás. En vez de mover como la cámara por la habitación, como en algún momento lo pensé, por el juego Blade. Estaría bueno esto de que mostrara como el ambiente de cada personaje. Y con su selección. O sea, en ambientes de este personaje."*

Referencia #2 de siete. El video se titula literalmente **"Interactive UI design for Jinx"**, y termina mostrando un Main Menu con arte de Jinx.

## Imágenes

| # | Qué se ve |
|---|---|
| 01 | Título "Interactive UI design for Jinx" sobre un editor con paneles de color animándose |
| 02 | Los paneles cambian de paleta: amarillo/cian, después rojo/cian, en transiciones de barrido |
| 03 | Main Menu terminado con arte de Jinx, y debajo un grafo de nodos del sistema de animación |

## Síntesis

### Idea
La UI no es un fondo estático con botones encima: los **paneles de color son el elemento animado**. Entran, se reordenan y cambian de paleta con barridos rectos y rápidos. La animación no decora — es lo que comunica que cambió la selección.

### Colores
Paleta agresiva y saturada por bloques planos: amarillo, cian, rojo. Sin degradés. El contraste entre bloques hace el trabajo que en otra UI harían bordes y sombras.

### Movimiento / feel
- Barridos **rectos**, no fades. Un panel se corre y descubre otro.
- Rápido y seco. Nada rebota ni se demora.
- El cambio de paleta acompaña al barrido, no ocurre aparte.

### Decisión que cierra para Dungeon Party
Joan descartó explícitamente la cámara moviéndose por una habitación (estilo Blade) para la selección de personaje. Lo que quiere en su lugar: **cada personaje mostrado en SU ambiente**, con la selección como cambio de panel animado.

Eso baja el costo enormemente — no hay que modelar una sala navegable; alcanzan fondos por personaje y transiciones de panel. Y el juego ya tiene `character_select` D2-style con preview 3D, así que es una evolución, no un sistema nuevo.

### Qué capturar
1. Bloques de color plano como protagonistas, no como marco.
2. Transición por barrido recto, corta.
3. Un ambiente por personaje detrás del panel, no una sala compartida.
4. La paleta cambia con la selección: cada personaje trae la suya.

### Nexo con la referencia #3
El video es literalmente de Jinx, y en la #3 Joan pide neón estilo Jinx / Borderlands para el cráneo. Las dos referencias apuntan al mismo registro visual.

## Fuente
Grabación de pantalla, sesión `2026-08-13_03-24-58` (168 frames, Instagram). Sesión original borrada por la auto-limpieza de `capturar.ps1`; estas hojas son la única copia.
