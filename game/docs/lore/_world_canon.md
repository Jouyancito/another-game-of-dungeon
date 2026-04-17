# World Canon — Dungeon Party

**Versión**: 2.0 — revert esencia chilena central + mantener estructura canon (tono misterio>mal, Necro excepción dark, discovery>slay, tono prohibido)
**Fecha**: 2026-04-17
**Estado**: Canon central. Los 6 `_class_lore_*.md` linkean aquí.
**Depende**: GDD_DungeonParty.md (pilares + estructura), `_class_lore_*.md` (identidad per-clase), `_system.md` (skills canon).
**Referenciado por**: los 6 `_class_lore_*.md`, futuros docs de bioma/quest/NPC/bestiario.
**Audiencia**: Design (cualquier lore doc nuevo), Art (paleta + referencias), UI (textos, NPCs, títulos), Story (quests futuras).

---

## §1. Filosofía del tono — Misterio > Mal

La Torre de Dungeon Party es **un enigma**, no el foco del mal cósmico. Los jugadores **suben a descubrir**, no a exterminar.

**Principios del tono**:
- **Asombro antes que horror**. Cada piso propone algo nuevo que entender, no algo que odiar.
- **Peligro fundamentado, no arbitrario**. Los enemigos tienen razones (territorio, hambre, costumbre, instrucción antigua). No hay "maldad genérica".
- **Discovery > Slay**. Matar es necesario pero nunca el punto. El punto es **saber qué estaba ahí**.
- **Pequeñas victorias**. Un run exitoso no salva el mundo — mapea otro pedazo de la torre, trae loot, deja una marca. Eso es suficiente.

**Lo prohibido** (ver §7 lista completa): body horror gratuito, Lovecraftiana cósmica, chosen-one trope, cruzada bien-vs-mal genérica, destruir-el-mal como motor narrativo.

**La excepción**: el **Necromancer** (ver §4) es el único alineamiento **claramente oscuro** dentro del tono misterio. Su presencia **confirma la regla**, no la rompe.

---

## §2. La Torre — enigma sin dueño

La Torre **existe antes de toda memoria registrada**. Nadie recuerda quién la construyó. Nadie la hereda. Está ahí.

**Canon estructural**:
- Cada piso es **portal dimensional** (consistente GDD §3). El piso no está "en la torre" — el piso **es** otra capa de realidad que la torre **conecta**.
- Los mundos de los pisos tienen leyes propias (el piso 5 GDD dice "las reglas del juego se alteran" — canon).
- La torre **cambia sutilmente entre runs** (semilla por host canon GDD §8.1, pero además: algunos detalles no son reproducibles — canon narrativo, no mecánico).
- Subir la torre **no tiene una recompensa final conocida**. Los que llegaron al piso 50+ cuentan cosas contradictorias. Los que llegaron al 100, si es que existe, no volvieron a contar nada.

**Lo que la torre NO es**:
- No es **mal cósmico** (ni Ancient Evil, ni Dark Lord, ni Lovecraft)
- No es **prueba divina** (los dioses del Sínodo no la reclaman — §3 Cleric)
- No es **artefacto alienígena** (la torre es familiar al mundo — siempre estuvo)
- No es **prisión** (nadie está encerrado — la torre admite, no captura)

**Lo que la torre podría ser** (canon ambiguo por diseño):
- Un archivo de realidades
- Una escuela que nadie administra
- Un monumento a algo que el reino olvidó
- Todo lo anterior. O ninguno.

**Efecto narrativo**: la ambigüedad de la torre obliga al jugador a **descubrir su propia teoría**, no a recibir la oficial. Diferentes jugadores pueden creer cosas distintas — y ninguno está "equivocado" por canon.

---

## §3. El Gremio de la Torre — institución administradora

El **Gremio de la Torre** es la institución transversal que administra el acceso a la Torre. La **Asesora del Gremio** (GDD §3 NPC cara visible) es su representante en la Taberna.

