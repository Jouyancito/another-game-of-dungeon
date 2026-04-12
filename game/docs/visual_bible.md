# Visual Bible — Dungeon Party

**Documento**: Referencia visual maestra por piso
**Versión**: 1.0 — 2026-04-11
**Relación**: `DESIGN_BRIEF.md` §3 (referencias) + `tier_1_pool.md` (YAML de pisos)
**Fuente**: concept art generado con Hailuo AI + Gemini 2.5, validado contra el brief

---

## Cómo usar este documento

Cada piso tiene una entrada con:
1. **Imagen canon** — path al archivo de referencia. Es la "foto" que define el piso.
2. **Paleta hex** — colores exactos extraídos de la imagen canon, con rol asignado.
3. **Lighting setup** — valores concretos para Godot (DirectionalLight3D, WorldEnvironment).
4. **Escala** — dimensiones del piso (NO todos son 600×600m; cada piso tiene la escala que pide su emoción).
5. **Shape language** — orgánico/geométrico, bordes, densidad visual.
6. **Mood** — emoción dominante validada contra el brief.
7. **Notas para modelado** — qué priorizar cuando se armen los assets.
8. **Aceptado/Rechazado** — qué sí copiar de la imagen y qué no.

Cuando un artista, IA o modelador trabaje en un piso, **abre esta entrada primero**. No inventa. La imagen canon es la verdad, la paleta hex es ley, y las notas resuelven ambigüedades.

---

## Principios visuales universales

**Paleta maestra del Tier I** (extraída de las 5 canon):
```
CÁLIDOS (dominantes):
  #F5D576  dorado diamante / emisión principal del techo
  #E8D4A0  luz cálida de los rayos del techo
  #F5B048  dorado de fogatas, antorchas
  #F0C898  cielo pastel tarde-atardecer
  #E0C58A  piedra cálida ruinas

VERDES (terreno):
  #8FAE6B  verde pradera pastel (P1)
  #6B8B3A  verde hierba iluminada
  #5C7A34  musgo denso sobre piedra
  #2E3D24  verde oscuro canopy (P2)

FRÍOS (acentos):
  #7A8FC4  azul-lavanda del techo interior
  #A8D4E8  azul emisión del fantasma / cristales
  #5C84A0  azul agua de estanques
  #7ECFD8  cian de hongos bioluminiscentes

OSCUROS (sombras/noche):
  #3D2818  marrón troncos profundo
  #1C3044  azul oscuro noche bosque
  #3C2824  banderas bandidos, ropa oscura
```

**Regla**: en el Tier I, los cálidos dominan (60-70% de la imagen), los verdes sostienen (20-25%), los fríos acentúan (10-15%). En Tier II-III los fríos ganan terreno.

**Lighting universal del Tier I**:
- Fuente principal: diamante emisivo del techo de caverna (DirectionalLight3D, ~70-80° desde arriba)
- God rays: firma visual del tier interior. Todo piso que muestre el techo debe tener rayos volumétricos.
- Temperatura: 3200-3800K (cálida dorada, nunca blanca fría)
- Fog: siempre presente pero sutil (~0.002 densidad), color azul-lavanda para profundidad atmosférica
- NO sky node — background solid color (canon técnico del proyecto)

**Shape language del Tier I**:
- Orgánico dominante (curvas, raíces, musgo, piedras redondeadas)
- Las únicas formas geométricas son humanas (outpost, ruinas, pérgola, carreta)
- Densidad visual: media-alta en bosque, media en pradera, baja en claro

**Escala de pisos (principio canon)**:
Cada piso tiene la escala que pide su emoción. NO hay una medida única.

| Piso | Escala | Por qué |
|---|---|---|
| P1 Pradera | 600×600m | La apertura y el asombro son su alma |
| P2 Bosque | ~200×200m | La opresión y el laberinto son el punto |
| P3 Ruinas | ~300×300m | Exploración con rincones, ni tan amplio ni tan cerrado |
| P4 Paso | ~400×200m (lineal) | El camino define la forma, no un cuadrado |
| P5 Claro | ~100×100m | La intimidad es el punto |
| P24 Boss | 80×80m (cerrado) | Arena instanced |

