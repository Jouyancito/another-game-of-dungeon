# `char_` — Brief de construcción de personajes

**Base name: `char_`.** Todo artefacto sobre los personajes jugables lleva ese prefijo
(archivos, carpetas, docs, títulos y `topic_key` de engram).

Escrito 2026-08-08 al cierre de la sesión de diseño, para que la **próxima sesión pueda
generar sin volver a decidir nada**. Todo lo que sigue está resuelto salvo lo marcado
como BLOQUEANTE en §6.

---

## 0. Qué se construye — decisiones cerradas

**Seis personajes completos**: guerrero, guerrera, mago, maga, explorador, exploradora.

| Decisión | Valor | Origen |
|---|---|---|
| Cuerpos | **6 propios**, esculpidos con su contextura | Joan 2026-08-08, tras ver el blockout |
| Equipo | **6 sets únicos**, exclusivos por clase Y por sexo (modelo Metin2) | Joan 2026-08-08 |
| Esqueleto | **UNO solo, compartido por los seis** — mismos nombres de hueso y jerarquía; largos distintos | restricción técnica, §4 |
| Altura | **1.80 m, fija en los seis** | colisionador del juego, §5 |
| Razas | **fuera** (sin enanos ni elfos) | no existe canon de razas; multiplicaría el trabajo |
| Estilo | 3D texturizado, registro Path of Exile | `[[village_poe_style]]`, `[[poe_visual_bar]]` |
| Orden | guerrero M → exploradora F → maga F → el resto | los tres primeros son los que pide `[[titlescreen]]` |

**Qué se descartó y por qué** (para que nadie lo reviva sin motivo):
- *Cuerpo base compartido + kits cross-clase + shape keys de masa.* Se midió: con cuerpo
  compartido el hombro daba guerrero 0.598 / arquero 0.482 / mago 0.425 — **arquero y mago
  quedaban a 6 cm**, indistinguibles a distancia de juego. El blockout mostró el problema
  que la tabla de números escondía.
- *Enanos y elfos.* `_world_canon.md` no define razas; sería lore nuevo, y el scope reset
  del 2026-05-18 tiene "canon expansion" en la lista de STOP.

---

## 1. Lo que hay hoy — verificado contra el repo, no asumido

- **Solo existen personajes masculinos.** `char_warrior_base.gltf`, `char_mage_base.gltf`,
  `char_archer_base.gltf` en `game/assets/art/piso1_pradera/characters/` salen de Quaternius
  **"Ultimate Modular Men"**. Los de `shared/characters/kaykit/` (Barbarian, Knight, Mage,
  Rogue, Rogue_Hooded) también. **No existe base femenina en ningún pack del repo.**
- El boceto del titlescreen pide **exploradora** y **maga** — dos de sus tres personajes son
  mujeres. La pantalla de inicio **no se puede construir fiel al boceto con los assets
  actuales**. Este es el bloqueo real que fuerza el trabajo, no una preferencia.
- Ya existe `game/tools/blender/gen_proportion_blockout.py` — genera y mide siluetas
  paramétricas. Sirve para validar proporciones nuevas antes de esculpir.
- Librería de animación disponible sin usar:
  `game/assets/art/_raw/quaternius/quaternius_universal-animation-library/`.

---

## 2. Path of Exile aplicado a PERSONAJES

Destilado de `[[poe_visual_bar]]` y `[[village_poe_style]]`. El antecedente que obliga a
hacer esto antes de modelar: **el `tree_pack` se descartó entero por hacer "estilo PoE" sin
analizar por qué PoE se ve así.**

### 2.1 La regla madre

> **Silueta = geometría. Superficie = textura.**

Si el detalle cambia el contorno (un borde de placa roto, una correa que cuelga, un dobladillo
desgarrado) → **se modela**. Si solo cambia cómo la luz juega sobre una superficie (grabado,
veta, grano de cuero, poros, pelo) → **va a mapa normal**. Joan llegó a esta regla solo, desde
la imagen de la quimera, y está canonizada en `poe_visual_bar` §8.

Corolario para personajes: **nadie modela pelo por pelo**. Pelo y piel viven del lado de la
textura (+ cards cuando el primer plano lo exige).

### 2.2 Materiales — el error que hay que no cometer

