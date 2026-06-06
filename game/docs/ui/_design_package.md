# Paquete de diseño UI/UX — Dungeon Party (alfa demo)
**Generado 2026-06-05 · Para revisión de Joan**
*Síntesis de research: HUD · Inventario/Skills · Personajes/Skins/Items*

> **Filtro de scope**: cada ítem tiene etiqueta `[ALFA-YA]` (existe), `[ALFA-NICE]` (implementar antes del video de 10 min) o `[POST-ALFA]` (no sale en el video → no tocar ahora).

---

## Sistema visual común

Tokens compartidos entre las 3 áreas. Todo lo que ves abajo usa este vocabulario — es lo que hace que sean UN diseño y no tres parches.

| Token | Valor | Uso |
|---|---|---|
| `bg_dungeon` | `Color(0.06, 0.05, 0.09, 0.97)` | Fondos de panel (inventory, character window) |
| `cell_dark` | `Color(0.08, 0.07, 0.10)` | Celdas de grid |
| `grid_line` | `Color(0.22, 0.20, 0.28, 0.8)` | Bordes de grilla, tinte púrpura D2 |
| `gold_border` | `Color(0.75, 0.60, 0.25, 1.0)` | Marcos dorados (acento principal) |
| `gold_fill` | `Color(0.9, 0.75, 0.1, 1)` | Fill XP, slot activo |
| `hp_red` | `Color(0.85, 0.1, 0.1, 1)` | Líquido orbe HP |
| `mp_blue` | `Color(0.15, 0.4, 0.95, 1)` | Líquido orbe MP |
| Tipografía | **Cinzel** | Números HUD, niveles, key labels, títulos |

**Color language** (el mismo en HUD + skills + items — consistencia antes que belleza):
- Rareza: common gris · rare azul · epic púrpura · legendary dorado
- Recurso: Rage rojo · MP azul · Combo dorado
- Clase: Warrior `#C84B11` naranja-carbón · Mage `#1A6FCC` azul eléctrico · Archer `#6DBD1A` verde lima

---

## 1. HUD (PRIORIDAD — lo primero que se ve en cada segundo del video)

### Decisión: globos D2, no barras ornamentadas

**Veredicto**: globos. Las razones concretas:
- D2 es ref canon explícita (`_art_canon.md §1.2`).
- Los globos liberan el centro-inferior para la hotbar sin pelear espacio horizontal.
- Orbe rojo/azul brillante sobre bioma apagado (Kimetsu canon §2.4) = contraste máximo, HUD memorable.
- Escalan a co-op 6 jugadores (mini-orbes en party frame) sin reescribir el layout.

**Caveat honesto**: el Foozle pack NO tiene sprites de orbe circular. Los globos requieren 3 PNGs nuevos — son el único costo real de asset del HUD alfa y son pequeños (~10 min en Aseprite o un pack CC0 de Kenney, ver sección assets).

### Mockup ASCII — 1920×1080 (viewport efectivo ~1020px alto en Windows maximizado)

```
+------------------------------------------------------------------+
|              [ TARGET FRAME — top center, ya OK ]                |
|                                                                   |
|                                                                   |
|                          ( + )  crosshair                        |
|                                                                   |
|                                                                   |
|  Lv.7                                                             |
|  .--.        [===== HOTBAR  8 slots + torch =====]         .--.  |
| /HP  \       [1][2][3][4][5][6][7][8][F]                  /MP  \ |
| \ 96 /       [====  XP BAR horizontal (12px)  ====]       \ 96 / |
|  '--'                                                       '--'  |
| 150/150                                                           |
+------------------------------------------------------------------+
```

**Medidas concretas:**
- Orbe HP: esquina inferior izquierda, 96×96px, centro `(x=80, y=960)`. Texto `150/150` Cinzel 12px centro-bajo. `Lv.7` Cinzel 11px encima del orbe.
- Orbe MP: esquina inferior derecha, 96×96px, centro `(x=1840, y=960)`.
- Hotbar: centrada, 8 slots 52×52px + separación 4px + torch slot ≈ 500px total, `offset_top = -80`.
- XP bar: horizontal 12px alto, debajo del hotbar, ~500px, misma ancla central.
- Target frame: top-center, `offset_top=16`, ya bien posicionado — no se toca.

