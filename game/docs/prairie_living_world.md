# Pradera — Mundo Viviente

**Versión**: 1.0
**Fecha**: 2026-04-10
**Estado**: Design Document
**Departamento**: Game Design
**Relacionado**: `biome_prairie.md`, `project_loot_design.md`

Este documento define cómo la Pradera (Piso 1) se siente como un mundo HABITADO y no como una arena de combate. Cubre NPCs civiles, fauna pacífica, eventos dinámicos y el **Puesto de Guardia** (outpost fortificado).

---

## 1. Filosofía

La Pradera es el piso MÁS civilizado de la torre. El jugador acaba de salir de la taverna y entra aquí por primera vez — esta es su primera impresión del mundo. Tiene que sentirse:

- **Vivo** — cosas pasan sin el jugador
- **Creíble** — los NPCs tienen rutinas, motivaciones
- **Peligroso pero manejable** — hay amenazas pero también protección
- **Contrastado** — islas seguras rodeadas de wilderness

La tensión narrativa: el jugador ve un campesino feliz → 30 metros después ve un cadáver en el camino → entiende que el mundo es frágil.

---

## 2. Puesto de Guardia (Fortified Outpost)

### Concepto

Un mini-campamento fortificado ubicado en una **ubicación natural defensiva** (cima de colina suave, junto al río, borde del bosque con visión abierta). Es el **hub civilizado** del Piso 1 — el lugar al que el jugador vuelve entre peleas.

### Ubicación

Propuesta: en el cuadrante **noreste** del mapa, junto al camino principal que conecta la entrada (sur) con el jefe (norte). Sobre una colina baja con visión 360°. Cerca del lago para acceso a agua.

### Estructura física

```
                  ┌─ Torre de vigía
                  │     (arquero)
                  │
     ╔═══════╗   ╔╪═══════╗   ╔═══════╗
     ║ Muro  ║═══╬ PUERTA ╬═══║ Muro  ║
     ╚═══════╝   ╚════════╝   ╚═══════╝
         │       │        │        │
         │   ┌───┴──┐  ┌──┴───┐    │
         │   │Tienda │  │Fogata│    │
         │   │Merca- │  │central│    │
         │   │der    │  └──────┘    │
         │   └───────┘              │
         │                          │
         │   ┌───────┐  ┌───────┐   │
         │   │Cuartel│  │Stash  │   │
         │   │guardia│  │(baúl) │   │
         │   └───────┘  └───────┘   │
         │                          │
     ╔═══╬══════════════════════╬═══╗
     ║Muro                      Muro║
     ╚══════════════════════════════╝
```

### Elementos

| Elemento | Descripción | Función gameplay |
|----------|-------------|------------------|
| **Muros de madera** | 2-3m altura, estacas puntiagudas en el tope | Bloquean pathfinding de enemigos. Invulnerables |
| **Puerta principal** | Madera reforzada, siempre abierta de día | Entrada/salida del jugador |
| **Torre de vigía** | Plataforma de madera con arquero NPC (friendly) | Dispara a mobs que se acerquen |
| **Fogata central** | Llama animada, troncos alrededor | Punto de reunión visual. Sentarse = heal lento |
| **Tienda del mercader** | Carpa de tela con caja de madera adelante | NPC vendor (pociones, starter gear) |
| **Cuartel de guardia** | Tienda más grande, armas apoyadas | Spawn de patrullas |
| **Stash** | Baúl de madera grande | Almacenamiento persistente entre runs |

### NPCs del puesto

| NPC | Rol | Servicios |
|-----|-----|-----------|
| **Capitán Valdo** | Líder del puesto | Da quests diarias, lore |
| **Mercader Tomás** | Comerciante | Vende pociones, arcos, flechas, saetas |
| **Herrero Brunhilde** | Forja (futuro) | Reparar equipo, mejoras +1 |
| **Arquero de la torre** (x1) | Defensa pasiva | Dispara a mobs que se acercan |
| **Guardias patrulleros** (x4) | Patrullan el puesto + 30m alrededor | Matan mobs que se acerquen |
| **Sanadora Elena** | Healer NPC | Restaura HP completo por 10 oro |

### Comportamiento

- **De día**: puerta abierta, guardias patrullan, mercaderes abiertos, NPCs caminando
- **De noche** (si implementamos ciclo): puerta cerrada, más guardias en los muros, fogata central encendida, mobs más agresivos alrededor
- **Bajo ataque** (evento raro): si un bandido camp cercano está activo, mandan un asalto al puesto — el jugador puede ayudar a defender

