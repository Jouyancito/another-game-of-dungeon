# turtle — investigación de referencia (2026-08-23)

**Pedido de Joan (2026-08-23), textual:**

> *"recuerdo que lo hiciste, pero no habías usado el motor completo. Por eso es que yo igual te
> estoy pidiendo no que los hagas, porque la idea es que hagas la investigación, veas cómo son
> otras tortugas, sáquele referencias, sacarle también quizá las animaciones, de todo."*

Esto es **investigación, no construcción**. Sigue `CREATION_PROTOCOL.md` del motor: §1 categoría,
§2a visual multi-fuente, §2b funcional, §3 dimensiones contra el maniquí de 1,80 m. El movimiento
va aparte, en `motion/_motion_spec.md`, con el formato del spec del golem.

Ya existe `game/tools/blender/turtle/build_turtle.py`. Esta ficha es el **objetivo contra el
cual juzgarlo**, y ya encontró dos defectos concretos (abajo).

---

## §1 — Categoría del objeto real

**Quelonio de borde de agua.** El build actual se describe como *"pond/water-edge turtle"*.

Hay que decidirlo explícitamente, porque son tres animales distintos y hoy la malla no declara
cuál es:

| | Tortuga terrestre (tortoise) | **Galápago / de estanque (terrapin)** | Tortuga marina |
|---|---|---|---|
| Caparazón | muy abovedado, pesado | **bajo y aplanado, hidrodinámico** | plano, alargado |
| Patas | columnares, elefantinas, con uñas romas | **palmeadas, con membrana y uñas** | aletas |
| Cuello | grueso y corto | **largo y extensible** | corto |
| Hábitat | seco | **orilla, entra y sale del agua** | mar |

**Recomendación: galápago.** Encaja con el bioma de pradera con ríos del piso 1 (ya existe
`river_pack` y `_references/water_margin/`), y su caparazón bajo lo diferencia en silueta del
domo del slime, que es el mob vecino más cercano.

**¿Hay un hermano en el motor?** Sí, y es importante: `build_turtle.py` declara *"Mirrors
build_slime.py structure"*. Comparte la gramática de shape-keys por parte del cuerpo. Cualquier
arreglo de esa gramática hay que hacerlo en la función compartida, no en la copia — es
exactamente el defecto `build_goat()`/`build_sheep()` que el protocolo §1 documenta.

---

## §2a — Visual, nunca de una sola fuente

**Aviso honesto**: no puedo ver imágenes de la web. Lo que sigue son datos morfológicos
verificables de fuentes independientes; el **registro de estilo** (cuán estilizado, cuánto
detalle) necesita capturas que Joan anexe. Está declarado abajo como hueco.

### El caparazón tiene una gramática fija — y es lo que lo hace leer como caparazón

La disposición de escudos (*scutes*) no es decorativa ni aleatoria. Es la misma en todas las
especies:

- **1 escudo nucal** (cervical) al frente de la línea media
- **5 escudos vertebrales** a lo largo de la línea media
- **4 pares de escudos pleurales**, a los costados
- **12 pares de escudos marginales**, bordeando todo el contorno

El plastrón (abajo) va: gulares → pectorales → abdominales → femorales → anales.

**Por qué importa para modelar**: un caparazón con manchas al azar lee como piedra o como
hongo. Un caparazón con **5 placas centrales y una orla de marginales** lee como tortuga
incluso en silueta y a bajo poly. Es la lectura más barata que hay disponible, y hoy no está.

### Alometría — el dato que decide la proporción

Medido sobre tortugas en cautiverio con análisis 3D: **los ejemplares chicos son
proporcionalmente MÁS abovedados; los grandes son proporcionalmente más chatos.**

Consecuencia directa: si nuestra tortuga es un mob grande (ver §3), **tiene que ser más chata
que una tortuga de tamaño real**, no más abovedada. Agrandar un domo de tortuga chica es la
receta para que lea como juguete.

### Variación entre especies (para la variedad del roster)
La tortuga leopardo tiene el caparazón más alto; la de espolones africana, el más corto y el más
grande en tamaño absoluto. Sirve como rango si en algún momento hacen falta variantes.