---

## P1 — Pradera Interior (Tutorial Zone)

**Imagen canon**: `game/docs/refs/p1_prairie/canon_main.jpg`
**Escala**: 600×600m

### Paleta
```
#F5D576  dorado del diamante emisivo (el "sol" del techo)
#E8D4A0  dorado de los god rays cayendo
#8FAE6B  verde pradera pastel suave
#7A8FC4  azul-lavanda del cielo interior de cristales
#6B7C9E  gris-azul de montañas lejanas
#7B5A3C  madera del outpost
#F5F5F2  blanco de cascadas
```

### Lighting Godot
```
DirectionalLight3D:
  rotation_degrees: Vector3(-75, -30, 0)   # desde arriba-izquierda
  light_energy: 3.5
  light_color: Color(0.96, 0.85, 0.63)     # #F5D8A0
  shadow_enabled: true (setting-dependent)

WorldEnvironment:
  ambient_light_color: Color(0.72, 0.77, 0.85)  # #B8C4D8 azul-lavanda
  ambient_light_energy: 0.4
  fog_enabled: true
  fog_density: 0.002
  fog_light_color: Color(0.78, 0.83, 0.88)      # #C8D4E0
  background_mode: CLEAR_COLOR
  background_color: Color(0.72, 0.77, 0.85)
```

### Notas para modelado
- God rays son FIRMA VISUAL del Tier I interior. Implementar con shader volumétrico o partículas grandes semi-transparentes orientadas al diamante.
- El diamante emisivo del techo debe ser ENORME (visible desde todo el mapa) con OmniLight3D o SpotLight3D con energía alta (~10) y rango largo (~500m). Shader con emission + albedo blanco-dorado.
- Los cristales Vía Láctea son MultiMesh con emission suave (~0.5 energy), distribuidos en curva S en el techo.
- El outpost es ~30m de radio con empalizadas de madera, 2-3 torres de vigía, chimeneas con partículas de humo.
- Las cascadas del borde son partículas + mesh de agua con shader translúcido.

### Aceptado de la imagen canon
- Composición panorámica con outpost al centro y diamante arriba ✅
- Proporciones outpost vs campo vs techo ✅
- Paleta cálida dorada dominante ✅
- God rays fuertes desde el diamante ✅
- Cristales emisivos en el techo curvo ✅
- Cascadas en los bordes ✅

### NO copiar
- El fondo parece un cielo abierto con nubes — en el juego NO hay cielo abierto. Es un techo de caverna cerrado con diamante y cristales. La imagen lo muestra bien pero el gradiente del fondo podría confundirse con sky.

---

## P2 — Bosque del Lindero

**Imagen canon**: `game/docs/refs/p2_bosque_lindero/canon_main.jpg` (Gemini)
**Variantes útiles**: `variant_hongos_a.png`, `variant_hongos_b.png` (Hailuo — hongos gigantes cian)
**Escala**: ~200×200m (compacto, claustrofóbico — la opresión es el punto)

### Paleta
```
#3D2818  marrón profundo de troncos (dominante en sombras)
#2E3D24  verde oscuro del canopy (dominante arriba)
#7A8494  gris-azul de la niebla entre árboles
#F5C76A  dorado de luciérnagas (acento emisivo cálido)
#8C7856  tierra con huellas de animales
#7ECFD8  cian de hongos bioluminiscentes gigantes (acento fuerte)
```

### Lighting Godot
```
DirectionalLight3D:
  rotation_degrees: Vector3(-85, 20, 0)   # casi vertical, filtrada por canopy
  light_energy: 1.5                         # MUCHO menor que P1 — bosque filtra
  light_color: Color(0.88, 0.78, 0.55)     # dorado filtrado por hojas

WorldEnvironment:
  ambient_light_color: Color(0.22, 0.28, 0.35)  # azul-gris oscuro
  ambient_light_energy: 0.3                       # bajo — bosque es oscuro
  fog_enabled: true
  fog_density: 0.008                               # más denso que P1
  fog_light_color: Color(0.48, 0.52, 0.58)
```

