# Game Design Document — Dungeon Party

**Versión**: 0.2  
**Fecha**: 2026-04-07  
**Estado**: En diseño

---

## 1. Concepto General

### Elevator Pitch

Dungeon Party es un **dungeon crawler cooperativo en primera persona** para 1 a 6 jugadores. Los jugadores ascienden una torre de 10 pisos con dificultad progresiva, cada uno con un jefe final único. Recolectás loot, subís de nivel, y dejás tu marca en un mundo persistente compartido. Sesiones cortas, pero intensas.

### Género

- Dungeon Crawler cooperativo
- RPG con progresión persistente
- Primera persona
- Roguelite elements (loot por run, pérdida al morir)

### Plataforma

- PC (Windows, Mac, Linux) — Godot 4 exporta a las tres sin problema
- Conexión multijugador vía **Steam (GodotSteam)** — NAT traversal automático, invitaciones desde lista de amigos

### Jugadores

- **Mínimo**: 1 (modo solo para farmear y progresar)
- **Máximo**: 6 (cooperativo)

### Sesiones

- Partidas cortas y contenidas — no requiere sesiones de horas
- Cada piso de la torre es una sesión natural

### Estilo Visual

- **Low-poly** — modelos simples, texturas planas, se ve bien y se desarrolla rápido
- Pisos compactos pero densos en contenido

---

## 2. Pilares de Diseño

Los principios que guían TODAS las decisiones del juego:

1. **La coordinación es poder** — La dificultad es fija. Jugar en equipo es más fácil que jugar solo. El juego PREMIA la cooperación.
2. **Las sinergias ganan batallas** — Las clases no solo cooperan, se POTENCIAN. Combinar habilidades entre dos o más jugadores desbloquea efectos que ninguno podría lograr solo.
3. **Cada run importa** — Si morís, perdés el loot de esa run. Hay tensión real en cada decisión.
4. **Tu dungeon, tu historia** — El mundo es persistente. Las marcas y los momentos épicos quedan grabados.
5. **Fácil de aprender, difícil de dominar** — Sistemas simples con profundidad emergente.

---

## 3. Estructura del Juego

### La Torre

- **5 pisos iniciales** — cada uno más difícil que el anterior (expandible sin límite)
- **Cada piso es un portal a un mundo diferente** — la torre es un nexo que conecta dimensiones
- Entre cada piso hay una **sala de transición** con el portal al siguiente mundo
- **Cada piso tiene un jefe final**:
  - Pisos 1-3: mecánicas para **1 jugador** — cualquiera puede ganarles solo
  - Pisos 4-5: mecánicas **cooperativas opcionales** — se pueden hacer solo pero tienen mecánicas extra para grupo
- **Mapas procedurales con semillas** — el layout cambia cada run pero la temática del piso se mantiene
- La dificultad es **fija** — no escala con la cantidad de jugadores
- Jugar solo es más difícil; jugar en grupo es la experiencia recomendada
- Pisos grandes y densos — pocos enemigos bien diseñados, no hordas genéricas
- **Fuego amigo activo** — las habilidades dañan a aliados, hay que coordinar

#### Temáticas de los Pisos

La torre conecta mundos diferentes. Cada piso es una dimensión con su propia identidad:

| Piso | Mundo | Colores | Sensación |
|------|-------|---------|-----------|
| 1 | **Pradera Interior** | Verdes, azules, dorados | Abierto, luz del diamante en el techo, árboles, casas, pilares gigantes |
| 2 | **Bosque / Selva** | Verdes oscuros, marrones | Denso, húmedo, poca luz, la vegetación te encierra |
| 3 | **Hielo / Nieve** | Blancos, azules, grises | Frío, cuevas congeladas, viento, hielo resbaloso |
| 4 | **Tormenta / Cielo** | Grises, púrpuras, destellos | Plataformas flotantes, rayos, cielo abierto pero hostil |
| 5 | **Dimensión Rota** | Invertidos, cambiantes, imposibles | Gravedad cambia, geometría imposible, las reglas del juego se alteran |

