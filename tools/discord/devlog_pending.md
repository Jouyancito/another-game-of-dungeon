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

NOTE ON ORDER — everything above the first '## ' heading is ignored by the
parser, so this route note costs nothing and saves a run. Entries are sequenced
as ONE walkthrough of floor 1, not by when they were built:

    1-2    the antechamber, before you step outside
    3-6    the open prairie: horizon, then the ground under your feet
    7-10   inside a stand of trees
    11-12  combat, wherever you find it

One loading of the build covers all twelve. Tick what you actually saw.
-->

## [ ] La entrada al piso 1 ahora es una mina, no un pasillo gris

Bajás a la pradera por una antesala entibada con madera: vigas, puntales y
tablas que sostienen la tierra encima tuyo. Antes eran cajas grises puestas
para tapar el hueco.
@ al arrancar el piso 1, antes de salir a la pradera. Mirá arriba.
> Reemplazadas las cajas placeholder de la antesala por entibado procedural.
> Canon en `game/docs/art/_entrance_antechamber.md`, generación en el worldgen
> del piso 1. Commit `a8aa88c`.

## [ ] La puerta de la entrada ya se cruza caminando

Se salía saltando, o directamente no se salía: había una barrera invisible en el
marco, y un pedazo de tierra que te frenaba justo al cruzar. Ahora se pasa
caminando, como corresponde.
@ arrancá el piso 1 y salí por el marco de madera sin saltar.
> Tres bugs encadenados, uno tapando al otro. La malla de la loma se generaba
> continua sobre toda la huella, sin hueco para la puerta, y dejaba una pared de
> tierra de 7,4 m parada en el vano. Debajo quedaba un canto vertical de 0,30 m
> donde terminaba la losa: Godot trata como PARED todo lo más empinado que 45°, y
> ese canto medía 71,6°. Y la resolución del terreno era fija mientras el tamaño
> del mapa es ajustable, así que agrandarlo degradó la grilla de 6,25 a 8,125 m
> por celda y la interpolación volvió a meter terreno sin excavar dentro del
> corredor: el vano de 6 m tenía 3 m de paso real, corridos hacia un lado.
> Pendiente del vano ahora 35,2°. Commits `466e540`, `4cd0dda` y `de57fb0`.
> La garantía de que no vuelva es un test, no la memoria de nadie:
> `game/tests/test_entrance_walkable.gd` cruza una cápsula del tamaño del
> jugador, con los pies sobre la superficie de colisión real, y falla el build si
> un vano queda intransitable. Verificado en ambos sentidos: con el bug
> reintroducido falla e imprime el ángulo medido.

## [ ] La pradera creció y ahora las lomas te tapan lo que sigue

El mapa es más grande, pero lo que cambia de verdad es que las colinas son casi
el doble de altas. Antes veías el otro lado del mapa desde el spawn y sabías al
toque dónde estaba todo. Ahora hay que ir a buscarlo.
@ salí a la pradera y caminá en línea recta un rato, mirando el horizonte.
> `proc_bounds` 600 → 780 m y `TERRAIN_MAX_HEIGHT` 9 → 16 m. El tamaño solo
> habría empeorado la lectura: la frecuencia del ruido se dividía por la escala,
> así que crecer estiraba las mismas lomas en vez de agregar nuevas. Con el
> divisor topeado, los metros nuevos traen colinas nuevas. Commit `fcd2958`.

## [ ] La flor ya no tiene porte de ratón, y crece en manchones

