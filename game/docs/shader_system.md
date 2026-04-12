# Sistema de Shaders Integrado — Dungeon Party

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document + Referencia Tecnica
**Departamento**: Game Design + Art & VFX

---

## Tabla de Contenidos

1. [Por que Shaders Integrados](#1-por-que-shaders-integrados)
2. [Como Funcionan los Shaders en Godot 4](#2-como-funcionan-los-shaders-en-godot-4)
3. [Arquitectura del Sistema de Shaders](#3-arquitectura-del-sistema-de-shaders)
4. [Catalogo de Shaders](#4-catalogo-de-shaders)
5. [Sistema de Calidad Grafica](#5-sistema-de-calidad-grafica)
6. [Referencia: Minecraft Shaders → Godot](#6-referencia-minecraft-shaders-a-godot)

---

## 1. Por que Shaders Integrados

### El problema de shaders externos

En Minecraft, los shaders (BSL, SEUS, Complementary) son MODS. El jugador los instala por separado. Esto tiene problemas:
- El jugador puede NO tener shaders → el juego se ve feo
- Cada shader mod se ve diferente → no hay consistencia visual
- Compatibilidad con versiones → se rompen con updates
- Performance impredecible → el dev no puede optimizar

### Nuestra solucion: shaders como parte del juego

Los shaders de Dungeon Party son **parte del engine del juego**. Vienen INCLUIDOS. No son opcionales, no son mods.

Pero — y esto es clave — hay **niveles de calidad** que el jugador elige en Opciones:
- **Bajo**: shaders minimos (cell shading + outline, sin post-process)
- **Medio**: shaders completos sin efectos caros (sin volumetric fog, sin SSR)
- **Alto**: todo habilitado
- **Ultra**: todo al maximo + efectos adicionales

El jugador SIEMPRE ve el juego con shaders. Solo cambia CUANTO shader.

### Por que esto funciona en Godot 4

Godot 4 tiene un **shader language nativo** (basado en GLSL) que compila a Vulkan/OpenGL directamente. No es un wrapper — es acceso directo al GPU pipeline. Esto significa:
- Los shaders corren tan rapido como es posible en el hardware
- No hay overhead de traduccion (como si un mod reinterpretara instrucciones)
- Podemos optimizar cada shader para NUESTRAS necesidades exactas
- El jugador no instala nada — los .gdshader viajan con el proyecto

---

## 2. Como Funcionan los Shaders en Godot 4

### Tipos de shader disponibles

Godot 4 ofrece 4 tipos de shader, cada uno para un proposito:

| Tipo | En Godot | Que controla | Nuestro uso |
|------|----------|-------------|-------------|
| **Spatial** | `shader_type spatial;` | Como se renderiza un mesh 3D | Cell shading, agua, lava, hielo, cristales, vegetacion |
| **Canvas Item** | `shader_type canvas_item;` | Como se renderiza un elemento 2D | HUD effects, damage vignette, UI glow |
| **Particles** | `shader_type particles;` | Comportamiento de particulas GPU | Esporas, ceniza, nieve, brasas, energia |
| **Sky** | `shader_type sky;` | El cielo/fondo | Cielo por bioma, void, tormenta |

### Como se aplica un shader

```
Opcion A: ShaderMaterial en un mesh
  MeshInstance3D
  └─ material: ShaderMaterial
     └─ shader: res://game/shaders/cell_shade.gdshader
     └─ shader_param/shade_color: Color(0.2, 0.1, 0.3)

Opcion B: Post-process en WorldEnvironment
  WorldEnvironment
  └─ environment: Environment
     └─ compositor: Compositor
        └─ compositor_effects: [DesaturationEffect, VignetteEffect]
```

### Lenguaje de shaders de Godot

El lenguaje es casi identico a GLSL (el estandar de la industria). Cualquier shader de Minecraft que use GLSL se puede PORTAR a Godot con ajustes menores.

Diferencias clave:
- `uniform` → `uniform` (igual)
- `varying` → se maneja con `VERTEX`, `NORMAL`, etc. (built-in varyings)
- Fragment shader → funcion `fragment()` en Godot
- Vertex shader → funcion `vertex()` en Godot
- La funcion `light()` permite custom lighting (cell shading)

---

## 3. Arquitectura del Sistema de Shaders

### Estructura de archivos

```
game/
├── shaders/
│   ├── core/                    # Siempre cargados
│   │   ├── cell_shade.gdshader         # Toon shading para modelos
│   │   ├── outline.gdshader            # Bordes de personajes/enemigos
│   │   ├── fresnel_rim.gdshader        # Rim light para separacion
│   │   ├── damage_flash.gdshader       # Flash rojo/verde al recibir danio
│   │   ├── loot_glow.gdshader          # Brillo de items en suelo
│   │   └── interaction_highlight.gdshader # Brillo de objetos interactivos
│   │
│   ├── environment/             # Cargados segun bioma activo
│   │   ├── water_surface.gdshader      # Agua de rios/lagos/oceano
│   │   ├── lava_flow.gdshader          # Lava y metal fundido
│   │   ├── ice_frost.gdshader          # Hielo y escarcha
│   │   ├── crystal.gdshader            # Cristales con refraccion
│   │   ├── sand_scroll.gdshader        # Arena moviendose con viento
│   │   ├── corruption.gdshader         # Pulso de corrupcion
│   │   ├── bioluminescence.gdshader    # Brillo organico pulsante
│   │   └── void_dissolve.gdshader      # Disolucion dimensional
│   │
│   ├── vegetation/              # Vegetacion animada
│   │   ├── wind_grass.gdshader         # Pasto meciendose
│   │   ├── wind_tree.gdshader          # Arboles meciendose (copa)
│   │   ├── wind_foliage.gdshader       # Arbustos y hojas
│   │   └── underwater_plants.gdshader  # Plantas subacuaticas
│   │
│   ├── post_process/            # Efectos de pantalla completa
│   │   ├── desaturation.gdshader       # Desaturar progresivamente
│   │   ├── vignette.gdshader           # Oscurecer bordes (danio, horror)
│   │   ├── color_grading.gdshader      # Ajuste de colores por bioma
│   │   ├── heat_distortion.gdshader    # Distorsion de calor
│   │   ├── underwater.gdshader         # Efecto subacuatico
│   │   └── corruption_screen.gdshader  # Distorsion por corrupcion
│   │
│   ├── transition/              # Transiciones entre pisos
│   │   ├── teleport_beam.gdshader      # Efecto teletransporte (Era 1)
│   │   ├── portal_tunnel.gdshader      # Tunel de portal (Era 2)
│   │   └── fade.gdshader               # Fade in/out basico
│   │
│   ├── sky/                     # Cielos por bioma
│   │   ├── sky_cavern.gdshader         # Techo de caverna con diamante
│   │   ├── sky_storm.gdshader          # Cielo tormentoso con rayos
│   │   ├── sky_void.gdshader           # Vacio estrellado
│   │   └── sky_underground.gdshader    # Oscuridad total
│   │
│   └── includes/                # Funciones compartidas
│       ├── noise.gdshaderinc           # Funciones de noise (perlin, simplex)
│       ├── lighting.gdshaderinc        # Funciones de iluminacion custom
│       └── common.gdshaderinc          # Utilidades (remap, fresnel, etc.)
```

### Sistema de includes

Godot 4 soporta `#include` en shaders. Esto evita duplicar codigo:

```glsl
// noise.gdshaderinc — se incluye en muchos shaders
float perlin_noise(vec2 uv) { ... }
float simplex_noise(vec3 pos) { ... }
float fbm(vec2 uv, int octaves) { ... }

// En un shader que necesita noise:
#include "res://game/shaders/includes/noise.gdshaderinc"
```

### ShaderManager (autoload)

Un script singleton que gestiona que shaders estan activos:

```gdscript
# shader_manager.gd — Autoload
extends Node

enum Quality { LOW, MEDIUM, HIGH, ULTRA }

var current_quality: Quality = Quality.HIGH
var current_biome_shaders: Array[ShaderMaterial] = []

func set_quality(q: Quality) -> void:
    current_quality = q
    _apply_quality_settings()

func load_biome_shaders(biome: String) -> void:
    _unload_current_biome_shaders()
    # Carga solo los shaders relevantes al bioma
    # Pradera: wind_grass + wind_tree + sky_cavern
    # Volcan: lava_flow + heat_distortion + sky_underground
    # etc.

func _apply_quality_settings() -> void:
    # Ajusta parametros de todos los shaders activos
    # LOW: desactiva post-process, reduce iteraciones de noise
    # MEDIUM: post-process basico, noise estandar
    # HIGH: todo habilitado
    # ULTRA: mayor resolucion de efectos, mas iteraciones
    pass
```

---

## 4. Catalogo de Shaders

### Shader 1: Cell Shading (Toon)

**Archivo**: `core/cell_shade.gdshader`
**Tipo**: spatial
**Aplicado a**: todos los modelos 3D (personajes, enemigos, props)

**Que hace**: Reemplaza el shading gradual por BANDAS de luz. El modelo tiene 2-3 colores: iluminado, sombra, y (opcional) penumbra. Es lo que da el look "anime/cartoon" al juego.

**Referencia visual**: Genshin Impact, Breath of the Wild, Kimetsu no Yaiba (cuando animan en 3D CGI)

**Parametros expuestos**:
```glsl
uniform int shade_steps : hint_range(2, 4) = 3;         // Bandas de luz
uniform float shade_threshold : hint_range(0.0, 1.0) = 0.5; // Donde empieza la sombra
uniform vec4 shade_color : source_color;                  // Color de sombra (NO negro)
uniform float shade_smoothness : hint_range(0.0, 0.1) = 0.02; // Suavidad del borde
uniform bool use_ramp_texture = false;                    // Usar textura de gradiente custom
uniform sampler2D shade_ramp;                             // Gradiente de luz custom
```

**Logica clave**: en la funcion `light()`, el dot product entre normal y luz se DISCRETIZA:

```glsl
void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float stepped;
    if (use_ramp_texture) {
        stepped = texture(shade_ramp, vec2(NdotL * 0.5 + 0.5, 0.0)).r;
    } else {
        stepped = smoothstep(shade_threshold - shade_smoothness,
                            shade_threshold + shade_smoothness, NdotL);
    }
    vec3 final_color = mix(shade_color.rgb * ALBEDO, ALBEDO, stepped);
    DIFFUSE_LIGHT += final_color * LIGHT_COLOR * ATTENUATION;
}
```

---

### Shader 2: Outline (Inverted Hull)

**Archivo**: `core/outline.gdshader`
**Tipo**: spatial
**Aplicado a**: segundo pass de personajes y enemigos

**Que hace**: Renderiza un contorno oscuro alrededor de los modelos. Usa la tecnica "inverted hull" — escala el modelo un poco, flipea las normales, renderiza solo la cara trasera en color solido.

**Parametros**:
```glsl
uniform float outline_width : hint_range(0.0, 0.01) = 0.003;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
```

**Logica**: en `vertex()`, empuja los vertices en la direccion de la normal:

```glsl
void vertex() {
    VERTEX += NORMAL * outline_width;
}
void fragment() {
    ALBEDO = outline_color.rgb;
}
// render_mode: cull_front, unshaded
```

**Performance**: casi gratis — es un draw call extra por modelo con un shader trivial.

---

### Shader 3: Wind (Vegetacion)

**Archivo**: `vegetation/wind_grass.gdshader`
**Tipo**: spatial
**Aplicado a**: MultiMeshInstance3D de pasto, flores, arbustos

**Que hace**: Mueve los vertices superiores de la vegetacion simulando viento. Los vertices inferiores (raiz) no se mueven. Usa noise para que no todo se mueva igual.

**Parametros**:
```glsl
uniform float wind_strength : hint_range(0.0, 2.0) = 0.5;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_noise_scale : hint_range(0.1, 10.0) = 2.0;
```

**Logica clave**:
```glsl
void vertex() {
    float height_factor = clamp(VERTEX.y / 0.5, 0.0, 1.0); // Solo mueve la parte alta
    float noise_val = sin(NODE_POSITION_WORLD.x * wind_noise_scale +
                         NODE_POSITION_WORLD.z * wind_noise_scale +
                         TIME * wind_speed);
    VERTEX.x += noise_val * wind_strength * height_factor * wind_direction.x;
    VERTEX.z += noise_val * wind_strength * height_factor * wind_direction.y;
}
```

---

### Shader 4: Water Surface

**Archivo**: `environment/water_surface.gdshader`
**Tipo**: spatial
**Aplicado a**: planos de agua (lagos, rios, oceano)

**Que hace**: Simula agua con movimiento de olas, transparencia, reflejo simplificado, y causticas.

**Referencia**: Minecraft shaders BSL/Complementary water

**Parametros**:
```glsl
uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.7);
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;
uniform float wave_height : hint_range(0.0, 0.5) = 0.1;
uniform float wave_scale : hint_range(1.0, 50.0) = 10.0;
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.02;
uniform float fresnel_power : hint_range(1.0, 10.0) = 4.0;
uniform sampler2D normal_map_1;  // Textura de normales, scroll UV
uniform sampler2D normal_map_2;  // Segunda capa, diferente velocidad
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
```

**Efectos por calidad**:
- **LOW**: color plano + transparencia + scroll UV basico. Sin reflejo, sin refraccion.
- **MEDIUM**: + wave vertex displacement + dual normal map + fresnel
- **HIGH**: + screen space refraction + depth-based foam + causticas proyectadas
- **ULTRA**: + screen space reflection simplificada

---

### Shader 5: Lava Flow

**Archivo**: `environment/lava_flow.gdshader`
**Tipo**: spatial

**Que hace**: Lava con emision brillante, movimiento de flujo con dos capas de noise a diferentes velocidades, distorsion de calor en los bordes.

**Parametros**:
```glsl
uniform vec4 lava_bright : source_color = vec4(1.0, 0.5, 0.0, 1.0);   // Naranja brillante
uniform vec4 lava_dark : source_color = vec4(0.3, 0.0, 0.0, 1.0);     // Rojo oscuro
uniform float flow_speed_1 : hint_range(0.0, 1.0) = 0.1;
uniform float flow_speed_2 : hint_range(0.0, 1.0) = 0.05;
uniform float emission_strength : hint_range(0.0, 5.0) = 3.0;
uniform float noise_scale : hint_range(1.0, 20.0) = 5.0;
```

---

### Shader 6: Bioluminescence

**Archivo**: `environment/bioluminescence.gdshader`
**Tipo**: spatial

**Que hace**: Objetos que brillan con luz propia de forma pulsante (sine wave). El brillo sube y baja suavemente. Usado en hongos, corales, cristales organicos.

**Parametros**:
```glsl
uniform vec4 glow_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);  // Azul default
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.1, 3.0) = 0.8;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.3;  // Minimo brillo
```

**Logica**:
```glsl
void fragment() {
    float pulse = mix(pulse_min, 1.0, (sin(TIME * pulse_speed) * 0.5 + 0.5));
    ALBEDO = glow_color.rgb;
    EMISSION = glow_color.rgb * glow_intensity * pulse;
}
```

---

### Shader 7: Post-Process — Color Grading por Bioma

**Archivo**: `post_process/color_grading.gdshader`
**Tipo**: canvas_item (aplicado a ColorRect fullscreen)

**Que hace**: Ajusta los colores de TODA la pantalla para dar la identidad del bioma. Es como un filtro de Instagram pero reactivo.

**Este es el shader que mas cambia entre biomas.** Cada bioma tiene un preset de color grading:

| Bioma | Temperatura de color | Saturacion | Contraste | Tint |
|-------|---------------------|------------|-----------|------|
| Pradera | Calido (+0.1 naranja) | +10% | Normal | Dorado sutil |
| Bosque | Neutro-frio | Normal | -5% (niebla) | Verde sutil |
| Tundra | Frio (+0.15 azul) | -15% | +10% | Azul hielo |
| Volcan | Calido (+0.2 rojo) | +5% | +15% | Rojo/naranja |
| Catacumbas | Frio (+0.1 violeta) | -30% | +20% | Violeta tenue |
| Abismo | Frio (+0.2 azul oscuro) | -40% | +25% | Azul profundo |
| Dimension Astral | N/A — cambiante | Invertida | Extremo | Purpura/cian |

**Parametros**:
```glsl
uniform float temperature : hint_range(-1.0, 1.0) = 0.0;     // Frio ← → Calido
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.7;
```

---

### Shader 8: Kimetsu Combat Trails

**Archivo**: `core/combat_trail.gdshader`
**Tipo**: spatial
**Aplicado a**: MeshInstance3D generado por trail de habilidades

**Que hace**: Crea los trails de color brillante que dejan las habilidades al estilo de las respiraciones de Kimetsu. Cada clase tiene su color. El trail BRILLA contra fondos oscuros (emission alta) y es mas sutil contra fondos claros (emission baja adaptativa).

**Parametros**:
```glsl
uniform vec4 trail_color_primary : source_color;      // Color principal (clase)
uniform vec4 trail_color_secondary : source_color;     // Color secundario (clase)
uniform float trail_emission : hint_range(0.0, 10.0) = 5.0;
uniform float trail_lifetime : hint_range(0.1, 2.0) = 0.5;  // Segundos
uniform float trail_width : hint_range(0.01, 0.5) = 0.1;
uniform float trail_noise_scale : hint_range(1.0, 20.0) = 5.0;
uniform sampler2D trail_pattern;  // Textura del patron (olas para agua, llamas para fuego)
```

**Referencia directa**: las lineas de agua cuando Tanjiro ataca, las llamas de Rengoku, los rayos de Zenitsu. Eso EXACTAMENTE, pero en nuestro estilo low-poly.

**Implementacion del trail**:
```
Cada ataque genera un ImmediateMesh (o trail mesh) que:
1. Sigue la trayectoria del arma/mano del jugador
2. Aplica el shader con el color de la clase
3. Tiene UV scroll para que el patron se mueva
4. Fade out con alpha sobre el lifetime
5. Emission alta = brilla como neon en oscuridad
```

---

## 5. Sistema de Calidad Grafica

### Presets de calidad

El jugador elige en el menu de Opciones. Cada preset activa/desactiva shaders y ajusta parametros.

| Feature | Low | Medium | High | Ultra |
|---------|-----|--------|------|-------|
| Cell shading | 2 bandas | 3 bandas | 3 bandas + ramp | 4 bandas + ramp |
| Outlines | Solo jugador | Jugador + enemigos | + loot + props | + outline de color |
| Wind vegetation | Off | Vertex simple | Vertex + noise | + interaccion con jugador |
| Water | Color plano | + olas + normal map | + refraccion + foam | + reflejo SSR |
| Lava | Color + emission | + scroll UV doble | + distorsion calor | + particulas extra |
| Post-process | Off | Color grading only | + vignette + bloom | + DOF + motion blur |
| Fog | Distance fog basico | + color por bioma | + volumetric (fake) | + volumetric real |
| Shadows | 1 cascade, 512px | 2 cascades, 1024px | 3 cascades, 2048px | 4 cascades, 4096px |
| SSAO | Off | Off | Half-res | Full-res |
| Combat trails | Sin shader, particulas | + shader basico | + noise + pattern | + emission adaptativa |
| Bioluminescence | Color plano | + pulse | + area light fake | + area light real |
| LOD shader | Flat 50m+ | Flat 80m+ | Simplified 80m+ | Simplified 120m+ |

### FPS esperado por calidad

| Hardware | Low | Medium | High | Ultra |
|----------|-----|--------|------|-------|
| GTX 1060 / RX 580 | 60+ | 60 | 45-55 | 30-40 |
| RTX 2060 / RX 5700 | 60+ | 60+ | 60 | 50-60 |
| RTX 3070+ | 60+ | 60+ | 60+ | 60+ |

---

## 6. Referencia: Minecraft Shaders → Godot

### Lo que la gente ama de los shaders de Minecraft

Y como lo replicamos EN Godot, integrado:

| Efecto en Minecraft | Shader pack ejemplo | Equivalente en Dungeon Party | Archivo |
|---------------------|--------------------|-----------------------------|---------|
| Agua realista con olas | BSL, Complementary | `water_surface.gdshader` + wave vertex | environment/ |
| Cielo dinamico con nubes volumetricas | SEUS PTGI | `sky_cavern.gdshader` (no cielo abierto — estamos en torre, pero nubes dentro de cavernas grandes) | sky/ |
| Sombras suaves | Todos | Godot built-in soft shadows (ProjectSettings) | N/A |
| Bloom en luces brillantes | BSL, Complementary | Godot built-in Glow + per-material emission | WorldEnvironment |
| Color grading/tonemap | Complementary | `color_grading.gdshader` por bioma | post_process/ |
| Niebla volumetrica | SEUS | Godot built-in VolumetricFog + `FogVolume` nodes | WorldEnvironment |
| Reflejo en agua | BSL | Screen space reflection en quality HIGH+ | water_surface.gdshader |
| Waving plants | BSL, Complementary | `wind_grass.gdshader`, `wind_tree.gdshader` | vegetation/ |
| God rays (rayos de sol) | SEUS, BSL | Godot VolumetricFog + DirectionalLight3D | WorldEnvironment |
| Rain/snow particles | Complementary | GPUParticles3D por bioma + `rain.gdshader` | particulas nativas |
| Motion blur | SEUS | Godot built-in (Environment.motion_blur) | WorldEnvironment |
| Depth of field | BSL | Godot built-in (Camera3D.dof_blur) | Opcional, sutil |
| Ambient occlusion | Todos | Godot built-in SSAO (Environment.ssao) | WorldEnvironment |

### Lo que Godot hace MEJOR que Minecraft shaders

1. **Toon/Cell shading**: Minecraft shaders son para PBR realista. Nosotros queremos estilizado → la funcion `light()` custom de Godot es PERFECTA para esto. Minecraft no puede hacer cell shading facilmente.

2. **Emission per-material**: En Godot, cada material puede emitir luz propia sin trucos. La lava, los hongos, los cristales brillan NATIVAMENTE. En Minecraft necesitas light blocks.

3. **Custom render passes**: Godot permite multiples passes por material (outline como segundo pass). Minecraft shaders no tienen acceso a esto tan limpiamente.

4. **Shader LOD**: Podemos degradar shaders por distancia de forma nativa. Minecraft aplica shaders uniformemente.

### Lo que Minecraft shaders hacen MEJOR (y como compensamos)

1. **Path tracing (SEUS PTGI)**: Iluminacion global real en tiempo real. Godot no puede. **Compensacion**: pre-bake de lightmaps + LightmapGI para interiores + ambient light bien calibrada.

2. **PBR completo**: Minecraft shaders convierten bloques en superficies PBR detalladas. Nosotros NO queremos PBR → no es una desventaja, es una decision de estilo.

3. **Modding community**: Miles de personas optimizan shaders de Minecraft. **Compensacion**: nosotros optimizamos UNA VEZ para nuestro caso exacto, sin overhead de generalidad.

---

## Apendice: Checklist de Shader Review

Antes de mergear un shader al proyecto:

- [ ] Compila sin warnings en Godot 4.6
- [ ] Funciona en Forward+ renderer
- [ ] Tiene parametros `uniform` para todo valor tuneable (no magic numbers)
- [ ] Respeta el sistema de calidad (tiene versiones LOW/MED/HIGH o parametros que se ajustan)
- [ ] No usa mas de 4 `texture()` lookups en fragment (performance)
- [ ] No usa loops con iteraciones variables (performance)
- [ ] Incluye comentario en la primera linea: `// Dungeon Party — [nombre] shader v[version]`
- [ ] Tiene fallback razonable si una uniform no se setea (default values)
- [ ] Probado en bioma claro (Pradera) y bioma oscuro (Catacumbas) — se ve bien en ambos