Concepto expandible: pisos futuros pueden ser volcán, océano, desierto, espacio, o lo que se necesite.

### Flujo de una Sesión

```
Taberna (Lobby) → Asesora del Gremio → Entrar a la torre → Explorar/Combatir → Jefe → Loot
    ↑                                                                                    |
    |                      ← Muerte (pierde loot) o Victoria (conserva loot) ←           |
```

### La Taberna (Lobby en Tiempo Real)

- **Espacio 3D en tiempo real** — no es un menú, es una taberna donde los jugadores se ven, caminan e interactúan
- Pre-sala antes de entrar a la torre
- Comprar/vender objetos
- Administrar inventario y habilidades
- Zona social para interactuar antes de la run
- Chat libre sin restricción de proximidad

### La Asesora del Gremio (NPC)

- NPC que controla el acceso a la torre
- Verifica que tengas el **nivel necesario** para subir al piso solicitado
- Verifica que hayas **completado el piso anterior**
- Da información sobre qué esperar en el siguiente piso
- Funciona como gate natural — no te salteas pisos sin cumplir requisitos

---

## 4. Clases de Personaje (Lanzamiento)

5 clases para el lanzamiento. Cada una con identidad clara y rol definido.

### 4.1 Guerrero

| Aspecto | Rama: Tanque | Rama: Berserk |
|---------|-------------|---------------|
| **Armas** | Espada + Escudo (una mano) | Arma a dos manos o doble arma |
| **Stats** | Defensa, HP | Daño, velocidad de ataque |
| **Mecánica** | Bloqueo, provocar, absorber daño | Modo furia — más daño recibís, más daño hacés |
| **Fantasía** | "Soy el muro. Nada pasa." | "Arraso con todo." |
| **Interacción aliados** | **Cubrir** — se pone delante de un aliado y absorbe daño por él | **Lanzar** — agarra a un compañero y lo lanza |

### 4.2 Mago

**Ataque base (sin rama — "desarmado"):**
- Gesto: finger guns (pistolita con los dedos)
- Proyectil: bolita pequeña de energía (blanca o color suave), con mini-relámpagos/líneas de energía alrededor, aspecto ligeramente distorsionado pero sutil — se nota que es débil e inestable, como que apenas se mantiene junta
- Stats base: 70 HP, 120 MP, 20 dmg, 15m rango, más lento que el guerrero (4.5 m/s)

| Aspecto | Rama: Elementalista | Rama: Arcano |
|---------|-------------------|--------------|
| **Estilo** | Fuego, hielo, rayo | Energía pura, manipulación espacial |
| **Mecánica** | Hechizos elementales, daño en área, debilidades elementales | Proyectiles de energía, escudos, teletransporte, empujar/atraer |
| **Daño** | Alto, explosivo | Medio, constante |
| **Fantasía** | "Controlo los elementos." | "Controlo el espacio." |
| **Interacción aliados** | **Empuje de viento** — empuja a un aliado con ráfaga | **Levantar** — eleva a un aliado, reposicionamiento táctico |

### 4.3 Arquero

| Aspecto | Rama: Ranger | Rama: Artillero |
|---------|-------------|-----------------|
| **Armas** | Arco, flechas | Armas de fuego, explosivos |
| **Estilo** | Muchas flechas, rápido, móvil | Explosiones, área, efectos de estado |
| **Mecánica** | Ráfagas, disparo en movimiento, daño constante | Granadas, minas, disparos con veneno/ralentización |
| **Fantasía** | "Lluvia de flechas sin parar." | "Todo explota y se envenena." |
| **Interacción aliados** | **Lazo** — fija una cuerda en un aliado, lo conecta a una posición | **Lazo** — misma habilidad base |

### 4.4 Nigromante

| Aspecto | Rama: Maldecidor | Rama: Creador |
|---------|-----------------|---------------|
| **Estilo** | Maldiciones, debuffs, magia oscura | Invoca criaturas de todo tipo |
| **Mecánica** | Drenar vida, ralentizar, debilitar enemigos | Esqueletos, golems, serpientes, arañas |
| **En equipo** | Hace que los enemigos sean más fáciles para todos | Llena el campo de criaturas aliadas |
| **Fantasía** | "Tus enemigos se destruyen solos." | "Tengo un ejército." |
| **Interacción aliados** | **Guardián** — invoca una criatura sobre un aliado que lo defiende y absorbe daño | **Guardián** — misma habilidad base |

