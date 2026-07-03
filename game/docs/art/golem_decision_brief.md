# Golem — Brief de decisión de arquitectura (para Joan)

**Fecha**: 2026-07-02 · **Autor**: Claude (analista de diseño) · **Modo**: develop-before-implement (no decido — desarrollo para que Joan decida)

> **El problema en una frase (palabras de Joan):** *"hay que definir qué es lo que me gusta del golem que flota porque está diseñado con piedras separadas que se coordinan, y el que está hecho en blender, desde referencias."*
>
> Hay DOS esencias que te atraen y son distintas. Este doc las separa, mide qué cuesta cada camino, y propone híbridos serios. Al final: 4 preguntas, una decisión cada una.

---

## 0. Las tres arquitecturas en vuelo (qué es cada archivo)

| ID | Archivo | Qué es | Estado |
|----|---------|--------|--------|
| **A** | `game/scenes/enemy/golem_assembly.gd` (1848 líneas) + `golem_assembly.tscn` | Golem por **CHUNKS**: esqueleto de `Node3D` posicionado en las articulaciones + capa SOUL (resortes por chunk que hacen que cada piedra flote/laguée). Awaken = ensamblaje pila→de-pie. Muerte = `RigidBody3D` derrumbe. Moveset tree-gated cableado. | El más ambicioso y el más avanzado en mecánica. Falló eye-review una vez ("cubos sueltos con huecos, sin peso"); las mejoras (soul springs + joint-overlap) no están verificadas visualmente todavía. |
| **B** | `game/scenes/enemy/golem.gd` (430 líneas) | Golem **bespoke sólido**: una malla `golem_dp_body_01.glb` (~2.4k tris). Piedra opaca pesada, musgo pintado + flores 3D. **Ya tiene rocas flotantes opcionales de dressing.** Awaken = squash→stand (escala global). Moveset simple: puñetazo/pisotón/tirar-roca. | Visualmente resuelto en peso/opacidad (fix "se siente transparente", `golem.gd:99-103`). Su techo es la animación (no articula partes — ver `golem.gd:285-287`). Le faltan elementos firma (árbol, espirales, vides). |
| **C** | `game/tools/blender/golem_rigged.glb` (28 huesos, UniRig) + `game/scenes/dev/golem_rigged_preview.gd` | El cuerpo bespoke (B) **riggeado con UniRig** → esqueleto real `Skeleton3D`, animable por-miembro con `AnimationPlayer`. Es el ANCLA del pipeline del bestiario entero. | Rig funcional (primera anim por-miembro viva salió con esto), con **defecto conocido**: la pierna derecha "brancha" del shin izquierdo. Solo vive en escenas dev de preview, no en un golem jugable. |

---

## 1. La esencia de cada approach (qué transmite, en serio)

### A — Piedras separadas que se coordinan y flotan
- **Qué transmite**: MAGIA. Un constructo, no una estatua. Las piezas no están soldadas: se coordinan. Eso lee como "algo mágico las sostiene y las mueve juntas". Es literalmente lo que Joan nombró primero.
- **Dónde vive en código**: la capa SOUL. Cada chunk NO está rígidamente parentado a su hueso — su transform **sigue con resorte amortiguado** al hueso (`golem_assembly.gd:988-1043`, doc `:172-193`). Las piedras "flotan y se bambolean mágicamente" y laguean detrás del gesto. Los chunks livianos (puños, cabeza) laguean más; el core (pelvis, pecho) es más rígido (`SOUL_CHUNK_MULTIPLIERS`, `:185-191`).
- **Awaken de ENSAMBLAJE** (la estrella según la biblia §6.5): dormant = pila de roca = terreno → las piedras se acomodan con peso escalonado → queda de pie y alerta (`_awaken`, `:858-905`; delays por chunk `:225-248`). Es la visión que Joan marcó como "la estrella".
- **Muerte = derrumbe natural**: `RigidBody3D` pre-congelados por chunk, se sueltan con gravedad (`_build_death_rigidbodies`, `:767-793`). El derrumbe sale gratis porque las piezas YA son piezas.
- **Animación por grupos de miembros**: el esqueleto articulado permite rotar hombro→codo→puño (`:1046-1112`), no solo escalar el bulto.
- **La deuda**: cohesión. Piezas separadas leen como "roto/scatter" salvo que estén tuneadas perfecto. Ya falló una vez por esto. El `joint-overlap tweak` (empuja 11% cada chunk hacia su hueso, `:524-532`) es el parche para cerrar huecos. Sin verificar en vivo aún. 1848 líneas = mucha superficie que mantener.

