# Cross-Class Synergies — Canon

**Versión**: 1.0
**Fecha**: 2026-04-16
**Estado**: Canon. Complementa los 6 per-class docs (`warrior.md`, `mage.md`, `archer.md`, `cleric.md`, `necromancer.md`, `danzante_sombras.md`).
**Depende**: `_system.md` (reglas sistema), `_status_effects.md` (combos §3), per-class docs (skills específicas referenciadas), `balance_v2.md`.
**Audiencia**: Design, Gameplay (implementación de triggers cross-class), Playtest.

---

## 0. Filosofía

**Pilar 2 del GDD — "Sinergias ganan batallas"**. El diseño parte de dos premisas:

1. **Dificultad fija, no escala con jugadores** (pilar 1). En coop, el poder extra sale de **coordinar**, no del headcount.
2. **Cada clase es pieza de máquina**, no un paquete de DPS autocontenido. La clase ideal solo existe cuando hay otra que la amplifica.

Este doc lista las sinergias **concretas y verificables** — cada combo apunta a skills canon por nombre + efecto emergente mecánico. No son sugerencias — son las matemáticas del coop.

---

## 1. Tipos de sinergia

| Tipo | Definición | Ejemplo |
|------|-----------|---------|
| **Status-chain** | Clase A aplica status X, clase B explota X. | Mage `Freeze` → Warrior `Shatter` combo (`_status_effects.md §3`). |
| **Aura-stack** | Buff/debuff persistente de A que multiplica skill de B. | Cleric Aura Resguardo +5% resist cap sobre Warrior Forma del Titán. |
| **Positional** | A crea condición física (agrupar, taunt, stealth); B ejecuta. | Mage Manipulación atrae → Archer Tormenta de Flechas `AOE_HUGE`. |
| **Resource-share** | Skill de A transfiere/genera recurso para B. | Buffer Verso del Guardián + Combo Points → finishers Danzante ×3. |
| **Invul-chain** | A aplica `Invul`/`Shield` a B mientras B castea alto-riesgo. | Warrior Último Bastión + Necromancer Rito del Abismo (2.5s cast). |

---

## 2. Matriz cross-class (6×6 — 15 pares únicos)

Cada celda lista **el combo más fuerte** entre las 2 clases. Detalles numéricos en §3.

|        | Warrior | Mage | Archer | Necromancer | Cleric | Danzante |
|--------|---------|------|--------|-------------|--------|----------|
| **Warrior** | — | Shatter (Mage Freeze + Puño L15) | Marked+Embestida crit | Invocaciones taunt con Grito | Buffer+Titán inmortal | Grito+Fear habilita backstab |
| **Mage** | — | — | Elemento en flecha via Tormenta | Tormenta sobre Plague (AoE-DEF-shred) | Buffer+Barrera absorb stack | Supernova+Danza (invul chain) |
| **Archer** | — | — | — | Ojo Verdadero + Aura Plaga armor pierce | Buffer Verso +DMG en ventana 8s | Marked+backstab true dmg |
| **Necromancer** | — | — | — | — | Aura Resguardo aplica a invocaciones | Marked+invocaciones prioritize target |
| **Cleric** | — | — | — | — | — | Sanador heal rápido compensa HP bajo |
| **Danzante** | — | — | — | — | — | — |

---

## 3. Combos concretos (15 combos, mínimo 5 — sobrelimitado para riqueza)

### Combo #1 — Shatter dual Mage + Warrior
**Clases**: Mage Elementalista Hielo + Warrior (cualquier rama)
**Cadena**:
1. Mage cast `Furia Elemental` (Hielo) → aplica `Freeze` 1.5s sobre target tier ≤ Veterano
2. Warrior en ventana `Freeze` cast `Puño de Guerra` L10+ (knockback 2m)
3. Sistema detecta `Shatter` combo (`_status_effects.md §3` — Frozen + golpe físico ≥100 dmg)

**Resultado mecánico**: **+50% dmg al golpe**, freeze removido, VFX cristal explotando. Aumenta hit efectivo del Warrior ×1.5 en el primer hit post-freeze.

**Gate**: Mage lvl 25 (rama Elementalista) + Warrior cualquiera + target no-boss (boss resist freeze cap 25%).

---

### Combo #2 — Buffer Inmortal (Cleric + Warrior Berserker)
**Clases**: Cleric Buffer + Warrior rama Berserker
**Cadena**:
1. Cleric Buffer pasiva **Aura de Resguardo** activa (cap resist 75% → 80%, canon balance_v2 §2.6)
2. Cleric cast `Verso del Guardián` sobre Warrior → +20% DMG + 10% resist cap stackeable (Warrior llega a **90%** resist cap mientras el Verso dura)
3. Warrior cast `Forma del Titán` → +50% DEF, inmune `Knockback`/`Stun`/`Fear`, +50% DMG
4. Warrior con evolución `Titán Inmortal` → revive 1× si muere durante buff

