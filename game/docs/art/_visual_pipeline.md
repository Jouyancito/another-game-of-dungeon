# Visual Pipeline — Tier 1 (wave3)

> **⚠️ TODO-canon-update (2026-04-23)**: refs a pisos con naming chileno (Pire-Mapu/Nahuelbuta/Quicaví/Tres Cumbres) quedaron **DEPRECATED** por rewrite a **hub planetario multicultural** en `_world_canon.md` v2.0. El pipeline técnico (toon shader, lightmaps, env_pradera base) **se mantiene**; solo cambia el naming de los pisos. Nuevos nombres canon: Valle de Erindar (piso 1, celta) / Selva de Aokigahara (piso 2, japonés) / Jötunheim (piso 3, nórdico) / Desierto de Al-Samum (piso 4, árabe) / Umbral Fragmentado (piso 5). Ver `_world_canon.md` v2.0 §13. No tocar por ahora — actualizar cuando se integren los pisos reales.

**Versión**: 1.0 — 2026-04-21
**Estado**: Canon. Base pipeline visual para subir el LOOK de "prototipo" a "juego" sin tocar poly count.
**Scope**: toon shader canon + WorldEnvironment per bioma + lightmap bake workflow + material presets per rol.
**Owner**: Dept Art (D).

---

## 0. TL;DR

Pipeline de 4 frentes acoplados:

1. **Toon shader** (`toon_basic.gdshader`) — ramp 3-step + rim + emission opcional + outline separado por inverse hull.
2. **Materiales preset** (`game/assets/art/materials/toon_*.tres`) — un preset por rol (floor, player, enemy, prop). Cada escena referencia el preset como `ExtResource` — NUNCA duplicar shader_parameter por instancia.
3. **WorldEnvironment per bioma** (`game/assets/art/environments/env_*.tres`) — Glow + SSAO + VolumetricFog + ACES + Adjustments. 5 presets canon (uno por piso). Wave3 implementa Pradera; resto documentado en §4.
4. **Lightmap bake** — `LightmapGI` node por scene + meshes estáticos con `gi_mode = 2` (STATIC) + `DirectionalLight3D` con soft shadows.

Iteración: montar pipeline en `scenes/test/test_visual_tier1.tscn` (§7), juzgar aislado, recién después tocar `main.tscn`.

---

## 1. Toon shader — `toon_basic.gdshader`

**Ubicación**: `game/assets/art/shaders/toon_basic.gdshader`.

### 1.1 Uniforms canon

| Uniform | Tipo | Default | Rol |
|---|---|---|---|
| `albedo_color` | `vec4` source_color | `(1,1,1,1)` | Color base (tint cuando hay textura) |
| `albedo_texture` | `sampler2D` | white | Textura opcional |
| `use_albedo_texture` | `bool` | `false` | Activa textura |
| `ramp_steps` | `float [2..6]` | `3.0` | Bandas del ramp (shadow/mid/light por default) |
| `ramp_smoothness` | `float [0..0.2]` | `0.02` | Suavidad del borde entre bandas. `0` = hard cel-shade |
| `shadow_intensity` | `float [0..1]` | `0.55` | Cuán oscura es la banda baja. `1` = pitch black en shadow |
| `rim_color` | `vec4` source_color | `(1,0.95,0.85,1)` | Color del rim Fresnel |
| `rim_power` | `float [0.5..16]` | `4.0` | Agudeza del rim — más alto = rim más fino |
| `rim_intensity` | `float [0..4]` | `1.0` | Fuerza del rim |
| `emission_color` | `vec4` source_color | `(0,0,0,1)` | Emisión constante |
| `emission_energy` | `float [0..8]` | `0.0` | Multiplicador emisión |

### 1.2 Convención ramp_steps per rol

| Rol | ramp_steps | ramp_smoothness | Razón |
|---|---|---|---|
| Player | 3 | 0.02 | Hard cel. Hero reading. |
| Enemy | 3 | 0.02-0.05 | Hard cel. Slimes/pulpos suelen 0.05 por orgánico. |
| Prop/terrain | 3 | 0.04 | Bandas blandas, evita aliasing en grandes superficies. |
| Hero emisivo (diamante, portales) | 4 | 0.08 | Más bandas + suave = glow interno más rico. |

