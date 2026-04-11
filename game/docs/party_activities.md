# Party Activities & Emotes — Another Party Dungeon

**Versión**: 1.0
**Fecha**: 2026-04-10
**Estado**: Design Document
**Departamento**: Game Design
**Relacionado**: `prairie_living_world.md`, `project_party_activities.md`

Este documento define la capa **social/party** del juego. Incluye minijuegos diegéticos integrados al mundo, emotes expresivos, y elementos de bonding cooperativo. Es el **pillar diferenciador** del juego vs otros dungeon crawlers coop.

---

## 1. Filosofía de diseño

### El principio fundamental

**Todo minijuego y emote debe sentirse parte del mundo.** NO hay modos arcade separados pegados al juego. Cada actividad tiene:

- **Un NPC, objeto o criatura** que la inicia
- **Un lore** que la justifica
- **Una recompensa** que encaja en el ecosistema (material, buff, título, cosmético)

### Por qué importa

Los juegos coop **no sobreviven por mecánicas** — sobreviven por **memorias sociales**. Lo que la gente recuerda de Deep Rock Galactic no es el combate, es "esa vez que nos quedamos atrapados riéndonos". Vos necesitás provocar esos momentos.

La combinación **dungeon crawl serio + actividades party diegéticas** ocupa un hueco que ningún juego del género cubre hoy.

### Posicionamiento de competencia

| Juego | Core loop | Capa social |
|-------|-----------|-------------|
| Dark and Darker | Serio, PvPvE tenso | ❌ Cero |
| Deep Rock Galactic | Serio coop | ⚠️ Básica (saludos, cervezas) |
| Lethal Company | Cómico terror | ✅ Fuerte (boombox, emotes) |
| Valheim | Survival coop | ⚠️ Media (construcción compartida) |
| **Another Party Dungeon** | Serio coop + loot | ✅✅ **Alta** — minijuegos, heists, emotes, música |

---

## 2. Minijuegos diegéticos — Los 5 tiers

### Tier 1: Heist / Stealth (robar a criaturas imposibles)

Actividades donde la amenaza es **demasiado fuerte para pelear**. Solo podés ganar con sigilo y coordinación.

#### El Huevo de la Dragona

**Ubicación**: Nido oculto en cueva del Piso 3 (Hielo).
**Setup**: La dragona Valtheria duerme sobre su nido. Un aldeano del Piso 2 cuenta el rumor.
**Mecánica**:
- Uno del party hace ruido lejos con una piedra o grito (distracción)
- Otro se acerca en modo stealth (agachado, sonido reducido)
- Tercero agarra el huevo del nido
- Cuarto cubre la retirada
- Si alguien pisa una rama o hace mucho ruido → Valtheria despierta
- **Fase 2 (persecución)**: 60 segundos para escapar de la zona. La dragona vuela persiguiéndolos con fuego. Si uno muere, los otros pueden seguir con el huevo.
**Reward**: Huevo = item único que vende caro o se puede cocinar para buff legendario
**Tone**: Tenso pero épico

#### La Flauta del Gigante Cíclope

**Ubicación**: Piso 4 (Tormenta), en la cima de una colina
**Setup**: Un cíclope duerme con una flauta mágica colgando de su cinto
**Mecánica**:
- Un jugador tiene que trepar por la espalda del gigante (stamina bar que se agota)
- Los otros hacen pantomima abajo para que si el cíclope abre un ojo, mire hacia ellos, no arriba
- Si el trepador cae o lo detectan → el cíclope los tira lejos (daño alto, no mata)
**Reward**: Flauta = item instrument, permite tocar música en grupo

#### El Tesoro de la Bruja del Bosque

**Ubicación**: Piso 1 (Pradera), cabaña oculta en el bosque
**Setup**: La bruja cocina en su caldero, la puerta trasera siempre abierta
**Mecánica**: Espionaje con líneas de visión. La bruja mira en direcciones random cada X segundos. Los jugadores se congelan cuando los mira. Uno puede distraer con voces desde fuera de la casa.
**Reward**: Recetas de alquimia, ingredientes raros