### B — Cuerpo bespoke sólido (Blender, desde referencias)
- **Qué transmite**: PESO y solidez. Una masa de piedra pesada, opaca, imponente. Es exactamente el "sólido con peso" que pediste tras el fix de transparencia (`golem.gd:99-103`: mata rim glow, oscurece sombra → "roca opaca, no superficie lavada").
- **Fidelidad a refs**: sale de tus 7 imágenes vía `gen_golem.py`. Musgo pintado en la piedra + flores 3D chicas (`_grow_moss`, `:173-206`). Silueta canon troll-LOTR bottom-weighted.
- **Ojos/núcleo cyan** (canon jewel P1) con camuflaje→glow al despertar (`:344-348`).
- **La deuda**: la animación. El awaken es escala global squash→stand (`:288-289`), no articula. El propio código lo admite: *"The real awaken will need separate part meshes"* (`:285-287`). Sin rig, su techo de animación es el de B: un bulto sólido que se mueve = el mismo "un png sólido moviéndose" que ya rechazaste en la v2 del assembly. Y todavía le faltan los elementos FIRMA que la síntesis marca como GAP (`_synthesis.md:34-41`): sin árbol, sin espirales, sin vides.

### C — Rig UniRig (28 huesos)
- **Qué transmite**: no una estética distinta — un **pipeline**. Animación esquelética estándar, la MISMA que va a usar todo el bestiario (UniRig por mesh → animar por-miembro en GDScript, según CLAUDE.md nota 2026-06-14).
- **Valor estratégico**: es el ancla del bestiario. Si el golem se anima "como todo el resto", cada criatura nueva reusa el camino.
- **La deuda**: (1) defecto de rig (pierna der. brancha del shin izq.); (2) un rig de piel (skin deform suave) sobre PIEDRA puede leer mal — la piedra no debería doblarse como carne. Para un golem querés segmentos rígidos (1 chunk = 1 hueso, sin blending), que es justo lo que A hace a mano. (3) Hoy solo vive en preview dev, no jugable.

---

## 2. Observación clave (esto simplifica la decisión)

**La mecánica de combate tree-gated es ORTOGONAL al cuerpo.** El moveset firma —árbol destructible → arrancar tronco → abanicar x3 / sin árbol → pisotón+roca / snare en ambos / muerte=derrumbe— es *"el encuentro memorable del demo"* (biblia §6.5, `:253-267`). Hoy vive cableado solo en A (`golem_assembly.gd`: `_has_tree` `:161`, trunk-rip `:1181-1289`, `perform_attack` `:1800`). **Pero es una state-machine que se puede portar a cualquier cuerpo.** No estás obligado a elegir el cuerpo por el moveset: elegís el cuerpo por el FEEL, y el moveset viaja.

**Y B ya es un híbrido a medias**: `golem.gd` YA tiene rocas flotantes separadas que se elevan al despertar y orbitan (`_spawn_floating_rocks` `:227-266`, `_start_rock_orbit` `:308-317`). O sea: cuerpo sólido (B) + un gustito de piedras coordinadas (A) YA COEXISTEN en el mismo archivo. El híbrido no es teórico, está insinuado en el código.

---

## 3. Tensión con el canon endémico P1 (importante para las 3)

P1 = **caverna de cristal/diamante**. El canon dice textual: *"un golem de piedra volcánica en P1 NO tiene lógica"* (`_bestiary_visual_bible.md:126-128`; tabla `:154`: golem endémico *"solo si es cristal/geoda"*, vetas jewel cyan). La biblia §6.5 lo resuelve: no es piedra desnuda, es **"piedra viva de la pradera"** — musgo + núcleo/ojos cyan de cristal (`:186-197`).

- Las tres cargan ojos/núcleo cyan → las tres satisfacen la resolución canónica.
- **Matiz a favor de A**: un constructo de piedras separadas que flotan/coordinan lee MÁS "mágico/cristal-caverna" que un peñasco mundano. La magia visible ES la coartada endémica. Si te preocupa que "piedra" no pertenezca a la caverna-cristal, A es el que más justifica su presencia por su propia forma.

---

## 4. Las opciones (5, incluye 3 híbridos serios)

> Costos en "sesiones" = sesiones de trabajo enfocado. Riesgo = probabilidad de fallar eye-review / no leer como "una criatura".

### Opción 1 — **A puro** (chunks + soul springs, tune-to-ship)
- **Esencia que captura**: magia + coordinación + awaken-ensamblaje (la estrella) + derrumbe natural + anim por-miembro. TODA la esencia A.
- **Costo**: 2-4 sesiones (ya falló eye-review una vez; las soul springs + joint-overlap son nuevas y SIN verificar; tuning de cohesión es iterativo y sin garantía).
- **Riesgo**: ALTO. Si las piezas no cierran, vuelve a leer "scatter roto". 1848 LOC a mantener.
- **Gana el video**: el awaken de ensamblaje es un momento único y memorable si sale. El moveset tree-gated ya está acá.
- **Canon P1**: el mejor encaje (magia visible = coartada cristal-caverna).

