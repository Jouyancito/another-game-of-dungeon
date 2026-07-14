# GATE_PROTOCOL.md — Gate visual ejecutable (oso Filomeno + mobs Dungeon Party)

> **Qué es esto.** El procedimiento paso a paso que Claude sigue en CADA pasada de asset (corpóreo Lawen o mob del juego) antes de mostrar nada al humano. No es una filosofía: es una lista de comandos y gates con condición de corte numérica.
>
> **Por qué existe.** Modos de falla reales medidos (sesiones 2026-06-19, 2026-07-03): veredictos PASS sobre renders que el usuario refutó orbitando en 5 segundos; oscilación de proporciones sin números; sesgo del constructor auto-aprobándose; derrame de pintura invisible al ojo pero visible en Z. Ninguno de los 9 instrumentos inventariados fue invocado en una sola iteración de Filomeno. Este doc conecta el veredicto a los instrumentos y lo hace obligatorio.
>
> **Diseñado alrededor del observador real.** Claude-VLM es **DÉBIL** en juicio absoluto, gestalt y proporciones de memoria; es **FUERTE** en diffs lado-a-lado y en mediciones numéricas. Todo acá empuja el juicio hacia diffs y números, y saca a Claude del rol de juez absoluto.

**Regla madre (una sola frase):** Claude NUNCA emite un veredicto de un render solo, de memoria, ni sin el 2D en la misma imagen y un número al lado. Si no hay número, no hay veredicto.

---

## 0. Instrumentos (qué invoca cada paso)

| Instrumento | Ubicación | Rol en este protocolo |
|---|---|---|
| `compare_render.py` | `game/tools/imgdiff/` | Mediciones render↔2D: IoU de silueta, SSIM, ΔE por zona, **crop facial**. Fuente de los números del veredicto. |
| `visual_gate.mjs` + `odiff` | `game/tools/visual_gate/` | Regresión pixel-diff render↔golden bendecido. Detecta que un cambio rompió algo ya aprobado. |
| `art-ref-critic` (skill) | Skill tool | Crítico independiente. Lo corre un contexto distinto al que editó — rompe el sesgo del constructor. |
| Contact sheet (PIL) | genera este protocolo | Yuxtaposición 2D+render con números superpuestos. El único formato en que Claude juzga. |
| Contrato del personaje | `_refs/<X>/_contract.md` | Números objetivo del 2D. La condición de corte de la oscilación. |

> `silhouette_separation.py` está **ROTO y deprecado** (ARM_Z hardcodeado, falsos negativos; mide readiness A-pose Mixamo, no fidelidad de cara). No lo invoques. `image_comparison_rigor.md` §1 ordena reemplazarlo — este doc es ese reemplazo operativo.

---

## 1. Setup por personaje (UNA vez por asset)

Objetivo: convertir el 2D de referencia en **números** contra los cuales medir. Sin esto, la oscilación (cejas lejos→cerca→lejos) no tiene condición de corte.

### 1.1 SAVE+USE de la referencia (obligatorio, convención CLAUDE.md)
- La imagen 2D vive en el repo: `_refs/<X>/` (Filomeno: `corporeo-3d/_refs/filomeno_nude_apose.png` + `filomeno_apose.png` + `filomeno_turnaround.png` + `LOOK_LOCKED_face.png`). Engram guarda solo texto — la imagen DEBE estar en el repo.
- **CARGAR la ref ANTES de construir/medir.** Nunca desde el recuerdo de una descripción.

### 1.2 Medir el 2D → contrato de proporciones
Definí landmarks sobre el 2D una vez y calculá **ratios adimensionales** (invariantes a escala/encuadre). Para una cara:

```
brow_gap        = distancia_cejas / ancho_cabeza
eye_spacing     = distancia_inter_ojos / ancho_cabeza
eye_to_brow     = alto_ojo_a_ceja / alto_cabeza
snout_len       = largo_hocico / alto_cabeza
mouth_y         = altura_boca_desde_menton / alto_cabeza    # el bug "boca bajo el hocico" es un mouth_y fuera de rango
head_body       = alto_cabeza / alto_total
```

