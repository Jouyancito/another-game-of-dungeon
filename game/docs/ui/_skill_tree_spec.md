# Skill Tree UI — Design Spec

**Versión**: 1.0
**Fecha**: 2026-04-18
**Estado**: Canon design spec. Handoff a gameplay (B) + art (D) + QA para implementación.
**Depende de canon**:
- `game/docs/skills/_system.md` v1.0 (skill points, gating, cap 15, ramas lvl 25, evolución lvl 50)
- `game/docs/skills/{clase}.md` v2.0 (pool concreto fase prototipo)
- `game/docs/skills/_synergies.md`
- `game/docs/balance_v2.md` (curvas, 1 skill point/lvl char)
- `game/scenes/hud/hud.tscn` (hotbar 8 slots actual — target drop)
- `game/shared/skills/skill_resource.gd` (schema de las `.tres`)

**Scope**: definir qué muestra el Skill Tree UI, cómo interactúa con SaveManager y hotbar, cómo se gatea la ascendencia. NO implementa GDScript — solo contrato + mockup.

---

## 0. Problema y objetivos

### Problema
Hoy el prototipo tiene:
- Skills gastables desde hotbar 1-8 (ok)
- Sistema de skill points canon definido en `_system.md` v1.0 (ok)
- PERO no hay UI para que el jugador lea descripción de skill, vea CD/costos, asigne puntos, arrastre al hotbar
- Ascendencia lvl 25 definida en canon pero sin entry point UI
- User playtest: "no veo qué hace cada skill, no puedo subirlas, no puedo elegir qué llevo al hotbar"

### Objetivos del UI
1. **Leer**: el jugador debe poder leer descripción, CD, costo, efectos por nivel de cualquier skill de su clase
2. **Asignar**: gastar skill points disponibles (1/nivel char) en skills respetando cap 15
3. **Desasignar**: respec con costo (canon: oro + 6 resets max → "The Lost")
4. **Agrupar**: mostrar las skills en secciones lógicas (generales → ramas → ascendencia)
5. **Gate visual**: locked state para skills no desbloqueadas (char lvl, rama no elegida, quest incompleta)
6. **Equipar**: drag&drop desde el panel hacia los 8 slots del hotbar existente

### No-goals (fase prototipo)
- Loadouts Metin2 (4 sets) — diferido a fase Alpha según `_system.md §6`
- Evolución UI (lvl 15 + char 50 + ítem) — diferido a fase Beta
- Configuración de keybinds por skill — ya existe en input map global

---

## 1. Layout general (3 secciones + ascendencia)

El panel se abre con tecla **`K`** (canon `_system.md §4.1` "grimorio"). Tamaño: modal centered, 1280×720 sobre el HUD (el HUD sigue visible detrás, tinteado).

### Jerarquía de secciones (arriba → abajo)

```
┌──────────────────────── PANEL SKILL TREE ────────────────────────┐
│  [Clase: WARRIOR]  [Char lvl 18]  [Skill pts disponibles: 3]    │
│  [Rama activa: — ]  [Resets usados: 0/6]  [Respec: ❌ lvl 25+]  │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ▼ SECCIÓN 1 — GENERALES                (4 skills, desde lvl 1)  │
│                                                                   │
│    Grupo visual "Combate Directo"                                │
│      [Puño de Guerra lvl 3/15] [Embestida lvl 2/15]              │
│                                                                   │
│    Grupo visual "Control de Campo"                               │
│      [Grito de Guerra lvl 0/15] [Bloqueo Perfecto lvl 1/15]      │
│                                                                   │
│  ═══════════════════════════════════════════════════════════════  │
│                                                                   │
│  ▼ SECCIÓN 2 — ASCENDENCIA  (lvl 25+ required — 🔒 si lvl < 25) │
│                                                                   │
│    ╔═══ RAMA A ═══╗                 ╔═══ RAMA B ═══╗             │
│    ║   TANK       ║                 ║   BERSERKER  ║             │
│    ║  🔒 lvl 25   ║                 ║  🔒 lvl 25   ║             │
│    ║              ║                 ║              ║             │
│    ║ [T1] [T2] [T3 quest] ║         ║ [B1] [B2] [B3 quest] ║     │
│    ╚══════════════╝                 ╚══════════════╝             │
│                                                                   │
├──────────────────────────────────────────────────────────────────┤
│  HOTBAR (referencia visible, drag target):                       │
│  [1 Puño][2 Emb][3][4][5][6][7][8]                               │
└──────────────────────────────────────────────────────────────────┘
```

