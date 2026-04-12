# Direccion de Arte — Dungeon Party

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document — Decisiones Concretas
**Departamento**: Game Design + Art & VFX

---

## Tabla de Contenidos

1. [Filosofia Visual](#1-filosofia-visual)
2. [Pipeline de Renderizado](#2-pipeline-de-renderizado)
3. [Presupuesto de Poligonos](#3-presupuesto-de-poligonos)
4. [Teoria de Color y Contraste](#4-teoria-de-color-y-contraste)
5. [Atmosferas: Como se Siente Cada Lugar](#5-atmosferas-como-se-siente-cada-lugar)
6. [Sistema de Iluminacion](#6-sistema-de-iluminacion)
7. [Shaders Requeridos](#7-shaders-requeridos)
8. [Identidad Visual por Bioma](#8-identidad-visual-por-bioma)
9. [Progresion Visual de la Torre](#9-progresion-visual-de-la-torre)
10. [Guia de Rendimiento](#10-guia-de-rendimiento)

---

## 1. Filosofia Visual

### Principio rector

**Low-poly estilizado con shaders expresivos**. Un modelo de 200 poligonos con un buen shader se ve MEJOR que uno de 5000 sin shader. El estilo comunica mas que la fidelidad.

### Referencia de estilo

El look objetivo es una mezcla de:
- **Kimetsu no Yaiba (Demon Slayer)**: LA referencia principal de contraste. Fondos oscuros/nocturnos con explosiones de color HIPER saturado en las tecnicas de respiracion. Negro profundo + cian/naranja/rojo brillante. Esto es exactamente como queremos que se vea el combate magico: entornos atmosfericos con habilidades que EXPLOTAN en color. Las marcas de las tecnicas de respiracion (agua, fuego, rayo) son el modelo para los trails de habilidades de nuestras clases.
- **Risk of Rain 2**: siluetas claras, colores saturados, readability en combate
- **Genshin Impact (simplificado)**: cell shading suave, colores vibrantes por zona, transiciones de bioma fluidas
- **Valheim**: low-poly que se siente handcrafted, no "barato". Texturas planas pero con personalidad
- **Windbound**: organico, warm lighting, formas simples pero elegantes

### Leccion de Kimetsu para nuestro juego

El anime Demon Slayer enseña una leccion de arte que vale ORO:

**El contraste entre fondo y accion es lo que hace que el combate se sienta EPICO.**

En Kimetsu:
- La noche es NEGRA — sin grises, sin compromisos
- Las tecnicas de respiracion son LUMINOSAS — agua celeste, fuego naranja, rayo amarillo
- El resultado: cada ataque se siente como una explosion visual

En Dungeon Party aplicamos esto asi:
- Los biomas Siniestros y Hostiles tienen fondos OSCUROS y desaturados
- Las habilidades de clase tienen colores BRILLANTES con trail effects
- El contraste entre bioma y habilidad escala con la dificultad:
  - Pisos 1-20: fondo colorido + habilidades coloridas = festivo, divertido
  - Pisos 40-60: fondo gris + habilidades coloridas = "soy la unica luz aca"
  - Pisos 80+: fondo NEGRO + habilidades NEON = Kimetsu puro, epicidad maxima

**Color de habilidades por clase** (inspirado en respiraciones de Kimetsu):
| Clase | Color primario | Color secundario | Referencia Kimetsu |
|-------|---------------|-----------------|-------------------|
| Warrior | Naranja fuego | Rojo | Respiracion del Sol (Hinokami Kagura) |
| Mage | Cian/azul electrico | Blanco | Respiracion del Agua (Tanjiro) |
| Archer | Verde lima | Amarillo | Respiracion del Viento |
| Necromancer | Violeta oscuro | Rosa muerto | Respiracion de la Luna (Kokushibo) |
| Healer | Dorado calido | Blanco puro | Respiracion del Sol (purificacion) |

### Lo que NO somos
- **No somos Minecraft**: nada de bloques, nada de pixelado intencional
- **No somos realistas**: sin PBR complejo, sin texturas 4K, sin fotorrealismo
- **No somos flat/mobile**: hay profundidad, hay sombras, hay atmosfera. No es un juego de celular

### Regla de oro
> Si al jugador le dan ganas de quedarse mirando el paisaje antes de pelear, el arte esta funcionando.

---

## 2. Pipeline de Renderizado

### Godot 4.6 — Forward+ Renderer

Se usa **Forward+** (no Compatibility, no Mobile). Razones:
- Soporta luces volumetricas, GI, y post-processing completo
- Performance superior a Vulkan clustered para escenas con pocas luces dominantes
- Los pisos de 600x600m necesitan distance fog y LOD nativos

### Cadena de materiales

Todos los materiales del juego usan esta base:

```
StandardMaterial3D
├── albedo_color: color plano (sin textura en la mayoria de los casos)
├── roughness: 0.7-0.9 (mate, no plastico)
├── metallic: 0 (excepto metales explícitos: armas, armaduras)
├── shading_mode: per-pixel
└── cull_mode: back
```

**Excepciones que usan ShaderMaterial (custom shader)**:
- Agua (transparencia + movimiento)
- Follaje (viento + alpha cutout)
- Lava/magma (emision + scroll UV)
- Efectos magicos (emision + fresnel)
- Cristales (refraccion simplificada)

### Por que NO usamos texturas UV en la mayoria de modelos

- Los modelos low-poly con **vertex color** o **color plano por material** son mas baratos que texturas
- Menos draw calls (un material vs un material + textura)
- Mas facil de iterar (cambiar color = cambiar un valor, no re-pintar una textura)
- La identidad visual viene de la FORMA y el COLOR, no del detalle de textura

**Excepcion**: terreno, props grandes (ruinas, edificios), y items especiales si usan texturas — pero tileadas (repetibles), nunca unicas por modelo.

---

## 3. Presupuesto de Poligonos

### Por categoria de asset

| Categoria | Triangulos max | Ejemplo |
|-----------|---------------|---------|
| Jugador (cuerpo) | 1,500 - 2,500 | Capsula humanoid, low-poly pero con silueta reconocible |
| Jugador (arma) | 200 - 500 | Espada, baston, arco — forma clara, sin adornos 3D |
| Enemigo comun | 500 - 1,500 | Slime (200), lobo (800), esqueleto (1,200) |
| Enemigo mini-boss | 2,000 - 4,000 | Golem, hidra — mas detalle porque esta en pantalla mas tiempo |
| Boss de piso | 5,000 - 10,000 | El Arquitecto, Dragon — justifica detalle |
| Prop pequeño | 50 - 200 | Roca, arbusto, pocion, cofre |
| Prop mediano | 200 - 800 | Arbol, pilar, estatua, tienda |
| Prop grande | 800 - 2,000 | Edificio, ruina grande, altar |
| Terreno (chunk) | 5,000 - 10,000 | Chunk de 50x50m del heightmap |

### Presupuesto total por frame

**Target**: maximo **200,000 triangulos** visibles por frame.

Desglose tipico:
- Terreno visible: ~40,000 tris
- Props y vegetacion: ~80,000 tris (con instancing)
- Enemigos (10-15 en pantalla): ~15,000 tris
- Jugadores (6 max): ~15,000 tris
- Efectos (particulas, beams): ~10,000 tris
- HUD 3D (armas en mano): ~2,000 tris
- Headroom para picos: ~38,000 tris

Esto corre a **60 FPS en hardware medio** (GTX 1060 / RX 580 equivalente).

---

## 4. Teoria de Color y Contraste

### Principios de color

#### A. Saturacion como indicador de profundidad en la torre

La torre usa la saturacion como lenguaje visual SUBCONSCIENTE:

| Rango de pisos | Saturacion | Sensacion | Ejemplo |
|----------------|------------|-----------|---------|
| 1-20 (Early) | Alta (70-100%) | Vibrante, acogedor, "todo va a estar bien" | Pradera: verdes vivos, cielo azul |
| 21-50 (Mid) | Media (40-70%) | Tensión creciente, seriedad | Catacumbas: violeta apagado, grises |
| 51-80 (Late) | Baja-Media (30-60%) | Hostil, "no deberias estar aqui" | Abismo: azules oscuros, negros |
| 81-100 (Endgame) | Mixta: desaturada con acentos HIPER saturados | Surreal, final | Vacio: negro + purpura BRILLANTE |

**Por que funciona**: el cerebro humano asocia colores vivos con seguridad (naturaleza, sol) y desaturacion con peligro (tormenta, noche). Usamos eso.

#### B. Temperatura de color como indicador de hospitalidad

| Temperatura de color | Significado | Uso |
|---------------------|-------------|-----|
| Calido (naranja, dorado, amarillo) | Seguridad, descanso, hogar | Tavernas, safe zones, POIs amigables |
| Neutro (verde, beige, gris claro) | Exploracion, neutral | Praderas, bosques, caminos |
| Frio (azul, violeta, gris oscuro) | Peligro, hostilidad, misterio | Dungeons, biomas hostiles, zonas de boss |
| Rojo/magenta saturado | PELIGRO INMEDIATO | Trampas, ataques de boss, zonas de danio |

#### C. Contraste de lectura (readability en combate)

El jugador SIEMPRE debe poder distinguir:
1. **Suelo vs vacio** — contraste minimo de 40% luminosidad
2. **Enemigo vs fondo** — silueta clara, outline si es necesario
3. **Proyectil amigo vs enemigo** — colores OPUESTOS (azul amigo, rojo enemigo)
4. **Loot en el suelo** — brillo/emision para que resalte del entorno
5. **Zona de danio vs zona segura** — rojo/naranja pulsante para danio, sin efecto para seguro

**Regla de 3 capas de lectura**:
```
Capa 1 (fondo):    colores muted/desaturados — no compite por atencion
Capa 2 (gameplay):  colores medios — enemigos, jugadores, props interactivos
Capa 3 (feedback):  colores BRILLANTES — danio, loot, alertas, UI diegetica
```

#### D. Paleta maestra del juego

Colores que aparecen en TODO el juego, independientemente del bioma:

| Elemento | Color | Hex | Uso |
|----------|-------|-----|-----|
| HP del jugador | Rojo sangre | #C62828 | Barra de vida, danio recibido |
| MP del jugador | Azul arcano | #1565C0 | Barra de mana, habilidades magicas |
| XP | Dorado ambar | #FF8F00 | Barra de experiencia, level up |
| Danio fisico | Blanco-amarillo | #FFF9C4 | Numeros de danio fisico |
| Danio magico | Cian brillante | #00E5FF | Numeros de danio magico |
| Curacion | Verde esmeralda | #2E7D32 | Numeros de heal, efectos de cura |
| Loot Comun | Blanco | #FFFFFF | Nombre del item |
| Loot Raro | Azul | #2196F3 | Nombre del item |
| Loot Magico | Amarillo dorado | #FFD600 | Nombre del item + resplandor |
| Loot Unico | Rojo vino | #880E4F | Nombre del item + aura |
| Interaccion | Blanco con outline | #FFFFFF | "Presiona E", prompts |
| Peligro ambiental | Rojo pulsante | #FF1744 | Zonas de danio, trampas activas |

---

## 5. Atmosferas: Como se Siente Cada Lugar

### Categorias de atmosfera

Cada bioma cae en UNA de estas 5 atmosferas. La atmosfera define iluminacion, audio, y feel general.

---

### ACOGEDOR — "Hogar antes de la tormenta"

**Sensacion**: Seguridad temporal. El jugador baja la guardia, explora con calma, se prepara. Como llegar a una fogata en Dark Souls, pero es un bioma entero. Hay vida, hay luz, hay color. Pero sabemos que no dura.

**Iluminacion**: Luz direccional calida (sol/diamante), sombras suaves, golden hour permanente. Ambient light alta — pocas zonas oscuras.

**Sonido**: Pajaros, viento suave, agua corriendo. Musica en tonos mayores, melodica, con instrumentos acusticos (guitarra, flauta).

**Movimiento ambiental**: Pasto mecido por viento, nubes lentas, particulas de polen flotando. Todo se mueve LENTO y SUAVE.

**Colores dominantes**: Verdes calidos, dorados, azul cielo. Saturacion ALTA.

**Biomas en esta categoria**:
- Pradera Interior (pisos 1-15)
- Sabana Seca (pisos 5-25) — version "calida" del acogedor
- Tavernas/Pisos de descanso

**Cuando el jugador entra**: "Ah, que lindo. Puedo respirar." — y ESO es el punto. Que el contraste con lo que viene despues sea BRUTAL.

---

### MISTERIOSO — "Algo me observa"

**Sensacion**: Curiosidad mezclada con incomodidad. No es peligroso todavia, pero algo no esta bien. El jugador quiere explorar pero mira sobre el hombro. La belleza del lugar es SOSPECHOSA.

**Iluminacion**: Luz indirecta (bioluminiscencia, hongos, cristales). Sin fuente de luz obvia "natural". Sombras de color (no negras: azuladas, verdosas, violetas). Niebla de color suave.

**Sonido**: Goteo de agua, crujidos lejanos, melodias ambientales que aparecen y desaparecen. Eco. Sonidos que no podemos identificar. Musica en tonos menores, lenta, con pads sinteticos.

**Movimiento ambiental**: Esporas flotando, niebla rodando, luces que parpadean. Movimiento organico, LENTO pero CONSTANTE. Cosas que se mueven en la periferia de tu vision.

**Colores dominantes**: Purpuras, azules profundos, verdes bioluminiscentes. Saturacion MEDIA con acentos brillantes.

**Biomas en esta categoria**:
- Bosque Denso
- Cavernas de Cristal
- Bosque de Hongos Gigantes
- Oceano Sumergido
- Selva Tropical
- Laboratorio Arcano

**Cuando el jugador entra**: "Esto es hermoso... pero por que siento que algo me mira?" — la tension no viene del peligro, viene del MISTERIO.

---

### HOSTIL — "Sobrevivi"

**Sensacion**: Agresion ambiental constante. El bioma MISMO es un enemigo. El jugador no explora — AVANZA con urgencia. Cada segundo que pasas ahi, el ambiente te castiga. La victoria es SALIR.

**Iluminacion**: Luz extrema (lava, hielo brillante) o minima (oscuridad). Alto contraste. Sombras duras y negras. Efectos de particulas que afectan visibilidad (ceniza, nieve, arena). No hay golden hour — hay EMERGENCIA.

**Sonido**: Viento violento, crujidos estructurales, rugidos lejanos. Musica agresiva: percusion tribal, cuerdas disonantes, o SILENCIO total (que es peor). El audio dice "andate de aca".

**Movimiento ambiental**: Particulas agresivas (ceniza, nieve, arena, brasas). El terreno se mueve (lava, plataformas, derrumbes). RAPIDO y CAOTICO.

**Colores dominantes**: Rojos, naranjas (calor) o blancos frios, grises (frio). Saturacion BAJA excepto en fuentes de danio (lava roja brillante, hielo azul brillante). El fondo es monocromatico, el peligro tiene COLOR.

**Biomas en esta categoria**:
- Tundra Congelada
- Volcan Activo
- Desierto Abrasador
- Forja Infernal
- Plataformas del Cielo/Tormenta
- Playa de Ceniza/Tierras Muertas

**Cuando el jugador entra**: "Mierda. Vamos rapido." — y cuando sale: "No quiero volver ahi." Pero va a tener que hacerlo.

---

### SINIESTRO — "No deberia estar vivo"

**Sensacion**: Horror psicologico. No hay jumpscares — hay TENSION. El ambiente te dice que algo terrible paso aca. Los muertos estan inquietos. La realidad se siente fragil. El jugador avanza porque parar es PEOR.

**Iluminacion**: OSCURIDAD como mecanica. El jugador ilumina su propio camino (antorcha, hechizo). La oscuridad no es "ausencia de luz" — es PRESENCIA de algo. Luces que se apagan. Sombras que se mueven solas. Iluminacion intermitente.

**Sonido**: Susurros, risas lejanas, pasos que no son los tuyos. Musica MINIMA — drones graves, notas aisladas de piano, o silencio total roto por sonidos puntuales. El audio es el arma principal del horror.

**Movimiento ambiental**: POCO movimiento excepto cosas que NO deberian moverse (estatuas que cambian de posicion, sombras con movimiento propio). La quietud es el horror. Particulas: ceniza, esporas violetas, manos etéreas.

**Colores dominantes**: Negros, grises hueso, violetas espectrales. Desaturacion EXTREMA. Los unicos puntos de color son las fuentes de peligro (ojos rojos, fuego espectral verde, auras moradas). El contraste viene de LUZ vs OSCURIDAD, no de color.

**Biomas en esta categoria**:
- Pantano Putrefacto
- Catacumbas/Necropolis
- Jardin Corrompido
- Abismo Abismal/Profundidades
- Pradera Marchita (late-game)

**Cuando el jugador entra**: "No. No no no." — el bioma te dice "date la vuelta", y no podes. Esa impotencia ES la experiencia.

---

### SURREAL — "Esto no es real"

**Sensacion**: Confusion controlada. Las reglas del mundo que el jugador aprendio ya no aplican. La geometria es incorrecta. Los colores estan "mal". El cerebro no puede procesar lo que ve. No es miedo — es DESORIENTACION.

**Iluminacion**: Sin fuente de luz identificable. Todo esta iluminado "desde adentro" o "desde ninguna parte". Colores de luz imposibles (magenta, cian). Sombras que van en la direccion equivocada. Bloom agresivo en puntos focales.

**Sonido**: Reverb infinito, sonidos al reves, melodias familiares pero a velocidad o tono incorrecto. El audio de biomas anteriores pero DISTORSIONADO. Musica: ambient experimental, glitch, sonidos granulares.

**Movimiento ambiental**: Geometria que rota, plataformas que aparecen/desaparecen, cielo que se mueve como liquido. Particulas que van HACIA ARRIBA. Gravedad visual incorrecta. El mundo respira.

**Colores dominantes**: Negro vacio con acentos HIPER saturados (purpura cosmico, cian neon, magenta). O colores "normales" pero INVERTIDOS (cielo rojo, pasto azul). La paleta es INESTABLE — puede cambiar durante el nivel.

**Biomas en esta categoria**:
- Dimension Astral/Vacio
- Mundo Espejo/Realidad Invertida
- Templo del Reloj/Dominio Temporal
- Santuario del Umbral (piso 100)

**Cuando el jugador entra**: "...que?" — la confusion ES la atmosfera. El jugador debe ADAPTARSE para sobrevivir.

---

## 6. Sistema de Iluminacion

### Fuentes de luz por atmosfera

| Atmosfera | Luz principal | Ambient | Sombras | Fog |
|-----------|--------------|---------|---------|-----|
| Acogedor | DirectionalLight3D (sol calido, 5500K) | Alta, warm (0.3-0.4) | Soft, 50% opacidad | Distance fog dorado, 100m+ |
| Misterioso | OmniLight3D puntuales (bioluminiscencia) | Baja, fria (0.1-0.2) | Colored (azul/verde), soft | Volumetric fog de color, 20-40m |
| Hostil | DirectionalLight3D duro + emisiones | Media, extrema (calida O fria) | Hard, alto contraste | Particle fog (ceniza/nieve), 30-60m |
| Siniestro | Player torch (unica fuente movil) | Muy baja (0.02-0.05) | Duras, casi negras | Oscuridad como fog, 5-10m |
| Surreal | Sin fuente (ambient puro) | Media, multicolor | Invertidas o ausentes | Bloom como fog, infinito |

### Transiciones entre biomas

Cuando el jugador cambia de piso (y potencialmente de bioma), la transicion visual toma **3-5 segundos**:
1. Fade a negro (0.5s)
2. Carga del nuevo bioma (invisible al jugador)
3. Fade desde negro con la nueva iluminacion (0.5s)
4. La niebla se ajusta gradualmente (2-3s) — no es instantanea

### Ciclo dia-noche

**No hay ciclo dia-noche**. Cada piso tiene su iluminacion FIJA. Razones:
- Dentro de una torre/abismo, no tiene sentido
- La consistencia visual permite optimizar shaders y pre-bake de luz
- Cada bioma tiene su propia "hora del dia" congelada:
  - Pradera: golden hour permanente (tarde)
  - Tundra: amanecer frio
  - Volcan: noche roja
  - Catacumbas: medianoche

---

## 7. Shaders Requeridos

### Shaders core (usados en todos los biomas)

#### 1. Cell Shading (Toon Shader)

El shader mas importante del juego. Define el estilo visual entero.

**Que hace**: Reduce la gradacion de luz a 2-3 bandas de color (iluminado, sombra, penumbra) en vez del gradiente continuo de PBR.

**Parametros**:
- `shade_steps`: 2 (hard) o 3 (soft) — por atmosfera
- `shade_color`: color de la sombra (NO negro — usa el complementario desaturado del albedo)
- `outline_width`: 0.002-0.004 (solo para personajes y enemigos, NO para terreno)
- `outline_color`: negro o color del bioma

**Donde se aplica**: TODOS los personajes, enemigos, y props interactivos.
**Donde NO se aplica**: terreno, cielo, particulas, agua.

#### 2. Outline Shader (borde)

**Que hace**: Dibuja un contorno alrededor de modelos 3D para mejorar readability.

**Metodo**: Inverted hull (escala el modelo un poco y renderiza solo la cara trasera en color solido). Es BARATO.

**Donde se aplica**: jugadores (siempre), enemigos (siempre), loot en suelo (con glow), props interactivos (cuando el cursor esta encima).

#### 3. Wind Shader (vegetacion)

**Que hace**: Mueve vertices de vegetacion simulando viento. Basado en vertex Y (mas arriba = mas movimiento).

**Parametros**: frecuencia, amplitud, direccion del viento (por bioma).

**Donde se aplica**: pasto, arboles, arbustos, flores. Solo en biomas con vegetacion.

#### 4. Fresnel / Rim Light

**Que hace**: Agrega un halo de luz en los bordes de modelos, dando profundidad y separacion del fondo.

**Donde se aplica**: personajes (sutil), loot (brillante), objetos magicos (intenso).

### Shaders por bioma (solo se cargan cuando el bioma esta activo)

| Shader | Biomas | Que hace |
|--------|--------|----------|
| Water surface | Oceano, Pantano, Selva | Reflexion planar simplificada + scroll UV + transparencia |
| Lava flow | Volcan, Forja | Emision + scroll UV doble (capas a diferente velocidad) + distorsion calor |
| Ice/frost | Tundra | Fresnel fuerte (blanco), roughness baja, transparencia parcial |
| Crystal refraction | Cavernas de Cristal | Refraccion simplificada (screen space) + emision interna |
| Corruption pulse | Jardin Corrompido | Colores que pulsan entre normal y "equivocado", patron noise |
| Void dissolve | Dimension Astral, Vacio | Dissolve shader con noise + emision en bordes |
| Time distortion | Templo del Reloj | Screen-space distorsion (zonas lentas/rapidas) |
| Fog volumetric | Bosque, Pantano, Catacumbas | WorldEnvironment fog + density map por bioma |
| Bioluminescence | Hongos, Oceano, Abismo | Emision pulsante (sine wave en intensidad) |
| Sand scroll | Desierto | Scroll UV en suelo simulando viento de arena |
| Desaturation post | Pradera Marchita, Ceniza | Post-process que desatura progresivamente |

### Shaders de feedback (siempre activos)

| Shader | Uso |
|--------|-----|
| Damage flash | Modelo parpadea rojo 0.1s al recibir danio |
| Heal flash | Modelo parpadea verde 0.1s al curarse |
| Death dissolve | Modelo se disuelve al morir (noise + alpha) |
| Loot glow | Items en suelo pulsan con color de rareza |
| Interaction highlight | Props interactivos brillan cuando estas en rango |

---

## 8. Identidad Visual por Bioma

### Clasificacion completa

| # | Bioma | Atmosfera | Paleta | Luz dominante | Shader especial | Sensacion en 3 palabras |
|---|-------|-----------|--------|---------------|-----------------|------------------------|
| 1 | Pradera Interior | Acogedor | Verde esmeralda, dorado, azul cielo | Sol calido (golden hour) | Wind, fog dorado | Libertad, esperanza, calma |
| 2 | Bosque Denso | Misterioso | Verde oscuro, purpura biolum., gris | Bioluminiscencia filtrada | Fog volumetrico, wind | Claustrofobia, belleza oculta |
| 3 | Cavernas de Cristal | Misterioso | Azul cristal, rosa cuarzo, negro | Cristales emisivos | Crystal refraction, biolum. | Asombro, fragilidad, eco |
| 4 | Pantano Putrefacto | Siniestro | Verde toxico, marron fango, amarillo | Niebla verdosa difusa | Water, fog, corruption | Asco, trampa, desesperacion |
| 5 | Tundra Congelada | Hostil | Blanco, azul hielo, gris tormenta | Amanecer frio difuso | Ice/frost, fog blanco | Soledad, frio, supervivencia |
| 6 | Volcan Activo | Hostil | Rojo magma, negro, naranja | Lava emisiva + particulas | Lava flow, heat distortion | Urgencia, calor, destruccion |
| 7 | Ruinas Antiguas | Misterioso | Beige, gris piedra, verde musgo | Filtraciones de luz cenital | Dust particles | Nostalgia, peligro oculto, historia |
| 8 | Desierto Abrasador | Hostil | Dorado arena, naranja, terracota | Sol abrasador directo | Sand scroll, heat distortion | Sed, inmensidad, espejismo |
| 9 | Oceano Sumergido | Misterioso | Azul profundo, turquesa, verde alga | Causticas de agua + biolum. | Water, bioluminescence | Ahogo, maravilla, profundidad |
| 10 | Plataformas del Cielo | Hostil | Gris tormenta, purpura, blanco rayo | Rayos intermitentes | Void dissolve, lightning | Vertigo, electricidad, caida |
| 11 | Selva Tropical | Misterioso | Verde lima, esmeralda, amarillo flor | Luz filtrada por dosel | Wind, water, rain particles | Vida salvaje, humedad, emboscada |
| 12 | Forja Infernal | Hostil | Naranja metal, gris acero, rojo | Emission de metal caliente | Lava flow (para metal) | Mecanica, aplastamiento, calor |
| 13 | Catacumbas | Siniestro | Negro, gris hueso, violeta | Antorchas puntuales (jugador) | Fog oscuro, flicker | Terror, silencio, muertos |
| 14 | Jardin Corrompido | Siniestro | Rosa corrupto, verde toxico, purpura | Emision incorrecta (colores "mal") | Corruption pulse | Belleza enferma, engano, locura |
| 15 | Dimension Astral | Surreal | Negro vacio, purpura cosmico, cian | Ambient multicolor sin fuente | Void dissolve, gravity fx | Desorientacion, infinito, vacio |
| 16 | Abismo Abismal | Siniestro | Negro abisal, azul tenue, verde bio | Bioluminiscencia escasa | Biolum., oscuridad extrema | Presion, demencia, profundidad |
| 17 | Ciudad Abandonada | Siniestro | Gris piedra, marron madera, negro | Faroles apagados, luna fria | Fog urbano, flicker | Soledad, fantasmas, emboscada |
| 18 | Bosque de Hongos | Misterioso | Azul biolum., rosa, purpura | Hongos emisivos | Bioluminescence, spore particles | Alienigena, suave, respiracion |
| 19 | Templo del Reloj | Surreal | Dorado reloj, bronce, azul/rojo | Engranajes emisivos | Time distortion zones | Destiempo, mecanica, paradoja |
| 20 | Playa de Ceniza | Hostil | Gris ceniza, negro, rojo brasa | Brasas lejanas, sin sol | Desaturation post, ash particles | Fin del mundo, vacio, ceniza |
| 21 | Mundo Espejo | Surreal | Desaturado del bioma reflejado + tinte violeta | Hereda invertido | Mirror effect, desaturation | Deja-vu, incorrectness, trampa |
| 22 | Laboratorio Arcano | Misterioso | Azul arcano, dorado runico, purpura | Conductos magicos emisivos | Magic particles, unstable glow | Conocimiento prohibido, inestabilidad |
| 23 | Pradera Marchita | Siniestro | Gris ceniza, verde apagado, negro | Diamante roto (luz intermitente) | Desaturation post | Nostalgia rota, muerte, vacio |
| 24 | Santuario del Umbral | Surreal | Blanco marmol, negro, dorado divino | Ambient perfecto (sin fuente) | Perfection shader (sin noise) | Juicio, perfeccion, final |
| 25 | Sabana Seca | Acogedor | Amarillo paja, naranja, azul cielo | Sol de atardecer | Wind, grass sway | Extension, peligro visible, calor seco |

---

## 9. Progresion Visual de la Torre

### El viaje emocional del color

La torre cuenta una historia VISUAL. El jugador no necesita que le digan que la torre se vuelve mas peligrosa — lo VE.

```
Pisos 1-20:    COLORES VIVIDOS     ████████████████████  Verdes, dorados, azules
                                    La vida. El comienzo. "Puedo hacer esto."

Pisos 21-40:   COLORES EN TENSION  ████████████████████  Purpuras, marones, grises con acentos
                                    La duda. Las sombras crecen. "Esto se complica."

Pisos 41-60:   COLORES APAGADOS    ████████████████████  Grises, negros, rojos apagados
                                    La resistencia. Todo es gris. "No quiero seguir."

Pisos 61-80:   OSCURIDAD           ████████████████████  Negros, violetas, azules profundos
                                    El abismo. La oscuridad total. "Estoy perdido."

Pisos 81-99:   COLORES IMPOSIBLES  ████████████████████  Negros + neon (purpura, cian, magenta)
                                    Lo surreal. La realidad se rompe. "Esto no es real."

Piso 100:      BLANCO Y NEGRO ORO  ████████████████████  Marmol, obsidiana, oro divino
                                    La perfeccion. El juicio final. "Soy digno."
```

### Transiciones de color criticas

| Momento | Transicion visual | Impacto emocional |
|---------|-------------------|-------------------|
| Piso 1 → Piso 2 | Saturacion baja un 5% | Imperceptible, pero el subconsciente lo nota |
| Piso 10 (primer boss) | Arena con iluminacion dramatica, contraste alto | "Esto es serio" |
| Piso 20 → 21 | Caida de saturacion notable (10-15%) | "Las cosas cambiaron" |
| Piso 50 (midpoint twist) | Glitch visual de 1 segundo al cambiar de piso | "Algo se rompio" |
| Piso 75 (Pradera Marchita) | Reconoce la Pradera del piso 1 pero GRIS | "No... esto era mi lugar seguro" |
| Piso 90+ | Colores neon sobre negro absoluto | "Estoy en otro mundo" |
| Piso 100 | Blanco absoluto, silencio, luego oro | "El final" |

---

## 10. Guia de Rendimiento

### Targets de FPS

| Hardware | FPS target | Calidad sugerida |
|----------|-----------|------------------|
| GTX 1060 / RX 580 (minimo) | 60 FPS estable | Medium: fog reducido, LOD agresivo, sin SSAO |
| RTX 2060 / RX 5700 (recomendado) | 60 FPS estable | High: fog completo, LOD normal, SSAO |
| RTX 3070+ (alto) | 60+ FPS | Ultra: todo habilitado, draw distance maxima |

### Tecnicas de optimizacion obligatorias

#### LOD (Level of Detail)
- **LOD 0** (0-30m): modelo completo
- **LOD 1** (30-80m): 50% triangulos
- **LOD 2** (80-200m): 25% triangulos
- **LOD 3** (200m+): billboard/impostor (textura 2D que mira a la camara)

#### Instancing (MultiMeshInstance3D)
Todo lo que se repite mas de 10 veces en un piso usa instancing:
- Pasto, arboles, rocas, hongos, cristales, columnas, escombros
- **Un draw call** para 1,000 copias del mismo mesh

#### Occlusion Culling
- Habilitado globalmente en Project Settings
- Los biomas interiores (cavernas, catacumbas, forja) se benefician MAS
- Los biomas exteriores (pradera, sabana) se benefician de distance fog como culling visual

#### Chunk Loading (para pisos de 600x600m)
- El piso se divide en chunks de 50x50m (144 chunks total)
- Solo se cargan los chunks en un radio de 150m del jugador (aprox. 28 chunks)
- Los chunks se pre-cargan en la direccion de movimiento del jugador
- Los chunks se descargan cuando el jugador esta a +200m

#### Shader LOD
Los shaders caros (water, crystal refraction, time distortion) se desactivan a distancia:
- **Full shader**: 0-50m
- **Simplified shader**: 50-100m (sin refraccion, sin scroll UV)
- **Flat color**: 100m+ (solo albedo + ambient)

### Lo que NUNCA se hace
- GI en tiempo real (pre-bake siempre, o LightmapGI para interiores)
- Sombras dinamicas para MAS de 8 luces por escena
- Transparencia en mas del 15% de los pixeles visibles (alpha sort es caro)
- Physics en objetos decorativos (solo gameplay-critical)
- Pathfinding en mas de 30 agentes simultaneos por chunk

---

## Apendice: Checklist de Asset para Artistas

Antes de entregar un asset al pipeline, verificar:

- [ ] Triangulos dentro del presupuesto de su categoria
- [ ] Material usa StandardMaterial3D con color plano (no textura) o vertex color
- [ ] Si usa textura: es tileable, resolucion maxima 512x512 (256x256 preferido)
- [ ] Tiene LOD 0 y al menos LOD 1 (50% tris)
- [ ] Silueta legible a 30m de distancia
- [ ] Cell shader se ve bien aplicado (verificar shade_steps)
- [ ] Outline no clip con la geometria
- [ ] No tiene n-gons, no tiene caras sueltas, normals correctas
- [ ] Scale aplicado (1 unit = 1 metro en Godot)
- [ ] Pivot point en la base del modelo (para placement)
