# Entrevista Co-definición — El Mundo (Lore, Pisos, Bestiario)

**Creado**: 2026-07-02
**Fuentes que este doc cierra**:
- `_world_seeds_postalpha.md` §7 — conflicto Erindar vs caverna (estacionado sin decisión formal)
- `_DESIGN_INDEX.md` ⚠️ — estructura de pisos incorrecta en `_floor_sketches.md`
- `_bestiary_visual_bible.md` §6 — fichas vacías (bandido, lobo, slime, king slime)
- `CLAUDE.md` próximos pasos paso 4 — los 5 mapas alpha sin definir

**Cómo usar**:
- Estructura de funnel: cada bloque va de pregunta abierta a específica.
- Claude hace UNA pregunta por vez dentro del bloque.
- Reglas de skip están marcadas en cada pregunta con la fuente que las justifica.
- Si una respuesta de Joan abre lore nuevo → se anota en `_world_seeds_postalpha.md` y se sigue adelante. No expandir canon vigente.

**Filtro activo**:
> "¿Esto sale en el video de 10 min del demo?" — si la respuesta es no, vive en post-alfa.
> La entrevista cierra gaps que BLOQUEAN trabajo concreto, no agrega ideas nuevas.

---

## BLOQUE 1 — ¿Qué es el Piso 1?

**Propósito**: cerrar formalmente el conflicto documentado en `_world_seeds_postalpha.md` §7.
El canon escrito (`_world_canon.md` §13) describe "Valle de Erindar" como pradera húmeda exterior con neblina verde y megalitos — un bioma de superficie. El código implementó algo distinto: una caverna-cristal con techo, diamante bioluminiscente y pradera interior. Joan dijo informalmente en `_world_seeds_postalpha.md` §7 que "no nos atamos" al nombre Erindar, pero eso no está cerrado formalmente.

**Lo que NO se pregunta (ya decidido)**:
- P1 es una caverna con techo. El diamante existe. El scatter de pradera existe. Esto no cambia. — *(`floor1_prairie.tscn`, `_floor_sketches.md` P1)*
- King Slime es el boss de zona. — *(implementado)*
- El criterio de curaduría endémica aplica (Axlin). — *(`_bestiary_visual_bible.md` §4)*

---

### 1.1 — Abierta: ¿Qué feel tiene el Piso 1 cuando alguien lo ve por primera vez?

Antes de hablar de nombre o detalles: describí en una o dos frases qué sensación tendrías que tener los primeros 30 segundos dentro del P1. ¿Qué querés que el jugador sienta apenas entra?

> (No hay opciones — pregunta abierta para capturar la intención de Joan antes de proponer nada.)

**Respuesta de Joan** (2026-07-03): "Pradera INMENSA — no esperabas que la torre fuera tan grande por dentro; hay vida, naturaleza dentro de ella." Mundo HUMANO: fauna real, solo 2 entidades mágicas pasivas y conocidas (golem y slime). ✅ Registrado en `_alpha_5_maps.md §Tabla P1`.

---

### 1.2 — Específica: El nombre "Erindar"

**Canon actual**: `_world_canon.md` §13 dice que el Piso 1 se llama "Valle de Erindar" (raíz celta/irlandesa, Erin = nombre poético de Irlanda). El concepto era pradera húmeda de superficie. La implementación divergió — es una caverna, no un valle.

**La pregunta**: ¿Qué hacemos con el nombre Erindar?

| Opción | Qué implica | Doc que actualizar |
|--------|-------------|-------------------|
| **A) Erindar sigue, redefinido** | El nombre se mantiene pero el concepto cambia: los aventureros nombraron esta caverna-burbuja "Erindar" porque los verdes del piso les recordaron algo de leyenda celta, aunque no sea un valle exterior. El nombre es folclórico, no descriptivo. | `_world_canon.md` §13 — actualizar descripción del Piso 1. Cerrar `_world_seeds_postalpha.md` §7 con esta decisión. |
| **B) Erindar se descarta** | El P1 recibe un nombre que refleje lo que realmente es. Proponer nombre nuevo basado en la caverna + los cristales. | `_world_canon.md` §13 — reemplazar "Valle de Erindar". `_floor_sketches.md` P1 — actualizar nombre. |
| **C) P1 no tiene nombre propio todavía** | El piso funciona como "Pradera Interior" como label funcional hasta que el mapa esté terminado y Joan vea el video. El nombre se decide cuando haya material grabado para anclar la identidad. | Solo actualizar `_world_seeds_postalpha.md` §7 con "decisión diferida, condición: ver el video del slice". |

