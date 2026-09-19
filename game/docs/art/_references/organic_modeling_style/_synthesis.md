# organic_modeling_style

**Joan dijo:** "Vienen varios cosas modeladas: primero un limón, después una cebolla — me gusta el estilo de animación así. Aparecen unas flores moradas/violetas. Después un tipo moviendo una manta, animación de manta, como fluido, muy hipnotizante. Y después hay alguien trabajando como en plasticina — muy bonitos los diseños, no son de este mundo, son más abstractos. Ese tipo de dibujos también me gustaría para algún piso."

**Joan agregó (2026-07-18):** también hay una calabaza con dientes. Y el valor no es solo el estilo — es CÓMO MUESTRAN los modelos: "que te sirva para mostrarme a mí, por ejemplo, o para colocar en el bestiario". El formato de presentación (objeto grande + desglose anotado) es referencia en sí mismo.

## Qué contiene (verificado contra los posts originales, 2026-07-18)

- **Limón, cebolla, calabaza con dientes, frasco de vidrio** — autor **a_iwaac** (Instagram), realtime **Eevee en Blender**. Cada post muestra el objeto grande con el DESGLOSE DEL SHADER anotado a mano encima: Solidify, normal map, Base Texture, Roughness, Transmission, Compositing, Grease Pencil — los nodos visibles. **La referencia trae la receta escrita.** Comentario top del post: "we need more expressive 3D art and less UE5 hyperrealism".
- **Flores moradas** — mismo estilo painterly/expresivo.
- **Manta roja fluida** — autor pymo_3d. **NO es Blender: es Cinema4D + ComfyUI** (caption explícita). Anti-nota: el truco no se replica directo; el equivalente Blender es cloth sim + wind + loop vía cache MDD (ver TECNICAS del motor).
- **Plasticina/claymation** — autor handmadehome. **NO es 3D: es escultura física real** (arcilla, guantes, herramienta). Referencia de LOOK a replicar digitalmente (SSS + fingerprint textures + on-2s), no tutorial de técnica.

## Tres usos distintos de esta ref

1. **Estilo de material/render**: painterly expresivo realtime Eevee (a_iwaac) — candidato de dirección "para algún piso" (sin decidir cuál).
2. **Formato de presentación** (pedido explícito de Joan 2026-07-18): objeto centrado + fondo plano de color + desglose anotado = plantilla para (a) mostrar avances de assets a Joan, (b) las fichas del **bestiario in-game** (canon: bestiario estilo "El bestiario de Axlin"). El motor debería tener un preset "showcase/ficha" que renderice cualquier modelo así.
3. **Recetas de shader**: los breakdowns anotados de a_iwaac son recetas directas para el lookdev del motor.

- **Fuente**: reels Instagram. Frames: `ref_01` limón (a_iwaac), `ref_02` cebolla, `ref_03` flor violeta, `ref_04` manta (pymo_3d, C4D), `ref_05` plasticina (handmadehome, físico), `ref_06` calabaza con dientes + breakdown (a_iwaac), `ref_07` frasco de vidrio + breakdown (a_iwaac).

**Aplicación**: preset showcase/ficha en motor-blender + shader painterly Eevee como estilo candidato de piso + fichas de bestiario.
