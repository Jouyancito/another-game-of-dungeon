# World References — Canon de Referencias Culturales

**Versión**: 1.0
**Fecha**: 2026-04-17
**Estado**: Canon central de referencias. Fuente única para alinear visión narrativa, visual, jugable y de sistema.
**Depende**: `_world_canon.md` (mundo), `GDD_DungeonParty.md` (pilares + estructura), `_system.md` (skills canon), `_class_lore_*.md` (identidad per-orden).
**Referenciado por**: docs futuros de bioma / bestiario / quest / VFX / coop.
**Audiencia**: Design (tomar decisiones alineadas), Art (VFX + paleta + silhouette), UI (tono), Story (narrativa), Gameplay (coop + progresión + drops).

---

## §1. Filosofía — por qué las referencias importan

Dungeon Party no inventa cada sistema desde cero. Se **para sobre hombros** de obras que ya resolvieron partes del problema — dungeon crawling, coop, gremios, progresión, lore emergente. Este doc centraliza las referencias para:

1. **Alinear visión** entre dept Design, Gameplay, Art, UI, Story. Todos hablan el mismo idioma de refs.
2. **Evitar reinventar**. Si Danmachi ya resolvió "sistema de gremios + familias", lo tomamos y adaptamos.
3. **Comunicar a contributores** (actuales + futuros). Un nuevo miembro lee este doc y entiende **qué cualidades querés** del juego.
4. **Anclar decisiones ambiguas**. *"¿Cómo debería sentirse el momento de encontrar un piso nuevo?"* → "Como Made in Abyss capa 3" > subjetividad.
5. **Filtrar ideas que rompen tono**. Si una propuesta no alinea con Danmachi / Frieren / Hades / etc, se evalúa más estricto.

**Regla guard**: las refs son **inspiración**, no plantillas a copiar. El canon propio (`_world_canon.md`) manda. Las refs guían estética/mecánica/tono, no contenido específico.

---

## §2. Referencia central — Danmachi

**DanMachi** (*Is It Wrong to Try to Pick Up Girls in a Dungeon? / Dungeon ni Deai wo Motomeru no wa Machigatteiru Darō ka*) es la referencia narrativa y estructural más cercana a Dungeon Party. User lo citó explícitamente como ancla del diseño de mazmorras + coop + gremios.

### 2.1 Resumen Danmachi (para contributores nuevos)

- **Setting**: ciudad de **Orario**, construida alrededor del **Dungeon** — una mazmorra vertical de 50+ pisos que desciende bajo la ciudad. Cada piso tiene bioma distinto (caverna, bosque subterráneo, capa cristalizada, niebla). Los pisos profundos son progresivamente más letales.
- **Protagonista**: **Bell Cranel** — aventurero novato de **pelo blanco y ojos rojos**. Su arco es de rookie a héroe (level up visible).
- **Sistema de Familias (Familia)**: grupos de aventureros liderados por un dios/diosa. Cada diosa otorga una **gracia divina** (falna) que da bonificaciones únicas. Familias conocidas: Hestia (Bell), Loki (top tier), Freya, Apollo, Takemikazuchi, Hefesto.
- **Asociación de Aventureros (Guild)**: institución neutral que administra Orario. NO es familia. Emite misiones, tickets de magia, regula conflictos entre familias, organiza torneos.
- **Niveles**: los aventureros tienen grado 1-7 (raro alcanzar 7). El grado sube con "logros extraordinarios" (matar bosses, sobrevivir experiencias imposibles).
- **Falna (gracia divina)**: tatuaje en la espalda otorga status (STR/DEF/AGI/DEX/MAG). Sube con experiencia. Los dioses "actualizan" la falna manualmente tras combates.
- **Monster Feast**: festival anual donde todas las familias cooperan en un encuentro masivo.
- **Tono**: aventura + slice of life (cena en Hogar de la Familia, relaciones entre personajes) + intensidad combate (peligro real, muertes canon de NPCs).
- **Narrativa**: el jugador sigue a Bell + interacciones entre familias + exploración del Dungeon capa por capa. Cada capa tiene **misterios** (habitantes únicos, lore histórico). Los bosses son parte del ecosistema, no villanos.

### 2.2 Mapeo conceptual Danmachi → Dungeon Party

