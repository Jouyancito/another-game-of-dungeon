# Realismo estilizado CON rendimiento — investigación y plan (2026-08-27)

**Encargo**: Joan, 2026-08-27 — *"diseño más realista que también esté bien en rendimiento;
el juego hoy se siente Genshin Impact pero con polys no definidos"*.
**Método**: 7 agentes ultracode (2 retro local + 5 investigación web), 120+ fuentes.
**Doc hermano**: `_sketch_intake_protocol.md` (pipeline Joan-dibuja → Claude-implementa).
**Regla de este doc**: cada sección termina en acción concreta. Lo que no baja a acción, no entró.

---

## 0. El diagnóstico en una línea

"Genshin con polys indefinidos" NO se arregla con más geometría. Se arregla con las
**tres palancas que definen la geometría simple**, en este orden de retorno:

1. **LUZ + ATMÓSFERA** — la tesis Valheim, confirmada por su CEO: *composición e
   iluminación importan más que polycount y resolución de textura*. Hoy el juego
   **no tiene NINGÚN WorldEnvironment propio** (auditoría 2026-08-27: Environment y
   DirectionalLight solo existen en escenas dev). La mitad del problema es luz plana.
2. **DETALLE HORNEADO** — normal/AO/curvature bakeados: la luz por-píxel define los
   planos que la malla no tiene. El guardián v15+ ya lo estrenó; falta generalizarlo.
3. **TEXTURA REUTILIZABLE RICA** — trim sheets + palettes: bordes biselados en el
   normal map ("Ultimate Trim", Insomniac GDC 2015) = look high-poly sin subir un tri.

Las técnicas NPR duras (outlines, toon ramps) van EN CONTRA del objetivo
estilizado-realista. El corpus SIGGRAPH (curso *Stylized Rendering in Games*)
apunta al enfoque Prince of Persia/Borderlands: **estilo en textura y luz, shading
físicamente plausible**. Implicación de dirección: evolucionar DP_ToonGrounded de
"toon" a "ilustrativo" (bandas suaves + normal maps + sombra teñida, menos outline).

## 1. Plan de ataque (orden impacto/esfuerzo)

| # | Palanca | Costo | Impacto | Entregable |
|---|---|---|---|---|
| 1 | **Luz y atmósfera por bioma** | horas | TODO el juego a la vez | `Environment.tres` por piso + `_mood_canon.md` (método §3) |
| 2 | **Bakes automatizados** | días | cada asset se lee "definido" | `bake_detail.py` en el pipeline bpy (generalizar `texture_bake.py` del guardián) |
| 3 | **Vertex blend triplanar** (rocas/muros/terreno) | días | mata el look "asset pegado" | `paint_weathering()` en bpy + `rock_blend.gdshader` compartido |
| 4 | **Trim sheet maestro + palette** | 1-2 semanas amortizadas | arquitectura de dungeon entera | trim 2K (6-8 franjas, bisel 45°) + `trim_uv.py` |
| 5 | **Dither LOD + visibility ranges** | horas | pradera estable | `PixelDither` + rangos 30-60 m en clutter |
| 6 | Impostors octaédricos / SDFGI | diferido | — | solo con profiling que lo justifique / solo si hay día-noche |

**Primer paso obligatorio**: preset de Environment (mazmorra-antorcha, mazmorra-fría,
pradera-crepúsculo) y REJUZGAR los assets actuales bajo esa luz ANTES de decidir
cuánta textura nueva hace falta.

## 2. Presupuesto de frame — GTX 1080, 1080p, 16.6 ms

| Sistema | Presupuesto |
|---|---|
| Geometría opaca + jefes (shader uber) | ~5 ms |
| Sombras (1 direccional, 2-3 splits) | ~2.5 ms |
| Vegetación MultiMesh chunked + LOD | ≤2 ms |
| GI (ideal 0; SDFGI half-res si día/noche) | 0-3 ms |
| MSAA 2x + alpha-to-coverage | ~1 ms |
| Partículas/efectos coop (4 jugadores + jefe) | ~2 ms |
| Post (glow, grading) | ~1.5 ms |
| Reserva/CPU submit | ~2.5 ms |

**Reglas duras** (todas con fuente medida):
- **MSAA 2x + alpha-to-coverage en follaje. NADA de TAA**: cuesta ~1.2 ms fijos en
  una 1080 (issue #61905) y embarra el estilo. (Nota: el canon del shimmer 2026-07-31
  eligió TAA para el follaje — REVISAR ese trade con alpha-to-coverage antes de fijar.)