#### Las Plumas del Grifo Dorado

**Ubicación**: Piso 2 (Bosque), árbol gigante
**Setup**: Un grifo anida en lo más alto. Sus plumas son material legendario
**Mecánica**: Uno trepa (rhythm mini-game), los otros tiran piedras a otros árboles para distraer. Tiempo límite: antes del amanecer (si el sol sale, el grifo ve todo)
**Reward**: Plumas (material), posibilidad de domar al grifo (futuro: mounts)

---

### Tier 2: Chase / Catch (atrapar lo que huye)

Lo opuesto — vos tenés que atrapar algo rápido y escurridizo.

| Actividad | NPC / Rumor | Mecánica | Reward |
|-----------|-------------|----------|--------|
| **El Cerdo del Aldeano** | Campesino Horacio en la Pradera | Arrinconar al chancho entre 4 jugadores (pathfinding huye del jugador más cercano) | Comida buff + oro |
| **El Gnomo Ladrón** | Aparece random al pasar por un POI | Gnomo invisible robó un item tuyo. Deja huellas breves en el suelo. Seguirlas y rodearlo antes de su madriguera | Recuperás el item + oro del gnomo |
| **La Gallina Dorada** | Leyenda del bar del Puesto | Spawn random en praderas, super rápida, solo aparece 1 vez por día de juego. Atraparla requiere coordinación | Huevos de oro (oro directo) |
| **La Mariposa Fantasma** | Sólo de noche (futuro) | Vuela en zig-zag, desaparece y reaparece. Red de bardo necesaria | Material raro de alquimia |
| **El Caballo Fantasma** | Al atardecer, cerca del lago | Aparece, si lo montás te sacude (balance minigame). Te lleva a un lugar secreto si aguantás | Acceso a POI oculto |

---

### Tier 3: Cooperación sincronizada

Estas requieren que **todos hagan algo al mismo tiempo**. Falla uno = falla todo.

#### Cocinar un Banquete

**Ubicación**: Taverna del Puesto de Guardia, Piso 25, Piso 50
**Setup**: Un NPC chef ofrece un concurso de cocina
**Mecánica**: Tipo Overcooked minimalista, cada jugador es un rol:
- **Carnicero** — corta ingredientes crudos (rhythm)
- **Cocinero** — pone en la olla en el momento correcto
- **Servidor** — lleva los platos a la mesa del chef
- **Ayudante** — trae materiales del depósito cuando se acaban

Tiempo limitado. Si llegan a 5 estrellas, buff legendario de comida (+2 a todos los stats por 1 hora real de juego).

#### Ritual de Invocación

**Ubicación**: Altares secretos en todos los pisos
**Setup**: 4 pedestales rodean un altar central con símbolos brillantes
**Mecánica**: Cada jugador mantiene una tecla en su pedestal por 10 segundos. Si uno suelta antes, el ritual se rompe y salen 3-4 demonios menores. Si lo completan, invocan al jefe secreto del altar.
**Reward**: Loot único del jefe secreto (cosméticos, títulos, skill points raros)

#### Levantar la Estatua Caída

**Ubicación**: Ruinas random en la pradera
**Setup**: Una estatua bloquea el camino hacia un cofre
**Mecánica**: Todos mantienen E al ritmo correcto (aparece un indicador circular). Si el ritmo se rompe, la estatua cae y todos reciben daño.
**Reward**: Loot del cofre oculto debajo

#### El Puente de Hielo Frágil

**Ubicación**: Piso 3 (Hielo)
**Setup**: Puente largo y frágil. Si pasa más de un jugador a la vez, se rompe
**Mecánica**: Party coordina el orden de cruce. Si alguien se apresura, cae al vacío y pierde 1 item random del inventario
**Reward**: Acceso a otra zona del mapa

---

### Tier 3.5: Concurso de Humos de Pipa