| Danmachi | Dungeon Party | Grado de adopción |
|----------|--------------|------------------|
| Dungeon de Orario (vertical 50+ pisos) | **Torre** (5 pisos MVP → 100 futuro) | **Adoptamos** — estructura vertical es canon GDD §3. |
| Familias (lideradas por dios) | **6 Órdenes** (sin diosas — tradiciones culturales) | **Adaptamos** — función social similar (grupo con identidad), pero **sin panteón de dioses**. Órdenes son históricas, no religiosas. |
| Asociación de Aventureros (Guild) | **Gremio de la Torre** + Asesora del Gremio | **Adoptamos directo** — función idéntica (administrar acceso, contratos, neutralidad). |
| Grados 1-7 con logros extraordinarios | **Niveles 1-50** (GDD canon) + ascendencia lvl 25 | **Adaptamos** — más granular que Danmachi. La ascendencia lvl 25 (`_system.md`) es el equivalente al "upgrade de grado". |
| Falna (tatuaje divino con status) | **Ascendencia lvl 25** (canon skills) | **Adaptamos** — sin ritual divino; en DP la ascendencia es entrenamiento culminado de la orden. |
| Piso con bioma distinto | **5 pisos con mundo distinto** (GDD §3) | **Adoptamos directo** — estructura bioma-por-piso. |
| Monster Feast (evento anual) | **Reservado** — posible evento futuro | **Considerar** — eventos cooperativos cross-orden encaja con pilar 1 GDD (coord es poder). |
| Cooperación + competencia entre familias | **Cooperación Gremio + identidad orden** | **Adaptamos** — DP minimiza competencia explícita entre órdenes; la tensión está en relaciones (Exorcista vs Necro nuclear, etc — ver `_class_lore_*.md §6`). |
| Dungeon genera monstruos orgánicamente | **Pisos con enemigos fijados por bioma** (procedural con semilla) | **NO adoptamos** — DP es menos emergente, más diseñado. |
| Bell pelo blanco / ojos rojos (arquetipo rookie) | **Jugador genérico customizable** | **NO adoptamos** como protagonista único. DP es **party coop**, no "una historia". |
| Dioses interfiriendo en la narrativa | **NO existe canon DP** | **NO adoptamos** — DP tiene Torre como enigma, no dioses activos. |

### 2.3 Qué Danmachi aporta específicamente

- **Sensación de "mazmorra viva como ecosistema"**: los pisos profundos no son solo "harder room" — son **mundos con habitantes** que tienen sentido interno. DP hereda esto (GDD §3 "cada piso es un portal a un mundo diferente").
- **Gremio como institución neutral**: la Asociación de Danmachi es **mediador**, no aventurero. El Gremio de la Torre de DP funciona idéntico.
- **Slice of life en "hogar"**: los aventureros vuelven al Hogar de la Familia entre runs. DP tiene la Taberna (GDD §3) — pero **más cross-orden** (todas las órdenes comparten Taberna, vs familias separadas en Danmachi).
- **Progresión visible**: el grado sube con logros, no solo XP. DP tiene **achievements + quests ocultas** (canon `_system.md §5bis`) — equivalente funcional.

### 2.4 Qué Danmachi NO aporta (lo que evitamos)

- **Pantheon de dioses**. DP no tiene religión con dioses activos. El Sínodo de la Tres Luz es fe, no pantheon.
- **Competencia dramática entre familias**. En Danmachi, familias pueden enfrentarse (Familia Apollo vs Hestia). En DP, el Gremio **prohíbe** conflicto escalable en la Taberna (canon `_world_canon.md §9`).
- **Protagonista único con arco central**. DP es coop, no hay "Bell Cranel" central.
- **Fanservice/tono shonen romance**. DP mantiene tono adulto sobrio (misterio > mal canon).

---

## §3. Referencias secundarias consolidadas

### 3.1 Anime / Manga

#### Frieren (Sousou no Frieren)
- **Aporta**: paciencia académica centenaria del Mage (`_class_lore_mage.md §1`). Achievement "La Suerte de Frieren" para el mimic (canon `_mimic.md §5`). Estética mago-estudiosa serena.
- **Usado en**: Mage (Vigilia Arcana), mimic achievement.

#### JJK (Jujutsu Kaisen)
- **Aporta**: casting dramático con pose + declaración de técnica (Gojo Domain Expansion style). Nombre visible antes del ultimate (canon brief §3 + `mage.md` Supernova).
- **Usado en**: Mage Arte Arcano Supernova, Cleric Juicio Sagrado, Danzante Danza de Mil Sombras, en general VFX de ultimates.

