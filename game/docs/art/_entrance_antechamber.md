# Antesala de entrada — diseño y decisiones

Estado: **funcional, sin terminar visualmente** (2026-08-01).
Código: `floor1_prairie.gd` → `_build_entrance()`, `_build_entrance_mound()`, `_entrance_shape()`.
Verificación visual: `scenes/dev/entrance_capture.tscn` → `tools/godot/entrance_capture/*.png`.

## Qué es

El jugador **emerge del subsuelo** hacia la pradera. Aparece dentro de una sala
enterrada; al fondo, el portal; sale caminando por un corredor a cielo abierto.

Canon (`_world_canon.md:81`): *"cada piso es portal dimensional... el piso ES otra capa
de realidad que la torre CONECTA"*. No hay distancia física hasta la Ciudad de la Torre,
así que el pasillo **no va** a la ciudad — el portal del fondo **es** la conexión. Joan
(2026-08-01): *"una antesala, no que sea una puerta que conecte ambas altiro"*. Es un
lugar donde se está, no un umbral que se cruza.

## Medidas (contra el maniquí de 1.80 m)

| | |
|---|---|
| Sala | 16 × 14 m, 4.5 m de alto (2.5 jugadores) |
| Vano | 6 m de ancho × 3.5 m de alto (pasan seis de frente) |
| Tierra sobre el techo | ~1.5 m |
| Corredor | 32 m hasta la pradera, pendiente media ~15° |

## La restricción que manda sobre todo

`TERRAIN_RESOLUTION = 96` sobre 600 m ⇒ **un vértice cada 6.25 m**.

Consecuencia dura, aprendida a los golpes en esta sesión: **el mapa de alturas no puede
sostener a la vez una sala enterrada y una puerta**. Cualquier transición del terreno
ocupa una celda entera, y una celda cae dentro de un cuarto de 16 m y lo atraviesa en
diagonal. Las dos ramas del intento:

- Dejar tierra sobre el techo ⇒ la ladera cruza **adentro** de la habitación.
- Sacar la transición de la habitación ⇒ no queda tierra encima: **galpón** sobre el pasto.

**Resolución**: el terreno se excava bajo TODA la huella construida (para que nunca se
meta adentro), y la tierra sobre el techo pasa a ser **geometría** (`_build_entrance_mound`),
que sí puede cortar a filo contra la fachada.

Corolario que costó otra ronda: **la geometría corta en seco solo si le alineás la costura
a mano**. La loma también se muestrea en grilla; una celda a caballo del filo generó una
rampa de tierra SÓLIDA dentro del vano y el jugador no podía salir caminando. Se construye
en dos tramos que se tocan exactamente en la fachada.

Y una tercera de la misma familia: la **boca se alinea a un vértice del terreno**. Si cae
entre dos, la interpolación contra el vecino sin excavar deja el umbral enterrado ~1.8 m
aunque el tallado sea correcto.

## Decisión de material — progresión por piso (Joan, 2026-08-01)

> *"como primer piso, no debería haber cemento quizás, o al menos unos pilares de madera
> más parecido a minas, y a medida que avance los pisos cambiarlo"*

La entrada del piso 1 **no es piedra trabajada ni hormigón**: es un **socavón de mina con
entibado de madera** — postes, dintel de viga, tablones. Rústico, humano, precario.

El material de la entrada **escala con el piso**, y es un termómetro de a dónde llegó el
jugador:

| piso | lenguaje de la entrada |
|---|---|
| 1 — Pradera | madera de entibado, socavón de mina |
| 2-5 | progresivamente más labrado / antiguo / ajeno — a definir |

Encaja con el gradiente de realidad P1→P5 de `_world_seeds_postalpha.md` (familiar → imposible)
y con §17 del canon: **silueta = geometría, superficie = textura**.

## Pendientes

1. **Los taludes tapan la entrada.** Desde el camino no se ve por dónde entrar (reportado
   con captura, 2026-08-01). El perfil del corte tiene que arrancar recto desde la fachada
   con el ancho de la fachada, y recién abrirse hacia afuera más adelante.
2. **Entibado de madera** en vez de las cajas grises (decisión de arriba).
3. **Facetas** visibles en el sombreado del talud — la malla usa paso de 1.5 m.
4. **El pavimento es una cinta blanca lisa** — pide piedra real del motor.
