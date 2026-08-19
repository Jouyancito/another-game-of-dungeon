# Contrato de creación de assets — Dungeon Party

Canon vigente desde 2026-08-15. Aplica a **todo** lo que se modele: personajes, piezas de
equipo, props, estructuras.

Nace de un pedido de Joan después de que el pelo del guerrero saliera mal tres veces seguidas:

> *"cómo modelar cosas que ya sabes cómo funcionan, o ver qué es lo que te falta... por ejemplo,
> el pelo tú debes saber que el cuero cabelludo son puros folículos individuales que tienen
> cierto ancho, longitud, densidad, color, y son muchísimos, pero también saber que hay técnicas
> que funcionan bien, para no hacer millones de polígonos."*

Ahí está el contrato entero en una frase. Va desarrollado abajo.

---

## 0. El contexto del juego — lo que condiciona TODAS las decisiones de abajo

Estas cinco cosas no son preferencias: son las restricciones que hacen que este contrato sea de
Dungeon Party y no genérico. Cualquier decisión de modelado se contrasta contra ellas primero.

**Es PRIMERA PERSONA.** El jugador nunca se ve la cara ni el cuerpo. Los rasgos faciales sólo
aparecen en `character_select` (preview 3D estilo D2) y en los compañeros de party a media
distancia. Medido: **a distancia de juego una cabeza ocupa ~20 px y ningún rasgo facial se lee**
— ni una ceja marcada ni una sutil. El presupuesto de cara es mucho menor de lo que parece.

**El cuerpo es una base limpia; la identidad la pone el EQUIPO.** Sistema tipo Metin2: un cuerpo
compartido sin ropa, y encima se monta armadura. Consecuencia dura: con equipo puesto, la piel
visible se reduce a **rostro, cuello, manos y antebrazos** — detallar torso y piernas es
esfuerzo perdido. Y el casco, cuando exista, define cuánto pelo se ve; puede volver secundario
todo el trabajo de peinado.

**Estilo del rostro: REALISTA, no anime.** Se toma el *sistema* de Metin2 (base + equipo), no su
tratamiento facial estilizado. El nivel de fidelidad lo fija §3b: **Skyrim**.

**Las clases se distinguen por SILUETA y COLOR antes que por detalle.** El triángulo, derivado de
las referencias:

| Clase | Silueta | Eje del prop | Paleta |
|---|---|---|---|
| Warrior | masa ancha, centro bajo | ensancha | cálida — negro, rojo tierra, plata oxidada |
| Mage | columna vertical | báculo, vertical | fría — azul-gris, negro, plata |
| Archer | ancha y baja | arco, horizontal | apagada — oliva, marrón, cuero |

Tres lecturas limpias a veinte metros. Sostener eso vale más que cualquier detalle de superficie.

**El asset se juzga al tamaño de uso, no al de inspección.** Personaje → junto al poste de 1,80 m
y a distancia de juego. Un rasgo que sólo se aprecia acercando la cámara más de lo que el juego
permite, no existe.

---

## 1. Las dos capas — ninguna sirve sin la otra

Todo asset se piensa en dos niveles, y **saltarse cualquiera produce el mismo tipo de error**.

### Capa A — El mecanismo real

Qué es la cosa en el mundo, cómo funciona, cómo es normalmente. Sin esto no hay criterio de
éxito y se termina "descubriendo" por render lo que se sabía de antemano.

Para el pelo: crece de folículos, cada uno con su ancho, largo, densidad y color; son
decenas de miles; cae por gravedad; se peina en una dirección; **los mechones se solapan**, y
por eso en una cabeza con pelo no se ve el cuero cabelludo salvo en la raya.

De ahí sale el criterio antes de tocar nada: **cero scalp visible fuera de la raya**. No hizo
falta ningún render para saberlo.

### Capa B — La técnica de aproximación

