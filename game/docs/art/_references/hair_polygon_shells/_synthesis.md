# hair_polygon_shells — pelo construido como cáscaras de polígonos (2026-08-13)

**Joan dijo:** *"es como de una sujeta de que le están haciendo el pelo, y se la hacen con polígonos, pero se ve precioso, hay resultado. Esa idea está muy buena para trabajar quizás en el pelo de los personajes."*

Referencia #1 de siete grabadas el 2026-08-13. Es la que toca directo el hueco abierto del guerrero: hoy su pelo es un casquete plano pintado sobre el cuero cabelludo, con borde duro.

## Imágenes

| # | Qué se ve |
|---|---|
| 01 | Cabeza low-poly gris de frente-perfil, con las primeras cáscaras colocadas sobre el cráneo |
| 02 | Vista 3/4: el pelo ya es un conjunto de placas anchas con wireframe visible, siguiendo el volumen del cráneo |
| 03 | Vista lateral/trasera: las placas se superponen en capas, con una cola o mechón separado |

## Síntesis

### Idea
El pelo **no es una superficie continua ni una textura pintada**: es un conjunto de **placas poligonales anchas** — pocas, grandes, deliberadamente facetadas — que se apoyan sobre el cráneo siguiendo su curvatura. Cada placa es un mechón. El volumen sale de cómo se superponen, no de densidad.

### Forma
- Placas anchas y planas, no tiras finas. Se leen como mechones, no como pelos.
- Nacen del cráneo y lo envuelven: la base de cada placa sigue la curva de la cabeza, la punta se despega.
- Se superponen en **capas** — la de atrás asoma entre las de adelante. Ahí está el volumen.
- El silueteado del peinado lo definen los bordes de las placas exteriores, no una malla de contorno.

### Por qué sirve acá
Encaja con el canon del proyecto sin adaptación:
- **Silueta = geometría** (§2.1 de `_char_build_brief.md`): el peinado se lee a distancia por su contorno de placas.
- Es geometría low-poly con material simple — el modelo Valheim del canon vigente.
- Cae del lado determinista del pipeline: colocar placas sobre una superficie conocida es plomería, no pintura a ciegas. El cráneo del cuerpo MPFB ya tiene grupo `scalp` (376 verts) que define exactamente dónde nacen.

### Qué capturar
1. Pocas placas, grandes. Si se necesitan muchas para que se vea bien, el enfoque es otro.
2. La base de cada placa **conformada al cráneo**, no flotando encima.
3. Superposición en capas con un orden claro: nuca → laterales → frente.
4. Un mechón o cola separada como marcador de identidad, no simetría perfecta.

### Contra qué NO sirve
No resuelve pelo largo con física ni barba. Para el guerrero — pelo corto o recogido bajo el trarilonko — es exactamente lo que hace falta.

## Fuente
Grabación de pantalla de Joan, sesión `2026-08-13_03-24-14` (499 frames, Instagram). La sesión original **ya fue borrada** por la auto-limpieza de `capturar.ps1`, que conserva sólo las últimas 3. Estas hojas de contacto son la única copia sobreviviente.