### Implementación (cero riesgo de romper `hud.gd`)

Los globos van como `TextureProgressBar` (built-in Godot 4), NO shader custom:
- `texture_under` = `orb_frame.png` (marco circular dorado)
- `texture_progress` = `orb_mask_fill.png` (círculo blanco sólido, tintado por `modulate`)
- `fill_mode = FILL_BOTTOM_TO_TOP` (simula líquido subiendo/bajando)
- `radial_fill = false` (lineal vertical es suficiente para alfa)

`TextureProgressBar` extiende `Range` igual que `ProgressBar`. API idéntica (`.value`, `.max_value`). `_on_health_changed` / `_on_mana_changed` **no cambian su lógica** — solo cambia el tipo de nodo target. Los `@onready` (`health_bar`, `mana_bar`) siguen siendo compatibles sin tocar código de señales.

### Animaciones "juicy" (todo via Tween, sin libs externas)

| Animación | Implementación |
|---|---|
| HP baja | `Tween` fill 0.3s ease-out + flash `modulate` blanco 0.08s |
| MP baja | Ídem, color azul |
| HP sube (regen) | Fill 0.5s ease-in-out, sin flash |
| Level up | Conservar tween scale-up + label "NIVEL X" actual |
| Slot activo cambia | Scale 1.0→1.04→1.0 en 0.15s |
| HP <20% | `AnimationPlayer` pulsa glow rojo a 1.2 Hz (urgencia sin molestar) |

### Filtro de scope — HUD

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| Globos HP/MP via `TextureProgressBar` circular | ✅ | |
| Texto numérico Cinzel debajo de cada orbe + `Lv.X` | ✅ | |
| XP bar 12px con `Panel_1.png` NinePatch | ✅ | |
| Hotbar slots con `Panel_2.png` NinePatch por slot | ✅ | |
| Flash daño + fill tween + scale slot + pulse <20% HP | ✅ | |
| Ripple de líquido en superficie del orbe al daño | | ✅ |
| Burbujas MP al castear skill (GPUParticles2D) | | ✅ |
| Vignette roja borde pantalla en <15% HP | | ✅ |
| Icono de mob + barra tipo-daño en target frame | | ✅ |
| Party frame con mini-orbes por jugador (co-op) | | ✅ |
| Minimap esquina superior derecha | | ✅ |

### Assets a conseguir — HUD

| Asset | Fuente | Licencia | Tiempo estimado |
|---|---|---|---|
| `orb_frame_red.png` (128×128, marco circular dorado, interior transparente) | Kenney "Fantasy UI Borders" — tiene frames circulares | CC0 | 5 min (descargar + recortar) |
| `orb_frame_blue.png` | Mismo frame, tint via `modulate` en Godot — no hace falta archivo aparte | — | 0 min |
| `orb_mask_fill.png` (96×96, círculo blanco sólido) | Aseprite o GIMP: círculo blanco sobre fondo transparente | — | 2 min |
| `Panel_1.png` | **Ya en** `game/assets/art/_raw/foozle/foozle_rpg-ui-set-1.zip` | Comercial (ya adquirido) | Extraer a `game/assets/art/ui/foozle/` |
| `Panel_2.png` | Ídem | Comercial (ya adquirido) | Ídem |

---

## 2. Inventario / Skills UI

### A. Inventario — grid con theme Foozle

**Estado actual**: grid 12×7 dibujado con `draw_rect`, celdas grises monocromas, items como rectángulos de color por rareza sin iconos, background panel gris plano. El contraste con el theme oscuro/dorado es bajo.

