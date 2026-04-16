# Mimic — Visual & VFX

**Estado**: Draft v1 — 2026-04-16
**Dept**: Art (worktree D — `dept/art/mimic`)
**Issue**: #60
**Base**:
- `game/scenes/loot/loot_chest.tscn` — referencia visual del estado disguised (mimic debe ser indistinguible hasta el reveal)
- `game/scenes/enemy/base_enemy.gd` — B extiende esto para `mimic.gd` (no scope de Art)

> Cofre falso que se disfraza de loot chest común y ataca al interact. Esta doc cubre la capa visual: mesh con dos estados (disguised / revealed), animación reveal, y VFX del reveal.

---

## 1. Estados visuales

### 1.1 Disguised
**Indistinguible** del `loot_chest.tscn` actual:
- Geometría: BoxMesh body 1.0×0.6×0.7 + lid 1.0×0.15×0.7
- Color madera marrón `#73502666` (`Color(0.45, 0.30, 0.15)`) — mismo que `LootChest._apply_tier_visuals()` para tier COMMON
- Label3D "Cofre [E]" idéntico (oculto por default; B lo activa al entrar en interact range)
- Sub-meshes revealed (dientes, ojos, lengua, mouth_inner) están `visible = false`

El player que mira un mimic disguised NO debe poder distinguirlo de un cofre normal a simple vista. La diferencia se revela al interactuar.

### 1.2 Revealed
Tras la animación `reveal`:
- Tapa abierta hacia atrás 45° (rotation X = -0.785rad)
- 6 dientes triangulares blancos: 3 superiores (cuelgan del lid) + 3 inferiores (sobre el borde del cuerpo)
- 2 ojos esféricos amarillo brillante `#FFD700` con emission energy 2.5
- Lengua rosa-roja saliendo del centro de la boca
- Plano oscuro `MouthInner` cubre el hueco interior del cofre (evita ver vacío)

---

## 2. Assets entregados

```
game/scenes/enemy/
└── mimic_chest.tscn                 # Mesh + AnimationPlayer (sin script — B agrega mimic.gd)

game/scenes/enemy/vfx/
└── mimic_reveal_vfx.tscn            # Burst púrpura 30 partículas + flash central — 0.5s self-free

game/docs/art/
└── mimic.md                         # Este doc
```

> **Nota path scene mesh**: el prompt de A pidió `game/assets/models/enemies/mimic_chest.tscn`. Usé `game/scenes/enemy/mimic_chest.tscn` siguiendo la convención del repo (todos los enemies viven en `scenes/enemy/` — turtle, fox, bandit, golem, king_slime, etc.). `assets/models/` no existe como directorio canónico y mezclar `.tscn` ahí rompería el patrón. Si A prefiere el path original, mover es trivial (`mv` + actualizar referencias en `mimic.gd` cuando B lo escriba).

---

## 3. Estructura del scene `mimic_chest.tscn`

```
MimicChest (CharacterBody3D, groups=["enemies", "interactables"])
├── CollisionShape3D                 (BoxShape 1.0×0.6×0.7, igual que loot_chest)
├── ChestBody (MeshInstance3D)       (BoxMesh body, color madera)
├── MouthInner (MeshInstance3D)      (plano oscuro, hidden)
├── LidPivot (Node3D)                (pivote en borde trasero-superior y=0.6 z=-0.35)
│   ├── LidMesh (MeshInstance3D)     (BoxMesh lid offset adelante)
│   └── TeethUpper (Node3D, hidden)
│       ├── ToothU1 / ToothU2 / ToothU3   (PrismMesh blancos, rotación 180° X+Z)
├── TeethLower (Node3D, hidden, y=0.7)
│   ├── ToothL1 / ToothL2 / ToothL3       (PrismMesh blancos)
├── Tongue (MeshInstance3D, hidden)  (BoxMesh rosa)
├── EyeLeft (MeshInstance3D, hidden) (SphereMesh amarillo emisivo, x=-0.22 y=0.45 z=0.36)
├── EyeRight (MeshInstance3D, hidden)(SphereMesh amarillo emisivo, x=+0.22)
├── AnimationPlayer                  (libraries: RESET + reveal)
└── Label3D                          ("Cofre [E]", hidden por default)
```

