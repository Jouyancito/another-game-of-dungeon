# Sistema de Transiciones entre Pisos

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document
**Departamento**: Game Design

---

## Tabla de Contenidos

1. [Filosofia de Transicion](#1-filosofia-de-transicion)
2. [Dos Eras de Transporte](#2-dos-eras-de-transporte)
3. [Animacion de Transicion como Pantalla de Carga](#3-animacion-de-transicion-como-pantalla-de-carga)
4. [Forma de la Torre y los Pisos](#4-forma-de-la-torre-y-los-pisos)

---

## 1. Filosofia de Transicion

### El problema

La mayoria de juegos hacen esto: terminas un piso → pantalla negra → 3-4 segundos → apareces en el siguiente. Es funcional, pero ROMPE la inmersion. El jugador sale del mundo durante la carga.

### La solucion

La transicion entre pisos es un **momento narrativo jugable**. El jugador no "espera" — HACE algo. La animacion de transicion ES la pantalla de carga. Cuando la carga termina, la animacion termina. Si la carga es rapida, la animacion es corta. Si es lenta, la animacion tiene mas detalle.

### Principio clave

> La transicion le cuenta al jugador DONDE esta en la torre. Pisos civilizados = transporte seguro. Pisos profundos = lo desconocido.

---

## 2. Dos Eras de Transporte

### Era 1: Civilizacion (Pisos 1-50) — El Teletransportador

**Narrativa**: La civilizacion de aventureros ha explorado y cartografiado hasta el piso 50. Hay infraestructura: estaciones de teletransporte construidas por la Hermandad de Exploradores. Son seguras, confiables, y tienen un NPC operador.

**NPC: El Operador de Transporte**

Cada piso (1-50) tiene un **punto de transporte** visible: una plataforma con runas, cristales de energia, y un NPC que la opera.

Dialogos del Operador (variaciones):
- Pisos 1-10: "Bienvenido, aventurero. La plataforma esta lista. Tranquilo, estos pisos los tenemos bien mapeados."
- Pisos 11-20: "Preparate. Los pisos de adelante se ponen interesantes."
- Pisos 21-35: "Hmm... los reportes de los exploradores son preocupantes. Tene cuidado."
- Pisos 36-49: "Casi nadie vuelve de estos niveles. La plataforma funciona pero... la senal es inestable. Buena suerte."
- Piso 50 (ultimo con NPC): "Este es el ultimo puesto de la Hermandad. Despues de aca... nadie ha construido nada. Si seguis, estas solo."

**Visual de la plataforma (Pisos 1-50)**:
- Plataforma circular de piedra tallada con runas luminosas
- 4 pilares con cristales de energia en las esquinas
- Runas que brillan cuando se activa
- NPC de pie al costado con un uniforme de la Hermandad
- Estado de la plataforma DEGRADA con la profundidad:
  - Pisos 1-20: Impecable, cristales brillantes, runas nitidas
  - Pisos 21-35: Algunas grietas, un cristal roto reemplazado con uno improvisado
  - Pisos 36-49: Runas tenues, estructura dañada, cables/cadenas sosteniendo pilares
  - Piso 50: Medio destruida, el NPC esta nervioso, los cristales parpadean

**Mecanica**: El jugador se para en la plataforma → interactua (E) → el Operador activa → animacion de transicion.

---

### Era 2: Lo Desconocido (Pisos 51-100) — Los Portales

**Narrativa**: Pasado el piso 50, no hay civilizacion. No hay Hermandad. Los unicos accesos entre pisos son **portales naturales** — grietas en la realidad de la torre que nadie construyo. Aparecen solos. Nadie sabe por que.

**Visual del portal (Pisos 51-100)**:

Inspirado en los portales de Nether de Minecraft pero con identidad propia:

- **Marco**: No tiene marco construido. Es una RASGADURA en el espacio. Los bordes son irregulares, como si alguien hubiera desgarrado la realidad con las manos. Particulas flotan alrededor — fragmentos del piso siguiente asomandose.
- **Interior**: No es negro como el Nether portal. Es un REMOLINO de colores del bioma siguiente. Si el siguiente piso es Tundra, el portal tiene remolinos de blanco y azul con particulas de nieve saliendo. Si es Volcan, el portal irradia calor naranja.
- **Sonido**: Un zumbido grave que se intensifica al acercarse. Susurros que no se entienden. Diferente en cada piso.
- **Comportamiento**: El portal PULSA. Se expande y contrae como si respirara. Las particulas se aceleran cuando un jugador esta cerca.

**Progresion visual de los portales**:
- Pisos 51-65: Rasgadura mediana, relativamente estable, colores del bioma siguiente
- Pisos 66-80: Mas grande, inestable, distorsiona la vision alrededor (shader de distorsion)
- Pisos 81-95: Enorme, la distorsion afecta un radio de 10m, fragmentos de realidad flotando
- Pisos 96-99: El portal es tan grande que OCUPA una pared entera. La realidad alrededor se esta rompiendo.
- Piso 100: No hay portal. El piso se ABRE solo cuando el jugador derrota al ultimo guardian.

**Mecanica**: El jugador CAMINA hacia el portal. No hay interaccion (E). Al entrar, la animacion de transicion comienza. Es un acto de voluntad — el jugador elige entrar a lo desconocido.

---

### Tabla comparativa

| Aspecto | Era 1: Teletransportador (1-50) | Era 2: Portal (51-100) |
|---------|--------------------------------|----------------------|
| Quien lo construyo | La Hermandad de Exploradores | Nadie. Aparece solo. |
| Activacion | Interactuar (E) con NPC | Caminar hacia adentro |
| Sensacion | Seguro, controlado | Misterioso, aterrador |
| Visual | Plataforma con runas y cristales | Rasgadura en la realidad |
| Audio | Hum mecanico/magico, voz del NPC | Zumbido grave, susurros |
| Estado fisico | Se degrada con la profundidad | Crece e intensifica |
| Control del jugador | Puede hablar con NPC, prepararse | Entra o no entra, sin dialogo |
| Narrativa | "La civilizacion llego hasta aca" | "Nadie ha estado aca antes" |

---

## 3. Animacion de Transicion como Pantalla de Carga

### Principio: la animacion OCULTA la carga

No queremos pantalla negra. Queremos que el jugador VEA algo interesante mientras el siguiente piso se genera.

### Flujo tecnico

```
1. Jugador activa transicion (E en plataforma / camina al portal)
2. Comienza animacion de transicion (reproduccion en loop si es necesario)
3. En BACKGROUND: genera el siguiente piso (async)
4. Cuando la generacion termina: animacion transiciona al final
5. Fade-in al nuevo piso
```

### Animacion Era 1: Teletransporte

**Punto de vista**: Primera persona. El jugador NO se mueve.

**Secuencia** (duracion minima 2 seg, se estira si la carga tarda):

```
Segundo 0.0 - 0.3:   Las runas de la plataforma se encienden
                      Particulas suben desde el suelo (espiral)
                      El NPC se aleja un paso

Segundo 0.3 - 0.8:   Los cristales de los pilares disparan rayos de luz
                      hacia el centro (donde esta el jugador)
                      Luz creciente desde abajo
                      El mundo alrededor se desatura (focus en la luz)

Segundo 0.8 - 1.5:   La luz envuelve la pantalla completamente
                      Se ven las MANOS del jugador (modelo first-person)
                      levantandose para cubrirse los ojos
                      Destello blanco

Segundo 1.5 - CARGA: Pantalla blanca con particulas de energia moviendose
                      (loop infinito, liviano de renderear)
                      Texto sutil: nombre del piso + numero
                      Barra de progreso MUY sutil en la parte inferior
                      (opcional, se puede ocultar)

Cuando carga termina: Las particulas se disipan
                      El nuevo bioma aparece gradualmente (fade de blanco)
                      Las manos del jugador bajan
                      Sonido ambiental del nuevo bioma entra gradualmente
```

### Animacion Era 2: Portal

**Punto de vista**: Primera persona. El jugador CAMINA.

**Secuencia** (duracion minima 3 seg, se estira si la carga tarda):

```
Segundo 0.0 - 0.5:   El jugador empieza a caminar hacia el portal (auto)
                      La distorsion visual del portal crece
                      El sonido ambiental del piso actual se silencia
                      El zumbido del portal sube de volumen

Segundo 0.5 - 1.0:   Las MANOS del jugador entran al portal primero
                      Se ven envueltas en el color/energia del portal
                      El borde del portal pasa por la pantalla
                      (como cruzar una cortina de agua)

Segundo 1.0 - 1.5:   El jugador esta DENTRO del portal
                      Vision: tunel de energia con particulas
                      Los colores son los del BIOMA SIGUIENTE
                      Se ven fragmentos del siguiente piso flotando
                      (meshes LOD2 del bioma, borrosos)

Segundo 1.5 - CARGA: Dentro del tunel de energia (loop)
                      Las particulas fluyen HACIA el jugador
                      Fragmentos del bioma siguiente se hacen mas claros
                      Texto sutil: "Piso X" + nombre del bioma
                      El jugador siente que esta VIAJANDO

Cuando carga termina: El tunel se abre
                      La luz del nuevo bioma entra
                      Las manos del jugador salen del portal
                      El jugador emerge del otro lado
                      (el portal se cierra detras con un sonido de implosion)
                      Se puede mirar atras y ver la rasgadura cerrandose
```

### Caso especial: Piso 100

No hay portal. Despues de derrotar al ultimo guardian del piso 99:

```
El suelo se QUIEBRA bajo los pies del jugador.
Caida libre en primera persona.
Las manos del jugador se estiran intentando agarrarse de algo.
Fragmentos de roca caen junto al jugador.
Luz blanca desde abajo, creciendo.
El jugador cae en luz blanca.
Silence total — 1 segundo de blanco puro.
Fade-in: Santuario del Umbral. Marmol blanco. Silencio.
El jugador esta de pie. No hay señal de la caida.
```

---

### Assets requeridos para las transiciones

| Asset | Tipo | Descripcion |
|-------|------|-------------|
| Manos first-person | Mesh animado | Manos del jugador (por clase, diferentes guantes/colores) |
| Plataforma de transporte | Mesh + materiales | Plataforma con runas, 4 pilares, cristales. 3 variantes de deterioro. |
| NPC Operador | Mesh + rig basico | Humanoide con uniforme. No necesita animacion compleja — idle + gesto. |
| Portal rasgadura | Shader + particulas | No es un mesh — es un shader en un plano con particulas alrededor |
| Tunel de transicion | Shader fullscreen | Shader de post-process que crea el efecto tunel |
| Particulas de transporte | GPUParticles3D | Espiral de energia para la plataforma |
| Particulas de portal | GPUParticles3D | Fragmentos flotantes, distorsion, color del bioma |

---

## 4. Forma de la Torre y los Pisos

### La torre es CIRCULAR?

**Respuesta: la torre es circular por fuera, pero los pisos NO necesitan ser circulares.**

Pensalo asi: la torre (o abismo) tiene una estructura externa que es cilindrica — cuando la ves desde afuera (o desde la aldea), es un cilindro gigante que baja a la tierra. Pero DENTRO, los pisos son espacios magicos que no respetan la geometria externa. Un piso puede ser mas grande que la torre por fuera. Es parte del misterio.

**Referencia**: SAO Aincrad es un cilindro gigante, pero los pisos individuales son mundos completos que no caben fisicamente dentro. Nadie cuestiona esto — es magia de la torre.

### Forma RECOMENDADA para los pisos: Irregular organica (ni cuadrado ni circulo)

#### Por que NO cuadrado puro

- Se siente artificial y procedural (bordes rectos = "esto lo genero una computadora")
- Las esquinas son espacio desperdiciado — el jugador nunca va a las esquinas de un mapa cuadrado
- No tiene sentido narrativo: por que un espacio natural dentro de una torre seria cuadrado?

#### Por que NO circulo puro

- Dificil de dividir en chunks eficientes (los chunks son rectangulares por naturaleza)
- El heightmap es una grilla rectangular — un circulo desperdicia ~21% de la grilla (las esquinas)
- Los bordes curvos son mas caros de colisionar y renderizar
- El jugador choca con un "muro invisible curvo" que se siente raro

#### La solucion: BORDE ORGANICO sobre grilla cuadrada

```
Implementacion:
1. La grilla del piso es cuadrada (600x600m) para chunks y heightmap
2. Se genera un BORDE IRREGULAR usando Perlin noise sobre un circulo base
3. El borde es visible como: pared de roca, abismo, niebla impenetrable, barrera magica
4. El area jugable es ~70-80% de la grilla total (el resto es borde)
```

**Visual del borde por era**:

| Pisos | Borde visual | Por que |
|-------|-------------|---------|
| 1-20 | Paredes de roca natural con vegetacion | "Los limites de la caverna" |
| 21-40 | Paredes de roca + grietas con luz | "La torre se hace notar" |
| 41-60 | Abismo — el suelo se acaba | "No hay mas alla" |
| 61-80 | Niebla densa impenetrable | "Algo no te deja pasar" |
| 81-99 | Distorsion visual — la realidad se rompe | "El espacio termina" |
| 100 | Paredes de marmol perfectas (geometria exacta) | "Esto fue diseñado" |

### Por que esta solucion es la mejor

1. **Chunks cuadrados** (50x50m) para el sistema de carga → rendimiento optimo
2. **Borde organico** → se siente natural, no artificial
3. **Cada piso tiene forma diferente** → la seed controla el noise del borde → rejugabilidad
4. **El jugador nunca ve el borde cuadrado real** → solo ve el borde organico
5. **El area jugable es grande** pero no un cuadrado perfecto → exploracion interesante

### Forma visual del piso (vista aerea conceptual)

```
+------------------+
|  ████████████    |  ████ = area jugable (forma organica)
| ██████████████   |  .... = borde (roca/abismo/niebla)
|████████████████  |  +--+ = grilla real (invisible)
|█████████████████ |
| ████████████████ |
|██████████████████|
| █████████████████|
|  ████████████████|
|   ██████████████ |
|    ████████████  |
|     ██████████   |
+------------------+

No es un circulo perfecto.
No es un cuadrado.
Es ORGANICO — como una cueva real vista desde arriba.
```

### Generacion del borde

```
Algoritmo:
1. Centro del piso: (300, 300) en la grilla
2. Radio base: 250m (deja 50m de margen)
3. Para cada angulo (0-360, cada 1 grado):
   radio_en_angulo = radio_base + perlin_noise(angulo * frecuencia, seed) * amplitud
4. Amplitud: 30-60m (variacion del borde)
5. Frecuencia: 3-5 (cuantas "ondulaciones" tiene el borde)
6. Todo punto fuera del radio_en_angulo = borde (no jugable)
```

**Resultado**: cada piso tiene una forma unica, organica, que parece natural. Algunos pisos son mas anchos al norte, otros tienen peninsulas, otros tienen bahias. El jugador descubre la forma explorando.

### Excepciones de forma

| Tipo de piso | Forma | Razon |
|-------------|-------|-------|
| Pisos de boss | Arena circular o hexagonal, 100-150m de diametro | Combate enfocado, no exploracion |
| Pisos de descanso (taverna) | Pequeños (100-150m), forma ovalada | No hay mucho que explorar, es un respiro |
| Piso 50 (midpoint) | Forma normal PERO con una grieta enorme que lo divide en dos | Narrativa: "algo se rompio aqui" |
| Piso 100 (Santuario) | Cuadrado PERFECTO con simetria axial | Contraste: despues de 99 pisos organicos, la perfeccion geometrica es PERTURBADORA |