---

## §2b — Funcional: qué componentes la hacen coherente

- **El caparazón es hueso fusionado, no una mochila.** Carapacho y plastrón se unen por
  **puentes óseos laterales**. Si el modelo no tiene ese puente, la tortuga lee como un bicho
  con un plato encima. Es una pieza estructural, no un accesorio.
- **Las patas tienen que caber adentro.** La retracción no es magia: hay volumen reservado. Si
  las patas se modelan del grosor que se ve lindo afuera, la animación de esconderse las mete
  dentro de geometría que no existe y clipean. **El hueco manda sobre el grosor de la pata.**
- **El cuello se pliega, no se encoge.** En los galápagos el cuello entra en S vertical. Un
  cuello que se escala hacia adentro lee como goma.
- **Palmeadas implica orilla.** Si lleva membranas, el bioma tiene que tener agua cerca; si no,
  las uñas van romas y la pata columnar. Coherencia de nicho, `_bestiary_visual_bible.md` §4.

---

## §3 — Dimensiones contra el maniquí de 1,80 m

Medido del GLB actual con `_glb_stats.py`:

| | Actual (`turtle.glb`) | Galápago real | Factor |
|---|---|---|---|
| Largo | **0,845 m** | 0,20–0,25 m | **≈ 3,8×** |
| Ancho | 0,590 m | ~0,18 m | ≈ 3,3× |
| Alto | 0,304 m | ~0,08 m | ≈ 3,8× |

**No es un defecto — es una decisión que nunca se escribió.** La tortuga del juego es casi 4×
una real: le llega a la rodilla al jugador (0,30 m contra 1,80 m). Eso es coherente con un mob
que hay que poder pelear, y con la escala del golem (4,0 m para imponer).

Lo que hay que hacer es **declararlo**: `MOB_SCALE = 3.8×`, anotado en el generador, para que la
próxima persona no lo "corrija" hacia el tamaño real ni lo agrande otra vez. Sin ese número
escrito, es indistinguible de un error — que es exactamente cómo el `tree_pack` terminó a escala
de arbusto.

**Y arrastra una consecuencia por la alometría**: a 3,8× de tamaño, el caparazón debería ser
**proporcionalmente más chato** que el de un galápago real. Relación alto/largo actual: 0,304 /
0,845 = **0,36**. Para un animal de ese tamaño, apuntar a **0,28–0,32** lo haría más creíble.

---

## Defectos concretos encontrados contra esta ficha

1. **No tiene gramática de escudos.** Es un domo liso. Es la lectura más barata de "tortuga" y
   está sin usar.
2. **Marcha equivocada** — ver `motion/_motion_spec.md`. El clip `move-loop` está descrito como
   *"pares diagonales de patas"* moviéndose juntos, y la marcha real de un quelonio es
   **secuencia lateral, una pata por vez**.
3. **Sale blanca en Godot** (auditoría del 2026-08-22). Arreglado con `_bake_vcol.py`, pendiente
   de que Joan decida si entra a `game/assets/`.
4. **Escala sin declarar** (3,8×) y **domo un poco alto** para esa escala.

---

## Qué capturar

1. **Gramática de escudos**: 5 vertebrales + orla de marginales. Aunque sea a bajo poly.
2. **Decidir galápago** y comprometerse: caparazón bajo, patas palmeadas, cuello largo.
3. **Puente óseo** entre carapacho y plastrón — que no lea como plato encima.
4. **Volumen interior reservado** para que patas y cabeza quepan al retraerse.
5. **Declarar `MOB_SCALE = 3.8×`** en el generador, con el número escrito.
6. Bajar la relación alto/largo a **0,28–0,32** por alometría.

---

---

## TABLA DE PARÁMETROS — lo que el generador tiene que consumir

Joan, 2026-08-23: *"a veces te digo investigar, pero me buscas 1 o 2 referencias y eso es todo,
**necesito parámetros**"*. Esta es la sección que convierte la investigación en código. Cada
valor tiene su fuente al lado; ninguno se elige a ojo en el momento de modelar.

### Escala y masa