### Opción 2 — **B puro** (bespoke sólido, animación por escala + dressing)
- **Esencia que captura**: peso + silueta canon + fidelidad a refs. Nada de coordinación/magia real.
- **Costo**: 0.5-1 sesión para shippear estático + awaken de escala + sumar elementos firma faltantes (árbol/espirales/vides). Barato.
- **Riesgo**: BAJO visualmente (ya pasó el fix de solidez), pero **techo de animación bajo**: sin rig es "el bulto sólido que se mueve". Es el look que ya rechazaste en otra forma.
- **Gana el video**: sólido y creíble parado; flojo en movimiento. Habría que portarle el moveset tree-gated desde A.
- **Canon P1**: OK (musgo + cyan), pero es el que menos justifica "por qué piedra en cristal".

### Opción 3 — **HÍBRIDO H1: núcleo bespoke sólido + placas/rocas orbitantes coordinadas** ⭐ (recomendado para el demo)
- **Qué es**: tomar el cuerpo sólido de B (peso, silueta, fidelidad) y **enriquecer el sistema de rocas flotantes que YA existe** (`golem.gd:227-317`) hasta convertirlo en un set de placas/piedras separadas que se coordinan: más piezas, lajas de hombro que se despegan y orbitan, lag por resorte (portar la idea SOUL de A como capa secundaria sobre un cuerpo que NO se desarma del todo). Awaken = el cuerpo se yergue (B) + las placas se elevan y coordinan a su sitio (esencia A). Muerte = derrumbe de las placas + cuerpo cae.
- **Esencia que captura**: peso (B) **Y** magia/coordinación (A) al mismo tiempo. Es la respuesta literal a "me gustan las dos cosas".
- **Costo**: 1-2 sesiones. El costo más bajo por unidad de esencia porque **ambas mitades ya viven en `golem.gd`** — es enriquecer, no construir de cero.
- **Riesgo**: MEDIO-BAJO. El cuerpo sólido garantiza la cohesión (nunca se ve "roto"); las piedras separadas son dressing coordinado, no la estructura → si una no cierra, no rompe la lectura de criatura.
- **Gana el video**: cuerpo imponente y creíble + halo de piedras vivas que se coordinan al despertar = las dos cosas que te gustan, sin la fragilidad de A puro.
- **Canon P1**: muy bueno (sólido mundano + placas mágicas flotantes = piedra viva + magia cristal).
- **Nota**: el awaken-ensamblaje TOTAL (todo el cuerpo se arma de una pila) se pierde parcialmente — acá el cuerpo es sólido y solo las placas se coordinan. Es un ensamblaje "de superficie", no "de esqueleto".

### Opción 4 — **HÍBRIDO H3: cuerpo bespoke RIGGEADO (B+C) + rocas de dressing**
- **Qué es**: riggear el cuerpo sólido con UniRig (arreglar el defecto de la pierna), animar por-miembro vía `Skeleton3D` estándar, mantener las rocas flotantes como acento. Es "el golem como una criatura estándar del bestiario".
- **Esencia que captura**: peso (B) + animación esquelética del pipeline (C) + un toque de A (rocas dressing).
- **Costo**: 1-2 sesiones si el defecto de rig es arreglable rápido; si UniRig hay que re-correr, +1.
- **Riesgo**: MEDIO. Skin deform suave sobre piedra puede leer "gomoso" (la piedra no se dobla). Mitigable con weighting rígido por segmento, pero eso empieza a parecerse a hacer A a mano.
- **Gana el video**: golem animado consistente con el resto del bestiario; menos "único" pero sólido y escalable. Pierde el awaken-ensamblaje (la estrella).
- **Canon P1**: OK, igual que B.
- **Valor estratégico**: el mayor — prueba el pipeline UniRig del bestiario entero con la criatura más difícil.

### Opción 5 — **HÍBRIDO H2: chunks de A montados sobre un Skeleton3D real (A+C)**
- **Qué es**: reemplazar el esqueleto hecho a mano de A (`Node3D` bones, `:377-458`) por un `Skeleton3D` de UniRig, pesando cada chunk RÍGIDAMENTE a un hueso (sin blend → sigue siendo piedra). Mantener la capa SOUL como secundaria. Unifica: coordinación de chunks (A) + pipeline del bestiario (C).
- **Esencia que captura**: toda la de A + integración al pipeline (C).
- **Costo**: 3+ sesiones. El más caro.
- **Riesgo**: ALTO. Es la refactorización más grande; hereda el riesgo de cohesión de A MÁS el defecto de rig de C.
- **Gana el video**: potencialmente lo mejor de todo, pero es el camino menos seguro para una fecha de demo.
- **Recomendación**: es el norte POST-demo si A demuestra que el look funciona. Hoy es sobre-ingeniería para el video de 10 min.

