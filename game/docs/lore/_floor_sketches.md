# Floor Sketches — Los 5 Pisos de la Torre

**Version**: 0.1-draft
**Fecha**: 2026-06-05
**Estado**: BOCETO ESPECULATIVO — NO es canon afirmativo. No implementar, no escribir como verdad
afirmativa, no construir sistemas a partir de esto hasta que el vertical slice del Piso 1 esté
grabado y el alfa (5 mapas publicables) esté encaminado. Vive aquí como fuente de inspiración y dirección.

> **Filtro vigente (scope reset 2026-05-18):** "¿esto sale en el video de 10 min del demo?"
> Piso 1 = sí. Pisos 2-5 = boceto estacionado, exactamente igual que `_world_seeds_postalpha.md`.
>
> **Fuentes respetadas**: `_world_canon.md` v2.0, `_art_canon.md` v2.0, `_world_seeds_postalpha.md`,
> conversación Joan-Claude 2026-06-05 (modelo descubrimiento→conquista→civilización, bestiario Axlin,
> gradiente de realidad, reglas de coherencia ecológica, Guardián-Cuervo como jefe de Rango P5).

---

## Marco — cómo leer estos bocetos

Cada piso tiene cuatro ejes:

| Eje | Pregunta |
|-----|----------|
| **Bioma + paleta** | ¿Dónde estás? ¿Qué ves? (toon + contraste Kimetsu) |
| **Bestiario Axlin** | ¿Quién vive acá? ¿Por qué pertenece a este lugar? |
| **Gradiente de realidad** | ¿Cuánto se aleja este piso de las leyes familiares? |
| **Costura al siguiente** | ¿Cómo el jugador siente que lo que viene es diferente? |

**Principio bestiario Axlin**: las criaturas son endémicas — pertenecen a su ambiente, su morfología es
legible desde el nicho que ocupan. Un slime que come bioluminiscencia tiene lógica. Un golem de piedra
volcánica en P1 (que es caverna con cristales) no la tiene. La lógica ecológica es el criterio de
curaduría, no un sistema adaptativo (eso sería post-alfa).

**Gradiente de realidad**: P1 es el ancla — proporciones reales, físicas reales, escala humana.
A mayor profundidad, más ajena se vuelve la realidad. P5 puede romper toda regla visual y física.
Esto justifica el eje de diseño y le da coherencia al aparente caos del Umbral Fragmentado.

**Reglas de coherencia ecológica** (acordadas con Joan 2026-06-05, aplican a todos los pisos):
- **Hidrología**: el agua fluye alto → bajo; los ríos necesitan caudal y fuente; los lagos están en
  depresiones; el agua no aparece en una cima sin razón.
- **Vegetación por humedad/luz**: hongos en húmedo/sombrío; vegetación densa cerca del agua;
  rala en zonas altas/secas/rocosas.
- **Proporciones reales**: player 1.8m; árboles 3-5x = 5.4-9m (birch 5.45m, common 7.26m,
  maple 6.64m en assets actuales).
- **Spawns por nicho**: criaturas donde ecológicamente tienen sentido.
- **Geología**: rocas en zonas altas y secas; acantilados donde hay diferencia de nivel.
- **Transiciones ecológicas**: deshilachar entre biomas, no cortar seco.

---

## Piso 1 — Pradera Interior "Erindar"

> **Estado**: IMPLEMENTADO. Lo que sigue es descripción del estado actual + intención canónica.
> El nombre "Erindar" es placeholder — ver conflicto en `_world_seeds_postalpha.md` §7.

### Bioma + paleta/mood

Caverna enorme (escala ~600×600m) con techo de roca mineral de donde cuelgan cristales
bioluminiscentes que arman una especie de vía láctea subterránea. Un diamante emisivo gigante en el
techo central actúa como "sol de caverna" — la fuente de luz principal, cálida y dorada. El suelo
es pradera de verdad: pasto, agua, árboles, flores.

No es exterior. Es una burbuja de vida dentro de la roca.

**Paleta** (implementada, ver `_art_canon.md` §5.2):
- Dorado diamante `#F5D576` — el "sol" del techo
- Verde pradera pastel `#8FAE6B`
- Azul-lavanda cristales `#7A8FC4`
- Blanco cascadas `#F5F5F2`