**Ubicación**: Taverna del Puesto, cerca de la fogata (o en cualquier zona segura con fogata)
**Setup**: Un enano viejo fumador legendario reta a cualquiera que tenga pipa a un concurso de humos
**Referencia visual**: Escena icónica de El Señor de los Anillos donde Gandalf lanza un barco de humo en la fiesta de Bilbo

**Mecánica en dos fases**:

#### Fase 1: Dibujo (privado, cada jugador solo)
- Se abre una pequeña UI tipo "papel" con un canvas 2D
- El jugador tiene 60 segundos para **dibujar** lo que quiere formar con el humo (barco, dragón, espada, corazón, etc.)
- Controles simples: drag del mouse para dibujar líneas, botón para borrar, botón para confirmar
- El dibujo queda oculto hasta la fase 2

#### Fase 2: Ejecución (pública, todos miran)
- Los jugadores se turnan. Cada uno fuma la pipa (animación) y el humo sale con la FORMA que dibujaron
- Partículas volumétricas en el aire, 3D, visibles por 5-8 segundos
- Mientras se ve el humo, los demás **votan** con un sistema simple (flechas up/down o 1-5 estrellas)
- El jugador con más votos gana

**Reward del ganador**:
- Oro de la apuesta
- Título cosmético rotativo: "Maestro del Humo" (pasa al siguiente ganador en el próximo concurso)
- Un **cristal que graba su última figura** — cosmético que puede exhibir en la taverna

**Por qué es GENIAL**:
- **Expresión creativa libre** — cada partida es distinta porque los dibujos son únicos
- **Momentos virales** — la gente va a postear screenshots de barcos, dragones, cosas graciosas
- **Low-skill accessible** — no necesitás ser bueno dibujando, los votos también se ríen de dibujos malos
- **Streamer bait** — es contenido perfecto para Twitch/YouTube
- **Diegético** — hace sentido en el mundo porque la pipa mágica "lee la intención" del fumador

**Implementación técnica**:
- Canvas 2D con array de puntos que el jugador dibuja
- Los puntos se convierten en un path 3D de emisores de partículas
- Las partículas suben con forma (usando el path como guía)
- Material shader que hace el humo translúcido y gris/blanco

### Variantes futuras del concurso de humos

- **Humo de color** — con hierbas especiales, el humo sale coloreado (pipa con hoja de dragón = humo rojo)
- **Humo animado** — con pipas raras, el dibujo se MUEVE (tu barco navega)
- **Concurso grupal** — 2 jugadores dibujan juntos, sus humos se combinan en una figura colaborativa
- **Concurso por temas** — el NPC dice "esta noche es tema: animales", todos tienen que dibujar un animal

---

### Tier 4: Duelos temáticos (PvP amistoso)

Combates sin muerte real, solo por diversión y apuestas.

| Actividad | Setup | Mecánica | Reward |
|-----------|-------|----------|--------|
| **Torneo de la Taverna** | Arena de madera en el Puesto | Peleas 1v1 con armas de práctica, no daño real, 3 hits para ganar | Oro apostado + título "Campeón del Puesto" |
| **Trago del Valiente** | El alquimista ofrece una pócima experimental | Todos toman, la última persona consciente gana. Efectos random: ver doble, teleport, miniaturización, colores invertidos, etc. | Título + cosmético |
| **Concurso de Tiro** | Maestro arquero en el Puesto | Arco y blancos móviles, 10 flechas, mejor puntaje gana | Arco único + título "Ojo de Águila" |
| **Lucha de Brazos del Campeón** | 5 NPCs en diferentes pisos, cada uno más fuerte | Pulsear con cada uno progresivamente | Título final: "Brazo de Hierro" + buff permanente a STR |

---

### Tier 5: Eventos ambientales

**Cosas que pasan SIN que las busques** — aparecen si estás en el lugar correcto en el momento correcto.

#### La Fiesta del Pueblo

Llegás a una aldea que está celebrando algo (boda, cosecha, festival religioso). Música, baile, mesas con comida. Podés:
- **Unirte al baile** → buff temporal de moral (+1 luck)
- **Comer de la mesa** → restaura HP y hambre
- **Escuchar al juglar** → rumores de POIs ocultos en el mapa

