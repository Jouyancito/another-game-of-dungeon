# flower_variety — dos escalas de flor, y una por piso

Pasadas por Joan el 2026-08-08, ya ordenadas por piso: *"sobre flores, en este caso te daré
referencias de varios pisos, te los dejo igual ordenados"*.

## La regla de las dos escalas

Textual: *"estas flores como son bien detalladas, podrían ser unas grandes detalladas y otras
pequeñitas que sea en más volumen, para no saturar tampoco"*.

Eso resuelve la tensión entre detalle y presupuesto, y es exactamente cómo se ve una pradera real:

- **Flor grande y detallada** — pocas, con geometría de pétalo de verdad. Se leen de cerca, son
  las que el jugador mira. Candidatas a **item recogible** (Joan: *"podrían ser items
  recogibles"*), lo que además justifica el detalle: un item se mira en la mano.
- **Flor chica en volumen** — muchas, casi sin geometría, existen para dar MASA DE COLOR a
  distancia. No se miran de cerca nunca.

El error actual es que las doce especies están en un solo tamaño intermedio: ni se leen de cerca
ni hacen masa de lejos.

## Piso 1 — pradera

| Ref | Qué aporta |
|---|---|
| `_p1_orange_poppy_field` | **Naranja saturado en masa continua** sobre pasto verde. Es el color que más falta hoy. La flor tiene 4 pétalos anchos y copa abierta. |
| `_p1_perennial_bed_render` | Espigas verticales violetas + pompones rosados + margarita blanca. Tres alturas conviviendo. |
| `_p1_meadow_planting_tool` | Densidad de plantación real, con rosa y blanco repartidos en masa. |

Joan sobre lo que falta hoy: *"faltan algunas flores, amarillas naranjas o lilas, estaría bueno y
uno que otro color"*. Amarillo y violeta ya existen en el `flower_pack`; **naranja no existe**, y
es el dominante de la referencia más fuerte del set.

## Piso 2 — bosque

Otro registro por completo: sombra, poca luz, flor rara y detallada.

| Ref | Qué aporta |
|---|---|
| `_p2_lily_of_the_valley` | Campanillas blancas colgando de un tallo arqueado, hoja ancha lanceolada. Silueta de sotobosque perfecta. |
| `_p2_orchid_macro` | Pétalo con VENAS — patrón radial rojo sobre amarillo. Es detalle de textura, no de geometría. |
| `_p2_blue_spotted_bells` | Azul con lunares blancos y lengüeta naranja. Rareza que se lee como "esto no es de acá". |
| `_p2_blue_orange_lanterns` | Farolito estriado azul con corona naranja. Candidato fuerte a item. |
| `_p2_exotic_trio` | El extremo del registro raro; referencia de cuánto se PUEDE empujar, no objetivo. |

Encaja con el gradiente de realidad P1→P5 de `_world_seeds_postalpha.md`: la pradera tiene flor
reconocible, el bosque ya empieza a tener flor imposible.

## Qué capturar

1. **Naranja saturado en masa** para el piso 1. Es el hueco más grande de la paleta.
2. **Dos presupuestos de geometría** por especie, no uno.
3. **Silueta colgante** (campanilla) para el piso 2 — hoy todas las flores miran hacia arriba.
4. **Venas y lunares** se resuelven con vertex color, no con más triángulos.
5. Las candidatas a item recogible se modelan pensando en que se van a ver **en la mano**, de
   cerca, fuera del bioma.

## Fuente

Referencias de internet pasadas por Joan en chat, 2026-08-08. Referencia visual interna.
