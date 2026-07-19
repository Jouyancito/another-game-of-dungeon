# golem_floating — refs 2026-07-19 (9 imágenes, Joan)

**Joan dijo:** "aquí te dejo ref de golems que me parecen bien. Recuerda que sean piedras
flotantes que se mueven en sintonía como si fuera magia levantando las piedras."
También confirmó que la idea de quitarle el tronco para golpearlo (weakpoint) ya
estaba hablada — eso vive en el motion spec del **golem_guardian** (`trunk_rip`),
entidad DISTINTA a esta. Este batch es específicamente para el **golem de piedras
flotantes** (`game/tools/blender/golem_floating/`).

## Lectura por imagen

| # | Qué es | Aporte clave |
|---|---|---|
| 01 | Golem musgoso azul-verde, gancho/ancla en la cabeza, ojos cubiertos de percebes, ojos cyan brillantes | Asimetría, colonización orgánica densa, silueta con "casco" de basura de mar |
| 02 | Render 3D limpio, rocas blancas apiladas con musgo en las juntas | **LA CLAVE ESTRUCTURAL**: torso/brazo-superior/antebrazo/puño/pierna son CLUSTERS DE ROCA DISTINTOS pero leen como UNA figura humanoide coherente — no piedras sueltas orbitando |
| 03 | Concept B&N, manada de golems-árbol caminando, ojos blancos brillantes, ramas tipo cornamenta | Silueta de montículo caminante, grupo/manada, ramas como remate de cabeza |
| 04 | Miniatura, espada clavada en la cabeza, un puño en alto | Figura humanoide clara y compacta, gesto de amenaza legible |
| 05 | Golem estilo WoW parado en agua, bloques con runas talladas, **SEPARACIÓN VISIBLE entre segmentos** (torso/pelvis/piernas flotan con gap chico entre sí) | **Referencia más directa a "piedras flotantes en sintonía"**: cada bloque es su propia pieza, sostenida en posición anatómica correcta por gaps pequeños — la magia se ve en el espacio entre piezas, no en piedras dispersas lejos del cuerpo |
| 06 | Golem con grietas de lava + runes + cristales en hombros/antebrazos, musgo, pose de pie sobre engranajes | Grietas de energía (lava en vez de cyan) + cristales como remate de hombros — acento de "poder" |
| 07 | Miniatura, sosteniendo una roca grande sobre la cabeza como maza | Arma improvisada = otra roca más grande, sugiere que el golem puede EMPUÑAR piedras extra como ataque |
| 08 | Pintura, vides envolviendo el cuerpo, esferas doradas brillantes incrustadas en pecho/hombros, ruinas + agua | Orbes de luz EMBEBIDOS en el cuerpo (no un núcleo único central) + vides |
| 09 | Blockout gris simple, figura humanoide de clusters de roca sobre base circular | Blockout ideal de proporciones: cabeza pequeña, torso ancho, brazos/piernas segmentados, MUY legible como humanoide |

## Síntesis (el esquema)

- **Corrección estructural sobre el build actual**: el `golem_floating` construido
  (commit dd2cc63) es un cúmulo de piedras con distintas fases/órbitas independientes
  — lee como "explosión de rocas", no como una figura. Las refs 02/05/09 muestran
  el camino correcto: **cada parte del cuerpo (torso, brazo, antebrazo, puño, pierna)
  es UN cluster de roca reconocible en su posición anatómica**, con gaps PEQUEÑOS
  entre piezas (la "magia" vive en el gap, no en dispersión).
- **Movimiento**: "se mueven en sintonía como si fuera magia" — las piezas deben
  moverse COORDINADAS (mismo tempo/fase, como una marioneta sostenida por hilos
  invisibles), no cada una con su propio ciclo independiente. Contradice el patrón
  de fases desfasadas del build actual.
- **Colores**: gris-blanco piedra (02, 09) a gris-verde oscuro (01), musgo en las
  JUNTAS/base de cada cluster (no salpicado parejo), acento de energía: cyan (canon
  Joan confirmado ayer) O lava/dorado (06, 08 — variantes a evaluar por bioma).
- **Energía visible**: grietas + runas talladas en los bloques (05, 06) es más rico
  que esferas de luz pegadas por fuera (build actual) — la luz VIENE DE DENTRO de
  la piedra agrietada, no es un objeto aparte flotando.
- **Arma opcional**: sostener una piedra extra como maza (07) — gancho de diseño
  para el ataque, no implementado aún.
- **Qué capturar para DP**:
  1. Silueta humanoide COHERENTE por clusters anatómicos (02/05/09) — prioridad #1.
  2. Gaps pequeños y sincronía de movimiento entre piezas, no órbitas dispersas.
  3. Runas/grietas TALLADAS en la piedra en vez de esferas de glow pegadas.
  4. Musgo concentrado en juntas/base, no salpicado uniforme.
  5. Cyan confirmado (decisión PO 2026-07-19) — 06/08 quedan como referencia de
     variante alternativa (lava/dorado) para otro bioma, no para esta versión.

## GAP vs build actual (dd2cc63)

- ❌ Estructura: piedras sueltas orbitando el núcleo, sin leer brazo/pierna/torso
  reconocibles — las refs piden clusters anatómicos claros.
- ❌ Sincronía: fases desfasadas por grupo (hombro/puño/corona con phase distinta)
  contradice "se mueven en sintonía".
- ❌ Energía: esferas cyan pegadas por fuera de la roca en vez de grietas/runas
  talladas que brillan desde dentro.
- ✅ Color cyan, muerte=derrumbe, silueta jaggeda (displacement) — se mantienen.

**Fuente**: 9 imágenes de Joan, 2026-07-19.
