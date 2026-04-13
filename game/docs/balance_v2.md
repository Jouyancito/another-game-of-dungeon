# Balance v2.0 — Dungeon Party

**Versión**: 2.0
**Fecha**: 2026-04-12
**Estado**: Design Document — REEMPLAZA fórmulas lineales v1 (stats_system.md secciones de fórmulas)
**Departamento**: Game Design
**Relacionado**: `stats_system.md` (mecánicas), `tower_biome_system.md` (estructura), `enemy_tier_system.md` (tiers enemigos), `DESIGN_BRIEF.md` (identidad)

---

## 0. Propósito del documento

Reconciliar los conflictos de balance detectados en el informe 2026-04-12 y establecer las curvas definitivas para:
- Nivel jugador 1-100
- Escalado enemigos piso 1-100
- XP híbrido (kill + uso)
- Safe zones + tensión de supervivencia
- Time-to-kill target por tier

Las fórmulas lineales anteriores (`base + STR*2`) quedan **OBSOLETAS** para stats totales, aunque se mantienen como fórmula base dentro de la curva compound.

---

## 1. Decisiones canon

| Decisión | Valor | Razón |
|----------|-------|-------|
| Nivel máximo jugador | **100** | Uno conceptual por piso, encaja con 100 pisos |
| Pisos totales | 100 | Canon brief |
| Resistencias cap | **75%** | Consistencia con damage_formula.gd actual |
| Resistencia cap con Healer-Buffer en party | **80%** | +5% coop bonus, incentivo de grupo |
| Especialización de clase | **Nivel 25** | Fin Tier I, momento narrativo en safe zone P25 |
| XP | **Híbrido** kill+uso | Ver §6 |
| Duración piso promedio | 30 min (primera pasada), 8-12 min (familiarizado) | Decisión usuario |
| Duración run completo primera pasada | ~50h | 100 × 30min teórico, ajustado por eventos |
| Stat points por nivel | 3 (refuerzo, corrigible) | Mantener canon |
| Resets max → "The Lost" | 6 | Mantener canon |
| Safe zones fijas | P1, P25, P50, P75, P95 | Brief canon |
| Tabernas móviles eventuales | P2-24, P26-49, P51-74, P76-94 | Ver §7 |

---

## 2. Curva jugador — HP / MP / Daño

### 2.1 HP máximo

Curva **decelerada cuadrática soft** para que cada punto VIT importe pero con diminishing returns visibles:

```
max_hp = base_hp + (VIT * 5) + (VIT^1.3 * 0.8) + (level * 8)
```

| Nivel | VIT (ejemplo Warrior) | max_hp |
|-------|----------------------|--------|
| 1 | 10 | 100 + 50 + 16 + 8 = 174 |
| 25 | 30 | 100 + 150 + 71 + 200 = 521 |
| 50 | 50 | 100 + 250 + 138 + 400 = 888 |
| 75 | 75 | 100 + 375 + 235 + 600 = 1310 |
| 100 | 100 | 100 + 500 + 342 + 800 = 1742 |

**Razón diseño**: jugador lvl 100 tiene ~10× HP de lvl 1, no 2× como fórmula lineal actual. Sobrevive al enemigo tier 100.

### 2.2 MP máximo

```
max_mp = base_mp + (INT * 3) + (INT^1.2 * 0.5) + (level * 5)
```

### 2.3 Daño físico (compound MMO)

**Reemplaza** `damage_formula.gd::physical()`:

```gdscript
static func physical_v2(base_dmg: float, weapon_dmg: int, total_str: int, level: int, class_mult: float = 1.0) -> float:
    var stat_mult = 1.0 + (total_str * 0.02)      # +2% daño por STR
    var level_mult = 1.0 + (level * 0.03)          # +3% daño por nivel
    return (base_dmg + float(weapon_dmg)) * stat_mult * level_mult * class_mult
```

| Nivel | STR | class_mult Warrior (1.5) | weapon 20 | base 10 | daño total |
|-------|-----|--------------------------|-----------|---------|------------|
| 1 | 12 | 1.5 | 20 | 10 | 30 × 1.24 × 1.03 × 1.5 = **57** |
| 25 | 40 | 1.5 | 40 | 10 | 50 × 1.80 × 1.75 × 1.5 = **236** |
| 50 | 70 | 1.5 | 80 | 10 | 90 × 2.40 × 2.50 × 1.5 = **810** |
| 75 | 100 | 1.5 | 120 | 10 | 130 × 3.00 × 3.25 × 1.5 = **1902** |
| 100 | 140 | 1.5 | 200 | 10 | 210 × 3.80 × 4.00 × 1.5 = **4788** |

