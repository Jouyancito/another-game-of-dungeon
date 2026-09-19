# water_margin — la orilla por capas

Pasadas por Joan el 2026-08-08: *"con lo del río sería similar... la idea es recrear igual
naturaleza en el juego, con modelados como el árbol que hiciste, pero variedades"*.

## La idea

Una orilla real **no es una línea**: es una secuencia de bandas, y cada banda tiene su especie.
Las seis fotos, en aguas distintas, repiten el mismo orden desde el agua hacia la tierra:

1. **Agua abierta** — reflejo, sin vegetación.
2. **Alfombra flotante** — nenúfar (43, 45) o lenteja de agua cubriendo la superficie entera
   como un fieltro verde (46, 48).
3. **Emergentes finas** — cola de caballo, juncia: tallos rectos saliendo del agua poco profunda,
   sin hoja (44).
4. **Espadaña / totora** — la silueta firma de la orilla: hoja de cinta ancha + la maza marrón
   (42).
5. **Herbácea de ribera** — flor rosada/magenta en mata, hoja ancha (42).
6. **Pasto de banco y arbusto** — la transición al campo (43, 48).

Hoy el `river_pack` cubre la banda 6 y las piedras. **Las bandas 2 a 5 no existen.**

## Qué capturar

- **La maza de la espadaña** es el elemento más reconocible de una orilla y es geometría trivial:
  un cilindro marrón sobre un tallo. Máximo retorno por esfuerzo del set.
- **La alfombra flotante importa más que las plantas sueltas.** En 46 y 48 la lenteja cubre TODA
  la superficie y define el color del agua. Es una decisión de material de agua, no de scatter.
- **Los tallos emergentes son casi 2D** (44): cintas rectas verticales, sin ramificación. Muy
  baratos, y son lo que dice "acá el agua es poco profunda".
- **Los troncos caídos y restos** (48) atan la orilla a una historia. Un tronco medio hundido
  vale por diez juncos.
- **El nenúfar es un disco**, con una muesca radial. Barato, y su patrón de dispersión (racimos
  contra la orilla, nunca en el centro) hace la mitad de la lectura.

## Regla ecológica que hay que respetar

`_world_coherence.md` §2 ya fija el halo de humedad en 1.5–3× el radio del cuerpo de agua, y
`_humidity_at()` ya lo calcula en código. **Las bandas de arriba son una función de esa humedad**,
no un scatter aparte: banda 2 en humedad ~1.0, banda 5 en ~0.5, banda 6 en ~0.3.

## Fuente

Referencias de internet pasadas por Joan en chat, 2026-08-08. Referencia visual interna.
