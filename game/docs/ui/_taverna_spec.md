# Spec — Taverna Lobby (dept/design, v2.0 REWRITE 2026-04-23)

**Leer antes**: `_world_canon.md` v2.0 §11 (La Taberna — zona neutral cross-orden), GDD §3 (NPCs, lobby), `balance_v2.md` (enhancement +1/+9, loot system).
**Estado**: v2.0 REWRITE — adapta NPCs y estética a canon **hub planetario**. Reemplaza v1.0 (chilena).
**Scope**: escena de lobby post-main menu y entre runs. Zona segura, sin combate, acceso a servicios permanentes + transición a pisos.

---

## §1. Concepto — Taberna cosmopolita de la Ciudad de la Torre

La Taberna no es un taverna europea genérica. Es el **salón multicultural** del Gremio de la Torre, construido alrededor de la base de la Torre, donde aventureros de todas las culturas del mundo convergen a descansar entre runs.

Canon `_world_canon.md §2` (hub planetario): la Ciudad creció 60+ años agregando elementos de cada ola de migrantes. La Taberna es la manifestación más visible de esa fusión — **vigas nórdicas + mosaicos árabes + biombos japoneses + textiles africanos + braseros andinos**, todo en el mismo edificio, todo funcionando.

Canon `_world_canon.md §11`: zona neutral cross-orden. Warriors, Mages, Archers, Clerics, Necromancers y Danzantes comparten el espacio sin violencia. La Regla del Gremio: ningún conflicto de orden escala adentro.

**Estética multicultural clave**:

- **Vigas y columnas de madera oscura** nórdicas (pino tratado, tallado con runas en las esquinas) — referencia escandinava.
- **Piso de mosaico árabe-persa** (patrones geométricos estrellados, baldosas azul cobalto y blanco marfil) — referencia islámica medieval.
- **Biombos japoneses (shōji)** dividiendo rincones privados — papel de arroz + marcos de bambú.
- **Tapices y textiles africanos** (patrones kente, bogolán maliense, kitenge swahili) en paredes como aislación y decoración.
- **Chimenea central de piedra volcánica** (piedra oscura pulida, referencia andina y polinesia — el brasero central es el corazón que toda la Ciudad reconoce como "casa común").
- **Farolitos colgantes mixtos**: algunos de papel (chōchin japoneses), algunos de bronce trabajado (árabes con patrones caligráficos), algunos de hierro forjado (nórdicos).
- **Altar neutral**: un nicho pequeño con pequeños tributos de varias tradiciones (una vela, un incienso, un hilo rojo, una moneda de cobre). No es un altar religioso funcional — es un gesto de respeto generalizado.

**Paleta**: marrones tierra (maderas) + ocre + azul cobalto (mosaico árabe) + rojo laca (japonés) + dorado caligrafía (árabe) + verde musgo (textiles africanos) + naranja fuego central. Los Danzantes ocupan el único rincón **negro/violeta tenue** — contraste intencional.

---

## §2. Layout — Vista 2D desde arriba (ASCII)

```
╔══════════════════════════════════════════════════════════════════╗
║                        PUERTA ENTRADA                            ║
║                           ↕                                      ║
║   ┌──────────┐   ┌───────────────────┐   ┌────────────────────┐  ║
║   │ RINCÓN   │   │                   │   │    ZONA FOGÓN      │  ║
║   │ DANZANTE │   │    BARRA + MESAS  │   │    (chimenea)      │  ║
║   │ (oscuro) │   │    CENTRALES      │   │    Libro Retornos  │  ║
║   └──────────┘   │                   │   └────────────────────┘  ║
║                  └───────────────────┘                           ║
║   ┌──────────────────────────────────────────────────────────┐   ║
║   │              CORREDOR DE SERVICIOS                       │   ║
║   │   [ZAHRA]    [BRANDR]    [AYANA]     [STASH COFRE]      │   ║
║   └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║   ┌──────────────────────────────────────────────────────────┐   ║
║   │              PUERTA TRASERA → TORRE                      │   ║
║   └──────────────────────────────────────────────────────────┘   ║
╚══════════════════════════════════════════════════════════════════╝
```

**Dimensiones referenciales (Godot scene)**: ~25m × 15m (espacio interior). Escala first-person: techo a 4m de altura. La puerta trasera da a un corredor breve hacia la base de la Torre (portal dimensional — el jugador NO ve la torre "entera" desde adentro; la transición es el corredor).