#### Demon Slayer (Kimetsu no Yaiba)
- **Aporta**: Pilares como arquetipos de fervor espiritual con disciplina (Cleric 3 devociones = análogo a los 9 Pilares). Forma del Titán del Warrior inspirada en Gyomei (Pilar de Piedra). Formas rápidas para el Danzante (Uzui Pilar del Sonido, Zenitsu Agatsuma forma rápida).
- **Usado en**: Warrior Forma del Titán, Cleric Sínodo, Danzante Velo Nocturno + Danza.

#### One Piece
- **Aporta**: aesthetic flamboyant, nombres de ataques declarados en combate, pose pre-ultimate. Gear Second vibes para blur de velocidad.
- **Usado en**: Mage Supernova (pose finger-guns + nombre visible), Archer Ráfaga, Warrior Embestida (trail polvo amarillo).

#### Made in Abyss
- **Aporta**: **torre vertical invertida** (abyss descendente vs Torre ascendente de DP — misma estructura simbólica). Biomas por capa con peligro escalante. Narrativa misterio > mal EXTREMO. Atmósfera de "explorar por amor al descubrimiento con costo alto".
- **Usado en**: `crystal_ceiling.md` biomas, tono general, pilar 4 GDD "tu dungeon tu historia".
- **⚠️ FILTRO**: Made in Abyss tiene body horror extremo — NO adoptamos esa parte (canon `_world_canon.md §7` tono prohibido). Solo estética verticalidad + misterio.

#### Berserk
- **Aporta**: combate visceral, lore dark (Griffith / God Hand), pacto con costo irrecuperable. Encaja con Necromancer DARK canon v2.0 (Orn consumió a Adrik = análogo Griffith/Behelit).
- **Usado en**: Necromancer framing dark (`_class_lore_necromancer.md`), combate pesado Warrior Band of the Hawk vibes.

#### Rurouni Kenshin (Shishio Makoto)
- **Aporta**: antagonista carismático con código propio claro. Base para Danzante (código "Yo Elijo" canon `_class_lore_danzante_sombras.md §3`).
- **Usado en**: Danzante personalidad + voz.

#### Bleach (Soi Fon)
- **Aporta**: frialdad + eficiencia + lealtad clánica antes que al Estado. Shunpo (teletransporte corto) visual para Danzante.
- **Usado en**: Danzante Paso de Sombra + Velo Nocturno.

#### Death Note (L moral ambigua)
- **Aporta**: personaje oscuro con fundamento moral propio, no villano caricatura. Refuerza Necromancer DARK como "elección consciente", no "edgelord estético".
- **Usado en**: Necromancer voz + filosofía.

### 3.2 Video Games

#### Diablo 2
- **Aporta**: skill tree estilo ramas + 2 especializaciones por clase (canon GDD §6.2 + `_system.md §1`). 3 stat points por nivel (GDD §6.1). Drops con raridades (Common/Rare/Epic/Legendary canon GDD §6.4).
- **Usado en**: Sistema skills, progresión, loot raridades.

#### Path of Exile
- **Aporta**: drop tables complejas con pool por enemigo, afixes en gear, modifiers stackeables. Issue #23 DP referenciado.
- **Usado en**: `p1_loot_table.md` estructura, afixes futuros.

#### Metin2
- **Aporta**: drop ownership (damage threshold + timer, canon `_drop_ownership_canon.md`), hotbar con 4 loadouts guardados (canon `_system.md §4.2`), enhancement +1 a +9 con chance de romper (canon GDD §6.4).
- **Usado en**: Drop ownership v2, hotbar UI target, enhancement system.

#### Hades (Supergiant)
- **Aporta**: narrativa procedural + NPCs con voz distintiva + runs cortas con progresión permanente + relación NPCs en "base" (análogo Taberna DP). Sensación de "conozco a cada NPC por nombre".
- **Usado en**: Taberna (GDD §3), NPCs de la Asesora del Gremio, sistema de progresión cross-run.
- **Específicamente**: la "base de Hades" (Hogar de Hades entre runs) es el paralelo más cercano a cómo DP quiere que se sienta la Taberna.

#### Vagrant Story
- **Aporta**: combate stat-heavy con números visibles (chain counter, parte del cuerpo targeted). Dungeon vertical con mapa interconectado.
- **Usado en**: ref secundaria para UI combate futura + sensación "cada hit importa".

