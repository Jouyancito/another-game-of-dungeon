# Motor Tiers — a qué nivel del motor se construyó cada asset

> Nacido del pedido de Joan (2026-07-29): *"quiero trabajar con el motor al máximo en
> estos diseños... esos diseños los hiciste antes de darte cuenta que no estabas usando
> al máximo el motor, podemos darle una asignación de concepto, quizás motor low cost,
> o motor normal"*.
>
> El motor bpy headless creció mucho entre el primer mob (2026-07-18) y el bioma pradera
> (2026-07-28). Los assets construidos temprano NO son malos por descuido: usan un motor
> que todavía no tenía las técnicas que hoy son estándar. Este doc pone un nombre y un
> criterio MEDIBLE a cada nivel, para saber qué hay que rehacer y qué ya está bien.
>
> Complementa `_mob_style_contract.md` (qué debe LOGRAR un asset) diciendo con qué
> HERRAMIENTAS se construye. El contrato de estilo es el fin; los tiers son el medio.

## Por qué el criterio es medible y no de ojo

El tier NO se asigna mirando el render del build script. Se asigna con el checklist de
abajo, que se verifica leyendo el script y sondeando el GLB exportado.

Esto tiene una razón concreta y dolorosa: el 2026-07-29 se midió que **6 de 7 mobs
exportan con `baseColorFactor` = 1,1,1 (blanco), sin `COLOR_0` y sin texturas** — todo
su shading vive en grafos de nodos procedurales que glTF no puede expresar, así que el
exportador los descarta. Sus renders showcase muestran gel translúcido con burbujas y
caparazones con patrón; el juego recibe domos blancos. Un veredicto de ojo sobre el
showcase aprobó el slime minutos antes de que la medición lo refutara.

Herramienta de verificación: `game/tools/blender/_glb_truth_render.py` — importa el GLB
y lo renderiza con SOLO lo que trae adentro. Reporta `VCOL / mats / tris / altura`.

## Los tres niveles

### M1 — motor low-cost

El nivel del que hay que salir. Marca registrada: **el color no sobrevive el export**.

- Color en grafos de shader nodes (`TexNoise` / `TexVoronoi` / `Mix`) → se pierde al
  exportar, el asset llega blanco al juego.
- Una sola forma fija codeada a mano; el seed (si existe) sólo perturba color.
- Geometría por unión de primitivas diseñadas a mano para tocarse (`object.join()`),
  sin ninguna regla que verifique el contacto.
- Sin presupuesto de tris verificado en build-time.

### M2 — motor normal

El piso aceptable para cualquier asset que entra al juego.

- **Vertex color con `bm.loops.layers.float_color`** (FLOAT_COLOR). Nunca BYTE_COLOR:
  decodifica sRGB al leer sin encodear al escribir, y oscurece los tonos ~12×.
  El material queda `baseColor` blanco × vertex color = color real en Godot.
- Variantes reales por seed: el seed cambia la FORMA, no sólo el color.
- Presupuesto de tris verificado e impreso en el build (`OK` / `!! OVER budget !!`).
- Modelado en **metros reales**; el showcase incluye el poste de referencia de 1.8 m.

### M3 — motor máximo

Lo que hoy sale del motor cuando se lo usa completo. Referencia viva: `tree_pack`,
`bush_pack`, `river_pack`, `rock_pack`, y `golem_guardian/build_golem_guardian.py`.

Todo M2, más:

- **Ruido Perlin desplazando vértices a lo largo de la normal** — lo que separa una roca
  de una esfera achatada. Doble capa (ridge + detail) en `rock_pack`.
- **Adyacencia cuantificada entre masas**: separación entre centros de blobs
  ≤ 0.55–0.65× la suma de radios consecutivos. El contacto nominal de esferas NO alcanza
  una vez que el ruido talla la superficie — abajo de ese umbral se lee como una masa,
  arriba como piedras flotando. No es predecible por matemática de bounding box, sólo por
  render.
- **Silueta rota a propósito** (`notch_deg` / `outlier_deg`): detalle que sobresale del
  envelope hasta 1.08× el radio, para meter muescas en el contorno. Una masa vegetal real
  nunca es un círculo limpio.
- **Tinte independiente por lóbulo/parte** (deriva ±20% por canal), no un gradiente fijo.
- **Posado sobre terreno con ruido** (`_ground_common.ground_height()`), no plantado en
  Z=0 plano.
- **QA honesto en el propio build**: render a altura de ojo del jugador (cámara 1.65 m,
  ~6 m de distancia) además del hero. Este render nació de un bug real: el tree_pack
  shipeó semanas a escala de arbusto (~2.3 m) porque ningún render tenía referencia de
  altura.
- **Varias pasadas render → mirar → corregir** antes de declarar el asset listo. Los packs
  buenos necesitaron 4-5; ninguno salió bien en la primera.

## Asignación actual

Medido 2026-07-29 leyendo los build scripts + sondeando los GLB.

