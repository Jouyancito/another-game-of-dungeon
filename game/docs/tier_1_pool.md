# Tier I — Pool de Pisos (1–25)

**Documento**: Templates de los pisos del Tier I
**Estado**: Borrador — primeros 5 pisos del ascenso inicial
**Relación**: `DESIGN_BRIEF.md` §6 Tier I + §11 plantilla de 11 campos
**Orden de diseño**: estos 5 pisos representan la **primera experiencia del jugador** (pisos 1→5 en la primera run). Son los templates más importantes porque son los que entregan la tesis del juego.

---

## Filosofía del arranque (pisos 1–5)

El jugador que abre Dungeon Party por primera vez recorre estos 5 pisos en ~2 horas y **decide si el juego le interesa o no**. Estos pisos son la carta de amor. Tienen que:

1. **Introducir todos los sistemas del juego en vivo**, no en menús.
2. **Presentar las 5 primeras familias de piso** (tutorial → combate → exploración → evento → descanso) para que el jugador entienda de entrada la variedad del diseño. No todo es pelear.
3. **Dejar rumores del Tier V** sin explicarlos.
4. **Nunca abrumar** — son el tier de "curiosidad, asombro, calidez".

**Nota importante sobre el boss del tier**: el **Trono Viscoso** NO vive en estos primeros 5 pisos. Es el **ancla fija del P24**, justo antes de la safe zone del P25. Estos 5 pisos son la **apertura del tier**; el boss es el **cierre**. El jugador alcanza el boss después de ~10-15 horas de gameplay, tras recorrer los 23 pisos anteriores del tier. El diseño completo del Trono Viscoso vive en `memory/project_boss_trono_viscoso.md` y se integrará a un doc propio de pisos 20-25 del Tier I cuando lo diseñemos.

**Dirección MMORPG**: todos estos pisos son diseñados instance-safe. Los pisos abiertos (1, 2, 4) pueden ser shared entre grupos en el futuro; las sub-dungeons (3, 4) son instanced por party; el boss del 5 es instanced por party siempre.

---

## PISO 1 — Pradera Interior (Tutorial Zone — FIJO)

