# Animation Pipeline — Canon v1.0

**Versión**: 1.0
**Fecha**: 2026-04-21
**Autor**: Dept B (Gameplay) — wave3 `dept/gameplay/animation-tier2`
**Estado**: Canon vigente. Handoff a art (weights) + QA (validación runtime).

## 0. Problema y scope

### Problema
Prototipo wave2 usa `WorldModel` procedural (Node3D jerarquía + `Tween`) para feel. Sin blend, sin root motion, sin IK: el player se desliza, los ataques no ligan, los pies penetran steps. Feel de prototipo técnico, no de juego cooperativo vendible.

### Scope wave3
- Clase target: **Warrior** (5 anims Mixamo: Idle/Walk/Run/Punch/Jump)
- `AnimationTree` programático — construido desde GDScript, no requiere editor GUI para el tree_root
- `SkeletonIK3D` foot placement — raycast por pie, lerp Y, disable en aire
- Degrade gracefully — si rig Mixamo no importado, el WorldModel procedural sigue como fallback (prototipo no se rompe)

### No-goals wave3
- Mage/Archer/Cleric/Necromancer/Danzante — wave4+
- Motion matching, root motion authoring
- Hit reaction proc, aim look IK
- Cloth/hair physics, facial
- Mixamo→Cascadeur handoff — post-Alpha

## 1. Fuente de anims

### Fase prototipo/Alpha — Mixamo (CC0 stock)
- **Ventaja**: 2500+ anims humanoid free, SkeletonProfileHumanoid compatible out-of-box con Godot 4.6, retargetable entre todas las clases (mismo rig base)
- **Desventaja**: genéricas, sin personalidad por clase
- **Uso**: locomotion + ataques base. Suficiente para playtest Fase 1

### Fase Beta+ — Cascadeur hand-crafted
- **Cuándo**: después de validar gameplay. No invertir en anims custom antes de que las mecánicas estén lockeadas
- **Scope**: signature moves per clase (embestida Warrior, arcos dramáticos Mage, sombras Danzante)
- **Pipeline**: mismo rig Humanoid → export GLB → mismo slot en `AnimationPlayer`
- **Decisión canon**: Cascadeur **no bloquea Beta**. Si no hay presupuesto, Mixamo + curación (blend time tuning, speed scaling) es suficiente para Alpha pública.

## 2. Pipeline retarget Godot 4.6

Paso a paso — reproducible por cualquier dept.

### 2.1 Descargar en Mixamo
1. Login mixamo.com
2. Elegir character base neutral — sugerido **"Y Bot"** (low-poly, bones cleanos)
3. Para cada anim canon (Idle/Walk/Run/Punch/Jump):
   - Buscar → asignar a Y Bot
   - **Trim** si la anim loopea con gap
   - Download:
     - Format: **FBX Binary** (mejor que ASCII, 50% menos tamaño)
     - Skin: **Without Skin** (salvo la 1era anim base, que necesita mesh para rig)
     - FPS: **30** (60 es overkill para locomotion, gasta memoria)
     - Keyframe Reduction: **none** (Godot re-reduce en import si querés)

### 2.2 FBX → GLB

Godot 4.6 importa FBX nativo (Godot Engine >= 4.3), pero GLB es más estable cross-platform. Conversión:

**Opción A** — `fbx2gltf` CLI:
```bash
fbx2gltf -i idle.fbx -o idle.glb --binary --keep-attribute auto
```

**Opción B** — Blender:
1. File → Import → FBX
2. File → Export → glTF 2.0 (binary `.glb`)
3. Include → Selected Objects; Transform → +Y Up; Data → Animation

Depositar los GLB en `game/assets/models/warrior/animations/`.

### 2.3 Retarget en Godot editor

1. Abrir proyecto Godot 4.6
2. Seleccionar el GLB del rig base (con skin) en FileSystem
3. Tab **Import** →
   - "Retarget" → "Bone Renamer": ON
   - "Silhouette Fixer": ON, asignar `SkeletonProfileHumanoid`
   - "Rest Fixer": ON (opcional, para corregir T-pose)