**Zonas funcionales**:

| Zona | Descripción | Nodos Godot sugeridos |
|------|-------------|----------------------|
| Barra + mesas centrales | Espacio de ambient + decoración. Sin interacción funcional en Fase 1. Mesas largas de madera estilo nórdico + bancos bajos tipo tatami al fondo. | `StaticBody3D` × mesas/sillas, `MeshInstance3D` decoración |
| Rincón Danzante | Oscuro, biombo shōji medio cerrado, con buena visibilidad de la puerta. Los que vienen de linajes sombríos siempre saben dónde está la salida. | `OmniLight3D` muy tenue, mesh silla simple |
| Zona Fogón | Chimenea central + vitrina con Libro de Retornos. `InteractableObject` (consultar Libro = lore log futuro). Altar neutral adyacente. | `CPUParticles3D` (fuego), `StaticBody3D` vitrina |
| Corredor de Servicios | Los 3 NPCs interactuables + cofre de stash. La zona de jugabilidad real del lobby. | Ver §3 |
| Puerta Entrada | Trigger de entrada desde main menu. Arco con mosaico árabe en el dintel. | `Area3D` trigger |
| Puerta Trasera → Torre | Trigger de transición al piso. Usa `Ayana` para activar (ver §3.3). Arco simple de piedra. | `Area3D` trigger |

---

## §3. NPCs interactuables (3 canónicos)

### 3.1 Asesora Zahra — Contratos + Stash + Equipment Manager

**Canon ref**: `_world_canon.md §4` v2.0. Nombre: **Zahra** (árabe — "flor, brillo, blancura radiante"). Representante del Gremio de la Torre. Origen cultural: árabe-magrebí (norte de África / mundo árabe medieval).

**Posición en escena**: mesa alta al fondo del corredor de servicios, vista a toda la sala. De espaldas a la pared — nunca da la espalda a la puerta. Siempre tiene un libro abierto frente a ella (un registro de contratos encuadernado en cuero con caligrafía árabe en el lomo).

**Descripción visual**: mujer 45-60 años. Túnica oscura (azul cobalto o verde oliva profundo) con bordados dorados en hilo de oro en los puños y el cuello (patrones geométricos árabes — arabescos estilizados). Cabello oscuro recogido bajo un pañuelo de seda liviano (hijab informal, estilo magrebí, no religioso-estricto sino cultural). Ojos de kohl. Anillos de plata con piedras semipreciosas en dos dedos. Expresión: profesional, paciente, ligeramente cínica. No tiene armadura — es gestora, no aventurera.

**Línea de identidad**: *"Volviste. Hamdullah. ¿Qué trajiste?"*
(Hamdullah = "gracias a Dios" en árabe — lo usa como "menos mal".)

**Servicios disponibles (Fase 1)**:

| Servicio | Descripción | Implementación |
|----------|-------------|----------------|
| **Stash personal** | Inventario permanente almacenado en Taberna. Safe entre runs — el loot de carrera se pierde al morir, pero el stash no. | `StashUI` escena con grid 5×8 = 40 slots. Persiste en `SaveManager.save_stash()`. |
| **Equipment Manager** | Equipar/desequipar ítems del inventario actual y del stash. | Integra `InventoryManager` + `EquipmentSlots` ya existente. |
| **Contratos de Gremio** | Lista de misiones activas del Gremio (pagar por info, matar específico, catalogar enemigo). Futuro — Fase 2. | Placeholder UI. |

**Interacción UI**: press `E` al acercarse → abre panel flotante `Control` con 3 tabs: `Stash`, `Equipar`, `Contratos`. Mismo estilo que inventory/tooltip existente.

**Líneas de diálogo**:
- Primera vez: *"Zahra. Asesora del Gremio. Estos son los servicios que el contrato incluye."*
- Al abrir Stash: *"Yo lo guardo. Hasta que vuelvas, insha'Allah."* (pausa) *"O hasta que no vuelvas."*
- Al morir y volver: *"Otra vez. Bien. El Gremio registró la caída."*
- Exorcista + Necromancer en escena simultáneamente: *"Yalla — resuelvan sus diferencias afuera."* (sin mirar)
- Al entregar contrato completado: *"Ashe. El Gremio paga."* (usa una palabra yoruba que aprendió de Ayana — detalle menor, muestra que los NPCs se influyen entre sí)