- **NO occlusion culling en pradera** (cuesta más de lo que ahorra en abierto); SÍ en interiores por sala.
- **Vegetación = MultiMesh chunked (16-32 m) sin colisión**, tope 2 ms.
- **Warm-up de shaders al cargar** (lección Road to Vostok: stutter de 1-1.5 s al primer cast).
- **Efectos de habilidad sin luces dinámicas con sombra** (lección muzzle-flash Vostok): omni sin sombra + emissive + partículas.
- **Prohibido render doble** (espejos/PiP/portales) salvo presupuesto explícito.
- **Decidir día/noche TEMPRANO**: activa o libera ~3 ms (SDFGI) y condiciona la palanca #1.
- Jefes 10 m: siempre visibles (sin visibility range) pero con 2-3 LODs de import.

## 3. Método repetible: fotograma/cuadro → Environment de Godot (8 pasos)

Lo que hicieron los grandes, a escala hobby: Sucker Punch midió los negros/blancos de
Kurosawa cuadro a cuadro (SIGGRAPH 2021 *Real-Time Samurai Cinema*); Rockstar citó a
Bierstadt y los luministas para RDR2 (*fondo luminoso, primer plano oscuro*); BOTW
declaró gouache+plein-air; Firewatch hizo que **el cielo gobierne la paleta**.
**Se copia la RELACIÓN (key/fill, dónde vive el negro), nunca los píxeles.**

Por cada bioma: elegir UN fotograma/cuadro canónico y correr:

1. **Luz key** → `DirectionalLight3D`: elevación (rasante -6/-15° = hora dorada;
   -60° = mediodía) + `light_temperature` (dorada 3000K, mediodía 5800K, luna 8000K+).
2. **Sombras** → ¿de qué color? Nunca negras (Ghibli): `ambient_light` desde el sky.
   Contraste key:fill — drama 4:1, Ghibli suave 2:1.
3. **Muestrear 5 colores** (eyedropper promediado 11×11): cielo cenit, cielo horizonte,
   luz, sombra, niebla → sky material + `fog_light_color`.
4. **Niebla** → ¿a qué distancia se funde todo con el cielo? `fog_density` calibrada +
   `aerial_perspective 1.0` (el efecto luminista RDR2) + `fog_sky_affect 0.0`.
5. **Histograma** del fotograma (truco Kurosawa-mode) → tonemap AgX/ACES + exposure +
   contraste hasta que el screenshot del juego dé un histograma similar.
6. **LUT** del fotograma (GD Grader / Imagen AI) → `adjustment_color_correction` (Texture3D).
7. **Acentos** al FINAL: glow con threshold alto (solo brilla lo que debe), omnis cálidas
   en focales. Orden SIEMPRE: sky+ambient → key → fog → grading → recién antorchas.
8. **Verificar contra la referencia**: screenshot del juego AL LADO del fotograma,
   mismo encuadre, orbitado. Es "verify by view" aplicado a la luz.

**Color script por piso** (técnica Pixar, 30 min): una fila de thumbnails — color
dominante + acento por piso (P1 verde-dorado → P3 azul-piedra → jefe rojo-negro).
Cada `Environment.tres` se deriva de su thumbnail.
**Color reservado de gameplay** (gramática ufotable): una familia de color EXCLUSIVA
para "esto se ataca" (puntos débiles/núcleos) y otra para peligro (wind-ups), ausentes
de la paleta ambiental de todos los biomas.

## 4. Arquitectura del bestiario (de los juegos referenciados, con código)

1. **Composición estilo Valheim** (docs de modding Jötunn = estructura real): escena
   `creature_base.tscn` con nodos `Health/AIBrain/AttackSet/LootDrop/Visual`; TODA la
   variación en Resources. El jefe NO es una clase: es `is_boss = true` + partes + fases.
   Los ataques de mobs y jugador comparten el MISMO Resource de ataque (un solo camino de daño).
2. **Partes como datos estilo Monster Hunter**: cada criatura un `.tres` con
   `BodyPart { nombre, hp_parte, multiplicadores por tipo de daño, drop_al_romper, hueso }`.
   Umbral de diseño MH: multiplicador ≥45 = punto débil. **Romper una parte abre una
   debilidad nueva** (coraza rota → núcleo expuesto) — puzzle, no sponge. Daño alto ⇒
   wind-up ≥1 s + ventana de castigo (ya canon del guardián).
3. **Colisión estilo SotC** ("colisión deformable" barata): shapes simples por hueso vía
   `BoneAttachment3D` con `part_id` en metadata; el jugador es una cápsula. Si algún
   jefe se trepa: reparentar el punto de agarre al BoneAttachment tocado — el patrón
   exacto de SotC a costo trivial.
