# Entrevista Co-definición — Video Demo (Vertical Slice)

**Creado**: 2026-07-02 · **Depende de**: `CLAUDE.md` §Scope Reset 2026-05-18

> **Por qué existe este doc**: Joan marcó explícitamente que unilateralmente proponer un guion
> es un error — "estás definiendo el parámetro sin haberlo definido conmigo, eso es raro".
> Este doc es el protocolo correcto: Claude pregunta, Joan responde, las decisiones se co-definen.

**Cómo usar**:
- Claude hace UNA pregunta por vez, en el orden de este doc.
- Espera respuesta antes de avanzar. NO asume ni completa por Joan.
- Reglas de skip están explícitas en cada pregunta. Si aplica una, saltear sin preguntar.
- Anotar la decisión al final de cada sección.
- Al terminar Q10 → ir a los guiones borrador para que Joan los use como disparador.

**Filtro activo en toda la entrevista**:
> "¿Esto acerca o aleja de los 5 mapas publicables?"
> Si una respuesta introduce scope nuevo → anotarlo pero no incluirlo en el video actual.

---

## Q1: ¿Cuál es el objetivo del video?

Esta respuesta define todo lo que viene después. Sin ella, el resto de la entrevista no tiene base.

**La pregunta**: ¿Para qué querés que exista este video?

| Opción | Qué cambia | Cuándo tiene sentido |
|--------|------------|----------------------|
| **A) Baseline interno** | Grabación honesta sin audiencia. No se publica. Sirve para que Joan (y Claude) vean exactamente dónde está el juego antes de avanzar. Las cosas feas se muestran — ese es el punto. | Cuando el objetivo principal es evaluar el estado real, no presentar nada. El video es un espejo, no un trailer. |
| **B) Devlog público** | Muestra el proceso de desarrollo. La audiencia es pequeña e interesada en el dev journey. Puede mostrar cosas incompletas si se explican en contexto. | Cuando querés construir comunidad temprana o documentar el proceso para referencia futura. |
| **C) Teaser Steam** | El video trabaja para la página de Steam. Audiencia: gamers que no saben nada del juego. Objetivo: wishlist. Todo lo feo se corta. | Cuando la página de Steam ya existe o va a existir pronto y este video es el primer material público "serio". |
| **D) Showcase itch.io** | Complementa una demo descargable. La audiencia lo ve para decidir si baja la demo. Tiene que mostrar el gameplay loop real, no solo los mejores momentos. | Cuando el plan es publicar una demo jugable en 30 días y este video es el preview. |

> La opción cambia radicalmente la duración, la edición y qué mobs/momentos tienen que salir bien. Si no estás seguro, podemos comparar dos opciones antes de decidir.

**Decisión registrada**: _______________________

---

## Q2: ¿Dónde se publica y cuándo?

**Regla de skip**: si elegiste A (baseline) en Q1 → esta pregunta no aplica. Saltar a Q3.

**La pregunta**: ¿Dónde va a vivir el video y hay algún deadline que lo condicione?

| Opción | Qué implica | Tradeoff |
|--------|-------------|----------|
| **A) YouTube + Twitter/X, sin deadline** | El video sale cuando el juego lo permite. No hay presión de fecha. | Ventaja: no apurás nada por el video. Riesgo: sin deadline, el video nunca se graba. |
| **B) YouTube + Twitter/X, en 30 días** | El video es el deadline del alpha. Todo lo que no esté listo en 30 días no entra. | El video actúa como motor, no como resultado. Obliga a priorizar. |
| **C) Página Steam directamente** | Requiere calidad de representación de tienda. Más exigente en producción visual. | Válido si la página de Steam ya existe o se va a publicar junto con el video. |
| **D) Privado, solo Joan** | Sin audiencia ni presión de presentación. | Redundante si elegiste A en Q1 — este slot es solo para confirmar. |

**Decisión registrada**: _______________________

---

## Q3: ¿Cuánto dura realmente el video?

