<!--
Devlog staging. Entries accumulate here across a session and are posted in one
batch at session close — never one message per change, or the channel becomes
a commit log nobody reads.

  python dp_discord.py devlog devlog_pending.md --dry-run   # preview, no token
  python dp_discord.py devlog devlog_pending.md             # posts only [x]

Format, one entry per heading:

  ## [ ] Title anyone can scan
  Plain lines: what changed, in words a player understands.
  @ how to reach it in a running build (the "Dónde verlo" label is added when
    rendering — write only the instruction here).
  > Quoted lines: the technical half. Files, systems, numbers. Optional.

The '@' line is required and the checkbox gates posting. An entry stays '[ ]'
until a human loads the build, looks at the thing, and ticks it '[x]'. Written
by the agent, approved by the owner — the agent never ticks its own box.

Entries are in Spanish (the Discord community reads Spanish); repo, commits and
docs stay in English.
-->

## [ ] La entrada al piso 1 ahora es una mina, no un pasillo gris

Bajás a la pradera por una antesala entibada con madera: vigas, puntales y
tablas que sostienen la tierra encima tuyo. Antes eran cajas grises puestas
para tapar el hueco.
@ al arrancar el piso 1, antes de salir a la pradera. Mirá arriba.
> Reemplazadas las cajas placeholder de la antesala por entibado procedural.
> Canon en `game/docs/art/_entrance_antechamber.md`, generación en el worldgen
> del piso 1. Commit `a8aa88c`.

## [ ] Los árboles dejaron de titilar cuando girás la cámara

Al mover el mouse rápido, las hojas vibraban y los bordes se partían. Ya no.
@ parate frente a un grupo de árboles y girá la cámara rápido.
> Activado TAA en el render. El shimmer venía del aliasing temporal sobre la
> vegetación con alpha. Además el collider del tronco se calcula desde la malla
> de corteza, así que dejás de chocar con aire alrededor de los árboles.

## [ ] Los enemigos ya no se apilan uno encima del otro

Cuando venían varios juntos se montaban formando una torre. Ahora se empujan
entre ellos y el más pesado gana el lugar.
@ juntá tres o más enemigos y dejá que te persigan al mismo tiempo.
> Resolución de solapamiento en `base_enemy`, con la masa decidiendo quién cede.
> También arreglado que TODOS los enemigos murieran rojos: el flash de daño
> pintaba el mesh y no restauraba el material si la muerte caía dentro de los
> 0.2 s del flash.

## [ ] El slime revienta en gotas que se absorben en el suelo

Ya no desaparece con un fundido. Explota en gotitas que caen, se aplanan y se
hunden en la tierra.
@ matá cualquier slime verde de la pradera y quedate mirando.
> La muerte usa islas de geometría separadas: un shape key no puede desgarrar
> una superficie continua, tirar de una región estira hilos hacia el resto. Las
> gotas son islas independientes desde el modelado. Además el slime estaba
> enterrado 0.40 m bajo el suelo.

## [ ] La pradera creció y ahora las lomas te tapan lo que sigue

El mapa es más grande, pero lo que cambia de verdad es que las colinas son casi
el doble de altas. Antes veías el otro lado del mapa desde el spawn y sabías al
toque dónde estaba todo. Ahora hay que ir a buscarlo.
@ salí a la pradera y caminá en línea recta un rato, mirando el horizonte.
> `proc_bounds` 600 → 780 m y `TERRAIN_MAX_HEIGHT` 9 → 16 m. El tamaño solo
> habría empeorado la lectura: la frecuencia del ruido se dividía por la escala,
> así que crecer estiraba las mismas lomas en vez de agregar nuevas. Con el
> divisor topeado, los metros nuevos traen colinas nuevas. Commit `fcd2958`.

## [ ] Ya no te quedás trabado al salir de la entrada

Al cruzar el marco de madera aparecía un pedazo de tierra que te frenaba, y
había que saltar para pasar.
@ arrancá el piso 1 y salí caminando por el marco, sin saltar.
> La resolución del terreno era fija mientras el tamaño del mapa es ajustable,
> así que agrandar el mapa degradó la grilla de 6.25 a 8.125 m por celda y la
> interpolación metió terreno sin excavar dentro del corredor. El vano de 6 m
> tenía 3 m de paso real, corridos hacia un lado. Commit `de57fb0`.

## [ ] El pasto y las orillas del río son del motor propio

La alfombra de pasto —unas 190 mil briznas— venía de un pack descargado. Ahora
sale del generador propio, con dos variantes en vez de una sola repetida. Las
orillas también: piedra seca contra piedra mojada, y juncos de verdad.
@ agachate a mirar el pasto de cerca, y seguí un arroyo hasta la orilla.
> Purga de todo asset que no fuera del motor al máximo. Nota honesta: el mapa
> quedó con MENOS variedad de árbol hasta que se construyan las especies que
> faltan — se fueron los que daban el color rojo. Commit `1006f73`.

## [ ] La puerta de la entrada ya se cruza caminando

Se salía saltando, o directamente no se salía: había una barrera invisible en el
marco. Ahora se pasa caminando, como corresponde.
@ arrancá el piso 1 y salí por el marco de madera sin saltar.
> Dos bugs encadenados. La malla de la loma se generaba continua sobre toda la
> huella, sin hueco para la puerta, y dejaba una pared de tierra de 7,4 m parada
> en el vano. Y debajo quedaba un canto vertical de 0,30 m donde terminaba la
> losa del piso: Godot trata como PARED todo lo más empinado que 45°, y ese canto
> medía 71,6°. Pendiente del vano ahora 35,2°. Commits `466e540` y `4cd0dda`.

## [ ] El build ahora falla si una puerta no se puede cruzar

Regla nueva, no un arreglo puntual: si un vano queda intransitable, el test lo
frena antes de que llegue al juego.
@ nada que mirar en el juego — se ve al correr los tests.
> `game/tests/test_entrance_walkable.gd`. Verifica pendiente bajo 45° y que una
> cápsula del tamaño del jugador, con los pies sobre la superficie de colisión
> real, cruce sin chocar. Verificado en ambos sentidos: con el bug reintroducido
> falla e imprime el ángulo medido. GUT 470 tests / 465 pasando.
