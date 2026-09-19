# turtle_terrestrial — tortuga TERRESTRE (tortoise) (2026-08-24)

**Aportadas por Joan**: *"referencias de tortugas en los juegos y diferentes fenotipos... hay
tanto de tierra como de agua, así que sería bueno que las puedas separar. Trata de tomar en
cuenta el tema de la textura, las formas, la anatomía de cada una."*

Hermana de `_references/turtle_aquatic/`. La separación importa porque **son dos animales
distintos**, no dos pieles del mismo: caparazón, patas y pie cambian de raíz.

## Imágenes

| # | Archivo | Qué muestra |
|---|---|---|
| 01 | `01_planetzoo_galapagos_giant_front.jpeg` | Galápagos gigante de frente (Planet Zoo). **La vista que más enseña**: patas columnares, caparazón abovedado, cuello saliendo bajo el arco frontal |
| 02 | `02_planetzoo_giant_neck_extended.png` | El mismo, con el **cuello completamente extendido** y la boca abierta — el rango real del estiramiento |
| 03 | `03_planetzoo_sulcata_group_grass.png` | Tortugas de espolones caminando. **Escudos piramidales con anillos de crecimiento** en su forma más legible |
| 04 | `04_planetzoo_sulcata_multi_angle.png` | Las mismas desde varios ángulos y tamaños |

## ESTRUCTURA — lo que define a una terrestre

### Caparazón: ALTO y abovedado, no bajo
Es el opuesto exacto del acuático. Un domo pronunciado, casi hemisférico en las gigantes, con
el borde frontal **arqueado hacia arriba** para dejar salir el cuello.

| Parámetro | Valor | Fuente |
|---|---|---|
| `SHELL_H_LEN_RATIO` | **0,60–0,75** (vs 0,28–0,32 del acuático) | refs 01, 03 |
| `FRONT_ARCH` | el borde delantero se levanta sobre la cabeza | ref 01, 02 |
| `SHELL_SILHOUETTE` | domo, no plato | todas |

### Escudos: PIRAMIDALES con anillos de crecimiento — **es la textura**
El hallazgo de textura más importante de todo el lote, y lo que a nuestro modelo le falta.
Cada escudo de una terrestre **no es una placa lisa**: es una pirámide truncada con **anillos
concéntricos de crecimiento** grabados, más claros en el centro y más oscuros en el borde. El
patrón se lee como madera cortada.

| Parámetro | Valor |
|---|---|
| `SCUTE_PROFILE` | pirámide truncada, no placa plana |
| `SCUTE_RINGS` | 4–8 anillos concéntricos por escudo, centro claro → borde oscuro |
| `SCUTE_RELIEF` | pronunciado — en la sulcata cada escudo sobresale varios cm |

### Patas: COLUMNARES (elefantinas), no esparrancadas
**Diferencia mayor con el acuático, y contradice en parte lo que construimos.** Una terrestre
sostiene un caparazón pesado, así que sus patas van **casi verticales bajo el cuerpo**, como
columnas — no en el sprawl marcado del galápago.

| Parámetro | Valor | Fuente |
|---|---|---|
| `LIMB_POSTURE` | **columnar**, patas casi verticales bajo el cuerpo | refs 01, 03, 04 |
| `FOOT_SHAPE` | **redondo, de elefante**, sin dedos separados | ref 01 |
| `LEG_SCALES` | **escamas grandes y salientes** (espolones en la sulcata), no piel lisa | refs 03, 04 |
| `FRONT_LEG_ARMOR` | la cara anterior de la pata delantera va cubierta de escamas duras superpuestas | ref 01 |

### Cuello y cabeza
- Cuello **largo y muy extensible** (ref 02: se estira casi tanto como la cabeza).
- Cabeza **pequeña respecto del caparazón**, con **pico córneo** ganchudo.
- Piel del cuello **rugosa y plegada**, no lisa.

## Qué capturar
1. **Escudos piramidales con anillos concéntricos** — es la textura que define a la especie.
2. **Caparazón alto** (ratio 0,60–0,75), con el arco frontal levantado.
3. **Patas columnares** con escamas grandes, pie redondo sin dedos.
4. Cuello largo extensible; cabeza chica con pico.
5. Paleta terrosa: pardo, ocre, gris — nada de verde brillante.

## Nota sobre el modelo actual
Nuestra tortuga se decidió **galápago de borde de agua** (`_references/turtle/_synthesis.md`),
así que sigue el eje acuático: caparazón bajo, patas esparrancadas, pie con garras. **Esta
ficha NO la contradice** — describe la otra especie. Si en algún momento se quiere una tortuga
terrestre en el roster (un mob más pesado y lento, o una gigante como mini-boss), esta ficha es
su punto de partida y **no se construye reescalando la acuática**.

**Fuente/fecha**: capturas de Planet Zoo aportadas por Joan, 2026-08-24.
