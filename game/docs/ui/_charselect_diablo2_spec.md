# Character Select — Spec Rediseño D2-Style

> **Estado:** Propuesta revisable — pendiente validación del dev antes de implementar.
> Basada en: Diablo 2 (panel scrolleable con miniaturas), integrado con el `CharacterPreview` 3D existente.

---

## Problema actual

`CardContainer` es un `HBoxContainer` horizontal sin scroll. A partir de 4+ personajes las cards salen de pantalla a la derecha. No hay forma de ver todos los slots al mismo tiempo.

---

## Diseño objetivo

Layout dividido en **dos zonas horizontales**:

```
┌─────────────────────────────────────────────────────────────┐
│  "Selecciona tu Personaje"  (Título — Cinzel, dorado)        │
├───────────────────┬─────────────────────────────────────────┤
│  PANEL IZQUIERDO  │         PANEL DERECHO                   │
│  ScrollContainer  │         Preview grande 3D               │
│  ┌─────────────┐  │  [Nombre grande]                        │
│  │ Card 1 ▶   │  │  [Clase]  [Nv. X]  [Piso Y]            │
│  │ Card 2     │  │  [Equipo: slots con contenido]           │
│  │ Card 3     │  │                                          │
│  │  ...       │  │  [BtnJugar]  [BtnEliminar]               │
│  │ + Crear    │  │                                          │
│  └─────────────┘  │                                         │
└───────────────────┴─────────────────────────────────────────┘
│                  [BtnVolver]                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Estructura de nodos (.tscn)

```
CharacterSelect (Control, anchor full-rect)
├── Background (ColorRect, full-rect)
├── VBoxContainer (root layout, margin 40px todos lados)
│   ├── Title (Label — Cinzel, 40px, dorado)
│   ├── HSplitLayout (HBoxContainer, size_flags_vertical=EXPAND_FILL)
│   │   ├── LeftPanel (VBoxContainer, custom_minimum_size.x=280)
│   │   │   ├── ScrollContainer (size_flags_vertical=EXPAND_FILL)
│   │   │   │   └── CharacterList (VBoxContainer, size_flags_horizontal=EXPAND_FILL)
│   │   │   │       [cards pobladas en código — ver _refresh_characters()]
│   │   │   └── BtnCrear (Button, "＋ Nuevo Personaje", full-width)
│   │   └── RightPanel (VBoxContainer, size_flags_horizontal=EXPAND_FILL)
│   │       ├── PreviewContainer (Control, custom_minimum_size=Vector2(260,380))
│   │       │   └── BigPreview (CharacterPreview, custom_minimum_size=Vector2(260,380))
│   │       ├── CharInfoBox (VBoxContainer, visible=false por defecto)
│   │       │   ├── NameLabel (Label, 28px, Cinzel)
│   │       │   ├── ClassLevelRow (HBoxContainer)
│   │       │   │   ├── ClassLabel (Label, 16px, 70% alpha)
│   │       │   │   └── LevelLabel (Label, 16px, dorado)
│   │       │   ├── FloorLabel (Label, 14px, celeste)
│   │       │   └── EquipmentRow (HBoxContainer)
│   │       ├── ActionRow (HBoxContainer, alignment=CENTER)
│   │       │   ├── BtnJugar (Button, 300×60, disabled=true)
│   │       │   └── BtnEliminar (Button, 200×60, disabled=true)
│   │       └── EmptyHint (Label, "Seleccioná un personaje", visible=true, 50% alpha)
└── BtnVolver (Button, 200×50, align=CENTER)
```

---

## Mapeo de paths — lo que cambia en `character_select.gd`

| Path antiguo | Path nuevo |
|---|---|
| `$CenterContainer/VBoxContainer/CardContainer` | `$VBoxContainer/HSplitLayout/LeftPanel/ScrollContainer/CharacterList` |
| `$CenterContainer/VBoxContainer/ActionRow/BtnJugar` | `$VBoxContainer/HSplitLayout/RightPanel/ActionRow/BtnJugar` |
| `$CenterContainer/VBoxContainer/ActionRow/BtnEliminar` | `$VBoxContainer/HSplitLayout/RightPanel/ActionRow/BtnEliminar` |
| `$CenterContainer/VBoxContainer/BtnVolver` | `$VBoxContainer/BtnVolver` |

---

## Card de personaje (miniatura — panel izquierdo)

Cada card en `CharacterList` es un `PanelContainer` horizontal:

```
PanelContainer (custom_minimum_size = Vector2(260, 64), full-width)
└── HBoxContainer (margin 8px, separation 10)
    ├── ClassIcon (TextureRect, 40×40) ← ícono SVG/PNG de clase
    └── InfoVBox (VBoxContainer, size_flags_horizontal=EXPAND_FILL)
        ├── NameLabel (Label, 15px, bold)
        └── SubRow (HBoxContainer)
            ├── ClassLabel (Label, 12px, 70% alpha)
            ├── LevelLabel (Label, 12px, dorado, "Nv. X")
            └── FloorLabel (Label, 12px, celeste, "| Piso Y")
