# biome_landscape

**Joan dijo:** "Aparece un video de que el Blender no puede ser tan realista, y hace un bioma gigante, con árboles, con plantas, tronco en el suelo, un auto moviéndose. Ese tipo de Blender me encantaría para el paisaje, para nuestro mundo — sería precioso."

- **Idea**: bioma forestal denso, muy realista (terreno + rocas + árboles + vegetación + tronco caído + auto atravesando).
- **Colores**: verde denso, natural.
- **Forma**: densidad y variedad de vegetación, capas de terreno.
- **Movimiento/Feel**: sensación de mundo vivo/real — auto moviéndose da escala y vida.
- **Qué capturar**: el NIVEL DE DENSIDAD/DETALLE del bioma — Joan lo quiere explícitamente para el paisaje del mundo del juego.
- **Fuente**: reel Instagram ("Blender can't achieve realism... so I made this"). Frame origen: `frame_03783.png` (auto + bosque denso).

**Aplicación posible**: referencia directa para scatter/densidad de vegetación en pisos exteriores — cruzar con `_world_coherence.md` (reglas de hidrología/vegetación ya definidas).

---

## Fotos de pradera real (Joan, 2026-07-29)

Joan las pasó tras la primera caminata in-game del bioma día ("se siente como
pradera... comparen, se parecen o no"). Observado de las imágenes, no asumido:

| File | Qué muestra |
|---|---|
| `prairie_photo_yellow_flower_hillside.png` | Pradera verde saturada con flores amarillas chicas dispersas; ladera con bosque mixto (coníferas oscuras + caducas claras) |
| `prairie_photo_rolling_hills.png` | Colinas onduladas, campos en mosaico con muros de piedra, árboles solitarios dispersos; pasto alto en primer plano |
| `prairie_photo_wildflowers_lake.png` | Deriva DENSA de flores multicolor (naranja/violeta/azul/rosa) al borde de un lago calmo; árbol grande a la derecha |
| `prairie_photo_purple_wildflower_drift.png` | Manto violeta/magenta+azul de flores bajo árboles grandes, camino de tierra al costado |

**Qué capturar (gaps vs render actual del bioma):**
1. **Color del pasto**: verde VIVO saturado (no oliva/caqui). El terreno nuestro
   lee barro seco; las 4 fotos leen verde jugoso incluso en zonas pisoteadas.
2. **Flores en DERIVAS masivas, no plantas sueltas**: manchones/carpetas de
   puntos de color concentrados por zona (amarillo acá, violeta allá), con
   transición gradual — no un espécimen aislado cada 10m.
3. **Terreno ondulado**: colinas suaves continuas, nunca disco plano.
4. **Árboles = copas densas y llenas**; árboles solitarios como landmarks
   espaciados venden la escala de la pradera.
5. **Agua = espejo azul-verde claro** que refleja el cielo (lago de
   `wildflowers_lake`), no mancha marrón.