### 4.5 Curandero

| Aspecto | Rama: Sanador | Rama: Buffer |
|---------|-------------|-------------|
| **Estilo** | Curación directa, escudos | Potenciar stats del equipo |
| **Mecánica** | Cura HP, escudos, resurrección más rápida | Buffea daño, velocidad, defensa de aliados |
| **En equipo** | Reactivo — responde cuando hay daño | Proactivo — prepara al equipo antes del combate |
| **Fantasía** | "Nadie muere mientras yo esté acá." | "Hago que mis aliados sean bestias." |
| **Interacción aliados** | **Campo sagrado** — campo que empuja enemigos y atrae aliados | **Campo sagrado** — misma habilidad base |

### Sinergias entre Clases

Las habilidades de dos clases se pueden combinar para efectos potenciados:

| Clase 1 | Clase 2 | Sinergia |
|---------|---------|----------|
| **Guerrero Tanque** | **Mago Elementalista** | El Guerrero provoca enemigos en grupo → el Mago los destruye con hechizo en área |
| **Mago Elementalista** | **Arquero Ranger** | El Mago congela enemigos → el Arquero los remata con daño crítico a congelados |
| **Nigromante Creador** | **Curandero Sanador** | El Sanador cura a las invocaciones del Creador, haciéndolas más duraderas |
| **Guerrero Tanque** | **Curandero Buffer** | El Buffer potencia la defensa del Tanque → casi inmortal temporalmente |
| **Nigromante Maldecidor** | **Mago Elementalista** | El Maldecidor maldice enemigos → los hechizos del Mago hacen daño doble |
| **Arquero Artillero** | **Guerrero Berserk** | El Artillero ralentiza con veneno → el Berserk entra y masacra |
| **Mago Arcano** | **Guerrero Berserk** | El Arcano levanta/empuja enemigos en grupo → el Berserk lanzado al medio |
| **Curandero Buffer** | **Arquero Ranger** | El Buffer potencia velocidad de ataque → lluvia de flechas imparable |

### Clases Post-Lanzamiento (Futuro)

- **Artesano** — Crafteo en dungeon: bomba, dron piloteable, escudo, tótem. 4 funciones base + slots desbloqueables con loot especial
- **Vampiro** — DPS sustain con drenaje de vida
- **Luchador** — Melee con sistema de combos
- **Slasher** — Assassin rápido y frágil
- **Estratega** — Control de campo táctico
- **Amplificador** — Buffer que potencia stats de aliados

---

## 5. Sistema de Comandos de Voz (Post-Lanzamiento)

Feature planificada para después del lanzamiento. No forma parte del MVP.

### Concepto

Las habilidades se pueden activar mediante comandos de voz O teclas tradicionales. El sistema de voz es una **feature opcional** que añade inmersión, no un requisito.

### Funcionamiento

1. El jugador grita el comando de voz (ej: "¡FUEGO!")
2. El sistema reconoce el comando
3. La habilidad se ejecuta si está disponible (cooldown, maná, etc.)

### Consideraciones

- Los comandos deben ser **cortos** (1-2 palabras) para reacción rápida
- El sistema debe tolerar **variaciones** en pronunciación
- **Los demás jugadores cercanos escuchan el grito** por el chat de proximidad
- Las teclas son el sistema principal; la voz es un **modo alternativo opcional**

---

## 6. Sistemas de Progresión

### 6.1 Nivel del Personaje

- **Nivel máximo**: 50
- **Fuentes de XP**: matar enemigos, completar pisos, misiones, eventos, cacerías
- **Curva**: sube rápido al principio, se ralentiza al acercarse al 50 (sin ser excesivo)
- El nivel es **persistente** — se guarda en el perfil del jugador
- Desbloquea puntos de habilidad para el árbol
- **3 stat points por nivel** para repartir libremente entre atributos

