# Pipeline por Mob — Dungeon Party

Pipeline repetible para producir un mob completo (anatomía → geometría → textura → export → juego → banco de pruebas), destilado de los dos primeros mobs bespoke que lo recorrieron entero: **tortuga** y **halcón** (2026-08-24/25), ambos aprobados **8/10 por Joan**.

**Regla madre**: cada fase existe porque saltarla YA costó rondas de retrabajo. El caso que la parió está citado junto a cada fase. Corolario: si un defecto nuevo cuesta una ronda, se convierte en gate ANTES del próximo mob.

División dura que atraviesa todo el pipeline: **TRAYECTORIA = IA (GDScript) / CUERPO = clip (GLB)**. `loc_x`/`loc_y` están prohibidos en clips.

---

## El pipeline

### Fase 0 — Ficha anatómica
- **Entregable**: `_references/<mob>/_synthesis.md` con tabla en DOS mitades: MEDIDA (dimensiones, conteos) y ESTRUCTURA (por parte móvil: plano que ocupa, ángulo de reposo, qué la limita).
- **Gate**: la mitad ESTRUCTURA existe y cubre cada parte móvil. Sin ella, no se modela.
- **Previene**: la tortuga arrancó con solo medidas → las patas-en-X y el húmero-horizontal salieron recién al agregar ESTRUCTURA.

### Fase 1 — Motion spec
- **Entregable**: `_references/<mob>/motion/_motion_spec.md`. Cada renglón termina en un número o una orientación; el criterio de éxito se escribe ANTES de construir.
- **Gate**: los asserts del spec se miden sobre los SAMPLERS en el build.
- **Previene**: "idle que aletea = build roto" — sin spec no hay contra qué medir.

### Fase 2 — Geometría desde la anatomía
- **Regla**: construir DESDE las unidades anatómicas, nunca pintar estructura sobre superficie continua. Caparazón desde escudos (las líneas de la grilla SON bordes de placa); ala desde plumas (cada primaria es una pieza).
- **Regla de escala**: patrón en textura, malla en geometría — si las frecuencias se acercan, sale ruido (anillos damero).
- **Patrones de referencia**: `_carapace.py`, `hawk/_feather_texture.py`.
- **Previene**: la TERCERA falla de pintar-encima (pelo, caparazón, ala-plano).

### Fase 3 — Textura
- Horneada DESDE las mismas funciones que dieron la forma (`_bake_vcol.py`). Tinte DENTRO de la textura: atlas por tono si hay piezas repetidas; mapa único si la superficie es única.
- **PROHIBIDO** nodo de mezcla en Base Color: glTF exporta blanco (5 casos en 24h). sRGB: codificar UNA sola vez y etiquetar.

### Fase 4 — Gates en el build (SystemExit)
Conteos anatómicos · envergadura/ratio en banda · ranuras con GAP medido · ojos frontales (dot) · soldadura cuello-cráneo (mm por key) · patas-en-X por cuadrante PROPIO (contra el origen aprobaba paralelas) · relieve en mm vs domo pelado · presupuesto de tris · asserts del motion spec sobre samplers.
- **Espacios de coordenadas**: umbral de MUNDO nunca sobre coords LOCALES — el join pliega todo al espacio del base object (3 casos pagados).
- **Blender**: `shape_key_add(from_mix=False)` · sonda escrito-vs-leído tras `foreach_set` · soltar NLA tracks (el rest pose se reafirma ÚLTIMO) · Blender 5 usa layers/strips/channelbags, no `Action.fcurves`.

### Fase 5 — Probe GLB post-export
- **Herramienta**: probe puro-python (struct+json). Verifica COLOR_0, baseColorTexture presente, N clips.
- **Previene**: GLB blanco o plano que ningún render del build detecta.

### Fase 6 — Deploy
- **Herramienta**: `_deploy.py` — export DIRECTO a `assets/`, tabla leída del código que CARGA, manifest sha256, gate de paridad en hook Stop.
- **Previene**: dos copias SIEMPRE divergen — la tortuga corrió 2 builds vieja dentro del juego sin aviso.

