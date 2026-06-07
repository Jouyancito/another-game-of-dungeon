# Flujo de Inicio (Onboarding) — Spec de Diseño

> **Estado:** Diseño / definición — develop-before-implement. NO implementado aún.
> **Creado:** 2026-06-06 · **Autor visión:** Joan
> **Supersede parcialmente:** `_charselect_diablo2_spec.md` (el modelo "lista + preview" pasa a ser
> un *atajo secundario* dentro de un modelo más ambicioso de navegación por clase-bioma).
>
> Este documento define el QUÉ y el modelo. No resuelve cada asset ni cada nodo `.tscn`.

---

## 0. Pilar de feel (world-first)

El flujo de inicio es la **primera impresión** del juego. No es "menú→config→cargar nivel": es la
primera vez que el jugador SIENTE la identidad de cada clase. Por eso el character select no muestra
clases como una lista de opciones — las muestra como **lugares**. Cada clase vive en su propio bioma.
Elegir clase es *entrar a un mundo*, no marcar un radio button.

Referencia: **Blade & Soul** (cada clase en su escenario temático) + **Valheim** (selección de mundo
con seed, world-state propio).

---

## 1. El flujo completo

```
┌──────────────┐   Jugar    ┌─────────────────────┐  PJ elegido  ┌────────────────────┐
│  MENÚ (hoy)  │ ─────────▶ │  CHARACTER SELECT   │ ───────────▶ │   WORLD SELECT     │
│ main_menu    │            │  (Blade & Soul)     │              │   (Valheim, local) │
└──────────────┘            └─────────────────────┘              └────────────────────┘
                                                                            │ Entrar
                                                                            ▼
                                                                    floor1_prairie.tscn
```

Tres pantallas. La #1 ya existe (sin cambios por ahora). La #2 es **rediseño** de
`character_select.tscn`. La #3 es **nueva**.

---

## 2. Pantalla 1 — Menú principal (sin cambios)

`game/scenes/ui/main_menu.tscn` queda como está: Jugar / Arena / Hostear(stub) / Tutorial(stub) /
Opciones(stub) / Salir. Único cambio futuro: "Jugar" deja de ir directo a `floor1_prairie` y pasa por
el nuevo flujo (char select → world select). Ya hoy "Jugar" va a `character_select`, así que el cambio
real está aguas abajo.

---

## 3. Pantalla 2 — Character Select (Blade & Soul)

### 3.1 Modelo: navegación por CLASE, no por personaje

Esta es la decisión arquitectónica núcleo. La navegación primaria es **clase → clase**, cada una con su
bioma. Dentro de cada bioma están **todos tus PJs de esa clase** + el slot para crear uno nuevo.

> Por qué por clase y no por PJ: el char select clásico (incluido el spec D2) navega por PJ y el fondo
> es decorado. Acá el **bioma ES la unidad de navegación**. Esto fusiona en una sola pantalla dos cosas
> que normalmente están separadas: **crear** un PJ y **seleccionar** uno existente.

### 3.2 Layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│  ◀  GUERRERO  ▶            (nombre de clase — navegación entre biomas)      │
├──────────┬──────────────────────────────────────────┬─────────────────────┤
│ LISTA    │                                          │  CARTEL DE CLASE     │
│ (atajo)  │        BIOMA DE LA CLASE (escena 3D)     │  ┌────────────────┐  │
│ ┌──────┐ │                                          │  │ GUERRERO       │  │
│ │Thoric│ │     [Nombre Nv.12]   [Nombre Nv.4]      │  │ Rol: Tanque /  │  │
│ │ Gue  │ │        🗿               🗿               │  │   Berserk      │  │
│ ├──────┤ │       (PJ 1)          (PJ 2)            │  │ Recurso: Rage  │  │
│ │Lyra  │ │                              ┌──────┐   │  │ STR↑ DEF↑ VIT↑ │  │
│ │ Mago │ │                              │  +   │   │  │                │  │
│ ├──────┤ │                              │Crear │   │  │ "personalidad" │  │
│ │ ...  │ │                              └──────┘   │  │  (provisorio)  │  │
│ └──────┘ │                                          │  └────────────────┘  │
├──────────┴──────────────────────────────────────────┴─────────────────────┤
│   [ Input: nombre del personaje nuevo ]          [ Volver ]   [ Jugar ▶ ]   │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Comportamiento

