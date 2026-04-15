# Drop Ownership — Canon

**Versión**: 1.0
**Fecha**: 2026-04-15
**Estado**: Canon. Regla global cross-bioma/cross-tier.
**Depende**: —
**Referencian**: `p1_economy.md §4`, `p1_loot_table.md §0`, futuros docs de loot por piso.
**Audiencia**: dept Gameplay (implementación spawner/pickup), dept UI (indicadores ownership), dept Design (futuras tablas de loot).

---

## 0. Filosofía

Modelo inspirado en **Metin2**: el drop pertenece al que **contribuyó al kill**, por una ventana de tiempo limitada. Pasado el timer, se libera para cualquiera.

Objetivo: evitar loot-grief sin romper la tesis coop. Un jugador que farmea solo en una arena multiplayer no pierde su loot por randoms que pasan cerca. Un jugador que participa de un kill colectivo tiene derecho a intentar rolar por el drop.

**Frase-ley**: *"Suerte de run = suerte tuya. Items de evento/ritual = bind-on-drop."*

---

## 1. Regla de ownership

### 1.1 Quién es owner

Al morir un enemigo, el sistema calcula **participantes válidos del kill**:

- Contribuidor ≥ 10% del HP máximo del mob (damage dealt threshold).
- O healer/buffer que aplicó support activo al grupo durante la pelea (ver §4 edge cases).
- Todos los participantes válidos entran a la pool de owners.

### 1.2 Round-robin damage split

Cuando hay múltiples owners, los drops se reparten **round-robin ponderado por % damage dealt**:

1. Ordenar participantes por % damage (descendente).
2. Item 1 → primer jugador (top damage).
3. Item 2 → segundo (next damage).
4. Si un mob dropea N items y hay M jugadores con N > M → vuelve al inicio ponderando por % damage restante.

**Ejemplo**: 3 jugadores, mob dropea 2 items. J1 (60% dmg), J2 (30%), J3 (10%).
- Item 1 → J1.
- Item 2 → J2.
- J3 queda sin drop este kill. Round-robin se resetea por kill, NO persiste.

**Excepción support**: si hay un healer/buffer flagged como "participante activo support", se le asigna el item de menor valor (Common antes que Rare) solo si quedó fuera del round-robin damage. Soft-pity — evita que el Cleric farmee 0 drops en 3 horas.

### 1.3 Timer de ownership

Cada drop nace con **timer 2 minutos (120s)**.

| Fase | Duración | Quién puede lootear |
|------|----------|---------------------|
| **Locked** | 0-120s | Solo el owner asignado por round-robin |
| **Free** | 120s+ | Cualquier jugador. Visual: el drop empieza a parpadear al seg 90 (warning 30s). |

Durante locked, otros jugadores ven el drop pero con **indicador visual "owned"** (ej. outline del color del owner). No pueden interactuar.

### 1.4 Despawn

Drop despawnea a los **10 minutos** desde spawn. Después del fase Free (120s-600s) el item es libre para cualquiera; pasados los 600s, desaparece del mundo.

**Excepción chest**: contenido de chest NO tiene timer — se asigna al momento de apertura via round-robin (el que abre el chest es el "top damage" del evento de apertura).

---

## 2. Dispersión radial al dropear

Al morir el mob y resolverse el drop:

- **Posición base**: centro de masa del mob (collision shape center).
- **Dispersión**: cada item se desplaza aleatoriamente **1-2m** en un círculo horizontal alrededor del centro.
- **Altura**: arc parabólico breve (0.5s airtime, peak +0.6m) antes de caer al suelo.

**Razón**:
1. Evita "pila invisible" de 5 items en el mismo pixel — distinguir cada uno visualmente.
2. Feeling de "explosión de loot" — satisfacción visceral al kill.
3. Permite pickup selectivo con cursor (agacharse con Ctrl + E sobre el item que querés).

**Colisión**: los drops usan physics layer separada para no empujarse entre sí ni colisionar con el player. Caen al suelo (layer World) y quedan.

---

## 3. Bind-on-drop

Algunos items ignoran round-robin y se asignan **directamente a un jugador específico**.

### 3.1 Reglas bind-on-drop

Un item con flag `bind_on_drop = TRUE`:

1. Se asigna al **único jugador que cumplió la condición trigger** (no al top damage).
2. **Solo ese jugador lo ve** — otros ven un shimmer visual pero no pueden interactuar nunca.
3. **No tiene timer libre** — persiste hasta que el owner lo levanta o haga despawn natural (600s).
4. **No es tradeable** en esa run. Post-run en taverna puede convertirse en tradeable según el item específico.

### 3.2 Cuándo aplica bind-on-drop

- **Items de evento/ritual**: Corona Oxidada (bandit leader kill épico), Asta Antigua (primera interacción con el pet del altar), Pluma del Grifo.
- **Quest items**: Pergamino Sellado del Cazador, Diario del Peregrino, notas lore únicas.
- **Drops únicos de Veteranos**: items con nombre propio ("del Cicatrizado") van al jugador que dio el último hit al Veterano (no round-robin).
- **First-kill rewards**: primera vez que un jugador mata un tipo de mob en su cuenta, drop flag personal (cosmético pequeño).