---

## 3. Transeúntes del camino

### Carreta de mercader viajero

La carreta es el **NPC evento estrella** del Piso 1. Se mueve lentamente por el camino principal, vulnerable, y genera eventos dinámicos.

**Composición**:
- 1 carreta de madera tirada por caballo/buey (visual)
- 1 mercader al frente (NPC civil, débil)
- 1-2 guardias a los costados (NPCs con espada, level 3)

**Estados posibles** (uno cada vez que el jugador se encuentra una):

| Estado | Frecuencia | Lo que pasa |
|--------|-----------|-------------|
| **Tranquilo** | 40% | Solo caminan, saludos, posibles líneas de diálogo ambiental |
| **Emboscada de bandidos** | 25% | 3-4 bandidos los están atacando. Si ayudás → reward + discount permanente con ese mercader |
| **Rueda rota** | 15% | Carreta parada, mercader pide ayuda. Fetch quest: traer `material_iron x2` o pagar 20 oro. Reward: item random común |
| **Ya emboscada** | 10% | Llegás tarde. Cadáveres, carreta volcada, loot esparcido. Storytelling puro |
| **Pidiendo material** | 10% | Mercader te para, necesita `material_leather x3` para seguir viaje. Te paga bien |

### Peregrinos

Pequeños grupos (2-3) caminando hacia los **altares/ruinas** del mapa. Rezan al llegar. Pasivos. Si los matás, karma negativo (si implementamos).

### Pastores con rebaño

1-2 pastores con 4-6 cabras/ovejas. Se mueven lento por zonas abiertas. Si un lobo ataca al rebaño, el pastor pide ayuda. Reward: leche, carne, o favor.

### Cazadores

Se mueven en los bordes del bosque, cazan conejos/zorros de forma proactiva. **FRIENDLY** — atacan a wolves/wasps si los ven. Si los salvás de peligro, te dan info sobre POIs ocultos.

---

## 4. Fauna pacífica

No todo lo que se mueve ataca. Esto es clave para que el mundo respire.

| Fauna | Comportamiento | Interacción |
|-------|----------------|-------------|
| **Ciervo** | Pasta en praderas abiertas, huye al detectarte (20m) | Cazable, dropea `material_leather` + `material_fang` |
| **Conejo pacífico** | Salta cerca de madrigueras, se esconde al acercarte | Cazable, dropea `material_rabbit_pelt` |
| **Pájaros volando** | Vuelan en bandadas, se posan en árboles | Solo scenery, no cazable |
| **Mariposas** | Revolotean cerca de flores | Scenery puro |
| **Peces en el lago** | Se ven nadando bajo el agua | Futuro: pesca |
| **Ardillas** | Corren por troncos, recogen bellotas | Scenery + material raro |

**Regla**: fauna pacífica NO cuenta como "enemigo" para el sistema de combate. Tiene un grupo separado `"wildlife"` que se maneja diferente.

---

## 5. Eventos dinámicos ambientales

Momentos que el jugador encuentra en el mundo, por seed o aleatorios.

### Lista de eventos

1. **Caravana bajo ataque** (detallado arriba)
2. **Granja incendiada** — humo visible desde lejos, llegás y hay cadáveres, loot quemado, un bandido superviviente escondido
3. **Cazador herido** — pide ayuda, te guía a un campamento secreto si lo curás
4. **Gitanos en carreta** — comercian items raros por materiales específicos (economía alternativa)
5. **Niño perdido** — fetch quest simple cerca del puesto, reward de un aldeano agradecido
6. **Duelo de campesinos** — dos NPCs peleando con palos por apuesta, podés unirte como espectador o pelear
7. **Patrulla en combate** — llegás y los guardias están peleando contra un pack grande, podés ayudar
8. **Cofre olvidado** — un viajero dejó un cofre (hay una nota), legalmente es tuyo si lo encontrás
9. **Oración en altar** — un peregrino reza, te ofrece bendición temporal si lo escuchás
10. **Cadáver con carta** — cuerpo sin dueño, tiene una carta que revela la ubicación de un tesoro

### Frecuencia

- **2-3 eventos activos** a la vez en el mapa de 600x600m
- Cuando el jugador resuelve uno (o pasa mucho tiempo sin verlo), spawn de un nuevo evento en otra ubicación
- Los eventos tienen radio de ~80m — solo se activan visualmente cuando estás cerca

---

## 6. Densidades propuestas