Antes las flores eran del tamaño de un ratón y estaban repartidas de a una, tan
separadas que se leían como objetos sueltos en vez de pradera. Ahora vienen en
manchas de una sola especie, y hay tres alturas conviviendo: pasto bajo pisado,
mata de rodilla, y espiga alta.
@ salí a la pradera y caminá mirando el suelo, después levantá la vista al horizonte.
> Medidas las doce mallas de flora: TODAS entre 0,107 y 0,491 m, o sea que la capa
> entera era el estrato de los tobillos. `FLORA_TARGET_HEIGHT` declara la altura a
> la que cada especie debe LEERSE y divide por el AABB real, así que reexportar un
> asset no cambia su porte en pantalla. El trébol medía 10,7 cm — un ratón mide 10.
> Y el scatter elegía especie punto por punto, que por construcción no puede dar
> masas: ahora la elige una vez por mancha. Commit `fdc9a34`.

## [ ] El pasto dejó de ser todo del mismo verde

La alfombra tenía un solo color plano para las 193 mil briznas. Ahora el suelo
tiene manchones —verde húmedo y verde amarillento seco conviviendo— y cada brizna
usa el degradado que el generador le había pintado.
@ parate en un claro y girá 360° mirando el suelo a media distancia.
> El shader pintaba `ALBEDO = albedo.rgb` con un olivo fijo heredado de cuando el
> piso 1 era caverna, y encima `surface_set_material()` pisaba el vertex color que
> el motor había horneado. Ahora lee ese color y lo mezcla entre dos tonos según un
> ruido en espacio de mundo: manchas de ~83 m con quiebre de ~22 m adentro. De paso,
> `blade_height` se calibraba con la PRIMERA malla para todas, así que la espiga
> alta mecía sus dos tercios superiores como un bloque rígido. Commit `fdc9a34`.

## [ ] El pasto y las orillas del río son del motor propio

La alfombra de pasto —unas 190 mil briznas— venía de un pack descargado. Ahora
sale del generador propio, con dos variantes en vez de una sola repetida. Las
orillas también: piedra seca contra piedra mojada, y juncos de verdad.
@ agachate a mirar el pasto de cerca, y seguí un arroyo hasta la orilla.
> Purga de todo asset que no fuera del motor al máximo. Nota honesta: el mapa
> quedó con MENOS variedad de árbol hasta que se construyan las especies que
> faltan — se fueron los que daban el color rojo. Commit `1006f73`.

## [ ] Los árboles dejaron de titilar cuando girás la cámara

Al mover el mouse rápido, las hojas vibraban y los bordes se partían. Ya no.
@ parate frente a un grupo de árboles y girá la cámara rápido.
> Activado TAA en el render. El shimmer venía del aliasing temporal sobre la
> vegetación con alpha. Además el collider del tronco se calcula desde la malla
> de corteza, así que dejás de chocar con aire alrededor de los árboles.

## [ ] Los árboles ahora tienen especies, y cada especie tiene edades

Antes había seis árboles sueltos. Ahora hay cuatro especies distintas —cada una
con su corteza y su color de hoja— y cada una aparece en varias edades: brotes,
adultos y ejemplares viejos de copa ancha. Volvió el rojo al mapa con una especie
otoñal. Y los renovales crecen debajo de los árboles grandes, no en cualquier lado.
@ caminá por una zona con árboles y fijate en los chicos que crecen bajo las copas.
> La tabla mezclaba dos ejes: cuatro de las seis variantes compartían corteza,
> atlas de hoja y tints —una misma especie en cuatro formas— y una era literalmente
> un estadio archivado como especie. Ahora son especie × estadio × altura: 17
> modelos, 4 especies, hasta 4 estadios. El brinzal de cada especie tolera más
> sombra que su adulto, que es lo que hace que la regeneración caiga bajo el dosel.

## [ ] Volvió a haber árboles bajo la sombra de otros árboles

Apareció una especie nueva: un árbol chico y ancho, de hoja oscura, que crece
debajo de los grandes. Antes el suelo bajo las copas quedaba pelado, porque
ninguna de las especies que había sabía vivir a la sombra.
@ metete dentro de un grupo denso de árboles y mirá hacia abajo y a los lados.
> `env_tree_shade_01`, construido con el motor propio (M3). 5,48 m contra los
> 8,58 m del generalista y más ancho que alto, así que lee como sotobosque y no
> como un árbol más del dosel. 726 tris sobre un presupuesto de 800. Cableado en
> los tres lugares que hacen falta: pool, nicho (`shade 0.3–1.0`, el extremo que
> quedó vacío tras la purga) y scatter. Validación: 274 scripts sin errores.