#### El Concurso de Pesca del Lago

Un día específico del "mes de juego", el lago del Piso 1 tiene competencia. Pescar el pez más grande = premio.
**Reward**: Caña legendaria + título "Rey del Lago"

#### La Noche de las Estrellas Fugaces

Una vez cada X horas de juego real, cae una estrella. Si estás afuera cuando pasa, podés pedir un deseo → buff único random de 24h de juego.

#### La Carrera del Jabalí Salvaje

Un NPC cazador te propone una carrera detrás de un jabalí. Tenés que perseguirlo sin matarlo. Si llegás primero al final, ganás.

---

## 3. Casos especiales — Eventos "Heist" grandes

Algunos eventos son **mini-expediciones completas**. Diseñados para ser jugados una vez, memorables, con lore denso.

### "La Boda del Ogro"

**Ubicación**: Piso 2 (Bosque), aparece en fase lunar específica
**Setup**: Los ogros celebran una boda con un pastel legendario en el centro
**Mecánica**: La party tiene que colarse en la boda disfrazados (items de disfraz se compran en el Puesto), moverse entre ogros sin levantar sospechas, y escapar con el pastel antes que se dé cuenta la novia
**Reward**: Pastel de Ogro = buff legendario de 3h + cosmético único

### "La Apuesta del Diablo"

**Ubicación**: Taverna oculta del Piso 4
**Setup**: Un demonio elegante juega cartas en una mesa. Ofrece apuestas cada vez más altas
**Mecánica**: Juego de cartas simple (similar a Gwent ultra-básico). Las primeras apuestas son oro. Las siguientes son items. La apuesta final: un "fragmento del alma" (stat permanente vs stat permanente — podés ganar +1 STR o perder -1 VIT)
**Reward**: Stats permanentes, riesgo real

### "La Subasta del Tuerto"

**Ubicación**: Random en cualquier piso, 1 vez por ciclo
**Setup**: Un mercader misterioso con un ojo cubierto aparece con 3 items únicos
**Mecánica**: La party apuesta oro. Si hay múltiples parties en el mismo server, pueden competir por el mismo item (futuro con coop online)
**Reward**: Items únicos exclusivos de la subasta

### "El Río Subterráneo"

**Ubicación**: Piso 3 (Hielo), balsa en un río subterráneo
**Setup**: Balsa que requiere 4 remos, río con rápidos
**Mecánica**: Cada jugador controla un remo, tienen que sincronizar (rhythm game cooperativo) para evitar rocas. Si chocan mucho, la balsa se destruye y caen al agua helada (daño)
**Reward**: Acceso a zona oculta del piso + cofre especial

---

## 4. Sistema de emotes — acciones expresivas

Los emotes son el "idioma corporal" de la party. Se activan con una rueda (tecla B) estilo Deep Rock Galactic. La cantidad no es fija — se pueden agregar más con el tiempo. Empezamos con un set base y se expande.

### Set base propuesto (escalable)

| Nombre | Descripción | Interacción con otros |
|--------|-------------|----------------------|
| **Saludar** | Wave con la mano | Otros pueden responder = animación sincronizada |
| **Bailar** | Baile medieval rítmico | Si 2+ jugadores bailan cerca → sincronización, buff temporal moral |
| **Reír** | Risa animada | Sonido alegre que se escucha en 20m |
| **Sí** | Asentir | Usado para votar en decisiones de party |
| **No** | Negar con la cabeza | Voto contrario |
| **Sentarse** | Se sienta en el piso o banco | Si cerca de fogata: heal lento. Si cerca de otros sentados: conversación ambiental |
| **Brindar (jarra)** | Levanta una jarra de hidromiel | Si otros brindan cerca = cheers sincronizado + buff moral (+1 luck 5 min) |
| **Fumar pipa** | Saca pipa estilo Gandalf, humo animado | Cerca de fogata: humo mágico con formas (dragones pequeños, runas). Buff meditación: regen MP +20% por 2 min |
| **Rezar** | Se arrodilla y reza | Si está cerca de un altar, el altar brilla y da un buff random temporal |
| **Hierba del bardo** | Fuma una hoja enrollada (versión fantasy) | Buff relajante: regen HP fuera de combate +20% por 3 min |
| **Tocar instrumento** | Requiere instrumento equipado | Combina con otros instrumentos para armonías grupales |

