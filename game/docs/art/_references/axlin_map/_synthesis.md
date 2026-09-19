# Reference: axlin_map — official book maps, El bestiario de Axlin (2026-07-20)

Joan asked for Axlin illustrations again — no village drawing exists, but the
book's OFFICIAL MAPS do (illustrated by Paolo Barbieri per the cover credit).
Found via the Fandom wiki's MediaWiki image API (same recipe as other refs).
Real finds, eyeballed directly.

## Images

| File | What it shows |
|---|---|
| `mapa_ciudadela.jpg` | "La Ciudadela" — the walled CAPITAL city plan, concentric rings + radial roads, 12 numbered landmarks |
| `mapa_tierras_salvajes.jpg` | World map: enclave dots scattered through forest/mountain/swamp, "Aldea de Axlin" marked, X = abandoned enclaves, dotted roads/routes between settlements |
| `mapa_tierras_olvidadas.jpg` | Wider regional map (context, lower detail) |

## Qué se VE — La Ciudadela (mapa oficial, concéntrico)

**Esto es la CIUDAD capital, no un enclave chico como el de Axlin** — pero su
lógica es oro puro y CONFIRMA lo que ya construimos:
- Anillos concéntricos explícitos, nombrados por antigüedad: "la ciudad vieja"
  (centro) → "primer ensanche" → "segundo ensanche" → "anillo exterior" — la
  ciudad crece hacia AFUERA con el tiempo, capas más nuevas en el borde. Esto
  es literalmente el mecanismo de EXPANSIÓN que Joan pidió para el WorldState
  (aldea gana territorio → nuevo anillo se agrega hacia afuera).
- **Calles RADIALES** conectando el centro a las puertas del muro — no solo
  anillos concéntricos, sino "rayos" que cruzan todos los anillos. Nuestra
  aldea hoy solo tiene UN camino recto (entrada→plaza); un asentamiento más
  grande necesitaría 2-4 radios si crece a "aldea grande".
- **Landmarks del centro** (1-Palacio del Jerarca, 2-Explanada, 3-Plaza de los
  Fundadores) — el poder/gobierno vive en el núcleo, como ya definimos.
- **"12-Mercado de la MURALLA"** — dato interesante que CONTRADICE mi
  suposición: el mercado de la Ciudadela está pegado al MURO, no al centro.
  Interpretación: en una ciudad grande, el mercado sirve a caravanas que
  entran por la puerta — se ubica cerca del punto de entrada/tránsito externo,
  no del núcleo cívico. Para nuestra aldea CHICA (una sola entrada, la plaza
  ES el único punto de tránsito) el mercado en la plaza sigue siendo correcto;
  pero si alguna vez generamos un asentamiento con MÚLTIPLES entradas, el
  mercado debería preferir la entrada, no el centro geométrico.
- Zonas marcadas "sin urbanizar" / "en obras" en el anillo exterior — la
  ciudad tiene partes a medio construir, coherente con crecimiento orgánico.

## Qué se VE — Mapa de tierras salvajes (mundo)

- Los enclaves son PUNTOS dispersos en bosque/montaña/pantano, conectados por
  rutas de riesgo con nombre propio ("Ruta de Besari", "Ruta de Lexis y
  Loxan") — no autopistas, senderos peligrosos entre asentamientos aislados.
- **Enclaves ABANDONADOS marcados con X** — confirma que los asentamientos
  pueden MORIR en este mundo, no solo crecer. Relevante para el canon
  WorldState: la contraparte de "la aldea se expande" es "la aldea puede ser
  abandonada/destruida" si pierde territorio en vez de ganarlo.
- Minas y canteras marcadas como puntos de recursos separados de los
  enclaves — sugiere que la economía puede vivir PARCIALMENTE fuera del
  perímetro de la aldea (coherente con un futuro "destacamento minero").

## Qué capturar para el generador / canon

1. **Confirmado, no inventado**: el modelo anillos-concéntricos + centro-cívico
   que ya construimos es EXACTAMENTE como Axlin estructura sus asentamientos
   (a escala ciudad). Buena señal — no hay que rehacer nada, solo escalar.
2. **Expansión por anillos** (para `_village_expansion_canon.md`): cuando la
   aldea "gana territorio" vía misión, el mecanismo concreto es agregar un
   anillo/ensanche nuevo hacia afuera, no simplemente agrandar el existente.
3. **Calles radiales** como ítem futuro cuando la escala "aldea grande" tenga
   más de una entrada.
4. **Abandono como estado del WorldState**: falta contraparte de la expansión
   — una aldea que pierde una misión/territorio podría marcarse como en
   decadencia o, en el extremo, abandonada (ruina) — mismo sistema, signo
   opuesto.
5. **Mercado junto a la entrada en asentamientos grandes/multi-puerta**; en la
   aldea chica actual (una sola entrada) el mercado en la plaza sigue siendo
   la lectura correcta, sin cambios inmediatos.

## Fuente

- [El Bestiario de Axlin Wiki (Fandom)](https://el-bestiario-de-axlin.fandom.com/es/wiki/El_Bestiario_de_Axlin_Wiki:Portada) — imágenes vía API MediaWiki, 2026-07-20. Mapas ilustrados por Paolo Barbieri (crédito de portada, Laura Gallego / Montena).
