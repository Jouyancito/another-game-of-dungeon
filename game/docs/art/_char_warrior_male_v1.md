# char_warrior_male — v1 (2026-08-13)

Estado de cierre del guerrero masculino. Este doc existe para que la próxima
sesión **no vuelva a decidir nada de esto** ni repita los errores que costó.

Sesión completa en engram bajo `another-game-of-dungeon`, doce observaciones.
Página de revisión: https://claude.ai/code/artifact/5fc10764-a8b5-4192-9123-109e0d81d11d

---

## 1. Qué es v1

Un cuerpo humano anatómico paramétrico, pintado por zonas, con pelo de placas,
bajo la iluminación y el shader del juego. **No tiene textura, ni equipo, ni
esqueleto.**

| Archivo | Qué es |
|---|---|
| `game/assets/art/characters/char_warrior_male_mh.blend` | el cuerpo, 13.380 verts evaluados |
| `game/assets/art/characters/char_warrior_male_hair.blend` | cuerpo + pelo, 38 placas |
| `game/assets/art/characters/char_warrior_male_blockout.blend` | el blockout de primitivas, **conservado como objetivo de medición** |

## 2. Herramientas nuevas

| Script | Para qué |
|---|---|
| `game/tools/blender/gen_char_warrior_male_mh.py` | genera el cuerpo desde MPFB, resuelve altura, audita contra el canon |
| `game/tools/blender/paint_char_zones.py` | pinta zonas por grupo de vértices, `--look flat\|dramatic` |
| `game/tools/blender/preview_char_toon.py` | réplica en nodos de `toon_basic.gdshader` |
| `game/tools/blender/gen_char_hair_plates.py` | pelo por placas conformadas al cráneo |
| `game/tools/blender/skin_tone_strip.py` | compara N tonos de piel bajo el shader del juego |
| `game/tools/visual_gate/measure_ref_body.py` | TARGET_SPEC numérico desde una imagen de referencia |
| `game/tools/refs/split_recording.py` | separa una grabación de pantalla en sus videos |

## 3. Parámetros que quedaron fijados

```
MPFB macros    gender 1.0 · age 0.58 · muscle 0.86 · weight 0.62 · proportions 0.42
piel           #A8724E   (opciones renderizadas en _review_skin_tones/)
pelo           #241A14 · 38 placas · ROOT_W 0.036 · BACK_BIAS 1.35
shadow_tint    (0.58, 0.60, 0.86) violeta frío
iluminación    DOS luces: key cálido en ángulo + contraluz frío detrás
```

**Medido contra el canon `_char_build_brief.md` §5:**

```
altura 1.800 m  (objetivo 1.80)          exacto
pies en z = 0                            exacto
7.50 cabezas    (canon 7.50)             exacto
hombro 0.603 m  (objetivo 0.598)         +5 mm
luz brazo-torso 0.308 m                  riggeable
```

El hombro **no se forzó**: salió del dial de músculo en 0.86 y cayó a 5 mm del
número que el brief ya tenía. Dos caminos independientes dando el mismo valor.

## 4. Cambio al shader compartido

`game/assets/art/shaders/toon_basic.gdshader` tiene un uniform nuevo:

```glsl
uniform vec4 shadow_tint : source_color = vec4(1.0);
vec3 tinted = mix(shadow_tint.rgb, vec3(1.0), shade);
DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * shade * tinted;
```

**Retrocompatible**: en blanco reproduce el comportamiento anterior, así que
ningún material existente cambió. Sin él la sombra es el mismo matiz más
oscuro y la piel cálida queda marrón barro.

## 5. Lo que NO está hecho

- **Textura.** `use_albedo_texture` sigue en `false`. Sin arrugas, cicatrices,
  vello ni poros. Es el hueco más grande y el brief §2.2 ya exige el stack
  albedo + normal + roughness.
- **La nuca del peinado no está juzgada.** No hay toma de atrás.
- **Cejas.** Único rasgo facial sin grupo de vértices ni geometría propia.
- **Esqueleto.** Rigify está instalado; el brief manda uno solo compartido.
- **Equipo.** Y ahí vive el peso visual — ver §6.
- Dos defectos de pelo vistos de frente: una placa suelta sobre la sien
  izquierda, un par de puntas al costado.

## 6. Reglas ganadas — leer antes de tocar el próximo personaje

1. **Una vista filtrada no es un inventario.** Afirmé que la malla no tenía
   grupos para uñas ni ojos basándome en un regex sobre los nombres. Tenía
   `fingernails`, `toenails`, `scalp`, y los ojos completos apagados por un
   modificador MASK. Leer los 152 grupos, no filtrarlos.

2. **Arreglar la ceguera de shape keys en un camino no la arregla en los
   otros.** Los macros de MPFB son shape keys: `obj.data.vertices` devuelve la
   malla sin morfear. El ojo está a z=1.545 en la base y a **1.686** en el
   cuerpo real. Buscar TODAS las lecturas de `obj.data.vertices`.

3. **Agregar luces APLANA.** `toon_basic.gdshader` acumula `DIFFUSE_LIGHT +=`
   por luz, así que cada lámpara suma otro juego de bandas y las lava. Cuatro
   luces salieron más planas que una. Dos es el número.

4. **Crecer no es peinar.** El pelo crece radial desde el remolino, pero
   después se peina hacia atrás. Modelar sólo el crecimiento tapa la cara.

5. **La masa "maciza" viene del equipo, no del cuerpo.** Medido: los brazos
   del Bárbaro D2R están a la par de los del blockout, y sus piernas son 25%
   MÁS FINAS. Lo que engorda su silueta son las botas y el faldón. Si se infla
   el cuerpo hasta sentirse macizo desnudo, con equipo queda un tanque.

6. **No mover un umbral hasta que el asset pase.** El gate de cintura/pecho
   usaba 0.84 inventado por mí. Se cambió a reportar sin veredicto, marcado
   SIN CALIBRAR, en vez de ajustarlo para aprobar.

7. **Publicar no es lo mismo que mirar.** Yo miro un render para poder emitir
   veredicto con evidencia; Joan necesita que esté publicado para verlo. Son
   dos pasos y ninguno reemplaza al otro.

## 7. Referencias cargadas esta sesión

Siete, en `game/docs/art/_references/`, cada una con `_synthesis.md`:
`hair_polygon_shells` · `ui_anim_jinx` · `skull_handdrawn` ·
`combat_aura_silhouette` · `metal_weld_joints` · `pixelart_painterly_mmo` ·
`fake_interior_parallax`

⚠️ **`capturar.ps1` conserva sólo las últimas 3 sesiones de grabación.** Tres
referencias se perdieron y sobrevivieron sólo por hojas de contacto ya
generadas. **Copiar al repo apenas se graba.**

## 8. Siguiente paso natural

La textura. Es el hueco grande, es lo que Joan describió como *"parecía indio
descrito por Walt Disney"*, y ninguna cantidad de luz lo compensa.