**Mockup ASCII:**
```
 INVENTARIO  (marco gold_border 2px, fondo bg_dungeon, corner_radius 8)
+------------------------------------------+
| [S][ ][P][ ][ ][ ][H][ ][ ][ ][ ][ ]    |   celda: cell_dark
| [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]    |   grilla: grid_line
| [ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ][ ]    |
| ...  (12×7 celdas)                       |
+------------------------------------------+
             ___________________
            | ▍ Espada Rota     |  <- tooltip: franja rareza 3px borde-izq
            |   Common          |
            |   +2 STR          |
             -------------------
```

Items sin icono: en vez de mancha de color, letra inicial centrada 20px bold sobre fondo de rareza (Sword → "S", Helmet → "H", Potion → "P" — distinguibles sin assets). Tooltip con `StyleBoxFlat.border_width_left = 3`, `border_color = rarity_color` (efecto D2/PoE inmediato).

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| Celdas `cell_dark` + grilla `grid_line` púrpura | ✅ | |
| Letra inicial en items sin icono, 20px sobre rareza | ✅ | |
| Tooltip: franja rareza 3px izquierda | ✅ | |
| Panel inventory marco `gold_border` 2px, corner 8 | ✅ | |
| `TextureRect` por item en el grid (iconos reales) | | ✅ |

### B. Pestaña Skills — miniaturas con contexto visual

**Estado actual**: filas `PanelContainer` 88px, `TextureRect` 64×64, `PlaceholderTexture2D` gris cuando `icon == null`, nivel placeholder mentiroso "1/max".

**Mockup ASCII:**
```
 HABILIDADES
+--------------------------------------------------+
|▍[WC] War Cry            En hotbar                |  ← borde izq = cast_type
|      Grito de guerra...                          |    INSTANT  dorado
|      +15% daño · 8s                              |    CHANNELED azul
+--------------------------------------------------+    TOGGLE   verde
|▍[CH] Charge             Disponible               |    PASSIVE  púrpura
|      ...                                         |  icono fallback:
+--------------------------------------------------+    ColorRect color-clase
|▍[ ] Sharp Eye           Bloqueada Lv 5           |    + letra display_name[0]
+--------------------------------------------------+
```

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| Fallback icono: `ColorRect` color-de-clase + letra 22px | ✅ | |
| Borde izquierdo 4px por `cast_type` (dorado/azul/verde/púrpura) | ✅ | |
| Estado real: `En hotbar` / `Disponible` / `Bloqueada Lv X` | ✅ | |
| Entry 88→72px, icono 64→48px (más densidad) | ✅ | |
| **SVGs Archer ×4** (blocker para consistencia visual) | ✅ **BLOCKER** | |
| Tooltip expandido al hover (daño escalado al nivel actual) | | ✅ |
| Barra progreso nivel skill (0/max) | | ✅ |
| SVGs Cleric ×4 + Necromancer ×4 | | ✅ |

### C. Hotbar — legibilidad de skills sin ícono

**Problema**: slot con skill pero `icon == null` se ve vacío — el jugador no sabe si hay algo asignado.

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| `skill != null && icon == null` → nombre abreviado 4 chars (ej. "WCry") | ✅ | |
| Borde slot 1–2px por `resource_type` (Rage rojo · MP azul · Combo dorado) | ✅ | |
| Animación pulse dorado 0.3s cuando cooldown llega a 0 | | ✅ |
| Número de stacks de recurso encima del slot (Rage/Combo actuales) | | ✅ |

### Assets a conseguir — Inventario/Skills

| Asset | Fuente | Licencia |
|---|---|---|
| `sharp_eye.svg` (Archer PASSIVE — ojo con brillo toon, 64×64 transp, verde/dorado) | IA (Recraft/Midjourney) o Inkscape manual | — |
| `rapid_fire.svg` (Archer CHANNELED — 3 flechas en ráfaga paralelas) | Ídem | — |
| `aimed_shot.svg` (Archer CHARGED — flecha única con aura de carga) | Ídem | — |
| `scatter_shot.svg` (Archer INSTANT CONE — abanico 5 flechas, ref Huntress PoE) | Ídem | — |
| Ruta: `game/assets/ui/icons/skills/archer/` | Misma estructura que las otras clases | — |