### Secciones canon

| Sección | Qué muestra | Gate desbloqueo | Ramas en fase prototipo |
|---------|-------------|-----------------|-------------------------|
| **Generales** | Las 4 skills core (`_system.md §2` gating lvl 1, 4, 8, 12) | Char lvl correspondiente por skill | N/A (todas los jugadores de la clase acceden) |
| **Ascendencia Rama A** | Skills exclusivas rama A (`warrior.md §4` / `mage.md §4`) | Char lvl 25 + rama A elegida | Warrior: Tank · Mage: Elementalista · Archer: Ranger · Cleric: Sanador (*3 ramas excepción*) · Necro: Maldiciones · Danzante: Sombra |
| **Ascendencia Rama B** | Skills exclusivas rama B | Char lvl 25 + rama B elegida | Warrior: Berserker · Mage: Arcano · Archer: Artillero · Cleric: Buffer · Necro: Creador · Danzante: Trickster |
| **(Cleric sólo) Rama C** | Skills Exorcista | Char lvl 25 + rama C elegida | Excepción canon `_system.md §1` — Cleric 3 ramas |

### Aclaración sobre "grupos visuales" dentro de Generales

El user pidió que las generales Warrior se agrupen en algo tipo "Corporal / Mental". Canon `_system.md` **no define sub-grupos dentro de generales** — son 4 skills planas. Propuesta del UI:

**Grupos visuales son puramente de presentación** (agrupan íconos en el panel para legibilidad), NO cambian gating ni reglas del sistema. El canon sigue siendo "4 skills generales". Si el usuario quiere renombrar los grupos, editamos solo el string del header.

Propuesta por clase (dept Design, 2026-04-18):

| Clase | Grupo visual A | Grupo visual B |
|-------|----------------|----------------|
| **Warrior** | **Combate Directo**: Puño de Guerra, Embestida | **Control de Campo**: Grito de Guerra, Bloqueo Perfecto |
| **Mage** | **Proyección Arcana**: Bolita Inestable, Supernova | **Control Arcano**: Tormenta Arcana, Barrera Prismática |
| **Archer** | **Disparo**: (2 skills de proyectil precisión) | **Soporte de tiro**: (2 utility) |
| **Cleric** | **Luz Restauradora**: (heals) | **Juicio**: (buff/ofensivas) |
| **Necromancer** | **Invocación**: (skills que cuestan HP) | **Maldición**: (debuffs MP) |
| **Danzante** | **Sombra**: (stealth / combo) | **Movimiento**: (evasivas) |

> **Nota para gameplay**: los strings de grupo viven en un diccionario por clase en la UI, fácil de tunear sin tocar `.tres`. Idealmente leídos de `.tres` metadata campo `general_group` (agregar al schema si hace falta — ver §9).

---

## 2. Wireframe ASCII (layout del panel, zoom)

```
╔═════════════════════════════════════════════════════════════════════════════╗
║  ⚔ WARRIOR                                              Char lvl 18        ║
║  ─────────                                              Skill pts: 3       ║
║  Rama activa: —       Resets: 0/6     [Elegir rama] (🔒 lvl 25+)          ║
╠═════════════════════════════════════════════════════════════════════════════╣
║                                                                             ║
║  ▼ GENERALES                                                                ║
║                                                                             ║
║  ┌─ Combate Directo ──────────────────────────────────────────────────┐    ║
║  │  ┌────────────┐      ┌────────────┐                                │    ║
║  │  │ [ICON]     │──────│ [ICON]     │                                │    ║
║  │  │ Puño Guerra│      │ Embestida  │                                │    ║
║  │  │ 3/15   [+] │      │ 2/15   [+] │                                │    ║
║  │  └────────────┘      └────────────┘                                │    ║
║  │      ↓ (prerreq visual, línea)                                     │    ║
║  └────────────────────────────────────────────────────────────────────┘    ║
║                                                                             ║
║  ┌─ Control de Campo ─────────────────────────────────────────────────┐    ║
║  │  ┌────────────┐      ┌────────────┐                                │    ║
║  │  │ [ICON]     │      │ [ICON]     │                                │    ║
║  │  │ Grito Guer │      │ Bloqueo Per│                                │    ║
║  │  │ 0/15   [+] │      │ 1/15   [+] │                                │    ║
║  │  └────────────┘      └────────────┘                                │    ║
║  └────────────────────────────────────────────────────────────────────┘    ║
║                                                                             ║
║  ════════════════════════════════════════════════════════════════════════    ║
║                                                                             ║
║  ▼ ASCENDENCIA   🔒 Requiere lvl 25 (actual 18)                            ║
║                                                                             ║
║  ┌─ TANK ─────────────────────┐   ┌─ BERSERKER ────────────────────┐      ║
║  │ 🔒 Postura de Muralla      │   │ 🔒 Giro de Espada              │      ║
║  │ 🔒 Escudo Vengador         │   │ 🔒 Forma del Titán (ULT)       │      ║
║  │ 🔒 Último Bastión [quest]  │   │ 🔒 Sangre que Llama [quest]    │      ║
║  └────────────────────────────┘   └────────────────────────────────┘      ║
║                                                                             ║
╠═════════════════════════════════════════════════════════════════════════════╣
║  [1 Puño][2 Emb][3 ⋯ ][4 ⋯ ][5 ⋯ ][6 ⋯ ][7 ⋯ ][8 ⋯ ]   ← drop target     ║
║                                                                             ║
║  [ Cerrar (Esc / K) ]                          [ Respec (🔒 rama no elegida)]║
╚═════════════════════════════════════════════════════════════════════════════╝
```

