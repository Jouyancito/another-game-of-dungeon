# sculpt_2d_to_3d

**Joan dijo (2026-07-27):** "Muestra cómo una persona modela paso a paso a un personaje 2D en Blender... ve el paso a paso que hacen sobre cómo trabajan, e investiga cómo es que tú puedes hacer lo mismo."

## Fuente

Reel Instagram de **emilyjerjian_** (`instagram.com/p/DbQqyjLo4zv/`) — "Yubaba. Second model of the Sunday scaries series" (#blender #spiritedaway). Sculpt de Yubaba (El viaje de Chihiro) partiendo del fotograma 2D original. Capturado de sesión `2026-07-27_15-57-05` (1052 frames). **Nota IP: Yubaba es Ghibli — referencia de TÉCNICA, nunca asset shippable.**

## El workflow observado (paso a paso)

1. **Artwork 2D como fondo camera-locked** — el fotograma original de la película se carga en el viewport y la cámara queda fija sobre él. Todo el modelado se juzga CONTRA el dibujo desde esa vista (ref_01: wireframe de la cabeza calzado sobre el dibujo; ref_02: cuerpo/vestido azul calzado).
2. **Blockout por masas** — esferas/blobs por volumen anatómico (moño de pelo, cara, cuerpo-vestido), calzados contra la silueta del dibujo desde la cámara.
3. **Sculpt interactivo** — brushes (clay strips, inflate, crease) para arrugas, cejas, nariz bulbosa, moños del pelo (ref_04: clay gris del pelo). La forma se refina siempre re-chequeando la vista de cámara.
4. **Paint directo sobre el mesh** — Texture Paint / Color Attributes, muestreando la paleta del artwork 2D y pintando A MANO el sombreado toon del dibujo (sombra de párpado lila, labios, arrugas marcadas) — ref_03, ref_06, ref_07. El sombreado queda HORNEADO en el color, no depende de luces.
5. **Presentación** — orbita el modelo terminado con el artwork 2D de fondo (ref_05): el 3D "sale" del cuadro y desde la vista original es casi indistinguible del dibujo.

## Qué capturar (takeaway para DP)

- **La vista de cámara ES el contrato**: el modelo se construye para clavar la silueta y el color del 2D desde UNA vista canónica; el resto (espalda, 3/4) se resuelve con coherencia, no con fidelidad. Esto es medible → gate visual (render desde la cámara vs artwork = SSIM/ΔE).
- **Sombreado pintado, no iluminado**: el look 2D viene de pintar la sombra en el albedo (vertex color), compatible directo con nuestro pipeline FLOAT_COLOR + toon shader.
- **Pipeline "concepto 2D → personaje 3D"**: es exactamente el eslabón que falta para pasar de arte conceptual (de Joan o generado) a personaje del juego.

## Réplica headless (investigación 2026-07-27)

Lo interactivo (brushes de sculpt) NO es headless-viable; los equivalentes sí:

| Paso de ella | Equivalente headless nuestro |
|---|---|
| Artwork camera-locked | Image plane + cámara fija por script (trivial en bpy) |
| Blockout por masas | Ya probado: blob assembly (golem_guardian, corpóreo) |
| Sculpt a mano | (a) fit de silueta: máscara extraída del 2D → shrinkwrap/ajuste de verts desde la vista de cámara; (b) base automática: SF3D/TRELLIS image-to-3D con el artwork como input (árbol de decisión ya en skill) |
| Paint a mano | **Camera-projection**: proyectar UV desde la cámara y hornear el artwork a FLOAT_COLOR vertex colors → desde la vista canónica el modelo ES el dibujo. Espalda sin data → mirror/paleta plana |
| Juicio de ojo | visual_gate: render desde cámara canónica vs artwork (SSIM/IoU/ΔE) |

**Aplicación**: pipeline de personajes/enemigos desde arte 2D — concepto → base mesh → projection-paint → UniRig → Godot.
