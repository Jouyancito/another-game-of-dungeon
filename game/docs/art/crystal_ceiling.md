# Crystal Ceiling — componente de iluminación por bioma

**Canon art** para iluminación de pisos de la torre. La torre es vertical: cada
piso está TECHADO, no abre a cielo. El techo de cristal bioma-teñido filtra luz
desde arriba y define la identidad visual del bioma.

---

## 1. Filosofía

- **La torre es vertical y arcana.** No hay cielo dinámico: cada piso tiene su
  techo de cristal, fuente principal de luz.
- **Identidad visual instantánea** al entrar a un piso → el tinte del cristal
  lo comunica antes que cualquier asset detallado.
- **Cheap y coherente:** un único DirectionalLight3D + OmniLight3D focal por piso.
  No requiere sistema día/noche ni skybox dinámica.
- **Vibe:** torre mágica, "skybox interna", sensación de estar bajo una lente
  gigante de cristal coloreado.

---

## 2. Archivos

| Archivo | Rol |
|---|---|
| `game/scenes/levels/components/crystal_ceiling.tscn` | Escena reusable |
| `game/scenes/levels/components/crystal_ceiling.gd` | Script `class_name CrystalCeiling` |

## 3. Estructura de la escena

```
CrystalCeiling (Node3D)        ← script
├── CeilingMesh (MeshInstance3D) — PlaneMesh flip invertido, material translúcido
├── CeilingLight (DirectionalLight3D) — luz principal, apunta hacia abajo
└── FocusLight (OmniLight3D) — foco central que simula "sol filtrado"
```

- El mesh usa `cull_mode = 2` (CULL_FRONT) para que se vea desde abajo, invertido
  vía `transform` en Y y Z.
- `material_override` se DUPLICA en `_ready()` para que cada instancia tenga su
  tint propio (evita que todas las ceilings compartan la misma referencia).
- `shadow_enabled = true` en la DirectionalLight3D → sombras de paredes/enemigos
  en el piso. Si perf es drama, bajar a `false` (ver §6).

---

## 4. API @export

```gdscript
@export_enum("pradera", "bosque", "hielo", "tormenta", "dimension_rota") bioma
@export size: Vector2 = (50, 50)       # bounding del techo (XZ plano)
@export light_energy: float = 1.2      # 0.3–3.0, intensidad del Directional
@export height: float = 15.0           # altura del techo sobre Y=0
@export enable_focus_light: bool = true
```

Los setters aplican en vivo en el editor (setget). Cambiar `bioma` repinta el
tint; cambiar `size` redimensiona el PlaneMesh; cambiar `height` mueve el mesh
y reposiciona la FocusLight al 50% de la altura.

---

## 5. Paleta canon por bioma

| Piso | Bioma          | Hex       | Mood                              |
|------|----------------|-----------|-----------------------------------|
| 1    | pradera        | `#C8E68A` | verde-amarillo cálido — día primaveral |
| 2    | bosque         | `#4A7A3E` | verde profundo — dosel denso, sombras |
| 3    | hielo          | `#A8D8FF` | azul-cyan claro — frío, luz dura |
| 4    | tormenta       | `#7868A8` | violeta-gris — nubes eléctricas |
| 5    | dimension_rota | `#C84AC8` | magenta corrupto — wrong, glitchy |

### Justificación

- **Pradera `#C8E68A`**: verde cálido con hint amarillo para evocar pasto bajo
  sol de mediodía. Saturación media — no fluorescente.
- **Bosque `#4A7A3E`**: verde oscuro saturado — dosel forestal denso, poca luz
  penetra. Contrasta con piso 1 (más claro) para que el salto entre pisos se
  sienta.
- **Hielo `#A8D8FF`**: cyan claro, alta luminancia → "frío duro", cristal
  real de hielo. Muy diferente de los verdes previos.
- **Tormenta `#7868A8`**: violeta desaturado con undertone gris → nubes
  cargadas, no nubes límpidas. Hint al elemental Lightning sin gritar "rayo".
- **Dimensión Rota `#C84AC8`**: magenta puro saturado — color "wrong" universal
  en videojuegos (Shadow Realm/Void). Comunica corrupción sin palabras.

### Agregar nuevo bioma

1. Extender el `@export_enum` en `crystal_ceiling.gd` con el nuevo key.
2. Agregar entrada en `BIOMA_TINTS` con el `Color("#HEX")`.
3. Documentar hex + justificación en esta tabla.

