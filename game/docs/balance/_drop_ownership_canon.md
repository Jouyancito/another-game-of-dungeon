# Drop Ownership — Canon

**Versión**: 2.0
**Fecha**: 2026-04-16
**Estado**: Canon. Regla global cross-bioma/cross-tier. Reemplaza v1 (2026-04-15) post Judgment Day 2026-04-16.
**Depende**: `_system.md` (party futuro), `p1_economy.md §6`, `p1_loot_table.md §8` (bind items P1).
**Referencian**: `p1_economy.md`, `p1_loot_table.md`, `game/docs/art/drop_vfx.md`, futuras tablas boss.
**Audiencia**: dept Gameplay (implementación `drop_controller.gd`, `party.gd`, `ground_item.gd`), dept UI (indicadores), dept Art (VFX), dept Design (futuras tablas loot).

---

## 0. Filosofía

Modelo **Party-first con fallback Metin2-strict singleplayer**.

- Si el killer está en party → TODA la party comparte el drop (party-auto, sin damage gate, AFK incluido).
- Si el killer está solo → solo el killer es owner (Metin2 clásico).

Objetivo: coop tesis primero, anti-grief segundo. La party decide antes de pelear; dentro de la pelea nadie pelea por loot. Solo-play queda cubierto sin ambigüedad.

**Frase-ley**: *"Tu party, tu botín. Solo, tu kill, tu botín. Eventos/rituales, tu suerte."*

---

## 1. Pool de owners

### 1.1 Entrada al pool

| Contexto | Pool owners |
|----------|-------------|
| Killer en party | **Todos** los miembros vivos + AFK de la party del killer |
| Killer solo (sin party) | Solo el killer |
| Kill por ambiente (lava, trap, caída) | Vacío — drop pasa directo a free-for-all |

**Reglas pool**:
- **Sin damage gate**. No hay threshold mínimo de daño. Entrar a la party = entrar al pool.
- **AFK cuenta**. Miembro conectado pero sin inputs recientes sigue en el pool.
- **Muerto no cuenta**. Miembro party muerto al momento del kill queda fuera del reparto (no fantasma).
- **Support participant** (Cleric/Buffer sin damage): ver §4.

### 1.2 Party system

- `game/shared/systems/party.gd` (autoload, stub 30 líneas) resuelve `get_party(player) -> Array[Player]`.
- Singleplayer: party vacía → pool = [killer].
- Multiplayer (Steam futuro): party formada pre-run en taverna; stub compatible sin refactor.

---

## 2. Reparto — floor + random

Al resolverse un kill, dado `N` drops y `M` miembros en el pool:

1. **Garantizado**: cada miembro recibe `floor(N / M)` drops.
2. **Random**: los `N mod M` drops restantes se sortean aleatoriamente entre los M miembros (sin repetir hasta agotar, luego reset).
3. **Bind items** (ver §5) **NO entran al reparto floor+random**. Se resuelven aparte según su regla de trigger.

### 2.1 Ejemplo numérico

Mob suelta **5 drops**, party **3 miembros** (A, B, C):

- `floor(5/3) = 1` → A, B, C reciben 1 drop cada uno (garantizado).
- `5 mod 3 = 2` → 2 drops sorteados random entre A/B/C. Puede salir AA, AB, BC, CC, etc.
- Resultado posible: A=2, B=2, C=1 (u otras combinaciones).

### 2.2 Reglas del reparto

- **Instantáneo**. Resolución al momento del kill. Sin queue cross-mob.
- **Sin orden por damage**. Damage dealt es **irrelevante** (eliminado canon v1).
- **Sin soft-pity cross-kill**. Cada kill es independiente.
- **Determinismo**: `RandomNumberGenerator` seed por kill (debug reproducible).

---

## 3. Timers

### 3.1 Tabla canónica

| Tipo drop | Owner-lock | Free-for-all | Despawn total |
|-----------|-----------|--------------|---------------|
| **Drop normal** | 180s (0-180s) | 120s (180-300s) | 300s |
| **Bind item** | 300s (0-300s) | — (nunca libera) | 300s |

- **Drop normal**: tras owner-lock, pasa a free. Cualquier jugador puede lootear. A los 300s desaparece.
- **Bind item**: owner-only durante toda su vida. Nunca se libera. Si el owner no lo levanta en 300s, se pierde.

### 3.2 Downed extension (futuro)

Cuando exista downed state (ver backlog global):
- Si al expirar owner-lock el owner está downed → **+120s** extra antes de free-for-all.
- Solo aplica a drops normales. Bind items no extienden (ya son 300s).

Este bloque queda documentado pero **no implementar en P1**.

### 3.3 Visual de timers

Reenviar a `game/docs/art/drop_vfx.md` (dept Art). Resumen:
- Glow color-rareza durante owner-lock.
- Shock ring a los 180s (drop normal) marca transición a free.
- Bind items mantienen glow intensificado hasta despawn.

---

## 4. Support participant

