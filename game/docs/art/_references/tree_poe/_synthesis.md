# tree_poe — Árboles y vegetación estilo Path of Exile / Valheim (2026-07-29)

**Base-name**: `tree_poe_`
**Carpeta**: `game/docs/art/_references/tree_poe/`
**Estado**: ✅ 14 imágenes commiteadas y VISTAS una por una (no confiadas del reporte de un agente).
**Motivo**: Joan rechazó `tree_pack` (2026-07-28/29): *"los árboles ahora son un tronco liso
perfecto y con hojas agrupadas en forma de esferas, eso no es un patrón normal ni visual
similar a un árbol. ahí necesitas buscar info en cada modelado sobre lo que estés trabajando
igual, si pedí troncos estilo path of exile, lo lógico es buscar troncos de path of exile y
analizarlos, entender el por qué son así y entender la esencia, quizás patrones."*

**Confirmado por inspección directa** de `game/tools/blender/tree_pack/renders/tree_showcase_macro_prairie.png`
y `tree_showcase.png`: los 5 variantes son un poste cónico liso + una masa de poliedros verdes
encima. **Cero ramas.** El bare-trunk mide ~62% de la altura en el render de prairie.

> **Este documento NO es solo mood.** La sección **§B — El PORQUÉ y los PATRONES** es una lista
> numerada de reglas con NÚMEROS, implementables por un generador. La sección **§C** es la tabla
> de gaps contra el código actual con `file:line`. La **§D** dice cuáles patrones son imposibles
> sin relajar las constraints del pack.

---

## Imágenes

