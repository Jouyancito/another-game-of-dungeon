# ancient_pillar — pilar de piedra antigua, resquebrajado, con lianas (2026-08-22)

**Pedido de Joan, textual (2026-08-22):**

> *"los pilares le agregaste una textura que parece piso/tierra, así que se ve raro, debería ser
> quizás de hormigón antiguo, que se note resquebrajado, quizás con unas cuantas lianas, estilo
> como el título"*

Tres cosas en una frase: **material equivocado hoy**, **material correcto**, y **el registro
estilístico** (el del logo).

## El defecto actual

Lo que hay en el juego es `props/outpost/prop_pillar_wood_01.glb` — del pack cívico, y con una
textura que lee como suelo. Un pilar con textura de tierra no lee como pilar: lee como un
cilindro de terreno parado. El material es el problema antes que la forma.

## Proporciones reales — para que no salga ni un poste ni un obelisco

Los órdenes clásicos definen la esbeltez por **diámetros de base**, y ese es el número que hay
que fijar antes de modelar:

| Orden | Altura en diámetros | Lectura |
|---|---|---|
| Toscano (Serlio) | 1 : 6 | achaparrado, pesado |
| **Toscano** | **1 : 7** | **sólido, primitivo — el que corresponde** |
| Dórico | 1 : 8 | el más robusto de los griegos |
| Toscano (Scamozzi) | 1 : 7½ | más esbelto |

**Toscano 1:7.** Es el más sólido de todos los órdenes, sin acanaladuras y sin ornamento — que
es exactamente el registro de una ruina primitiva, no de un templo refinado. Con un diámetro de
base de 0,55 m sale un fuste de **3,85 m**, que contra el poste de 1,80 m del jugador es algo
que hay que mirar hacia arriba sin ser una torre.

El entablamento toscano mide 1,75 diámetros — dato para el pilar *entero*; para una ruina
partida casi siempre no aplica, porque lo que queda es el fuste.

## Material — hormigón antiguo, no piedra pulida ni tierra

Hormigón romano envejecido: gris cálido, **agregado visible** (piedritas embebidas que asoman
donde la superficie se descascaró), manchas de escurrimiento verticales bajo los quiebres.
No es granito pulido ni sillar prolijo.

## Cómo se rompe — el resquebrajamiento es geometría, no textura

Regla del contrato de estilo: **el detalle vive en las muescas de la silueta, no en la
superficie**. Un pilar "resquebrajado" pintado sigue leyendo entero.

- **Corte superior irregular**: la ruina se parte en diagonal o en escalón, nunca en horizontal
  limpia. Ese corte es la firma.
- **Fisuras que ATRAVIESAN el contorno**: una grieta que sólo está en la textura desaparece a
  10 m. Las dos o tres principales tienen que morder el borde.
- **Lascas faltantes** en las aristas, sobre todo en la base y en el corte.
- **Juntas de tambor**: los pilares antiguos se construían por tambores apilados. Una junta
  horizontal marcada a media altura, con un tambor **levemente rotado** respecto del de abajo,
  cuenta la historia entera del asentamiento por dos polígonos.

## Lianas — pocas y con lógica ecológica

Joan dijo *"unas cuantas"*, y el criterio ya está en el canon: las plantas van en **grietas y
zonas bajas**, no espolvoreadas por encima (lección del golem, `_art_canon.md` y el dressing).

- Nacen **de la base y de las fisuras**, no del aire.
- **Dos o tres**, asimétricas — una domina y las otras acompañan.
- Trepan por el lado **sombrío/húmedo**: un solo lado, no un envoltorio parejo.
- Las de arriba caen colgando; las de abajo abrazan.

## Registro estilístico — "estilo como el título"

Joan lo ancla al logo (`_references/logo/`), donde la **U de DUNGEON es un portón invertido y
abierto**: una letra que resulta ser arquitectura. El registro de esos bocetos es de **trazo a
mano, formas macizas, sin filigrana** — arquitectura primitiva y pesada, dibujada, no de CAD.

El pilar tiene que pertenecer a la misma construcción que ese portón: mismo mundo, mismo peso,
misma antigüedad.

## Qué capturar

1. **Toscano 1:7** — 0,55 m de diámetro, 3,85 m de fuste entero.
2. **Hormigón antiguo gris cálido con agregado visible**, no tierra ni granito.
3. **El resquebrajamiento muerde la silueta**: corte superior irregular + 2-3 grietas que
   cruzan el contorno + lascas en las aristas.
4. **Junta de tambor** con rotación leve — la pista más barata de "esto lo construyó alguien".
5. **2-3 lianas** naciendo de grietas y base, de un solo lado.
6. Estados de rotura como variantes (entero / partido a 2/3 / tocón), como ya estaba planeado
   para `gen_pillar` en la skill `blender-asset-smith`.

## Encaje con el canon
`blender-asset-smith` ya tenía `gen_pillar` **planeado** con presupuesto ≤800 tris y la receta
`bmesh.ops.spin` (torno) + bevel + `bisect_plane` para los estados de rotura. Esta ficha le pone
el material y las proporciones que le faltaban.
Hard-surface ⇒ **bespoke habilitado** sin discusión (el scope guard lo permite explícitamente).

## Hueco declarado
- ⌛ Falta referencia visual de ruinas con vegetación que le guste a Joan. Las proporciones y el
  material salen de fuentes; **el registro exacto de cuán destruido**, no.

**Fuente/fecha**: proporciones de los órdenes — Michael Rouchell (Traditional Architecture),
Traditional Building Magazine, Skurman, A Touch of Rome; consultadas 2026-08-22.
Pedido y anclaje estilístico: Joan, 2026-08-22.
