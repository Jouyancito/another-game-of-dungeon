# Spec Fase 1 — Danzante de Sombras (dept/design, ola 2, 2026-04-18)

**Leer antes**: `danzante_sombras.md` v2.0, `_class_lore_danzante_sombras.md` v2.0, `_system.md` v1.0, `balance_v2.md`.
**Estado**: Draft canon — handoff a B (gameplay) y D (art).
**Clase**: Danzante de Sombras | **ID clase**: `danzante`
**Rama futura**: Sombra (asesino puro) / Trickster (evasión + control) — desbloqueables lvl 25.
**Importante**: esta es la única clase sin `.gd` ni `.tscn` implementados — spec desde cero. B deberá crear `danzante.gd` como extensión de BasePlayer antes de implementar los `.tres`.

---

## Recurso único — Combo Points (max 5)

Canon `_system.md §5ter` + `danzante_sombras.md §1`:

- **No regenera por tiempo**. Se acumulan con hits.
- **Max 5 puntos**.
- **Generación**:
  - Corte Fugaz hit: +1
  - Hit desde stealth: +2
  - Crit en cualquier hit: +1 extra (adicional al gen del hit)
- **Reset**: cambiar target O 8s sin hitear → Combo Points = 0
- **Gasta en finishers** (Danza de Mil Sombras — Fase 1). Daño escala con puntos gastados:
  - 1 punto: ×1.0
  - 2 puntos: ×1.4
  - 3 puntos: ×1.8
  - 4 puntos: ×2.4
  - 5 puntos: ×3.0 (sweet spot)
- **MP gasta**: utility (Velo Nocturno, Paso de Sombra).
- `resource_gen_type = 4` (COMBO en enum SkillResource).

**Nota de implementación**: Combo Points requieren `ClassResource` propio en `danzante.gd` (mismo patrón que `Rage` en `warrior.gd`). El tracker de target-switch para reset debe existir en `BasePlayer` o en `danzante.gd` (señal `target_changed(new_target)`). El timer de 8s sin hitear es un `Timer` interno en `danzante.gd` que se resetea en cada hit y dispara `combo_points = 0` al timeout.

---

## Skills (4 generales — Fase 1)

### 1. `danzante_swift_cut` — Corte Fugaz

- **Canon ref**: `danzante_sombras.md §3 SKILL 1`
- **Lore**: Los trails de sombra violeta-negra. El 3er hit aplica Bleed. Los Hijos de la Noche Austral llaman a la cadena *"el paso de la marea"* — rápido como la corriente de los canales de Tierra del Fuego.
- **Cast type**: INSTANT (melee rápido, 0.25s entre hits — cadena 3-hit)
- **Target type**: CONE (cono 80° 2m — MELEE_SHORT)
- **Range**: 2.0m
- **Cone angle**: 80.0°
- **Cost**: 0 MP
- **Combo gen**: +1/hit normal / +2 si desde stealth / +1 extra si crit
- **Cooldown**: 0.25s (entre hits — animación)
- **Damage formula**: PHYSICAL_V2
- **Base damage**: 8 (por hit) | **Stat scaling**: DEX, class_mult 1.2
- **Bleed fórmula**: `physical_v2(5, 0, DEX, level, 0.8)` /s — ignora armor_reduction (canon `_status_effects.md §2.1`)
- **Status effects**: `bleed` en el 3er hit de cadena (duración 3s). Los primeros 2 hits de cadena no aplican bleed.
- **Tags**: `[physical, melee, chain, combo_gen]`