**Regla de skip**: si elegiste C (teaser Steam) en Q1 → los trailers de Steam suelen ser 60-120 segundos (corto) más una versión extendida de 3-5 min. Confirmar antes de saltar a Q4.

**La pregunta**: ¿Cuánto dura el video que tenés en mente?

| Opción | Qué muestra | Qué requiere |
|--------|-------------|--------------|
| **A) 3-5 min** | Solo los mejores momentos. El piso completo no entra — se muestran beats seleccionados. | Edición. No podés poner 3 min de gameplay crudo y que funcione — hay que elegir qué va. |
| **B) 8-12 min** | Un recorrido del piso completo o casi. Puede tener cortes básicos para quitar espera. La audiencia ve el loop de gameplay real. | Que el piso esté en estado grabable end-to-end (entrada, combate, boss, drops). |
| **C) 15-20 min** | Gameplay largo, casi sin cortes. Puede incluir comentario mientras se juega. | Solo funciona para baseline (Q1-A) o devlog personal. La audiencia pública no termina 20 min de un juego desconocido. |

**Decisión registrada**: _______________________

---

## Q4: ¿Qué clase mostrás y por qué?

**Contexto**: Warrior, Mage y Archer están implementados. El recorte a 3 es solo para el demo — las 6 clases siguen siendo canon de lanzamiento.

**La pregunta**: ¿Qué clase (o clases) aparecen en el video?

| Opción | Qué tiene | Tradeoff |
|--------|-----------|----------|
| **A) Solo Warrior** | El más fácil de grabar — melee directo, hit-feedback claro en primera persona, no requiere puntería. | Menos variedad visual. Si los VFX del Warrior son débiles, el video se puede ver soso. |
| **B) Solo Mage** | Skills con mayor impacto visual (proyectil + rayo canalizado). Mejor para mostrar el sistema de magia. | Más difícil de grabar bien — el caster en primera persona necesita distancia y posicionamiento para que las skills se lean. |
| **C) Warrior + Mage (dos segmentos)** | Muestra variedad de clases sin grabar las 3. El Warrior establece el combate; el Mage muestra el peak de efectos. | Requiere 2 runs distintos o un corte de escena. Más montaje. |
| **D) Las 3 clases (W + M + A)** | Muestra la amplitud del alpha. Cada clase ocupa un tercio del tiempo. | Requiere 3 runs. Cada run tiene que ser compacto y no aburrir. El Archer puede verse monótono si no hay buenos momentos de puntería. |

> Nota técnica: en primera persona, el Warrior es el más filmable porque el impacto del golpe se lee en el cuerpo del enemigo. El Mage requiere que los proyectiles sean visibles (posicionarse bien). El Archer necesita hits limpios para que se vea bien.

**Decisión registrada**: _______________________

---

## Q5: ¿Qué mobs aparecen en el video?

**Contexto**: mobs implementados en P1: slime, mini_slime, king_slime, wolf, bird, hawk, fox, goat, rat, scorpion, snake, wasp, turtle, mimic_chest, bandit_melee, bandit_archer. El golem tiene el cuerpo hecho (`golem_dp_chunks_01.glb`) y el moveset tree-gated definido — pero la implementación del árbol destructible está en progreso.

**La pregunta**: ¿Qué mobs querés que el espectador vea en el video?

| Opción | Qué muestra | Tradeoff |
|--------|-------------|----------|
| **A) Los más pulidos visualmente** | Elegís los mobs en mejor estado de modelo, IA y feedback. Candidatos: slime, wolf, bandit. El golem entra si tiene el moveset listo. | El video muestra lo mejor que hay. Pero si el golem no está, falta el mob más icónico del piso. |
| **B) Slime wave → King Slime como cierre** | El slime es el endémico central de P1. Una wave culminando en el boss es el loop narrativo más limpio. | Si el King Slime no tiene un fight memorable (fases, patrones definidos), el cierre se cae. |
| **C) Variedad de familias** | Un mob de cada familia: blob (slime), cuadrúpedo (wolf), humanoide (bandit), boss (king slime). | Muestra amplitud del bestiario. El riesgo: ningún encuentro tiene tiempo para brillar — se siente catálogo. |
| **D) Joan elige en vivo** | Sin pre-decidir — grabás y mostrás lo que los spawns dan. | Honesto. Para baseline (Q1-A) funciona. Para trailer (Q1-C) es riesgoso — si el spawn no da algo interesante, no tenés material. |

