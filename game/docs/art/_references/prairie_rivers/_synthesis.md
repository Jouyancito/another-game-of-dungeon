# Reference: prairie_rivers — rocks IN the channel + riverbank fauna (2026-07-18)

Requested for the floor-1 stream rework. Current gap: streams are flat water ribbons with
rocks/pebbles only in the DRY streambed variant — the two WET streams have no rocks in the
channel, and `_scatter_stream_banks()` places rocks/pebbles/reeds/bushes on the banks but
no fauna. Images live IN THIS FOLDER, hunted multi-source (Openverse→Flickr/Wikimedia
Commons/Geograph + one Fandom wiki screenshot) and eyeballed one by one.

## Images

| File | What it shows |
|---|---|
| `river_boulders_rapids.jpg` | Real mountain stream: large granite boulders sitting directly IN cascading rapids, moss + grass at the bank edge |
| `frog_on_rocks_stream.jpg` | Real creek: several boulders breaking the surface across a shallow channel + grass/moss on banks (titled "frog on rocks" — see caveat below) |
| `rogue_river_boulders.jpg` | Rogue River (Oregon): a waterfall dropping into a calm rock-walled pool, rafters for scale — channel walls are cliff/boulder, not mid-stream rocks |
| `heron_riverbank_reeds.jpg` | Calm canal-style river: a grey heron standing in a reed bed at the bank, trailing reed stems breaking the water surface |
| `zelda_zoras_river_rapids.webp` | The Legend of Zelda: Twilight Princess — a river routed through a rock cavern/tunnel with lantern-orbs hung over the water (stylized, style-gap noted below) |

## Qué se VE (observado, no asumido)

**Rocas DENTRO del canal de agua (no solo en la orilla):**
- `river_boulders_rapids.jpg`: múltiples piedras grandes (≈0.5-1m) se paran en medio de la
  corriente — el agua se parte y hace espuma ALREDEDOR de ellas, algunas generan pequeños
  saltos escalonados. Confirma que las rocas van DENTRO del flujo, no solo en los bordes.
- `frog_on_rocks_stream.jpg` — cross-valida: varias piedras (puño a boulder) rompen la
  superficie a lo ancho de un canal poco profundo, con musgo en el lado a la sombra y tono
  más claro/seco en el lado que da al sol. Confirma que las rocas del canal tienen un split
  de color húmedo/seco según el contacto con el agua, no un color plano uniforme.
- **No pude verificar** la rana del título en este recorte específico de
  `frog_on_rocks_stream.jpg` pese al nombre de la fuente — su aporte a esta síntesis queda
  limitado a rocas-en-canal + vegetación de orilla, no fauna confirmada en ESTA imagen.

**Vegetación + fauna de orilla:**
- `heron_riverbank_reeds.jpg`: una garza gris se para DENTRO de un juncal en el borde del
  agua (no en tierra seca) — los juncos nacen directamente del agua en un estante poco
  profundo, con tallos que siguen rompiendo la superficie más lejos de la orilla. Confirma
  que los juncos enraízan EN el agua del margen, y que aves vadeadoras usan ESE margen
  específico.
- Cross-referenciado con `frog_on_rocks_stream.jpg`: pastos y helechos chicos crecen
  directamente sobre la roca/musgo de la orilla, no retirados del borde del agua.

**Paredes/composición del canal (secundario):**
- `rogue_river_boulders.jpg`: acá las paredes rocosas de acantilado forman el canal, no hay
  boulders en medio del cauce — útil sobre todo como referencia de composición
  "cascada cayendo a un pozo calmo rodeado de roca", menos relevante para el scatter de
  rocas del lecho que las dos imágenes anteriores.

**Nota de gap de estilo (Zelda):**
- `zelda_zoras_river_rapids.webp`: precedente de videojuego fantástico para nuestro
  escenario exacto — un río corriendo DENTRO de una caverna/túnel rocoso — decorado con
  esferas-linterna colgando sobre el agua y un recorrido en canoa. Estilo de arte distinto
  (3D estilizado era N64/GameCube vs nuestro toon-shaded low-poly) — usada acá SOLO como
  referencia de COMPOSICIÓN (río-dentro-de-caverna con props de luz sobre el canal), no
  para detalle de roca/material.

## Qué capturar

1. `_scatter_stream_banks()` hoy solo puebla la banda de orilla (`BAND_INNER`..`BAND_OUTER`,
   es decir `STREAM_HALF_WIDTH` a +4m FUERA del canal) — `river_boulders_rapids.jpg` +
   `frog_on_rocks_stream.jpg` muestran rocas que pertenecen DENTRO del canal también, no
   solo en la banda de orilla. Falta un pase de rocas IN-CHANNEL (separado del scatter de
   banks) que muestree posiciones con distancia a la centerline < `STREAM_HALF_WIDTH`,
   igual a lo que ya hace la variante de streambed seco según el brief — extender ese
   poblado de rocas in-channel también a los streams húmedos.