**Schema fields P0/P1 (.tres)**:
```
id = &"danzante_swift_cut"
class_id = &"danzante"
display_name = "Corte Fugaz"
description = "Melee cadena 3-hit cono 80° 2m. Gen +1 Combo/hit, +2 desde stealth. 3er hit aplica Bleed 3s. 0 MP. Canon danzante_sombras.md §3 SKILL 1."
cast_type = 0          # INSTANT
target_type = 3        # CONE
range_m = 2.0
radius_m = 0.0
cone_angle_deg = 80.0
resource_cost = 0
resource_type = 0      # NONE (costo 0)
cooldown_s = 0.25
damage_formula = 1     # PHYSICAL_V2
base_damage = 8
status_applied = Array[StringName]([&"bleed"])
status_duration_s = 3.0
unlock_level = 1
max_skill_level = 15
evolution_id = &"danzante_thread_cut"
tags = Array[StringName]([&"physical", &"melee", &"chain", &"combo_gen"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 1     # +1 Combo por hit
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 4       # COMBO
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación — cadena 3-hit**: el sistema de cadena requiere tracking de hit count en `PlayerSkills._execute` o en `danzante.gd`. El bleed se aplica solo en hit_index == 2 (0-indexed: 0, 1, 2). La detección de "desde stealth" (+2 Combo gen en vez de +1) requiere flag `is_in_stealth` en `BasePlayer`. Si el hit es crit: `resource_gen_on_hit += 1` adicional ese tick. En Lvl 5: cadena pasa a 4 hits (config en `danzante.gd`, no en .tres).
- **VFX hint**: trails de sombra violeta-negra siguiendo el arma en cada hit (0.2s de vida). Hit 1 y 2: afterimage sutil. Hit 3 (bleed): color del trail cambia a rojo-violeta, impacto con partículas rojas pequenas que caen. La cadena completa se siente como ritmo: corto-corto-GOLPE.
- **Gameplay hook**: el generador de Combo Points. Sin Corte Fugaz, no hay finishers. El loop de Fase 1 es simple y satisfactorio: Corte Fugaz × 3-5 hits para acumular puntos → Danza de Mil Sombras para gastarlos con ×2.4 o ×3.0. La cadena tiene feeling de ritmo — el 3er hit es el reward natural del chain. Entrar desde stealth duplica la generación: 2 hits desde stealth + 1 normal = 5 Combo Points ya sin contar crits. Esto hace que Velo Nocturno (skill 3) → Corte Fugaz sea el opener de alta eficiencia.

---

### 2. `danzante_shadow_step` — Paso de Sombra

- **Canon ref**: `danzante_sombras.md §3 SKILL 2`
- **Lore**: La disolución en partículas negras. El clon en el origen. Los Hijos no hablan del Paso — lo demuestran. *"Si me ves, ya decidí que me veas."*
- **Cast type**: INSTANT (dash + spawn clon)
- **Target type**: SELF (dash en dirección de movimiento o hacia atrás por default)
- **Range / dash_distance**: 7.0m
- **Cost**: 10 MP
- **Cooldown**: 4.0s
- **Damage formula**: NONE (el clon replica Corte Fugaz al morir — lógica engine, no fórmula en .tres)
- **Status effects**: ninguno en el caster directo. Clon deja efecto al morir.
- **Tags**: `[physical, mobility, invul, decoy]`

**Schema fields P0/P1 (.tres)**:
```
id = &"danzante_shadow_step"
class_id = &"danzante"
display_name = "Paso de Sombra"
description = "Dash 7m. Invul 0.3s. Deja clon 2s en origen (tanquea 1 golpe, replica Corte Fugaz al morir). 10 MP. CD 4s. Canon danzante_sombras.md §3 SKILL 2."
cast_type = 0          # INSTANT
target_type = 0        # SELF
range_m = 7.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 10
resource_type = 3      # MP
cooldown_s = 4.0
damage_formula = 0     # NONE
base_damage = 0
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 4
max_skill_level = 15
evolution_id = &"danzante_void_step"
tags = Array[StringName]([&"physical", &"mobility", &"invul", &"decoy"])
dash_distance_m = 7.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.3
quest_gate = &""
```

- **Nota implementación — clon decoy**: al activar el dash, spawn un `ShadowClone` en la posición origen del caster. El clon:
  - HP: 1 hit de absorción (muere al primer golpe que recibe)
  - Duración: 2s si no recibe golpes
  - Al morir: replica `danzante_swift_cut` (1 hit, `CONE 80° 2m`, daño = 100% del base del caster en ese momento)
  - Layer física: layer 2 (Player) para que los enemigos puedan atacarlo
  - Visual: versión translúcida del Danzante, sin partículas de trail (para distinguirse del real)
  - Este clon NO genera Combo Points
- **VFX hint**: disolución en partículas negras en el origen (0.5s dissolve del clon sprite). Reaparición del Danzante en destino con chispa de sombra. El clon tiene shader de transparencia 40-60%. Al morir: el clon "explota" en trails de sombra con un Corte Fugaz visual.
- **Gameplay hook**: la herramienta de supervivencia + el confusor de aggro. En party, el clon hace que los enemigos pierdan foco del Danzante real por 2s — valioso contra AI que tiene targeting fijo. En solo, es el escape básico de situaciones letales. El `invul_duration_s = 0.3` es el corazón — 0.3s de invulnerabilidad hace que sea usable como "esquive de último segundo". Lvl 15: primer ataque tras el aterrizaje es crit garantizado — convierte el Paso de Sombra en opener: dash → land → Corte Fugaz con crit (= +2 Combo si desde stealth activo, +1 crit extra = casi full Combo en 1 opener).

---

### 3. `danzante_night_veil` — Velo Nocturno

- **Canon ref**: `danzante_sombras.md §3 SKILL 3`
- **Lore**: El Danzante se desvanece entre sombras. *"¿Me ves?"* — y antes de que alguien responda, ya no está.
- **Cast type**: INSTANT (0.2s cast — casi instantáneo)
- **Target type**: SELF
- **Range**: 0.0
- **Cost**: 25 MP
- **Cooldown**: 25.0s
- **Damage formula**: NONE (no daño directo)
- **Status effects**: `stealth` 6s (o hasta atacar). Canon `_status_effects.md §2.5`:
  - Invisible a enemigos IA (no targeted por enemigos mientras activo)
  - Próximo ataque tras stealth = crit ×2.5 (flag `post_stealth_crit` en danzante.gd)
  - Movimiento +20% velocidad durante stealth
- **Tags**: `[stealth, buff, crit_setup]`

**Schema fields P0/P1 (.tres)**:
```
id = &"danzante_night_veil"
class_id = &"danzante"
display_name = "Velo Nocturno"
description = "Stealth activa 6s o hasta atacar. Próximo ataque post-stealth crit ×2.5. Velocidad +20%. 25 MP. CD 25s. Canon danzante_sombras.md §3 SKILL 3."
cast_type = 0          # INSTANT
target_type = 0        # SELF
range_m = 0.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 25
resource_type = 3      # MP
cooldown_s = 25.0
damage_formula = 0     # NONE
base_damage = 0
status_applied = Array[StringName]([&"stealth"])
status_duration_s = 6.0
unlock_level = 8
max_skill_level = 15
evolution_id = &"danzante_veil_of_oblivion"
tags = Array[StringName]([&"stealth", &"buff", &"crit_setup"])
dash_distance_m = 0.0
tick_interval_s = 0.0
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **Nota implementación — `stealth` status**: requiere que `StatusManager` del player tenga el status `stealth` con efectos:
  1. Flag `is_in_stealth = true` en BasePlayer — IA de enemigos `enemy_basic.gd` debe skip targeting de este player si `target.is_in_stealth == true`.
  2. `post_stealth_crit_mult = 2.5` en `danzante.gd` — se activa la primera vez que el Danzante ataca tras salir de stealth. Consumido en ese primer ataque.
  3. Velocidad +20%: `velocity_multiplier += 0.20` en BasePlayer durante duración.
  4. Stealth se rompe al hacer cualquier ataque (Corte Fugaz, Danza, etc.) — no al activar Paso de Sombra (el dash mantiene stealth).
  - El gen de +2 Combo desde stealth (canon recurso) se verifica en `resource_gen_on_hit` de los skills de ataque con flag `is_in_stealth`.