**Frase-ley**: *"Suerte de run = suerte tuya."* Si rolaste mal esta run, rolás mejor la próxima — pero el item-evento que solo sale cuando matás al bandit leader épicamente es tuyo, nadie te lo roba.

---

## 4. Edge cases

### 4.1 Jugador desconecta mid-kill
- Si el jugador iba a ser owner del drop pero se desconectó antes del death event: el drop va al **siguiente en round-robin**.
- Si reconecta <60s: el drop NO se le reasigna (ya se resolvió). Su turno vuelve al próximo kill.

### 4.2 Mob muere por DoT sin atacante cercano
- DoT aplicado por jugador X cuenta como su damage aunque esté lejos. Owner correcto.
- Si el DoT fue de una skill de otro jugador (ej. Necromancer curse que causó bleed) → el caster del DoT es el damage dealer.

### 4.3 Kill por ambiente (caer a lava, trap)
- No hay owner válido por damage → drop pasa inmediatamente a fase **Free** (no hay locked window).
- Excepción bind-on-drop sigue aplicando (ej. trap triggereado por jugador X → X owner).

### 4.4 Healer/buffer sin damage
- Si aplicó ≥1 heal o buff al grupo en los últimos 10s antes del kill → se agrega a round-robin como "support participant".
- Recibe soft-pity: drop de menor valor si quedó fuera del reparto damage.

### 4.5 Kill simultáneo (mob muere por 2+ hits en <100ms)
- Todos los hits cuentan normal. Round-robin por % damage total del combate, no por "last hit".
- Last hit no tiene weight especial (anti-kill-steal).

### 4.6 Mob split (King Slime → mini_slimes)
- Cada mini_slime es un kill independiente. Damage dealt se trackea desde el momento del split.
- No hay "inherit damage del padre" — si solo atacaste al King Slime pero no a los mini, no sos owner de sus drops.

### 4.7 Owner al máximo de inventario
- Drop sigue spawneado en el mundo (dispersión normal), flagged para owner.
- Si al owner no le cabe, al pasar el timer 120s cualquiera lo puede tomar (fase Free estándar).
- Sin queue de "loot auto" — el jugador debe gestionar su inventario.

### 4.8 PvP futuro (fuera scope P1)
- Si se habilita PvP en taverna/arenas especiales: damage del PvP NO cuenta para ownership de mobs.
- Detalle diferido a doc PvP.

---

## 5. Feedback visual y audio

| Estado | Visual | Audio |
|--------|--------|-------|
| Drop spawneado locked | Outline color del owner, nombre flotante sutil | "pop" leve al caer |
| Drop locked visto por no-owner | Outline gris, tooltip "propiedad de {owner}" al hover | (silencio) |
| Transición a Free (seg 90-120) | Outline empieza a parpadear | Tick suave cada 5s últimos 30s |
| Drop Free | Sin outline, interactuable por todos | — |
| Bind-on-drop visto por no-owner | Shimmer dorado translúcido, sin tooltip | (silencio) |
| Pickup exitoso | Flash del color raridad | "chime" según raridad |

---

## 6. Implementación — notas para dept Gameplay

No es código, solo pointers. El apply lo hace B cuando corresponda.

- `DropSpawner.spawn_drops(mob, damage_log)` — recibe damage log (dict `{player_id: dmg_dealt}`).
- Ownership se resuelve en este call. Cada `Drop` node se crea con `owner_id` y `locked_until` timestamps.
- `Drop._can_interact(player)` → chequea `bind_on_drop`, `owner_id`, `locked_until`.
- Indicador visual = shader outline con uniform `owner_color` (material shared entre drops).
- UI HUD: icono pequeño "pending drops" arriba-derecha con count + timer restante.

---

## 7. Decisiones tomadas (registro)

| Decisión | Fecha | Razón |
|----------|-------|-------|
| Timer 120s (2 min) para locked phase | 2026-04-15 | Match Metin2 sensation. Suficiente para player terminar pelea + caminar a loot. |
| Threshold 10% damage para owner válido | 2026-04-15 | Filtra a "contributor real". 5% era muy laxo, 20% castigaba classes support. |
| Despawn 10 min total | 2026-04-15 | Evita clutter en arenas procedurales. Forzar decisión "ahora o nunca" post-kill. |
| Round-robin reset por kill | 2026-04-15 | No persistir un "anti-pity" entre mobs distintos — complejidad sin feel. |
| Dispersión 1-2m | 2026-04-15 | Suficiente para distinguir drops, no tanto que pierdas uno bajo una textura. |
| Bind-on-drop como flag del item, no del mob | 2026-04-15 | Un mob puede dropear items bind y items round-robin en el mismo kill (ej. bandit leader dropea Corona bind + gear normal). |

---

## 8. Pendientes

- Definir `bind_on_drop` en el schema de `item_definition` cuando B cree el script.
- Tradeable state post-run (items bind-on-drop en taverna): decidir si se unbindea al llegar a taverna o queda bind forever.
- PvP ownership (diferido).
- Behavior en Mercado Ámbar / trading peer-to-peer (fuera scope P1).