**Contraste Kimetsu**: bioma cálido + colorido. Las skills de las 3 clases alpha (naranja Warrior,
cian/azul Mage, verde Archer) explotan sobre el fondo dorado-verde. Festivo, divertido — pisos 1-20
según el eje `_art_canon.md` §2.4.

**Cielo propio**: NO hay cielo exterior. El "cielo" es el techo de caverna con cristales y diamante.
God rays caen desde el diamante — firma visual del piso. Toda diferencia de hora del día es simulada
por el parpadeido suave del diamante.

**Toques celtas** (reconciliación elegante propuesta, no implementada): megalitos cubiertos de musgo,
círculos de piedra enterrados bajo el pasto, bruma verde en zonas bajas cerca del agua.
Si se agregan, refuerzan el nombre Erindar sin derribar el techo de caverna.

### Bestiario endémico (implementado + nicho)

| Criatura | Nicho ecológico | Por qué pertenece acá |
|----------|-----------------|----------------------|
| **Slime** | Zonas de cristales bioluminiscentes, agua estancada | Come la bioluminiscencia de los cristales. Su cuerpo semitransparente brilla con el color que acaba de absorber. Lógica: parásito de fuente de luz |
| **Mini Slime** | Mismo nicho que Slime, radios menores | Cría/estadio juvenil. Grupos de 3-5. Se forman por fisión del Slime adulto |
| **Wolf** | Zona del giant_tree, transición bosque-pradera | Predador territorial del bosque del árbol. Patrulla el perímetro de los árboles grandes |
| **Bird / Hawk** | Pilares de piedra, zonas elevadas | Anidan en lo alto. Los pájaros son presa; los halcones son cazadores de corriente de aire caliente del diamante |
| **Fox** | Lindero pradera-bosque | Carroñero oportunista. Aparece cerca de camps abandonados |
| **Bandit (melee/archer)** | Outpost, caminos | Humanos que llegaron antes que el jugador y se quedaron. No pertenecen al bioma — son evidencia de que otros estuvieron acá |

**Mimic** (piso 1): camuflado como cofre en zonas de loot. No es endémico — es un parásito de la
dinámica de exploración, no del ecosistema mineral.

**Jefe de zona**: **King Slime** — el que comió demasiada bioluminiscencia. Versión aberrante del
ciclo natural: absorció tanta luz del diamante que su cuerpo se volvió denso, iridiscente, casi
sólido. Culminación ecológica del piso: si los slimes son el ecosistema, el King Slime es su
exceso. Implementado como boss gate.

### Gradiente de realidad

**Nivel de familiaridad: MÁXIMO.** P1 es el ancla. Físicas de Godot sin modificar. Gravedad
estándar. Proporciones reales. La única "rareza" es que es una caverna con vida interior — pero
la vida tiene sentido (luz = cristales = slimes = predadores = ciclo).

El jugador llega sabiendo cómo se mueve el mundo. Todo funciona como espera. Eso es
intencional: el contraste con pisos posteriores solo funciona si P1 fue seguro.

### Costura al siguiente piso

El borde del piso es una pared de roca orgánica de 25m. Más allá: oscuridad. La frontera es
física, no narrativa todavía. La semilla post-alfa es que esa pared sea una frontera diegética
(la capa está sellada) y el gate al P2 esté al final de ese borde — custodiado por lo que sea
que vive al otro lado.

---

## Piso 2 — Bosque del Lindero (Aokigahara)

> **Estado**: BOCETO ESPECULATIVO. No implementar. Refs en `_art_canon.md` §5.3.

### Bioma + paleta/mood

Canopy tan denso que no se ve el techo de caverna. La luz es indirecta — filtrada por toneladas de
follaje, llegando al suelo como destellos verdes y ámbar. Hongos gigantes (2-3m) generan la única
fuente de luz confiable: bioluminiscencia cian. El suelo está cubierto de raíces expuestas, agua
negra en pozas, musgo grueso.

El silencio es antinatural. Los pájaros que en P1 gritaban, acá no cantan.