### Emotes que podrían agregarse después

- Escupir (cómico, sin efecto)
- Aplaudir (si 4+ jugadores aplauden a un NPC, da bonus)
- Llorar dramáticamente (persuade a mercaderes, -10% precios)
- Meditar profundo (te quedás inmóvil, regen x2 pero vulnerable)
- Abrazo (con otro jugador, animación grupal)
- Chocar los cinco (requiere otro jugador cerca)

### Notas sobre emotes "maduros"

**Pipa y hidromiel** son clásicos del fantasy (Gandalf, dwarves) — NO afectan rating, son estándar.

**"Hierba del bardo"** es la versión diegética de marihuana. Queda con Teen rating si no es explícito. Si preferís hacerlo más explícito/realista → Mature rating.

---

## 4.5. Sistema de señales — Pings y Fuegos Artificiales

En coop, **comunicar ubicación sin voz es CRÍTICO**. Necesitás dos niveles de señales:

### Nivel 1: Ping rápido (tecla dedicada)

Señal instantánea para marcar algo: un enemigo, un item, un peligro. Tipo Apex Legends / Deep Rock Galactic.

**Mecánica**:
- Tecla **Q** (por ejemplo) + apuntás con el crosshair
- Aparece un marker 3D en ese punto del mundo
- Visible para toda la party por 5 segundos
- **Tipo de ping depende de lo que apuntás**:
  - Apuntás a un enemigo → "¡Enemigo aquí!" con outline del mob
  - Apuntás a un item drop → "¡Loot!" con el nombre del item
  - Apuntás al suelo → "¡Vení acá!" marker genérico
  - Apuntás a un NPC → "¡Hablale a este!"
  - Apuntás a un cofre → "¡Loot box!"

### Nivel 2: Fuegos artificiales (señal de emergencia / celebración)

**Esto es la idea brillante**. Un item consumible que lanzás al cielo y explota como fuego artificial. Visible desde MUCHA distancia.

**Por qué es mejor que un marker genérico**:
- **Visible desde lejos** (300m+) — si te perdés del grupo en un mapa de 600x600m, es perfecto
- **Diegético** — encaja en el mundo (pólvora mágica, cristales explosivos)
- **Expresivo** — la party lo puede usar para celebrar un kill importante
- **Memorable** — los fuegos artificiales son PURA alegría visual

**Tipos de fuegos artificiales**:

| Tipo | Color | Uso |
|------|-------|-----|
| **Bengala Roja** | Rojo intenso | "¡Necesito ayuda YA!" — emergencia, morí o estoy atrapado |
| **Bengala Verde** | Verde | "¡Estoy acá, vengan!" — meeting point |
| **Bengala Azul** | Azul | "¡Loot importante aquí!" — cofre o boss |
| **Fuego Celebración** | Multicolor explosión | "¡Ganamos!" — después de matar un jefe |
| **Humo Amarillo** | Humo continuo 30s | "Sígame" — marcador persistente para guiar al grupo |

**Mecánica**:
- Son **items consumibles** del inventario (stackeables, compras en el mercader)
- Se usan con click derecho → animación de encendido → explosión en el cielo
- Sonido fuerte + luz intensa que ilumina el área
- Costo bajo para que sean descartables (5-10 oro cada uno)

**Extras divertidos**:
- En **zonas seguras** (taverna, Puesto), los fuegos son puramente cosméticos (no molestan NPCs)
- En **combate**, el estruendo puede **atraer enemigos cercanos** — consecuencia a balancear
- **Fuegos artificiales de festival** — en eventos como La Fiesta del Pueblo, hay versiones gratis especiales