Cómo se consigue eso **sin** modelar el mecanismo real. Nadie modela cincuenta mil folículos:
la industria tiene soluciones probadas, y el trabajo de modelar es **elegir la correcta**.

Para el pelo, tres capas: cap opaco → cards/cáscaras en capas → mechones sueltos. El cap da
cobertura por construcción; las cards dan volumen y silueta; los mechones dan identidad.

**El salto entre A y B ES el trabajo.** Con A sin B se modelan millones de polígonos. Con B sin
A se aplica una técnica sin saber qué tiene que lograr — que fue el caso del pelo: se sabía
"placas" sin saber que el criterio era el solapamiento.

### Cuando falta la capa B

Pasa seguido y hay que decirlo en vez de improvisar. Qué hacer:

1. **Nombrar la familia del problema.** "Superficie fina y densa sobre una malla" (pelo, pasto,
   pelaje), "tela sobre cuerpo", "interior que no se puede entrar".
2. **Buscar la técnica establecida de esa familia**, no del asset puntual.
3. **Si no aparece, decirlo explícitamente** y proponer la aproximación más simple que se pueda
   medir. Nunca presentar una invención como si fuera el método estándar.

### Qué da y qué no da una referencia visual

- **Un screenshot da el OBJETIVO**: cómo se ve, qué se lee, qué proporción tiene.
- **Un screenshot NO da el MÉTODO**: cómo está construido por dentro. El sistema de pelo de
  Arthur Morgan en RDR2 se ve buenísimo y es propietario; mirándolo no se deduce.
- Por eso **hacen falta las dos fuentes**: la referencia fija el objetivo, la técnica pública da
  el camino. Trabajar con una sola es exactamente donde se inventa.

---

## 2. Composición — toda pieza consulta el cuerpo antes de construirse

Pedido de Joan: *"si haces pelo, el pelo tiene que caer sí o sí por alrededor de la oreja, no
pasa por la oreja completa"*.

Es una sola regla para muchos casos: **nada se monta sobre el cuerpo sin saber qué hay debajo.**

El cuerpo MPFB trae **152 grupos de vértices** que son esa información, ya hecha:

| Zona | Grupos disponibles | Para qué sirve |
|---|---|---|
| Oreja | `ears` | El pelo la rodea, no la atraviesa |
| Ojos | `helper-{l,r}-eye`, `joint-{l,r}-eye` | Cascos y capuchas no los tapan; permite ojo faltante |
| Boca | `lips`, `helper-{upper,lower}-teeth`, `helper-tongue` | Cascos con visera, mordaza, barba |
| Cuero cabelludo | `scalp` (376 verts) | Dónde nace el pelo — es la definición anatómica |
| Manos | `fingernails`, `joint-l-finger-N-M` (por dedo) | Guantes; dedo faltante |
| Articulaciones | 125 grupos `joint-*` | **Puntos de corte para amputaciones** |

### Reglas por tipo de pieza

| Pieza | Debe respetar | Debe ocultar |
|---|---|---|
| Pelo | `ears` — cae alrededor | — |
| Casco | ojos, `ears` si es abierto | el pelo, o usa variante recortada |
| Guante | — | `fingernails` |
| Coraza | — | torso bajo ella (evita clipping) |
| Manga | el punto de corte del brazo | antebrazo si va larga |

### Amputaciones y variantes de cuerpo

No hace falta modelar nada nuevo: el cuerpo ya tiene un modificador **MASK** que oculta
vértices por grupo.

- **Antebrazo amputado** → máscara desde `joint-l-elbow` hacia abajo + tapa en el corte.
- **Dedo faltante** → `joint-l-finger-3-*` fuera de la máscara.
- **Ojo faltante** → `helper-l-eye` fuera + párpado cerrado por morph.

**Y la ropa tiene que enterarse.** Manga larga sobre un muñón tiene tres salidas, de menor a
mayor costo:

1. **Recortada** a la altura del corte. Un solo criterio para cuerpo y prenda, cero geometría.
2. **Anudada** — un toro achatado y la tela estrechándose hacia él. Da carácter: dice que la
   persona convive con eso.
3. **Caída y vacía** — la más difícil: sin brazo adentro la tela COLAPSA. Rígida se ve como un
   tubo hueco flotando. Necesita física de tela, o modelarse ya plegada y quieta (que a
   distancia de juego lee perfecto y es lo recomendado).

---

## 3. Presupuesto — qué se finge en vez de construirse

Tercera capa, y la que más ahorra. La pregunta no es "¿cómo lo modelo?" sino **"¿qué parte de
esto el jugador nunca va a poder inspeccionar?"**.

Ejemplo que planteó Joan: una carpa de mercader que no se puede entrar. El interior no se
modela — la abertura lleva una imagen con parallax que se mueve al caminar. Referencia guardada
en `_references/fake_interior_parallax/`.

Preguntas obligatorias antes de construir:

- **¿A qué distancia se ve?** Un rasgo que no se lee al tamaño de uso no existe. Medido en este
  proyecto: a distancia de juego una cabeza mide ~20 px y **ningún** rasgo facial se lee.
- **¿Se puede entrar / rodear?** Si no, el interior y la cara oculta no se modelan.
- **¿Va tapado por equipo?** Con armadura, la piel visible se reduce a rostro, cuello, manos y
  antebrazos. Detallar torso y piernas es esfuerzo perdido.
- **¿Es color o es forma?** El lateral rapado de un undercut es color, no geometría. La barba de
  tres días es valor; la barba llena es masa. **Rala se pinta, llena se modela.**

---

## 3b. Nivel de fidelidad — el techo es SKYRIM

Joan, 2026-08-15: primero *"algo más simple estilo red dead 1 quizás"*, y enseguida la
corrección: *"creo que igual di un estándar muy bajo xd, quizás podría ser más un skyrim"*.

Es la decisión que más ahorra de todo el documento, porque **fija cuándo parar**. Sin techo, cada
asset tiende a pedir un pase más.

Y es un techo que se puede señalar con el dedo: **Farkas ya es una de las referencias del
guerrero** (`_references/warrior_archetype/07_skyrim_farkas.jpg`). El estándar no es abstracto.

| | RDR1 (2010) | **SKYRIM (2011) ← nuestro techo** | RDR2 (2018) |
|---|---|---|---|
| Pelo | cáscaras opacas | **cards con alpha**, mechones translúcidos | miles de cards + física por mechón |
| Piel | albedo simple | **albedo + normal + roughness** | + subsurface |
| Cara | rasgos por geometría | **+ arrugas grandes y cicatrices en normal** | poros, arrugas dinámicas |
| Armadura | capas pintadas | **capas modeladas, hebillas con geometría** | desgaste procedural |
| Tela | modelada plegada | **modelada plegada** | simulación |
| Aguanta | media distancia | **media distancia y preview de personaje** | close-up de cine |

### Qué habilita, concretamente

- **Hair cards con alpha vuelven a estar dentro.** Requiere UVs en las cards (excepción legítima
  a la regla de "sin UVs" del proyecto), un atlas de mechones, y un `toon_hair.gdshader` derivado
  con `cull_disabled` + `depth_prepass_alpha`. El `toon_basic` ya lee alpha (`ALPHA = base_col.a`)
  pero tiene `cull_back` y `blend_mix`, que romperían el pelo.
- **El normal map entra al presupuesto** para arrugas grandes, cicatrices y desgaste de metal.
- **La armadura lleva hebillas y correas modeladas**, no sólo pintadas.

### Qué sigue afuera

- **Los poros. En ningún soporte.** Skyrim no los tiene; eso es RDR2.
- Subsurface scattering y arrugas dinámicas de expresión.
- Simulación de tela: sigue modelada plegada y quieta.

**Regla de corte**: si un detalle sólo se aprecia acercando la cámara más de lo que el juego
permite, no se hace. Y si alguien pide "más real", la respuesta es Skyrim, no RDR2.