#### Sistema de Atributos

| Atributo | Abreviación | Efecto |
|----------|-------------|--------|
| **Fuerza** | STR | +2 daño físico por punto |
| **Inteligencia** | INT | +2 daño mágico, +3 MP por punto |
| **Destreza** | DEX | Futuro: crit, dodge |
| **Defensa** | DEF | Reduce daño físico recibido (1:1) |
| **Vitalidad** | VIT | +5 HP por punto |

**Stats base por clase:**

| Stat | Guerrero | Mago |
|------|----------|------|
| STR | 12 | 4 |
| INT | 3 | 12 |
| DEX | 6 | 5 |
| DEF | 10 | 3 |
| VIT | 10 | 5 |

**Rango** es un stat modificable por ítems (ej: "+2 Rango" en un legendario).

**Resistencias elementales** (cap 75%):

| Resistencia | Guerrero | Mago |
|-------------|----------|------|
| Fuego | 0% | 10% |
| Hielo | 0% | 10% |
| Rayo | 0% | 10% |

Fórmulas:
- Daño físico = daño_base + (STR × 2)
- Daño mágico = daño_base + (INT × 2)
- Reducción física = DEF puntos menos de daño (mínimo 1)
- HP total = hp_base + (VIT × 5)
- MP total = mp_base + (INT × 3)
- Daño elemental recibido = daño × (1 - resistencia%)

**Escalado de enemigos por piso:**

| Piso | HP | Daño | DEF |
|------|----|------|-----|
| 1 - Pradera | 100 | 10 | 0 |
| 2 - Bosque | 200 | 20 | 5 |
| 3 - Hielo | 350 | 35 | 12 |
| 4 - Tormenta | 500 | 50 | 20 |
| 5 - Dimensión Rota | 700 | 70 | 30 |

#### Progresión por piso

| Nivel | Piso | Qué pasa |
|-------|------|----------|
| 1-10 | Piso 1 | **Clase base** — mecánicas generales, aprendés lo básico |
| 10 | Desbloqueo | **Elegís tu rama de especialización** |
| 11-20 | Piso 2 | Desarrollás tu especialización |
| 21-30 | Piso 3 | Habilidades más poderosas |
| 31-40 | Piso 4 | Builds avanzados |
| 41-50 | Piso 5 | Endgame, builds completos |

### 6.2 Árbol de Habilidades (estilo Diablo 2)

- **Simple y claro** — pocas ramas, decisiones que importan
- Cada clase tiene su árbol único con **2 ramas** de especialización
- Nivel 1-10: habilidades base de la clase (iguales para todos)
- Nivel 10: elegís tu rama → se abre el árbol especializado
- Subís de nivel → ponés puntos → desbloqueás o mejorás habilidades

### 6.3 Sistema de Reset de Rama

El jugador puede cambiar de rama, pero con consecuencias crecientes:

| Reset | Costo | Estado |
|-------|-------|--------|
| **1ro** | Gratis — completar una misión | Normal |
| **2do** | Gratis — completar otra misión | Normal |
| **3ro** | Objetos de misión especial | Normal |
| **4to** | Objetos de misión especial | Normal |
| **5to** | Objetos de misión especial | Último cambio — advertencia |
| **6to** | — | **Perdido** |

#### El Perdido

Un personaje que reseteó 6 veces pierde su identidad de tanto cambiar:

- Pierde acceso a AMBAS ramas — queda como clase base
- Desbloquea una **habilidad única exclusiva**: **Golpe de Cabeza**
  - Daño masivo, igual para todas las clases
  - El personaje se lanza de cabeza contra el enemigo
  - Absurdo, poderoso, memorable
- Es un estado que mezcla castigo con recompensa — perdés un árbol entero pero ganás un golpe devastador

#### Redención del Perdido

- Existe un **jefe especial** que solo aparece si hay un Perdido en el grupo
- El jefe tiene mecánicas diseñadas para que el Perdido use su Golpe de Cabeza en momentos clave
- El equipo protege al Perdido mientras él resuelve las mecánicas del jefe
- Al vencer al jefe → el Perdido **recupera** el derecho a elegir rama nuevamente