4. Click **Reimport**
5. Editor → "Advanced" → "Bone Map": regenerate
6. Validar manualmente los 3 críticos: `Hips`, `LeftFoot`, `RightFoot`. Si mapping incorrecto, `FootIKController` falla.

Para anims sin skin (walk/run/etc), mismo proceso — solo asignar silhouette. El esqueleto se comparte por library.

### 2.4 Poblar AnimationPlayer

1. Abrir `game/scenes/player/player.tscn`
2. Seleccionar nodo `AnimationPlayer` (wave3 stub en escena)
3. Panel Animation → dropdown "Manage Animations" → **Load Animation Library** → apuntar al GLB importado (carga su `AnimationLibrary` con todas las anims del archivo)
4. Validar que las anims aparecen con nombres reconocibles: `Idle`, `Walking`, `Running`, `Punching`, `Jump`. `AnimationController3D._resolve_anims()` detecta por substring case-insensitive — los nombres standard Mixamo ya matchean.
5. Al correr escena, ver output: si `[AnimationController] Anims Mixamo no importadas`, chequear nombres anims vs substrings (`idle`, `walk`, `run`).

## 3. Blend tree structure

### Warrior (wave3 — fully implementada programáticamente)

```
StateMachine
├── locomotion  (AnimationNodeBlendSpace2D, 2D space)
│   ├── point (0, 0)   → idle
│   ├── point (0, 0.5) → walk forward
│   └── point (0, 1.0) → run forward
│
├── attacking   (AnimationNodeOneShot wraps locomotion)
│   └── animation → attack_punch (punch) — variant override en trigger
│
└── dead        (AnimationNodeAnimation — terminal)
```

**Transiciones**:
- `locomotion` → `attacking`: immediate, trigger `OneShotRequest.FIRE`
- `attacking` → `locomotion`: at_end (espera fin del OneShot)
- `locomotion` → `dead`: immediate, advance_condition `is_dead`
- `attacking` → `dead`: immediate, advance_condition `is_dead`

**Parámetros runtime (set desde `AnimationController3D`)**:
- `parameters/locomotion/blend_position` — `Vector2(0.0, speed_norm)`, lerped con damp 10.0
- `parameters/attack_oneshot/request` — `ONE_SHOT_REQUEST_FIRE` para disparar
- `parameters/attack_oneshot/active` — `bool`, read-only, true durante OneShot
- `parameters/state_machine/conditions/is_dead` — `bool`

### Mage/Archer/Cleric/Necro/Danzante (wave4+ placeholder)

Mismo esqueleto. Diferencias:
- **Mage**: add `channel_loop` (rayo canalizado) — OneShot loopeable en vez de fire-and-forget
- **Archer**: add `aim_blend` — eje X del BlendSpace2D = aim up/down, separate de locomotion
- **Cleric**: add `cast_heal` + `cast_buff` OneShots separados
- **Necromancer**: add `summon` OneShot (spawn syncing con VFX signal)
- **Danzante de Sombras**: add `stealth_enter`/`stealth_exit` transitions con fade

Documentar en wave4 doc per-class.

## 4. IK rules

### Foot placement (wave3 — Warrior)
- 2× `SkeletonIK3D` creados runtime por `FootIKController` como children del `Skeleton3D`
- `tip_bone`: `LeftFoot` / `RightFoot` (SkeletonProfileHumanoid standard)
- `root_bone`: `LeftUpLeg` / `RightUpLeg` (2 bones arriba, cadera)
- Target `Node3D` standalone en world-space (no parentado al skeleton)
- Raycast desde `bone_global.origin + Vector3.UP * 0.1` hacia `Vector3.DOWN * 0.6`
- Si hit: target.y = `hit.y + 0.05` (offset evita z-fighting)
- Si no hit (jump/fall): `ik.stop()`, pierna animación normal
- Smooth lerp Y con `lerp_speed=12.0` (step-up sin snap)

### Aim look (wave4+)
- Placeholder: `LookAtModifier3D` en `Head` bone, target = cámara pitch
- Fuera de scope wave3

### Hand IK (post-Alpha)
- Ataques con arma — tip_bone = muñeca, target = arma grip
- Solo si un artista justifica el costo

## 5. Weight class per clase — coordinación con art direction bible (C)