Sigue compatible con el canon *"modelo Valheim"* (`_art_canon.md`): geometría simple, materiales
ricos, luz dramática — Skyrim sube el techo de MATERIALES, no el de polígonos.

---

## 3c. Sistema de equipo — forma, material y marcador

Diseño de Joan, 2026-08-15: *"al principio solo tuvieran ropa simple, como cualquier novato, y a
medida que vas subiendo, sacar crafteos de armaduras acorde al mob que requiere; si hacemos su
armadura de cuero de lobo, es como la skin del lobo en la armadura"*.

Resuelve producción y diseño con la misma decisión, y **destraba la fila de ropa/armadura** que
era la que faltaba del inventario.

### Las tres capas

Lo que lo hace barato es **separar forma de material**.

| Capa | Qué aporta | Cuántas | Se comparte entre clases |
|---|---|---|---|
| **Forma** | silueta, clase, peso, tier | **una POR CLASE y por tier** | ❌ nunca |
| **Material** | color, textura, "de qué está hecho" | uno por mob | ✅ sí |
| **Marcador** | reconocimiento a distancia | 1-2 por mob | ✅ sí, adaptado a la forma |

**La forma es POR CLASE, y no es negociable.** Como el §0 dice que las clases se distinguen por
silueta antes que por detalle, compartir la forma entre clases tiraría abajo esa distinción: la
misma armadura de oso tiene que ser una **coraza pesada** en el Warrior y una **túnica con la
piel al hombro** en el Mage. Mismo ítem, mismo material, mismo marcador — modelos distintos.

Es lo que hace Metin2 y por eso funciona ahí: el ítem es uno, el modelo es por clase.

Cuentas reales con 3 clases y 3 tiers:

```
FORMAS a modelar    3 clases × 3 tiers            =  9
MATERIALES          6 mobs, reutilizados en todas =  6   (ya existen)
MARCADORES          6 mobs, adaptados por forma   =  6   (piezas chicas)

SETS resultantes    9 formas × 6 materiales       = 54
```

**54 sets visualmente distintos modelando 9 piezas.** El ahorro sigue intacto: lo que se
multiplica es sólo la capa cara, y lo barato — material y marcador — se reusa entre todas las
clases.

### El marcador no es opcional

Si sólo cambia el material, **todas las armaduras tienen la misma silueta**. A distancia de juego
el material casi no se lee: lo que se lee es el contorno (§0). Dos jugadores con cuero de lobo y
de oso se verían idénticos a veinte metros, y ahí se pierde justo la sensación de progresión que
el sistema busca dar.

Por eso cada mob aporta **una o dos piezas que rompen el contorno**: la cabeza del lobo como
capucha, los colmillos del jabalí cruzados al pecho, placas irregulares del golem. Es poca
geometría y hace todo el trabajo de lectura.

### Recetas: material primario + secundarios

También de Joan: *"quizás seleccionaríamos alguno en específico y que otros mobs sean
complementos, onda slime sirve de pegamento"*.

- **Primario** — define el material y el marcador. Es el mob que da nombre al set.
- **Secundarios** — insumos funcionales, sin efecto visual. El slime como pegamento, tendones,
  resina.

El valor de diseño está en los secundarios: **le dan propósito a mobs que si no son sólo XP**, y
crean razones para cazar cosas puntuales.

### Tier 0 — la ropa de novato

Forma tier 0, **sin marcador**, material neutro de tela cruda. Es el arranque del jugador y no
requiere modelar nada nuevo más que la forma base.

### Qué hay para trabajar

El juego tiene **18 enemigos**, así que materiales y marcadores salen de mobs que ya existen. La
única producción nueva son las 4-5 formas por tier.

### Cómo se monta la prenda: REEMPLAZA el cuerpo, no lo viste

