# 🌱 World Seeds — POST-ALFA

> **⚠️ ESTO NO ES CANON VIGENTE.** Son ideas de mundo/diseño capturadas para **REVIVIR POST-ALFA**.
> No implementar, no escribir como verdad, no construir sistemas a partir de esto hasta que el
> vertical slice del Piso 1 esté grabado y el alfa (5 mapas publicables) esté encaminado.
>
> **Filtro vigente:** *"¿esto sale en el video de 10 min del demo?"* — si la respuesta es no, vive acá.
>
> - **Origen:** workflow ultracode "visión de mundo" (2026-06-05) — 3 lentes (arquitecto de mundo,
>   lore/bestiario, crítico de scope) + síntesis + crítica adversarial.
> - **Memoria engram:** `lore/world-vision-2026-06-04` (#413).
> - **Rationale:** honrar el entusiasmo creativo sin reabrir la herida que el scope reset 2026-05-18
>   cerró ("canon expansion" está en el STOP list). Estas semillas son buenas; el momento no es ahora.

---

## Qué SÍ es alfa (recordatorio de foco, costo ~0)

Antes de las semillas, lo que la visión confirmó como accionable YA para el Piso 1 — todo sale en cámara, ningún rewrite:

1. **Mantener la caverna + cristales** (no tocar geometría).
2. **Pulir biome clusters** anclados a POIs (ya integrados).
3. **Ambient cálido golden-hour** — en luminancia, NO saturación (respeta jerarquía Kimetsu: el bioma no debe competir con el color de las skills).
4. **Contraste** fogata naranja ↔ cristal azul.
5. **Reubicar spawns por lógica ecológica** (slimes↔cristales/agua, lobos↔bosque del giant_tree, aves↔pilares) — solo cambia el *dónde*, que ya es parámetro.
6. **Una frase diegética en la entrada**: "esto es una capa/dimensión, no la superficie".
7. **Framing del King Slime** como "el que comió demasiada bioluminiscencia" — culminación ecológica del piso.
8. → **Grabar el vertical slice. Mirar el video.**

---

## 🌱 Semillas estacionadas

### 0. MODELO MACRO DE MUNDO — descubrimiento → conquista → civilización (2026-06-05)
Sistema que unifica casi todas las semillas de abajo. Inspiración declarada: **Valheim** (world-state que avanza por trofeos de jefes + upgrade de mundo).

**Las 3 fases de una zona/torre:**
1. **Descubrimiento** (estado default, y el del alfa): salvaje puro. Sin civilización, sin caminos guiados. Explorás a ciegas. Transición ecológica natural entre biomas (lo que sí aplica al Piso 1 hoy).
2. **Conquista**: cada zona tiene su **jefe de zona** (el dueño local). Cada **bloque de pisos** (Joan piensa en grupos de ~5) culmina en un **jefe de Rango** — gate mayor, más complejo que los de zona (ej. el cuervo, ver #1).
3. **Civilización**: cuando un tramo ya te quedó **muy fácil** (delay de ~**5-10 pisos por encima**), la civilización entra y coloniza: construye **carreteras directas que EVITAN los jefes de zona ya vencidos**. Lo conquistado se vuelve tránsito seguro y guiado (recién acá aparecen los senderos estilo MMORPG).

**World-state colectivo (estilo Valheim):** el avance del mundo es propiedad del **SERVER/mundo** y progresa según los **logros colectivos** de quienes entran (trofeos de jefes → upgrade de mundo). Consecuencia de diseño deseada: existen **servers en distintos estados de avance** — unos vírgenes (todo descubrimiento), otros colonizados (carreteras, civilización extendida). Da replayability, identidad de comunidad por server, y razón para múltiples mundos.

**Jerarquía de bosses:**
- **Jefe de zona**: por zona/piso, dueño local (ej. **King Slime = jefe de zona del Piso 1**, ya implementado).
- **Jefe de Rango**: cada bloque (~5 pisos), gate mayor con mecánica especial (ej. cuervo "El Que Recuerda", memoria persistente). Mucho más complejo.

**⚠️ Implicación netcode (CLAVE):** el world-state persistente por server toca directo la **TOPOLOGÍA de red** (hoy P2P GodotSteam co-op; pivot futuro a server/MMO). Esta decisión NO se toma en un doc de feel — cuando se vaya a implementar, **consultar al `netcode-architect`**. La persistencia de world-state colectivo es arquitectura grande, no un detalle.

**Gradiente de REALIDAD (Joan 2026-06-05):** otra dimensión del descenso, además de civilización y dificultad. Los **pisos bajos = mundo MMORPG familiar**: físicas reales, proporciones reales, lógica conocida (el jugador se ancla en lo familiar). A medida que se avanza, **cambian las leyes**: mundos más mágicos, físicas diferentes, estructuras amorfas/raras/imposibles, cosas nuevas por descubrir. Refuerza la cosmología de capas (#3) y el límite humano: la realidad se vuelve cada vez más ajena hasta volverse insoportable. Implica un eje de diseño "lo normal → lo surreal" que justifica por qué P5 (Dimensión Rota) puede romper toda regla.

**Scope:** TODO esto es post-alfa. Lo ÚNICO que define para el alfa: el Piso 1 está en fase **descubrimiento** (salvaje, King Slime como jefe de zona) → **NO meter sendero/civilización ahora** (todavía no entró). Y el Piso 1 es el **ancla de familiaridad**: físicas reales, proporciones reales (árboles 3-5x el player, escala humana) — todo lo raro viene después. La transición ecológica + variación de tamaños + escala realista que ya se tocó hoy es exactamente lo correcto para esta fase.

### 1. Guardián-cuervo "El Que Recuerda" — jefe de RANGO (boss-gate con memoria)
Monstruo **inmortal** en un punto de paso obligado, visual tipo cuervo gigante. Mecánica de **memoria persistente por jugador**: primera vez = pelea/boss; si ya lo venciste = pasivo, te reconoce y te deja pasar (rito de paso). Refuerza el pilar GDD "tu dungeon, tu historia".
- **Costo:** ALTO — persistencia cross-run + 2 estados de IA + arte nuevo. **Compite con el King Slime** que ya es el boss-gate del Piso 1.
- **Gaps abiertos:** ¿reemplaza o complementa al King Slime? ¿persistencia individual o por party? En co-op, si uno lo venció y otro no, ¿pelea o pasa? ¿"inmortal" = nunca se mata o revive pasivo?

### 2. Bestiario endémico adaptativo — forma FUERTE (sistema)
La versión-sistema de "El bestiario de Axlin" (Laura Gallego): regiones con monstruos que mutan, pueblos con defensas específicas a sus criaturas locales, lógica combinatoria.
- **Costo:** ALTO — sistema combinatorio sin hook en el código actual. Choca con que la Torre "no tiene habitantes vivos" (es una capa de realidad, no un pueblo).
- **Lo que SÍ aplica en alfa:** solo el **principio de curaduría** (los monstruos *pertenecen* a su ambiente → cambia el spawn). La forma fuerte espera.

### 3. Cosmología de capas — "estratos sellados" (TEORÍA, no verdad)
Lectura narrativa: cada piso es una capa de realidad **más vieja y más sellada** que la anterior (Pradera = capa joven → … → Dimensión Rota = la herida). El cambio de bioma es geológico-temporal, no aleatorio. Referencia: **Made in Abyss**.
- **⚠️ Restricción dura:** el `_world_canon.md` v2.0 define la Torre como **ambigua por diseño** ("ningún jugador está equivocado"). Esta cosmología es **lore NUEVO** — el crítico la marcó como canon expansion disfrazada de reconciliación. Si algún día entra, entra como **UNA teoría del Gremio entre varias**, jamás como verdad confirmada.

### 4. Lore + conexión narrativa de los otros 4 pisos
Bosque, Hielo, Tormenta, Dimensión Rota — identidad cultural (el canon v2.0 ya sugiere raíces: ver `_world_canon.md`), bestiario, y cómo se cosen entre sí.
- **Costo:** no existen en código. **Congelado** hasta que el alfa de 1 mapa esté resuelto.

### 5. Umbral vertical + boss-gate como "costura entre capas"
Los pisos NO se conectan por adyacencia (estilo Skyrim) sino **verticalmente**: donde el mundo termina físicamente está la puerta al siguiente. El borde del mapa (hoy pared de roca orgánica de 25m) pasa de "muro de contención" a **frontera diegética** (la capa está sellada). El guardián custodia la costura.
- **Costo:** arquitectura de los 5 pisos. Sirve como **brújula** ahora, no como tarea.
- **Lo único alpha-safe relacionado:** "nombrar" el borde existente como frontera (la frase de entrada, ítem 6 de arriba).

### 6. Found-lore props elaborados (geografía con memoria)
Contar historia por el ambiente, sin cutscenes ni texto narrado:
- El `camp` POI deja de ser una fogata → **escena de supervivencia abandonada** (empalizada anti-embestida de slime, foso seco, ropa tendida, un **cráneo de King Slime cristalizado en una pica** = foreshadow del boss).
- El `giant_tree` (35m, casi toca el techo de 45m) = el ser vivo más viejo del piso, "el que sostiene la burbuja".
- **Costo:** bajo-medio (props colocados). **Nice-to-have** — no bloquea el video, diferir si compite con grabar el slice.

### 7. ⚖️ Decisión pendiente: Erindar vs caverna mineral
Conflicto de canon detectado (verificado): `_world_canon.md` (líneas 211, 289-294) canoniza el Piso 1 como **"Valle de Erindar"** (celta/irlandés: pradera húmeda, neblina verde, megalitos, círculos de piedra, colinas onduladas — **exterior, sin caverna**). Pero el **código ya divergió de facto**: `floor1_prairie.gd` implementa pradera-**caverna** con techo + cristales bioluminiscentes.
- **Estado (Joan, 2026-06-05):** "Erindar es solo un nombre, el mapa actual no tiene sentido todavía" → **no nos atamos**. Caverna se mantiene; la identidad fina se define al ver el slice grabado.
- **Reconciliación elegante (si algún día se decide):** caverna mineral **+ toques celtas** (megalitos, círculos de piedra cubiertos de musgo, bruma verde) bajo el domo. Honra el nombre canon sin derribar el techo.
- **NO tomar esta decisión a las apuradas dentro de un doc de feel.** Estacionada.

### 8. 🌡️ Coherencia de transición de biomas — gradual vs ruptura dimensional (2026-06-08)
Joan planteó: la generación procedural puede ser por-piso, pero las **transiciones de biomas entre pisos** deben ser graduales — *"no pasar del frío al calor extremo"*. Verificado en archivo: **esa regla YA es canon, escrita por Joan el 2026-04-08** en `tower_biome_system.md §C` (líneas 904-1005).

**Lo que §C ya define (no inventamos nada):**
- Ejes Minecraft-style: Temperatura (Congelante -2 → Abrasador +2), Humedad (Árido -2 → Saturado +2).
- **Regla dura:** máx **Δ2 por eje** entre pisos consecutivos (línea 947).
- Ejemplo textual (línea 952): *"Tundra(-2,-1) NO puede ir a Volcán(+2,-2): diferencia (4,1) — PROHIBIDO"* = exactamente el salto frío→calor que Joan quiere prohibir.
- Excepciones ya previstas (línea 955): **Dimensión Astral + Mundo Espejo son "comodines"** — pueden seguir a CUALQUIER bioma (rupturas intencionales de realidad).

**⚠️ Contradicción de canon detectada (verificada):** hay **dos modelos de torre sin reconciliar**:
1. `tower_biome_system.md` — 100 pisos procedural, 24 biomas, §C gradual (máx Δ2). **NO está en la lista "Canon Vigente"** de CLAUDE.md → por eso la regla §C se "perdió de vista".
2. `_world_canon.md §13` — 5 pisos culturales (Erindar celta / Aokigahara jp / Jötunheim nórdico / Al-Samum árabe / Umbral). **Vigente.** Pero Jötunheim(frío) → Al-Samum(calor) = **Δ4 = viola §C**.
   → El salto frío→calor NO es diseño: es **dos docs chocando**.

**✅ DECISIÓN (Joan, 2026-06-08): el portal es una VÁLVULA DE BYPASS de coherencia — no binario.** No es "todos los saltos son ruptura" ni "todo debe ser gradual". Es:
- **Default = gradual donde la coherencia lo permite.** Pueden existir pisos consecutivos que SÍ cambian gradualmente (§C, máx Δ2) — frío→templado→cálido, transición sentida. Esos pisos honran tu regla.
- **Portal = bypass diegético cuando NO se puede.** Cuando dos pisos adyacentes romperían §C (el salto dimensional frío→calor, ej. Jötunheim→Al-Samum = Δ4), el **portal absorbe y justifica** la discontinuidad ("cruzaste a otra dimensión sellada"). El salto se vuelve **feature**, no bug.
- El portal **telegrafía** el cambio (`floor_transitions.md`: Era-1 teleportador muestra el bioma siguiente; Era-2 rasgadura deja ver partículas del próximo piso), **NO lo suaviza**. Avisa, no maquilla.
- Mecánica equivalente a los **comodines** de §C (Dimensión Astral/Mundo Espejo pueden seguir a cualquier bioma): el portal es el comodín universal que licencia romper la adyacencia donde el diseño lo pida.

**Reconciliación de los dos modelos:** §C gradual aplica como **default** a los biomas procedurales/conectivos (y a cualquier par de pisos dentro de Δ2). El **portal** es el mecanismo que permite los saltos dimensionales (pisos culturales ancla, comodines) sin que se sientan rotos. El instinto "no frío→calor" de Joan vive en lo gradual; el portal es la excepción gobernada, no el caos.

**Anti-patrón:** NO forzar que TODO sea gradual (mataría los saltos dimensionales que son fantasía), ni que TODO sea salto-portal (perdería el "sense of place" Valheim de las transiciones sentidas). El portal decide caso por caso: ¿este par de pisos entra en Δ2? gradual. ¿No entra? portal lo bypasea y avisa.

**Lo que SÍ está sólido (sin acción):** procedural por-piso, determinista con seed, ya es canon **y está implementado** (`floor1_prairie.gd`, seed 12345 byte-identical, regenerable).

- **Costo / scope:** EJECUCIÓN 100% post-alfa. El alfa = solo P1; el demo de 10 min **nunca transiciona** a otro piso. No se rediseña nada ahora — esto es brújula. Pendiente real post-alfa: reconciliar formalmente los dos modelos de torre (100-piso procedural vs 5-piso cultural) — ese es el gap de fondo, no el salto térmico.
- **Cross-ref:** `tower_biome_system.md §C` (la regla huérfana, rescatarla del olvido al reconciliar), `floor_transitions.md` (el portal que telegrafía), `_world_canon.md §13` (los 5 pisos culturales).

---

## Anti-patrón a vigilar (el propio doc lo nombra)

El crítico de scope marcó que *"darle nombre y sentido"* es **la rendija por la que vuelve la canon expansion** que el reset cerró. Hasta la visión que generó este doc se asomó a esa rendija (introdujo la cosmología de estratos como si fuera reconciliación gratis). **Disciplina:** afirmar lore cuesta tiempo de escritura que no sale en el video. Si una idea no cambia lo que la cámara graba en el Piso 1, vive en este doc — no en el canon vigente, no en el código.
