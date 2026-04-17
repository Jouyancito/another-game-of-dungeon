# Ambient Fauna — decorativa no interactiva

**Canon art** para fauna ambiental que puebla los pisos sin interactuar con
combate ni loot. "Vida en el mundo" — visual-only, pure polish.

---

## 1. Filosofía

- **Presencia visual, cero friction.** Las criaturas no atacan, no reciben daño,
  no son loot, no son interactuables. Existen para que el piso no se sienta
  vacío entre encuentros.
- **Cheap y desechable.** Sin CharacterBody3D, sin colisión real, sin grupo
  `"enemies"`. Solo `Node3D` + script de comportamiento + mesh low-poly.
- **Respawn silencioso.** Si una criatura se aleja del spawner (fly off /
  hop away), se auto-libera y el spawner instancia otra en su lugar. El player
  no nota el ciclo.

---

## 2. Archivos

| Archivo | Rol |
|---|---|
| `game/scenes/levels/components/ambient_fauna_spawner.tscn` + `.gd` | Spawner reusable (`class_name AmbientFaunaSpawner`) |
| `game/scenes/fauna/butterfly.tscn` + `.gd` | Mariposa — wander errático |
| `game/scenes/fauna/bird.tscn` + `.gd` | Pájaro (ambient, NO confundir con `scenes/enemy/bird.tscn`) — vuelo en arco + perch |
| `game/scenes/fauna/rabbit.tscn` + `.gd` | Conejo — hop/freeze + flee del player |

---

## 3. Criaturas implementadas

### 3.1 Mariposa (`butterfly.gd`)

- **Hábitat**: aire bajo (0.5 – 2.5m)
- **Mesh**: 2 QuadMesh (WingLeft + WingRight) con material naranja emisivo.
  `cull_mode = 2` para que se vean de ambos lados.
- **Comportamiento**:
  - Target random cada 0.5-2s dentro de `wander_radius` (3m default)
  - Lerp posición hacia target con `move_speed` 1.5 m/s
  - Altura oscila via `sin(time * TAU / height_period)` entre `height_min`/`height_max`
  - Flap alas via `sin(time * wing_flap_hz * TAU)` sobre `rotation.z` (alas opuestas)
  - Despawn si supera `despawn_distance` (50m default) del spawner
- **API `@export`**: `wander_radius`, `move_speed`, `height_min/max`, `height_period`, `wing_flap_hz`, `despawn_distance`

### 3.2 Pájaro (`bird.gd`)

**Nota**: NO confundir con `scenes/enemy/bird.tscn` — ese es enemigo hostil. Este
es fauna decorativa. Path distinto (`scenes/fauna/bird.tscn`), sin `class_name`,
sin grupo `enemies`.

- **Hábitat**: aire alto (5-15m)
- **Mesh**: BoxMesh body + 2 BoxMesh wings marrones.
- **Comportamiento**:
  - Target lejano (10-20m default) en XZ + altura random 5-15m
  - Vuelo lineal hacia target a `flight_speed` 4 m/s
  - Al llegar: `perch_chance` 10% → posarse 2-3s a 1m del suelo del spawner,
    luego repick target. Si no perch, repick inmediato.
  - `look_at(_target)` para face direction en vuelo
  - Flap alas siempre (incluyendo perch, visible aleteo ocasional)
  - Despawn si supera 60m del spawner

### 3.3 Conejo (`rabbit.gd`)

- **Hábitat**: suelo (Y del spawner)
- **Mesh**: BoxMesh body + head + 2 ears + SphereMesh tail white.
- **Comportamiento**:
  - Estado inicial: FREEZE (1-3s random)
  - Al terminar freeze: burst de 2-3 hops en dirección random (clampeado a
    `wander_radius` 15m del spawner)
  - Cada hop: duración 0.35s, arco parabólico `y = 4h*t*(1-t)` con `hop_height` 0.5m
  - Entre hops del burst: dirección con jitter ±0.4 rad (curvy scurry)
  - Al terminar burst: FREEZE otra vez, loop
  - **Flee reactivo**: si player (grupo `"player"`) entra a `flee_radius` (5m),
    interrumpe cualquier estado y hace burst de 3-5 hops opuesto al player a
    `flee_speed_multiplier` 1.6×. Después retoma wander normal.
  - `look_at` la dirección del hop para face movement
  - Despawn si supera 40m del spawner (flee puede sacarlo)

---

## 4. Spawner

### `AmbientFaunaSpawner` (`ambient_fauna_spawner.gd`)

Componente reusable — instancia N criaturas de un `PackedScene` dado, distribuidas
random en disco horizontal de radio `spawn_radius` alrededor del spawner.

### API `@export`

- `creature_scene: PackedScene` — escena a instanciar (butterfly/bird/rabbit/…)
- `count: int = 5` (range 1-30) — cantidad viva simultánea
- `spawn_radius: float = 15.0` — radio del disco de spawn
- `respawn_on_despawn: bool = true` — si criatura emite `despawned`, spawnear reemplazo
- `spawn_height: float = 0.0` — Y del spawn inicial sobre origin del spawner

### Distribución

Posición random uniform en disco: `r = sqrt(randf()) * spawn_radius` (no `randf() * radius` — ese concentra en centro). `angle = randf() * TAU`.