### Combinación: Ping + Fuego Artificial

- **Corto/cerca** → usás Ping (tecla Q)
- **Largo/lejos** → lanzás Fuego Artificial del inventario

Esto cubre toda la comunicación sin voz del juego.

---

## 4.6. El Juicio de la Party — Sistema de votación cómica

Tipo "Among Us medieval" — los jugadores pueden juzgarse entre ellos como broma. Sin consecuencias reales de progreso, solo cosméticas.

### Mecánica

**Trigger**: `/juicio @jugador` o desde menú de party. Limitado a **1 por hora por jugador**.

**Locación**: Teleport a la **Plaza de los Juicios** — arena circular con guillotina central, banquitos para jurados, plataforma de juez NPC, multitud NPC que reacciona.

**Fases**:
1. **Acusación** (30s) — el acusador escribe la razón (text input)
2. **Defensa** (30s) — el acusado escribe su defensa
3. **Votación** (15s) — otros jugadores levantan letrero verde (inocente) o rojo (culpable)
4. **Veredicto** — mayoría simple

### Castigos cosméticos (si es culpable)

Todos sin pérdida real de progreso:

- **Guillotina** — animación Monty Python de decapitación, respawn con cabeza flotante vendada por 10 min
- **Cepo público** — atrapado 60s, los demás le tiran tomates (animación de mancha)
- **Alquitrán y plumas** — cubierto de plumas, dropea plumas al caminar 5 min
- **Piedra de la Vergüenza** — cadena al cuello con una piedra pesada atada, -40% velocidad de movimiento por 10 min. Visual: piedra arrastrándose por el suelo con sonido de cadena
- **Trago del Arrepentido** — miniaturizado al 50% del tamaño por 5 min
- **Gorro de la Vergüenza** — sombrero ridículo cosmético por 10 min

### Si es inocente
- Lluvia de monedas falsas del cielo
- El acusador recibe **Título de la Calumnia** por 24h
- Buff cosmético "El Vindicado" — glow dorado 5 min

### Protecciones anti-abuso
- 1 juicio por hora por jugador
- No podés re-juzgar a quien ya te juzgó en los últimos 30 min
- **Opt-out en settings** — desactivás la feature para vos (pero tampoco podés juzgar)
- 10+ inocentes consecutivos → título "El Justo" + inmunidad 24h

---

## 5. El Cristal Cantor (boombox diegético)

### Concepto

La referencia a Lethal Company es brillante — la boombox ahí creó momentos icónicos. Pero una boombox moderna rompería la estética fantasy. La solución: **Cristal Cantor**.

### Qué es

Un cristal mágico que **reproduce sonidos grabados**. Los bardos viajeros los usan para distribuir música. Se encuentran en mercados, drops de bandit camps, o se compran en el Puesto.

### Mecánica

- Es un **item del inventario** (1x1 en la grilla)
- Al usarlo con click derecho: se instancia en el suelo, permanece ahí
- Todos los jugadores dentro de 15m escuchan la música
- Se puede **recoger** después con E
- Batería infinita (es magia, no tecnología)

### Tipos de Cristal Cantor

Diferentes cristales con diferentes músicas/efectos:

| Cristal | Música | Efecto adicional |
|---------|--------|------------------|
| **Cristal del Bardo Común** | Música medieval alegre (random del pool) | Ninguno, solo ambiente |
| **Cristal del Héroe** | Himno épico de batalla | +5% damage a toda la party dentro del rango durante combate |
| **Cristal del Descanso** | Música calma de taberna | Regen de HP fuera de combate +50% |
| **Cristal del Baile** | Música rítmica | Buff de movement speed +10% mientras suena |
| **Cristal Prohibido** | Música distorsionada, inquietante | Enemigos dentro del rango reciben -10% daño pero se aturden cada 5 segundos |
| **Cristal del Amor** | Música romántica | NPCs mercaderes dan -5% precios (solo funciona 1 vez por NPC) |

### Por qué funciona