### Líneas de prerrequisito
Dentro de un grupo visual, si una skill requiere otra (no en fase prototipo, pero preparado para Alpha), se dibuja una línea vertical entre los íconos. En fase prototipo ninguna skill canon requiere otra → líneas solo visuales para estructura.

---

## 3. Per-skill panel (hover / click)

Cuando el jugador hace **hover** sobre un ícono de skill aparece el **tooltip detallado**. Cuando hace **click izquierdo** se fija ese panel abierto al lado del árbol hasta click fuera.

### Estructura del panel individual

```
╔════════════════════════════════════════════════════╗
║  [ICON 64×64]   Puño de Guerra                     ║
║                 lvl 3 / 15                         ║
╠════════════════════════════════════════════════════╣
║  Tags: [physical][melee][single][strike]           ║
║                                                    ║
║  Ataque básico de puño. Identidad "el primer       ║
║  golpe que todos reciben en la cara".              ║
║                                                    ║
║  ─ Coste ─                                         ║
║    MP: 0                                           ║
║    Rage gen: +5 por hit                            ║
║                                                    ║
║  ─ Cooldown ─                                      ║
║    Animación (0.5s)                                ║
║                                                    ║
║  ─ Rango ─                                         ║
║    MELEE_SHORT (2m, cono 60°)                      ║
║                                                    ║
║  ─ Fórmula actual (lvl 3) ─                        ║
║    physical_v2(15, weapon_dmg, STR, 3, 1.5)        ║
║    Poder: 100% × (1 + (3-1) × 0.08) = 116%         ║
║                                                    ║
║  ─ Efectos por nivel ─                             ║
║    ✓ lvl 1: base                                   ║
║    ✓ lvl 5: crit chance +10%       (faltan 2)      ║
║    · lvl 10: knockback 2m en hit                   ║
║    · lvl 15: aplica Bleed 5s en crit [cap]         ║
║                                                    ║
║  ─ Evolución (lvl 15 + char 50 + ítem) ─           ║
║    🔒 Puño del Titán (requiere Gauntlet del Titán) ║
║                                                    ║
╠════════════════════════════════════════════════════╣
║  Skill pts disponibles: 3                          ║
║                                                    ║
║    [  −  ]   3 / 15   [  +  ]                      ║
║                                                    ║
║  [ Arrastrar al hotbar ⇵ ]                         ║
╚════════════════════════════════════════════════════╝
```

### Datos que vienen de cada fuente

| Campo | Fuente canon |
|-------|--------------|
| Icon | `skill_resource.gd` → `icon: Texture2D` (ya existe, 4 Warrior SVG wired) |
| Display name | `.tres` → `display_name: String` |
| Tags | `.tres` → `tags: Array[StringName]` |
| Descripción | `.tres` → `description: String` (agregar si falta) |
| Costo MP / recurso | `.tres` → `mp_cost: float`, `resource_cost: Dict{type, amount}` (schema P0 canon) |
| CD | `.tres` → `cooldown: float` (`0.0` = animación-gated) |
| Rango alias | `.tres` → `range_alias: StringName` (MELEE_SHORT, AOE_MEDIUM, etc.) |
| Fórmula compound | Calc runtime — `DamageFormula.physical_v2(...)` con valores actuales del player |
| Efectos por nivel | `.tres` → `level_effects: Array[Dict{level, description}]` **← nuevo campo, ver §9** |
| Evolución | `.tres` → `evolution: Dict{name, required_item_id, char_level}` |
| Nivel actual skill | `PlayerSkills.get_skill_level(skill_id)` (runtime, persiste en save) |
| Skill pts disponibles | `SaveManager.get_skill_points_available()` (runtime) |

