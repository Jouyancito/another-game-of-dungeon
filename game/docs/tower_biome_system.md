# Sistema de Biomas y Estructura de la Torre

**Version**: 1.0
**Fecha**: 2026-04-08
**Estado**: Design Document - Exhaustive Reference
**Autor**: Departamento de Game Design, Dungeon Party Studio

---

## Tabla de Contenidos

1. [Filosofia de la Torre](#a-filosofia-de-la-torre)
2. [Catalogo de Biomas](#b-catalogo-de-biomas)
3. [Sistema de Adyacencia Tematica](#c-sistema-de-adyacencia-tematica)
4. [Estructura de la Torre (100 Pisos)](#d-estructura-de-la-torre-100-pisos)
5. [Sistema de Seeds](#e-sistema-de-seeds)
6. [Rejugabilidad](#f-rejugabilidad)
7. [Mecanicas Ambientales por Bioma](#g-mecanicas-ambientales-por-bioma)
8. [Anti-patterns](#h-anti-patterns-lo-que-no-hacer)
9. [Fuentes y Referencias](#fuentes-y-referencias)

---

## A. Filosofia de la Torre

### Por que 100 pisos

La decision de 100 pisos no es arbitraria. Es una decision de diseno fundamentada en multiples ejes:

**Referencia narrativa**: Sword Art Online (Aincrad) establecio el arquetipo de "torre de 100 pisos" en el imaginario colectivo del genero. DanMachi usa una estructura similar con pisos que se profundizan. El numero 100 es lo suficientemente grande como para sentirse epico pero lo suficientemente redondo como para ser memorable.

**Matematica de contenido**: Con 20+ biomas distintos, 100 pisos permite que cada bioma aparezca en promedio 4-5 veces, pero nunca de la misma manera gracias a la generacion procedural. Esto da suficiente espacio para:
- 10 pisos de boss (cada 10 pisos)
- 9 pisos de descanso/taverna (cada ~10 pisos, antes de cada boss)
- 5 pisos de evento especial
- ~76 pisos de exploracion y combate con variacion de biomas

**Por que no 50**: 50 pisos no da suficiente espacio para desarrollar la curva de dificultad de forma gradual. Los saltos de dificultad serian demasiado abruptos entre rangos. Ademas, con 20+ biomas, muchos no aparecerian nunca en un run, desperdiciando contenido.

**Por que no 200**: 200 pisos diluye la experiencia. Cada piso individual pierde peso narrativo y emocional. El jugador deja de sentir progreso significativo. Ademas, para un equipo indie, 200 pisos de contenido unico es inviable. DanMachi tiene un dungeon "infinito" pero solo ~60 pisos estan documentados con detalle, y los jugadores pierden interes en la numeracion despues del piso 50.

### Ritmo de la experiencia

**Duracion de un piso promedio**: 10-20 minutos (exploracion + combate + loot)
- Pisos tempranos (1-20): ~10 min (tutorial/introductorio)
- Pisos medios (21-60): ~15 min (complejidad creciente)
- Pisos tardios (61-90): ~15-20 min (densidad de contenido alta)
- Pisos finales (91-100): ~20 min (maxima dificultad, mecanicas complejas)
- Pisos de boss: ~10-15 min (arena + combate de boss)
- Pisos de descanso: ~5 min (tienda, reparacion, preparacion)

**Duracion de un run completo (100 pisos)**: ~20-25 horas
- Esto NO es para una sola sesion. Un run completo se extiende a lo largo de multiples sesiones.
- Cada sesion natural: 1-3 horas (5-10 pisos)
- El juego guarda progreso entre sesiones dentro del mismo run

**Puntos de inflexion (pacing beats)**:
- Cada 10 pisos: Boss fight + recompensa significativa
- Cada 5 pisos: Cambio de bioma garantizado (no repetir bioma 5 veces seguidas)
- Cada 9 pisos: Taverna/descanso para reabastecerse
- Piso 50: "Midpoint twist" - cambio de reglas, nuevo tipo de amenaza
- Piso 100: Boss final de la torre, climax del run

### Como mantener la atencion en pisos 50+

Este es el problema mas critico. Dead Cells lo resuelve con rutas alternativas. Hades con narrativa. Spelunky 2 con branching paths. Nosotros usamos una combinacion:

**1. Escalada de complejidad mecanica, no solo numerica**
- Los biomas tardios no solo tienen enemigos con mas HP/DMG
- Introducen NUEVAS MECANICAS que cambian como jugas
- Ejemplo: en el Bioma Vacio (pisos 80+), la gravedad cambia aleatoriamente cada 30 segundos
- Ejemplo: en el Bioma Temporal, los enemigos tienen habilidades de "rewind"

**2. Composicion de biomas**
- A partir del piso 50, los biomas pueden FUSIONARSE
- Un piso puede ser "Bosque Congelado" (reglas de Bosque + mecanicas de Hielo)
- Esto multiplica la variedad exponencialmente sin crear contenido nuevo

**3. Eventos raros y descubrimientos**
- Pisos secretos que solo aparecen bajo condiciones especificas
- NPCs unicos con quests que afectan pisos futuros
- Loot legendario exclusivo de pisos 60+

**4. Presion de muerte permanente**
- Cuanto mas alto subis, mas tenes que perder (loot acumulado)
- La tension narrativa escala naturalmente con la inversion del jugador
- Inspirado en Dark Souls: el riesgo hace que cada piso se sienta importante

**5. Variacion visual progresiva**
- Los biomas en pisos 70+ tienen variantes "corrompidas" o "dimensionales"
- Misma mecanica base pero estetica completamente diferente
- Ejemplo: la Pradera en piso 5 es verde y soleada; la Pradera Marchita en piso 75 es gris y con ceniza

---

## B. Catalogo de Biomas

### Convenciones del catalogo

Cada bioma se define con:
- **Nombre** y descripcion tematica
- **Mecanica ambiental unica**
- **Paleta de colores** (3-4 colores principales)
- **Enemigos tematicos** (arquetipos, no nombres finales)
- **POIs** (Points of Interest)
- **Peligros ambientales**
- **Referencia** a juego/media con algo similar
- **Rango de pisos** donde puede aparecer

---

### 1. Pradera Interior

**Descripcion**: Un campo abierto iluminado por un diamante gigante en el techo de la caverna. Hierba verde, arboles aislados, colinas suaves. Sensacion de libertad falsa — estas dentro de una torre, pero parece un mundo exterior. Casas en ruinas, pilares de piedra antiguos.

**Mecanica ambiental**: **Viento variable** — rafagas de viento empujan a los jugadores y proyectiles en direcciones aleatorias cada 15-20 segundos. Los proyectiles de arquero y mago se desvian.

**Paleta de colores**: Verde esmeralda, dorado trigo, azul cielo palido, marron tierra

**Enemigos tematicos**:
- Slimes basicos (tutorial)
- Lobos (pack AI, atacan en grupo)
- Golems de piedra (lentos, tanques, rompen cobertura)
- Pajaros agresivos (aereos, atacan en picada)

**POIs**:
- Casa en ruinas (loot basico, a veces NPC)
- Altar de piedra (buff temporal al interactuar)
- Pozo antiguo (acceso a area secreta subterranea)
- Campamento de aventureros abandonado (crafting station temporal)

**Peligros ambientales**:
- Agujeros ocultos en la hierba alta (caida, danio de caida)
- Plantas venenosas (DoT al contacto)
- Nidos de avispas (agravan si te acercas, enjambre)

**Referencia**: SAO Piso 1 (grassland), Valheim Meadows, Dark Souls Undead Burg (sensacion de tutorial pero con peligro real)

**Rango de pisos**: 1-15, 70-80 (variante Marchita)

---

### 2. Bosque Denso

**Descripcion**: Arboles enormes cuyas copas bloquean casi toda la luz. El suelo esta cubierto de raices, musgo y hongos luminiscentes. Caminos estrechos entre troncos gigantes. Sensacion claustrofobica — lo contrario de la Pradera.

**Mecanica ambiental**: **Visibilidad reducida** — niebla baja constante que limita el rango de vision a 8-10 metros (vs 20-25m normal). Los enemigos pueden emboscar. El minimapa se desactiva parcialmente.

**Paleta de colores**: Verde oscuro, marron corteza, purpura hongos bioluminiscentes, gris niebla

**Enemigos tematicos**:
- Treants (arboles animados, se camuflan hasta que estas cerca)
- Aranas gigantes (telaranas que ralentizan, ataques emboscada)
- Duendes del bosque (rapidos, esquivos, roban items del inventario)
- Oso corrupto (mini-boss, tanque agresivo)

**POIs**:
- Arbol ancestral (interactuar revela mapa parcial del piso)
- Cueva de hongos (alquimia/pociones)
- Santuario druidico (heals o buffs de naturaleza)
- Puente de raices (shortcut peligroso, puede romperse)

**Peligros ambientales**:
- Telaranas (ralentizan movimiento 50%)
- Esporas toxicas (nubes verdes, DoT + confusion visual)
- Raices que atrapan (inmovilizan 2 segundos, requieren input para escapar)
- Caida de ramas (danio de area aleatorio)

**Referencia**: SAO Piso 3 (misty forest), Terraria Underground Jungle, DanMachi pisos 25-27 (Large Tree Labyrinth)

**Rango de pisos**: 5-25, 75-85 (variante Bosque Muerto)

---

### 3. Cavernas de Cristal

**Descripcion**: Cuevas amplias con formaciones de cristal gigantes que emiten luz propia en tonos azules, rosas y blancos. Los cristales reflejan y distorsionan la luz, creando sombras confusas. El sonido rebota creando ecos enganosos.

**Mecanica ambiental**: **Refraccion de luz** — los ataques de energia/magicos pueden rebotar en cristales, danando aliados o enemigos dependiendo del angulo. Los cristales se pueden destruir para crear nuevas rutas o eliminar rebotes peligrosos.

**Paleta de colores**: Azul cristalino, rosa cuarzo, blanco diamante, negro obsidiana

**Enemigos tematicos**:
- Elementales de cristal (reflejan un porcentaje de danio magico)
- Murcielagos de cristal (enjambre, emiten sonido que aturde)
- Golem de cuarzo (se fragmenta al morir, genera 3 mini-golems)
- Gusano minero (emerge del suelo, ataque sorpresa)

**POIs**:
- Veta de minerales (recursos de crafting raros)
- Camara de resonancia (puzzle musical para abrir paso)
- Cristal gigante central (romperlo libera boss; dejarlo da buff de luz)
- Lago subterraneo (pesca de items, acceso a area secreta)

**Peligros ambientales**:
- Cristales inestables (explotan si los golpeas, danio de area)
- Caida de estalactitas (zonas marcadas en el suelo)
- Gas toxico en tuneles estrechos (necesitas avanzar rapido)
- Suelo resbaladizo por humedad

**Referencia**: Noita Snowy Depths (subterraneo hostil), Terraria Crystal Caverns, Deep Rock Galactic Crystalline Caverns

**Rango de pisos**: 10-30, 60-75

---

### 4. Pantano Putrefacto

**Descripcion**: Agua estancada color verde turbio, arboles muertos con lianas colgantes, niebla espesa color amarillo verdoso. El suelo es inestable — partes solidas, partes fango que te hunde. Olor a descomposicion (comunicado por efectos visuales de particulas).

**Mecanica ambiental**: **Terreno traicionero** — el 30% del suelo visible es fango que reduce velocidad de movimiento al 40%. El agua estancada aplica "Plagued" (DoT lento, 2% HP/seg). Saltar consume stamina extra. Los ataques de fuego son 25% mas efectivos.

**Paleta de colores**: Verde toxico, marron fango, amarillo bilis, gris muerto

**Enemigos tematicos**:
- Ranas venenosas gigantes (saltan, escupen veneno en area)
- No-muertos del pantano (lentos pero resurreccen si no los rematas con fuego)
- Sanguijuelas (se adhieren, drenan HP, invisibles en agua)
- Hidra de pantano (mini-boss, multiples cabezas, regenera si no cortamos todas)

**POIs**:
- Choza de la bruja (compra/venta de pociones, precios erraticos)
- Barco hundido (loot de agua, requiere bucear)
- Arbol de los ahorcados (lore, a veces quest NPC)
- Islote seco (safe zone pequeno, punto de respiro)

**Peligros ambientales**:
- Pozos de fango (inmovilizan, necesitas ayuda de aliado o consumible)
- Gas de pantano (explosivo si hay fuego cerca — riesgo y oportunidad)
- Sanguijuelas en el agua (danio pasivo constante al caminar por agua)
- Lluvia acida (DoT leve constante al aire libre)

**Referencia**: Valheim Swamp, DanMachi (ambiente opresivo de pisos medios), Dark Souls Blighttown

**Rango de pisos**: 15-35, 65-80

---

### 5. Tundra Congelada

**Descripcion**: Paisaje de hielo y nieve con viento cortante. Cuevas de hielo con estalactitas congeladas, lagos congelados que pueden romperse, ventiscas que van y vienen. La temperatura afecta al jugador.

**Mecanica ambiental**: **Hipotermia** — un medidor de frio se llena gradualmente. Al llenarse: reduccion de velocidad de ataque 20%, luego movimiento 30%, luego DoT. Se reduce estando cerca de fuego (antorchas, fogatas, ataques de fuego). Los ataques de hielo/agua son 25% mas efectivos contra jugadores. El suelo de hielo reduce la friccion (deslizamiento).

**Paleta de colores**: Blanco nieve, azul hielo, gris tormenta, celeste palido

**Enemigos tematicos**:
- Lobos de escarcha (rapidos, ataques que aplican "Frostbite" — slow)
- Elemental de hielo (proyectiles de hielo, crea paredes de hielo)
- Yeti (tanque lento, golpe que lanza hacia atras, grito que aturde en area)
- Espiritus de ventisca (invisibles durante tormenta, visibles en calma)

**POIs**:
- Cueva caliente (safe zone natural, fogata con NPC)
- Lago congelado (loot debajo, riesgo de romper el hielo y caer)
- Altar de hielo (buff de resistencia al frio temporal)
- Cadaver congelado de aventurero (loot garantizado, a veces trampa)

**Peligros ambientales**:
- Ventisca (reduce visibilidad a 3m, empuja al jugador)
- Suelo de hielo (deslizamiento, inercia al moverse)
- Avalanchas (en areas de montana, danio masivo de area)
- Agua congelante (caer al agua aplica Frostbite instantaneo)

**Referencia**: Valheim Mountains, SAO Piso 8 (winter), Risk of Rain 2 Rallypoint Delta, Noita Snowy Depths

**Rango de pisos**: 15-40, 70-85

---

### 6. Volcan Activo

**Descripcion**: Roca negra y roja, rios de lava fluyendo, ceniza en el aire, calor asfixiante. Plataformas de roca solida sobre lagos de magma. Erupciones menores periodicas que remodelan el terreno. Luz roja/naranja dominante.

**Mecanica ambiental**: **Calor extremo** — medidor de calor (opuesto a hipotermia). Al llenarse: DoT por quemaduras, reduccion de regeneracion HP/MP. Se reduce con pociones de resistencia al fuego o estando cerca de agua/hielo. Los ataques de fuego hacen 25% MENOS danio a enemigos (son resistentes), pero los ataques de hielo/agua hacen 30% MAS.

**Paleta de colores**: Rojo magma, negro obsidiana, naranja lava, gris ceniza

**Enemigos tematicos**:
- Salamandras de fuego (nadan en lava, emergen para atacar)
- Elemental de lava (invulnerable al fuego, debil a hielo)
- Diablillos volcanicos (voladores, lanzan bolas de fuego)
- Golem de obsidiana (extremadamente resistente, lento, golpe devastador)

**POIs**:
- Forja antigua (mejora de armas temporal, +fire damage)
- Templo del dragon (lore + boss opcional)
- Geyser de vapor (plataforma de salto, acceso a areas elevadas)
- Mina de obsidiana (recursos raros de crafting)

**Peligros ambientales**:
- Rios de lava (danio masivo al contacto, muerte en 3 segundos)
- Erupciones (proyectiles de magma cayendo en areas aleatorias)
- Suelo inestable (se desmorona sobre lava despues de pisar)
- Ceniza en el aire (reduccion leve de visibilidad constante)

**Referencia**: SAO Piso 13 (volcano), Spelunky 2 Volcana, Noita (lava systems), Dark Souls Lost Izalith

**Rango de pisos**: 20-45, 75-90

---

### 7. Ruinas Antiguas

**Descripcion**: Restos de una civilizacion avanzada perdida. Columnas rotas, mosaicos en el suelo, estatuas decapitadas, salas enormes con techos derrumbados. Mezcla de naturaleza reclamando la arquitectura. Trampas mecanicas antiguas aun funcionales.

**Mecanica ambiental**: **Trampas mecanicas** — el bioma tiene la mayor densidad de trampas del juego. Piso con presion, dardos envenenados, paredes que se cierran, cuchillas pendulares. Las trampas se pueden activar contra enemigos si los atraes hacia ellas. Los Rogues/Dex characters tienen ventaja detectandolas.

**Paleta de colores**: Beige arenisca, gris piedra, verde musgo, dorado desgastado

**Enemigos tematicos**:
- Constructos guardianes (robots de piedra, patrullan rutas fijas)
- Momias (lentas, pero su ataque aplica "Curse" — reduce defensa)
- Tramperos fantasma (invisibles, activan trampas cerca de jugadores)
- Golem guardian (mini-boss, protege la sala del tesoro)

**POIs**:
- Biblioteca antigua (lore scrolls, posibilidad de aprender habilidad temporal)
- Sala del tesoro (bien custodiada, loot premium)
- Fuente de restauracion (heal completo una vez por piso)
- Taller del artificer (desactiva trampas del piso si resuelves puzzle)

**Peligros ambientales**:
- Trampas de presion (dardos, picos del suelo)
- Paredes que se cierran (crush damage, one-shot si no esquivas)
- Suelo que se derrumba (caida a nivel inferior)
- Estatuas que cobran vida (sorpresa, se activan cuando das la espalda)

**Referencia**: SAO Piso 5 (ancient ruins), DanMachi pisos 51-57 (labyrinth), Spelunky Temple

**Rango de pisos**: 10-35, 55-70

---

### 8. Desierto Abrasador

**Descripcion**: Dunas de arena dorada infinitas, oasis escasos, ruinas semienterradas, sol abrasador (o su equivalente en la torre: cristal de luz ardiente en el techo). Tormentas de arena periodicas que cambian la topografia.

**Mecanica ambiental**: **Sed y tormentas** — medidor de deshidratacion (similar a hipotermia). Reduce stamina y velocidad de sprint. Se mitiga en oasis o con consumibles de agua. Tormentas de arena periodicas (cada 2-3 minutos, duran 30 segundos) que reducen visibilidad y danan si estas al descubierto.

**Paleta de colores**: Dorado arena, naranja atardecer, marron terracota, azul oasis

**Enemigos tematicos**:
- Escorpiones gigantes (veneno + ataque de cola)
- Gusanos de arena (emergen debajo, danio de area, Tremors-style)
- Bandidos del desierto (humanoides, usan tacticas de grupo, tienen arcos)
- Esfinge (mini-boss, lanza acertijos — respuesta incorrecta = danio)

**POIs**:
- Oasis (safe zone, recupera deshidratacion, a veces NPC mercader)
- Piramide semienterrada (mini-dungeon dentro del piso)
- Caravana abandonada (loot, a veces trampa)
- Espejismo (puede ser loot real o trampa, 50/50)

**Peligros ambientales**:
- Tormentas de arena (danio + ceguera temporal)
- Arena movediza (inmobiliza, hundimiento progresivo)
- Calor extremo al sol (DoT si no estas en sombra durante horas pico)
- Cactus (danio al contacto)

**Referencia**: SAO Piso 11 (desert), Journey (estetica de dunas), Zelda Gerudo Desert, Metin2 Desert maps

**Rango de pisos**: 15-40, 60-75

---

### 9. Oceano Sumergido

**Descripcion**: Camaras gigantes inundadas dentro de la torre. El jugador se mueve en un entorno parcialmente acuatico — plataformas de ruinas sobre agua profunda, tuneles sumergidos, burbujas de aire. Corales luminiscentes, peces bioluminiscentes, ruinas submarinas.

**Mecanica ambiental**: **Sistema de oxigeno** — al sumergirse, un medidor de oxigeno se agota. Al vaciarse: DoT rapido. Burbujas de aire y plantas acuaticas restauran oxigeno. El movimiento bajo el agua es 40% mas lento. Los ataques de rayo hacen danio de area en agua (danio a todos en el agua, incluidos aliados — cuidado con el fuego amigo). Los ataques de fuego no funcionan bajo el agua.

**Paleta de colores**: Azul profundo, turquesa coral, verde alga, blanco espuma

**Enemigos tematicos**:
- Medusas electricas (ataques de rayo en area de agua)
- Tiburones oscuros (rapidos, ataques devastadores, solo en agua profunda)
- Cangrejos ermitano gigantes (tanques lentos, caparazon con loot)
- Sirena (atrae al jugador hacia agua profunda con canto, letal si caes)

**POIs**:
- Ruina submarina (loot acuatico exclusivo)
- Jardin de coral (alquimia acuatica, pociones de respiracion)
- Barco hundido (loot premium, custodiado)
- Altar de Poseidon (buff de movimiento acuatico)

**Peligros ambientales**:
- Corrientes (empujan al jugador en una direccion)
- Zonas de presion (a mucha profundidad, danio constante)
- Torbellinos (arrastran hacia el centro, danio al golpear fondo)
- Anemonas venenosas (DoT al contacto)

**Referencia**: SAO Piso 4 (lake), Subnautica (tension subacuatica), DanMachi Water City (piso 25), Zelda Water Temple

**Rango de pisos**: 20-45, 65-80

---

### 10. Plataformas del Cielo / Tormenta

**Descripcion**: Plataformas flotantes sobre un vacio infinito, conectadas por puentes de energia, cadenas o fragmentos de roca. Tormentas electricas constantes, viento que empuja. Caer es muerte instantanea. Vertigo real.

**Mecanica ambiental**: **Vacio y rayos** — caer de una plataforma es muerte instantanea (o danio masivo + respawn en la plataforma anterior). Rayos caen periodicamente en areas marcadas (2 seg de warning visual). Armadura metalica atrae rayos — tanques son vulnerables aqui. Clases ligeras tienen ventaja.

**Paleta de colores**: Gris tormenta, purpura electrico, blanco relampago, negro vacio

**Enemigos tematicos**:
- Harpias (voladoras, ataques que empujan hacia el borde)
- Elemental de rayo (teletransporte corto, danio de rayo en cadena)
- Gargoyles (estacionarios en bordes, despiertan cuando te acercas)
- Dragon de tormenta (boss de bioma, vuela entre plataformas)

**POIs**:
- Santuario del viento (buff de resistencia a empuje)
- Nido de harpias (loot + huevos que se venden caro)
- Obelisco de rayo (canalizar para crear puente a plataforma secreta)
- Fragmento de torre flotante (mini-dungeon vertical)

**Peligros ambientales**:
- Caida al vacio (muerte instantanea / respawn con penalizacion)
- Rayos periodicos (danio alto, area marcada, armadura metalica atrae)
- Viento fuerte (empuja hacia bordes, mas peligroso en puentes)
- Puentes inestables (se desmoronan despues de 5 segundos de pisar)

**Referencia**: SAO Piso 4 (sky theme), Risk of Rain 2 Sky Meadow, Zelda Skyward Sword, Dark Souls Anor Londo (verticalidad)

**Rango de pisos**: 25-50, 70-90

---

### 11. Selva Tropical

**Descripcion**: Vegetacion exuberante, arboles gigantes con raices aereas, lianas por todas partes, lluvia constante, calor humedo. La verticalidad es clave — el nivel tiene multiples capas (suelo, copa de arboles, dosel). Sonidos constantes de fauna. Todo esta VIVO.

**Mecanica ambiental**: **Verticalidad y lluvia** — el piso tiene 3 niveles verticales (suelo, nivel medio entre ramas, dosel superior). La lluvia constante hace que superficies inclinadas sean resbaladizas. Ciertas plantas se pueden trepar. El fuego se apaga rapido (desventaja para builds de fuego).

**Paleta de colores**: Verde lima, verde esmeralda, marron humedo, amarillo flor tropical

**Enemigos tematicos**:
- Monos agresivos (rapidos, tiran objetos desde las copas)
- Serpientes constrictoras (atrapan, necesitas mash para liberarte)
- Plantas carnivoras (estacionarias, muerden si te acercas, alto danio)
- Jaguar sombra (sigiloso, ataca desde atras, muy rapido)

**POIs**:
- Altar Maya (puzzle de secuencia, recompensa legendaria)
- Cascada oculta (detras: cueva con loot)
- Arbol gigante central (NPC sabio, quest o lore)
- Campamento de exploradores (crafting + mercader)

**Peligros ambientales**:
- Lianas trampa (atrapan al jugador si camina rapido sin mirar)
- Rios con corriente (arrastran, pueden llevar a cascada = danio de caida)
- Insectos venenosos (enjambres pequeños, DoT leve pero constante)
- Lluvias torrenciales (visibilidad reducida + sonido ambiental alto, dificulta comunicacion)

**Referencia**: DanMachi pisos 29-32 (Dense Forest Ravine), SAO Piso 7 (rain forest), Terraria Jungle, Valheim Black Forest (densidad)

**Rango de pisos**: 10-35, 60-80

---

### 12. Forja Infernal / Fundicion

**Descripcion**: Una instalacion industrial dentro de la torre. Engranajes gigantes girando, cadenas, plataformas moviles, metal al rojo vivo, chimeneas escupiendo humo. Alguien (o algo) construyo esto para forjar... que? Ruidos metalicos constantes.

**Mecanica ambiental**: **Maquinaria activa** — plataformas moviles, engranajes que aplastan, chorros de vapor que danan. El nivel es un puzzle de timing ademas de combate. Las partes mecanicas se pueden manipular (activar/desactivar) para crear ventajas tacticas o trampas para enemigos.

**Paleta de colores**: Naranja metal caliente, gris acero, rojo brasa, marron oxido

**Enemigos tematicos**:
- Automotones (robots mecanicos, patrones predecibles pero letales)
- Herreros oscuros (humanoides, ataques con martillos infundidos de fuego)
- Ensamblajes (enemigos que se "reparan" si no los destruyes completamente)
- Araña mecanica (boss de bioma, se cuelga del techo, dispara tornillos)

**POIs**:
- Forja maestra (mejora permanente de arma durante el run)
- Panel de control (activar/desactivar secciones del nivel)
- Almacen de materiales (recursos de crafting en abundancia)
- Prototipo abandonado (arma/item unico de este bioma)

**Peligros ambientales**:
- Engranajes aplastantes (timing, one-shot)
- Vapor a presion (danio + empuje, areas marcadas)
- Metal al rojo vivo (suelo que dano al pisar)
- Cadenas que caen (danio + atrapamiento temporal)

**Referencia**: Noita Hiisi Base (instalacion industrial), Dark Souls Sen's Fortress (trampas de timing), Dead Cells Clocktower

**Rango de pisos**: 25-50, 65-85

---

### 13. Catacumbas / Necropolis

**Descripcion**: Tumbas infinitas talladas en roca, sarcofagos apilados, huesos decorando las paredes, velas que se encienden y apagan solas. Silencio absoluto excepto por susurros que no podemos identificar. Los muertos no descansan aqui.

**Mecanica ambiental**: **Oscuridad activa** — la iluminacion es minima. Los jugadores necesitan antorchas, hechizos de luz, o habilidades para ver. Los enemigos pueden ver en la oscuridad. Romper fuentes de luz (candelabros) oscurece zonas. Los Necromancers tienen ventaja aqui: sus invocaciones son 30% mas fuertes.

**Paleta de colores**: Negro profundo, gris hueso, violeta espectral, dorado tumba

**Enemigos tematicos**:
- Esqueletos armados (clasico, se reconstruyen una vez si no usas luz sagrada)
- Espectros (intangibles excepto contra ataques magicos, drenan MP)
- Liche menor (caster, invoca esqueletos, se teletransporta)
- Revenant (guerrero no-muerto poderoso, agresivo, resiste mucho)

**POIs**:
- Tumba del heroe (lore + loot raro, a veces maldito)
- Altar de descanso (heal + buff contra undead temporal)
- Biblioteca del liche (scrolls de habilidades oscuras)
- Catacomba secreta (mini-dungeon extra, loot legendario)

**Peligros ambientales**:
- Oscuridad total (sin luz, los ataques pierden 50% de precision)
- Manos que emergen del suelo (slow + danio leve, jump scare)
- Gas cadaverico (nausea visual = distorsion de pantalla + slow)
- Sarcofagos que se abren (spawneo de esqueleto)

**Referencia**: Diablo 2 Catacombs, Dark Souls Catacombs/Tomb of the Giants (oscuridad opresiva), DanMachi deep floors (atmosfera)

**Rango de pisos**: 20-45, 70-90

---

### 14. Jardin Corrompido

**Descripcion**: Lo que alguna vez fue un jardin hermoso ahora esta retorcido. Flores mutantes, arboles con caras, frutos podridos que emiten esporas, enredaderas que se mueven. Belleza y horror coexisten. Los colores son vibrantes pero "equivocados" — rosas demasiado rojos, verdes demasiado brillantes.

**Mecanica ambiental**: **Corrupcion progresiva** — un medidor de corrupcion sube al estar en el bioma. Niveles bajos: efectos cosmeticos (pantalla levemente distorsionada). Niveles medios: alucinaciones (enemigos falsos). Niveles altos: debuffs reales (stats reducidos). Se reduce con pociones de purificacion o altares de limpieza.

**Paleta de colores**: Rosa corrupto, verde toxico brillante, purpura veneno, negro podredumbre

**Enemigos tematicos**:
- Enredaderas vivas (atrapan, constriccion, damagean sobre tiempo)
- Hongos caminantes (explotan al morir, liberan esporas confusas)
- Hadas corrompidas (voladoras rapidas, ataques de magia oscura)
- Bestia del jardin (boss, fusión de planta y animal, multiples fases)

**POIs**:
- Fuente de purificacion (limpia corrupcion, heal parcial)
- Invernadero intacto (semillas para alquimia, recipes)
- Estatua de la jardinera (lore del origen de la corrupcion)
- Fruto dorado (consumible raro, buffs potentes pero riesgo de corrupcion)

**Peligros ambientales**:
- Esporas en el aire (corrupcion + confusion visual)
- Frutos tentadores (comer da buff temporal pero sube corrupcion mucho)
- Enredaderas que agarran (inmovilizan, danio sobre tiempo)
- Suelo que se hunde (zonas de compost, slow)

**Referencia**: Terraria Corruption/Crimson, Hollow Knight Fungal Wastes, Dark Souls Darkroot Garden, Elden Ring Caelid (corrupcion ambiental)

**Rango de pisos**: 25-50, 60-80

---

### 15. Dimension Astral / Vacio

**Descripcion**: El espacio entre dimensiones. Plataformas de roca flotando en un vacio estrellado. Gravedad reducida. Fragmentos de otros biomas flotando como islas. Estetica surreal — colores invertidos, geometria imposible, sensacion de no pertenecer.

**Mecanica ambiental**: **Gravedad alterada** — saltos son 2x mas altos, caida mas lenta. Cada 30-45 segundos la gravedad cambia de direccion (arriba, lateral, invertida). Los jugadores deben adaptarse constantemente. Los proyectiles tambien se ven afectados por los cambios de gravedad. No hay "arriba" permanente.

**Paleta de colores**: Negro vacio, purpura cosmico, blanco estelar, azul nebulosa

**Enemigos tematicos**:
- Observadores (ojos flotantes, rayos de energia, telegrafian con la mirada)
- Fragmentos de vacio (geometria imposible animada, ataques de area)
- Entidad astral (boss de bioma, cambia la gravedad a voluntad)
- Ecos (clones oscuros del jugador, mismas habilidades pero invertidas)

**POIs**:
- Fragmento de otro bioma (mini-area con reglas del bioma original)
- Portal roto (shortcut a 2-3 pisos adelante, riesgo de ir a piso aleatorio)
- Altar del vacio (sacrifice: pierde HP para ganar loot raro)
- Constellation puzzle (resolver patron estelar para buff permanente del run)

**Peligros ambientales**:
- Cambios de gravedad (impredecibles, pueden causar caida al vacio)
- Zonas de distorsion (teletransportan aleatoriamente dentro del piso)
- Vacio absoluto (zonas sin plataforma = muerte)
- Entropias visuales (pantalla se distorsiona, disorienta)

**Referencia**: SAO Piso 5 "Dimension Rota" (GDD original), Risk of Rain 2 Void Fields, Dark Souls Ash Lake (alien), Noita Parallel Worlds

**Rango de pisos**: 45-70, 85-100

---

### 16. Abismo Abismal / Profundidades

**Descripcion**: Las profundidades mas oscuras de la torre. Presion aplastante, bioluminiscencia escasa, criaturas adaptadas a la oscuridad total. Sensacion de estar donde ningun mortal deberia estar. El jugador se siente PEQUENO.

**Mecanica ambiental**: **Presion y terror** — un medidor de "Cordura" baja mientras estas en el bioma (inspirado en Darkest Dungeon). Cordura baja causa: alucinaciones (enemigos falsos), reduccion de precision, eventual panic (movimiento erratico). Se mitiga estando cerca de aliados (co-op incentivo), usando items de luz, o descansando en safe zones.

**Paleta de colores**: Negro abisal, azul profundo, verde bioluminiscente tenue, blanco ojos

**Enemigos tematicos**:
- Anglerfish (senal de luz falsa que atrae, ataque devastador)
- Sombras vivientes (solo visibles al borde de tu campo de vision)
- Kraken menor (tentaculos que emergen del piso/paredes)
- Dios dormido (boss de bioma, lovecraftiano, altera realidad)

**POIs**:
- Faro de las profundidades (safe zone, restaura cordura, NPC)
- Restos de expedicion anterior (lore, loot de adventureros caidos)
- Altar abisal (pacto oscuro: buff potente a cambio de maldicion)
- Burbuja de realidad (mini-zona donde las reglas normales aplican)

**Peligros ambientales**:
- Oscuridad absoluta (peor que catacumbas, luz apenas alcanza 3m)
- Perdida de cordura (alucinaciones, debuffs mentales)
- Terremotos (danio de area, cambia layout de pasillos)
- Mimic de cofres (cofres que son enemigos disfrazados)

**Referencia**: DanMachi Deep Floors 37+ (terror psicologico), Darkest Dungeon (cordura), Subnautica (terror de profundidad), Bloodborne (estetica Lovecraft)

**Rango de pisos**: 50-75, 85-100

---

### 17. Ciudad Abandonada

**Descripcion**: Los restos de una ciudad que existio dentro de la torre. Calles empedradas, edificios de piedra y madera en ruinas, plazas con fuentes secas, faroles apagados. Alguien vivio aqui. Ya no. Que paso?

**Mecanica ambiental**: **Combate urbano** — el bioma favorece tacticas de cobertura. Los edificios se pueden entrar y usar como posiciones defensivas. Las calles estrechas limitan movimiento lateral. Los techos se pueden caminar. El verticalidad y flanqueo son criticos. Puertas se pueden bloquear/romper.

**Paleta de colores**: Gris piedra, marron madera vieja, blanco desteñido, negro hollin

**Enemigos tematicos**:
- Ciudadanos fantasma (humanoides etéreos, atacan en grupo, debiles individualmente)
- Rata rey (jefe de enjambre, controla hordas de ratas)
- Guardian de la ciudad (constructo, patrulla calles, muy resistente)
- Ladron de sombras (stealth, ataca desde edificios, roba items)

**POIs**:
- Ayuntamiento (lore central, mapa del piso)
- Tienda abandonada (loot variado, a veces trampa)
- Teatro (evento: obra de teatro fantasma, recompensa por completarla)
- Alcantarilla (acceso a ruta alternativa subterranea)

**Peligros ambientales**:
- Edificios que se derrumban (al entrar, chance de colapso, danio + atrapamiento)
- Fuego en edificios (se propaga, bloquea rutas)
- Ratas (enjambres pequenos, danio leve pero constante en calles)
- Trampas de antiguos residentes (en entradas de edificios)

**Referencia**: DanMachi Rivira (ciudad subterranea), Dark Souls Undead Burg/Lower Undead Burg, Bloodborne Yharnam, Diablo 2 Lut Gholein

**Rango de pisos**: 20-45, 55-75

---

### 18. Bosque de Hongos Gigantes

**Descripcion**: Hongos del tamano de arboles, esporas flotando en el aire, luz bioluminiscente en colores pastel. El suelo es esponjoso (afecta movimiento). Todo es organico, blando, humedo. Sonidos de goteo y... respiracion? Los hongos estan VIVOS.

**Mecanica ambiental**: **Esporas activas** — diferentes tipos de esporas flotan en el aire, cada una con un efecto distinto. Esporas rojas: danio. Azules: slow. Verdes: heal (si! beneficiosa). Doradas: buff temporal. El jugador debe leer el color y decidir si esquivar o buscar las esporas. Los ataques de viento/aire dispersan esporas en nuevas direcciones.

**Paleta de colores**: Azul bioluminiscente, rosa esporas, purpura hongo, verde musgo fluorescente

**Enemigos tematicos**:
- Myconid (humanoide hongo, lento, ataque espora en area)
- Spore stalker (invisible cuando esta quieto, parece un hongo mas)
- Slime fungico (absorbe elementos, devuelve del mismo tipo)
- Colonia madre (boss, hongo gigante estacionario, spawmea adds)

**POIs**:
- Claro de hongos luminosos (safe zone, esporas verdes concentradas)
- Laboratorio de un alquimista (crafting de pociones de esporas)
- Hongo ancestral (NPC, da quest o informacion en formato críptico)
- Mina de micelios (recursos organicos raros)

**Peligros ambientales**:
- Esporas rojas (DoT al caminar por nubes rojas)
- Esporas azules (slow al caminar por nubes azules)
- Suelo esponjoso (movimiento 20% mas lento, saltos 30% mas altos)
- Hongos explosivos (los pisas, explotan, danio de area)

**Referencia**: Terraria Mushroom Biome, Dark Souls Ash Lake (mystique), Morrowind Telvanni (hongos gigantes), Hollow Knight Fungal Wastes

**Rango de pisos**: 15-40, 60-75

---

### 19. Templo del Reloj / Dominio Temporal

**Descripcion**: Un espacio donde el tiempo no fluye normalmente. Relojes gigantes en las paredes, engranajes de tiempo flotantes, zonas donde todo se mueve en camara lenta o camara rapida. Estetica steampunk mezclada con magia arcana. Las manecillas de los relojes se mueven en direcciones aleatorias.

**Mecanica ambiental**: **Zonas temporales** — el piso tiene zonas de "tiempo lento" (jugador y enemigos al 50% velocidad) y "tiempo rapido" (todo al 150% velocidad). Estas zonas estan marcadas por el color del suelo (azul = lento, rojo = rapido). Los jugadores habiles pueden atraer enemigos a zonas lentas y atacar desde zonas rapidas. Cada 60 segundos, las zonas se reconfiguran.

**Paleta de colores**: Dorado reloj, bronce engranaje, azul tempo-lento, rojo tempo-rapido

**Enemigos tematicos**:
- Cronista (mago que acelera/ralentiza aliados y jugadores)
- Automoton del reloj (se mueve en patron de reloj, predecible pero letal)
- Devorador de tiempo (absorbe buffs temporales del jugador)
- Guardian del Reloj (boss, controla las zonas temporales a voluntad)

**POIs**:
- Reloj central (puzzle de engranajes, detiene las zonas temporales 60 seg)
- Sala del Cronista (NPC que vende items temporales)
- Reloj roto (area de "tiempo congelado", enemigos y jugadores quietos — momento para explorar)
- Biblioteca de tiempo (lore sobre la torre y sus creadores)

**Peligros ambientales**:
- Zonas de tiempo rapido (enemigos mas rapidos, danio mas frecuente)
- Loops temporales (areas que te devuelven a la entrada si no resuelves puzzle)
- Engranajes de tiempo (aplastan en intervalos regulares)
- Envejecimiento acelerado (zona especifica: reduce stats temporalmente)

**Referencia**: Dead Cells Clocktower, Braid (mecanicas temporales), Prince of Persia (tiempo), Chrono Trigger

**Rango de pisos**: 35-55, 75-95

---

### 20. Playa de Ceniza / Tierras Muertas

**Descripcion**: Un paisaje post-apocaliptico dentro de la torre. Ceniza cubre todo, el cielo es gris permanente, arboles calcinados, rios secos. No hay vida — solo muerte y silencio. Aqui algo terrible paso. Es la advertencia de lo que espera arriba.

**Mecanica ambiental**: **Desolacion** — no hay regeneracion natural de HP/MP en este bioma. Las pociones son 50% menos efectivas. El Healer es CRITICO aqui. La unica forma de recuperar HP es con habilidades de aliados, items, o encontrar los escasos oasis de vida. Los ataques sagrados/luz hacen 25% mas danio.

**Paleta de colores**: Gris ceniza, negro carbon, blanco hueso, rojo brasa moribunda

**Enemigos tematicos**:
- Ceniza animada (amorfa, se reforma si no usas ataques de luz)
- Draugr (no-muertos nordicos, fuertes, resisten knockback)
- Fenix corrupto (volador, explotan al morir, renacen una vez)
- Remanente del cataclismo (boss, entidad de destruccion pura)

**POIs**:
- Oasis de vida (unico lugar con regeneracion natural, safe zone)
- Monumento al caido (lore + buff de motivacion para el equipo)
- Crater de impacto (centro del cataclismo, loot raro pero vigilado)
- Refugio subterraneo (NPC sobreviviente, quest)

**Peligros ambientales**:
- Ceniza en el aire (reduccion de visibilidad leve constante)
- Suelo inestable (zonas que se hunden, caida a vacio)
- Llamaradas residuales (erupciones de fuego desde grietas, aleatorias)
- Tormenta de ceniza (periodica, danio + ceguera)

**Referencia**: Dark Souls 3 Kiln of the First Flame, Elden Ring Caelid, Dark Souls Ash Lake, NieR Automata (desolacion)

**Rango de pisos**: 40-60, 80-95

---

### 21. Mundo Espejo / Realidad Invertida

**Descripcion**: El piso es un reflejo distorsionado de un bioma ya visitado. Todo se ve "casi" igual pero algo esta MAL. Los colores estan levemente apagados, las proporciones son ligeramente incorrectas, los NPCs tienen dialogos que no tienen sentido. Un bioma del "Uncanny Valley".

**Mecanica ambiental**: **Inversiones** — las reglas del bioma original estan invertidas. Si era la Pradera: la hierba dano, el agua cura. Si era el Volcan: la lava cura pero el agua dano. Los jugadores deben recordar el bioma original y pensar al reves. Ademas, la direccion de movimiento se invierte periodicamente (arriba es abajo, izquierda es derecha) por 5 segundos.

**Paleta de colores**: Versiones desaturadas del bioma original, con tinte rojo/violeta

**Enemigos tematicos**:
- Doppelgangers (copias de los jugadores con habilidades invertidas)
- Espejo roto (fragmentos voladores que reflejan ataques)
- NPC corrompidos (NPCs amigables de pisos anteriores, ahora hostiles)
- El Otro (boss, reflejo del jugador mas fuerte del grupo)

**POIs**:
- Espejo intacto (portal de vuelta a la version normal — shortcut)
- Tienda invertida (compras con HP en vez de oro, vende items unicos)
- Altar de la verdad (revela el camino correcto del piso)
- Grieta en la realidad (mini-event, lore sobre la torre)

**Peligros ambientales**:
- Inversiones de controles (periodicas, 5 seg, desorientantes)
- Reflejos hostiles (tu reflejo te ataca si te quedas quieto mucho tiempo)
- Suelo falso (parece solido, no lo es — y viceversa)
- Desorientacion auditiva (sonidos vienen de la direccion opuesta)

**Referencia**: Noita Parallel Worlds, Zelda Link Between Worlds (Dark World), Silent Hill (Otherworld), Stranger Things (Upside Down)

**Rango de pisos**: 50-70 (solo aparece despues del midpoint)

---

### 22. Laboratorio Arcano

**Descripcion**: Un centro de investigacion magica donde los creadores de la torre experimentaban. Tubos de ensayo gigantes con criaturas preservadas, circulos de invocacion en el suelo, estanterias con tomos flotantes, energia arcana fluyendo por conductos en las paredes. La magia aqui es TANGIBLE.

**Mecanica ambiental**: **Inestabilidad magica** — la magia es 30% mas potente PERO hay un 15% de chance de "misfire" (el hechizo sale con efecto aleatorio). Las pociones tienen efecto doble. Los circulos de invocacion se pueden activar para invocar aliados temporales O enemigos (50/50 si no es un Mago). Los Magos pueden controlar los circulos.

**Paleta de colores**: Azul arcano, dorado runico, verde alquimia, purpura energia

**Enemigos tematicos**:
- Experimento fallido (aberraciones, ataques erraticos, impredecibles)
- Automoton arcano (constructo magico, resistente a fisica)
- Familiar salvaje (elemental desbocado, cambia de elemento)
- Archimago loco (boss, humanoide, patrones complejos de hechizos)

**POIs**:
- Mesa de alquimia (crafting avanzado, pociones raras)
- Biblioteca arcana (aprender hechizo temporal del run)
- Circulo de invocacion (invocar aliado temporal o enemigo)
- Sala de contención (bestia encerrada: liberarla = fight + loot, dejarla = safe)

**Peligros ambientales**:
- Zonas de magia inestable (misfires mas frecuentes)
- Circulos de invocacion activos (spawnean enemigos periodicamente)
- Tubos rotos (liberan sustancias al pasar: buff o debuff aleatorio)
- Trampas arcanas (runas en el suelo, diferentes efectos)

**Referencia**: Noita Temple of the Art / The Laboratory, DanMachi pisos 51-57 (laberinto artificial), Diablo 2 Arcane Sanctuary

**Rango de pisos**: 35-55, 70-90

---

### 23. Pradera Marchita (Variante Late-game)

**Descripcion**: La misma Pradera del inicio... pero muerta. La hierba es gris, los arboles estan sin hojas, el diamante del techo esta agrietado y emite luz intermitente. Los mismos POIs del piso 1, pero corrompidos. PODEROSO emocionalmente para jugadores que recuerdan el inicio.

**Mecanica ambiental**: **Eco del pasado** — los enemigos de este bioma son versiones mejoradas de los enemigos del piso 1. Los slimes ahora son Slimes de Vacio. Los lobos son Lobos Espectrales. El jugador reconoce los patrones pero con nuevas mecanicas encima. La nostalgia es un arma de diseno.

**Paleta de colores**: Gris ceniza, verde apagado, dorado opaco, negro grieta

**Enemigos tematicos**:
- Versiones corrompidas de TODOS los enemigos de Pradera (mismos patrones base, nuevas habilidades)
- Eco del jugador (fantasma de un "run anterior", NPC hostil con gear aleatorio)
- Nada (zonas donde la realidad se disuelve, danio al estar dentro)

**POIs**:
- Los mismos POIs de la Pradera, pero rotos/corrompidos
- Tumba del primer aventurero (lore del prologo)
- Grieta dimensional (acceso al Piso Final si se cumplen condiciones)

**Peligros ambientales**:
- Los mismos que Pradera pero amplificados
- Zonas de nada (danio constante, disolucion visual)
- Nostalgia (efecto cosmetico: flashbacks del piso 1)

**Referencia**: Dark Souls 3 Untended Graves / Cemetery of Ash (loop narrativo), Chrono Trigger "Day of Lavos" (misma locacion, diferente contexto)

**Rango de pisos**: 75-90 (solo late-game)

---

### 24. Santuario del Umbral (Piso Final)

**Descripcion**: El ultimo espacio antes del boss final de la torre. No es un bioma natural — es un CONSTRUCTO. Geometria perfecta, simetria absoluta, pisos de marmol blanco y negro, columnas infinitas, un cielo que es un espejo. Aqui las reglas de la torre se revelan. Es un templo al poder que creo la torre.

**Mecanica ambiental**: **Perfeccion** — no hay aleatoriedad. Cada enemigo esta colocado intencionalmente. No hay trampas — solo combate puro. Las stats del jugador se normalizan parcialmente (el over-leveling ayuda menos). Es la prueba final de HABILIDAD, no de grind. Los buffs ambientales de otros biomas se desactivan.

**Paleta de colores**: Blanco marmol, negro obsidiana, dorado divino, plateado espejo

**Enemigos tematicos**:
- Guardian del Umbral (boss gauntlet: 3 mini-bosses antes del final)
- Ecos de todos los pisos (enemigos seleccionados de cada bioma visitado)
- El Arquitecto (boss final, creador de la torre, multiples fases)

**POIs**:
- Altar de preparacion (ultimo chance para heal/buff antes del boss)
- Mural de la torre (resumen visual del run del jugador — pisos visitados, muertes, kills)
- Sala del juicio (prueba opcional para buff final)

**Peligros ambientales**:
- Ninguno ambiental — todo el peligro viene de los enemigos
- El propio boss final

**Referencia**: Risk of Rain 2 Commencement, Dark Souls Kiln of the First Flame, SAO Ruby Palace (Piso 100)

**Rango de pisos**: 100 (fijo, siempre)

---

### 25. Sabana Seca

**Descripcion**: Llanuras de hierba alta seca, acacias dispersas, cielo despejado con calor abrasador. Termiteros gigantes que funcionan como estructuras explorables. Grietas en el suelo seco. Sensacion de extension — todo se ve desde lejos, la sigil es posible pero el escape no.

**Mecanica ambiental**: **Campo abierto** — no hay cobertura natural. Los enemigos te ven desde lejos (rango de deteccion 2x). Pero vos tambien los ves a ellos. El combate favorece builds de largo alcance (Archer, Mage). Los melee sufren cerrando distancia. La hierba alta permite stealth si te agachas.

**Paleta de colores**: Amarillo paja, naranja atardecer, marron seco, azul cielo limpio

**Enemigos tematicos**:
- Hienas de manada (rapidas, atacan en grupo de 4-6, flanquean)
- Rinoceronte blindado (carga en linea recta, danio devastador si conecta)
- Buitre sombrio (volador, debuff "Marked" — otros enemigos priorizan al marcado)
- Leon espectral (boss de bioma, ataques de area, rugido que aturde)

**POIs**:
- Termitero gigante (mini-dungeon, loot de insectos, recursos)
- Abrevadero (safe zone, reduce deshidratacion)
- Campamento de cazadores (NPC mercader, quest de caza)
- Arbol solitario (punto de observacion, revela mapa)

**Peligros ambientales**:
- Incendio de pradera (fuego que se propaga por la hierba seca, danio de area)
- Calor (deshidratacion como en Desierto pero mas leve)
- Estampida (evento: manada de animales cruza, danio masivo si estas en el camino)
- Grietas en el suelo (caida a cueva subterranea)

**Referencia**: SAO Piso 2 (savanna), Valheim Plains (campo peligroso), Monster Hunter (biomas abiertos)

**Rango de pisos**: 5-25, 55-70

---

## C. Sistema de Adyacencia Tematica

### Principio fundamental

La transicion entre biomas debe sentirse NATURAL. Un jugador nunca deberia pasar de un desierto abrasador directamente a una tundra congelada. Siempre debe haber un bioma de transicion intermedio. Esto esta inspirado en como Minecraft maneja sus biomas con parametros de temperatura/humedad.

### Ejes de clasificacion

Cada bioma se clasifica en dos ejes:

**Temperatura**: Congelante (-2) / Frio (-1) / Templado (0) / Calido (+1) / Abrasador (+2)
**Humedad**: Arido (-2) / Seco (-1) / Normal (0) / Humedo (+1) / Saturado (+2)

| Bioma | Temperatura | Humedad |
|-------|-------------|---------|
| Pradera Interior | 0 (Templado) | 0 (Normal) |
| Bosque Denso | 0 (Templado) | +1 (Humedo) |
| Cavernas de Cristal | -1 (Frio) | 0 (Normal) |
| Pantano Putrefacto | +1 (Calido) | +2 (Saturado) |
| Tundra Congelada | -2 (Congelante) | -1 (Seco) |
| Volcan Activo | +2 (Abrasador) | -2 (Arido) |
| Ruinas Antiguas | 0 (Templado) | -1 (Seco) |
| Desierto Abrasador | +2 (Abrasador) | -2 (Arido) |
| Oceano Sumergido | 0 (Templado) | +2 (Saturado) |
| Plataformas del Cielo | -1 (Frio) | 0 (Normal) |
| Selva Tropical | +1 (Calido) | +2 (Saturado) |
| Forja Infernal | +2 (Abrasador) | -1 (Seco) |
| Catacumbas | 0 (Templado) | -1 (Seco) |
| Jardin Corrompido | 0 (Templado) | +1 (Humedo) |
| Dimension Astral | N/A | N/A |
| Abismo Abismal | -1 (Frio) | +1 (Humedo) |
| Ciudad Abandonada | 0 (Templado) | 0 (Normal) |
| Bosque de Hongos | 0 (Templado) | +2 (Saturado) |
| Templo del Reloj | 0 (Templado) | 0 (Normal) |
| Playa de Ceniza | +1 (Calido) | -2 (Arido) |
| Mundo Espejo | Hereda del bioma reflejado | Hereda |
| Laboratorio Arcano | 0 (Templado) | 0 (Normal) |
| Pradera Marchita | 0 (Templado) | -1 (Seco) |
| Santuario del Umbral | N/A | N/A |
| Sabana Seca | +1 (Calido) | -1 (Seco) |

### Regla de adyacencia

**La diferencia maxima permitida entre dos biomas consecutivos es de 2 puntos en cada eje (temperatura Y humedad).**

Esto significa:
- Pradera (0,0) puede ir a Bosque Denso (0,+1): diferencia (0,1) -- PERMITIDO
- Pradera (0,0) puede ir a Volcan (+2,-2): diferencia (2,2) -- LIMITE, PERMITIDO pero raro
- Tundra (-2,-1) NO puede ir a Volcan (+2,-2): diferencia (4,1) -- PROHIBIDO
- Tundra (-2,-1) puede ir a Cavernas (-1,0): diferencia (1,1) -- PERMITIDO

### Excepciones a la adyacencia

1. **Dimension Astral y Mundo Espejo**: son "comodines" — pueden aparecer despues de CUALQUIER bioma. Representan rupturas en la realidad de la torre.

2. **Pisos de boss**: el piso de boss siempre es una arena tematica del bioma actual. No es un bioma separado.

3. **Pisos de descanso/taverna**: son biomas neutrales (Templado, Normal) que resetean la cadena de adyacencia. Despues de una taverna, CUALQUIER bioma templado puede seguir.

4. **Santuario del Umbral**: siempre es piso 100, sin restriccion de adyacencia.

5. **Pradera Marchita**: solo aparece en late-game (75+) y puede seguir a cualquier bioma como "shock emocional" intencional.

### Grafo de adyacencia (simplificado)

```
CADENAS NATURALES (caminos comunes que el generador favorece):

Pradera → Sabana → Desierto → Volcan → Forja
Pradera → Bosque → Selva → Pantano → Oceano
Pradera → Bosque → Hongos → Catacumbas → Abismo
Cavernas → Tundra → Plataformas Cielo → Dimension Astral
Ruinas → Ciudad → Catacumbas → Abismo
Sabana → Playa Ceniza → Ruinas → Laboratorio
Bosque → Jardin Corrompido → Hongos → Pantano
Ciudad → Templo Reloj → Laboratorio → Dimension Astral
Cualquier bioma → [Taverna] → Cualquier bioma templado
Cualquier bioma → Dimension Astral → Cualquier bioma
Cualquier bioma → Mundo Espejo → (se refleja el bioma anterior)
```

### Cadenas tematicas sugeridas por rango de dificultad

**Pisos 1-20 (Tutorial/Early game)**:
Pradera → Sabana → Bosque → Hongos → Selva

**Pisos 21-40 (Mid-early)**:
Cavernas → Tundra → Pantano → Oceano → Desierto

**Pisos 41-60 (Midgame)**:
Volcan → Forja → Ruinas → Ciudad → Playa Ceniza

**Pisos 61-80 (Late-mid)**:
Jardin Corrompido → Catacumbas → Abismo → Dimension Astral → Mundo Espejo

**Pisos 81-99 (Endgame)**:
Templo Reloj → Laboratorio → Pradera Marchita → Abismo → Dimension Astral

**Piso 100 (Final)**:
Santuario del Umbral (fijo)

**Nota**: estas son cadenas SUGERIDAS. El generador procedural las usa como peso estadistico, no como regla rigida. Un run puede tener Volcan en piso 15 si la seed lo determina, siempre que la adyacencia con el bioma anterior sea valida.

---

## D. Estructura de la Torre (100 Pisos)

### Pisos fijos vs aleatorios

| Tipo | Pisos | Descripcion |
|------|-------|-------------|
| **Fijos** | 1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 | Siempre el mismo tipo (tutorial, boss, midpoint, final) |
| **Semi-fijos** | 9, 19, 29, 39, 49, 59, 69, 79, 89, 99 | Siempre taverna/descanso, pero layout aleatorio |
| **Aleatorios** | Todos los demas | Bioma, layout, enemigos, loot determinados por seed |

### Mapa completo de la torre

```
Pisos 1-10: INTRODUCCION (La Puerta)
├── Piso 1:  [FIJO] Pradera Interior — tutorial, enemigos debiles, introduccion de controles
├── Piso 2:  [ALEATORIO] bioma temprano (Pradera/Sabana/Bosque)
├── Piso 3:  [ALEATORIO] bioma temprano
├── Piso 4:  [ALEATORIO] bioma temprano
├── Piso 5:  [ALEATORIO] bioma temprano (primera mecanica ambiental compleja)
├── Piso 6:  [ALEATORIO] bioma temprano
├── Piso 7:  [ALEATORIO] bioma temprano
├── Piso 8:  [ALEATORIO] bioma temprano
├── Piso 9:  [FIJO-TIPO] Taverna — descanso, tienda, reparacion
└── Piso 10: [FIJO-TIPO] Boss del Primer Tramo

Pisos 11-20: DESPERTAR (El Ascenso)
├── Piso 11-18: [ALEATORIO] biomas intermedios tempranos
├── Piso 19: [FIJO-TIPO] Taverna
└── Piso 20: [FIJO-TIPO] Boss del Segundo Tramo

Pisos 21-30: PRUEBA (El Desafio)
├── Piso 21-28: [ALEATORIO] biomas intermedios
├── Piso 25: [EVENTO] primer piso de evento posible (raro)
├── Piso 29: [FIJO-TIPO] Taverna
└── Piso 30: [FIJO-TIPO] Boss del Tercer Tramo

Pisos 31-40: DOMINIO (La Forja)
├── Piso 31-38: [ALEATORIO] biomas intermedios-avanzados
├── Piso 35: [EVENTO] segundo piso de evento posible
├── Piso 39: [FIJO-TIPO] Taverna
└── Piso 40: [FIJO-TIPO] Boss del Cuarto Tramo

Pisos 41-50: QUIEBRE (El Abismo)
├── Piso 41-48: [ALEATORIO] biomas avanzados, composicion de biomas empieza
├── Piso 45: [EVENTO] tercer piso de evento posible
├── Piso 49: [FIJO-TIPO] Taverna — ultima antes del midpoint
└── Piso 50: [FIJO] MIDPOINT BOSS — cambia las reglas del juego
         • Nuevo tipo de enemigo global aparece (Corrupcion)
         • Biomas pueden fusionarse a partir de aqui
         • Difficulty spike intencional

Pisos 51-60: RENACIMIENTO (La Otra Torre)
├── Piso 51-58: [ALEATORIO] biomas avanzados, fusiones posibles
├── Piso 55: [EVENTO] cuarto piso de evento posible
├── Piso 59: [FIJO-TIPO] Taverna
└── Piso 60: [FIJO-TIPO] Boss del Sexto Tramo

Pisos 61-70: RESISTENCIA (La Tormenta)
├── Piso 61-68: [ALEATORIO] biomas tardios, fusiones comunes
├── Piso 65: [EVENTO] quinto piso de evento posible
├── Piso 69: [FIJO-TIPO] Taverna
└── Piso 70: [FIJO-TIPO] Boss del Septimo Tramo

Pisos 71-80: DESESPERACION (El Precio)
├── Piso 71-78: [ALEATORIO] biomas tardios + variantes corrompidas
├── Piso 75: [EVENTO] sexto piso de evento, Pradera Marchita posible
├── Piso 79: [FIJO-TIPO] Taverna
└── Piso 80: [FIJO-TIPO] Boss del Octavo Tramo

Pisos 81-90: ASCENSION (El Umbral)
├── Piso 81-88: [ALEATORIO] biomas finales, fusiones complejas, variantes
├── Piso 85: [EVENTO] septimo piso de evento posible
├── Piso 89: [FIJO-TIPO] Taverna — ultima antes del final
└── Piso 90: [FIJO-TIPO] Boss del Noveno Tramo

Pisos 91-100: APOTEOSIS (El Final)
├── Piso 91-98: [ALEATORIO] biomas finales, maxima dificultad
├── Piso 95: [EVENTO] posible piso de evento final
├── Piso 99: [FIJO-TIPO] Taverna final — ultimo respiro
└── Piso 100: [FIJO] Santuario del Umbral — Boss Final
```

### Pisos de Descanso / Taverna

- **Ubicacion**: pisos 9, 19, 29, 39, 49, 59, 69, 79, 89, 99
- **Funcion**: zona segura sin enemigos. El jugador puede:
  - Reparar equipo
  - Comprar/vender en tienda (inventario del NPC varia por seed)
  - Guardar progreso del run
  - Comunicarse con el equipo sin presion
  - Cambiar habilidades/builds
- **Estetica**: una version pequena de la Taberna principal, pero dentro de la torre. Un NPC de la Asesora del Gremio da pistas sobre el proximo tramo.
- **Duracion esperada**: 3-5 minutos
- **Inspiracion**: DanMachi Piso 18 "Under Resort" (safe zone dentro del dungeon), Noita Holy Mountains

### Pisos de Boss

- **Ubicacion**: pisos 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
- **Estructura**: arena cerrada, sin exploracion. El piso es la arena del boss.
- **Mecanicas de boss** por tramo:

| Piso | Boss Tier | Mecanicas |
|------|-----------|-----------|
| 10 | Tutorial Boss | 1 fase, patrones simples, telegrafos claros, 1 mecanica unica |
| 20 | Intermediate | 2 fases, adds en fase 2, 2 mecanicas |
| 30 | Skilled | 2 fases, mecanica de posicionamiento, requiere esquivar |
| 40 | Advanced | 2 fases, mecanica de equipo (alguien debe distraer, otro ataca) |
| 50 | MIDPOINT | 3 fases, mecanicas de equipo obligatorias en co-op, solo = endurance |
| 60 | Expert | 2 fases + enrage timer, DPS check |
| 70 | Master | 3 fases, mecanicas de bioma en la arena, ambiente cambia |
| 80 | Legendary | 3 fases, el boss usa habilidades de jugadores, adapta tactica |
| 90 | Mythic | 3 fases, mecanica de "puzzle + combate", fase final cambia las reglas |
| 100 | THE ARCHITECT | 4 fases, cada fase un bioma diferente, resumen de todo el juego |

### Pisos de Evento

- **Ubicacion**: pisos 25, 35, 45, 55, 65, 75, 85, 95 (no todos se activan)
- **Probabilidad**: cada piso de evento tiene 40% de chance de activarse en un run
- **Tipos de eventos**:

| Evento | Descripcion | Efecto |
|--------|-------------|--------|
| **Mercader Errante** | NPC raro con items unicos | Items exclusivos de evento, precios altos |
| **Arena del Gladiador** | Oleadas de enemigos, recompensas por oleada | Loot escalado, riesgo/recompensa |
| **Puzzle Room** | Piso sin combate, solo puzzles ambientales | Recompensa de XP y loot raro |
| **Invasion** | El bioma actual es "invadido" por enemigos de otro bioma | Dificultad extra, loot extra |
| **NPC Quest** | Un NPC pide ayuda especifica | Recompensa unica, lore |
| **Treasure Vault** | Piso lleno de cofres pero con trampa de tiempo | Speed run: agarra lo que puedas en 2 min |
| **Rift** | Portal a una version mini de un bioma futuro | Preview del bioma, loot temprano |
| **Recuerdo** | Flashback: juegas un piso como otro personaje/clase | Lore, perspectiva diferente, recompensa de XP |

### Pisos Estacionales (fuera de la estructura base)

Para eventos de temporada (Halloween, Navidad, etc.), se puede insertar un piso especial en cualquier posicion de evento:
- **Halloween**: Bioma de cementerio horror, enemigos especiales, cosmeticos
- **Invierno**: Bioma de fiesta invernal, jefe Snowman, cosmeticos
- **Aniversario**: Bioma meta (referencias al desarrollo del juego)

### Curva de escalado de enemigos

La formula de escalado usa progresion exponencial suave. Base multiplicada por factor de piso.

```
HP_enemigo  = HP_base  * (1 + (piso - 1) * 0.08)
DMG_enemigo = DMG_base * (1 + (piso - 1) * 0.06)
DEF_enemigo = DEF_base * (1 + (piso - 1) * 0.05)
VEL_enemigo = VEL_base * (1 + min(piso - 1, 50) * 0.01)  # cap en +50% velocidad
```

**Tabla de referencia (enemigo base: Slime)**:

| Piso | HP | Danio | DEF | Velocidad |
|------|----|-------|-----|-----------|
| 1 | 100 | 10 | 0 | 3.0 m/s |
| 10 | 172 | 15.4 | 2.3 | 3.27 m/s |
| 20 | 252 | 21.4 | 4.8 | 3.57 m/s |
| 30 | 332 | 27.4 | 7.3 | 3.87 m/s |
| 40 | 412 | 33.4 | 9.8 | 4.17 m/s |
| 50 | 492 | 39.4 | 12.3 | 4.47 m/s |
| 60 | 572 | 45.4 | 14.8 | 4.50 m/s |
| 70 | 652 | 51.4 | 17.3 | 4.50 m/s |
| 80 | 732 | 57.4 | 19.8 | 4.50 m/s |
| 90 | 812 | 63.4 | 22.3 | 4.50 m/s |
| 100 | 892 | 69.4 | 24.8 | 4.50 m/s |

**Bosses**: HP x5, DMG x2, DEF x2.5 respecto al enemigo base del piso.

**Nota**: la velocidad tiene un cap para evitar que enemigos tardios sean imposibles de reaccionar. La dificultad tardía viene de MECANICAS, no de stats inflados.

### Rangos de dificultad y expectativa de jugador

| Rango | Pisos | Nombre | Expectativa |
|-------|-------|--------|-------------|
| **Aprendiz** | 1-10 | Tutorial | Aprender controles, mecanicas basicas, primer boss |
| **Aventurero** | 11-20 | Early | Familiarizarse con biomas, builds, sinergias basicas |
| **Veterano** | 21-30 | Mid-early | Dominar mecanicas ambientales, primeros challenges reales |
| **Experto** | 31-40 | Mid | Composicion de equipo importa, gear matters |
| **Maestro** | 41-50 | Mid-late | Preparacion para el midpoint, optimizacion de build |
| **Leyenda** | 51-60 | Late-early | Biomas fusionados, nuevas amenazas, adaptacion |
| **Mito** | 61-70 | Late | Cada error se paga caro, cooperacion critica |
| **Ascendido** | 71-80 | Late-hard | Variantes corrompidas, presion constante |
| **Trascendido** | 81-90 | Endgame | Solo los mejores llegan aqui |
| **Inmortal** | 91-100 | Final | La prueba definitiva |

---

## E. Sistema de Seeds

### Que define la seed

Una seed es un numero de 64 bits que alimenta TODOS los generadores aleatorios del run. De una seed se derivan:

1. **Orden de biomas**: que bioma aparece en cada piso (respetando reglas de adyacencia)
2. **Layout de cada piso**: la generacion procedural del mapa usa la seed como input
3. **Spawn de enemigos**: cantidad, tipo, posicion inicial
4. **Distribucion de loot**: que cofres aparecen, que contienen
5. **Eventos**: que pisos de evento se activan, cual evento es
6. **Tienda de taverna**: inventario del NPC mercader
7. **Comportamiento ambiental**: timing de tormentas, erupciones, etc.

### Seed compuesta

La seed principal genera sub-seeds para cada sistema:

```
seed_principal = hash_64(input_seed)
seed_biomas    = hash_64(seed_principal + "biomes")
seed_layout    = hash_64(seed_principal + "layout" + piso_actual)
seed_enemigos  = hash_64(seed_principal + "enemies" + piso_actual)
seed_loot      = hash_64(seed_principal + "loot" + piso_actual)
seed_eventos   = hash_64(seed_principal + "events")
seed_tienda    = hash_64(seed_principal + "shop" + piso_taverna)
seed_ambiente  = hash_64(seed_principal + "environment" + piso_actual)
```

### Interfaz de seed

- **Seed aleatoria**: por defecto, cada run genera una seed aleatoria
- **Seed manual**: el jugador puede ingresar una seed alfanumerica
- **Seed compartida**: despues de un run, la seed se muestra en la pantalla de resultados. Se puede copiar y compartir.
- **Formato visible**: las seeds se convierten a un formato legible tipo `PRADERA-LOBO-4217` (nombre de bioma + nombre de enemigo + numero) para memorizabilidad

### Seeds especiales

| Tipo | Frecuencia | Descripcion |
|------|------------|-------------|
| **Daily Challenge** | 1 por dia | Misma seed para todos los jugadores. Leaderboard diario. Solo 1 intento. |
| **Weekly Challenge** | 1 por semana | Seed con modificadores especiales (doble danio, sin pociones, etc.) |
| **Community Seed** | Mensual | Seed votada por la comunidad, con condiciones especiales |
| **Dev Seed** | Especial | Seeds con Easter eggs, puestas por los developers |
| **Nightmare Seed** | Siempre disponible | Seed conocida por ser extremadamente dificil |

### Reproducibilidad

La misma seed SIEMPRE genera el mismo run si:
- Misma version del juego
- Mismo numero de jugadores (el numero de jugadores NO cambia la generacion — la dificultad es fija)

Esto es critico para competitividad y para compartir experiencias.

---

## F. Rejugabilidad

### Que cambia entre runs

| Sistema | Cambia | Como |
|---------|--------|------|
| Orden de biomas | Si | Determinado por seed, siempre diferente |
| Layout de pisos | Si | Generacion procedural por seed |
| Enemigos | Si | Tipos y posiciones varian por seed |
| Loot | Si | Items en cofres varian por seed |
| Eventos | Si | 40% de chance por piso de evento, diferentes cada run |
| Tienda de taverna | Si | Inventario varia por seed |
| Clima/ambiente | Si | Timing y intensidad de fenomenos por seed |
| Ruta de biomas | Si | Cadena de biomas diferente cada run |

### Que NO cambia entre runs

| Sistema | Permanente | Razon |
|---------|-----------|-------|
| Controles | Siempre igual | Muscle memory es sagrada |
| Mecanicas de clase | Siempre igual | Mastery del jugador |
| Reglas de bioma | Siempre igual | Aprendizaje transferible |
| Patrones de boss | Siempre igual | Skill check, no RNG check |
| Progresion de personaje | Persistente | Niveles y stats son del personaje, no del run |
| Taverna | Siempre accesible | Inventario seguro permanente |

### Sistemas anti-fatiga

**1. Composicion de biomas (piso 50+)**
A partir del midpoint, dos biomas pueden fusionarse. Esto genera combinaciones unicas:
- Bosque + Tundra = Bosque Nevado (arboles con nieve, visibilidad reducida + hipotermia)
- Volcan + Oceano = Abismo Termal (cuevas con geyser, vapor, agua caliente)
- Catacumbas + Laboratorio = Cripta Arcana (undead + magia, enemigos hibridos)
- Pantano + Hongos = Ciénaga Fungi (triple debuff zone, esporas + veneno + slow)

Esto da **~150+ combinaciones posibles** de los 25 biomas base. La rejugabilidad se multiplica exponencialmente.

**2. Modificadores de bioma (aleatorios)**
Cada piso tiene 20% de chance de tener un modificador:
- **Doble loot**: mas cofres, mas items
- **Elite enemies**: enemigos mas fuertes pero loot premium
- **Pacifist**: no hay enemigos, solo trampas y puzzles
- **Speed run**: timer, recompensa por completar rapido
- **Fog of war**: mapa no se revela, exploracion total
- **Friendly fire+**: danio de fuego amigo x2 (riesgo extremo en co-op)

**3. Progresion persistente del personaje**
Aunque el loot del run se pierde al morir, el personaje conserva:
- Nivel y stat points
- Skills desbloqueados
- Recetas aprendidas
- Bestiary (enemigos descubiertos)
- Logros/achievements

**4. Sistema de "First Clear" vs "Farming"**
- **First clear**: primera vez que un personaje supera un piso. Recompensa bonus de XP y loot unico.
- **Farming run**: correr pisos ya superados por loot. XP reducida, pero loot normal.
- **Sprint mode**: empezar un run desde un piso ya superado (ej: empezar en piso 30 si ya pasaste el boss del piso 30). Reduce grind pero perdes loot de pisos anteriores.

**5. Leaderboards**

| Tipo | Metrica | Scope |
|------|---------|-------|
| **Piso maximo** | Piso mas alto alcanzado | Global, por clase |
| **Speed run** | Tiempo total del run | Por seed (daily/weekly) |
| **Kill count** | Enemigos eliminados en un run | Global |
| **No-death** | Pisos completados sin morir | Global |
| **Solo** | Piso maximo en solitario | Global, por clase |
| **Group** | Piso maximo en grupo de 6 | Global |

---

## G. Mecanicas Ambientales por Bioma

### Lista completa de mecanicas ambientales

| Mecanica | Biomas | Efecto en movimiento | Efecto en visibilidad | Efecto en combate | Interaccion con clases |
|----------|--------|---------------------|----------------------|-------------------|----------------------|
| **Viento variable** | Pradera, Sabana | Empuje lateral | Ninguno | Desvía proyectiles | Mago/Archer afectados; Warrior inmune |
| **Visibilidad reducida** | Bosque, Pantano | Ninguno | 8-10m rango | Emboscadas posibles | Todos afectados; antorchas ayudan |
| **Refraccion de luz** | Cristal | Ninguno | Distorsion de sombras | Ataques magicos rebotan | Mago se beneficia (rebote controlado) |
| **Terreno traicionero** | Pantano | Slow 40% en fango | Ninguno | Melee afectado (acercarse es dificil) | Necro beneficiado (minions tanquean) |
| **Hipotermia** | Tundra | Slow progresivo | Ninguno | Velocidad ataque reducida | Mago (fuego) se mitiga; Warrior vulnerable |
| **Calor extremo** | Volcan, Desierto | Stamina reducida | Ceniza/calima leve | Regen reducida | Mago (hielo) se beneficia |
| **Trampas mecanicas** | Ruinas | Rutas limitadas | Ninguno | Trampas usables contra enemigos | Archer/Rogue detectan mejor |
| **Deshidratacion** | Desierto, Sabana | Sprint limitado | Ninguno | Stamina reducida | Healer puede crear agua |
| **Oxigeno** | Oceano | -40% bajo agua | Ninguno | Fuego no funciona bajo agua; rayo AoE | Mago (rayo) peligroso para aliados |
| **Vacio mortal** | Cielo, Astral | Caida = muerte | Ninguno | Knockback es letal | Warrior (knockback resist) ventaja |
| **Rayos periodicos** | Cielo | Ninguno | Destellos | Danio de area, armadura atrae | Clases ligeras mejor; tanques vulnerables |
| **Verticalidad** | Selva, Ciudad | 3 niveles, trepar | Dosel bloquea | Combate en multiples capas | Archer domina (alto ground) |
| **Lluvia constante** | Selva, Bosque | Superficies resbaladizas | Reducida | Fuego -50% efectividad | Mago (hielo/rayo) se beneficia |
| **Maquinaria** | Forja | Plataformas moviles | Ninguno | Timing de maquinas | Todos igual, requiere skill |
| **Oscuridad** | Catacumbas, Abismo | Ninguno | 3-5m con luz | Precision -50% sin luz | Necro +30% poder; otros necesitan luz |
| **Corrupcion** | Jardin, Marchita | Ninguno | Distorsion progresiva | Stats reducidos | Healer puede purificar |
| **Gravedad alterada** | Astral | Saltos 2x, cambios | Ninguno | Proyectiles afectados | Todos afectados; adaptacion constante |
| **Cordura** | Abismo | Eventual mov. erratico | Alucinaciones | Precision reducida | Co-op mitiga; Healer limpia |
| **Esporas activas** | Hongos | Suelo esponjoso (slow) | Partículas | Buff/debuff segun color | Mago dispersa; Warrior ignora esporas |
| **Zonas temporales** | Reloj | Slow/fast zones | Ninguno | DPS variable por zona | Todos igual; posicionamiento clave |
| **Desolacion** | Ceniza | Ninguno | Leve ceniza | SIN regeneracion natural | Healer CRITICO |
| **Inversiones** | Espejo | Controles invertidos | Desaturacion | Reglas invertidas | Todos afectados; memoria importa |
| **Inestabilidad magica** | Laboratorio | Ninguno | Particulas arcanas | Magia +30% pero 15% misfire | Mago beneficiado y arriesgado |
| **Combate urbano** | Ciudad | Cobertura, flanqueo | Edificios bloquean | Tacticas de equipo | Archer (techo), Warrior (calles) |
| **Campo abierto** | Sabana | Sin cobertura | Todo visible | Rango 2x deteccion | Archer domina; melee vulnerable |
| **Perfeccion** | Umbral | Normal | Normal | Sin buffs ambientales | Pura habilidad |

### Sinergias clase-bioma destacadas

| Clase | Mejor bioma | Peor bioma | Por que |
|-------|-------------|------------|---------|
| **Warrior** | Catacumbas (melee corridors), Ciudad (cobertura) | Cielo (knockback letal), Sabana (sin cobertura) | Necesita acercarse pero no ser empujado |
| **Mage** | Laboratorio (+30% magia), Cristal (rebotes) | Selva (lluvia mata fuego), Oceano (fuego inutil) | Depende del elemento equipado |
| **Archer** | Sabana (campo abierto), Selva (alto ground) | Catacumbas (oscuridad), Forja (espacios cerrados) | Necesita linea de vision y distancia |
| **Necromancer** | Catacumbas (+30% invocaciones), Pantano (undead terrain) | Ceniza (sin regen para minions), Astral (gravedad afecta minions) | Minions son su fuerza; si mueren rapido, pierde |
| **Healer** | Ceniza (CRITICO, unica fuente de regen), Abismo (limpia cordura) | Laboratorio (misfire de heals), Cielo (dificil posicionar) | Es el soporte; importa donde mas se necesite |

---

## H. Anti-patterns (Lo que NO hacer)

### Investigacion: quejas comunes de los jugadores

Basado en investigacion de comunidades de Reddit, Steam, BoardGameGeek y foros de juegos:

**1. "Los pisos son todos iguales con skin diferente"**
- **Problema**: biomas que se ven diferente pero JUEGAN igual. Cambiar colores no es variedad.
- **Solucion en Dungeon Party**: cada bioma tiene una MECANICA UNICA que cambia el gameplay. La Tundra no es "Pradera pero blanca" — tiene hipotermia, hielo resbaladizo, y enemigos con slow. El jugador JUEGA DIFERENTE en cada bioma.

**2. "La dificultad solo sube numeros"**
- **Problema**: "dificultad" = enemigos con mas HP y mas danio. Es lazy design. El jugador hace lo mismo pero mas lento.
- **Solucion en Dungeon Party**: la velocidad de enemigos tiene CAP. La dificultad sube con MECANICAS nuevas, composicion de biomas, y habilidades de enemigos. El piso 80 no es "piso 10 pero con numeros x8" — es un bioma fusionado con mecanicas ambientales combinadas y enemigos con habilidades nuevas.

**3. "No hay razon para explorar"**
- **Problema**: cuando el camino optimo es ir directo al boss/salida, el jugador ignora el 80% del contenido.
- **Solucion en Dungeon Party**: POIs con loot exclusivo, shortcuts que ahorran pisos futuros, NPC quests que dan ventajas, y loot que solo aparece en areas "off the beaten path". Explorar es SIEMPRE rentable.

**4. "El multiplayer no agrega nada"**
- **Problema**: en muchos dungeon crawlers, el co-op es "single player pero hay alguien al lado". No hay razon mecanica para cooperar.
- **Solucion en Dungeon Party**: sinergias de clase (Mago + Warrior = buffs combinados), mecanicas ambientales que requieren coordinacion (alguien tanquea frio mientras otro resuelve puzzle), bosses con mecanicas de equipo, y fuego amigo que obliga a comunicarse.

**5. "Los runs son demasiado largos / demasiado cortos"**
- **Problema**: runs de 30+ horas son un compromiso enorme. Runs de 20 minutos no generan apego.
- **Solucion en Dungeon Party**: los runs son largos (20-25h totales) PERO se dividen en sesiones naturales de 1-3 horas. Cada sesion es satisfactoria por si sola (5-10 pisos, un boss, loot). El progreso se guarda. Es un maraton, no un sprint.

**6. "Las transiciones entre biomas son absurdas"**
- **Problema**: pasar de un desierto a un glaciar sin explicacion rompe la inmersion.
- **Solucion en Dungeon Party**: sistema de adyacencia con ejes de temperatura/humedad. Las transiciones son siempre graduales. Ademas, la narrativa lo justifica — cada piso es una dimension diferente conectada por la torre. La torre ES el portal.

**7. "El endgame es vacio"**
- **Problema**: despues de terminar, no hay razon para volver.
- **Solucion en Dungeon Party**: daily/weekly challenges, leaderboards, farming de loot legendario en pisos altos, nuevas clases para probar, seeds compartidas de la comunidad, y la meta de completar los 100 pisos con todas las clases.

**8. "Los biomas de agua son horribles"**
- **Problema**: NOTORIAMENTE, los niveles acuaticos son los menos populares en casi todo juego. Movimiento lento, oxigeno, combate frustante.
- **Solucion en Dungeon Party**: el bioma de Oceano es PARCIALMENTE acuatico. Hay plataformas secas. El movimiento bajo agua es lento pero las burbujas de aire son frecuentes. Se puede elegir cuanto tiempo pasar bajo agua. Y lo mas importante: el loot exclusivo acuatico es MUY bueno, asi que hay incentivo real.

### Errores de diseno a evitar

| Error | Descripcion | Ejemplo real | Nuestra prevencion |
|-------|-------------|--------------|-------------------|
| **Palette swap** | Cambiar colores sin cambiar gameplay | Muchos RPGs mobiles | Mecanica ambiental unica por bioma |
| **Number inflation** | Solo subir stats sin nuevas mecanicas | Diablo 3 Greater Rifts | Velocidad con cap, mecanicas nuevas |
| **Mandatory grind** | Obligar a repetir pisos para progresar | MMORPGs | Sprint mode, XP de first clear |
| **Dead exploration** | Areas grandes sin recompensa | No Man's Sky (launch) | POIs con loot exclusivo siempre |
| **Difficulty cliff** | Salto de dificultad sin preparacion | Many roguelikes pre-boss | Taverna antes de cada boss |
| **Co-op tax** | Mas jugadores = mas tedioso | Monster Hunter World (HP scaling) | Dificultad FIJA, no escala |
| **Tutorial overstay** | Tutorial de 2 horas | Muchos JRPGs | Tutorial es 1 piso (10 min) |
| **Asset reuse visible** | Mismos assets en todos los biomas | Juegos indie con pocos recursos | Paletas distintas + props unicos por bioma |
| **Unfair RNG** | Muerte por mala suerte, no por mala jugada | Noita (a veces) | Todas las amenazas tienen telegraph |
| **Empty difficulty tiers** | Dificultad que solo cambia numeros | Skyrim difficulty slider | Cada tier agrega mecanicas nuevas |

### Trampas de diseno que PARECEN buenas

**1. "Mas biomas = mejor"**
- Parece: mas variedad, mas contenido
- Realidad: cada bioma necesita enemigos, POIs, props, musica, SFX unicos. 50 biomas superficiales es peor que 25 biomas profundos.
- Nuestra decision: 25 biomas base, profundos, con sistema de composicion para multiplicar la variedad.

**2. "Pisos mas grandes = mejor"**
- Parece: mas exploracion, mas contenido por piso
- Realidad: pisos grandes con poco contenido se sienten vacios. Running simulator.
- Nuestra decision: pisos DENSOS pero compactos. Mejor tener un piso de 15 minutos lleno de cosas que uno de 30 minutos con la mitad vacia.

**3. "Dificultad = diversión"**
- Parece: mas dificil = mas satisfactorio
- Realidad: dificultad sin fairness = frustracion. El jugador necesita sentir que PUDO haber ganado.
- Nuestra decision: TODOS los ataques tienen telegraph. TODOS los peligros ambientales tienen aviso visual/sonoro. La muerte siempre es culpa del jugador.

**4. "Aleatoriedad total = rejugabilidad"**
- Parece: si todo es aleatorio, cada run es unico
- Realidad: demasiada aleatoriedad = falta de coherencia. Un piso de volcán con enemigos de hielo no tiene sentido.
- Nuestra decision: aleatoriedad CONTROLADA. Los biomas definen que enemigos, POIs y peligros pueden aparecer. La seed randomiza DENTRO de esas reglas.

**5. "Cuantas mas mecánicas ambientales, mejor"**
- Parece: cada bioma debería tener 5+ mecánicas únicas
- Realidad: demasiadas mecánicas por bioma = overwhelm cognitivo. El jugador no puede procesar todo.
- Nuestra decision: 1-2 mecánicas PRINCIPALES por bioma, mas peligros ambientales menores. La mecanica principal es el "gancho" del bioma.

---

## Fuentes y Referencias

### Juegos investigados

- [Dead Cells biome design and replayability](https://steamcommunity.com/app/588650/discussions/0/3766731645530968964/) — Multiple biome paths, 100+ weapons, route variety
- [Hades vs Dead Cells replayability comparison](https://kinglink-reviews.com/2020/10/27/dead-cells-vs-hades-which-is-the-better-roguelite/) — Build variety vs narrative as replay hooks
- [Risk of Rain 2 Environments](https://riskofrain2.wiki.gg/wiki/Environments) — Stage set system, loop progression, environment variety
- [Spelunky 2 biome branching and procedural generation](https://game-wisdom.com/analysis/spelunky-2) — Player choice in biome routing
- [Noita Biomes](https://noita.wiki.gg/wiki/Biomes) — Main path + side biomes, Holy Mountain separators, Wang tiles
- [Valheim biome progression](https://valheim.fandom.com/wiki/Progression_guide) — Natural difficulty gating via gear requirements
- [Minecraft world generation and biome transitions](https://www.alanzucconi.com/2022/06/05/minecraft-world-generation/) — Temperature/humidity parameters for adjacency
- [Terraria biomes and contagion](https://terraria.wiki.gg/wiki/Biomes) — Spreading biomes, biome placement rules

### Anime/media

- [Sword Art Online - Aincrad floor structure](https://swordartonline.fandom.com/wiki/Aincrad) — 100-floor tower, each floor is a unique world
- [DanMachi - Dungeon floor structure](https://danmachi.fandom.com/wiki/Dungeon) — Floor sections (upper/middle/lower/deep), safe zones, thematic areas
- [SAO Aincrad floor themes](https://swordartonline.fandom.com/wiki/Category:Floors) — Grassland, savanna, forest, lake, ruins, winter, desert, volcano themes
- [DanMachi dungeon design explained](https://gamerant.com/is-it-wrong-to-try-to-pick-up-girls-in-a-dungeon-the-dungeons-floors-explained/) — Section-based difficulty with distinct biome themes

### Design theory

- [Procedural dungeon generation algorithms](https://www.gamedeveloper.com/programming/procedural-dungeon-generation-algorithm) — BSP, cellular automata, room-based methods
- [Dungeon generation in Unexplored](https://www.boristhebrave.com/2021/04/10/dungeon-generation-in-unexplored/) — Grammar-based lock-and-key structures
- [The PCG Paradox: repetition in procedural generation](https://www.wayline.io/blog/pcg-paradox-repetition-solutions) — How procedural generation can feel repetitive and solutions
- [Procedural Generation of Dungeons (research paper)](https://www.researchgate.net/publication/260800341_Procedural_Generation_of_Dungeons) — Academic framework for dungeon PCG

### Community feedback

- [What gets boring in dungeon crawlers (BoardGameGeek)](https://boardgamegeek.com/thread/1802354/what-does-every-dungeon-crawler-do-gets-boring-and) — Player fatigue patterns
- [Dungeon crawler repetitive complaints](https://gamefaqs.gamespot.com/boards/220-rpgs-role-playing-games/61490081) — Core issues with the genre
- [Best dungeon crawlers on Steam](https://www.slant.co/topics/6422/~dungeon-crawler-games-on-steam) — What works well in reviewed games

---

## Apendice: Verificacion de Consistencia

### Check de adyacencia

Se verifico que todas las cadenas sugeridas en la seccion C respetan la regla de diferencia maxima de 2 en temperatura y humedad:

- Pradera (0,0) → Sabana (+1,-1): diff (1,1) OK
- Sabana (+1,-1) → Desierto (+2,-2): diff (1,1) OK
- Desierto (+2,-2) → Volcan (+2,-2): diff (0,0) OK
- Volcan (+2,-2) → Forja (+2,-1): diff (0,1) OK
- Pradera (0,0) → Bosque (0,+1): diff (0,1) OK
- Bosque (0,+1) → Selva (+1,+2): diff (1,1) OK
- Selva (+1,+2) → Pantano (+1,+2): diff (0,0) OK
- Pantano (+1,+2) → Oceano (0,+2): diff (1,0) OK
- Bosque (0,+1) → Hongos (0,+2): diff (0,1) OK
- Hongos (0,+2) → Catacumbas (0,-1): diff (0,3) **VIOLACION** → corregido: Hongos → Jardin Corrompido (0,+1) → Catacumbas (0,-1) = diff (0,2) OK
- Cavernas (-1,0) → Tundra (-2,-1): diff (1,1) OK
- Tundra (-2,-1) → Cielo (-1,0): diff (1,1) OK
- Cielo (-1,0) → Astral (N/A): OK (comodin)
- Ruinas (0,-1) → Ciudad (0,0): diff (0,1) OK
- Ciudad (0,0) → Catacumbas (0,-1): diff (0,1) OK
- Catacumbas (0,-1) → Abismo (-1,+1): diff (1,2) OK
- Sabana (+1,-1) → Ceniza (+1,-2): diff (0,1) OK
- Ceniza (+1,-2) → Ruinas (0,-1): diff (1,1) OK
- Ruinas (0,-1) → Laboratorio (0,0): diff (0,1) OK
- Bosque (0,+1) → Jardin Corrompido (0,+1): diff (0,0) OK
- Jardin (0,+1) → Hongos (0,+2): diff (0,1) OK
- Hongos (0,+2) → Pantano (+1,+2): diff (1,0) OK
- Ciudad (0,0) → Reloj (0,0): diff (0,0) OK
- Reloj (0,0) → Laboratorio (0,0): diff (0,0) OK
- Laboratorio (0,0) → Astral (N/A): OK (comodin)

**Cadena corregida en seccion C**: `Pradera → Bosque → Hongos → Jardin Corrompido → Catacumbas → Abismo` (agregado Jardin Corrompido como paso intermedio).

### Check de rango de pisos

Se verifico que cada rango de pisos en el catalogo de biomas no tiene "huecos" — es decir, que para cualquier piso del 1 al 100, al menos 3 biomas estan disponibles:

| Rango de pisos | Biomas disponibles (count) |
|----------------|---------------------------|
| 1-5 | 2 (Pradera, Sabana parcial) — OK, tutorial, se compensa con piso 1 fijo |
| 5-10 | 5 (Pradera, Sabana, Bosque, Hongos, Selva) |
| 10-15 | 8 (+ Cristal, Pantano, Tundra, Ruinas) |
| 15-20 | 10 (+ Desierto) |
| 20-30 | 14 (+ Oceano, Cielo, Ciudad, Catacumbas) |
| 30-40 | 16 (+ Reloj, Laboratorio) |
| 40-50 | 17 (+ Ceniza, Astral) |
| 50-60 | 18 (+ Espejo, Abismo completo) |
| 60-80 | 20+ (todos disponibles + variantes) |
| 80-100 | 20+ (todos + composiciones) |

Cobertura adecuada en todos los rangos.

### Check de mecanicas unicas

Se verifico que no hay dos biomas con la misma mecanica principal:

- Viento variable: solo Pradera
- Visibilidad reducida: Bosque (niebla) y Pantano (niebla toxica) — SIMILARES pero diferentes: Bosque es neutral, Pantano dania
- Refraccion: solo Cristal
- Terreno traicionero: solo Pantano
- Hipotermia: solo Tundra
- Calor extremo: Volcan y Desierto — SIMILARES pero diferentes: Volcan es danio directo, Desierto es deshidratacion/stamina
- Trampas mecanicas: solo Ruinas
- Deshidratacion: Desierto (principal) y Sabana (secundario, mas leve)
- Oxigeno: solo Oceano
- Vacio mortal: Cielo y Astral — SIMILARES pero diferentes: Cielo es vertical, Astral es multidireccional
- Rayos: solo Cielo
- Verticalidad: Selva (natural) y Ciudad (urbana) — SIMILARES pero contexto diferente
- Lluvia: solo Selva (constante)
- Maquinaria: solo Forja
- Oscuridad: Catacumbas (parcial) y Abismo (extrema) — escalado del mismo concepto
- Corrupcion: solo Jardin (y Marchita como variante)
- Gravedad alterada: solo Astral
- Cordura: solo Abismo
- Esporas activas: solo Hongos
- Zonas temporales: solo Reloj
- Desolacion: solo Ceniza
- Inversiones: solo Espejo
- Inestabilidad magica: solo Laboratorio
- Combate urbano: solo Ciudad
- Campo abierto: solo Sabana
- Perfeccion: solo Umbral

**Resultado**: las similitudes detectadas son intencionales (variaciones de un tema) y nunca son identicas. Cada bioma tiene una identidad mecanica clara.

---

*Documento preparado por el Departamento de Game Design. Este documento es la fuente de verdad para la estructura de la torre y el sistema de biomas. Cualquier cambio debe actualizarse aqui primero.*
