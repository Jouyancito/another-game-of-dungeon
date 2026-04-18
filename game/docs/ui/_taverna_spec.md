# Spec — Taverna Lobby (dept/design, ola 2, 2026-04-18)

**Leer antes**: `_world_canon.md` §11 (La Taberna — zona neutral cross-orden), GDD §3 (NPCs, lobby), `balance_v2.md` (enhancement +1/+9, loot system).
**Estado**: Draft canon — handoff a B (scripts NPCs), D (modelos + ambientación), QA.
**Scope**: escena de lobby post-main menu y entre runs. Zona segura, sin combate, acceso a servicios permanentes + transición a pisos.

---

## §1. Concepto — Taberna de montaña chilena

La Taberna no es un taverna europea genérica. Es un edificio construido **en la ladera de una montaña**, adyacente a la base de la Torre. Arquitectura: **piedra volcánica andina + madera de lenga/ñirre** (árboles patagónicos reales, madera dura y oscura). Techo de pizarra andina inclinado. Chimenea central de piedra volcánica que nunca se apaga.

Canon `_world_canon.md §11`: zona neutral cross-orden. Warriors, Mages, Archers, Clerics, Necromancers y Danzantes comparten el espacio sin violencia. La Regla del Gremio: ningún conflicto de orden escala adentro.

**Estética chilena clave**:
- Maderas oscuras del sur (lenga, alerce — colores naturales sin pintura)
- Piedra volcánica irregular (Llaima, Villarrica — el Sínodo sugirió usar piedra de los volcanes sagrados en la construcción, hace ~40 años)
- **Piso de huevo** (baldosas hexagonales de barro cocido, técnica colonial chilena)
- Tejidos mapuche en decoración de paredes (sin fetichismo — son objetos funcionales: frazadas, cojines de corrida de caballos, cortinas de lana)
- **Llamas disecadas** como decoración — referencia andina norte (Atacama, los Vigilantes trajeron la tradición)
- Luz de velas y braseros (no hay electricidad ni magia luminosa visible — la taberna es cálida, no brillante)

**Paleta**: marrones tierra + ocre andino + gris pizarra + naranja fuego (braseros). Acento azul volcánico en detalles del Sínodo (vitrales pequeños). Negro/violeta casi invisible en el rincón donde los Danzantes tararean.

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
║   │  [MILLARAY]   [HERRERO]   [MENSAJERA]   [STASH COFRE]   │   ║
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
| Barra + mesas centrales | Espacio de ambient + decoración. Sin interacción funcional en Fase 1. | `StaticBody3D` × mesas/sillas, `MeshInstance3D` decoración |
| Rincón Danzante | Oscuro, con buena visibilidad de la puerta. Los Hijos siempre saben dónde está la salida. | `OmniLight3D` muy tenue, mesh silla simple |
| Zona Fogón | Chimenea central + vitrina con Libro de Retornos del Sínodo. `InteractableObject` (consultar Libro = lore log futuro). | `CPUParticles3D` (fuego), `StaticBody3D` vitrina |
| Corredor de Servicios | Los 3 NPCs interactuables + cofre de stash. La zona de jugabilidad real del lobby. | Ver §3 |
| Puerta Entrada | Trigger de entrada desde main menu. | `Area3D` trigger |
| Puerta Trasera → Torre | Trigger de transición al piso. Usa `Mensajera` para activar (ver §3.3). | `Area3D` trigger |

---

## §3. NPCs interactuables (3 canónicos)

### 3.1 Asesora Millaray — Contratos + Stash + Equipment Manager

**Canon ref**: `_world_canon.md §4`. Nombre: Millaray (flor dorada, mapudungun). Representante del Gremio de la Torre.

**Posición en escena**: mesa alta al fondo del corredor de servicios, vista a toda la sala. De espaldas a la pared — nunca da la espalda a la puerta. Siempre tiene un libro abierto frente a ella.

**Descripción visual**: mujer 45-60 años. Poncho liviano lana gris sobre ropa de trabajo. Cabello oscuro recogido. Expresión: profesional, paciente, ligeramente cínica. No tiene armadura — es gestora, no aventurera.

**Línea de identidad**: *"¿Volviste. Bien. ¿Qué trajiste?"*

**Servicios disponibles (Fase 1)**:

| Servicio | Descripción | Implementación |
|----------|-------------|----------------|
| **Stash personal** | Inventario permanente almacenado en Taberna. Safe entre runs — el loot de carrera se pierde al morir, pero el stash no. | `StashUI` escena con grid 5×8 = 40 slots. Persiste en `SaveManager.save_stash()`. |
| **Equipment Manager** | Equipar/desequipar ítems del inventario actual y del stash. | Integra `InventoryManager` + `EquipmentSlots` ya existente. |
| **Contratos de Gremio** | Lista de misiones activas del Gremio (pagar por info, matar específico, catalogar enemigo). Futuro — Fase 2. | Placeholder UI. |

**Interacción UI**: press `E` al acercarse → abre panel flotante `Control` con 3 tabs: `Stash`, `Equipar`, `Contratos`. Mismo estilo que inventory/tooltip existente.

**Líneas de diálogo (español Rioplatense — NPC habla formal con tono cínico)**:
- Primera vez: *"Millaray. Asesora del Gremio. Estos son los servicios que el contrato incluye."*
- Al abrir Stash: *"Guardé todo. Hasta que volvás."* (pausa) *"O no."*
- Al morir y volver: *"Otra vez. Bien. El Gremio registró la caída."*
- Exorcista + Necromancer en escena simultáneamente: *"Resuelvan sus diferencias fuera."* (sin mirar)

---

### 3.2 Herrero Kutrán — Enhancement +1/+9

**Nombre canon**: **Kutrán** (mapudungun — "enfermedad/dolor", en sentido figurado el herrero que "duele" el metal hasta hacerlo mejor). Acepción de artesano que trabaja a fuerza. Apodo en la taberna: "el que duele el acero".

**Posición en escena**: fragua pequeña lateral en el corredor de servicios (con ventana al exterior para ventilación). Yunque, brasas, herramientas. Siempre trabajando — el jugador lo interrumpe.

**Descripción visual**: hombre 50s. Herencia huasa-mapuche del sur chileno. Mandil de cuero de guanaco (curtido local). Brazos expuestos — cicatrices de fragua. Gafas de soldador puestas en la frente (hay herencia industrial de Lota en su técnica). Manos enormes.

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

**Interacción UI**: press `E` → abre panel `EnhancementUI`. Drag ítem al slot central → se muestran stats del ítem actual, stats proyectadas si sube, costo oro, probabilidades. Botón `Reforzar`. Animación corta de fragua si hay éxito (chispas, sonido martillo). Animación de ruptura si el ítem se destruye (el herrero hace gesto de disculpa breve).

**Líneas de diálogo**:
- Al abrir sin ítems: *"Traé algo que valga el carbón primero."*
- Al fallar sin romper: *"Quedó igual. Eso pasa. La fragua no promete."*
- Al romper un ítem +5: *"Lo siento."* (pausa corta, sin drama) *"Pasó."*
- Al lograr +9: *"Eso no lo veo seguido."* (la única vez que Kutrán para de trabajar para mirarte)

---

### 3.3 Mensajera Lefkén — Party Invite + Siguiente Piso

**Nombre canon**: **Mensajera Lefkén** — Lefkén (mapudungun "los Rápidos", referencia al clan desaparecido de Danzantes — ver `_class_lore_danzante_sombras.md §7 Hook B`). El nombre no es coincidencia en canon: la Mensajera es ex-Hija de la Noche Austral que abandonó el clan para trabajar con el Gremio (historia personal implícita en su presencia — quest futura).

**Posición en escena**: de pie cerca de la Puerta Trasera → Torre. Siempre en movimiento leve — nunca quieta del todo. Ropa de viaje oscura (capa patagónica de lana gruesa). Mensajero bag al hombro.

**Descripción visual**: mujer joven, 25-30. Herencia Selk'nam/Yagán visible en complexión oscura + ojos claros (variación real de los pueblos australes). Cabello corto, funcional. Expresión: neutral con ligera impaciencia — habituada a esperar adventurers que no se deciden.

**Línea de identidad**: *"Cuando estén listos, yo llevo el mensaje."*

**Servicios disponibles (Fase 1)**:

| Servicio | Descripción | Implementación |
|----------|-------------|----------------|
| **Party Invite** | Invitar a jugadores a la party antes del run. Multiplayer futuro. En Fase 1: solo modo "1 jugador" visible pero placeholder para expansión. | `PartyPanel` UI con slots 1-6, botón invite (disabled en Fase 1 si multiplayer no implementado). |
| **Siguiente Piso** | Lanzar el run — carga la escena del piso siguiente. | Trigger transición a `piso_1.tscn` (o procedural gen futuro). Ejecuta `SaveManager.save_run_start()` antes de cambiar escena. |
| **Dificultad / opciones de run** | Configurable antes de entrar. Futuro — Fase 2. | Placeholder dropdown. |

**Flujo transición al piso**:

```
Jugador press E en Mensajera
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
- Primera vez: *"¿Primera vez? La Torre no avisa cuando cambia de humor. Suerte."*
- Antes de entrar solo: *"¿Solo? El Gremio lo registra igual. Adelante."*
- Al volver de un run exitoso: *"Volviste. La Torre dejó ir esta vez."*
- Al volver con el equipo completo: *"Todos volvieron."* (cabeceo leve — la versión de un cumplido de alguien que viene de los Hijos de la Noche Austral)

---

## §4. Stash + cofre visual

Además de los 3 NPCs, hay un **cofre físico** en el corredor de servicios — es el `StaticBody3D` visual del stash. El jugador puede interactuar con el cofre directamente (alternativo a Millaray) para abrir solo el panel de Stash sin las otras tabs. Es QoL: acceso rápido al inventario sin hablar con el NPC.

**Tipo**: cofre de madera de lenga con herrajes de bronce oxidado. Diseño austral patagónico (simple, resistente, sin ornamentos). Textura `standard_material` low-poly consistente con el estilo del juego.

---

## §5. Transiciones — cuándo aparece la Taberna

| Situación | Desde | Acción |
|-----------|-------|--------|
| Inicio del juego (post-main menu) | Main menu → Taberna | `SceneManager.load("taverna.tscn")` directamente. Fade in. |
| Vuelta de run exitoso | Último piso del run → Taberna | `SaveManager.save_run_end(loot_list)` → `SceneManager.transition("taverna.tscn")`. Loot del run aparece en cofre stash automáticamente (opcional: animación de "depósito"). |
| Muerte | Cualquier piso → Taberna (sin loot del run) | `SaveManager.save_death()` → `SceneManager.transition("taverna.tscn")`. Millaray tiene línea de muerte. El cofre NO recibe loot del run caído (permadeath loot — canon GDD). |
| Entre runs | Ya en Taberna | El jugador accede libremente a los NPCs. |

**Música** (placeholder canon): ambiente suave de taberna. Sin percusión fuerte — debe sentirse como descanso real después del piso. Sugiero referencia: bandas sonoras de taberna de Zelda Breath of the Wild / Elden Grace Site. Post-Fase1: implementar `AudioStreamPlayer` con loop de ambient taberna chileno (guitarra clásica suave + lluvia exterior opcional).

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
│   ├── MeshInstance3D × mesas/sillas/barra
│   └── MeshInstance3D × decoración (tejidos, llamas, vitrina)
├── ChimeneyParticles (CPUParticles3D) — fuego central
├── NPCGroup
│   ├── NPC_Millaray (CharacterBody3D o StaticBody3D + Area3D interact)
│   │   └── InteractionArea (Area3D trigger E)
│   ├── NPC_Kutran (CharacterBody3D o StaticBody3D)
│   │   └── InteractionArea (Area3D trigger E)
│   └── NPC_Mensajera_Lefken (CharacterBody3D caminando lento loop)
│       └── InteractionArea (Area3D trigger E)
├── StashChest (StaticBody3D + Area3D interact)
├── TriggerEntrance (Area3D) — entrada del player al cargar escena
├── TriggerToTower (Area3D) — activado solo por Mensajera confirm
└── UILayer (CanvasLayer)
    ├── InteractionPrompt (Label "Presioná E")
    ├── StashUI (Control — hidden by default)
    ├── EnhancementUI (Control — hidden by default)
    └── PartyPanel (Control — hidden by default)
```

---

## §8. Ambient detail — Tradiciones canónicas de la Taberna

Canon `_world_canon.md §11`:

- **Rincón Danzante**: el rincón oscuro de la Taberna tiene una silla baja y una mesa sin velas. Los Hijos tararean ahí. El resto de los clientes aprenden a ignorar los sonidos de melodías austral — no por descortesía, sino porque los Hijos **no quieren ser escuchados por los que no reconocen la melodía**. Implementación: `AudioStreamPlayer3D` ambiental muy tenue con loop de melodía selk'nam (2-3 notas repetidas, filtrado bajo).

- **Oración del Muro**: una mesa privada en el fogón, con sillas para 6. Dos sillas siempre quedan vacías (tradición — para los que no volvieron). Warriors y Clerics hacen la *Oración del Muro* ahí 60s antes de run. Implementación Fase 1: NPC Warrior estático + NPC Cleric estático (decorativos) sentados ahí como ambient detail.

- **Rangers invitan primera ronda**: la primera vez que el jugador entra a la Taberna, hay un `DialogueTrigger` de ambient: un NPC Ranger-silhouette en la barra deja una jarra (sin palabras). Los Artilleros piden la última ronda con un toast ruidoso. Es sabor — no mecánica.

- **Libro de Retornos**: vitrina del fogón, interactuable. Abre un log de texto de todas las veces que el jugador terminó un run exitoso (fecha, piso alcanzado, party). Es el lore-journal in-game de cada corrida exitosa. El Sínodo lo tiene en la Catedral de las Tres Cumbres — este es una copia del Gremio. Sin entradas de muertos — el silencio es canon.

---

## §9. Handoff

**B (gameplay)**:
- Crear `game/scenes/taverna/taverna.tscn` + `taverna.gd` (script de escena para interacciones).
- Implementar `InteractionSystem` (press E cerca de NPCs/cofre → abre UI correspondiente). Si ya existe en otro contexto, reusar.
- `NPC_Millaray.gd`: abrir `StashUI` / `EquipmentUI` con tabs. Integrar con `SaveManager.save_stash()`.
- `NPC_Kutran.gd`: lógica de enhancement. Función `try_enhance(item, enhancement_level) -> bool`. Tabla de probabilidades de §3.2 hardcodeada en `NPC_Kutran.gd` o como `@export var` configurable.
- `NPC_Mensajera_Lefken.gd`: lógica de party panel + trigger de transición a piso. Ejecutar `SaveManager.save_run_start()` antes de scene change.
- `StashChest.gd`: alternativa directa al panel de stash de Millaray (abre solo el tab Stash).
- Save integration: `SaveManager.save_player_state()` + `save_stash()` al llegar a la Taberna (señal `taverna_entered`).
- Música ambient: `AudioStreamPlayer` en `taverna.gd` con loop de ambient (usar placeholder hasta D provea track).
- Transición desde piso: añadir llamada a `SceneManager.transition_to("res://scenes/taverna/taverna.tscn")` en `main.gd` o `GameManager` al finalizar run.

**D (art)**:
- Modelo 3D `taverna.tscn` — building shell low-poly estilo del juego. Escala: 25m × 15m interior, techo 4m.
- Materiales: madera oscura (lenga) + piedra volcánica + piso hexagonal barro (texturas planas, estilo low-poly).
- 3 modelos NPC: Millaray (mujer madurez, poncho), Kutrán (herrero musculoso, mandil), Mensajera Lefkén (joven, capa patagónica).
- Objetos: cofre stash, vitrina Libro de Retornos, mesa Oración del Muro, chimenea.
- Iluminación: cálida, braseros + chimenea. No usar luz azul/fría — la Taberna es refugio.
- Ambiente visual: ref `_class_lore_*` §4 de cada clase para detalles decorativos que reflejen las órdenes presentes.

**QA**:
- `test_taverna_interactions.gd`: verificar que los 3 NPCs abren sus UIs correctamente, que el stash persiste entre recargas de escena, que la transición al piso ejecuta `save_run_start()` antes de cambiar escena, que la muerte no deposita loot del run en el stash.

---

*Spec Taverna — dept/design C, 2026-04-18. Zona neutral cross-orden canon `_world_canon.md §11`. La Asesora Millaray ya es NPC canon desde `_world_canon.md §4`. Kutrán y Mensajera Lefkén son nuevos personajes canon de esta spec.*
