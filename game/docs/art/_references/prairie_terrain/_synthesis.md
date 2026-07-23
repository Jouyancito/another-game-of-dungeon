# Reference: prairie_terrain — a landmark that RISES from the center of a cavern (2026-07-18)

Requested for the floor-1 terrain rework. The producer's complaint: `_compute_height_at`
currently reads as a flat disc at map-center with the ground rising 12-16m toward the
BORDER — "a hole/crater toward the center", not a landscape. He floated a MOUNTAIN or
landmark that rises FROM the center instead, for verticality. Images live IN THIS FOLDER,
hunted multi-source (Fandom wiki API + Openverse→Flickr/Wikimedia) and eyeballed one by
one — observations below are from the actual images.

## Images

| File | What it shows |
|---|---|
| `danmachi_18f_central_tree.png` | DanMachi 18F: a single giant tree on a raised earthen mound at the exact center of the safe-floor, ringed by a low palisade, pale mist-wall in the background (shared with `crystal_ceiling/`, re-purposed here as the composition reference) |
| `abyss_1st_layer.webp` | Made in Abyss 1st Layer: jagged rock spires/pillars beside a cave-mouth entrance, mushroom foreground |
| `abyss_3rd_layer.webp` | Made in Abyss: vertigo POV looking straight down the Abyss shaft — extreme vertical scale sold via curved wall + tiny birds |
| `yana_caves_alien.png` | Real karst formation ("Too ALIEN for Earth" — Yana Caves): massive jagged vertical limestone spires towering well above the tree line |
| `gadime_cave_stalagmite.jpg` | Real cave interior (Gadime Cave): a single vertical fluted flowstone/stalagmite column, layered wet rock walls around it |

## Qué se VE (observado, no asumido)

**El landmark central es UNA masa dominante sobre un montículo, no un anillo que sube al borde:**
- `danmachi_18f_central_tree.png` es la referencia de composición más directa: el árbol
  gigante se para sobre un MONTÍCULO elevado en el centro exacto del piso, con un cerco
  bajo rodeándolo — el terreno alrededor del montículo se queda MÁS BAJO. Es literalmente
  la inversión de lo que pide el productor: sube desde el centro, no hacia el borde.

**La "montaña rising" es un fenómeno geológico real, no solo fantasía:**
- `yana_caves_alien.png` — CROSS-VALIDADO como formación real (karst tsingy): picos de
  piedra caliza verticales, MÁS ALTOS que el dosel de árboles alrededor, agrupados en un
  macizo único que domina el paisaje. Confirma que "un macizo rocoso vertical gigante
  parado en medio del terreno" es un accidente geográfico real, no una invención.
- `gadime_cave_stalagmite.jpg` — versión de escala chica del mismo patrón de crecimiento:
  columna vertical acanalada (fluted), se angosta hacia arriba, superficie con vetas
  verticales que atrapan la luz. Útil como referencia de TEXTURA/geometría de superficie
  para escalar el landmark, no de composición general.

**La verticalidad extrema se vende con objetos de escala, no solo con altura bruta:**
- `abyss_3rd_layer.webp`: la pared curva del pozo + pájaros diminutos contra la inmensidad
  es lo que comunica la escala — sin esos puntos de referencia chicos, la imagen sería
  solo una textura de piedra sin sensación de profundidad/altura.
- `abyss_1st_layer.webp`: la boca de la cueva se lee bien porque queda ENMARCADA detrás de
  picos rocosos irregulares en primer/segundo plano — confirma que zonas de caverna se
  leen mejor cuando hay masas rocosas quebradas interrumpiendo el terreno medio, no solo
  paredes lisas.

## Qué capturar

1. **Invertir la dirección del rise en `_compute_height_at`**: hoy `BOWL_RISE_BASE` y
   `BOWL_LIP_RISE_BASE` levantan el terreno hacia AFUERA desde `FLAT_RADIUS_BASE` hasta el
   borde (se lee como cráter). Según `danmachi_18f_central_tree.png`, el montículo del
   landmark debería subir HACIA ADENTRO, con el pico cerca de/poco después de
   `flat_radius`, y el terreno más allá quedándose bajo — un bulto centrado sobre/cerca del
   disco de spawn, no una rampa monótona hacia el borde.
2. **`_build_landmark_pillars()` es el hook natural** para plantar el landmark vertical
   (estilo `yana_caves_alien.png` — macizo rocoso quebrado único) o el combo
   montículo+objeto-dominante (estilo `danmachi_18f_central_tree.png` — un solo árbol/masa,
   no pilares dispersos). Las referencias confirman: UNA masa dominante centrada lee mejor
   como "acá está el centro del mundo" que varios pilares repartidos.
3. **La magnitud actual de `BOWL_RISE_BASE`/`BOWL_LIP_RISE_BASE` (12-16m) coincide con la
   escala real** que muestra `yana_caves_alien.png` (picos claramente más altos que un
   dosel de árboles, varias alturas de edificio) — el problema NO es la magnitud, es la
   DIRECCIÓN/posición: aplicar el rise CENTRADO (pico dentro/cerca de `FLAT_RADIUS_BASE`)
   en vez de monótono hacia el borde.
4. El veteado vertical acanalado de `gadime_cave_stalagmite.jpg` es referencia de
   textura/geometría de superficie para el modelado futuro en Blender de
   `_build_landmark_pillars()` (vetas verticales que atrapan luz) — no cambia la función de
   altura, es nota para cuando se modele el asset.
5. El truco de escala de `abyss_3rd_layer.webp` (objetos chicos contra la inmensidad)
   sugiere vestir la base del nuevo landmark con props de escala chicos (rocas, clusters de
   cristal, vegetación baja) para que se lea la altura real contra el jugador — mismo
   patrón que `_build_crystal_field` ya usa para acentos puntuales (ver
   `crystal_ceiling/_synthesis.md`).

## Fuentes (multi-fuente, por convención)

- DanMachi Wiki (Fandom) — Dungeon, vía API MediaWiki (`static.wikia.nocookie.net`),
  imagen compartida y re-bajada desde `crystal_ceiling/` (fuente original 2026-07-18, ver
  ese folder para la cita completa).
- [Made in Abyss Wiki (Fandom) — 1st Layer](https://madeinabyss.fandom.com/wiki/1st_Layer)
  y [3rd Layer](https://madeinabyss.fandom.com/wiki/3rd_Layer), imágenes vía API MediaWiki
  (`static.wikia.nocookie.net`), 2026-07-18.
- ["Too ALIEN for Earth- Yana Caves"](https://commons.wikimedia.org/w/index.php?curid=72774550)
  (Wikimedia Commons, Tejass123), CC BY-SA 4.0, vía Openverse, descargado 2026-07-18.
- ["Calcite flowstone and stalagmite formations inside the Gadime Cave"](https://commons.wikimedia.org/w/index.php?curid=179986790)
  (Wikimedia Commons, Mozaikuks), CC0 1.0, vía Openverse, descargado 2026-07-18.