```yaml
piso:
  nombre_working: "Pradera Interior"
  tier: 1
  bioma_base: "pradera_interior"
  familia: "tutorial"            # único en el juego — solo el P1 tiene esta familia
  funcion: >
    Enseñar al jugador TODOS los sistemas del juego en un entorno con red de
    seguridad. Primer contacto con el mundo, primer combate, primer loot,
    primer equipar, primera muerte, primer revive. Aprendizaje vivo, no menús.

  emocion_dominante: "descubrimiento cálido, asombro contenido"

  landmark: >
    El diamante emisivo gigantesco del techo de caverna + la curva S de
    cristales Vía Láctea en lo alto + el outpost fortificado con humo
    saliendo de su chimenea al fondo del mapa. El jugador, apenas aparece,
    ve los tres al mismo tiempo y entiende: "estoy adentro de algo enorme".

  lectura_espacial: >
    Abierto (600×600m). Outpost como ancla central. POIs distribuidos
    radialmente en anillos (cerca: fauna pacífica + quests iniciales;
    medio: combate contra enemigos nivel 1-3; lejos: POIs peligrosos
    como ruinas, campamentos bandidos, boss room). Bordes orgánicos:
    acantilado N, playa/lago S, pared de torre E, cascadas W.

  mecanica_distintiva: >
    Red de seguridad del outpost. El perímetro fortificado ofrece servicios
    (comercio básico, herrería inicial, stash pequeño, curación NPC, quest
    board). Apenas el jugador cruza la empalizada, el mundo empieza a
    enseñarle con peligro real. Tutorial vivo: aprender cae, equipar, morir
    y revivir SIN cinemáticas ni tooltips invasivos.

  recompensa:
    - "Cofre inicial al salir del outpost con equipment común del nivel"
    - "Loot tables de slime, rata, zorro, lobo, pájaro, bandido (10 tablas)"
    - "Quest del Capitán: '5 geles de slime' → gold + primer anillo común"
    - "Pesca en el estanque (POI pond) → materiales de alquimia"
    - "Quest del Veterinario: cuidar a un conejo herido → cosmético de pet"
    - "Diario suelto en el altar olvidado (lore: rumor del Tier V)"
    - "Stash inicial de 40 slots gratis"

  peligro: >
    Bajo-medio. Enemigos nivel 1-3 (slimes, ratas, zorros, lobos, pájaros,
    algunas avispas cerca del pantano pequeño). Bandidos nivel 4-5 en el
    campamento del POI camp (zona de "ok, ya estás listo"). NO hay boss
    en este piso específico — el Trono Viscoso vive en el P5 dedicado.
    El downed es posible si el jugador ignora el outpost y se mete solo
    a los campamentos antes de equiparse.

  rol_en_tier: >
    Abrir el tier y el juego entero. Es la carta de amor del juego al
    jugador nuevo. Si este piso falla en transmitir "esto es un dungeon
    crawler cooperativo con alma melancólica y mundo vivo", todo falla.

  vida_visual:
    - "Mariposas sobre flores (MultiMesh con path random)"
    - "Pájaros en copas de árboles (Area3D espanto al acercarse)"
    - "Ardillas cruzando caminos"
    - "Peces en el estanque (shader simple)"
    - "Ciervos blancos cerca del lago (no atacan, huyen de lejos)"
    - "Carreta de mercader con 5 estados visibles"
    - "Guardias del outpost patrullando el perímetro"
    - "Campesinos, pastores con rebaños, cazadores friendly"
    - "Veterinario curando un conejo en el outpost"
    - "Humo saliendo de la chimenea del outpost"

  retirado_posible:
    nombre: "El Ciervo de los Ojos Viejos"
    tier_original: 4
    estado: "Cansado, pacífico, nunca ataca"
    aparicion: "Raro — parpadea brevemente en un claro al amanecer in-game"
    drop: "Asta Antigua (cosmético de pet)"
    lore: "Fue el guardián de un jardín del Tier IV que ya no existe. Se quedó."

  sub_dungeon_opcional: "Ninguna en el Piso 1. El tutorial no debe distraer."

  mision_emergente_seed:
    - "El Cazador Perdido: aparece en el POI giant_tree pidiendo que encuentren a su hijo (trigger solo si el jugador explora el árbol grande)"

  por_que_encaja: >
    Piso 1 = tutorial zone obligatorio, fijo, irreemplazable. Es donde el
    juego presenta su tesis. El outpost con guardias + la fauna pacífica +
    los POIs + los cristales del techo + la primera muerte enseñan todo
    sin tooltips. Referencias: Frieren (la primera vez que Fern ve algo
    antiguo), Skyrim (la cinemática del carromato convertida en mundo).
```

---

## PISO 2 — Bosque del Lindero