| Parámetro | Valor | Unidad | Fuente |
|---|---|---|---|
| `CARAPACE_LEN_REAL` | 0,20–0,28 | m | galápago adulto (macho 20, hembra 28) |
| `CARAPACE_LEN` | 0,845 | m | medido de `turtle.glb` |
| `MOB_SCALE` | **3,4×** | — | 0,845 ÷ 0,25 — **declarar en el generador** |
| `SHELL_W_LEN_RATIO` | 0,70 | — | 0,590 ÷ 0,845, actual; carapacho oval |
| `SHELL_H_LEN_RATIO` | **0,28–0,32** | — | alometría: a mayor tamaño, más chato (MDPI 2024). Actual **0,36 — fuera de rango** |
| `MOB_HEIGHT` | 0,30 | m | a la rodilla del maniquí de 1,80 m |

### Gramática del caparazón — conteos fijos, no decorativos

| Parámetro | Valor | Unidad | Fuente |
|---|---|---|---|
| `SCUTE_NUCHAL` | 1 | conteo | morfología de quelonios |
| `SCUTE_VERTEBRAL` | **5** | conteo | línea media, de nucal a cola |
| `SCUTE_PLEURAL_PAIRS` | 4 | pares | laterales |
| `SCUTE_MARGINAL_PAIRS` | 12 | pares | orla del contorno |
| `PLASTRON_SCUTE_PAIRS` | 6 | pares | gular · pectoral · abdominal · femoral · anal |
| `REAR_MARGIN_SERRATED` | true | bool | borde posterior aserrado (galápago) — **muesca de silueta gratis** |

### Locomoción

| Parámetro | Valor | Unidad | Fuente |
|---|---|---|---|
| `GAIT` | `lateral_sequence_diagonal_couplet` | enum | JEB, *Testudo hermanni* |
| `FOOTFALL_ORDER` | FL → HR → FR → HL | secuencia | delantera izq, trasera der, delantera der, trasera izq |
| `DUTY_FACTOR` | ≥ 0,75 | — | apoyo trípode: nunca menos de 3 patas en el suelo |
| `WALK_SPEED_REAL` | 0,158 (rango 0,082–0,219) | m/s | medido en tortugas caminando |
| `WALK_SPEED_MOB` | **0,54** | m/s | 0,158 × 3,4 — ≈ ⅓ de la caminata del jugador |
| `COM_LIFT_PER_STEP` | activo, visible | — | **no es péndulo invertido**: el cuerpo sube y baja en cada paso |
| `SHELL_DEFORM` | 0 | — | es hueso: no deforma nunca |

### Tiempos de animación (a 30 fps)

| Parámetro | Valor | Unidad | Fuente |
|---|---|---|---|
| `IDLE_STILL_FRACTION` | ≥ 0,40 | — | un idle de tortuga es quietud interrumpida |
| `ATTACK_ANTICIP` | 0,70 | fracción del clip | el contraste lento/rápido ES el personaje |
| `ATTACK_STRIKE` | 0,10 | fracción | |
| `ATTACK_RECOVER` | 0,20 | fracción | |
| `RETRACT_IS_FLINCH` | true | bool | el `hit` ES esconderse — mejor idea del set actual |
| `NECK_FOLD` | S vertical | enum | **se pliega, no se escala** |

### ESTRUCTURA — plano, ángulo y límite por parte móvil

**Esta mitad faltaba entera, y es la que decide si lee.** El 2026-08-24 la tortuga cumplía
TODOS los parámetros de medida —ratio en banda, 5 escudos, marcha en secuencia lateral— y Joan
la miró y dijo: las cuatro patas apuntan igual y la cabeza es un círculo. Ningún parámetro de
medida podía haberlo evitado, porque describían cuánto mide la tortuga y nunca cómo está armada.

#### Miembros — postura ESPARRANCADA (sprawling), no columnar

El hallazgo que lo explica todo, medido: *"el movimiento del húmero ocurre predominantemente en
el plano HORIZONTAL, mientras que los del miembro distal ocurren predominantemente en el plano
VERTICAL, de ahí la típica postura esparrancada"* (J. Exp. Biol.).