## [ ] El árbol gigante dejó de ser un árbol chico agrandado

El hito que se ve desde lejos ahora está construido a su tamaño, con el tronco
grueso que le corresponde. Antes era un árbol normal estirado, y por eso se veía
como un juguete inflado.
@ buscá el árbol gigante de la pradera y mirale el tronco desde la base.
> Era `env_tree_prairie_wide_01` (8,57 m) escalado ×4,5 a 38,6 m. Bajo
> auto-semejanza elástica el diámetro tiene que crecer como la altura^1,5, así que
> un escalado uniforme le deja el tronco de un árbol cuatro veces menor. Ahora hay
> un estadio `ancient` que lo construye a 22,06 m con su grosor propio, y el
> escalado quedó en un jitter de ±6%.

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

## [ ] La tortuga entra al juego con caparazón real, marcha de tortuga y escamas

Rehecha de punta a punta: el caparazón ahora está construido escudo por escudo
(37 placas con anillos de crecimiento, relieve real que entra a la silueta),
plastrón con puentes óseos y las patas saliendo por sus aberturas, marcha con
arrastre de pie de verdad (el pie plantado viaja hacia atrás mientras el cuerpo
pasa por encima), patas en X, cabeza soldada al cuello, y escamas grandes en
patas y cuello. Todo con textura horneada que sí llega al juego.
@ mob_lab con la tortuga (o el spawn de la pradera): tecla 2 para verla
caminar, y mirala también desde abajo.
> Tres causas raíz de la sesión: la esfera con escudos pintados no podía leer
> como caparazón (el edge flow no sigue la anatomía — se rehízo la malla desde
> los escudos); el GLB desplegado iba dos builds atrás del generado (ahora el
> builder exporta directo y un gate por hash bloquea el desfase); y un nudo de
> nodos mataba las texturas al exportar (el tono por región va en la textura
> horneada, nunca en el grafo). Veredicto de Joan en vivo: 8/10.

## [ ] El halcón vive: planea en círculos amplios, caza ratas y pica de verdad

Rehecho de cero, construido pluma por pluma (10 primarias con "dedos", cola
rufa en abanico, garras), con textura de barbas horneada y cinco animaciones
nacidas de un spec de movimiento real de buteo. Y tiene vida propia: planea en
térmica con vueltas de ~20 segundos, aletea solo cuando se traslada o remonta,
caza ratas en picada diagonal — el loot de la rata queda tirado donde murió —
golpea al pasar y sigue de largo con el impulso. Al morir, cae al suelo con
las alas encogidas. El vuelo tiene inercia: curva sus giros como un ave real.
@ mob_lab (T para la lista de mobs): G vuelve al poste un objetivo, H suelta
una rata para verlo cazar, 6 lo mata en vuelo.
> Bugs de fondo que pagó esta build: el punto de órbita viajaba más rápido de
> lo que el ave vuela (por eso "giraba estático"); el GLB salía mirando +Z y
> volaba de cola; y un dummy con la firma de take_damage en orden equivocado
> abortaba la IA a mitad de frame y lo dejaba pegado al poste.

## [ ] Los arroyos ahora llevan piedra de rio de verdad

Las piedras de los tres arroyos de la pradera son nuevas: bloques gastados por
el agua, con caras planas, hombros redondeados y grietas, y ninguna es igual a
otra. Cada mundo mezcla seis formas distintas con rotacion y tamano al azar, y
los grupos de piedras se componen en el momento en vez de repetir un bloque
prefabricado.
@ Piso 1: segui cualquiera de los dos arroyos con agua (o el cauce seco) y mira
  las piedras del lecho de cerca y desde la orilla.