```yaml
piso:
  nombre_working: "Bosque del Lindero"
  tier: 1
  bioma_base: "bosque_denso_ligero"
  familia: "combate"
  funcion: >
    Primera salida real del jugador a un piso sin outpost. Combate contra
    manadas coordinadas. Introduce oscuridad parcial y sub-dungeons como
    contenido opcional. Es el piso que dice: "ahora sí estás en la torre."

  emocion_dominante: "curiosidad tensa, primer desafío real, intimidad del bosque"

  escala: "~200×200m (compacto — mucho más chico que la Pradera del P1)"

  landmark: >
    Un árbol doble monumental cuyos dos troncos se unen en la base,
    con un nido abandonado a 15m de altura anidado entre ambos troncos.
    A sus pies, un círculo de hongos bioluminiscentes gigantes (2-3m
    de alto, color cian #7ECFD8) que al anochecer iluminan el tronco
    como linternas orgánicas. Los jugadores dicen "nos vemos en el árbol
    doble" y todos saben dónde. Se ve desde cualquier punto del piso
    por la emisión de los hongos, no por línea de vista directa.

  lectura_espacial: >
    Compacto y claustrofóbico (~200×200m). Canopy denso que bloquea
    CASI TODA la vista del techo de caverna: el jugador casi no ve los
    cristales Vía Láctea, solo vislumbres esporádicos a través de agujeros
    en el follaje. Esto crea un contraste fuerte con el P1 (de apertura
    total a cierre total). Sendas estrechas entre árboles gigantes con
    hongos gigantes, telarañas colgando entre troncos, plantas carnívoras
    dormidas en el suelo. Un río pequeño atraviesa el piso de norte a sur.

  mecanica_distintiva: >
    Oscuridad casi total + hazards ambientales + manadas. El canopy denso
    hace que la antorcha sea CASI OBLIGATORIA en zonas sombrías. Las
    telarañas ralentizan si las atravesás (50% speed por 3s — mesh semi-
    transparente entre troncos). Las plantas carnívoras despiertan al
    acercarse a 4m y atacan con mordida si no las ves (DoT leve, se
    esquivan rodando). Los hongos gigantes emiten luz tenue pero son
    terreno visual — se usan como puntos de referencia en el laberinto.
    Los lobos atacan en manada de 3-4: uno distrae, los otros rodean —
    enseña al jugador coop o al solo a usar los árboles como cobertura.

  recompensa:
    - "Drops de lobos, zorros, serpientes, arañas (materiales + equip raro)"
    - "Nidos en árboles altos con huevos especiales (material alquimia)"
    - "Hongos bioluminiscentes (light source consumible)"
    - "Sub-dungeon 'Madriguera del Lobo Blanco' (opcional) → minijefe + capa única"
    - "Retirado posible: El Grifo Cansado (ver abajo)"

  peligro: >
    Medio. Enemigos nivel 3-5. Lobos en manada (IA coordinada), serpientes
    venenosas (DoT), arañas emboscadoras, avispas cerca del río. Primera
    aparición probable del downed si el grupo se separa. Sin boss.

  rol_en_tier: >
    Primer combate REAL después del tutorial. Enseña que las manadas son
    distintas de enemigos solitarios. Enseña sub-dungeons como contenido
    opcional. Introduce el concepto de Retirados. Enseña que la antorcha
    importa. El jugador sale de acá con su primer "recuerdo de combate".

  vida_visual:
    - "Luciérnagas doradas en las zonas de sombra (MultiMesh con emission, más densas que en P1)"
    - "Pájaros que se espantan al acercarse (Area3D trigger)"
    - "Ardillas trepando árboles"
    - "Telarañas colgando entre troncos (hazard: ralentiza 50% speed × 3s, algunas con araña real)"
    - "Hongos gigantes cian-azulados (2-3m de alto) con emission sutil, puntos de referencia en el laberinto"
    - "Plantas carnívoras dormidas camufladas entre raíces (hazard: muerden a 4m)"
    - "Troncos caídos musgosos"
    - "Ciervos asustadizos que huyen al verte"
    - "Cuervos en las ramas altas"
    - "Niebla baja al nivel del suelo (fog ground shader)"
    - "Polvo dorado flotando en los escasos haces de luz que cruzan el canopy"

  retirado_posible:
    nombre: "El Grifo Cansado"
    tier_original: 4
    estado: "Dormido contra el árbol grande, no ataca a menos que se lo ataque primero"
    aparicion: "Muy raro — quizás 1 de cada 15 runs"
    drop: "Pluma del Grifo (cosmético de cape) + log en codex"
    lore: >
      Fue el último grifo de una bandada de las Plataformas del Cielo.
      Bajó cuando las tormentas del Tier IV lo expulsaron. Duerme porque ya
      no tiene a quien proteger. Si el jugador lo mata, el codex registra
      'el mundo perdió algo'.

  sub_dungeon_opcional:
    nombre: "Madriguera del Lobo Blanco"
    estructura: "4 salas + boss room"
    mecanica: "Oscuridad total — la antorcha es obligatoria dentro"
    minijefe: "Lobo Blanco Alfa (3x HP de lobo normal, ataques en cadena)"
    recompensa_exclusiva: "Capa del Lobo Blanco (DEF+4, cosmética distintiva blanca)"
    entrada_señalada_por: "Huellas de sangre que llevan a una grieta al sur"

  mision_emergente_seed:
    - "El Cazador Lesionado: tirado en la base del árbol grande, dice que un oso enorme se llevó su arco al norte → trigger de exploración"
    - "La Niña del Bosque: aparece al atardecer in-game, dice que escucha una voz en la cueva del lobo → confirma el rumor de la sub-dungeon"

  por_que_encaja: >
    Tier I necesita un piso de combate real después del tutorial. El bosque
    ofrece lectura espacial distinta del outpost + manadas + oscuridad parcial.
    Es el momento donde el jugador pasa de "aprendo" a "aplico". Referencias:
    bosque del DanMachi Piso 3, bosques de Sword Art Online Piso 1, Frieren
    cuando cruzan bosques antiguos.
```

---

## PISO 3 — Las Ruinas del Peregrino

