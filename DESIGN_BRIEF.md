# Dungeon Party — Design Brief

**Documento**: Dirección creativa maestra
**Versión**: 1.0 — 2026-04-11
**Estado**: Vivo. Se actualiza cuando cambia la visión, no cuando cambian features.
**Relación con otros docs**:
- `GDD_DungeonParty.md` → el qué y el cómo técnico (mecánicas, stats, fórmulas).
- `game/docs/tower_biome_system.md` → catálogo completo de los 25 biomas.
- `game/docs/art/_art_canon.md` → paleta, poly budget, atmósfera visual, refs (v2.0 unified 2026-05-18).
- **Este brief** → la **identidad**, el tono, la **gramática de diseño** y la arquitectura macro de la torre.

Cuando el GDD y este brief entren en conflicto, **este brief gana en cuestiones de tono y dirección**; el GDD gana en cuestiones de mecánica.

---

## 0. Cómo usar este brief

Este documento NO es una lista de features. Es una brújula. Sirve para tres cosas:

1. **Decidir qué construir** cuando hay múltiples caminos posibles.
2. **Rechazar ideas** que no encajan con la identidad, aunque sean buenas en abstracto.
3. **Briefear a cualquier IA o colaborador** para que no desvíe el tono.

Si algo que estás por construir no puede justificarse con una frase de este brief, probablemente no pertenece al juego **todavía**.

---

## 1. Qué es Dungeon Party (en una página)

Dungeon Party es un **dungeon crawler cooperativo en primera persona** para 1–6 jugadores. El núcleo del género es Dark and Darker + Diablo + Deep Rock Galactic, pero el **alma** es otra cosa.

El alma es esta: **un viaje melancólico, bello y socialmente vivo a través de una torre de 100 pisos que no son habitaciones sino mundos abiertos**. La cooperación es el pilar — no porque el juego lo obligue, sino porque el juego lo **recompensa emocionalmente**. Se pelea, se saquea y se sube de nivel, sí, pero también se descansa, se hacen fogatas, se juzga en broma a un amigo en la Plaza de los Juicios, se pesca, se monta un carro tirado por cabras y se muere rodeado de enemigos que celebran.

La torre se **desciende emocionalmente** mientras se **asciende físicamente**: los primeros pisos son civilizados, con caminos, guardias y mercaderes; a partir del 50 todo se vuelve salvaje, solitario y luego extraño; los últimos pisos son casi un sueño. Cada tramo cambia el estado de ánimo del juego, no solo el skin del bioma.

El jugador no debería recordar "el piso 17" — debería recordar **"el piso del lago ciego"**, **"el piso donde encontramos al mercader emboscado"**, **"el piso donde la campana atraía a los muertos"**. Los pisos memorables no son los que tienen más contenido; son los que tienen **una imagen fuerte, una regla clara y una emoción dominante**.

**Tres frases para defender el juego ante cualquiera**:
- "Es un dungeon crawler coop donde cada piso es un mundo abierto con su propio estado de ánimo."
- "La cooperación no es un modo, es el motor emocional: hasta el sistema de loot premia a los 4 roles."
- "Tiene la melancolía de Frieren, el loot de Diablo 2, el humor absurdo de Among Us y los silencios de Made in Abyss."

---

## 2. Pilares de identidad (5)

Cada decisión de diseño debe poder trazarse a al menos uno de estos pilares. Si una feature no cumple ninguno, no pertenece al juego.

1. **La coordinación es el motor emocional, no solo mecánico.** La dificultad es fija. El loot premia a quien participó en cualquier rol (contribución ponderada). Las habilidades tienen sinergias reales entre clases. **Jugar solo siempre es posible si el jugador se lo gana con farmeo** — nunca hay contenido bloqueado por composición de grupo. Jugar juntos hace todo más fácil, más memorable y más divertido, pero nunca es requisito para cerrar la torre. La cooperación es motor, no gate.

2. **La torre es un viaje, no un grinder.** 100 pisos no son 100 mazmorras — son un ascenso con curva emocional: curiosidad (1–25), melancolía (26–50), supervivencia (51–75), extrañeza (76–95), mito (96–100). Cada tramo se siente diferente en ánimo, no solo en skin.

3. **Cada piso es un mundo completo a la escala que pide su emoción, no una sala.** La escala NO es fija. El Piso 1 (Pradera) es 600×600m porque la apertura y el asombro son su alma. El Piso 2 (Bosque) es ~200×200m porque la opresión y el laberinto son el suyo. Un claro de descanso puede ser 100×100m porque la intimidad es el punto. Un salón de trono puede ser 80×80m cerrado. Un paso entre colinas puede ser 400×200m lineal. La regla no es "grande" — es **"completo, coherente y a la medida de la emoción dominante"**.

4. **La belleza y el descanso son contenido, no relleno.** Pisos pacíficos, pesca, fogatas, carretas de mercader, ciervos blancos — todo esto es tan importante como el combate. La alternancia entre tensión y calma es lo que hace que el peligro pegue más.

5. **La rareza es una especia, no una base.** Los pisos absurdos, incómodos o "inútiles" existen y son celebrados — pero como **acentos**, no como estructura. Un juego 100% raro pierde la fuerza de la rareza.

---

## 3. Referencias (el ADN visual y emocional)

### Referencia central
**Frieren: Beyond Journey's End** — es la piedra angular.
- Aventura **post-épica**: el mundo ya fue salvado, quedan ruinas cargadas de historia.
- Demonios **únicos** y diseñados, nunca clichés rojos con cuernos.
- Paleta **cálida pastel**, luz dorada suave, emisión contenida.
- Props con personalidad narrativa: una silla olvidada cuenta algo.
- La "bella tristeza" es el tono dominante.

### Referencias de soporte
| Fuente | Qué tomamos |
|---|---|
| **Made in Abyss** | Descenso emocional, silencios, peligros que no se ven venir, belleza hostil. |
| **Kimetsu no Yaiba** (Demon Slayer) | Atmósferas por tramo, contrastes de luz, **y especialmente diseño de color + animación de habilidades** (los "respirar agua/fuego/trueno" son la referencia maestra para el look de las habilidades de clase). |
| **Jujutsu Kaisen** | Animación y estilo de los jutsus cantados — timing dramático, cámara que se inclina en el momento del cast, trail visual del hechizo. |
| **One Piece** | Estilo cartoon-épico de las habilidades con nombre, fuerza del impacto visible, poses de cast. |
| **Sword Art Online (Aincrad)** | Pisos como mundos completos con identidad propia. |
| **DanMachi** | Pisos como ecosistemas vivos, labyrinths con personalidad (Piso 3 brumoso, Labyrinth del Gran Árbol). |
| **Shield Hero** | Compañeros, pets, monturas con progresión, evolución de equipo. |
| **Metin 2** | Loot al mundo con despawn de 3–5 min, mundo abierto con campos y ciudades. |
| **Diablo 2** | Grilla 12×7, raridades (pero **sin Épico**), stash per-account, sockets con riesgo. |
| **Path of Exile** | Mantener la progresión fresca vía variación controlada. |
| **Dark and Darker** | Tensión coop, fuego amigo, audio que importa. |
| **Monster Hunter** | Cooperación ponderada por contribución. |
| **Deep Rock Galactic** | Hermandad coop + humor + rituales de celebración. |
| **Lethal Company** | Cristal Cantor = boombox diegético adaptado a fantasía. |
| **Among Us** | Sistema de Juicios medieval cómico, sin pérdida real. |
| **Overlord** | Torre con pisos temáticos + Floor Guardians con personalidad y lore propio. Mezcla de dark fantasy con humor absurdo (Ainz pretendiendo ser sabio). Estética undead/magia oscura para Necromancer y Tier III-IV. NPCs con jerarquía y voz propia (no menús con cara). |
| **Skyrim / BOTW** | Fauna ambiental pasiva (mariposas, pájaros, ciervos) como worldbuilding barato y potente. |
| **Terraria, Spelunky** | Biomas temáticos con identidad mecánica propia. |

