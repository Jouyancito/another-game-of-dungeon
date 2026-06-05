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

### 1. Guardián-cuervo "El Que Recuerda" (boss-gate con memoria)
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

---

## Anti-patrón a vigilar (el propio doc lo nombra)

El crítico de scope marcó que *"darle nombre y sentido"* es **la rendija por la que vuelve la canon expansion** que el reset cerró. Hasta la visión que generó este doc se asomó a esa rendija (introdujo la cosmología de estratos como si fuera reconciliación gratis). **Disciplina:** afirmar lore cuesta tiempo de escritura que no sale en el video. Si una idea no cambia lo que la cámara graba en el Piso 1, vive en este doc — no en el canon vigente, no en el código.