`village_poe_style` diagnostica la causa raíz de por qué el proyecto se veía a "color sólido"
durante once pasadas: **ruido procedural no es textura**. El ruido da moteado; nunca da cuero,
metal ni tela, porque esos materiales tienen ESTRUCTURA direccional que el ruido genérico no
reproduce.

Stack obligatorio por material: **albedo + normal + roughness** (+ displacement solo donde el
normal no alcance). Fuente CC0 ya validada en el proyecto: **Poly Haven**
(`https://api.polyhaven.com/assets?type=textures`, sin key).

Lo que separa un material de otro en PoE es sobre todo el **roughness**: cuero mate contra
metal especular contra tela suave. Si los tres comparten roughness, se leen como plástico
pintado por más albedo distinto que tengan.

### 2.3 Tela

`poe_visual_bar` es explícito: la capa del personaje encapotado **lee como tela de verdad** —
pliegues que atrapan luz y sombra por su cuenta. Un plano rígido con color no puede producir
eso. Para capas, túnicas y dobladillos: pliegues **horneados en la geometría** + normal map de
pliegue fino. Es especialmente crítico en el **mago/maga**, cuya silueta ES la túnica.

### 2.4 Anatomía

`poe_visual_bar` deja constancia de que **los rigs de personaje de PoE pasan todos los ítems de
la Naturalness Audit** de `art-ref-critic` — brazos con codo correcto, masa conectada, sin
geometría flotante. El listón para los personajes de DP es ese mismo, no uno más bajo por ser
low-poly.

### 2.5 Paleta y luz

- **Todo desaturado salvo el fuego y UN acento controlado.** Cero verdes brillantes, cero
  amarillos alegres — eso es lo que significa "menos animado, más PoE".
- Contraste de luz agresivo: **charcos de luz cálida muy acotados contra ambiente frío y
  oscuro**. No "todo bien iluminado".
- Consecuencia para los personajes: se van a ver casi siempre **a contraluz o en penumbra**.
  Por eso la silueta manda y por eso el mago necesita sus runas emisivas — en una mazmorra
  oscura serían lo único que emite luz propia.

### 2.6 La advertencia de cámara

`poe_visual_bar` la deja escrita: PoE es isométrico y **DP es primera persona**. La cámara de DP
tiene **menos lugar donde esconder un material plano** que la de PoE. El listón de detalle sube,
no baja, respecto de la referencia.

### 2.7 Anti-clon

Joan reventó la empalizada v14 por esto: *"son palos idénticos... misma textura, mismo orden,
misma coordenada"*. Aplicado a personajes: remaches, correas, hebillas, escamas y placas
**no pueden compartir fase**. Cada elemento repetido varía en ángulo, largo, grosor y desgaste.

---

## 3. Reglas de forma por clase

### 3.1 Guerrero — canon ya cerrado, NO reabrir

`[[warrior_archetype]]` ya destiló 14 imágenes de 6 franquicias. Vigente y suficiente:

1. **La silueta se lee antes que el detalle** — UNA decisión de forma legible a 20 m.
2. **Ancho y robusto por sobre alto** — hombros cuadrados, centro de gravedad bajo.
3. **UN prop de identidad** propio, no un loadout genérico.
4. **Materiales en capas visiblemente construidos** — correas, hebillas y costuras a la vista.
   Funcional lee "guerrero" mejor que prolijo.
5. **El desgaste comunica rol**, no edad.
6. **Base terrosa + UN acento** metálico controlado.

Registro elegido: **veterano curtido / primitivo tribal** (nunca limpio-heroico).
Paleta fijada: azul andino `#2E4560` · plata oxidada `#B8B8B0` · rojo tierra `#6B2A20`.
El **trarilonko** mapuche es el ÚNICO marcador ornamentado, contra una base plana y gastada.

### 3.2 Arquero y mago — reglas de silueta (derivadas, sin refs propias todavía)

| | Silueta | Dirección de línea | Material dominante | Acento |
|---|---|---|---|---|
| **Guerrero** | trapecio, pesa arriba | horizontal, en bloque | metal sobre cuero | metal oxidado |
| **Explorador** | vertical y angosto, **asimétrico** | diagonal | cuero y tela, mate | ninguno brillante |
| **Mago** | triángulo invertido, pesa abajo | vertical larga | tela con pliegues | **runas emisivas** |