Canon preliminar — revisar vs `_art_direction_bible.md` de C cuando mergee.

| Clase | Weight class | Anim speed mult | Feel target |
|-------|--------------|-----------------|-------------|
| **Warrior** | Heavy | 0.9× | Pesado, pasos marcados, idle con sway ancho |
| **Mage** | Medium | 1.0× | Base neutral, floating idle sutil |
| **Archer** | Light | 1.15× | Ágil, pasos cortos, idle alerta |
| **Cleric** | Medium | 0.95× | Estoico, idle contemplativo |
| **Necromancer** | Light | 0.9× | Etéreo, floating, pasos no tocan piso |
| **Danzante de Sombras** | Ultra-light | 1.2× | Felino, pasos cuasi-silenciosos, idle bajo |

**Implementación** (wave4): en cada `_on_class_ready()`, override:
```gdscript
if animation_controller != null:
    animation_controller.anim_speed_mult = 1.15  # Archer
```
`AnimationController3D` expone `anim_speed_mult` wave4 (no en wave3 — sin arte real no tiene sentido tunearlo).

Si `_art_direction_bible.md` de C define weights distintos al mergear, **canon de art prevalece**. Este doc se actualiza en wave4.

## 6. Degrade gracefully — contrato fallback

**Estado inicial post-merge wave3 (sin GLB importado)**:
- `AnimationPlayer` existe en `player.tscn` pero sin library cargada
- `AnimationController3D.setup()` detecta `_has_required_anims() == false`
- Marca `_active = false`, NO construye tree_root
- `update_locomotion()` / `trigger_attack()` / `set_dead()` son no-ops
- `FootIKController.setup()` detecta `Skeleton3D == null`, marca `_active = false`
- `WorldModel` procedural sigue animando como wave2 — playable, prototipo intacto

**Post-import GLB + retarget**:
- `AnimationPlayer` tiene `AnimationLibrary` Mixamo cargada
- `_has_required_anims()` pasa (detecta Idle/Walk/Run por substring)
- Tree se construye, `_active = true`
- `WorldModel` sigue renderizando pero sus tween no se ven en gameplay — las anims del AnimationTree override los pivots procedurales (mismos nodos, última escritura gana)
- **Recomendación wave4**: ocultar `WorldModel` si `animation_controller._active`, evitar desync.

## 7. Tests y validación

### Tests GUT (`game/tests/unit/test_animation_tree_warrior.gd`)
1. `BlendSpace2D responde a velocity` — setear velocity = run_speed * forward, validar `blend_position.y` cerca 1.0 después de lerp frames
2. `OneShot attack triggerea + animation_finished emite` — llamar `trigger_attack(&"attack_punch")`, validar signal emitted con variant correcto
3. `IK activa/desactiva según is_on_floor` — llamar `update(true)` / `update(false)`, validar ik.is_running state

### Runtime smoke test (QA handoff)
1. Abrir `main.tscn`, correr
2. Mover WASD → ver que transición idle → walk → run (sprint) es fluida, sin snap
3. Saltar → ver que IK pies desactiva (se sueltan) y reactiva al caer
4. Atacar (click) → punch anim reemplaza tween actual, animación visual clara
5. Morir (tank 30s downed) → transition a `dead` state
6. Comparar feel vs wave2 — debe ser drásticamente más legible

## 8. Nombres convenciones

- GDScript clases: `AnimationController3D`, `FootIKController` (sufijo `3D` para distinguir 2D futura, sufijo `Controller` para managers)
- Anim nombres en library: mantener nombres Mixamo originales (no renombrar — el resolver usa substring)
- Bone names: **SkeletonProfileHumanoid standard** (`Hips`, `Spine`, `LeftUpLeg`, `LeftLeg`, `LeftFoot`, etc). Cualquier rig fuera de este estándar requiere adaptación explícita.
- Signals: `attack_finished(variant: StringName)`, `state_entered(state_name: StringName)`

## 9. Changelog

- **v1.0 — 2026-04-21** — Canon inicial wave3 dept B. AnimationController3D + FootIKController + pipeline Mixamo + blend tree structure Warrior. Fallback Tween WorldModel documentado. Weight class prelim vs C.
