# Drop VFX — Ownership system visual layer

**Estado**: Draft v2 — 2026-04-16 (post Judgment Day, alineado a canon drop-ownership v2)
**Dept**: Art (worktree D — `dept/art/drop-vfx`)
**Base canon**:
- `game/docs/balance/_drop_ownership_canon.md` — reglas ownership v2 (C owner)
- `game/scenes/loot/item_drop.gd` — script actual del drop (B owner). **Canon v2 pide rename → `ground_item.gd`**, pendiente en B.
- `game/scenes/loot/item_drop.tscn` — escena con MeshInstance3D + AuraLight + Label3D
- `game/shared/systems/item_database.gd` — `get_rarity_color(rarity)` provee colores

> Capa visual del sistema de drops con owner-lock + free-for-all + bind-on-drop. Define qué ve el jugador en cada estado del item en el mundo, alineado a los timers del canon v2.

---

## 1. Timers canon v2 — resumen rápido

Dos ciclos posibles por drop. Determinado por flag `bind_on_drop` en `item_data`.

### 1.1 Drop normal (`bind_on_drop = false`)

```
t=0 ─────────── t=180s ─────────── t=300s
  │                │                   │
  │ Owner-locked   │ Free-for-all      │ Despawn
  │ (glow ×1.6)    │ (glow ×1.0)       │ (dissolve 0.8s)
  │ label [owner]  │ label sin owner   │ puff particles
  └─ owner-only ───┘─ todos ───────────┘
```

### 1.2 Bind items (`bind_on_drop = true` — Corona, quest, Royal Gel)

```
t=0 ────────────────────────── t=300s
  │                                │
  │ Owner-locked (glow ×1.6)       │ Despawn directo
  │ label [owner] todo el ciclo    │ (dissolve 0.8s + puff)
  └─ owner-only hasta el final ────┘
```

**NO** hay free-for-all phase para bind items. NO hay ring shock a mitad. Directo a dissolve.

---

## 2. Estados visuales (canon v2)

| Estado | Rango | Aplica a | Visual | Función narrativa |
|--------|-------|----------|--------|-------------------|
| **Owner-locked** | 0 → 180s (normal) / 0 → 300s (bind) | Ambos | Glow pulsante intenso ×1.6, label `[owner_name]`, color rareza | "Es de Fulano, no lo agarres" |
| **Free-for-all** | 180 → 300s | Solo normal | Glow pulsante normal ×1.0, label sin owner, ring shock breve al entrar | "Ahora es de quien lo agarre" |
| **Despawn** | t = 300s (ambos) | Ambos | Dissolve shader 0.8s + particle puff ascendente | "Se fue — perdiste la chance" |

**Filosofía**: el jugador nunca debe (1) agarrar un item ajeno por error, (2) perder un drop sin entender por qué, (3) confundir bind item con normal. El VFX comunica ownership sin texto extra.

**Diferencia clave bind vs normal**: el glow ×1.6 **NUNCA baja** en bind items. Si el jugador ve un drop que sigue brillando fuerte después de 3 minutos y él no es el owner, sabe leer: "Es un item bindeado, nunca va a ser mío."

---

## 3. Colores por rareza (canon)

Reusar `ItemDatabase.get_rarity_color(rarity)` — NO duplicar paleta en shaders. Rarezas existentes en `item_drop.gd:88`:

| Rareza canon | Hint color (referencia visual) | Fuente real |
|--------------|--------------------------------|-------------|
| `common` | Gris claro `#A0A0A0` | `ItemDatabase.get_rarity_color("common")` |
| `magic` | Azul `#4A90E2` | `ItemDatabase.get_rarity_color("magic")` |
| `rare` | Azul-violeta `#7B5BFF` | `ItemDatabase.get_rarity_color("rare")` |
| `unique` | Naranja-dorado `#E89B3C` | `ItemDatabase.get_rarity_color("unique")` |

> **Nota P1 economy**: canon v2 no introduce Legendary en P1 (reservado Tier II+). La paleta existente cubre todo P1.

---

## 4. Assets entregados

```
game/assets/art/shaders/
├── ground_item_glow.gdshader        # Pulse + fresnel rim por rareza (uniform bind_locked)
└── ground_item_dissolve.gdshader    # Dissolve noise con bias Y ascendente

game/scenes/loot/vfx/
├── ownership_release_vfx.tscn       # Ring shock expansivo — 0.6s (spawn al entrar FFA)
└── bind_expire_vfx.tscn             # Partículas ascenso (alma/polvo) — 1.2s (spawn al despawn)
```

