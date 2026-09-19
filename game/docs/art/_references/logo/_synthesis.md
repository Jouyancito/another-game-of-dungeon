# Reference — `logo`

Base name: **`logo_`**. Todo artefacto sobre el logotipo del juego lleva ese prefijo.

## Fuente

Bocetos a mano del owner (Joan), 2026-07-31. Originales: `Desktop/Juego/bocetos a mano/logo.jpg`
y `logo cerca.jpg`. Copiados acá como `logo_sketch_hand_full.jpg` (hoja completa, incluye el
estudio aparte del portón) y `logo_sketch_hand_closeup.jpg` (detalle del lettering).

## Idea

El título **ANOTHER GAME OF DUNGEON** compuesto en tres líneas de mayúsculas dibujadas a mano,
donde **una letra deja de ser letra y pasa a ser arquitectura del propio dungeon**.

La nota del owner, textual en el boceto:

> *"la «U» debería ser un portón dado vuelta que está abierto"*

Esa es la jugada central del logo: la **U de DUNGEON** no se dibuja como letra sino como un
**portón de doble hoja invertido y abierto**. Las dos hojas del portón hacen de astas verticales
de la U, y el arco del portón queda abajo. El lector reconoce la palabra antes de darse cuenta
de que está mirando una puerta — y esa segunda lectura *es* el logo.

## Forma

- **Composición**: 3 líneas. `another` arriba, `game of` al medio, `DUNGEON` abajo.
- **Jerarquía tipográfica — decidida por el owner 2026-08-01** (corrige el boceto, que era todo
  mayúsculas del mismo cuerpo):

  > *"another game of en minúscula, quizás con letra un poquito más desordenada, y Dungeon en
  > grande, bonito y con el portón."*

  | Línea | Caja | Cuerpo | Acabado |
  |---|---|---|---|
  | `another` / `game of` | **minúscula** | chico | **más desordenado**, suelto, de mano |
  | `DUNGEON` | mayúscula | **grande** (más, no mucho más) | **trabajado y limpio**, con el portón |

  **Esto resuelve solo el problema del ancho de la U.** Con `DUNGEON` en su propia escala, el
  portón manda dentro de su línea sin desentonar contra nada: las otras dos líneas ya viven en
  otro cuerpo y no compiten por ritmo.

  **Y la tipografía cuenta el chiste del título sola**: *another game of* dicho por lo bajo,
  chiquito y desprolijo — la modestia autoconsciente, *otro juego de dungeon más* — y **DUNGEON**
  grande y bien hecho, que es lo que el juego se toma en serio. Humildad arriba, ambición abajo.
  Esa tensión es el logo. No aplanarla haciendo las tres líneas del mismo acabado.
- **Lettering**: trazo manual, irregular, con presión visible y remates sucios. No es una
  tipografía limpia: tiene el pulso de la mano. En `DUNGEON` el pulso está pero controlado.
- **La U-portón**: dos hojas rectangulares verticales, cada una con marco propio, herrajes
  (bisagras, remaches, un tirador o argolla) y paneles interiores. Están **separadas** — el
  portón está *abierto*, y ese hueco entre hojas es la contraforma de la U.
- **Estudio aparte** (esquina de `logo_sketch_hand_full.jpg`): el mismo portón dibujado suelto,
  en perspectiva, con el detalle de los herrajes. Es la referencia de cómo debe leerse la puerta.
- **Motivo repetido — PENDIENTE DE CONFIRMAR**: en el boceto, la **A de ANOTHER** y la **A de
  GAME** también aparecen construidas como bloques verticales altos con divisiones internas,
  emparentados con las hojas del portón. Puede ser intención (un sistema donde varias letras son
  arquitectura) o puede ser el trazo. **Preguntar al owner antes de construir.**

## La puerta se abre — el logo es la transición (owner, 2026-07-31)

**El logo no es una imagen fija: es el portal.**

> *"cuando apriete iniciar o la tecla para comenzar a jugar, que se inicie la animación como
> entrando hacia la puerta de la Dungeon. Ahí quizás podemos dibujar en el logo la puerta cerrada,
> y cuando se inicia el juego, que se abra la puerta, y como que te inicies dentro del menú
> principal."*

Secuencia: logo en reposo con la **puerta cerrada** → el jugador presiona iniciar → **las hojas se
abren** → la cámara **entra por el vano** → estás en el menú principal.

### El problema que esto crea, y su solución (cerrada por el owner 2026-08-01)

Una U necesita hueco. Con el portón **cerrado**, las hojas llenan el vano y la contraforma
desaparece: la palabra corre riesgo de leerse `D_NGEON`.