**Resultado**: Warrior con 90% resist cap + 50% DEF + `Empower` +20% DMG Cleric + 1 revive. Tanque-DPS híbrido que **no puede morir** salvo boss-mechanic específico.

**Gate**: Cleric lvl 25 (Buffer) + Warrior lvl 30 (Berserker, `Forma del Titán`). Evolución opcional lvl 50+ítem.

---

### Combo #3 — Archer Armor-Pierce (Necromancer + Archer Ranger)
**Clases**: Necromancer Maldiciones + Archer Ranger
**Cadena**:
1. Necro pasiva **Aura de Plaga** activa (-10% DEF enemigos en 5m, canon)
2. Necro cast `Maldición Marchita` L10 sobre target (`-20% DEF` adicional durante 8s)
3. Archer rama Ranger pasiva **Ojo del Águila** (+15% crit, +25% si >15m)
4. Archer quest-skill **Ojo Verdadero** (ignora `armor_reduction`, crit ×4.0 si headshot)

**Resultado**: armor_reduction del target cae a ~0% efectivo. Target con DEF 500 vs Archer lvl 50 (armor mult 50% baseline) → post-plague+marchita tiene DEF efectiva ~230 → post-Ojo Verdadero armor ignorado total. **Dmg multiplier teórico ×6-8** sobre hit normal.

**Gate**: Necro lvl 25 (Maldiciones) + Archer lvl 50 + quest "Ojo Verdadero".

---

### Combo #4 — Danza Invul Chain (Mage + Danzante)
**Clases**: Mage (cualquier rama) + Danzante (cualquier rama)
**Cadena**:
1. Danzante cast `Danza de Mil Sombras` (Invul 4s + 20 cortes `AOE_LARGE` 8m)
2. Mage en ventana invul cast `Arte Arcano: Supernova` (AoE 10m, 2s cast)
3. Supernova detona durante Danza invul

**Resultado**: Danzante absorbe 0 dmg Supernova (Invul), enemigos en el overlap reciben **Danza (20 cortes) + Supernova (magic_v2(200)) simultáneo**. Max DPS burst cross-class posible en el juego.

**Gate**: Danzante lvl 12 + Mage lvl 12. Ambos disponibles desde prototipo fase.

---

### Combo #5 — Agrupar-Ejecutar (Mage Arcano + Archer Artillero)
**Clases**: Mage Arcano + Archer Artillero
**Cadena**:
1. Mage rama Arcano `Manipulación Espacial` modo **Atracción** (cono 8m, arrastra enemigos 5m hacia centro)
2. Archer Artillero `Proyectil Explosivo` L15 (sticky, detona 1s después, `AOE_MEDIUM` 5m con fragmentación)

**Resultado**: 3-5 enemigos agrupados en punto central → detonación explosiva + fragmentación = **cobertura AoE completa single-cast**. Sin agrupar, la fragmentación raramente hitea >2 enemigos.

**Gate**: Mage lvl 30 (Arcano) + Archer lvl 30 (Artillero).

---

### Combo #6 — Cursed Undead (Necromancer + Cleric Exorcista)
**Anti-sinergia documentada** — requiere coordinación explícita.

**Clases**: Necromancer Creador + Cleric Exorcista
**Problema**: Cleric Exorcista pasiva **Luz Sagrada** hace +50% dmg a undead/void. Las invocaciones del Necro **son undead**.

**Mitigación**:
- Cleric Exorcista debe evitar Círculo Sagrado en radio de invocaciones del Necro
- Cleric cambiar a rama Sanador o Buffer si coop Necromancer es común
- UI avisa con ícono warning cuando Exorcista + Necro en mismo party

**Resultado si no se coordina**: Necro pierde invocaciones al ritmo de kill de Exorcista. Party pierde DPS y utility.

**Canon**: documentado como caso de **coord-is-power** pilar 2 GDD — a veces el poder es saber **qué NO hacer**.

---

### Combo #7 — Stealth Party Full (Danzante Trickster + Archer)
**Clases**: Danzante Trickster + Archer
**Cadena**:
1. Danzante cast `Velo Nocturno` (stealth 6s + velocidad +20%)
2. Archer cast `Voltereta Evasiva` L15 (al terminar libera flechas 360°)
3. Ambos dashean juntos → Danzante clon falso + Archer afterimage

**Resultado**: ambos invisibles 1-2s + flechas 360° descargan desde posición ambigua. **Positional confusion máxima** sobre enemigos tier B+.

**Gate**: Danzante lvl 8 + Archer lvl 8. Ambos early-prototype accesibles.

---

