# bush_variety — el arbusto que hoy no existe

Pasadas por Joan el 2026-08-08 mirando el `bush_showcase` del pack actual: *"sobre el bush pack,
5 arbustos, mmm no me gustan para nada"*.

## Qué es un arbusto, y qué construimos en su lugar

Un arbusto se lee por **masa de hojas con ramaje visible adentro**. En las siete referencias, sin
excepción, la silueta está hecha de cientos de hojas individuales, hay huecos por donde se ve el
fondo, y en la base asoman ramas leñosas (refs 26, 29, 30, 31).

Lo que tenemos son **poliedros facetados pintados de verde**. `env_bush_large_01` es una pila de
peñascos verdes: mismo lenguaje de forma que el `rock_pack`, con otra paleta. No hay una sola
hoja, no hay ramas, no hay hueco. La variante `flowering` es un cono verde con puntitos rosados.

## Y el hallazgo que importa más que el arbusto

`_motor_tiers.md` califica a `bush_pack` como **M3**, el nivel máximo. Y es cierto según su
checklist: tiene FLOAT_COLOR, adyacencia `enforce_overlap`, notch/outlier, 5 variantes,
presupuesto de tris. **Pasa el tier y falla como arbusto.**

Los tiers miden el MEDIO (con qué técnicas se construyó), no el FIN (si el resultado se lee como
la cosa que representa). El fin es trabajo de `_mob_style_contract.md`, y a este pack nadie se lo
aplicó. **Un asset no está listo por ser M3.**

## Diff contra el estado actual

| Eje | Hoy (`bush_showcase.png`) | Referencia | Acción |
|---|---|---|---|
| Silueta | Blob poliédrico cerrado | Contorno mordido por hojas, con huecos | Hojas como geometría propia en la capa exterior |
| Forma | Facetas grandes de peñasco | Masa de hojas chicas + ramas | Instanciar hoja sobre puntos de una envolvente |
| Interior | Sólido | Se ve a través; ramas leñosas visibles | Ramas desde la base, envolvente hueca |
| Valor | Un verde plano | Oscuro adentro, claro en la punta | Oscurecer por profundidad dentro de la envolvente |
| Color | Un solo verde por variante | Verdes distintos + rojo, púrpura, dorado, lima (refs 27, 28) | Paleta por especie, no sólo por seed |
| Flor | Puntitos rosados encima | Floración integrada en la masa (ref 28) | Flor sobre puntos de la envolvente, misma pasada que la hoja |
| Vestido | Ninguno | Pasto y flores al pie (refs 25, 26) | Faldón integrado |

## La variedad de color que pide

Ref 27 y 28 son el pedido explícito: **no todo verde**. Púrpura oscuro (ninebark), rojo
(quince), dorado (spirea goldflame), lima (goldmound), rosa. Joan: *"a esos arbustos los puedes
mezclar con flores u otra fauna correspondiente al bioma"*.

## Nota de inventario

Joan cree que en el juego pueden seguir packs gratis descargados al principio. **Verificar antes
de construir** — pero recordar que la purga M3 del 2026-08-07 sacó los `.gltf` CC0 justamente
por no ser del motor.

## Fuente

Referencias de internet pasadas por Joan en chat, 2026-08-08. Referencia visual interna.
