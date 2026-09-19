# Tortuga — Motion Reference Spec

**Versión**: 1.0 · **Fecha**: 2026-08-23 · **Autor**: Claude (base textual) — Joan anexa clips visuales
**Canon padre**: `_synthesis.md` (hermano de esta carpeta) · `_bestiary_visual_bible.md` §3/§4
**Formato**: mismo que `_references/golem/motion/_motion_spec.md`

> **Qué es esto**: el objetivo textual contra el cual se construye y se compara cada animación de
> la tortuga. Poses clave, tiempos, forma del arco, señales de peso, y errores comunes — por
> movimiento. Joan anexa clips reales en `clips/` y los enlaza en el campo "Anexo visual".
>
> **Qué NO es**: código. Base de referencia pura.

---

## Identidad de movimiento — qué hace que se lea como tortuga

Antes de cualquier movimiento individual:

- **La marcha es LENTA POR ESTRUCTURA, no por pereza.** La lentitud sale de dos cosas medibles:
  frecuencia de zancada baja y **duty factor alto** (cada pata pasa mucho tiempo apoyada). No se
  simula "lento" bajando la velocidad de reproducción de un ciclo rápido — se construye con
  contactos largos.
- **NO es un péndulo invertido.** Medido en biomecánica: a diferencia de casi todos los
  cuadrúpedos, la tortuga **levanta activamente su centro de masa en cada paso**. Consecuencia
  para la animación: **el cuerpo SUBE Y BAJA visiblemente en cada zancada**. Ese bombeo vertical
  es la firma. Un ciclo de caminata plano y deslizante puede tener las patas perfectas y aun así
  no leer como tortuga.
- **El caparazón no se deforma.** Es hueso. Todo lo que se mueve es cuello, patas y cola. Un
  caparazón que rebota convierte al animal en peluche — y es tentador porque el build actual
  hereda la gramática de shape keys del **slime**, cuyo cuerpo entero sí deforma.
- **La cabeza manda la atención.** Con un cuerpo tan restringido, lo único que comunica
  intención es hacia dónde apunta la cabeza y cuánto sale del caparazón.

---

## LA CORRECCIÓN MÁS IMPORTANTE — la marcha está mal

El build actual documenta su ciclo así:

> `move-loop   slow heavy plod — body rocks as diagonal leg pairs step`

**Pares diagonales moviéndose juntos es un TROTE.** Es la marcha de un perro o un gato, y
ningún quelonio la usa.

La marcha real, medida: **secuencia lateral con acoplamiento diagonal** (*lateral-sequence,
diagonal-couplet*), con **largos períodos de apoyo trípode**.

El orden de apoyos es:

```
1. pata delantera izquierda
2. pata trasera DERECHA   (la diagonal de la anterior)
3. pata delantera derecha
4. pata trasera IZQUIERDA
```

Una pata por vez. **Tres patas en el suelo casi todo el ciclo** — de ahí sale la estabilidad, y
la lectura de "esto pesa y no se apura".

La diferencia se ve: el trote da un balanceo **lateral** parejo; la secuencia lateral da un
avance **asimétrico** con bombeo vertical, donde el cuerpo se inclina hacia la esquina que
quedó sin apoyo. Es más difícil de animar y es lo que hace la diferencia.

---

## Velocidad — número real para el ciclo

Medido en tortugas caminando: **8,2 a 21,9 cm/s, media 15,8 cm/s.**

Escalado a nuestra tortuga (3,8× el tamaño real, ver `_synthesis.md` §3), la velocidad
equivalente ronda **0,6 m/s** — que es cerca de un tercio de la caminata del jugador. Bien: un
mob al que uno le camina alrededor.

El largo del ciclo tiene que salir de ahí, no de un número elegido a ojo: **distancia por
zancada ÷ velocidad = duración del ciclo**. Si el ciclo de 64 frames avanza más de lo que
corresponde, las patas patinan.

---

## Movimiento 1 — `idle-loop` (64–72 frames)

**Actual**: *respiración lenta + cabeza mirando de lado a lado.* La base está bien.

- **Poses clave**: reposo neutro → cabeza gira ~25° a un lado, sostiene → vuelve al centro →
  al otro lado, sostiene.
- **Tiempo**: los sostenidos son LARGOS. Un idle de tortuga es mayormente quietud interrumpida,
  no movimiento continuo. Regla: ≥40% del clip sin movimiento apreciable.
- **Peso**: la respiración mueve la **piel del cuello y las patas**, nunca el caparazón.
- **Error común**: idle continuo y ondulante. Lee como pez. La tortuga se queda quieta y de
  golpe mira.
- **Anexo visual**: ⌛ pendiente.

