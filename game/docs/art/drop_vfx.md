# Drop VFX — Ownership system visual layer

**Estado**: Draft v2.1 — 2026-04-16 (alineado a implementación real de B post Judgment Day)
**Dept**: Art (worktree D — `dept/art/drop-vfx`)
**Base canon**:
- `game/docs/balance/_drop_ownership_canon.md` — reglas ownership v2 (C owner)
- `game/scenes/loot/ground_item.gd` — script real del drop (B owner, rama `dept/gameplay/drop-ownership`). Contrato: 3 signals + `mark_free()`
- `game/scenes/loot/ground_item.tscn` — escena con MeshInstance3D + AuraLight + Label3D
- `game/shared/loot/drop_controller.gd` — autoload que maneja timers canon v2 (180 / 300) y llama `mark_free()`
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

Reusar `ItemDatabase.get_rarity_color(rarity)` — NO duplicar paleta en shaders. Rarezas existentes en `ground_item.gd:155`:

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

Aplica al `MeshInstance3D` del drop. Reemplaza el `StandardMaterial3D` actual (`ground_item.gd:157-163`).

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

GPUParticles3D one-shot, **0.6s**. Spawn en handler de `became_free` (solo drop normal — bind items nunca emiten esta signal).

- **ShockRing** (32 part.): emisión radial flat XZ, vel 1.5-2.5, scale curve creciente, color rareza.

Llamar `vfx.set_color(rarity_color)` antes de `add_child`. Self-frees a los 0.6s.

### 4.4 `bind_expire_vfx.tscn`

GPUParticles3D one-shot, **1.2s**. Spawn en handler de `vfx_despawn_requested` con `reason ∈ {"expired", "bind_expired"}` (ambos ciclos, mismo VFX). Dos emisores:

- **Particles** (24 part., ascend): esfera radio 0.18m, vel 0.6-1.4 hacia +Y, gravity +Y suave.
- **RimFlash** (16 part., ring): anillo radio 0.4m base, flash breve al inicio.

Llamar `vfx.set_color(rarity_color)` antes de `add_child`. Self-frees a los 1.2s.

---

## 5. Signal contract con dept B (implementación real)

**Base real**: `game/scenes/loot/ground_item.gd` (commit B, rama `dept/gameplay/drop-ownership`). Los timers viven en `DropController` (autoload), no en `GroundItem`. `GroundItem` expone API de estado + emite signals; el controller las dispara.

### 5.1 API real de GroundItem

```gdscript
class_name GroundItem
extends Area3D

# --- Signals (3 totales) ---
signal despawned(item: GroundItem, reason: String)
    # Emitido al arrancar despawn. reason ∈ {"expired", "bind_expired", "picked_up"}
    # - "expired"      → drop normal llegó al final del FFA (t=300s)
    # - "bind_expired" → bind item llegó al final del lock directo (t=300s)
    # - "picked_up"    → recogido por un player (no es dissolve VFX — es scale-down de pickup)

signal vfx_despawn_requested(item: GroundItem, reason: String, color: Color)
    # Hook VFX externo. Emitido junto con `despawned`.
    # color = ItemDatabase.get_rarity_color(rarity) ya resuelto.
    # Art escucha esta para spawn de dissolve shader + particle puff.

signal became_free(item: GroundItem)
    # Emitido cuando DropController llama `mark_free()` en t=180s (solo drop normal).
    # Art escucha esta para: baja glow a ×1.0, clear label [owner_name], spawn ring shock.

# --- Método driven por DropController ---
func mark_free() -> void:
    # Flipea el GroundItem a free-for-all.
    # is_free = true, owner_profile_id = "", owner_name = ""
    # Refresca label (saca [owner: name]) y emite `became_free`.

# --- Estado ---
var is_free: bool             # false mientras locked, true post mark_free() o si spawnó sin owner
var is_despawning: bool       # true a partir de despawn_now() — bloquea pickups
var bind_on_drop: bool        # leído de item_data; true = sin FFA phase
var owner_profile_id: String  # persistente (canon v2 #7), "" si libre/sin owner
var owner_name: String        # string legible para label
```

> **Resumen del refactor de v1→v2**: las 4 signals que el doc v1 proponía (`owner_lock_expired`, `free_for_all_started`, `despawning`, `bind_expired`) **colapsaron en 2** (`became_free` + `despawned` con `reason`). B eligió este contrato por simpleza: un solo emisor de "algo terminó" con `reason` como discriminador, en vez de cuatro signals cuasi-equivalentes. Art se adapta.

### 5.2 Mapeo estado visual → hook real

| Estado | Rango | Cómo escuchamos | Acción VFX |
|--------|-------|-----------------|-----------|
| **Owner-locked (arranque)** | 0s, ambos ciclos | En `_apply_visuals()` (run en `_ready()` después de `setup()`) | Swap mesh material → `ground_item_glow.gdshader`, `bind_locked = 1.0`, label con `[owner: name]` (ya lo hace `_refresh_label()`) |
| **FFA start** (solo normal) | t=180s | Connect `became_free` | `bind_locked = 0.0` (glow pulse baja a ×1.0), spawn `ownership_release_vfx.tscn`. Label ya se refrescó solo vía `mark_free()` |
| **Despawn** (ambos) | t=300s | Connect `vfx_despawn_requested` | Swap mesh material → `ground_item_dissolve.gdshader`, tween 0→1 en 0.8s, spawn `bind_expire_vfx.tscn` |