### Botón `+` (asignar punto)

```
condición_habilitado = (
    skill_pts_available > 0
    AND skill_level < 15
    AND char_level >= skill.char_level_gate
    AND skill.rama == null OR skill.rama == player.ascendencia_elegida
)
```

Click `+`:
1. `SaveManager.spend_skill_point(skill_id)` → decrementa skill_pts, incrementa `skill_level[skill_id]`
2. Emite señal `skill_level_changed(skill_id, new_level)`
3. Re-render del panel + contador global arriba

### Botón `−` (retirar punto)

Habilitado solo si:
- Skill level > 0
- **Respec parcial**: cuesta oro (fase prototipo: gratis dentro del tutorial, postlvl 25 cuesta oro incremental — `_system.md §2`)
- No requiere ítem "Tomo del Renacer" (ese solo para cambiar de rama completa)

Cada `−` refund 1 skill point.

---

## 4. Integración con stat points y save

### Canon recap
- `balance_v2.md` + `_system.md §2`: **1 skill point por nivel de personaje**
- Cap por skill: **15**
- Skill points acumulan si no se gastan (stockable)

### Contrato con SaveManager

Funciones que el UI invoca (no implementar aquí, lista para handoff gameplay):

```gdscript
# Query (no muta estado)
SaveManager.get_skill_points_available() -> int
SaveManager.get_skill_level(skill_id: StringName) -> int
SaveManager.get_total_skill_points_spent() -> int
SaveManager.get_ascendencia() -> StringName        # &"" si no elegida, &"tank"/&"berserker"/etc.
SaveManager.get_respec_count() -> int              # 0..6, después 6 → "The Lost" flag

# Mutaciones
SaveManager.spend_skill_point(skill_id: StringName) -> bool
SaveManager.refund_skill_point(skill_id: StringName, gold_cost: int) -> bool
SaveManager.choose_ascendencia(rama_id: StringName) -> bool   # solo si char lvl >= 25
SaveManager.full_respec(item_tomo_id: StringName) -> bool     # consume ítem Tomo del Renacer

# Señales
signal skill_points_changed(new_available: int)
signal skill_level_changed(skill_id: StringName, new_level: int)
signal ascendencia_changed(new_rama: StringName)
signal respec_exhausted()                                     # 6/6 → "The Lost"
```

### Schema de save (JSON)

Agregar bloque `skills` al save:

```json
{
  "player": { "...": "..." },
  "skills": {
    "points_available": 3,
    "points_spent_total": 15,
    "levels": {
      "warrior_punch": 3,
      "warrior_charge": 2,
      "warrior_war_cry": 0,
      "warrior_perfect_block": 1
    },
    "ascendencia": "",
    "respec_count": 0,
    "the_lost_flag": false,
    "hidden_skills_unlocked": []
  }
}
```

**Schema bump**: `save_schema_version` bump recomendado — gameplay decide versión exacta al implementar.

---

## 5. Drag to hotbar — contrato

### Source: skill icon en el panel

Cada Control de ícono implementa `Control._get_drag_data()`:

```gdscript
func _get_drag_data(at_position: Vector2) -> Variant:
    if skill_level <= 0:
        return null   # no arrastras skill sin puntos invertidos
    var preview := TextureRect.new()
    preview.texture = skill_resource.icon
    preview.custom_minimum_size = Vector2(48, 48)
    set_drag_preview(preview)
    return {
        "type": &"skill",
        "skill_id": skill_resource.id,
        "source": &"skill_tree_panel"
    }
```

### Target: hotbar slot existente (`hud.tscn`)

Cada `HotbarSlot` implementa `_can_drop_data` + `_drop_data`:

```gdscript
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.get("type") == &"skill"

func _drop_data(at_position: Vector2, data: Variant) -> void:
    var skill_id: StringName = data["skill_id"]
    Hotbar.bind_slot(slot_index, skill_id)   # reemplaza lo que estaba
    # si la skill ya está en otro slot, liberar ese otro (no permitir duplicados)
    Hotbar.remove_skill_from_other_slots(skill_id, except=slot_index)
```

### Reglas de drag