### Fase 7 — Juicio visual ★ CHECKPOINT JOAN
- `_canonical_views.py` (`require_views`): 7 vistas OBLIGATORIAS, incluida la de abajo — un set sin ella aprobó un plastrón inexistente.
- Showcase del ARCHIVO DESPLEGADO (`_turtle_deploy_showcase.py` como patrón), nunca del build.
- Pixel-sample antes de cualquier veredicto de valor (2 ilusiones de brillo relativo en una sola sesión).
- **★ Joan lee naturalidad sobre las 7 vistas** — su ojo es la única red para "se ve vivo/creíble".

### Fase 8 — Vida en el juego
- IA de trayectoria + clip por estado vía `_play_clip` idempotente. UNA sola máquina de persecución: `_stalk(victim, lethal)` — dos copias divergieron en feel.
- Inercia: `_steer` con aceleración + heading slerp. `w = v/r` DERIVADA, nunca dos constantes.
- Acción de naturaleza: cazar dispara `_spawn_loot` de la presa. Golpea-y-sigue para neutrales.
- Checklist de defectos conocidos: giro 180 del GLB de cola (frente +Z vs `look_at` -Z — solo se ve orientándose en vivo) · `is_dead` corta física → volador muerto colgado (caída tween `t = sqrt(2h/g)` + `_death_anim_hold`) · salida de embestida necesita OR de `get_slide_collision_count()` (la colisión llega antes que `attack_range`) · medio-arreglo: al tocar una instancia, buscar TODAS las hermanas (4 casos).

### Fase 9 — Banco mob_lab ★ CHECKPOINT JOAN (obligatorio)
- `game/scenes/dev/mob_lab.gd` (G provoca neutral, H suelta presa, 6 muerte real, T lista) + `target_dummy.gd` con firmas EXACTAS del player — `has_method()` no valida firmas (un orden invertido abortó frames a mitad).
- Neutrales: probar SIEMPRE con provocación explícita — jamás muestran combate solos.
- **★ Sesión EN VIVO con Joan**: feel del movimiento + sus capturas orbitando. Encontró defectos invisibles a todo render propio, 2 veces.

---

## Catálogo de gotchas por familia

| Familia | Gotcha | Detección |
|---|---|---|
| Espacios de coordenadas | El join pliega al espacio del base object; umbral de mundo sobre coords locales aprueba basura (3 casos) | Sonda que imprime bbox en ambos espacios antes del assert |
| Medio-arreglo | Arreglar una instancia deja hermanas rotas (4 casos) | Al tocar una instancia, `rg` de TODAS las hermanas antes de cerrar |
| Export silencioso | Nodo de mezcla en Base Color → glTF blanco (5 casos/24h) | Probe GLB post-export: baseColorTexture + COLOR_0 |
| GLB de cola | Frente del modelo +Z vs `look_at` -Z → giro 180 | Solo se ve orientándose EN VIVO en mob_lab, nunca en render estático |
| Firmas de stubs | `has_method()` pasa con firma incompatible; el frame aborta a mitad | `target_dummy.gd` con firmas EXACTAS copiadas del player |
| is_dead corta física | Volador muerto queda colgado en el aire | Probar muerte real (tecla 6); caída tween + `_death_anim_hold` |
| w = v/r | Dos constantes independientes → patinaje en curvas | Derivar w de v y r; assert del motion spec sobre samplers |
| Blanco con volumen | Brillo relativo engaña al ojo (2 ilusiones en una sesión) | Pixel-sample numérico antes de cualquier veredicto visual |
| Frecuencia textura/malla | Patrón de textura cerca de la densidad de malla → anillos damero | Regla: patrón en textura, estructura en geometría; revisar en espacio UV |
| Blender API | `from_mix`, `foreach_set` sin sonda, NLA reafirma rest pose último, Blender 5 sin `Action.fcurves` | Checklist de Fase 4 en cada builder nuevo |

---

## Herramientas existentes