### 2.4 Daño mágico (misma fórmula, INT en vez de STR)

```
magic_v2 = (base + weapon) * (1 + INT*0.02) * (1 + level*0.03) * class_mult
```

### 2.5 Defensa — migración a diminishing returns

**Reemplaza** `damage_formula.gd::apply_physical_defense()`:

```gdscript
# Armor reduction estilo Diablo 3 — self-capping
static func armor_reduction_v2(total_def: int, attacker_level: int) -> float:
    var k = attacker_level * 50.0
    return float(total_def) / (float(total_def) + k)  # 0..1, nunca 1.0

static func apply_armor_v2(raw: float, total_def: int, attacker_level: int) -> float:
    var reduction = armor_reduction_v2(total_def, attacker_level)
    return raw * (1.0 - reduction)
```

**Razón**: la fórmula actual `max(raw - DEF, 1)` snowballea con DEF alta. La nueva self-capea, nunca llega a 100%, incentiva diversificar stats.

| DEF | vs lvl 10 (k=500) | vs lvl 50 (k=2500) | vs lvl 100 (k=5000) |
|-----|-------------------|---------------------|----------------------|
| 20 | 3.8% | 0.8% | 0.4% |
| 100 | 16.7% | 3.8% | 2.0% |
| 500 | 50.0% | 16.7% | 9.1% |
| 2000 | 80.0% | 44.4% | 28.6% |

DEF pura ya no domina. Necesitás combinar con VIT y resistencias.

### 2.6 Resistencias elementales (mantener asintótica)

Fórmula confirmada de stats_system.md con cap 75%, +5% si hay Healer-Buffer:

```
soft_cap = 75.0 (base) or 80.0 (with Healer-Buffer in party)
res_efectiva = soft_cap * (1 - e^(-0.025 * raw))
damage_final = raw_damage * (1 - res_efectiva / 100)
```

---

## 3. Curva enemigo — HP / Daño / DEF por piso

Reconcilia enemy_tier_system (4800 piso 100) con tower_biome_system (892 piso 100). Se adopta una **curva intermedia decelerante compound** para que jugador lvl 100 pueda ganar pero sea desafío real:

### 3.1 Sub-tier A (fodder)

```
HP(piso)   = 50  * (1 + piso * 0.08) * (1 + piso^1.2 * 0.01)
DMG(piso)  = 5   * (1 + piso * 0.06) * (1 + piso^1.15 * 0.008)
DEF(piso)  = floor(piso * 1.2)
XP(piso)   = 10  * (1 + piso * 0.08)
```

| Piso | HP | DMG | DEF | XP |
|------|----|----|----|----|
| 1 | 54 | 5 | 1 | 11 |
| 10 | 108 | 10 | 12 | 18 |
| 25 | 250 | 20 | 30 | 30 |
| 50 | 600 | 45 | 60 | 50 |
| 75 | 1200 | 85 | 90 | 70 |
| 100 | 2400 | 155 | 120 | 90 |

**Boss** (ancla tier): HP ×5, DMG ×2, DEF ×2.5 respecto a Sub-A.

| Piso boss | HP boss | DMG boss | DEF boss |
|-----------|---------|----------|----------|
| 25 | 1250 | 40 | 75 |
| 50 | 3000 | 90 | 150 |
| 75 | 6000 | 170 | 225 |
| 95 | 10800 | 280 | 285 |
| 100 | 12000 | 310 | 300 |

### 3.2 Multiplicadores sub-tier (mantener)

| Sub-tier | HP | DMG | DEF | XP |
|----------|----|----|----|----|
| A | 1.0× | 1.0× | 0 | 1.0× |
| B | 1.6× | 1.6× | +2 | 2.0× |
| C | 2.4× | 2.4× | +5 | 3.5× |
| Veterano (NUEVO) | 1.8× base del sub-tier escapado | 1.8× | +3 | 4.0× + drop único |
| Boss | 5.0× | 2.0× | ×2.5 | 15× |

### 3.3 Sistema Veterano (enemigo aprendido)