### Paleta y mood maestros
- Cálida, pastel, emisión suave.
- **Nunca** grimdark gore. Si hay terror, es terror de **extrañeza y pérdida**, no de sangre y tripas.
- Luces doradas, verdes musgo, azules fríos, rojos óxido. Casi nada saturado al 100%.
- El sol es un diamante emisivo dentro del techo de caverna — la torre entera es un **interior**, no un exterior. Esto es **canon**.

### Estilo visual de habilidades (canon)

Las habilidades de clase deben verse y **sentirse** como habilidades de anime shonen moderno. Es el contraste intencional con el mundo: el mundo es Frieren (contemplativo, cálido, melancólico), pero **cuando un jugador lanza una habilidad grande, la cámara y el efecto son anime de pelea**.

Referencias ordenadas de mayor a menor autoridad para el look de habilidades:

1. **Kimetsu no Yaiba — PRIMARIA**. Los "respirar agua", "respirar fuego", "respirar trueno" son el norte. Color saturado solo durante el cast, trail del arma con forma distintiva por estilo, cámara que sigue el arco del golpe, momento de impacto con freeze-frame muy corto. Cada rama de clase es una "forma de respiración" visualmente.
2. **Jujutsu Kaisen**. Timing dramático del cast, cámara inclinada al activarse, nombre de la habilidad visible brevemente, trails gruesos con negro al borde. Útil especialmente para Mago y Necromancer.
3. **One Piece**. Estilo cartoon-épico, pose de cast, impacto exagerado visualmente, nombres propios para habilidades grandes. Útil para Warrior (Berserker rama) y Archer (Artillero rama).

**Regla**: las habilidades **pequeñas** (ataque base, click) son funcionales, sin drama. Las habilidades **medias** (mantener, cooldown corto) tienen trail y color pero sin pausa. Las habilidades **grandes** (ultimate, cooldown largo) se llevan la cámara: nombre visible, pose, impacto, contraste de color sobre el mundo pastel.

**Por qué el contraste funciona**: el juego se siente contemplativo el 90% del tiempo, pero cuando un jugador ejecuta una sinergia perfecta o lanza su ultimate, la cámara cambia de Frieren a Demon Slayer. Esto hace que las habilidades grandes se sientan **importantes** sin que el juego entero parezca ruidoso.

---

## 4. Gramática de diseño de pisos (las 7 preguntas)

Un piso no está diseñado hasta que responde estas 7 preguntas. Si falta una, todavía está solo "ambientado".

1. **Función** — ¿Qué hace este piso en el ritmo del juego? (avanzar, descansar, sorprender, preparar, cerrar)
2. **Emoción dominante** — ¿Qué debe sentir el jugador a los primeros 30 segundos? (tensión, calma, asombro, incomodidad, codicia, melancolía)
3. **Landmark** — ¿Cuál es la imagen que el jugador recordará y compartirá con un amigo? (el cristal Vía Láctea, el lago ciego, la estatua que mira distinto al volver)
4. **Lectura espacial** — ¿Cómo se navega? (abierto, laberíntico, vertical, circular, fragmentado, lineal con desvíos)
5. **Mecánica distintiva** — ¿Qué regla propia introduce? (niebla, ecos, verticalidad, campana que atrae, luz limitada) **Máximo una por piso**.
6. **Recompensa** — ¿Qué ofrece además de loot? (shortcut, información, NPC, buff, historia, evento único)
7. **Rol en el tier** — ¿Abre, sostiene, rompe o cierra el tono del tramo al que pertenece?

**Regla de oro**: un piso bueno se resume en **una frase**. Si no podés resumirlo, todavía no está diseñado.

---

## 5. Tipos de piso (las 6 familias)

No diseñamos pisos sueltos — diseñamos instancias de familias. Cada familia tiene un propósito claro. La identidad del bioma es la ropa; la familia es el esqueleto.

| Familia | Función | Emoción típica | Ejemplo |
|---|---|---|---|
| **COMBATE** | Avance principal, presión, loot | Tensión, acción, coordinación | Pradera con campamento bandido, cuevas con slimes |
| **EXPLORACIÓN** | Rutas, secretos, POIs, codicia | Curiosidad, asombro | Ruinas con cofres ocultos, bosque con senderos múltiples |
| **DESCANSO** | Bajar tensión, socializar, comerciar | Alivio, apego, calidez | Safe zone, fogata, pesca, taverna itinerante |
| **EVENTO** | Romper rutina con reglas especiales | Sorpresa, historia | Caravana bajo ataque, fiesta del pueblo, noche de estrellas fugaces |
| **ANOMALÍA** | Piso raro, incómodo o "inútil" | Misterio, recuerdo fuerte | Piso donde solo hay viento y cabras, aldea vacía preparada para fiesta que nunca ocurrió |
| **UMBRAL / BOSS** | Clímax de tramo, cambio de tono | Anticipación, resolución | Antes y después del boss, safe zones 25/50 |

### Subtipos de Descanso (importante — el descanso es contenido)

- **Cálido**: taverna, fogata, música, comida, NPCs. Apego y comunidad.
- **Triste**: ruina silenciosa, santuario, lago, memorial. Melancolía, worldbuilding.
- **Lúdico**: minijuego, pesca, concurso, animales, ritual festivo. Humor y memoria.

**Cada piso de descanso debe decir algo del mundo.** Un descanso sin voz es un menú con flores.

### Subtipos de Anomalía

- **Bella pero sin sentido**: viento, cabras, vista inmensa. No hace nada, pero se recuerda.
- **Incómoda**: reglas rotas, luz que no obedece, gestos humanos en criaturas no humanas.
- **Cálida pero rara**: pueblo vacío con señales de vida reciente, fiesta abandonada que parece reciente.

El terror, si aparece, vive en esta familia — y es terror **de extrañeza y pérdida**, nunca gore.

---

## 6. Arquitectura de los 100 pisos

### Principios arquitectónicos

1. **Anclas fijas y pool procedural**. La torre tiene anclas fijas en posiciones clave y pool procedural entre ellas. Las anclas son: **P1** (tutorial), **bosses de tier** (P24, P49, P74, P95 — fijos al final de cada tier), **safe zones 25 y 50**, y **P100** (boss final). Todo lo demás vive en pools del tier y se reordena por seed en cada run.
2. **El Piso 1 es tutorial zone**, no safe zone. Tiene outpost fortificado con servicios básicos (comerciante, herrero básico, stash inicial) **pero el peligro está al otro lado de la puerta**. El jugador aprende acá: combate, loot, muerte, revive, inventario, equipamiento. Es la primera aventura, no el refugio.
3. **Las safe zones 25 y 50 son canon**. Son pisos de DESCANSO **reales** — sin peligro adentro, con mercaderes, herrería avanzada, stash grande, Plaza de los Juicios, NPCs recurrentes. La diferencia con el Piso 1: en la safe zone no se pelea. En el Piso 1 sí, apenas salís del outpost.
4. **Los bosses de tier son anclas fijas al final del tramo**, no templates del pool. Tier I boss = P24 (Trono Viscoso, justo antes de la SZ del P25). Tier II boss = P49. Tier III boss = P74. Tier IV boss = P95. Esto respeta la generación procedural: entre anclas hay 22-24 pisos random del pool del tier. Solo las anclas son fijas.
5. **Cada run reconfigura el orden del pool entre anclas**. La identidad del tier se mantiene; el orden de los pisos random cambia. Así el jugador repite con variedad y las anclas son puntos de referencia constantes.
6. **Reglas de adyacencia**: nunca 2 anomalías consecutivas, nunca 3 combates sin un descanso o evento, un umbral siempre precede a un boss, un evento puede aparecer en cualquier lado.
7. **El piso 1 y el piso 100 se reflejan**. El 100 es la pradera marchita + el santuario del umbral. Callback visual intencional.