### Notas para modelado
- **Canopy denso**: el jugador NO ve el techo de caverna ni el diamante. Solo vislumbres esporádicos a través de agujeros en el follaje. Esto crea el contraste con el P1: de apertura total a cierre total.
- **Hongos gigantes** (2-3m de alto): estan en las variantes Hailuo. Son emission cian (~0.8 energy), material StandardMaterial3D con albedo `#2A4845` + emission `#7ECFD8`. Funcionan como PUNTOS DE REFERENCIA en el laberinto (el jugador dice "estoy cerca del hongo grande azul").
- **Telarañas**: mesh plano semi-transparente entre troncos. Partículas de polvo. Hazard: ralentiza 50% speed por 3s al cruzar.
- **Plantas carnívoras**: mesh en el suelo, cerradas cuando el jugador está lejos. Animation: se abren y atacan cuando el jugador entra a 4m (mordida, DoT leve). Duermen si no las provocás.
- **Árbol doble**: el landmark es un árbol con DOS TRONCOS que se unen en la base, con el nido anidado entre ambos a 15m. El nido es visible desde toda el área.
- **Luciérnagas**: MultiMesh con emission dorada, path random, más densas en zonas de sombra.
- **Niebla baja**: fog ground shader o partículas grandes al nivel del suelo.

### Aceptado de la imagen canon (Gemini)
- Árbol doble monumental con nido arriba ✅
- Luciérnagas doradas como puntos de luz ✅
- Hongos bioluminiscentes al pie del árbol (azulados) ✅
- Niebla entre los árboles ✅
- Composición centrada en el landmark ✅
- Tono melancólico Frieren ✅

### Aceptado de las variantes (Hailuo)
- Hongos gigantes cian dominantes — válidos como elemento del bioma bosque ✅
- Pueden ser usados para zonas del P2 más profundas (sub-dungeon "Madriguera del Lobo Blanco" zona exterior)

### NO copiar
- Las variantes Hailuo no muestran el nido en el árbol — el nido es obligatorio como landmark.
- La imagen Gemini no muestra telarañas ni plantas carnívoras — esos elementos se agregan en el modelado 3D, no eran parte del prompt original.

---

## P3 — Las Ruinas del Peregrino

**Imagen canon**: `game/docs/refs/p3_ruinas_peregrino/canon_main.jpg` (Hailuo panorámica)
**Imagen secundaria**: `canon_closeup.png` (close-up del altar)
**Escala**: ~300×300m

### Paleta
```
#E0C58A  piedra cálida (dominante)
#5C7A34  musgo verde denso sobre piedra
#F8D878  dorado suave de los god rays del techo
#A8D4E8  azul claro emisivo del fantasma de La Hermana Olvidada
#C8E4F0  mariposas azules casi blancas
#5C4530  sombras profundas de nichos y cámaras
```

### Lighting Godot
```
DirectionalLight3D:
  rotation_degrees: Vector3(-80, -10, 0)   # casi vertical, god rays fuertes
  light_energy: 2.8
  light_color: Color(0.97, 0.85, 0.47)     # #F8D878

WorldEnvironment:
  ambient_light_color: Color(0.55, 0.50, 0.40)  # ambient cálido piedra
  ambient_light_energy: 0.35
  fog_enabled: true
  fog_density: 0.004
  fog_light_color: Color(0.75, 0.70, 0.58)      # polvo dorado en el aire
```

