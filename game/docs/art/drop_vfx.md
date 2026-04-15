# Drop VFX — Ownership system visual layer

**Estado**: Draft v1 — 2026-04-15
**Dept**: Art (worktree D — `dept/art/drop-vfx`)
**Base canon**:
- `game/scenes/loot/item_drop.gd` — script existente del drop (B owner)
- `game/scenes/loot/item_drop.tscn` — escena con MeshInstance3D + AuraLight + Label3D
- `game/shared/systems/item_database.gd` — `get_rarity_color(rarity)` provee colores

> Capa visual del sistema de drops con bind-on-drop + ownership transfer. Define qué ve el jugador en cada estado del item en el mundo.

---

## 1. Concepto

Tres estados visuales de un drop, lectura instantánea:

| Estado | Duración | Visual | Función |
|--------|----------|--------|---------|
| **Idle (bind-locked)** | 0 → ~120s | Glow pulsante intenso color rareza, label con `[owner_name]` | "Es de Fulano, no lo agarres" |
| **Ownership release** | t = 120s | Pulse breve + ring expansivo, label cambia a color rareza sin owner | "Ahora es free for all" |
| **Bind expire (despawn)** | t = 180s, último frame | Dissolve 1s + partículas ascenso color rareza | "El alma del item se va — perdiste la chance" |

**Filosofía**: el jugador NUNCA debe agarrar un item ajeno por error y NUNCA debe perder un drop sin entender por qué. El VFX comunica ownership state sin texto extra.

---

## 2. Colores por rareza (canon)

Reusar `ItemDatabase.get_rarity_color(rarity)` — NO duplicar paleta en shaders. Estas son las rarezas existentes en `item_drop.gd:88`:

| Rareza | Hint color (referencia visual, fuente real = ItemDatabase) |
|--------|------------------------------------------------------------|
| `common` | Gris claro `#A0A0A0` |
| `magic` | Azul `#4A90E2` |
| `rare` | Azul-violeta `#7B5BFF` |
| `unique` | Naranja-dorado `#E89B3C` |

> **Nota brief**: el brief del task pidió `Common gris / Rare azul / Epic morado`. Mapea así: **Common → common gris**, **Rare azul → magic** (ya azul) **o rare** (azul-violeta), **Epic morado → rare** (azul-violeta). Si dept Design quiere agregar tier "Epic" puro, abrir issue con C — no inventar ID acá.

---

## 3. Assets entregados

```
game/assets/art/shaders/
├── ground_item_glow.gdshader        # Pulse + fresnel rim por rareza
└── ground_item_dissolve.gdshader    # Dissolve noise con bias Y ascendente

game/scenes/loot/vfx/
├── bind_expire_vfx.tscn             # Partículas ascenso (alma) — 1.2s lifetime
└── ownership_release_vfx.tscn       # Ring expansivo — 0.6s lifetime
```

### 3.1 `ground_item_glow.gdshader`

Aplica al `MeshInstance3D` del drop. Reemplaza el `StandardMaterial3D` actual (`item_drop.gd:78-84`).

**Uniforms**:
- `base_albedo` — color del mesh por tipo (weapon/armor/etc., usa `_get_type_color()` actual)
- `rarity_color` — `ItemDatabase.get_rarity_color(rarity)`
- `pulse_speed` — 1.0 (common) → 2.5 (unique). Mapping sugerido:
  ```gdscript
  var pulse_by_rarity := {"common": 1.0, "magic": 1.5, "rare": 2.0, "unique": 2.5}
  ```
- `pulse_min` / `pulse_max` — rango emission. Default 0.6 → 2.4. Common bajo, unique más amplio.
- `fresnel_power` — borde brilla. Default 2.5.
- `bind_locked` — 1.0 mientras `dropped_by != ""` y ownership no liberado, 0.0 después. Multiplica pulse ×1.6.

### 3.2 `ground_item_dissolve.gdshader`

Aplica al **mismo** MeshInstance3D, swap del glow shader cuando arranca el despawn final.

**Uniforms**:
- `base_albedo` — mismo color que tenía el glow
- `edge_color` — color rareza (el edge del dissolve usa rareza)
- `dissolve_amount` — driven por Tween 0.0 → 1.0 en 1.0s
- `edge_width` — grosor del borde brillante. Default 0.08
- `noise_scale` — densidad del noise dissolve. Default 3.0 (más alto = pixels más finos)