### 1.3 Convención rim per rol

| Rol | rim_color | rim_power | rim_intensity |
|---|---|---|---|
| Player Warrior | dorado `#D4A040` | 3.5 | 1.2 |
| Player Mage | azul-cyan `#A9D3E9` | 3.0 | 1.4 |
| Enemy genérico | blanco cálido | 3.0-4.0 | 1.0-1.3 |
| Enemy boss | color de la clase (rojo rage, verde slime, etc) | 2.5 | 1.5+ |
| Prop wood/stone | tono cálido del bioma | 4.0-4.5 | 0.6-0.8 |
| Terrain floor | color del sol del bioma | 5.0 | 0.3-0.4 (tenue) |

**Regla**: rim saturado SOLO en actores (player/enemy). Props y terrain usan rim bajo (<0.8) para no competir con el read principal.

### 1.4 Outline — `toon_outline.gdshader`

**Inverse hull**: shader separado con `cull_front` que expande vertex a lo largo del normal. Uso opcional — activar sólo en heroes y props contrastantes (no todo el mundo).

**Params**:
- `outline_color` — default `#0A0A0F` (casi negro pero con tinte azul).
- `outline_thickness` — `0.012` default. Subir a `0.02` en heroes de lejos, bajar a `0.006` en props pequeños.

**Cómo aplicar** (workflow Godot):
1. Duplicar el `MeshInstance3D` como hijo del mismo parent.
2. Setear `surface_material_override/0 = toon_outline.tres`.
3. Opcional: escalar ligeramente el hijo para ajustar grosor sin tocar el param.

**Limitación conocida**: inverse hull no funciona bien en meshes con normals discontinuas (cubos perfectos). Para cubos/primitivos, preferir outline post-process (futuro — screen-space edge detection).

---

## 2. Material presets — `game/assets/art/materials/`

**Regla de oro**: cada rol tiene un preset `.tres` único. Las escenas lo referencian como `ExtResource`. **NUNCA** duplicar shader_parameter en sub_resources ShaderMaterial salvo overrides muy locales.

### 2.1 Presets canon wave3

| Preset | Color albedo | Uso |
|---|---|---|
| `toon_base.tres` | blanco `#FFFFFF` | Default/placeholder. Punto de partida para forks. |
| `toon_grass_floor.tres` | verde pastel `#8FAE6B` | Floor arena Pradera + tile grass P1 |
| `toon_wall_stone.tres` | gris `#6B6661` | Walls, piedra estructural |
| `toon_player_warrior.tres` | acero `#7A7A82` + rim dorado | Warrior cápsula |
| `toon_player_mage.tres` | azul arcano `#4D4DCC` + rim cyan + emission azul | Mage cápsula |
| `toon_enemy_red.tres` | rojo `#CC3333` + emission rojo leve | enemy_basic cubo |
| `toon_enemy_slime.tres` | verde `#33BF33` + emission verde | slime |
| `toon_enemy_stone.tres` | gris piedra `#85807B` | golem body |
| `toon_enemy_wolf.tres` | gris-negro `#595550` | wolf |
| `toon_prop_wood.tres` | marrón `#7A5A3B` | cofres, palisades, barrels |

### 2.2 Variantes inline aceptables

Si un node necesita leve variante (ej. golem head emisivo naranja vs body sin emisión):

```gdscript
[sub_resource type="ShaderMaterial" id="ShaderMaterial_head"]
resource_local_to_scene = true
shader_parameter/albedo_color = ...
...
```

**Resource_local_to_scene = true** es importante para que la variante no se comparta entre instancias.

---

## 3. WorldEnvironment — Pradera (implementada wave3)

**Ubicación**: `game/assets/art/environments/env_pradera.tres`.

### 3.1 Params canon

