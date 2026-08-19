# Reference — `titlescreen`

Base name: **`titlescreen_`**. Todo artefacto sobre la pantalla de inicio lleva ese prefijo.

## Fuente

Bocetos a mano del owner (Joan), 2026-07-31. Originales: `Desktop/Juego/bocetos a mano/pantalla
inicio.jpg` y `pantalla inicio idea.jpg`. Copiados acá como `titlescreen_sketch_hand_scene.jpg`
(la escena en grande) y `titlescreen_sketch_hand_annotated.jpg` (la misma escena chica + la nota
manuscrita del owner).

## Idea

La primera pantalla del juego — título / iniciar partida — **no es un menú sobre un fondo: es una
escena de descanso dentro del dungeon, con el peligro mirando desde la oscuridad.**

Nota del owner, transcripción literal del boceto:

> *"Pasillo con oscuridad y mobs viendo*
> *Título en la nube de humo del tabaco y una fogata*
> *Un caraleón acechando a la exploradora*
> *y mago que fue atacado x un mímico*
> *Guerrero fumando tabaco en pipa junto a su escudo y espada"*

**CORREGIDO por el owner 2026-08-08.** La lectura anterior de este doc decía que el humo *forma*
el título. **Es al revés:**

> *"el tema de que no está sobrepuesto está mal. La idea es que el título se encuentre como sólido
> dentro de la mazmorra, y que el humo pase a través de él — quizá un poquito por adelante, un
> poquito por atrás, pero que no lo tape completamente."*

**El título es un objeto SÓLIDO que existe dentro de la mazmorra**, con volumen y materia propia,
ocupando su lugar en el espacio 3D del salón. El humo de la pipa y de la fogata **lo atraviesa**:
algunas volutas pasan por delante, otras por detrás. Nunca lo oculta. El humo no es el título —
es lo que prueba que el título está físicamente ahí, porque tiene que rodearlo para pasar.

La línea roja del boceto que sube de la pipa hasta el título sigue valiendo como **conexión visual
pipa → humo → altura del título**, pero ya no como "el humo dibuja las letras".

**El título ES el logo de `[[logo]]`** — el wordmark 3D con la U-portón. Confirmado por el owner
2026-08-01: *"al final ese título va a estar en la pantalla de inicio"*. Todo el trabajo del logo
desemboca acá.

## La escena, contada por el owner (2026-08-01) — versión ampliada

Esta descripción es MÁS RICA que la nota del boceto y manda sobre ella. Textual, ordenada:

> *"donde está el guerrero fumando en la pipa, descansando al lado de su espada y su escudo,
> mientras observa, sentado al lado de la fogata, [a] su compañera exploradora tirando del mago
> o la maga, que fue comida por un mímico. Todo eso mientras [en] el pasillo que está a la derecha
> se notan como monstruos acechándolos en la oscuridad. Un ojo viéndolo, cerrando y abriéndose
> constantemente. Y este el camaleón que aparece de repente, que se nota como camuflado, pero que
> se nota que está ahí. Quizá ahí el camaleón pueda adoptar un poco los colores del fondo de la
> muralla, y como que se nota que se mueve, y que es un poquito más borroso, [acechando] a la
> exploradora con la maga."*

### Lo que esto agrega o corrige respecto del boceto

1. **El guerrero es el ancla y OBSERVA.** No sólo fuma: está mirando la escena de rescate. Su
   mirada es la que dirige la del jugador hacia la acción.
2. **La exploradora está TIRANDO de la maga**, sacándola del mímico. No están las dos quietas:
   hay un esfuerzo en curso. La maga *fue comida* — está siendo extraída.
3. **El camaleón acecha a LAS DOS** (exploradora + maga), no sólo a la exploradora.
4. **El ojo parpadea.** Un ojo concreto en la oscuridad que se abre y se cierra sin parar — es un
   elemento animado con ritmo propio, no una mancha fija.
5. **El camaleón se camufla contra el muro**: adopta los colores de la piedra de fondo. Se ve
   **porque se mueve**, no porque contraste. Y va **más desenfocado** que el resto.

### Reglas de lectura que salen de ahí

- **El movimiento es lo que revela**, no el color ni el contraste. El camaleón está a la vista y
  aun así cuesta verlo: lo delata el desplazamiento. Eso obliga a que la pantalla esté VIVA.
