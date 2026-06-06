# Principio de Inserción Integral — Canon de Gameplay Coherence

> **Estado: CANON DE PROCESO VIGENTE** (desde 2026-06-05)
> Consultar SIEMPRE que se agregue cualquier elemento al mundo de Dungeon Party.
> Aplica a toda clase de elemento: fauna, mob, vegetación, agua, terreno.

---

## Regla madre

> **Nada entra al mundo "a medias".** Si agregás una mariposa, esa mariposa tiene hábitat, lógica de vuelo, y una respuesta a "¿qué pasa si le pego?". Si agregás un arbusto, tiene escala real, decide dónde crece, y declara si colisiona. Un elemento sin su lógica completa es deuda, no contenido.

El filtro del scope-reset SIGUE vigente encima de esto: *"¿esto sale en el video de 10 min del demo?"*. El Principio NO te autoriza a inflar scope — te obliga a que **lo que SÍ entra, entre entero**.

---

## Por qué esto importa (Valheim / ecología)

En Valheim un golem vive en la montaña *porque es piedra*; un fuling patrulla en tribu *porque es tribu*. El comportamiento está atado al hábitat. Cuando rompés ese vínculo, el jugador lo siente como "asset puesto ahí", no como mundo vivo.

El Principio existe para que cada cosa refuerce las otras 7 capas del bioma (terrain, flora, fauna, hazard, recurso, boss, post-boss). Una capa incompleta debilita a las demás.

---

## CHECKLIST POR TIPO DE ELEMENTO

Cada elemento que agregues DEBE responder TODAS las preguntas de su categoría antes de considerarse "hecho". Si una pregunta no aplica, escribí explícitamente `N/A — razón`.

---

### A) FAUNA AMBIENTAL (no-combat: mariposa, conejo deco, pájaro de fondo, libélula)

Propósito: vida ambiental. NO es un mob. Existe el riesgo de que se confunda con uno.

| # | Pregunta | Mapeo GDScript |
|---|----------|----------------|
| 1 | **¿Hábitat?** ¿En qué tiles/zonas aparece? (claro abierto / borde de agua / aéreo / cerca de flores) | `@export var habitat_type: String` — leído por el spawner para elegir tile válido |
| 2 | **¿Movimiento?** Patrón coherente con la criatura (mariposa: flotación errática lenta; pájaro: arcos; conejo: hops + freeze). NO debe quedarse estática | `_process` con noise/timer; NOT `CharacterBody3D` pesado si no colisiona — un `Node3D` + `AnimationPlayer` alcanza |
| 3 | **¿Vida / HP?** Decisión EXPLÍCITA: ¿tiene HP o es indestructible? Default fauna ambiental: **1 HP, muere de un toque, drop nulo o cosmético**. NUNCA `health = 100` copiado de BaseEnemy | Si destruible: 1 HP + `enemy_type` con `LootTable` vacía. Si indestructible: sin `take_damage`, layer fuera de Enemies |
| 4 | **¿Reacciona al jugador?** Huye al acercarse (radio flush), o lo ignora | Raycast/distance check en `_process`; flee simple (dirección opuesta al player) |
| 5 | **¿Grupo / layer?** NO va en grupo `"enemies"` salvo que cuente como kill. Default: grupo `"ambient"`, collision_layer fuera de layer 3 | `add_to_group("ambient")`, collision_layer ≠ 4 (Enemies) |
| 6 | **¿Drop?** Default ninguno. Excepción: recurso de bioma cosmético (pluma, escama) con chance baja | `LootTable._add("butterfly", {...})` solo si dropea algo |
| 7 | **¿Audio?** Aleteo / chillido ambiental opcional, volumen MUY bajo en mezcla | `AudioManager.play_sfx` con bus `ambient` a volumen bajo |

**Anti-patrón:** una mariposa que es `BaseEnemy` con 100 HP, está en grupo `enemies`, y el jugador la puede "farmear". Eso NO es fauna ambiental — es un mob disfrazado que rompe el balance del TC/economía.

---

### B) MOB / ENEMIGO (combat: perro, slime, lobo, orco)

Propósito: amenaza. Hereda `BaseEnemy` (`base_enemy.gd`). El framework YA provee el 70%.