| Param | Valor | Motivo |
|---|---|---|
| `background_mode` | 1 (Color) | Lore Pradera es caverna interior — NO sky HDRI abierto. Ver `_world_canon.md` §Pradera |
| `background_color` | `#B8C4D8` azul-lavanda | Techo caverna en sombra (`p1_pradera.md` §3) |
| `ambient_light_source` | 2 (Color) | Fill global independiente del sky |
| `ambient_light_color` | `#B8C4D8` | Mismo hue que fondo para coherencia |
| `ambient_light_energy` | `0.4` | Evita cubo sin detalle en lado sombra |
| `tonemap_mode` | 3 (ACES) | Contraste filmo + highlights no se queman |
| `tonemap_exposure` | `1.0` | Baseline — subir si el bioma queda apagado |
| `glow_enabled` | true | Para que emission del mage/sinrgia/crystal_ceiling lea |
| `glow_intensity` | `0.8` | Suave — no bake glow dentro del albedo |
| `glow_strength` | `1.0` | Default |
| `glow_bloom` | `0.1` | Bloom discreto, evita lavado |
| `glow_hdr_threshold` | `1.0` | Solo emission >1.0 aporta bloom |
| `ssao_enabled` | true | Contacto entre meshes — hace que todo se siente "asentado" |
| `ssao_radius` | `2.0` | Rango mediano, no acorta demasiado |
| `ssao_intensity` | `1.0` | Visible sin sobre-oscurecer |
| `ssao_power` | `1.5` | Curva del AO |
| `ssao_light_affect` | `0.5` | AO atenuado en zonas iluminadas — look más natural |
| `fog_enabled` | true | Height fog + light fog unificados |
| `fog_light_color` | `#C8D4E0` | Hue coherente con background |
| `fog_density` | `0.004` | Sutil — se nota a 30m+ |
| `fog_sun_scatter` | `0.15` | Dispersión en dirección del sol, god-ray-ish |
| `volumetric_fog_enabled` | true | Densidad volumétrica para god-rays del diamante |
| `volumetric_fog_density` | `0.01` | Bajo — no bloquear gameplay |
| `volumetric_fog_albedo` | `#FFF2D8` blanco-amarillo cálido | Tint cálido del "sol diamante" |
| `volumetric_fog_anisotropy` | `0.2` | Forward scatter — god rays leen mejor mirando al sol |
| `volumetric_fog_length` | `48.0` | Cubre la arena entera (20×20 + margen) |
| `adjustment_enabled` | true | Color grade final |
| `adjustment_brightness` | `1.02` | +2% — mínima |
| `adjustment_contrast` | `1.05` | +5% contraste — look más punchy |
| `adjustment_saturation` | `1.1` | +10% saturación — look de anime, no documentary |

### 3.2 DirectionalLight3D canon Pradera

```gdscript
transform = Transform3D(0.766, -0.492, 0.413, 0, 0.643, 0.766, -0.643, -0.587, 0.492, 0, 12, 0)
# ≈ azimuth 40°, elevation 55° — golden-hour suave del diamante arriba-izquierda
light_color = Color(0.96, 0.85, 0.63, 1)  # #F5D8A0 dorado tibio canon p1_pradera.md §4
light_energy = 1.2
shadow_enabled = true
shadow_blur = 2.5             # Soft shadows (MEDIUM equivalente)
directional_shadow_mode = 2   # PSSM 4 splits
directional_shadow_max_distance = 60.0
```

**Por qué no 3.5 como p1_pradera**: en arena test 20×20 + mesh cápsulas, `3.5` quema la escena. `1.2` + ACES + glow emision hace que el look final tenga la potencia de 3.5 pero sin blowout. Al integrar assets P1 finales (diamante + god rays shader) se podrá subir a 2.0-2.5.

---

## 4. Paletas per bioma — canon

Implementación: un `.tres` por bioma en `game/assets/art/environments/`. Wave3 sólo Pradera; el resto quedan en este canon como spec listo para wave4+.

### 4.1 Pradera (Piso 1 — implementada)

