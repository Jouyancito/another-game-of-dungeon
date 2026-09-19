# edge_decals — "pegatinas 3D" sobre los bordes de la geometría (Joan, 2026-08-28)

**Joan dijo:** *"la descripción muestra una forma en que pegatinas hacen cambios a estructuras
para darle como diferentes usos, eso entendí yo, espero que sea algo así."*

**Lo que la técnica ES (corrección del matiz)**: los *edge decals* NO cambian la función ni la
forma de una estructura. Son **detalle visual pegado sobre las aristas** de un módulo (esquinas
desconchadas, grietas, desgaste, remaches) para que **el mismo módulo repetido parezca distinto**
sin geometría nueva. Es una técnica de **variación y costo**, no de "usos": la pared sigue siendo
pared; lo que cambia es que 20 copias no se ven como 20 copias.

Captura: post de `@icebollero3d` (Instagram, hace ~10 semanas) — texto del post + 4 pilares de
hormigón mostrando el flujo: geometría base → duplicar polígonos del área de borde → recortar la
zona del decal → asignar material y ajustar UV.

## Cómo funciona (cada frase termina en un número o una orientación)

- El decal es una **tira de polígonos** copiada de la superficie del módulo, empujada **1-3 mm
  hacia afuera** de la cara para evitar z-fighting, con su propio material: albedo + normal +
  **alpha** (lo que no es grieta es transparente).
- Se coloca **sobre la arista**, envolviendo las dos caras (ancho típico 5-15 cm a escala real
  en una pared de 3 m).
- Se **reutiliza**: la misma tira, rotada, escalada 0,7-1,3× y en otra arista, da variación.
  Con 3-5 decals distintos alcanza para un kit modular de paredes/pilares.
- Costo: pocos triángulos, pero **transparencia alpha = overdraw**. Los comentarios del post lo
  señalan ("ese shader suele ser pesado", "¿y las transparencias?") y tienen razón si se abusa:
  regla práctica, ≤ 2 capas de decal superpuestas en un mismo píxel y decals chicos.

## En Godot 4 (verificado contra el proyecto: hoy 0 usos de `Decal` en `game/scenes/`)

Dos formas, y sirven para cosas distintas:

| Técnica | Qué es | Para qué sirve mejor | Costo |
|---|---|---|---|
| **Nodo `Decal`** (proyectado) | caja que proyecta albedo/normal/ORM sobre cualquier malla debajo | manchas, grietas y humedad en **superficies planas**; se coloca en la escena sin tocar el asset | barato por unidad, pero hay límite de decals visibles por frame (Forward+: 512, se degrada antes); no envuelve aristas bien |
| **Edge decal de malla** (lo del post) | tira de polígonos con material alpha pegada al borde, parte del asset | **esquinas y aristas** desconchadas en kits modulares (pilares, marcos, muros de piedra, vigas) | overdraw solo donde está la tira; se hornea en el GLB en Blender, cero trabajo en runtime |

Regla: **arista → decal de malla; cara → nodo Decal.**

## Dónde aplica en Dungeon Party

- Kits modulares que se repiten: muros y pilares de ruinas (`lotr_skyrim/` 04, 14), aldea
  (`village_*`), interiores de taverna (`tavern/`), mazmorra (`dungeon_interior/`).
- Encaja con `_asset_modeling_best_practices.md` (props/estructuras) y con el estilo
  **LOTR × Skyrim** del catálogo (ruina con historia = bordes gastados).
- **No** aplica a orgánico (roca natural, árboles): ahí la variación viene del scatter y el
  hundimiento (`prairie_rivers/` sección 2026-08-28).

## Métrica de éxito (antes de construir)
En un pasillo de 6 módulos iguales, con 4 edge decals reusados: a 3 m ningún par de módulos
adyacentes comparte el mismo patrón de borde (verificado por posición/rotación del decal), y el
costo extra ≤ 200 tris por módulo. Overdraw: ≤ 2 decals superpuestos en cualquier píxel.

## Fuente
Instagram `@icebollero3d`, post sobre edge decals (captura de la descripción + pilares de
ejemplo). Relacionadas: `metal_weld_joints/`, `village_poe_style/`, `dungeon_interior/`.