```yaml
piso:
  nombre_working: "Las Ruinas del Peregrino"
  tier: 1
  bioma_base: "ruinas_antiguas_superficiales"
  familia: "exploracion"
  funcion: >
    Bajar el ritmo de combate. Premiar exploración con loot, lore y secretos.
    Introducir que el mundo tiene historia — que la torre existía antes del
    jugador. Primera dosis de melancolía suave.

  emocion_dominante: "asombro nostálgico, codicia controlada, respeto"

  landmark: >
    Una estatua gigantesca medio derrumbada de un peregrino encapuchado,
    mirando hacia el diamante del techo de caverna. A sus pies, ofrendas
    viejas de piedra — monedas petrificadas, flores secas, un libro cerrado.
    La estatua se ve desde cualquier punto del piso. Es el ancla visual.

  lectura_espacial: >
    Fragmentado. Estructuras parcialmente derrumbadas conectadas por caminos
    de piedra irregular. Rincones escondidos, escaleras rotas, cámaras
    semi-colapsadas, columnas caídas usadas como puentes improvisados. Se
    puede trepar, esconder, rodear. Varios altares distribuidos en el piso
    forman un circuito de lore.

  mecanica_distintiva: >
    Cofres escondidos detrás de columnas, bajo baldosas sueltas, dentro de
    sarcófagos, arriba de repisas. El jugador es premiado por MIRAR, no por
    PELEAR. Varios altares con diarios fragmentados que arman una historia:
    la Orden del Peregrino, lo que les pasó, y el primer rumor concreto del
    Tier V (un nombre, una frase, una imagen).

  recompensa:
    - "3–5 cofres escondidos con equipment rare/magic"
    - "Altar principal: diario completo del Peregrino (primera cita del Tier V)"
    - "Reliquia con bonus INT (en la sub-dungeon)"
    - "Misión emergente: 'La última peregrina' pide encontrar a su hermano"
    - "Retirado posible: La Hermana Olvidada (fantasma pacífica)"
    - "Sub-dungeon 'La Cripta del Primer Maestro'"
    - "Drops de cuervos, lagartijas (materiales únicos de ruinas)"

  peligro: >
    Bajo-medio. Pocos enemigos normales en el exterior (cuervos hostiles,
    arañas de ruina, algún esqueleto suelto — eco del Tier II). Estatuas
    animadas como guardianes en la sub-dungeon. Trampas desactivables en
    el suelo. El peligro real son los derrumbes que cierran caminos
    temporalmente (5 min, reabren solos).

  rol_en_tier: >
    Enseñar que hay contenido fuera del combate. Primer encuentro con el
    lore del mundo. Introduce misiones emergentes con NPC vivo. Primera
    aparición sutil de melancolía (el fantasma de la hermana, la Orden que
    ya no existe). Prepara emocionalmente al jugador para el lore del boss
    del tier.

  vida_visual:
    - "Cuervos en las columnas rotas"
    - "Lagartijas en las piedras calentadas"
    - "Polvo dorado flotando en los rayos de luz del diamante del techo"
    - "Musgo verde y ocre cubriendo las estatuas"
    - "Hojas secas arremolinándose en el viento"
    - "Fantasma tenue de la Hermana Olvidada flotando entre las columnas"
    - "Mariposas raras (color gris-azulado) solo en este piso"
    - "Un cuervo enorme (decorativo) sentado en la cabeza de la estatua grande"

  retirado_posible:
    nombre: "La Hermana Olvidada"
    tier_original: 5
    estado: "Fantasma pacífica, NPC no combate"
    aparicion: "Si el jugador deja una ofrenda (consumible) en el altar principal"
    drop: "Bendición de la Hermana (buff temporal +10% XP por 30 min)"
    lore: >
      Fue una peregrina de la Orden que llegó al Piso 100 y volvió. Nadie
      le creyó. Se sentó en estas ruinas a esperar a su hermano, que siguió
      subiendo. Su hermano nunca volvió. Ella tampoco se fue.

  sub_dungeon_opcional:
    nombre: "La Cripta del Primer Maestro"
    estructura: "4 salas + puzzle de luces + boss room"
    mecanica: >
      Las estatuas del pasillo central solo son pasivas mientras haya luz
      sobre ellas. Un jugador lleva la antorcha, los otros pelean o resuelven.
      El puzzle de luces requiere encender 4 braseros en orden.
    minijefe: >
      El Primer Maestro (estatua animada de 3m, lento pero mata de un golpe
      si te atrapa). Usa las columnas como cobertura.
    recompensa_exclusiva: >
      Reliquia del Maestro (anillo con INT+3 y una pasiva: regenera 1 MP
      extra en combate). Primera vez que el jugador ve un item único de verdad.
    entrada_señalada_por: >
      Un cuervo negro parado sobre una grieta cubierta de hiedra seca.
      Si el jugador se acerca, el cuervo vuela revelando la entrada.

  mision_emergente_seed:
    - "La última peregrina: NPC viva al pie de la estatua grande. Dice que su hermano se metió a la cripta hace una semana y no salió → directa a sub-dungeon. Al rescatarlo, ambos vuelven al outpost del P1 como mercaderes permanentes."
    - "El erudito curioso: en el altar menor, un NPC pide transcripción de 3 placas del piso → recompensa: pergamino de teletransporte al P1"

  por_que_encaja: >
    Tier I necesita un respiro de combate después del Piso 2. Las ruinas
    cuentan al jugador que el mundo existía antes que él. Primera dosis de
    lore y melancolía suave, sin romper el tono cálido del tramo inicial.
    Es donde el jugador entiende "esta torre no la hice yo, hay historia acá".
    Referencias: Frieren + DanMachi Labyrinth del Gran Árbol + catacumbas de
    Elden Ring (contenidas, no abismales).
```

