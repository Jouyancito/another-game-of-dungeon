# VFX Canon — Warrior Fase 1

**Versión**: 1.0 — 2026-04-18
**Estado**: Canon Fase 1. Base para pipeline VFX del resto de clases.
**Scope**: 4 VFX Warrior general (Puño / Embestida / Grito / Bloqueo Perfecto).
**Handoff**: B (Gameplay) instancia los `.tscn` y llama `play()` desde `player_skills.gd`.

---

## 1. Ubicación y estructura

```
game/scenes/fx/
├── vfx_base.gd                # Base class_name VFXBase — API play()/stop()/signals
└── warrior/
    ├── charge_vfx.gd + .tscn           # Embestida
    ├── war_cry_vfx.gd + .tscn          # Grito de Guerra (toggle)
    ├── punch_impact_vfx.gd + .tscn     # Puño de Guerra (impact en hit)
    └── perfect_block_vfx.gd + .tscn    # Bloqueo Perfecto (shield + parry flash)
```

Shaders custom: `game/assets/art/shaders/vfx/` — reservado. Fase 1 usa `StandardMaterial3D` + emission + `TorusMesh`/`QuadMesh`/`BoxMesh` low-poly. No se requirió shader custom.

---

## 2. API canon (VFXBase)

Todas las VFX heredan de `VFXBase` y exponen:

| Método | Comportamiento |
|---|---|
| `play()` | Arranca efectos. Emite `vfx_started`. Si `duration_s > 0`, programa auto-`stop()` al expirar. |
| `stop()` | Apaga efectos. Emite `vfx_finished`. Si `auto_free == true`, `queue_free()` tras `fade_out_s`. |

**@export params** de `VFXBase`:
- `duration_s: float` — 0 = sostenida (toggle/reactive), >0 = one-shot con auto-stop.
- `auto_free: bool` — default `true`. Si `false` (ej: Grito toggle), el caller controla lifecycle.
- `fade_out_s: float` — tiempo de gracia post-stop para partículas en lifetime residual.

**Señales**: `vfx_started`, `vfx_finished` — para hook diegético opcional (audio sync, analytics).

**Hook pattern estándar en B** (player_skills.gd):
```gdscript
var vfx = preload("res://scenes/fx/warrior/charge_vfx.tscn").instantiate()
get_tree().current_scene.add_child(vfx)       # O self.add_child para follow player
vfx.global_transform = _owner_player.global_transform
vfx.play()
# auto_free queue_free al terminar; no hacer nada más.
```

---

## 3. Specs por VFX

### 3.1 `charge_vfx.tscn` — Embestida

| Campo | Valor |
|---|---|
| Canon ref | `warrior.md §7` — "trail de polvo amarillo (One Piece Gear Second)" |
| `duration_s` | **0.3** — matchea dash tween de B (spec canon §3 SKILL 2 cast 0.2s + movimiento) |
| `fade_out_s` | 0.15 |
| `auto_free` | true |
| Colores | Dorado tibio `#D4A040` + Rojo Rage `#E04828` (paleta Warrior canon §3 skill_icons.md) |

**Componentes**:
- `DustKick` — burst inicial 18 partículas dorado en el suelo (emission sphere 0.25m, gravity -4, one-shot explosiveness 0.9). Sensación "arrancó fuerte".
- `Trail` — emisión continua 24 partículas/0.4s rojo rage detrás del player (spread 25°, velocity 0.5-1.5 m/s). Trail de dash.
- `SpeedLines` — 10 líneas elongadas doradas dirigidas hacia atrás (BoxMesh 0.05×0.05×0.8, velocity 4-6 m/s). Sensación de velocidad motion-blur.

**Trigger B**: `_execute_dash()` — instanciar al inicio (antes del movimiento), anclar al player para que siga la posición. VFX se auto-free al terminar los 0.3s.

---

### 3.2 `war_cry_vfx.tscn` — Grito de Guerra (toggle)

| Campo | Valor |
|---|---|
| Canon ref | `warrior.md §7` — "onda sonora concéntrica dorada (JJK Domain preview)" |
| `duration_s` | **0** — sostenida. Stop manual al toggle off. |
| `auto_free` | **false** — ciclo de vida lo gestiona el caller (un .instantiate() por activación de toggle). |
| `aura_radius_m` | 10.0 (matchea `AOE_LARGE` canon §3 SKILL 3) |
| `shockwave_expand_time` | 0.55s |
| Colores | Dorado `#D4A040` + Dorado oro apagado `#C89F4A` |