---

### 3.2 Herrero Brandr — Enhancement +1/+9

**Canon ref**: `_world_canon.md §9.2` v2.0. Nombre: **Brandr** (nórdico antiguo — "hoja de espada, fuego, tizón ardiente"). Origen cultural: escandinavo / norte de Europa (equivalente fantasy a un herrero islandés o noruego medieval).

**Posición en escena**: fragua pequeña lateral en el corredor de servicios (con chimenea y ventana al exterior para ventilación). Yunque nórdico de hierro forjado, brasas naranjas, herramientas (martillos de distintos tamaños, tenazas, limas). Siempre trabajando — el jugador lo interrumpe.

**Descripción visual**: hombre 50s. Herencia nórdica — barba rojiza trenzada (con anillos de bronce), cabello largo atado atrás. Piel pálida con pecas. Mandil de cuero oscuro sobre torso desnudo (brazos expuestos muestran tatuajes runicos — patrones de vinculación al fuego). Brazos enormes, cicatrices de fragua. Un martillo colgando del cinturón.

**Línea de identidad**: *"¿Querés que lo mejore o que te explique qué es un yunque?"*

**Servicios disponibles (Fase 1)**:

**Enhancement +1 a +9** — Canon `balance_v2.md` (ítem enhancement con chance de romper):

| Nivel | Costo oro | Chance éxito | Chance romper ítem |
|-------|-----------|--------------|-------------------|
| +1 | 100 | 95% | 0% |
| +2 | 200 | 90% | 0% |
| +3 | 400 | 80% | 5% |
| +4 | 800 | 70% | 10% |
| +5 | 1.600 | 60% | 15% |
| +6 | 3.200 | 50% | 20% |
| +7 | 6.400 | 40% | 30% |
| +8 | 12.800 | 30% | 40% |
| +9 | 25.600 | 20% | 50% |

- **Éxito**: ítem sube +1 nivel. Los stats del ítem suben según rareza y tipo (canon `p1_loot_table.md`).
- **Falla (sin romper)**: ítem mantiene nivel. Oro consumido igual.
- **Romper**: ítem se destruye. Oro consumido. Solo ocurre desde +3 en adelante.
- **Enhancement Stone** (ítem especial): reduce chance de romper −20% por stone usada. Drop en pisos — B implementa como consumible stackeable.

**Interacción UI**: press `E` → abre panel `EnhancementUI`. Drag ítem al slot central → se muestran stats del ítem actual, stats proyectadas si sube, costo oro, probabilidades. Botón `Reforzar`. Animación corta de fragua si hay éxito (chispas, sonido martillo). Animación de ruptura si el ítem se destruye (Brandr hace gesto de disculpa breve).

**Líneas de diálogo**:
- Al abrir sin ítems: *"Traé algo que valga el carbón primero."*
- Al fallar sin romper: *"Quedó igual. La fragua no promete nada."*
- Al romper un ítem +5: *"Lo siento."* (pausa corta, sin drama) *"Eldr no perdona."* (eldr = "fuego" en nórdico antiguo).
- Al lograr +9: *"Skål."* (brindis nórdico — la única vez que Brandr para de trabajar, alza una jarra imaginaria y vuelve al yunque)
- Al jugador Necromancer: *"Tu metal está frío de otra manera."* (observación, sin juicio — Brandr no discrimina cliente pero nota)

---

### 3.3 Mensajera Ayana — Party Invite + Siguiente Piso

**Canon ref**: `_world_canon.md §9.2` v2.0. Nombre: **Ayana** (yoruba/etíope — "bella flor, floración eterna"; en algunas tradiciones orales africanas también significa "la que anuncia", apropiado para mensajera). Origen cultural: África occidental / cuerno de África (mezcla yoruba-etíope fantasy).

**Posición en escena**: de pie cerca de la Puerta Trasera → Torre. Siempre en movimiento leve — nunca quieta del todo. Camina lento loop 3m de radio. Nunca se sienta.

**Descripción visual**: mujer joven, 25-30. Herencia africana — piel oscura profunda, cabello recogido en trenzas finas (braids estilo yoruba con cuentas de madera en las puntas). Ojos oscuros con delineado simple. Capa corta de viaje en patrón kitenge (textil africano oriental — patrones geométricos amarillos y rojos sobre fondo negro). Debajo: ropa de cuero flexible para correr. Mensajero bag al hombro (piel curtida, cierres de bronce). Brazaletes de cuerda trenzada en ambas muñecas.