---

## PISO 4 — El Paso del Mercader

```yaml
piso:
  nombre_working: "El Paso del Mercader"
  tier: 1
  bioma_base: "pradera_interior_variante_camino"
  familia: "evento"
  funcion: >
    Introducir misiones emergentes narrativas como sistema central del juego.
    Primer combate contra facción humana (bandidos). Primer evento dinámico
    con consecuencias que cambian el outpost del P1. Última parada antes del
    boss del tier.

  emocion_dominante: "urgencia cálida, heroísmo contenido, tensión moral suave"

  landmark: >
    El Paso de la Rueda Rota — una garganta angosta entre dos colinas bajas,
    con una carreta volcada en el centro (sana, emboscada, rota, masacrada o
    pidiendo material según el seed) y rastros frescos de pelea. Desde las
    colinas, se ven las banderas del campamento bandido al fondo.

  lectura_espacial: >
    Lineal con desvíos. Un camino principal atraviesa el paso de E a W, con
    desvíos a los lados: escondite de bandidos al norte, cueva de los Lobos
    del Paso al sur, colinas con vista al este, y un bosque pequeño con un
    altar de ofrenda al oeste. El jugador elige qué desvíos tomar — puede
    ir directo al boss del próximo piso si ignora todo.

  mecanica_distintiva: >
    Eventos dinámicos del mercader en 5 estados visibles (sano / emboscado /
    rueda rota / ya masacrado / pidiendo material). El estado se decide por
    seed de la run. Cada estado abre una interacción distinta con consecuencias
    distintas en el outpost del Piso 1. Primera vez que el jugador siente que
    sus decisiones importan a nivel narrativo.

  recompensa:
    - "Gold + equipment del campamento bandido (loot table bandit completa)"
    - "Si salvás al mercader: vuelve al P1 con tienda premium permanente"
    - "Misión emergente principal: 'La hermana raptada' → sub-dungeon"
    - "Corona Oxidada drop del bandit leader (versión menor de la del boss)"
    - "Sub-dungeon 'Cueva de los Lobos del Paso'"
    - "Retirado posible: El Mensajero Perdido"
    - "Mapa parcial del Piso 5 (boss room) si se saquea la tienda bandida"

  peligro: >
    Medio. Bandidos nivel 4-6 en grupos coordinados (tanque + arquero).
    Líder del campamento es elite con 3x HP, ataque con arco de dos disparos.
    Lobos del paso en las colinas. Emboscadas en los desvíos. Downed
    probable si el grupo no coordina contra los arqueros bandidos — primer
    aprendizaje de que los enemigos humanos son tácticos, no embisten.

  rol_en_tier: >
    Introducir combate humano (no solo fauna). Introducir misiones emergentes
    con consecuencias narrativas permanentes (el mercader vuelve). Última
    escala antes del boss. Primer encuentro con "decisiones que cambian el
    outpost" — el jugador aprende que el mundo responde a lo que hace.

  vida_visual:
    - "Cuervos sobre los cuerpos del campamento"
    - "Humo del fogón de los bandidos"
    - "Caballo del mercader pastando si está vivo / huido si emboscado"
    - "Banderines rotos de los bandidos agitándose en el viento"
    - "Ardillas en las colinas"
    - "Mariposas en los claros alejados del combate"
    - "Vendedor ambulante fantasma (si el mercader fue masacrado) — NPC raro, no interactúa"
    - "Perros del mercader si sobrevivió (2–3, cerca de la carreta)"

  retirado_posible:
    nombre: "El Mensajero Perdido"
    tier_original: 3
    estado: "Caminando sin rumbo por el paso, ignora a todos"
    aparicion: "Raro — a veces pasa cerca del campamento bandido sin que estos lo ataquen"
    drop: "Pergamino Sellado (entregarlo al Capitán del outpost da gold + título)"
    lore: >
      Llevaba un mensaje del Piso 50 al Piso 1 sobre algo que vio más arriba.
      Cruzó el umbral y olvidó a quién se lo tenía que entregar. Camina desde
      entonces, sellado, inútil, recordando a medias.

  sub_dungeon_opcional:
    nombre: "Cueva de los Lobos del Paso"
    estructura: "4 salas + 2 minijefes (líder bandido + lobo blanco del paso)"
    mecanica: >
      La primera sala está bloqueada por una puerta que se abre desde adentro.
      Hay que entrar por un pasaje trasero escondido detrás de una cascada
      pequeña. Dentro: oscuridad parcial + enemigos mixtos (bandidos + lobos
      entrenados). Rescate de la hermana al fondo.
    minijefes:
      - "El Carnicero: bandido con hacha a dos manos, 4x HP"
      - "Lobo Blanco del Paso: más pequeño que el del P2 pero encadenado"
    recompensa_exclusiva: >
      La hermana rescatada (vuelve al P1 como NPC quest giver permanente)
      + Anillo del Viajero (accesorio INT+3, raro) + equipment bandido
    entrada_señalada_por: >
      Cascada pequeña al sur del campamento. Detrás hay una grieta natural
      con un cadáver sentado contra la pared (el aventurero herido moribundo
      que dio la quest).

  mision_emergente_seed:
    - "La hermana raptada (PRINCIPAL): aventurero herido al borde del camino, pide rescate → sub-dungeon"
    - "El buhonero desesperado: si la carreta está rota (estado seed), pide material específico (clavo de hierro, 3 tablones) → recompensa: pergamino de teletransporte"
    - "El guardia que no vuelve: si el jugador habla con el Capitán del P1 antes de entrar al P4, hay una quest de encontrar a su guardia desaparecido → cadáver cerca del campamento bandido"

  por_que_encaja: >
    Tier I necesita introducir misiones emergentes y combate humano antes del
    boss del tier. Es la última parada antes del Trono Viscoso — el jugador
    llega al boss sabiendo que sus decisiones importan, no solo el daño que
    hace. Referencias: las caravanas de Skyrim, las misiones de paso de
    Witcher 3, el concepto de "mundo que responde" de Breath of the Wild.
```