### 6.4 Loot y Objetos (estilo Metin 2)

#### Drops de enemigos

- Los enemigos dropean objetos al morir — armas, armaduras, consumibles, materiales
- Algunos objetos vienen con **bonos aleatorios** (ej: +5% daño fuego, +10 HP)
- Jefes tienen **loot garantizado** de mayor rareza
- Los bonos son random — dos espadas iguales pueden tener bonos diferentes
- Al morir → **se pierde el loot de esa run**
- Los objetos guardados en la Taberna ANTES de la run están a salvo

#### Rareza

| Rareza | Color | Bonos |
|--------|-------|-------|
| **Común** | Blanco | 0 bonos |
| **Raro** | Azul | 1 bono |
| **Épico** | Púrpura | 2 bonos |
| **Legendario** | Dorado | 3 bonos + efecto especial |

#### Item Level (Nivel de objeto)

- Cada objeto tiene un **nivel mínimo** para equiparlo
- Ejemplo: Espada de Fuego +3 → requiere nivel 25
- Podés COMPRAR o guardar el objeto pero no EQUIPARLO hasta tener el nivel
- Evita que un nivel 1 use armas de nivel 50

#### Sistema de Mejora (+1 a +9)

| Nivel | Probabilidad de éxito | Si falla |
|-------|----------------------|----------|
| +1 a +3 | Alta (80-90%) | No pasa nada |
| +4 a +6 | Media (50-60%) | El objeto baja un nivel |
| +7 a +8 | Baja (30-40%) | El objeto puede **romperse** |
| +9 | Muy baja (15-20%) | El objeto se **rompe** casi seguro si falla |

- No existen items de protección — el riesgo es REAL
- Un objeto +9 es un tesoro — poquísima gente lo tiene
- Romper = se destruye para siempre

#### Comercio entre Jugadores

- Se puede comerciar en la **Taberna** (lobby)
- Intercambio directo de objetos entre jugadores
- Genera economía natural entre el grupo

### 6.5 Modificadores de Dungeon

Los modificadores alteran las reglas del piso temporalmente. Hacen que cada run se sienta diferente.

#### Tipo 1: Modificadores de Evento/Monstruo

Se activan cuando aparece un evento o monstruo especial en el piso:

| Evento | Modificador |
|--------|------------|
| Monstruo de hielo | Ralentización general, +daño hielo, -efectividad golpes físicos |
| Monstruo de fuego | Daño por área constante, +daño fuego, -efectividad hielo |
| Horda de no-muertos | +daño del Nigromante, -curación recibida |
| Emboscada oscura | Visibilidad reducida, +daño crítico |

El entorno se adapta al evento — no es solo pelear, es adaptarse.

#### Tipo 2: Modo Hardcore (aleatorio)

Cada vez que entrás a un piso hay un **porcentaje de probabilidad** de que se active modo hardcore. Se aplican uno o más modificadores extremos:

| Modificador Hardcore | Efecto |
|---------------------|--------|
| **Controles invertidos** | Izquierda es derecha, adelante es atrás |
| **Reflejo físico** | Enemigos reflejan un % del daño físico recibido |
| **Reflejo mágico** | Enemigos reflejan un % del daño mágico recibido |
| **Sin curación** | La curación no funciona en este piso |
| **Niebla** | Visibilidad mínima |
| **Velocidad x2** | Enemigos se mueven al doble de rápido |
| **Silencio** | No se pueden usar habilidades por X segundos periódicamente |

#### Recompensa Hardcore

El modo hardcore da **mejores recompensas** como incentivo por el riesgo:

- +50% XP ganada en el piso
- +Probabilidad de loot épico y legendario
- Posibilidad de drops exclusivos de hardcore
- El grupo decide: "es hardcore, ¿entramos o reseteamos?"

### 6.6 Escalado por Diferencia de Nivel (Level Gap)

Penalización en RECOMPENSAS, no en acceso. Nadie está bloqueado de jugar con nadie.