| Ruta | Para qué sirve |
|---|---|
| `tools/blender/turtle/build_turtle.py` (+`_carapace.py`, gait, anim_strip) | Builder patrón: cuadrúpedo con estructura por placas |
| `tools/blender/hawk/build_hawk.py` + `_feather_texture.py` | Builder patrón: volador con ala por plumas y textura bakeada |
| `tools/blender/.../_bake_vcol.py` | Hornear textura desde las mismas funciones que dan la forma |
| `tools/blender/.../_deploy.py` | Export directo a `assets/` + manifest sha256 + gate de paridad + detección de huérfanos |
| `tools/blender/.../_canonical_views.py` | 7 vistas obligatorias (`require_views`), incluida la inferior |
| `tools/blender/.../_turtle_deploy_showcase.py` | Patrón de showcase del archivo DESPLEGADO (no del build) |
| Probe GLB puro-python (struct+json, Fase 5) | Verifica COLOR_0 / baseColorTexture / N clips post-export |
| `game/scenes/dev/mob_lab.gd` + `target_dummy.gd` | Banco en vivo: provocación, presa, muerte real, firmas exactas |

---

## Roadmap del mobpack Piso 1 (medido 2026-08-25)

Fuentes: `game/docs/art/_mob_audit_2026-08-22.md`, `_bestiary_visual_bible.md` §5, `_deploy.py` líneas 40-44, `_deploy_manifest.json`, inspección de `scenes/enemy/`, `tools/blender/`, `assets/art/piso1_pradera/enemies/`.

| Mob | Ficha | Builder | GLB en juego | Clips | IA propia | Veredicto | Talla |
|---|---|---|---|---|---|---|---|
| tortuga | sí | sí | sí (`small/turtle_dp_01.glb`, manifest) | sí (5) | sí (shell + DEF dinámica) | **LISTO** (8/10) | — |
| halcón | sí | sí | sí (`flying/hawk_dp_01.glb`, manifest) | sí (3) | sí (circling/diving + caza ratas) | **LISTO** (8/10) | — |
| slime / mini | sí | sí | sí (`slime_dp_01.glb` en .tscn + deploy) | no verificado | sí (split en minis) | **LISTO** | — |
| king_slime | sí (§6.6) | sí | sí (`king_slime_dp_01.glb` + deploy) | no verificado | sí (boss, 48KB) | **repasar-con-motor** (Joan: "no hemos trabajado en él" con el motor maduro) | M |
| golem | sí | sí (3 gen) | sí por código (NO en `_deploy.py`) | por-miembro en GDScript | sí (tree-gated) | **rehacer-con-motor** — pedido explícito de Joan: volver a trabajarlo con el motor ya definido, al nivel tortuga/halcón | L |
| rata | sí | sí | NO — `rat.glb` huérfano en tools/, `rat.gd` usa primitivo | NO | sí (pack-aggro + huida) | **solo-deploy+cablear** (+verificar luma 0.287, bug ~12x latente) | S/M |
| avispa | NO | sí | NO — `wasp_vcol.glb` huérfano, `wasp.gd:85` primitivo | NO | sí | **solo-deploy+cablear** | S |
| serpiente | NO | sí | NO — sin COLOR_0; vcol rechazado por gate (152 verts) | NO | mínima (2KB) | **rehacer-como-halcón** (UV + bake) | M/L |
| pájaro | sí (`corvid/`) | sí | NO — `bird_vcol.glb` huérfano, ala blanca sin revisar | NO | sí (picada 3 estados) | **parchear** (ala + escala córvido) + deploy | M |
| lobo | sí | NO | NO — primitivo | NO | sí | **decisión Joan**: bespoke vs pack | L |
| zorro | NO | NO | NO — primitivo | NO | sí | **decisión Joan**: pack o rehacer | L |
| cabra | NO | NO | NO — primitivo | NO | sí | **decisión Joan**: pack o rehacer | M/L |
| escorpión | NO | NO | NO — primitivo | NO | mínima | **decisión Joan**: pack o rehacer | M/L |
| bandidos (melee/archer/leader) | sí | NO | placeholder `enemy_ninja.gltf` por código | del pack | sí (3 .gd) | **rehacer-como-halcón** (misma decisión pendiente) | L |
| mimic | sí (balance) | proc autorado (canon §5) | sí (proc en `mimic_chest.tscn` + VFX) | proc | sí (state machine) | **repasar-con-motor** (nunca pasó por el pipeline) | M |

