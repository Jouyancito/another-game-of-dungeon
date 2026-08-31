# Vocabulario de comportamiento por mob

> Nacido del pedido de Joan (2026-07-30): *"los movimientos de huida y de alerta también
> tienen ciertos patrones... por ejemplo el golem, si no está en alerta está quieto como
> una piedra; si está en alerta se mueve, quizás más lento, observando; si está huyendo,
> aunque el golem no huye, igual habría que hacer una animación"*.
>
> Se llena **mob por mob**, con Joan definiendo qué quiere expresar y el motor
> construyendo desde ahí. Este archivo es el contrato entre las dos cosas.

## Por qué existe

`_mob_style_contract.md` §3 fija los nombres de los clips (`idle-loop`, `move-loop`,
`attack`, `hit`, `death`) — el QUÉ. Este doc define el CÓMO por especie: qué expresa cada
bicho en cada estado, para que dos mobs distintos no terminen moviéndose igual.

Hay un hueco concreto que esto viene a cerrar: la IA ya tiene estados que **ninguna
animación refleja**. `base_enemy.gd` maneja seis personalidades —

| Personalidad | Qué hace | Quiénes |
|---|---|---|
| `DEFAULT` | comportamiento base | la mayoría |
| `HUNTER_FAST` | detección grande, rápido, no afloja | wolf, hawk |
| `JUGGERNAUT_SLOW` | lento, jamás abandona la persecución | golem |
| `CURIOUS` | se acerca despacio, ataca sólo de cerca o si lo provocan | slime, mini_slime |
| `SKITTISH` | huye al acercarse el jugador; ataca sólo acorralado | fox, goat |
| `TERRITORIAL` | agrede sólo dentro de su territorio, después vuelve | scorpion |

— y además lleva flags de `alerta` y de `huida activa`. Pero `EnemyAnimator` sólo conoce
`idle / walk / run / attack / jump / death`. **Alerta y huida no existen como animación**,
así que hoy un bicho asustado huye con la misma pose con la que patrulla.

## Las 9 preguntas por mob

Cortas a propósito. Lo que hace falta es la INTENCIÓN, no la descripción técnica.

1. **Qué es en una frase.** La identidad. "Un charco curioso", "una piedra que despierta".
2. **Peso.** ¿Liviano o pesado? Cambia el timing de absolutamente todo lo demás.
3. **En reposo, sin ver al jugador.** ¿Inmóvil como piedra? ¿Respira? ¿Pasta, patrulla,
   husmea?
4. **Alerta — te vio, todavía no ataca.** Es el estado que hoy no existe. ¿Se yergue? ¿Gira
   la cabeza? ¿Se tensa? ¿Vibra? ¿Se queda MÁS quieto que antes?
5. **Acercándose.** ¿Cómo se desplaza cuando va hacia vos? ¿Igual que patrullando o
   distinto?
6. **Ataque.** ¿Cómo golpea, y cómo se anticipa el golpe? (el aviso importa tanto como el
   impacto)
7. **Recibe daño.** ¿Se encoge, retrocede, se enfurece, no se inmuta?
8. **Huida** (si aplica, y aun si el bicho "no huye" conviene tenerla). ¿Recto? ¿Zigzag?
   ¿Salta lejos? ¿Se entierra? ¿Mira hacia atrás mientras escapa?
9. **Muerte.** Cómo se resuelve el cuerpo, acorde a su materia. Nunca un fade genérico.

Y una décima que ahorra retrabajo:

10. **Qué NO debe hacer.** Lo que lo volvería genérico o lo confundiría con otro mob.

## Familias

Varios mobs comparten patrón. Definir la familia primero y después sólo las diferencias
evita responder 28 veces lo mismo.

| Familia | Mobs | Nota |
|---|---|---|
| Gel / blob | slime, mini_slime, king_slime | sin esqueleto: todo es deformación |
| Cuadrúpedos | wolf, fox, goat, jabali, rat | Joan: tienen patrón propio de huida |
| Voladores | bird, hawk, wasp, giant_moth | el reposo también es movimiento |
| Reptantes | snake, scorpion, spider | cuerpo bajo, sin silueta erguida |
| Piedra / construcción | golem, jotun_giant, guardian_cuervo | quietud absoluta como estado |
| Humanoides | bandit_melee, bandit_archer, bandit_leader, samum | van por otro pipeline (sculpt) |
| Caparazón | turtle | la defensa es una pose |
| Trampa | mimic_chest | su estado de reposo es una MENTIRA |
| Anfibio | frog | — |

---

# Fichas

## slime · mini_slime — ✅ definido y construido

1. **Qué es**: un charco de gel curioso, torpe en su propio cuerpo.
2. **Peso**: liviano pero denso; se mueve con inercia, nunca nervioso.
3. **Reposo**: respiración viscosa, siempre viva. Nunca completamente quieto.
4. **Alerta**: ⬜ sin definir.
5. **Acercándose**: salta. Y al desplazarse el gel se derrama hacia donde va: la masa se
   queda atrás al arrancar, pasa de largo y rebota. Resuelto con un resorte
   subamortiguado, no con una interpolación suave.
6. **Ataque**: se agacha para tomar impulso y lanza la masa hacia adelante.
7. **Recibe daño**: flinch corto.
8. **Huida**: ⬜ sin definir. `CURIOUS` no huye hoy, pero el mini podría.
9. **Muerte**: **revienta en gotitas** que vuelan, caen, se aplanan contra el suelo y se
   absorben. No se desinfla ni se aplasta.
10. **NO debe**: tener cara (decisión de Joan 2026-07-30 — la cara es del Rey Slime); ni
    dientes, nariz o pupilas si alguna vez la lleva; ni moverse con reacciones rápidas.

## king_slime — ⬜ pendiente

Lo único fijado: **sí lleva cara expresiva** (canon PO 2026-07-17, reconfirmado
2026-07-30), en relieve del propio gel. Hereda el vocabulario del slime; falta todo lo
demás.

## golem — 🟡 esbozado por Joan, falta confirmar

3. **Reposo**: quieto como una piedra. Inmóvil de verdad — no una idle sutil.
4. **Alerta**: se mueve, **más lento**, observando.
8. **Huida**: no huye, pero igual hay que darle una.

Ya construido aparte: moveset condicionado por árbol, muerte por derrumbe, ~5 m.

## Resto — ⬜ pendientes

bandit_melee · bandit_archer · bandit_leader · wolf · fox · goat · jabali · rat · bird ·
hawk · wasp · giant_moth · snake · scorpion · spider · turtle · frog · mimic_chest ·
jotun_giant · guardian_cuervo · samum · forest_watcher · enemy_basic

---

## Lo que hace falta en código (independiente de las fichas)

- `EnemyAnimator` no tiene `play_alert()` ni `play_flee()`, y `play_hit()` tampoco existe
  pese a que los mobs bespoke ya exportan el clip `hit`.
- La IA sí lleva los flags (`_alert_time_left`, `_is_fleeing_skittish`,
  `_cornered_timer`), así que el enganche es directo una vez definido qué anima cada uno.