**Decisión registrada** (2026-07-03): ⌛ **Sin respuesta formal en esta entrevista** — la pregunta 1.2 no fue planteada directamente. Label funcional en uso: "Pradera Interior". Erindar: sin confirmar ni descartar. Ver `_world_canon.md §13 P1` (marcado "en revisión") y `_world_seeds_postalpha.md §7`.

---

### 1.3 — Específica: ¿Toques celtas en la caverna?

**Regla de skip**: si en 1.2 elegiste B o C → esta pregunta no aplica. La reconciliación celta solo tiene sentido si el nombre Erindar sigue. Saltar a Bloque 2.

**El contexto**: `_floor_sketches.md` P1 propone agregar "toques celtas discretos" para honrar el nombre sin derribar el techo: un círculo de piedra enterrado bajo el pasto, un megalito cubierto de musgo en zona baja, bruma verde cerca del agua.

**La pregunta**: ¿Los toques celtas entran en el P1 o el bioma tiene identidad propia sin raíz cultural?

| Opción | Qué implica |
|--------|-------------|
| **A) Sí, toques celtas discretos** | Un círculo de piedra semienterrado, musgo cubriendo la piedra, bruma baja en zonas de agua. No es "P1 = Irlanda" — es un guiño ambiental. Se pueden reusar assets de roca existentes + material override con musgo. Agrega misterio ("¿quién los puso acá?") coherente con el tono discovery > slay del canon. |
| **B) No, el P1 tiene identidad propia** | Los cristales, el diamante del techo y la pradera son la identidad. No necesita raíz cultural explícita — es una caverna-burbuja sin etiqueta. |
| **C) Post-alfa, no ahora** | Interesante pero no prioritario. El alpha graba el piso como está. Anotarlo en `_world_seeds_postalpha.md` para revisitar. |

**Decisión registrada** (2026-07-03): No aplica — skip. La pregunta 1.2 quedó sin respuesta formal; sin decisión sobre Erindar, la pregunta sobre toques celtas no tiene base. ⌛ Pendiente junto con 1.2.

---

## BLOQUE 2 — Estructura de la Torre: ¿Cómo se siente avanzar?

**Propósito**: cerrar el conflicto marcado con ⚠️ en `_DESIGN_INDEX.md`. La advertencia dice:
> "la estructura de pisos es **bloque familiar largo → encuentro con el cuervo → distorsión progresiva**. NO es una curva gradual 1→5."

`_floor_sketches.md` actualmente documenta una curva gradual (P1=familiar, P2=misterioso, P3=físicas alteradas, P4=lógica doblada, P5=ruptura). Eso contradice la visión de Joan de sesión 2026-06-05.

**Lo que NO se pregunta (ya decidido)**:
- El gradiente de realidad existe: P1 ancla familiar → distorsión progresiva. — *(`_world_seeds_postalpha.md` §0)*
- El Guardián-Cuervo "El Que Recuerda" es jefe de RANGO, no de zona. — *(`_floor_sketches.md` P5, `_world_seeds_postalpha.md` §1)*
- El modelo macro Descubrimiento → Conquista → Civilización estilo Valheim es la dirección. — *(`_world_seeds_postalpha.md` §0)*
- Los 5 nombres culturales de los pisos son canon v2.0. — *(`_world_canon.md` §13)*

---

### 2.1 — Abierta: ¿Cómo se siente progresar en la torre?

Sin fijarte en los pisos individuales: ¿qué quiere el jugador que le pase a medida que sube? ¿Qué tiene que sentir diferente entre el piso 1 y el piso 5?

