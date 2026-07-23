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