---

## PISO 5 — El Claro del Fuego Solitario

```yaml
piso:
  nombre_working: "El Claro del Fuego Solitario"
  tier: 1
  bioma_base: "pradera_interior_variante_bosque"
  familia: "descanso"            # subtipo: cálido
  funcion: >
    Primer descanso REAL del juego. Enseñar al jugador que no todo es
    combate, que los pisos de descanso son contenido con voz propia,
    no relleno. Pausa emocional después del evento intenso del paso
    del mercader. Introducir NPCs itinerantes que pueden aparecer en
    otros pisos aleatorios del tier.

  emocion_dominante: "calidez, alivio, curiosidad tranquila"

  landmark: >
    Una fogata grande al centro del claro, con leña amontonada alrededor,
    y **La Bardo de los Cabellos de Ceniza** sentada en un tronco caído
    tocando una lira pequeña. Pelo blanco largo, túnica gris clara, figura
    delgada — guiño directo a Frieren. Al anochecer del ciclo visual del
    piso, luciérnagas rodean la fogata formando un domo de luz dorada denso.
    Se ve desde lejos por el resplandor entre los árboles.

  lectura_espacial: >
    Circular. Un claro amplio en el bosque al que llegan senderos desde
    3 direcciones. La fogata en el centro, tocones de árbol como asientos
    alrededor, un estanque pequeño al norte con peces visibles, una
    pérgola vieja de piedra al sur con asientos tallados cubiertos de
    musgo. Todo invita a sentarse.

  mecanica_distintiva: >
    Zona de paz forzada + ciclo visual día/noche. Los enemigos que se
    acerquen a 20m del fuego se alejan o se sientan a mirar (slimes
    pacíficos, lobos curiosos, zorros que se roban comida). No se puede
    atacar dentro del radio del fuego — el arma se envaina automáticamente.
    Primer piso donde el jugador pone las armas en la espalda. Además, el
    piso tiene un **ciclo visual corto (~3-4 min por fase)** que alterna
    entre día (tonos dorados cálidos, pocas luciérnagas) y noche (bosque
    oscuro azulado, domo denso de luciérnagas brillantes). El fuego es
    constante en ambas fases — es el ancla visual. Validado visualmente
    por las dos imágenes canon (day + night).

  recompensa:
    - "Buff 'Calor del Fuego' (+5% XP por 30 min) al interactuar con la fogata"
    - "Pesca en el estanque (materiales únicos: Escama de Luciérnaga, Pez del Claro)"
    - "Tienda limitada del bardo: pergaminos (teletransporte al outpost, curación menor), linterna de aceite, instrumentos pequeños, partituras"
    - "Quest emergente del bardo: Flor de Medianoche → canción única que da buff pasivo mientras él esté en el claro"
    - "Logro 'Amigo del Fuego' si alimentás al Gato del Bardo con pescado del estanque"
    - "Primera aparición del bardo como NPC recurrente del tier (puede volver a verse en otros pisos random)"

  peligro: >
    NULO dentro del claro. Cero combate en el radio del fuego. Apenas salís
    al bosque de vuelta, vuelven los enemigos del nivel del tier. El bardo
    explica en una línea: 'Este fuego recuerda cosas viejas. Los animales
    lo respetan.'

  rol_en_tier: >
    Enseñar que el descanso es contenido real, no relleno. Introducir a los
    NPCs itinerantes del tier (el bardo como recurrente). Primera pausa
    emocional del Tier I. Prepara al jugador para entender que la torre
    tiene lugares donde parar y respirar, no solo lugares donde pelear.
    También deja sembrado: en el Tier II aparece un santuario similar pero
    más triste.

  vida_visual:
    - "Luciérnagas al anochecer del ciclo rodeando el fuego"
    - "El Gato del Bardo descansando junto al fuego"
    - "Peces en el estanque (shader simple)"
    - "Mariposas nocturnas raras en los tocones"
    - "Polillas grandes atraídas al fuego"
    - "Sombras danzantes del fuego proyectadas en los troncos del bosque"
    - "Partículas musicales sutiles saliendo de la lira del bardo (cuando toca)"
    - "Un ciervo blanco que a veces se acerca al borde del claro y mira desde la distancia"
    - "Humo del fuego subiendo lento hacia el canopy"

  retirado_posible:
    nombre: "El Gato del Bardo"
    tier_original: 3
    estado: "Durmiendo junto al fuego, no ataca, no tiene habilidades activas"
    aparicion: "Siempre que este piso aparezca en la run (es parte del claro)"
    drop: "Ninguno — no se puede matar. Si intentás atacarlo, desaparece en humo y el bardo deja de tocar. Logro oculto anti-player: 'El que rompió la calma' (mensaje de consola, no achievement visible)"
    lore: >
      Fue el compañero de una maga del Tier III que murió intentando subir
      al Tier IV. El gato bajó solo, caminando, se sentó a este fuego, y
      se quedó. Acompaña a cualquier bardo que pase por el claro. Cuando
      el bardo no está, el gato sigue ahí solo, esperando.

  sub_dungeon_opcional: "Ninguna — el claro ES el contenido del piso."

  mision_emergente_seed:
    - "La Flor de Medianoche (PRINCIPAL): el bardo pide una flor azul que solo crece en claros con luciérnagas → quest rápida en el bosque alrededor → recompensa: canción del bardo que da +5% damage por 1h si él sigue en el claro"
    - "La Canción Perdida: el bardo busca una melodía que escribió hace tiempo y olvidó → pergamino escondido en un POI de ruinas del mismo tier (encadena con P3 si apareció antes)"
    - "El Recado del Gato: si alimentás al gato 3 veces en distintas runs, te entrega una nota sellada → llevarla a un mago del Tier III en una sesión futura (quest de largo plazo)"

  por_que_encaja: >
    Tier I necesita introducir la familia 'descanso' temprano para que el
    jugador entienda que el juego no es solo combate. P5 es el lugar ideal:
    después del evento intenso del P4 (paso del mercader), el jugador llega
    a un claro tranquilo con música y puede respirar. Pedagógicamente
    importante. Referencias: las tavernas al costado del camino de Skyrim,
    las fogatas de Dark Souls convertidas en contenido cálido, los descansos
    musicales de Frieren, la fogata del boss opcional de The Witcher 3.
```

