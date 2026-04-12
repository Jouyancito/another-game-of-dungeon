# Sistema de Ecologia Procedural — Generacion Logica de Mapas

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document
**Departamento**: Game Design

---

## Tabla de Contenidos

1. [Filosofia: Por que Generacion Logica](#1-filosofia-por-que-generacion-logica)
2. [Variables Ambientales Base](#2-variables-ambientales-base)
3. [Sistema de Propagacion](#3-sistema-de-propagacion)
4. [Reglas Ecologicas](#4-reglas-ecologicas)
5. [Fuentes Ambientales (Features que Afectan el Entorno)](#5-fuentes-ambientales)
6. [Tabla de Vegetacion por Condiciones](#6-tabla-de-vegetacion-por-condiciones)
7. [Tabla de Terreno por Condiciones](#7-tabla-de-terreno-por-condiciones)
8. [Ejemplos Concretos de Emergencia](#8-ejemplos-concretos-de-emergencia)
9. [Pipeline de Generacion](#9-pipeline-de-generacion)
10. [Biomas como Presets Climaticos](#10-biomas-como-presets-climaticos)
11. [Micro-biomas Emergentes](#11-micro-biomas-emergentes)

---

## 1. Filosofia: Por que Generacion Logica

### El problema con la generacion random pura

Un generador que coloca arboles, rocas, y agua al azar produce mapas que se VEN procedurales. El jugador lo nota aunque no sepa por que. Cosas que delatan un mundo falso:
- Arboles al lado de lava
- Hielo al lado de un volcan sin transicion
- Agua estancada sin fuente que la alimente
- Desierto con arboles frondosos
- Nieve en una cueva caliente

### La solucion: condiciones ambientales como motor

En vez de colocar "arbol de pradera" porque el bioma es pradera, hacemos esto:

1. El generador crea la GEOGRAFIA primero (terreno, agua, grietas, fuentes de calor)
2. Cada punto del mapa calcula sus CONDICIONES AMBIENTALES (temperatura, humedad, luz, nutrientes)
3. La vegetacion, textura del suelo, y props se ELIGEN SOLOS segun las condiciones
4. El resultado es un mundo que se siente LOGICO — porque lo es

**Analogia**: No le decimos al mapa "sos una pradera, tene pasto". Le damos temperatura templada, humedad media, luz alta, y el pasto APARECE porque esas son las condiciones donde el pasto crece.

---

## 2. Variables Ambientales Base

Cada punto del mapa (resolucion: 1 valor cada 2x2 metros = grilla de 300x300 para un piso de 600x600m) tiene estas variables:

### Variables primarias

| Variable | Rango | Unidad conceptual | Que determina |
|----------|-------|-------------------|---------------|
| **Temperatura** | -20 a +60 | Grados conceptuales | Tipo de vegetacion, hielo/nieve, evaporacion |
| **Humedad** | 0 a 100 | Porcentaje | Vegetacion densa vs dispersa, agua, pantano |
| **Luz** | 0 a 100 | Porcentaje | Tipo de planta (sombra vs sol), bioluminiscencia |
| **Elevacion** | 0 a 100 | Metros sobre el piso base | Temperatura (baja 2 grados cada 10m), viento |
| **Nutrientes** | 0 a 100 | Fertilidad del suelo | Densidad de vegetacion, tamano de plantas |

### Variables derivadas (calculadas automaticamente)

| Variable | Formula | Que determina |
|----------|---------|---------------|
| **Viento** | Base del bioma + (Elevacion * 0.3) | Direccion de esporas, inclinacion de arboles |
| **Erosion** | (Viento * 0.4) + (Humedad * 0.3) + (Tiempo * 0.3) | Forma de rocas, profundidad de grietas |
| **Evaporacion** | Temperatura * 0.5 - Humedad * 0.2 | Charcos que se secan, bruma |
| **Presion** | Funcion de profundidad en la torre (piso * 0.5) | Densidad del aire, efectos en pisos profundos |

---

## 3. Sistema de Propagacion

### Como las condiciones se propagan por el mapa

Las variables no son estaticas — se PROPAGAN desde fuentes. Esto es lo que crea los gradientes naturales.

### Propagacion de temperatura

La temperatura se propaga con **difusion radial con atenuacion**:

```
Para cada fuente de calor/frio:
  influencia_en_punto = intensidad_fuente / (1 + distancia * factor_atenuacion)
  temperatura_punto += influencia_en_punto
```

**Factor de atenuacion por medio**:
- Aire abierto: 0.05 (el calor viaja lejos)
- Roca/tierra: 0.15 (el calor se disipa rapido en solido)
- Agua: 0.03 (el agua conduce bien el calor — un rio caliente calienta mucho alrededor)

**Ejemplo**: Un rio de lava (temperatura fuente: +200) con atenuacion 0.05 en aire:
- A 0m: +200 (mortal)
- A 5m: +200 / (1 + 5 * 0.05) = +160 (abrasador)
- A 20m: +200 / (1 + 20 * 0.05) = +100 (muy caliente)
- A 50m: +200 / (1 + 50 * 0.05) = +57 (calido)
- A 100m: +200 / (1 + 100 * 0.05) = +33 (templado-calido)

El resultado: vegetacion MUERE cerca de la lava, se vuelve seca a 20m, y recien a 50m+ aparece algo verde.

### Propagacion de humedad

La humedad se propaga desde fuentes de agua con **flood fill atenuado**:

```
Para cada fuente de agua:
  humedad_en_punto = humedad_fuente * max(0, 1 - (distancia / radio_maximo))
  
  Modificadores:
    - Cuesta abajo: humedad viaja MAS lejos (radio * 1.5)
    - Cuesta arriba: humedad viaja MENOS (radio * 0.5)
    - Viento a favor: humedad viaja mas lejos en esa direccion (radio * 1.3)
    - Temperatura alta: humedad se evapora mas rapido (radio * 0.7)
```

**Ejemplo**: Un lago (humedad fuente: 100, radio: 40m):
- A 0m (orilla): 100% — barro, juncos, agua
- A 10m: 75% — pasto alto, denso, flores
- A 20m: 50% — pasto normal, arbustos
- A 30m: 25% — pasto disperso
- A 40m+: 0% — condicion base del bioma

**Y si hay una grieta al lado del lago?** La grieta es terreno bajo → la humedad fluye hacia ella (cuesta abajo) → la grieta se llena de vegetacion DENSA. Exactamente lo que el usuario pidio.

### Propagacion de luz

La luz depende de la estructura del bioma:

- **Biomas "exteriores"** (Pradera, Sabana, Desierto): luz base 90-100% (la fuente de luz del techo ilumina todo)
- **Biomas "interiores"** (Cavernas, Catacumbas): luz base 10-20% (depende de fuentes puntuales)
- **Biomas "mixtos"** (Bosque, Selva): luz base 40-60% (filtrada por dosel)

La luz se bloquea por obstaculos:
- Arboles grandes: reducen luz 30% en su sombra
- Rocas/paredes: bloquean luz completamente
- Agua: refleja luz parcialmente, aumenta luz en las orillas

Donde hay POCA luz y MUCHA humedad → hongos bioluminiscentes, musgo, plantas de sombra.
Donde hay MUCHA luz y POCA humedad → pasto seco, rocas expuestas, cactus.

### Propagacion de nutrientes

Los nutrientes del suelo se acumulan por:
- **Cercania a agua**: +20 nutrientes base
- **Vegetacion muerta cercana**: +10 por cada prop de "arbol muerto" o "hojas caidas"
- **Distancia a roca expuesta**: roca = 0 nutrientes, se incrementa con distancia
- **Ceniza/lava enfriada**: +30 (suelos volcanicos son fertiles despues de enfriarse)

Nutrientes altos + humedad alta + luz media = JUNGLA
Nutrientes bajos + humedad baja + luz alta = DESIERTO/ROCA

---

## 4. Reglas Ecologicas

### Regla 1: Nada crece sin razon

Cada planta tiene condiciones minimas y optimas. Si las condiciones no se cumplen, la planta NO aparece. No hay excepciones.

### Regla 2: Transiciones siempre graduales

Nunca hay un corte abrupto entre "zona con pasto" y "zona sin pasto". Las condiciones son gradientes continuos, y la densidad de vegetacion sigue ese gradiente.

```
Gradiente ejemplo (alejandose de un lago en pradera):
Orilla:    [juncos densos] [barro] [agua]
5m:        [pasto alto + flores] [suelo humedo oscuro]
15m:       [pasto medio] [suelo normal]
25m:       [pasto disperso + rocas] [suelo seco]
40m:       [rocas + pasto ralo] [suelo arido]
60m+:      [solo rocas y tierra] [condicion base del bioma]
```

### Regla 3: Las features modifican su entorno

Un rio no solo ES agua — CAMBIA todo lo que esta alrededor:
- Erosion en las orillas (baja elevacion en un radio de 3-5m)
- Humedad propagada (vegetacion a los lados)
- Temperatura moderada (el agua enfria en biomas calidos, calienta en frios)
- Nutrientes depositados (suelo fertil en la llanura de inundacion)

### Regla 4: El clima del bioma es el DEFAULT, no la LEY

El bioma "Pradera" dice: temperatura 20, humedad 50, luz 90. Pero si hay un rio de lava cruzando la pradera (evento raro), la zona alrededor del rio tiene temperatura 100+, humedad 0, y la vegetacion MUERE ahi. La pradera se adapta a sus circunstancias.

### Regla 5: Causa y efecto visible

El jugador debe poder VER por que algo esta ahi:
- "Hay muchas plantas aca... ah, hay un arroyo al lado"
- "El pasto se acaba... es porque hay una grieta volcanica"
- "Hongos luminosos en esta cueva... esta humeda y oscura, tiene sentido"

Si el jugador puede deducir POR QUE el mundo se ve asi, el mundo se siente REAL.

---

## 5. Fuentes Ambientales

### Features que modifican las condiciones del mapa

Cada feature que el generador coloca es una FUENTE de condiciones ambientales:

#### Fuentes de calor

| Feature | Temperatura emitida | Radio de influencia | Notas |
|---------|--------------------|--------------------|-------|
| Rio de lava | +200 | 100m | Mata vegetacion a 20m, seca a 50m |
| Grieta volcanica | +120 | 40m | Mas pequeña, mas puntual |
| Geyser | +80 | 20m | Pulsos de vapor caliente |
| Fogata/forja | +40 | 10m | Artificial, pequeña |
| Cristal de luz (techo) | +15 | Piso entero | Global, la "luz del sol" de la torre |

#### Fuentes de frio

| Feature | Temperatura emitida | Radio de influencia | Notas |
|---------|--------------------|--------------------|-------|
| Glaciar | -60 | 80m | Enfria y seca el aire |
| Rio congelado | -30 | 30m | Lineal, afecta ambos lados |
| Cueva de hielo | -40 | 25m | Interior cerrado |
| Ventisca (zona) | -20 | Area variable | Se mueve, temporal |
| Sombra de estructura | -5 | Proyeccion de sombra | Sin sol directo |

#### Fuentes de humedad

| Feature | Humedad emitida | Radio de influencia | Notas |
|---------|----------------|--------------------|-------|
| Lago | +100 | 40m | Circular, la fuente mas comun |
| Rio | +90 | 25m a cada lado | Lineal, crea corredores verdes |
| Cascada | +100 | 30m | Circular + bruma que viaja con viento |
| Manantial | +80 | 15m | Pequeño, puntual |
| Pantano/agua estancada | +100 | 50m | Muy alta, toda la zona |
| Lluvia (zona) | +40 | Area del bioma | Constante en biomas lluviosos |
| Grieta con filtracion | +70 | 15m | Agua que sale de grieta = vegetacion alrededor |

#### Fuentes de luz

| Feature | Luz emitida | Radio | Notas |
|---------|------------|-------|-------|
| Cristal de techo (diamante) | 90-100 | Global | Simula sol, la pradera entera |
| Cristal de techo (roto) | 30-50, intermitente | Global | Pradera Marchita |
| Antorcha/farol | 60 | 8m | Puntual, castea sombras |
| Hongo bioluminiscente | 30 | 4m | Tenue, azulado |
| Cristales de cueva | 50 | 10m | Azul/rosa, Cavernas de Cristal |
| Lava | 40 | 15m | Luz roja/naranja, no "buena" para plantas |
| Nada | 0 | — | Oscuridad total (Catacumbas, Abismo) |

#### Fuentes de nutrientes

| Feature | Nutrientes | Radio | Notas |
|---------|-----------|-------|-------|
| Cercania a agua | +20 | 10m de cualquier agua | Suelo fertil |
| Ceniza volcanica (fria) | +30 | 20m de lava antigua | Volcanico = fertil a largo plazo |
| Compost/materia organica | +25 | 5m | Zonas con vegetacion muerta |
| Roca desnuda | 0 | — | Nada crece en piedra pura |
| Arena pura | 5 | — | Casi nada crece |
| Suelo del bosque | +40 base | Global en bosque | Hojarasca acumulada |

---

## 6. Tabla de Vegetacion por Condiciones

### Como funciona: el generador consulta esta tabla

Para cada punto de la grilla (cada 2x2m), el generador:
1. Lee las condiciones (temp, humedad, luz, nutrientes)
2. Busca en esta tabla que vegetacion puede crecer ahi
3. Elige aleatoriamente entre los candidatos con peso por "optimalidad"
4. Aplica densidad segun que tan OPTIMAS son las condiciones (mas optimo = mas denso)

### Vegetacion disponible

| Planta | Temp min-max | Humedad min-max | Luz min-max | Nutrientes min | Densidad max | Visual |
|--------|-------------|-----------------|-------------|----------------|-------------|--------|
| **Pasto corto** | 5-40 | 20-80 | 50-100 | 10 | Alta | Verde, bajo, comun |
| **Pasto alto** | 10-35 | 40-90 | 60-100 | 20 | Media-Alta | Verde oscuro, se mece |
| **Flores silvestres** | 10-30 | 30-70 | 60-100 | 30 | Baja | Colores varios, decorativo |
| **Arbusto** | 5-35 | 25-70 | 40-100 | 15 | Media | Verde, mediano |
| **Arbol deciduo** | 5-35 | 30-80 | 50-100 | 25 | Baja-Media | Grande, copa verde |
| **Arbol conífera** | -10-25 | 20-60 | 40-100 | 15 | Media | Triangular, verde oscuro |
| **Arbol tropical** | 20-45 | 60-100 | 70-100 | 30 | Media | Copa ancha, frondoso |
| **Musgo** | 0-25 | 50-100 | 0-40 | 10 | Alta | Verde oscuro, cubre superficies |
| **Hongos** | 0-25 | 60-100 | 0-30 | 20 | Media | Variados, sombra/humedad |
| **Hongos gigantes** | 5-20 | 70-100 | 0-20 | 30 | Baja | Bioluminiscentes, grandes |
| **Hongos bioluminiscentes** | 0-20 | 60-100 | 0-15 | 15 | Media | Emiten luz azul/rosa |
| **Juncos** | 5-35 | 80-100 | 40-100 | 15 | Alta (en agua) | Orillas de agua |
| **Nenufares** | 10-35 | 100 (en agua) | 50-100 | 10 | Media (en agua) | Sobre agua quieta |
| **Lianas/enredaderas** | 15-40 | 50-100 | 20-80 | 20 | Media | Cuelgan de arboles/paredes |
| **Cactus** | 25-55 | 0-20 | 70-100 | 5 | Baja | Zonas aridas, raro |
| **Pasto seco** | 15-45 | 5-30 | 60-100 | 5 | Media | Amarillo, sabana/desierto |
| **Plantas carnivoras** | 15-35 | 70-100 | 30-60 | 25 | Muy baja | Peligro! Pantano/selva |
| **Cristales (como "flora")** | -20-5 | 0-30 | 0-100 | 0 | Media | Mineral, no biologico |
| **Coral (subacuatico)** | 10-30 | 100 | 30-70 | 20 | Media | Color, subacuatico |
| **Enredaderas corrompidas** | 10-35 | 40-90 | 10-60 | 30+ corrupcion | Media | Rosa/purpura, retorcidas |

### Regla de densidad

```
densidad_final = densidad_max * factor_optimalidad

factor_optimalidad = promedio de:
  - que tan cerca esta la temperatura del RANGO OPTIMO (centro del rango)
  - que tan cerca esta la humedad del RANGO OPTIMO
  - que tan cerca esta la luz del RANGO OPTIMO
  - (nutrientes >= minimo? 1.0 : 0.0)
```

Ejemplo: Pasto corto (rango temp 5-40, optimo ~22)
- En un punto con temp=22, humedad=50, luz=75 → factor ~0.9 → densidad ALTA
- En un punto con temp=38, humedad=25, luz=90 → factor ~0.4 → densidad BAJA (pasto disperso)
- En un punto con temp=45, humedad=10, luz=95 → fuera de rango → densidad 0 (no hay pasto)

---

## 7. Tabla de Terreno por Condiciones

### Textura/material del suelo

El suelo NO es uniforme. Cambia segun las condiciones:

| Condicion | Textura de suelo | Color base | Shader |
|-----------|-----------------|-----------|--------|
| Humedad 80-100 + Temp > 15 | Barro | #5D4037 (marron oscuro) | Reflejo humedo (specular alto) |
| Humedad 80-100 + Temp < 5 | Hielo/escarcha | #B3E5FC (celeste) | Ice shader (fresnel blanco) |
| Humedad 50-80 + Nutrientes > 20 | Tierra fertil | #4E342E (marron rico) | Mate, con detalle de hojas |
| Humedad 30-50 | Tierra normal | #795548 (marron medio) | Mate estandar |
| Humedad 10-30 | Tierra seca | #A1887F (marron claro) | Mate, grietas |
| Humedad 0-10 + Temp > 30 | Arena | #FFE082 (dorado) | Sand scroll shader |
| Humedad 0-10 + Temp < 5 | Nieve | #FAFAFA (blanco) | Sparkle shader (brillo puntual) |
| Temp > 80 | Roca volcanica | #37474F (gris oscuro) | Rugoso, sin vida |
| Temp > 150 | Lava solidificada | #212121 (negro) con venas #FF6D00 | Emision en grietas |
| Nutrientes 0 + Roca | Piedra desnuda | #9E9E9E (gris) | Mate, duro |
| Bajo agua | Fondo acuatico | #1B5E20 (verde oscuro) | Causticas de agua |
| Corrupcion > 50 | Suelo corrompido | #4A148C (violeta oscuro) | Corruption pulse |

### Transiciones de suelo

El suelo transiciona entre texturas usando **vertex blending** (mezcla por vertice del mesh de terreno):

```
En cada vertice del terreno:
  - Lee las condiciones ambientales
  - Asigna peso a las 2-3 texturas mas cercanas
  - Blendea suavemente entre ellas
```

Resultado: el barro de la orilla del lago se MEZCLA gradualmente con la tierra normal, que se mezcla con tierra seca. Sin bordes duros.

---

## 8. Ejemplos Concretos de Emergencia

### Ejemplo 1: Grieta humeda en pradera

**Setup**: Pradera base (temp 20, humedad 40, luz 90). El generador coloca una grieta en el terreno. Un manantial emerge de la grieta (humedad +70, radio 15m).

**Resultado emergente**:
```
Lejos de grieta (30m+):  Pasto corto disperso, tierra normal
                          Pradera estandar, nada especial.

Acercandose (20m):        Pasto mas alto, mas denso
                          "Hmm, aca hay mas vida..."

Cerca (10m):              Pasto alto + flores + arbustos
                          Suelo oscuro (tierra fertil)
                          "Hay un arroyo por aca seguro"

En la grieta (0-5m):      Juncos, musgo en las paredes
                          Barro en el fondo, agua corriendo
                          Lianas si hay pared vertical
                          "Ah, sale agua de la grieta. Por eso hay tanta vegetacion."
```

**El jugador ENTIENDE por que la vegetacion esta ahi.** No le explicamos nada — lo VE.

### Ejemplo 2: Lava cruzando bosque

**Setup**: Bosque Denso (temp 15, humedad 60, luz 40). Un evento raro: un rio de lava cruza el piso (temp fuente +200, atenuacion en aire 0.05).

**Resultado emergente**:
```
Zona de lava (0-5m):      Roca volcanica negra, cero vegetacion
                          Ceniza flotando, particulas de brasa
                          Suelo con grietas de emision naranja

Zona muerta (5-20m):      Arboles MUERTOS (troncos calcinados, sin hojas)
                          Suelo gris ceniza, pasto inexistente
                          Calor visible (heat distortion shader)

Zona de transicion (20-40m): Arboles MARCHITOS (hojas amarillas/marrones)
                              Pasto seco y ralo
                              El suelo pasa de ceniza a tierra seca

Bosque normal (40m+):     Arboles verdes, musgo, hongos
                          El bosque sigue como si nada
```

**La historia se cuenta sola**: "La lava llego aca y mato todo a su paso. El bosque esta intentando recuperarse."

### Ejemplo 3: Cueva dentro de pradera

**Setup**: Pradera (temp 20, humedad 40, luz 90). Una cueva en una colina (luz interior 5, humedad interior 70 por filtacion).

**Resultado emergente**:
```
Entrada de cueva:          Pasto llega hasta el borde
                          Musgo empieza donde la luz baja
                          Transicion verde claro → verde oscuro

Interior cercano (luz 20-30): Musgo denso en paredes y suelo
                               Humedad alta → goteo de agua
                               Sin pasto (poca luz), solo musgo

Interior profundo (luz 0-10): Hongos bioluminiscentes (alta humedad + sin luz)
                               Musgo oscuro
                               Charcos en el suelo
                               Emision tenue azul/verde

Si la cueva conecta a volcanica: Hongos desaparecen cerca del calor
                                  Cristales minerales donde hay calor + mineral
                                  Transicion de humedo-frio a seco-caliente
```

### Ejemplo 4: Oasis en desierto

**Setup**: Desierto (temp 45, humedad 5, luz 95). Un manantial subterraneo (humedad +100, radio 25m).

**Resultado emergente**:
```
Desierto puro (30m+):     Arena, rocas, cactus muy dispersos
                          Cero vegetacion verde
                          Heat shimmer en el aire

Borde del oasis (20-25m): Pasto seco aparece
                          Arena se mezcla con tierra
                          Un cactus o dos

Oasis cercano (10-15m):   Pasto VERDE (contraste brutal con arena)
                          Arbustos, flores
                          Suelo oscuro fertil

Centro del oasis (0-5m):  Palmeras/arboles tropicales (alta temp + alta humedad)
                          Agua cristalina
                          Juncos, nenufares
                          El unico color verde en kilometros
```

**El contraste visual ES la narrativa**: un punto de vida en un mar de muerte.

### Ejemplo 5: Pantano con grieta volcanica

**Setup**: Pantano (temp 25, humedad 90, luz 30). Una grieta volcanica cruza (temp +120, radio 40m).

**Resultado emergente**:
```
Pantano normal:            Agua estancada, vegetacion densa, niebla verde
                          Hongos, juncos, arboles muertos con lianas

Cerca de grieta (20-30m): El agua se EVAPORA — bruma densa
                          Temperatura sube → vegetacion se reduce
                          Barro se seca → grietas en el suelo
                          Hongos mueren (demasiado calor)

Junto a grieta (5-15m):   Sin agua (evaporada), suelo seco/agrietado
                          Las unicas plantas: pasto seco resistente al calor
                          El pantano "se rompe" alrededor de la grieta
                          Contraste: agua estancada a 30m, polvo seco aca

En la grieta (0-5m):      Roca, lava, cero vida
                          Pero en la ORILLA de la grieta donde la humedad del
                          pantano se encuentra con el calor: VAPOR constante
                          → un microclima unico
```

---

## 9. Pipeline de Generacion

### Orden de operaciones (paso a paso)

El generador de un piso sigue ESTE orden. No se puede alterar la secuencia.

```
PASO 1: SEED
  └─ Input: numero de piso + seed del run
  └─ Output: seed unica para este piso

PASO 2: BIOMA BASE
  └─ Input: seed + rango de piso + adyacencia (bioma anterior)
  └─ Output: bioma seleccionado → condiciones base globales
  └─ Ejemplo: "Pradera Interior" → temp=20, humedad=40, luz=90, nutrientes=25

PASO 3: HEIGHTMAP (terreno base)
  └─ Input: seed + parametros del bioma (montañoso? plano? cavernoso?)
  └─ Output: grilla de elevacion 300x300 (cada celda = 2x2m)
  └─ Algoritmo: Perlin noise multicapa con parametros por bioma:
     - Pradera: amplitud baja (colinas suaves)
     - Montaña/Tormenta: amplitud alta (picos)
     - Caverna: heightmap invertido (techo) + suelo

PASO 4: FEATURES GEOLOGICAS
  └─ Input: heightmap + seed
  └─ Output: rios, lagos, grietas, cuevas, acantilados
  └─ Logica: el agua fluye cuesta abajo (A* sobre heightmap invertido)
  └─ Los rios se forman donde se acumula "flujo" de agua virtual

PASO 5: FEATURES ESPECIALES (segun bioma)
  └─ Input: seed + bioma
  └─ Output: fuentes de calor (lava), fuentes de frio (glaciar), etc.
  └─ Estas SON las fuentes ambientales que modifican el mapa

PASO 6: CALCULAR CONDICIONES AMBIENTALES
  └─ Input: condiciones base + features + heightmap
  └─ Output: grilla 300x300 con (temp, humedad, luz, nutrientes) por celda
  └─ Proceso:
     1. Inicializar toda la grilla con condiciones base del bioma
     2. Aplicar modificacion por elevacion (temp baja con altura)
     3. Propagar calor/frio desde fuentes (difusion)
     4. Propagar humedad desde fuentes de agua (flood fill)
     5. Calcular luz (global - obstrucciones)
     6. Calcular nutrientes (cercania a agua + materia organica)
  └─ Iteraciones de propagacion: 3-5 pasadas para convergencia

PASO 7: VEGETACION
  └─ Input: grilla de condiciones + tabla de vegetacion
  └─ Output: instancias de vegetacion colocadas en el mapa
  └─ Para cada celda de la grilla:
     1. Consultar tabla de vegetacion (que puede crecer aca?)
     2. Filtrar por condiciones minimas
     3. Elegir con peso (mas optimo = mas probable)
     4. Aplicar densidad segun optimalidad
     5. Randomizar posicion dentro de la celda (2x2m) con jitter

PASO 8: TEXTURA DE SUELO
  └─ Input: grilla de condiciones + tabla de terreno
  └─ Output: vertex colors / splatmap del terreno
  └─ Para cada vertice del mesh de terreno:
     1. Consultar tabla de terreno
     2. Asignar blend weights a las 3 texturas mas relevantes
     3. Smooth con vecinos para evitar bordes duros

PASO 9: PROPS Y POIs
  └─ Input: seed + bioma + heightmap + condiciones
  └─ Output: colocacion de props (rocas, ruinas, cofres) y POIs
  └─ Los props tambien respetan condiciones:
     - Rocas: en zonas de baja humedad/nutrientes
     - Ruinas: en zonas planas (no en pendiente)
     - Cofres: en POIs, no en medio de la nada
     - Fogatas: en zonas protegidas (cerca de paredes/rocas)

PASO 10: ENEMIGOS
  └─ Input: seed + bioma + condiciones + POIs
  └─ Output: spawn points de enemigos
  └─ Los enemigos aparecen donde tiene SENTIDO:
     - Lobos: en manada, en zonas abiertas (pradera/sabana)
     - Arañas: en zonas oscuras, cerca de paredes
     - Slimes: en zonas humedas
     - Esqueletos: en ruinas, catacumbas

PASO 11: ILUMINACION
  └─ Input: bioma + features + vegetacion
  └─ Output: luces colocadas + parametros de ambiente
  └─ Pre-bake o lightmap donde sea posible
```

### Performance del generador

| Paso | Costo | Timing |
|------|-------|--------|
| 1-3 (seed, bioma, heightmap) | Bajo | < 50ms |
| 4-5 (features) | Medio | < 100ms |
| 6 (condiciones) | Alto (propagacion iterativa) | < 500ms |
| 7-8 (vegetacion + suelo) | Alto (90,000 celdas) | < 1s |
| 9-10 (props + enemigos) | Bajo | < 100ms |
| 11 (iluminacion) | Medio | < 200ms |
| **Total** | — | **< 2 segundos** |

Esto se ejecuta durante la transicion entre pisos (pantalla de carga). 2 segundos es invisible para el jugador.

---

## 10. Biomas como Presets Climaticos

### El bioma NO define el contenido — define las CONDICIONES BASE

Cada bioma es simplemente un SET de condiciones globales. El contenido EMERGE de esas condiciones.

| Bioma | Temp base | Humedad base | Luz base | Nutrientes base | Resultado emergente |
|-------|-----------|-------------|----------|----------------|-------------------|
| Pradera Interior | 20 | 40 | 90 | 25 | Pasto, flores, arboles dispersos, colinas |
| Bosque Denso | 15 | 60 | 40 | 40 | Arboles densos, musgo, hongos donde no hay luz |
| Tundra Congelada | -10 | 15 | 70 | 5 | Nieve, hielo, coniferas raras, cristales |
| Volcan Activo | 50 | 10 | 60 | 10 | Roca negra, lava, cero vegetacion excepto ceniza fertil lejos |
| Pantano Putrefacto | 25 | 90 | 30 | 35 | Agua, juncos, hongos, arboles muertos, niebla |
| Cavernas de Cristal | 8 | 40 | 20 | 5 | Cristales (como "flora"), musgo, hongos bioluminiscentes |
| Desierto Abrasador | 45 | 5 | 95 | 3 | Arena, cactus, rocas, cero vegetacion excepto oasis |
| Selva Tropical | 30 | 80 | 50 | 45 | Todo crece, todo es verde, lianas, denso |
| Catacumbas | 12 | 25 | 5 | 0 | NADA crece. Piedra, hueso, polvo. La oscuridad es total. |
| Sabana Seca | 35 | 15 | 90 | 10 | Pasto seco, acacias dispersas, rocas |
| Bosque de Hongos | 12 | 85 | 10 | 35 | Hongos gigantes DOMINAN (condicion perfecta para ellos) |
| Oceano Sumergido | 15 | 100 | 40 | 20 | Coral, algas, subacuatico. Reglas diferentes. |
| Jardin Corrompido | 18 | 55 | 45 | 40 (+ corrupcion) | Plantas normales PERO retorcidas. El nutriente esta envenenado. |

### Por que esto es poderoso

Porque el mismo sistema genera contenido DIFERENTE dependiendo del contexto:

**Condiciones: temp 20, humedad 80, luz 40, nutrientes 35**
- En un Bosque Denso: produce musgo, hongos, arboles con lianas → se ve como bosque humedo
- En un Oceano Sumergido (plataformas secas): produce la misma vegetacion → las ruinas sobre agua tienen musgo y hongos. LOGICO.
- En una Cueva de Pradera: produce musgo y hongos en la cueva → el jugador entiende que la cueva esta humeda

**El sistema no sabe que bioma es.** Solo sabe las condiciones. Y el resultado SIEMPRE tiene sentido.

---

## 11. Micro-biomas Emergentes

### Que son

Cuando las features crean condiciones que no coinciden con el bioma base, emergen **micro-biomas**: zonas pequeñas con ecologia propia.

### Catalogo de micro-biomas emergentes

| Condicion | Micro-bioma | Donde aparece | Visual |
|-----------|-------------|---------------|--------|
| Agua + Calor (cerca de lava) | Termas | Volcan, Forja | Vapor, algas termales, rocas humedas |
| Agua + Frio extremo | Lago congelado | Tundra, Cavernas | Superficie de hielo, peces debajo |
| Grieta + Humedad | Jardin de grieta | Cualquiera | Vegetacion densa en fisura, musgo |
| Sombra de estructura + Humedad | Cueva de musgo | Pradera, Sabana | Musgo denso, hongos, goteo |
| Ceniza + Humedad (post-volcan) | Suelo fertil nuevo | Volcan, Ceniza | Brotes verdes en ceniza negra |
| Hielo derritiendose + Pendiente | Arroyo de deshielo | Tundra, Montaña | Agua corriendo entre nieve |
| Oscuridad total + Humedad | Gruta bioluminiscente | Cavernas, Catacumbas | Hongos brillantes, azul/rosa |
| Viento fuerte + Arena | Duna | Desierto, Sabana | Arena acumulada, patron de olas |
| Agua estancada + Calor | Burbuja de vapor | Pantano, Selva | Niebla densa, visibilidad cero |
| Nutrientes altos + Luz alta + Humedad alta | Claro del bosque | Bosque, Selva | Flores, mariposas (particulas), arboles frondosos |

### Por que importan

Los micro-biomas son lo que hacen que cada run se sienta UNICO. El jugador ve cosas como:

- "Esta pradera tiene un arroyo que no estaba la vez pasada" → diferente seed, diferente heightmap, el agua fluyo diferente
- "Hay hongos brillantes en esta grieta" → la grieta genero humedad y oscuridad, condiciones perfectas
- "Este volcan tiene una zona verde!" → la ceniza vieja se volvio fertil, un manantial aparecio

Cada run cuenta una historia ambiental diferente. Sin que escribamos NI UNA LINEA de narrativa.

---

## Apendice: Parametros Expuestos para Balance

Estos valores se exponen como `@export` para ajustar sin tocar codigo:

```gdscript
## Propagacion
@export var heat_attenuation_air: float = 0.05
@export var heat_attenuation_rock: float = 0.15
@export var heat_attenuation_water: float = 0.03
@export var humidity_falloff_flat: float = 1.0
@export var humidity_falloff_downhill: float = 1.5
@export var humidity_falloff_uphill: float = 0.5
@export var humidity_evaporation_factor: float = 0.7
@export var propagation_iterations: int = 5

## Vegetacion
@export var vegetation_density_multiplier: float = 1.0
@export var tree_spacing_min: float = 4.0  # metros entre arboles
@export var grass_density_per_cell: int = 8  # instancias por celda 2x2m
@export var optimality_threshold: float = 0.3  # minimo para que algo crezca

## Terreno
@export var terrain_blend_sharpness: float = 2.0
@export var mud_humidity_threshold: float = 80
@export var snow_temperature_threshold: float = 0

## Chunks
@export var chunk_size: float = 50.0  # metros
@export var chunk_load_radius: float = 150.0
@export var chunk_unload_radius: float = 200.0
@export var chunk_preload_direction: bool = true
```
