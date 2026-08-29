> # ⚠️ TÉCNICA DESCARTADA — NO CONSTRUIR CON ESTO
>
> **Descartada el 2026-08-15** en `_asset_creation_contract.md` §402: *"⚠️ técnica descartada
> (anime)"*. El techo de fidelidad del proyecto es **Skyrim** (§3b), y en esa fila el pelo es
> **cards con alpha + atlas de mechones**. Las cáscaras opacas son el renglón **RDR1**, un
> escalón por debajo del estándar que Joan corrigió hacia arriba.
>
> **Costó dos implementaciones.** El 2026-08-22 se construyó esta técnica dos veces seguidas
> —`gen_char_hair_shells.py` y el blockout previo— leyendo esta carpeta y sin abrir el
> contrato. Ninguna leyó como pelo. La técnica vigente está en
> `gen_char_hair_cards.py` + `gen_hair_atlas.py`, y el método en
> `_modeling_knowledge_base.md` §Hair.
>
> **Qué sigue sirviendo de acá**: la *cáscara base* (frames 65-171) equivale al **scalp cap**
> del método de tres capas, que sí es canon. Lo descartado son las cáscaras de mechón como
> reemplazo de las cards.
>
> *(Aviso agregado 2026-08-23 por la auditoría de activación: el descarte de una técnica se
> escribe en su propia carpeta de referencia, porque el lector natural de una referencia es
> justamente el que está por construir con ella.)*

---

# hair_polygon_shells — pelo construido como cáscaras de polígonos (2026-08-13)

**Joan dijo:** *"es como de una sujeta de que le están haciendo el pelo, y se la hacen con polígonos, pero se ve precioso, hay resultado. Esa idea está muy buena para trabajar quizás en el pelo de los personajes."*

Referencia #1 de siete grabadas el 2026-08-13. Es la que toca directo el hueco abierto del guerrero: hoy su pelo es un casquete plano pintado sobre el cuero cabelludo, con borde duro.

## Imágenes

| # | Qué se ve |
|---|---|
| 01 | Cabeza low-poly gris de frente-perfil, con las primeras cáscaras colocadas sobre el cráneo |
| 02 | Vista 3/4: el pelo ya es un conjunto de placas anchas con wireframe visible, siguiendo el volumen del cráneo |
| 03 | Vista lateral/trasera: las placas se superponen en capas, con una cola o mechón separado |

## Síntesis

### Idea
El pelo **no es una superficie continua ni una textura pintada**: es un conjunto de **placas poligonales anchas** — pocas, grandes, deliberadamente facetadas — que se apoyan sobre el cráneo siguiendo su curvatura. Cada placa es un mechón. El volumen sale de cómo se superponen, no de densidad.

### Forma
- Placas anchas y planas, no tiras finas. Se leen como mechones, no como pelos.
- Nacen del cráneo y lo envuelven: la base de cada placa sigue la curva de la cabeza, la punta se despega.
- Se superponen en **capas** — la de atrás asoma entre las de adelante. Ahí está el volumen.
- El silueteado del peinado lo definen los bordes de las placas exteriores, no una malla de contorno.

### Por qué sirve acá
Encaja con el canon del proyecto sin adaptación:
- **Silueta = geometría** (§2.1 de `_char_build_brief.md`): el peinado se lee a distancia por su contorno de placas.
- Es geometría low-poly con material simple — el modelo Valheim del canon vigente.
- Cae del lado determinista del pipeline: colocar placas sobre una superficie conocida es plomería, no pintura a ciegas. El cráneo del cuerpo MPFB ya tiene grupo `scalp` (376 verts) que define exactamente dónde nacen.

### Qué capturar
1. Pocas placas, grandes. Si se necesitan muchas para que se vea bien, el enfoque es otro.
2. La base de cada placa **conformada al cráneo**, no flotando encima.
3. Superposición en capas con un orden claro: nuca → laterales → frente.
4. Un mechón o cola separada como marcador de identidad, no simetría perfecta.

### Contra qué NO sirve
No resuelve pelo largo con física ni barba. Para el guerrero — pelo corto o recogido bajo el trarilonko — es exactamente lo que hace falta.

## Lote 2 — 2026-08-15: la técnica vista completa (corrige el lote 1)

Joan volvió a grabar el video *"para que te des cuenta que no es solamente placas"*, después de
que la primera implementación saliera rala y con placas volando sobre el cráneo. Sesión
`2026-08-15_12-37-33`, 483 frames. Seis recortados y commiteados acá.

| Archivo | Qué muestra |
|---|---|
| `shell_00193_paint_divisions.png` | La cáscara en blanco con trazos negros dibujados encima: se marcan las divisiones de mechones SOBRE la superficie continua |
| `shell_00216_paint_side.png` | Lo mismo de perfil |
| `shell_00299_shells_underside.png` | **La clave** — la cáscara vista desde abajo/adentro: pocas placas ENORMES, reverso blanco |
| `shell_00311_shells_open.png` | Las cáscaras separadas: bordes recortados irregulares, no rectángulos |
| `shell_00326_shells_stack.png` | Cómo se apilan, superpuestas como tejas |
| `shell_00339_result_front.png` | Resultado final: pelo corto ondulado con volumen |

### Lo que corrige

El lote 1 se leyó como "placas anchas repartidas sobre el cráneo" y se implementó como **39
tiras angostas de ancho constante** que avanzan por raycast. El video muestra otra cosa:

1. **Pocas cáscaras GRANDES, no muchas tiras.** Del orden de 10-15, cada una cubriendo una
   porción importante del cráneo. El nombre de la carpeta ya lo decía — *shells*, cáscaras.
2. **El borde de cada cáscara está RECORTADO en forma irregular, y ese borde ES el mechón.**
   El detalle no viene de una textura ni de subdividir: viene de la silueta del contorno.
3. **Se solapan como tejas**, cada una montada sobre la anterior.
4. **Sin textura alpha.** Se descartó explícitamente la vía UV + atlas de mechones + alpha que
   se había propuesto el 2026-08-15: es la técnica de otro estilo (hair cards realistas) y acá
   no hace falta. El color es un parámetro plano — en el video aparece la misma cabeza en
   borgoña y en rubio.

### Implicancia para el generador

`gen_char_hair_plates.py` construye tiras de `SEGMENTS × STEP` de largo y `ROOT_W` de
semi-ancho. Eso hay que reemplazarlo por cáscaras: superficies grandes conformadas al cráneo
con contorno dentado. El **scalp cap** que se agregó el 2026-08-15 sigue siendo válido y de
hecho se parece a la cáscara base del video (frames 65-171) — lo que falta es que las capas de
encima sean cáscaras y no tiras.

## Fuente
Grabación de pantalla de Joan, sesión `2026-08-13_03-24-14` (499 frames, Instagram). La sesión original **ya fue borrada** por la auto-limpieza de `capturar.ps1`, que conserva sólo las últimas 3. Estas hojas de contacto son la única copia sobreviviente.
