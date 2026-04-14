# game/assets/art/p1/ — Pradera Interior

Assets del **Piso 1 (Pradera)**. Organizados por categoría.

**Docs de referencia**:
- `game/docs/art/p1_pradera.md` — lista completa de assets + paleta + moodboard.
- `game/docs/art/p1_assets_sourcing.md` — de dónde sale cada asset (Kenney / Quaternius / AI / Blender).
- `game/docs/art_pipeline.md` — pipeline operativo general.
- `game/docs/visual_bible.md` §P1 — canon lighting + paleta.

---

## Estructura

```
p1/
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

**VFX / shaders** NO viven acá — están en `game/assets/shaders/` y particle scenes en `game/scenes/fx/` (ver `shader_system.md`).

---

## Convenciones de naming

- **Siempre** `snake_case`.
- Prefijo por categoría cuando ayuda a agrupar: `tree_oak_a`, `rock_small_b`, `slime_green`.
- Variantes con sufijo `_a`, `_b`, `_c` (no `_1`, `_2`).
- LODs con sufijo `_lod0`, `_lod1` (si alguna vez se usan; Tier I no usa LODs).
- Atlas compartidos: `atlas_prairie_props_1024.png`.
- Formatos:
  - Meshes: `.glb` (Godot-friendly, incluye animaciones y materiales).
  - Texturas: `.png` (sin compresión destructiva).
  - Audio: NO va acá (va en `game/assets/sounds/`).
- Escala: **1 unidad Godot = 1 metro**. Siempre verificar antes de exportar.
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

## Workflow de alta (resumen)

1. Buscar asset en Kenney / Quaternius / Poly Pizza (ver `p1_assets_sourcing.md`).
2. Si existe CC0 → descargar, abrir en Blender, ajustar (escala, pivot, material canon), export `.glb`.
3. Si no existe → AI gen (Meshy/Rodin/Tripo) con prompt low-poly, cleanup Blender obligatorio.
4. Último recurso → modelar en Blender from scratch.
5. Colocar en la subcarpeta correcta de `p1/`.
6. Import en Godot, verificar con lighting canon P1 (`visual_bible.md` §P1).
7. Commit: `art(p1): add <asset_id> <nombre>`.

---

## Qué NO va acá

- Archivos **raw** de AI gen o Blender source (`.blend`, `.glb` crudos sin limpiar) → `game/assets/art/_raw/` (agregar a `.gitignore`).
- Packs CC0 descargados enteros → `game/assets/art/_raw/kenney/`, `_raw/quaternius/`. Solo commitear los assets individuales que se usan, no el pack completo.
- Assets de otros pisos (P2-P5) → carpetas paralelas `p2/`, `p3/`, etc. cuando existan.
- Shaders y materiales reusables → `game/assets/shaders/`, `game/assets/materials/`.

---

## Licencias

Todos los packs CC0 (Kenney, Quaternius, Poly Pizza) permiten uso comercial sin atribución. Si agregás una fuente nueva, documentar en `game/assets/art/LICENSES.md` (crear si no existe).

---

## Estado actual

🟡 **Vacío**. Estructura creada 2026-04-13. Pendiente:
1. Descargar packs Kenney + Quaternius recomendados (`p1_assets_sourcing.md` §1).
2. Primer asset de prueba: `V05 tree_oak_a` import + screenshot con lighting canon.
3. Iteración hero asset `N07 giant_diamond`.