Reglas:
1. Si un enemigo B/C escapa con <30% HP → flag "herido" en seed persistente del bioma
2. Al regresar al mismo bioma (o próximo piso del mismo bioma), reaparece como **Veterano**:
   - Stats × 1.8
   - 1 habilidad adicional aprendida del jugador (si le pegaste melee, ahora tiene bloqueo)
   - Animación de rencor al verte
   - Nombre propio generado: "Gorok el Cicatrizado", "Lyra la Tuerta"
3. Drop garantizado: item único + entrada en codex
4. Solo persisten 3 Veteranos activos por bioma (FIFO)

---

## 4. Break-even — Jugador vs Enemigo

Target TTK (time-to-kill) por sub-tier, con jugador de nivel promedio del tier:

### 4.1 TTK target

| Sub-tier | TTK solo (hits) | TTK coop 4p (segs) |
|----------|------------------|---------------------|
| A (fodder) | 2-3 hits | 1-2s |
| B (depredador) | 4-6 hits | 3-5s |
| C (alfa) | 8-12 hits | 8-12s |
| Veterano | 10-15 hits | 12-18s |
| Mini-boss | 20-30 hits | 45-60s |
| Boss tier | 40-80 hits | 3-5 min coop |

### 4.2 Tabla simulación — Warrior solo vs sub-A

| Piso | Nivel jugador target | DMG jugador | HP enemigo | Hits necesarios | TTK @ 1.0 atks/s |
|------|---------------------|-------------|------------|-----------------|------------------|
| 1 | 1 | 57 | 54 | 1 | 1s ✓ |
| 10 | 10 | 140 | 108 | 1 | 1s ✓ |
| 25 | 25 | 236 | 250 | 2 | 2s ✓ |
| 50 | 50 | 810 | 600 | 1 | 1s ✓ |
| 75 | 75 | 1902 | 1200 | 1 | 1s ✓ |
| 100 | 100 | 4788 | 2400 | 1 | 1s ✓ |

El fodder sub-A muere de 1-2 hits en el sweet spot. Good.

### 4.3 Tabla simulación — Warrior solo vs Boss Tier

| Piso boss | Nivel target | DMG jugador | HP boss | Hits | TTK @ 1.0 atks/s con armor del boss |
|-----------|--------------|-------------|---------|------|--------------------------------------|
| 25 | 25 | 236 | 1250 | ~6 | 10-12s (con armor reduction ~30%) |
| 50 | 50 | 810 | 3000 | ~4 | 8-10s base, pero boss tiene mecánicas que extienden |
| 100 | 100 | 4788 | 12000 | ~3 | Solo hits "puros", boss real con fases llega a 3-5min |

Validación: boss no es saco de HP — mecánicas/fases alargan el combate. El DPS puro es OK.

### 4.4 Gear scaling gap

Entre pisos del mismo tier, el gear del piso N+5 debería dar ~15% más daño base al arma. Esto mantiene al jugador **dependiente del drop** sin hacerlo obligatorio (un jugador habilidoso puede pasar tier sin gear nuevo, solo más lento).

---

## 5. Curva XP — Nivel general

Sistema piecewise que reemplaza `Progression.xp_for_level()`:

```gdscript
static func xp_for_level_v2(level: int) -> float:
    if level < 25:      # Tier I — rápido, enganchador
        return 100.0 * pow(1.15, level - 1)
    elif level < 50:    # Tier II — gradual
        return 3000.0 * pow(1.12, level - 25)
    elif level < 75:    # Tier III — desacelerando
        return 45000.0 * pow(1.10, level - 50)
    elif level < 95:    # Tier IV — endgame grind
        return 500000.0 * pow(1.08, level - 75)
    else:               # Tier V — mito
        return 2500000.0 * pow(1.05, level - 95)
```

| Nivel | XP required | XP acumulado aprox |
|-------|-------------|---------------------|
| 1→2 | 100 | 100 |
| 10→11 | 351 | 2.3k |
| 25→26 | 3k | 26k |
| 50→51 | 45k | 400k |
| 75→76 | 500k | 4M |
| 95→96 | 2.5M | 20M |
| 99→100 | 3.2M | 30M |

**Razón**: curva exponencial constante 1.15 explota en lvl 100. El piecewise mantiene pacing natural: rápido al principio (enganchar), grind real al final (significado del lvl max).

---

## 6. Sistema XP Híbrido — Skyrim + clásico

### 6.1 Dos fuentes de crecimiento simultáneas

