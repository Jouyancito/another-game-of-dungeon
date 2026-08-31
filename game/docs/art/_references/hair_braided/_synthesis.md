# hair_braided — pelo trenzado como geometría (2026-08-22)

**Joan dijo:** *"esta última está god para tener de referencia para peinados de npc / mujeres"*
(por `05_pack_15_braided_hairstyles.png`).

Cinco referencias aportadas mientras se trabajaba el undercut del guerrero. **No compiten con
las hair cards con alpha**: cubren un caso que las cards NO resuelven bien — el pelo recogido,
trenzado o en rastas, donde el mechón es un volumen cerrado con torsión, no una cortina de
hebras.

## Imágenes

| # | Archivo | Qué se ve |
|---|---|---|
| 01 | `01_braid_tubes_blender_viewport.png` | Viewport de Blender: rastas/trenzas modeladas como **tubos con relieve de torsión**. 91.804 tris para un peinado — el costo real de la técnica |
| 02 | `02_box_braids_bust.png` | Busto femenino con box braids largas. Cada trenza es un tubo independiente que cae libre |
| 03 | `03_cornrows_bun_profile.png` | Dos perfiles: **cornrows pegadas al cráneo** + moño + trenza larga. El cuero cabelludo SE VE entre las trazas, y ahí está el diseño |
| 04 | `04_single_braid_three_views.png` | Tres vistas de un peinado con trenza única. Sculpt gris: se juzga la forma sin color |
| 05 | `05_pack_15_braided_hairstyles.png` | Pack comercial de 15 peinados trenzados sobre maniquíes. **La referencia de catálogo para NPCs** |

## Síntesis

### Idea
Un mechón trenzado es un **volumen cerrado con torsión periódica**, no una superficie plana.
Por eso las cards con alpha no lo dan: una card es una cortina, y una trenza tiene sección.
La técnica correcta acá es **tubo barrido a lo largo de una curva, con la torsión en el
relieve** — y el relieve se lee en la silueta, no en textura.

### Forma / silueta
- La trenza **cambia de grosor a lo largo**: gruesa en el nacimiento, adelgazando al final,
  rematada en una punta o un atado.
- Las cornrows (03) van **pegadas al cráneo** y siguen líneas paralelas; el cuero cabelludo
  entre ellas es parte del diseño, no un defecto de cobertura. Es la excepción a la regla de
  "no se ve cuero cabelludo".
- Las box braids (02) **cuelgan libres** y se separan entre sí — cada una es su propio objeto
  con su propia caída.
- Un peinado trenzado casi siempre combina **dos zonas**: pegado al cráneo arriba, suelto abajo.

### Costo — el dato que más importa
`01` marca **91.804 triángulos** para un solo peinado. Eso es ~5× el cuerpo entero del guerrero.
Para NPCs esto **no entra tal cual**: hay que bajar la torsión a relieve de pocos segmentos, o
resolverla en normal map (que el techo Skyrim ya habilita, ver `_asset_creation_contract.md` §3b).

### Qué capturar
1. **La trenza es un tubo barrido**, con torsión periódica y taper — no una card.
2. **Dos zonas por peinado**: pegado al cráneo + suelto. Se modelan distinto.
3. **En cornrows el cuero cabelludo visible es diseño**, no falta de cobertura.
4. **El pack 05 es catálogo de NPCs**: sirve para elegir QUÉ peinados existen en el roster,
   antes de modelar ninguno.
5. **Presupuesto**: la referencia está a 91k tris. Nuestro techo obliga a resolver la torsión
   con menos geometría o con normal map.

### Contra qué NO sirve
No reemplaza `hair_undercut_viking/` (el peinado elegido del guerrero) ni las hair cards con
alpha para pelo suelto. Es la referencia para el **eje trenzado/recogido**, que hoy no tiene
ninguna otra.

## Encaje con el canon
La ref 02 del guerrero (`hair_undercut_viking/02_undercut_braids_side.png`) ya tenía trenzas
paralelas y se decidió resolverlas como **valor pintado** porque a tamaño de juego no piden
geometría. Estas referencias muestran el otro extremo de esa decisión: cuando la trenza ES el
peinado (y no un detalle sobre una franja), sí necesita volumen. El criterio de corte sigue
siendo el de siempre — **el tamaño al que se va a ver**.

**Fuente/fecha**: aportadas por Joan, 2026-08-22.