| # | Pregunta | Mapeo GDScript (lo que YA existe en `base_enemy.gd`) |
|---|----------|------------------------------------------------------|
| 1 | **¿HP / daño / rango / velocidad?** Escalado al piso. Piso 1 canon: HP ~100, dmg ~10, DEF 0 (ver `CLAUDE.md`) | `@export health`, `@export damage`, `@export attack_range`, `@export speed` — heredados |
| 2 | **¿Tier y SubTier?** ¿Es fauna hostil (A), depredador (B), alfa de zona (C), o boss? Define el peligro percibido + badge en nameplate | `@export enemy_tier: int` + `@export sub_tier: SubTier` (A/B/C/BOSS) — enum YA existe |
| 3 | **¿Agresividad?** ¿AGGRESSIVE (ataca al ver) o NEUTRAL (solo si lo provocás)? El goat es NEUTRAL | `@export aggression: AggressionType` — YA existe. NEUTRAL usa `is_provoked` auto en `take_damage` |
| 4 | **¿IA por estados?** Mínimo: idle/patrol → pursue → attack. ¿Comportamiento especial? (slime hop, wolf charge+flee, bird swoop) | Override `_idle_behavior`, `_move_toward_target`, `_on_death`. Loop idle→pursue→attack YA está en `_physics_process` de BaseEnemy |
| 5 | **¿Hábitat / nicho?** ¿Dónde vive y por qué? (slime: borde de agua/cueva húmeda; wolf: campo abierto; bird: aéreo). Define dónde lo spawnea el nivel | **GAP ACTUAL:** agregar `@export var habitat_type: String = "open_field"` a `BaseEnemy`. El spawner lo filtra. Valores: `open_field`, `water_edge`, `cave`, `aerial` |
| 6 | **¿Grupo social?** ¿Solo, manada, tribu? ¿Hay alfa cuya muerte afecta al resto? | Patrón `wolf.gd`: `is_alpha` + `_notify_pack_alpha_dead` por radio. Reutilizable para cualquier pack |
| 7 | **¿Drops + probabilidades?** TC propia: gold range + materiales (chance) + equipo raro (chance baja) + guaranteed (quest items). El material debe SERVIR (craft/quest), no ser basura | `LootTable._add("perro", {gold_min/max, drops:[{item_id, chance, qty}], guaranteed:[...]})`. `enemy_type` debe coincidir con la key |
| 8 | **¿Habilidades / ataque especial?** Más allá del melee base: carga, veneno, salto, proyectil | Override `perform_attack` o `_on_post_attack_hit`. Status via `apply_status(&"bleed"/"weak"/"stun", dur, self)` — YA soportado |
| 9 | **¿Status / knockback?** mass + knockback_resistance coherentes con el físico del mob (slime liviano ~0.5, golem pesado ~5.0) | `@export mass`, `@export knockback_resistance` — YA existen |
| 10 | **¿Muerte?** ¿Tween simple, split (slime → 4 mini), notificación a la manada, VFX? | Override `_on_death`. Loot + xp + journal + title + SFX + camera shake YA automáticos en `die()` |
| 11 | **¿Nombre con identidad?** Nombre que suene a personaje, no a categoría genérica ("Rana del Pantano" > "EnemyFrog") | `@export display_name: String`, `@export enemy_level: int`. Nameplate auto en `_setup_nameplate` |
| 12 | **¿VFX de habilidad saturado?** Si tiene habilidad, su VFX explota en color sobre el bioma desaturado (principio Kimetsu: contraste) | `GPUParticles3D` con `S > 0.8` en HSV. Carpeta `scenes/enemy/vfx/` |

**Regla de oro mob:** un mob nuevo que solo cambia el mesh y reusa stats de otro NO es un mob nuevo — es un reskin. Para que cuente como contenido integral debe diferir en al menos 3 de: IA, hábitat, drops, grupo social, habilidad especial.

---

### C) VEGETACIÓN (pasto, arbusto, árbol, trébol, hongo, flor)

