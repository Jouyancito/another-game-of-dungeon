# prairie_ecology — referencias de pradera

Pasadas por Joan el 2026-08-07, después de caminar el piso 1: *"te voy a dar un poco de
referencias, así como ambientes, praderas, bosques, cosas así, para que veas la densidad,
cantidad de planta, diferentes colores, tipo de animales que puedes encontrar"*.

Las 4 primeras son referencia; las 3 `ingame_*` son el estado actual del juego, para tener
el antes al lado del objetivo.

## Idea

Ninguna pradera real es un tapiz verde uniforme. Las cuatro fotos, siendo climas distintos,
coinciden en tres cosas que el piso 1 hoy no tiene:

1. **La flor viene en masas, no en unidades.** En la referencia densa no se distingue una
   flor: se ven manchas de color de metros de ancho. Hoy el juego pone flores sueltas
   separadas — se leen como objetos, no como pradera.
2. **El suelo tiene manchones, no un tono.** Verde profundo, verde amarillento, seco, tierra
   pelada, todo en el mismo cuadro.
3. **La altura varía.** Pasto bajo pisado, mata media, espiga alta. La silueta contra el
   horizonte es irregular.

## Colores

- Dominante: **amarillo** — es el color de masa de casi toda pradera florida.
- Acento caliente: **rojo / naranja**, en poca cantidad y bien saturado.
- Acento frío: **violeta / azul**, disperso.
- **Blanco** como puntuación de alta frecuencia, muy repartido.
- El verde de base NO es uno: convive verde azulado húmedo con verde amarillento seco.

## Forma

- **Estepa** (mongolian_steppe): matas redondas separadas con espaciamiento regular sobre
  pasto bajo. Escala enorme, lectura limpia. Es el modelo para las zonas abiertas.
- **Pampa** (pampa_grassland): pasto irregular con roca aflorando y árboles agrupados solo
  en el horizonte. Es el modelo para la transición hacia el borde.
- **Vega florida** (wildflower_meadow): la masa de flor ocupa el primer plano y el bosque
  cierra el fondo. Es el modelo para los claros.
- **Jardín denso** (dense_wildflowers): el extremo de densidad. Referencia de cuánto es
  "mucho", no un objetivo para el mapa entero.

## Movimiento / feel

El pasto y la flor alta se mueven; la mata leñosa casi no. Esa diferencia de rigidez entre
capas es la mitad de la sensación de mundo vivo. Hoy no hay viento en ninguna capa.

## Qué capturar

- Densidad de masa floral **muy** por encima de la actual, agrupada en manchones por especie
  en vez de repartida pareja.
- Variación de tono en el suelo mismo, no solo en lo que se le planta encima.
- Tres estratos de altura legibles.
- Contraste de altura y color hacia el horizonte para que la escala se lea.

## Contra el estado actual

`prairie_ecology_ingame_vista_2026-08-07.png` — Joan: *"se siente como pradera"*, y es
cierto que la silueta funciona. Lo que falta es exactamente lo de arriba: masa de flor,
manchones de suelo, y estratos.

`prairie_ecology_ingame_exit_2026-08-07.png` — la flor del ángulo inferior derecho está
**fuera de escala** (Joan: *"es enana, como el porte de un ratón"*). Medir el tamaño nativo
del `flower_pack` antes de tocar el scatter — ver `_asset_inventory_p1.md` pendiente 1.

`prairie_ecology_ingame_border_2026-08-07.png` — se ve mapa por debajo del muro del borde.
El plan acordado era **pradera que se pierde en el horizonte** y el muro sólido apareciendo
recién al llegar. Sin implementar.

## Fuente

Referencias de internet pasadas por Joan en chat, 2026-08-07. Sin atribución conocida — son
referencia visual interna, no van al juego.