| Acción | Resultado |
|---|---|
| Flechas ◀ ▶ (o swipe de clase) | Cambia de bioma: nuevo fondo + nuevo cartel + los PJs de esa clase |
| Click sobre el **cuerpo** de un PJ | Selecciona ese PJ. Nombre + nivel flotan arriba del modelo |
| Click en slot **+ Crear** | Modo creación en ese bioma: se habilita el input de nombre |
| Escribir nombre + Jugar (con slot Crear activo) | Crea el PJ de esa clase con ese nombre → va a World Select |
| Seleccionar PJ existente + Jugar | Va directo a World Select con ese PJ |
| Lista izquierda (atajo) | Click en un PJ salta a su bioma y lo selecciona. Aparece solo cuando hay ≥1 PJ |

### 3.4 Decisión — clases en el alpha

**3 biomas en el alpha** (Guerrero / Mago / Arquero), con la **estructura preparada para 6**
(Clérigo / Nigromante / Danzante). Las flechas de navegación solo recorren las clases con bioma
disponible; las demás pueden mostrarse como "Próximamente" o no mostrarse. Esto respeta el scope reset
(alpha = 3 clases) sin cerrar la puerta a las 6 de lanzamiento.

> Las 6 clases siguen siendo canon de lanzamiento. El recorte a 3 es solo del alpha demo.

### 3.5 Cartel de clase — copy provisorio (lore PAUSADO)

El lore de clases está en hold hasta realinear con `_world_canon.md` v2.0 (post-alpha). Por eso el cartel
usa **copy mecánico** (rol, recurso, stats dominantes) + un gancho de personalidad provisorio marcado
como placeholder. NO escribir lore narrativo todavía.

| Clase | Rol | Recurso | Stats dominantes | Gancho (placeholder) |
|---|---|---|---|---|
| **Guerrero** | Tanque / Berserk | Rage | STR 12 · DEF 10 · VIT 10 | Aguanta el frente, devuelve el golpe |
| **Mago** | Elementalista / Arcano | MP (fantasy lock) | INT 12 | Poder a distancia, frágil de cerca |
| **Arquero** | Ranger / Artillero | Concentración | DEX 12 · VIT 7 | Daño físico sostenido, control del rango |

Fuente de stats: `game/shared/classes/class_base_stats.gd`. El gancho de personalidad se reemplaza por
copy canon cuando el lore se reactive post-alpha.

### 3.6 Reuso de código existente

- **`CharacterPreview`** (`character_preview.gd`): ya renderiza modelo 3D girando. Reusable como el
  cuerpo de cada PJ en el bioma. ⚠️ Cuidado de performance: el spec D2 evitó N previews en paralelo por
  costo de SubViewport. Acá pueden coexistir varios PJs en escena — **medir** y, si hace falta, usar
  modelos 3D directos en la escena-bioma en vez de N SubViewports.
- **`SaveManager`**: `get_character(index)` ya devuelve name/level/class_name/highest_floor/equipment.
  Necesita poder **filtrar por clase** para poblar cada bioma (helper nuevo, p.ej. `get_characters_by_class()`).
- **`GameManager`**: `selected_class_scene` + `selected_character_index` se siguen usando igual.
- **`class_selector.tscn`**: el flujo de creación actual queda **absorbido** por este modelo (crear pasa
  a ser el slot "+" dentro del bioma). Evaluar si se deprecia o se reusa internamente.

### 3.7 Assets a definir (no bloquean el diseño)

- Fondo/bioma por clase (3 alpha). Pueden ser escena 3D simple, skybox temático, o backdrop + piso.
  Decisión visual → recae en art canon. Empezar con algo barato e iterar (world-first: reglas → estilo).
- Posiciones de los PJs dentro del bioma (layout de N modelos sin que se solapen).

---

## 4. Pantalla 3 — World / Server Select (Valheim, local)

### 4.1 Decisión de alcance (tomada)

**Local, con seed funcional.** Un jugador crea o elige un mundo con seed; se guarda local. Single-player
REAL ya andando. El modelo **server-compartido** (world-state colectivo, avance por server, trofeos de
jefes) se DISEÑA acá pero se implementa **post-netcode**. La UI nace multiplayer-shaped, la implementación
arranca single-player.