2. Las rocas in-channel deberían asomar parcialmente respecto a `STREAM_DEPTH` (paradas en
   el piso del canal, con el agua visiblemente partiéndose/haciendo espuma alrededor, como
   en `river_boulders_rapids.jpg`) en vez de flotar sobre la superficie del ribbon —
   coordinar con la superficie de agua de `_build_stream_ribbons()`
   (`get_terrain_height + STREAM_DEPTH * 0.40`) para que las rocas asomen unos cm arriba de
   esa superficie, ni totalmente sumergidas ni flotando por encima.
3. El color de las rocas necesita un split húmedo/seco por banda de altura (musgo oscuro
   donde siempre toca agua cerca de la línea de flote, tono más claro/seco del lado que da
   al sol) — hoy probablemente un material de roca plano; agregar un gradiente de color
   vertical o dos variantes de material de roca según la posición Y dentro del canal.
4. El gap de fauna de `_scatter_stream_banks()` confirmado por el brief (rocas/pebbles/
   reeds/bushes pero sin fauna) — `heron_riverbank_reeds.jpg` valida agregar un prop tipo
   ave-vadeadora (o spawn de fauna ambiental chica) específicamente DENTRO de los clusters
   de juncos en la línea de agua inmediata, no repartido de forma genérica por toda la
   banda de orilla.
5. Opcional: tomar prestado el truco de `zelda_zoras_river_rapids.webp` de "acentos de luz
   colgando sobre el canal de agua" para tramos de stream que pasen cerca/dentro de zonas
   con el rework de crystal-ceiling (cruce con esa spec) — idea bonus, no es un fix de
   roca/vegetación, marcar como baja prioridad/opcional en el spec.

## Fuentes (multi-fuente, por convención)