> **Naming**: los nombres de scenes se mantienen — `ownership_release_vfx` describe el momento t=180s (owner lock expira), `bind_expire_vfx` describe el momento t=300s (item desaparece, "alma se va"). Ambos son semánticamente correctos en canon v2.

### 4.1 `ground_item_glow.gdshader`

Aplica al `MeshInstance3D` del drop. Reemplaza el `StandardMaterial3D` actual (`item_drop.gd:78-84`).

**Uniforms confirmados**:

| Uniform | Tipo | Default | Rol |
|---------|------|---------|-----|
| `base_albedo` | vec4 | `(0.6, 0.6, 0.6, 1)` | Color del mesh por tipo (weapon/armor/etc., usa `_get_type_color()`) |
| `rarity_color` | vec4 | `(1, 1, 1, 1)` | `ItemDatabase.get_rarity_color(rarity)` |
| `pulse_speed` | float `[0, 5]` | 1.5 | 1.0 (common) → 2.5 (unique). Mapping: `{"common": 1.0, "magic": 1.5, "rare": 2.0, "unique": 2.5}` |
| `pulse_min` | float `[0, 5]` | 0.6 | Rango bajo emission pulse |
| `pulse_max` | float `[0, 8]` | 2.4 | Rango alto emission pulse |
| `fresnel_power` | float `[0.5, 8]` | 2.5 | Borde brilla (lectura desde lejos) |
| `bind_locked` | float `[0, 1]` | 0.0 | **1.0 mientras está owner-locked, 0.0 después**. Multiplica pulse ×1.6 |

**Canon v2 application**:
- Drop normal: `bind_locked = 1.0` durante 0→180s, luego `0.0` durante 180→300s.
- Bind item: `bind_locked = 1.0` durante 0→300s (nunca baja).

### 4.2 `ground_item_dissolve.gdshader`

Aplica al **mismo** MeshInstance3D, swap del glow shader cuando arranca el despawn final (t=300s ambos ciclos).

**Uniforms confirmados**:

| Uniform | Tipo | Default | Rol |
|---------|------|---------|-----|
| `base_albedo` | vec4 | `(0.6, 0.6, 0.6, 1)` | Mismo color que tenía el glow |
| `edge_color` | vec4 | `(1.0, 0.85, 0.4, 1)` | Color rareza (edge del dissolve) |
| `dissolve_amount` | float `[0, 1]` | 0.0 | Driven por Tween 0.0 → 1.0 en 0.8s |
| `edge_width` | float `[0, 0.3]` | 0.08 | Grosor del borde brillante |
| `noise_scale` | float `[0.5, 8]` | 3.0 | Densidad del dissolve noise |

**Canon v2**: duración dissolve estándar = **0.8s** (antes 1.0s, ajuste minor para que el puff particles lidere el closure).

### 4.3 `ownership_release_vfx.tscn`

GPUParticles3D one-shot, **0.6s**. Spawn en t=180s (solo drop normal — bind items NO lo disparan).

- **ShockRing** (32 part.): emisión radial flat XZ, vel 1.5-2.5, scale curve creciente, color rareza.

Llamar `vfx.set_color(rarity_color)` antes de `add_child`. Self-frees a los 0.6s.

### 4.4 `bind_expire_vfx.tscn`

GPUParticles3D one-shot, **1.2s**. Spawn en t=300s (ambos ciclos). Dos emisores:

- **Particles** (24 part., ascend): esfera radio 0.18m, vel 0.6-1.4 hacia +Y, gravity +Y suave.
- **RimFlash** (16 part., ring): anillo radio 0.4m base, flash breve al inicio.

Llamar `vfx.set_color(rarity_color)` antes de `add_child`. Self-frees a los 1.2s.

---

## 5. Signal contract con dept B (canon v2)

**B agrega a `ground_item.gd`** (post-rename desde `item_drop.gd`) las señales y timers canon v2. Art entrega assets, B integra.

### 5.1 Señales canon

