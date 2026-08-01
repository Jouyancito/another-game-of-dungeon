# Cola de re-modelado — review de Joan, 2026-07-31

Origen: playtest completo del piso 1 con 15 capturas comentadas. Método acordado con Joan:
**lista → alpha de cada asset → review conjunto**. Ningún asset se da por bueno sin que Joan
lo mire.

Regla de fondo que ordena todo esto (canon `_art_canon.md` §17): **silueta = geometría,
superficie = textura**, objetivo PoE1. Y la regla de proceso que ya costó una ronda: antes de
modelar cualquiera de estos, **buscar referencias reales de ESE objeto** y construir desde
ellas, no desde el recuerdo de una descripción.

---

## A — Reemplazar packs CC0 por modelo propio del motor

Assets descargados que siguen en el mapa. Joan ya los marcó más de una vez.

| # | Asset | Estado | Nota de Joan |
|---|---|---|---|
| A1 | **Arbusto** (bola verde) | pack CC0 | "es de una textura que habíamos descargado... ya como dos, tres veces que la idea es eliminarlas" |
| A2 | **Bandido** (melee + arquero) | pack CC0 | "también son de una textura de un pack, de un modelado que descargamos gratis" |
| A3 | **Árboles no-motor** | pack CC0 | de los 3 del frente, solo uno es del motor. "Me agradan los colores, estilos de los otros dos, pero son diferentes" — el objetivo es igualar ese color/estilo con modelado propio |
| A4 | **Roca** | pack CC0 | ver R1 abajo, además de reemplazo tiene problema de diseño |

## B — Ilegibles: no se entiende qué son

Joan textual: *"no es entendible para nada, toca volver a modelarlo"*. Estos no son
"mejorables", están mal de base — la silueta no comunica el objeto.

| # | Asset | Diagnóstico |
|---|---|---|
| B1 | Estructura naranja del campamento bandido | volumen plano sin lectura; no se entiende si es pared, techo o rampa |
| B2 | Torre / poste alto gris | "esa torre no sé qué es. No se nota qué es" |
| B3 | Cúmulo verde con puntas rosadas | ilegible a distancia de juego |
| B4 | Cristales / esquirlas celestes | "esto no entiendo cómo leerlo o interpretarlo" |
| B5 | Roca con cubos grises encima | "es una mezcla de varios diseños y se siente como un collage" |

## C — Ecología y distribución (generación, no modelado)

Esto NO se arregla modelando: se arregla en las reglas de scatter de `floor1_prairie.gd`.
Canon relacionado: `_world_coherence.md` (nichos, hidrología).

| # | Problema | Regla que falta |
|---|---|---|
| C1 | **Hongos bajo un árbol en seco** | "sin agua cerca, sin nada, es raro que salgan hongos en un lado así" → los hongos necesitan nicho: humedad, sombra, materia en descomposición |
| C2 | **Flores sueltas de a una** | "una flor en una pradera es raro, las praderas son muchas flores en zonas" → **investigar distribución real de flores en praderas** y simular manchones/áreas, no unidades dispersas |
| C3 | **Vallas en medio de la nada** | una valla implica algo que contener o delimitar; sin contexto es ruido |
| C4 | **Rocas: un huevo parado** | ver R1 |

### R1 — Rocas, lo que Joan pidió en detalle

> "La roca, si te das cuenta, es un huevo. Esa piedra no es estable de por sí, cualquier cosa
> la botaría. Es medio raro que esté parada y que sea la única generación."

Lo que quiere en su lugar — **irregular y aleatorio**:
- piedras más grandes, anchas y **bajas** (estables por proporción, no equilibradas)
- rocas **soportadas por otras** rocas
- **montículos** de piedra
- dimensiones muy variadas: muy grandes y muy chicas conviviendo
- campos empedrados tipo **orilla de río** — "puras rocas que se movieron"
- varias generaciones de montículos, no una sola forma repetida

## D — Bugs de sistema (código, no arte)

Reportados en el playtest. **Pendientes de verificar en código** antes de estimar.

| # | Bug | Detalle |
|---|---|---|
| D1 | **Árboles sin colisión** | "te entras en el árbol" |
| D2 | **Lobos se amontonan** | "no hay colisión, no hay bloqueo por espacio" entre enemigos — se apilan en el mismo punto |
| D3 | **Plataforma de spawn atravesable** | la plataforma grande del inicio no es sólida, se traspasa. Joan: "no se me ocurre cómo podríamos hacerlo" |
| D4 | **Cristales del techo al alcance** | "estoy tocando los cristales del techo casi" — altura mal calibrada, se reportó dos veces |

## E — Diseño pendiente

| # | Tema | Nota |
|---|---|---|
| E1 | **Pantalla de muerte** | hoy solo `[R] volver al punto de partida`. Joan quiere más opciones: revivir con un objeto, algo ligado a ser el dueño/anfitrión de la partida. Falta diseñar qué se puede hacer ahí |
| E2 | **Ronda de optimización** | Joan la difiere a propósito: "cuando terminemos el primer piso, ahí le damos". Motivo: se ven todos los cristales a distancia completa, sin LOD ni culling |

---

## Orden sugerido

1. **D (bugs)** primero — son baratos y rompen la experiencia ahora mismo.
2. **C (ecología)** después — cambia cómo se lee el mapa entero sin modelar un solo asset.
3. **A + B (modelado)** al final, de a un alpha por vez con review de Joan entre medio.
4. **E2 (optimización)** cuando el piso 1 esté cerrado, por decisión explícita de Joan.