---

## Qué falta del Tier I (pisos 6–25)

El pool del Tier I necesita completarse con 20 pisos más. Los primeros 5 ya usaron una instancia de cada familia (menos combate, que solo gastó 1 de 14). Distribución restante:

| Familia | Usados en P1-P5 | Restantes | Notas |
|---|---|---|---|
| Tutorial | 1 (P1) | 0 | Es único del Piso 1, no se repite |
| Combate | 1 (P2) | 12-13 | Variantes de bosque profundo, sabana seca, pantano borde, ruinas superficiales, praderas alternativas |
| Exploración | 1 (P3) | 2 | Más ruinas, cueva con cristales |
| Descanso | 1 (P5) | 1-2 | Santuario pequeño, lago de pesca (subtipo triste para variedad) |
| Evento | 1 (P4) | 2 | Fiesta del pueblo, concurso del cazador, caravana distinta |
| Anomalía | 0 | 1 | "El piso del viento y las cabras" (propuesto en §6 del brief) |
| Umbral | 0 | 1 | Piso inmediatamente antes del boss del P24 — transición emocional |
| **Boss (ancla fija)** | 0 | **1 (P24)** | **Trono Viscoso — no es template del pool, es ancla fija** |
| **Safe Zone (ancla fija)** | 0 | **1 (P25)** | **"Último Puesto" — no es template del pool, es ancla fija** |