### Notas para modelado
- **God rays**: este piso tiene el MEJOR uso de god rays de las 10 imágenes. Referencia maestra para implementar volumétricos en Godot. Los rayos caen casi verticales entre columnas rotas, con polvo flotando en los haces.
- **Fantasma de La Hermana Olvidada**: PointLight3D azul suave (`#A8D4E8`, energy 1.2, rango 4m) + shader ghost (albedo semi-transparente, rim light, sutil distorsión). Aparece solo si el jugador deja ofrenda en el altar.
- **Estatua monumental**: mesh grande (~8-10m de alto), peregrino encapuchado sentado mirando hacia arriba, cubierto de musgo (vertex painting o textura blend). Ofrendas al pie (monedas, flores secas, libro cerrado).
- **Mariposas gris-azuladas**: MultiMesh con animation subtle, solo en este piso (distintas a las de otros pisos = identidad visual propia).
- **Columnas rotas, arcos caídos, baldosas sueltas**: terreno irregular, varios niveles de altura, pasadizos semi-colapsados que el jugador puede caminar si se agacha.

### Aceptado de la imagen canon
- Estatua gigante del peregrino encapuchado ✅✅
- Fantasma azul claro de La Hermana Olvidada ✅✅ (el Retirado del P3 está DENTRO de la imagen sin haberlo pedido explícitamente)
- Ofrendas en el altar ✅
- God rays fuertes entre columnas rotas ✅
- Musgo cubriendo todo ✅
- Mariposas azul claro ✅

### NO copiar
- Nada — esta imagen es canon al 100%. Usarla como referencia directa.

---

## P4 — El Paso del Mercader

**Imagen canon**: `game/docs/refs/p4_paso_mercader/canon_main.png`
**Imagen rechazada**: la primera variante de Hailuo (composición débil, sin drama narrativo)
**Escala**: ~400×200m (lineal — el camino define la forma, no un cuadrado)

### Paleta
```
#C0A88C  piedra clara de las colinas del paso
#8C6A44  tierra cálida del camino
#F0C898  cielo pastel del piso
#3C2824  banderas oscuras de bandidos
#6B4028  caballo marrón
#484442  armadura caída (gris oscuro)
#7A8B5A  vegetación de las colinas
```

### Lighting Godot
```
DirectionalLight3D:
  rotation_degrees: Vector3(-65, -40, 0)   # más lateral que P1 — tarde, sombras largas
  light_energy: 3.0
  light_color: Color(0.94, 0.78, 0.60)     # #F0C898 — tarde cálida

WorldEnvironment:
  ambient_light_color: Color(0.60, 0.55, 0.48)
  ambient_light_energy: 0.45
  fog_enabled: true
  fog_density: 0.003
  fog_light_color: Color(0.85, 0.78, 0.65)
```

### Notas para modelado
- **Forma lineal**: este piso NO es cuadrado. Es un paso angosto (200m ancho × 400m largo) entre dos cadenas de colinas rocosas. El camino principal va de E a W; los desvíos van a N (campamento bandido) y S (cueva con cascada).
- **Carreta volcada**: mesh detallado — ruedas, mercadería tirada, cofres abiertos. 5 estados visuales por seed (sana, emboscada, rota, masacrada, pidiendo material).
- **Banderas de bandidos**: mesh plano con shader de viento (waving), texture con calavera simple, montadas en postes en las colinas del fondo.
- **Cadáveres**: mesh estáticos de NPCs armados tirados en el suelo. SIN sangre visible, SIN heridas gráficas. Solo cuerpos vestidos caídos. Esto cumple el brief: tensión moral suave, no grimdark gore.
- **Caballo del mercader**: mesh de caballo pastando libre (no tiene dueño si el mercader fue emboscado).
- **Cascada al sur**: marca la entrada a la sub-dungeon "Cueva de los Lobos del Paso" (entrada por detrás de la cascada).

### Aceptado de la imagen canon
- Paso angosto entre colinas rocosas ✅
- Carreta volcada con restos de pelea ✅
- Banderas de bandidos en las colinas del fondo ✅
- Caballo pastando libre ✅
- Cascada visible ✅
- Cadáveres sin gore ✅
- Paleta cálida tarde ✅

### NO copiar
- Los cadáveres de la imagen son bastante detallados — en low-poly serían más simples (silueta clara pero sin detalle facial).

---

## P5 — El Claro del Fuego Solitario

**Imagen canon día**: `game/docs/refs/p5_claro_fuego/canon_day.jpg`
**Imagen canon noche**: `game/docs/refs/p5_claro_fuego/canon_night.jpg`
**Escala**: ~100×100m (la intimidad es el punto)