```

**Sin `CharacterPreview` en la miniatura** — demasiado costo de SubViewport × 6 corriendo en paralelo. Solo el panel derecho tiene el preview grande.

**Card seleccionada:** `modulate = Color(1.0, 0.85, 0.3, 1.0)` en el panel. No seleccionadas: `Color(1,1,1,1)`.

**Card "Crear nuevo":** misma altura (64px), ícono `+` a la izquierda, texto "Nuevo personaje" a la derecha. Sin cambio de lógica respecto al `_create_new_card()` actual.

---

## Íconos de clase

Ruta canónica:

```gdscript
const CLASS_ICONS: Dictionary = {
    "Guerrero": "res://assets/art/ui/icons/class_guerrero.png",
    "Mago":     "res://assets/art/ui/icons/class_mago.png",
    "Archer":   "res://assets/art/ui/icons/class_archer.png",
    "Cleric":   "res://assets/art/ui/icons/class_cleric.png",
    "Necromancer": "res://assets/art/ui/icons/class_necromancer.png",
    "Danzante": "res://assets/art/ui/icons/class_danzante.png",
}
```

Si la textura no carga: mostrar un `ColorRect` 40×40 con `CLASS_COLORS[class_key]` como fallback temporal.

> Verificar si los SVG de Mage/Danzante en `game/assets/art/ui/icons/` están en PNG exportado o solo SVG. Godot 4 importa SVG directo — ambos sirven.

---

## Preview grande (panel derecho)

`BigPreview` es un `CharacterPreview` **único** — no se crean múltiples instancias en paralelo. Al seleccionar una card:

```gdscript
func _select_card(index: int) -> void:
    selected_index = index
    var character: Dictionary = SaveManager.get_character(index)
    var class_color: Color = CLASS_COLORS.get(character.get("class_name", ""), Color.WHITE)
    $VBoxContainer/HSplitLayout/RightPanel/PreviewContainer/BigPreview.setup_character(class_color)
    _update_char_info(character)
    _update_buttons()
    _highlight_selected()
```

`setup_character(Color)` ya existe en `character_preview.gd` — **sin cambios** a ese archivo.

`auto_spin = true` siempre en el preview grande (ya es el default).

---

## `_update_char_info(character: Dictionary)` — función nueva

```gdscript
func _update_char_info(character: Dictionary) -> void:
    var info_box = $VBoxContainer/HSplitLayout/RightPanel/CharInfoBox
    var empty_hint = $VBoxContainer/HSplitLayout/RightPanel/EmptyHint
    empty_hint.visible = false
    info_box.visible = true
    info_box.get_node("NameLabel").text = character.get("name", "???")
    info_box.get_node("ClassLevelRow/ClassLabel").text = character.get("class_name", "")
    info_box.get_node("ClassLevelRow/LevelLabel").text = "Nv. %d" % character.get("level", 1)
    info_box.get_node("FloorLabel").text = "Piso más alto: %d" % character.get("highest_floor", 1)
    _update_equipment_row(character.get("equipment", {}))