Propuesta de Joan, 2026-08-15: *"se puede colocar estilo Metin2, que cada cuerpo se ajuste a esa
ropa"*. Es la técnica correcta y resuelve el único punto que quedaba sin camino.

**La armadura no se conforma al cuerpo: ocupa su lugar.** Cada pieza es una malla completa que ya
incluye por dentro la forma del cuerpo, y la región de cuerpo que queda debajo **se oculta**.

Por qué es la salida barata y no un atajo:

- **No existe el problema de conformar tela.** Nunca hay que resolver cómo cae una prenda sobre
  un cuerpo, porque no hay prenda sobre cuerpo — hay una pieza en su lugar.
- **Mata el clipping de raíz.** No puede atravesarse lo que no está.
- **El rigging es gratis**: la pieza usa el mismo esqueleto y los mismos pesos que la región que
  reemplaza.
- **Encaja con el base compartido** (§0): el cuerpo es el maniquí, y con armadura puesta deja de
  verse — que es justamente lo que ya estaba asumido.

Contrapartida, para tenerla explícita: **bajo armadura el cuerpo deja de importar.** Dos
personajes con distinto físico y la misma coraza se ven iguales de torso. Es aceptable acá
porque el cuerpo es compartido por diseño, pero significa que **las variaciones de cuerpo sólo se
leen en las zonas expuestas** — rostro, cuello, manos, antebrazos.

### El mecanismo, y qué falta para tenerlo

El modificador **MASK ya está funcionando** en la malla (`Hide helpers`, sobre el grupo `body`):
ocultar vértices por grupo es algo que el cuerpo ya sabe hacer.

Lo que falta son los **grupos de REGIÓN**. Los 152 grupos actuales son articulaciones (125
`joint-*`) y rasgos (`ears`, `lips`, `scalp`, `fingernails`), pero no hay `torso`, `forearm_L`,
`thigh_R`. Se generan **una sola vez**, derivándolos de los joints que ya existen: el antebrazo
izquierdo es lo que cae entre `joint-l-elbow` y `joint-l-wrist`.

Regiones mínimas para vestir un personaje:

```
torso · pelvis · brazo_sup_{L,R} · antebrazo_{L,R} · mano_{L,R}
muslo_{L,R} · pierna_{L,R} · pie_{L,R} · cuello · cabeza
```

Y sirven para las **dos** cosas que estaban abiertas:

| Uso | Cómo |
|---|---|
| Ocultar cuerpo bajo armadura | la pieza declara qué regiones tapa; el MASK las saca |
| Amputaciones | la región sale del MASK + tapa en el corte |
| Manga sobre muñón | la prenda consulta hasta qué región llega el cuerpo (§2) |

### Qué región reemplaza cada pieza, por clase

Y acá aparece la segunda consecuencia de que la forma sea por clase: **no todas las clases tapan
las mismas regiones con la misma pieza**. Una coraza de guerrero se come el torso entero; una
túnica de mago se come torso, pelvis y muslos de una sola vez, porque llega hasta el pie.

| Pieza | Warrior | Mage | Archer |
|---|---|---|---|
| Torso | torso | torso + pelvis + muslos (túnica larga) | torso + pelvis |
| Brazos | brazo_sup + antebrazo | antebrazo (manga suelta) | antebrazo |
| Piernas | muslo + pierna | — (ya tapadas por la túnica) | muslo + pierna |

Eso también explica un ahorro que ya estaba anotado: **la túnica del Mage elimina las piernas de
la silueta**, así que su set cuesta menos geometría que el del Warrior aunque cubra más cuerpo.

### Lo que falta decidir

- **Cuántos tiers** y qué formas por tier (ligera / media / pesada), sabiendo que cada tier se
  multiplica por las 3 clases.
- **Generar los grupos de región** — trabajo concreto, una vez, y destraba armadura y
  amputaciones a la vez.
- **Referencias**: no hay carpeta de ropa/armadura todavía.

---