> Si el golem con moveset tree-gated (arranca el árbol → abanica x3; sin árbol → pisotón/roca) está listo, se convierte en el candidato más fuerte para el momento icónico del video. El King Slime es el cierre natural si el golem no está.

**Decisión registrada**: _______________________

---

## Q6: ¿Cuál es la estructura de beats del video?

**Regla de skip**: si elegiste A (baseline) en Q1 → no hay estructura narrativa necesaria. Grabás el run y listo. Saltar a Q7.

**La pregunta**: ¿Qué momentos tiene el video y en qué orden van?

Acá no te doy opciones cerradas — te doy un menú de beats. Elegís cuáles querés y en qué orden.

**Menú de beats disponibles**:

| Beat | Qué es | Duración est. | Estado |
|------|--------|---------------|--------|
| **Entrada al piso** | El jugador aparece. El bioma se establece. God rays, scatter, cristales del techo. | 30-60s | Implementado |
| **Primer encuentro** | El primer mob aparece. El jugador lo enfrenta. El sistema de combate queda establecido. | 60-90s | Implementado |
| **Exploración libre** | El jugador recorre el mapa. Se ven distintas zonas: árbol gigante, cristales, outpost bandidos. | 60-120s | Implementado |
| **Skill showcase** | El jugador usa las skills de la clase. Cooldowns, recursos, VFX. | 60s | Implementado (varía por clase) |
| **Loot moment** | Un mob cae, aparece loot, el jugador lo recoge. Loop básico visible. | 30s | Implementado |
| **Mob wave** | Un grupo de mobs ataca. Se ve la IA y el crowd. | 60s | Implementado |
| **Near-death** | El jugador está en bajo HP — usa habilidad defensiva, huye, o entra en downed state. | 30s | Implementado (downed state) |
| **Boss fight** | King Slime o golem. El combate de boss. | 120-180s | King Slime implementado; golem en progreso |
| **Victoria + drops** | El boss cae. Drops visibles en pantalla. El jugador los recoge. | 30s | Implementado |

> Elegí los beats que querés y poné el orden que tiene sentido para el objetivo del video (Q1). Podés agregar algo que no esté en esta lista.

**Estructura decidida**: _______________________

---

## Q7: ¿Cuál es el tono de edición?

**La pregunta**: ¿Qué tan editado está el video?

| Opción | Qué implica | Tradeoff |
|--------|-------------|----------|
| **A) Gameplay crudo** | Un take, sin cortes, sin overlays de texto, sin música agregada. Lo que salió, sale. | Más honesto y de cero esfuerzo de producción. Puede tener momentos muertos y errores. Para baseline es perfecto. Para audiencia pública, necesita que el gameplay solo sea suficientemente entretenido. |
| **B) Cortes básicos** | Se cortan los momentos muertos (backtracking, esperas, pantallas de carga). Se mantiene el audio del juego. Sin música adicional. | El equilibrio más práctico. El video se ve compacto sin requerir herramientas ni tiempo de edición. Recomendado para devlog. |
| **C) Montaje editado** | Cuts rítmicos, posible slow-mo en momentos de impacto, títulos de texto para contexto ("Warrior — Clase melee"), música seleccionada. | El video de mayor producción. Requiere más tiempo y herramientas. Para teaser Steam es lo esperado — sin montaje, el teaser queda flojo. |

**Decisión registrada**: _______________________

---

## Q8: ¿Qué pasa con el audio?

**La pregunta**: ¿Cómo queda el audio del video?

