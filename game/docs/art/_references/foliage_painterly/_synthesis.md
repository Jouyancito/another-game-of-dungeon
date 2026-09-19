# foliage_painterly — cómo debería leerse la naturaleza de fondo

**Joan dijo (2026-07-20):** "Esta imagen es de cómo sería bueno que fuera la naturaleza
de fondo."

- **Idea**: vegetación de fondo (arbustos, follaje, flores silvestres) pintada como
  MASAS DE COLOR con pincelada visible, no hojas individuales modeladas ni textura
  fotorrealista. Gouache/acuarela: el pincel deja blobs de verde oscuro→claro
  superpuestos, con puntitos de flor (amarillo, violeta) esparcidos encima como acento
  final, no integrados en la malla del follaje.
- **Colores**: verde saturado con rango de valor amplio (oscuro en las sombras internas
  del arbusto, casi amarillo-lima en los bordes iluminados) + acento violeta/púrpura en
  las flores (racimo denso, no flores sueltas).
- **Forma**: silueta de "nube" del arbusto — masa orgánica redondeada, sin definir tallo
  por tallo. La pincelada individual (trazos alargados en forma de hoja) da la textura,
  no geometría.
- **Movimiento/Feel**: N/A — referencia de técnica de pintura, no de animación.
- **Qué capturar**: el LENGUAJE DE MATERIAL para vegetación de fondo — value range
  amplio dentro de una masa (no un verde plano), acento de flor como capa final encima,
  silueta de nube/blob en vez de hoja-por-hoja. Aplica al tratamiento de shader/textura
  de árboles y arbustos del piso 1 (y futuros pisos), no a la geometría 3D en sí.
- **Fuente**: captura de video de pintura (proceso de gouache/acuarela), Joan 2026-07-20.

**Relación con refs existentes**: complementa `hand_drawn_palette/` (paleta e
ilustración general) y `nature_anim_style/` (atmósfera) — esta es más específica:
técnica concreta de pincelada para masas de follaje, aplicable al momento de definir
cómo se texturiza/shadea la vegetación del bioma pradera en curso.

**Aplicación posible**: preset de lookdev "painterly foliage" en el motor (textura de
copa de árbol/arbusto con este value-range + blob de pincelada), o como guía de shader
en Godot para el material de follaje del piso 1.