**Paleta** (propuesta, ver `_art_canon.md` §5.3):
- Marrón profundo `#3D2818` — troncos dominantes
- Verde oscuro canopy `#2E3D24`
- Cian hongos bioluminiscentes `#7ECFD8` — los únicos puntos de luz fría
- Dorado luciérnagas `#F5C76A` — acento emisivo cálido, muy esporádico

**Cielo propio**: no hay cielo — solo canopy. El "horizonte" es la pared de árboles. El único
arriba es la espesura. La ausencia del diamante dorado de P1 es el primer shock ambiental.

**Contraste Kimetsu**: bioma desaturado, oscuro, verde apagado. Los combates acá son la primera
vez que las skills se ven como la única fuente de color — el contraste sube respecto a P1.

**Raíz cultural**: Aokigahara japonés. No el aspecto turístico contemporáneo — el lore mitológico:
bosque donde los espíritus se quedan porque los árboles son tan densos que pierden el camino de
vuelta. Torii en ruinas aparecen entre los troncos. No son decoración — son evidencia de que
alguien intentó marcar el camino hace mucho tiempo.

**Coherencia hidrológica**: el agua de P1 (cascadas, ríos) tiene que ir a algún lado. P2 recibe
ese caudal: pozas negras de agua oscura acumulada en depresiones. Los hongos crecen donde el
suelo está más húmedo (cerca de las pozas). Las raíces más grandes rodean las zonas de agua.

### Bestiario endémico

| Criatura | Nicho ecológico | Por qué pertenece acá |
|----------|-----------------|----------------------|
| **Kitsune** (nuevo) | Zonas de torii ruinosos | Guardian yokai. Custodian los umbrales que quedan. No atacan salvo que el jugador cruce sin respeto (romper el torii = aggro) |
| **Yamabiko** (nuevo) | Cañadas entre árboles altos | Criatura del eco — imita sonidos. Atrae a los jugadores lejos del grupo repitiendo voces conocidas. Nicho: acústico |
| **Tengu** (nuevo) | Copas de los árboles más altos | Guardián aéreo que baja cuando el jugador se queda quieto demasiado tiempo. No le gusta la indecisión |
| **Planta carnívora** | Pozas de agua, suelo húmedo | Predador de oportunidad. Se abre cuando hay movimiento cercano. No es una criatura — es el terreno mismo que ataca |
| **Telaraña / araña** | Zonas entre troncos, horizontalmente | Criaturas que tejen redes entre árboles. La telaraña ralentiza. La araña patrulla su red |

**Jefe de zona** (boceto): **El Nurikabe** — pared-criatura de madera y musgo, inmenso. En la
mitología japonesa, el Nurikabe es un yokai que bloquea el camino de los caminantes nocturnos.
Acá es un boss que textualmente es una pared del bosque que cobra vida. Mecánica: destruir
partes específicas para abrir el paso. El mapa no tiene salida mientras el Nurikabe vive.

### Gradiente de realidad

**Nivel: MISTERIOSO.** Las físicas son reales pero el ambiente las distorsiona. El sonido no se
comporta bien (yamabiko). La luz es incoherente (hongos iluminan sin fuente de calor). Los árboles
son demasiado grandes para haber crecido en una caverna (en P1 los árboles tenían escala real;
en P2 los troncos son el doble de anchos, como si el tiempo pasara diferente).

No es surreal todavía. Es un bosque "como debería ser" pero llevado al límite — demasiado denso,
demasiado silencioso, demasiado húmedo.

### Costura al siguiente piso

Al fondo del bosque, el suelo empieza a helar. Las pozas de agua negra tienen una capa de hielo
en la superficie. La temperatura baja sin que haya viento. Los árboles se vuelven más ralos. La
última criatura que el jugador ve antes del gate es un Kitsune inmóvil mirando hacia adelante —
no lo ataca, pero tampoco se mueve. El gate está más allá de él.

---

## Piso 3 — Jotunheim

> **Estado**: BOCETO ESPECULATIVO. Refs: `_art_canon.md` §5.4 (las ruinas del peregrino están
> mezcladas con la propuesta Jotunheim de `_world_canon.md` §13 — reconciliar al implementar).

### Bioma + paleta/mood

