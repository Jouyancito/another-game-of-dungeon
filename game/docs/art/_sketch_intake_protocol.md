# Protocolo de bocetos: Joan dibuja → Claude implementa (2026-08-27)

**Origen**: pedido de Joan 2026-08-27 (*"si hay alguna forma de yo dibujar/bocetear
cosas y tú las puedas implementar"*). Investigación: handoff concept→3D de industria
(NastyRodent, Clip Studio), captura/limpieza de dibujo en papel, imagen→3D 2026.

**Regla de oro para Joan**: nunca hace falta dibujar BIEN — hace falta dibujar CLARO.
Una línea temblorosa con "esto es metal, mide 1 m" al lado vale más que un dibujo
hermoso sin anotaciones. Foto siempre PERPENDICULAR al papel, con luz de ventana,
sin flash. Nada más.

## Dónde se deja

```
game/docs/art/_references/bocetos/{asset}/
    {asset}_front.png|jpg    ← vista de frente (la principal)
    {asset}_side.png|jpg     ← perfil (opcional)
    {asset}_back.png|jpg     ← espalda (opcional)
    {asset}_notas.*          ← flechas, texto, lo que sea (opcional)
```

Foto cruda del papel sirve — Claude la limpia. Todo en una sola hoja también sirve
(Claude recorta). El nombre `{asset}` en snake_case es el mismo del `.glb` final:
buscar el base name encuentra todo (convención base-name del proyecto).

## Qué anotar en el dibujo (lo que más rinde)

1. **Escala contra el jugador**: un monito al lado con "1.80" o una nota tipo
   "llega a la cintura" / "2 jugadores de alto". Es LA anotación más valiosa.
2. **Materiales por tipo, con flechas**: "metal", "madera", "piedra", "tela",
   "BRILLA". Un dibujo pintado no dice qué es metal; una flecha sí.
3. **Simetría**: "simétrico" escrito = Claude modela la mitad y espeja.
4. **Rígido vs blando**: qué cuelga/se mueve al animar (una correa ≠ placa).
5. Close-up SOLO de lo complejo (una cara, un mecanismo).

## Niveles de esfuerzo: qué promete cada uno

| Nivel | Joan entrega | Claude promete |
|---|---|---|
| **N0 Garabato** | 1 dibujo rápido, cualquier ángulo, foto | Silueta e idea INTERPRETADAS; proporciones y materiales a criterio de Claude + estilo del juego. 2-3 iteraciones esperables. |
| **N1 Frente + escala** | frente derecho + anotación de escala | Proporciones frontales fieles y escala correcta a la primera. La profundidad, a criterio de Claude. |
| **N2 Ficha mínima** ★ | frente + perfil + escala + materiales con flechas + simetría | Volumen fiel, materiales correctos, ~1 pasada de corrección. **El sweet spot.** |
| **N3 Ficha completa** | N2 + espalda o 3/4 + close-up + colores | Asset casi final; correcciones solo de gusto fino. |

## Los 5 pasos de Claude (por cada boceto nuevo)

1. **LIMPIAR**: foto de papel → grayscale + niveles (papel a blanco, trazo a negro) +
   corrección de perspectiva. Guarda `{asset}_front_clean.png` al lado. Nunca usar
   "mejora automática" de apps de escaneo (revienta los grises).
2. **LEER Y PREGUNTAR**: lectura multimodal del boceto. Si hay UNA ambigüedad crítica
   (escala sin anotar, material no obvio) → una sola pregunta a Joan, no interrogatorio.
3. **MODELAR**: pipeline normal (preflight MODELADO FULL, bpy headless, contrato de
   estilo vigente). Simetría anotada → mitad + mirror.
4. **VALIDAR CONTRA EL BOCETO**: board canónico + **silueta render-vs-boceto lado a
   lado** (misma vista orto) + maniquí 1.80 m. La comparación de silueta es el gate
   nuevo que este protocolo agrega al board.
5. **ENTREGAR**: GLB → deploy → contact sheet para el veredicto de Joan → engram.

## Herramientas opcionales (solo si el caso lo pide)

- **Concept refinado desde garabato**: ControlNet Scribble (SD 1.5, corre en 8 GB)
  convierte un boceto ambiguo en 2-3 concepts refinados; Joan ELIGE uno y ese pasa a
  ser la referencia. Convierte ambigüedad en decisión de Joan. Solo si SD está
  instalado; si no, Claude pregunta directo.
- **Blockout volumétrico AI** (formas orgánicas complejas): TripoSR o SF3D (~6 GB,
  licencias limpias) como referencia de volumen DENTRO del .blend — NUNCA como asset
  final (topología de triángulos sin loops; 2-4 h de retopo la harían perder contra
  modelar directo en bpy). NO instalar hasta el primer caso real. Evitar Hunyuan3D
  (licencia con exclusión regional) y TRELLIS (16 GB).
- **Dibujo digital sin instalar nada**: Kleki (web, celular/tablet) exporta PNG limpio.
  Desktop: Krita. El papel + foto sigue siendo el camino principal.

## Anti-patterns (de la investigación)

- NO salida imagen→3D como asset final (no rigea, pelea con el estilo).
- NO pedir turnarounds de 8 vistas: el máximo útil es N3.
- NO "mejora automática" de escaneo sobre el boceto.
- NO modelar sobre foto inclinada (distorsiona las proporciones orto).