1. **No duplicados en hotbar**: si la skill X está en slot 3 y la arrastras al slot 5, queda solo en slot 5 (auto-clear slot 3).
2. **Swap**: si el target slot tiene otra skill Y, Y se va al slot fuente (si el drag viene de otro slot). Si el drag viene del panel, Y se descarta.
3. **No arrastrar skills con `level == 0`** (no gastaste punto → no la equipás).
4. **No arrastrar skills lockeadas** (rama no elegida, char lvl insuficiente, quest no completada).
5. **Ascendencia sin elegir**: las skills de rama son todas `level 0` por defecto → regla 3 las bloquea implícitamente.
6. **Consumibles en slots 7-8 (canon prototipo)**: si el player arrastra una skill al slot 7 u 8 permitimos — pero el canon `_system.md §4.2` reserva slots consumibles para fase Alpha (4 loadouts). Por ahora cualquier slot acepta skill.

### Limpiar slot

Right-click sobre un hotbar slot: `Hotbar.unbind_slot(slot_index)` (funcionalidad existente si hay — si no, pedido a gameplay).

---

## 6. Ascendencia gate (lvl 25 + quest)

### Estado visual según char_level + ascendencia elegida

| Condición | Estado UI sección Ascendencia |
|-----------|-------------------------------|
| `char_level < 25` | 🔒 Toda la sección gris + candado overlay + tooltip "Requiere lvl 25 (actual {lvl})". Ambas ramas clickeables solo para leer descripción (modo preview). |
| `char_level >= 25 AND ascendencia == ""` | Ambas ramas destacadas en color pleno + botón `[Elegir esta rama]` debajo de cada una. Skills dentro siguen lockeadas visualmente hasta elegir. |
| `char_level >= 25 AND ascendencia == "tank"` | Rama Tank desbloqueada full (skills clickeables, asignables). Rama Berserker en modo "no elegida" (gris oscuro, tooltip "Elegiste Tank. Cambiar de rama requiere Tomo del Renacer"). |
| Ídem Berserker | Simétrico. |

### Flujo elegir rama (lvl 25+)

1. Player llega a lvl 25
2. Notificación HUD: "¡Ascendencia desbloqueada! Abrí el Skill Tree (K) para elegir rama."
3. Player abre panel → ve las dos ramas en modo "no elegida"
4. Click en `[Elegir Tank]` → modal confirmación: *"Elegir rama Tank. Esto se puede revertir con un Tomo del Renacer (ítem raro). ¿Continuar?"*
5. Confirm → `SaveManager.choose_ascendencia(&"tank")`
6. Sección Tank se desbloquea, sección Berserker pasa a estado "no elegida"

### Skills quest-gated dentro de la rama

Las skills ocultas (ej *Último Bastión* para Tank, lvl 50 + quest) se muestran con:

- Slot visual **gris + candado grande** + badge "🎯 QUEST"
- Tooltip al hover: *"Skill oculta. Requiere lvl 50 + completar quest 'El Muro Inquebrantable'. Trigger: completar piso 50 sin que ningún aliado muera en tu radio 8m."*
- Una vez completada la quest (SaveManager detecta `hidden_skills_unlocked` contiene el id):
  - Candado desaparece, slot pasa a color pleno
  - `level = 1` automático al desbloquear (canon — la quest ya es el "costo" de desbloqueo)
  - **Subsiguientes niveles 2-15 cuestan skill points normales**

---

## 7. Respec

Canon `_system.md §2`:
- Respec parcial (retirar punto de 1 skill) → costo oro incremental
- Cambiar de rama → ítem raro **"Tomo del Renacer"** (no se compra, drop)
- **6 resets máximo lifetime** → al intentar el 7º, player pasa a flag "The Lost" (canon `GDD_DungeonParty.md`)

### UI flow

**Respec parcial** (botón `−` sobre una skill con puntos):
1. Click `−` en panel skill individual
2. Modal: *"Retirar 1 punto de 'Puño de Guerra' costará 500 oro. ¿Continuar?"*
3. Confirm → `SaveManager.refund_skill_point(&"warrior_punch", 500)`
4. **NO cuenta como reset** (resets son para cambio de rama completo)

**Respec completo / cambio de rama** (botón global):
1. Player tiene Tomo del Renacer en inventario
2. Abre Skill Tree, click botón `[ Respec completo ]`
3. Modal con warning grande: *"Usarás 1 Tomo del Renacer. Resetea TODAS las skills y liberará la rama actual. Resets usados: 0/6. ¿Continuar?"*
4. Confirm → consume ítem, resetea todo, incrementa `respec_count`
5. Player vuelve a estado "sin rama elegida" (puede re-elegir Tank o Berserker)

