# Mage — Skill Set Canon

**Versión**: 2.0 — migrado al modelo `_system.md` v1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Reemplaza versión 1.0.
**Depende**: `_system.md`, `_status_effects.md`, `balance_v2.md`.
**Class mult mágico**: 1.5 | **Base stats**: INT 12 / STR 4 / DEX 5 / DEF 3 / VIT 5
**Recurso único**: **ninguno — solo MP** (fantasy lock canon `_system.md §5ter`)

---

## 0. Identidad

Mage es el arquetipo de mana puro. Pool grande, gestión intensa, ningún recurso secundario que lo "haga más fácil". Dos ramas definen la personalidad: **Elementalista** (Fuego / Hielo / Rayo, specialty sub-elemento fijo) y **Arcano** (manipulación espacial, control de posición, teleport).

---

## 1. Recurso — MP only

- Pool base 100 + INT×3 + INT^1.2×0.5 + level×5 (canon `balance_v2 §2.2`)
- Regen: 5/s fuera combate, 2/s en combate
- Full regen en safe zones
- **Sin recurso secundario** — el Mage compensa con skills de gestión (Barrera devuelve MP al romper, ítems que regen MP por crit, etc.)

---

## 2. Pool total (10 skills)

| # | Skill | Categoría | Rama | Gate | Tags |
|---|-------|-----------|------|------|------|
| 1 | Bolita Inestable | general | — | 1 | `[magic][projectile][single][arcane]` |
| 2 | Tormenta Arcana | general | — | 4 | `[magic][channel][AoE][arcane]` |
| 3 | Barrera Prismática | general | — | 8 | `[magic][shield][defensive][arcane]` |
| 4 | Arte Arcano: Supernova (ult) | general | — | 12 | `[magic][ultimate][AoE][arcane]` |
| E1 | Maestría Elemental (pasiva) | rama | Elementalista | 25 | `[passive][elemental]` |
| E2 | Furia Elemental | rama | Elementalista | 30 | `[magic][elemental][focus]` |
| E3 | Armonía Rota (oculta) | rama quest | Elementalista | 50 + quest | `[magic][AoE][tri-elemental]` |
| A1 | Distorsión Espacial (pasiva) | rama | Arcano | 25 | `[passive][mobility]` |
| A2 | Manipulación Espacial | rama | Arcano | 30 | `[magic][utility][tele]` |
| A3 | Singularidad (oculta) | rama quest | Arcano | 50 + quest | `[magic][AoE][control]` |

Gating char lvl 1, 4, 8, 12 generales. Rama 25, 30, 50+quest.

---

## 3. Skills generales

### SKILL 1 — Bolita Inestable
Proyectil finger-guns canon brief §3. Base de cualquier build.

- **Tags**: `[magic][projectile][single][arcane]`
- **Tipo**: proyectil activa | **Costo**: 8 MP | **CD**: 0.4s | **Cast**: 0.15s | **Velocidad**: `PROJ_MED` (22 m/s)
- **Rango impacto**: `AOE_SMALL` 1m radio al explotar
- **Fórmula**: `magic_v2(18, weapon_dmg, INT_total, level, 1.5)`
- **Lvl 5**: velocidad 25 m/s, `AOE_SMALL` 1.5m radio
- **Lvl 10**: disparo doble (2 bolitas con 0.1s delay, 2º al 70% dmg)
- **Lvl 15**: primer impacto aplica `Vulnerable` 3s. **Forma base — cap**.
- **Evolución (+ ítem *Fragmento de Supernova* boss P25)**: **Orbe de Colapso** — la bolita se vuelve esfera estacionaria 2s que atrae enemigos 4m, luego detona con 2× dmg.
- **Acuática**: **Presión Abisal** — proyectil viaja igual bajo agua, dmg +20%.

### SKILL 2 — Tormenta Arcana
Canalizada AoE sostenido. Ya implementada como "rayo canalizado" prototipo.

- **Tags**: `[magic][channel][AoE][arcane]`
- **Tipo**: canalizada AoE | **Costo**: 20 MP/s | **CD**: 3s post-canal | **Rango**: `CONE_CANAL` (8m cono 45°) + `AOE_SMALL` 4m alrededor del target
- **Efecto base**: tick 0.25s, daño continuo
- **Fórmula/tick**: `magic_v2(6, weapon_dmg*0.3, INT, level, 1.5) * 0.25`
- **Lvl 5**: tick cada 0.2s
- **Lvl 10**: aplica `Slow` 30% a todo lo tickeado por 1s refrescante
- **Lvl 15**: enemigos dentro >2s reciben `Vulnerable`. **Forma base — cap**.
- **Evolución (+ ítem *Tormenta Perpetua* boss P75)**: **Tormenta Perpetua** — canal gratis primeros 3s.

### SKILL 3 — Barrera Prismática
Escudo defensivo, único recurso de mitigación del Mage pre-rama.