| Situación | Penalización | Puede jugar |
|-----------|-------------|-------------|
| **Nivel bajo en piso alto** | Recibe más daño, hace menos daño | Sí — el grupo lo protege |
| **Nivel alto en piso bajo** | Menos XP, menos loot, no dropean legendarios | Sí — ayuda a su amigo pero no gana casi nada |

#### Filosofía

- El nivel 50 PUEDE entrar al piso 1 con su amigo → lo hace por diversión, no por farmeo
- El nivel 1 PUEDE entrar a pisos altos con ayuda → pero sufre y necesita al equipo
- El juego empuja naturalmente a jugar en tu rango pero NUNCA bloquea la cooperación

---

## 7. Sistema de Muerte

### 3 Estados del Jugador

| Estado | Qué pasó | Qué podés hacer |
|--------|----------|-----------------|
| **Vivo** | Normal | Todo |
| **Herido** | Daño letal pero no excesivo | Estás en el piso, no te movés, esperás revive |
| **Muerto** | Overkill (daño excesivo) | Volvés directo a la Taberna |

### Estado Herido

- Caés al piso, no podés moverte ni atacar
- Formas de revivir:
  - **Curandero**: habilidad de revivir — **3 usos máximo** por run (depende del nivel de la habilidad)
  - **Objeto de revivir**: cualquier clase puede usarlo, pero solo funciona en estado Herido
- Si nadie te revive en X tiempo → morís y volvés a la Taberna

### Muerte (Overkill)

- El golpe fue TAN fuerte que saltea el estado Herido
- Volvés directo a la **Taberna**
- Perdés **todo el loot de la run**
- Perdés el **% de XP del nivel actual** (ej: nivel 42 con 50% XP → volvés a 42 con 0% XP)
- **NUNCA bajás de nivel** — solo perdés progreso hacia el siguiente
- Se le pregunta al equipo: ¿seguir o volver?

### Escenarios de Grupo

| Escenario | Qué pasa |
|-----------|----------|
| **Alguien queda herido** | El equipo lo revive con Curandero u objeto |
| **Alguien muere (overkill)** | Va a la Taberna, el equipo decide si continuar |
| **Queda 1 vivo** | Decide: completar el piso solo o devolverse |
| **Mueren todos** | Run terminada, todos a la Taberna con penalización |

### Filosofía

La muerte tiene que DOLER pero no ser devastadora. Perdés loot y XP del nivel, no semanas de trabajo. El Curandero es CLAVE — sus 3 revives son el recurso más valioso de la run.

---

## 8. Mundo Persistente y Personalización

### 8.1 Torre Persistente por Host

- Un jugador **hostea** la partida — la torre se guarda en su máquina
- Cada torre tiene una **semilla única** que define su layout
- Los pisos desbloqueados, grafitis y estado se guardan en esa torre
- El host invita amigos vía **Steam**
- Si el host vuelve a hostear mañana, todo sigue donde lo dejaron
- Cada host tiene su propia torre — diferente semilla, diferente experiencia
- Los jugadores llevan su **perfil personal** (nivel, inventario, habilidades) a cualquier torre

### 8.2 Sistema de Grafitis (3 niveles)

#### Grafiti Común
- **Quién**: Cualquier jugador
- **Dónde**: Pisos normales
- **Duración**: Se borran periódicamente (rotación automática)
- **Contenido**: Caracteres predeterminados + **imagen propia** (máx 128x128px, PNG/JPG)

#### Grafiti Permanente
- **Quién**: Jugadores que cumplan requisitos especiales o misiones del gremio
- **Dónde**: Salas especiales, zonas secretas
- **Duración**: Permanente
- **Contenido**: **Imagen propia** de mejor resolución (máx 256x256px, PNG/JPG)

#### Restricciones de Imágenes
- Peso máximo por imagen limitado para no afectar rendimiento
- Límite de grafitis por piso para no saturar
- Sin moderación por ahora (juego entre amigos)

