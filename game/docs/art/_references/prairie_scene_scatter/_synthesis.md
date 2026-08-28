# prairie_scene_scatter — escena de pradera realista (reel Instagram, 2026-08-28)

**Joan dijo:** *"el fondo del paisaje me parece re fome que sea de ese estilo de dibujo, si igual
la idea es que sea más realista"* (sobre `horizon_ring_01.png`, siluetas vectoriales planas —
DESCARTADA) y sobre este reel: *"esto muestra como una escena, donde coloca pasto, flores y un
árbol que me agradan demasiado, eso es lo que esperaría si es posible"*.

Seis capturas del reel, en orden de flujo de trabajo. Observado de las imágenes, no asumido.

| File | Qué muestra |
|---|---|
| `01_tree_asset_library` | Asset Browser de Blender con librería `bq_Tree_*` (prefijo **bq = Botaniq**, addon de Polygoniq): Prunus serrulata / cerasifera en variantes summer-autumn-winter, Ceiba pentandra, musgo Rhytidiadelphus. El árbol se ARRASTRA a la escena, no se modela. Maniquí gris al lado para escala |
| `02_terrain_sculpt` | Plano subdividido en **Sculpt Mode** (fila de pinceles visible); el terreno pasa de plano a loma suave a mano. Árbol ya puesto, columpio colgado de una rama |
| `03_scatter_grass_viewport` | Scatter de pasto sobre la loma (parches verde-oscuro densos en viewport); **plano-fondo celeste vertical** detrás del árbol como cielo; cámara y timeline 0-150 (animación de cámara) |
| `04_scatter_flowers_closeup` | Primer plano a ras de suelo: briznas de pasto + flores rosa-magenta a la altura del pasto + **pétalos cayendo** (partículas sueltas en el aire). Columpio con cuerdas |
| `05_scene_overview` | Misma escena, encuadre general: loma con scatter, árbol, plano-cielo, cámara |
| `06_final_render` | Render final: loma verde jugosa con **manto denso de flores chicas blancas/amarillas**, cerezo de tronco oscuro con copa rosa, columpio, cielo celeste pálido con **contraluz fuerte + bloom + bruma**. **El horizonte es la CRESTA DE LA LOMA contra el cielo** — no hay montañas ni bosque lejano |

## Idea

Una pradera realista NO es una textura de fondo: es **relieve + densidad + luz**. El reel construye
la escena con cuatro capas y ninguna es un dibujo: terreno esculpido (loma), scatter de pasto,
scatter de flores encima del pasto, un árbol de librería fotorealista, y la iluminación hace el
resto (sol bajo a contraluz, bruma, bloom). El "fondo" del render final es la propia loma cortando
el cielo. Por eso el anillo de siluetas vectoriales se sentía fome: reemplazaba con un cartel lo que
acá es geometría + atmósfera.

## Colores

- Pasto: verde saturado cálido, amarilleado por el sol a contraluz (no oliva).
- Flores: manto de puntos **blancos y amarillos chicos** (tipo margarita/ranúnculo), no flores grandes;
  en el closeup, rosa-magenta a ras del pasto.
- Árbol: tronco casi negro (contraluz), copa rosa desaturada con transparencia de luz.
- Cielo: celeste pálido → casi blanco en el horizonte; sin nubes marcadas.
- Global: luz de tarde, alto brillo, sombras suaves.

## Forma

- Terreno: **una loma**, cresta suave, pendiente visible; el jugador está en la ladera.
- Pasto: alto (~40-60 cm a escala del maniquí), continuo, sin claros de tierra.
- Flores: cabezas pequeñas, densidad tal que a 20-30 m el suelo lee "salpicado" uniforme.
- Árbol: copa ancha y baja (cerezo), ramas horizontales gruesas, un accesorio humano (columpio) que da escala y relato.

## Movimiento / Feel

- Pétalos cayendo (partículas) — vida sin viento fuerte.
- Cámara en travelling lento (timeline 0-150).
- Sensación: calma, verano, contraluz de tarde. El **contraluz** es el truco de "realismo": bordes
  de pasto y pétalos iluminados desde atrás.

## Qué capturar (traducido a Godot, contra lo que YA existe en floor1_prairie)

| # | Capa | Ref | Estado nuestro | Gap |
|---|---|---|---|---|
| 1 | **Relieve** | loma con cresta contra cielo | terreno de caverna prácticamente plano + murallas | **el mayor** — sin relieve no hay horizonte natural |
| 2 | Pasto | continuo, 40-60 cm, verde cálido | `_build_grass_carpet()` 120k briznas, density 2.2 (5059eb2) — Joan aún no lo vio in-game | verificar in-game antes de tocar (sospechosos en engram `luz/horizonte-ring`) |
| 3 | Flores | manto de puntos blancos/amarillos, miles | flores como scatter de props sueltos | pasar flores a **MultiMesh sobre el pasto** con cabezas chicas, densidad ×10-×50 |
| 4 | Árbol hero | Botaniq (cards de hojas con textura foto, alpha) | árboles low-poly | un árbol hero de calidad foto (Botaniq lite / Poly Haven / propio con cards+atlas), no todos |
| 5 | Luz | sol bajo, contraluz, bloom, bruma | caverna-día ya con sol + fog (0df661e) | ángulo de sol más bajo + bloom en pasto/pétalos + bruma más presente |
| 6 | Cielo | degradé celeste→blanco | cristales DanMachi (1a3faf5) | decisión de Joan: cristal vs cielo abierto (ver pregunta abajo) |
| 7 | Partículas | pétalos cayendo | nada | GPUParticles3D baratas, solo cerca del árbol |

**Métrica de éxito antes de construir**: a 1,7 m de altura y mirando al horizonte, la **cresta de
terreno** debe cortar el cielo en ≥ 50 % del ancho del encuadre (hoy: 0 %, corta la muralla), y el
suelo debe leer ≥ 30 % de cobertura de flores en un frame a 20 m (contar píxeles blanco/amarillo
sobre verde).

## Herramientas que aparecen en el reel

- **Blender** ("Free software btw"): Sculpt Mode para el terreno, Asset Browser para el árbol.
- **Botaniq** (prefijo `bq_`): librería de vegetación de Polygoniq, addon de pago con versión gratuita
  limitada. No hace falta el addon para el juego: se importa el `.blend`/glTF del árbol y se exporta
  como cualquier asset (contrato Blender→glTF→Godot en `_modeling_knowledge_base.md`).
- Scatter: pasto/flores por partículas o geometry nodes (no se ve cuál). En Godot equivale a MultiMesh
  chunked, que ya está (`_build_grass_carpet`).

## Fuente

Reel de Instagram guardado por Joan, 2026-08-28. Autor desconocido (sin handle visible en las
capturas). Seis frames del reel + render final rotado a horizontal.