- **VFX hint**: el Danzante se desvanece en partículas de sombra (0.4s fade). Mientras en stealth: player mesh transparencia 90% (solo el jugador local lo ve — en multiplayer, invisible para otros players también salvo aliados con "percepción" — mechanic post-Fase1). Al romper stealth atacando: pop de sombras con el ataque visible de manera llamativa.
- **Gameplay hook**: el setup de burst. 25s CD significa que usarla bien importa — no es panic-button recargable. El loop de burst del Danzante de Fase 1: Velo Nocturno → mover a posición ventajosa (+20% velocidad en stealth) → Corte Fugaz primer hit (×2 Combo + crit extra) → post-stealth crit ×2.5 → cadena Corte Fugaz × 2-3 más → Danza de Mil Sombras con 4-5 Combo Points. Sinergia con Warrior Taunt: el Warrior toma el aggro → Danzante aplica stealth → backstab libre sin represalias (ver `_synergies.md #9`).

---

### 4. `danzante_thousand_shadows` — Danza de Mil Sombras

- **Canon ref**: `danzante_sombras.md §3 SKILL 4`
- **Lore**: 4 segundos de afterimages superpuestos. El nombre aparece flotante. Los Hijos dicen *"Una vez"* antes de activar — porque la hacen exactamente esa cantidad.
- **Cast type**: CHANNELED (0.5s cast nombre visible + 4s duración burst)
- **Target type**: AOE
- **Range / radius**: 8.0m radio (AOE_LARGE — self-centered)
- **Cost**: 70 MP + gasta TODOS los Combo Points actuales (min 0)
- **Cooldown**: 110.0s
- **Damage formula**: PHYSICAL_V2 (por corte, 20 cortes distribuidos)
- **Base damage**: 25 (por corte) | **Stat scaling**: DEX, class_mult 1.2, weapon_dmg×0.4
- **Combo damage multiplier**: cada Combo Point gastado × +0.2 dmg (1 Combo = ×1.2, 5 Combo = ×2.2 sobre el total)
  - Schema usa `combo_damage_multipliers = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0]` (índex 0 = 0 pts, índex 5 = 5 pts)
  - Canon doc dice ×1 + ×0.2/pt — array refleja eso: `[1.0, 1.2, 1.4, 1.6, 1.8, 2.0]`
  - Nota: el combo_damage_multiplier en la Danza es sobre el TOTAL de todos los cortes, no por corte individual — B implementar como `total_dmg * combo_mult` al finalizar
