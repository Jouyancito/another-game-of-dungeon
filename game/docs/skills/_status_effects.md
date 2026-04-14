# Status Effects — Catálogo Canon

**Versión**: 1.0
**Fecha**: 2026-04-14
**Estado**: Canon. Expande `_system.md` §5quater con catálogo completo y reglas detalladas.
**Depende**: `_system.md` (reglas base), `balance_v2.md` (resist cap, fórmulas)
**Audiencia**: dept Gameplay (implementación), dept Art (VFX), dept Design (futuras skills)

---

## 0. Filosofía

Status effects son el **vocabulario mecánico compartido** entre clases. Cualquier skill nueva que aplique un status debe usar uno de este catálogo, no inventar. Si una clase necesita un efecto nuevo, primero se agrega acá.

Reglas de oro:
1. **Refresh-to-max, no suma**. Aplicar mismo status sobre uno activo deja la duración mayor.
2. **Stacks** son excepción explícita por status (bleed, poison).
3. **Inmunidades** se resuelven en orden: tipo de mob → bioma → gap nivel → tier → final.

---

## 1. Reglas globales

### 1.1 Aplicación de status

Pseudo-código de aplicación canónica:

```
func aplicar_status(target, status_id, base_duration, source):
    # 1. Inmunidad por tipo (ej Boss Slime inmune a freeze permanente)
    if target.has_flag("immune_" + status_id):
        return false

    # 2. Multiplicador de bioma
    bioma_mult = obtener_bioma_resist(target.bioma, status_id)

    # 3. Multiplicador por gap de nivel
    gap = target.level - source.level
    if gap >= 25: return false
    elif gap <= 10: gap_mult = 1.0
    else: gap_mult = (25 - gap) / 15.0

    # 4. Multiplicador por tier (sub-A 1.0, ..., boss 0.25)
    tier_mult = obtener_tier_mult(target.tier)

    # 5. Duración final
    final_duration = base_duration * bioma_mult * gap_mult * tier_mult

    # 6. Refresh-to-max o stack
    if status.is_stackable:
        target.add_stack(status_id, final_duration)
    else:
        target.refresh_status(status_id, final_duration)

    return true
```

### 1.2 Multiplicadores de tier (canon `_system.md`)

| Tier | Mult |
|------|------|
| Sub-A fodder | 1.00 |
| Sub-B depredador | 0.80 |
| Sub-C alfa | 0.60 |
| Veterano | 0.50 |
| Elite / Mini-boss | 0.40 |
| Boss tier | 0.25 |

### 1.3 Multiplicadores de bioma

| Bioma | Status reducidos | Multiplicador |
|-------|-----------------|---------------|
| Hielo (P26-50) | freeze, slow | 0.50 |
| Hielo (P26-50) | burn | 1.30 (vulnerables a fuego) |
| Fuego/Volcán | burn | 0.50 |
| Fuego/Volcán | freeze | 1.30 |
| Tormenta (P51-75) | shock, stun por rayo | 0.50 |
| Pradera (P1-25) | sin resistencias especiales | 1.00 |
| Acuático (eventos especiales) | burn | 0.70 |
| Acuático | shock | 1.30 (vulnerables al rayo en agua) |
| Dimensión Rota (P76-100) | todos los elementales | 0.70 |
| Dimensión Rota | silence, fear | 0.50 (mentes rotas resisten control) |

### 1.4 Inmunidades especiales por arquetipo de mob

| Arquetipo | Inmune permanente a |
|-----------|---------------------|
| Slime | freeze (no se puede congelar líquido) |
| Golem | poison, bleed |
| Espectro / Wraith | physical bleed, knockback |
| Undead | fear, miss chance (sin moral) |
| Elemental fuego | burn (auto-inmune) |
| Elemental hielo | freeze, slow |
| Construct | silence, fear |
| Bosses (todos) | knockback hard, fear-huir |

Bosses pueden recibir versiones reducidas (ej knockback se convierte en stagger 0.3s).

---

## 2. Catálogo completo

Ordenado por categoría: **DoT** / **Control** / **Debuff** / **Buff** / **Especiales**.

### 2.1 DoT (Damage Over Time)

