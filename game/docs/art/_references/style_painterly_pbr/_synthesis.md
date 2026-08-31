# style_painterly_pbr — "PBR pintado" (nombre de estilo en el catálogo)

**Joan dijo (2026-08-28):** *"es un render que está friendo un huevo, pero la que me interesa es la
forma que tiene el post-renderizado. Los colores y la textura se sienten muy bonitos para un cierto
estilo de diseño. Aparte, está todo detallado bien en el viewport; eso es lo que igual intentaría
tener. La textura de los muebles parece madera, el sartén parece metal, el huevo parece huevo. Eso
es lo que quiero que se muestre realmente. Si puedes colocarle un nombre de estilo, estaría bueno."*

→ Manda sobre **el look de render** (material + luz + color) y sobre **el nivel de detalle
geométrico** de props. Entrada del catálogo: `_style_catalog.md` → **PBR pintado**.

| File | Qué muestra |
|---|---|
| `01_kitchen_pan_split` | mitad viewport (wireframe) / mitad render: cocina con hornalla encendida, sartén rojo con huevo frito con cara, frascos, cuenco con frutillas, azulejos, cajones de madera. Luz de sol lateral cálida con rayos, sombras suaves |
| `02_egg_closeup_split` | huevo en primer plano: clara con **subsurface** (borde translúcido), yema con relieve tipo gajos, cara mínima (dos ojos + boca); sartén con **pinceladas visibles** en el esmalte y remache con highlight |
| `03_kitchen_pan_split_b` | igual a 01, otro frame — confirma consistencia |
| `04_wall_stucco_split` | pared con **estuco de relieve real** (normal/height, no albedo pintado), mesada de madera clara con veta, luz rasante que revela el relieve |

## Nombre del estilo y familia

**PBR pintado** (en inglés *painterly PBR* / *stylized PBR*). Familia conocida: **Sea of Thieves**
(el ejemplo canónico: materiales físicamente correctos con texturas pintadas a mano), **Arcane**
(pinceladas visibles sobre 3D), **Overcooked / Pixar-Ratatouille** (cocina cálida, formas
redondeadas, cara en la comida). No es toon (no hay líneas ni bandas de sombra) y no es fotorealismo
(la paleta está empujada y las formas son gordas).

## Cómo se reconoce (cada frase termina en un número o una orientación)

**Materiales — "cada cosa se lee como lo que es"**
- Metal (sartén): roughness ~0.3-0.4 con **variación pintada** (pinceladas en el esmalte),
  highlight de sol único y ancho, remaches con su propio highlight.
- Madera (cajones, mesada): veta visible, roughness ~0.6, bordes **biselados** que atrapan luz.
- Estuco (pared): relieve REAL en normal/height (~1-2 mm a escala), lectura sólo con luz rasante.
- Comida (huevo): **subsurface** en la clara (translúcida en el borde, ~2-4 mm de profundidad),
  yema con micro-relieve y specular alto.
- Regla: **la textura sola no alcanza** — el relieve (normal/height) es lo que separa esto de
  "textura pegada".

**Geometría — "detallado bien en el viewport"**
- Nada es un cubo: **bordes biselados o subdividos** (radio de bisel ~3-8 mm a escala real en
  props de mano; el ojo lee el highlight del bisel como "objeto sólido").
- Formas **gordas y redondeadas** (huevo, sartén, frascos): proporciones exageradas +10-20 %
  respecto de lo real.
- Densidad de malla alta en el viewport (subdivisión visible) → **para hero props**, no para
  scatter. Ver "Presupuesto" abajo.

**Luz**
- Un sol **cálido** (~3500-4500 K) lateral/rasante + rayos volumétricos suaves; sombras suaves
  (área grande), **rebote** cálido en las sombras (nada negro).
- Bloom bajo; profundidad de campo leve en primeros planos.

**Color**
- Paleta **saturada y cálida**: rojo-naranja del sartén, amarillo del huevo, madera miel, azul
  desaturado en azulejos y cajones como **complementario** frío. Dos o tres colores dominantes por
  encuadre, el resto neutros.
- El contraste principal es **cálido/frío**, no claro/oscuro.

## Relación con el canon vigente

- Compatible con `_art_canon.md` §17 ("materiales que se leen como lo que son") y con el modelo
  Valheim (materiales ricos) — pero **sube la geometría**: Valheim es low-poly con textura; acá el
  detalle está en la malla (biseles, subdivisión). Es un escalón arriba en tris por prop.
- La paleta cálida-saturada es más **cozy** que el "ambiente frío-oscuro con charcos cálidos" del
  §17.1 → encaja natural en **interiores habitados** (taverna, cocina, casas de aldea, tiendas)
  más que en cavernas o mazmorras.

## Presupuesto (qué NO se lleva de acá)

- La densidad de malla del viewport **no** va al scatter ni a lo que se repite 100 veces. Hero
  props de mano y mobiliario de interior: sí. Regla práctica: bisel real en lo que el jugador ve a
  < 3 m; normal map de bisel en lo demás.
- Subsurface: sólo en lo orgánico/comida que se ve de cerca.

## Métrica de éxito (definida antes de construir)
Sobre un prop hecho "en PBR pintado": a 1 m, el highlight de bisel es visible en ≥ 80 % de los
bordes duros del objeto; el relieve del material se ve con luz rasante (diferencia de luminancia
≥ 15 % entre cresta y valle del estuco/veta); paleta del encuadre = 2-3 dominantes cálidos +
1 complementario frío (medido por clusters de color).

## Fuente
Reel de Instagram "Viewport / Render" (cocina, huevo frito con cara), autor sin identificar.
Relacionadas: `poe_visual_bar/` (tema principal §17), `village_poe_style/` (materiales de
arquitectura), `tavern/` (interior habitado donde este estilo aplica primero), `hand_drawn_palette/`.