### Contrato con criaturas

Spawner conecta `despawned(fauna: Node)` si la criatura la declara. Cada fauna script la emite antes de `queue_free()` cuando pasa su threshold de despawn.

---

## 5. Aplicado a piso 1 (floor1_prairie.tscn)

5 spawners agregados en `AmbientFauna` parent node:

| Spawner | Posición | Creature | Count | Radius |
|---|---|---|---|---|
| ButterflySpawner_A | `(18, 0, 12)` | butterfly | 5 | 6m |
| ButterflySpawner_B | `(-22, 0, -8)` | butterfly | 5 | 6m |
| BirdSpawner_A | `(0, 10, 0)` | bird | 3 | 25m |
| BirdSpawner_B | `(35, 10, -30)` | bird | 3 | 25m |
| RabbitSpawner | `(10, 0, -20)` | rabbit | 4 | 12m |

**Total activo: 20 criaturas simultáneas** (10 mariposas + 6 pájaros + 4 conejos).

---

## 6. Agregar nueva criatura

Template check-list:

1. **Script** `game/scenes/fauna/{nombre}.gd`:
   - `extends Node3D` (NO CharacterBody3D)
   - `signal despawned(fauna: Node)` — para que el spawner reponga
   - `@export var despawn_distance: float = ...`
   - En `_ready()`: `spawner_origin = global_position`
   - En `_process()`: comportamiento + check despawn → `despawned.emit(self); queue_free()`
2. **Escena** `game/scenes/fauna/{nombre}.tscn`:
   - Node3D root con script
   - Meshes low-poly (BoxMesh/SphereMesh/QuadMesh + StandardMaterial3D)
   - NO grupo `"enemies"`, NO CharacterBody3D
3. **Usar** en cualquier floor scene:
   - Instanciar `ambient_fauna_spawner.tscn`
   - Setear `creature_scene = preload("res://scenes/fauna/{nombre}.tscn")`
   - Ajustar `count` / `spawn_radius` / `respawn_on_despawn`
4. **Documentar** en §3 de este canon con hábitat / mesh / comportamiento.

---

## 7. Performance

- **Max recomendado**: ~30 criaturas activas simultáneas por piso. Floor1 actual:
  20 → margen OK.
- **No CharacterBody3D, no física real**: cada criatura cuesta ~1 Node3D + 2-5
  MeshInstance3D + _process() con math simple. Barato.
- **Distance culling**: Godot 4 culling automático por frustum descarta renders
  fuera de cámara. No implementar culling manual.
- **Si FPS cae**:
  - Reducir `count` por spawner
  - Setear `respawn_on_despawn = false` (deja morir)
  - Eliminar LookAt en birds (save trig per frame)
  - Reducir `wing_flap_hz` (recalcula sin menos veces)
- **Raycast suelo para snap**: NO implementado (scope-out). Si rabbit aparece
  flotando sobre terreno irregular, futuro TODO agregar raycast down en `_ready`.

---

## 8. Edge cases

- **Player atraviesa criatura**: sin colisión real, atraviesan libremente.
  Mariposa/pájaro no reaccionan. Rabbit reacciona huyendo si está a <5m.
- **Criatura spawnea dentro de pared**: scope-out para primer pass. TODO:
  raycast en spawner pre-add_child, si colisiona → re-pick pos.
- **Player grupo `"player"`**: rabbit busca por grupo. Si el player no está en
  ese grupo (pre-setup scenes), `_find_player()` retorna null y rabbit no flee
  (wander normal). No crash.
- **Multi-player futuro (Steam)**: server-authoritative spawn/despawn cuando
  llegue multiplayer. NO scope de esta tarea — por ahora single-client.

---

## 9. Referencias visuales

- **Stardew Valley**: insectos low-res en pantalla, gallinas scurry por el
  rancho, pájaros perch en árboles → mismo feel "fondo vivo sin friction".
- **Spiritfarer**: peces que nadan en círculos, luciérnagas con trail —
  ambient fauna como ingredient del mood.
- **Genshin Impact (Mondstadt)**: mariposas en claros, aves volando en arco
  sobre colinas, conejos hop en praderas — canon AAA del patrón.
- **Hollow Knight (Greenpath)**: mariposas flotan, no son enemigos — polish
  visual barato con impacto alto.

---

## 10. TODOs / futuras iteraciones

- **Raycast suelo**: rabbit/squirrel snap a terreno irregular (scope-out primer
  pass — arena plana default).
- **Obstáculo avoidance en spawn**: pre-raycast para evitar spawn dentro de paredes.
- **Ardilla + árboles**: cuando se agreguen árboles al piso, implementar `squirrel.gd`
  con behavior "scurry around trunk".
- **Peces**: cuando haya agua (piso con lago/río), `fish.gd` con nado en círculos.
- **Sound FX**: pájaros chirp ambient ocasional, mariposas silent, conejos
  silent — delegar a dept Audio cuando exista.
- **Per-biome fauna**: floor2 bosque = ciervos + búhos, floor3 hielo = zorros
  árticos + pingüinos, floor4 tormenta = cuervos + murciélagos, floor5 dimension
  rota = criaturas glitch custom. Cada una en `scenes/fauna/{name}.tscn`.

---

**Última revisión**: 2026-04-17 (issue #53 — D)
