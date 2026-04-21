# Warrior — Mixamo Animations (stubs)

Carpeta target para GLB humanoid retargeted. Fuente: [mixamo.com](https://www.mixamo.com).

## Anims requeridas wave3 (5)

| Archivo | Mixamo asset | Uso canon |
|---------|--------------|-----------|
| `idle.glb` | "Idle" (breathing idle) | BlendSpace2D (0, 0) |
| `walk_forward.glb` | "Walking" (in-place) | BlendSpace2D (0, 0.5) |
| `run_forward.glb` | "Running" (in-place) | BlendSpace2D (0, 1.0) |
| `punch.glb` | "Punching" | OneShot `attack_punch` (trigger Warrior click) |
| `jump.glb` | "Jump" (in-place) | Transition state futura wave4 |

## Pipeline retarget Godot 4.6

1. En Mixamo: elegir character neutral (ej "Y Bot"), asignar cada animación, download:
   - Format: **FBX for Unity / .fbx Binary**
   - Skin: **Without Skin** (para idle) / **With Skin** (para 1 archivo base rig)
   - Frames per Second: **30**
   - Keyframe Reduction: **none**
2. Convertir FBX → GLB con [fbx2gltf](https://github.com/facebookincubator/FBX2glTF) o Blender export GLB.
3. Depositar GLB en esta carpeta.
4. En Godot editor:
   - Seleccionar el GLB del rig base con skin
   - Import tab → "Retarget" → "Bone Renamer": silhouette `SkeletonProfileHumanoid`
   - Reimport
   - Click "Advanced" → "Bone Map" → regenerate; verificar mapping LeftFoot/RightFoot/Hips
5. Para cada anim .glb:
   - Import Animation → extraerla a `.res` separado si se quiere compartir library
   - O unificar todas en un solo `warrior_anims.glb` con varios tracks
6. Asignar al `AnimationPlayer` del `player.tscn` via library drag-drop (editor).

`AnimationController3D._resolve_anims()` detecta las anims por substring del nombre. Los nombres Mixamo standard ("Idle", "Walking", "Running", "Punching") ya son compatibles.

## Si faltan anims

`AnimationController3D.setup()` degrade gracefully → `_active=false` y el `WorldModel` (tween procedural actual) maneja movimiento/ataque como hasta wave2. NO rompe prototipo.

## No-goals wave3

- Strafe left/right anims → wave4 (expansión BlendSpace2D eje X)
- Hit reaction proc → wave4
- Cascadeur hand-crafted → post-Alpha
