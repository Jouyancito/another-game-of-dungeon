# Spec Fase 1 — Archer (dept/design, ola 2, 2026-04-18)

**Leer antes**: `archer.md` v2.0, `_class_lore_archer.md` v2.0, `_system.md` v1.0, `balance_v2.md`.
**Estado**: Draft canon — handoff a B (gameplay) y D (art).
**Clase**: Archer | **ID clase**: `archer`
**Rama futura**: Ranger (Hermandad de Nahuelbuta) / Artillero (Gremio Forja de Lota) — desbloqueables lvl 25.

---

## Recurso único — Concentración (max 100)

Canon `_system.md §5ter` + `archer.md §1`:

- Cap 100. Decae 3/s tras 10s sin disparar.
- **Genera por CALIDAD de disparo** (premia skill del jugador, no spam):
  - Headshot: +10
  - Flecha full charge: +15
  - Hit a >15m: +3
  - Miss: −5
- **Gasta en**: skills de precisión (segunda flecha, crit garantizado, armor-pierce).
- **MP gasta**: skills utility (Voltereta, Tormenta de Flechas).
- `resource_gen_type = 5` (CONCENTRACION en enum SkillResource).

**Nota de implementación**: la generación de Concentración por headshot y por hit >15m requiere detección en `PlayerSkills._execute` o en `mage_projectile.gd` (ver B). Miss −5 se dispara cuando el proyectil no impacta ningún colisionador en `range_m`.

---

## Skills (4 generales — Fase 1)

### 1. `archer_precise_shot` — Disparo Preciso

- **Canon ref**: `archer.md §3 SKILL 1`
- **Lore**: La flecha que esperó el momento exacto. Identidad de la Hermandad de Nahuelbuta — *"mawida ñochi"* (el bosque es silencio).
- **Cast type**: INSTANT (proyectil — 0 CD explícito, animación es el cooldown)
- **Target type**: SINGLE_ENEMY
- **Range**: 40m (LINE_PIERCE semántico — proyectil viaja en línea recta)
- **Radius / cone_angle**: 0.0 / 0.0
- **Cost**: 0 MP
- **Concentración gen**: +3 hit normal / +10 headshot / −5 miss
- **Cooldown**: 0.3s (animación base)
- **Damage formula**: PHYSICAL_V2
- **Base damage**: 12 | **Stat scaling**: DEX reemplaza STR en `physical_v2` (class_mult 1.3)
- **Status effects**: ninguno base (headshot = crit ×1.5 — lógica engine, no status)
- **Tags**: `[physical, projectile, single, headshot]`

