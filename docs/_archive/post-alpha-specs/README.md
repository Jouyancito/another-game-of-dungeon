# Specs archivadas — revivir post-alpha

**Archivadas**: 2026-05-18 (scope reset)
**Razón**: Plan post-reinicio en `juego dungeon.md` (Desktop) recorta scope alpha a **5 mapas publicables**. Estas specs describen sistemas que NO entran en alpha demo y se posponen hasta post early-access.

## Archivos

| Archivo | Estado original | Por qué se archiva |
|---------|----------------|--------------------|
| `_taverna_spec.md` | Spec completa con layout + 3 NPCs canon (Millaray/Kutrán/Mensajera Lefkén) + save integration + transiciones (creada 2026-04-18) | Taverna v2 fuera de alpha. Hub mínimo basta para demo. |
| `_skill_tree_spec.md` | Spec UI v1.0 (3 secciones + mockup + drag contract + ascendencia gate) | Skill tree UI no entra en MVP demo (cap lvl 15, asignación directa basta). |
| `professions_spec.md` | Spec DRAFT (commit `4abbb39`) | Professions = sistema secundario. No acerca a los 5 mapas publicables. |

## Cuándo reactivar

Cuando el demo de itch.io + Steam wishlist estén publicados y exista feedback real de jugadores tipo Valheim / Hades / Vampire Survivors early access, revisar cuál de estos sistemas pide la comunidad y priorizar.

**No revivir** sin pasar por el filtro: *"¿Esto acerca o aleja de los siguientes 5 mapas?"*

## Restauración

```sh
git mv docs/_archive/post-alpha-specs/_taverna_spec.md     game/docs/ui/
git mv docs/_archive/post-alpha-specs/_skill_tree_spec.md  game/docs/ui/
git mv docs/_archive/post-alpha-specs/professions_spec.md  game/docs/
```

Y antes de tocar nada en `_class_lore_*.md` (pausados desde 2026-04-23 por world_canon v2.0), realinear primero al hub planetario multicultural.
