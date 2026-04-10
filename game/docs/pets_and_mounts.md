# Mascotas y Monturas — Another Party Dungeon

**Versión**: 1.0
**Fecha**: 2026-04-10
**Estado**: Design Document
**Departamento**: Game Design
**Relacionado**: `party_activities.md`, `prairie_living_world.md`

Este documento define los sistemas de **mascotas** (compañeros pasivos/combat) y **monturas** (traversal en mapas abiertos). Son sistemas separados pero complementarios.

---

## 1. Filosofía general

### Mascotas
Compañeros con valor emocional. No son power fantasies — son adorables, memorables, opcionales. Conectan al jugador con el mundo más allá del combate.

### Monturas
Herramientas de traversal para mapas grandes. Funcionan solo en zonas abiertas. Permiten coop cooperativo en vehículos (la idea estrella: carro con pasajeros).

### Regla de oro
**Ni mascotas ni monturas rompen el balance del juego.** Las mascotas de combate son débiles o limitadas por cooldown. Las monturas no funcionan en dungeons interiores. Son capas de FUN, no power creep.

---

## 2. Sistema de Mascotas

### Tipos

#### Mascotas cosméticas (no-combat)

Solo te siguen, emiten sonidos, hacen animaciones. No pelean, no reciben daño (son intangibles o etéreas). Habilidades pasivas muy leves.

| Mascota | Obtención | Habilidad pasiva |
|---------|-----------|------------------|
| **Gatito atigrado** | Comprar 50 oro en la taverna | Ronronea cerca de fogata, +5% luck |
| **Gato negro** | Quest "La bruja del bosque" | Detecta trampas ocultas en un radio |
| **Gato blanco** | Cosmético raro de cofre | Ninguna, pura elegancia |
| **Perro pastor** | Quest del pastor (Pradera) | Ladra cuando hay enemigos cerca |
| **Perrito faldero** | Comprar 100 oro | Ninguna, compañía pura |
| **Lobo cachorro** | Drop raro del lobo adulto | +5% velocidad |
| **Cuervo** | Drop raro del bosque (Piso 2) | Trae 1 oro random al suelo por kill |
| **Halcón** | Drop de hawk | Señala enemigos lejanos con un brillo sutil |
| **Conejo pacífico** | Quest del niño perdido | Ninguna, pura cuteness |
| **Hada luciérnaga** | Drop de hada del Piso 2 | Ilumina radio de 3m (útil en cuevas) |
| **Slime bebé** | Drop raro del Rey Slime | Meta joke — dropea gel de vez en cuando |
| **Zorro albino** | Drop raro de zorro común | Ninguna, exclusividad |
| **Búho sabio** | Quest en biblioteca ruinosa | Marca POIs en el minimapa ocasionalmente |
| **Ardilla curiosa** | Spawn random cerca de árboles | Trae nueces que dan regen de stamina |
| **Pollito** | Quest del granjero | Crece con el tiempo → gallina → gallina dorada (años de juego) |
| **Mini dragón** | Drop legendario de dragones | Respira fuego cosmético sin daño |

#### Mascotas de combate

SÍ pelean con vos. Son drops raros o recompensas de quests difíciles. Balance: débiles pero útiles.

| Mascota | Clase ideal | Mecánica | Duración |
|---------|------------|----------|----------|
| **Lobo entrenado** | Ranger (Archer) | Ataca al mismo target que vos, 50% de tu damage | Permanente, puede morir temporalmente |
| **Esqueleto guerrero** | Necromancer (Creator) | Invocación temporal con cooldown | 3 min, 10 min cooldown |
| **Golem de piedra pequeño** | Mage (Arcano) | Tanqueo, absorbe hits por vos | Permanente |
| **Águila cazadora** | Ranger (Ranger) | Vuela sobre vos, señala enemigos lejanos + daño leve | Permanente |
| **Gato demonio** | Necromancer (Curses) | Dropea gemas malditas cuando mata enemigos | Permanente |
| **Oso guardián** | Warrior (Tank) | Provoca enemigos, tanquea | Permanente, puede morir temporalmente |
| **Fénix** | Mage (Elemental) | Revive una vez por run con pequeña explosión | Un uso por run |

### Sistemas comunes

#### Alimentar
Cada mascota tiene un **hambre** (slow decay). Si no comés, deja de seguirte (no muere — se esconde en la taverna hasta que la llames).

- Comida básica: cualquier item de `"type": "consumable"` tipo "food"
- Comida preferida: cada mascota tiene una favorita (gatos = pescado, perros = carne, cuervos = semillas)
- Comida preferida da bonus de bonding