### Paleta (día)
```
#F5B048  dorado cálido del fuego (centro emocional)
#F5DC5C  puntos luciérnaga dorados
#6B8B3A  verde hierba iluminada
#5C84A0  azul del estanque
#5C3C20  marrón troncos apilados
#A898A0  piedra pálida de la pérgola
#D8C890  tierra dentro del domo de luz
```

### Paleta (noche)
```
#F8B850  dorado fuego más saturado (calor vs frío)
#1C3044  azul oscuro del bosque nocturno (contraste)
#F0D870  puntos dorados luciérnagas densas (domo brillante)
#4A7236  verde pasto iluminado por el fuego
#6B5038  marrón del bardo y el tronco
```

### Lighting Godot (ciclo día/noche, ~3-4 min por fase)
```
# Fase DÍA
DirectionalLight3D:
  light_energy: 2.0
  light_color: Color(0.92, 0.82, 0.60)
WorldEnvironment:
  ambient_light_color: Color(0.55, 0.60, 0.48)
  ambient_light_energy: 0.5

# Fase NOCHE (tween transition ~30s)
DirectionalLight3D:
  light_energy: 0.3                          # casi apagada
  light_color: Color(0.40, 0.45, 0.55)      # azulada tenue
WorldEnvironment:
  ambient_light_color: Color(0.12, 0.18, 0.27)  # azul oscuro bosque
  ambient_light_energy: 0.15

# En AMBAS fases — el fuego es constante:
PointLight3D (fogata):
  light_color: Color(0.96, 0.69, 0.28)     # #F5B048
  light_energy: 5.0
  omni_range: 8.0
  omni_attenuation: 1.8                     # caída fuerte para domo marcado
```

### Notas para modelado
- **Ciclo visual día/noche**: el piso tiene un ciclo corto (~3-4 min por fase) que alterna entre día (tonos dorados, pocas luciérnagas) y noche (bosque oscuro, domo denso de luciérnagas). Tween entre los dos sets de lighting. Esto está validado por las dos imágenes canon: la de día y la de noche son el MISMO claro en momentos distintos.
- **La Bardo de los Cabellos de Ceniza**: NPC sentada en un tronco caído. **Pelo blanco largo, túnica gris clara, figura delgada** — guiño directo a Frieren. Visible en ambas fases del ciclo. Toca lira con partículas musicales sutiles (notas doradas).
- **El Gato del Bardo**: mesh de gato atigrado dormido junto al fuego. No collide, no ataca, no tiene HP. Si el jugador intenta atacarlo → desaparece en humo y la Bardo deja de tocar (castigo emocional, no mecánico).
- **Zona de paz forzada**: en un radio de 20m del fuego, el jugador NO puede atacar — el arma se envaina automáticamente. Los enemigos que entren al radio se sientan o se alejan.
- **Estanque**: shader de agua simple con reflexión planar del fuego. Peces como MultiMesh con path circular.
- **Pérgola vieja**: mesh de piedra con columnas bajas, asientos tallados, enredaderas colgando. Cubierta de musgo.
- **Luciérnagas**: MultiMesh con emission dorada. Densidad variable: pocas en fase día, DOMO DENSO en fase noche.

### Aceptado de AMBAS imágenes canon
- Fogata central con leña apilada ✅
- La Bardo de pelo blanco tocando lira ✅✅ (guiño Frieren confirmado)
- Gato dormido junto al fuego ✅✅ (El Gato del Bardo Retirado presente)
- Estanque con peces ✅
- Pérgola de piedra con enredaderas ✅
- Luciérnagas formando domo ✅
- Contraste día/noche como ciclo visual ✅

### NO copiar
- La Bardo de la imagen diurna tiene pelo castaño (contradice la versión nocturna de pelo blanco). **Canon: pelo blanco** (es el guiño Frieren y es más memorable).

---

*Documento vivo. Se expande cuando se generen imágenes de los pisos 6-25, Tier II+, y bosses.*