### Combo #8 — Plague Land Zone (Necromancer + Mage)
**Clases**: Necromancer Maldiciones + Mage (cualquier rama)
**Cadena**:
1. Necro cast `Aliento de Plaga` sobre grupo (`AOE_SMALL` cono, `Plague` 8s DoT + `Weak`)
2. Mage cast `Tormenta Arcana` sobre el mismo grupo (tick 0.25s)
3. Un enemigo muere con `Plague` activa dentro de Tormenta

**Resultado**: `Plagued Land` combo (`_status_effects.md §3`) — la plaga se propaga al **doble del radio** normal. Reacción en cadena si hay densidad alta. El Mage mantiene la Tormenta → ticks + propagación escalan exponencial.

**Gate**: Necro lvl 30 (Aliento de Plaga rama Maldiciones) + Mage lvl 4 (Tormenta Arcana general).

---

### Combo #9 — Warrior Taunt + Danzante Backstab
**Clases**: Warrior Tank + Danzante Sombra
**Cadena**:
1. Warrior rama Tank `Escudo Vengador` → aplica `Taunt` 3-4s a enemigos en cono 90°
2. Enemigos tauntados giran a pegarle al Warrior, dejando espalda expuesta
3. Danzante rama Sombra cast `Corte Fugaz` cadena → build Combo Points con crit bonus `Golpe Letal`

**Resultado**: Danzante ejecuta cadena con crit mult ×2.75 (Golpe Letal) sin riesgo — enemigos no pueden girarse por `Taunt` hasta que expire. 3 hits cadena × ×2.75 crit en ventana de 3s = **burst single-target sostenido**.

**Gate**: Warrior lvl 30 (Tank Escudo Vengador) + Danzante lvl 25 (Sombra Golpe Letal).

---

### Combo #10 — Rito Cast-Protect (Cleric Buffer + Necromancer)
**Clases**: Cleric Buffer + Necromancer
**Cadena**:
1. Necro prepara cast `Rito del Abismo` (cast 2.5s, vulnerable)
2. Cleric cast `Égida Divina` sobre Necro (Shield + 30% DEF, 8s)
3. Necro completa cast sin interrupts gracias al Shield

**Resultado**: Rito del Abismo completa sin romperse por 1-2 golpes enemigos que habrían interrumpido el cast. Habilita ultimate AoE 300 dmg magic_v2 sin riesgo.

**Variante con quest-skill**: si Cleric Buffer tiene `El Guardián Silencioso` activo (quest lvl 50+), Necro es **inmune a golpe letal** durante el cast.

**Gate**: Cleric lvl 12 (Égida) + Necro lvl 12 (Rito). Quest-variant lvl 50+.

---

### Combo #11 — Mage Arcano Homing + Warrior Cleave
**Clases**: Mage Arcano + Warrior Berserker
**Cadena**:
1. Warrior cast `Giro de Espada` (AoE `AOE_SMALL` 3m)
2. Mage Arcano cast `Bolita Inestable` con integración rama A1 (**homing leve** hacia target más cercano)
3. Los enemigos sobrevivientes del giro son identificados como "target más cercano" del Mage

**Resultado**: las bolitas del Mage rematan automáticamente los sobrevivientes del giro sin que el Mage tenga que apuntar. Limpia zona post-AoE eficientemente.

**Gate**: Mage lvl 25 (Arcano pasiva A1) + Warrior lvl 25 (Berserker Giro de Espada).

---

### Combo #12 — Séquito Tanks + Archer Positioning
**Clases**: Necromancer Creador + Archer
**Cadena**:
1. Necro cast `Llamar Esqueleto` x2-3 (hasta pasiva Séquito = 3 invocaciones)
2. Necro cast `Pacto de Invocación` → invocaciones `Taunt` pulse cada 1s
3. Archer mantiene distancia óptima (pasiva Ranger +25% crit a >15m)

**Resultado**: invocaciones tanquean y tauntean, Archer opera desde distancia sin presión melee. **Comp idoniao 2-player boss encounter**: esqueletos mueren, Necro reinvoca, Archer hace DPS sostenido.

**Gate**: Necro lvl 25 (Creador Séquito) + Archer lvl 4 (DEX scaling).

---

### Combo #13 — Cleric Plegaria Protected
**Clases**: Cleric (cualquier) + Warrior Tank
**Cadena**:
1. Cleric cast `Plegaria` (canal 3s estacionario para regen 15 Fe, interrumpible)
2. Warrior cast `Grito de Guerra` (aura 10m — aliados +15% DMG + enemigos `Weak`/`Fear` L15)
3. El Cleric está en el aura, enemigos con `Fear` huyen

**Resultado**: Cleric canalea Plegaria sin interrupts porque los enemigos en rango están huyendo (Fear) o con -25% DMG (Weak). Fe regenerada permite castear `Juicio Sagrado` más frecuente.