### Botón `[ Respec completo ]` — visibilidad

```
visible = (
    respec_count < 6
    AND player_has_item(&"tomo_del_renacer")
    AND ascendencia != ""
)
```

Si `respec_count >= 6`:
- Botón visible pero **disabled**, tooltip: *"Sos 'The Lost'. No podés resetear más. La identidad de tu personaje se fijó."*

### `the_lost_flag` — consecuencias lore

Canon GDD: el estado "The Lost" tiene implicaciones narrativas — NPCs reaccionan distinto, unlocks específicos. Fuera del scope de este UI — solo mostramos el badge *"The Lost"* al lado del nombre del char en el header del panel.

---

## 8. Mockup visual completo (ASCII — escenario realista lvl 26 Warrior Tank elegida)

```
╔═════════════════════════════════════════════════════════════════════════════════╗
║  ⚔ WARRIOR                                                  Char lvl 26        ║
║                                                             Skill pts: 1       ║
║  Rama activa: TANK                Resets: 0/6   [ Respec completo ] (🔒)      ║
║  Gold: 1,250                                                                    ║
╠═════════════════════════════════════════════════════════════════════════════════╣
║                                                                                 ║
║  ▼ GENERALES                                                                    ║
║                                                                                 ║
║  ┌─ Combate Directo ──────────────────────────────────────────────────┐        ║
║  │  ┌──────────┐    ┌──────────┐                                      │        ║
║  │  │ ⚔️        │    │ ➡️        │                                      │        ║
║  │  │ Puño     │    │ Embestida│                                      │        ║
║  │  │ 5/15 [+] │    │ 3/15 [+] │                                      │        ║
║  │  └──────────┘    └──────────┘                                      │        ║
║  └────────────────────────────────────────────────────────────────────┘        ║
║                                                                                 ║
║  ┌─ Control de Campo ─────────────────────────────────────────────────┐        ║
║  │  ┌──────────┐    ┌──────────┐                                      │        ║
║  │  │ 📣        │    │ 🛡️        │                                      │        ║
║  │  │ Grito    │    │ Bloqueo P│                                      │        ║
║  │  │ 2/15 [+] │    │ 4/15 [+] │                                      │        ║
║  │  └──────────┘    └──────────┘                                      │        ║
║  └────────────────────────────────────────────────────────────────────┘        ║
║                                                                                 ║
║  ═════════════════════════════════════════════════════════════════════════════  ║
║                                                                                 ║
║  ▼ ASCENDENCIA — TANK ELEGIDA                                                   ║
║                                                                                 ║
║  ╔═══ TANK (activa) ══════════════╗   ┌─ Berserker (no elegida) ──┐            ║
║  ║ ┌──────────┐   ┌──────────┐    ║   │  Necesita Tomo del Renacer │            ║
║  ║ │ 🧱 Postur│   │ 🛡️⚔️ Escud│    ║   │  para cambiar. Solo       │            ║
║  ║ │ a Murall │   │ o Vengad │    ║   │  lectura:                 │            ║
║  ║ │ 1/15 [+] │   │ 0/15 [+] │    ║   │  · Giro de Espada        │            ║
║  ║ └──────────┘   └──────────┘    ║   │  · Forma del Titán (ULT) │            ║
║  ║                                ║   │  · Sangre que Llama [🎯] │            ║
║  ║ ┌──────────┐                   ║   └───────────────────────────┘            ║
║  ║ │ 🎯🔒      │                   ║                                            ║
║  ║ │ Último   │  <- QUEST-GATED   ║                                            ║
║  ║ │ Bastión  │     (lvl 50+)     ║                                            ║
║  ║ │ 🔒 lvl50 │                   ║                                            ║
║  ║ └──────────┘                   ║                                            ║
║  ╚════════════════════════════════╝                                            ║
║                                                                                 ║
╠═════════════════════════════════════════════════════════════════════════════════╣
║  HOTBAR:                                                                        ║
║  [1 Puño][2 Emb][3 Grito][4 Bloq][5 Postura][6 ⋯][7 ⋯][8 ⋯]                   ║
║                                                                                 ║
║  [ Cerrar (Esc) ]                                          [ Modo respec ]     ║
╚═════════════════════════════════════════════════════════════════════════════════╝
```

### Hover sobre "Último Bastión" (quest-gated)