#### Bonding
Nivel de vínculo con vos. De 0 a 100.
- Sube al alimentar, al tenerla cerca, al jugar con ella (interacción con petting)
- Alto bonding → animaciones especiales, más sonidos, mejor habilidad pasiva (escala con bonding)

#### Cosméticos para mascotas
Podés ponerles:
- **Collares** — cambia el color, a veces dropea de enemigos
- **Gorros** — cosméticos raros (un gato con sombrero de mago es oro)
- **Bandanas** — con colores del party
- **Armaduras mini** — versión cosmética de tu armadura

#### Ubicación
Las mascotas VIVEN en la taverna. Tenés un cuartito donde duermen cuando no las llamás.

- **Llamar mascota** — emote de silbido (tecla configurable)
- **Despedir temporalmente** — otro emote, vuelve a la taverna
- **Solo 1 mascota activa a la vez** (en el mundo contigo). Podés tener muchas guardadas.

### NPCs relacionados

- **Señora de los Gatos** — NPC en la taverna con 5-6 gatos. Vende, da quests de gatos perdidos
- **Domador de Bestias** — quest line para pets de combate
- **Veterinario** — cura mascotas heridas, vende items para ellas
- **Sastre de Mascotas** — vende cosméticos (gorros, collares, bandanas)

---

## 3. Sistema de Monturas

### Filosofía
Las monturas son para **traversal en mapas abiertos**. Con pisos de 600x600m, caminar se hace tedioso. Las monturas aceleran el movimiento + habilitan gameplay nuevo (combate montado, carros coop).

**Regla fundamental**: las monturas funcionan **SOLO en zonas abiertas**. En dungeons, cuevas, ruinas interiores no podés montar. Esto mantiene el ritmo de juego distinto entre exploración y dungeon crawl.

### Tipos de monturas

| Montura | Velocidad | Obtención | Zonas | Habilidad especial |
|---------|-----------|-----------|-------|-------------------|
| **Caballo común** | +40% | Comprar 500 oro | Exteriores | Ninguna |
| **Caballo de guerra** | +45% | Quest + 2000 oro | Exteriores | +50% damage en combate montado (Warrior) |
| **Jabalí gigante** | +50% | Drop de evento raro | Exteriores | Atropella mobs chicos |
| **Lobo de montaña** | +50% | Quest del Piso 3 | Exteriores + hielo | Salta más alto |
| **Grifo joven** | +60% | Quest legendaria Piso 2 | Exteriores abiertos | Planeo corto (tecla Space) |
| **Caballo fantasma** | +70% | Quest secreta | Exteriores, solo de noche | Atraviesa algunas walls |
| **Slime gigante** | +30% | Drop meta del Rey Slime | Exteriores | Rebota divertido, cosmético de broma |
| **Carro de cabras** | +35% | Comprar 1500 oro | Caminos abiertos | **COOP — 4 jugadores** |
| **Dragón joven** | +80% | Quest post Piso 50 | Exteriores + vuelo | Vuelo completo |

### Mecánicas

#### Invocar / Desmontar
- Tecla **Y** para invocar/desmontar
- Animación de aparición (estilo WoW — la montura viene de un portal)
- Si estás en zona interior, aparece un mensaje: "No podés invocar aquí"

#### Combate montado

Diferente por clase:

| Clase | Puede pelear montado | Penalización |
|-------|---------------------|--------------|
| **Warrior** | Sí (melee desde el caballo) | -20% precisión |
| **Archer** | **Sí, sin penalización** (es su fantasía) | Ninguna |
| **Mage** | **No** — las dos manos en las riendas | Tiene que desmontar |
| **Necromancer** | **No** — requiere concentración | Tiene que desmontar |
| **Cleric** | Parcial — solo buffs básicos, no smite | Magia mayor requiere desmontar |

#### Daño a la montura

- Las monturas RECIBEN daño pero tienen HP separado
- Si HP de montura llega a 0 → "desaparece" (no muere permanentemente)
- Vos caés al suelo con animación
- Cooldown de 2 minutos para volver a invocarla

#### Almacenamiento
- Las monturas viven en un "bolsillo dimensional" (como WoW)
- Podés tener muchas, invocás la que quieras
- La **activa** es la que aparece al apretar Y

### El Carro Cooperativo — La joya del sistema

**Carro tirado por cabras** — cabe **2-4 jugadores**. Uno conduce, los otros son pasajeros.

#### Roles en el carro