---

## Movimiento 2 — `move-loop` (ciclo completo de 4 apoyos)

- **Poses clave**: los cuatro contactos en secuencia lateral (orden arriba), cada uno con su
  levantada del centro de masa.
- **Arco**: cada pata describe un arco bajo y largo, casi rasante. Las tortugas no levantan
  mucho el pie.
- **Peso**: **bombeo vertical del cuerpo en cada paso**, e inclinación hacia la esquina
  descargada. El caparazón se mueve como bloque rígido.
- **Duty factor alto**: cada pata está apoyada mucho más tiempo del que está en el aire. En
  ningún momento hay menos de tres patas en el suelo.
- **Errores comunes**: (a) trote de pares diagonales — el defecto actual; (b) cuerpo deslizando
  a altura constante; (c) patas que patinan porque el avance no coincide con la velocidad.
- **Anexo visual**: ⌛ pendiente. **Este es el clip que más necesita referencia en video**, porque
  la secuencia lateral es difícil de creer sin verla.

---

## Movimiento 3 — `attack` (26 frames)

**Actual**: *anticipación larga, mordida rápida hacia adelante.* Correcto de concepto.

- **Poses clave**: cuello se recoge hacia atrás y abajo (carga) → **sostener** → disparo hacia
  adelante → overshoot → retorno lento.
- **Tiempo**: la anticipación tiene que ser **mucho más larga que el golpe**. Proporción de
  referencia: ~70% anticipación, ~10% disparo, ~20% recuperación.
- **Peso**: en la mordida el cuerpo se ancla — las patas delanteras se plantan y el caparazón
  se adelanta apenas. Un cuello que sale sin que el cuerpo reaccione lee a goma.
- **Real**: las tortugas mordedoras son famosas justamente por este contraste — lentas hasta que
  el cuello se dispara. **El contraste ES el personaje.**
- **Error común**: acelerar la anticipación para que el ataque "se sienta ágil". Rompe la
  identidad entera.

---

## Movimiento 4 — `hit` (16 frames)

**Actual**: *cabeza y patas se retraen al caparazón, después asoma.* Es la mejor idea del set:
**el flinch ES el escondite**, no un flinch genérico.

- **Poses clave**: golpe → retracción rápida (cabeza y las cuatro patas) → cerrado, quieto →
  asoma con cautela.
- **Tiempo**: la retracción es **el movimiento más rápido de toda la tortuga**. Es la única vez
  que se mueve rápido sin ser el ataque.
- **Peso**: el cuerpo baja al retraerse — el caparazón se apoya en el suelo.
- **Ojo de modelado**: esto exige el **volumen interior** de `_synthesis.md` §2b. Sin hueco, las
  patas clipean.
- **Error común**: retraer con escala. El cuello **se pliega en S**, no se encoge.

---

## Movimiento 5 — `death` (36 frames)

**Actual**: *patas se abren, el caparazón se asienta plano, la cabeza cae.* Bien.

- **Poses clave**: rigidez breve → patas ceden hacia afuera → caparazón se asienta → cabeza cae
  última, colgando.
- **Tiempo**: la cabeza cae **después** que el cuerpo. La secuencia importa: si todo cae junto,
  parece que se apagó una máquina.
- **Peso**: al asentarse hay un pequeño rebote (settle) — el caparazón toca, cede un poco, para.
- **Error común**: caer de espaldas. Es icónico pero implica una fuerza que dé vuelta un animal
  bajo y ancho; solo tiene sentido con un golpe que lo justifique.

---

## Clips que faltan en el set actual

- **`retract-idle`** — quedarse escondida cuando el jugador está cerca pero no ataca. Es el
  comportamiento defensivo real de un quelonio y hoy no existe: la tortuga solo se esconde al
  ser golpeada.
- **`emerge`** — salir del caparazón después de la retracción, lento y cauteloso. Hoy está
  metido dentro del final del `hit`, donde dura demasiado poco para leerse.

---

## Anexo visual — hueco declarado

⌛ `clips/` está vacío. Lo que más falta, en orden:

1. **Video de marcha** (secuencia lateral) — es lo que este documento describe y no puede
   mostrar, y el defecto más importante que hay que corregir.
2. Mordida de tortuga mordedora — el contraste lento/rápido.
3. Retracción completa.

**Fuente/fecha**: Journal of Experimental Biology (rotación de cintura escapular y locomoción en
*Testudo hermanni*), SICB (biomecánica de tortugas gigantes — sin péndulo invertido), PMC
(velocidades óptimas en *Testudo graeca*), ResearchGate (energética y biomecánica de la
locomoción de quelonios); consultadas 2026-08-23.
