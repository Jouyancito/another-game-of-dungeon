# Reference — `mine_adit`

Base name: **`mine_adit_`**. Relacionado: `[[rock_poe]]`, `[[village_palisade]]`, `[[dungeon_interior]]`.

## Fuente

Ocho imágenes que pasó el owner (Joan) el 2026-08-19, en **dos tandas que él mismo separó**,
y la separación es el dato más útil del lote:

**Tanda A — cuevas naturales** (*"imágenes de pruebas que servirían para cachar cómo serían"*):
- `mine_adit_natural_mouth_jungle_scale.png` — boca enorme desde adentro, persona diminuta al centro
- `mine_adit_natural_slot_overhang_valley.png` — ranura horizontal irregular sobre un valle
- `mine_adit_natural_fracture_slabs_passage.png` — pasaje entre lajas de fractura
- `mine_adit_natural_warm_arch_stalactites.png` — arco cálido con estalactitas

**Tanda B — minas hechas por humanos** (*"cuevas de minas, que son hechas por humanos"*):
- `mine_adit_hewn_horseshoe_rails_people.jpeg` — **la clave del lote**: galería con rieles y mineros
- `mine_adit_hewn_tunnel_rails_lamps.png` — túnel vertical con rieles, balasto y lámparas
- `mine_adit_hewn_timber_walkway_lamps.png` — pasarela de madera hacia la profundidad
- `mine_adit_stylized_blue_warm_lamp.png` — la misma escena **en clave de arte de juego**

**La antesala del piso 1 se rige por la tanda B.** El canon la fija como socavón con entibado
(`_entrance_antechamber.md`), no como cueva natural. La tanda A sirve para el borde del mapa y
para bocas de cueva de otros pisos.

## Qué muestran

**La forma, y es la corrección más grande.** `hewn_horseshoe` enseña el perfil sin ambigüedad:
**herradura**. Las paredes suben rectas apenas un tramo corto y enseguida **curvan hacia la
bóveda**; no hay una sola esquina. Ninguna de las cuatro minas tiene sección rectangular. Lo que
se había razonado desde "una sección rectangular no se sostiene" queda confirmado contra foto.

**La superficie NO es granular.** Es **ondulación grande** —bultos de 0,3 a 1 m— cruzada por
**líneas de fractura largas y oscuras** que corren metros enteros por el techo. Grava y ripio
aparecen sólo en el PISO, como balasto entre durmientes. Una textura de gravilla en la pared es
exactamente el error opuesto al que muestran las fotos.

**El agua manda.** Escurrimiento vertical en las paredes, manchas de óxido de hierro, y el piso
siempre más oscuro y húmedo que la pared.

**La luz es puntual y escasa.** Lámparas cada tantos metros haciendo charcos; entre charco y
charco, negro. En `stylized_blue_warm_lamp` esa lectura se lleva a arte de juego: **dos
temperaturas**, ámbar de la lámpara contra azul frío de la profundidad, y roca en planos
angulares grandes.

**Rieles y durmientes en las cuatro de la tanda B.** Es la señal de lectura instantánea de
"esto lo hizo alguien", más fuerte incluso que el entibado.

## Colores — medidos, no estimados

Parche de pared, promedio RGB → HSV:

| Referencia | RGB | H | S | V |
|---|---|---|---|---|
| `hewn_horseshoe_rails_people` | (121, 86, 57) | 27° | 0.53 | 0.47 |
| `hewn_tunnel_rails_lamps` | (163, 139, 99) | 38° | 0.39 | 0.64 |
| `hewn_timber_walkway` (zona oscura) | (32, 22, 12) | 30° | 0.62 | 0.13 |
| `natural_fracture_slabs` (tanda A) | (124, 120, 118) | 20° | **0.05** | 0.49 |
| **`COLOR_BORDER` nuestro** | (87, 73, 59) | 30° | **0.32** | **0.34** |

**El tono nuestro está bien** (30° contra 27–38°). Lo que está mal es que la roca del juego es
**más apagada y más oscura que cualquier mina real de la tanda**: S 0.32 contra ~0.45, V 0.34
contra ~0.55. Objetivo: **H 30°, S 0.45, V 0.50**.

Y ojo con la tanda A: la laja de fractura es **gris** (S 0.05). Es otra roca —pizarra— y otro
piso. No mezclar las paletas.

## Qué capturar — para la antesala

1. **Sección de herradura.** Pared corta y recta, después bóveda. Cero esquinas a 90°.
2. **Ondulación grande + grietas largas.** No gravilla. Los rasgos de la pared se miden en
   decímetros, y las grietas cruzan metros.
3. **Subir saturación y valor de la roca** a S 0.45 / V 0.50, manteniendo el tono ocre.
4. **La grava va al piso**, como balasto — es donde las fotos la ponen.
5. **Lámparas a intervalos** haciendo charcos, con negro entre medio. Ya hay dos afuera; adentro
   la sala está iluminada pareja, que es lo contrario.
6. **Rieles y durmientes**: la firma de "hecho por humanos", barata y legible.
7. **Escurrimiento vertical y óxido** en la pared; el piso más oscuro que la pared.

## Qué NO tomar de acá

- Las **estalactitas** de `natural_warm_arch`: son de cueva natural y de disolución kárstica.
  Una galería excavada no las tiene, y ponerlas contradice "lo hizo alguien".
- El **gris** de la tanda A en la paleta de la antesala.
- La escala catedralicia de `natural_mouth_jungle`: la antesala mide 4,5 m de alto.