> (Pregunta abierta — captura la intención antes de hablar de estructura.)

**Respuesta de Joan**: ⌛ No preguntado en la entrevista 2026-07-02/03. Pendiente.

---

### 2.2 — Específica: ¿Curva gradual o bloque familiar + salto?

**La pregunta**: para los 5 pisos del alpha, ¿cuál es la estructura correcta?

| Opción | Qué implica para el alpha | Cómo afecta `_floor_sketches.md` |
|--------|--------------------------|----------------------------------|
| **A) Curva gradual (P1→P5)** | Cada piso es un escalón de extrañeza. P2 ya empieza a sentirse raro. P3 tiene algo físico que no cierra. El arco completo de 5 pisos es el recorrido de familiar a imposible. | `_floor_sketches.md` queda mayormente correcto — solo ajustar terminología. |
| **B) Bloque familiar largo + salto al final** | P1-P2-P3 (o P1-P4) se sienten en el mismo mundo — distintos biomas pero con las mismas reglas físicas y de juego. El quiebre real llega en P4 o con el Cuervo. P5 es lo surreal. El jugador siente que "tocó el límite de lo conocido" antes de romperse todo. | `_floor_sketches.md` necesita reescribir las descripciones de "gradiente de realidad" de P2-P4 para que no sean escalones de extrañeza sino variaciones dentro de lo familiar. |
| **C) Los 5 pisos del alpha son solo el "bloque familiar"** | Los 5 pisos del alpha son la primera parte del juego largo — todos se sienten relativamente familiares. La ruptura real viene en los pisos 6-10+ del juego completo (post-alfa). El Cuervo marca el fin del bloque familiar, no el centro. | Para el alpha, los 5 pisos son biomas distintos pero sin extrañeza mecánica. La curva de realidad es post-alfa. |

**Decisión registrada**: ⌛ No abordado en la entrevista 2026-07-02/03. Pendiente. Nota: la entrevista sí estableció el principio "gradiente humano → fantasía" (P1 = mundo humano, P2+ = fantasía creciente) — ver `_alpha_5_maps.md §Principios`. Esto es brújula, no responde la pregunta estructural formal.

---

### 2.3 — Específica: ¿En qué piso ocurre el primer salto real?

**Regla de skip**: si elegiste A (curva gradual) en 2.2 → no hay "un salto", hay una curva. Saltar a 2.4.

**La pregunta**: en el modelo bloque familiar + salto, ¿en qué piso del alpha ocurre el primer quiebre de reglas?

| Opción | Qué implica |
|--------|-------------|
| **A) El salto ocurre en P3 (Jötunheim)** | P1-P2 son biomas distintos pero familiares (pradera, bosque). P3 introduce la primera ruptura: escala gigante, frío como mecánica, aurora eterna. El jugador llega a P3 y las reglas cambian algo concreto. |
| **B) El salto ocurre en P4 (Al-Samum)** | P1-P3 son distintos pero coherentes (pradera, bosque, montaña de hielo — lugares reales, con reglas reales). P4 es el primero donde el agua puede matar, los oasis aparecen y desaparecen, las estrellas se mueven. Primera ruptura de lógica. |
| **C) El salto ocurre en P5 (Umbral)** | P1-P4 son todos mundos con reglas propias pero coherentes. P5 es donde todo se rompe: gravedad variable, fragmentos flotantes, tiempo no-lineal. El Cuervo es el gate de ese salto final. |

**Decisión registrada**: ⌛ No abordado en la entrevista 2026-07-02/03. Pendiente.

---

### 2.4 — Cierre: ¿Qué cambia en `_floor_sketches.md`?

Una vez que Joan responda 2.2 y 2.3, esto no es una pregunta — es la lista de cambios a ejecutar en la próxima sesión de trabajo.

**Template para completar con las respuestas anteriores**:

| Sección de `_floor_sketches.md` | Cambio a hacer |
|---------------------------------|----------------|
| Descripción de gradiente P2 | |
| Descripción de gradiente P3 | |
| Descripción de gradiente P4 | |
| Tabla resumen "Nivel realidad" columna | |
| Nota sobre el Guardián-Cuervo (¿dónde está en el alpha?) | |

> Llenar esta tabla al final del Bloque 2 con las decisiones de Joan. Es la hoja de trabajo para la sesión de escritura que cierra el ⚠️ del `_DESIGN_INDEX.md`.

---

## BLOQUE 3 — Bestiario P1: Las Fichas Vacías

**Propósito**: llenar las fichas de `_bestiary_visual_bible.md` §6 que no tienen referencias de Joan. El golem ya está completo (§6.5, referencias resueltas en 2026-06-14). Los pendientes: bandido melee (§6.1), bandido arquero (§6.2), lobo (§6.3), slime/mini (§6.4), King Slime (§6.6).

**Proceso por criatura**:
1. Joan trae o describe una referencia visual.
2. Claude extrae silueta + gama + firma + nicho, cruza con el ADN compartido de §1-§4 de la biblia.
3. Claude propone la ficha preliminar.
4. Joan aprueba o corrige.

**Regla de skip por criatura**: si Joan no tiene referencia en este momento → marcar `[pendiente-referencia]` y seguir. No se inventa el diseño sin referencia. Esa es la regla central de la biblia (`_bestiary_visual_bible.md` §0 "Cómo se usa").

**Lo que NO se pregunta (ya decidido)**:
- La familia de silueta de cada criatura ya está asignada en la tabla §5 de la biblia.
- El build-method (orgánico = pack-reskin, construct/blob = bpy) ya está asignado en §5.
- El golem está completo — no volver a revisar §6.5.

---

### 3.1 — Bandido melee / Bandido arquero

**Contexto del canon**: los bandidos son los únicos NO-endémicos intencionales de P1 (`_bestiary_visual_bible.md` §4). Son "evidencia de que otros estuvieron acá" — intrusos humanos, no fauna. Su diseño tiene que leer como HUMANO en contraste con todo lo demás. Familia: humanoide (bípedo, hombros, arma en mano). Acento de color: tela oscura, sin paleta de fauna.

**La pregunta**: ¿Tenés alguna referencia visual para los bandidos? ¿En qué look estás pensando?

> Si no hay referencia todavía: ¿al menos hay preferencia de tono? ¿Más survival/improvisado (harapos, armas rotas, parches), más organizado (uniforme de una facción), o algo intermedio? ¿Tienen alguna cultura de referencia o son "genérico medieval"?

**Respuesta de Joan** (2026-07-03): ⌛ Sin referencia entregada en esta entrevista. [pendiente-referencia]
**Notas para ficha**: pendiente. Los bandidos siguen siendo no-endémicos (intrusos humanos, contraste con la fauna).

---

### 3.2 — Lobo

**Contexto del canon**: cuadrúpedo predador, patrulla la zona del giant_tree y la transición bosque-pradera. Endémico. Familia: cuadrúpedo, bajo, 4 patas, cola. El quiebre asimétrico que lo individualiza dentro de la familia debe ser distinto al del zorro (el zorro hurta — el lobo carga). Gama: dentro de `#8FAE6B` verde pradera / `#7B5A3C` madera, con ojos como acento.

**La pregunta**: ¿Tenés referencia para el lobo? ¿O descripción del feel que querés?

> Anclas opcionales para disparar: ¿más Dire Wolf de Game of Thrones (inmenso, pelaje espeso, escala imponente), más lobo de parque natural (proporciones realistas, elegante), o algo más estilizado/toon (Low Poly-style con ángulos duros)?

**Respuesta de Joan** (2026-07-03): ⌛ Sin referencia entregada en esta entrevista. [pendiente-referencia]
**Notas para ficha**: pendiente.

---

### 3.3 — Slime / Mini Slime