| # | Pregunta | Mapeo GDScript |
|---|----------|----------------|
| 1 | **¿Escala real?** Un árbol no mide lo mismo que un trébol. Definir altura en metros y respetar contra el player (cápsula ~1.8m) | `scale` en el `.tscn` o `MultiMeshInstance3D`; validar visualmente vs cápsula del player |
| 2 | **¿Hábitat por humedad/luz?** Hongo: sombra/húmedo (cerca de agua, bajo árboles). Flor: sol abierto. Trébol: campo. Musgo: piedra húmeda. NO sembrar hongos en pleno sol | Capa de spawn por zona; si usás FastNoiseLite (humedad), thresholds distintos por especie |
| 3 | **¿Colisión SÍ/NO?** Árbol/roca grande: SÍ (bloquea). Pasto/trébol/flor: NO (atravesable). Arbusto: borde (frena pero no bloquea completamente) | `StaticBody3D` + collision layer 1 (World) para árboles/rocas; `MeshInstance3D` puro sin colisión para pasto/flores |
| 4 | **¿Densidad / agrupación?** ¿Disperso o en clusters? Pasto va en `MultiMesh` denso; árbol en clusters chicos de 3-5 | `MultiMeshInstance3D` para densidad alta (pasto/trébol); instancias individuales para árboles |
| 5 | **¿Interactivo?** ¿Decoración o cosechable? (Hierba Silvestre = recurso de bioma cosechable con recipe en craft) | Si cosechable: `Area3D` + interact → entrega material. Si deco: solo mesh |
| 6 | **¿Performance?** Vegetación densa SIN colisión y en `MultiMesh`. Nunca 500 nodos individuales con física | MultiMesh, sin physics, distance-cull si hace falta |

---

### D) AGUA (charco, arroyo, estanque)

| # | Pregunta | Mapeo GDScript |
|---|----------|----------------|
| 1 | **¿Fuente / caudal?** ¿De dónde viene y adónde va? Un charco aislado es geológicamente raro; un arroyo nace de una grieta/roca y desemboca en una poza | Diseño de layout: nacimiento (roca/cueva) → cauce → poza. Coherencia geológica antes de colocar assets |
| 2 | **¿Es transitable o barrera?** ¿El player la cruza, se hunde, o la bordea? | Charco: cosmético, atravesable. Estanque profundo: `Area3D` que frena o aplica efecto. Definir explícito antes de colocar |
| 3 | **¿Vida alrededor?** El agua ATRAE ecología: hongos en el borde, luciérnagas sobre la superficie, slimes (húmedo), juncos. El agua sin vida alrededor se siente muerta | Spawn de fauna ambiental + vegetación con `habitat_type = "water_edge"` ligado al tile de agua |
| 4 | **¿Efecto al jugador?** ¿Ninguno, splash sonoro, ralentiza, daño? | Piso 1: cosmético + SFX de splash. Sin daño (piso inicial, sin hazard ambiental — canon) |
| 5 | **¿Visual?** Shader de agua (no plano opaco): leve transparencia, reflejo tenue, normales animadas. Desaturado como el bioma | `ShaderMaterial` agua toon. Props `water/` ya existen en `assets/art/piso1_pradera/` |

---

### E) TERRENO / GEOLOGÍA (colinas, grietas, rocas, cuevas, paredes)

| # | Pregunta | Mapeo GDScript |
|---|----------|----------------|
| 1 | **¿Coherencia narrativa?** Las grietas/rocas tienen historia: una grieta lleva a una cueva, una pared de roca delimita el claro, un afloramiento marca el camino al boss. NO rocas random flotando | Layout intencional; la roca grande es landmark, no relleno |
| 2 | **¿Colisión y navegación?** Todo terreno transitable en NavMesh / piso válido; las paredes bloquean. El enemigo NO debe poder caminar a través de una colina | `StaticBody3D` + collision layer 1 World; verificar que `_ground_drop_position` (mask layer 1, ya existe en BaseEnemy) detecte el suelo correcto |
| 3 | **¿Señalización ambiental?** ¿Este accidente geográfico ORIENTA? (hueso gigante en pared → boss room; columna de luz; sonido distante). Guiar sin minimap, como Valheim | Beacon: `OmniLight3D` tenue en dirección del boss + SFX ambiental por distancia. Sin minimap marker en alfa |
| 4 | **¿Escala vs jugador?** Una "montaña" de piso 1 es una colina transitable, no un Everest. Coherente con el scope de zona inicial | Validar altura/pendiente contra velocidad del player (5 m/s base) y altura de salto |
| 5 | **¿Hábitat que habilita?** La cueva húmeda habilita slimes + hongos; el claro abierto habilita lobos + flores. El terreno DEFINE qué fauna/flora vive ahí | El `habitat_type` de mobs/vegetación se ancla al tipo de terreno del tile |