**Canon del Gremio**:
- Fundado hace ~60 años (recuerdo reciente en el reino).
- **NO es una clase** — es paraguas administrativo.
- Reconoce las **6 órdenes de clase** como proveedores de aventureros legítimos (§5).
- Administra contratos, registros de runs, pagos por kills específicos, permisos por piso.
- Tiene sede en una construcción **anexa a la Torre pero no dentro** (la Taberna es un salón del Gremio ampliado).
- El Gremio **no entra a la Torre** como institución — contrata aventureros de las órdenes.

**Asesora del Gremio**: NPC provider de misiones. Nombre específico canon y personalidad detallada **reservados** — se definen cuando se implemente el NPC (probablemente via dept Story o UI). Por ahora: profesional, paciente, ligeramente cínica por años de recibir aspirantes muertos.

---

## §4. Necromancer = excepción dark canónica

El Necromancer es el único alineamiento **claramente oscuro** dentro del tono general misterio del mundo.

**Por qué la excepción**:
El tono del mundo es misterio + asombro + peligro fundamentado. La manipulación de la muerte — robar el descanso, encadenar almas a un propósito ajeno, tratar al cadáver como herramienta — **rompe el tono aceptable del reino**. No hay manera de "enmarcar elegante" lo que hace el Necromancer: **roba**. El Pacto lo sabe. El Pacto no se justifica.

**Lo que el Necromancer ES**:
- **Dark anti-hero jugable** — el jugador elige el camino oscuro con ojos abiertos.
- Brujo tradicional con disciplina ritual oscura.
- Manipulador **consciente** de tabúes. No ingenuo. No redimible fácilmente.
- Paga con su propia vida (recurso Vida canon) — paga, pero **lo que paga no compensa lo que toma**.

**Lo que el Necromancer NO ES**:
- No es "simplemente otra orden" — es la excepción tonal
- No es Lovecraftian (sigue siendo fantasy medieval, no horror cósmico)
- No es **irredimible por canon** — el jugador puede llevar al Necromancer a arcos narrativos de arrepentimiento, pero la base es dark

**Relación con las otras 5 órdenes**:
- **Cleric Exorcista**: **enemigo natural nuclear**. No tensión doctrinal — **enemistad fundamental**. El Exorcista cree que el Necromancer **debe ser detenido**. El Necromancer cree que el Exorcista **no entiende el precio real**.
- **Otras 4 órdenes**: desconfianza profunda. Las otras órdenes **toleran** al Necromancer solo porque el Gremio lo admite. Si no fuera por el contrato del Gremio, la Orden del Muro los cazaría. La Vigilia los estudia con horror controlado. Los Hijos de la Medianoche **los evitan** (son la única orden que sintió alguna afinidad histórica — ahora: alianza informal difícil, no automática).

**Skill mechanics**: **NO CAMBIAN**. El canon técnico (`_system.md` + `necromancer.md` skill set) se mantiene — 10 skills, recurso Vida, invocaciones, maldiciones, ultimate Rito del Abismo. **Solo cambia el framing narrativo** (Pacto dark real, no academia gris).

---

## §5. Las 6 órdenes — lista canon

| Clase | Orden canon | Lore completo |
|-------|-------------|---------------|
| Warrior | **Orden del Muro Inquebrantable** | `_class_lore_warrior.md` |
| Mage | **Vigilia Arcana** | `_class_lore_mage.md` |
| Archer (Ranger) | **Hermandad de los Vientos Silenciosos** | `_class_lore_archer.md` §2.1 |
| Archer (Artillero) | **Gremio Mecánico de Drennhold** | `_class_lore_archer.md` §2.2 |
| Cleric | **Sínodo de la Tres Luz** | `_class_lore_cleric.md` |
| Necromancer | **Pacto de los Marchitos** — **excepción dark** | `_class_lore_necromancer.md` |
| Danzante | **Hijos de la Medianoche** | `_class_lore_danzante_sombras.md` |