**Contexto del canon**: el endémico central de P1. `_bestiary_visual_bible.md` §4 ya tiene dirección clara: "Come la bioluminiscencia de los cristales. Su cuerpo semitransparente brilla con el color que acaba de absorber." La silueta ya está asignada: familia blob (icosphere achatada, sin extremidades). El mini slime es la cría — grupos de 3-5, fisión del adulto.

**La pregunta**: ¿Tenés referencia visual para los slimes? ¿O el modelo actual en el juego (icosphere translúcida que brillan con el color del cristal cercano) ya te convence como base?

> Si el modelo actual te parece bien, ese ES el diseño — solo lo documentamos en la ficha. La dirección ya existe, falta la referencia formal de Joan para que tenga autoridad de canon.

**Respuesta de Joan** (2026-07-03): ⌛ Sin referencia visual entregada. [pendiente-referencia]
**Notas para ficha**: pendiente. Dirección ya establecida: semitransparente, brilla el color del cristal absorbido.

---

### 3.4 — King Slime (boss de zona)

**Contexto del canon**: "el que comió demasiada bioluminiscencia" — culminación ecológica del piso. La versión aberrante del ciclo natural del slime: absorbió tanta luz del diamante que su cuerpo se volvió denso, iridiscente, casi sólido. La ficha de boss necesita capturar la mecánica firma además del look.

**La pregunta**: ¿Qué querés que haga el King Slime en el boss fight? ¿Y cómo se ve diferente de un slime común además del tamaño?

> Anclas para la mecánica: ¿tiene fases (se divide en mini slimes a cierto % de HP)? ¿Tiene ataque de area-of-effect (se expande, aplasta)? ¿Tiene un tell visual antes de atacar (pulsa el color que acaba de absorber)? ¿Hay algo del bioma que usa como arma (absorbe cristales del suelo y los dispara)?

**Respuesta de Joan** (2026-07-03): Rol y mecánica de muerte decididos — ver ficha en `_bestiary_visual_bible.md §6.6`. Aspecto visual: ⌛ pendiente-referencia. Para el demo alcanza modelo actual + material iridiscente/denso. Golem trigger también actualizado: solo al ser atacado (3.4 fue el contexto donde se reconfirmó esto, junto con el rol del oso como nuevo mini subjefe).
**Notas para ficha**: ver §6.6 de la biblia visual del bestiario (completo de lo que hay disponible hasta hoy).

---

## BLOQUE 4 — Los 5 Mapas Alpha

**Propósito**: `CLAUDE.md` próximos pasos paso 4 dice textual:
> "Definir EXPLÍCITAMENTE los 5 mapas alpha (cuáles biomas, qué enemies, qué boss). Doc corto, 1 página."

Esto está pendiente desde el scope reset del 2026-05-18. Este bloque es esa definición.

**Lo que NO se pregunta (ya decidido)**:
- Los 5 nombres culturales: Erindar/P1, Aokigahara/P2, Jötunheim/P3, Al-Samum/P4, Umbral Fragmentado/P5. — *(`_world_canon.md` §13)*
- Los bocetos narrativos de cada piso ya existen en `_floor_sketches.md`.
- El boss de P1 es King Slime. Implementado.
- El Guardián-Cuervo es jefe de RANGO (distinto al boss de zona de cada piso). — *(`_world_seeds_postalpha.md` §1)*
- P1 está en desarrollo activo. El alpha empieza por P1.

**Regla de skip global del bloque**: si Joan define los 5 mapas en una sola respuesta libre, anotar y no hacer preguntas individuales por piso. El objetivo es el doc de 1 página, no el proceso de llegar a él.

---

### 4.0 — Abierta: ¿Qué tienen que demostrar los 5 mapas juntos?

Antes de definir mapa por mapa: ¿qué tiene que probar el alpha como set? ¿Qué le muestra al jugador que un solo mapa no puede mostrar?

**Respuesta de Joan** (2026-07-03): El demo incluye P1 + antesala de P2. Los 5 mapas tienen que mostrar el arco humano→fantasía — que la torre lleve a lugares que se sienten como mundos distintos, no solo más difíciles. (Respuesta parcial — no se estructuró como pregunta formal. Detalle en `_alpha_5_maps.md §Principios`.)

