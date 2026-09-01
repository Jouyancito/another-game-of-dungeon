# Síntesis de investigación — cómo se hacen los assets en 2026

Fecha: 2026-08-19. Complementa `_asset_creation_contract.md` (el canon) y
`_modeling_knowledge_base.md` (las técnicas concretas).

Nace de un pedido de Joan:

> *"lo único que teníamos como correcto era la anatomía, por el tema de que habías descargado un
> pack que te ayudaba a entender cómo es el cuerpo humano. Hay que intentar hacer lo mismo, pero
> con la piel, el pelo, todo, para que tú entiendas cómo se hace un personaje."*

Y una corrección suya que cambió el enfoque de toda la búsqueda:

> *"me dices que no alcanza con mi hardware; hay quizás detalles que puedan aplicarse, que no sea
> como el modelo completo."*

Tenía razón. **El valor de MPFB2 nunca fue correr MakeHuman: fue usar su conocimiento embebido.**
Un modelo que no corre en una GTX 1080 igual publica su metodología, y la metodología es gratis.
Todo lo de abajo se extrajo con ese criterio.

---

## 0. La síntesis, antes del detalle

Se revisaron siete fuentes. **Todas comparten dos rasgos**, y ahí está la lección:

### (a) Separan PARÁMETRO de INSTANCIA

Ninguna modela "un árbol". Modelan **el espacio de todos los árboles** y después sacan uno.

| Fuente | Parámetro (la especie) | Instancia (el individuo) |
|---|---|---|
| MPFB2 | 1258 morph targets por músculo y medida | un cuerpo con esos dials en cierto valor |
| PERM | θ = corte, β = rizo | un peinado concreto |
| Infinigen | `AssetFactory(factory_seed)` | `spawn_asset(i)` |
| FaceSynthetics | modelo facial paramétrico | una cara vestida con assets muestreados |

Es el mismo patrón cuatro veces, descubierto por gente que no trabajaba junta.

**Lo que hicimos mal:** el pelo del guerrero se modeló como *un* peinado. Por eso al cambiar el
cráneo se rompió — no había parámetro que reajustar, había geometría fija.

### (b) DERIVAN sus números en vez de elegirlos

Esta es la más importante, y es exactamente el error que se repitió toda la sesión anterior:
cinco parámetros elegidos a ojo, los cinco demasiado altos.

- Infinigen no elige el tamaño de cara: lo **calcula desde el tamaño de un píxel** a esa distancia.
- Hunyuan3D no juzga la malla a ojo: la mide con **tres métricas** y descarta.
- Texturing.xyz no pinta "detalle": separa el detalle en **frecuencias** y pesa cada una.

> Si un número del pipeline no se puede derivar de algo físico o medir después,
> es una opinión disfrazada.

---

## 1. Infinigen — Princeton, BSD-3 (uso comercial libre)

`github.com/princeton-vl/infinigen`. **Procedural puro, no ML.** Genera con código Blender.

### El catálogo, y cuánto pega con el piso 1

Cubre casi todo el dominio de vegetación: `trees`, **`deformed_trees`**, `BushFactory`,
`MushroomFactory`, `GrassTuftFactory`, `FlowerFactory`, `FernFactory`, `MossFactory`,
`LichenFactory`, `PineNeedleFactory`, hojas por especie (broadleaf, maple, pine, ginko),
`BoulderFactory`, `BlenderRockFactory`, `GlowingRocksFactory`. Más criaturas, frutas, corales,
moluscos, nubes y clima.

### Lo mejor que encontré en toda la búsqueda: `target_face_size()`

En `src/infinigen/core/placement/detail.py`. **No eligen presupuesto de polígonos.** Toman la
distancia focal, el sensor, la resolución de render y la distancia al objeto, y calculan cuántos
metros mide **un píxel** ahí. Ese es el tamaño de cara objetivo:

```python
f_m         = 0.001 * camd.lens
sensor_dims = 0.001 * np.array([camd.sensor_width, camd.sensor_height])
pixel_shape = (resolution_percentage / 100) * np.array([resolution_x, resolution_y])
pixel_dims  = (sensor_dims / pixel_shape) * (dist / f_m)
res         = min(pixel_dims)
return np.clip(global_multiplier * res, global_clip_min, global_clip_max)
```

El criterio en una línea: **una cara nunca debe ser más chica que un píxel.** Todo lo que esté por
debajo es polígono que el jugador no puede ver y la GPU paga igual.

