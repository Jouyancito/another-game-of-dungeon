# game/assets/art/piso1_pradera/ — Pradera Interior

Assets del **Piso 1 (Pradera)**. Organizados por categoría.

**Docs de referencia**:
- `game/docs/art/p1_pradera.md` — lista completa de assets + paleta + moodboard.
- `game/docs/art/p1_assets_sourcing.md` — de dónde sale cada asset (Kenney / Quaternius / AI / Blender).
- `game/docs/art_pipeline.md` — pipeline operativo general.
- `game/docs/visual_bible.md` §P1 — canon lighting + paleta.
- Skill `kenney-quaternius-sourcer` — índice CC0 oficial + naming convention.

---

## Estructura

```
piso1_pradera/
├── terrain/       # Tiles suelo (grass, dirt, stone, rocky, sand, cliffs)
├── vegetation/    # Árboles, arbustos, hierba, flores, hongos, juncos
├── props/
│   ├── rocks/     # Rocas, troncos caídos, tocones
│   ├── ceiling/   # Diamante gigante + cristales del techo
│   ├── water/     # Cascadas, nenúfares mesh
│   ├── outpost/   # Empalizadas, torres, casas, chimeneas
│   ├── ruins/     # Columnas rotas, muros, escalones, pisos tallados
│   └── common/    # Barriles, cajas, cofres, fogatas, tiendas, antorchas
├── skybox/        # Dome techo caverna + montañas billboards
└── enemies/       # Meshes + animaciones de enemigos P1
    └── deco/      # Fauna decorativa no hostil (mariposas, conejos, etc.)
```

**Estructura paralela** para otros pisos: `piso2_bosque/`, `piso3_hielo/`, `piso4_tormenta/`, `piso5_dimension_rota/`, más `shared/` para assets reutilizables entre pisos.

**VFX / shaders** NO viven acá — están en `game/assets/shaders/` y particle scenes en `game/scenes/fx/` (ver `shader_system.md`).

---

## Convenciones de naming (skill `kenney-quaternius-sourcer` canon)

**Patrón oficial**: `{prefix}_{descripcion_snake_case}.glb`

| Prefix | Categoría | Ejemplo |
|--------|-----------|---------|
| `env_` | Environment (terrain, vegetation, skybox, decoración mapa) | `env_tree_oak_01.glb`, `env_grass_tuft_01.glb` |
| `prop_` | Objetos decorativos / interactuables | `prop_chest_wooden.glb`, `prop_barrel_01.glb` |
| `char_` | Personajes / NPCs | `char_warrior_base.glb`, `char_capitan_outpost.glb` |
| `enemy_` | Enemigos hostiles | `enemy_slime_green.glb`, `enemy_bandit_melee.glb` |
| `fx_` | Partículas / VFX (sprites, meshes de efectos) | `fx_god_rays_volumetric.tres` |

**Reglas adicionales**:
- **Siempre** `snake_case` (sin mayúsculas, sin guión medio).
- Variantes numeradas `_01`, `_02`, `_03` (skill canon — reemplaza `_a/_b/_c` que usé antes).
- LODs: `_lod0`, `_lod1` (Tier I no usa LODs).
- Atlas compartidos: `atlas_prairie_props_1024.png`.
- Formatos:
  - Meshes: **`.glb`** (glTF binario, Godot 4 carga nativo).
  - Texturas: `.png` sin compresión destructiva.
  - Audio: NO va acá (va en `game/assets/sounds/`).
- Escala: **1 unidad Godot = 1 metro**. Verificar antes de exportar.
- Pivot: en la **base** del objeto (contacto con el piso).

---

## Reglas Tier I (recordatorio)

- **Sin PBR**. Sin normal maps. Sin roughness/metallic maps.
- **Vertex color preferido**. Atlas 1024 si se necesita textura.
- **Poly budget** (ver `p1_pradera.md` §6):
  - Hero: 3k-8k tris.
  - Enemy estándar: 800-2500 tris.
  - Prop medio: 300-1500 tris.
  - Prop pequeño: 50-300 tris.
  - Tile terreno: <200 tris.
- **Paleta canon** (`p1_pradera.md` §3): verde pradera `#8FAE6B` dominante, dorado diamante `#F5D576` acento emisivo, azul-lavanda `#7A8FC4` fríos. Proporción 60/25/15 (cálidos/verdes/fríos).

---

## Workflow de alta (jerarquía decisión skill)

1. **PRIMERO** buscar en Kenney/Quaternius (ver `p1_assets_sourcing.md` y skill `kenney-quaternius-sourcer`). Gratis, CC0, estilo coherente.
2. Si existe CC0 → descargar, abrir en Blender, ajustar (escala, pivot, material canon), export `.glb`.
3. **SEGUNDO** si no existe en CC0 → AI gen (Meshy/Rodin/Tripo) con prompt low-poly. Solo para hero/únicos (bosses, NPCs signature, props signature). Cleanup Blender obligatorio.
4. **ÚLTIMO** Blender from scratch. Solo si Kenney/Quaternius no tienen + AI gen no da calidad + es pieza crítica gameplay.
5. Renombrar siguiendo convención `{prefix}_{descripcion}.glb`.
6. Colocar en subcarpeta correcta de `piso1_pradera/`.
7. Import en Godot, verificar con lighting canon P1 (`visual_bible.md` §P1).
8. Commit: `art(p1): add <prefix>_<nombre>`.

---

## Qué NO va acá

- Archivos **raw** de AI gen o Blender source (`.blend`, `.glb` crudos sin limpiar) → `game/assets/art/_raw/` (agregar a `.gitignore`).
- Packs CC0 descargados enteros → `game/assets/art/_raw/kenney/`, `_raw/quaternius/`. Solo commitear los assets individuales que se usan, no el pack completo.
- Assets de otros pisos → carpetas paralelas (`piso2_bosque/`, etc.) cuando existan.
- Assets reutilizables entre pisos → `game/assets/art/shared/`.
- Shaders y materiales reusables → `game/assets/shaders/`, `game/assets/materials/`.

---

## Licencias

Todos los packs CC0 (Kenney, Quaternius, Poly Pizza) permiten uso comercial sin atribución. Donar a Kenney/Quaternius si monetizás (recomendación skill). Si agregás una fuente nueva, documentar en `game/assets/art/LICENSES.md` (crear si no existe).

---

## Estado actual

🟡 **Vacío**. Estructura creada 2026-04-14. Pendiente:
1. Descargar packs Kenney + Quaternius recomendados (`p1_assets_sourcing.md` §1).
2. Primer asset de prueba: `env_tree_oak_01` import + screenshot con lighting canon.
3. Iteración hero asset `prop_giant_diamond` (Meshy/Rodin).