- ["White fast moving water over boulders"](https://www.flickr.com/photos/10361931@N06/4989504768)
  (Openverse → Flickr, Horia Varlan), CC BY 2.0, descargado 2026-07-18.
- ["MYLF Frog on Rocks"](https://www.flickr.com/photos/39108150@N05/5794436540)
  (Openverse → Flickr, Region 5 Photography / US Forest Service), CC BY 2.0, descargado
  2026-07-18.
- ["Rogue River"](https://www.flickr.com/photos/50169152@N06/17580951856)
  (Openverse → Flickr, BLM Oregon & Washington), CC BY 2.0, descargado 2026-07-18.
- ["Heron in the reeds, Offenham Park"](https://www.geograph.org.uk/photo/1923531)
  (Openverse → Geograph, Bill Johnson), CC BY-SA 2.0, descargado 2026-07-18.
- The Legend of Zelda: Twilight Princess — "Upper Zora's River" screenshot
  ([Zelda Wiki (Fandom)](https://zelda.fandom.com/wiki/Upper_Zora%27s_River)), vía API
  MediaWiki (`static.wikia.nocookie.net`), descargado 2026-07-18. Style-gap: 3D estilizado
  era N64/GameCube vs nuestro toon-shaded low-poly — usada SOLO para composición.

---

## Jerarquía de roca en el río — grabación de Joan (2026-08-28)

**Joan dijo:** *"te muestra cómo hace un río, y cómo va ocupando la misma textura de piedras,
rocas, en diferentes lados para conformar el río. El tema de las piedras, piedritas, en general
el ambiente me parece muy muy bien. No sé si podrás replicar ese tipo de colores, textura.
Realmente se nota como piedras de ambiente: no son polígonos separados, ni perfectos."*

Fuente: reel de Instagram grabado por Joan con `capturar.ps1` (sesión
`grabar en screenshots/sesiones/2026-08-28_14-26-17`, 694 frames); 8 cuadros recortados a la
zona del reel, `river_rock_hierarchy_01..08`. Es un desglose de arte de entorno en **Unreal**
(los contornos amarillos son los assets seleccionados en el editor; un panel "Details" con
parámetros de *Ripples* aparece al hablar del agua). El texto del reel habla de **jerarquía
visual** ("guide… hierarchy… everything… importance… lighting… player… door"): la roca se usa
en tres escalas para guiar al jugador.

| File | Qué muestra |
|---|---|
| `01_canyon_river_overview` | cañón de roca caliza pálida, río verde-azulado al fondo, personaje para escala |
| `02_pebble_bed_selected_assets` | lecho de cantos rodados como SUPERFICIE (un solo asset seleccionado en amarillo cubre metros); orilla mojada más oscura; agua transparente que deja ver el lecho |
| `03_boulders_pool` | peñascos medianos semienterrados al borde de una poza, **el mismo mesh** reaparece rotado y escalado |
| `04_gravel_cone_hierarchy` | cono de grava a pie de pared: grande (pared) → medio (bloques) → chico (grava) en un solo encuadre |
| `05_pool_topdown_door` | cenital de la poza: el contorno amarillo marca UN asset de orilla que "cierra" el espacio — la roca como puerta/umbral para el jugador |
| `06_gravel_bank_pool` | banco de grava seca contra poza; transición seco (claro, cálido) → mojado (oscuro) → sumergido (teal) |
| `07_pool_clear_water` | agua clara: el lecho se ve a través, el color del agua es el del fondo + teal por profundidad |
| `08_canyon_walls_far` | paredes lejanas con la misma caliza, menos contraste por distancia |

### Qué se VE (observado)

- **Una sola familia de material** para todo lo mineral: caliza gris-crema con tintes ocre en
  las caras al sol y gris-azulado en sombra. Pared, peñasco y canto rodado comparten color; lo
  que cambia es la **escala del grano** y la forma.
- **Tres escalas, no dos**: (1) pared/acantilado de decenas de metros, (2) peñascos de 0,5-3 m
  semienterrados en grupos, (3) **lecho de cantos rodados como superficie continua** — no son
  miles de piedritas sueltas: es una malla/textura de grava con relieve (normal + height) que
  cubre metros, y encima unas pocas piedras individuales para romper la repetición.
- **El mismo mesh reusado**: el peñasco seleccionado aparece en otros puntos rotado 90-180° y
  escalado 0,6-1,5×; enterrado hasta un 30-50 % de su altura. Así nunca lee como "polígono
  separado": no hay base visible ni borde recto contra el suelo.
- **Bandas por humedad**, de arriba hacia el agua: seco (claro, cálido, polvo) → **mojado**
  (20-40 cm de banda más oscura y saturada, roughness baja) → sumergido (teal, el lecho se ve
  a través del agua).
- **Agua**: transparente, color = fondo + teal que crece con la profundidad; ondulaciones
  finas (*ripples*) sin espuma; no es un plano celeste opaco.
- **Nada es perfecto**: peñascos con caras rotas y aristas redondeadas, grava de tamaños
  mezclados (2-15 cm), la orilla es irregular, el borde agua-piedra no es una línea.

### Traducido a nuestro piso 1 (contra el código, no contra el recuerdo)

Ya existe `river_pack` cableado en `floor1_prairie.gd` (in-channel rocks + reeds, 2026-07-27)
y `POOL_ROCKS`. Joan reportó igual que los ríos "son planos celestes lisos, no funcionan como
ríos" (2026-08-27). El gap no es que falten rocas: es **material, bandas y lecho**.

| # | Ref | Nuestro | Qué cambiar |
|---|---|---|---|
| 1 | una familia de material mineral | rock_pack / river_pack con materiales propios | unificar albedo/normal de roca en UNA familia por bioma; tinte por orientación (sol/sombra) |
| 2 | lecho de grava como superficie | fondo del stream = terreno liso | malla de lecho con textura de grava tileable + normal/height, bajo el agua y en la orilla |
| 3 | mismo mesh reusado, enterrado 30-50 % | instancias apoyadas sobre el terreno | scatter con **hundimiento** y rotación libre; nunca la base del mesh al ras |
| 4 | banda mojada 20-40 cm | sin banda | material de roca con máscara por altura relativa al agua: más oscuro, roughness 0,2-0,3 |
| 5 | agua transparente teal por profundidad | plano celeste opaco | shader de agua: alpha por profundidad (depth fade), tinte teal, ripples de normal |
| 6 | grande → medio → chico en un encuadre | rocas de un solo tamaño | garantizar los tres tamaños en cada tramo de río (pared/borde alto, peñascos, grava) |

**Métrica de éxito (antes de construir)**: en un frame del río a 1,7 m, (a) se ven las tres
escalas de roca; (b) ≥ 80 % de las rocas del borde tienen su base oculta (no se ve arista
inferior); (c) hay una banda visiblemente más oscura entre roca seca y agua; (d) el lecho se
ve a través del agua en los primeros 2 m desde la orilla.

**Respuesta a "¿podrás replicarlo?"**: sí, sin fotogrametría. Es (1) una textura de grava y
una de caliza horneadas desde procedural (como `texture_bake.py` del golem), (2) un shader de
agua con depth-fade (Godot lo soporta nativo con `depth_texture`), (3) scatter con hundimiento.
Lo que no se replica 1:1 es la densidad de malla de Megascans — y no hace falta al techo Skyrim.