Glaciares y montañas de hielo a escala de gigante. Las proporciones empiezan a mentir: todo en
este piso es demasiado grande. Las "colinas" son más altas que los árboles más altos de P2. Las
"piedras" del suelo son bloques de hielo del tamaño de una casa. El jugador se siente pequeño
de una manera que en P1 y P2 no ocurrió.

Noche perpetua con aurora boreal. El único cielo visible acá (el primero que no es un techo de
caverna) es negro con luces que danzan. El frío es mecánica: slow acumulado por exposición,
zonas de refugio con fogatas temporales.

**Paleta** (propuesta, ver `_art_canon.md` §5.4 + world_canon §13 P3):
- Blanco hielo dominante + azul profundo `#A8D4E8`
- Negro roca volcánica bajo el hielo
- Verde aurora boreal como firma del cielo
- Hueso y gris piedra para ruinas que asoman entre el hielo

**Cielo propio**: primer piso con cielo exterior real — pero es noche eterna. Aurora boreal verde
y violeta. El "sol" que el jugador busca inconscientemente no está. Solo el frío y la danza de luz.

**Contraste Kimetsu**: el piso más hostil visualmente hasta acá. Fondo blanco/azul desaturado,
frío. Las skills explotan con el contraste máximo contra ese fondo — especialmente el naranja del
Warrior y el cian del Mage que se confunden con el hielo hasta que están activadas.

**Coherencia hidrológica**: el agua de P2 congeló. Los ríos de P1 y las pozas de P2 llegan acá
como glaciares lentos. La lógica vertical de agua que fluye de pisos altos hacia pisos bajos se
mantiene: el hielo en P3 es el agua de arriba congelada.

**Raíz cultural**: Jotunheim nórdico. Los Jötnar (gigantes de hielo) son los habitantes originales.
Las ruinas de estructuras a escala titánica son evidencia de que una civilización de gigantes
existió acá — sus mesas son el piso, sus tazas son el lago helado.

### Bestiario endémico

| Criatura | Nicho ecológico | Por qué pertenece acá |
|----------|-----------------|----------------------|
| **Jötunn menor** (nuevo) | Llanuras heladas, a campo abierto | Gigante de hielo a escala 3x player. Territorial, lento, golpea fuerte. Su piel es roca volcánica; el hielo creció encima |
| **Lobo ártico** | Cañadas entre glaciares, caza en manada | El wolf de P1 adaptado al hielo — pelaje blanco, más rápido en superficies heladas, ataque de empuje que hace slide al jugador |
| **Cuervo explorador** (nuevo) | Zonas elevadas, ruinas de gigantes | Cuervo de tamaño anormal. Carroñero que sigue al jugador. No ataca solo — pero el boss de Rango del P5 "El Que Recuerda" es de esta especie, y estos cuervos son su red de observación |
| **Araña de hielo** (nuevo) | Interior de ruinas congeladas, cuevas | Teje redes de hielo que inmovilizan. Aguarda en las sombras de los gigante-artefactos. Nicho: predador de emboscada en zonas cerradas |

**Jefe de zona** (boceto): **El Jarl-Jötunn** — el último gigante consciente de Jotunheim. No
es el más grande — es el que todavía recuerda para qué sirven las ruinas. Mecánica: combate en
dos fases — erguido (golpes de área) y caído de rodillas (ataque de helada que cubre el suelo).
Al morir, el hielo de una sección del piso se funde, revelando un pasaje hacia abajo.

### Gradiente de realidad

**Nivel: FÍSICAS ALTERADAS.** Las proporciones ya mienten — las cosas son demasiado grandes. El
frío es mecánica directa en el jugador (no solo visual). La aurora boreal pulsa de formas que no
corresponden al movimiento natural de plasma solar. Los cuervos tienen ojos que reflejan luz
donde no debería haberla.

Todavía hay lógica interna coherente. Es un mundo de gigantes donde el jugador es el pequeño.
Raro, pero comprehensible.

### Costura al siguiente piso

El hielo se empieza a romper. Grietas de luz anaranjada bajo la superficie. El final de P3 huele
a ozono. El gate está en el fondo de una grieta entre dos glaciares — y del otro lado se escucha
viento que suena como estática eléctrica.