- **Status effects**: el Danzante es `invul` durante los 4s (invul_duration_s = 4.0)
- **Tags**: `[physical, ultimate, multihit, invul]`

**Schema fields P0/P1 (.tres)**:
```
id = &"danzante_thousand_shadows"
class_id = &"danzante"
display_name = "Danza de Mil Sombras"
description = "ULTIMATE. 4s invul. 20 cortes AoE 8m. PHYSICAL_V2 base 25/corte. Gasta todos los Combo. 70 MP. CD 110s. Canon danzante_sombras.md §3 SKILL 4."
cast_type = 1          # CHANNELED (0.5s pose + 4s ejecución)
target_type = 2        # AOE (self-centered)
range_m = 8.0
radius_m = 8.0
cone_angle_deg = 0.0
resource_cost = 70
resource_type = 3      # MP
cooldown_s = 110.0
damage_formula = 1     # PHYSICAL_V2
base_damage = 25
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 12
max_skill_level = 15
evolution_id = &"danzante_red_moon_dance"
tags = Array[StringName]([&"physical", &"ultimate", &"multihit", &"invul"])
dash_distance_m = 0.0
tick_interval_s = 0.2  # 20 cortes en 4s = 1 corte cada 0.2s
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 0
secondary_resource_type = 0
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0
combo_consume_all = true    # consume todos los Combo Points al activar
combo_damage_multipliers = PackedFloat32Array([1.0, 1.2, 1.4, 1.6, 1.8, 2.0])
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 4.0     # 4s invul durante ejecución del ultimate
quest_gate = &""
```

- **Nota implementación — multihit loop**: `tick_interval_s = 0.2` + `cast_type = CHANNELED` significa que `_execute_channeled` dispara 1 hit de `PHYSICAL_V2(25, weapon*0.4, DEX, level, 1.2)` cada 0.2s, distribuido a enemigos random dentro del `radius_m = 8.0`. 20 cortes totales en 4s. El multiplicador de Combo (`combo_damage_multipliers`) se lee en el momento del cast (cuántos Combo Points tenía el jugador al activar), se consume (`combo_consume_all = true`), y el multiplicador resultante se aplica a TODOS los ticks del canal uniformemente.
- **Nota invul**: `invul_duration_s = 4.0` → flag `invul_active = true` durante el canal completo. El Danzante no puede ser dañado durante la Danza. Si el canal es cancelado (interrumpible en border case), refund 50% MP canon.
- **VFX hint**: 0.5s de pose visible — el Danzante se detiene, nombre flotante "Danza de Mil Sombras" aparece en pantalla (grande, en tipografía de estilo). Luego: 4s de afterimages superpuestos del Danzante moviendose en el área, grid de trails de cortes visibles (líneas blancas rápidas que se disuelven). Cada hit distribuido = destellos en el enemy. Al finalizar: los afterimages se disuelven todos a la vez, el Danzante reaparece en posición actual.
- **Gameplay hook**: el climax del kit. 110s CD hace que sea el momento del run, no una rotación. El sweet spot es llegar con 5 Combo Points (×2.0 del total de 20 cortes × 25 base = daño masivo). El prefect loop: Velo Nocturno → generar 5 Combo Points con Corte Fugaz desde stealth (2-3 hits son suficientes) → activar Danza → 4s invul mientras el AoE barre. En party, el Warrior activa Taunt para agrupar → Danzante activa Danza con 5 puntos → el daño AoE es devastador sobre el grupo agrupado.

---

## Tabla resumen — fields críticos