**Solución del owner, textual:**

> *"quizás las letras deben ser iguales al marco y el relleno del portón sea de otro color, así
> siempre se lee DUNGEON, solo se abre la puerta."*

**El marco del portón lleva EXACTAMENTE el mismo tratamiento que el trazo de las letras** — mismo
color, mismo peso, mismo pulso. Así la U-portón deja de ser un caso especial y es **una letra
más**. El **relleno de las hojas va en otro color**, y entonces se lee como *material adentro de
la letra*, no como parte del trazo.

Consecuencia importante: **la legibilidad ya no depende de la apertura.** `DUNGEON` se lee igual
con la puerta cerrada que abierta. La animación pasa a ser puro golpe de efecto y no puede
romper la lectura — una animación que no puede romper la lectura es una animación segura.

### Profundidad — las hojas se abren, no desaparecen

> *"igual podríamos agregar profundidad para que se sienta que no son puertas que desaparecen,
> sino que se abren, y la idea después sería que la cámara como que entrara a ese portón y
> abriera el menú principal."*

Las hojas tienen **grosor**: giran sobre su bisagra y se les ve el canto. No hacen fade, se abren.

**Consecuencia técnica — arquitectura híbrida.** Un SVG plano puede deformar pero **no** puede
rotar en perspectiva ni dejar que la cámara lo atraviese, y la cámara entrando por el vano es un
movimiento 3D. Por eso:

| Uso | Qué es |
|---|---|
| Marca, ícono, Steam, portada, cualquier uso estático | **Logo plano en SVG** |
| Pantalla de título | El mismo logo plano, pero **las dos hojas son geometría real** alineada al vano de la U, rotando sobre bisagra mientras la cámara avanza |

El resto del logo **no se mueve** — solo la puerta, como pidió el owner.

**Riesgos de ejecución anotados:**
1. Si las hojas 3D llevan luz propia y el logo es plano, el pegote canta. Sombrearlas **planas,
   sin specular**, con el mismo tratamiento del trazo.
2. El vano de la U necesita medidas fijas y publicadas para que el mesh de las hojas calce exacto.
3. El relleno de las hojas tiene que contrastar contra el fondo *y* contra el trazo, o la versión
   cerrada se empasta.

## Dos logos, no uno (owner, 2026-07-31)

| Marca | Qué es | Para qué |
|-------|--------|----------|
| **Grande** | El lettering completo de 3 líneas con la U-portón | Marca del juego, portada, pantalla de título |
| **Chica** | Sin definir — el owner la dejó abierta | Ícono de app, cápsula de Steam, favicon, taskbar |

Propuesta para la chica (**sin confirmar**): **el portón solo, sin letras.** Si el portón es el
elemento memorable, la marca reducida es el portón. Un arco con dos hojas es una silueta simple
que sobrevive a 32 px, donde el lettering completo no.

## Nota técnica — formato

El logo debe **escalar hasta llenar la pantalla** durante la animación de entrada. Eso obliga a
**SVG, no bitmap**. Godot 4 importa SVG nativo y lo escala sin pérdida (verificado en este
proyecto, sesión 2026-04-17: por eso los íconos de skill son SVG y no PNG por resolución).

## Colores

El boceto es lápiz/lapicera sobre papel rayado — **no define paleta**. Sin decidir.
Al definirla, respetar `_art_canon.md` §17 (modelo Valheim: formas simples, materiales y luz ricos).
Insumo posible: `[[hand_drawn_palette]]` — azul/teal luminoso contra oscuridad, trazo suelto.

## Movimiento / feel

Rústico, tallado, de mano. El chiste del logo es visual y silencioso: **la puerta abierta como
invitación a entrar**. Coherente con un dungeon crawler donde el gesto de cruzar el umbral es
la acción fundacional.

El "Another" del título es autoconsciente — *otro juego de dungeon más* — así que el logo puede
permitirse humildad y oficio antes que épica pulida.

## Qué capturar

1. **La U es un portón invertido y abierto.** Es lo innegociable. Si eso no se lee, el logo falló.
2. La ambigüedad letra/puerta debe resolverse a favor de la **legibilidad de la palabra primero**:
   se lee DUNGEON, y recién después se ve la puerta.
3. El trazo a mano, no una fuente de sistema limpia.
4. Los herrajes del portón — bisagras y remaches — son lo que lo vuelve puerta y no rectángulo.

## Estado

**Boceto crudo. Nada construido.** Ver `[[asset/logo]]` en engram.