**Aplicable a Dungeon Party hoy**, y de forma directa: el juego es first-person, el FOV está
fijado, la resolución está fijada, y sabemos a qué distancia mínima pasa el jugador junto a un
árbol. De ahí sale el presupuesto **derivado**, no inventado. Reemplaza a los números al ojo del
contrato §3.

### El node transpiler — y lo que habilita para Joan

Se diseña con geometry nodes en la UI de Blender, se aprieta un botón, y sale **código Python
reproducible** que reconstruye el nodegraph. Menos de un segundo.

Esto tiene una consecuencia concreta: **Joan puede diseñar visualmente y entregar código.** No
tiene que escribir Python para aportar un generador; el transpiler traduce.

### El patrón AssetFactory (transferible tal cual)

```python
class MyAssetFactory(AssetFactory):
    def __init__(self, factory_seed):
        super().__init__(factory_seed)
        with FixedSeed(factory_seed):
            self.my_randomizable_parameter = np.random.uniform(0, 100)

    def create_asset(self, **kwargs) -> bpy.types.Object: ...
```

**Dos niveles de azar, y esto es sutil e importante:** `factory_seed` fija los parámetros de la
**especie** (este roble tiene hojas así de anchas); `spawn_asset(i)` produce el **individuo** i.
Un bosque de robles distintos que siguen siendo todos robles. Nuestros generadores hoy tienen un
solo nivel, así que o salen clones o salen inconexos.

### Los límites, sin maquillaje

- **Escena completa es carísima**: config `local_256GB`, ~50 min por escena interior en 4 Xeon
  Gold, y el terreno multi-vista no es tratable sin CUDA. **No vamos a generar escenas.**
- **Los árboles no exportan a OBJ.** Textual de su doc: *"exporting whole trees as OBJs generally
  isn't supported, unless you do so at very low resolution, or you turn off the tree's branches /
  leaves first."* Usan instancias para ramas y hojas. Este es el límite más caro para nosotros,
  porque árboles es justo lo que más se necesita.
- Lo que **sí** sirve, y es barato: `generate_individual_assets` con `--render none --export obj`.
  Genera un asset suelto y lo exporta **sin renderizar**. Ahí no hay GPU.

---

## 2. PERM + hair20k — el MPFB2 del pelo

`github.com/c-he/perm`, **MIT**. Dataset de **21.054 peinados** (hair20k), sobre USC-HairSalon.

Dos dials, y desacoplan justo lo que nosotros teníamos mezclado:

- **θ** — tipo de corte, como mechones guía. La forma global.
- **β** — patrón de rizo local, como guedejas.

Nuestras categorías inventadas fueron "placas" y "cap": una decisión de implementación disfrazada
de decisión de diseño. Forma y rizo son los ejes reales.

**Camino completo a Godot, gratis:**

```
hair20k  →  strands .abc  →  addon de Daniel Bystedt (free)  →  hair cards  →  Godot
```

**No hace falta correr el modelo.** El valor está en el dataset ya generado: descargar, elegir,
convertir. Los 64 GB de RAM que pide el README son sólo para re-fittear el PCA.

Salidas: `.abc` (Alembic), `.ply`, `.obj`. Traen `.blend` de ejemplo.

⚠️ El MIT cubre el repo. Los modelos entrenados con datos internos de Adobe piden licencia aparte.
Los públicos no.

---

## 3. Texturing.xyz — displacement multicanal, y por qué la piel salió mal

Estándar de la industria. Un solo mapa donde **cada canal RGB es una FRECUENCIA distinta** de
detalle: macro (arrugas grandes), meso (pliegues), micro (poros). Cada canal se pesa por separado
en el render.

**Esto explica el defecto que Joan detectó** — *"tiene un patrón repetido"*. La piel del guerrero
metió **sólo micro**, como hash por vértice, sin macro ni meso, y a resolución de malla. Un poro no
puede vivir en la frecuencia de la malla: sale tejido, no piel. Por eso al sacarlo quedó plano —
las otras dos frecuencias nunca existieron.

**El concepto es gratis** aunque los mapas sean pagos: separar frecuencias y pesarlas aparte.

### Y el fork de arquitectura que esto abre

El techo de fidelidad fijado es **Skyrim**. Skyrim texturiza con **UV + normal maps**, no con
vertex paint. La técnica actual de piel está **estructuralmente por debajo del techo pedido** — no
por valores mal elegidos, por método. Decisión pendiente de Joan, no se ejecuta sola.

---

## 4. Microsoft FaceSynthetics — valida el modelo Metin2