---

## Piso 4 — Desierto de Al-Samum

> **Estado**: BOCETO ESPECULATIVO. Refs en `_world_canon.md` §13 P4, `_art_canon.md` §5.5.

### Bioma + paleta/mood

Tormenta de arena permanente. El horizonte nunca se ve limpio. La visión es un recurso escaso:
cuando el viento baja, hay quizás 30 segundos de visibilidad antes de que otra ráfaga entierre
todo. El suelo son dunas de arena ardiente — moverse lento es seguro; moverse rápido en la
dirección equivocada es perderse.

Bajo la arena: ruinas de palacios imposibles. Columnas que no deberían sostenerse solas. Oasis
que aparecen y desaparecen (la arena se mueve, los descubre y los cubre). Agua en el oasis —
pero el agua acá no es segura. Es el primer piso donde un recurso aparentemente seguro puede
matar.

**Paleta** (propuesta, ver `_art_canon.md` §5.5):
- Ocre arena `#C0A88C` — dominante total
- Rojo tormenta cuando la arena está alta
- Negro noche de oasis, único descanso visual
- Dorado atardecer en los breves momentos de calma

**Cielo propio**: cielo rojo-naranja por el polvo de arena. El sol es una mancha desdibujada.
A veces desaparece. En los oasis nocturnos, el cielo se limpia y aparecen estrellas — las primeras
estrellas reales del juego. Pero son demasiadas, y se mueven.

**Contraste Kimetsu**: piso de alta tensión. El bioma hostil — fondo rojo-arena oscuro — hace que
cada cast de skill sea visible desde lejos como una señal de supervivencia. El árabe al que
apunta la raíz cultural `_world_canon.md` §13 sugiere Djinn que son elementales de tormenta —
son fuego y viento encarnados, y visualmente chochan directo con las paletas de las skills.

**Coherencia**: el agua viene de las capas superiores (glaciares de P3 derretidos, filtrados por
la roca). Llega a P4 caliente y bajo tierra. Los oasis son afloramientos de esa agua profunda.

**Raíz cultural**: árabe/persa — Las Mil y Una Noches, alquimia medieval, tormentas de simoom.
Los Djinn no son demonios — son elementales que preexisten a cualquier civilización que haya
pasado por este piso.

### Bestiario endémico

| Criatura | Nicho ecológico | Por qué pertenece acá |
|----------|-----------------|----------------------|
| **Djinn de arena** (nuevo) | Núcleo de tormentas, dunas altas | Es la tormenta personificada. No tiene cuerpo sólido — es arena que tiene forma de criatura mientras el viento lo sostiene. Mecánica: atacar durante la tormenta los refuerza; en calma son vulnerables |
| **Escorpión gigante** (ya existe como scene) | Zonas rocosas, ruinas enterradas | Predador de emboscada. Se entierra bajo la arena. El jugador pisa encima antes de verlo |
| **Serpiente (ya existe)** | Oasis, agua | Custodia el agua. No es maligna — pero el agua en P4 es territorio, y las serpientes lo defienden |
| **Esfinge (nuevo)** | Ruinas expuestas, columnas altas | No ataca directamente. Bloquea el paso. Mecánica de acertijo o habilidad especial requerida para pasar. Tonal: los enigmas en el desierto son parte de la cultura del piso |

**Jefe de zona** (boceto): **El Rey Djinn** — cuando el viento de todo el desierto se une en un
punto. No tiene forma fija. Mecánica: el arena borra el suelo del jugador (el boss cambia el
terreno como mecánica principal). Derrotarlo limpia la tormenta del piso por el resto del run.

### Gradiente de realidad

**Nivel: LÓGICA DOBLADA.** Las estrellas se mueven cuando no deberían. El agua en los oasis
a veces refleja un cielo que no corresponde al de arriba. Las ruinas no tienen razón estructural
para estar de pie. Los Djinn son viento que tiene memoria.

El jugador ya no puede confiar en que "el agua es segura" o "las estrellas son estrellas". Cada
suposición que trajo de P1 tiene una excepción en este piso.

### Costura al siguiente piso