**Componentes**:
- `Burst` — 32 partículas radiales one-shot dorado al activar (spread 180°, lifetime 0.7s). "Grito inicial".
- `Shockwave` — `TorusMesh` (inner 0.88 / outer 1.0) escala Tween 0.5→10m en 0.55s con fade opacity 0.85→0. Onda concéntrica dorada.
- `DomeMarker` — `TorusMesh` ring fijo radio 10m (alpha 0.45) persistente mientras toggle activo. Marca el área de efecto al jugador.
- `SustainedAura` — 40 partículas flotantes low-opacity emitiendo dentro del radio (emission_box 4.5×0.1×4.5). Aura continua.

**Trigger B**:
- `_activate_toggle()` → instanciar + `play()`. Guardar ref en `active_toggles[skill.id]["vfx"]`.
- `_deactivate_toggle()` → `stop()` + `queue_free()` manual (auto_free false).

**Nota**: el script intenta matchear visualmente el `Weak` aplicado a enemigos dentro del radio (canon §3 SKILL 3). La partícula sostenida es baja densidad — no tapa gameplay, pero da feedback "algo está pasando".

---

### 3.3 `punch_impact_vfx.tscn` — Puño de Guerra (on-hit)

| Campo | Valor |
|---|---|
| Canon ref | `warrior.md §7` — "shockwave tierra low-poly naranja (Demon Slayer Pilar de Piedra)" |
| `duration_s` | **0.25** |
| `fade_out_s` | 0.1 |
| `auto_free` | true |
| Colores | Naranja cálido `#F28C2E` + Crema `#FFD866` (variación tonal del dorado canon) |

**Componentes**:
- `Flash` — `SphereMesh` 0.3m radius, emission_energy 3.5, Tween scale 0.4→1.4 + alpha 1→0 en 0.18s. Flash de contacto.
- `Sparks` — 16 partículas radiales one-shot naranja (spread 180°, gravity -5, velocity 4-7.5 m/s). Chispas al impacto.

**Trigger B**: en `_apply_skill_to_targets()` (o `_execute_cone()` para Puño), **por cada target impactado**:
```gdscript
var vfx = preload("res://scenes/fx/warrior/punch_impact_vfx.tscn").instantiate()
get_tree().current_scene.add_child(vfx)
vfx.global_position = target.global_position + Vector3(0, 1.0, 0)  # pecho del enemy
vfx.play()
```

---

### 3.4 `perfect_block_vfx.tscn` — Bloqueo Perfecto

| Campo | Valor |
|---|---|
| Canon ref | `warrior.md §7` — "flash blanco + grieta en el escudo" (Sekiro deflect spark) |
| `duration_s` | **0.4** — matchea reactive window base canon §3 SKILL 4 |
| `fade_out_s` | 0.2 |
| `auto_free` | true |
| Colores | Acero `#7A7A82` + Dorado `#D4A040` (shield) + Blanco tibio `#FFF9D8` (flash/sparks) |

**Componentes**:
- `ShieldAnchor` — posicionado 1.1m al frente del parent (`-Z`), contiene:
  - `Shield` — `QuadMesh` 0.9×1.3 acero+oro emission, alpha tween 0→0.55 en 0.08s al play, 0.55→0 en 0.15s al stop.
  - `Flash` — `SphereMesh` 0.25m oculto por default, se dispara con `trigger_parry_flash()`.
  - `Sparks` — 14 chispas one-shot blanco cálido al parry (spread 120°, velocity 2.5-5.5 m/s).

**API extendida**:
```gdscript
play()                    # shield fade-in, queda visible la ventana
trigger_parry_flash()     # spark + flash emission (llamar al detectar block exitoso)
stop()                    # shield fade-out (auto al expirar duration_s)
```

**Trigger B**:
- `_execute_reactive()` → instanciar + `play()`. Shield fade-in durante ventana.
- Al recibir hit dentro de la ventana (antes/después del reflejo) → `vfx.trigger_parry_flash()` para feedback "bloqueo perfecto exitoso".
- `auto_free` cierra lifecycle al expirar los 0.4s.

---

## 4. Checklist handoff B

Para wirear los 4 VFX desde `player_skills.gd`:

- [ ] **Embestida**: `_execute_dash()` línea 422 — preload + instantiate + play al inicio. Parent al `current_scene` y posicionar en `_owner_player.global_transform`.
- [ ] **Grito**: `_activate_toggle()` línea 464 — preload + instantiate + play. Guardar ref en `active_toggles[skill.id]["vfx"]`. `_deactivate_toggle()` línea 477 — `stop()` + `queue_free()`.
- [ ] **Puño impact**: `_apply_skill_to_targets()` línea 357 — por cada target impactado, instantiate + position en target + play.
- [ ] **Bloqueo**: `_execute_reactive()` — instantiate + play al abrir ventana. En callback/hook de block exitoso → `trigger_parry_flash()`.

**Imports útiles** (top of file):
```gdscript
const ChargeVFXScene: PackedScene = preload("res://scenes/fx/warrior/charge_vfx.tscn")
const WarCryVFXScene: PackedScene = preload("res://scenes/fx/warrior/war_cry_vfx.tscn")
const PunchImpactVFXScene: PackedScene = preload("res://scenes/fx/warrior/punch_impact_vfx.tscn")
const PerfectBlockVFXScene: PackedScene = preload("res://scenes/fx/warrior/perfect_block_vfx.tscn")
```

---

## 5. Paleta canon — Warrior Fase 1

Coherencia cross-asset con `skill_icons.md §3`:

| Rol | Hex | Uso |
|---|---|---|
| Primario Acero | `#7A7A82` | Shield, armadura base |
| Accent Dorado tibio | `#D4A040` | Trim, trail charge, burst war_cry, shield accent |
| Accent Dorado apagado | `#C89F4A` | Aura sostenida war_cry |
| Energía Rojo Rage | `#E04828` | Trail rage (charge backwards), shock lines |
| Impact Naranja | `#F28C2E` | Punch impact sparks (warm variant del dorado) |
| Flash Blanco cálido | `#FFF9D8` | Parry flash, sparks bloqueo |

**Regla**: mínimo 2 colores por VFX (primario + accent). Energía solo en VFX que tocan Rage semánticamente (charge forward = dorado ofensivo, charge backwards trail = rage red, punch sparks = naranja cálido).

---

## 6. Performance — notas low-poly

- `GPUParticles3D` > `CPUParticles3D` (convención canon CLAUDE.md). 4/4 VFX usan GPU.
- Mesh draw passes: `BoxMesh`/`SphereMesh`/`TorusMesh` primitivos (no imports externos). Low-poly garantizado por definición.
- Counts canon: DustKick 18, Trail 24, Burst 32, Sparks 14-16, SustainedAura 40, SpeedLines 10. Total peak simultáneo ~150 partículas por player — negligible en desktop, seguro para 6-player coop.
- Emission energy 1.1-3.5 — visible sin quemar la escena. Revisar con scene nocturna (cave) si hay glare.
- Materiales `transparency = 1` (alpha blend). **NO** usar `transparency = 2` (alpha cutoff) para evitar bordes duros en fade-out.
- `cull_mode = 2` (disabled, doble-cara) en los que tienen Quad/Torus aplanados para que se vean desde cualquier ángulo.

---

## 7. Iteraciones futuras

- **Shader speed-lines custom**: si B pide mejor sensación de velocidad en Embestida, agregar shader procedural en `game/assets/art/shaders/vfx/speed_lines.gdshader` (screen-space lines alrededor del player). Fase 1 usa partículas elongadas — funcional pero conservador.
- **Shield crack shader** (Bloqueo): si se quiere grieta animada al bloqueo exitoso, shader con UV mask + tiempo de expansión. Fase 1 usa flash sphere — suficiente.
- **Audio sync**: las señales `vfx_started` / `vfx_finished` están libres para hookear SFX cuando el pipeline de sonido entre. Ver issue futuro.
- **Hit direction en Puño**: actualmente el flash es esférico. Si se quiere direccional (cono hacia atrás del golpe) se agrega `@export var impact_direction: Vector3` y se orienta el sprite burst.
- **Grito evolución Rugido del León**: al evolucionar (canon §3 SKILL 3 + ítem *Corazón de León*), agregar overlay color (naranja cálido melena) al `Burst` + `DomeMarker`. No requiere scene nueva — `@export color_tint: Color`.

---

## 8. Coordinación con otros departamentos

- **B (Gameplay)**: consume la API `play()/stop()/trigger_parry_flash()`. Cualquier cambio en los nombres de método rompe handoff — version-bump este doc y notificar antes de mergear.
- **C (Design)**: si el canon `warrior.md §7` cambia las refs visuales, sincronizar este doc + paleta §5.
- **D (Art)**: propietario de este doc. Owner de VFX cross-class en futuras fases.

---

**Última revisión**: 2026-04-18 (Fase 1 — D, Warrior VFX base)