**Convenciones aplicadas**:
- Root `CharacterBody3D` con `groups=["enemies"]` igual que turtle/fox/golem/king_slime — B puede heredar `BaseEnemy`.
- `groups=["interactables"]` adicional para que el sistema de interact-on-E del player detecte el chest disguised (mismo grupo que `LootChest`).
- Sin script atado al .tscn — B agrega `mimic.gd` y wira signals.

---

## 4. Animación `reveal`

**Duración**: 0.6s. Tracks (8 totales en `Anim_reveal`):

| t (s) | Track | Acción |
|-------|-------|--------|
| 0.00 | EyeLeft / EyeRight `:visible` | `false` |
| 0.10 | EyeLeft / EyeRight `:visible` | `true` (ojos aparecen) |
| 0.18 | MouthInner `:visible` | `true` (plano oscuro aparece antes de abrir) |
| 0.20 | LidPivot `:rotation` | tilt mínimo `(-0.1, 0, 0)` (anticipación) |
| 0.25 | LidPivot/TeethUpper `:visible` | `true` (dientes superiores aparecen al empezar a abrir) |
| 0.30 | Tongue `:visible` + `:scale` | aparece a scale `(0.3, 1, 0.3)` |
| 0.30→0.50 | Tongue `:scale` | crece a `(1, 1, 1)` (lengua sale) |
| 0.40 | LidPivot `:rotation` | abierto `(-0.785, 0, 0)` = -45° |
| 0.50 | TeethLower `:visible` | `true` |
| 0.50→0.55→0.60 | ChestBody `:scale` | squash `(1,1,1) → (1.12, 0.88, 1.12) → (1,1,1)` (rebote) |

**Anim `RESET`**: vuelve todo al estado disguised (lid rotation 0, todo invisible, body scale 1). `autoplay = "RESET"` para que al instanciar la escena arranque disguised por default.

### 4.1 Cómo escuchar el final (B)

`AnimationPlayer` emite `animation_finished(anim_name: StringName)` built-in. B conecta:

```gdscript
# en mimic.gd (B)
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: StringName) -> void:
    if anim_name == "reveal":
        reveal_animation_finished.emit()
```

NO requiero un signal custom desde el .tscn (evita atar la escena a un script que no controlo). Si B prefiere que el AnimationPlayer dispare directo via Method track, decirlo y agrego un track tipo "method" — pero la convención built-in es más limpia.

---

## 5. VFX reveal — `mimic_reveal_vfx.tscn`

**Spawn**: B instancia + posiciona + add_child al `current_scene` (NO al mimic, así sobrevive si el mimic empieza a moverse o se destruye temprano).

```gdscript
# en mimic.gd, listener de `disguise_revealed`:
const MIMIC_REVEAL_VFX := preload("res://scenes/enemy/vfx/mimic_reveal_vfx.tscn")

func _on_disguise_revealed() -> void:
    var vfx := MIMIC_REVEAL_VFX.instantiate()
    get_tree().current_scene.add_child(vfx)
    vfx.global_position = global_position + Vector3(0, 0.5, 0)  # centro de la boca
```

**Composición**:
- **Burst** (30 part., 0.4s): emisión esférica radio 0.18m, vel 2.5-4.0, gravity -1.5 (caen suave), scale curve 0.3→1.0→0.0 (pop + fade), color `#B040E6` (púrpura trickster).
- **Flash** (16 part., 0.25s): anillo XZ central, vel 0.6-1.2, scale 0.5-0.9, color `#FFCCFF` (lavanda claro central).
- **Self-free**: timer interno 0.5s → `queue_free`.
- API: `set_color(c: Color)` para tunear desde código.