- **Item diegético** — encaja en el mundo fantasy
- **Social** — todos escuchan, es un acto público
- **Memorable** — "el momento en que pusimos el Cristal del Héroe antes de pelear al jefe"
- **Customizable** — cada jugador puede tener su cristal favorito
- **Monetizable** (futuro, éticamente) — cristales cosméticos con canciones licenciadas podrían ser DLC opcional

### Ideas para música

- **Composiciones originales** estilo medieval (laúd, flauta, tambor)
- **Licencias indie** de artistas chill fantasy (más barato que triple A)
- **Covers de clásicos en clave medieval** — "Never Gonna Give You Up" con laúd es gold para meme culture

---

## 6. Sistema de instrumentos musicales (futuro)

Expansión natural de los emotes. Si tenés un instrumento equipado en off_hand, el emote "Tocar instrumento" se activa.

### Instrumentos disponibles

| Instrumento | Slot | Efecto solo | Efecto combinado |
|-------------|------|-------------|------------------|
| **Laúd** | off_hand | Melodía dulce, regen HP +20% | +flauta = buff armonía grupal |
| **Flauta** | off_hand | Regen MP +20% | +laúd = armonía |
| **Tambor** | off_hand | +10% damage party | +laúd+flauta = trío completo |
| **Arpa dorada** | off_hand | Calma enemigos cercanos por 5s | Versión rara del laúd |
| **Cuerno de guerra** | off_hand | Grito que aturde enemigos cercanos | Único, no combina |

### El "concierto"

Si la party entera toca instrumentos al mismo tiempo **en armonía**, se activa un buff especial: **Concierto de la Hermandad** — todos los stats +5 por 10 minutos.

Es difícil de conseguir (requiere coordinación real) pero se vuelve un ritual memorable.

---

## 7. Prioridad de implementación

Todo esto es **post-MVP**. Primero el juego tiene que funcionar (Piso 1 jugable, coop, boss). Después:

### Fase A — Hangout basics (post-coop funcional)
1. Los 12 emotes básicos (sin mecánicas especiales, solo animaciones)
2. Cristal Cantor simple (1 tipo, música random)
3. Sentarse cerca de fogata con heal lento

### Fase B — Taverna viva (después del Puesto de Guardia)
4. Torneo de la Taverna (duelos amistosos)
5. Trago del Valiente (gambling con efectos random)
6. Concurso de Tiro
7. Emotes con interacciones (brindar sincronizado, bailar en grupo)

### Fase C — Heists del mundo
8. El Huevo de la Dragona (el primero, el más icónico)
9. El Cerdo del Aldeano (el más cómico)
10. El Gnomo Ladrón
11. La Gallina Dorada

### Fase D — Grandes eventos
12. La Boda del Ogro
13. La Apuesta del Diablo
14. La Subasta del Tuerto
15. El Río Subterráneo

### Fase E — Música y bonding profundo
16. Sistema de instrumentos completo
17. El Concierto de la Hermandad
18. Cristales Cantores expandidos (6 tipos)
19. Ritual de Invocación
20. Cocinar un Banquete completo

---

## 8. Preguntas abiertas (decisiones pendientes del usuario)

1. **Rating target**: ¿Teen 13+ (versión fantasy diegética) o Mature 17+ (versión explícita moderna)? Recomendado: **Teen**.
2. **"Hierba del bardo"**: ¿explícita como marihuana o ambigua como "hierba mística"? Recomendado: **ambigua**.
3. **Alcohol**: ¿hidromiel/cerveza sin efectos borrachera, o con efectos visuales de borrachera? Recomendado: **con efectos leves para humor**.
4. **PvP en duelos**: ¿solo entre miembros de la misma party, o cross-party? Recomendado: **solo party al principio**.
5. **Música de Cristal Cantor**: ¿composiciones propias, licencia indie, o mix con covers memes? Recomendado: **mix**.
6. **Frecuencia de eventos ambientales**: ¿timed (cada X horas reales) o trigger por proximidad random? Recomendado: **mix de ambos**.