#### Grafiti Épico (3-Strike)
- **Quién**: Se otorga automáticamente por jugadas épicas
- **Dónde**: El lugar exacto donde ocurrió la hazaña
- **Duración**: Permanente + efecto visual especial
- **Contenido**: Registro de la hazaña, quién lo hizo, cuándo
- **Ejemplo**: "Acá el Nigromante invocó 20 esqueletos de una — 2026-04-10"

### 8.3 Qué cuenta como "Jugada Épica"

- Matar X enemigos sin recibir daño
- Revivir a todo el equipo en un piso
- Completar un piso sin que nadie muera
- Derrotar un jefe en tiempo récord
- Sobrevivir con 1 HP por X tiempo
- (Expandible con más condiciones)

---

## 9. Sistema de Comunicación

### 9.1 Chat de Proximidad

- La voz de los jugadores se escucha según la **distancia** dentro del juego
- Cerca = se escucha claro
- Lejos = se escucha bajo o no se escucha
- No hay chat global dentro de la dungeon
- Separarse del grupo = perder comunicación = peligro real
- Fuera de la dungeon (en la Taberna) = chat libre sin restricción

### 9.2 Comunicación a Distancia

| Piso | Objeto | Qué ves/escuchás |
|------|--------|-------------------|
| 1-3 | **Walkie-Talkie** | Audio con estática a distancia |
| 4-5 | **Solo proximidad** | La torre interfiere, se pierde la señal |
| 4-5 | **Bola de Cristal** (loot/misión especial) | Videollamada — ves la cara/avatar del otro jugador |

- El **Walkie-Talkie** se entrega al llegar a nivel 10 (al elegir especialización)
- La **Bola de Cristal** es un objeto raro que se encuentra en pisos avanzados

### 9.3 Parlante Musical

- Objeto que reproduce **archivos MP3 locales** del jugador dentro del juego
- Se escucha por **proximidad** — solo los que están cerca escuchan la música
- Se puede dejar en una sala o cargar encima
- Ideal para ambientar la Taberna o zonas de la dungeon
- Integración con Spotify u otras plataformas → contenido post-lanzamiento

### 9.4 Personalización del Avatar

- Cada jugador puede **editar la apariencia** de su personaje
- **Cosméticos**: skins, accesorios, cambios visuales — **solo visuales, sin bonos de stats**
- Se obtienen por: loot, compra en la Taberna, logros
- Se ven en: la Taberna, la Bola de Cristal, dentro del juego

---

## 10. Eventos Dinámicos

- Pocos pero presentes — no son el foco principal
- Eventos aleatorios que pueden aparecer en ciertos pisos:
  - Sala de tesoro sorpresa
  - Emboscada de enemigos especiales
  - NPC misterioso que ofrece un intercambio
  - Trampa que altera el piso temporalmente
- Eventos únicos para combinaciones de clases específicas (sinergia de evento)

---

## 11. Stack Técnico (Propuesta)

| Componente | Tecnología | Razón |
|-----------|-----------|-------|
| Motor de juego | Godot 4 | Gratis, open source, 3D, networking integrado |
| Lenguaje | GDScript | Nativo de Godot, fácil de aprender |
| Networking | Steam (GodotSteam) | NAT traversal automático, lobbies, invitaciones desde Steam |
| Conexión social | Steam + Discord (comunidad) | Steam para conexión in-game, Discord para comunidad |
| Persistencia local | SQLite | Guardar perfiles, inventarios, progreso |
| Persistencia servidor | JSON/SQLite sincronizado | Estado de la torre por servidor |

---

## 12. Alcance y Prioridades

### MVP (Versión Mínima Jugable)

Lo primero que hay que construir para tener algo JUGABLE:

1. **Movimiento en primera persona** dentro de un piso
2. **2 clases funcionales** (Guerrero + Mago) con habilidades base (sin ramas)
3. **2-3 tipos de enemigos** con IA básica
4. **1 piso** con generación procedural (semilla) + 1 jefe
5. **Sistema de vida, herido y muerte** con pérdida de loot
6. **Loot básico** con sistema de rareza
7. **Taberna** como lobby simple
8. **Conexión multijugador** para 2 jugadores vía Steam
9. **Guardado de perfil** local

### Fase 2