### 4.2 Layout

```
┌───────────────────────────────────────────────────────────────────┐
│  Selecciona un Mundo                                               │
├───────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ▶ Mi Primer Mundo      seed: 84213   ·  Piso 1  ·  3h jugadas │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │   Mundo de prueba      seed: 00001   ·  Piso 1  ·  0h        │  │
│  ├─────────────────────────────────────────────────────────────┤  │
│  │   + Crear mundo nuevo   [ nombre ___ ]  [ seed ___ / random ]│  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  (futuro, gris) ☁ Unirse a server compartido — post-netcode       │
│                                                                   │
│                          [ Volver ]     [ Entrar ▶ ]              │
└───────────────────────────────────────────────────────────────────┘
```

### 4.3 Datos de un mundo (save local)

```
world_save = {
  "world_id": "uuid",
  "name": "Mi Primer Mundo",
  "seed": 84213,              # determina generación procedural (cuando aplique)
  "created_at": <timestamp>,
  "playtime_seconds": 0,
  "highest_floor_cleared": 0, # world-state: avance del MUNDO, no del PJ
  "boss_trophies": [],        # hooks server-compartido: trofeos de jefes derribados
  "world_flags": {}           # marcas persistentes (Descubrimiento→Conquista→Civilización)
}
```

> `highest_floor_cleared`, `boss_trophies` y `world_flags` son los **hooks** del modelo colectivo
> capturado en canon. En el alpha viven en el save LOCAL del mundo; cuando llegue netcode, esa misma
> estructura se sincroniza por server. La UI ya tiene el slot gris "Unirse a server compartido".

### 4.4 Relación PJ ↔ mundo

El PJ (progresión, gear, nivel) es **del jugador** y viaja entre mundos. El avance del MUNDO
(pisos despejados, trofeos, marcas) es **del mundo**. Esto es el modelo Valheim: tu vikingo entra a
cualquier mundo; el mundo guarda su propio progreso. Cuadra con el canon world-state colectivo.

---

## 5. Decisiones registradas

| # | Decisión | Estado |
|---|---|---|
| D1 | Char select navega por **clase-bioma**, no por PJ | Tomada |
| D2 | **3 biomas** en alpha (W/M/A), estructura para 6 | Tomada |
| D3 | Cartel de clase = **copy mecánico provisorio** (lore pausado) | Tomada |
| D4 | World select = **local + seed funcional**, server-compartido diseñado/no implementado | Tomada |
| D5 | "Lista izquierda" = atajo secundario (la lista del spec D2) | Tomada |

---

## 6. Qué NO se hace ahora

- **Netcode / server compartido real** (Steam P2P) — post-alpha. Solo dejamos los hooks de datos + UI gris.
- **Lore narrativo de clases** en el cartel — espera realineación world_canon v2.0.
- **Las 3 clases extra** (C/N/D) con bioma — estructura lista, biomas después.
- **Generación procedural por seed** del mundo — el dato seed se guarda; el uso real depende del estado
  del generador de pisos.

---

## 7. Relación con specs existentes

- **`_charselect_diablo2_spec.md`**: superseded como modelo principal. Su aporte vive como el atajo de
  lista izquierda (3.3) y su lección de performance (no N SubViewports en paralelo, 3.6).
- **`_world_seeds_postalpha.md`** + canon de mundo: el world-state colectivo de la Pantalla 3 implementa
  los hooks de ese modelo (Descubrimiento→Conquista→Civilización, trofeos de jefes).

---

## 8. Preguntas abiertas para la próxima iteración

1. Bioma por clase: ¿escena 3D real, skybox temático, o backdrop 2D + piso? (decisión visual / art canon)
2. Performance N PJs en escena: ¿SubViewport por PJ o modelos directos en la escena-bioma? (medir)
3. ¿La lista izquierda muestra TODOS los PJs siempre, o solo los de la clase actual + un "ver todos"?
4. World select: ¿límite de mundos guardados? ¿borrar mundo desde acá?

---

*Documento de diseño — develop-before-implement. Implementar recién tras validación del flujo.*