| Asset | Tier | Evidencia |
|---|---|---|
| `tree_pack` | **M3** | FLOAT_COLOR + tinte per-lóbulo, 5 siluetas por seed, notch/outlier, tri-budget, render a altura de ojo |
| `bush_pack` | **M3** | FLOAT_COLOR, adyacencia `enforce_overlap`, notch/outlier, 5 variantes, tri-budget |
| `river_pack` | **M3** | FLOAT_COLOR, Perlin por vértice + split wet/dry por cara, 5 variantes, tri-budget |
| `rock_pack` | **M3** | FLOAT_COLOR, Perlin doble capa (ridge+detail), 6 variantes, taper/flatten/carve |
| `golem_guardian` | **M3** | FLOAT_COLOR con el fix de sRGB, `make_rock` noise-displaced, animación con curvas de cascada (peso/lag) |
| `flower_pack` | M2+ | FLOAT_COLOR, 6 variantes por seed; sin ruido de superficie (escala mínima, no lo necesita) |
| `grass_pack` | M2+ | FLOAT_COLOR vía `motor-blender/recetas/biome_vcol`; primer consumidor de la librería nueva |
| `gen_golem*.py` (raíz) | M2 | Bevel + boolean UNION + remesh voxel + subsurf (técnicas que nadie más usa), pero **BYTE_COLOR** — anterior al fix |
| `rat` | **M1+** | Único mob con vertex color, pero BYTE_COLOR (`build_rat.py:247`) → tonos ~12× oscuros. Shape keys por campos continuos |
| `snake` | **M1** | Mejor geometría del lote (generador paramétrico spine+loft, no primitivas), pero VCOL ausente → llega blanco |
| `turtle` | **M1** | Arquitectura de shape keys madura (rangos por parte), pero VCOL ausente → llega blanco |
| `bird_prey` | **M1** | Loft curvo real en el pico, ala festoneada; VCOL ausente → llega blanco |
| `wasp` | **M1** | Primitivas + card de ala; VCOL ausente → llega blanco (sólo el ojo tiene color) |
| `slime` | **M1** | UV-sphere deformada a mano, forma única; VCOL ausente → **domo blanco en el juego** |
| `king_slime` | **M1** | `slime` × 2.2 + corona de primitivas; mismos gaps |

## Reglas

1. **Todo asset nuevo arranca en M3.** No existe "lo hago rápido en M1 y lo mejoro
   después" — el rehacer cuesta más que el hacer bien.
2. **Ningún asset entra al juego en M1.** M2 es el piso: si el color no sobrevive el
   export, el asset no está terminado.
3. **El veredicto se emite sobre el truth render, nunca sobre el showcase del build
   script.** El showcase muestra Blender; el truth render muestra el juego.
4. **Ningún veredicto sin un número al lado** (regla madre del `visual_gate`). Para
   assets del motor los números mínimos son `VCOL / mats / tris / altura`.

## Deuda de infraestructura que mantiene esto vivo

Hoy los helpers de M3 están **copy-pasteados** entre `bush_pack`, `tree_pack`,
`river_pack` y `flower_pack` — `tree_pack/build_tree_pack.py:21-26` lo admite explícito
("*its proven helpers are reused directly... does NOT reinvent any of them*", o sea se
copió el archivo). Eso hace que un asset nuevo pueda arrancar en M1 sin querer, sólo por
no copiar de la fuente correcta.

La migración a librería compartida arrancó el 2026-07-29 en `~/motor-blender/recetas/`
(`biome_vcol.py`, `biome_mass.py`, `biome_stem.py`, `glb_export.py`), con `grass_pack`
como único consumidor. `biome_vcol.py` es el modelo a seguir: documenta que es *"the ONLY
sanctioned way to create a per-vertex color layer in this motor... BYTE_COLOR is
structurally unreachable from here"* — mata la clase entera de bug por diseño en vez de
por disciplina.

Falta extraer y adoptar:

1. `finalize_vcol_mesh` + `vcol_material` — existe, falta que los 5 packs lo consuman.
2. La familia blob/dab/lobe-mass (`add_blob_dab`, `add_core_blob`, `build_lobe_mass`,
   `enforce_overlap`) — LA técnica de "lee como masa, no como dispersión".
3. Un generador de roca noise-displaced único — hoy forkeado en `rock_pack`,
   `river_pack`, `gen_golem.py` y `golem_guardian` con firmas distintas.
4. `assert_tri_budget(name, tris, budget)` compartido.
5. Extender `_ground_common` a los mobs (hoy ninguno lo usa; todos se plantan en Z=0).

## Límite que los tiers NO resuelven

`_mob_style_contract.md` §5 es tajante: *"Anatomía orgánica compleja (lobo, zorro,
humanoides) NO se genera por primitivas — packs/sculpt manual."* Subir el tier del motor
no cambia eso. Un bandido humanoide no es trabajo de `gen_*.py` a ningún nivel: va por el
pipeline de `corporeo-3d` (base-mesh → sculpt → retopo → UniRig). El golem es la
excepción sancionada porque geométricamente es pilas de piedra, no anatomía.