**Fuente 1 — Nivel general (XP por kill/quest)**
- Da **stat points de refuerzo** (3 por nivel)
- Desbloquea habilidades nuevas por nivel
- Permite "corrección" del build (si usaste mucho STR pero querés INT, tenés 3 points/nivel)

**Fuente 2 — Stat growth por uso (pasivo)**
- Pegás con arma melee → STR sube con probabilidad
- Casteás hechizos → INT sube
- Recibís daño → VIT + DEF suben
- Esquivás/sprintás → DEX sube
- Curás/buffeás a otros → INT sube (Healer)

Fórmula de growth por uso:

```gdscript
# Cada uso tiene chance de incrementar el stat en 1
func on_stat_action(stat: String, action_weight: float):
    var current = stats[stat]
    var chance = action_weight * (1.0 / (1.0 + current * 0.05))  # diminishing
    if randf() < chance:
        stats[stat] += 1
        emit_signal("stat_grew", stat, stats[stat])
```

Action weights (balance inicial):
- Melee hit conectado: STR +weight 0.05
- Spell cast: INT +0.03
- Damage received (no muerte): VIT +0.08, DEF +0.05
- Dodge/sprint exitoso: DEX +0.04
- Heal aplicado: INT +0.03 (solo Healer)

Growth desacelera con stat alto: stat 10 → chance 0.033, stat 100 → chance 0.009. Nunca bloquea, pero tarda.

### 6.2 Stat cap por nivel

Para evitar que un jugador lvl 5 tenga STR 100 grindeando un muñeco:

```
stat_soft_cap(level) = 15 + (level * 2)
```

| Nivel | Soft cap per-stat |
|-------|-------------------|
| 1 | 17 |
| 25 | 65 |
| 50 | 115 |
| 100 | 215 |

Pasando el soft cap, growth chance × 0.1. No imposible, pero muy lento. El nivel general **gate** el growth realista.

### 6.3 Build variety emergente

Jugador que solo pega melee con Warrior → STR sube naturalmente, pero VIT también (recibe daño). DEX no sube si nunca esquiva. El personaje refleja el playstyle real, no la asignación teórica.

Jugador híbrido Mage-melee → STR e INT suben juntos. Build viable sin planeamiento.

---

## 7. Safe Zones + Tabernas Móviles

### 7.1 Safe zones fijas

| Piso | Nombre | Servicios |
|------|--------|-----------|
| P1 | Puesto de Guardia | Outpost tutorial, stash básico, Capitán Valdo |
| P25 | Último Puesto | Herrería +1/+3 enhancement, stash expandido, Plaza Juicios |
| P50 | Última Luz | Herrería +4/+7, stash grande, mercader único, despedida emocional |
| P75 | Cabaña del Sobreviviente | Herrería +8, NPC ermitaño, último human contact |
| P95 | Umbral Inicial | Santuario vacío, preparación final |

### 7.2 Tabernas móviles (eventos raros)

**Probabilidad por piso** entre safe zones fijas:

| Pisos | Chance taverna móvil | Tipo |
|-------|---------------------|------|
| P2-24 | 20% | Caravana de mercader + fogata |
| P26-49 | 15% | Ermitaño en cabaña |
| P51-74 | 10% | Cueva con aventurero sobreviviente |
| P76-94 | 8% | Anomalía: taverna abandonada con ecos |

Cap: máximo 1 taverna móvil cada 5 pisos (evita clustering).

### 7.3 Tensión de supervivencia

Diseño target:
- Entre P1 y P25, jugador pasa por 2-4 tabernas móviles (de las 24 posibles × 20%)
- Con 30min por piso primera pasada + ~4 tabernas, run del Tier I = ~13 horas con descansos naturales
- Sensación "salgo del piso 15 sin saber cuándo descansaré" = LOGRADA

Trade-off inevitable:
- Pro: tensión real, planeamiento, value de consumibles
- Con: jugadores casuales pueden frustrarse sin safe zone cercana
- **Mitigación**: consumibles de emergencia (Pergamino de Retorno a safe zone más cercana) como drop raro

---

## 8. Gore tenue — regla visual

### 8.1 Muerte de enemigos humanoides (bandidos, humanoides)

1. HP llega a 0
2. Animación de caída al suelo (1.5s)
3. Ragdoll leve (3-5s) con física limitada
4. Cuerpo queda visible 10s
5. Desvanece en partículas doradas estilo Frieren (2s fade)