---

## 3. Siluetas de las 3 clases (geometría procedural)

### Realidad técnica base

`WorldModel` + `MannequinBuilder` construyen el cuerpo con primitivas Godot (Box/Cylinder/Sphere). **No hay Skeleton3D ni rig.** Las 3 clases comparten la misma geometría hoy — la única diferencia es el color del material. El art canon exige **silueta legible a 20m por FORMA, no por color**, así que la diferenciación tiene que estar en la geometría del `WorldModel`.

Buena noticia: la jerarquía `right_shoulder → ElbowPivot → Hand` (Node3D) ya sigue la animación Tween igual que un bone. Cualquier `MeshInstance3D` hijo de `Hand` se mueve con el brazo → tenemos attachment points funcionales sin rig.

### Mockup de siluetas (procedural, CERO assets externos)

```
   WARRIOR          MAGE            ARCHER
    ___            __^__            ___
   |###|          ( cap )         |   |
  [#####]==        |   |          | o-+--   <- arco horiz (left_hand)
   |   |  hombrera |   | bastón   |   |
   |   |           |   | vert     |   |
  _|   |_          _|  |_         _|  |_
 ancho + bajo    alto + est.    medio + din.
 #C84B11          #1A6FCC        #6DBD1A
```

| Clase | Parámetros geometría | Prop asimétrico | Color canónico |
|---|---|---|---|
| **Warrior** | Torso width 0.30→**0.38**, cápsula radius 0.38 / height 1.75 | `BoxMesh` hombreras en `right_shoulder` | `#C84B11` naranja-carbón |
| **Mage** | Torso width **0.22** (estrecho), cápsula height **1.85** | `BoxMesh` capucha sobre `head_mesh` + `CylinderMesh` bastón (0.03r × 1.1h) hijo de `right_elbow/Hand` | `#1A6FCC` azul eléctrico |
| **Archer** | Torso width **0.26** (intermedio) | `BoxMesh` arco delgado hijo de `left_elbow/Hand` — toggle visible según estado de combate | `#6DBD1A` verde lima |

**Implementación**: parámetro `class_id: String` en `WorldModel.setup()` → método `_apply_class_shape(class_id)` que (1) escala el torso según clase, (2) agrega el prop asimétrico al attachment point correcto, (3) setea el material con el color canónico. Sin Skeleton3D, sin Blender, sin assets externos.

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| `class_id` + `_apply_class_shape()` en `WorldModel.setup()` | ✅ | |
| Props asimétricos: hombrera Warrior / capucha+bastón Mage / arco Archer | ✅ | |
| Migración `WorldModel` a Skeleton3D (8 bones) | | ✅ |
| `BoneAttachment3D` nativo reemplaza `WeaponAttach` Node3D | | ✅ |
| Animaciones idle distintas por clase | | ✅ |

---

## 4. Items equipados visibles en el modelo (estilo D2, sin rig)

### Honestidad técnica

D2 usa sprites 2D pre-renderizados por clase × tipo de armadura — no es generativo. En Godot con rig real sería `BoneAttachment3D` trivial. **El problema es que el WorldModel no tiene Skeleton3D.** Solución pragmática: explotar los attachment points que ya existen.

### Armas en mano (viable alfa sin rig)

`Node3D WeaponAttach` hijo de `ElbowPivot/Hand` en ambos brazos del `WorldModel` y del `ViewModel`. Al equipar main/off_hand → instanciar mesh como hijo; al desequipar → `free()`. La animación de ataque (Tween sobre `right_shoulder`) arrastra toda la jerarquía → el arma se mueve con el golpe sin código extra.