```
┌─────────────────────────────────────────────────────┐
│  🎯 Último Bastión                                  │
│  Skill oculta — quest gated                         │
├─────────────────────────────────────────────────────┤
│  Requisitos:                                        │
│    · Char lvl 50 (actual 26) ❌                     │
│    · Rama Tank activa ✅                            │
│    · Completar quest "El Muro Inquebrantable"       │
│      Trigger: completar piso 50 sin que ningún      │
│      aliado muera en tu radio 8m                    │
│                                                     │
│  Preview:                                           │
│    Al recibir daño letal, quedás en 1 HP con        │
│    Invul 3s. Aliados en 6m +50% DEF durante 3s.    │
│    CD 300s.                                         │
└─────────────────────────────────────────────────────┘
```

---

## 9. Handoff — qué implementa cada dept

### B (Gameplay) — Control nodes + lógica

1. **Escena `skill_tree_panel.tscn`** en `game/scenes/ui/` (nuevo folder si no existe). Raíz `Control` con:
   - Header stats (char lvl, skill pts, rama activa, resets, gold)
   - 3-4 `VBoxContainer` por sección (Generales agrupadas, Ascendencia Rama A, B, y C si Cleric)
   - Footer con referencia al hotbar (reuso del HUD hotbar node via `preload`)

2. **Script `skill_tree_panel.gd`** — responsabilidades:
   - Leer clase del player, construir grid dinámicamente
   - Conectar señales de `SaveManager` (skill_level_changed, skill_points_changed, ascendencia_changed)
   - Implementar `_get_drag_data` en cada `SkillIcon`
   - Invocar `SaveManager.spend_skill_point / refund_skill_point / choose_ascendencia / full_respec`

3. **Script `skill_icon.gd`** — `Control` con:
   - Display ícono + frame según nivel (ver §D art)
   - Label nivel actual / cap
   - Botones `+` / `−`
   - Drag source implementation
   - Estado visual: `locked` / `available` / `has_points` / `at_cap`

4. **Script `hotbar_slot.gd` (edit existente)** — agregar:
   - `_can_drop_data` y `_drop_data` para tipo `"skill"`
   - `Hotbar.remove_skill_from_other_slots()` helper

5. **`SaveManager` ampliación**:
   - Agregar bloque `skills` al save schema (bump versión)
   - Implementar los getters/setters del §4
   - Emitir señales listadas
   - Cargar/guardar `respec_count` y `the_lost_flag`
   - Cargar/guardar `hidden_skills_unlocked` (array de ids)

6. **Schema `.tres` ampliación** (`game/shared/skills/skill_resource.gd`):
   - Agregar `description: String` (multiline)
   - Agregar `general_group: StringName` (&"combate_directo", &"control_de_campo", etc.)
   - Agregar `level_effects: Array[Dictionary]` — cada dict `{level: int, description: String}` para los efectos cualitativos lvl 5/10/15 canon
   - Agregar `evolution: Dictionary` — `{name, required_item_id, required_char_level}`
   - Agregar `quest_gate: Dictionary` o null — `{quest_id, description, trigger_summary}`

7. **Input map**: agregar action `open_skill_tree` bindeada a `K` (canon `_system.md §4.1`).

8. **Notificación lvl 25** — cuando `PlayerSkills.char_level` pasa a 25 por primera vez, emitir popup HUD + sound + highlight del botón `K`.

### D (Art) — assets visuales

1. **Background panel** — imagen de fondo del modal skill tree. Estilo low-poly del resto del HUD (ver `hud.tscn` referencia). Tamaño 1280×720. Material: pergamino / piedra grabada según clase.

2. **Frames por nivel de skill** — borde del ícono cambia según `skill_level`:
   | Rango lvl | Color frame | Descripción |
   |-----------|-------------|-------------|
   | 0 | Gris oscuro | no invertido |
   | 1-4 | Bronce | inicio |
   | 5-9 | Plata | maestría media |
   | 10-14 | Oro | avanzado |
   | 15 | Rubí + glow | cap |
   | Evolucionada | Violeta + aura animada | forma alterna activa |

3. **Botones `+` / `−`** — SVG simples, estado normal / hover / disabled. Match con estética warrior SVG existente (`game/assets/ui/icons/skills/warrior/`).

4. **Candado overlay** para skills lockeadas — 2 variantes:
   - Candado simple (char lvl insuficiente o rama no elegida)
   - Candado + diana dorada 🎯 (skill quest-gated)