```

---

## `_update_equipment_row(equipment: Dictionary)` — función nueva

`equipment` tiene la estructura que guarda `SaveManager`: `{ "weapon": {"item_id": "sword_rusty", ...}, "chest": {...}, ... }`.

Para alpha: mostrar slots con contenido como texto simple. Post-alpha: reemplazar `Label` por `TextureRect` con ícono del ítem.

```gdscript
func _update_equipment_row(equipment: Dictionary) -> void:
    var row: HBoxContainer = $VBoxContainer/HSplitLayout/RightPanel/CharInfoBox/EquipmentRow
    for child in row.get_children():
        child.queue_free()
    if equipment.is_empty():
        var lbl := Label.new()
        lbl.text = "Sin equipo"
        lbl.modulate = Color(1, 1, 1, 0.4)
        row.add_child(lbl)
        return
    for slot_key in ["weapon", "off_hand", "chest", "helmet", "ring_1", "amulet"]:
        var entry: Dictionary = equipment.get(slot_key, {})
        if entry.is_empty():
            continue
        var lbl := Label.new()
        lbl.text = "[%s]" % entry.get("item_id", "?")
        lbl.add_theme_font_size_override("font_size", 11)
        lbl.modulate = Color(0.9, 0.75, 0.3, 1.0)
        row.add_child(lbl)
```

---

## Estado vacío (sin personajes)

Si `SaveManager.get_character_count() == 0`, `CharacterList` solo muestra la card "Crear nuevo" y `RightPanel` muestra `EmptyHint` con texto "No tenés personajes aún. ¡Creá uno!".

---

## Scroll behavior

```
ScrollContainer:
  horizontal_scroll_mode = SCROLL_MODE_DISABLED
  vertical_scroll_mode   = SCROLL_MODE_AUTO
  follow_focus           = true   ← para navegación con teclado (futuro)
```

Con 6 cards de 64px + separación 8px el contenido ocupa ~432px — en 1080p cabe sin scroll. En resoluciones menores scrollea automáticamente. `follow_focus = true` asegura que la card seleccionada quede visible al navegar con teclado.

---

## Archivos a modificar

| Archivo | Cambio |
|---|---|
| `game/scenes/ui/character_select.tscn` | Reemplazar layout completo por la estructura nueva |
| `game/scenes/ui/character_select.gd` | Reemplazar `_create_character_card()` (card horizontal 64px), `_refresh_characters()` (poblar `CharacterList`), `_select_card()` (alimentar BigPreview + CharInfoBox). Agregar `_update_char_info()` + `_update_equipment_row()`. Actualizar paths de botones. |
| `game/scenes/ui/character_preview.gd` | **Sin cambios** — API `setup_character(color)` es suficiente |
| `game/scripts/save_manager.gd` | **Sin cambios** — `get_character(index)` ya devuelve `equipment`, `highest_floor`, `level`, `class_name`, `name` |

---

## Lo que NO cambia

- Lógica de confirmación doble en BtnJugar / BtnEliminar — igual que hoy.
- `GameManager.selected_class_scene` y `GameManager.selected_character_index` — sin tocar.
- `SaveManager` API — se consume igual que hoy.
- `CharacterPreview` — se reutiliza tal cual. Solo hay **una instancia** en vez de N.

---

## Extensiones post-alpha (no hacer ahora)

- Reemplazar `Label` de equipment por `TextureRect` con ícono real del ítem
- Backdrop del RightPanel cambia por clase seleccionada (D2 cambia por acto/progreso)
- Animación de idle/equip en el preview (actualmente solo gira)
- Navegación completa con teclado/gamepad

---

*Documento creado 2026-06-05. Propuesta — validar con dev antes de implementar.*
