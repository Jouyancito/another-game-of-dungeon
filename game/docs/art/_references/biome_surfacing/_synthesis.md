# biome_surfacing — cómo los juegos resuelven suelo, roca y árbol

Pasadas por Joan el 2026-08-08: *"referencias como de diferentes juegos en cómo usan
textura de suelo, de la roca, de los árboles, para que te des una idea de lo que yo
espero"*. Y la advertencia de calibración, textual: *"hay algunos que son triple A, que
claramente no te va a pedir la misma calidad, pero por ejemplo Skyrim ya es un juego
antiguo y tiene muy buena renderización, así que vale buena referencia. Valheim también."*

Distinto de `prairie_ecology/`: aquellas eran **fotos de pradera real** (densidad, color,
masa). Estas son **soluciones de juego** — qué hace un motor cuando tiene que dibujar esto
en tiempo real. La foto dice qué; el juego dice cómo.

## La regla de modelado que las acompaña (Joan, 2026-08-08)

Es una convención de trabajo, no un comentario sobre estas imágenes. Textual:

> *"Si vas a modelar un junco o una de estas plantas que hay al lado de los ríos, vas a
> modelar solamente uno, o variedades de uno. Y ese uno lo vas a agrupar. Esa agrupación
> no debería ser unos unos unos unos, sino que debería ser varias variaciones en diferentes
> formas. Se puede hacer randomizada, quizás entre un grupo nomás, más estricta, pero
> pueden tener diferente altura, algunas quizás rotas."*

Traducido a pipeline:

1. El motor modela **una planta**, no un macizo.
2. Modela **variantes de esa misma planta** — alta, baja, doblada, quebrada, seca.
3. La **agrupación** muestrea entre esas variantes. Un grupo NO es la misma malla repetida.
4. La variación vive **dentro** del grupo, no sólo entre grupos.

La diferencia contra lo que hay hoy: `_scatter_clumps` agrupa, pero repite **una sola
malla** con jitter de escala y rotación. Escalar una planta uniformemente no es lo mismo
que otra planta: el ojo lee la silueta repetida igual, sólo que más grande. La variación
tiene que ser de GEOMETRÍA, y eso se hornea en el pack, no en el scatter.

## Qué muestra cada referencia

| Archivo | Juego | Qué aporta |
|---|---|---|
| `_valhalla_poppy_meadow` | AC Valhalla | Masas monoespecie de metros: amapola roja, margarita blanca, pasto dorado, cada una su mancha |
| `_rdr2_tall_meadow` | RDR2 | Altura del pasto contra el personaje (cintura/pecho) + neblina atmosférica en la montaña |
| `_eldenring_grass_boulders` | Elden Ring | Bloques de roca sembrados en pasto a media pierna; árbol de copa amarilla como acento |
| `_eldenring_open_ground` | Elden Ring | Suelo abierto de combate — cuánto se PUEDE vaciar sin que muera |
| `_skyrim_river_bank` | Skyrim | Banda ribereña por capas: agua → guijarro → junco → helecho → bosque |
| `_skyrim_riverwood_village` | Skyrim | Musgo en cara superior de roca y techo; roca de primer plano con caras planas grandes |
| `_skyrim_backlit_grass` | Skyrim | Pasto a CONTRALUZ — traslucidez de la hoja, el campo se enciende |
| `_survival_forest_rocks` | survival 2026 | Suelo de bosque oscuro, roca grande como obstáculo de navegación |

## Lo que hay que capturar

1. **Masa monoespecie.** La amapola de Valhalla confirma la decisión de agrupar por especie:
   una mancha es una especie repetida, no una mezcla. Ya implementado en `_scatter_clumps`.
2. **Altura del pasto contra el jugador.** En RDR2 y Valhalla llega a la cintura o al pecho.
   La banda alta de `FLORA_TARGET_HEIGHT` (0.85–0.95 m contra 1.80 m de jugador) queda a la
   cadera: está en el rango, tirando a conservadora.
3. **Traslucidez a contraluz.** `_skyrim_backlit_grass` es la única imagen del set donde el
   pasto se ve *lindo* en vez de correcto, y la diferencia es una sola cosa: la luz pasa a
   través de la hoja. Hoy el shader del tapiz es opaco puro. Es la palanca más barata que
   queda para "que sea bonita".
4. **Musgo por orientación, no por textura.** En Skyrim el musgo está en la cara de ARRIBA
   de la roca y en la de sombra, no envolviendo la piedra. Es una regla de normal (Y+), no
   un mapa pintado — barato y correcto en el motor.
5. **Roca con caras planas grandes.** La roca de primer plano de Riverwood tiene planos
   amplios y aristas netas, no ruido parejo. El `rock_pack` M3 usa Perlin doble capa; le
   falta el corte plano.
6. **Banda ribereña por capas.** Agua → guijarro → junco → helecho → pasto. Hoy el arroyo
   tiene guijarros y nada más.
7. **Neblina de distancia.** Presente en RDR2 y en las dos de Skyrim. Sigue sin existir en
   el piso 1.

## Calibración honesta

Valhalla, RDR2 y Elden Ring son presupuestos que no tenemos y no es el objetivo copiarlos.
Skyrim (2011) y Valheim son la vara real, y las dos ganan por lo mismo: **no por densidad de
polígono sino por luz y por capas**. El pasto de `_skyrim_backlit_grass` es geometría simple;
lo que lo hace funcionar es el contraluz. Eso encaja exacto con el canon de estilo ya
acordado (`_art_canon.md` §17, modelo Valheim): geometría low-poly simple, materiales ricos,
luz y atmósfera dramáticas.

## Fuente

Capturas de video y screenshots pasadas por Joan en chat, 2026-08-08. Sin atribución
conocida; referencia visual interna, no van al juego.
