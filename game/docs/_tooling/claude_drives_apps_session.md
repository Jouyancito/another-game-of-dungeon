# Session — Claude Code operando aplicaciones (capa de capacidad)

> Arrancada 2026-06-27. Track propio: cómo Claude Code **opera** apps (Blender, Godot, dev tools)
> mejor — no "saber Blender", sino la capa de actuación + percepción + loop que sirve a TODO el
> bestiario y al juego. Base de dos investigaciones multi-agente (técnicas + prior-art de repos),
> web-verificadas y adversarialmente chequeadas.

## El marco (la tesis)

Operar una app son **3 cosas, no una**:

1. **Actuación** — cómo Claude toca la app (clic, tecla, correr `bpy`/GDScript).
2. **Percepción** — cómo Claude VE el resultado.
3. **Loop** — cómo se autocorrige hasta converger.

La trampa es obsesionarse con la actuación ("que clickee mejor"). **La palanca real está en percepción + loop**: si Claude ve bien lo que produjo y tiene una señal objetiva de "esto mejoró o no", converge con cualquier método de actuación. Joan ya está adelante en esa dimensión (`art-ref-critic`, `diagnostic-view-kit`, `verify-before-present`). Lo que falta es **endurecerla con una métrica no-LLM**.

## Ranking de vías de actuación (solo-dev Windows 11 Home + GTX 1080)

`① Headless/CLI ≈ ② MCP app-server ≫ ③ Vision/computer-use > ④ UIA`

| Vía | Madurez / Windows | Cuándo usarla |
|---|---|---|
| **① Headless / CLI** | GA, nativo, confirmado | Todo lo determinístico no-visual: compile/import gate, GUT, fórmulas, gen de assets, render Cycles. La base actual. |
| **② MCP app-server** | patrón maduro, confirmado | Blender vivo (texture-paint sobre geometría, viewport-screenshot). Godot: envolver TUS primitivas (`validate.ps1`, anim-capture, GUT) en un FastMCP chico. |
| **③ Vision / computer-use** | beta, claims inflados | UN nicho: manejar el JUEGO CORRIENDO + leer el HUD (puro pixel, sin API). Para EDITORES es la peor herramienta. |
| **④ UIA / accessibility** | ciega a UIs framebuffer | Experimento falsable: `--accessibility always` en Godot 4.5+. Menús de Control-nodes podrían volverse driveables. Mundo 3D y HUD `_draw` nunca entran. |

**Por qué Headless+MCP > vision:** determinístico, rápido, barato, devuelve valores reales (no OCR), sin foreground-steal ni elementos stale — exactamente las paredes que chocó Synapse.

## El multiplicador: el loop de percepción (el 80% de la ganancia)

La literatura (LL3M, BlenderGym, ReLook 2025) valida el loop de Joan y da las correcciones que faltan:

1. **Renders diagnósticos multi-vista** (clay + silueta, contact-sheet ~2k px), no beauty-shot. Los VLM son débiles juzgando profundidad/altura desde una sola imagen (DH-Bench).
2. **Nunca confiar SOLO en el ojo del VLM.** BlenderGym: Claude como verificador alinea ~0.66 vs ~0.79 humano-humano, con sesgo posicional. Parear `art-ref-critic` con **métrica no-LLM**: silhouette IoU/Chamfer, CLIP-sim contra la ref commiteada, o pixel-diff (**odiff**).
3. **El paso COMPARAR que falta entero.** Review hoy = leer 30 frames a mano. `odiff` (MIT, single-binary Windows) entre captura y golden → bajo threshold PASA solo; si se pasa, RECIÉN gastás tokens en critic + ojo. Es el visual-regression gate ausente.
4. **Veredicto estructurado** (PASS/FAIL por eje + score 0-1, voto multi-sample), no prosa.

## Patrones cross-repo (la señal real — a qué convergió toda la gente)

1. **La app expone un socket/addon y vos le mandás código arbitrario.** Un tool de código (`execute_blender_code`, `game_eval` GDScript) le gana a 50 wrappers angostos que se rompen en cada update.
2. **Arquitectura dual: headless para batch + socket/autoload para runtime vivo.** Trabajo estático reproducible + socket al build CORRIENDO para inspeccionar nodos/señales/estado. Es la forma del tester de noche.
3. **El loop `screenshot→VLM→act` es dominante.** Nunca juzgar un asset 3D desde una sola cámara.
4. **Determinismo = AUTORIDAD, VLM = ASESOR**, con gate barato (pixel-diff) ANTES del VLM.
5. **Pure-vision para UI custom-drawn; los árboles de accesibilidad son ~ciegos en Godot.** Híbrido: UIA/MCP para Blender(Qt)/diálogos/IDE, visión adentro de la ventana Godot.

## Backlog de repos — Tier S (estudiar YA, vetados vivos + Windows-fit)

| Repo | Qué robar | Lic |
|---|---|---|
| `ahujasid/blender-mcp` | escape-hatch `execute_blender_code`. Ya lo corrés — injertale medición | MIT |
| `trycua/cua` | el **cua-driver**: clickea/teclea SIN robar foco/cursor, enchufa como MCP | MIT |
| `AB498/computer-control-mcp` | **Windows Graphics Capture** (`use_wgc`) → arregla frame NEGRO de ventana GPU. Reemplazo libre de Synapse, CPU-only | MIT |
| `Coding-Solo/godot-mcp` | loop `godot --headless` + capturar errores, CERO plugin | MIT |
| `anthropics/anthropic-quickstarts` (computer-use-demo) | esqueleto del loop + image-pruning/prompt-caching | MIT |