Guardá esto como **contrato** en `_refs/<X>/_contract.md`:

```md
# Contrato de proporciones — <X> (fuente: filomeno_nude_apose.png)
| Ratio        | Target 2D | Tolerancia ±  | Cómo se mide |
|--------------|-----------|---------------|--------------|
| brow_gap     | 0.34      | 0.03          | crop facial, landmarks cejas/ancho cráneo |
| eye_spacing  | 0.41      | 0.03          | ...          |
| mouth_y      | 0.22      | 0.02          | ...          |
| ...          |           |               |              |
```

> Los valores de ejemplo son placeholders — **medilos del 2D real** en el paso 1.2, no los inventes. El punto es que exista un número objetivo y una tolerancia ANTES de tocar el mesh.

### 1.3 Contrato de paleta (por zona, no global)
Extraé la paleta del 2D por zona (`extract_palette.py` ya existe en `_refs/`). Registrá el color objetivo por región (pelaje, hocico, ojos, garras) como Lab, para medir ΔE CIEDE2000 por zona en el paso 2. Un derrame de pintura que atraviesa el cráneo se ccaza acá: la zona "cráneo" se sale de su ΔE objetivo aunque el ojo no lo note.

### 1.4 Baseline de instrumento (calibración)
Corré `compare_render.py --target filomeno_nude_apose.png --render <render_pose_correcta>` una vez para confirmar que self-compare ≈ 1.0 y que cross-pose baja (demo real: IoU 0.43 / SSIM 0.24). Esto te dice qué números son "buenos" para ESTE personaje antes de creer en ningún veredicto.

**Salida del setup:** `_contract.md` commiteado + paleta por zona + puntero engram `reference/<X>`. Sin `_contract.md`, el loop del paso 2 NO arranca.

---

## 2. Loop por cambio (CADA edición del mesh/textura)

El orden es obligatorio y cada flecha es un gate: no avanzás si el anterior no pasó.

```
PROBE geométrico  →  CAMBIO  →  CAPTURA estándar  →  CONTACT SHEET (con 2D)
     →  MEDICIONES vs contrato  →  VEREDICTO per-ítem citando números  →  (recién ahí) HUMANO
```

### 2.1 PROBE geométrico ANTES de pintar/construir
Antes de texturizar o refinar, preguntá al mesh, no al render: **¿la feature está modelada?** Consultá vértices/bones/bounding con `mcp__blender__execute_blender_code` o `get_object_info`. 5 iteraciones de ojos por esferas apiladas fallaron distinto cada vez porque nadie preguntó primero "¿hay geometría de ojo o estoy pintando sobre un cráneo liso?". Si la feature no existe en geometría, **no la pintes** — modelala o cambiá de método (ver 2-STRIKE).

### 2.2 Captura estándar (encuadres FIJOS, no "un render lindo")
El modo de falla nº1 fue juzgar sobre baja-res / encuadre ancho que el usuario refutó orbitando. Contramedida: batería fija, alta-res, encuadre apretado.