**Total**: 5 diseñados (P1-P5) + ~18 templates del pool (P6-P23) + P24 ancla fija (boss) + P25 ancla fija (SZ) = **25 totales**.

**Siguiente iteración propuesta**: definir los **pisos 6–10** como continuación del arranque — 3 combate (para empujar el ritmo de combate después del descanso del P5) + 1 exploración + 1 evento. Eso deja los pisos 11-23 para ir completando el pool con variedad.

**Iteración posterior recomendada**: **pisos 20-24** (los 5 pisos del clímax del tier, incluyendo el umbral + el boss). Diseñar el cierre del tier antes que el medio asegura que el recorrido apunta al clímax correcto.

---

## Notas generales sobre los 5 pisos

1. **Ritmo del arranque**: tutorial (P1) → combate (P2) → exploración (P3) → evento (P4) → descanso (P5). Cada piso cambia de familia para evitar fatiga y para presentar las 5 primeras familias del juego de forma ordenada. El jugador cierra las primeras 2 horas sabiendo que el juego tiene variedad real.
2. **Retirados sembrados**: los 5 pisos tienen un Retirado posible (P1 el Ciervo, P2 el Grifo Cansado, P3 la Hermana Olvidada, P4 el Mensajero Perdido, P5 el Gato del Bardo). Primera impresión: "hay spoilers vivos por todos lados si sabés mirar".
3. **Sub-dungeons sembradas**: 2 de los 5 pisos tienen sub-dungeon opcional (P2 y P3) + 1 sub-dungeon obligatoria para quest principal (P4 para rescatar la hermana). El P5 no tiene sub-dungeon porque el claro es el contenido.
4. **Misiones emergentes**: ~10 quests seed totales en los 5 pisos. Ninguna es obligatoria para avanzar.
5. **Consecuencias del outpost**: P4 es el primer piso donde las decisiones del jugador cambian el outpost del P1 de forma permanente (el mercader, la hermana, el guardia). P5 siembra otra: el bardo puede llegar al outpost en sesiones futuras si completás la quest de la Flor de Medianoche.
6. **Lore del Tier V**: sembrado 2 veces en los primeros 5 pisos (altar del P1 con diario suelto, diario del peregrino en P3). El tercer hit fuerte de lore viene en el Diario del Rey del Trono Viscoso (P24), fuera del scope de este documento.
7. **NPC recurrente introducido**: el bardo del P5 es el primer NPC que puede aparecer en otros pisos random del tier como seed. Esto abre el patrón de "NPCs itinerantes que memoriza el jugador".
8. **El boss del Tier I vive en el P24**, no en estos 5 pisos. Los pisos 6-23 son el camino hacia él. El P24 es ancla fija (ver brief §6).

---

*Documento vivo. Actualizar cuando se validen los pisos en testing o cuando cambien las decisiones de tono.*