| Opción | Qué implica | Tradeoff |
|--------|-------------|----------|
| **A) Audio del juego crudo** | SFX de ataques, pasos, ambiente — todo lo que el motor pone. Sin música agregada. | Honesto. Si los SFX son buenos, puede ser suficiente. Si son placeholder, le resta impacto al video. |
| **B) SFX del juego + música de fondo** | Los SFX del juego en primer plano, música instrumental libre de derechos por debajo. | Eleva el feel sin mucho esfuerzo. Requiere elegir música adecuada (libre de derechos o comprada). |
| **C) Música sola, SFX suprimidos** | La música lleva el video. Los SFX del motor quedan bajísimos o se suprimen. | Solo funciona en trailers muy editados donde el montaje es visual. Si las skills tienen feedback de SFX importante, suprimirlo confunde. |
| **D) Narración de voz mientras se juega** | Joan habla en tiempo real explicando lo que se ve. | Perfecto para devlog honesto. Para teaser o showcase, no funciona. Para baseline puede capturar observaciones en el momento. |

**Decisión registrada**: _______________________

---

## Q9: ¿Qué nivel de calidad es "suficientemente bueno" por segmento?

Esta es la pregunta que evita bloquearse esperando la perfección. El riesgo real del video no es la edición — es no grabarlo nunca porque algo "todavía no está listo".

**La pregunta**: Para cada segmento del video (los beats que elegiste en Q6), ¿qué es el mínimo aceptable para que salga en el video?

Completar la columna derecha de esta tabla — Joan decide, no Claude:

| Segmento | ¿Qué es "suficientemente bueno"? | ¿Qué lo sacaría del video? |
|----------|----------------------------------|---------------------------|
| Exploración del bioma | | |
| Combate básico vs mob | | |
| Skills en uso | | |
| Loot / drops | | |
| Boss fight | | |
| HUD visible (barras, hotbar) | | |