#### Bleed
- **Tipo**: físico, ignora armor_reduction
- **Duración base**: 5s
- **Tick**: cada 1s
- **Daño/tick**: `physical_v2(8, 0, source.STR_o_DEX, source.level, 0.7)` (ignora armor)
- **Stack**: SÍ, hasta x3 (cada stack tickea independiente)
- **Aplicado por**: dagas, crits físicos, espadas filo, ciertas trampas
- **Interacción**: NO afecta enemigos sin sangre (constructs, slimes, espectros)
- **VFX hint**: gotas rojas saliendo del modelo, charco mínimo en el suelo (low-poly)

#### Burn
- **Tipo**: mágico fuego
- **Duración base**: 4s
- **Tick**: cada 1s
- **Daño/tick**: `magic_v2(10, 0, source.INT, source.level, 0.6)`, dmg type fire
- **Stack**: NO (refresh-to-max)
- **Aplicado por**: skills fire (Mage Elementalista Fuego, ítems fuego)
- **Interacción**: enemigos en bioma hielo vulnerables (×1.3); apaga si entra al agua
- **VFX hint**: llamas pequeñas estilo low-poly, partículas naranjas ascendiendo

#### Poison
- **Tipo**: mágico veneno
- **Duración base**: 6s
- **Tick**: cada 1s
- **Daño/tick**: `magic_v2(6, 0, source.INT_o_DEX, source.level, 0.5)`
- **Stack**: SÍ, hasta x3
- **Efecto extra**: **bloquea heals al 50% durante duración** (mecánica única, justifica usarlo en boss)
- **Aplicado por**: shurikens del Danzante, bestias venenosas, alquimia
- **Interacción**: golems y constructs inmunes
- **VFX hint**: tinte verdoso al modelo, partículas verdes flotantes

#### Plague (Necromancer Maldiciones — único)
- **Tipo**: mágico oscuro
- **Duración base**: 8s
- **Tick**: cada 1.5s
- **Daño/tick**: `magic_v2(7, 0, source.INT, source.level, 0.6)`
- **Stack**: NO
- **Efecto extra**: al expirar o killear, se propaga a enemigos en 3m con duración -50%
- **Aplicado por**: Aliento de Plaga, pasiva Aura de Plaga
- **VFX hint**: niebla violeta-verdosa pulsante alrededor

---

### 2.2 Control (CC duro)

#### Freeze
- **Efecto**: target inmóvil, no puede actuar
- **Duración base**: 1.5-3s típico
- **Stack**: NO (refresh-to-max)
- **Aplicado por**: skills hielo (Mage Elementalista Hielo)
- **Interacción**: shatter si recibe golpe físico fuerte mientras frozen → bonus dmg +50% único, status removido (combo)
- **Inmunidades**: slimes (líquidos), elementales hielo, bosses cap 25%
- **VFX hint**: cristal de hielo envolviendo modelo, sparkles azules

#### Stun
- **Efecto**: aturdido, sin acción ni movimiento
- **Duración base**: 1-2s típico
- **Stack**: NO (refresh-to-max)
- **Aplicado por**: impactos pesados (Embestida, Bloqueo Perfecto reflejo, ítems shock)
- **Interacción**: bosses reciben "stagger" 0.3s en vez de stun completo
- **VFX hint**: estrellitas circulando cabeza estilo cartoon discreto

#### Knockback
- **Efecto**: desplazamiento físico X metros
- **Duración**: instantáneo (es un movimiento, no estado)
- **Stack**: NO (un knockback en proceso ignora otros)
- **Aplicado por**: explosivos, cargas, Embestida
- **Interacción**: bosses inmunes; elites reciben "stagger" en su lugar
- **VFX hint**: efecto shockwave en punto de impacto

#### Silence
- **Efecto**: target no puede usar skills (solo ataque básico)
- **Duración base**: 2s
- **Stack**: NO
- **Aplicado por**: Cleric Exorcista vs undead, ciertas skills oscuras
- **Interacción**: undead/casters lo sienten; melee puro lo ignora
- **VFX hint**: hilo dorado sobre la boca o símbolo de prohibido sobre cabeza

#### Taunt
- **Efecto**: target obligado a atacar al taunter
- **Duración base**: 3s
- **Stack**: NO (último taunt aplicado domina)
- **Aplicado por**: Warrior Tank skills (Skill 1 con rama Tank), ciertos ítems
- **Interacción**: bosses pueden tener fases anti-taunt; en fases normales reciben 50% duración
- **VFX hint**: línea visual roja entre taunter y target durante duración

---

### 2.3 Debuff (no-CC, modifican stats)