Ángulos mínimos por pasada (headless, ver `blender-asset-smith`):
1. **front** (alineado al 2D — el que va al contact sheet)
2. **worm** (worm's eye, desde abajo — caza "boca bajo el hocico", "negro derramado al cráneo")
3. **close-up cara** (crop apretado a la región del contrato)
4. **3/4 izq** y **3/4 der**
5. **orbit** de 8–12 pasos (el low NO se pierde — v10–v15 regresaron a 2 ángulos y ahí volvió a fallar)

Resolución mínima: la cara ocupa ≥512px de lado en el close-up. Un veredicto sobre <512px de cara es inválido.

### 2.3 Contact sheet CON el 2D (el único formato que Claude juzga)
Componé (PIL) una lámina: **2D de referencia a la izquierda, render al lado**, misma altura, por cada ángulo relevante. Encima, **números superpuestos** (los ratios medidos del paso 2.4). Los FACE_compare boards v2/v3 existían y funcionaban — desaparecieron en orbit_v8 y ahí volvió el desastre. **El contact sheet es obligatorio en cada pasada, no opcional.** Sin 2D en la misma imagen, Claude cae en juicio absoluto (su modo débil).

### 2.4 Mediciones numéricas vs contrato (el desbloqueo)
Corré el instrumento **con crop facial**, no full-body:

```bash
python game/tools/imgdiff/compare_render.py \
  --target _refs/filomeno/filomeno_nude_apose.png \
  --render out/orbit_front.png \
  --crop face \
  --contract _refs/filomeno/_contract.md \
  --json out/metrics_front.json
```

> **Gap crítico B del inventario:** `compare_render.py` es full-body; un cuerpo 95% correcto + cara 5% rota da PASS global. **Siempre `--crop face`** (o la región del defecto) además del full-body. El JSON reporta cada ratio del contrato con su delta vs target y su estado (dentro/fuera de tolerancia), + ΔE por zona (caza el derrame) + IoU/SSIM de silueta.

### 2.5 Veredicto per-ítem citando números
No hay "PASS 3/5" global. Hay una fila por ítem del contrato, cada una PASS/FAIL **citando el número**:

```
brow_gap     medido 0.31  target 0.34 ±0.03  → PASS (dentro)
mouth_y      medido 0.15  target 0.22 ±0.02  → FAIL (-0.07, boca demasiado abajo)  ← el bug real
eye_spacing  medido 0.44  target 0.41 ±0.03  → PASS
ΔE cráneo    medido 18.2  target <6          → FAIL (derrame de pintura al cráneo)  ← invisible al ojo, visible acá
IoU silueta  medido 0.89  baseline 0.9+      → PASS
```

**Gate:** el asset avanza al humano SOLO si todos los ítems son PASS. Un solo FAIL → volvés al paso 2.1 (probe) para ESE ítem. El veredicto sin números citados es inválido y se descarta.

### 2.6 Regresión (no romper lo aprobado)
Cuando un ítem pasa a golden, bendecilo en `visual_gate.mjs`. En pasadas siguientes, `odiff` render↔golden avisa si un cambio en la nariz rompió la oreja ya aprobada. Esto ataca la oscilación: no podés "arreglar cejas" y romper ojos sin que el diff lo grite.

---

## 3. Reglas duras (no negociables)

1. **2-STRIKE — cambiar de método, no repetir.** Si el MISMO approach falla 2 veces (aunque falle distinto cada vez), está PROHIBIDO el tercer intento igual. Cambiás de método (esferas apiladas → textura; geometría → shape key) o escalás al humano. Las 5 iteraciones de ojos por esferas son el anti-patrón que esta regla mata. Registrá strike 1 y strike 2 explícitamente en el log de la pasada.
2. **Nunca juicio absoluto sin el ref en la misma imagen.** Prohibido "se ve bien" sobre un render solo. El 2D va en el contact sheet, siempre. Es el modo FUERTE del observador (diff) sustituyendo al DÉBIL (absoluto).
3. **Números o nada.** Ningún veredicto sin al menos un ratio medido citado. "Parece correcto" no es un estado válido del gate.
4. **Crítico independiente antes de "listo".** Antes de presentar como terminado, corré `art-ref-critic` en contexto separado del que editó. El constructor NO se auto-aprueba (2026-06-19: agente se puso 7/10, tres críticos independientes vieron el desastre). Si el crítico difiere del constructor por ≥2 puntos, gana el crítico y el asset vuelve al loop.
5. **Encuadres y resolución mínimos.** Cara ≥512px en close-up; worm's eye siempre presente; orbit conserva el ángulo bajo. Un veredicto que no cubrió worm+close es inválido.
6. **El humano es gate FINAL, entra UNA vez.** Joan no es el debugger de la iteración 8; entra cuando TODOS los ítems son PASS y el crítico independiente concuerda. Si el asset llega a Joan con FAILs conocidos, el gate falló, no Joan.

---

## 4. Escalado a mobs del juego (Dungeon Party, Godot, low-poly toon)

El protocolo es el mismo esqueleto; cambian las fuentes.

- **Ref (paso 1.1):** en vez de un 2D ilustrado, la **ficha del bestiario** (`game/docs/art/_bestiary_visual_bible.md`) + las refs de Joan en `game/docs/art/_references/<mob>/`. SAVE+USE idéntico.
- **Contrato (paso 1.2):** sale de la ficha — silueta legible a 32px (test de miniatura), proporciones canon del mob (ej. golem ~5m, arm-drag), paleta toon del `_art_canon.md`. Los ratios se miden sobre las refs de Joan igual que sobre el 2D del oso.
- **Captura (paso 2.2):** render headless del `.glb` + captura in-engine vía Godot `SubViewport` (el `anim_capture` ya produce 1237+ frames — de ahí salen los ángulos). Worm's eye importa doble en mobs: el jugador los ve desde abajo en primera persona.
- **Mediciones (paso 2.4):** `compare_render.py --crop` sobre la silueta (legibilidad toon) + ΔE contra paleta canon. Para animación, `visual_gate.mjs` sobre frames golden bendecidos.
- **Integración pre-push:** el gate se cablea al **pre-push visual** existente (`game/tools/imgdiff` + `game/tools/godot`). Ningún `.glb`/anim de mob se pushea sin: contact sheet vs ficha + metrics JSON PASS + golden de regresión. Esto es lo que hace el gate "mayormente automático": el `.glb` que no pasa no llega ni a Joan ni a `master`.
- **Meta cumplida:** el ojo de Joan entra una vez al final por asset, no 3 días por mob.

---

## 5. Qué NO automatizar (la lista honesta)

Los instrumentos miden **fidelidad y consistencia**, no **calidad final**. Estas cosas son de Joan, por diseño, y ningún número las reemplaza:

- **Gestalt final** — "¿se siente un oso vivo o un muñeco?". Claude no tiene alarma de gestalt; es su debilidad estructural. No la finjas con métricas.
- **Feel / peso / carisma** — que el golem se sienta pesado, que Filomeno tenga ternura de marca Lawen.
- **Identidad y estilo propio** — que el asset sea "de este mundo" y no un collage de refs. Coherencia con `_world_coherence.md` es criterio humano.
- **La decisión de "esto es publicable"** — el veredicto artístico final.

El gate NO decide si el asset es bueno. El gate garantiza que **cuando Joan lo mire, todos los defectos medibles ya están resueltos** y su ojo se gasta solo en lo que solo un humano puede juzgar. Ese es el trato: automatizar lo medible para proteger lo humano.

---

## Checklist de 10 líneas (copiar en cada sesión de asset)

```
[ ] 1. Ref 2D/ficha cargada del repo (SAVE+USE), NO de memoria.
[ ] 2. _contract.md existe con ratios objetivo + tolerancias medidos del 2D.
[ ] 3. PROBE geométrico hecho: la feature está MODELADA antes de pintar.
[ ] 4. Captura estándar: front+worm+close(≥512px)+3/4+orbit. Ningún ángulo perdido.
[ ] 5. Contact sheet armado CON el 2D al lado y números superpuestos.
[ ] 6. compare_render.py corrido --crop face + JSON de métricas por ítem.
[ ] 7. Veredicto per-ítem PASS/FAIL citando el número. Cero juicio absoluto.
[ ] 8. 2-STRIKE respetado: mismo método falló 2x → cambié de método o escalé.
[ ] 9. art-ref-critic (contexto independiente) concuerda antes de decir "listo".
[ ] 10. TODOS los ítems PASS → recién ahí, humano UNA vez. Si hay FAIL, no sale.
```
