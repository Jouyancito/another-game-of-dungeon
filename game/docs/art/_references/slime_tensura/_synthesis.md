# slime_tensura — expresiones y gestos del slime

**Hueco CERRADO el 2026-08-09.** Estuvo abierto desde el 2026-07-18: Joan había citado el
anime de memoria y no había frames. Ahora hay cinco.

| Archivo | Qué aporta |
|---|---|
| `_expression_sheet.png` | Nueve expresiones en collage — la fuente principal |
| `_question_tendril.png` | El signo de pregunta hecho de gel, saliendo del cuerpo |
| `_lid_prop.png` | Objeto apoyado encima del domo, ojos cerrados |
| `_king_crown_mantle.png` | Referencia de Rey Slime: corona y manto |
| `_leap_aggressive.png` | El salto de ataque con estelas y gotas |

---

## La corrección que traen las imágenes

Yo iba a construir el `!` y el `?` **deformando el cuerpo entero** en la forma del símbolo.
**La referencia hace otra cosa, y es mucho mejor.**

En `_question_tendril.png` el cuerpo **sigue siendo un domo intacto**. El signo de pregunta
es un **zarcillo delgado de gel que sale de la parte alta y se enrosca**, con su punto
suelto debajo. El símbolo es un **apéndice**, no una deformación de la masa.

Esto importa por tres razones:

1. **Es fiel.** Es lo que hace el anime.
2. **Es barato.** Un zarcillo son unas decenas de tris; deformar el domo entero en una `?`
   legible pediría muchísima más geometría y rompería la silueta que identifica al bicho.
3. **Es componible.** El mismo cuerpo sirve para todas las expresiones y sólo cambia el
   apéndice — que es exactamente lo que necesita una mascota de escritorio con muchos estados.

Regla que sale de acá: **el cuerpo se mantiene, el símbolo se agrega.**

### Pero hay DOS registros, no uno (Joan, 2026-08-09)

> *"sería entrete que si fuera un `!!!` de una expresión casi de susto, y la de `???` que
> puede ser como real ¿preguntas eso? Esas expresiones podrían ser que cambie el cuerpo a
> signo de interrogación o exclamación — no es sólo generarlo pequeño arriba por duda, es
> una hipérbole."*

| registro | qué pasa | cuándo |
|---|---|---|
| **Leve** | zarcillo chico arriba, cuerpo intacto | duda, "mmm", una pregunta menor |
| **Hipérbole** | **el cuerpo ENTERO se vuelve el símbolo** | `!!!` susto, `???` incredulidad |

La escalada entre los dos registros **es** la expresividad. Un solo registro se vuelve
monótono a los tres días de tenerlo en el escritorio; dos dan lectura instantánea de
gravedad — se nota de reojo si el bicho está murmurando o gritando.

Y es convención del propio anime: la deformación hiperbólica del cuerpo es un recurso
cómico estándar, no una licencia nuestra.

---

## Vocabulario de cara

Confirma y precisa la regla vieja (rasgos = relieve, no piezas):

- **Ojos cerrados de contento**: dos trazos curvos simples, como acentos. Es el estado por
  defecto en casi todos los frames.
- **Ojos apretados** (`><`): mismo trazo, más quebrado, para esfuerzo o fastidio.
- **Nada de pupilas, dientes ni nariz.** Nunca. El slime con dientes ya fue rechazado
  (`game/tools/blender/slime_teeth/`, commit `5ebc7f1`).
- La cara se lee por **sombra propia** sobre un material homogéneo, no por color.

## Vocabulario de apéndices y adornos

Todo lo que no es cara se resuelve **agregando masa pequeña**, no deformando el cuerpo:

- **Gotas de sudor**: blobs sueltos pegados a la superficie, arriba y a los costados.
- **Zarcillo `?`**: sale de la parte alta-trasera, se enrosca, punto suelto abajo.
- **Zarcillo `!`**: mismo nacimiento, trazo recto y punto abajo (derivado — no hay frame,
  pero es la construcción hermana del `?`).
- **Núcleo visible**: en el collage aparece etiquetado *"Rimuru core"* — una masa más oscura
  suspendida dentro del cuerpo translúcido. Reservado; útil si la mascota necesita un
  "estado encendido".

## Movimiento — el salto agresivo

`_leap_aggressive.png` es la referencia que Joan pidió **para el Rey Slime**, no para el
común: *"que se note esa agresividad de atacarte a ti, no es un slime que ataca por
curiosidad como los pequeños"*.

Lo que muestra el dibujo:
- Cuerpo **estirado en la dirección del vuelo**, no esférico.
- **Estelas** de movimiento y **gotas que se desprenden** por detrás — el gel deja material
  atrás al acelerar.
- Ojos como trazos **enojados**, no los curvos de contento.

Encaja con lo ya escrito en `motion/_motion.md`: conservación de volumen, y deformación en
la dirección del desplazamiento. La diferencia entre el común y el rey es la **intención**:
el pequeño se derrama, el rey se lanza.

## Rey Slime — corona y manto

`_king_crown_mantle.png` muestra corona dorada **encima** y manto de piel blanca alrededor.

**Divergencia deliberada con nuestro canon**: Joan, 2026-08-09 — *"la corona debería estar
por dentro del slime"*. Coincide con `boss_king_slime_spec.md`: el rey **se tragó al monarca
entero, insignias incluidas**; no es un slime que *es* rey. La referencia aporta la forma de
la corona y la idea del manto; **la posición la decide nuestro canon.**

---

## Qué capturar, por asset

| | Cuerpo | Cara | Apéndices |
|---|---|---|---|
| **Mascota de escritorio** | domo intacto, squash/stretch | trazos curvos, `><` | zarcillos `!`/`?`, gotas |
| **Slime común (juego)** | domo, deformación por velocidad | **sin cara** (decisión 2026-07-30) | ninguno |
| **Rey Slime** | estirado al saltar, estelas | trazos enojados | corona **adentro**, manto |

## Fuente

Frames del anime *That Time I Got Reincarnated as a Slime*, pasados por Joan en chat el
2026-08-09. Referencia visual interna, no van al juego.