**Una línea por orden** (para UI / selección de clase / tooltip):

- **Warrior (Muro)**: *"El muro que elige quedarse."*
- **Mage (Vigilia)**: *"Los que estudian antes de golpear."*
- **Archer Ranger (Vientos)**: *"El bosque espera. Nosotros también."*
- **Archer Artillero (Drennhold)**: *"Si no prendió, no era el momento."*
- **Cleric (Tres Luz)**: *"Elijo sostener a estos."*
- **Necromancer (Marchitos)**: *"Pagamos con sangre. Ellos con algo peor."*
- **Danzante (Medianoche)**: *"Si me ves, yo decidí que me veas."*

---

## §6. Enemigos — guardianes, habitantes, manifestaciones

Los enemigos de la Torre **no son demonios** por default. Son:

- **Guardianes**: criaturas o espíritus que custodian algo (ruinas, knowledge, objeto). No odian al jugador — ejecutan función.
- **Habitantes**: fauna/cultura propia del piso. Atacan por territorio, hambre, ritual.
- **Manifestaciones**: fenómenos personificados (la tormenta del piso 4, la dimensión rota del piso 5). No son conscientes — son **escenario con voluntad**.

**Excepciones dark canon**:
- **Undead/aberraciones del Pacto de los Marchitos** (Necromancer hostil — NPC o fallido) = **sí son "malos" claros**. Son el escape del tono por excepción.

**Bosses** = misterios encarnados, **no** avatares del mal:
- El boss Piso 1 (Rey Slime) = ecosystem apex, no villano
- Bosses posteriores = entidades con lore propio, no "bad guy" genérico
- Excepción: si un boss es relacionado con el Pacto de los Marchitos → puede ser dark puro (consistente con excepción Necromancer)

---

## §7. Tono prohibido — lista canon

**No hacer en lore de Dungeon Party**:

1. **Body horror gratuito** (sin razón narrativa)
2. **Lovecraftiana cósmica** (no hay "el Viejo Dios Durmiente")
3. **Chosen one trope** (nadie es elegido por profecía — todos eligen su propio camino)
4. **Cruzada bien-vs-mal genérica** (las órdenes no son "buenos vs malos" — son tradiciones distintas)
5. **Destruir el mal** como motor narrativo (el motor es **descubrir**, con peligro)
6. **Prophecy-driven plots** (nadie cumple una profecía para salvar el mundo)
7. **Villanos genéricos sin motivación** (todo enemigo tiene razón, incluso los malos del Pacto)
8. **Edgelord Necro** (el Necromancer es dark real, no dark por estética — tiene código, paga precio, razones reales)

---

## §8. Discovery > Slay — principio canon

Pilar de design del mundo:

- **Achievements priorizan descubrir**: primer glimpse de un piso, primer catálogo de una criatura, primer mapa de una zona oculta. Matar 100 es secundario a **encontrar 1 cosa nueva**.
- **Loot narrativo**: los ítems uniques cuentan historia (origen, dueño anterior, lugar donde apareció).
- **Quests de exploración > quests de matar X**: el Gremio paga mejor por **traer información** que por traer cabezas.
- **Journal canon**: canon implementación `title_tracker.gd` ya establecido (achievement Frieren del mimic). Cada descubrimiento merece entrada en Journal.

---

## §9. La Taberna — zona neutral cross-orden

Canon GDD §3 ampliado:

- **Único lugar del mundo** donde Warriors, Mages, Archers, Clerics, Necromancers y Danzantes **beben en la misma barra sin violencia**.
- **Regla del Gremio**: dentro de la Taberna, ningún conflicto de orden puede escalar. El Gremio **expulsa inmediatamente** a quien viole la regla — y la expulsión es **permanente**.
- **Excepción viva**: el Exorcista y el Necromancer pueden compartir espacio en la Taberna **con silencio cortés**. Pelean en combate, pero en la Taberna no hay sangre. (Esto es la tregua más tensa del lore — respeta el canon del Gremio.)

