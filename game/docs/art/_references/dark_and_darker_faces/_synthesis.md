# Dark and Darker — caras, cuerpo base y sistema de personaje

Aportadas por Joan el 2026-08-19, 7 capturas, mientras se trabajaba la forma de los
ojos del guerrero.

> ⚠️ **Las imágenes todavía NO están en esta carpeta.** Llegaron por chat y no quedan
> en disco, así que no se pudieron commitear. Joan: dejalas acá con los nombres de
> abajo y esta síntesis queda anclada a ellas.

| archivo esperado | qué muestra |
|---|---|
| `01_lobby_trio_candlelight.png` | Fighter, Ranger y Cleric en el lobby, luz de vela |
| `02_lobby_ranger_hood.png` | Ranger encapuchado, barba, luz cálida frontal |
| `03_campfire_ranger_wizard.png` | dos personajes junto al fuego, cara iluminada desde abajo |
| `04_campfire_hood_mask.png` | capucha y máscara, penumbra fuerte |
| `05_select_class_fighter.png` | **closeup del Fighter + los 9 retratos de clase** |
| `06_perk_skill_base_clothes.png` | **cuerpo entero con la ropa base de inicio** |
| `07_cosmetics_base_bodies.png` | **modelos base sin ropa: humano, Orc, Elf** |

---

## Idea

Fidelidad **realista pero SUAVE**. No es hiperrealismo tipo RDR2: la piel está
limpia, sin poro visible, sin manchas. Los rasgos son sólidos y bien construidos,
y el detalle fino simplemente no está. Cae entre Skyrim y algo más pulido, y es un
techo **más barato de alcanzar** que el que teníamos fijado.

## Colores

Paleta apagada y cálida. Todo pasa en penumbra: marrones, verdes oliva, beige sucio.
La única fuente saturada es el fuego. Las caras rara vez reciben luz plena.

## Forma

- **Ojos chicos, hundidos, con sombra orbital marcada.** Se ve muy poca esclerótica
  — casi nada de blanco. Confirma exactamente el defecto que teníamos: nuestro globo
  es grande, poco hundido y demasiado brillante.
- **Cejas finas y bien separadas del ojo**, no bloques pesados apoyados encima.
- Barba presente en casi todos los varones. El lampiño es la excepción, no la regla.
- Pómulos y mandíbula definidos por **plano y sombra**, no por cambio de color.

## Movimiento / feel

Nada de lo que importa se juzga a plena luz. En las siete capturas la cara está en
penumbra con una fuente cálida puntual (vela, fuego, antorcha), y **el rasgo se lee
por la sombra que proyecta**. Es la confirmación externa de lo que se descubrió hoy
midiendo: juzgar una cara en modo plano no vale, y ninguna cantidad de color arregla
lo que tiene que hacer la luz.

## Qué capturar

1. **Ojo chico, hundido, poca esclerótica.** Es el objetivo de la rampa de forma de
   ojo (`ramp_eye_shape.py`): `eyefold-down`, `eyefold-concave`, `push1-in`,
   `scale-decr`.
2. **Ceja fina y separada del ojo.** La nuestra es un bloque negro pegado al párpado.
3. **Barba como default** en el guerrero varón.
4. **Evaluar siempre con luz cálida en penumbra**, que es como el jugador lo va a ver.
5. **Bajar el techo de detalle de piel.** Con esta referencia, el poro y la arruga
   fina dejan de ser objetivo — y eso es una buena noticia, porque Nyquist ya decía
   que no caben en la malla (arista mediana de 4.07 mm en la cabeza).

## Y lo que confirma del sistema, no de la cara

Las capturas 06 y 07 valen tanto como las de cara:

- **07 (Cosmetics)** muestra los **cuerpos base sin ropa**, humano / Orc / Elf, en
  **pose A** — la misma que tiene nuestro guerrero. La pose de modelado que Joan
  cuestionó es la correcta y así la usa el referente.
- **06 (Perk & Skill)** muestra la **ropa base de novato**: camisa cruda, pantalón
  simple, descalzo. Es literalmente lo que Joan describió como punto de partida
  antes del crafteo de armaduras.
- **05 (Select Class)** muestra que cada clase tiene **retrato de cara propio**, lo
  que refuerza que la cara es identidad de clase y no decoración.

Todo eso valida el contrato de equipo ya escrito (`_asset_creation_contract.md` §3c):
cuerpo base compartido + equipo que reemplaza la región, y forma por clase.

## Fuente

Capturas de **Dark and Darker** (IRONMACE), aportadas por Joan el 2026-08-19.
Uso interno como referencia visual para un proyecto no comercial.
