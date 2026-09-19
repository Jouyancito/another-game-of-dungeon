# rock_poe — la roca estilizada que el piso 1 necesita

Pasadas por Joan el 2026-08-08 mirando el `rock_showcase` del pack actual: *"con el rock_pack
me pasa algo similar, son rocas genéricas, el estilo PoE no se nota en ellas, Path of Exile"*.

## La causa raíz, en una línea

**El generador sólo sabe hacer bultos.** `rock_pack` desplaza vértices con Perlin isótropo a lo
largo de la normal (doble capa ridge + detail). Ese operador, por construcción, produce una
superficie continuamente ondulada — una papa. Nunca produce un plano.

Y el estilo que Joan pide es **exactamente lo contrario**: caras PLANAS grandes que se cortan
en ARISTAS NETAS. Ninguna cantidad de tuneo de frecuencia o amplitud lo alcanza, porque no es
un problema de parámetro sino de operador. Hace falta **descomposición planar**: cortar el
volumen con planos, conservar las facetas rectas, y recién después perturbar apenas para que
no se lea como cristal.

## Diff contra el estado actual

| Eje | Hoy (`rock_showcase.png`) | Referencia | Acción |
|---|---|---|---|
| Silueta | Bulto redondeado; `large_boulder` es un huevo facetado | Masas apiladas, columnas quebradas, cuñas inclinadas | Cortes con plano + apilado de bloques, no una sola masa |
| Forma | Ruido isótropo continuo | Caras planas grandes, aristas vivas | `bisect` por planos / bevel de aristas duras |
| Estratificación | Ausente | Capas sedimentarias horizontales, splits columnares (refs 32, 36, 38, 39) | Cortes paralelos con desplazamiento por capa |
| Valor | Banda beige estrecha y plana | Oscuros profundos en grieta, claro fuerte arriba | Oscurecer por cavidad (AO horneado a vertex color) |
| Musgo | Tinte verdoso tenue en todo `mossy_boulder` | Capa verde OPACA sólo en caras hacia arriba, con borde duro (refs 32, 36) | Umbral por normal Y, no tinte global |
| Vestido | Ninguno | Pasto, piedritas y hongos en la base integran la roca al suelo (refs 32, 36, 37) | Faldón de dressing en el propio asset |
| Acentos | Ninguno | Bolsones de cristal / veta (ref 33 #9, ref 34 #7) | Variante rara con geoda |

## La familia que hay que cubrir

Las referencias no son una roca con seis tamaños: son **tipos distintos**.

1. **Bloque apilado con musgo** — varias piedras trabadas, musgo en la cara superior (32, 36).
2. **Columna / menhir** — vertical, partida por una diaclasa (34 #2, 34 #4).
3. **Cuña inclinada** — placas planas saliendo del suelo en ángulo (34 #5, 35).
4. **Afloramiento estratificado** — capas horizontales, como un acantilado chico (39, 40).
5. **Losa lisa** — la que ya existe y es la única que funciona.
6. **Roca de orilla** — con base mojada y algas (37).
7. **Geoda** — rara, con cristal adentro (33 #9).

## Calibración

Refs 39 y 40 son escaneos 16K: sirven para la LECTURA de estratos, no para el nivel de detalle.
El objetivo son las pintadas (33, 34, 35) y las estilizadas (32, 36, 37): **poca geometría,
mucha decisión de plano y de valor**. Igual que el canon §17 modelo Valheim.

## Fuente

Referencias de internet pasadas por Joan en chat, 2026-08-08. Referencia visual interna.