**Por qué púrpura y no rareza**: el púrpura comunica "trampa / engaño / trickster" — distinto del color rareza que comunica loot. Si Art quisiera reusar paleta canon, `epic` (`#9933CC`) es el más cercano y estaría bien — pero la decisión actual es separar deliberadamente la lectura "esto NO es loot, es un enemigo" del sistema de drops.

### 5.1 Camera shake — hook para B (no en este scene)

Decisión consciente: **no wireo camera shake en `mimic_reveal_vfx.tscn`**. El VFX scene no debe tener referencias hard-coded a la cámara del player (acopla el asset a una jerarquía específica).

B hace el shake conectando directo desde `disguise_revealed` al método de shake de la cámara:

```gdscript
# en mimic.gd
func _on_disguise_revealed() -> void:
    # ... spawn vfx ...
    var cam := get_viewport().get_camera_3d()
    if cam and cam.has_method("shake"):
        cam.shake(0.3, 0.15)  # amount, duration — ajustar a feel
```

Si el player aún no tiene `shake()` en su cámara, es una task aparte (no scope de este art drop).

---

## 6. Signals esperados de B

Documentados acá para que Art/Design tengan contrato claro. **NO emitidos por estos assets — B los implementa en `mimic.gd`**:

| Signal | Emisor | Cuándo | Listener Art |
|--------|--------|--------|--------------|
| `disguise_revealed(mimic: Mimic)` | mimic.gd | Player interactúa con E al cofre disguised | Spawn `mimic_reveal_vfx.tscn` + camera shake + play "reveal" anim |
| `reveal_animation_finished` | mimic.gd | `AnimationPlayer.animation_finished` con `anim_name == "reveal"` | (Gameplay-only — B transiciona a state AGGRESSIVE) |
| `mimic_died(mimic: Mimic)` | mimic.gd / base_enemy on_death | HP llega a 0 | (Opcional — VFX death no incluido en este drop, ver §7) |

**Coordinación pendiente con B**: si los nombres de signals difieren de lo que B implemente, alinear acá. Doc se actualiza vía bus.

---

## 7. VFX combat (no entregados — opt-in futuro)

Mencionados en el prompt como nice-to-have. NO están en este drop:

- **Bite VFX**: pequeño efecto rojo en la boca al ataque melee. Sugerencia: Particles3D one-shot, 8 part. rojo, 0.2s, gatillado en `mimic.gd` cuando emite ataque.
- **Death VFX**: cofre colapsa (squash exagerado + fade material) + dientes se rompen (spawn 6 PrismMesh con velocity radial + gravity) + drops salen del centro (B ya lo hace via `DropController.spawn_drops`).

Si A o Design quieren estos, abrir un bus task `dept/art/mimic-combat-vfx` después de que B y C cierren la base.

---

## 8. Materiales y colores

| Elemento | Color hex | Notas |
|----------|-----------|-------|
| Madera (body + lid) | `#73502666` `Color(0.45, 0.30, 0.15)` | Match exacto loot_chest COMMON |
| Diente | `#F5F5EB` `Color(0.96, 0.96, 0.92)` | Blanco hueso, no blanco puro (más natural) |
| Ojo (albedo + emission) | `#FFD700` `Color(1.0, 0.84, 0.0)` | Amarillo dorado, emission energy 2.5 |
| Lengua | `#D95974` `Color(0.85, 0.35, 0.45)` | Rosa-rojo carnoso |
| Boca interior | `#260D0D` `Color(0.15, 0.05, 0.05)` | Casi negro, da profundidad al hueco |
| VFX burst | `#B040E6` `Color(0.69, 0.25, 0.9)` | Púrpura trickster (NO rareza canon) |
| VFX flash central | `#FFCCFF` `Color(1, 0.8, 1)` | Lavanda claro highlight |

