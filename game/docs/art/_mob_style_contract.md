# Mob Style Contract — el lenguaje común del bestiario

> Nacido del trabajo del slime (2026-07-18, sesión con Joan). Todo mob generado por el
> motor Blender OBEDECE este contrato — es lo que hace que el juego se sienta UN juego
> y no una colección de assets sueltos. Fuente de decisiones: PO Joan.

## 1. Silueta primero

- El mob se reconoce por su SILUETA a 20 m, antes de ver color o detalle.
- Formas simples y llenas; nada de greebles.
- Máximo 3 colores por mob: base + secundario + acento.

### 1.1 Vara de calidad (PO Joan, 2026-07-19): estilizado RICO, no low-poly barato

"Low-poly" NO es la meta — era una muleta. La meta es **estilizado expresivo**
(ref a_iwaac: "more expressive 3D art, less UE5 hyperrealism"):
- Mallas densas y suaves (el polycount es gratis a esta escala) — el slime aprobado
  ya es 96×48 smooth, no facetado.
- Superficies con detalle esculpido (displacement/noise sobre subdivisión) donde
  la materia lo pide: roca agrietada, caparazón, plumas sugeridas.
- Materiales pintados/painterly con variación — nunca color plano (regla §2).
- Sigue prohibido: fotorrealismo/PBR genérico, y greebles que ensucien la silueta.
- `_art_canon.md` §2.1 ("low-poly stylized") queda matizado por esta decisión:
  se conserva el eje "stylized/NO realista", se abandona el eje "barato/facetado".

## 2. El material ES el bicho (regla del slime)

- El material se comporta como la materia real: agua transparente (alpha), gelatina
  translúcida con burbujas, quitina brillante dura, pelaje mate. NUNCA color plano
  sólido — siempre variación procedural sutil (2 tonos + textura), pero sin ruido
  que ensucie la silueta.
- Variantes por hábitat via color (canon PO 2026-07-17): agua→azul, pradera→verde,
  tierra/roca→café-gris. Se cambia la paleta, no el modelo.

## 3. El movimiento ES la personalidad (regla del slime sin cara)

- Un mob puede no tener cara: se define por CÓMO se mueve (slime = wobble viscoso).
- Set de animaciones estándar, mismos nombres en TODOS los mobs (Godot los mapea igual):
  - `idle-loop` — respiración/vida en reposo, SIEMPRE activa
  - `move-loop` — locomoción propia de la especie (hop, slither, scurry, fly-bob, plod)
  - `attack` — anticipación → golpe → recuperación (one-shot)
  - `hit` — flinch corto (one-shot)
  - `death` — colapso ACORDE A SU MATERIA (gel se derrite, insecto cae, reptil queda
    laxo). Nunca un fade genérico.
- Sufijo `-loop` = Godot auto-loopea al importar. Rápido/lento = `speed_scale` en Godot,
  NO clips duplicados.
- Principios: anticipación antes de cada acción; settle/overshoot después; frecuencias
  desfasadas para materia blanda (aprendido en el wobble).

## 4. Ficha showcase (regla a_iwaac)

- Todo mob se presenta igual: fondo plano morado (0.30, 0.22, 0.48), cámara 50 mm,
  key/fill/rim = 110/30/130 W (calibrado 2026-07-18 — más fuerte CLIPEA la textura),
  `view_transform = 'Standard'`.
- **Silueta de escala (PO Joan, 2026-07-19, regla Pokédex)**: TODO still hero lleva
  al lado una silueta de jugador negra mate (humanoide simple, 1.75 m de alto) a
  escala real contra el mob. La cámara hero encuadra AMBOS. Sin esto la ficha
  miente la escala (la avispa de 0.4 m parecía insecto chico). Los GIFs de
  animación siguen mostrando solo al mob.
- Entregables por mob: 1 still hero 1024×1280 (mob + silueta de escala) + 1 GIF por
  animación (512×640) + GLB con las animaciones + .blend. Carpeta: `game/tools/blender/<mob>/`.
- El tablero `bestiario.html` junta todas las fichas — ahí se juzga la coherencia.

## 5. Reglas técnicas duras (gotchas pagados)

- `view_transform = 'Standard'` (AgX desatura todo a pastel).
- Shape keys NO exportan con Apply Modifiers → malla densa sin subsurf.
- Multi-animación glTF: una action por clip, push a NLA tracks con el MISMO nombre
  (shape keys y object-transform por separado), export `NLA_TRACKS`.
- ShaderNodeMix: sockets A/B repetidos por tipo — seleccionar el RGBA por `s.type`,
  nunca `inputs["A"]`.
- SSS radius SIEMPRE explícito (~0.1) — el default de 1 m lava a leche.
- Alpha blend en blob cerrado → `use_backface_culling = True` o la cara trasera
  se dibuja delante.
- Resetear shape key values a 0 tras renderizar clips (quedan pegados en el último frame).
- Texturas de nodos NO viajan en el GLB — bake a imagen pendiente antes de Godot.
- Anatomía orgánica compleja (lobo, zorro, humanoides) NO se genera por primitivas —
  packs/sculpt manual (regla motor). El motor genera: blobs, insectos, reptiles
  simples, criaturas de formas geométricas.

## 6. Higiene (regla Joan 2026-07-18)

- Trabajar EN el mismo script; versiones muertas se BORRAN del árbol (git history es
  la papelera). `renders/anim/` está gitignoreado (intermedios); el GIF es el artefacto.