```gdscript
# En ground_item.gd (ex item_drop.gd)

signal owner_lock_expired       # t=180s (drop normal) — emitido antes de pasar a FFA
signal free_for_all_started     # t=180s (drop normal) — emitido al entrar FFA. Art engancha aquí el ring shock
signal despawning               # t=300s (drop normal) — emitido al empezar dissolve
signal bind_expired             # t=300s (bind items) — emitido al empezar dissolve. Sin free-for-all previo

const OWNER_LOCK_DURATION := 180.0      # Canon v2: era 120s en v1
const FREE_FOR_ALL_DURATION := 120.0    # 180→300
const TOTAL_DESPAWN_TIME := 300.0       # Canon v2: era 180s en v1
const DISSOLVE_DURATION := 0.8

const OWNERSHIP_RELEASE_VFX := preload("res://scenes/loot/vfx/ownership_release_vfx.tscn")
const BIND_EXPIRE_VFX := preload("res://scenes/loot/vfx/bind_expire_vfx.tscn")
const GLOW_SHADER := preload("res://assets/art/shaders/ground_item_glow.gdshader")
const DISSOLVE_SHADER := preload("res://assets/art/shaders/ground_item_dissolve.gdshader")
```

> **Owner-lock vs free-for-all**: dos signals separadas en t=180s porque pueden tener listeners distintos:
> - `owner_lock_expired` — gameplay listeners (DropController, pickup permission check)
> - `free_for_all_started` — VFX / HUD listeners (ring shock, label update)
>
> Si B prefiere una sola signal (ej. solo `free_for_all_started`), confirmar con A.

### 5.2 Flujo drop normal

```gdscript
func _ready() -> void:
    # ... existente ...
    _setup_glow_material()
    if _is_bind_item():
        _start_bind_timer()         # directo 300s → dissolve
    else:
        _start_owner_lock_timer()   # 180s → FFA → dissolve

func _is_bind_item() -> bool:
    return item_data.get("bind_on_drop", false)

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
    _glow_mat.set_shader_parameter("bind_locked", 1.0)  # arranca siempre locked
    mesh.set_surface_override_material(0, _glow_mat)

func _start_owner_lock_timer() -> void:
    await get_tree().create_timer(OWNER_LOCK_DURATION).timeout
    if not is_instance_valid(self) or _picked_up:
        return
    _enter_free_for_all()
    await get_tree().create_timer(FREE_FOR_ALL_DURATION).timeout
    if not is_instance_valid(self) or _picked_up:
        return
    _despawn_normal()

func _enter_free_for_all() -> void:
    owner_lock_expired.emit()
    _glow_mat.set_shader_parameter("bind_locked", 0.0)  # pulse baja a ×1.0
    var vfx := OWNERSHIP_RELEASE_VFX.instantiate()
    add_child(vfx)
    var rarity_color: Color = ItemDatabase.get_rarity_color(item_data.get("rarity", "common"))
    vfx.set_color(rarity_color)
    # Label: remove [owner_name]
    var display_name: String = item_data.get("name", "???")
    if item_quantity > 1:
        display_name += " x%d" % item_quantity
    label_3d.text = display_name
    dropped_by = ""
    free_for_all_started.emit()

func _despawn_normal() -> void:
    despawning.emit()
    _trigger_dissolve()

func _start_bind_timer() -> void:
    await get_tree().create_timer(TOTAL_DESPAWN_TIME).timeout
    if not is_instance_valid(self) or _picked_up:
        return
    bind_expired.emit()
    _trigger_dissolve()

func _trigger_dissolve() -> void:
    # Swap glow → dissolve shader
    var rarity_color: Color = ItemDatabase.get_rarity_color(item_data.get("rarity", "common"))
    var dissolve_mat := ShaderMaterial.new()
    dissolve_mat.shader = DISSOLVE_SHADER
    dissolve_mat.set_shader_parameter("base_albedo", _get_type_color(item_data.get("type", "material")))
    dissolve_mat.set_shader_parameter("edge_color", rarity_color)
    mesh.set_surface_override_material(0, dissolve_mat)
    # Puff particles acompañando el fade
    var vfx := BIND_EXPIRE_VFX.instantiate()
    vfx.position = global_position
    get_tree().current_scene.add_child(vfx)
    vfx.set_color(rarity_color)
    # Tween dissolve 0→1 en 0.8s, luego free
    var tw := create_tween()
    tw.tween_method(_set_dissolve.bind(dissolve_mat), 0.0, 1.0, DISSOLVE_DURATION)
    tw.tween_callback(queue_free)

func _set_dissolve(v: float, mat: ShaderMaterial) -> void:
    mat.set_shader_parameter("dissolve_amount", v)
```

### 5.3 Migración desde código actual

Cambios en `item_drop.gd` actual para llegar al contrato:

| Actual (`item_drop.gd`) | Canon v2 (`ground_item.gd`) |
|--------------------------|------------------------------|
| `@export var despawn_time := 180.0` | `const TOTAL_DESPAWN_TIME := 300.0` |
| `_start_despawn_timer()` con blink 30s | Eliminar blink. Reemplazar por `_start_owner_lock_timer()` o `_start_bind_timer()` según flag |
| `_apply_visuals()` usa `StandardMaterial3D` | Swap a `_setup_glow_material()` con `ShaderMaterial` |
| Sin signals | 4 signals nuevas: `owner_lock_expired`, `free_for_all_started`, `despawning`, `bind_expired` |
| `dropped_by: String` (nombre) | **Canon v2**: ownership por `save_profile_id` persistente. Refactor pendiente B — el nombre en label puede seguir, pero la lógica de permission usa ID |

---

## 6. Refs visuales

**Glow pulse** (owner-locked): Diablo 4 beam + pulse, Path of Exile rim, WoW Classic quest items.
**Dissolve ascend** (despawn): Genshin Impact evaporación, Hades boon fade.
**Ring shock** (FFA start): Borderlands owner-release flash, Vermintide 2 loot dice ring.

**NO copiar**: efectos sobrenaturales explícitos (no fantasmas, no cráneos). Low-poly stylized — alma/polvo abstracto color rareza.

---

## 7. Performance

- Shaders fragment-only sin textures externas → costo bajo.
- GPUParticles3D one-shot → self-free vía `queue_free`.
- Sin point lights por VFX (el item ya tiene `AuraLight` OmniLight3D — no duplicar).
- Cap visual: >20 drops simultáneos → considerar disable pulse en common (revisar profiler post-integration).
- Dissolve 0.8s + particles 1.2s → overlap ~0.4s intencional para closure suave antes de `queue_free`.

---

## 8. Coordinación pendiente

### 8.1 Con B (Gameplay) — **BLOQUEANTE**

- [ ] Rename `item_drop.gd` → `ground_item.gd` + `item_drop.tscn` → `ground_item.tscn` (canon v2 usa ese nombre)
- [ ] Agregar 4 signals canon: `owner_lock_expired`, `free_for_all_started`, `despawning`, `bind_expired`
- [ ] Reemplazar `despawn_time = 180.0` por constantes canon v2 (180 / 120 / 300)
- [ ] Branch según `item_data.bind_on_drop`: normal (3 estados) vs bind (2 estados)
- [ ] Eliminar blink 30s (dissolve final basta de communication)
- [ ] Refactor `dropped_by` (nombre) → `owner_save_profile_id` (persistente, canon v2 regla #7)
- [ ] Confirmar nombres signal: `owner_lock_expired` + `free_for_all_started` son dos signals separadas o una sola. Si preferís una sola, avisar.

### 8.2 Con C (Design) — no bloqueante

- [ ] `bind_on_drop = true` debe estar seteado en ItemDatabase para: Corona evento, items quest, Royal Gel, loot ritual. Verificar lista final.
- [ ] Confirmar si Tier "Epic" entra entre `rare` y `unique` en ItemDatabase (sin resolver desde v1). Si no entra, doc está completo.

### 8.3 Multiplayer (futuro)

- Ownership por `save_profile_id` ya soporta peer_id-agnostic (no rompe al meter Steam P2P).
- VFX deben sincronizar via MultiplayerSynchronizer cuando entre networking. Los timers canon (180/120/300) corren authoritative en host, clients reciben signal RPCs.

---

## 9. Red flags

- **NO** poner glow ×1.6 en bind items Y drops normales durante su lock → matas la lectura. Bind mantiene ×1.6 todo el ciclo, normal baja a ×1.0 a los 180s.
- **NO** usar AnimationPlayer en cada drop para el pulse → el shader lo hace gratis vía TIME.
- **NO** spawn point lights extras desde los VFX → ya hay AuraLight, suma costo de sombras.
- **NO** olvidar setear `set_color` antes de `add_child` en los VFX → si no, salen blancos.
- **NO** disparar `ownership_release_vfx.tscn` en bind items → bind no tiene FFA phase, se saltea ese ring shock.
- **NO** cambiar el `OmniLight3D` AuraLight existente — es complementario al glow shader, no compite.
- **NO** eliminar el label `[owner_name]` antes de t=180s → es la señal textual que acompaña al glow ×1.6 (doble canal lectura).