### Distribución macro (proporciones por tier)

| Tier | Rango | Pisos | Filosofía | Civilización | Emoción dominante |
|---|---|---|---|---|---|
| **I — Ascenso Civilizado** | 1–25 | 25 | La casa del jugador. Caminos, guardias, mercaderes. Primera aventura. | Alta (pre-50) | Curiosidad, asombro, calidez |
| **II — Frontera del Mundo** | 26–50 | 25 | La civilización se adelgaza. Pueblos olvidados. Aparece la melancolía. | Media (pre-50) | Asombro, melancolía, respeto |
| **III — Wilderness** | 51–75 | 25 | No hay caminos, no hay NPCs. El mundo existe sin la gente. | Nula (post-50) | Hostilidad, aislamiento, belleza dura |
| **IV — Anomalía** | 76–95 | 20 | Las reglas se rompen. Belleza torcida. Extrañeza. | Nula o distorsionada | Extrañeza, incomodidad, memoria fallida |
| **V — Mito** | 96–100 | 5 | Cierre. Callback al Piso 1. Descenso final. | Cero | Trascendencia, melancolía plena |

### Distribución por familia dentro de cada tier

Estos porcentajes son objetivos de diseño, no camisas de fuerza. El pool se balancea en cada run respetándolos.

| Familia | Tier I | Tier II | Tier III | Tier IV | Tier V |
|---|---|---|---|---|---|
| **Combate** | 14 | 13 | 17 | 9 | 1 |
| **Exploración** | 3 | 3 | 3 | 2 | 0 |
| **Descanso** | 3 (+SZ P25) | 3 (+SZ P50) | 1 | 2 | 1 |
| **Evento** | 3 | 3 | 2 | 2 | 0 |
| **Anomalía** | 1 | 1 | 1 | 4 | 1 |
| **Umbral** | 0 | 1 | 0 | 0 | 1 |
| **Boss** | 1 (P25\*) | 1 (P50\*) | 1 | 1 | 1 (P100) |
| **Total** | **25** | **25** | **25** | **20** | **5** |

\* Los bosses del tier I y II NO son los de piso 25 y 50 — las safe zones son de descanso. Los bosses son **menores** (tier bosses) distribuidos en el pool del tramo, no fijos.

### Tier I — Ascenso Civilizado (Pisos 1–25)

**Filosofía**: El jugador acaba de entrar a la torre. Todo es nuevo. El mundo es acogedor aunque peligroso. Hay guardias, caminos, carretas, mercaderes, campesinos, fauna pacífica, eventos divertidos. La muerte duele pero se siente como "mala suerte", no como castigo cósmico.

**Piso 1 — Pradera Interior (FIJO — Tutorial Zone)**
- Bioma: pradera con techo de caverna, diamante emisivo, cristales Vía Láctea.
- Mundo vivo: puesto fortificado, NPCs civiles, carreta de mercader con 5 estados, fauna pacífica.
- **Rol especial**: el Piso 1 es **tutorial zone**, no safe zone. El outpost ofrece servicios básicos (comercio, herrería inicial, stash pequeño, quests iniciales) pero apenas el jugador sale del perímetro fortificado empieza el peligro real. Acá el jugador aprende todo: cómo se pelea, cómo se cura, cómo se lootea, qué es el downed, cómo revivir, cómo equipar, cómo morir. El outpost sirve de red de seguridad; la pradera enseña.
- Boss del tramo: **Trono Viscoso** (Rey Slime poseyendo el salón del trono devorado) — **ancla fija en P24**, justo antes de la safe zone del P25. NO es el boss del Piso 1 (en el modelo viejo de 5 pisos lo era; en el modelo nuevo de 100 pisos, el Tier I entero es "el antiguo Piso 1", y el boss es su clímax al final del tramo).

**Biomas del pool del tier I**: Pradera Interior (P1 fijo + variantes), Bosque Denso ligero, Sabana Seca, Ruinas Antiguas (superficiales), Pantano borde.

**Landmarks memorables del tier I** (ideas sembradas):
- El puesto fortificado con el capitán y el veterinario de pets.
- La carreta del mercader con la rueda rota y el bandido.
- El lago con pesca y ciervos blancos.
- El altar olvidado con el diario del último peregrino.
- El árbol gigante con el nido y la ardilla ladrona.

**Safe Zone Piso 25 — "Último Puesto"**
- Herrería básica (reparación común + raro).
- Stash expandido.
- Comercio variado.
- Plaza de los Juicios (primer sitio donde funciona).
- NPCs recurrentes con quests pequeñas.

### Tier II — Frontera del Mundo (Pisos 26–50)

**Filosofía**: La civilización empieza a desaparecer. Aldeas olvidadas, peregrinos solitarios, santuarios abandonados. Aquí entra la melancolía por primera vez. El jugador empieza a sentir que "estamos lejos de casa".

**Biomas del pool**: Tundra Congelada, Cavernas de Cristal, Ruinas Antiguas profundas, Bosque de Hongos Gigantes, Desierto Abrasador (borde), Bosque Denso profundo.

**Landmarks posibles**:
- Una aldea congelada con señales de vida reciente que no deberían estar ahí.
- Un bosque de hongos bioluminiscentes donde el sonido se comporta raro.
- Un santuario cubierto de polvo donde solo queda un NPC esperando a alguien que no viene.
- Ruinas con una biblioteca donde los libros se reordenan solos cuando nadie mira.
- Una catedral vegetal donde la luz importa más que el daño.

**Safe Zone Piso 50 — "Última Luz"**
- Herrería avanzada (reparación de únicos, enhancement +7 en adelante).
- Stash grande, última vez.
- Mercader viajero que **solo aparece acá**.
- Santuario con un NPC que te cuenta qué hay más adelante — nunca directamente, siempre en metáforas.
- Plaza de los Juicios con castigos más absurdos.
- **Punto de despedida emocional**: el juego deja claro que lo que sigue es distinto.

### Tier III — Wilderness (Pisos 51–75)

**Filosofía**: No hay caminos. No hay NPCs humanos. El mundo existe sin la gente. El jugador está solo con su equipo, y el equipo es todo lo que importa.

**Biomas del pool**: Volcán Activo, Pantano Putrefacto profundo, Selva Tropical, Ciudad Abandonada, Catacumbas/Necrópolis, Forja Infernal, Océano Sumergido (borde), Desierto Abrasador profundo, **Salar de los Espejos** (nuevo — ver abajo).

**Bioma nuevo: Salar de los Espejos**
Planicie infinita de sal blanca con una lámina delgada de agua encima. El agua refleja perfectamente el techo de la torre — el diamante emisivo del Piso 1 se ve como un segundo sol abajo, y el jugador camina **sobre su propio reflejo**. Espejismo perfecto, sin horizonte real. Inspiración: Salar de Uyuni (Bolivia). Hostilidad: exposición total (no hay cobertura), luz cegadora, enemigos que aparecen desde lejos por el reflejo. Belleza que duele. Encaja con el Tier III por el aislamiento, la exposición y la belleza dura sin civilización. Landmark de tier.

**Reglas especiales del tier III**:
- **No hay caminos**: el jugador explora con brújula y memoria.
- **Los descansos existen pero no son humanos**: un lago ciego con peces pálidos, un jardín protegido por una criatura pacífica que no se puede matar, una cabra rara que comparte su cueva.
- **El loot cambia de sabor**: menos comercio humano, más scavenge. Los "items guardados" son los que llevás del 50.
- **Mounts y carros no entran** a biomas interiores (cavernas, catacumbas). Sí a volcán externo, selva, ciudad.