5. **Frame rama activa vs no elegida** — cuando ascendencia elegida, la rama activa tiene glow metálico, la otra rama pasa a tinte gris desaturado.

6. **Tooltip background** — consistente con tooltips existentes de inventory (`game/scenes/ui/tooltip.tscn` si existe, sino crear).

### QA — test plan

1. **Drag consistency**
   - Arrastrar skill al slot 3 → queda en slot 3, no en panel
   - Arrastrar misma skill al slot 5 → migra del 3 al 5, slot 3 vacío (no duplicados)
   - Arrastrar skill con lvl 0 → prevent (no debería ni iniciar drag)
   - Arrastrar skill lockeada → prevent
   - Drop sobre slot con otra skill → swap correcto

2. **Skill points — asignar / refund**
   - Subir char lvl 1 → 2 → `skill_pts_available += 1`
   - Gastar 1 punto en Puño → `skill_level[puño] = 1`, `available -= 1`
   - Intentar subir Puño a 16 → bloqueado, botón `+` disabled
   - Refund con oro insuficiente → modal error, no muta estado
   - Refund válido → `skill_level -= 1`, `available += 1`, oro gastado

3. **Ascendencia gate**
   - Char lvl 24: sección Ascendencia 🔒, click no hace nada excepto leer preview
   - Char lvl 25: ambas ramas desbloqueadas, ninguna elegida, skills internas aún lockeadas
   - Elegir Tank: sección Tank activa, Berserker gris
   - Intentar subir Giro de Espada con rama Tank elegida → bloqueado (no pertenece)
   - Skills quest-gated siguen 🔒 hasta cumplir trigger
   - Trigger completado (fake via debug): skill queda desbloqueada con `level = 1` auto

4. **Respec**
   - Respec parcial con oro suficiente: refund ok, `respec_count` NO incrementa
   - Respec completo con Tomo del Renacer: reset todo, `respec_count += 1`, rama vuelve a `""`
   - Respec completo sin tomo: botón disabled
   - Respec `count == 5` → 6º respec funciona, `count = 6`
   - 7º intento: botón disabled con tooltip "The Lost"
   - Save y reload → estado persiste

5. **Save schema**
   - Save con `skills` block → reload → estado idéntico
   - Save schema viejo (sin `skills`) → migración: `points_available = char_level`, `levels = {}`, `respec_count = 0`
   - `the_lost_flag = true` persiste entre sesiones

6. **Signals**
   - Asignar punto emite `skill_level_changed`
   - HUD hotbar actualiza ícono si la skill equipada cambia de nivel
   - Elegir rama emite `ascendencia_changed`
   - 6to respec emite `respec_exhausted`

7. **Edge cases**
   - Abrir panel con 0 skill points: todos los `+` disabled correctamente
   - Abrir panel char lvl 1: solo Puño desbloqueable, resto gris
   - Arrastrar skill durante combate (no debería permitirse — pedir confirmación a Design)
   - Arrastrar skill mientras sos un fantasma (`_is_dead`): bloquear todo el panel

---

## 10. Pendientes / diferidos

- **Loadouts Metin2 (4 sets)** — diferido fase Alpha (`_system.md §4.2`)
- **Evolución UI (activar lvl 15 + char 50 + ítem)** — diferido fase Beta. Preview en el tooltip ya definido, activación interactiva después.
- **Cleric 3ra rama (Exorcista)** — el layout debe soportar 3 columnas para Cleric. Propuesta: las 3 ramas se distribuyen en grid 3-col solo para Cleric, resto 2-col. Implementación dinámica según `class.ascendencia_count`.
- **"The Lost" narrative integration** — badge visual hecho en este spec. NPCs reactivos, unlocks especiales → lore dept fase Alpha.
- **Sonidos UI** — click `+` / `−` / elegir rama / unlock quest → handoff art/audio fase Alpha.

---

## 11. Diff con canon existente

Este spec NO cambia canon. Solo agrega:
- `.tres` schema: 4 campos nuevos (`description`, `general_group`, `level_effects`, `evolution`, `quest_gate`) — compatibles con `skill_resource.gd` actual (agregar `@export`).
- `SaveManager`: bloque `skills` nuevo + schema bump.
- Input action nuevo `open_skill_tree`.

Todo lo demás (gating, cap 15, skill points 1/lvl, ascendencia 25, respec 6 max, evolución lvl 50) **es lectura de canon** `_system.md` v1.0.

---

*Spec v1.0 — dept Design. Implementación a cargo de gameplay + art + QA. Cambios al diseño se versionan aquí primero.*