- **Profundidad por foco**: el camaleón va más borroso que el grupo en primer plano. Hay planos de
  nitidez, no una imagen pareja.
- **Tres focos de atención en cadena**: guerrero en reposo → rescate en curso → amenaza que nadie
  ve. El jugador los descubre en ese orden.

## Pase de detalle del owner (2026-08-08)

Segunda vuelta sobre la escena. Manda sobre todo lo anterior donde haya choque.

### Arquitectura — tumba antigua, no dungeon genérico

El pasillo de la derecha (y por extensión el salón) es **estructura antigua tipo tumba**:
cemento viejo, **losas**, piedra de muralla, **algún pedazo caído** en el suelo. Referencias que
nombró: *pirámide, azteca*. Vieja, pesada, construida — no cueva natural.

### La antorcha define la luz

Hay **una antorcha en el pasillo**, montada **a la altura del salón** (donde está el título).
Es la fuente de luz que hace existir la oscuridad: **ilumina su tramo y deja el resto del pasillo
negro**. También derrama algo de luz hacia el salón. La oscuridad no es ausencia decorativa —
es el borde de alcance de esa antorcha.

### Los ojos

En la oscuridad del pasillo. **Pestañean a veces** (no constante). Color **amarillo o rojo** —
el owner dejó las dos abiertas.

### El guerrero

Sentado, fumando en pipa, junto a la fogata. **Con armadura, quizá sin casco.** El escudo y la
espada **apoyados contra la pared** (corrige "espada clavada en el suelo"). Y el detalle que da
el descanso: los **brazaletes / avambrazos sueltos tirados alrededor de él**, como si se los
hubiera sacado para descansar un rato.

### El rescate — referencia Frieren

**Al otro lado de la fogata**, la exploradora saca al mago o maga del cofre-mímico. **Está
luchando por sacarlo** — esfuerzo físico visible. Referencia de tono que el owner ya había dado:
**Frieren**. No hay carpeta `_references/frieren/` — Frieren vive como ref transversal en
`_art_canon.md` §1.3 (*"paciencia académica, melancolía silenciosa"*) y en `_world_references.md`.
Lo que aporta acá es el registro: aventura cotidiana y sin épica, un percance que se resuelve
tironeando, compañeros que se conocen hace rato. **Nadie está actuando heroicamente.**

### El camaleón — evento temporizado, no elemento fijo

Cambia de naturaleza respecto de lo anterior. **Aparece, mira y se va:**

- **Pasa por arriba** y lo mira desde la muralla.
- Está camuflado, pero se lo nota: **transparencia borrosa** que no lo deja pasar desapercibido.
- **Ojos independientes mirando a todos lados** — uno arriba, otro abajo. Preocupado del entorno,
  no fijado en una presa.
- **Saca la lengua.**
- **Dura unos segundos**, después se mueve y **desaparece de la pantalla**.

Esto lo convierte en un **evento con ciclo propio** dentro de una pantalla que loopea, no en parte
de la composición fija. La composición tiene que funcionar igual cuando el camaleón no está.

## Estilo — RESUELTO (owner, 2026-08-01): 3D texturizado tipo Path of Exile

El owner planteó primero *"todo es realmente tal cual el boceto a mano"* y acto seguido lo
resolvió al revés:

> *"puede ir más parecida como una textura de Path of Exile. No creo que sea como dibujada a mano,
> más parecido al logo que construimos."*

**Decisión firme: NO ilustración a mano. Escena 3D texturizada, en el mismo lenguaje que el logo**
— materiales fotográficos con relieve real, luz física, atmósfera. El boceto a mano sigue siendo
la fuente de **composición y contenido**, no de acabado.

Consecuencias directas:
- El logo 3D entra tal cual, sin traducirlo a otro lenguaje.
- Aplica todo lo aprendido en `[[gate]]` y `[[dungeon_interior]]`: mapas de normal/AO/displacement
  cableados a mano, luz rasante, dos temperaturas.
- Referencia de acabado obligatoria: `[[poe_visual_bar]]` y `[[village_poe_style]]`.

**Antecedente que obliga a estudiar antes de construir**: el owner descartó `tree_pack` entero por
hacer "estilo PoE" sin analizar por qué los troncos de PoE son así.

## Forma — composición

Encuadre horizontal, tres bandas de profundidad:

- **Fondo / derecha**: **pasillo de tumba antigua** en oscuridad — losas, cemento viejo, piedra de
  muralla, pedazos caídos. Dentro de esa oscuridad, **varios pares de ojos** (amarillos o rojos)
  que **pestañean a veces** — los mobs mirando. **Una antorcha montada a la altura del salón** es
  la que define hasta dónde llega la luz y dónde empieza el negro.
- **Medio**: el **título como objeto sólido** en el salón, alto y centrado, con volumen real. El
  **humo de la pipa y la fogata lo atraviesa** — volutas por delante y por detrás, sin taparlo.
- **Primer plano / base**: el grupo en el suelo, a ambos lados de la fogata —
  1. La **fogata** como centro y ancla de luz cálida.
  2. De un lado, el **guerrero sentado** con armadura (quizá sin casco), fumando en pipa, con
     **escudo y espada apoyados contra la pared** y los **brazaletes sueltos tirados alrededor**.
  3. Del otro lado, la **exploradora luchando por sacar al mago/maga** del **cofre-mímico** con
     dientes. El mímico ya mordió — no está por actuar.
- **Arriba a la izquierda**: el **camaleón** (dedos ventosa, ojos saltones) **de paso por la
  muralla**. No es parte fija de la composición — entra, mira, saca la lengua y se va (ver pase
  2026-08-08). Ellas no lo ven.

## Colores

Boceto a lapicera — casi todo monocromo. Las dos únicas decisiones de color presentes:

| Elemento | Color en el boceto | Estado 2026-08-08 |
|---|---|---|
| Línea de humo que sube al título | **rojo** | sin reconfirmar — el humo ya no forma el título |
| Ojos de los mobs en la oscuridad | **rojo** | **amarillo o rojo** — owner dejó las dos abiertas |

Lo que sí está definido es la **estructura de luz**: la antorcha del pasillo y la fogata del salón
son las dos fuentes. Todo lo cálido sale de ahí; el resto es el negro que ellas no alcanzan.
Paleta completa **sin definir**.

## Movimiento / feel

Es una **escena viva, no una ilustración fija.** Todo se mueve solo: el humo sube y **atraviesa**
el título (delante y detrás), la fogata parpadea, los ojos de la oscuridad se abren y cierran a
intervalos, la exploradora forcejea con el mímico, y el **camaleón entra y sale en un ciclo de
unos segundos**.

Hay entonces **dos capas temporales**: un loop de fondo permanente (fuego, humo, forcejeo, ojos) y
**eventos que van y vienen** (el camaleón, un parpadeo de ojos concreto). La pantalla no puede
depender de los eventos para verse bien.

El tono es **calma con amenaza encima**. Un alto en el camino: alguien fuma, alguien ya salió
lastimado de un cofre, y arriba y a la derecha el dungeon los está mirando. Nadie está peleando.
Esa es la promesa del juego en una imagen — descanso prestado.

## Qué capturar

1. **El título es materia dentro del mundo.** Sólido, con volumen, ocupando lugar en el salón —
   y el humo lo **atraviesa** por delante y por detrás para probarlo. Ni sobrepuesto, ni hecho
   de humo.
2. **Los ojos en la oscuridad.** La amenaza no se muestra, se insinúa. Pestañean.
3. **El grupo en reposo, con secuelas.** El mímico ya mordió, el guerrero ya se sacó los
   brazaletes. La escena tiene pasado.
4. **El acecho que el personaje no ve.** El camaleón de paso — el jugador sabe algo que el
   personaje no. Y se va, así que quien mire poco se lo pierde.
5. **La antorcha es la que dibuja la oscuridad.** La luz motivada, no niebla negra puesta encima.
6. Composición horizontal con el título alto y centrado, y el grupo abajo — deja el aire de la
   derecha para la oscuridad, y sitio libre bajo el título para los botones del menú.

## Relación con el logo

El `Título` del boceto es un **placeholder**: dice literalmente "Titulo" en una caja. Lo que va
ahí es el logo de `[[logo]]` — el lettering con la U-portón.

Con la corrección del 2026-08-08, el logo **entra como geometría 3D real dentro del salón**, no
como sprite ni overlay. Eso le exige lo mismo que a cualquier prop de la escena: material
texturizado, que reciba la luz de la fogata y la antorcha, y que proyecte y reciba sombra. Es una
pieza más de la mazmorra que además se lee como título.

### Cómo vive el título en la sala (owner, 2026-08-08)

