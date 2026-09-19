# Reference: village_poe_style — Path of Exile art direction pivot (2026-07-20)

Joan's explicit pivot request: MORE Path of Exile (grim, painterly, real), LESS
"animado" (toon/cartoonish). Source: Lioneye's Watch (Act 1 hub town) — the
canonical grim-village screenshot from the PoE Fandom wiki, via MediaWiki API.
Images live in this folder, eyeballed directly.

## Images

| File | What it shows |
|---|---|
| `lioneyes_watch_1.jpg` | Wide town square: stalls, fire pits, NPCs, wet stone paving |
| `lioneyes_watch_2.jpg` | Closer building/market detail |
| `lioneyes_watch_3.jpg` | Stall canvas awning + stone pillars + brazier + noticeboard |

## Qué se VE — el motivo real por el que TODO se lee "color sólido" hoy

This is the missing piece. Compare our current village_gen output to this
reference and the gap is obvious:

- **El suelo NO es un color plano ni siquiera "con ruido"**: es piedra
  ADOQUINADA — losas individuales con juntas oscuras, musgo/mugre en las
  costuras, mojado (reflejo especular). Nuestro terreno hoy es un plano verde
  con manchas de color — nunca va a leer como "tierra" o "piedra" sin
  GEOMETRÍA de losas + una textura de imagen real (no solo nodos de ruido).
- **La lona del toldo tiene TEJIDO visible + desgarros + pandeo real** — no es
  un plano rígido de color. Se lee tela porque cuelga, se arruga, tiene
  bordes deshilachados.
- **Los pilares de piedra tienen JUNTAS DE MORTERO visibles** y una soga real
  enrollada alrededor — otra vez, geometría de detalle + textura de imagen,
  no un cilindro liso con color.
- **El brasero (bracero de metal) da luz cálida en un charco muy acotado** —
  el resto de la escena es FRÍO Y OSCURO. Contraste extremo, no el
  "cálido general" que tenemos ahora.
- **Paleta**: prácticamente TODO desaturado (grises, marrones, piedra) salvo
  el fuego. Cero verdes brillantes, cero amarillos alegres — eso es lo que
  significa "menos animado, más PoE."

## La causa raíz técnica (por qué 11 pasadas no resolvieron esto)

`mood_valheim.py` hoy SOLO hace variación procedural (ruido de nodos mezclando
2-3 tonos + bump). Esto puede dar "moteado", pero NUNCA va a leerse como tierra
real, madera real o paja real — porque esos materiales tienen ESTRUCTURA
(vetas direccionales largas, granos de piedra, textura de tejido) que el ruido
procedural genérico no reproduce. La solución real es TEXTURAS DE IMAGEN
reales (fotografiadas o pintadas), mapeadas por UV o triplanar, sobre la
geometría — como CUALQUIER motor de juego real hace.

## Fuente de texturas recomendada (gratis, CC0, sin licencia que pagar)

**Poly Haven** (polyhaven.com) — biblioteca 100% CC0 de texturas PBR reales
(fotografiadas): tiene "dirt", "wood_planks", "thatch"/"straw" (buscar
"roof_thatch" o similar), "cobblestone", "grass", agua/normal maps. API
pública sin key: `https://api.polyhaven.com/assets?type=textures`. Cada
textura trae mapas diffuse/normal/roughness listos para un Principled BSDF.
Esta es la ruta correcta para resolver "no hay tierra, no hay madera, no hay
paja" de una vez — bajar 5-6 texturas base y conectarlas de verdad, en vez de
seguir iterando nodos de ruido.

## Qué capturar para el generador

1. Reemplazar el terreno plano+ruido por losas de piedra reales (geometría) +
   textura de imagen CC0 de adoquín, con juntas oscuras.
2. Cargar 5-6 texturas Poly Haven (tierra, madera, paja/techo, piedra, pasto)
   y conectarlas vía Image Texture → Principled BSDF en los materiales
   compartidos (`mat()` helper) en vez de solo ruido procedural.
3. Empujar el grade de color hacia desaturado-salvo-fuego (paleta PoE), no el
   verde-pradera saturado actual.
4. Toldos/telas con geometría de pandeo (no plano rígido) + bordes
   deshilachados.
5. Contraste de luz mucho más agresivo: charcos de luz cálida muy acotados
   contra ambiente frío/oscuro — no el "todo bien iluminado" actual.