Clerics y Buffers sin damage entran al pool **solo** bajo todas estas condiciones:

| Condición | Regla |
|-----------|-------|
| Party | Debe estar **en la party del killer**. Sin party → no cuenta. |
| Heal / buff aplicado | Debe haber aplicado al menos un heal o buff a **un miembro de la party** en los **últimos 10s** antes del kill. |
| Timestamp válido | El timestamp del heal/buff debe registrarse en el evento (sin log → no cuenta). |

**Sin heal ni buff en los 10s previos** → queda fuera aunque esté en party.

No hay "soft-pity support". Si cumple condiciones, entra al reparto floor+random como cualquier otro miembro.

---

## 5. Bind items P1

Items con flag `bind_on_drop = TRUE`. Ignoran reparto floor+random y se asignan directo al jugador trigger.

### 5.1 Reglas bind

1. Asignado al **jugador que cumplió el trigger específico** (no random, no top damage).
2. **Solo el owner lo ve interactuable**. Resto ve shimmer translúcido.
3. **Timer 300s owner-only**. Nunca pasa a free-for-all.
4. **No tradeable** durante el run. Post-run en taverna según item.

### 5.2 Lista canon P1

Derivada de `p1_loot_table.md §8`:

| Item | Fuente | Trigger del bind |
|------|--------|------------------|
| `emblema_bandido` | bandit_archer / bandit_melee (drop garantizado) | Jugador que dio el killing blow |
| `Corona Oxidada (menor)` | bandit_melee Epic roll (1% efectivo) | Jugador que dio el killing blow |
| Items Veterano (sufijo "del Cicatrizado" / "del Tuerto") | Veteranos sub-A/B/C | Jugador que dio el killing blow al Veterano |
| `Asta Antigua` | Altar POI + interacción | Jugador que triggereó la interacción |
| `Pluma del Grifo` | Evento Grifo (ver `p1_economy.md §6`) | Jugador trigger del evento |
| Quest items (`Pergamino Sellado del Cazador`, `Diario del Peregrino`, notas lore únicas) | Quest spawn | Jugador que completó el quest paso |
| Drops de evento (todos) | Eventos biome | Jugador trigger del evento |
| **`Royal Gel`** | Boss King Slime P24 (fuera scope P1, incluido para canon futuro) | Jugador trigger del último hit al boss |

**Nota Royal Gel**: schema final se define cuando B cree tabla boss P24. Por ahora listado como bind-on-drop canon para que B implemente el flag desde el inicio.

### 5.3 Regla de colisión bind + normal

Un mob puede soltar bind items **y** drops normales en el mismo kill. Ejemplo bandit_melee:
- Drops normales (gear, oro) → floor+random party.
- `emblema_bandido` garantizado → al killing blow (bind).
- `Corona Oxidada` Epic roll → al killing blow (bind).

Los dos sistemas coexisten sin conflicto.

---

## 6. Gold

Drop especial. Reglas propias:

| Regla | Detalle |
|-------|---------|
| Owner | **Ninguno**. Drop global desde spawn. |
| Auto-pickup | **OFF**. Manual pickup por cualquier jugador (en party o no). |
| Split party | Al pickup, si el jugador está en party → split automático **entre miembros vivos de la party**. |
| Pickup Range | Reserva de schema para stat futura MMO "Pickup Range +N". No implementar en P1. |

**Ejemplo**: jugador A (party de 3, uno muerto) levanta 90 oro → 45 oro para A, 45 oro para B (vivo), C muerto no recibe.

---

## 7. Kill por ambiente

Mob muere por daño no-player (lava, trap ambiental, caída).

- **Pool vacío**. Sin killer → sin owners.
- Drop pasa **directo a free-for-all desde spawn**. Sin owner-lock.
- Despawn estándar **300s**.
- **Excepción bind**: si un bind item cae por trap triggereado por jugador X, X es owner del bind (trigger válido). Drops normales siguen siendo free-for-all.

---

## 8. Respawn y persistencia

- Ownership se trackea por **`save_profile_id`** (persistente cross-sesión), **NO** por `instance_id` del player.
- Consecuencia: player muere + reload + R respawn → conserva ownership de drops que siguen en timer.
- Si el player se desconecta (no respawn, sale del run) → ownership queda bloqueado hasta el timer. No se reasigna.

---

## 9. Eliminado de v1 (registro de cambios)

| Regla v1 | Estado v2 | Razón |
|----------|-----------|-------|
| Threshold 10% damage para owner | **ELIMINADO** | Party-first hace irrelevante el damage gate |
| Threshold 60% killer-majority | **ELIMINADO** | Nunca existió formalmente; flagged en Judgment Day |
| Round-robin ponderado por % damage | **ELIMINADO** | Reparto floor+random no requiere orden |
| Round-robin reset por kill | **ELIMINADO** | No hay round-robin — reparto instantáneo |
| Sort por damage dealt | **ELIMINADO** | Floor+random ignora damage completamente |
| Round-robin persist cross-mob | **ELIMINADO** | Sin queue entre kills |
| Soft-pity support (menor valor) | **ELIMINADO** | Support entra al floor+random estándar si cumple §4 |
| Timer 120s lock + 480s free | **REEMPLAZADO** | Ahora 180s lock + 120s free + 300s total |
| Last hit con peso especial | **ELIMINADO (drops normales)** | Mantenido solo para bind items (ver §5.2) |