> *"podríamos probar primero que fuera parte de la tumba, pero que se notara más, que fuera un
> poco más resaltado. Quizá que esté como flotando dentro de la sala y adelante. La idea igual
> está que se note (...) debería ser color diferente a la muralla. Y se genera la sombra: si está
> la fogata desde abajo por adelante, en la muralla se va a generar como la sombra del Dungeon."*

Cuatro decisiones:

1. **Pertenece a la tumba** — mismo lenguaje de materia y desgaste que la arquitectura. No es un
   objeto de otro universo pegado encima.
2. **Pero resaltado** — no se funde con el fondo. Tiene que leerse a la primera.
3. **Flotando dentro de la sala, adelante.** No montado en muro: suspendido, en plano delantero.
4. **Color distinto al de la muralla.** Nota de ejecución: el muro del blockout y el render actual
   del logo son ambos **piedra cálida ocre** — si se deja así, se camufla. La separación más
   barata es **por temperatura, no por valor**: todo el salón es cálido (fogata + antorcha), así
   que un material **frío** (piedra oscura, basalto, bronce con pátina verdosa) se despega solo,
   sin necesidad de subirle el brillo ni sacarlo de la lógica de la tumba.

### La sombra proyectada — elemento de primer orden

La fogata está **abajo y adelante** del título. Eso proyecta la **sombra del logo hacia arriba
sobre el muro del fondo**, grande y deformada por la perspectiva. Y como la fogata parpadea, esa
sombra **respira y tiembla** sola.

Vale doble:
- Es la prueba visual de que el título es materia dentro de la sala, no una capa encima.
- Es movimiento de fondo gratis para el loop, sin animar nada.

### Cómo se sostiene — RESUELTO: enredaderas (owner, 2026-08-08)

Se descartó la propuesta de cadenas. Joan:

> *"sobre flotando, podría estar con enredadera. Ya que estamos usando las enredaderas en el
> título. Ese tipo de cosas también podrías tú generar como coherencia."*

**El título cuelga enredado en vegetación que baja del techo.** Resuelve la tensión
"parte de la tumba + flotando" sin invocar magia: no levita, está **atrapado en raíces**.

**OJO — son dos roles botánicos distintos, no repetir el mismo activo:**

| Rol | Comportamiento | Fuente |
|---|---|---|
| Enredadera **sobre las letras** | trepadora **pegada a la cara** de la letra, ramificada en abanico, hojas chicas | canon `[[vine]]`, ya definido |
| Vegetación **que sostiene** | raíces / lianas que **caen** desde una grieta del techo y envuelven el logo | nuevo, este pase |

La trepadora del canon `[[vine]]` **se agarra de una superficie** — un título flotando no le da
superficie de dónde agarrarse. Lo que cuelga tiene que ser **raíz colgante**, que es otra planta y
otra silueta. Confundirlas rompe la lógica de la referencia.

**Por qué encaja con la tumba**: una estructura antigua enterrada con raíces que rompieron el
techo y bajaron adentro. Explica la grieta, explica la luz que podría filtrarse, y explica por qué
el logo está ahí colgado.

**Bonus — resuelve el problema de color de arriba.** El salón entero es cálido (fogata + antorcha).
El **verde del follaje** y el **magenta de la buganvilla** (`[[vine]]`: el color más saturado del
logo, acento en UNA sola letra) son ambos fríos contra el ocre de la piedra. **La vegetación
separa el título del muro sin tener que cambiarle el material a la piedra** — se cumple "color
diferente a la muralla" y "parte de la tumba" al mismo tiempo.

**Y da movimiento**: balanceo lento de las raíces en el loop, y el humo cruza también entre ellas.

**Sin confirmar**: material exacto del lettering, densidad de la raíz colgante, y escala del logo
respecto de los personajes.

## Estado

**Blockout inicial hecho** (`tools/logo/titlescreen.blend` → `tools/logo/out/titlescreen_block.png`,
2026-08-01): salón de piedra con techo y vano a la derecha, fogata de bloques. Nada de esto está
texturizado ni poblado todavía, y precede al pase de detalle del 2026-08-08.

**Pendiente de decisión antes de construir**: si la pantalla corre viva en Godot (escena 3D real,
cámara + partículas en engine) o es un render/video pre-hecho en Blender que Godot reproduce.

Ver `[[asset/titlescreen]]` en engram.