- **Temperatura**: cálida.
- **Hue dominante**: verde pastel + dorado.
- **Fondo**: `#B8C4D8` (techo caverna).
- **Sol**: `#F5D8A0`, elevation 55°, energy 1.2.
- **Fog**: `#C8D4E0` density 0.004.
- **Volumetric fog**: `#FFF2D8` density 0.01.
- **Adjustments**: sat +10%, contrast +5%.
- **Emoción**: asombro + calma rota. Falsa seguridad.

### 4.2 Bosque Nahuelbuta (Piso 2 — spec)

- **Temperatura**: fría-neutra.
- **Hue dominante**: verde profundo + cyan.
- **Fondo**: `#2E3D35` (bosque denso sin cielo visible).
- **Sol**: `#A8C48F` verde-filtrado, elevation 40°, energy 0.9 (hojas filtran).
- **Fog**: `#6B8575` density 0.012 (bosque cerrado, lectura corta).
- **Volumetric fog**: `#8FAE9C` density 0.02 (god rays verdes entre árboles).
- **Adjustments**: sat +5%, contrast +8%. **Tint verde leve** en LUT cuando haya.
- **Emoción**: opresión + algo vivo observándote.

### 4.3 Hielo Pire-Mapu (Piso 3 — spec)

- **Temperatura**: fría.
- **Hue dominante**: blanco-azul + highlights cian.
- **Fondo**: `#D8E0E8` blanco-cielo-frío.
- **Sol**: `#E8F0FF` azul-blanco frío, elevation 25° (sol bajo), energy 1.6.
- **Fog**: `#C8D4E0` density 0.008 (atmósfera seca).
- **Volumetric fog**: `#FFFFFF` density 0.005 (wind-blown snow implícito).
- **Adjustments**: sat **-15%** (palidecer), contrast +10%, brightness +5%.
- **Emoción**: aislamiento + belleza cortante.

### 4.4 Tormenta Tres Cumbres (Piso 4 — spec)

- **Temperatura**: neutra con rayos violeta-blanco.
- **Hue dominante**: gris-violeta + destellos.
- **Fondo**: `#2A2938` violeta oscuro (cielo cerrado con nubes).
- **Sol**: `#C8B8D8` luz diffusa tormenta, elevation 60° invisible detrás de nubes, energy 0.6 (sin dirección clara). Complementar con `OmniLight3D` flashes cíclicos.
- **Fog**: `#45485A` density 0.015 (lluvia visible).
- **Volumetric fog**: `#5A4D6B` density 0.025 (densidad de tormenta).
- **Adjustments**: sat **-20%** (desaturar), contrast +12%.
- **Emoción**: caos + energía contenida.

### 4.5 Dimensión Rota (Piso 5 — spec)

- **Temperatura**: imposible — magenta + verde tóxico contrastan.
- **Hue dominante**: magenta-violeta + acentos verde ácido.
- **Fondo**: `#1A0F22` violeta profundo.
- **Sol**: `#C875E8` magenta simbólico, elevation direccional variable (multi-luz), energy 0.8.
- **Fog**: `#5A2D6E` density 0.01.
- **Volumetric fog**: `#9E3CB8` density 0.03 (niebla viva).
- **Adjustments**: sat +25%, contrast +15%. **LUT final obligatoria** cuando exista pipeline de color grading.
- **Emoción**: desgarro + ominoso + belleza alien.

---

## 5. Lightmap bake — workflow Godot 4.6

### 5.1 Pre-requisitos por scene

1. `WorldEnvironment` con Environment resource.
2. `DirectionalLight3D` con `shadow_enabled = true`.
3. `LightmapGI` node agregado a la scene.
4. Meshes estáticos (floor, walls, props fijos) con:
   - `gi_mode = 2` (STATIC) en el MeshInstance3D.
   - Mesh tiene `lightmap_unwrap` (Godot lo genera automático si falta).
5. Meshes dinámicos (player, enemies, props movibles) con `gi_mode = 1` (DYNAMIC) o `0` (DISABLED).

### 5.2 Pasos en editor Godot

1. Abrir la scene (ej. `main.tscn`).
2. Seleccionar el `LightmapGI` node.
3. Setear params:
   - `bounces = 2` (balance calidad/tiempo)
   - `quality = 2` (HIGH)
   - `environment_mode = 2` (CUSTOM_COLOR)
   - `environment_custom_color = <ambient_color del bioma>`
   - `environment_custom_energy = 0.4`