**Landmarks posibles**:
- Una ciudad abandonada con fiestas visibles en las ventanas que se apagan al acercarse.
- Una forja infernal donde todavía hay un golem trabajando, sin saber que no hay nadie.
- Un pantano donde las ranas cantan en coro humano.
- Un volcán con una criatura enorme dormida — nunca hay que despertarla.

### Tier IV — Anomalía (Pisos 76–95)

**Filosofía**: La realidad se rompe. Las reglas del juego cambian sin avisar. La belleza se vuelve hostil. La extrañeza es el tono dominante.

**Biomas del pool**: Jardín Corrompido, Templo del Reloj, Mundo Espejo, Dimensión Astral, Laboratorio Arcano, Playa de Ceniza, Abismo Abismal (borde).

**Reglas especiales del tier IV**:
- Cada piso introduce **una regla rota**: gravedad invertida parcial, tiempo que se revierte, enemigos que reflejan daño, objetos que desaparecen al mirarlos directo.
- Los combates son **menos frecuentes pero más tensos**.
- Los descansos son **casi oníricos**: un jardín donde nada crece pero todo huele a flores, una playa de ceniza con música que solo uno del grupo puede oír.
- Aquí vive la mayoría de las **anomalías puras** — pisos sin peligro pero imposibles de explicar.

**Anomalías tipo**:
- El piso del viento: solo hay viento, cabras y vista. No se pelea. No hay loot. Hay un logro oculto si nadie ataca nada.
- El piso de la campana: una campana al centro. Tocarla invoca enemigos, pero también abre un cofre único.
- El piso del reflejo: todo lo que el grupo hace se repite 10 segundos después en espejos. Los enemigos son los reflejos.
- El piso de la fiesta: un pueblo preparado para una celebración. No hay nadie. La música sigue sonando.

### Tier V — Mito (Pisos 96–100)

**Filosofía**: Cierre. Callback al Piso 1. Descenso final. Cinco pisos **fijos**, escritos a mano, sin pool.

| Piso | Nombre (working) | Función | Nota |
|---|---|---|---|
| **96** | **Pradera Marchita** | Callback | La pradera del Piso 1, corrompida. El puesto fortificado en ruinas, los NPCs ausentes, el diamante del techo apagado. La carreta del mercader está, quemada. |
| **97** | **Abismo Abismal** | Transición | Caída visual, no literal. Descenso por capas de luz. Sin enemigos, solo silencio. |
| **98** | **Umbral Inicial** | Descanso raro | Un hall vacío con sillas y velas. Nadie. Solo los jugadores. Una última conversación de party antes del final. |
| **99** | **Archipiélago Celeste** | Exploración mágica | Islas flotantes conectadas por puentes de liana y raíces colgantes que se mecen. Cascadas cayendo al vacío bajo los pies. Luz dorada flotando en el aire, motas brillantes, viento suave. Magia pura visible — no hostil, bella. Combate ligero opcional con criaturas espirituales pacíficas a menos que se las provoque. **Atravesable solo por un jugador muy farmeado**. Navegación y verticalidad son el desafío, no el combate. |
| **100** | **Santuario del Umbral** | Boss final | La pelea final. Arena épica. Callback visual a la Pradera pero invertido. Completable en solo con gear endgame; la cooperación facilita pero nunca es requisito. |

---

## 7. Curva emocional del ascenso (la partitura)

Esta es la "línea melódica" del juego. Sirve para saber qué emoción debería dominar cada tramo.

```
Pisos 1–10     ▁▂▃▁▂▃     descubrimiento, primera sorpresa, primer amigo
Pisos 11–25    ▃▄▅▃▄▆     aventura establecida, primeros descansos buenos, P25 alivio
Pisos 26–40    ▅▄▃▄▅▄     mundo más raro, melancolía entra, ruinas
Pisos 41–50    ▆▅▄▅▇     frontera, despedida emocional, P50 última luz
Pisos 51–60    ▂▃▄▅      soledad, readaptación, wilderness
Pisos 61–75    ▄▅▆▄▅     supervivencia establecida, belleza dura
Pisos 76–85    ▃▆▂▇▃     anomalía entra, ritmo roto a propósito
Pisos 86–95    ▆▃▇▂▆     belleza torcida, pisos memorables
Pisos 96–100   ▁▂▇▁█    cierre, silencio, clímax, silencio final
```

**Interpretación**: los picos son momentos fuertes, los valles son respiros. Ningún tramo es constante. Un tramo 100% combate aburre; un tramo 100% calma se vuelve indistinto. La alternancia es el contenido.

---

## 8. Sistemas que definen el ADN del juego

Estas no son features — son **los sistemas que hacen que Dungeon Party sea Dungeon Party y no otro dungeon crawler**. Tocarlos con mucho cuidado.

### 8.1 Contribución ponderada del loot (pilar mecánico)
El sistema de rareza del loot en grupo usa **contribución ponderada** (daño × 1.0 + tankeado × 0.2 + curación × 0.15). Es el único ARPG mainstream que lo hace así. Premia a los 4 roles. Sin esto, los healers y tanks no tienen razón de existir en el juego, y el pilar "coordinación es poder" se cae.

### 8.2 Celebración de enemigos al downed
Cuando un jugador cae, **los enemigos del área celebran 15 segundos antes de seguir atacando**. Cada enemigo celebra distinto (slime bailando, lobo aullando, bandido con taunt obsceno). Esto:
- Da ventana natural de revive.
- Reduce frustración (no hay chain-kill).
- Da personalidad a cada enemigo.
- Es **único en el género**. Nadie lo hace.

### 8.3 Carro cooperativo tirado por cabras
4 jugadores en una carreta de cabras en zonas abiertas: 1 conduce, los demás pelean, curan o hacen escudos mágicos. Es la **"cinemática viviente"** del juego — contenido que nadie en el género coop tiene. Exclusivo de tramos abiertos (Tiers I–III externos).

### 8.4 Plaza de los Juicios (Among Us medieval)
Sistema de juicios cómicos entre jugadores. Castigos cosméticos (guillotina Monty Python, cepo con tomates, miniaturización, piedra de la vergüenza). Sin pérdida real. Opt-out en settings. Es **humor diegético**, no minijuego pegado con cinta.

### 8.5 Cristal Cantor
Boombox diegético medieval. Items mágicos que reproducen música grabada por bardos. Tipos: del Héroe, del Descanso, del Baile, Prohibido, del Amor. Cada uno con efecto ambiental distinto. Referencia: Lethal Company adaptado a fantasía.

### 8.6 Stash per-account + inventario per-character
Loop extracción: **Prepare → Risk → Return → Bank → Repeat**. El stash está en safe zones (Piso 1 outpost, 25, 50). El inventario muere con el personaje. Esto crea tensión real sin ser frustrante — siempre podés guardar antes del run.

### 8.7 Fauna ambiental (mariposas, pájaros, ardillas, peces)
No pelean, no dropean loot, no colliden. **Son decorativos pero obligatorios**. Sin esto, el mundo se siente muerto. Skyrim y BOTW enseñaron esta lección.

### 8.8 Luz como recurso
Antorchas, linternas, orbes arcanos, hongos bioluminiscentes. Tecla F para quick-swap. Biomas con zonas oscuras donde uno del grupo **tiene que llevar luz** mientras otro pelea. Coordinación que no es DPS.

### 8.9 Pausa que no pausa
El menú de pausa solo libera el mouse. **No congela el juego**, porque es coop online. Esto es canon y **no se discute** — fue validado por el diseño del juego entero.