---

### 4.1 — P2: Aokigahara (Bosque, raíz japonesa)

El boceto de `_floor_sketches.md` propone: bosque denso con canopy que tapa todo, luz indirecta filtrada, silencio antinatural, hongos bioluminiscentes, torii en ruinas, yokai (kitsune, tengu, yamabiko), boss Nurikabe (pared viviente).

**La pregunta**: ¿El boceto de P2 es la dirección o ajustás algo?

| Campo | Boceto actual | ¿Confirmás? |
|-------|--------------|-------------|
| Bioma | Bosque denso, silencio antinatural, hongos cian como única luz | |
| Mob emblema | Kitsune (guardián de torii), Tengu (baja si el jugador se queda quieto), Yamabiko (eco que atrae fuera del grupo) | |
| Boss | Nurikabe — pared viviente que bloquea el mapa. Destruir partes específicas para abrir el paso. | |
| Gradiente | ¿Ya hay algo "raro" en P2 o todavía es un bosque familiar? | |

**Decisiones P2** (2026-07-03): ⚠️ La dirección de base (Aokigahara/japonés) queda DESCARTADA — "muy genérica" (Joan). El boceto completo fue reemplazado. Nueva identidad: bosque oscuro/lunar, Kimetsu fluorescencia, tono místico/élfico, clima lluvia/niebla, criaturas NATURALEZA CREADA (criterio Axlin, no mitologías copiadas), referencia sensación = Chiloé. Nombre pendiente. Aspecto demo: antesala P2 (2-3 min post-boss King Slime). Ver `_world_canon.md §13 P2` y `_alpha_5_maps.md §P2`.

---

### 4.2 — P3: Jötunheim (Glaciares/Nórdico)

El boceto propone: glaciares a escala de gigantes, noche eterna con aurora boreal, primer piso con cielo real (pero sin sol), frío como posible mecánica, jötnar (gigantes de hielo), boss Jarl-Jötunn (el último gigante consciente, 2 fases).

**La pregunta**: ¿El boceto de P3 te convence o ajustás algo? ¿El frío entra como mecánica en el alpha?

| Campo | Boceto actual | ¿Confirmás? |
|-------|--------------|-------------|
| Bioma | Glaciares a escala titánica, noche eterna, aurora boreal | |
| Mob emblema | Jötunn menor (gigante de hielo, 3x player, territorial) | |
| Mecánica nueva | Frío = slow acumulado por exposición sin refugio | |
| Boss | Jarl-Jötunn (2 fases: erguido → de rodillas/helada de suelo) | |

**Decisiones P3**: ⌛ No revisado en la entrevista 2026-07-02/03. Boceto previo en `_floor_sketches.md` — no usar como canon decidido.

---

### 4.3 — P4: Al-Samum (Desierto/Tormenta, raíz árabe-persa)

El boceto propone: tormenta de arena permanente, visibilidad como recurso escaso, oasis que aparecen y desaparecen, agua insegura (primera trampa de recurso aparentemente safe), djinn de arena (sin cuerpo sólido durante la tormenta), boss Rey Djinn (cambia el terreno como mecánica principal).

**La pregunta**: ¿El boceto de P4 te convence o ajustás algo? ¿Hay algo de "lógica doblada" que querés destacar?

| Campo | Boceto actual | ¿Confirmás? |
|-------|--------------|-------------|
| Bioma | Tormenta permanente, visibilidad variable, oasis que aparecen/desaparecen | |
| Mob emblema | Djinn de arena (reforzado durante tormenta, vulnerable en calma) | |
| Regla rota | Agua en oasis puede curar o matar — el jugador no lo sabe de entrada | |
| Boss | Rey Djinn — cambia la geometría del suelo como mecánica de pelea | |

**Decisiones P4**: ⌛ No revisado en la entrevista 2026-07-02/03. Boceto previo en `_floor_sketches.md` — no usar como canon decidido.

---

### 4.4 — P5: Umbral Fragmentado

