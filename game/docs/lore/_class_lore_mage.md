# Mage — Identidad, Lore y Fantasía

**Versión**: 3.0 — revert naming (fantasy genérico recuperado) + mantiene estructura v2.0 (§0 DRY, tono misterio>mal, Necro con horror controlado)
**Fecha**: 2026-04-17
**Estado**: Canon lore — complemento narrativo de `game/docs/skills/mage.md`
**Depende**: `_world_canon.md`, `_system.md`, `_class_lore_*` (hermanos).
**Audiencia**: Design, Art, UI, Story.

---

## §0 Contexto del Mundo

Ver canon central: [`_world_canon.md`](_world_canon.md).

Resumen: medieval-fantástico (Torre como **misterio**, no mal). Esta orden opera dentro de ese tono — **academia que estudia el misterio**, no que lo destruye.

---

## §1 Esencia

El Mage no es un DPS con fuegos artificiales. Es **el que decide entender antes que golpear**. Su fantasía es **curiosidad como arma**: el hechizo es la consecuencia visible del trabajo invisible de años — desentrañar, catalogar, probar. El Mage NO es poderoso porque "tenga magia". Es poderoso porque **sabe cómo funciona la magia**.

Inspiraciones base:
- **Frieren (Sousou no Frieren)** — disciplina académica centenaria, paciencia extrema, respeto por los pequeños hechizos antes que por los grandes.
- **JJK (Jujutsu Kaisen)** — casting dramático con pose y declaración del técnica (especialmente en ultimate "Arte Arcano: Supernova").
- **Doctor Strange (comics)** — el mago que usa bibliotecas como arsenal.
- **Hermione Granger** — preparación obsesiva como ventaja estructural.

El Mage es el miembro de party más "peligroso en teoría" y el más "frágil en práctica". Sin party, es un objetivo móvil. Con party, es el que **descubre** el rumbo del combate — consistente con el pilar discovery > slay del `_world_canon.md §8`.

---

## §2 Origen / cultura — La Vigilia Arcana

La **Vigilia Arcana** es la institución académica de magia más antigua del reino (aprox. 800 años documentados, más tiempo indocumentado). Sede principal: la **Torre de Vigilia** — una estructura anexa al reino, **no confundir con la Torre del Gremio**: la Torre de Vigilia es universidad, no dungeon.

**Reclutamiento**: no hay "don natural" estrictamente — hay **curiosidad detectable**. Los reclutadores de la Vigilia visitan aldeas buscando niños de 7-11 años que hacen preguntas que nadie puede contestar. Los que preguntan por qué el fuego es naranja pero la brasa es roja. Los que quieren saber qué hay debajo del suelo. Son invitados a postularse. El examen dura 3 días — es escrito, no práctico.

**Formación**: ingreso a los 12 años, graduación promedio a los 24-28 años. Pasan por:
- **Primer Ciclo** (12-17): fundamentos — alfabetos rúnicos, historia de escuelas, primeras bolitas inestables. Los alumnos llevan túnicas grises.
- **Segundo Ciclo** (17-22): especialización tentativa — casi todos prueban Elementalista y Arcano antes de elegir. Túnicas azules.
- **Tercer Ciclo** (22-28): tesis individual + primer contrato externo. Túnicas **violeta** (color canon del Mage — se gana, no se regala).
- **Vigilantes** (post-graduación): mages activos. Pueden volver a la Torre de Vigilia entre contratos.

**¿Se nace o se elige?**: Se elige, pero con filtro estricto. No todos los curiosos son aceptados (hay test de aptitud arcana), y no todos los aptos son curiosos (los aptos sin curiosidad no sobreviven al primer ciclo).

**Relación con la Torre del Gremio**: los Mages entienden la Torre del Gremio como **el artefacto arcano más grande del mundo** y como **el misterio estudiable por excelencia**. Subirla no es opcional — es **la tesis final**. Cada Mage que firma el contrato del Gremio lo hace con **doble propósito**: ayudar al grupo Y catalogar lo que encuentra. Hay Mages que subieron la torre no para llegar arriba, sino para quedarse estudiando un piso específico.

**Ramas**:
- **Elementalista**: estudia los tres elementos fundamentales (Fuego/Hielo/Rayo) como fenómenos naturales — elige uno al llegar a Vigilante (canon lvl 25). No hay rivalidad entre sub-elementos; hay debate académico perpetuo sobre cuál es "más puro".
- **Arcano**: estudia el espacio, la distancia, la manipulación de la posición como recurso. Es la rama más nueva (~200 años). Los Elementalistas viejos a veces los llaman "los que hacen trucos". Los Arcanos responden que manipular espacio es resolver el problema antes de crearlo.