### 8.10 Los Retirados (spoiler vivo del futuro)
En algunos pisos aparecen, muy ocasionalmente, **criaturas de tiers futuros en estado degradado** — viejos, heridos, olvidados, perdidos. Un demonio del Tier IV que vagabundea por un bosque del Tier I, cansado y sin voluntad de pelear. Un golem del Tier III durmiendo en una ruina del Tier II. Una criatura astral del Tier IV atrapada en un altar del Tier I, parpadeando como si no entendiera dónde está.

**Reglas**:
- Son **mucho más débiles** que sus versiones del tier original — pelean al nivel del piso donde aparecen, no al suyo.
- Son **encuentros raros**, no frecuentes. Un jugador puede pasar 20 runs sin ver a uno.
- Drop: un item cosmético único, un fragmento de lore, o simplemente una imagen memorable.
- Algunos no atacan al jugador a menos que se los ataque primero — solo miran, se alejan, desaparecen.
- Cada uno tiene un **nombre** y una **frase de diario** en el codex (worldbuilding).

**Why**: Da un spoiler suave de lo que viene más arriba sin romper la sorpresa. Refuerza la idea de que la torre es **vieja**, que otras cosas pasaron antes del jugador, que el mundo no gira alrededor de él. Referencia: los demonios ancianos de Frieren.

**How to apply**: Cada tier tiene 3–5 "Retirados" catalogados. Aparecen en pisos aleatorios del tier inferior con baja probabilidad. Cuando un jugador los encuentra, el codex los registra. Coleccionar los Retirados = logro + título.

### 8.11 Sub-dungeons (mazmorras dentro de pisos)
Un piso abierto (600×600m) puede contener la **entrada a una sub-dungeon**: una mazmorra más cerrada y corta, con sus propias reglas, un minijefe, y un tesoro especial. **Opcional siempre** — el jugador puede ignorarla y seguir al siguiente piso.

**Ejemplos**:
- **Piso de hielo**: entrada a una **cueva de cristal preciosa** con ecos que atraen enemigos, un minijefe guardián, y un cofre único con un item de aire frío.
- **Piso de pradera (variante)**: una madriguera de bandidos con un líder local, prisioneros y un mapa parcial del piso.
- **Piso de bosque**: árbol hueco con cámara secreta, telarañas gigantes, minijefe araña.
- **Piso de ruinas**: cámara subterránea con trampas y un altar activo.

**Reglas de diseño**:
- Una sub-dungeon tiene **máximo 3–5 salas** y un boss menor. No son pisos completos — son "cápsulas" opcionales.
- Su identidad mecánica debe ser **distinta** del piso que la contiene (si el piso es abierto, la sub-dungeon es cerrada; si el piso es de día, la sub-dungeon es oscura).
- Siempre dan una **recompensa exclusiva**: item, lore, shortcut, o acceso a contenido que no existe en el piso abierto.
- La entrada no está siempre visible — puede estar señalada por una tumba, una grieta, una antorcha extraña, un cadáver junto a una puerta.

**Why**: Extiende la vida de cada piso sin inflar el tamaño del mapa. Premia la exploración real. Permite meter terror contenido o mecánicas específicas sin obligar a todo el piso a sostenerlas.

### 8.15 Sistema de masa (weight)
Cada entidad del juego (jugador, enemigo, NPC, invocación) tiene un valor `mass` que afecta cómo responde a fuerzas físicas (knockback, viento, empujones, cargas). No es inventario-weight — es masa física del cuerpo.

**Impacto en el juego**:
- **Knockback**: `push = force / mass`. Slimes (0.5) salen volando, golems (15.0) apenas se mueven.
- **Habilidades de viento (Mago Elementalista)**: `wind_power / target.mass` determina si empuja o no. Un nivel 1 empuja ratas; un nivel 15 empuja todo menos bosses. El jugador **ve** que su viento no alcanza para mover al golem → entiende que necesita subir de nivel.
- **Masa de jugador por clase**: Warrior (5.0) es el más pesado, Danzante de Sombras (2.0) el más liviano. Esto afecta cómo los empujan los enemigos, el viento ambiental, y las trampas de presión.
- **Trampas y puzzles ambientales**: baldosas de presión, puentes frágiles, plataformas de peso (ver §8.16).

**Regla**: la masa nunca bloquea contenido — solo cambia cómo se interactúa con él. Un jugador liviano puede cruzar un puente frágil que un pesado rompería, pero el pesado puede activar una presión que el liviano no.

### 8.16 Cautela visual — el mundo avisa, vos elegís si escuchás

El juego **nunca** muestra tooltips de peligro ambiental. En su lugar, el mundo **habla con imágenes**. Si el jugador presta atención, evita el problema. Si no presta atención, activa una consecuencia que se convierte en contenido jugable (quest de reparación, desvío, combate emergente).

**Principio**: **leer el mundo es una habilidad del jugador real**, no del personaje. No hay "Percepción +5" que muestre peligros. Hay un cartel de madera con dibujos, y el jugador humano decide si lo mira o lo ignora.

**Ejemplo flagship: el puente frágil**

Un puente de madera viejo cruza un barranco dentro de un bioma cerrado (caverna, ruinas, bosque denso). Antes del puente hay un **cartel de madera con 3 dibujos**:
1. Una persona sola ANTES del puente (parada, esperando)
2. Una persona sola CRUZANDO el puente (en el medio)
3. Una persona sola DESPUÉS del puente (del otro lado, segura)

No hay texto. No hay tooltip. Los dibujos dicen: **"uno a la vez"**.

**Mecánica**:
- El puente tiene un umbral de masa (`bridge_max_mass`). Ejemplo: 6.0.
- Solo cuenta la masa de **jugadores en el puente**. Monturas y pets NO cuentan (o cuentan un 20% de su masa). Items equipados no afectan.
- Un Warrior (5.0) cruza solo → OK (5.0 < 6.0).
- Un Mage (2.5) + un Archer (3.0) cruzan juntos → OK (5.5 < 6.0).
- Un Warrior (5.0) + un Healer (3.5) cruzan juntos → **se rompe** (8.5 > 6.0).
- Dos Warriors → **se rompe** (10.0 > 6.0).

**Cuando el puente se rompe**:
- Los jugadores en el puente caen al barranco (no mueren — caen a una zona inferior del mismo piso).
- El puente queda destruido para todo el grupo hasta que se repare.
- Se activa una **quest de reconstrucción**: recolectar materiales del mismo piso (madera de los árboles del bioma, cuerda de las telarañas, clavos del campamento más cercano).
- Mientras tanto, el grupo tiene que buscar una ruta alternativa (más larga, más peligrosa) o reparar.
- La reparación es **cooperativa**: uno sostiene, otro clava, otro vigila enemigos. Cada paso toma ~10s.

**Por qué funciona**:
- El cartel es **diegético** (dibujos en madera, no UI). Cumple la prohibición #5 ("no minijuegos pegados con cinta").
- La consecuencia es **contenido, no castigo**. El puente roto abre una quest, no un game over.
- Refuerza la **coordinación** (pilar 1): el grupo decide quién cruza primero basado en la masa de cada clase.
- Refuerza la **lectura del mundo**: el jugador que vio el cartel y avisó "ey, uno a la vez" se siente listo. El que no lo vio aprende para la próxima.
- Funciona especialmente bien en **biomas cerrados** (cavernas, catacumbas, ruinas) donde la inmersión depende del espacio apretado.

**Más ejemplos de cautela visual** (mismo principio, distintos hazards):