4. Meshes sin UV2: Godot pregunta "Generate lightmap UV2 for unbaked meshes?" → **Yes**.
5. En la toolbar del viewport 3D, clic en `Bake Lightmaps`.
6. Esperar. El archivo `.lmbake` / `.exr` se guarda al lado de la scene.

### 5.3 Commit policy

- Bake file `<5MB`: commit al repo (path estándar: `res://scenes/<scene>/<scene>_lightmap_data.lmbake`).
- Bake file `≥5MB`: NO commit. Agregar al `.gitignore`:
  ```
  *.lmbake
  *.lightmap_data.exr
  ```
  Documentar en el README de la scene cómo re-bakear.
- Wave3 Pradera: bake esperado <2MB (arena 20×20 + cilindros invisibles + ceiling). Commit OK.

### 5.4 Automatización (futuro)

Script de bake headless via Godot CLI:

```bash
godot --headless --quit-after 1 \
  --import \
  path/to/project.godot \
  --bake-lightmaps \
  path/to/scene.tscn
```

**NOTA**: flag `--bake-lightmaps` no está en Godot 4.6 stable por default — requiere módulo custom o editor script invocado via `--script`. Wave3 documenta workflow manual; automatización queda para wave4.

### 5.5 ¿Cuándo re-bakear?

- Agregar/mover un `DirectionalLight3D` o `OmniLight3D`.
- Cambiar emission energy >0.5 en meshes baked-affect.
- Cambiar layout de walls, floor, o props estáticos fijos.
- Cambiar Environment ambient_light_energy.
- **NO** re-bakear al editar players/enemies (son dynamic).

---

## 6. Iteration flow — test scene primero

**Regla canon**: toda experimentación de pipeline visual se hace en `game/scenes/test/test_visual_tier1.tscn` (§7 si implementada) — **no** en `main.tscn`. Cuando el look ya convence aislado, se replica a main en un solo commit.

**Por qué**: iterar shaders/env/lights en scene de producción mete diffs ruidosos que dificultan review + riesgo de romper gameplay paralelo.

### 6.1 Protocolo de cambio

1. Abrir `test_visual_tier1.tscn`.
2. Tocar params hasta que el resultado convenza.
3. Export params a `.tres` (materials + environment).
4. Replicar en `main.tscn`: referenciar los `.tres` nuevos.
5. Commit único — "visual: tune toon ramp + glow pradera".

---

## 7. Stretch — `test_visual_tier1.tscn`

Scene aislada para juzgar pipeline sin contexto de main. Contenido mínimo:

- 3 meshes toon-shaded: esfera (player-like), cubo (enemy-like), plano grande (floor grass).
- 1 `DirectionalLight3D` con params canon §3.2.
- 1 `WorldEnvironment` con `env_pradera.tres`.
- 1 `LightmapGI` baked.
- Camera3D fija a 5m alto, orbit estática.

Si wave3 llega a implementarla, vive en `game/scenes/test/test_visual_tier1.tscn`.

---

## 8. Coordinación con otros departamentos

- **B (Gameplay)**: presets de material no afectan gameplay. Si B agrega una clase nueva, pide un `toon_player_<clase>.tres` a D — NO crees tu propio material inline.
- **C (Design)**: si canon lore/bioma cambia palette/temperatura, sincronizar §4 y generar `.tres` nuevo. Nunca editar `env_pradera.tres` sin actualizar este doc.
- **QA (A)**: al revisar PRs de D, validar que cada .tscn que toca materiales usa `ExtResource` al preset — rechazar ShaderMaterial inline salvo variantes justificadas (§2.2).

---

## 9. Versionado

| Versión | Fecha | Cambios |
|---|---|---|
| 1.0 | 2026-04-21 | Initial — toon shader + 10 presets + env_pradera + 5 biome specs + lightmap workflow |

**Última revisión**: 2026-04-21 (D — wave3 visual-pipeline-tier1).