| Skill | cast_type | target_type | unlock_level | resource_type | combo | invul_duration_s | cooldown_s |
|-------|-----------|-------------|--------------|---------------|-------|-----------------|------------|
| danzante_swift_cut | 0 INSTANT | 3 CONE | 1 | 0 NONE | gen +1/hit | 0.0 | 0.25 |
| danzante_shadow_step | 0 INSTANT | 0 SELF | 4 | 3 MP | — | 0.3 | 4.0 |
| danzante_night_veil | 0 INSTANT | 0 SELF | 8 | 3 MP | — | 0.0 | 25.0 |
| danzante_thousand_shadows | 1 CHANNELED | 2 AOE | 12 | 3 MP | consume_all | 4.0 | 110.0 |

---

## Handoff

**B (gameplay)**:
- **Primero**: crear `game/scenes/player/danzante.gd` extendiendo `BasePlayer`. Misma estructura que `player.gd` (Warrior). Implementar:
  - `class_name Danzante`
  - Stats base: DEX 13 / STR 7 / INT 4 / DEF 3 / VIT 5 / HP base 85 / MP base 80 (canon `danzante_sombras.md §0`)
  - `ClassResource` Combo Points: max 5, gen/reset logic
  - `is_in_stealth: bool` flag + timer reset (8s sin hit → combo = 0)
  - `post_stealth_crit_mult: float` consumable
  - Signal `stealth_changed(active: bool)` para VFX
- Crear `game/scenes/player/danzante.tscn` — misma estructura que `player.tscn` (CharacterBody3D + cámara + head), mesh diferente (cápsula oscura).
- Crear 4 `.tres` en `game/shared/skills/resources/danzante/`.
- Wire en `danzante.gd::_equip_default_skills()`.
- `danzante_swift_cut`: cadena 3-hit requiere hit_counter interno que resetea en 0.5s sin activación. Bleed solo en hit 3. Gen Combo diferenciado: `+2 si is_in_stealth`, `+1 si crit`, `+1 base`.
- `danzante_shadow_step`: spawn `ShadowClone` nodo en posición origen. El clon requiere su propio escena simple (`shadow_clone.tscn` — CharacterBody3D sin AI, con collider layer 2, HP = 1 hit).
- `danzante_night_veil`: modificar `enemy_basic.gd` para respetar `target.is_in_stealth` al hacer targeting. Player en stealth = skip en `_find_target()`.
- `danzante_thousand_shadows`: loop de 20 ticks de 0.2s cada uno aplicando PHYSICAL_V2 a random enemy en `radius_m`. `invul_active = true` durante canal.
- QA: `test_danzante_skills_phase1.gd`.

**D (art)**:
- 4 SVG icons en `game/assets/ui/icons/skills/danzante/`: `swift_cut.svg`, `shadow_step.svg`, `night_veil.svg`, `thousand_shadows.svg`.
- Crear `danzante.tscn` mesh placeholder: cápsula con `StandardMaterial3D` color negro/violeta (distinto al Warrior rojo y Mage azul).
- Paleta: negro profundo + violeta medianoche. Rojo sangre solo en pintura corporal ritual (para ceremonias, no en combate base). Ver `_class_lore_danzante_sombras.md §4`.
- VFX: trails sombra violeta, partículas disolventes para dash, vanish effect para stealth, afterimages para Danza.
- El stealth shader (player semi-transparente) es prioridad visual — es el estado más frecuente del Danzante.

**QA**:
- `test_danzante_skills_phase1.gd`.
- Casos clave: Combo gen desde stealth (+2) vs normal (+1), reset de Combo en timeout 8s, invul durante Danza 4s (no recibe daño), clon absorbe 1 golpe y muere, stealth oculta al player de IA enemigos.

---

## Nota de arquitectura

El Danzante es la única clase de Fase 2 que no tiene ningún `.gd` ni `.tscn`. B debe crear la base del archivo siguiendo exactamente el mismo patrón que `player.gd` (Warrior):

```
# danzante.gd
extends BasePlayer
class_name Danzante

func _on_class_ready() -> void:
    # Stats DEX-based, HP/MP bases doc canon
    pass

func _on_attack_pressed() -> void:
    # Dispatch Corte Fugaz
    pass

func _on_attack_released() -> void:
    # Si stealth activo: first hit bonus
    pass
```

Los Combo Points como `ClassResource` deben seguir el mismo protocolo que `rage` en Warrior pero con generación diferente (por hit, no por daño recibido).

---

*Spec Fase 1 Danzante de Sombras — dept/design C, 2026-04-18. Primera clase sin implementación base — B debe crear el .gd y .tscn antes que los .tres.*
