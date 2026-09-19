# fake_interior_parallax — interiores falsos con parallax (2026-08-13)

**Joan dijo:** *"es como de un túnel, en donde demuestran que realmente no es un túnel, sino que es como una imagen prerenderizada, que se ve como una ventana y que tiene vista según tu posición. Para que así no tenga que modelar todo el interior del túnel, porque es un lugar que no tiene acceso. Los juegos generalmente ocupan eso para dar vida a los interiores. Me parece buena idea que se implemente, tanto para la eficiencia como rendimiento, y para agregar cosas dentro de las casas."*

Referencia #7 de siete. Texto en pantalla: *"Si piensas que… equivocado… es un túnel… te chocaría… porque"*.

## Imágenes

| # | Qué se ve |
|---|---|
| 01-10 | Un túnel que parece real; una X roja desmintiéndolo; el mismo túnel revelado como superficie plana; explicación con diagramas |

## Síntesis

### Idea
Un interior al que el jugador **nunca va a entrar** no necesita existir. Se resuelve con una **imagen prerenderizada mapeada sobre una superficie plana**, desplazada según la posición de la cámara. El desplazamiento crea la profundidad; el jugador no puede distinguirlo hasta que intenta entrar.

### Cómo funciona
Es la técnica de **interior mapping / parallax occlusion**: la textura se muestrea con un offset proporcional al ángulo de visión, así que el "fondo" se mueve más lento que el "marco". El cerebro lee eso como profundidad.

### Dónde sirve en Dungeon Party
- **Ventanas de casas** del asentamiento — hoy o son opacas o exigen modelar el interior.
- **Túneles y bocas de cueva** que decoran pero no se recorren.
- **Rejas y aberturas** que insinúan una sala detrás.

### Por qué importa más de lo que parece
El repo tiene 2,6 GB en `game/assets`. Cada interior modelado suma geometría, materiales y tiempo de carga a cambio de un lugar donde nadie entra. Esta técnica cambia **un interior completo por una textura y un shader**. Es la relación costo-beneficio más alta de las siete referencias.

### Qué capturar
1. Usarlo sólo donde el acceso está genuinamente cerrado. Si el jugador puede acercarse y tocar, se rompe.
2. El offset debe responder a la posición, no sólo al ángulo — si no, se lee como calcomanía.
3. Marco geométrico real (el hueco de la ventana, la boca del túnel) y sólo el interior falso. El borde es lo que vende la ilusión.

### Estado
No implementado. Es un shader nuevo (`interior_parallax.gdshader`) sobre el pipeline existente, no un cambio de arquitectura.

## Fuente
Grabación de pantalla, sesión `2026-08-13_03-13-10` (553 frames, Instagram). La única de las cuatro primeras que sobrevivió a la auto-limpieza. Aun así, estas hojas de contacto son la copia estable.