**Driver desde GDScript** (B owns esta integración):
```gdscript
var dissolve_mat: ShaderMaterial = load("res://assets/art/shaders/ground_item_dissolve.gdshader")
mesh.set_surface_override_material(0, dissolve_mat)
dissolve_mat.set_shader_parameter("base_albedo", current_albedo)
dissolve_mat.set_shader_parameter("edge_color", rarity_color)
var tw = create_tween()
tw.tween_method(_set_dissolve, 0.0, 1.0, 1.0)
tw.tween_callback(queue_free)

func _set_dissolve(v: float) -> void:
    dissolve_mat.set_shader_parameter("dissolve_amount", v)
```

### 3.3 `bind_expire_vfx.tscn`

GPUParticles3D one-shot, 1.2s. Dos emisores:
- **Particles** (24 part., ascend): esfera radio 0.18m, vel 0.6-1.4 hacia +Y, gravity +Y suave (asciende).
- **RimFlash** (16 part., ring): anillo radio 0.4m base, breve flash al inicio.

Llamar `vfx.set_color(rarity_color)` antes de `add_child`. Self-frees a los 1.2s.

### 3.4 `ownership_release_vfx.tscn`

GPUParticles3D one-shot, 0.6s. Un emisor:
- **ShockRing** (32 part.): emisión radial flat XZ, vel 1.5-2.5, scale curve creciente.

Pulse breve no destructivo — el item sigue ahí, solo cambia ownership.

---

## 4. Signal contract con dept B

**B agrega a `ground_item.gd` / `item_drop.gd`** estas señales y wire los VFX. Art solo entrega assets, B integra.

```gdscript
# En item_drop.gd:
signal ownership_released   # t=120s — item pasa a free for all
signal bind_expired         # t=180s — despawn final con dissolve

const BIND_DURATION := 120.0
const DESPAWN_TIME := 180.0  # ya existe como @export

const BIND_EXPIRE_VFX := preload("res://scenes/loot/vfx/bind_expire_vfx.tscn")
const OWNERSHIP_RELEASE_VFX := preload("res://scenes/loot/vfx/ownership_release_vfx.tscn")
const GLOW_SHADER := preload("res://assets/art/shaders/ground_item_glow.gdshader")
const DISSOLVE_SHADER := preload("res://assets/art/shaders/ground_item_dissolve.gdshader")

var _bind_locked: bool = true
var _glow_mat: ShaderMaterial

func _ready() -> void:
    # ... existente ...
    _setup_glow_material()
    if dropped_by != "":
        _start_ownership_timer()

func _setup_glow_material() -> void:
    _glow_mat = ShaderMaterial.new()
    _glow_mat.shader = GLOW_SHADER
    var rarity: String = item_data.get("rarity", "common")
    var rarity_color: Color = ItemDatabase.get_rarity_color(rarity)
    var type_color: Color = _get_type_color(item_data.get("type", "material"))
    var pulse_by_rarity := {"common": 1.0, "magic": 1.5, "rare": 2.0, "unique": 2.5}
    _glow_mat.set_shader_parameter("base_albedo", type_color)
    _glow_mat.set_shader_parameter("rarity_color", rarity_color)
    _glow_mat.set_shader_parameter("pulse_speed", pulse_by_rarity.get(rarity, 1.0))
    _glow_mat.set_shader_parameter("bind_locked", 1.0 if _bind_locked else 0.0)
    mesh.set_surface_override_material(0, _glow_mat)

func _start_ownership_timer() -> void:
    await get_tree().create_timer(BIND_DURATION).timeout
    if not is_instance_valid(self) or _picked_up:
        return
    _release_ownership()

func _release_ownership() -> void:
    _bind_locked = false
    _glow_mat.set_shader_parameter("bind_locked", 0.0)
    var vfx = OWNERSHIP_RELEASE_VFX.instantiate()
    add_child(vfx)
    var rarity_color: Color = ItemDatabase.get_rarity_color(item_data.get("rarity", "common"))
    vfx.set_color(rarity_color)
    # Update label: remove [owner_name]
    var display_name: String = item_data.get("name", "???")
    if item_quantity > 1:
        display_name += " x%d" % item_quantity
    label_3d.text = display_name
    dropped_by = ""
    ownership_released.emit()

func _trigger_bind_expire_vfx() -> void:
    # Llamar en _start_despawn_timer al final, ANTES de queue_free
    var vfx = BIND_EXPIRE_VFX.instantiate()
    vfx.position = global_position
    get_tree().current_scene.add_child(vfx)
    var rarity_color: Color = ItemDatabase.get_rarity_color(item_data.get("rarity", "common"))
    vfx.set_color(rarity_color)
    # Swap a dissolve shader y tween
    var dissolve_mat := ShaderMaterial.new()
    dissolve_mat.shader = DISSOLVE_SHADER
    dissolve_mat.set_shader_parameter("base_albedo", _get_type_color(item_data.get("type", "material")))
    dissolve_mat.set_shader_parameter("edge_color", rarity_color)
    mesh.set_surface_override_material(0, dissolve_mat)
    var tw := create_tween()
    tw.tween_method(_set_dissolve.bind(dissolve_mat), 0.0, 1.0, 1.0)
    tw.tween_callback(func(): bind_expired.emit(); queue_free())

func _set_dissolve(v: float, mat: ShaderMaterial) -> void:
    mat.set_shader_parameter("dissolve_amount", v)
```