#### Dark Souls / Elden Ring
- **Aporta**: mundo enigma (lore descubierto por items/NPCs/arquitectura, no expuesto). Bosses como misterios con backstory. Silhouette tanques (Havel the Rock = Warrior).
- **Usado en**: tono misterio > mal canon, bosses canon, Warrior silhouette (Havel), Necromancer estética (Pontiff Sulyvahn + Archdeacon McDonnell), Mage silhouette (Crestfallen Warrior's Mage).

#### Castlevania (Symphony of the Night)
- **Aporta**: arquitectura gótica + mapa interconectado + chapel referenced en DP docs.
- **Usado en**: `crystal_ceiling.md` aesthetic, futuros biomas altos.

#### Bloodborne
- **Aporta**: aristocracia corrompida (Hunter of Hunters + Cainhurst) para Necromancer DARK. Atmósfera de "belleza envuelta en mal".
- **Usado en**: Necromancer aesthetic (`_class_lore_necromancer.md §4`).

#### Ghost of Tsushima
- **Aporta**: transición honor → shadow (Jin post-Ghost). Ref para Danzante de Sombras moralmente ambiguo-orgulloso.
- **Usado en**: Danzante personalidad + silhouette.

#### The Witcher 3
- **Aporta**: naming fantasy inventado con fonética slava (Kaer Morhen, Novigrad), brujas del pantano (Crookback Bog) para Necromancer dark rural.
- **Usado en**: naming fantasy genérico (Vandrheim/Velathir/Drennhold/Bramastrum), Necromancer Brujas del Pantano vibes.

#### Deep Rock Galactic (DRG)
- **Aporta**: **coop fuerte 4-players**, gremio de minería (paralelo estructural al Gremio de la Torre DP), biomas por mission, cooperación mecánica real (cada rol importa).
- **Usado en**: coop 1-6 jugadores DP, Gremio, design de roles complementarios (Warrior tank, Cleric heal, etc).
- **Específicamente**: DRG es la ref más cercana a "4 jugadores en el mismo piso cooperando en roles distintos" que DP quiere lograr.

#### Risk of Rain 2
- **Aporta**: coop hasta 4 con escalado.
- **⚠️ FILTRO**: RoR2 **escala con cantidad de jugadores**. DP **NO** (pilar 1 GDD — coord es poder, dificultad fija). Solo adoptamos "vibe coop", no escalamiento.
- **Usado en**: NINGUNO mecánicamente. Solo referencia visual del "frenesí coop".

#### Stardew Valley
- **Aporta**: calidez slice of life + fauna ambient decorativa. Ya ref en `ambient_fauna.md`.
- **Usado en**: Taberna tono cálido, fauna piso 1 pradera (mariposas, pájaros, conejos).

#### Spiritfarer
- **Aporta**: tono cálido slice of life + narrativa emocional sin melodrama.
- **Usado en**: Taberna tono + despedidas de NPCs (futuro post-producción).

#### Monster Hunter
- **Aporta**: hunting boss + biomas + party 4 (gran ref coop boss). Armor set por boss. Loot por boss.
- **Usado en**: bosses por piso (GDD §3), loot garantizado de boss (GDD §6.4), party 4+ boss encounter design.

#### FFXIV (Final Fantasy XIV)
- **Aporta**: trinity coop (tank/healer/DPS) + raids 8-man + identidad de clase/job marcada. Glamour system (cosmetics).
- **Usado en**: coop roles (DP usa pseudo-trinity), cosmetics canon GDD §9.4.

### 3.3 Mitología chilena (criaturas citables)
Canon `_world_canon.md §11` — reservado para post-producción a nivel bioma, no identidad de clase:

- **Caleuche** (barco fantasma de los ahogados)
- **Imbunche** (criatura deformada por brujo)
- **Trauco** (figura rural opresora, folklore chilote)
- **Pincoya** (sirena de la pesca, folklore chilote)
- **Alicanto** (ave andina que come oro)
- **Camahueto** (criatura andina-chilote)
- **Chonchón** (cabeza voladora, brujería chilota)
- **Peuchén** (serpiente voladora)

**Uso propuesto**: bestiario por piso/bioma (post-producción). NO como orden cultural.

---

## §4. Mapeo aplicado — qué referencia alimenta qué sistema

Tabla de decisión rápida: si diseñás sistema X, consultá ref Y.

| Sistema DP | Referencia principal | Referencia secundaria |
|-----------|---------------------|----------------------|
| **Mazmorra vertical multi-piso** | Danmachi (Dungeon Orario) | Made in Abyss (abyss invertida) |
| **Coop 1-6 jugadores** | Deep Rock Galactic | Danmachi (familias mixed party) |
| **Gremio + NPCs neutrales** | Danmachi (Guild / Asociación) | Hades (NPCs base) |
| **Biomas por piso** | Danmachi (pisos) + Made in Abyss (capas) | Monster Hunter (maps) |
| **Taberna slice of life cross-orden** | Hades (Hogar) | Stardew Valley (calidez) + Danmachi (Hogar Familia) |
| **Skill tree + ascendencia lvl 25** | Diablo 2 (ramas) + `_system.md` canon | Path of Exile (passive tree complexity, futuro) |
| **Drops + ownership** | Metin2 | Path of Exile (loot tables) |
| **Enhancement +1 a +9** | Metin2 | — |
| **Hotbar 4 loadouts** | Metin2 | — |
| **Skills VFX dramáticos** | JJK + Demon Slayer | One Piece |
| **Ultimate con nombre visible** | JJK (Domain Expansion) | One Piece (gear declarations) |
| **Lore dark Necromancer** | Berserk (Griffith) + Bloodborne | Witcher Crookback Bog |
| **Mage académico paciente** | Frieren | Doctor Strange |
| **Danzante nómade orgulloso** | Rurouni Kenshin + Bleach Soi Fon | Ghost of Tsushima |
| **Bosses como misterios** | Dark Souls / Elden Ring | Monster Hunter |
| **Party trinity + roles** | FFXIV | DRG |
| **Achievements + quests ocultas** | Danmachi (grado por logros) + Hades (heat system) | — |
| **Naming fantasy genérico** | Witcher 3 (fonética inventada) | Elden Ring |
| **Atmósfera misterio > mal** | Made in Abyss + Dark Souls | Hades (tragedia sin nihilismo) |
| **Mitología rural oscura** | Chiloé negro (Imbunche/Caleuche) + Witcher Brujas | — |

---

## §5. Tono prohibido reforzado (`_world_canon.md §7` extendido)

Las referencias anteriores se pueden aplicar **selectivamente**. **No adoptamos**:

1. **Body horror gratuito** — aunque Made in Abyss / Bloodborne lo tienen, DP lo evita.
2. **Chosen one trope** — ni Bell de Danmachi, ni protagonistas individuales. DP es coop.
3. **Pantheon de dioses activos** — Danmachi tiene dioses intervencionistas. DP no.
4. **Lovecraftiana cósmica** — no hay "Viejo Dios Durmiente" en DP.
5. **Romance shonen / fanservice** — tono adulto sobrio.
6. **Competencia dramática entre órdenes con muertes** — el Gremio prohíbe conflicto escalable (canon `_world_canon.md §9`).
7. **Protagonista único con arco central** — DP es party coop, no "historia del elegido".
8. **Escalado con cantidad de jugadores** — pilar 1 GDD (dificultad fija).
9. **Edgelord estético Necromancer** — el Necromancer es dark real con código, no "cool dark por verse cool".
10. **Referencias culturales específicas como identidad general** (decisión user 2026-04-17 reversión naming). Solo acentos puntuales en biomas.

---

## §6. Narrativa estilo — qué se siente Dungeon Party

Combinando las referencias anteriores, Dungeon Party debería sentirse como:

**"Danmachi + Deep Rock Galactic + Hades"** — aventura coop en mazmorra vertical + cooperación real de roles + base emocional con NPCs que te reconocen.

**Tono core**:
- **Intensidad combate**: Demon Slayer / JJK — cada ultimate se siente ganado, nombres visibles, pose.
- **Atmósfera exploración**: Made in Abyss / Dark Souls — asombro ante lo desconocido con peligro latente.
- **Slice of life Taberna**: Hades + Stardew Valley — calidez, NPCs memorables, continuidad cross-run.
- **Cooperación mecánica**: DRG + Danmachi — cada rol importa, las sinergias son visibles (canon `_synergies.md` 15 combos).
- **Progresión visible**: Diablo 2 + Danmachi grado — cada run deja huella (loot, XP, achievements, Journal).
- **Lore emergente**: Dark Souls + Danmachi — descubrís el mundo por items, NPCs, ruinas; no por cutscenes expositivas.
- **Dark spot contenido**: Berserk + Chiloé negro — el Necromancer es la única zona oscura del mundo misterio.

**Pilares GDD reforzados por refs**:
- **Coord es poder** → DRG + Danmachi (roles complementarios mecánicos)
- **Sinergias ganan batallas** → Genshin Impact elemental reactions (**ref propuesta C, validar user** — ver §8)
- **Cada run importa** → Hades runs + Danmachi mortalidad de NPCs
- **Tu dungeon tu historia** → Danmachi pisos únicos + Made in Abyss lore emergente
- **Fácil aprender difícil dominar** → Slay the Spire / Hades mechanical depth

---

## §7. Refs propuestas C (validar user)

Estas refs no fueron mencionadas explícitamente por el user, pero C las propone como potencialmente útiles. **Flag pendiente validación**:

1. **Genshin Impact** — elemental reactions (Hydro + Electro = Electrocharged, Pyro + Cryo = Melt, etc). Paralelo directo con status combos DP (canon `_status_effects.md §3` Shatter/Ignite/Plagued Land). Podría inspirar expansión del sistema de combos.
   - **Aporte**: expansión de status combos, UI indicador de reacción lista.
   - **Filtro**: evitar gacha/pull system de Genshin.

2. **Baldur's Gate 3** — party cooperative 4 + class synergies + D&D roots. Muy aplicable al coop + synergies DP.
   - **Aporte**: party 4 coop, reactions en combate (AoO), inspiración dialogue tree.
   - **Filtro**: DP es action no turn-based.

3. **Final Fantasy XIV** — party trinity + raids + glamour cosmetics.
   - **Aporte**: roles coop MMO, cosmetics canon GDD §9.4.
   - Ya incluido en §3.2.

4. **Honkai Star Rail** — turn-based + character synergy.
   - **⚠️ Filtro**: turn-based no aplica a DP action. Solo inspiración de marketing visual.

5. **Slay the Spire** — gameplay loop adictivo con decisiones entre runs.
   - **Aporte**: design de "qué recompensa dar entre pisos" (heal / loot / upgrade).

6. **Vampire Survivors** — gameplay loop adictivo simple pero profundo.
   - **Aporte**: sensación de build-up de poder durante el run.

7. **Hollow Knight** — atmósfera misterio > mal perfecta + mapa interconectado + NPCs memorables.
   - **Aporte**: tono exploración, NPCs con secretos.

8. **Sea of Thieves** — coop 4 jugadores con roles emergentes + navegación + voice chat proximidad (paralelo canon GDD §9.1 chat de proximidad).
   - **Aporte**: coop emergente + voice chat proximidad.

---

## §8. Cross-ref

- **World canon**: `_world_canon.md` (mundo, tono misterio>mal, Necromancer dark excepción, acentos regionales reservados)
- **Skills canon**: `game/docs/skills/_system.md` (+ `_synergies.md` para combos)
- **Class lore**: `_class_lore_*.md` (6 órdenes con sus refs específicas ya documentadas)
- **Drop canon**: `_drop_ownership_canon.md` (Metin2 reference)
- **Mimic canon**: `_mimic.md` (Frieren reference)
- **GDD**: `GDD_DungeonParty.md` (pilares + estructura)
- **Visual bible**: `game/docs/visual_bible.md` (paleta + silhouettes)

---

## §9. Cómo usar este doc

1. **Antes de diseñar sistema nuevo**: consultá §4 (mapeo aplicado) — te dice qué ref debería inspirar tu diseño.
2. **Si proponés cambio que rompe tono**: chequeá §5 (tono prohibido) — si rompe, reconsiderá.
3. **Si citás ref nueva**: agregá a §3 con 1-2 líneas de aporte concreto + 1 línea de filtro (qué NO adoptar).
4. **Si el user menciona una ref**: linkealo a este doc. Si la ref no está, abrir sesión para agregar.

Este doc **crece con el proyecto**. No es snapshot 2026-04-17 — es vivo. Cambios se versionan aquí primero.

---

*Canon References v1.0. Danmachi es la referencia central por decisión user 2026-04-17. Las otras 25+ refs aportan piezas específicas. Actualizar al agregar refs nuevas — no sobrescribir sin justificar.*
