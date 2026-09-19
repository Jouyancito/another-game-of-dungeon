# wolf — lobo, cuadrúpedo predador de manada (2026-08-22)

**Pedido de Joan**: *"saca referencias de internet si es necesario, primero parte por las
referencias, lobos de skyrim, red dead 2"*.

**Investigación TEXTUAL, no visual.** No puedo ver imágenes de la web: lo que sigue son
**medidas reales y specs construibles**, que es lo que el KB manda producir en research web.
Las capturas de Skyrim/RDR2 las tiene que anexar Joan — quedan como hueco declarado abajo.

## Medidas reales — para modelar a escala, no a ojo

| Magnitud | Rango real | Valor a usar |
|---|---|---|
| Alzada a la cruz | 66–84 cm | **0,80 m** (macho grande) |
| Largo cabeza+cuerpo | 102–183 cm | **1,40 m** |
| Cola | 29–50 cm | **0,45 m** |
| Orejas | 9–11 cm | **0,10 m** |
| Pie trasero | 22–25 cm | **0,24 m** |
| Peso | 23–68 kg | 55 kg (informa la masa, no la malla) |

Contra el poste de 1,80 m: **el lomo del lobo llega a la altura de la entrepierna del
jugador**. Es un animal grande, pero NO llega a la cintura — la tentación es hacerlo demasiado
alto para que imponga. Si hace falta que imponga, se sube la escala EXPLÍCITAMENTE y se anota,
como se hizo con el golem (4,0 m).

## Forma / silueta
- **Caja torácica grande y profunda**, que desciende bien abajo — es la masa principal.
- **Lomo en declive** desde la cruz hacia la grupa. No es una línea horizontal.
- **Cuello muy musculado**, más grueso de lo que se cree: casi tan ancho como el cráneo.
- **Patas proporcionalmente MÁS LARGAS que las de otros cánidos** — es la firma del lobo frente
  al perro; con patas cortas se lee como pastor alemán.
- **Orejas chicas y triangulares.** Erguidas. Orejas grandes = zorro, no lobo.
- Hocico largo, más angosto en hembras.
- Ojo con el **error digitígrado** (KB, cheat-sheet de criaturas): la rodilla trasera que
  apunta hacia atrás es el TOBILLO; la rodilla real va alta y metida contra el cuerpo.

## Qué capturar
1. **Alzada 0,80 m** — verificada contra el poste de 1,80 m en el showcase.
2. **Lomo en declive + tórax profundo**: es lo que lo separa de un perro genérico.
3. **Patas largas**, no rechonchas.
4. **Orejas chicas y triangulares.**
5. Cola densa, llevada baja en reposo.

## Encaje con el canon
`_bestiary_visual_bible.md` §3 lo clasifica como **cuadrúpedo** (cola y orejas marcan el rol:
el lobo carga, el zorro hurta) y §5 tabla lo marca **pack re-skin**, con el argumento de que un
script bpy no hace anatomía curva ni ciclo de caminar. Ese canon es de 2026-07-03 y **la
práctica posterior lo superó**: `build_rat.py`, `build_snake.py`, `build_turtle.py`,
`build_wasp.py` y `build_bird.py` son orgánicos bespoke que sí existen. La decisión
pack-vs-bespoke para el lobo queda ABIERTA para Joan; esta ficha sirve para las dos vías.
Color según §2: pelaje desaturado, **ojos como acento**.
El bestiario pone el lobo tercero en la cola de fichas: **golem → bandido → lobo**.

## Hueco declarado
- ⌛ **Faltan capturas de Skyrim y RDR2** — las pidió Joan y no puedo bajarlas. Sin ellas esta
  ficha tiene medidas y anatomía pero NO tiene el registro de estilo (cuán peludo, cuán
  estilizado, qué tan oscuro). Anexarlas a esta carpeta antes de construir el pelaje.

**Fuente/fecha**: medidas de dimensions.com, Britannica, National Wildlife Federation y
Washington Dept. of Fish & Wildlife, consultadas 2026-08-22.
