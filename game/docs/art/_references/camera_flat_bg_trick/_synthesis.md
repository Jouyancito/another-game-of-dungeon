# camera_flat_bg_trick

**Joan dijo:** "La tercera es una cámara, o sea, la vista es de una ventana de un tren, pero la imagen que se carga de fondo es solamente una imagen plana y hace un efecto de cámara. Ese tipo de efectos es necesario para que no tengá�is que cargar una escena completa para mostrar algo."

- **Idea**: truco de optimización — vista de ventana de tren donde el fondo es UNA imagen plana (billboard) + efecto de cámara, no geometría 3D cargada.
- **Colores**: cálido/atardecer en el frame capturado.
- **Forma**: plano único con parallax/profundidad falsa vía cámara.
- **Movimiento/Feel**: sensación de movimiento del tren sin costo de escena real.
- **Qué capturar**: la TÉCNICA — cómo simular profundidad/mundo exterior sin cargar geometría real. Relevante para optimización (ventanas, vistas lejanas, fondos de piso).
- **Fuente**: reel Instagram. Frame origen: `frame_00587.png` — **confianza baja**, quedó un thumbnail chico en el board, no el frame completo del clip. Si hace falta más detalle, revisar el video original.

**Aplicación posible**: fondos de piso/ventanas sin costo de render — candidato para perf del mundo.