- La **asimetría del explorador** (arco y carcaj cruzando el contorno en diagonal) es lo que
  más lo separa del mago. Sin eso, ambos son "flaco alto".
- La **cabeza alargada** del mago (capucha o sombrero) es lo que lo delata de lejos.
- Las **runas** son el identificador más barato que existe: no cambian la malla, no cuestan
  polígonos, son una capa emisiva. Y dan gancho de gameplay servido — encendidas al canalizar,
  apagadas sin maná.

---

## 4. Pipeline — qué skill, qué motor, qué vistas

### 4.1 Ruteo de skills (importante: NO es una sola)

| Trabajo | Skill | Motivo |
|---|---|---|
| **Cuerpos orgánicos** (los seis) | **`corporeo-3d`** | `blender-asset-smith` es hard-surface ONLY y su propio router manda los orgánicos acá |
| **Equipo duro** (placas, hebillas, armas, carcaj) | `blender-asset-smith` | hard-surface, kit-bash, su especialidad |
| **Juicio visual** | `art-ref-critic` | Naturalness Audit — obligatoria antes de cualquier veredicto |
| **Base de conocimiento** | `game/docs/art/_modeling_knowledge_base.md` | cargar ANTES de escribir cualquier generador |

### 4.2 Motor y ejecución

```
Blender: C:\Users\the_j\blender\blender-5.1.2-windows-x64\blender.exe
Invocación: --background --factory-startup --python-exit-code 1 --python <script>
```

Gotchas ya pagados, no re-descubrir:
- **Z-up siempre** para lo que se para. `export_yup=True` mapea Blender-Z → glTF-Y.
- **`bm.loops.layers.float_color`**, jamás `BYTE_COLOR` (round-trip sRGB rompe los tonos).
- **`shape_key_add()` por defecto `value=1.0, from_mix=True`** → contaminación silenciosa entre
  claves. Envolver siempre en helper con `from_mix=False` + `value=0.0`.
- **`BMVert.index` está obsoleto justo después de `bm.verts.new()`** → indexar diccionarios por
  el objeto `BMVert`, nunca por `.index`.
- **Materiales de nodos NO sobreviven el glTF.** Todo sombreado procedural debe resolverse a
  vertex color FLOAT_COLOR en tiempo de build, o exporta blanco. Verificar con
  `game/tools/blender/_glb_truth_render.py` — **el render del script de build no es evidencia**.
- `Material.use_nodes` / `World.use_nodes` tiran DeprecationWarning en 5.1.2 (se van en 6.0).

### 4.3 Rigging

**UniRig**, local y gratis en la GTX 1080 (WSL, env conda `UniRig`). Pipeline de 4 etapas
documentado en la skill `blender-asset-smith` §UniRig. Dos cosas que se olvidan:
- **Cerrar Ollama antes de riggear** — se come ~4.7 GB de VRAM.
- `export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"` es obligatorio.

**El esqueleto de los seis se define UNA vez y se reusa.** Riggear cada cuerpo por separado con
UniRig produciría seis jerarquías distintas y habría que animar seis veces. Definir el esqueleto
canónico primero, ajustar largos de hueso por cuerpo, mantener nombres.

### 4.4 Vistas obligatorias para juzgar

Ninguna se puede omitir. Un solo render general **no es presentación válida**.

| Vista | Para qué | Nota |
|---|---|---|
| **Silueta** (negro sobre claro) | el examen real de legibilidad | si no se lee en negro, no se lee |
| **Frontal ortográfica** | medir proporción sin distorsión | con la vara de 1.80 m y tick por cabeza |
| **3/4 a altura de ojo** | el ángulo honesto | el 3/4 con luz plana no perdona |
| **Ojo de jugador** (cam 1.65 m, ~6 m, lente 24) | como se ve en juego | reveló el bug de escala del `tree_pack` |
| **Close-up macro** | detecta el fallo de "calcomanía plana" | la vista general lo esconde |

**La vara de referencia de 1.80 m va en TODO showcase.** Es regla del motor, ganada con el
`tree_pack` miniatura que pasó cuatro revisiones porque ningún render tenía referencia de altura.

### 4.5 Veredicto

**Sin número no hay veredicto.** `tools/visual_gate/` + `tools/imgdiff/` + la Naturalness Audit
de `art-ref-critic`. Mirar un render no es evidencia. Y el juicio final de cómo se mueve y se
siente es de Joan viéndolo correr, no mío mirando frames.