| Archivo | Qué muestra | Fuente |
|---|---|---|
| `tree_poe_poe2_grelwood_artstation_thumbnail.jpg` | **La mejor ref del pack.** Base de árbol gigante PoE2 (Grelwood): raíces contrafuerte que forman un arco/cueva, corteza de surcos verticales profundos, musgo azul luminiscente, helechos brotando de las grietas | Patrick Manson (env. artist GGG), [artstation.com/artwork/y4k8XQ](https://www.artstation.com/artwork/y4k8XQ) |
| `tree_poe_poe2_canopy_hideout_artstation.webp` | Hideout bajo copa: troncos de fondo en silueta oscura con contrafuertes visibles al ras de suelo, haces de sol filtrados sobre chozas | Patrick Manson (GGG), [artstation.com/artwork/3EWg0B](https://www.artstation.com/artwork/3EWg0B) |
| `tree_poe_poe2_steam_jungle_canyon_treetrunk_vines.jpg` | Tronco alto oscuro con lianas colgantes + helechos densos en el borde derecho; el árbol funciona como marco/silueta, no como objeto legible | Steam appid 2694490, screenshot #6 |
| `tree_poe_poe2_steam_worldmap_pine_forest_aerial.jpg` | Vista aérea: siluetas de cluster de pinos, patrón de densidad/distribución del bosque | Steam appid 2694490, #18 |
| `tree_poe_poe2_steam_undergrowth_broadleaf_plants.jpg` | Sotobosque de hoja ancha a ras de suelo, clumps redondeados densos | Steam appid 2694490, #20 |
| `tree_poe_poe2_steam_foliage_silhouette_night.jpg` | Follaje en silueta oscura enmarcando las esquinas en escena de boss nocturna | Steam appid 2694490, #24 |
| `tree_poe_valheim_birch_trees_fog.webp` | **2ª mejor ref.** Abedules en niebla: troncos INCLINADOS cada uno hacia distinto lado, follaje de CARDS con alfa recortado, agujeros de cielo enormes, ramas visibles atravesando la copa | [valheim.fandom.com/wiki/Birch](https://valheim.fandom.com/wiki/Birch) |
| `tree_poe_valheim_beech_trees_grove.webp` | Arboleda de hayas a ras de suelo: troncos largos desnudos, ramas primarias en abanico, follaje en LÁMINAS horizontales en las puntas, copa superior lima-amarilla vs bajocopa casi negro | [valheim.fandom.com/wiki/Trees](https://valheim.fandom.com/wiki/Trees) |
| `tree_poe_valheim_blackforest_biome_view.webp` | **3ª mejor ref.** Interior de pinar: troncos rectos con MUÑONES DE RAMA MUERTA horizontales a lo largo del tronco desnudo, follaje en tiers caídos, niebla + backlight naranja haciendo la mitad del trabajo | [valheim.fandom.com/wiki/Black_Forest](https://valheim.fandom.com/wiki/Black_Forest) |
| `tree_poe_valheim_oak_single_render.webp` | Roble en primer plano: relieve de corteza tipo ladrillo/escama muy marcado, bifurcación en Y a media altura, muñón de rama rota | [valheim.fandom.com/wiki/Oak](https://valheim.fandom.com/wiki/Oak) |
| `tree_poe_valheim_fir_single_render.webp` | Abeto: copa de tiers de frondas caídas apiladas, radio decreciente hacia arriba, **se ve el tronco A TRAVÉS de la copa** | [valheim.fandom.com/wiki/Fir](https://valheim.fandom.com/wiki/Fir) |
| `tree_poe_valheim_pine_single_render.webp` | Pinos hacia arriba: troncos rectísimos, copa concentrada en el tercio superior | [valheim.fandom.com/wiki/Pine](https://valheim.fandom.com/wiki/Pine) |
| `tree_poe_valheim_meadows_biome_view.webp` | Meadows con lluvia: árbol de copa redondeada solitario en niebla + conífera junto a línea de nieve | [valheim.fandom.com/wiki/Meadows](https://valheim.fandom.com/wiki/Meadows) |
| `tree_poe_valheim_plains_biome_view.webp` | Plains: coníferas cónicas chicas + cluster florido sobre loma de pasto dorado | [valheim.fandom.com/wiki/Plains](https://valheim.fandom.com/wiki/Plains) |

**Fuentes que NO se pudieron bajar** (registradas por convención):
- `poewiki.net` y `poe2wiki.net` (The Grelwood, Woodland, Category:Area_screenshots) — muro anti-bot
  Anubis en WebFetch y en curl. Es la fuente más rica de screenshots limpios de bosque PoE y quedó
  fuera. **Pendiente**: pedirle a Joan capturas propias de Grelwood/Clearfell si quiere subir la vara.
- `steamdb.info/app/2694490/screenshots/` — SPA, sin URLs estáticas.
- **Rechazada tras inspección**: `shared.akamai.steamstatic.com/.../ss_b8ed545404b1d53fb7db4866beb3eddbfe9fa707.1920x1080.jpg`
  (screenshot oficial PoE1) — el agente la etiquetó "ancient tree roots ferns moss"; al abrirla es un
  fondo marino con un esqueleto de cangrejo, **sin un solo árbol**. Borrada del repo.
- No existe (buscado) ninguna postmortem/GDC de Iron Gate sobre la construcción técnica de los
  árboles de Valheim. Todo lo que se dice acá sobre Valheim es OBSERVADO de las imágenes, y está
  marcado como tal.

---

## Idea / Concepto

**Un árbol se lee como árbol por su ESQUELETO, no por su copa.** PoE y Valheim gastan su
presupuesto en dos cosas que el pack actual no tiene: (1) **la base** — el ensanche de raíces
que ancla el tronco al suelo, y (2) **la ramificación** — el árbol de ramas que sostiene el
follaje y que se VE a través de él. El follaje no es un objeto: es lo que cuelga de las puntas.

- **PoE1/PoE2**: el árbol es **escultura de raíz y corteza**. En el Grelwood la base ES el hero
  asset — raíces tan gruesas como el tronco, torcidas, formando arcos transitables, con musgo,
  helechos y lianas creciendo DE la corteza. Tronco y sotobosque son una sola biomasa continua,
  no un modelo + decals. La copa casi nunca se ve completa: se sale del encuadre o queda en
  silueta negra. PoE resuelve el árbol **de la rodilla para abajo**.
- **Valheim**: el árbol es **poste + esqueleto + láminas**. Geometría humilde (troncos casi
  cilindros, hojas en cards con alfa) pero: el tronco se inclina distinto por instancia, tiene
  muñones de rama muerta, la corteza tiene relieve fuerte por textura, y la copa está calada —
  **se ve el cielo y se ve el tronco a través de ella**. La atmósfera (niebla + backlight) hace
  la otra mitad.
- **El error del pack actual** en una frase: construyó la copa como un SÓLIDO (con núcleo
  relleno y sin agujeros, por contrato explícito del código) y saltó por completo el esqueleto.
  Una copa sólida sobre un poste liso es, geométricamente, una piruleta. Por eso lee como
  "rocas verdes".

---

## Colores

- **Tronco**: NO es un marrón medio plano. En Valheim el tronco es **oscuro y frío**
  (gris-violáceo / marrón apagado, valor bajo) contra una copa **clara y cálida**. La separación
  de VALOR entre tronco y copa iluminada es enorme (aprox. 3:1 o más en luminancia).
- **Copa**: rango de valor amplio DENTRO de la copa, y el eje del rango es **vertical**, no
  radial: parte superior lima/amarillo-dorado quemado por el sol, cara inferior casi negra
  verdosa. En el abedul con niebla la cara inferior de la copa es el valor más oscuro del cuadro.
- **Backlight**: en Black Forest y en las hayas, la luz atraviesa las hojas — el borde de la copa
  contra el sol se vuelve naranja/lima translúcido, no verde. Ese es el color que hace que la
  vegetación "respire".
- **PoE**: desaturado general, tronco casi acromático (gris-verdoso húmedo), y la saturación
  reservada para el acento mágico (musgo azul luminiscente del Grelwood, runas). Consistente con
  `_art_canon.md` §17.2.5.
- **Corteza**: los surcos leen por SOMBRA (oclusión en la grieta), no por cambio de tinte. El
  albedo de la corteza es casi uniforme; lo que la hace corteza es el relieve.

---

## Forma / Silueta

Lo que se ve en las refs, en orden de impacto sobre la lectura:

1. **La base se abre.** El tronco no toca el suelo con un corte perpendicular: se ensancha en
   3-5 lóbulos de raíz que se funden con el terreno (Grelwood, canopy hideout, robles Valheim).
2. **El tronco se dobla y se inclina, distinto por instancia.** En el abedul en niebla, tres
   troncos vecinos se inclinan cada uno hacia un lado distinto, ~8-12° de la vertical. Ninguno
   es recto.
3. **Hay muñones.** Los pinos de Black Forest tienen ramas muertas cortas y horizontales
   sobresaliendo del tronco desnudo. Detalle baratísimo, enorme ganancia de lectura: dice
   "esto creció" en vez de "esto es un cilindro".
4. **Las ramas primarias se ven a través de la copa.** En hayas y abedules las ramas cruzan la
   masa verde como líneas oscuras. La copa es un VELO sobre un esqueleto, no un bloque.
5. **La copa está calada.** Agujeros de cielo en todo el interior del contorno, y el contorno
   mismo tiene entrantes cóncavos profundos. Nunca es un óvalo convexo cerrado.
6. **El follaje cuelga hacia abajo o hacia afuera desde las puntas.** Frondas caídas en el
   abeto, láminas horizontales en las hayas. Nunca una esfera centrada en un punto.
7. **Asimetría.** Ninguna copa de las refs es simétrica alrededor del eje del tronco.

---

## Movimiento / Feel

Fuera de scope de este pase (esto es research de forma, no de animación), pero registrado
porque la convención de refs cubre movimiento:

- Valheim: la copa se mueve como **una sola masa con inercia**, con desfase entre tiers — las
  frondas exteriores atrasan respecto al tronco. El tronco no se mueve.
- PoE: el follaje ambiental es casi estático; el movimiento lo aportan la niebla volumétrica y
  las partículas, no la vegetación.
- **Pendiente**: si se hace wind shader, guardar frames de referencia en `tree_poe/motion/`
  antes de codear, per skill `blender-asset-smith` §"MOTION / PHYSICS references".

---

## Qué capturar para DP

1. **Construir el esqueleto antes que la copa.** Tronco → raíces → ramas primarias → clumps en
   las puntas. Si no hay rama, no hay follaje ahí.
2. **Vaciar la copa.** El follaje va en la cáscara exterior y en las puntas; el interior va hueco
   y se ve el tronco a través.
3. **Calar la silueta.** Agujeros de cielo y entrantes cóncavos son un REQUISITO, no ruido.
4. **La base se abre y se funde con el suelo.** Nunca un corte perpendicular.
5. **Separación de valor vertical**: copa superior clara/cálida, bajocopa casi negro, tronco
   oscuro y frío.
6. **Variación por instancia**: inclinación, asimetría de copa y muñones distintos por árbol.
7. **De PoE específicamente**: la raíz como hero, la corteza de surcos profundos, y la vegetación
   secundaria (musgo/helecho) creciendo DEL árbol.

---

# §B — El PORQUÉ y los PATRONES (reglas con números)

Cada regla es implementable. Fuente al lado. Lo no verificado está marcado.

## B.1 — Base y tronco

**P1 · Ensanche de raíz (root flare).** Un árbol no es un cono apoyado: la base se engrosa en
contrafuertes que reparten la carga de flexión al suelo.
- El diámetro del flare escala LINEALMENTE con el DBH (R² ≥ 0.81 en 10 taxones); cada +1 cm de
  DBH multiplica por 1.049–1.114 la probabilidad de flare/raíz visible. [Urban Forestry & Urban Greening](https://www.sciencedirect.com/science/article/abs/pii/S1618866719307344)
- En árboles con contrafuerte marcado, **69.57% tienen 3–5 raíces contrafuerte** radiando de la
  base, asimétricamente más grandes del lado de mayor carga. [Journal of Plant Ecology](https://academic.oup.com/jpe/article/6/2/187/921212)
- Contrafuertes medidos en *Acer rubrum*: ancho medio 10.4 cm, alto medio 20.3 cm. [Arboriculture & Urban Forestry](https://auf.isa-arbor.com/content/40/4/230)
- **Regla de generador (DERIVADA — ninguna fuente da la fracción limpia)**: radio en z=0 igual a
  **1.5–2.2×** el radio del tronco medido al **10% de la altura**, modulado por **3–5 lóbulos**
  (no un círculo), decayendo a sección circular hacia el **10–15% de la altura**. Un lóbulo más
  grande que los otros, orientado al lado de la copa más pesada.

**P2 · Perfil de conicidad (taper) — NO lineal.**
- Girard form class: el diámetro en la punta del primer tramo comercial es típicamente **78%** del
  DBH; el rango usado en tablas forestales es **0.66–0.86**. [Girard form class](https://en.wikipedia.org/wiki/Girard_form_class), [Ohioline F-74-12](https://ohioline.osu.edu/factsheet/F-74-12)
- Dirección: árbol de bosque = POCA conicidad (más cilíndrico, competencia lo empuja a crecer
  vertical); árbol a campo abierto = MUCHA conicidad. [Tree taper](https://en.wikipedia.org/wiki/Tree_taper)
- **Regla**: `top_r/base_r` sobre el tronco limpio = **0.70–0.85** para forma de bosque,
  **0.45–0.60** para campo abierto (este segundo rango es ESTIMADO — ninguna fuente lo da numérico).
- **Regla de forma (clásica de dendrometría)**: el perfil es **por tramos**, no una recta —
  neiloide en el 0–10% inferior (flare, se abre rápido), paraboloide en el cuerpo, cónico en la
  punta. Un `r = base_r + (top_r-base_r)*u` recto es exactamente lo que produce el "cono perfecto".

**P3 · Sección no circular + inclinación.**
- OBSERVADO en las refs (abedul en niebla, roble): cada tronco se inclina **~8–12°** de la
  vertical en dirección aleatoria por instancia, y la sección no es un círculo regular.
- Truco de producción confirmado: bend/lean con deformador en vez de eje recto; sección irregular
  en vez de círculo perfecto. [Polycount — Tree trunks](https://polycount.com/discussion/137176/tree-trunks)
- El jitter radial actual del pack (±6%) es sub-perceptual: no cuenta.

## B.2 — Ramificación (lo que falta por completo)

**P4 · Regla de Da Vinci / pipe model (Shinozaki 1964).** La suma de las secciones transversales
de las ramas por encima de una bifurcación iguala la sección del tronco por debajo.
[PLOS ONE](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0093535)
- **Número directo**: para una bifurcación simétrica en 2, **d_hijo / d_padre = 1/√2 = 0.707**.
  Para 3 hijos iguales, **1/√3 = 0.577**. General: `d_hijo = d_padre * sqrt(a_i)` con `Σa_i = 1`.
- Desviación real: en *Fagus crenata* la suma de hijas es "un poco mayor" que la madre; en
  *Abies homolepis* casi exacta; en *Quercus petraea* globalmente **<1** con dispersión alta.
  [PLOS ONE](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0093535), [Pipe model theory half a century on](https://pmc.ncbi.nlm.nih.gov/articles/PMC5906905/)
- **UNVERIFIED**: el exponente 1.8–2.3 que se suele citar NO se pudo confirmar en fuente primaria.
  Usar exponente 2 (ratio 0.707) con **±10–15% de jitter** por bifurcación (el jitter es estimación).

**P5 · Ángulo de rama, y cómo cambia con la altura.** Esta es la regla que más "lee" y la más
barata de implementar.
- Rama baja ≈ **85°** del eje del tronco (casi horizontal) · rama media ≈ **45°** · rama alta ≈
  **15–20°** (casi vertical, pegada al líder). [Xtremehorticulture](https://xtremehorticulture.blogspot.com/2020/06/best-branch-angles-are-45-degrees-from.html)
  — *blog hortícola, no paper: tomar los grados como indicativos.*
- Ramas de andamio entrenadas por resistencia estructural: **45–60°** del tronco.
  [University of Kentucky Extension](https://horticulture.mgcafe.uky.edu/sites/horticulture.ca.uky.edu/files/HortFact3011-4.pdf)
- Ángulos de horquilla estrechos = estructuralmente débiles. [Arboriculture & Urban Forestry](https://auf.isa-arbor.com/content/6/4/105)
- El porqué: dominancia apical. Fuerte → hábito ortotrópico → copa excurrente (cónica, conífera).
  Débil → plagiotrópico → copa decurrente (redonda, latifolia). [Apical dominance](https://en.wikipedia.org/wiki/Apical_dominance)
- **Regla**: `ángulo(u) = lerp(85°, 18°, u)` donde `u` = fracción de altura del punto de inserción.

**P6 · Distribución radial de ramas.** Ángulo de divergencia áureo **137.5°**; aproximaciones
racionales reales **1/2, 1/3, 2/5, 3/8, 5/13**. [Plant Cell & Environment](https://onlinelibrary.wiley.com/doi/10.1111/j.1365-3040.2004.01185.x), [Scientific Reports](https://www.nature.com/articles/srep15358)
- **Regla**: rama *i* a azimut `i * 137.5° + jitter(±20°)`. Nunca `2π·i/n` (eso da simetría de
  rueda, que es lo que hace `cluster_lobes` hoy).

**P7 · Altura de la primera rama viva (Live Crown Ratio).** LCR = largo de copa / altura total.
- Dominante/codominante típicamente **LCR > 35–40%**; Douglas-fir con **LCR > 50%** = dominante
  bien iluminado; **LCR < 30%** = suprimido/baja vigor. Bajo ~30% la capacidad fotosintética cae
  fuerte. [Forest Measurements §5.3 (Open Oregon)](https://openoregon.pressbooks.pub/forestmeasurements/chapter/5-4-live-crown-ratio/)
- **UNVERIFIED (estimación)**: campo abierto retiene copa mucho más abajo, LCR ~**0.7–0.9**;
  bosque cerrado se auto-poda a LCR ~**0.2–0.4**. Dirección es conocimiento forestal estándar;
  el número no se pudo verificar.
- **Regla para pradera (P1 del juego = campo abierto)**: primera rama al **10–30%** de la altura,
  LCR objetivo **0.65–0.85**. Para árbol de borde de bosque: primera rama al 50–65%.

**P8 · Cantidad de ramas primarias.** **NO VERIFICADO** — ninguna fuente da un conteo para
latifolia madura silvestre. Lo OBSERVADO en las refs: roble Valheim = 1 bifurcación en Y
(2 líderes); abedul = 3–5 primarias visibles; haya = 4–6. **Usar 3–5 y marcarlo como elección
de arte, no como dato.**

## B.3 — Dónde va realmente el follaje

**P9 · El follaje vive en la cáscara exterior; el interior va HUECO.**
- Las copas desarrollan un **"bare inner core"** que crece con la edad; núcleos vacíos chicos =
  copas eficientes, grandes = ineficientes. [Utah State — Forest production and the organization of foliage within crowns](https://digitalcommons.usu.edu/wild_facpub/2177)
- El porqué: el auto-sombreado es caro, así que el árbol pone hoja nueva en el exterior. Algunas
  especies mantienen hoja interior en "short shoots" justamente porque abaratan la hoja sombreada
  — es la EXCEPCIÓN, no la regla. [New Phytologist / PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC10107860/)
- **UNVERIFIED**: no se encontró un número de "espesor de cáscara / radio de copa".
- **Regla**: cero geometría de follaje a menos de ~0.6R del centro de un clump; los clumps se
  anclan en PUNTAS de rama, no alrededor de un centro.

**P10 · Porosidad de copa.** Fracción de hueco VOLUMÉTRICA de copa: **95.3%–98.5%** (5 especies,
escaneo láser terrestre). [PMC — A reinterpretation of the gap fraction of tree crowns](https://pmc.ncbi.nlm.nih.gov/articles/PMC9939530/)
- ⚠️ **No confundir con silueta 2D**: ese 95–98% es aire dentro de la envolvente, la mayoría
  invisible en contorno. Para agujeros de cielo en silueta usar un valor mucho menor.
- **OBSERVADO en las refs (no fuente)**: apuntar a **20–40%** del área de la envolvente de copa
  dejando ver cielo, con **≥3–5 entrantes cóncavos** que rompan el contorno.

**P11 · Asimetría por competencia de luz.** ~**90%** de los árboles al borde de un claro extienden
medible su copa hacia el centro del claro, con índices de asimetría "mucho mayores" que en dosel
cerrado. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0378112720310586), [Journal of Forestry Research](https://link.springer.com/article/10.1007/s11676-020-01180-0)
- **Regla**: desplazar el centroide de copa **10–25%** del radio de copa en una dirección
  aleatoria por instancia; alargar las ramas de ese lado y acortar las opuestas.

**P12 · Proporciones de copa.**
- Roble/plátano urbano: **diámetro de copa ≈ 24–27 × DBH**. [Urban Forestry & Urban Greening](https://www.sciencedirect.com/science/article/abs/pii/S1618866718305144)
- Latifolias tienden proporcionalmente a copa más ancha que coníferas de tronco comparable;
  coníferas tienen largo de copa > ancho de copa (silueta alargada vertical). [MDPI Forests](https://www.mdpi.com/1999-4907/15/4/633)
- **UNVERIFIED**: no se encontró la tripleta limpia ancho:alto:altura total por forma. Follow-up
  si el generador la necesita exacta.

## B.4 — Técnica low-poly (cómo lo logran los juegos)

**P13 · Presupuesto de triángulos por rol.** Background **50–800** tris · midground **800–3.000** ·
foreground/interactivo **3.000–10.000** · hero **10k–50k+**. [CGAxis Polygon Count Guide 2026](https://cgaxis.com/polygon-count-guide-how-many-polys-do-you-really-need-in-2026/)
- Packs low-poly de árbol realmente publicados: **300–1.800** tris/modelo; ejemplo mínimo **352 tris
  / 186 verts**. [Low Poly Tree Fantasy Pack](https://arludus.itch.io/low-poly-tree-fantasy-pack), [51+ Low Poly Tree bundle](https://yohansoulforge.itch.io/51-low-poly-tree-asset-bundle) *(listings de marketplace, ilustrativos)*
- Árbol SpeedTree stock en UE4 ≈ **25k** tris; para bosque denso se recomienda **≤10k**. Cadena LOD
  real: 15k → 10k → 5k → billboard; otra más agresiva: 115.000 → 13.000 → 2.500 → **32 tris**.
  Regla de escalón: cada LOD baja **≥25%** del anterior. [Polycount — Current and next-gen vegetation](https://polycount.com/discussion/157957/current-and-next-gen-vegetation)
- **Conclusión para DP**: 800 tris es la banda de "background prop". Es suficiente para un árbol
  legible SOLO si cada triángulo va a la silueta (P16).

**P14 · Cards de follaje con alfa vs clumps sólidos.** Los cards con alpha-cutout son el estándar
de industria: *"almost always the best way to get the best silhouettes with the best performance"*.
Un card puede ser una hoja o un racimo entero de rama. [Polycount — Alphas vs Geo for foliage](https://polycount.com/discussion/112248/alphas-vs-geo-for-foliage), [80.lv — Creating Vegetation with Alpha Cards](https://80.lv/articles/human-emotions-creating-vegetation-with-alpha-cards)
- Contrapartida: la geometría sólida se decima bien automáticamente (LOD), los cards no.
- **OBSERVADO**: el abedul y las hayas de Valheim son inequívocamente cards con alfa.

**P15 · Lados del cilindro de tronco: 3–8 bastan — SI hay normal map de corteza.** *(rango de foro,
no norma dura)*. Lo que arregla el facetado NO es más geometría: es el normal map. Los árboles de
Red Dead Redemption 2 son *"practically smooth cylinders with good normals and texture mapping"*.
[Polycount — Tree trunks](https://polycount.com/discussion/137176/tree-trunks)

**P16 · La silueta manda dónde van los triángulos.** *"Silhouette should drive where you put your
triangles… don't waste polys where they don't add to the silhouette."* Técnica: modelar en
flat/matcap para juzgar si la geometría agregada cambia el contorno antes de gastar presupuesto.
[Polycount — Silhouette and Polygon count](https://polycount.com/discussion/185569/silhouette-and-polygon-count), [Polycount — Best Practices for 3D Trees](https://polycount.com/discussion/98091/best-practices-for-creating-3d-trees-for-games)

**P17 · Transferencia de normales desde esfera.** Envolver los clumps de follaje en una esfera
invisible y transferir las normales de la esfera al follaje (Blender: Data Transfer modifier).
Hace que geometría plana/facetada sombree como un volumen redondeado continuo. [SpeedTree Forum](https://forum.speedtree.com/forum/speedtree-modeler/using-the-speedtree-modeler/4868-transfer-normals), [Polycount](https://polycount.com/discussion/125920/correct-vertex-normals-for-foliage)
- Combinado con **SSS/translucency de dos caras** para que la hoja a contraluz brille — junto con
  el albedo, es una de las dos entradas de shader que más definen el look "esponjoso".
  [80.lv — Meadows: Stylized Nature in UE4](https://80.lv/articles/meadows-creating-stylized-nature-in-ue4)

**P18 · Cómo hacer que un tronco low-poly NO parezca un cono liso.** (a) muescas/surcos modelados
(caro, solo hero); (b) sección transversal no circular; (c) doblez/inclinación real en vez de eje
recto; (d) AO horneado a vertex color oscureciendo la base — un pack de pino publicado *"uses
vertex color with the R channel for baked AO"*. [Vertex Color Trees set](https://vertexcat.itch.io/vertex-color-trees-set) *(tutorial/indie, no autoridad de industria)*

**P19 · Muñones de rama muerta (OBSERVADO, sin fuente).** Los pinos de Black Forest llevan ramas
muertas cortas horizontales a lo largo del tronco desnudo. ~8–12 tris cada uno. Es la mejor
relación lectura/triángulo de toda la lista.

---

# §C — Tabla de gaps: `build_tree_pack.py` vs los patrones

Archivo juzgado: `game/tools/blender/tree_pack/build_tree_pack.py` (983 líneas, leído completo).

| # | Patrón | Estado | Evidencia (`file:line`) |
|---|---|---|---|
| P1 | Root flare, 3–5 lóbulos, 1.5–2.2× | ❌ **IGNORADO** | `build_tree_pack.py:371` — `r = base_r + (top_r - base_r) * u`. El anillo z=0 es un círculo puro de `base_r`. No existe término de flare en ningún lado. |
| P2 | Perfil de taper por tramos (neiloide/paraboloide/cónico) | ❌ **VIOLADO** | `:371` mismo — interpolación estrictamente lineal = cono perfecto. Es literalmente la queja de Joan. |
| P2b | Ratio `top_r/base_r` 0.45–0.60 (campo abierto) | ✅ **OK** | prairie 0.20/0.32 = **0.63** (`:579`) · tall 0.60 (`:637`) · wide 0.68 (`:659`) · young 0.69 (`:678`) · dry 0.58 (`:697`). El ratio no es el problema; el PERFIL sí. |
| P3 | Inclinación 8–12°, sección no circular | ⚠️ **PARCIAL/inefectivo** | `bends` existe (`:365-369`) pero magnitudes 0.15–0.42 m sobre troncos de 4.5–5.4 m = **3–9°**, y el jitter radial es `jitter=0.06` (`:346`, `:375`) = ±6%. Ambos por debajo del umbral perceptual — el render los muestra como recto y circular. |
| P4 | Pipe model, `d_hijo/d_padre = 0.707` | ❌ **IGNORADO — no existe jerarquía de ramas** | `build_trunk` (`:345-408`) genera SOLO un cilindro. No hay recursión, no hay hijos. |
| P5 | Ángulo de rama 85°→18° según altura | ❌ **IGNORADO** | No hay ramas. Lo único parecido, `add_twig` en `build_tree_dry`, usa `elev = rng.uniform(0.10, 0.90)` (`:727`) — elevación aleatoria sin relación con la altura de inserción. |
| P6 | Divergencia 137.5° | ❌ **IGNORADO** | `cluster_lobes:445` — `ang = 2π·i/n + uniform(-0.15, 0.15)`: reparto en rueda perfectamente simétrico. Es lo contrario de filotaxis. |
| P7 | LCR 0.65–0.85 para árbol de pradera | ⚠️ **PARCIAL — forma equivocada de bioma** | prairie: tronco 5.4 m (`:578`), ancla de copa a 5.4−0.38·1.723 ≈ **4.75 m** (`:584`, `anchor_canopy_center:548-557`); con `core_dist_range` hasta 0.90R y `elev∈(-1.0, 0.5)` (`:268`) la copa va de ≈3.1 a ≈5.9 m → **LCR ≈ 0.45**. Eso es forma de árbol de BOSQUE puesto en una PRADERA. El render lo confirma: bare-trunk 62% de la silueta. |
| P8 | 3–5 ramas primarias | ❌ **IGNORADO** | Cero en 4 de 5 variantes. `build_tree_dry` intenta 3 twigs (`:723`) pero los enraíza **DENTRO de los blobs de follaje** (`:725-734`), no en el tronco, y los capa a `0.85·R` (`:742`) por diseño explícito: *"twigs are a texture accent, not a second silhouette element"* (`:717-718`). |
| P9 | Interior de copa hueco, follaje en cáscara | ❌ **VIOLADO — por contrato explícito** | `build_lobe_mass:249-255` siembra un **NÚCLEO** sólido de radio `R*0.62` (`nucleus_frac`, `:226`) por lóbulo; el docstring (`:233-236`) dice que existe *"so a solid connected core exists"*. Los dabs core muestrean desde `0.45R` (`:227`). Es exactamente la inversa de la regla botánica. |
| P10 | Agujeros de cielo 20–40%, entrantes cóncavos | ❌ **VIOLADO — imposible por construcción** | `enforce_overlap:107` (`min_frac=0.55, max_frac=0.65`) empuja cada dab a tocar a su vecino; y el **safety stitch** (`:318-336`) inserta un blob NUEVO para cerrar cualquier hueco restante entre lóbulos. El generador tiene "sin agujeros" como invariante de diseño. |
| P11 | Asimetría 10–25% hacia la luz | ❌ **IGNORADO** | `cluster_lobes:441-449` es radialmente simétrico; los jitters (±0.15 rad, ±0.12·R_avg) son ruido, no sesgo direccional. No hay parámetro de dirección de sol en todo el archivo. |
| P12 | Copa ≈ 24–27 × DBH | ❌ **VIOLADO (~2.5× angosto)** | prairie: `ring_r = 0.48·1.723/sin(60°) = 0.955`; span de copa ≈ 2·(0.955+1.85) = **5.6 m**. DBH (a 1.3 m sobre taper lineal `:371`) ≈ 0.58 m → **copa/DBH ≈ 9.6×**. Objetivo 24–27×. O la copa es ~2.6× muy angosta o el tronco ~2.6× muy grueso. |
| P13 | ≤800 tris = banda background | ✅ **OK** | Presupuesto declarado en el docstring (`:53`), `count_tris` en `:493`. |
| P14 | Cards de follaje con alfa | ❌ **IGNORADO** (bloqueado por constraint) | `add_core_blob:192-214` = icoesferas; `add_blob_dab:134-158` = bipirámides. Clumps sólidos, cero cards. Sin texturas no hay alfa posible. |
| P15 | 3–8 lados + normal map de corteza | ⚠️ **PARCIAL / mitad bloqueada** | `sides=6..8` (`:580, :638, :660, :679, :698`) está dentro del rango — pero el arreglo del facetado (normal map) no existe: sin UVs, sin texturas. |
| P16 | La silueta manda los triángulos | ❌ **VIOLADO** | El núcleo (`:253`) es una icoesfera `subdivisions=1` ≈ **80 tris** que nunca toca la silueta, por lóbulo. En prairie (3 lóbulos) son ~240 tris de **30% del presupuesto** gastados en interior invisible, más los dabs core a 0.45R. |
| P17 | Transferencia de normales desde esfera | ❌ **IGNORADO / incompatible** | `finalize_mesh:487` — `p.use_smooth = False` fuerza flat shading en todo el pack. Es lo opuesto exacto del truco. |
| P18 | Corteza: surcos / sección irregular / AO en base | ⚠️ **PARCIAL (solo el gradiente)** | Hay gradiente vertical oscuro→claro (`:379` + `TRUNK_DARK/TRUNK_LIGHT :521-522`), que es medio AO. Pero no hay muescas, ni sección irregular útil (`jitter=0.06`), ni oscurecimiento localizado en el encuentro con el suelo. |
| P19 | Muñones de rama muerta | ❌ **IGNORADO** | No existen. |
| — | Separación de valor copa-arriba / bajocopa | ⚠️ **PARCIAL** | `sample_dir:268` sesga dabs hacia abajo (`elev ∈ (-1.0, 0.5)`), pero el brillo se calcula por **distancia radial** (`bright_t = 0.35 + 0.35·dist/R`, `:283`), no por altura. Resultado: los dabs de la cara INFERIOR salen tan brillantes como los de arriba. No hay término de "vector arriba" en el color. |
| — | Variación por instancia (`_art_canon.md` §17.2.4) | ❌ **VIOLADO** | El pack exporta 5 GLB fijos. `floor1_prairie` solo los escala. Cada `tree_prairie_01` del mapa es el MISMO mesh. |

**Resumen**: de 21 patrones — **2 OK**, **6 parciales**, **13 ignorados o violados**. De los 13,
**9 son gratis o casi gratis** dentro de las constraints actuales (ver §D).

---

# §D — Buildability: qué entra en ≤800 tris / flat-shaded / FLOAT_COLOR / sin texturas

| Patrón | ¿Entra en las constraints actuales? | Costo / nota |
|---|---|---|
| P1 root flare | ✅ **SÍ** | 1–2 anillos extra bajo el 12% de altura con radio modulado por 3–5 lóbulos. ~**+16–28 tris**. |
| P2 perfil de taper curvo | ✅ **SÍ — gratis** | Solo cambiar la fórmula de radio en `:371`. Cero tris extra. |
| P3 inclinación + sección irregular | ✅ **SÍ — gratis** | Subir la magnitud de `bends` (3–9° → 8–12°) y el `jitter` de 0.06 a ~0.15–0.20 con perfil no uniforme por lado. |
| P4 pipe model 0.707 | ✅ **SÍ** | Es aritmética, no geometría. |
| P5 ángulo de rama por altura | ✅ **SÍ** | Ídem. |
| P6 divergencia 137.5° | ✅ **SÍ — gratis** | Reemplazar `2π·i/n` en `:445`. |
| P7 LCR de pradera | ✅ **SÍ — gratis** | Parámetro. |
| P8 3–5 ramas primarias | ✅ **SÍ, con reasignación** | Prisma cónico de 4 lados × 3 segmentos ≈ **24–30 tris/rama** → 4 primarias ≈ **100–120 tris**. Sale del presupuesto que hoy se va en el núcleo interior (~240 tris en prairie). **Es un intercambio, no un aumento.** |
| P9 interior hueco | ✅ **SÍ — AHORRA tris** | Borrar el núcleo (`:249-255`) y subir `core_dist_range` a ~(0.85, 1.05). Libera ~240 tris en prairie. |
| P10 agujeros de cielo | ✅ **SÍ — gratis** | Relajar `enforce_overlap` y **borrar el safety stitch** (`:318-336`). ⚠️ Contradice el contrato heredado de `bush_pack` — es un **cambio de política deliberado**, no un bugfix. Un arbusto sí quiere ser sólido; un árbol no. |
| P11 asimetría de copa | ✅ **SÍ — gratis** | Offset de centroide por instancia. |
| P12 copa 24–27× DBH | ✅ **SÍ — gratis** | Parámetros (ensanchar copa y/o adelgazar tronco). |
| P19 muñones | ✅ **SÍ** | ~**8–12 tris** cada uno; 3–4 por árbol = ~40 tris. Mejor lectura/triángulo de la lista. |
| Separación de valor vertical | ✅ **SÍ — gratis, alto impacto** | Añadir un término `dot(normal_o_posición_relativa, +Z)` al cálculo de color en `:283` y `:302`. Vertex color puro, sin texturas. **Probablemente el arreglo más barato con más retorno visual de todos.** |
| **P14 cards de follaje con alfa** | ❌ **REQUIERE relajar la constraint** | Un card necesita UV + textura con canal alfa. Sin texturas la única alternativa es el clump sólido — **que es justamente lo que produjo las "rocas verdes"**. Esta es la limitación #1 que impone el "sin texturas". |
| **P15 normal map de corteza** | ❌ **REQUIERE relajar la constraint** | Sin UVs ni texturas no hay normal map. El sustituto —modelar los surcos— cuesta cientos de tris que no hay. Un cilindro de 8 lados con vertex color **no puede** leerse como corteza. Limitación #2. |
| **P17 transferencia de normales** | ❌ **BLOQUEADO por `use_smooth = False`** (`:487`) | El flat shading prohíbe el truco por definición. Sin él, cada clump de follaje se lee como un poliedro individual iluminado como poliedro — **exactamente el defecto que Joan describió**. Limitación #3. |
| SSS / translucency de hoja a contraluz | ❌ **REQUIERE material nuevo** | El material es un Principled con `Attribute("Col")` → Base Color (`:502-515`). No hay transmisión. El backlight lima/naranja que hace respirar a Valheim y PoE es imposible hoy. Limitación #4. |
| P18 relieve de corteza | ⚠️ **Mitad** | Sección irregular y AO de base: sí, gratis. Surcos reales: no. |

### Veredicto de buildability

**9 de los 13 patrones incumplidos son gratis o se pagan reciclando triángulos que hoy se
desperdician en geometría interior invisible.** Un rebuild que solo aplique esos 9 (flare, taper
curvo, inclinación real, esqueleto de 3–5 ramas con 0.707 y 85°→18°, filotaxis, copa hueca,
agujeros de cielo, asimetría, muñones, valor vertical) cabe dentro de ≤800 tris, flat-shaded y
vertex color. **Eso resuelve la queja de Joan: "tronco liso sin ramas" y "esferas de hojas".**

**Lo que el flat-shaded/sin-texturas le está costando** (y que NINGÚN rebuild geométrico
compensa): corteza (P15), cards de follaje (P14), iluminación de follaje como volumen (P17) y
translucidez a contraluz. Es decir: **la mitad "material" de la fórmula Valheim que `_art_canon.md`
§17 declara canon.** Ver §E.

---

# §E — Qué dice `_art_canon.md` §17 vs qué hicieron los packs

Leído `game/docs/art/_art_canon.md:1328-1431`. Lo que §17 **manda** hoy:

- **§17.1** (`:1352-1357`): *"Modelo de fidelidad = Valheim… geometría low-poly humilde +
  **materiales pintados ricos** + luz/atmósfera dramática… El presupuesto de detalle va a
  **MATERIAL y LUZ**, no a polycount. **'Low poly total' (texturas planas) queda oficialmente
  enterrado.**"*
- **§17.2.1** (`:1361-1364`): *"**Silueta = geometría, superficie = textura.** … Si solo cambia
  cómo juega la luz (grabado, veta, pelo…) → **albedo + normal map**."*
- **§17.2.2** (`:1365-1368`): *"**Textura de imagen real, no solo ruido procedural.** Nodos de
  ruido dan 'moteado', nunca tierra/madera/paja — esos materiales tienen ESTRUCTURA. Fuente:
  PolyHaven CC0."*
- **§17.2.4** (`:1374-1376`): *"**Variación por instancia, nunca clone stamp.**"*
- **§17.3** (`:1391-1402`): *"Mundo (terreno, arquitectura, props, criaturas): **sombreado suave
  PBR** — respuesta de luz continua y realista, como PoE y Valheim (**ninguno de los dos usa
  cel-shading en el mundo**). DP_ToonGrounded's 3-band ramp queda **RETIRADO** para entorno."*

Qué hizo `build_tree_pack.py` (fechado **2026-07-28**, tres días DESPUÉS de la decisión de §17.3
del 2026-07-25):

| §17 manda | El pack hace | Veredicto |
|---|---|---|
| Superficie = **textura** (§17.2.1) | Sin UVs, sin texturas. Solo `float_color` "Col" → Base Color (`:502-515`) | ❌ **Contradice** |
| **Textura de imagen real**, PolyHaven (§17.2.2) | Ni textura ni ruido — color plano por vértice | ❌ **Contradice** |
| **Sombreado suave PBR**, toon ramp retirado (§17.3) | `p.use_smooth = False` en todo el pack (`:487`) | ❌ **Contradice, y va MÁS LEJOS** que el toon ramp que §17.3 acababa de retirar: flat shading es aún más duro que una rampa de 3 bandas |
| **"Texturas planas queda enterrado"** (§17.1) | El pack ES texturas planas (vertex color plano, flat shading) | ❌ **Contradice el enunciado literal** |
| **Variación por instancia** (§17.2.4) | 5 GLB fijos, escalados en el scatter | ❌ **Contradice** |
| Silueta = geometría (§17.2.1) | Silueta = poste + bola; ~30% del presupuesto en geometría interior invisible (`:249-255`) | ❌ **Contradice** |
| Presupuesto a material y luz, no a polycount (§17.1) | Presupuesto 100% a polycount; material y luz en cero | ❌ **Contradice** |

**Conclusión, sin vueltas**: `tree_pack` (y por extensión `bush_pack`/`flower_pack`, que comparten
la misma familia `DP_ToonGrounded` flat + vertex color) están ejecutando el canon **anterior** al
2026-07-25 — el que §17.1 declara *"oficialmente enterrado"*. La queja de Joan sobre los árboles no
es solo un problema de geometría de árbol: es el síntoma visible de que la parte "materiales ricos"
de la fórmula Valheim **nunca se implementó**, y §17 ya la había mandado.

**Decisión que hay que tomar antes del rebuild** (esto es de Joan, no se decide acá):
- **Opción A — rebuild geométrico dentro de las constraints**: aplica los 9 patrones gratis. Mata
  el "tronco liso sin ramas" y las "esferas". Barato, rápido, y el resultado sigue siendo
  flat-shaded sin corteza. **Cumple la crítica de Joan, no cumple §17.**
- **Opción B — rebuild geométrico + relajar material**: lo anterior + UVs en el tronco + textura
  de corteza PolyHaven CC0 + normal map + follaje en cards con alfa + shading suave + normales
  transferidas. **Cumple §17.** Cuesta: UV unwrap del tronco, presupuesto de textura, y romper
  la homogeneidad de la familia `DP_ToonGrounded` (el resto de los packs quedarían desalineados).

---

## Fuente / Fecha

- Research web multi-fuente, 2026-07-29. Imágenes de ArtStation (Patrick Manson, GGG), Steam
  (appid 2694490), Valheim Fandom wiki. URLs completas en la tabla de Imágenes y en cada regla
  de §B.
- Botánica/forestal: PLOS ONE, PMC, Journal of Plant Ecology, Arboriculture & Urban Forestry,
  Open Oregon Forest Measurements, Urban Forestry & Urban Greening.
- Técnica low-poly: Polycount, 80.lv, CGAxis, SpeedTree Forum.
- Código juzgado: `game/tools/blender/tree_pack/build_tree_pack.py` @ 2026-07-28 (983 líneas).
- Canon cruzado: `game/docs/art/_art_canon.md` §17 (`:1328-1431`).
- Refs previas del repo cargadas ANTES de investigar (regla de Joan): `foliage_painterly/`
  (lenguaje de material de follaje painterly), `village_poe_style/` y `poe_visual_bar/`
  (dirección PoE, base de §17), `p2_bosque/` (mood de bosque P2), `biome_landscape/`.

**Relación con refs existentes**: `foliage_painterly/` definió CÓMO se pinta el follaje (masas de
color, value range amplio); este doc define **CÓMO SE CONSTRUYE el árbol** (esqueleto, raíz,
ramas, dónde se cuelga ese follaje). Son complementarios y ambos deben cargarse antes de tocar
`build_tree_pack.py`.