El boceto propone: vacío geométrico, fragmentos flotantes de todos los pisos anteriores (el pasto de P1, el hielo de P3, la arena de P4 flotando sin soporte), gravedad variable, manifestaciones geométricas como mobs, Guardián-Cuervo como boss de RANGO.

**Pregunta clave**: el Guardián-Cuervo tiene memoria persistente por jugador (ya lo conoce en el segundo run → no pelea). ¿Eso entra en el alpha o se reserva para el lanzamiento?

| Campo | Boceto actual | ¿Confirmás? |
|-------|--------------|-------------|
| Bioma | Vacío geométrico + fragmentos de todos los pisos anteriores | |
| Mobs | Manifestaciones geométricas + ecos de bosses anteriores (sombras sin color) | |
| Boss | Guardián-Cuervo "El Que Recuerda" con memoria persistente por jugador | |
| Regla rota | Gravedad variable — zonas donde el jugador cae hacia arriba | |
| ¿La memoria del Cuervo entra en el alpha? | (requiere persistencia cross-run, arquitectura de netcode) | |

**Decisiones P5**: ⌛ No revisado en la entrevista 2026-07-02/03. Boceto previo en `_floor_sketches.md` — no usar como canon decidido. Solo confirmado: el Guardián-Cuervo es jefe de RANGO (no de zona), sigue siendo canon.

---

### 4.5 — Cierre: El doc de 1 página

Con las decisiones de 4.1 a 4.4, completar esta tabla. Es el output de este bloque — el "doc corto" del paso 4 de `CLAUDE.md`.

| Piso | Bioma | 3 mobs clave | Boss de zona | Una regla que cambia | Estado |
|------|-------|--------------|--------------|----------------------|--------|
| P1 — Erindar/Caverna | Pradera-caverna cristal | Slime, lobo, bandido | King Slime | — (ancla familiar) | En desarrollo |
| P2 — Aokigahara | | | | | Boceto |
| P3 — Jötunheim | | | | | Boceto |
| P4 — Al-Samum | | | | | Boceto |
| P5 — Umbral | | | | | Boceto |

> Esta tabla, una vez completada, es la fuente de verdad para el alpha. Se guarda como `_alpha_5_maps.md` en `game/docs/lore/`.

---

## BLOQUE 5 — Gradiente de Realidad: La Dimensión Mecánica

**Propósito**: el gradiente de realidad existe como concepto visual y atmosférico en el canon. Lo que falta es la dimensión MECÁNICA: ¿qué regla del JUEGO cambia en cada piso, no solo qué se ve diferente?

**Regla de skip**: si el Bloque 4 ya respondió "qué regla cambia en cada piso" con suficiente detalle → este bloque es redundante. Revisar las notas de 4.1-4.4 antes de arrancar este bloque.

**Lo que NO se pregunta (ya decidido)**:
- El gradiente existe: P1 ancla familiar → P5 ruptura total. — *(`_world_seeds_postalpha.md` §0)*
- P1 no rompe ninguna regla — es el ancla. — *(`_floor_sketches.md` P1)*
- P5 puede romper TODA regla. — *(`_world_canon.md` §13 P5)*

---

### 5.1 — Abierta: ¿Qué tipo de reglas puede romper la torre?

La torre conecta capas de realidad distintas. Si cada capa tiene leyes propias, ¿qué tipo de reglas del JUEGO te parece interesante que cambien a medida que bajás?

> Algunos ejes posibles para disparar (no son los únicos): gravedad, tiempo, IA de los mobs, visibilidad del minimapa, qué recursos se pueden usar, reglas de muerte/downed, stats que importan, comportamiento del loot.

**Respuesta de Joan**: ⌛ No abordado en la entrevista 2026-07-02/03. Pendiente.

---

### 5.2 — Específica: Una regla por piso (P2 a P5)

**La pregunta**: para cada piso de P2 a P5, elegí UNA mecánica del juego que cambia respecto al ancla del P1. Puede ser un solo parámetro — no tiene que ser un sistema complejo.

