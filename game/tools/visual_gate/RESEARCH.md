# Visual Gate — Investigación de QA Visual Automatizado para Assets 3D

**Fecha**: 2026-07-03  
**Alcance**: pipeline Dungeon Party (Blender headless + Claude como VLM + refs 2D ilustradas)  
**Problema raíz documentado**: Claude se auto-aprueba, juzga desde memoria sin comparar lado-a-lado, no detecta errores de gestalt ni derrames de pintura, oscila sin medir. El ojo humano entra 3 días por asset en lugar de al final.

---

## Índice

1. [Contexto: por qué falla el juicio VLM actual](#1-contexto)
2. [Métricas perceptuales programáticas](#2-métricas-perceptuales)
3. [Visual regression testing en engines de juego](#3-visual-regression-testing)
4. [VLM-as-judge: mejores prácticas y límites conocidos](#4-vlm-as-judge)
5. [Proporción por contrato: model sheet compliance](#5-proporción-por-contrato)
6. [Herramientas open-source relevantes](#6-herramientas-open-source)
7. [Menú de técnicas: aplicabilidad a nuestro caso](#7-menú-de-técnicas)
8. [Pipeline propuesto para el bestiario](#8-pipeline-propuesto)
9. [Fuentes](#9-fuentes)

---

## 1. Contexto

Los modos de falla documentados en la sesión Filomeno (2026-07-03) son exactamente los puntos ciegos conocidos de los VLMs como jueces visuales:

| Falla observada | Causa técnica documentada |
|---|---|
| PASS a baja resolución / encuadre ancho | El VLM no detecta errores finos de proporciones (>50% miss rate según Seeing Isn't Believing, 2026) |
| Ángulos no cubiertos (worm's eye, close-up) | VLMs evalúan la vista que reciben, no exigen cobertura de ángulos críticos |
| Comparación de memoria en vez de lado-a-lado | VLM single-answer scoring es el modo más débil; pairwise es más confiable |
| Oscilación sin números (demasiado lejos/cerca) | Razonamiento espacial fino: blindspot documentado en todos los modelos actuales |
| Sesgo del constructor | Builder bias + authority bias documentados en literatura (Judging the Judges, 2026) |
| Método agotado sin cambio | Sin criterio de parada numérico → ciclo indefinido |
| Derrame de pintura invisible | Errores no-perceptibles por baja resolución / ángulo; requieren inspección multi-view |

**Conclusión de la literatura (Seeing Isn't Believing, arXiv 2604.21523, Abril 2026)**: los VLM-evaluadores tienen tasa de fallo >50% en errores de composición espacial. El modo pairwise (dos imágenes lado a lado) es el más confiable, pero sigue fallando. No se deben usar solos como jueces únicos sin métricas adicionales.

---

## 2. Métricas Perceptuales Programáticas

### 2.1 SSIM — Structural Similarity Index

**Qué mide**: diferencia en luminancia, contraste y estructura pixel-a-pixel entre dos imágenes del mismo tamaño.

**Implementación**: `scikit-image.metrics.structural_similarity` (Python, BSD, sin deps GPU).

**Aplicable a 3D render vs 2D ilustración**: PARCIALMENTE. SSIM asume que las imágenes son del mismo dominio. Render 3D toon vs ilustración 2D tienen diferencias de trazo, textura y estilo que producen SSIM bajo aunque el asset sea correcto. Útil **solo cuando se comparan dos renders 3D del mismo asset** (revisión antes/después de un cambio).

**Caso de uso real aquí**:
- Golden image = render canónico aprobado (vista frontal, lateral, 3/4, worm's eye).
- Cada iteración: render las mismas vistas → SSIM vs golden → si cae por debajo de umbral, flagar para revisión humana.
- NO para comparar contra ilustración fuente 2D.

**Clasificación**: `aplicable-ya` (para regresión render-vs-render).

---

### 2.2 LPIPS — Learned Perceptual Image Patch Similarity

**Qué mide**: distancia perceptual en espacio de features de una red VGG/AlexNet preentrenada. Más sensible a diferencias semánticas y de textura que SSIM.

**Implementación**: `richzhang/PerceptualSimilarity` (GitHub, BSD). También disponible en `torchmetrics`.

**Aplicable a 3D render vs 2D ilustración**: LIMITADO. LPIPS fue entrenado en imágenes fotorrealistas de ImageNet. Aplica para comparar renders entre sí con más fidelidad perceptual que SSIM. Para render toon vs ilustración 2D, el score será alto (muy diferente) aunque las proporciones sean correctas, porque el estilo es distinto.

**Caso de uso real aquí**:
- Detectar regresiones entre versiones del mismo asset (si el shader cambió inesperadamente, LPIPS lo captura mejor que SSIM).
- NO reemplaza comparar vs referencia 2D.

**Clasificación**: `aplicable-con-trabajo` (requiere calibrar umbrales para estilo toon; usar sobre renders pareados, no sobre ilustración fuente).

---

### 2.3 ΔE CIEDE2000 — Color Difference

**Qué mide**: diferencia perceptual de color en espacio CIE L*a*b*. Estándar industrial. Fue diseñado para diferencias pequeñas de color, no para grandes divergencias de estilo.

**Implementación**: `scikit-image.color.deltaE_ciede2000`, también `colour-science/colour`, `lovro-i/CIEDE2000` (GitHub).

**Aplicable a 3D render vs 2D ilustración**: SÍ, con limitaciones. Se puede extraer la paleta dominante de la ilustración (los 5-10 colores canon del concept art) y comparar contra los colores promedio del render en las zonas clave (piel, pelo, ojos, sombra). Si ΔE > umbral (ej. >5), la paleta se desvió.

**Caso de uso real aquí**:
- Verificar que el shader toon usa la paleta correcta definida en el concept art.
- Útil para detectar el derrame de pintura del golem (zona cráneo con color de tronco).
- Requiere definir zonas de muestra (ROIs) en el render.

**Clasificación**: `aplicable-ya` (comparar paleta de zonas específicas render vs ilustración, implementación trivial).

---

### 2.4 Chamfer Distance de Siluetas

**Qué mide**: distancia media entre los puntos del contorno de dos formas binarias (siluetas). Cuantifica qué tan diferentes son las siluetas de dos imágenes.

**Implementación**: extraer silueta con `cv2.Canny` o `scikit-image.feature.canny`, binarizar, calcular distancia de chamfer o Hausdorff con `scipy.spatial.cKDTree`.

**Aplicable a 3D render vs 2D ilustración**: SÍ, esta es la métrica más directamente útil para comparar forma 3D vs concept 2D. El workflow:
1. Render del asset en fondo blanco (vista frontal, lateral, 3/4).
2. Extraer silueta del render → mask binaria.
3. Extraer silueta del concept art (o trazar manualmente una vez) → mask de referencia.
4. Calcular Chamfer Distance o IoU de siluetas.
5. Si la distancia supera umbral, la forma diverge del concept.

**Limitación**: requiere alinear escala y posición (normalization). Las ilustraciones 2D a menudo tienen poses distintas a la A-pose 3D.

**Clasificación**: `aplicable-con-trabajo` (setup inicial de masks de referencia requiere trabajo manual una vez por asset; después es automático).

---

### 2.5 Landmark Detection para Caras Estilizadas

**Qué mide**: puntos anatómicos (ojos, nariz, boca, contorno de cara) que permiten medir ratios de proporción.

**Paper relevante**: *StylizedFacePoint: Facial Landmark Detection for Stylized Characters* (OpenReview, 2025). Dataset FLSC con 2674 imágenes de 16 clips de cartoon, 98 landmarks por imagen.

**Implementación para assets estilizados**: MediaPipe Face Landmarker (478 puntos 3D) funciona para caras realistas. Para caras muy estilizadas como Filomeno (oso), los landmarks estándar fallan y se necesita fine-tuning o detección manual de puntos de referencia en el modelo 3D.

**Caso de uso real aquí (proporción por contrato)**:
- Medir en el concept art 2D: `ancho_ojo / ancho_cráneo`, `gap_ojos / ancho_cara`, `altura_hocico / altura_cabeza`.
- Medir los mismos ratios en el modelo 3D (vía Blender Python sobre el mesh, no sobre imagen).
- Assert: si el ratio 3D difiere del 2D por más de X%, falla el gate de proporción.
- Para Filomeno (orgánico, no cara humana): los landmarks se definen manualmente una vez y se miden con `bpy` sobre el mesh.

**Clasificación**: `aplicable-con-trabajo` (definir landmark mapping entre concept y mesh, hacerlo una vez por tipo de criatura).

---

## 3. Visual Regression Testing en Engines de Juego

### 3.1 Unreal Engine — Screenshot Comparison Tool

Documentado en UE 5.7. El workflow:
1. Un `Functional Screenshot Test Actor` en la escena captura renders durante automation tests.
2. Se genera una **golden image** (ground truth) en la primera corrida aprobada.
3. Corridas subsiguientes comparan contra el golden con tolerancias configurables: Zero / Low / Medium / High / Custom.
4. Tolerancias por canal RGBA, brightness range, local error threshold, global error threshold.
5. Opción de ignorar anti-aliasing (pixel shifting en bordes).
6. Visualizador muestra ground truth + diff + incoming, con blend interactivo.
7. Soporta alternativas de golden image para variaciones de hardware/driver.

**Lección clave para nuestro caso**: el paradigma golden-image con tolerancias configurables es estándar de industria. No requiere IA. Detecta regresiones de shader, material, y posición de mesh entre builds.

### 3.2 Godot — Estado del Arte

No hay herramienta oficial equivalente a UE. Lo disponible:
- `godot-rendering-tests` (Calinou, GitHub): colección de escenas de test de rendering para detectar regresiones en backends Vulkan/OpenGL.
- `godot-ui-automation` (graydwarf, GitHub): framework UI con screenshot validation contra baselines y tolerancia configurable.
- `Auto Screenshot` (Godot Asset Library, asset #3916): screenshots automáticos del viewport a intervalos.

**Gap real**: no hay integración screenshot + diff + CI/CD nativa en Godot 4. Se puede construir con `godot --headless` + script GDScript que exporta screenshots, luego comparar imágenes con Python (scikit-image SSIM/ΔE).

### 3.3 Blender Headless — blenderless

`blenderless` (PyPI, oqton/blenderless, MIT): paquete Python para rendering headless sin framebuffer. Resuelve el problema de que `bpy` solo se puede importar una vez por proceso. Soporta batch de vistas desde archivos 3D.

**Relevancia directa**: el pipeline Blender headless ya está en uso en el proyecto (scripts en `game/tools/blender/`). blenderless permite agregar renders automáticos multi-view sin abrir la GUI, integrables en un script de QA.

---

## 4. VLM-as-Judge: Mejores Prácticas y Límites Conocidos

### 4.1 Blindspots Documentados (Literatura 2025-2026)

Fuentes: *Seeing Isn't Believing* (arXiv 2604.21523, 2026), *MM-JudgeBias* (2026), *Fooling the LVLM Judges* (2025), *Beyond Perception Errors* (2026).

| Blindspot | Severidad | Evidencia |
|---|---|---|
| Errores espaciales finos (proporciones, gaps) | ALTA | >50% miss rate en benchmark de 4000 instancias |
| Conteo de objetos | ALTA | Conocido desde 2023, no resuelto |
| Detección de alucinaciones vs input | ALTA | "insensitive to hallucinated content" |
| Composición (qué está detrás/delante de qué) | ALTA | Marcado blindspot en multi-view |
| Diferencias de color sutil | MEDIA | Depende del contraste |
| Formas globales grandes | BAJA | VLMs son razonablemente buenos en gestalt general |

**Sesgos estructurales del VLM-juez**:
- **Builder bias**: el modelo que generó el asset tiende a aprobarlo (documentado aquí y en literatura).
- **Authority bias**: si se presenta el veredicto de otro agente primero, el juez coincide.
- **Position bias**: en pairwise, el primer elemento tiende a ganar.
- **Visual style bias**: sesgo hacia estilos occidentales/fotorrealistas.
- **Low-info bias**: cuando la imagen no es informativa, el modelo puntúa basado en texto/priors, no en la imagen (*When Vision-Language Models Judge Without Seeing*, 2026).

### 4.2 Técnicas que Mejoran el Juicio VLM

**Orden de efectividad según literatura**:

#### a) Pairwise forzado (lado a lado en UNA imagen)
El modo más confiable. Montar referencia 2D y render 3D en una imagen compuesta (collage) y pedir al VLM que señale diferencias específicas. El VLM es BUENO en comparar dos imágenes juntas; es DÉBIL en comparar una imagen con memoria.

**Implementación**: Pillow/PIL en Python para montar el collage.
```
[referencia_2D | render_3D_frontal]
[render_3D_lateral | render_3D_worm_eye]
```

#### b) Multi-view grid (contact sheet)
Una sola imagen con 4-6 vistas del asset (frontal, lateral, 3/4, posterior, worm's eye, close-up cara). El VLM procesa todo en una llamada y puede detectar inconsistencias entre vistas que no detectaría en imágenes separadas.

**Implementación**: Blender headless genera las 6 vistas → Python monta el grid → Claude evalúa el grid completo.

#### c) Flip test (espejar para resetear sesgo)
Espejar horizontalmente la imagen antes de pasar al VLM. Rompe el sesgo de "ya lo vi y me pareció bien". Si el veredicto cambia drásticamente entre la imagen normal y la espejada, hay sesgo de posición/familiaridad.

**Implementación**: `ImageOps.mirror()` en PIL, agregar a rutina.

#### d) Rúbrica por ítem con anclas binarias
En lugar de pedir un score global, pedir al VLM que evalúe cada dimensión por separado con ancla explícita:

```
ITEM: Posición de ojos
ANCLA FALLO: Los ojos están claramente más arriba/abajo/juntos/separados que en la referencia
ANCLA PASE: Los ojos coinciden con la referencia dentro de ~10% del ancho de cabeza
VEREDICTO (FALLO/PASE) + evidencia visible:
```

Este formato activa razonamiento explícito y reduce sesgo de puntuación global.

#### e) Overlay al 50% de opacidad
Superponer la silueta del concept art sobre el render con opacidad 50% y pedir al VLM que describa los desalineamientos. Requiere que las imágenes estén normalizadas a la misma escala y posición.

#### f) Anotaciones de medidas en imagen
Antes de pasar al VLM, renderizar las medidas clave encima de la imagen (líneas guía, etiquetas con ratios medidos). Esto convierte el juicio de gestalt en verificación de números, donde el VLM es más confiable.

### 4.3 Lo que NO puede Delegar al VLM

- Detección de derrames de paint (píxeles mal asignados visibles solo en ciertos ángulos): requiere multi-view automático + diff vs. imagen de referencia, no VLM.
- Conteo preciso de elementos (número de dedos, huesos, chunks).
- Medición de proporciones sub-píxel.
- Juicio definitivo de "se ve bien" sin comparación lado a lado.

---

## 5. Proporción por Contrato: Model Sheet Compliance

### 5.1 Estado del Arte

No existe un tool open-source unificado que tome un concept art 2D y un modelo 3D y calcule "compliance de proporciones". Es un gap real en la industria.

Lo que existe:

**Para caras realistas**: MediaPipe Face Landmarker (Google) detecta 478 puntos 3D en tiempo real. Permite medir ratios: `brow-eye height ratio`, `jaw width ratio`, `nose-lip distance`. Funciona en render 2D de la cara.

**Para caras estilizadas**: Paper *Facial Landmark Detection for Stylized Characters* (FLSC dataset, 2674 imágenes, 98 landmarks). Modelo fine-tuneado sobre cartoon faces. Disponible para descarga en OpenReview.

**Para assets orgánicos no-humanoides (Filomeno, golem)**: no hay solución lista. El approach viable:
1. Definir manualmente los landmarks en el concept art (una vez): marcar puntos clave en image editor.
2. Definir los puntos correspondientes en el mesh 3D (una vez): vertex groups o empty objects en Blender.
3. Render de la vista canónica con los landmarks renderizados como overlays.
4. Script Python calcula ratios y hace assert vs. los del concept art.

**Ratios útiles para Filomeno**:
- `ancho_ojo / ancho_cráneo` (en vista frontal)
- `gap_inter_ocular / ancho_cara` (separación de ojos)
- `altura_hocico / altura_total_cabeza`
- `altura_oreja / altura_cabeza`
- `ancho_hombros / altura_total`

### 5.2 Cómo Implementarlo en Blender Python (bpy)

```python
# Ejemplo de medición de proporción via bpy
import bpy
import mathutils

# Puntos landmark definidos como vértices nombrados o empties
# En el script de QA:
mesh = bpy.data.objects["filomeno_body"]
bpy.context.view_layer.update()

# Acceder a vértices específicos por grupo o por índice fijo
# y calcular distancias en world space
eye_left = mesh.matrix_world @ mesh.data.vertices[IDX_EYE_LEFT].co
eye_right = mesh.matrix_world @ mesh.data.vertices[IDX_EYE_RIGHT].co
skull_width = (skull_left - skull_right).length
eye_gap = (eye_left - eye_right).length
ratio_eyes = eye_gap / skull_width

CONCEPT_ART_RATIO = 0.38  # medido del PNG de referencia
TOLERANCE = 0.05
assert abs(ratio_eyes - CONCEPT_ART_RATIO) < TOLERANCE, \
    f"Eye gap ratio {ratio_eyes:.3f} diverge from concept {CONCEPT_ART_RATIO:.3f}"
```

**Clasificación**: `aplicable-con-trabajo` (setup inicial de 1-2h por tipo de criatura, luego automático en cada iteración).

---

## 6. Herramientas Open-Source Relevantes

| Tool | Función | Licencia | URL |
|---|---|---|---|
| `blenderless` | Rendering headless Blender batch multi-view | MIT | https://github.com/oqton/blenderless |
| `scikit-image` | SSIM, ΔE CIEDE2000, Canny (siluetas) | BSD | https://scikit-image.org |
| `richzhang/PerceptualSimilarity` | LPIPS | BSD | https://github.com/richzhang/PerceptualSimilarity |
| `colour-science/colour` | ΔE CIEDE2000, conversión colorspace | BSD | https://github.com/colour-science/colour |
| `lovro-i/CIEDE2000` | ΔE CIEDE2000 puro Python | — | https://github.com/lovro-i/CIEDE2000 |
| `Pillow / PIL` | Montar contact sheets, overlays, flip | HPND | https://pillow.readthedocs.io |
| `scipy.spatial.cKDTree` | Chamfer / Hausdorff de siluetas | BSD | https://scipy.org |
| `MediaPipe` | Landmark detection caras realistas | Apache 2.0 | https://mediapipe.dev |
| `godot-rendering-tests` | Regression tests renders Godot | MIT | https://github.com/Calinou/godot-rendering-tests |
| `godot-ui-automation` | Screenshot baseline comparison Godot 4.x | MIT | https://github.com/graydwarf/godot-ui-automation |

**No existe** un tool integrado "concept-art → 3D model compliance checker". Es el gap que este pipeline tiene que llenar con código propio.

---

## 7. Menú de Técnicas: Aplicabilidad a Nuestro Caso

Leyenda: `[aplicable-ya]` = sin trabajo extra significativo | `[aplicable-con-trabajo]` = setup 2-8h | `[no-aplica]` = dominio incorrecto o imposible sin infraestructura mayor

### Métricas Programáticas

| Técnica | Estado | Caso de uso aquí | Notas |
|---|---|---|---|
| SSIM render-vs-golden | `[aplicable-ya]` | Detectar regresión de shader/material entre iteraciones | NO sirve para comparar vs ilustración 2D |
| ΔE CIEDE2000 por zona | `[aplicable-ya]` | Verificar paleta toon vs concept art en ROIs (ojo, piel, sombra) | Requiere definir ROIs una vez por asset |
| Chamfer de siluetas | `[aplicable-con-trabajo]` | Comparar forma del render vs silueta del concept art | Requiere normalizar escala/posición |
| LPIPS render-vs-golden | `[aplicable-con-trabajo]` | Regresión perceptual más sensible que SSIM | Calibrar umbrales para estilo toon |
| LPIPS render-vs-ilustración 2D | `[no-aplica]` | El score siempre será alto por diferencia de estilo | Falsos positivos inevitables |
| Landmark detection MediaPipe | `[no-aplica]` | Assets no son caras humanas realistas | Falla en animales estilizados |
| Landmark detection manual bpy | `[aplicable-con-trabajo]` | Proporción por contrato (ratios concept vs mesh) | El approach correcto para orgánicos |

### VLM como Juez

| Técnica | Estado | Caso de uso aquí | Notas |
|---|---|---|---|
| Pairwise forzado (collage PIL) | `[aplicable-ya]` | Gate VLM principal: ref 2D + render en una imagen | La técnica más confiable según literatura |
| Multi-view grid (contact sheet) | `[aplicable-ya]` | Cubrir worm's eye, close-up, posterior en una llamada | Blender headless ya disponible |
| Rúbrica por ítem con anclas | `[aplicable-ya]` | Reemplazar score global por checklist binario | Reduce sesgo de puntuación holística |
| Flip test (espejar) | `[aplicable-ya]` | Romper sesgo de familiaridad del constructor | PIL ImageOps.mirror(), agregar a rutina |
| Overlay 50% de opacidad | `[aplicable-con-trabajo]` | Visualizar desalineamientos de silueta | Requiere normalización de escala |
| Anotaciones de medidas en imagen | `[aplicable-con-trabajo]` | Convertir juicio gestalt en verificación de números | PIL Draw para líneas guía y ratios |
| VLM single-answer sin referencia | `[no-aplica]` | Modo actual — demostrado que falla | Eliminarlo del pipeline |
| VLM con bajo resolución / encuadre ancho | `[no-aplica]` | Causa directa de los PASS incorrectos de Filomeno | Requiere resolución mínima y encuadres ajustados |

### Visual Regression Testing

| Técnica | Estado | Caso de uso aquí | Notas |
|---|---|---|---|
| Golden image + SSIM diff | `[aplicable-ya]` | Detectar cambios involuntarios entre commits de assets | 5 vistas fijas por asset; git-trackeable |
| UE Screenshot Comparison Tool | `[no-aplica]` | Solo si se migra a Unreal | Referencia de arquitectura |
| Godot headless + screenshot script | `[aplicable-con-trabajo]` | Gate de rendering en engine vs en Blender | Requiere escena de test por asset |

---

## 8. Pipeline Propuesto para el Bestiario

El gate visual automatizado ocupa 3 capas; el ojo de Joan entra en la cuarta.

```
LAYER 1 — MÉTRICAS PROGRAMÁTICAS (sin VLM)
Blender headless render 6 vistas (frontal/lateral/3-4/posterior/worm-eye/close-up)
  → ΔE CIEDE2000: paleta de zonas clave vs ROIs del concept art
  → Chamfer Distance: silueta del render vs silueta del concept (vista frontal + lateral)
  → SSIM vs golden anterior: detectar regresión accidental
  → Proporción bpy: ratios mesh vs ratios medidos del concept art
Si cualquier métrica falla → STOP, no pasa al VLM. Mostrar qué falla.

LAYER 2 — VLM PAIRWISE (con Claude como juez)
Generar contact sheet: 
  columna izquierda = 3 vistas del concept art 2D
  columna derecha = las 3 vistas equivalentes del render 3D
Una imagen → una llamada a Claude con rúbrica por ítem:
  □ Proporciones globales (cabeza/cuerpo/extremidades)
  □ Posición y tamaño de ojos
  □ Forma de hocico/boca
  □ Silueta total
  □ Paleta de colores (comparar visualmente)
  □ Detalle / textura coherente con estilo toon
Cada ítem: PASA / FALLA + evidencia específica en texto.
Si 2+ ítems fallan → STOP, no llega a Joan.

LAYER 3 — MULTI-ÁNGULO (Claude, segunda llamada)
Contact sheet con 6 vistas del 3D solo (incluyendo worm's eye y close-up de cara).
Rúbrica: ¿hay errores visibles SOLO desde este ángulo que no se ven en frontal?
  □ Paint bleeding / texture leak en alguna vista
  □ Geometry clipping
  □ Silueta inesperada desde abajo
  □ Ojos/boca correctos en close-up
Si hay errores → STOP.

LAYER 4 — OJO HUMANO (Joan)
Recibe: contact sheet Layer 2 + close-up Layer 3 + reporte de métricas Layer 1.
Veredicto final: APROBADO / CAMBIOS.
Esta capa tiene CONTEXTO COMPLETO y solo ve assets que pasaron los gates anteriores.
```

### Criterio de Parada para Iteraciones

Agregar al flujo de trabajo:
- Máximo **3 iteraciones** de un mismo feature (ej: posición de ojos) antes de escalar.
- Si un ratio no converge después de 2 iteraciones con medir → buscar causa raíz en el mesh, no ajustar intuitivamente.
- Cada ajuste requiere MEDIR el ratio antes y después, no juzgar visualmente si mejoró.

### Implementación Inmediata (orden de prioridad)

1. **Contact sheet PIL** (1h): script Python que monta ref 2D + render lado a lado y genera imagen para Claude.
2. **Multi-view Blender headless** (1-2h): 6 cámaras fijas en script `gen_views.py`, render batch.
3. **ΔE por zonas** (2h): definir ROIs en el concept art (coordenadas de píxel), extraer color medio, calcular ΔE vs render.
4. **Rúbrica por ítem en prompt** (30min): reemplazar "evalúa el asset" por checklist binario con anclas.
5. **Flip test** (15min): agregar `ImageOps.mirror()` a la rutina de Claude review.
6. **Chamfer de siluetas** (3-4h): extraer masks, normalizar, calcular distancia.
7. **Proporción bpy** (3-4h por tipo de criatura): definir landmark vertices, calcular ratios, assert vs concept.

---

## 9. Fuentes

- [Seeing Isn't Believing: Uncovering Blind Spots in Evaluator VLMs (arXiv 2604.21523, 2026)](https://arxiv.org/abs/2604.21523)
- [MM-JudgeBias: A Benchmark for Evaluating Compositional Biases in MLLM-as-a-Judge (2026)](https://arxiv.org/pdf/2604.18164)
- [Judging the Judges: A Systematic Evaluation of Bias Mitigation Strategies in LLM-as-a-Judge Pipelines (2026)](https://arxiv.org/pdf/2604.23178)
- [Fooling the LVLM Judges: Visual Biases in LVLM-Based Evaluation (2025)](https://arxiv.org/pdf/2505.15249)
- [When Vision-Language Models Judge Without Seeing: Exposing Informativeness Bias (2026)](https://arxiv.org/pdf/2604.17768)
- [Beyond Perception Errors: Semantic Fixation in Large Vision-Language Models (2026)](https://arxiv.org/pdf/2604.12119)
- [Facial Landmark Detection for Stylized Characters (FLSC dataset)](https://openreview.net/pdf/726e10ade7d55470fbc382488cefab81f72756a3.pdf)
- [StylizedFacePoint: Facial Landmark Detection for Stylized Characters](https://openreview.net/forum?id=J3mF5Ea5JG)
- [VLM-as-a-Judge Protocol (emergentmind)](https://www.emergentmind.com/topics/vlm-as-a-judge-protocol)
- [Screenshot Comparison Tool in Unreal Engine 5.7](https://dev.epicgames.com/documentation/unreal-engine/screenshot-comparison-tool-in-unreal-engine)
- [blenderless — Headless Blender Rendering (PyPI)](https://pypi.org/project/blenderless/)
- [oqton/blenderless (GitHub)](https://github.com/oqton/blenderless)
- [richzhang/PerceptualSimilarity — LPIPS (GitHub)](https://github.com/medical-images-process/PerceptualSimilarity)
- [LPIPS en torchmetrics](https://lightning.ai/docs/torchmetrics/stable/image/learned_perceptual_image_patch_similarity.html)
- [lovro-i/CIEDE2000 — ΔE Python (GitHub)](https://github.com/lovro-i/CIEDE2000)
- [colour-science/colour — ΔE CIEDE2000](https://github.com/colour-science/colour/blob/develop/colour/difference/delta_e.py)
- [scikit-image Python image processing](https://scikit-image.org)
- [godot-rendering-tests (Calinou, GitHub)](https://github.com/Calinou/godot-rendering-tests)
- [godot-ui-automation — Godot 4.x visual testing (GitHub)](https://github.com/graydwarf/godot-ui-automation)
- [How to Build a Multi-View 3D Renderer with Python + Blender](https://medium.com/data-science-collective/how-to-build-a-multi-view-3d-renderer-with-python-blender-3d-gaussian-splatting-100-automated-ce634bae22d8)
- [Our Workflow with Blender and Godot (Blender Studio)](https://studio.blender.org/blog/our-workflow-with-blender-and-godot/)
- [CharNeRF: 3D Character Generation from Concept Art (arXiv 2402.17115)](https://arxiv.org/pdf/2402.17115)
- [Cross-Cultural Expert-Level Art Critique Evaluation with VLMs (2026)](https://arxiv.org/html/2601.07984)
- [Sauce Labs: Best Visual Regression Testing Tools of 2026](https://saucelabs.com/resources/blog/comparing-the-20-best-visual-testing-tools-of-2026)
- [The 20 Best Visual Regression Testing Tools of 2026 (Percy)](https://percy.io/blog/visual-regression-testing-tools)