Sin sangre. Sin dismemberment. El cuerpo **existe** y luego se va.

### 8.2 Muerte de criaturas (slimes, bestias)

- Slimes: explotan en charco de gel que se evapora en 5s
- Lobos/bestias: caen, se convierten en luz etérea en 3s
- Golems: se fragmentan en piedras que quedan ambientales
- Espectros: implosión tenue sin restos

### 8.3 Muerte del jugador

- **Estado "downed"** primero (no muerte instantánea salvo abismo)
- Enemigos celebran 15s (canon brief §8.2)
- Si nadie revive → muerte real
- Cuerpo queda visible 30s (ventana extendida para recuperar loot en coop)
- Desvanece en partículas de color de la clase

### 8.4 Qué NO hacer

- NO chorros de sangre
- NO dismemberment visible
- NO gore facial
- NO cuerpos permanentes (el mundo se recicla)
- NO screamers o muerte shock

Tono Frieren: la muerte **es**, pero no se exhibe. Presente sin gratuitud.

---

## 9. Impacto en código — migración necesaria

### 9.1 Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `game/shared/stats/damage_formula.gd` | Reemplazar `physical/magic/dex` con versiones compound v2 |
| `game/shared/stats/damage_formula.gd` | Reemplazar `apply_physical_defense` con `apply_armor_v2` |
| `game/shared/stats/progression.gd` | `xp_for_level` → piecewise v2 |
| `game/shared/stats/progression.gd` | `max_health/max_mana` → decelerada |
| `scripts/base_player.gd` | Agregar sistema XP por uso (señales `on_hit_landed`, `on_spell_cast`, `on_damage_received`, `on_dodge`, `on_heal_applied`) |
| `scripts/base_player.gd` | Método `try_grow_stat(stat, weight)` con chance formula |
| `scenes/enemy/base_enemy.gd` | Sistema "Veterano" — flag persistente por seed+bioma al escapar |
| `scripts/loot_table.gd` | Ajustar drops según nuevo escalado |

### 9.2 Migración de personajes existentes

Saves v1 (nivel max 50, stats lineales) se migran:
- `new_level = old_level * 2` (lvl 50 → lvl 100 legacy conversion)
- Stats se mantienen, el escalado queda dentro del compound
- Un aviso en el save explica la conversión

### 9.3 Testing requerido

- Unit tests para `physical_v2`, `magic_v2`, `armor_reduction_v2`
- Tests para `xp_for_level_v2` (verificar no hay discontinuidades en los cortes piecewise)
- Simulación de TTK en tabla §4 con código real
- Test del sistema de growth por uso con seeds fijas (reproducibilidad)

---

## 10. Próximos pasos

Orden sugerido de implementación:

1. **Validación en papel** (hacer simulación jugador lvl 1-100 vs enemigos piso 1-100 en hoja de cálculo)
2. **Doc review** con el brief + stats_system.md para detectar conflictos residuales
3. **Implementar DamageFormula v2** en branch dept/design/balance-v2
4. **Implementar Progression v2** en la misma branch
5. **Agregar sistema XP por uso** en base_player.gd
6. **Tests GUT** para todo lo nuevo
7. **Playtest** del flujo lvl 1 → 25 con curvas nuevas
8. **Ajustar constantes** según feel del playtest

---

## 11. Decisiones pendientes (para próxima sesión)

1. **Snorkel como montura acuática** — especificar como item/slot y qué pisos lo requieren
2. **Habilidades acuáticas por clase** — listar las 5 nuevas (Mago presión, Archer arpón, Warrior placaje, Necro tiburón fantasma, Cleric burbuja)
3. **Sistema temperatura personaje** — medidor HUD, ropa afecta, consumibles térmicos
4. **Bestiario + Herbario + Codex** — UI del Journal expandido
5. **Polimorfismo (Tensei Slime)** — Shards de Alma, umbrales por tier, transformaciones activas
6. **Buffs por actividad** — tabla completa de minijuego → buff temporal
7. **Ajuste Cleric-Buffer cap +5%** — cómo se detecta en party y se aplica
8. **Ubicación definitiva de bosses** — fin de bioma + anclas de tier (reconciliar con tower_biome_system)

---

*Documento preparado por el Departamento de Game Design. Este documento reemplaza las fórmulas de balance de `stats_system.md` §Fórmulas Resumen. Cualquier cambio futuro se actualiza aquí primero.*