| Piso | ¿Qué regla cambia respecto a P1? | Ejemplo de posibilidad |
|------|----------------------------------|------------------------|
| P2 — Aokigahara | | Ej: el minimapa se desactiva (el bosque confunde la orientación) |
| P3 — Jötunheim | | Ej: el frío reduce un stat mientras el jugador está fuera de zona de refugio |
| P4 — Al-Samum | | Ej: el agua en oasis no es safe por default — hay que testearla antes de usarla |
| P5 — Umbral | | Ej: la gravedad es variable por zona — hay partes donde el jugador cae hacia arriba |

> Estas decisiones mecánicas son las que hacen que P2-P5 se sientan como pisos distintos y no solo como "más mobs más difíciles". Son también lo que da identidad de diseño a cada piso más allá del bioma visual.

**Decisiones de gradiente mecánico**: ⌛ No abordado en la entrevista 2026-07-02/03. Pendiente.

---

## Tabla de cierre — Gaps resueltos en esta entrevista

Completar al terminar la entrevista. Es la hoja de trabajo para la próxima sesión de escritura.

| Gap cerrado | Decisión tomada | Acción | Doc a actualizar |
|-------------|-----------------|--------|-----------------|
| Nombre / identidad P1 (Erindar vs caverna) | ⌛ Sin respuesta formal — label funcional "Pradera Interior"; Erindar en revisión | Marcado en `_world_canon.md §13 P1` | ✅ Hecho |
| Toques celtas en P1 | ⌛ Pendiente (depende de 1.2) | — | Pendiente |
| Estructura de pisos (curva vs bloque + salto) | ⌛ No preguntado en esta entrevista | — | Pendiente (`_floor_sketches.md`, `_DESIGN_INDEX.md ⚠️`) |
| Piso del primer salto real | ⌛ No preguntado en esta entrevista | Principio establecido: P1=humano, P2+=fantasía | Pendiente |
| Ficha bandido melee + arquero | ⌛ Pendiente-referencia | — | `_bestiary_visual_bible.md §6.1-6.2` |
| Ficha lobo | ⌛ Pendiente-referencia | — | `_bestiary_visual_bible.md §6.3` |
| Ficha slime / mini slime | ⌛ Pendiente-referencia | — | `_bestiary_visual_bible.md §6.4` |
| Ficha King Slime (boss) | ✅ Parcial: rol/ubicación/muerte decididos; aspecto ⌛ pendiente | §6.6 creado en bestiary | ✅ Hecho (parcial) |
| Golem: trigger de awaken | ✅ SOLO al ser atacado (no por proximidad) | §6.5 actualizado | ✅ Hecho |
| Oso: mini subjefe territorial (nuevo) | ✅ Decidido en entrevista — ataca al verte, guarida, contraste con golem | §6.7 stub creado | ✅ Hecho |
| P2: dirección Aokigahara/japonés | ✅ DESCARTADA; nueva dirección: bosque propio, Chiloé sensación, clima lluvia | `_world_canon.md §13 P2` + `_alpha_5_maps.md` | ✅ Hecho |
| Ciudad hub: origen multicultural | ✅ Ciudad nace chilena (Valparaíso), multicultura se agrega con updates | `_world_canon.md §2.1` actualizado | ✅ Hecho |
| Los 5 mapas alpha definidos | ✅ P1 completo, P2 parcial, P3/P4/P5 boceto pendiente revisión | Creado `_alpha_5_maps.md` | ✅ Hecho |
| Gradiente mecánico P2-P5 | ⌛ No abordado en esta entrevista | — | Pendiente (`_floor_sketches.md`) |
| Flujo de entrada al juego | ✅ Menú → crear PJ cross-mundos → selector D2 → world select | Documentado en `_alpha_5_maps.md §Flujo` | ✅ Hecho |

---

*Entrevista diseñada 2026-07-02. Usar en sesión de trabajo con Joan — un bloque por vez, una pregunta por vez dentro de cada bloque. No expandir canon nuevo: si una respuesta abre lore nuevo, se anota en `_world_seeds_postalpha.md` y se sigue con la pregunta siguiente.*