Armas procedurales alfa (todas con primitivas existentes en `MannequinBuilder`):
- Espada → `BoxMesh(0.06, 0.6, 0.04)`
- Escudo → `BoxMesh(0.3, 0.35, 0.04)`
- Bastón → `CylinderMesh(r=0.03, h=1.1)`
- Arco → `BoxMesh(0.04, 0.7, 0.04)`

### Armadura sin deformación (chest/legs/helmet, alfa)

Sin skin weights, la única opción es **color tint + overlay prop** — exactamente lo que hace D2 con sprites fijos por clase:
- Helmet → `BoxMesh` sobre `head_mesh`, forma varía por `item_type` (yelmo cerrado / abierto / capucha).
- Chest / legs / pies → albedo del material toon por rareza. Common gris · Rare azul · Epic púrpura · Legendary dorado. Comunica el upgrade visual, es barato, es legible.

**No viable sin rig** (→ post-alfa): armaduras con deformación, capas con física, boots/gloves que se adapten a la forma.

**Tranquilidad arquitectónica**: `WeaponAttach` Node3D tiene **la misma API pública** que un `BoneAttachment3D`. Cuando migremos al rig, `EquipmentPanel` y `Equipment` no cambian. El procedural entrega ~80% del impacto visual con ~10% del costo y no bloquea la migración futura.

| Cambio | [ALFA-NICE] | [POST-ALFA] |
|---|:---:|:---:|
| `WeaponAttach` en `WorldModel` + `ViewModel` | ✅ | |
| Armas procedurales 4 tipos (espada/escudo/bastón/arco) | ✅ | |
| Helmet `BoxMesh` overlay por `item_type` | ✅ | |
| Tint de armadura chest/legs por rareza del item | ✅ | |
| Migración Skeleton3D + armaduras deformables | | ✅ |
| `cosmetic_slots` + sistema transmog | | ✅ |
| Skin selector UI en character window | | ✅ |
| Cape/cloak con física (SoftBody3D) | | ✅ |

### Assets a conseguir — Personajes/Items

| Necesidad | Fuente | Cuando |
|---|---|---|
| **Alfa**: nada | Todo procedural con primitivas existentes | Ya |
| Post-alfa CC0 personajes | Quaternius Animated Characters (Skeleton3D compatible Godot 4) o Kenney Character Pack (fácil de tintear con toon shader) | Post-alfa |
| Post-alfa CC0 armas | Kenney Weapon Pack (.glb listos, ~200-400 tris/arma) | Post-alfa |
| Post-alfa custom | Meshy.ai free tier (.glb export) para piezas únicas que ningún CC0 calce con el art canon | Post-alfa |

---

## 5. Orden recomendado de implementación

El HUD es lo que más se ve en cada segundo del video de 10 min. Orden propuesto:

**Sprint 1 — HUD (mayor impacto/segundo, bajo riesgo)**
1. Generar/conseguir los 3 PNGs de orbe (único asset bloqueante del HUD — Kenney CC0 o Aseprite).
2. Swap `ProgressBar` → `TextureProgressBar` para HP/MP (cero cambio de lógica en `hud.gd`).
3. Reposicionar orbes a las esquinas, texto Cinzel, XP bar + slots NinePatch con Foozle (el zip ya está).
4. Tweens: flash daño, fill suave, scale slot activo, pulse <20% HP.

**Sprint 2 — Skills UI + blocker Archer (en paralelo si hay segunda mano)**
5. Arrancar YA los 4 SVGs de Archer — son lead time de asset, dispararlo en paralelo al Sprint 1.
6. Fallbacks de color + bordes por cast_type/recurso + densidad de entries. Todo código, cero assets.

**Sprint 3 — Siluetas + armas visibles**
7. `class_id` + `_apply_class_shape()` + props asimétricos → las 3 clases legibles a 20m.
8. `WeaponAttach` + armas procedurales → arma equipada visible en FP y en el modelo 3rd person.

---

*Este doc cubre forma, color funcional y layout. No hay lore inventado — identidad cultural de clases queda abierta para Joan.*