| Señal visual | Qué indica | Consecuencia si la ignorás |
|---|---|---|
| **Grietas en el suelo** con piedritas cayendo | El piso se va a derrumbar | Caés a una zona inferior (sub-dungeon forzada) |
| **Marcas de garras enormes** en la pared, cada vez más frescas | Depredador grande cerca | Emboscada de elite si seguís por ese pasillo |
| **Fogata abandonada todavía caliente** | Alguien (o algo) estuvo acá hace minutos | NPC herido cercano o emboscada de bandidos |
| **Marcas de agua** en las paredes a la altura de la cintura | La zona se inunda periódicamente | Inundación temporal que empuja al grupo (mass afecta cuánto te empuja el agua) |
| **Animales muertos** al pie de una planta | Planta carnívora dormida | La planta ataca si te acercás (ya canon del P2 bosque) |
| **Barras de metal dobladas** en una reja | Algo fuerte rompió la jaula | Criatura suelta por el piso, más peligrosa que los normales |
| **Espejos tapados con tela** en un pasillo | Los reflejos son peligrosos | Si destapás el espejo, invoca un reflejo tuyo como enemigo |
| **Marcas de tiza en el suelo** (X, flechas, círculos) | Otro aventurero pasó antes y dejó pistas | Siguen hasta un tesoro O hasta una trampa (ambiguo a propósito) |
| **Velas encendidas** en un santuario abandonado | Alguien las mantiene encendidas | NPC oculto observando, se revela si dejás una ofrenda |

**Regla de diseño**: cada bioma cerrado (caverna, ruinas, catacumba, forja) debe tener **al menos 2-3 señales de cautela visual** distribuidas. Biomas abiertos (pradera, sabana) las tienen menos (la visibilidad ya protege al jugador). La densidad de señales sube con el tier:
- Tier I: 1-2 señales por piso (tutorial suave)
- Tier II: 2-3 señales por piso
- Tier III: 3-5 señales por piso (wilderness, no hay NPCs que te avisen)
- Tier IV: 5+ señales por piso (anomalía, las señales a veces mienten)

### 8.14 Pool de bosses con narrativa compartida (post-MVP)
Cada tier arranca con **un solo boss** para el MVP (Tier I = Trono Viscoso). Post-lanzamiento, cada tier expande su pool hasta tener **3 bosses alternativos** que el seed elige por run. Pero no son 3 bosses sueltos: son **variantes narrativamente conectadas** — el juego usa el pool para contar una historia de degradación del mundo.

**Patrón**: cada trío de bosses del mismo tier representa **distintos momentos del mismo arco**. Una criatura con 3 cabezas en su plenitud → con 2 cabezas (herida) → con 1 cabeza (anciana y sola). O una familia real: rey → reina → príncipe. O un edificio entero: sano → saqueado → devorado.

**Ejemplos concretos para el Tier I** (post-MVP):
- **Trono Viscoso** (MVP canon) — rey tragado por slime, 1 corona visible, salón del trono devorado.
- **La Corte Disuelta** (variante) — 3 mini-bosses simultáneos en el mismo salón: Guardián (tanque), Bufón (mobilidad) y Escriba (mago). Son los cortesanos del rey, los mismos que aparecen como mini slimes del boss MVP. Arena: el mismo salón del trono pero iluminado distinto.
- **El Eco del Rey** (variante) — un boss puramente mágico: el slime ya no tiene rey adentro, solo un fantasma verde con forma de corona. Pelea a distancia, proyectiles de memoria, arena en una versión medio derruida del salón del trono. Es "el slime olvidó a su rey".

**Why**: tres runs seguidas contra el Trono Viscoso cansan. Tres runs contra variantes narrativas de la misma historia **construyen worldbuilding**. El jugador entiende que "algo pasa" en el salón del trono, que la torre es vieja, que las cosas cambian entre runs. Refuerza el pilar de "mundo que respira".

**How to apply**:
- Para el MVP: **1 boss por tier** (Trono Viscoso para Tier I).
- Primer content update post-lanzamiento: **+1 boss por tier** (total 2).
- Segundo update: **+1 boss por tier** (total 3 por tier = 15 bosses totales entre los 5 tiers del juego).
- Cada nuevo boss **debe estar narrativamente conectado** al anterior, no ser un boss random nuevo.
- El trío del Tier V (P100 final) se diseña distinto — es un boss único escrito a mano, no un pool.

### 8.13 Dirección MMORPG — diseño instance-safe
El juego apunta eventualmente a **MMORPG**. Todo el diseño de contenido — pisos, NPCs, eventos, sub-dungeons, misiones emergentes — debe asumir que **habrá múltiples grupos en la torre al mismo tiempo**. Esto tiene consecuencias concretas:

- **Ninguna feature asume un solo grupo**. Si un evento dinámico puede ejecutarse a la vez por 10 grupos distintos, el diseño debe soportar eso (instancing, cooldown por grupo, o contenido compartido con reglas claras).
- **Las UI nunca pausan el juego con `get_tree().paused = true`**. Nunca. Es coop/MMO. Esta es una prohibición absoluta (ver §9 #14).
- **Las safe zones 25 y 50 deben soportar docenas de jugadores al mismo tiempo** — son hub social. Los NPCs, mercaderes y Plaza de los Juicios deben escalar.
- **Las sub-dungeons son instanced por grupo** (cada party entra a su propia copia) mientras que los pisos abiertos pueden ser shared o instanced según el diseño de cada uno.
- **Los Retirados son únicos por grupo** (si dos grupos lo ven, cada uno lo ve en su instancia) — no es contenido compartido entre runs.
- **Las misiones emergentes son por grupo** — el NPC herido no se comparte entre 5 parties distintas.

**Why**: cambiar el modelo de "1 grupo" a "N grupos" después de tener el juego construido es mucho más caro que diseñar instance-safe desde el principio. Marcar deuda técnica con tag `MMO-DEBT` cuando algo no se pueda resolver instance-safe todavía.

### 8.12 Misiones emergentes (NPCs heridos y rescates)
Mientras el jugador explora un piso puede encontrarse con **NPCs en situaciones narrativas** que abren quests emergentes:

**Arquetipos**:
- **El herido en el camino**: un aventurero tirado contra un árbol. "Nos emboscaron. Se llevaron a mi hermana a una cueva al norte." → marca la sub-dungeon de rescate en el mapa.
- **El buhonero desesperado**: "Me robaron la carreta los bandidos. Si la recuperás te doy lo que quieras." → escolta o rescate.
- **El guardia que no vuelve**: el capitán del outpost pide que busquen a un guardia que salió de patrulla y no regresó → cadáver + item que lleva de vuelta al outpost → recompensa.
- **El niño perdido**: un chico llorando en el camino dice que sus papás se metieron a una cueva hace horas → sub-dungeon de rescate, tiempo opcional.
- **La vidente ciega**: una NPC que aparece en pisos raros, pide un item específico, da un rumor verdadero sobre un piso futuro.

**Reglas**:
- Son **emergentes**, no fijas. Aparecen por seed del piso, con probabilidad baja-media.
- **Opcionales siempre**. El jugador puede ignorarlas sin consecuencia.
- **Encadenan** con sub-dungeons, rescates, eventos o loot único.
- **Nunca bloquean** el avance al siguiente piso.
- Algunas tienen **consecuencias narrativas**: un NPC rescatado puede volver a aparecer en el outpost del Piso 1 con un item de agradecimiento.

**Why**: Worldbuilding que respira. Cada run se siente distinta no solo por el layout sino por las historias pequeñas que el jugador elige vivir o ignorar. Referencia: las misiones de Skyrim y Breath of the Wild que aparecen sin marcadores ni cinemáticas, solo con un NPC hablando.

---

## 9. Prohibiciones de diseño (qué NO hacer)

Estas son líneas rojas. Si una idea las cruza, se rechaza sin debate.

1. **No demonios cliché** (rojos con cuernos). Referencia Frieren: cada criatura es única, con ojos extraños y proporciones sutilmente mal.
2. **No escalar dificultad por número de jugadores**. La dificultad es fija. La coordinación es la variable.
3. **No pausa global**. Es coop online.
4. **No doble castigo**. La durabilidad no rompe items permanentemente. La tensión viene de perder loot al morir, no de acumulación de castigos.
5. **No minijuegos pegados con cinta**. Toda actividad social debe ser **diegética**: tiene NPC, lore, razón para existir en el mundo.
6. **No hardcodear layouts de piso**. Todo usa seeds + POIs procedurales. Nunca asumir "el árbol está en x, y".
7. **No loot igualitario random**. La contribución ponderada existe por una razón. Un Archer con 0 rareza no gana únicos sin importar cuánto pegue.
8. **No raridad Épica**. Solo Común (blanco), Raro (azul), Mágico (amarillo), Único (rojo vino). Esto es canon.
9. **No mundo muerto**. Cada piso debe tener al menos algo vivo visual aunque sea decorativo (mariposa, ave, pez, ardilla).
10. **No grimdark gore**. Si hay terror, es terror de extrañeza y pérdida, nunca de sangre y tripas.
11. **No romper el techo de caverna**. La torre es un interior gigantesco. El sol es un diamante. Esto es canon visual.
12. **No trailer prematuro**. Hasta que el juego se vea pulido, no se arma trailer. El marketing espera.
13. **No contenido bloqueado por composición de grupo**. El juego es cooperativo, no cooperativo-forzado. Un jugador dispuesto a farmear debe poder llegar al Piso 100 y cerrar la torre solo. La cooperación hace las cosas más fáciles, más memorables y más divertidas — **nunca posibles vs imposibles**. Puzzles, bosses y mecánicas de piso pueden premiar al grupo, pero nunca bloquear al solo.
14. **Nada pausa el juego. Jamás.** Ninguna UI, ninguna ventana, ningún menú usa `get_tree().paused = true`. Es coop/MMORPG — pausar un jugador detendría a los demás. Las ventanas solo liberan el mouse. Esto es absoluto y no se discute.

---

## 10. Principios de diseño de mapas (los 12)

Cuando diseñes un piso, consultá esta lista. Si tu piso viola 3 o más, reescribilo.

1. **Cada piso debe poder resumirse en una frase.** Si no podés, no está diseñado.
2. **Cada piso necesita una silueta mental** — un landmark que el jugador pueda dibujar después.
3. **Una sola mecánica dominante nueva por piso.** No apilar reglas.
4. **El piso debe prometer algo en los primeros 30–60 segundos.** Una imagen, una criatura, un sonido, una sospecha.
5. **Los pisos de descanso son contenido real**, no relleno. Cada uno dice algo del mundo.
6. **La rareza es especia, no base.** Máximo 1 anomalía cada 5–6 pisos en tiers I–III.
7. **La melancolía vale tanto como el peligro.** Un piso silencioso bien hecho pega más que 3 combates.
8. **Los pisos civilizados cuentan cómo vive la gente.** Los salvajes cuentan cómo sobrevive el mundo sin ella.
9. **El loot empuja exploración**, no solo cae del combate. Cofres escondidos, drops de fauna, eventos dinámicos.
10. **Los cambios de tier son cambios de civilización**, no de color. El tier II no es "el tier I pero gris".
11. **La cooperación debe cambiar la lectura del espacio**, no solo subir DPS. Uno lleva luz, otro pelea; uno abre, otro vigila.
12. **Un piso bueno no necesita ser enorme — necesita ser legible y deseable.** Piso 1 son 600×600m porque lo pide; un piso del tier V puede ser 100×100m si la intención lo pide.

### Elementos inter-piso (continuidad vertical de la torre)

La torre no es una colección de niveles sueltos — es un **lugar real con continuidad física**. Algunos elementos deben cruzar pisos para que el jugador sienta que está ascendiendo por un mismo edificio, no teletransportándose entre mundos desconectados.

**Ejemplos de elementos que pueden cruzar 2-3 pisos consecutivos:**
- **Cascada**: nace en un piso alto y cae al siguiente. El jugador la ve caer en el P8, y cuando sube al P9 encuentra el nacimiento. Crea un hilo visual reconocible.
- **Río subterráneo**: atraviesa 2-3 pisos con el mismo color de agua y la misma fauna acuática. Si pescaste en el P5, reconocés el mismo río en el P7.
- **Raíces gigantes**: un árbol monumental del P3 tiene raíces que perforan el suelo y aparecen como estructura en el P2. El jugador conecta ambos pisos mentalmente.
- **Veta de cristal emisivo**: una línea de cristales Vía Láctea que baja del techo y se ve en 3 pisos consecutivos con la misma curva. Da continuidad al "cielo interior" de la torre.
- **Grieta tectónica**: una fisura enorme que parte un piso y continúa en el siguiente con un bioma distinto asomándose del otro lado — hint visual del piso que viene.
- **Humo o niebla**: la niebla del pantano del P12 se cuela hacia el P11, creando un degradado ambiental. El jugador huele el pantano antes de llegar.
- **Sonido**: el rugido de un boss lejano, el agua de la cascada, o la música del bardo se escuchan ANTES de llegar al piso — bleeding de audio entre pisos.

**Reglas de diseño inter-piso:**
1. No todos los pisos comparten elementos. ~30% de los pisos del pool tienen al menos 1 conexión con un piso adyacente.
2. Las conexiones son **visuales y ambientales**, no mecánicas. El jugador no puede USAR la cascada para bajar al piso anterior (eso rompería el flujo de la torre). Solo la ve y la reconoce.
3. Las safe zones (P25, P50) pueden tener vistas a los pisos adyacentes — ventanas, balcones, miradores — como recompensa panorámica.
4. La conexión inter-piso más fuerte es la del **Tier V**: el P96 (Pradera Marchita) tiene elementos visuales rotos del P1 (Pradera Interior). Eso es un callback inter-tier, no solo inter-piso.

**Impacto en el sistema procedural (seed):**
Los elementos inter-piso son una **restricción de adyacencia** para el generador de seeds. Si el seed elige un template con cascada para el P8, entonces el P9 queda **obligado a elegir un template compatible** (uno que tenga la entrada de esa cascada). Esto se implementa así:

- Cada template del pool puede tener un tag `inter_floor_out` (ej: `cascada_sur`, `rio_este`, `raiz_central`) que indica qué elemento **sale** del piso hacia el siguiente.
- Cada template puede tener un tag `inter_floor_in` (ej: `cascada_sur`, `rio_este`) que indica qué elemento **recibe** del piso anterior.
- El generador, al armar la secuencia de pisos de un tier, primero elige los pisos sin restricción y después resuelve las conexiones: si el P8 tiene `out: cascada_sur`, el P9 debe ser un template con `in: cascada_sur` (o un template neutro sin tag `in`, que simplemente ignora la conexión).
- **Regla de escape**: si no hay template compatible disponible en el pool, el generador puede elegir uno neutro (sin conexión). No se debe bloquear la generación por falta de match — la conexión inter-piso es un **bonus**, no un requisito absoluto.
- Los templates con `inter_floor_in/out` deben ser ~30% del pool del tier. El 70% restante son neutros (sin conexiones) para dar libertad al seed.

---

## 11. Plantilla para diseñar un piso nuevo

Cuando le pidas a Claude (o a quien sea) un piso nuevo, usá esta plantilla. Forzala — si la respuesta no la completa, pedila de nuevo.

```yaml
piso:
  nombre_working: "El Lago Ciego"
  tier: 3
  bioma_base: "pantano_putrefacto"
  familia: "descanso"             # combate | exploracion | descanso | evento | anomalia | umbral | boss
  funcion: "Bajar tensión después de 3 pisos de combate en catacumbas"
  emocion_dominante: "melancolía contemplativa"
  landmark: "Un lago sin reflejo, con peces pálidos que nadan sin dirección"
  lectura_espacial: "circular, alrededor del lago"
  mecanica_distintiva: "No hay combate posible en 50m alrededor del lago — las armas se sienten pesadas"
  recompensa:
    - "Pescar con caña da materiales únicos del tier"
    - "Un NPC ciego vende mapas parciales del tier"
    - "Lore: diario en un bote"
  peligro: "Ninguno en el lago; alrededor, un enemigo único silencioso"
  rol_en_tier: "Contrapeso emocional entre dos tramos de combate duro"
  vida_visual:
    - "Peces pálidos (decorativos)"
    - "Libélulas sobre el agua"
    - "Un bote abandonado con lámpara encendida"
  por_que_encaja: "El tier III es hostil — un descanso no-humano mantiene el aislamiento sin agotar al jugador"
```

Si un piso propuesto no tiene las 11 líneas completas, no está diseñado.

---

## 12. Cómo usar este brief con Claude (o cualquier IA)

Los asistentes pierden tono rápido cuando se les dan pedidos abiertos. Las siguientes plantillas funcionan:

### Pedir ideas de piso
> "Usando `DESIGN_BRIEF.md` y `tower_biome_system.md` como canon, dame 5 ideas de piso para el **tier II (pisos 26–50)**, familia **descanso-triste**, emoción **melancolía respetuosa**. Cada idea debe completar la plantilla de 11 campos. Nada de relleno, nada de demonios genéricos. Referencia: Frieren."

### Validar una idea
> "Esta idea de piso: [idea]. ¿Viola alguna de las 12 prohibiciones? ¿Completa los 7 criterios de la gramática? ¿En qué tier encaja y por qué? Si no encaja, decime qué hay que cambiar."

### Rescate de idea débil
> "Este piso es bonito pero no juega. Dame 3 formas de darle una mecánica dominante sin traicionar su emoción ni violar los principios del brief."

### Crítica dura
> "Leé el DESIGN_BRIEF.md. Decime en qué está débil el diseño actual del juego y qué reforzaría la identidad sin agregar features nuevas."

---

## 13. Estado del MVP y prioridades inmediatas

**Donde estamos**: vertical slice avanzado. Core loop funciona (entrar, explorar, combatir, lootear, equipar, persistir). Piso 1 jugable. 5 clases. Loot, inventario y equipamiento integrados y aplicando stats reales al combate.

**Lo que falta para cerrar el MVP** (en orden de prioridad):
1. **Testear en Godot** todo lo integrado de las últimas 3 sesiones (lighting, loot, equipment, combate con stats, persistencia post-wipe-bug).
2. **Boss Trono Viscoso** jugable completo (diseño cerrado, implementación pendiente).
3. **Sistema de muerte con pérdida de loot del run** (hoy solo respawna).
4. **Stash persistente** implementado en el outpost del Piso 1.
5. **Taverna simple como pre-lobby**.
6. **Multiplayer Steam básico** (2 jugadores).
7. **Options menu + settings persistentes** (en paralelo, branch `feature/options-menu`).
8. **Polish del Round 2 de Judgment Day** (warnings menores).

**Después del MVP** (expansión natural):
- Pisos 2–25 (empezar a llenar el pool del Tier I).
- NPCs civiles del puesto fortificado.
- Carreta de mercader viajero con sus 5 estados.
- Sistema de habilidades por clase (hoy solo click + mantener).
- Safe zone Piso 25 con su contenido.
- Pets y mounts (pre-carro coop).

### Orden de diseño de contenido (canon)

El diseño de contenido del juego sigue este orden **y no otro**. Saltearse un paso produce sistemas que no encajan:

1. **Mapas primero**. Cada piso (o cada template del pool) se diseña con la plantilla de 11 campos del §11. Sin mapa diseñado, no se diseña nada más para ese piso.
2. **Monstruos después del mapa**. Una vez que el mapa existe y tiene emoción, lectura espacial y mecánica dominante definida, los monstruos se diseñan **para ese contexto**. Un monstruo de hielo vive en un piso de hielo no porque sea "temático", sino porque el mapa lo necesita mecánicamente.
3. **Retirados del piso**. Qué criaturas de tiers superiores pueden aparecer degradadas en ese piso.
4. **Sub-dungeons**. Qué mazmorra opcional entra en el piso, con su propio minijefe y recompensa exclusiva.
5. **Misiones emergentes**. Qué NPCs en situación pueden disparar quests en ese piso.
6. **Eventos sociales**. Qué minijuegos, fiestas, eventos temáticos encajan con el tono del piso.
7. **Habilidades de clase** que destaquen en ese tipo de piso (última capa — la jugabilidad de clase se ajusta al contenido, no al revés).

**Why**: El orden inverso (habilidades → eventos → monstruos → mapa) produce juegos donde todo se siente pegado con cinta. El mapa es la gramática; todo lo demás es vocabulario.

**Nunca antes del MVP**:
- Pisos 26+, tiers II+.
- Identificación de items.
- Gemas + engarzado.
- Ciclo día/noche.
- Trials / Plaza de Juicios.
- Minijuegos sociales completos.

---

## 14. Glosario rápido (términos internos del proyecto)

- **Torre** — el edificio de 100 pisos. Interior gigante con techo de caverna y diamante emisivo.
- **Tier** — tramo de 20–25 pisos con identidad emocional propia. Hay 5 tiers.
- **Pool** — set de templates de piso dentro de un tier, del cual se seleccionan los pisos de cada run.
- **Tutorial Zone** — Piso 1. Outpost con servicios básicos + pradera peligrosa al otro lado de la puerta. Aprendizaje vivo, no descanso.
- **Safe Zone** — piso de descanso REAL con servicios completos y sin peligro adentro. Canon solo en 25 y 50.
- **Trono Viscoso** — boss del Piso 1 (Rey Slime dentro del salón del trono devorado).
- **Outpost** — el puesto fortificado en la pradera con guardias, NPCs, stash, comercio.
- **Retirados** — criaturas de tiers futuros que aparecen degradadas/viejas en pisos inferiores como spoiler vivo.
- **Sub-dungeon** — mazmorra opcional corta (3–5 salas + minijefe) escondida dentro de un piso abierto.
- **Misión emergente** — quest opcional disparada por un NPC en situación (herido, robado, perdido). Encadena con sub-dungeons o rescates.
- **Contribución ponderada** — el sistema de rareza de loot en grupo.
- **Downed** — estado del jugador caído antes de morir. 30s. Los enemigos celebran.
- **Celebración** — animación de los enemigos cuando alguien queda downed. 15s.
- **Diegético** — que pertenece al mundo del juego, no pegado por encima. Los minijuegos tienen que serlo.
- **Road/wilderness** — filosofía de diseño de tramos: 1–50 caminos, 51–100 sin caminos.
- **Carro coop** — la carreta de cabras con 4 jugadores. Contenido único del género.
- **Cristal Cantor** — el boombox diegético.
- **Plaza de los Juicios** — el sistema de juicios entre jugadores, cómico, opt-out.
- **The Lost / El Perdido** — clase degenerada por resetear 6 veces.
- **Kinetic typography** — intro con texto + dragón entre capas de profundidad.

---

## 15. Notas finales

Este brief es el **alma del juego en texto**. Si alguna vez tenés que reiniciar una sesión con una IA y solo podés pasar un archivo, pasá este.

El GDD dice qué hace el juego. Este brief dice **por qué** lo hace, **a quién** le debe importar y **qué lo hace diferente** de los otros 300 dungeon crawlers de Steam.

El juego tiene algo que casi ningún juego coop del género tiene: **alma melancólica**, **humor cálido** y **hermandad real**. Defenderlo de la generalización genérica es el trabajo más importante del diseño.

Si en algún momento este brief choca con el instinto de "hagamos lo que hacen los otros", ganar el choque es el trabajo.

---

*Documento vivo. Actualizar cuando cambia la visión, no cuando cambian las features.*