Datos duros transversales:
- `_deploy.py` tiene exactamente **4 entradas** (turtle, slime, king_slime, hawk); el manifest sha256 registra 2. Huérfanos formales hoy: `rat.glb`, `snake.glb`, `wasp_vcol.glb`, `bird_vcol.glb`.
- Patrón de cableado establecido (turtle/hawk): const path + `ResourceLoader.exists` + fallback a primitivo con `push_warning`. Es la receta a copiar.
- El bloqueo real del pack NO es IA (todos tienen `.gd` con IA propia) — es **arte**: 4 mobs juegan con primitivas teniendo GLB en tools/, y 4 especies + bandidos esperan la decisión bespoke-vs-pack.

**REGLA DEL VEREDICTO (corrección de Joan, 2026-08-25)**: LISTO no significa
"el asset existe y está cableado" — significa **pasó por el motor maduro
(pipeline completo de este doc) y Joan lo calificó ≥ 7/10**. Con esa vara los
LISTOS reales son TRES: tortuga (8), halcón (8) y slime (≥ 7). El primer
borrador de esta tabla acreditó king_slime, golem y mimic por mera existencia
— el mismo error que el audit de 2026-08-22 ya había documentado ("un asset
puede estar en el juego y no estar terminado"). El golem en particular es
pedido explícito: rehacerlo con el motor actual, al nivel de los tres buenos.

### Orden de ataque sugerido

Criterio del scope-reset para priorizar: **"¿sale en el video de 10 minutos del demo?"** Si no sale, no se rebuilda ahora.

1. **Baratos — solo-deploy+cablear (S)**: avispa y rata. Copiar la receta turtle/hawk, sumar a `_deploy.py`, correr probe + showcase del desplegado. Rata exige además verificar luma en juego (BYTE_COLOR, media 0.287 — bug ~12x documentado en el audit).
2. **Parche rápido**: golem a `_deploy.py` (una línea, cierra el huérfano formal) — sin perjuicio de su rebuild L posterior.
3. **Parche M**: pájaro — revisar ala blanca, decidir si `bird_vcol` re-escala a córvido (la medida 1.22m era del halcón, que ahora existe bespoke aparte), luego deploy+cablear.
4. **Rebuild M**: serpiente — necesita UV + bake a textura (el vcol de 152 vértices no sostiene escamas; ya lo rechazó un gate). Pipeline completo Fase 0 → 9.
5. **Repasos con motor (M)**: king_slime y mimic — pasarlos por el pipeline (probe, showcase, gates, mob_lab con Joan) y subirlos al estándar.
6. **Rebuild L insignia**: el GOLEM con el motor maduro — construir-desde-la-anatomía de rocas, texturas horneadas, vida propia. Es el que Joan más quiere ver renacer.
7. **ANTES de tocar los demás L**: cerrar con Joan la decisión bespoke-vs-pack (lobo, zorro, cabra, escorpión, bandidos). El bestiario §5 decía pack; la práctica bespoke lo superó; el audit dejó la tensión abierta. No arrancar ningún L sin ese veredicto.

---

## Pendientes de infraestructura (plataforma, separado del arte)

Del review de reglas — NO reinventar, NO asumir hechos:

- **P2**: harness de gates con fixtures (testear los gates mismos).
- **P3**: sonda delta-E en deploy (color desplegado vs color horneado).
- **P5**: captura Godot headless del archivo desplegado (cierra el gap render-real).
- **P6**: specs con ids ejecutables (trazar assert ↔ renglón del spec).
- Poda de reglas: revisar qué gates ya no pagan su costo a medida que el pipeline madura.
