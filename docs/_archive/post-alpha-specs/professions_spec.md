# Professions / Vidas Paralelas Spec

**Estado**: DRAFT — open questions pendientes
**Última edición**: 2026-05-07
**Owner**: dept/design (asignar)

## Concepto

Reemplazar la tab "Equipo" del Character Window (que NO debe ir ahí — el equipamiento ya tiene su paper-doll dedicado) con un sistema de **Profesiones / Habilidades del Mundo Abierto**.

Las profesiones son **vidas paralelas al combate** — el player es aventurero pero también puede ser minero, pescador, lingüista, observador. Suben aparte del nivel de combate. No requieren combat. Se aprovechan en torre/dungeon Y en taverna/mundo abierto.

## Pilares

1. **NO bloquean progression** — sos viable sin profesiones. Son OPCIONALES.
2. **Suben con uso** — pescar sube Pesca, minar sube Minería. NO XP por kill.
3. **Recompensan exploración** — mejor Percepción = ves cosas que otros no.
4. **Cross-class neutral** — un Warrior puede ser pescador, un Mage puede ser cazador. NO restringe build de combate.
5. **Mundo abierto first** — útiles principalmente en taverna/aldea + zonas tranquilas. Útiles secundarios en torre.

## Lista preliminar (6 profesiones)

| Profesión | Qué hace | Cómo sube | Recompensa |
|---|---|---|---|
| **Minería** | Romper vetas en cuevas/montañas | Minar nodos | Materiales para crafting (gemas, metales) |
| **Pesca** | Pescar en ríos/lagos | Pescar | Comida (heal/buff), peces raros |
| **Caza** | Trampas + skinning de fauna | Cazar/trampear | Pieles, plumas, garras (crafting) |
| **Percepción** | Detectar trampas, secretos, prey escondida | Auto: usás stats al moverte | Ves cofres ocultos, trampas marcadas, prey de hawk visible |
| **Lingüística** | Leer textos antiguos, runas, pergaminos | Encontrar/leer textos | Lore, mapas escondidos, pistas de quests |
| **Observación** | Aprender comportamiento mob (Saber del doc Evolución) | Pasivo al observar mob | Conocer fases, weakpoints, prey patterns |

## UI placeholder (Fase 0 — primera iteración)

Tab "Profesiones" en Character Window:
```
═══ Profesiones ═══

🔨 Minería          Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100
🎣 Pesca            Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100
🏹 Caza             Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100
👁  Percepción       Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100
📜 Lingüística      Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100
🔍 Observación      Lvl 0   [▱▱▱▱▱▱▱▱▱▱]  0 / 100

[Tooltips al hover: explicación + cómo subir]
```

NO usar emojis en código real — placeholder visual aquí. Iconos SVG después (dept/art).

## Curva de niveles

Propuesta: 0-50 niveles per profesión. XP requerido por nivel: lineal o low-curve (no exponencial — no debe ser grindy).

Open question — ¿caps por floor de torre? Ej: piso 1 cap minería 10 (solo minerales básicos), piso 5 cap 50.

## Open Questions

- [ ] **Q1**: ¿Profesiones son por personaje o por cuenta? (alineado con Saber del DESIGN_NOTES_2026-05-06-1.md → personaje)
- [ ] **Q2**: ¿Hay sub-trees? Ej: Minería → especialización en gemas vs metales?
- [ ] **Q3**: ¿Cómo se desbloquean? ¿Todas desde lvl 1 o algunas requieren quest?
- [ ] **Q4**: ¿Persistencia entre runs? Permadeath del char afecta profesiones del char.
- [ ] **Q5**: ¿Stats afectan profesiones? Ej: DEX afecta Pesca, INT afecta Lingüística.
- [ ] **Q6**: ¿Hay límite de profesiones activas? ¿Podés ser maestro de las 6 o tenés que elegir?
- [ ] **Q7**: Cross con Saber/Evolución (DESIGN_NOTES_2026-05-06-1.md): "Observación" se solapa con sistema de Saber. ¿Es lo mismo? ¿Saber ES Observación?
- [ ] **Q8**: ¿Recompensas materiales requieren crafting system funcionando? (no existe aún → Fase 2/3)

## Decisiones Tomadas

- ✅ Tab "Equipo" NO va en Character Window — equipamiento tiene paper-doll dedicado
- ✅ Profesiones reemplazan esa tab (renombrar "Profesiones")
- ✅ Lista inicial 6: Minería / Pesca / Caza / Percepción / Lingüística / Observación
- ✅ Cross-class neutral
- ✅ Subida por uso (no XP por kill)

## Implementación — Fases sugeridas

### Fase 0 — UI placeholder (1-2h)
- Renombrar tab "Equipo" → "Profesiones" en `character_window.tscn`
- Crear scene/control con 6 barras placeholder (Lvl + bar 0/100 + label)
- Sin lógica de subida — solo visual. Stats hardcoded a 0.

### Fase 1 — Lógica básica de subida (5-8h)
- Crear `Professions` resource per-character (similar a ClassResource)
- Hooks: al minar nodo → +1 Minería XP. Al pescar → +1 Pesca XP. Etc.
- UI live update.
- Save/load.

### Fase 2 — Recompensas + integración crafting (futuro)
- Materiales que dropean al subir profesión
- Crafting system (issue separado)
- Recetas que requieren profesión X lvl Y

### Fase 3 — Sub-trees + maestría (futuro post-MVP)
- Especializaciones dentro de cada profesión
- Skills pasivas que se desbloquean

## Archivos afectados (Fase 0)

- `game/scenes/ui/character_window.tscn` — renombrar tab + reemplazar contenido
- `game/scenes/ui/character_window.gd` — wire profesiones placeholder
- (Futuro) `game/shared/professions/professions_resource.gd` — datos persistentes

## Cross-canon

- `_system.md` — sistema de skills (NO confundir con profesiones — son ortogonales)
- `DESIGN_NOTES_2026-05-06-1.md` — Saber/Evolución (Q7 cross-tension con Observación)
- `_world_canon.md` — actividades en taverna/aldea (pesca/minería tendrán nodos físicos)
- `balance_v2.md` — curva XP profesiones (Q5 stat impact)

---

*Doc vivo — actualizar cuando se respondan open questions o se asigne a dept.*