**Modificación al despawn timer existente** (`item_drop.gd:150-169`): reemplazar el `queue_free()` final por `_trigger_bind_expire_vfx()`. Quitar el blink de los últimos 30s — el dissolve final es suficiente comunicación. Si Design quiere mantener blink, dejar pero solo últimos 5s.

---

## 5. Refs visuales

**Glow pulse** (idle):
- Diablo 4 — items en suelo con beam vertical + pulse color rareza.
- Path of Exile — glow rim color por tier (white/blue/yellow/orange/red).
- WoW Classic — quest items con glow constante.

**Dissolve ascend** (expire):
- Genshin Impact — drops que no agarrás se "evaporan" en partículas hacia arriba.
- Hades — boon orbs no recogidos hacen fade vertical.

**Ownership release shock** (transfer):
- Borderlands — items pasan de "owner-locked" (rojo) a "free" con flash blanco breve.
- Vermintide 2 — loot dice rolls al final del run con ring pulse.

**NO copiar**: efectos sobrenaturales explícitos (no fantasmas, no cráneos). Acá es low-poly stylized — alma/polvo abstracto color rareza.

---

## 6. Performance

- Shaders son fragment-only sin textures externas → costo bajo.
- GPUParticles3D one-shot → garbage collected vía `queue_free`.
- Sin point lights por VFX (el item ya tiene `AuraLight` OmniLight3D — no duplicar).
- Cap visual: si hay >20 drops simultáneos en pantalla, considerar disable pulse en common (revisar profiler post-integration).

---

## 7. Coordinación pendiente con B

**Bloqueante**:
- [ ] B agrega signals `ownership_released` + `bind_expired` a `item_drop.gd`
- [ ] B implementa `_setup_glow_material()` reemplazando `_apply_visuals()` líneas 78-89
- [ ] B implementa `_release_ownership()` con timer 120s
- [ ] B reemplaza `queue_free()` final del despawn por `_trigger_bind_expire_vfx()`

**Coordinación con C (Design)**:
- [ ] Confirmar `BIND_DURATION = 120s` (¿se mantiene? ¿es por rareza?)
- [ ] Confirmar `DESPAWN_TIME = 180s` total (60s post-release o más?)
- [ ] Decidir si tier "Epic" se agrega al ItemDatabase como rareza propia entre `rare` y `unique`

**Multiplayer (futuro)**:
- En coop, el `dropped_by` debe matchear un `peer_id`, no solo nombre. Revisar cuando llegue Steam P2P.
- VFX deben ser visibles para todos (sync auto vía MultiplayerSynchronizer si añadimos).

---

## 8. Red flags

- **NO** poner glow en common Y unique con misma intensidad → matas la lectura de rareza.
- **NO** usar AnimationPlayer en cada drop para el pulse → el shader lo hace gratis vía TIME.
- **NO** spawn point lights extras desde los VFX → ya hay AuraLight, suma costo de sombras.
- **NO** olvidar setear `set_color` antes de `add_child` en los VFX → si no, salen blancos.
- **NO** cambiar el `OmniLight3D` AuraLight existente — es complementario al glow shader, no compite.