- **Conductor** (uno solo) — maneja la dirección y velocidad. No puede pelear.
- **Pasajeros** (hasta 3) — pueden:
  - Disparar desde atrás (Archer es el rey del carro)
  - Curar al conductor (Cleric puede castear desde el carro)
  - Usar habilidades defensivas (Mage barrera, Necromancer slowdown)
  - Solo ir sentados (modo turista)

#### Escenarios épicos

- **Huida de bandidos a caballo** — el carro huye mientras los pasajeros defienden
- **Viaje cooperativo** — todo el party viajando por la pradera, música del Cristal Cantor sonando
- **Persecución** — podés perseguir a otros enemigos/NPCs con el carro
- **Carrera entre parties** — eventos de race (futuro multiplayer)

#### Upgrades del carro
- **Refuerzos de madera** → más HP
- **Ruedas de hierro** → +velocidad
- **Caja trasera** → almacenamiento temporal para loot grande
- **Cañón pequeño** (rama Artillero del Archer) → arma fija

### NPCs relacionados

- **Caballerizo del Puesto** — vende caballo común + carro de cabras
- **Maestro de bestias del Piso 2** — quest line para monturas raras
- **Herrero de sillas** — vende cosméticos para monturas (sillas, adornos, armaduras decorativas)
- **Entrenador de monturas** — tutoriales in-game, te enseña cómo hacer combate montado

---

## 4. Integración con otros sistemas

### Con el Puesto de Guardia
El Puesto tiene un **establo** adyacente donde:
- Dejás monturas a descansar
- Comprás al caballerizo
- Acariciás tus pets

### Con los heists
- **El Huevo de la Dragona** requiere escapar en montura (tiempo límite)
- **El Cerdo del Aldeano** — más fácil atraparlo si 1 jugador está en caballo
- **La Carrera del Caballo Fantasma** — si la ganás, obtenés el caballo fantasma como montura

### Con el sistema de combate
- Combate montado tiene sus propias animaciones (necesita asset work)
- Algunos enemigos son más difíciles contra jugadores montados (ej: arqueros enemigos apuntan a la montura)

### Con el sistema de inventario
- Las monturas de carga (futuro) pueden llevar items extra
- Las mascotas NO ocupan inventario — son un sistema separado

---

## 5. Prioridad de implementación

**NO es para MVP**. Todo esto es post-MVP después de:
- Piso 1 funcional
- Coop online básico
- Boss del Piso 1 (Rey Slime)

### Fase A — Mascotas cosméticas básicas
1. Sistema de pet following + animaciones
2. 3-5 mascotas iniciales (gatito, perro, cuervo)
3. Llamar/despedir con emote
4. Alimentación básica

### Fase B — Mascotas de combate simples
5. Lobo entrenado (el más simple)
6. Esqueleto guerrero (para Necromancer)
7. Sistema de cooldowns y daño

### Fase C — Monturas básicas
8. Caballo común (sin combate montado)
9. Invocar/desmontar
10. Zonas abiertas vs interiores

### Fase D — Combate montado
11. Animaciones para cada clase
12. Penalizaciones por clase
13. Daño a montura

### Fase E — Carro cooperativo ⭐
14. Sistema de vehículo multi-pasajero
15. Sincronización de roles
16. Este es el gran hito — habilita gameplay coop único

### Fase F — Expansión
17. Monturas raras (grifo, jabalí, dragón)
18. Mascotas legendarias
19. Cosméticos para pets y mounts
20. NPCs completos (Señora de los Gatos, etc)

---

## 6. Preguntas abiertas

1. **¿Las mascotas pueden MORIR permanentemente o siempre se recuperan?** Propuesta: siempre recuperables (es frustrante perder un pet).
2. **¿Combat pets afectan el balance del juego?** Propuesta: débiles pero útiles, escalan con bonding para que valgan la pena invertir tiempo.
3. **¿Las monturas tienen estadísticas propias (HP, speed, stamina)?** Propuesta: sí, pero no afectan combate directo.
4. **¿Se pueden PERDER monturas permanentemente?** Propuesta: no, solo cooldown al morir.
5. **¿Hay rides compartidos (alguien monta atrás en TU caballo)?** Propuesta: solo carro de cabras permite multi-passenger, los caballos son single-rider.
6. **¿Pets cosméticos se "pierden" al morir en dungeon?** Propuesta: no, son independientes del inventario.
7. **¿Monturas únicas entre clases?** Propuesta: todas las monturas son usables por todas las clases, solo cambia qué tan efectivo es el combate montado.