- **Tags**: `[magic][shield][defensive][arcane]`
- **Tipo**: escudo activa | **Costo**: 25 MP | **CD**: 15s | **Cast**: 0.3s | **Duración**: 6s o hasta romper
- **Efecto base**: aplica `Shield` absorb = `80 + INT*3` (mágico o físico)
- **Lvl 5**: +30% absorb
- **Lvl 10**: al romper genera `AOE_SMALL` 3m, 40% absorb como dmg a enemigos en rango
- **Lvl 15**: refleja 20% del dmg absorbido al atacante. **Forma base — cap**.
- **Evolución (+ ítem *Prisma Fractal* Tier III)**: **Barrera Fractal** — 3 capas independientes, cada capa absorbe separadamente (HP efectivo ×3).

### SKILL 4 — Arte Arcano: Supernova (ULTIMATE)
- **Tags**: `[magic][ultimate][AoE][arcane]`
- **Tipo**: ultimate AoE | **Costo**: 70 MP | **CD**: 120s | **Cast**: 2s (nombre visible, pose JJK)
- **Rango**: `AOE_LARGE` (10m radio alrededor del caster)
- **Fórmula**: `magic_v2(200, weapon_dmg*2, INT, level, 1.5)` impacto único
- **Lvl 5**: radio `AOE_HUGE` 12m
- **Lvl 10**: aplica `Burn` 4s a todos los impactados
- **Lvl 15**: tras la explosión deja zona arcana 5s (tick 5% base/s). **Forma base — cap**.
- **Evolución (+ ítem *Colapso Estelar* boss P100)**: segunda explosión 2s después, 50% del daño, doble radio.

---

## 4. Rama Elementalista (char lvl 25+)

### E1 — Maestría Elemental (pasiva única)
- **Tags**: `[passive][elemental]`
- **Desbloqueo**: al elegir rama Elementalista lvl 25. Elegís sub-elemento fijo (Fuego / Hielo / Rayo).
- **Efecto base**: +30% dmg del sub-elemento permanente en todas las skills. Cambiar requiere Tomo del Renacer.
- **Integración con skills generales**:
  - Bolita aplica el sub-elemento (Fuego → `Burn`, Hielo → `Freeze` 1s, Rayo → chain a 2 enemigos 50% dmg)
  - Tormenta es del sub-elemento, tick +20% si el target ya tiene el debuff
  - Barrera aplica el status al atacante que la rompe
  - Supernova del sub-elemento, daño +25%
- **Lvl 5-15**: cada lvl +2% dmg del sub-elemento (cap +30% base +28% = +58% a lvl 15)

### E2 — Furia Elemental
Activa enfocada de rama.

- **Tags**: `[magic][elemental][focus]`
- **Desbloqueo**: rama Elementalista lvl 30 (requiere Bastón)
- **Tipo**: activa elemental | **Costo**: 30 MP | **CD**: 10s | **Cast**: 0.5s | **Rango**: `LINE_PIERCE` 12m
- **Fórmula base**: `magic_v2(45, weapon_dmg*1.5, INT, level, 1.5)`
- **Efecto por elemento**:
  - Fuego: `Burn` 6s (DoT `_status_effects.md §2.1`)
  - Hielo: `Freeze` 1.5s + `Slow` 60% 3s post-freeze
  - Rayo: chain a 3 enemigos adicionales (50% dmg cada salto), aplica micro `Stun` 0.3s
- **Lvl 5**: CD 8s
- **Lvl 10**: +45% dmg
- **Lvl 15**: el elemento aplica stack extra (Burn x2, Freeze 2s, Rayo chain 5). **Forma base — cap**.
- **Evolución (+ ítem *Tridente Elemental* boss P50)**: aplica los 3 efectos simultáneos (un solo uso, CD 30s).

### E3 — Armonía Rota (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "aplicar los 3 sub-elementos a un mismo boss".

- **Tags**: `[magic][AoE][tri-elemental]`
- **Trigger quest**: aplicar los 3 sub-elementos a un mismo boss (durante 1 combate)
- **Quest**: *"Armonía Rota"* — biblioteca escondida P55
- **Tipo**: activa AoE | **Costo**: 80 MP | **CD**: 90s | **Cast**: 1.5s | **Rango**: `AOE_LARGE` 10m
- **Efecto base**: detona los 3 elementos simultáneos en el área. Daño **triple** si los enemigos ya tienen los 3 status aplicados: `Burn` + `Freeze` + `Shock`.
- **Fórmula**: `magic_v2(250, 0, INT, level, 1.6)`, ×3 si triple status
- **Lvl 5-15**: dmg base +8%/lvl
- **Lvl 10**: los enemigos que sobreviven reciben `Vulnerable` 8s
- **Lvl 15**: aplica los 3 elementos antes de detonar (ya no requiere pre-setup). **Forma base — cap**.

---

## 5. Rama Arcano (char lvl 25+)

### A1 — Distorsión Espacial (pasiva única)
- **Tags**: `[passive][mobility]`
- **Desbloqueo**: rama Arcano lvl 25
- **Efecto base**: dash teleport 5m cada 12s sin gasto MP. No interrumpe casts.
- **Lvl 5-15**: cada lvl -0.5s CD (cap 5s)
- **Integración**:
  - Bolita curva hacia el target más cercano (homing leve, radio 3m)
  - Tormenta se puede relocar durante canal (mueve centro con crosshair)
  - Barrera teletransporta al caster 6m atrás al romperse
  - Supernova implosión antes de explotar (atrae 5m, luego detona)

