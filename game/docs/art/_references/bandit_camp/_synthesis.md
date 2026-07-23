# Reference: bandit_camp — aldea/campamento bandido (2026-07-18, v0.1)

Started per Joan's reference-first protocol: the current `_build_camp` POI uses the
civic outpost pack (neat fence, lantern, cart) which has NO bandit identity. This
folder collects what a raider/frontier camp actually looks like. One image so far —
MORE SOURCES PENDING (LOTR, Metin2, Dark and Darker per `_art_canon.md` approved
refs; goblin camps from Tensura also candidates).

## Images

| File | What it shows |
|---|---|
| `danmachi_rivira_town.png` | Rivira (DanMachi 18F frontier town) — eyeballed 2026-07-18 |

## Qué se VE (danmachi_rivira_town.png)

- **Empalizada**: troncos verticales enteros, alturas DESPAREJAS, madera curtida
  y manchada — se lee improvisada, defensiva, levantada rápido. Nada de cerco
  prolijo parejo (lo que tenemos hoy con el pack outpost).
- **Portón**: dos postes gruesos con travesaño arqueado AMARRADO CON SOGA, letrero
  de madera pintado a mano, jirones de tela colgando de los bordes.
- **Torre de vigía**: alta, angosta, esqueleto de palos visto, varios niveles,
  techo puntiagudo torcido — precaria a propósito.
- **Caserío**: construcciones de madera oscuras amontonadas SIN grilla, trepando
  la ladera de roca; densidad desordenada, ninguna simetría.
- **Integración con terreno**: el asentamiento abraza la base de una formación
  rocosa gigante — el terreno ES parte de la defensa.

## Rasgos de identidad "bandido/frontera" (para el rework del camp)

1. Irregularidad: alturas y ángulos desparejos en TODO (cerca, torres, techos).
2. Materiales pobres: tronco entero, soga, tela rasgada — no herrajes ni piedra
   labrada.
3. Verticalidad defensiva: al menos una torre de vigía que sobresalga.
4. Señalética tosca: letrero/estandarte pintado a mano (ya tenemos banner del
   pack — evaluar si el estilo calza o es demasiado prolijo).
5. Apoyarse en el terreno (roca/ladera) en vez de plantarse en campo abierto.

## Fuente 2 — El bestiario de Axlin (Guardianes de la Ciudadela, Laura Gallego)

Aprobada por Joan 2026-07-18: los enclaves de Axlin no son bandidos, pero SON
aldeas fortificadas contra monstruos — exactamente nuestro mundo. Extraído del
primer capítulo oficial (PDF de lauragallego.com, pasajes textuales) + reseñas:

- **Portón DOBLE (esclusa)**: "los centinelas nunca abrían el portón interior
  sin haber cerrado antes el exterior" — dos puertas en serie, nunca ambas
  abiertas. Rasgo arquitectónico distintivo y funcional (mundo con monstruos).
- **Centinelas**: anuncian llegadas desde el perímetro → torre/puesto de vigía.
- **Defensa concéntrica**: la cabaña más sólida está EN EL CENTRO, lejos de la
  empalizada — ahí viven los niños (<13) y madres; los adultos forman anillo
  protector alrededor. Lo más valioso, al centro.
- **Vida productiva adentro**: cultivos (guisantes) dentro/junto al recinto —
  una aldea viva, no solo militar.
- **Cicatrices**: los monstruos abren agujeros en la empalizada → parches y
  refuerzos visibles cuentan historia ambiental.

## Identidad fusionada (Rivira × Axlin) — canon v1 para el generador

1. Empalizada de troncos desparejos siguiendo el terreno (Rivira).
2. Esclusa de portón doble en la entrada (Axlin) — señalética tosca (Rivira).
3. Torre/puesto de vigía en el punto MÁS ALTO del perímetro (ambas).
4. Edificio central = el más protegido/sólido, resto en anillo (Axlin).
5. Parches/refuerzos en la empalizada como storytelling (Axlin).
6. Apoyarse en el terreno como defensa (Rivira).
7. Variante bandida = misma estructura, más desorden/jirones/botín; variante
   civil = más cultivo/orden. MISMO algoritmo, distinto estilo.

## Decisión de Joan (2026-07-18)

Adelante con el estilo fusionado. La aldea se GENERA: el layout depende del
bioma/terreno donde caiga (modelos por bioma y/o randomización interna según
terreno). Estructura (algoritmo) separada de estilo (bioma) — mismo principio
del motor Blender (geometría vs lookdev).

## GAP — pendiente

- Fuentes visuales extra (Metin2 orc camps, LOTR, Dark and Darker) — sumar
  cuando toque afinar el estilo bandido específico.
- Assets: no existe tronco-empalizada "tosco" real en el pack (el civic outpost
  es prolijo) — mientras el motor Blender no genere piezas propias, aproximar
  con jitter de altura/inclinación/escala sobre las piezas del pack.

## Fuentes

- [DanMachi Wiki (Fandom) — Rivira](https://danmachi.fandom.com/wiki/Rivira),
  screenshot vía API MediaWiki, 2026-07-18.
- [El bestiario de Axlin — primer capítulo oficial (PDF)](https://www.lauragallego.com/wp-content/uploads/2018/05/el_bestiario_de_Axlin-primer-capitulo.pdf),
  pasajes textuales extraídos 2026-07-18; corroborado con
  [reseña El Templo de las Mil Puertas](https://www.eltemplodelasmilpuertas.com/critica/bestiario-axlin-guardianes-ciudadela/1446/)
  y [Wikipedia](https://es.wikipedia.org/wiki/El_Bestiario_de_Axlin).

## Fuente

- [DanMachi Wiki (Fandom) — Rivira](https://danmachi.fandom.com/wiki/Rivira),
  screenshot vía API MediaWiki, 2026-07-18.

## Addendum — clima cálido (2026-07-18, PO principle 2 "living village" pass)

Pradera = P1, clima cálido, vida al aire libre. Investigación vernacular
architecture cross-checked (ver `game/docs/_village_expansion_canon.md` §7
para las citas completas): regiones cálidas favorecen estructuras abiertas
y semi-exteriores — porches/aleros grandes, ventanas amplias, secado de
comida/cuero al aire libre (sin heladas que lo impidan). Bakeado en
`village_gen.py` `STYLES["pradera"]`: `window_scale=1.15` (ventanas grandes),
`porch_chance=0.55` (más de la mitad de las casas con porche), `drying_rack`
(prop de secado nuevo). Contraste directo con hielo (`window_scale=0.65`,
`porch_chance=0.0`) — ver `village_hielo/_synthesis.md` addendum.