**Bind items**: NO emiten `became_free` — DropController nunca llama `mark_free()` en ellos. Por eso el glow `bind_locked=1.0` queda hasta el despawn. No hay que chequear bind en el listener de `became_free`: si se disparó, es normal.

**reason discriminator en despawn**:
- `"expired"` y `"bind_expired"` → mismo VFX (dissolve + particle puff). Diferencia solo semántica/telemetría.
- `"picked_up"` → **NO** gatillar dissolve shader. El pickup ya tiene su propio tween scale-down en `pickup()`. Art ignora este reason.

### 5.3 Snippet de integración (Art-side)

Si Art quiere pluggear el glow + dissolve sin tocar `ground_item.gd`, la vía recomendada es un listener autoload o un helper instanciado desde `_apply_visuals()`. Ejemplo conceptual:

```gdscript
# Llamado desde GroundItem._apply_visuals() después del StandardMaterial3D actual
# (o dentro de un "ArtLayer" opcional que B habilite si quiere el shader)

func _attach_art_layer() -> void:
    var rarity: String = item_data.get("rarity", "common")
    var rarity_color: Color = ItemDatabase.get_rarity_color(rarity)
    var type_color: Color = _get_type_color(item_data.get("type", "material"))
    var pulse_by_rarity := {"common": 1.0, "magic": 1.5, "rare": 2.0, "unique": 2.5}

    var glow := ShaderMaterial.new()
    glow.shader = preload("res://assets/art/shaders/ground_item_glow.gdshader")
    glow.set_shader_parameter("base_albedo", type_color)
    glow.set_shader_parameter("rarity_color", rarity_color)
    glow.set_shader_parameter("pulse_speed", pulse_by_rarity.get(rarity, 1.0))
    glow.set_shader_parameter("bind_locked", 1.0)
    mesh.set_surface_override_material(0, glow)

    became_free.connect(func(_it: GroundItem):
        glow.set_shader_parameter("bind_locked", 0.0)
        var ring := preload("res://scenes/loot/vfx/ownership_release_vfx.tscn").instantiate()
        add_child(ring)
        ring.set_color(rarity_color)
    )

    vfx_despawn_requested.connect(func(_it: GroundItem, reason: String, color: Color):
        if reason == "picked_up":
            return
        # Swap a dissolve
        var dissolve := ShaderMaterial.new()
        dissolve.shader = preload("res://assets/art/shaders/ground_item_dissolve.gdshader")
        dissolve.set_shader_parameter("base_albedo", type_color)
        dissolve.set_shader_parameter("edge_color", color)
        mesh.set_surface_override_material(0, dissolve)
        var tw := create_tween()
        tw.tween_method(func(v: float):
            dissolve.set_shader_parameter("dissolve_amount", v), 0.0, 1.0, 0.8)
        # Puff particles en paralelo
        var puff := preload("res://scenes/loot/vfx/bind_expire_vfx.tscn").instantiate()
        puff.position = global_position
        get_tree().current_scene.add_child(puff)
        puff.set_color(color)
    )
```

> **Nota**: el `_play_despawn_vfx()` actual en `ground_item.gd` (aura pulse + mesh scale + albedo fade) es un fallback funcional sin shader. El listener de `vfx_despawn_requested` **suma** encima — ambos pueden correr en paralelo sin conflicto (el fallback maneja root scale + queue_free, el listener maneja mesh material swap + particles). Si Art integra shader, el fallback `_play_despawn_vfx` puede simplificarse o quedarse como está.

### 5.4 Estado actual del código vs esta capa

- [x] Signals implementadas (`despawned`, `vfx_despawn_requested`, `became_free`)
- [x] `mark_free()` implementado
- [x] `bind_on_drop` leído de `item_data`
- [x] `owner_profile_id` persistente (canon v2 #7)
- [x] Label `[owner: name]` gestionado por `_refresh_label()`
- [ ] Glow shader wire-in — B no lo plugueó todavía, usa `StandardMaterial3D` + `aura_light`
- [ ] Dissolve shader wire-in — B tiene fallback tween en `_play_despawn_vfx()`, no swap a shader
- [ ] Particle scenes wire-in — NO se instancian todavía desde `ground_item.gd`

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

### 8.1 Con B (Gameplay) — no bloqueante (contrato ya establecido)

Canon v2 en código: **done por B**. Lo que queda es opcional/wire-in de la capa shader:

- [x] `GroundItem` + 3 signals + `mark_free()` implementados
- [x] Timers 180/120/300 en `DropController`
- [x] `bind_on_drop` + `owner_profile_id` persistente
- [ ] **Opcional**: plug glow shader en `_apply_visuals()` (reemplaza StandardMaterial3D) — puede hacerlo D vía Art layer listener, sin tocar ground_item.gd
- [ ] **Opcional**: plug dissolve shader + particle scenes en listener de `vfx_despawn_requested`
- [ ] Decisión: ¿el glow `bind_locked = 1.0` ×1.6 va en commons también? B dejó `aura_light.visible = false` para commons (forward renderer cost). Art puede seguir misma regla: solo glow con `pulse_speed > 1.0` en rareza ≥ magic.

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