> Referencia: las paredes de CSG grises son el gap visual más grande en wide shots (`_coherence_target_sheet.md` BREAK #5). Las wildflowers en general scatter también (BREAK #1). Si esos gaps se ven en cámara y son inaceptables, hay que fijarlos antes de grabar.

**Tabla completada**: _______________________

---

## Q10: ¿Cómo empieza y cómo termina?

**Regla de skip**: si elegiste A (baseline) en Q1 → el inicio es el menú/character select, el cierre es cuando termina el run. Registrar y saltar a los guiones.

**La pregunta**: ¿Con qué imagen arranca el video y con qué imagen termina?

**Opciones de inicio**:

| | |
|--|--|
| **Inicio A** | Pantalla negra. Aparece el título del juego. Fundido a negro. El jugador ya está en el piso. |
| **Inicio B** | Menú principal → character select → el jugador aparece directo en el piso (sin cortes de edición). |
| **Inicio C** | Acción directa — primer segundo del video es el primer ataque o la primera silueta del bioma. Sin intro. |

**Opciones de cierre**:

| | |
|--|--|
| **Cierre A** | El boss cae. Drops en pantalla. Fundido a negro. Título del juego. |
| **Cierre B** | El jugador explora tranquilo después del boss. La cámara lenta muestra el bioma. Fade. |
| **Cierre C** | Pantalla con texto: "Work in progress — 2026" o "Wishlist en Steam" (si Q1 fue C). |

**Decisión registrada**: _______________________

---

## Tabla de decisiones (completar al final)

| Decisión | Valor |
|----------|-------|
| Objetivo del video (Q1) | |
| Plataforma / audiencia (Q2) | |
| Duración (Q3) | |
| Clase(s) a mostrar (Q4) | |
| Mobs en el video (Q5) | |
| Beats y orden (Q6) | |
| Tono de edición (Q7) | |
| Audio (Q8) | |
| Calidad mínima por segmento (Q9) | |
| Inicio / Cierre (Q10) | |

---

## Guiones borrador — punto de partida, NO decisión

> **⚠️ Estos 3 guiones son material de arranque para la conversación, no propuestas.**
> Joan los usa como: "eso me convence / eso no funciona / quiero algo entre A y B".
> Ninguno es el video. Son distintas apuestas sobre qué puede ser el video.

---

### Guion A — "Baseline honesto" (5 min, crudo, privado)

**Objetivo**: ver el estado real antes de cualquier pulido. Para Joan, no para audiencia.

1. `[0:00-0:20]` Menú principal → character select → cargar el Warrior. Sin cortes.
2. `[0:20-2:30]` Gameplay libre en P1 sin guion. El jugador explora, mata lo que se cruza, muere si pasa. Se graba todo.
3. `[2:30-4:00]` Joan busca al King Slime. Pelea completa sin cortes.
4. `[4:00-5:00]` Drops. Joan habla en voz lo que observa en tiempo real: "esto funciona, esto no está, esto falta".

**No se publica. Se guarda como referencia.**
Esfuerzo de producción: 0. Grabar y guardar.
Condición para grabar: el piso se puede completar sin crash.

---

### Guion B — "Devlog P1" (10 min, cortes básicos, devlog público)

**Objetivo**: mostrar el loop de gameplay real del P1 a una audiencia pequeña interesada en el proceso.

1. `[0:00-0:20]` Texto simple: "Dungeon Party — Piso 1 Pradera / Alpha en desarrollo".
2. `[0:20-2:00]` Exploración del bioma: Joan recorre distintas zonas del P1 (entrada, árbol gigante, zona de cristales, outpost bandidos). Cortes de los momentos sin acción.
3. `[2:00-4:30]` Combate: Warrior vs wave de slimes, luego vs bandidos. Skills en uso. Un momento de near-death.
4. `[4:30-5:30]` Loot: apertura de cofre, drop de mob, ítems en hotbar.
5. `[5:30-8:30]` Boss: Warrior vs King Slime. Pelea completa, un corte si hay mucha espera en la transición.
6. `[8:30-10:00]` Victoria. Drops. Fade a negro. Título del juego + "Dungeon Party — En desarrollo / 2026".

Audio: SFX del juego + música libre de derechos debajo.
Edición: cortes básicos (iMovie / DaVinci gratuito), sin efectos.
Condición de grabación: el bioma tiene que verse aceptable en wide shot (las paredes CSG grises son el riesgo mayor).

---

### Guion C — "Teaser Steam" (2-3 min, montaje editado)

**Objetivo**: conseguir wishlists. El espectador no sabe nada y tiene que querer más en 3 minutos.

1. `[0:00-0:10]` Negro. SFX de ambiente de caverna. Un cristal emite luz. Texto: "Dungeon Party".
2. `[0:10-0:35]` Montaje de bioma: god rays del diamante, scatter de pradera, el árbol gigante, cristales bioluminiscentes del techo. Cámara lenta, música empieza a construir.
3. `[0:35-1:15]` Montaje de combate: Warrior golpea slimes (con damage numbers), Mage dispara el rayo canalizado, Archer flechea un bandido. Cuts rítmicos con la música.
4. `[1:15-1:50]` Boss: King Slime o golem (si el moveset tree-gated está). Slow-mo en el golpe final.
5. `[1:50-2:15]` Drops del boss. El jugador los recoge. Sensación de recompensa.
6. `[2:15-2:30]` Negro. Texto: "Dungeon Party" + "Próximamente en Steam" + (fecha tentativa si existe).

Audio: música seleccionada (estilo dungeon RPG, libre de derechos o comprada). SFX del juego sobre la música en los momentos clave.
Edición: DaVinci Resolve o Premiere. Slow-mo, color grade, títulos. 4-8 horas de post.
Condición de grabación: el combate tiene que verse bien. El bioma tiene que resistir un close-up. Si los VFX de skills son muy débiles, el montaje lo va a evidenciar.

---

*Entrevista diseñada 2026-07-02. Usar en sesión de trabajo con Joan — una pregunta por vez, esperar respuesta antes de avanzar, anotar cada decisión en su slot.*