> river_rock_worn_kit.glb (6 stones, 2032 tris total, shared limestone set) built
> by build_river_rock_kit.py from the v5 worn-block recipe; floor1_prairie.gd
> _scatter_stream_channel_rocks now instances kit meshes (seeded variant + scale
> 0.7-1.3 + runtime clusters of 2-3), legacy env_river_rock_* kept as fallback.

## [ ] Los arroyos son rios de verdad: grava, agua clara y arboles en la orilla

El cauce ahora tiene lecho de grava que se ve a traves del agua, el agua dejo
de ser ambar (era "oro fundido" de una version vieja) y es agua de rio, la
linea de agua se funde suave contra la grava y las piedras, y las orillas de
los arroyos con agua tienen arboles. El cauce seco quedo como lavado de grava
clara. Ademas todo lo que se apoya en el suelo (piedras, props) ya no flota
cerca de los canales: la altura del terreno que usaba el juego no coincidia
con la superficie visible justo en las pendientes.
@ Piso 1: segui cualquier arroyo desde el aire y despues baja a la orilla.
> _build_stream_beds() + _scatter_stream_trees() + natural water + depth_fade
> (water_toon.gdshader, default off) + get_terrain_height now samples the
> rendered mesh triangles exactly (was bilinear, ~0.3m off on channel walls).

## [ ] La tortuga camina como tortuga y el halcon no se clava en el aire

La tortuga usa su animacion de caminata (dos patas en diagonal, paso lento) y
apunta la cabeza hacia donde va; antes se deslizaba en pose quieta. El halcon
ya no queda flotando estatico: al llegar a un punto de vuelo arranca el
siguiente tramo.
@ Piso 1: tortugas cerca de los arroyos; el halcon esta arriba, seguilo un rato.
> turtle.gd: _get_anim_model_root override + walk_threshold 0.15 + 180 flip +
> wander yaw; speed 1.5->0.6; enemy_animator.gd: move_ref_speed stride sync.
> hawk.gd: arriving at wander target picks the next one instead of braking.

## [ ] Los arroyos ahora están tallados en la pradera, con orillas de verdad

El canal es más profundo (un corte de 1,3 m, ya no una hondonada de pasto) y
las orillas cambian a lo largo del río: barras de grava que entran suaves al
agua, muros de peñascos grises, lajas bajas al nivel del agua y montículos de
piedra. Los dos lados de un mismo tramo nunca repiten el mismo tipo de orilla.
El ancho y la profundidad varían a lo largo del cauce — pozones con piedras
sumergidas, partes bajas de vadeo, angosturas — y el borde con la pradera se
desgasta en parches de tierra en vez de cortar a cuchillo. Las rocas grandes
tienen colisión: te podés subir. Las piedras dejaron de verse blancas.
Los ríos además ahora obedecen la gravedad: el cauce se rutea caminando cuesta
abajo por el terreno, así que rodea las colinas buscando la caída en vez de
treparlas en línea recta. Y la piedra-huevo quedó eliminada de toda la
generación del río — todo lo mineral del cauce sale del kit de piedra gastada.
@ Freecam sobre cualquier arroyo — volar el cauce a nivel de ojo y en cenital; buscar un pozón, una angostura, y verificar que ningún arroyo trepa una colina.
> floor1_prairie.gd: STREAM_DEPTH 0.8→1.3 + flat floor 30%; ancho 2,2-5,2 m y profundidad
> 0,78-1,88 m por Perlin (seeds +72/+73); _build_stream_bank_profiles() (3 perfiles por
> tramo de 4 m + montículos, deterministas); franja de transición en color de terreno;
> convex collision en rocas ks≥1,6; kit worn v5 teñido en runtime (vcols estaban bien —
> caliza pálida + luz toon lavaba a blanco).