#### Slow
- **Efecto**: −X% velocidad de movimiento (típico −40%)
- **Duración base**: 3-5s
- **Stack**: NO (refresh-to-max, mayor slow domina si distintos)
- **Aplicado por**: hielo suave (post-freeze), telarañas, trampas, Mage L4 Tormenta
- **Interacción**: Slow no impide skills, solo movimiento
- **VFX hint**: trail azulado lento, partículas de hielo derritiéndose

#### Weak
- **Efecto**: −25% daño saliente del target
- **Duración base**: 5s
- **Stack**: NO
- **Aplicado por**: Verso del Exorcismo, Aura Plaga, debuffs varios
- **VFX hint**: tinte gris al modelo, brazos algo caídos en idle

#### Vulnerable
- **Efecto**: +25% daño recibido por el target (todas las fuentes)
- **Duración base**: 4s
- **Stack**: NO (mayor vulnerable domina)
- **Aplicado por**: Marca de Muerte (Necro Rito modo Marca), Verso Exorcismo, marcas Danzante
- **Interacción**: combo clave para coop — el que aplica vulnerable habilita burst del equipo
- **VFX hint**: cruz roja flotante sobre target, glow rojo tenue

#### Miedo (Fear)
- **Efecto dual**: −25% daño saliente + acción "huir" 3s (target corre lejos del source)
- **Duración base**: 3s
- **Stack**: NO
- **Aplicado por**: Grito de Guerra mejorado (Tank), skills oscuras Necromancer, eventos
- **Interacción**: bosses inmunes al huir, sí reciben −25% dmg debuff (cap 50% duración)
- **VFX hint**: símbolo de calavera tenue sobre cabeza, modelo encorva

#### Miss Chance
- **Efecto**: +X% chance de fallar ataques (típico 30%)
- **Duración base**: 4s
- **Stack**: NO (mayor % domina)
- **Aplicado por**: ilusiones (Mage Arcano, Danzante Trickster), ciertas pasivas
- **Interacción**: solo afecta ataques targeted, no AoE
- **VFX hint**: imagen del modelo "vibrando" con afterimages cortos

#### Marked
- **Efecto**: target visible a través de paredes para todo el equipo + +20% daño recibido del aplicador
- **Duración base**: 6s
- **Stack**: NO
- **Aplicado por**: Danzante (skill futura), Archer pasiva Ranger, scout items
- **Interacción**: complementa Vulnerable (se puede stackear distinto debuff)
- **VFX hint**: outline rojo brillante visible cross-wall

---

### 2.4 Buff (efectos positivos a aliados o self)

#### Regen
- **Efecto**: heal por segundo
- **Duración base**: 5-8s
- **Tick**: cada 1s
- **Heal/tick**: variable según skill
- **Stack**: hasta x3 (Sanador Maestría)
- **Aplicado por**: Luz Restauradora L4+, Círculo Sagrado (mientras dentro)
- **VFX hint**: partículas verdes ascendentes sobre modelo

#### Shield (Absorb)
- **Efecto**: pool de HP temporal absorbe dmg antes que HP real
- **Duración base**: 6-10s o hasta consumir
- **Stack**: NO (mayor escudo domina; cap a la suma si Cleric con upgrade)
- **Aplicado por**: Égida Divina, Barrera Prismática, Toque Vital L5 overheal
- **VFX hint**: aura translúcida hexagonal sobre modelo

#### Empower
- **Efecto**: +X% daño saliente (típico +20%)
- **Duración base**: 5-8s
- **Stack**: NO
- **Aplicado por**: Verso del Guardián (Buffer), Sanador Skill 1 mejorada
- **VFX hint**: aura dorada tenue sobre target

#### Haste
- **Efecto**: +X% velocidad movimiento + atk speed (típico +25%)
- **Duración base**: 5s
- **Stack**: NO
- **Aplicado por**: Buffer skills, ítems
- **VFX hint**: trail amarillo en pies, leve afterimage en movimiento

#### Resist Cap Boost (Aura de Resguardo)
- **Efecto**: +5% resist cap (75% → 80%) a aliados en 20m radio mientras Buffer vivo
- **Duración**: continua mientras Buffer vivo + en rango
- **Stack**: NO (es aura única de pasiva)
- **Aplicado por**: Cleric Buffer pasiva única (canon balance_v2 §2.6)
- **VFX hint**: aura dorada-blanca sutil sobre aliados en rango