### A2 — Manipulación Espacial
- **Tags**: `[magic][utility][tele]`
- **Desbloqueo**: rama Arcano lvl 30 (requiere Tomo)
- **Tipo**: utilidad dual | **Costo**: 20 MP | **CD**: 12s | **Cast**: 0.2s
- **Modos** (toggle pre-cast):
  - **Blink**: teleport 8m dirección mirada, `Invul` 0.2s al llegar
  - **Empuje**: cono 6m, `Knockback` 4m + `Stun` 0.5s
  - **Atracción**: cono 8m, arrastra enemigos 5m hacia vos
- **Lvl 5**: rango +1m en todos modos
- **Lvl 10**: CD 10s
- **Lvl 15**: los 3 modos usables en 1 activación (secuencia rápida). **Forma base — cap**.
- **Evolución (+ ítem *Pliegue Dimensional* Tier IV)**: Blink sin CD primer uso de cada combate.

### A3 — Singularidad (skill oculta ascendencia — quest-gated)
Canon `_system.md §5bis` — trigger "Usar Blink 100 veces sin morir".

- **Tags**: `[magic][AoE][control]`
- **Trigger quest**: usar Blink (A2 modo Blink o A1 pasiva) 100 veces sin morir
- **Quest**: *"El Camino entre Espacios"* — ermitaño P60
- **Tipo**: AoE control | **Costo**: 100 MP | **CD**: 180s | **Cast**: 1s | **Rango**: `AOE_HUGE` 8m (deployable)
- **Efecto base**: crea singularidad en punto objetivo que atrae TODO (enemigos, proyectiles enemigos, ítems del suelo, aliados que quieran entrar), detona 2s después con dmg masivo
- **Fórmula detonación**: `magic_v2(500, 0, INT, level, 1.5)`
- **Lvl 5**: radio atracción 10m
- **Lvl 10**: la detonación aplica `Vulnerable` 10s a sobrevivientes
- **Lvl 15**: durante 2s pre-detonación, proyectiles enemigos redirigidos al centro (no impactan aliados). **Forma base — cap**.

---

## 6. Sinergias coop (resumen — ver `_synergies.md`)

| Con | Combo |
|-----|-------|
| Warrior | Mage Furia Elemental Hielo → enemigos `Freeze` → Warrior Puño de Guerra (L10+) aplica `Shatter` combo (`_status_effects.md §3`) +50% dmg. |
| Archer | Flecha atraviesa Tormenta Arcana → flecha gana elemento. Manipulación Atracción junta enemigos en zona de `AOE_LARGE` Archer. |
| Necromancer | Tormenta + Aura Plaga = enemigos dentro reciben DEF -10% (plaga) + tick mágico = devastación. |
| Cleric Buffer | Aura Resguardo + Barrera Prismática = absorb stackeado + resist cap 80% sobre Mage. |
| Danzante | Danzante stealth + Supernova = Danzante intacto por stealth, Mage limpia área. |

---

## 7. FX visual

- Bolita Inestable: azul-violeta, trail de partículas arcanas, impacto = chispazo (Mago Frieren)
- Tormenta Arcana: rayo continuo canalizado (ya implementado), en Elementalista cambia color según elemento
- Barrera Prismática: hexágonos translúcidos iridiscentes (JJK Domain fragmentado)
- Supernova: pose finger-guns, luego esfera blanca que colapsa en explosión dorada-blanca-violeta
- Furia Elemental: aura del elemento envolviendo bastón
- Armonía Rota: triple vórtice rojo/azul/amarillo convergente, detonación tri-color
- Manipulación: runas flotantes + distorsión visual tipo heat-haze
- Singularidad: esfera negra con anillo de luz distorsionada, horizonte de eventos visible

---

## 8. Tabla rápida — costos y CDs

| Skill | MP | CD | Gate char |
|-------|----|----|-----------|
| Bolita Inestable | 8 | 0.4s | 1 |
| Tormenta Arcana | 20/s | 3s post | 4 |
| Barrera Prismática | 25 | 15s | 8 |
| Supernova (ult) | 70 | 120s | 12 |
| Maestría Elemental (E) | — passive | — | 25 |
| Furia Elemental (E) | 30 | 10s | 30 |
| Armonía Rota (E) | 80 | 90s | 50 + quest |
| Distorsión Espacial (A) | — passive | 12s tele | 25 |
| Manipulación (A) | 20 | 12s | 30 |
| Singularidad (A) | 100 | 180s | 50 + quest |

---

## 9. Deprecated

- XP por uso (curva `50 * 1.4^n` descartada — canon §7 `_system.md`)
- Maestría por drop lvl 6 — reemplazada por evolución lvl 15 + char 50 + ítem
- Modelo "4 fijas + 2 variables" — reemplazado por generales + rama

Nombres originales preservados (Bolita Inestable, Tormenta Arcana, Barrera Prismática, Supernova, Furia Elemental, Manipulación Espacial).

---

*Canon Mage v2.0.*