---

## FLUJO DE INSERCIÓN (los 4 pasos, siempre)

1. **Clasificá** el elemento (A/B/C/D/E) y abrí su checklist.
2. **Respondé las preguntas** — toda pregunta sin `N/A — razón` explícito es trabajo pendiente, no "listo".
3. **Mapeá a GDScript existente primero** (no reinventés: `BaseEnemy`, `LootTable`, grupos, `apply_status` ya existen). Solo agregás campo/sistema nuevo si hay un GAP real (ej: `habitat_type`).
4. **Verificá las 7 capas del bioma**: ¿este elemento refuerza terrain/flora/fauna/hazard/recurso/boss/post-boss, o queda aislado? Si queda aislado, atalo a algo.

---

## GAPS de framework detectados (a resolver para que el Principio sea aplicable)

| Gap | Estado | Costo |
|-----|--------|-------|
| `habitat_type` no existe en `BaseEnemy` | **GAP CONFIRMADO** (grep vacío) | 1 línea `@export var habitat_type: String = "open_field"` en `base_enemy.gd` + lectura en spawner |
| Spawner por hábitat | No existe todavía. Para alfa basta colocar a mano en `.tscn` respetando hábitat; spawner procedural es post-slice | Post-slice |
| `WorldState` / world-keys (boss-kill → raid) | No existe (confirmado). Requiere save robusto primero. Fuera del scope del primer lote | Post-slice |

---

## Las 7 capas del bioma (Valheim-derived)

Cada piso completo necesita estas 7 capas. Usar como checklist de "¿el piso se siente vivo?":

| Capa | Descripción | Ejemplo Piso 1 |
|------|-------------|----------------|
| 1. Terrain | Heightmap + variación, landmarks geológicos | Claro central + grieta → cueva + colina suave |
| 2. Flora | Vegetación con reglas de hábitat | Hongos en húmedo, flores en sol, juncos en borde agua |
| 3. Fauna | Mobs con hábitat + fauna ambiental | Slime (water_edge), wolf (open_field), bird (aerial), conejo deco |
| 4. Hazard | Peligro ambiental (puede ser ninguno en zona inicial) | Piso 1: **sin hazard** (starting zone, sin penalidad ambiental — canon) |
| 5. Recurso exclusivo | Material que SOLO dropea en este bioma | "Hierba Silvestre" — ingrediente de poción básica |
| 6. Boss + altar señalizado | Boss con landmark ambiental (luz, sonido, landmark visual) | Mushroom King + beacon luz verde-pálida + hum distante |
| 7. Post-boss (world-state) | Cómo reacciona el mundo después del kill (raids reforzadas, merchant nuevos, loot pool expandido) | Post-alfa: raid de slimes reforzados si has_key('defeated_floor1_boss') |

> **Nota capa 7:** La capa post-boss requiere `WorldState` (no existe aún). Para el alfa es suficiente que exista la idea documentada. Implementación cuando el save system esté probado.

---

## Contexto de uso en el proyecto

Este Principio aplica al stack existente:

- **BaseEnemy** (`game/scenes/enemy/base_enemy.gd`): framework ya tiene SubTier/AggressionType/status/loot/knockback. El único GAP material es `habitat_type`.
- **LootTable** (`game/shared/systems/loot_table.gd`): TC por `enemy_type` con chance + pool_pick + guaranteed. Usar directamente.
- **Grupos Godot**: `"enemies"` (layer 3) para mobs. `"ambient"` (sin layer combat) para fauna ambiental. `"player"` (layer 2) para el party.
- **Physics layers**: 1=World, 2=Player, 3=Enemies. Fauna ambiental → layer fuera de 3, sin mask de combat.
- **Status effects**: `apply_status(&"bleed"/"weak"/"stun"/"slow", duration, source)` ya implementado en BaseEnemy.
- **Señales**: `health_changed`, `player_died`, `xp_changed` en BasePlayer; BaseEnemy emite `enemy_died` + `loot_dropped`.
- **@export**: toda variable de balance va con `@export`. Esto incluye `habitat_type`, `mass`, `knockback_resistance`, `aggro_range`.

---

*Documento creado 2026-06-05. Living document — actualizar cuando se detecten nuevos gaps o anti-patrones en sesión.*