**Elementos canon de la Taberna**:
- **La Asesora del Gremio** (§3) atiende contratos desde una mesa alta al fondo.
- **El Libro de Retornos del Sínodo** se encuentra en una vitrina pública (cualquier orden puede consultar).
- **El Parlante Musical** (GDD §9.3) existe como objeto decorativo activable.
- **Tradiciones**:
  - Rangers invitan primera ronda, Artilleros la última (`_class_lore_archer.md §2.3`)
  - Warriors + Clerics hacen la *Oración del Muro* en mesa privada 60s antes de run
  - Danzantes tararean música clánica bajo voz
  - Mages llevan su cuaderno a la mesa y siguen trabajando

---

## §10. Naming convention — regla canon

**Naming actual**: fantasy genérico medieval (estilo Witcher / MMORPG clásico). Pronunciable ESP y ENG.

**Lugares canon existentes**:
- Vandrheim (fortaleza caída Warrior)
- Torre de Vigilia (academia Mage)
- Velathir / Boscarredas (bosque Ranger)
- Drennhold (ciudad forja Artillero)
- Catedral de Tres Cúpulas (Cleric)
- Bramastrum (catacumbas Necromancer)

**NPCs legendarios canon existentes**:
- Hrafn el Silente (Warrior)
- Lyssandra del Umbral (Mage Arcano)
- Margrethe la Persistente (Cleric Sanador)
- Orn el Primero (Necromancer fundador)
- Maestro Ghairan (Artillero)
- Torben el Silente (Cleric Exorcista)
- Adrik (hermana muerta de Orn)
- Kestrel (brujo ejemplar Pacto)

**Regla**: nombres fantasy inventados, pronunciables, memorables. No usan referencias a lugares reales que rompan inmersión. Se pueden iterar/renombrar en post-producción sin romper canon (es "solo texto").

---

## §11. Acentos regionales reservados para post-producción

**Decisión canon 2026-04-17**: la identidad cultural del mundo **NO se ancla a una cultura específica** en los nombres de las órdenes. Los nombres son fantasy genérico.

**Sin embargo**, el universo admite **acentos regionales puntuales** en:
- **Biomas específicos** (piso 2 bosque, piso 3 hielo, piso 5 dimensión rota) — el bioma puede tener flavor cultural específico (amazónico, austral, mesoamericano) sin contaminar la identidad general.
- **Criaturas míticas** referenciadas (Imbunche, Caleuche, Alicanto, etc) — como mitos locales citados dentro de un bioma, no como identidad de clase.
- **NPCs secundarios** de un piso específico — pueden tener regionalismos coherentes con el bioma.

**Trabajo reservado para post-producción**: dept Story + dept Design biomas definirán qué flavor cultural específico aplica a cada piso cuando se diseñen a fondo. **No es scope de lore de clases**.

---

## §12. Cross-ref canon

- **Skills system**: `game/docs/skills/_system.md` (10-14 skills/clase, ascendencia lvl 25)
- **Status effects**: `game/docs/skills/_status_effects.md`
- **Sinergias cross-class**: `game/docs/skills/_synergies.md` (15 combos)
- **Balance**: `game/docs/balance_v2.md` (fórmulas compound)
- **Drop ownership**: `game/docs/balance/_drop_ownership_canon.md` (v2)
- **Mimic**: `game/docs/balance/_mimic.md` (canon piso 1, achievement Frieren)
- **Mundo GDD**: `GDD_DungeonParty.md` (pilares + torre + lobby)
- **6 lore docs**: `game/docs/lore/_class_lore_*.md` (identidad per-orden)

---

*Canon mundo v2.0. Naming fantasy genérico. Acentos regionales puntuales reservados para post-producción en biomas específicos. El Necromancer es la única excepción tonal canon — no agregar más excepciones sin decisión explícita del user.*