La arena termina. No gradualmente — hay una línea donde la arena se corta y el suelo del otro lado
no tiene lógica. Es geometría pura: triángulos y cuadrados de roca negra brillante, como si el
mapa se hubiera generado a mano y alguien olvidó terminar la textura. El jugador cruza esa línea
y las físicas cambian.

---

## Piso 5 — Umbral Fragmentado

> **Estado**: BOCETO ESPECULATIVO. Refs en `_world_canon.md` §13 P5, `_art_canon.md` §5.6 + §4.5.
> El Guardián-Cuervo "El Que Recuerda" es JEFE DE RANGO — distinto a los jefes de zona
> de los pisos anteriores. Ver `_world_seeds_postalpha.md` §1 para detalles del concepto.

### Bioma + paleta/mood

Fragmentos de todos los pisos anteriores flotan en vacío geométrico. Un pedazo de pradera con
pasto que cuelga boca abajo. Una columna de hielo suspendida sin apoyo. Una duna de arena que
gira lentamente en el aire. La gravedad aquí no es una ley — es una sugerencia.

El fondo es negro absoluto. No la oscuridad de una caverna — el negro que hay cuando no hay nada.
Los fragmentos emiten su propia luz (el diamante de P1 brilla en su pedazo de pradera; los hongos
de P2 siguen brillando en su sección de bosque). Sin fuente de luz unificada.

**Paleta** (propuesta — inestable por diseño, ver `_art_canon.md` §4.5 + §8):
- Negro vacío como base total
- Acentos hipersaturados de todos los pisos anteriores (verde P1, cian hongos P2, blanco hielo P3,
  ocre arena P4) — simultáneos, inestables
- Outline glow `+40%` (toon shader inverso, canon `_art_canon.md` §8)

**Cielo propio**: no hay cielo. Hay fragmentos de todos los "cielos" anteriores — pedazos del techo
de cristal de P1, fragmentos de aurora de P3, una sección de cielo de estrellas de P4 que gira.
El único elemento nuevo son los ojos. En el vacío negro entre fragmentos, de vez en cuando,
parpadean.

**Contraste Kimetsu**: el piso más extremo del eje. Fondo negro total + acentos hipersaturados
de los fragmentos = cada skill es un evento visual absoluto. Es el pico del contraste — "Kimetsu
puro" según `_art_canon.md` §2.4.

**Sin raíz cultural única**: por diseño. El Umbral Fragmentado es el lugar donde las categorías
se rompen, incluyendo las culturales. Es neutral cross-cultural — donde todo converge sin ser
ninguno.

### Bestiario endémico

En el Umbral no hay fauna local en el sentido clásico. Lo que vive acá son tres tipos:

| Tipo | Descripción | Nicho |
|------|-------------|-------|
| **Manifestaciones geométricas** | Formas imposibles (Möbius, tetraedros recursivos) que se mueven con intención. No son criaturas — son el Umbral siendo hostil | Zones de vacío negro, aparecen cuando el jugador se queda solo entre fragmentos |
| **Ecos de pisos anteriores** | Sombras de bosses ya derrotados (King Slime sin color, contorno del Nurikabe, silueta del Jarl-Jötunn). No idénticos — son la memoria del Umbral de lo que cruzó | Flotan en los fragmentos de su piso de origen. Más fuertes cuanto más tiempo lleva el jugador en el Umbral |
| **Los que no volvieron** | Figuras humanas silenciosas en los bordes de los fragmentos, mirando hacia el vacío. No atacan. Tampoco responden | Evidencia de lo que pasó con los aventureros que llegaron al Umbral y no encontraron el camino de vuelta |

### Jefe de Rango — El Guardián-Cuervo "El Que Recuerda"

**Rol**: no es el jefe del piso 5 en el sentido de "mob más fuerte". Es el **guardián del umbral
entre la torre y lo que hay más allá**. Es el jefe de RANGO del primer bloque de 5 pisos —
el gate final, diferente en naturaleza a los jefes de zona.

**Concepto central** (de `_world_seeds_postalpha.md` §1): tiene **memoria persistente por jugador**.
- Primera vez que llega un jugador: el Guardián pelea. Es una batalla de rito de paso.
- Si el jugador ya lo venció antes (en otro run): el Guardián está inmóvil, mirando. No ataca.
  Lo reconoce. Lo deja pasar. El rito ya ocurrió — no necesita repetirse.