**Gate**: Cleric lvl 4 (Plegaria) + Warrior lvl 8 (Grito de Guerra). **Early-game viable**.

---

### Combo #14 — Vulnerable Burst (Necromancer + Danzante)
**Clases**: Necromancer Maldiciones + Danzante (cualquier rama)
**Cadena**:
1. Necro cast `Rito del Abismo` modo **Marca de Muerte** (`Vulnerable` 8s al detonar si el target sobrevive)
2. Danzante espera la detonación
3. Cuando `Vulnerable` aplica, Danzante cast `Flor de Sangre` con 5 Combo Points (mult ×3.0)

**Resultado**: `Vulnerable Strike` combo (`_status_effects.md §3`) — crit +50% adicional sobre crit normal. `Flor de Sangre` con Combo 5 + Vulnerable + crit Sombra × 2.75 = **burst anti-boss teórico máximo single-target**.

**Gate**: Necro lvl 12 (Rito) + Danzante lvl 30 (Flor de Sangre rama Sombra).

---

### Combo #15 — Full Party Zone Control (5-6 clases)
**Clases**: party completo (4-6 jugadores)
**Cadena** (secuencial coop, timing estricto):
1. Warrior Tank cast `Escudo Vengador` → taunt grupo enemigos
2. Mage Arcano cast `Singularidad` (quest-skill, atrae TODO 2s antes de detonar)
3. Necromancer cast `Aliento de Plaga` + `Maldición Marchita` → `Plague` + DEF shred
4. Archer Artillero cast `Ingeniería del Caos` → 5 cargas explosivas en el área
5. Cleric Buffer `Verso del Guardián` sobre party → +20% DMG
6. Danzante cast `Danza de Mil Sombras` cuando detona Singularidad

**Resultado**: todos los enemigos agrupados + taunt + armor shred + status stack + buff party + ult burst Danzante + Singularidad magic_v2(500). **Wipe teórico** de wave completa tier B+. **Ventana de ejecución**: ~4-5s desde Singularidad cast hasta Danza termina.

**Gate**: party completo, 4 de los 6 miembros lvl 50+ quest-skills (Singularidad, Ingeniería del Caos, quest de clase). Endgame execution.

---

## 4. Sinergias con status combos (`_status_effects.md §3`)

Combos que requieren que **status se encadenen**, no skills. Clases ideales:

| Combo status | Clase que aplica primer status | Clase que completa |
|--------------|-------------------------------|-------------------|
| **Shatter** (Frozen + hit físico ≥100) | Mage Elementalista Hielo | Warrior / Archer / Danzante |
| **Ignite** (Burn x2 refresh) | Mage Elementalista Fuego | Mage mismo (re-Furia Elemental Fuego) |
| **Electrocute** (Wet + shock) | Mage Elementalista Rayo | — (requiere evento acuático) |
| **Bleeding Frenzy** (Bleed x3 + crit) | Danzante Sombra | Danzante mismo / Archer Ranger |
| **Plagued Land** (Plague expire + Tormenta) | Necro Maldiciones | Mage |
| **Vulnerable Strike** (Vulnerable + crit) | Necro Rito Marca | Danzante / Archer |

---

## 5. Party comps recomendadas

Comps balanceadas para distintos escenarios:

### "Clásica 4-player" (prototipo fase 1-5):
- **Warrior Tank** (aggro + absorb)
- **Mage Elementalista** (AoE + status)
- **Archer Ranger** (single DPS distancia)
- **Cleric Sanador** (heals primarios)

### "Anti-boss 5-player":
- Warrior Berserker (boss DPS)
- Mage Arcano (control posición via Manipulación)
- Archer Ranger (Ojo Verdadero quest = armor pierce)
- Cleric Buffer (Verso del Guardián + Aura Resguardo)
- Danzante Sombra (Golpe Letal + Flor de Sangre execute)

### "Farm/AoE 4-player":
- Warrior Berserker (Giro de Espada AoE)
- Mage Elementalista Fuego (Furia Elemental DoT + Tormenta Arcana)
- Necromancer Creador (invocaciones tanquean + multiply DPS)
- Cleric Sanador (sostener el push)

---

## 6. Pendientes

- Playtest de los 15 combos concretos para calibrar multipliers (ej Shatter +50% vs +75%)
- UI spec — cómo indicar al jugador que el combo está disponible (pulso del ícono, tooltip highlight)
- Achievements/títulos por primer trigger de cada combo (hook para `title_tracker.gd`)
- Tests GUT para triggers automáticos de combo (dept Gameplay)
- VFX específico por combo — dept Art

---

*Canon sinergies v1.0. Los 15 combos son el piso mínimo — el diseño espera emergencia de más combos durante playtest. Cualquier combo nuevo se agrega acá primero.*
