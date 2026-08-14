# metal_weld_joints — soldadura en las uniones (2026-08-13)

**Joan dijo:** *"hay un tipo modelando como una cerradura, algo de metal, y le está colocando soldadura en las uniones. Eso me parece que son detalles ultrabonitos, que da mucho realismo a los estilos. Son detallazos. Sería bueno que se pudiera implementar eso en tu pensamiento: si pensás en una jaula, en un muro de metal, una valla de metal, tener en cuenta dónde son los puntos de unión, dónde se sueldan. Quizás no en todas partes, pero en la puerta, por ejemplo. Las bisagras, en partes que sean más llamativas."*

Referencia #5 de siete. Texto en pantalla: **"SPEED MODELING"**.

## Imágenes

| # | Qué se ve |
|---|---|
| 01 | Placa de título "SPEED MODELING" sobre el viewport |
| 02-03 | Mecanismo metálico cilíndrico tipo cerradura/pestillo, en gris de arcilla, con las uniones marcadas |

## Síntesis

### Idea
El realismo no viene de la textura sino de **admitir que la pieza fue fabricada**. Una unión soldada dice que dos partes distintas se juntaron. Sin ese detalle, un objeto metálico se lee como extruido de una sola pieza — que es como se ve casi todo el metal generado por código.

### Forma
- El cordón de soldadura es **geometría**, no un mapa: un bulto irregular que corre a lo largo de la junta.
- Es **irregular a propósito**: ancho variable, no una moldura limpia.
- Aparece sólo donde dos superficies se encuentran en ángulo, no en curvas continuas.

### Regla de aplicación (la parte importante)
Joan es explícito: **no en todas partes**. La soldadura se pone donde el jugador la va a mirar de cerca o donde carga significado:
- **Puertas y rejas** — donde el jugador se detiene.
- **Bisagras** — donde la unión es funcional y visible.
- **Esquinas de jaulas y vallas** — los nodos, no cada tramo.

Sembrar soldadura en cada arista es ruido, y además destruye la lectura de silueta que el canon prioriza.

### Cómo cae en el pipeline
Es hard-surface puro, o sea territorio de `blender-asset-smith`, no de `corporeo-3d`. Y es determinista: dadas dos superficies que se encuentran, la junta es calculable. Un generador de cordón a lo largo de una arista con perfil ruidoso es plomería, no arte a ciegas.

### Qué capturar
1. Cordón como geometría con ancho variable, nunca una línea uniforme.
2. Sólo en juntas seleccionadas: puertas, bisagras, esquinas estructurales.
3. Escala real: un cordón debe verse a la distancia de cámara del juego, o no ponerlo.

## Fuente
Grabación de pantalla, sesión `2026-08-13_03-07-05` (263 frames, Instagram). **Sesión original ya borrada** por la auto-limpieza de `capturar.ps1`. Estas hojas son la única copia sobreviviente.