- Las 5 clases completas
- Ramas de especialización (se desbloquean nivel 10)
- 5 pisos con 5 jefes
- Árbol de habilidades completo
- Sistema de mejora de objetos (+1 a +9 con riesgo de romper)
- Chat de proximidad
- Walkie-Talkie (pisos 1-3)
- Sinergias entre clases
- Habilidades de interacción con aliados
- Comercio entre jugadores en la Taberna
- Item Level (nivel mínimo para equipar)
- Escalado por diferencia de nivel
- Modo Hardcore aleatorio con mejor loot
- Modificadores de evento/monstruo
- Asesora del Gremio (NPC)
- Hasta 6 jugadores

### Fase 3 (Post-Lanzamiento)

- Comandos de voz opcionales
- Clases adicionales (Artesano, Vampiro, Luchador, Slasher, Estratega, Amplificador)
- Sistema de grafitis con imágenes (3 niveles)
- Bola de Cristal (videollamada en pisos 4-5)
- Parlante musical (archivos MP3)
- Cosméticos y personalización de avatar
- Eventos dinámicos
- Sistema del Perdido + jefe de redención
- Más pisos y jefes
- Más sinergias y eventos

---

## 13. Preguntas Resueltas

- [x] ¿Nombre definitivo? → **Another Game of Dungeon (AGOD)** — provisional
- [x] ¿Mecánicas de jefe? → Pisos 1-3 solo, pisos 4-5 cooperativas opcionales
- [x] ¿PvP? → Fuego amigo activo + duelos con apuestas en la Taberna
- [x] ¿Modificadores visibles? → Hardcore = sorpresa, eventos = aviso vago
- [x] ¿Crafting? → Objetos estándar desde el inicio, fabricación desde piso 3, pociones por misión
- [x] ¿Restricción de clases? → No hay límite, pueden entrar 6 guerreros si quieren
- [x] ¿Temáticas? → Portales a mundos diferentes, expandible sin límite
- [x] ¿Pociones? → Curación (comunes), descanso (comunes), buff (misión especial)

## 14. Interfaz de Usuario (HUD & Menús)

### HUD en juego
- Barra de vida (roja), maná (azul), XP (dorada) — abajo izquierda
- Hotbar de 8 slots (teclas 1-8)
- Crosshair central

### Ventana de Personaje
- **Acceso**: icono de cruz roja sobre la barra de vida (estilo Metin2)
- **Contenido**:
  - Nombre del personaje
  - Clase y nivel
  - Stats (STR, INT, DEX, DEF, VIT) con botones de + si hay puntos disponibles
  - Resistencias elementales (fuego, hielo, rayo)
  - Slots de equipamiento (por definir cuántos)
  - Guild/Gremio (si pertenece a uno)
- Se puede abrir/cerrar durante el juego

### Regeneración de Recursos
- **Vida**: regenera SOLO fuera de combate (15s sin recibir daño). Velocidad: 1 + (VIT × 0.3) HP/s. Modificable por stats, equipamiento, buffs
- **Maná**: regenera SIEMPRE (incluso en combate), sin delay. Velocidad: 3 + (INT × 0.2) MP/s. Modificable por stats, equipamiento, buffs

---

## 15. Preguntas Abiertas (Por Definir)

- [ ] ¿Nombre definitivo del juego? (AGOD es provisional)
- [ ] ¿Qué porcentaje de probabilidad para modo Hardcore?
- [ ] ¿Tiempo límite para revivir a un Herido antes de que muera?
- [ ] ¿Cuántos cosméticos iniciales por clase?
- [ ] ¿Reglas de los duelos? (solo 1v1 o también equipos?)
- [ ] ¿Cuántas pociones se pueden llevar por run?

---

## 15. Visión a Futuro

El juego se diseña con arquitectura modular para que eventualmente pueda escalar a un **MMORPG online**. Decisiones clave: lógica de juego separada del networking, perfiles portables, sistema de clases como módulos. No se implementa nada de MMORPG ahora — solo se deja la puerta abierta.

---

*Documento vivo — se actualiza a medida que se definen nuevas mecánicas y decisiones.*