---

## §3 Filosofía / código — "Saber antes de Ser"

El dogma de la Vigilia, grabado en la puerta del aula magna:

> *"No controlamos el fuego. Entendemos el fuego. El control es consecuencia."*

**Tres principios operativos**:

1. **La preparación es el hechizo real.** Lo que pasa en combate es solo la ejecución. El trabajo de verdad es el estudio previo.
2. **Un Mage que no registra lo que ve, no es Mage.** Todos los Vigilantes llevan cuaderno (grimorio). Cada combate, cada piso, cada bicho raro — se anota. La Vigilia Arcana mantiene **la Biblioteca de la Torre de Vigilia**, el archivo más grande del reino.
3. **Nunca mentir sobre la magia.** Exagerar un hechizo es pecado académico. Si no funcionó como querías, lo anotas. La honestidad arcana es la única defensa contra el auto-engaño.

---

## §4 Aesthetic / visual identity

- **Colores primarios**: violeta profundo (túnica de Vigilante) + azul tinta (runas + ojos bajo el capuchón).
- **Colores secundarios**: blanco tiza (páginas de cuaderno), oro apagado (encuadernación de tomos personales).
- **Materiales**: tela gruesa (lana tejida apretada, NO seda — el Mage es práctico), cuero para encuadernación, hueso pulido como puntero de lectura. Bastón de madera oscura, a veces con gemas arcanas empotradas en la cabeza (se heredan del maestro). Libro personal (grimorio) colgado de la cintura — siempre visible.
- **Símbolos**:
  - **Ojo abierto sobre libro abierto** (emblema de la Vigilia)
  - **Tres círculos concéntricos** (fundamento, teoría, práctica — los ciclos de formación)
  - **Pluma cruzada con bastón** (el cuaderno es tan arma como el bastón)
- **Postura/silhouette de combate**: posición lateral (no frontal — respeto por la distancia), bastón en mano izquierda apuntando al suelo, mano derecha libre para el gesto de finger-guns (canon `mage.gd` prototipo + GDD §4.2). Silhouette delgada, alta, encorvada hacia adelante al leer — erguida solo al castear.
- **Refs anime/film/game** (cross-ref `mage.md §7`):
  - **Frieren** — paciencia, escala temporal, respeto por los pequeños hechizos
  - **JJK Gojo cast Domain Expansion** — el nombre visible antes del ultimate
  - **Doctor Strange Eye of Agamotto** — geometría sagrada translúcida (Barrera Prismática)
  - **Dark Souls — Crestfallen Warrior's Mage** — silhouette encapuchada, bastón alto

---

## §5 Voz / personalidad

**Curioso, articulado, ocasionalmente distraído**. El Mage usa oraciones más largas que el Warrior. Cuando encuentra algo nuevo en combate, tiende a **comentarlo en voz alta** — no es monólogo, es método pedagógico heredado de la Vigilia.

Ejemplos de líneas típicas:
- Al ver un enemigo nuevo: *"Interesante. Sus resistencias son... distintas. Lo anoto."*
- Al castear Supernova: *"Arte Arcano — Supernova."* (nombre visible, tono grave — no grita, declara)
- Al morir un aliado que aplicaba `Freeze`: *"No llegamos a Shatter. Siguiente vez."*
- En la Taberna, si alguien pregunta por un hechizo: *"¿Querés teoría o querés práctica? Tengo las dos."*
- A un Warrior parco: *"Podés no responder. Lo anoto igual."*

**Lo que NUNCA dice**:
- "No sé." (siempre tiene al menos una hipótesis — puede estar mal, pero tiene)
- Desprecia a otra clase por "no entender" (el dogma §3.3 prohíbe el ego académico)
- Menciona fracasos de hechizos anteriores si no se le pregunta (se anota, se guarda, no se hace chiste)
- Frases tipo "destruir la oscuridad con luz arcana" — el Mage NO es cruzada; es **observador**.

---

## §6 Pareo con otras clases (lore)

### Archer (Hermandad de los Vientos Silenciosos / Gremio Mecánico de Drennhold)
**Alianza académica**. Los Archer Rangers mantienen la tradición de observación natural; los Mages estudian los mismos fenómenos desde otro ángulo. La Vigilia Arcana y la Hermandad de los Vientos firmaron un *Pacto de Registro Compartido* hace 150 años — los Archers anotan lo que el Mage no puede ver a distancia, el Mage interpreta lo que el Archer no puede explicar. En la Taberna, suelen compartir mesa.

Con los Artilleros de Drennhold: **relación técnica** — los Mages ayudaron a los primeros Artilleros a calcular trayectorias parabólicas con fuego arcano. Buena mesa compartida.