## 4. Preflight — los 10 puntos, escritos antes de generar

Extiende el preflight de 8 de `CLAUDE.md` con composición y presupuesto.

```
PREFLIGHT — <asset>
0. QUÉ ES ......... mecanismo real (capa A) → de ahí sale el criterio de éxito
0b. CON QUÉ TRUCO . técnica establecida de la familia (capa B). Si no se sabe, DECIRLO
1. refs ........... _references/<X>/ citadas — dan el objetivo, no el método
2. lecciones ...... asset previo con el mismo fallo de forma → regla
3. recetas ........ del motor, en vez de reimplementar
4. métrica ........ el número que decide, definido ANTES de construir
4b. COMPOSICIÓN ... qué zonas del cuerpo respeta y qué oculta (tabla §2)
4c. PRESUPUESTO ... qué NO se modela porque no se ve (§3)
5. rampa .......... N variantes del parámetro dudoso — el valor lo elige Joan
6. vistas ......... frente/perfil/3-4 + ingratas (nuca, cenital) + tamaño de uso
7. lectura ........ ¿encaja? ¿se fusiona? — no "¿está puesto?"
```

Un punto sin evidencia concreta al lado cuenta como NO hecho.

---

## 5. Qué sabemos y qué falta

Inventario honesto, para que "qué me falta" sea visible y no una sorpresa a mitad de camino.

| Familia | Capa A | Capa B | Estado |
|---|---|---|---|
| Cuerpo humano | ✅ MPFB2, paramétrico, 1258 morphs | ✅ morphs + vertex paint | resuelto |
| Pelo | ✅ folículos, solape, gravedad | ✅ cap + **cards con alpha** (techo Skyrim) | cap hecho; cards con alpha sin empezar |
| Barba | ✅ densidad decide | ✅ rala=valor, llena=geometría | sin empezar |
| Piel | ✅ variación por zona | ✅ vertex paint + **normal map** para arrugas y cicatrices | albedo a medias, normal sin empezar |
| Ropa / armadura | ✅ capas, correas, desgaste | ✅ **reemplaza la región del cuerpo** + MASK (§3c) | técnica resuelta; faltan grupos de región y refs |
| Amputaciones | ✅ punto de corte anatómico | ✅ MASK + tapa, mismos grupos de región | factible, sin hacer |
| Tela colgante | ✅ colapsa sin cuerpo | ✅ modelada plegada (sin simulación) | sin probar |
| Interiores falsos | ✅ | ✅ parallax en la abertura | referencia guardada |
| Etnias / culturas | ⚠️ requiere investigación por caso | — | por caso |

**La fila que más duele hoy es la de ropa/armadura**, porque es lo que define la lectura de cada
clase y todavía no tiene técnica elegida.

### Referencias: qué hay y qué falta

| Carpeta | Imágenes | Suficiente para decidir |
|---|---|---|
| `warrior_archetype/` | 16 + síntesis (a)(b)(b.2)(c) | ✅ sí |
| `ranger_archetype/` | 3, tres medios distintos | ✅ sí |
| `hair_undercut_viking/` | 2 | ✅ para el peinado del Warrior |
| `hair_polygon_shells/` | 3 + 6 frames del video | ⚠️ técnica descartada (anime) |
| `mage_archetype/` | **1** | ❌ **no** — sesgo de fuente única |

Faltan además:
- **Artillero** (rama del Archer). Tiene raíz cultural en el canon — mineros de Lota — pero **cero
  referencias visuales**, y no se deriva de las del Ranger: ninguna sugiere artillería.
- **Ropa y armadura**: sin lote propio. Es la carpeta que más falta, porque es lo que define la
  lectura de las clases.

Regla de Joan que aplica a todas: **nunca una sola fuente por sujeto** — *"si sacás de una sola
fuente eso te va a dar un sesgo rígido"*.

---

*Contrato v1.0 — 2026-08-15. Se versiona acá antes de aplicarse.*