| Elemento | Cantidad en 600x600m |
|----------|---------------------|
| Puesto de Guardia | 1 (fijo) |
| Pueblitos pequeños (3-5 casas) | 2 |
| NPCs civiles fijos (mercaderes, aldeanos) | 12-15 |
| Guardias del puesto (incluyendo torre) | 6 |
| Patrullas móviles (grupos de 2-3) | 3 grupos |
| Mercaderes viajeros (carreta) | 2-3 activos a la vez |
| Peregrinos | 4-6 en el mapa |
| Pastores + rebaños | 2-3 grupos |
| Cazadores | 5-7 |
| Fauna pacífica (ciervos, conejos, etc.) | 30-40 |
| Eventos dinámicos activos | 2-3 |
| **Enemigos hostiles (ya existentes)** | ~70 |

**Total de entidades "vivas"** en el mapa: ~150-180

---

## 7. Sistema de protección del puesto

El arquero de la torre y los guardias del perímetro son lo que hace que el puesto se **sienta seguro**:

- **Radio de defensa activa**: 30m alrededor del muro
- **Detección**: cualquier enemigo hostil dentro del radio es atacado por los guardias
- **Torre**: el arquero dispara a enemigos dentro de 25m desde la torre (daño moderado)
- **Reforzamiento**: si 5+ enemigos entran al radio, un guardia "llama refuerzos" y spawna 2 más en la puerta

Esto crea una mecánica natural: **el jugador aprende que cerca del puesto está seguro, lejos es peligroso**. Refuerza el diseño road/wilderness.

---

## 8. Implementación técnica (futuro — NO implementar ahora)

Cuando llegue el momento de implementar, estos son los componentes mínimos necesarios:

### Nuevos tipos de NPCs
- `BaseNPC` (CharacterBody3D) — hermano de BaseEnemy, con comportamientos pacíficos
- `CivilianNPC` — caminan rutas, dialogan al interactuar
- `GuardNPC` — patrullan, atacan hostiles, defienden área
- `MerchantNPC` — abren shop UI al interactuar
- `WildlifeNPC` — huyen, pueden ser cazados

### Sistemas de soporte
- `FactionManager` — relaciones amigable/neutral/hostil entre grupos
- `NPCRouteSystem` — waypoints para rutas de patrulla y caminos
- `DynamicEventManager` — spawna, trackea, y despawna eventos
- `DialogueSystem` — UI simple para hablar con NPCs

### Grupos nuevos
- `"civilians"` — NPCs pacíficos
- `"guards"` — NPCs que defienden al jugador
- `"wildlife"` — fauna no-combat
- `"merchants"` — tiene shop
- `"hostile_to_player"` (ya existe como `"enemies"`)

---

## 9. Prioridad de implementación (sugerida)

Cuando llegue el momento de convertir esto en código:

1. **Fase 1 — MVP del puesto** (el ancla)
   - Estructura visual (muros, puerta, tienda)
   - Capitán Valdo estático con diálogo básico
   - Mercader Tomás con shop UI funcional
   - Stash (baúl interactivo)
   - 1 guardia patrullando

2. **Fase 2 — Vida ambiental**
   - Fauna pacífica (ciervos, conejos)
   - Guardias del perímetro que atacan hostiles
   - Torre con arquero

3. **Fase 3 — Transeúntes**
   - Carreta del mercader viajero (estado "tranquilo" solo)
   - Peregrinos caminando

4. **Fase 4 — Eventos dinámicos**
   - Emboscada de caravana
   - Rueda rota
   - Otros eventos del punto 5

Cada fase es deployable por sí sola y agrega vida progresivamente al piso.

---

## 10. Preguntas abiertas (decisiones pendientes)

1. **¿Los NPCs civiles pueden morir?** Propuesta: sí, pero respawn después de X tiempo o al volver al piso.
2. **¿Sistema de karma?** Propuesta: si atacás a un civil, los guardias te marcan hostil por 10 minutos en el puesto.
3. **¿Los eventos son por seed o random?** Propuesta: la SEED del piso define cuáles están disponibles, el TRIGGER de activación es random en el tiempo.
4. **¿El stash es compartido entre runs?** Propuesta: sí, es el "almacén permanente del jugador" (ver `project_inventory_design.md`).
5. **¿Hay día/noche?** Propuesta: futuro. Por ahora, siempre es "día" en la Pradera.
6. **¿Hay más de un puesto?** Propuesta: 1 solo en Piso 1 (sensación de aislamiento civilizado). Pisos posteriores pueden tener más.