### Cleric (Sínodo de la Tres Luz)
**Tensión histórica respetuosa**. El Sínodo cree en verdades reveladas; la Vigilia cree en verdades investigadas. Ambas instituciones se toleran profesionalmente — hay Mages que consultan al Sínodo sobre fenómenos de origen "sagrado", y Clerics Exorcista que consultan a la Vigilia sobre undead/void. Discusiones teológicas pueden escalar si se prolongan; por eso los contratos del Gremio tienen cláusula de **silencio doctrinal durante la run**.

### Warrior (Orden del Muro Inquebrantable)
**Respeto distante**. Ver `_class_lore_warrior.md §6`. Los Mages entienden el voto del Warrior y lo respetan, pero no comparten la filosofía de "protección como único propósito" — para el Mage, **proteger es un medio, saber es el fin**.

### Necromancer (Pacto de los Marchitos) — **horror controlado académico**
**Relación delicada — los Mages estudian con horror controlado.**

Con el Necromancer DARK canónico (`_class_lore_necromancer.md` v2.0), la Vigilia Arcana **cataloga al Pacto** pero **no aprueba**. Los Mages mayores **prohíben a estudiantes de Primer y Segundo Ciclo** leer sobre nigromancia — solo Tercer Ciclo accede al tema. La política formal: **registrar sin practicar**.

En runs coop forzados por el Gremio, cooperan — **pero el Mage deja el campo limpio de evidencia antes de salir** (no quiere que otros cataloguen lo que el Pacto hizo).

### Danzante de Sombras (Hijos de la Medianoche)
**Indiferencia estudiada**. Los Mages no tienen conflicto directo con los Hijos — pero tampoco confianza. La Vigilia considera la tradición del Danzante como "conocimiento oral que no se deja estudiar" — lo cual, para un académico, es casi una ofensa personal. En combate coordinan bien. Fuera de combate, no hay conversación.

---

## §7 Hooks de quest

### Hook A — "Armonía Rota" — la tesis del Vigilante
Durante los tres ciclos de formación, cada aspirante Elementalista debe demostrar los tres sub-elementos al menos una vez. La quest §5bis canon `_system.md` ("aplicar los 3 sub-elementos a un mismo boss") **es literalmente la tesis de Vigilante**. La quest narrativa: un Vigilante antiguo **perdió su cuaderno de tesis** en la torre y la entrega no se pudo hacer. Encontrar el cuaderno reactiva la tesis — y la skill oculta *Armonía Rota*. Hook: el cuaderno está en manos de un enemigo, el jugador decide leerlo antes o después de entregarlo.

### Hook B — "El Camino entre Espacios" — Lyssandra del Umbral
La rama Arcano tiene una leyenda interna: **la Primera Arcana**, llamada **Lyssandra del Umbral**, desapareció hace 200 años durante un experimento de teleport masivo. Nunca se encontró el cuerpo. La Vigilia declaró "pérdida académica irreparable". Rumor: ciertos pisos altos de la torre tienen **anomalías espaciales no catalogadas** que podrían ser rastro de Lyssandra. Quest: investigar, encontrar, decidir qué hacer con lo que queda. Conecta con la skill oculta Arcano *Singularidad*.

### Hook C — "La Biblioteca bajo la Torre"
Rumor que la Vigilia no confirma ni niega: **hay un piso de la Torre del Gremio que contiene un archivo arcano pre-reino** — una biblioteca más antigua que la Vigilia misma. Quest: expedición académica con escolta (la Vigilia insiste en mandar un Warrior + un Cleric como contrato para exploradores). Objetivo: catalogar, fotografiar (con hechizo de transcripción), traer copias. Si el jugador decide **destruir** en vez de preservar, hay consecuencia de orden (la Vigilia excomulga al Mage — pierde acceso a la Torre de Vigilia pero gana título "Herético Arcano" con mecánica aparte).

---

## §8 Cross-ref

- **Skills canon**: `game/docs/skills/mage.md` (v2.0, 10 skills, MP-only fantasy lock)
- **Status effects**: `game/docs/skills/_status_effects.md`
- **Sinergias**: `game/docs/skills/_synergies.md` (combo #1 Shatter, #4 Supernova+Danza, #5 Agrupar-Ejecutar, #11 Homing+Cleave)
- **World canon**: `game/docs/lore/_world_canon.md`
- **GDD**: `GDD_DungeonParty.md §4.2` (Mage base gesto finger-guns)

---

*Lore Mage v3.0. Naming fantasy genérico (Vigilia Arcana / Torre de Vigilia / Lyssandra).*