---

## 5. Números fijos

```
Altura total ................ 1.80 m   (los seis, sin excepción)
Canon .......................  7.5 cabezas → cabeza = 0.24 m
Colisionador del juego ...... CapsuleShape3D height=1.8, radius=0.35
                              base_player.gd:11  stand_height := 1.8
```

Landmarks verticales (m desde el suelo), compartidos para que el ojo compare igual contra igual:

```
pie 0.07 · rodilla 0.50 · entrepierna 0.90 · cintura 1.10
pecho 1.32 · hombro 1.47 · mentón 1.56 · tope 1.80
```

Anchos de hombro del blockout, como **punto de partida a superar** — con cuerpos propios el
spread debe abrirse más que esto, que es justo lo que Joan rechazó:

```
guerrero 0.598 · explorador 0.482 · mago 0.425     (spread 41%)
```

**La altura nunca cambia.** Toda la contextura vive en ancho y volumen.

---

## 6. Huecos de referencia — BLOQUEANTES antes de esculpir

La convención del proyecto es tajante: **cargar las referencias del asset ANTES de construir**,
y construir desde ellas, no desde el recuerdo de una descripción. Auditado el repo, faltan tres
cosas, y las tres las tiene que aportar Joan:

1. **No existe ninguna referencia de PERSONAJES de Path of Exile.** `poe_visual_bar` es
   mayormente entorno (playa, muelle, templo, plaza, muralla) con un solo encapotado de fondo;
   `village_poe_style` es aldea. **Cero screenshots de personajes jugables de PoE.** Modelar
   "personaje estilo PoE" con referencias de arquitectura es exactamente el error del
   `tree_pack`. → **Pedir a Joan screenshots de personajes de PoE**, de fuentes distintas
   (su propia exigencia en `warrior_archetype`: nunca una sola fuente, da sesgo rígido).

2. **No existe `_references/mage_archetype/` ni `_references/archer_archetype/`.** El guerrero
   tiene 14 imágenes de 6 franquicias destiladas; el mago y el explorador **no tienen nada**.
   Sus reglas de silueta en §3.2 están derivadas por deducción, no por referencia. → Repetir
   para mago y explorador el método que ya funcionó con el guerrero.

3. **No hay ninguna referencia femenina.** Ni de cuerpo ni de equipo, para ninguna clase. Y la
   decisión Metin2 dice que el set femenino **se modela aparte, no es el masculino achicado** —
   así que hace falta material propio. → Pedir referencias de las tres clases en femenino.

Sin (1) el estilo es una apuesta. Sin (2) y (3), dos tercios del roster se diseñan a ciegas.
El armado estructural puede arrancar igual; el **feel** no.

---

## 7. Checklist de la próxima sesión

```
[ ] Cargar refs: poe_visual_bar · village_poe_style · warrior_archetype
    · organic_modeling_style · sculpt_2d_to_3d           (regla SAVE+USE)
[ ] Cargar game/docs/art/_modeling_knowledge_base.md      (antes de codear)
[ ] Invocar corporeo-3d para el cuerpo (NO blender-asset-smith)
[ ] Pedir a Joan los 3 huecos de referencia de §6
[ ] Definir el ESQUELETO canónico compartido — antes de esculpir el segundo cuerpo
[ ] Esculpir char_warrior_male, 1.80 m, Z-up
[ ] Renderizar las 5 vistas de §4.4, con vara de 1.80 m
[ ] Naturalness Audit + visual_gate → número, después veredicto
[ ] _glb_truth_render.py antes de dar por bueno cualquier color
[ ] Joan mira y corrige
```

---

## Enlaces

`[[titlescreen]]` — la pantalla que fuerza este trabajo · `[[warrior_archetype]]` — canon del
guerrero · `[[poe_visual_bar]]` — la barra de calidad · `[[village_poe_style]]` — por qué el
ruido procedural no alcanza · `[[vine]]`, `[[logo]]`, `[[gate]]` — el otro frente de la misma
pantalla.

Engram: `art/personajes-cuerpos-base` · `art/personajes-equipo-metin2` ·
`art/personajes-proporciones` · `art/organicos-bespoke-revisit` · `asset/titlescreen`.