**Pega directo al golem:** `glonorce/Blender_mcp` (MIT) — analizador BVH de ensamblaje: mide huecos vértice-a-cara reales entre chunks + interpenetración + score 0-100. Fix a nivel código del "cubos con huecos, sin peso". + **Gen3DEval** (patrón): juzgar 3D desde renders de NORMALES.

**Tier A (después):** `PatrykIti/blender-ai-mcp` (visión asesor / scene_assert autoridad) · `satelliteoflove/godot-mcp` (congelar reloj + step-until-condition + estado JSON) · `Nokorpo/GDSnap` (`godot --headless --script cli.gd` → pixel-diffs de escenas) · `gdUnit4` (`scene_runner`).

## Mapa de comunidad

- **Registries MCP:** mcp.so, Smithery, Glama, PulseMCP + awesome-lists `punkpeye/awesome-mcp-servers`, `appcypher/awesome-mcp-servers`.
- **BlenderMCP community** (Discord del repo 23k⭐ de ahujasid) — hub que dicta convenciones DCC+LLM.
- **Computer-use research:** XLANG Lab (benchmark OSWorld) · Simular AI (Agent-S) · ByteDance Seed/UI-TARS · trycua/Cua. Hubs: `ranpox/awesome-computer-use`, `ZJU-REAL/Awesome-GUI-Agents`.
- **Godot testing:** Discord oficial #unit-testing · GUT (bitwes) · gdUnit4.
- **Vision-as-critic:** SALT-NLP/Stanford (Design2Code) · Self-Refine/Reflexion · Gen3DEval (UCL+Meta, CVPR 2025) · MLLM-as-a-Judge.

## Mitos / trampas (no perseguir espejismos)

- **Computer-use de Anthropic NO está en Claude Code** — beta raw-API, referencia solo Linux/Docker (maneja un escritorio Linux virtual, NO tu Windows), ~1000-1800 tokens/screenshot, cloud paga. La GTX 1080 es irrelevante para esto.
- **UI-TARS / OmniParser / Agent-S** — referencia arquitectónica, NO drop-in: hosteás un VLM (1080 8GB no banca un 7B cómodo → 4-bit lento) y **reemplazan a Claude como driver**. OmniParser `icon_detect` es **AGPL-3.0** (mina si distribuís comercial).
- **trycua sandbox local** pide Hyper-V → **no corre en Win 11 Home** (runtime Linux o cloud pago). El *driver* sí es nativo.
- **`godot --headless` apaga TODO render** → jamás captura un frame. Para frames usar **Movie Maker** (`--write-movie out.png --fixed-fps 30 --quit-after N`).
- **EEVEE no renderiza truly-headless** (background-con-escritorio ≠ headless) → forzar `-E CYCLES` / WORKBENCH en runners display-less.
- **`3ddelano/gdai-mcp`** pago + cerrado ($19). **`self-operating-computer` / `open-interpreter --os`** stale/rotos en Win11. **`terminator`** (UIA) ciego en editor Godot.

## ⚠️ Corrección a creencia previa (engram `tooling/computer-use-godot-testing`)

**"Godot expone 0 UIA elements" YA NO es hecho duro del engine** — es **config-gated**. Godot 4.5 sumó accesibilidad vía **AccessKit** (heredado en 4.6.2). El "0 UIA" es consistente con el modo default `auto` (solo construye el árbol si detecta lector de pantalla). Experimento falsable barato: relanzar con `--accessibility always` + sondear con `Inspect.exe`. Los menús de Control-nodes (character-select, inventory) podrían volverse driveables sin pixels. El mundo 3D y el HUD `_draw` NUNCA entran.

## Próximo paso — la decisión abierta

**RECOMENDADO: "kit de verificación render→compare→fix" como skill reusable.** Todo free + Windows-native:
- Captura: **Godot Movie Maker** (`--write-movie`) reemplaza el SubViewport hand-keyed por secuencia PNG frame-perfecta (mantener ventana parkeada en -4000).
- Ensamblado: `ffmpeg tile` / ImageMagick `montage` → contact-sheet, un solo Read.
- Compare: **odiff** vs golden → score numérico = gate PASS/FAIL.
- Escalar: solo en FAIL, invocar `art-ref-critic` + ojo de Joan.

*Por qué:* ataca el gap medido más grande (cero diff automático, review manual frame-a-frame), formaliza lo que YA existe, y le pone la métrica objetiva que BlenderGym dice que es load-bearing.

**Alternativa A — FastMCP que envuelve primitivas Godot** (`validate_project()`, `capture_scene()`, `run_gut()` como tools tipadas). Mejora actuación, no percepción; suma un server a mantener.

**Alternativa B — GdUnit4 `scene_runner` sobre `floor1_prairie`** (boot escena jugable, simula input, assert HP/señales). Valida lógica, no visuales; segundo framework al lado de GUT.

**FORK ABIERTO:** ¿el próximo paso apunta a la **PERCEPCIÓN del arte/assets** (gate render→odiff→critic, recomendado) o a **DRIVEAR el juego jugable** estructuradamente (FastMCP / GdUnit4)?