**Razón global**: Judgment Day 2026-04-16 Round 1 encontró 5 CRITICAL + 3 WARNING. User decidió simplificar canon vs mantener complejidad v1. Metin2-strict-ish con extensiones party-link y support-party-only.

---

## 10. Edge cases

### 10.1 Party se arma mid-kill
- Pool se resuelve **al momento del death event**. Joinear party post-kill no retroactiva.

### 10.2 Party se disuelve mid-kill
- Snapshot del pool se toma al death event. Leavear post-kill no revoca ownership ya asignado.

### 10.3 Mob split (King Slime → mini_slimes)
- Cada mini_slime es kill independiente. Party del killer del mini define su pool.
- No inherit del padre.

### 10.4 Owner con inventario lleno
- Drop permanece spawneado con ownership normal durante el lock.
- Pasado el timer, drop normal → free-for-all; bind → despawnea perdido a los 300s.

### 10.5 Kill simultáneo (hits <100ms)
- Killer = jugador cuyo damage cerró el HP. Determinístico por timestamp.
- Su party define el pool.

### 10.6 DoT killer ausente
- Jugador que aplicó el DoT cuenta como killer aunque esté lejos.
- Su party define el pool.

### 10.7 Killer abandonó party después del tick DoT
- Killer al momento del death event es quien aplicó el hit final (DoT incluido).
- Su party **en ese momento** define el pool.

### 10.8 PvP (fuera scope P1)
- Damage PvP no afecta ownership de mobs. Diferido a doc PvP futuro.

---

## 11. Implementación — pointers dept Gameplay

No es código, pointers. B aplica.

- `DropController.resolve_drops(mob, killer, drops)` — input: killer player + array de drops. Resuelve pool via `party.gd`, reparte floor+random, marca bind.
- `party.gd` autoload — stub: `get_party(player) -> Array`. Singleplayer devuelve `[]`. Multiplayer Steam futuro hookea acá.
- `ground_item.gd` — `owner_save_id` + `locked_until_ts` + `is_bind_on_drop` + `can_pickup(player)`.
- Gold split en pickup handler de `ground_item.gd` (no en spawn).
- Timers configurables `@export` para tuning.

---

## 12. Futuro — fuera scope P1

Reservado. No implementar. Documentado para evitar refactors.

- **Downed extension** (§3.2): +120s lock si owner downed al expirar.
- **Pickup Range stat**: slot de stat MMO para auto-pickup a distancia.
- **Party trading post-run**: unbind de items bind al llegar a taverna (decisión por item).
- **Mercado Ámbar / peer-to-peer trading**: reglas propias, sin canon aún.
- **PvP ownership**: damage PvP no cuenta; diferido.

---

## 13. Decisiones registradas

| Decisión | Fecha | Razón |
|----------|-------|-------|
| Party-first + Metin2-strict fallback singleplayer | 2026-04-16 | Judgment Day decidió simplificar vs v1 |
| Sin damage gate (pool = party completa) | 2026-04-16 | Tesis coop: confianza pre-run, no pelea por loot |
| Floor+random (sin round-robin ni sort damage) | 2026-04-16 | Reparto instantáneo sin complejidad cross-mob |
| Timer 180s lock + 120s free + 300s total | 2026-04-16 | Ventana más amplia vs v1 (120s) — menos fricción coop |
| Bind items 300s owner-only sin free | 2026-04-16 | "Suerte de run = suerte tuya" aplicado estricto |
| AFK incluido en pool | 2026-04-16 | Party pre-run es contrato; no castigar desconexión breve |
| Support solo si en party + heal/buff 10s | 2026-04-16 | Evita free-ride de randoms; requiere contribución verificable |
| Gold sin owner, split party al pickup | 2026-04-16 | Feel MMO clásico; simplicidad de implementación |
| Kill ambiente → free-for-all directo | 2026-04-16 | Sin killer player, sin owner válido |
| Ownership por `save_profile_id` (persistente) | 2026-04-16 | Respawn/reload no pierde ownership |

---

## 14. Pendientes

- Schema `bind_on_drop` + `royal_gel` en tabla boss P24 (dept B, cuando armen boss).
- `game/shared/systems/party.gd` autoload stub (dept B, P1).
- Reescritura `game/docs/art/drop_vfx.md` con timers v2 180/120/300 (dept D, en curso).
- Integración `drop_controller.gd` con `party.gd` (dept B).
- Tradeable state post-run para items bind (decidir por item).
- Documentar regla Pickup Range cuando se cierre canon stats MMO futuro.