**Línea de identidad**: *"Cuando estén listos, yo llevo el mensaje."*

**Servicios disponibles (Fase 1)**:

| Servicio | Descripción | Implementación |
|----------|-------------|----------------|
| **Party Invite** | Invitar a jugadores a la party antes del run. Multiplayer futuro. En Fase 1: solo modo "1 jugador" visible pero placeholder para expansión. | `PartyPanel` UI con slots 1-6, botón invite (disabled en Fase 1 si multiplayer no implementado). |
| **Siguiente Piso** | Lanzar el run — carga la escena del piso siguiente. | Trigger transición a `piso_1.tscn` (o procedural gen futuro). Ejecuta `SaveManager.save_run_start()` antes de cambiar escena. |
| **Dificultad / opciones de run** | Configurable antes de entrar. Futuro — Fase 2. | Placeholder dropdown. |

**Flujo transición al piso**:

```
Jugador press E en Ayana
    ↓
Abre PartyPanel (futuro multiplayer) + botón "Entrar al Piso"
    ↓
[Confirmar]
    ↓
SaveManager.save_run_start(floor_number, party_composition)
    ↓
SceneManager.transition_to(next_floor_scene)
    ↓
Fade to black + load screen (futuro)
    ↓
Piso carga
```

**Líneas de diálogo**:
- Primera vez: *"¿Primera vez? La Torre no avisa cuando cambia de humor. Selam, aventurero."* (selam = "paz" en amárico etíope)
- Antes de entrar solo: *"¿Solo? El Gremio registra igual. Ashe."* (ashe = "así sea" yoruba — usado como confirmación/bendición)
- Al volver de un run exitoso: *"Volviste. La Torre los dejó ir esta vez."*
- Al volver con el equipo completo: *"Todos volvieron."* (cabeceo leve) *"Eso es raro. Buen día."*
- Al Warrior y Cleric haciendo Oración del Muro: *"Les doy tiempo."* (espera paciente a que terminen el ritual antes de ofrecer el portal)

---

## §4. Stash + cofre visual

Además de los 3 NPCs, hay un **cofre físico** en el corredor de servicios — es el `StaticBody3D` visual del stash. El jugador puede interactuar con el cofre directamente (alternativo a Zahra) para abrir solo el panel de Stash sin las otras tabs. Es QoL: acceso rápido al inventario sin hablar con el NPC.

**Tipo**: cofre grande de madera oscura (nórdica) con herrajes de bronce envejecido y refuerzos de hierro. Tapa curva tipo arca. Cerradura pesada con decoración árabe incisa (patrón geométrico) — la fusión cultural también está en los objetos. Textura `standard_material` low-poly consistente con el estilo del juego.

---

## §5. Transiciones — cuándo aparece la Taberna

| Situación | Desde | Acción |
|-----------|-------|--------|
| Inicio del juego (post-main menu) | Main menu → Taberna | `SceneManager.load("taverna.tscn")` directamente. Fade in. |
| Vuelta de run exitoso | Último piso del run → Taberna | `SaveManager.save_run_end(loot_list)` → `SceneManager.transition("taverna.tscn")`. Loot del run aparece en cofre stash automáticamente (opcional: animación de "depósito"). |
| Muerte | Cualquier piso → Taberna (sin loot del run) | `SaveManager.save_death()` → `SceneManager.transition("taverna.tscn")`. Zahra tiene línea de muerte. El cofre NO recibe loot del run caído (permadeath loot — canon GDD). |
| Entre runs | Ya en Taberna | El jugador accede libremente a los NPCs. |

**Música** (placeholder canon): ambiente suave de taberna cosmopolita. Loop fusión: oud árabe + shamisen japonés + percusión leve africana + voz a capela en lengua indistinta. Sin percusión fuerte — debe sentirse como descanso real después del piso. Referencia sugerida: bandas sonoras de tabernas multiculturales estilo Dragon Age / Elder Scrolls pero con fusión real de instrumentos world. Post-Fase1: implementar `AudioStreamPlayer` con loop ambient multicultural.

---

## §6. Save integration

La Taberna es el único punto donde `SaveManager` hace save completo del estado del jugador:

```gdscript
# Al llegar a la Taberna (desde cualquier origen):
SaveManager.save_player_state(player)   # stats, nivel, skill points
SaveManager.save_stash(stash_contents)  # inventario permanente
SaveManager.save_run_result(result)     # outcome del último run (éxito/muerte/loot)

# Al salir de la Taberna (al piso):
SaveManager.save_run_start(floor_num, loadout)  # checkpoint de inicio del run
```

**NO hay auto-save en pisos** (canon permadeath — si morís en el piso, el último save es el de la Taberna). Esta decisión implica que la Taberna es el "grace site" de Dungeon Party — es el anchor seguro del mundo.

---

## §7. Godot scene structure

```
Taverna.tscn
├── Environment3D (WorldEnvironment — luz cálida, shadows suaves)
├── DirectionalLight3D (sol filtrado por ventanas — ángulo bajo)
├── OmniLight3D × varios (braseros + chimenea — luz dinámica naranja)
├── TabernaGeometry (StaticBody3D) — paredes, suelo, techo, mobiliario
│   ├── MeshInstance3D — building shell
│   ├── MeshInstance3D × mesas/sillas/barra (estilo nórdico + tatami fondo)
│   ├── MeshInstance3D × biombos shōji japoneses (rincón Danzante)
│   ├── MeshInstance3D × tapices africanos kente (paredes)
│   ├── MeshInstance3D × mosaico árabe (piso)
│   └── MeshInstance3D × decoración adicional (altar neutral, faroles mixtos)
├── ChimeneyParticles (CPUParticles3D) — fuego central
├── NPCGroup
│   ├── NPC_Zahra (CharacterBody3D o StaticBody3D + Area3D interact)
│   │   └── InteractionArea (Area3D trigger E)
│   ├── NPC_Brandr (CharacterBody3D o StaticBody3D)
│   │   └── InteractionArea (Area3D trigger E)
│   └── NPC_Ayana (CharacterBody3D caminando lento loop)
│       └── InteractionArea (Area3D trigger E)
├── StashChest (StaticBody3D + Area3D interact)
├── TriggerEntrance (Area3D) — entrada del player al cargar escena
├── TriggerToTower (Area3D) — activado solo por Ayana confirm
└── UILayer (CanvasLayer)
    ├── InteractionPrompt (Label "Presioná E")
    ├── StashUI (Control — hidden by default)
    ├── EnhancementUI (Control — hidden by default)
    └── PartyPanel (Control — hidden by default)
```

---

## §8. Ambient detail — Tradiciones canónicas de la Taberna

Canon `_world_canon.md §11`:

- **Rincón Danzante**: el rincón oscuro de la Taberna tiene una silla baja y una mesa sin velas, protegido por un biombo shōji medio cerrado. Los Danzantes tararean ahí melodías antiguas de sus linajes (mezcla ambigua — el jugador no identifica la cultura exacta porque es **intencionalmente no-identificable**, los Danzantes preservan tradiciones que ya no se enseñan abiertamente). Implementación: `AudioStreamPlayer3D` ambiental muy tenue con loop de 2-3 notas repetidas, filtrado bajo.

- **Oración del Muro**: una mesa privada en el fogón, con sillas para 6. Dos sillas siempre quedan vacías (tradición — para los que no volvieron). Warriors y Clerics hacen la *Oración del Muro* ahí 60s antes de run. Implementación Fase 1: NPC Warrior estático + NPC Cleric estático (decorativos) sentados ahí como ambient detail.

- **Rangers invitan primera ronda**: la primera vez que el jugador entra a la Taberna, hay un `DialogueTrigger` de ambient: un NPC Ranger-silhouette en la barra deja una jarra (sin palabras). Los Artilleros piden la última ronda con un toast ruidoso. Es sabor — no mecánica.

- **Libro de Retornos**: vitrina del fogón, interactuable. Abre un log de texto de todas las veces que el jugador terminó un run exitoso (fecha, piso alcanzado, party). Es el lore-journal in-game de cada corrida exitosa. El Gremio mantiene una copia central en la Ciudad — este es el de la Taberna. Sin entradas de muertos — el silencio es canon.

- **Altar neutral**: nicho pequeño junto al fogón, con pequeños tributos de varias tradiciones (una vela corta, un incienso apagado, un hilo rojo atado a un clavo, una moneda de cobre, un pétalo seco). No es un altar religioso funcional — es un gesto colectivo. Cualquier aventurero puede dejar un objeto pequeño al irse. Los objetos se rotan solos (ambient decorativo, no mecánica).