#### Invul (invulnerabilidad)
- **Efecto**: ningún dmg recibido
- **Duración base**: 0.3-3s (corta por diseño)
- **Stack**: NO (un invul activo bloquea aplicar otro)
- **Aplicado por**: dashes (Voltereta, Paso de Sombra, Embestida con upgrade), Égida L5 trigger
- **VFX hint**: glow blanco breve, modelo translúcido durante duración

---

### 2.5 Especiales

#### Cursed (Necromancer canónico)
- **Efecto**: NO se puede curar al target durante duración (heals ignorados completamente)
- **Duración base**: 4s
- **Stack**: NO
- **Aplicado por**: Maldición Marchita (rama Maldiciones), boss debuffs
- **Interacción**: contrarresta a Cleric — un Cleric debe esperar o cleansear primero
- **VFX hint**: símbolo de calavera negra sobre target, tinte morado

#### Stealth (auto-buff player)
- **Efecto**: invisible a enemigos, próximo ataque crit ×2.5 (canon Danzante Velo Nocturno)
- **Duración base**: 6s o hasta atacar
- **Stack**: NO (ya estás en stealth o no)
- **Aplicado por**: Velo Nocturno, ciertos ítems
- **Interacción**: enemigos con flag "scent" o "true_sight" detectan igual
- **VFX hint**: modelo del player translúcido al 30%, sin trail

#### Charm (rara, eventos especiales)
- **Efecto**: target ataca a sus aliados durante duración
- **Duración base**: 3s
- **Stack**: NO
- **Aplicado por**: skills futuras de boss, ítems únicos
- **Interacción**: bosses inmunes; humanoides afectados
- **VFX hint**: corazón rosa flotante sobre cabeza (low-poly)

---

## 3. Combos entre status (sinergias mecánicas)

Algunos status interactúan generando bonus extra sin requerir skill especial.

| Combo | Trigger | Resultado |
|-------|---------|-----------|
| **Shatter** | Frozen + golpe físico ≥ 100 dmg | +50% dmg al golpe, freeze removido. VFX cristal explotando. |
| **Ignite** | Burn x2 (refresh sobre burn activo con >50% restante) | Próximo tick triplica dmg, burn termina. |
| **Electrocute** | Wet (acuático) + shock | Dmg ×1.5 al rayo, stun 0.5s. |
| **Bleeding Frenzy** | Bleed x3 stacks completos | El próximo crit explota stacks (suma de daño x3 pendiente). |
| **Plagued Land** | Plague que expira + enemigo dentro de Tormenta Arcana | Plague se propaga al doble del radio. |
| **Vulnerable Strike** | Vulnerable + crit | Crit +50% dmg adicional encima del crit normal. |

Estos combos son **emergentes** — no requieren UI explícita, solo ocurren si las condiciones se dan. Recompensan coordinación coop sin forzarla.

---

## 4. Display en HUD (spec UI)

Cada status activo en player o target frame muestra ícono pequeño:
- Ícono 24x24 px
- Borde por categoría (rojo DoT, azul control, gris debuff, dorado buff, violeta especial)
- Timer numérico abajo del ícono (segundos restantes)
- Stack count arriba derecha si aplica (ej Bleed x3)
- Hover muestra tooltip con efecto exacto

Player ve hasta 8 status simultáneos visibles (resto se suprime al overflow).

---

## 5. Implementación — checklist dept Gameplay

- [ ] `StatusEffect` clase base (resource o nodo según convención del proyecto)
- [ ] Manager por entidad: `apply()`, `remove()`, `tick()`, `is_immune()`
- [ ] Pipeline de aplicación con multiplicadores (tier × bioma × gap)
- [ ] Catálogo de status como recursos (uno por entrada de §2)
- [ ] Detección de combos §3 (eventos `status_applied` + check de combo)
- [ ] Señales: `status_applied`, `status_removed`, `status_ticked`, `combo_triggered`
- [ ] Tests GUT por combo y por inmunidad

---

## 6. Pendientes

- VFX detallado por status (dept Art) — usar §VFX hint como base
- Sonidos por status (dept Audio futuro)
- Localización text de tooltips ES/EN
- Status únicos de bosses (futuro, cuando se diseñen bosses pisos avanzados)

---

*Canon. Cualquier status nuevo se agrega acá primero, después se referencia desde skills.*