---

## 6. Performance notes

- `transparency = ALPHA` en el material → **costo GPU** (blending). Impacto
  chico en arena 50×50. Si se escala a boss arena 80m dome (issue futuro) y se
  detecta drop de FPS, opciones:
  - Cambiar a `BLEND_MODE_MIX` sobre `transparency = ALPHA_DEPTH_PRE_PASS` (mejor
    para meshes grandes translúcidos).
  - Bajar `alpha` del albedo a 0.3 (menos tinte, más perf).
  - Sustituir por `StandardMaterial3D` opaco con `emission` alta (pierde el
    feel "cristal" pero gana FPS).
- `shadow_enabled = true` en DirectionalLight3D → en arena 50×50 sin drama, pero
  si la arena crece a 150+ unidades, considerar desactivar sombras.
- `FocusLight` (OmniLight3D) tiene rango 25m → no afecta outside de esa burbuja,
  cheap. Se puede apagar vía `@export enable_focus_light = false` si perf drama.

---

## 7. Usage

### Por piso

Reemplazar la `DirectionalLight3D` global de la escena del piso por una
instancia de `crystal_ceiling.tscn` con el `bioma` correspondiente.

Ejemplo `floor1_prairie.tscn`:

```gdscript
[node name="CrystalCeiling" parent="." instance=ExtResource("2_ceiling")]
bioma = "pradera"
size = Vector2(120, 120)
height = 25.0
```

Ajustar `size` al bounding real del piso (Piso 1 Pradera es 600×600 pero la
arena jugable donde queremos tinte directo es ~120×120).

### Validación visual

`main.tscn` (arena de prueba 20×20) incluye una instancia con:
```
bioma = "pradera"
size = Vector2(20, 20)
height = 8.0
```

Cargar `main.tscn` → cambiar `bioma` en el inspector → tinte del piso, paredes
y enemigos cambia en vivo.

---

## 8. Edge cases

- **Boss arena dome 80m (issue futuro)**: `size = Vector2(80, 80)` + `height`
  más grande (30-40). El componente escala sin romper. Si el dome es circular
  en vez de plano cuadrado, requerirá un mesh custom (override
  `_apply_size()` o duplicar scene).
- **Multi-piso co-op (futuro)**: un solo crystal_ceiling por escena. Si jugadores
  están en pisos distintos, cada piso tiene su propia escena/instancia — no
  problema.
- **Escenarios interiores (mazmorra cerrada)**: apagar `enable_focus_light` +
  bajar `light_energy` a 0.5 — el cristal filtra "algo de luz" pero el interior
  es más oscuro. No implementado por default, dejar como pattern.

---

## 9. Referencias visuales

- **Made in Abyss layer 5 (Sea of Corpses)**: techo/skybox orgánico con tinte
  fijo — no hay sol, la luz ambient es el espacio.
- **Castlevania (series): chapel / library rooms**: techos de vidrio coloreado
  filtrando luz, arquitectura vertical gótica.
- **Hades 2 (Erebus/Oceanus/Olympus)**: cada zona tiene paleta de luz fija que
  comunica identidad sin necesidad de cielo.
- **Metroid Prime (Phendrana Drifts)**: luz azul filtrada desde hielo arriba,
  sensación de "estar encerrado bajo una lente natural".

---

## 10. Red flags / TODOs

- **Dust motes (god rays baratos)**: prompt original sugiere GPUParticles3D con
  motas de polvo flotando en el haz. No implementado en primer pass. Cuando se
  agregue:
  - `GPUParticles3D` hijo de `FocusLight`, emit shape sphere r=2
  - Partículas pequeñas (PointMesh o QuadMesh 0.03×0.03) con gravedad 0
  - Lifetime 8s, cantidad 30-50, velocidad lenta vertical
  - Color modulate = tint bioma lightened(0.4)
- **Dome para boss arena**: cuando se implemente el boss arena 80m con dome
  semiesférico, extender `crystal_ceiling.gd` con `@export use_dome: bool` y
  swap PlaneMesh → SphereMesh clippeada.
- **Animación sutil del tint**: Tween on `_material.emission_energy` (±0.1 cada
  4s) para sensación "respirante" del cristal. Dejar como polish futuro —
  cuidado con motion sickness + perf.

---

**Última revisión**: 2026-04-17 (issue #40 — D)