`microsoft.github.io/FaceSynthetics`, dataset público, paper ICCV 2021.

Su método: **cara paramétrica + biblioteca de assets artesanales combinados proceduralmente.** Cada
cara se "viste" muestreando de colecciones de pelo, ropa y accesorios.

Es exactamente el sistema Metin2 que Joan propuso, publicado en ICCV.

Números concretos: malla facial de **53.215 vértices / 7.414 polígonos**, esqueleto mínimo de
**4 joints** (cabeza, cuello, dos ojos). La biblioteca de texturas se construyó con una colección
de escaneos con histogramas de edad y etnia declaradas — o sea, **la variedad de tez es un eje
muestreado del dataset**, no un multiplicador de color.

---

## 5. Hunyuan3D Studio — el pipeline game-ready documentado

arXiv 2509.12815. El modelo no corre acá (24 GB de VRAM), **la metodología sí**.

### Las tres métricas — ya implementadas

`game/tools/blender/mesh_quality.py`, con harness de sanidad en `_test_mesh_quality.py`:

- **BER** — Boundary Edge Ratio. Agujeros y bordes sueltos.
- **TS** — Topology Score. ⚠️ El paper nombra la métrica pero **no publica la fórmula**; la nuestra
  es propia y está documentada. No citarla como de ellos.
- **HD** — Hausdorff, punto-a-superficie. Si la malla derivada se despegó del original.

### El orden de las etapas

```
geometría  →  SEGMENTAR PARTES  →  retopología  →  UV  →  textura  →  rig
```

Segmentar partes va **antes** que UV y textura: **las partes definen dónde caen las costuras.**

Consecuencia directa: los **grupos de región** pendientes no son un paso lateral, son el paso 3 de
un pipeline validado, y destraban UV, armadura y amputaciones a la vez.

### Números duros reusables

- Costuras UV: ratio `R = segmentos_de_costura / vértices` válido en **[0.1 – 0.35]**, y alineadas
  a aristas ya existentes para no generar caras extra.
- Rig humanoide: **22 joints**.
- Texturas PBR: 4K (base color, metallic, roughness, normal).

---

## 6. TRELLIS.2 y el resto de la generación 3D

**TRELLIS.2** (Microsoft, **MIT**, 4B params): lo mejor abierto. 1536 de resolución en menos de 20 s,
PBR completo, topología compleja. Pide **24 GB de VRAM**; hay 8. No corre local.

**Hunyuan3D 2.1**: pesos + código de entrenamiento abiertos, pero licencia comunitaria que
**restringe uso en UE, UK y Corea**.

Con este hardware, ambos son API de pago, no local. Se anota y se sigue.

---

## 7. Qué hacer con todo esto — en orden

1. ~~**Las tres métricas.**~~ Hecho. `mesh_quality.py` + harness, verde contra verdad derivada.
2. **Presupuesto de polígonos derivado de píxeles.** Portar `target_face_size()` al FOV y la
   resolución reales de Dungeon Party. Reemplaza los números al ojo del contrato §3.
3. **Grupos de región.** Paso 3 del pipeline. Destraba UV, armadura y amputaciones.
4. **hair20k.** Bajarlo, elegir el undercut nórdico, convertir a cards con el addon de Bystedt.
   Cero GPU.
5. **Piel por frecuencias**, y antes la decisión de vertex paint vs UV+normal maps.
6. **Infinigen para vegetación**, con `--render none --export obj`, sabiendo que los árboles
   completos no exportan y hay que atacarlos por partes.

---

## Fuentes

- [Infinigen](https://github.com/princeton-vl/infinigen) — Princeton VL, BSD-3
- [PERM](https://cs.yale.edu/homes/che/projects/perm/) · [código](https://github.com/c-he/perm) ·
  [hair20k](https://zhouyisjtu.github.io/project_hair/hair20k.html)
- [Hunyuan3D Studio](https://arxiv.org/pdf/2509.12815) — arXiv 2509.12815
- [FaceSynthetics](https://microsoft.github.io/FaceSynthetics/) — Microsoft, ICCV 2021
- [Texturing.xyz multicanal](https://texturing.xyz/pages/discover-unwrapped-multi-channel-faces)
- [TRELLIS.2](https://github.com/microsoft/TRELLIS.2) — Microsoft, MIT
- [Addon strands→cards de Daniel Bystedt](https://www.cgchannel.com/2024/03/daniel-bystedts-free-blender-add-on-creates-hair-cards-from-curves/)