Esto refuerza el pilar GDD "tu dungeon, tu historia" y diferencia al jugador veterano del novato
de la forma más directa posible: el boss más imponente del bloque simplemente no existe como
amenaza para quienes lo superaron.

**Visual** (boceto): cuervo gigante — escala 5-6m de envergadura. Negro absoluto con reflejos que
cambian según el ángulo (azul, violeta, verde oscuro). Los ojos son los que se ven parpadear en
el vacío negro entre fragmentos. Cuando está en reposo y reconoce al jugador, cierra los ojos y
dobla las alas.

**Mecánica de la primera pelea** (boceto): el Guardián usa fragmentos del piso como proyectiles y
plataformas. Cambia la gravedad local. En la fase final, el vacío negro se expande — el jugador
tiene que mantenerse en los fragmentos que el Guardián no ha destruido todavía.

**Gaps abiertos** (NO decidir en este doc):
- En co-op: si un jugador ya lo venció y el otro no, ¿pelea o pasa?
- ¿"Inmortal" significa que no se puede matar en runs posteriores o que se restaura entre runs?
- ¿La persistencia es individual (por Steam ID) o por party/server?
→ Consultar al netcode-architect cuando sea el momento. Hasta entonces, el concepto vive acá.

### Gradiente de realidad

**Nivel: RUPTURA TOTAL.** Las físicas de Godot no aplican sin modificación. Gravedad variable.
Tiempo no-lineal (el jugador puede ver su propia sombra moverse antes de que él se mueva). Los
fragmentos que debería ser sólidos son atravesables si el jugador tiene momentum suficiente.
La diferencia entre plataforma y abismo es subjetiva.

El jugador llegó al límite de lo que la realidad puede sostener. Más allá del Guardián-Cuervo,
nadie sabe qué hay — y los que llegaron no volvieron a contar nada coherente.

### No hay costura al siguiente piso

P5 es el final del primer bloque. Lo que hay después del Guardián-Cuervo no está en este doc —
ni en el canon actual. La torre tiene más pisos. Los que llegaron al 50+ cuentan cosas
contradictorias. Los que llegaron al 100, si existe, no volvieron (`_world_canon.md` §3).

---

## Tabla resumen — los 5 pisos de un vistazo

| Piso | Nombre (canon v2.0) | Bioma | Cielo propio | Boss zona | Nivel realidad |
|------|--------------------|----|-------|-----------|----------------|
| 1 | Valle de Erindar | Pradera-caverna mineral | Techo cristales + diamante | King Slime | Ancla familiar |
| 2 | Selva de Aokigahara | Bosque denso, silencioso | Canopy sin techo visible | Nurikabe (boceto) | Misterioso |
| 3 | Jotunheim | Glaciares a escala gigante | Noche con aurora boreal | Jarl-Jötunn (boceto) | Físicas alteradas |
| 4 | Desierto de Al-Samum | Tormenta de arena permanente | Rojo polvo / estrellas que se mueven | Rey Djinn (boceto) | Lógica doblada |
| 5 | Umbral Fragmentado | Vacío geométrico + fragmentos | Negro absoluto + ojos | El Guardián-Cuervo "El Que Recuerda" (JEFE DE RANGO) | Ruptura total |

---

## Notas de autoría

Este doc fue escrito en sesión Joan-Claude 2026-06-05 como captura de ideas desarrolladas en
conversación. Las descripciones de P2-P5 son especulativas — ninguna tiene geometría, código,
ni assets. Están acá para que cuando llegue el momento, haya un punto de partida coherente con
el tono, la ecología, y la progresión del gradiente de realidad ya acordados.

**Referencia de consistencia**: antes de implementar cualquier piso 2-5, releer:
- `_world_canon.md` §13 (nombres y conceptos base por piso)
- `_art_canon.md` §5 (params de lighting y paleta por piso)
- `_world_seeds_postalpha.md` (modelo macro de mundo + gaps abiertos)
- Este doc (bestiario + gradiente + costuras)