**Variante futura**: ojos rojos `#DC143C` para mimic "elite" / "boss". Hoy todos los mimics usan amarillo. Cuando C defina si hay variantes, agrego material override por nivel.

---

## 9. Performance

- 0 luces dinámicas — los ojos usan emission shader-side (gratis), no `OmniLight3D`.
- 6 PrismMesh + 2 SphereMesh + 4 BoxMesh = 12 sub-meshes total. En forward+ renderer, 1 mimic = ~12 drawcalls (low).
- VFX reveal: 30 + 16 = 46 partículas one-shot durante 0.5s. Instancias múltiples no se solapan en práctica (un mimic se revela una vez).
- Animation Player con 8 tracks corre 0.6s una sola vez por reveal. No loops, sin costo continuo.
- Recomendación cap: si en una sala hay >5 mimics simultáneos disguised, no cuesta más que 5 cofres normales (mismas 4 BoxMesh visibles + sub-meshes hidden = no rendering cost).

---

## 10. Coordinación pendiente

### 10.1 Con B (Gameplay) — bloqueante para wire-in

- [ ] B escribe `mimic.gd` extendiendo `BaseEnemy` (referencia: turtle/fox)
- [ ] B atacha `mimic.gd` al root `MimicChest` (ext_resource Script)
- [ ] B implementa signals: `disguise_revealed`, `reveal_animation_finished`, `mimic_died`
- [ ] B conecta `AnimationPlayer.animation_finished` para emitir `reveal_animation_finished`
- [ ] B en estado disguised: NO mueve, NO ataca, sólo escucha interact (E del player)
- [ ] B post-reveal: state AGGRESSIVE, persigue al player, ataca melee (mordida)
- [ ] B activa `Label3D` "Cofre [E]" cuando player está en interact range (igual que loot_chest)
- [ ] B oculta `Label3D` cuando dispara `disguise_revealed`

### 10.2 Con C (Design) — no bloqueante

- [ ] Stats canon (HP / damage / speed / xp_reward) — C documenta
- [ ] Loot table del mimic — C decide (drops mejores que cofre común porque "te trolló"?)
- [ ] Achievement "Tu primer mimic" — C decide trigger (primer kill? primer reveal?)
- [ ] Variantes futuras (ojos rojos para elite) — C decide spawn rules

### 10.3 Con A — confirmaciones

- [ ] Path del scene: usé `game/scenes/enemy/mimic_chest.tscn` por convención. Si preferís `assets/models/enemies/`, mover en próxima iteración.
- [ ] Naming class: B va a usar `class_name Mimic` o `MimicChest`. No afecta art pero sí affecta el preload path en VFX.

---

## 11. Red flags

- **NO** poner luz dinámica en los ojos del mimic — emission del material ya brilla, sumar OmniLight es costo gratuito visualmente.
- **NO** instanciar `mimic_reveal_vfx.tscn` como child del mimic — si el mimic se destruye antes de los 0.5s del VFX, el VFX se va con él. Spawnear en `current_scene`.
- **NO** wirear camera shake en el VFX scene — el VFX no debe conocer la cámara. Hook desde `disguise_revealed` en `mimic.gd`.
- **NO** olvidar que `RESET` anim corre en autoplay — si B agrega lógica que cambia visibility manualmente en `_ready()` antes del autoplay, RESET la pisa. Mejor dejar que RESET haga el setup inicial.
- **NO** asumir que el `Label3D "Cofre [E]"` es propiedad del mimic — el sistema de interact lo activa/desactiva externamente igual que en loot_chest. B no debe hard-codear su visibility en `_ready()`.
- **NO** cambiar el color de la madera sin cambiar también `loot_chest._apply_tier_visuals()` para COMMON — el contrato visual es "indistinguible". Si una desync ocurre, los players detectan mimics por color y se rompe el feature.