| Parámetro | Valor | Fuente |
|---|---|---|
| `UPPER_LIMB_PLANE` | **horizontal** — sale hacia AFUERA del caparazón | JEB, postura sprawling |
| `LOWER_LIMB_PLANE` | **vertical** — baja al suelo | ídem |
| `HUMERUS_PITCH` | −13° a −2° al apoyar · −27° a −1° al despegar | *Testudo hermanni*, JEB 219/17 |
| `ELBOW_ABOVE_HORIZ` | **62–74°** en protracción → **147–149°** en retracción | ídem — es el recorrido del codo |
| `HUMERUS_LONG_AXIS_ROT` | 38–52° (media 44°) | ídem |
| `LIMB_EXCURSION` | 49–92° | ídem |
| `LEG_YAW_FRONT` | **+40°** hacia adelante-afuera (cuadrante propio) | derivado: 4 patas, 4 cuadrantes |
| `LEG_YAW_BACK` | **−40°** hacia atrás-afuera | ídem |

**Las cuatro patas NO apuntan igual.** Cada una ocupa su cuadrante, en oblicuo. Cuatro conos
verticales idénticos no pueden leer como tortuga por más correcto que esté el caparazón.

#### El límite, que además da la asimetría de la animación

> *"La abertura anterior del caparazón limita significativamente la retracción del miembro
> anterior, forzando posiciones mucho más protraídas que retraídas."*

| Parámetro | Valor |
|---|---|
| `PROTRACTION_VS_RETRACTION` | **asimétrico**: la pata va MUY adelante y vuelve poco |
| `RETRACTION_LIMITER` | el propio puente carapacho-plastrón (hueso, no músculo) |
| `DUTY_FACTOR` (medido real) | **0.568–0.871** — el 0.78 que usa el generador cae dentro |
| `WALK_SPEED` (medido real) | 0.02–0.10 m/s — más lento aún que el 0.158 de la otra fuente |

#### Cabeza y cuello

| Parámetro | Valor | Fuente |
|---|---|---|
| `HEAD_SHAPE` | **cuña con hocico preorbital angulado**, NO esfera | morfología craneal de testudines |
| `NECK_RETRACTION_PLANE` | **vertical** (criptodiro) — S en el plano sagital | los pleurodiros la doblan lateral; el galápago es criptodiro |
| `JAW` | línea de mandíbula marcada, boca como corte horizontal | ídem |

### Contrato de volumen interior

| Parámetro | Valor | Unidad | Fuente |
|---|---|---|---|
| `INTERIOR_CLEARANCE` | ≥ volumen de 4 patas + cuello plegado | — | si no, la retracción clipea |
| `LIMB_THICKNESS` | derivado del hueco, **no al revés** | — | el hueco manda sobre la pata |

### Estado actual contra estos parámetros

| Parámetro | Objetivo | Actual | |
|---|---|---|---|
| `SHELL_H_LEN_RATIO` | 0,28–0,32 | **0,36** | ✗ fuera de rango |
| `SCUTE_VERTEBRAL` | 5 | **0** (domo liso) | ✗ ausente |
| `GAIT` | secuencia lateral | **pares diagonales** (trote) | ✗ marcha equivocada |
| `MOB_SCALE` declarado | sí | **no escrito** | ✗ |
| COLOR_0 en el GLB | presente | corregido 2026-08-22 | ✓ pendiente de entrar a assets |

---

## Hueco declarado
- ⌛ **Faltan referencias visuales.** Las medidas y la morfología salen de fuentes; el registro
  de estilo (cuán estilizada, cuánto detalle de escudos, paleta) no. Joan anexa.
- ⌛ Falta decidir si es galápago o terrestre — la recomendación está arriba, la decisión no.
- ⌛ Sin dato de fuente para `INTERIOR_CLEARANCE`: hay que medirlo del propio modelo, no existe
  como número publicado.

**Fuente/fecha**: MDPI *Animals* (análisis 3D de morfología de carapachos en cautiverio, 2024),
Wikipedia (Turtle shell), Tortoise Library, StarTortoises (escudos), ScienceDirect (carapace);
consultadas 2026-08-23.