---

## §9. Handoff

**B (gameplay)**:
- Crear `game/scenes/taverna/taverna.tscn` + `taverna.gd` (script de escena para interacciones).
- Implementar `InteractionSystem` (press E cerca de NPCs/cofre → abre UI correspondiente). Si ya existe en otro contexto, reusar.
- `NPC_Zahra.gd`: abrir `StashUI` / `EquipmentUI` con tabs. Integrar con `SaveManager.save_stash()`.
- `NPC_Brandr.gd`: lógica de enhancement. Función `try_enhance(item, enhancement_level) -> bool`. Tabla de probabilidades de §3.2 hardcodeada en `NPC_Brandr.gd` o como `@export var` configurable.
- `NPC_Ayana.gd`: lógica de party panel + trigger de transición a piso. Ejecutar `SaveManager.save_run_start()` antes de scene change.
- `StashChest.gd`: alternativa directa al panel de stash de Zahra (abre solo el tab Stash).
- Save integration: `SaveManager.save_player_state()` + `save_stash()` al llegar a la Taberna (señal `taverna_entered`).
- Música ambient: `AudioStreamPlayer` en `taverna.gd` con loop de ambient multicultural (usar placeholder hasta D provea track).
- Transición desde piso: añadir llamada a `SceneManager.transition_to("res://scenes/taverna/taverna.tscn")` en `main.gd` o `GameManager` al finalizar run.

**D (art)**:
- Modelo 3D `taverna.tscn` — building shell low-poly estilo del juego. Escala: 25m × 15m interior, techo 4m.
- Materiales mezclados:
  - Madera oscura nórdica (vigas, mesas, barra, cofre)
  - Mosaico árabe (piso — patrón geométrico estrellado, azul cobalto + marfil)
  - Bambú + papel arroz (biombos shōji rincón Danzante)
  - Textil kente africano (tapices pared)
  - Piedra volcánica (chimenea central)
- 3 modelos NPC canon:
  - **Zahra**: mujer árabe-magrebí 45-60, túnica bordada, pañuelo, kohl, anillos.
  - **Brandr**: hombre nórdico 50s, barba trenzada rojiza, mandil de cuero, tatuajes runicos brazos, martillo al cinturón.
  - **Ayana**: mujer africana 25-30, braids con cuentas, capa kitenge, bag mensajero, brazaletes trenzados.
- Objetos: cofre stash (madera nórdica + herrajes árabes), vitrina Libro de Retornos, mesa Oración del Muro, chimenea, altar neutral con mini tributos.
- Iluminación: cálida, braseros + chimenea + faroles colgantes mixtos (papel japonés + bronce árabe + hierro nórdico). No usar luz azul/fría — la Taberna es refugio.
- Ambiente visual: respetar `_world_canon.md §2.3` — fusión orgánica, no caricaturas.

**QA**:
- `test_taverna_interactions.gd`: verificar que los 3 NPCs abren sus UIs correctamente, que el stash persiste entre recargas de escena, que la transición al piso ejecuta `save_run_start()` antes de cambiar escena, que la muerte no deposita loot del run en el stash.

---

## §10. Migración desde v1.0 (chilena)

| Rol | v1.0 (descartado) | v2.0 (canon) |
|-----|-------------------|--------------|
| Asesora Gremio | Millaray (mapudungun "flor dorada") | **Zahra** (árabe "flor, brillo") |
| Herrero | Kutrán (mapudungun "dolor") | **Brandr** (nórdico "hoja, fuego") |
| Mensajera | Mensajera Lefkén (mapudungun "rápidos") | **Ayana** (yoruba/etíope "bella flor, anunciadora") |

**Paleta/estética v1.0 chilena pura** (lenga + piedra volcánica andina + textiles mapuche + llamas disecadas) → **v2.0 multicultural** (madera nórdica + mosaico árabe + shōji japonés + textiles africanos + piedra volcánica genérica). La piedra volcánica sobrevive como elemento pero sin referencia chilena explícita — es piedra oscura pulida de origen ambiguo.

---

*Spec Taverna v2.0 — dept/design C, 2026-04-23. Zona neutral cross-orden canon `_world_canon.md §11` v2.0. Los 3 NPCs Zahra, Brandr, Ayana son canon multicultural. Reemplaza spec v1.0 (chilena, 2026-04-18).*