4. **Kit modular estilo Skyrim** (2 artistas → 400+ dungeons): footprint base con
   múltiplos estrictos (módulo 4 m / sala 8 m), pivote suelo-centro INMUTABLE, puerta de
   dimensión única, naming `dgn_<kit>_<pieza>_<variante>`. **El golem comparte materiales
   del kit → "el dungeon que camina" sale gratis.** Graybox del encuentro ANTES de texturar.
5. **Test de silueta estilo Supercell**: render en negro puro a ~10% de pantalla; si el
   mob no se identifica, rehacer la FORMA. Sumar al board de juicio canónico.
6. **Fórmula por piso estilo Valheim**: 1 jefe + 2-3 mobs + 1 recompensa que habilita el
   siguiente tier. Es el esqueleto del bestiario con esfuerzo mínimo.
7. **Lección OpenMW**: motor genérico + contenido en datos — nunca una clase GDScript
   por monstruo.

## 5. Retro del proceso (mayo-agosto: 260 commits)

**El dato central**: con ficha ESTRUCTURA + gates + board, un mob converge en ~2 días
(tortuga y halcón: 8/10 a la primera pasada del pipeline completo). Sin eso: el golem
quemó 3 encarnaciones, ~26 pasadas y 3 meses. **El pipeline ES el producto.**

Tres fugas medidas: instrumentos ciegos (9 commits de detectores que nunca dispararon),
canon no cargado (2,5% se carga solo; lo que hay que ir a buscar FALLA), lecciones
repetidas ("queda flotando" pagado 4+ veces hasta el floor-gate/anchor de v17-v20).

**Las 8 mejoras (priorizadas — implementar como gates/hooks, no como memoria):**
1. **Presupuesto de iteraciones**: ~6 versiones sin nota ≥7 → STOP, volver a Fase 0
   (ficha con mitad ESTRUCTURA). Es lo que separó a la tortuga del golem.
2. **Matar `[skip-gate]` para assets** (solo docs/chore): mob sin probe+deploy+board va
   como `wip`, no como `feat(art)`. Julio fabricó 8 mobs batch; agosto los devolvió casi
   todos a la cola.
3. **Queja de Joan → gate el MISMO día**: todo defecto geométrico nombrado ("flota",
   "muy alto", "chocan") se traduce a assert de geometría viva antes de cerrar sesión.
4. **Control positivo para todo instrumento nuevo**: antes de confiar en su primera
   lectura limpia, mostrarle un caso malo conocido.
5. **Checkpoint Joan en BLOCKOUT** (post-Fase 2), no solo al final: en el golem, cada
   queja estructural llegó DESPUÉS de texturizar la estructura equivocada.
6. **P5 (captura Godot headless del archivo desplegado)**: el único gate que cierra
   "Blender miente / Godot es verdad" automáticamente.
7. **Preflight bloqueante por hook** (si no está escrito con citas, el build no corre).
8. **Rampa por defecto** para todo parámetro estético (dato: 5/5 valores elegidos por
   el agente salieron mal; con rampa, Joan converge en 1 ronda).

## 6. Biblioteca de referencias: mood-canon y higiene

- **Crear `_mood_canon.md` + un `Environment.tres` por bioma** destilando
  `poe_visual_bar` + `world_mood_ig` + `nature_anim_style` con el método §3. Hoy esas
  4 refs de mood tienen CERO cableo porque no existe Environment de juego.
- **Nueva convención**: toda síntesis de mood termina en bloque **"Parámetros Godot"**
  (valores concretos de Environment/luces), igual que las de assets terminan en
  correcciones de generador. Sin ese bloque, la ref muere en prosa.
- **Hueco declarado**: no hay refs de cine/pintura clásica de luz (Rembrandt, Mononoke,
  Friedrich, Bierstadt). Abrir `mood_cine_*` cuando Joan traiga frames — el método §3
  las convierte en parámetros.
- Recetas listas sin usar: anatomía del relámpago (poe_visual_bar §7, lista para
  código), god-rays (crystal_ceiling/mine_adit), gradiente wet/dry junto al río.
- Higiene: síntesis para `skyrim_faces`; 7 `.import` huérfanos de village_*; 10 carpetas
  sin imagen; decidir destino de la familia `village_*`; crear refs de wasp y snake.

## 7. Fuentes completas

Los 7 informes con sus 120+ fuentes viven en engram
(`investigacion/realismo-performance-*`) y el detalle por URL en cada sección de
arriba. Charlas ancla: *The Ultimate Trim* (GDC 2015), *Skyrim's Modular Level Design*
(GDC 2013), *Real-Time Samurai Cinema* (SIGGRAPH 2021), postmortem SotC (GDC 2006),
curso *Stylized Rendering in Games* (SIGGRAPH 2010), docs Jötunn/MonsterDB (Valheim),
guía Godot 3D optimization 2026 + issues #61905/#89492.
