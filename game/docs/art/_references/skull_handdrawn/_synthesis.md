# skull_handdrawn — cráneo dibujado a mano + neón (2026-08-13)

**Joan dijo:** *"es como de un cráneo que está dibujando a mano, que está en blanco y negro. Esa animación igual me parece superbonita. Me parece que si a eso se le aplica el color correspondiente más neón estilo Jinx de League of Legends, sería precioso. Estilo Borderlands. Y estaría bueno un piso de ese estilo."*

Referencia #3 de siete. **Es la única que propone un PISO entero**, no un detalle.

## Imágenes

| # | Qué se ve |
|---|---|
| 01 | Cráneo de criatura dibujándose trazo a trazo en una app de dibujo, blanco y negro, la mano y el lápiz visibles |

## Síntesis

### Idea
El atractivo está en el **trazo visible**: línea de grosor variable, construcción a la vista, cruces de lápiz que no se borran. No es un dibujo limpio — es un dibujo **en proceso** que se deja ver como proceso. Ahí está la personalidad.

### Forma
- Cráneo de criatura, no humano: cuencas enormes, cuernos o crestas, mandíbula pesada.
- Construcción por capas: primero cajas y ejes, después contorno, después sombra por rayado.
- La línea **no es uniforme**: se ensancha en las curvas de peso y adelgaza en las salidas.

### Color propuesto (Joan, no está en la referencia)
La referencia es blanco y negro. Joan quiere sumarle **neón estilo Jinx / Borderlands**: base oscura, línea de tinta gruesa, y acentos saturados que emiten — magenta, cian, verde ácido — sobre esa base.

### Por qué es la más riesgosa de las siete
Borderlands consigue su look con **cel shading + contorno de tinta grueso** sobre geometría normal. El proyecto ya tiene las dos piezas: `toon_basic.gdshader` con rampa de 3 bandas y `toon_outline.gdshader`. No hace falta tecnología nueva — hace falta subir el grosor del contorno y bajar la saturación del ambiente para que el neón destaque.

Pero el canon vigente es **modelo Valheim** (`_art_canon.md` §17): geometría low-poly con materiales ricos y luz dramática. Un piso Borderlands/Jinx es un **registro distinto, no una variación**. Esa es una decisión de canon que Joan tiene que tomar explícitamente, no algo que se cuele por un piso.

### Qué capturar si se hace
1. Contorno de tinta grueso y de peso variable, no uniforme.
2. Base desaturada y oscura para que dos o tres acentos neón carguen toda la lectura.
3. Trazo visible en las texturas: rayado, no ruido procedural (§2.2 del brief: *el ruido procedural no es textura*).
4. Emisión real (`emission_energy`) en los acentos, como ya la usa el material del slime.

## Fuente
Grabación de pantalla, sesión `2026-08-13_03-25-21` (455 frames, Instagram). Sesión original borrada por la auto-limpieza de `capturar.ps1`; esta hoja es la única copia.
