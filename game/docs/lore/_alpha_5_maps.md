# Los 5 Mapas Alpha — Dungeon Party

**Versión**: 0.1
**Fecha**: 2026-07-03
**Estado**: Cierra CLAUDE.md próximos pasos paso 4 (pendiente desde scope reset 2026-05-18).
**Fuente**: Entrevista de mundo con Joan — 2026-07-02/03. Ver `_mundo_entrevista.md` para el detalle.
**Regla editorial**: solo lo decidido en la entrevista. Lo no-decidido marcado ⌛.

> Filtro activo: *"¿esto sale en el video de 10 min del demo?"*
> P1 y la antesala de P2 salen en el video. P3/P4/P5 son boceto sin revisar en esta entrevista.

---

## Flujo de entrada + ciudad (decidido 2026-07-03)

**Flujo**:
1. Menú principal (Jugar / Opciones / Controles / Extras)
2. Crear personaje cross-mundos estilo Valheim — el PJ vive fuera del mundo; los mundos son saves
3. Selector de personajes estilo Diablo 2 — nombre / nivel / mini-preview equipado (ya implementado)
4. Selección de mundo — local para el demo; multiplayer post-demo = Steam (principal) + código de sala (fallback multi-plataforma)

**Ciudad hub**:
- **Nace con identidad chilena** (referencia: Valparaíso — cerros, casas de colores, palafitos, tejuela)
- La **multicultura se agrega con updates** a medida que el juego avanza y jugadores internacionales fomentan el estilo de su barrio
- **Cerca de la torre = ruinas** con flujo de gente (hubo una destrucción previa)
- **Pasado nivel 5**: la ciudad se reconstruye (world-state colectivo — implementación post-alfa)
- **Taverna** = spawn/dormitorio · **Gremio** = misiones/lore · **Comercio** = items básicos útiles hasta ~P5; después pierde peso vs crafteo/recompensas de dungeon (dungeon que regenera cada 6-12h — semilla post-alfa)
- **Intro estilo Genshin**: vuelta por la city → misión te manda a descubrir la torre; tutorial orgánico (un NPC que ofrece pelear y se va al primer hechizo)

---

## Los 5 Mapas — Tabla

| # | Nombre / Bioma | Feel | Clima | Mobs clave | Mini subjefes | Boss de zona | Transición salida |
|---|---|---|---|---|---|---|---|
| **P1** | Pradera Interior — ⌛ nombre oficial pendiente (Erindar: sin confirmar ni descartar) | "Pradera INMENSA — no esperabas que la torre fuera tan grande por dentro; hay vida, naturaleza dentro de ella." MUNDO HUMANO: fauna real, solo 2 entidades mágicas pasivas y conocidas | Luminoso-cristal, quieto | Lobos, pájaros cazando, mariposas, ratas, abejas, bandidos (intrusos). Candidatos alpha: oso territorial, cocodrilos en ríos, capibaras (neutral), depredador acechador en bosque denso, plantas/frutas recolectables | **Golem** — pasivo, dormido, despierta SOLO al ser atacado · **Oso** — territorial, ataca al verte | **King Slime** — tapón del acantilado, pelea OBLIGATORIA (no hay bypass) | Acantilado con caída al bosque de abajo (P2 está ABAJO — se desciende) |
| **P2** | ⌛ Nombre pendiente — raíz japonesa/Aokigahara OBSOLETA 2026-07-03 | Adentrarse en la FANTASÍA. Bosque oscuro con luz de luna llena, árboles con luces fluorescentes estilo Kimetsu. Tono místico/élfico, más oscuro que P1. Referencia sensación: "el bosque vivo que te observa" (Chiloé — feel, no catálogo literal) | Lluvia tormentosa / niebla | Búhos, serpientes entre arbustos, polillas gigantes. Criaturas: NATURALEZA CREADA endémica de la torre (criterio Axlin — NO se copian mitologías). Fichas de criaturas ⌛ | ⌛ por definir | ⌛ por definir | — |
| **P3** | Boceto previo: Jötunheim (nórdico) | ⌛ pendiente revisión con Joan | ⌛ | ⌛ | ⌛ | ⌛ | ⌛ |
| **P4** | Boceto previo: Al-Samum (árabe) | ⌛ pendiente revisión con Joan | ⌛ | ⌛ | ⌛ | ⌛ | ⌛ |
| **P5** | Boceto previo: Umbral Fragmentado | ⌛ pendiente revisión con Joan | ⌛ | ⌛ | Guardián-Cuervo (**jefe de RANGO**, no de zona — cross-piso) | ⌛ | ⌛ |

Para bocetos de P3/P4/P5 ver `game/docs/lore/_floor_sketches.md`.
**No usar esos bocetos como canon decidido** — requieren revisión con Joan en entrevista separada.

---

## P1 → P2: Boss + Transición en detalle

**King Slime** — rol y posición decididos 2026-07-03:
- Plantado AL FRENTE del acantilado, se instaló a comer EN la fuente del flujo de bioluminiscencia
- La razón ecológica (comer la fuente de luz) es el mismo motivo que lo convierte en el tapón del paso → ecología = level design
- Pelea **OBLIGATORIA** — no hay bypass; el boss ES el paso

**Secuencia de muerte y transición**:
1. El cuerpo se derrama por el borde del acantilado → **muestra el camino** (lectura visual de "bajar")
2. Queda el **núcleo flotando** (cristal condensado de bioluminiscencia)
3. Tomar el núcleo registra el **desbloqueo world-state colectivo** — en ese servidor el paso queda abierto para todos
4. Descenso por el acantilado (la luz del cristal muere, empieza a sonar lluvia)
5. Salida al bosque bajo luna llena → entrada al P2

**Aspecto King Slime**: ⌛ pendiente-referencia visual de Joan. Para el demo alcanza el modelo actual + material iridiscente/denso.
**Ataques/fases**: ya diseñados (4 fases implementadas) — ver implementación existente.

---

## P2 — Alcance del Demo

El demo incluye la **antesala del P2** (~un cuarto de la historia del segundo piso, gancho para lo que viene):
1. Cruce post-boss → descenso por el acantilado (la bioluminiscencia drena hacia abajo)
2. 2-3 min de bosque (cambio sensorial total: lluvia, oscuridad, árboles con luces fluorescentes)
3. Algo te observa (silueta que desaparece)
4. Corte "continuará"

Es el **shot más caro del demo**. Va después de que P1 esté video-ready.
**Primer candidato a recorte** si aprieta el tiempo — fallback: solo el descenso como cliffhanger.

---

## Principios del sistema de torre (decididos 2026-07-03)

1. **Climas por piso = identidad**: cada piso tiene clima propio (P1 = luminoso/cristal/quieto · P2 = lluvia tormentosa/niebla · P3-P5 ⌛)
2. **Torre bidireccional**: la torre se recorre hacia arriba Y hacia abajo. P1→P2 = descenso. Qué dirección toma cada piso posterior ⌛ (se define con el mapa completo)
3. **Gradiente humano → fantasía**: P1 = mundo humano (fauna real, 2 entidades mágicas) · P2+ = naturaleza creada, fantasía creciente. Clarifica el "gradiente de realidad" del canon previo.
4. **World-state colectivo del gate**: el núcleo del King Slime abre el paso P1→P2 para todo el servidor — modelo Valheim por mundo
5. **Early access incremental**: el juego se actualiza y la historia crece con cada update (estilo Valheim / Hades / Vampire Survivors)

---

*Entrevista Joan 2026-07-02/03. Cierra CLAUDE.md próximos pasos paso 4.*