---

## 5. Matriz de decisión

| | Peso | Magia/coord. | Awaken-ensamblaje | Anim calidad | Pipeline bestiario | Costo (ses.) | Riesgo | Fit canon P1 |
|---|------|--------------|-------------------|--------------|--------------------|--------------|--------|--------------|
| **1. A puro** | media | ★★★ | ★★★ (la estrella) | ★★★ | ✗ (esqueleto a mano) | 2-4 | ALTO | ★★★ |
| **2. B puro** | ★★★ | ✗ | ✗ (solo escala) | ★ | ✗ | 0.5-1 | bajo | ★★ |
| **3. H1 sólido+orbitantes** ⭐ | ★★★ | ★★ | ★★ (de superficie) | ★★ | parcial | 1-2 | med-bajo | ★★★ |
| **4. H3 bespoke rigged** | ★★★ | ★ (dressing) | ✗ | ★★★ | ★★★ | 1-2 | medio | ★★ |
| **5. H2 chunks+skeleton** | media | ★★★ | ★★★ | ★★★ | ★★★ | 3+ | ALTO | ★★★ |

**Lectura del analista** (no es decisión — es mi recomendación con evidencia): para EL DEMO, **Opción 3 (H1)** es la de mejor relación esencia/riesgo/costo porque responde literalmente al "me gustan las dos" reusando código que ya existe. **Opción 4 (H3)** es la jugada estratégica si tu prioridad es probar el pipeline del bestiario ya. **Opción 5 (H2)** es el norte post-demo. **Opción 1 (A puro)** solo si el awaken-ensamblaje total es innegociable Y aceptás el riesgo de tuning. En los 4 casos, el moveset tree-gated se porta desde A (es ortogonal al cuerpo).

---

## 6. Preguntas para Joan (una decisión cada una)

1. **La estrella**: ¿El **awaken de ENSAMBLAJE completo** (todo el cuerpo se arma de una pila de roca en el suelo) es INNEGOCIABLE para el demo? Si sí → camino A/H2. Si te alcanza con un "ensamblaje de superficie" (cuerpo sólido que se yergue + placas que se coordinan encima) → H1.

2. **Peso vs magia, si tuvieras que priorizar UNA para el primer pase jugable**: ¿un cuerpo que se siente PESADO y sólido sí o sí (aunque las piedras coordinadas sean solo dressing), o piedras que se coordinan/flotan sí o sí (aunque arriesgue leer "suelto")?

3. **Pipeline**: ¿Querés que el golem valide el pipeline UniRig del bestiario AHORA (H3/H2, se anima como todo el resto), o el golem puede ser un caso especial (animado a mano por chunks/tweens) y el pipeline se prueba con una criatura más simple después?

4. **Moveset firma**: confirmo que el combate tree-gated (árbol destructible → arrancar tronco → abanicar x3 / pisotón+roca sin árbol / derrumbe al morir) es el gancho del demo y debe sobrevivir en CUALQUIER opción que elijas — ¿correcto? (Es portable entre cuerpos; solo quiero confirmar la prioridad antes de anclarlo.)

---

## 7. ✅ DECISIÓN (Joan, 2026-07-02)

**Visión de largo plazo (palabras de Joan):** un montón de escombros en el suelo; cuando el player se acerca, las piedras **se levantan EN SINTONÍA** para armar al golem. El árbol tiene lógica narrativa: **creció en él mientras estaba quieto** — ahora que se mueve, lo puede usar (fundamento del moveset tree-gated).

**Arquitectura elegida: ESQUELETO INVISIBLE + piedras ANCLADAS a él que se sincronizan** (la propuesta original de Joan). Correcciones al brief:
- ❌ Piedras con movimiento INDIVIDUAL → descartado hace tiempo (era lo que fallaba).
- ❌ H1 "placas orbitantes como dressing" → malinterpretaba la idea; NO es dressing sobre cuerpo sólido.
- ✅ Es la arquitectura de **A** (joint-skeleton + chunks anclados, `golem_assembly.gd`), con norte post-demo **H2** (Skeleton3D real, chunks rígidos 1-hueso, sin blend).

**Barra de calidad del demo (Joan):** jugabilidad **más o menos completa** (awaken en sintonía + moveset tree-gated + derrumbe funcionando contra el player) > estética. El gate visual NO es 10/10.

**Moveset tree-gated: CONFIRMADO** ("esto fue lo último que hablamos"). Sobrevive en cualquier iteración del cuerpo.

**Pipeline UniRig:** no bloquea al golem — gameplay-first; el pipeline se valida donde convenga.