**Schema fields P0/P1 (.tres)**:
```
id = &"archer_precise_shot"
class_id = &"archer"
display_name = "Disparo Preciso"
description = "Proyectil flecha. Headshot = crit ×1.5. Gen +3 Conc por hit, +10 headshot, -5 miss. Canon archer.md §3 SKILL 1."
cast_type = 0          # INSTANT
target_type = 1        # SINGLE_ENEMY
range_m = 40.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 0
resource_type = 3      # MP (costo 0 — tipo declarado para futuros mods de gear)
cooldown_s = 0.3
damage_formula = 1     # PHYSICAL_V2
base_damage = 12
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 1
max_skill_level = 15
evolution_id = &"archer_true_eye"
tags = Array[StringName]([&"physical", &"projectile", &"single", &"headshot"])
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
resource_gen_on_hit = 3
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 5  # CONCENTRACION
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **VFX hint**: trail fino blanco-plata en trayectoria. Impacto normal = chispa rápida. Headshot = flash dorado breve + sonido "whip" más agudo. Miss = ningún FX en origen.
- **Gameplay hook**: el bread-and-butter del Archer. Sin costo, sin CD real, solo la disciplina de la puntería. A rango corto es un disparo más del montón. A >15m genera Concentración extra (+3 de hit + bonus por distancia si B implementa el tracker). El headshot es la recompensa al jugador que apunta en serio. La first-person camera del juego hace que puntear sea skill real del player, no del personaje — esto alinea perfectamente con la fantasía de la Hermandad de Nahuelbuta.

---

### 2. `archer_charged_arrow` — Flecha Cargada

- **Canon ref**: `archer.md §3 SKILL 2`
- **Lore**: El piñón que cae solo cuando la rama decide soltarlo. La carga no apura — espera el pico natural.
- **Cast type**: CHARGED (hold para cargar, release dispara)
- **Target type**: SINGLE_ENEMY
- **Range**: 40m
- **Radius / cone_angle**: 0.0 / 0.0
- **Cost**: 5 MP al release
- **Concentración gen**: +15 full charge (detectar full charge en PlayerSkills)
- **Cooldown**: 2.0s post-release
- **Damage formula**: PHYSICAL_V2
- **Base damage**: 25 | **Stat scaling**: DEX, class_mult 1.3 | **charge_damage_multiplier_max**: 3.5 (escala 1.0× a 3.5× según charge %)
- **Status effects**: ninguno base. Lvl 10 agrega `knockback` (lógica engine, no status)
- **Tags**: `[physical, projectile, charge, single]`

**Schema fields P0/P1 (.tres)**:
```
id = &"archer_charged_arrow"
class_id = &"archer"
display_name = "Flecha Cargada"
description = "Canaliza 0→2s. Daño 1.0x→3.5x según carga. Full charge gen +15 Conc. 5 MP al soltar. Canon archer.md §3 SKILL 2."
cast_type = 4          # CHARGED
target_type = 1        # SINGLE_ENEMY
range_m = 40.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 5
resource_type = 3      # MP
cooldown_s = 2.0
damage_formula = 1     # PHYSICAL_V2
base_damage = 25
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 4
max_skill_level = 15
evolution_id = &"archer_cosmos_arrow"
tags = Array[StringName]([&"physical", &"projectile", &"charge", &"single"])
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
resource_gen_type = 5  # CONCENTRACION — gen por full charge en lógica PlayerSkills
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 2.0
charge_damage_multiplier_max = 3.5
invul_duration_s = 0.0
quest_gate = &""
```

- **VFX hint**: acumulación visible en cuerda del arco. Glow azul (25% carga) → blanco (75%) → dorado pulsante (full charge). Al soltar: trail ancho, proyectil más grande. El glow de cuerda es indicador visual del multiplicador — el jugador "ve" cuánto poder tiene.
- **Gameplay hook**: el turno de inversión del Archer. Requiere 2 segundos quieto — en un dungeon-crawler first-person donde los enemigos avanzan, esos 2 segundos son decisión táctica real. El 3.5× de daño al full charge justifica el riesgo. La Voltereta Evasiva (skill 3) existe en parte para dar espacio a cargar esta skill sin morir. A Lvl 15, el full charge garantiza crit, convirtiendo Flecha Cargada en la opener perfecta desde distancia: entrar invisible con Concentración alta → Flecha Cargada full → Disparo Preciso headshot chain.

---

### 3. `archer_evasive_roll` — Voltereta Evasiva

- **Canon ref**: `archer.md §3 SKILL 3`
- **Lore**: El paso del viento de Nahuelbuta — lo que separa al arquero vivo del muerto. Los Artilleros de Lota le llaman "el salto del pirquinero cuando la carga falla".
- **Cast type**: INSTANT (dash)
- **Target type**: SELF
- **Range / dash_distance**: 5m hacia atrás o dirección de movimiento
- **Radius / cone_angle**: 0.0 / 0.0
- **Cost**: 10 MP
- **Concentración gen**: 0 (utility pura)
- **Cooldown**: 6.0s
- **Damage formula**: NONE (no daño directo)
- **Status effects**: ninguno en base (Lvl 15 libera flechas 360° — lógica engine separada)
- **Tags**: `[physical, mobility, invul, aoe]`

**Schema fields P0/P1 (.tres)**:
```
id = &"archer_evasive_roll"
class_id = &"archer"
display_name = "Voltereta Evasiva"
description = "Dash 5m. Invul 0.4s durante el movimiento. Limpia 1 debuff no-boss al activar. 10 MP. Canon archer.md §3 SKILL 3."
cast_type = 0          # INSTANT
target_type = 0        # SELF
range_m = 5.0
radius_m = 0.0
cone_angle_deg = 0.0
resource_cost = 10
resource_type = 3      # MP
cooldown_s = 6.0
damage_formula = 0     # NONE
base_damage = 0
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 8
max_skill_level = 15
evolution_id = &"archer_wind_step"
tags = Array[StringName]([&"physical", &"mobility", &"invul", &"aoe"])
dash_distance_m = 5.0
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
resource_gen_type = 0  # NONE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.4
quest_gate = &""
```

- **VFX hint**: after-image leve del Archer en el punto de origen (0.2s, fade out). Partículas de plumas verdes al aterrizar. El invul_duration_s = 0.4 — la lógica de inmunidad ya vive en la CharacterBody3D del player; invocar via signal o flag `invul_active`.
- **Gameplay hook**: el seguro de vida del Archer. Sin ella, cargar Flecha Cargada es suicida. Con ella, el loop de combat es: observar → cargar → rodar si el enemigo presiona → disparar al reanudarse. Es el skill más "floor" del kit — incluso un Archer malo la usa bien porque es reactiva. Lvl 15 la convierte en contraataque legible: el Archer esquiva Y dispara en todas direcciones al aterrizar, convirtiendo una huida en un area-deny. Sinergia directa con Danzante (Voltereta + Paso de Sombra = dúo evasivo — ver `_synergies.md`).

---

### 4. `archer_arrow_storm` — Tormenta de Flechas

- **Canon ref**: `archer.md §3 SKILL 4`
- **Lore**: La lluvia que el bosque de Nahuelbuta no olvidó. El Artillero de Lota diría que es ineficiente. El Ranger no contesta — las flechas lo hacen por él.
- **Cast type**: CHANNELED (1.5s cast + 6s duración zona)
- **Target type**: AOE
- **Range**: 30m (posición de la zona target — click en el suelo)
- **Radius**: 12.0m (AOE_HUGE)
- **Cone angle**: 0.0
- **Cost**: 60 MP + 30 Concentración
- **Concentración gen**: 0 (ultimate gasta)
- **Cooldown**: 100.0s
- **Damage formula**: PHYSICAL_V2
- **Base damage**: 20 (por flecha, ~2 flechas/s por target en zona)
- **Stat scaling**: DEX, class_mult 1.3, weapon_dmg×0.5
- **Status effects**: ninguno base. Lvl 10 agrega `slow` a targets dentro de la zona.
- **Tags**: `[physical, ultimate, aoe, rain]`

**Schema fields P0/P1 (.tres)**:
```
id = &"archer_arrow_storm"
class_id = &"archer"
display_name = "Tormenta de Flechas"
description = "ULTIMATE. Lluvia 12m radio 6s. ~2 flechas/s por enemigo. 60 MP + 30 Conc. Pose visible 1.5s. Canon archer.md §3 SKILL 4."
cast_type = 1          # CHANNELED
target_type = 2        # AOE
range_m = 30.0
radius_m = 12.0
cone_angle_deg = 0.0
resource_cost = 60
resource_type = 3      # MP (costo primario)
cooldown_s = 100.0
damage_formula = 1     # PHYSICAL_V2
base_damage = 20
status_applied = Array[StringName]([])
status_duration_s = 0.0
unlock_level = 12
max_skill_level = 15
evolution_id = &"archer_needle_sky"
tags = Array[StringName]([&"physical", &"ultimate", &"aoe", &"rain"])
dash_distance_m = 0.0
tick_interval_s = 0.5
tick_resource_cost = 0
reactive_window_s = 0.0
reflect_ratio = 0.0
reactive_rage_on_success = 0
ally_damage_bonus_pct = 0.0
secondary_resource_cost = 30
secondary_resource_type = 5  # CONCENTRACION (costo secundario)
hp_cost_type = 0
hp_cost_value = 0.0
resource_gen_on_hit = 0
resource_gen_on_cast = 0
resource_gen_per_target = 0
resource_gen_type = 0  # NONE
combo_consume_all = false
combo_damage_multipliers = PackedFloat32Array()
charge_max_seconds = 0.0
charge_damage_multiplier_max = 1.0
invul_duration_s = 0.0
quest_gate = &""
```

- **VFX hint**: al activar, cielo visual en el AOE se oscurece ligeramente (shader temporal en la zona). Silbido ascendente 1.5s de cast. Flechas llueven en visual randomizado dentro del radio. Estilo referencia: lluvia de flechas One Piece (pose del Archer antes del cast — brazo en alto, arco tensado al cielo). El nombre de la skill aparece flotante visible durante el cast.
- **Gameplay hook**: el definidor de terreno del Archer. No es DPS instantáneo — es zona de control sostenida. El loop de uso canónico: Warrior o tanque agrupa a los enemigos → Tormenta de Flechas los clava en el area → el Archer retrocede y dispara Disparo Preciso en los que escapan. Cuesta 60 MP + 30 Concentración — requiere gestión real de recursos durante el combate previo. Lvl 15 explota el área al final, convirtiendo los 6s en un crescendo: cuanto más tiempo estuvieron los enemigos adentro, más daño toma la explosión final. Sinergia con Warrior Taunt (ver `_synergies.md`).

---

## Tabla resumen — fields críticos

| Skill | cast_type | target_type | unlock_level | resource_type | secondary_resource_type | cooldown_s | damage_formula | invul_duration_s |
|-------|-----------|-------------|--------------|---------------|------------------------|------------|----------------|-----------------|
| archer_precise_shot | 0 INSTANT | 1 SINGLE | 1 | 3 MP | 0 NONE | 0.3 | 1 PHYS_V2 | 0.0 |
| archer_charged_arrow | 4 CHARGED | 1 SINGLE | 4 | 3 MP | 0 NONE | 2.0 | 1 PHYS_V2 | 0.0 |
| archer_evasive_roll | 0 INSTANT | 0 SELF | 8 | 3 MP | 0 NONE | 6.0 | 0 NONE | 0.4 |
| archer_arrow_storm | 1 CHANNELED | 2 AOE | 12 | 3 MP | 5 CONC | 100.0 | 1 PHYS_V2 | 0.0 |

---

## Handoff

**B (gameplay)**:
- Crear 4 `.tres` en `game/shared/skills/resources/archer/` siguiendo el schema de este doc.
- Wire en `archer.gd::_equip_default_skills()` (misma lógica que `player.gd` Warrior).
- `archer_precise_shot`: implementar detección de headshot (raycast hit zone) y generación de Concentración diferenciada. Headshot crit ×1.5 en `PlayerSkills._apply_damage`.
- `archer_charged_arrow`: implementar CHARGED input (hold-to-charge) vía `charge_max_seconds = 2.0`. El `charge_damage_multiplier_max = 3.5` ya está en schema — la lógica de interpolación lineal (0%→100% = 1.0×→3.5×) vive en `PlayerSkills._execute_charged`. Generación de +15 Concentración se dispara solo al full charge (detectar `charge_pct >= 0.98`).
- `archer_evasive_roll`: `invul_duration_s = 0.4` — aplicar flag `invul_active` en `BasePlayer`. Limpieza de 1 debuff no-boss: `status_manager.remove_first_non_boss_debuff()`.
- `archer_arrow_storm`: spawn de zona `ArrowRainZone` como nodo `Area3D` en posición target. `tick_interval_s = 0.5` — cada tick aplica damage_formula a enemigos dentro. Duración zona: 6s. El `secondary_resource_cost = 30 / secondary_resource_type = 5` requiere doble-check de recurso antes de cast.
- QA: `test_archer_skills_phase1.gd` con cobertura: hit normal, headshot, miss, charge full, charge parcial, roll invul, storm tick count.

**D (art)**:
- 4 SVG icons en `game/assets/ui/icons/skills/archer/`: `precise_shot.svg`, `charged_arrow.svg`, `evasive_roll.svg`, `arrow_storm.svg`.
- 4 VFX `.tscn` (placeholders aceptables Fase 1): trail proyectil, glow de carga, after-image roll, lluvia overhead.
- Paleta Ranger: verde oliva + marrón tierra + plata desgastada (ver `_class_lore_archer.md §4.1`). Artillero: gris acero + naranja mecha (§4.2). Estas 4 skills son generales — paleta neutral que no choque con ninguna rama.

**QA**:
- `test_archer_skills_phase1.gd` en `tests/skills/`.
- Casos mínimos: costo recurso correcto, cooldown correcto, invul activo durante roll 0.4s, Tormenta no activable sin 30 Concentración.

---

*Spec Fase 1 Archer — dept/design C, 2026-04-18.*
