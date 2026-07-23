# Art Canon — Dungeon Party

**Versión**: 2.0 (consolidada post scope reset)
**Fecha**: 2026-05-18
**Estado**: SINGLE SOURCE OF TRUTH visual. Reemplaza:
- `game/docs/art_direction.md` v1.0 (2026-04-09)
- `game/docs/visual_bible.md` v1.0 (2026-04-11)
- `game/docs/art/_art_direction_bible.md` v1.0 (2026-04-21)
**Audiencia**: Art, Gameplay (spawn anim hooks), UI (tooltips palette), QA (visual regressions).

> **⚠️ TODO-canon-update (2026-04-23)**: paleta y refs culturales chilenas v1.0 (6 clases con raíz mapuche/diaguita + 5 pisos chilenos) quedaron **DEPRECATED** por rewrite a **hub planetario multicultural** en `_world_canon.md` v2.0. El framework toon (shaders, workflow low-poly, pipeline) **se mantiene**; solo cambian las paletas/refs culturales per-clase. Las paletas concretas hex de §6 quedan como **placeholders válidos para alpha** hasta que se haga el rewrite de identidades culturales post-alpha.

> **Filtro vigente scope reset 2026-05-18**: "¿Esto acerca o aleja de los 5 mapas publicables?" — toda decisión de arte se mide contra el vertical slice 10 min.

---

## §0. Principio rector — JERARQUÍA VISUAL CANON

### §0.1 Lo que importa MÁS (en orden)

1. **Habilidades estallan en color saturado** — esto es lo que vende el juego. Kimetsu no Yaiba es la referencia maestra.
2. **Silhouettes legibles a distancia** — el jugador identifica clases/enemigos a 20m por forma, no por detalle.
3. **Atmósfera por bioma** — paleta + lighting cuentan dónde estás sin tutorial.
4. **Characters con personalidad funcional** — no necesitan ser AAA. Quaternius low-poly toon es suficiente baseline; lo que da personalidad es el VFX de sus habilidades + silhouette diferenciada.

### §0.2 Lo que importa MENOS (NO gastar tiempo)

- Detalle de texturas character (no PBR, no normal maps, no 4K)
- Realismo facial
- Animaciones cinemáticas largas
- Modeling from scratch cuando hay CC0 disponible

### §0.3 Regla de oro

> Si al jugador le dan ganas de quedarse mirando el paisaje antes de pelear, el arte está funcionando.
> Si al jugador le dan ganas de tirar una skill solo para verla otra vez, el VFX está funcionando.

---

## §1. References board — TODAS las refs canon

Compiladas de los 3 docs + 5 refs nuevas agregadas 2026-05-18. Cada ref lleva **por qué** se cita.

### §1.1 Refs maestras de estilo VISUAL

#### Tier PRIMARIO — Skill VFX (lo más importante)

- **Kimetsu no Yaiba (Demon Slayer)** — LA REFERENCIA. Respiraciones (agua/fuego/rayo/sol/luna) son el modelo para skill trails y casts. Color saturado solo durante cast, trail con forma distintiva por estilo, freeze-frame en impacto. Cada rama de clase = "forma de respiración" visualmente.
- **One Piece** — cartoon-épico habilidades con nombre, fuerza del impacto visible, poses de cast (Warrior Berserker, Archer Artillero).
- **JJK (Jujutsu Kaisen) — Gojo Domain Expansion** — casting dramático con pose + nombre visible (canon Mage ultimate). Domain Expansion infinite void → framing ultimate cinematográfico + wrongness.
- **Honkai Star Rail** — framing cinematográfico cinematic ultimate cuts.

#### Tier ATMÓSFERA / BIOMA

- **Valheim** — low-poly handcrafted (no "barato"), texturas planas con personalidad, build pattern incremental EA.
- **Valheim Meadows** — paleta verde pastel low-poly legible (P1 Pradera canon).
- **Risk of Rain 2** — silhouettes claras, paleta acotada por bioma, readability en combate. Distant Roost (P1), Verdant Falls (P2), Sky Meadow (P4).
- **Hollow Knight** — aesthetic minimalista. Greenpath (P2 forest), Crystal Peak (P3 cristales), Abyss/White Palace (P5 geometría imposible).
- **Genshin Impact** — cell shading suave, transiciones de bioma fluidas. Inazuma → purple storm aesthetic (P4).
- **Windbound** — orgánico, warm lighting, formas simples elegantes.
- **Hi-Fi Rush** — toon shading expresivo, saturación valiente, rim lights canon estético.

#### Tier SILHOUETTE / CHARACTER (lower priority post-clarification 2026-05-18)

- **Dark Souls — Havel the Rock** — silhouette tank bulky/grounded (Warrior canon).
- **Dark Souls — Magic Swordsman / Crestfallen Mage** — silhouette encapuchada bastón alto (Mage canon).
- **Dark Souls — Pontiff Sulyvahn + Archdeacon McDonnell** — corrupción litúrgica (Necromancer/Cleric Exorcista).
- **Dark Souls III — Irithyll of the Boreal Valley** — hielo con luz dura + saturación baja (P3).
- **Demon Slayer — Gyomei (Pilar de Piedra)** — Warrior weight/walk cycle Forma del Titán.
- **Frieren — Aura la Degolladora** — Necromancer estética hueso-esqueleto.
- **Bleach — Soi Fon Shunpo** — Danzante desaparición en afterimage.
- **Bloodborne — Cainhurst** — aristocracia corrompida (Necromancer DARK).

### §1.2 Refs MECÁNICAS / ESTRUCTURALES

- **Diablo 2** — Loot grid 12×7, raridades (sin Épico), sockets con riesgo, stash per-account, paper-doll, character select UI. NOTA: D2 es canon UI/UX, **NO** look de personajes.
- **Dark and Darker** — FPS dungeon crawler co-op, perma-death, loot del run.
- **Deep Rock Galactic** — co-op 4-jugadores, shape language coop legible.
- **Vampire Survivors / Hades / Valheim** — incremental build pattern early access.
- **Overlord** — torre temática con Floor Guardians, dark fantasy + humor absurdo, NPCs con jerarquía (no menús con cara).

### §1.3 Refs TONO / LORE

- **Frieren (Sousou no Frieren)** — paciencia académica, melancolía silenciosa, respeto por pequeños hechizos (Mage).
- **Made in Abyss** — silencios pesados, wrongness ambiental capas profundas (P5 — filtro sin body horror).
- **Princess Mononoke (Ashitaka)** — flecha con intención moral, dosel denso húmedo P2.
- **Berserk — Band of the Hawk** — disciplina militar (Warrior), Griffith pos-Behelit pacto irrecuperable (Necromancer).
- **Attack on Titan — Garrison** — voto de guarnición no vanguardia (Warrior).

### §1.4 Refs WORLDBUILDING (5 nuevas agregadas 2026-05-18 + las viejas)

- **Señor de los Anillos (LOTR)** — **NUEVA**. Alta fantasía clásica, escala épica (Mordor / Moria), heroic feel. Útil para: framing cinematográfico de pisos late-game, sensación de mundo más grande que el jugador, biomas que se ven monumentales (catacumbas / abismo / dimensión rota).
- **Metin2** — **NUEVA**. MMORPG coreano low-poly oriental. Útil para: mob design clásico fantasy diverso, mezcla cultural (oriental + occidental coexisten), aesthetic "antiguo MMO" que es comfort food para gamers.
- **Shangri-La Frontier** — **NUEVA**. VRMMO anime con sentido de descubrimiento + hidden bosses + exploration reward. Útil para: filosofía hidden content, sense of place de Outward/SLF que queremos en los 5 pisos.
- **Tensura (That Time I Got Reincarnated as a Slime)** — **NUEVA**. Anime fantasy con monster variety y world creature richness. Útil para: variedad de slimes/monsters en pradera, mob personality (no son cubos hostiles, tienen carácter), evolution mechanic potencial post-alpha.
- **Dark and Darker** — ya estaba en §1.2 pero también es ref worldbuilding (dungeon atmosphere first-person).
- **Demon Slayer (anime)** — ambientes nocturnos contrastando técnicas brillantes (refuerza §0.1).
- **SAO Aincrad Floor 1** — pradera abierta con horizonte artificial (P1).
- **Ragnarok Online — Prontera Fields** — flores dispersas densidad media (P1).
- **Selva Valdiviana real (Chile)** — base cultural Hermandad de Nahuelbuta (Archer Ranger).
- **Mineros de Lota real (Chile)** — base cultural Artillero (Archer industrial).
- **Brujería chilota real** — base cultural Necromancer DARK (Caleuche).
- **Selk'nam Hain ceremonia (Martin Gusinde fotos)** — pintura corporal blanco/rojo/negro (Danzante).
- **Mapuches reales** — Weichafe + Machi + trarilonko (Warrior + Cleric Sanador).
- **Yatiris de la Isla del Sol** — silueta sabio altiplano (Mage).

### §1.5 Refs BIOMA SPECIFIC

| Piso | Refs canon |
|------|------------|
| 1 Pradera | SAO Aincrad F1, Valheim Meadows, Prontera Fields, Risk of Rain 2 Distant Roost, Kimetsu (luz volumétrica cálida) |
| 2 Bosque | Mononoke Forest of Deer God, BOTW Hyrule Forest, Hollow Knight Greenpath, Selva Valdiviana real, R2 Verdant Falls |
| 3 Hielo | Metroid Prime Phendrana Drifts, Castlevania ice caverns, BOTW Hebra Mountains, DS3 Irithyll, Hollow Knight Crystal Peak |
| 4 Tormenta | Laputa (plataformas flotantes), BOTW thunderstorm, Genshin Inazuma, R2 Sky Meadow, Honkai Star Rail Fragmentum |
| 5 Dim. Rota | Made in Abyss capas profundas, HK Abyss/White Palace, Control (Remedy) Oldest House, Antichamber, JJK Domain Expansion |

---

## §2. Filosofía visual

### §2.1 Low-poly stylized — NO realista

Dungeon Party es **low-poly stylized**. Tres ejes:

- **Shape language legible**: silhouette antes que detalle.
- **Texturas planas + vertex color**: nada de PBR complejo, nada de normal maps (Tier I baseline).
- **Shader-driven identity**: el bioma se reconoce por luz + tint + rim, no por geometría exclusiva.

### §2.2 Toon > PBR (CANON)

Decisión canon: el render principal es **toon shader stepped ramp**, NO PBR.

Razones:
1. **Identidad**: toon + paleta acotada = look reconocible. PBR low-poly lee "mobile game genérico".
2. **Performance**: stepped ramp evita cálculos PBR caros. Escala mejor a 1-6 jugadores.
3. **Scope**: menos variables (no roughness/metallic per-asset).

**Filtro**: NO significa "cartoon saturado". Es toon con **paleta madura** — low saturation en biomas serios, alta saturación **solo** donde lore lo pide (Pradera soleada, Dimensión Rota corrupta).

### §2.3 Lo que NO somos

- **No Minecraft**: nada de bloques, nada de pixelado intencional.
- **No realistas**: sin PBR complejo, sin texturas 4K, sin fotorrealismo.
- **No flat/mobile**: hay profundidad, hay sombras, hay atmósfera.

### §2.4 Lección Kimetsu — contraste bioma vs habilidad

El anime Demon Slayer enseña la lección oro:

> **El contraste entre fondo y acción es lo que hace que el combate se sienta ÉPICO.**

En Kimetsu:
- La noche es NEGRA — sin grises, sin compromisos.
- Las técnicas de respiración son LUMINOSAS — agua celeste, fuego naranja, rayo amarillo.
- Resultado: cada ataque se siente como explosión visual.

En DP aplicamos así:
- Biomas Siniestros/Hostiles → fondos OSCUROS y desaturados.
- Habilidades de clase → colores BRILLANTES con trail effects.
- Contraste bioma-habilidad escala con dificultad:

| Pisos | Look | Sensación |
|-------|------|-----------|
| 1-20 | Fondo colorido + habilidades coloridas | Festivo, divertido |
| 40-60 | Fondo gris + habilidades coloridas | "Soy la única luz acá" |
| 80+ | Fondo NEGRO + habilidades NEON | Kimetsu puro, epicidad máxima |

### §2.5 Regla legibilidad coop — silhouettes a 20m

Canon hard rule: las 6 clases deben ser **distinguibles por silhouette a 20m** en combate coop 1-6.

- 20m = rango típico combate party + boss arena.
- Distinción por **silhouette** (forma), NO solo por color (daltónicos, lighting dim).
- Test: screenshot gris 1-bit a 20m third-person → cada clase identificable.

Consecuencias:
- Warrior **broad, bulky, grounded** — no leerse como Mage desde atrás.
- Necromancer **encorvado largo** — no como Cleric erguido.
- Danzante **ligero angular flowing** — no como Archer poised.

Si dos clases comparten silhouette a 20m = **bug de dirección** — se corrige con prop asimétrico (hombro, capucha, staff, bandolera).

---

## §3. Color de habilidades por clase (Kimetsu canon)

Inspirado en respiraciones de Kimetsu (`art_direction.md` v1.0):

| Clase | Color primario | Color secundario | Referencia Kimetsu |
|-------|---------------|-----------------|---------------------|
| Warrior | Naranja fuego | Rojo | Respiración del Sol (Hinokami Kagura) |
| Mage | Cian/azul eléctrico | Blanco | Respiración del Agua (Tanjiro) |
| Archer | Verde lima | Amarillo | Respiración del Viento |
| Necromancer | Violeta oscuro | Rosa muerto | Respiración de la Luna (Kokushibo) |
| Cleric (Healer) | Dorado cálido | Blanco puro | Respiración del Sol (purificación) |
| Danzante | Negro afterimage | Violeta medianoche | Respiración del Insecto (Shinobu — sutil + letal) |

**Estos colores son el HERO ASSET del juego**. Cada cast = una explosión de su color primario. Trail effects + freeze-frame en impacto + damage numbers tinted al color de la clase.

---

## §4. Atmósferas — 5 categorías canon

Cada bioma cae en UNA de estas 5. Define iluminación, audio, feel general.

### §4.1 ACOGEDOR — "Hogar antes de la tormenta"

**Sensación**: seguridad temporal. Jugador baja la guardia, explora con calma. Hay vida, hay luz, hay color. Pero sabemos que no dura.

- **Iluminación**: Direccional cálida (sol/diamante), sombras suaves, golden hour permanente. Ambient alta.
- **Sonido**: Pájaros, viento suave, agua corriendo. Tonos mayores, melódico, acústico.
- **Movimiento**: Pasto mecido, nubes lentas, polen flotando. LENTO y SUAVE.
- **Colores**: Verdes cálidos, dorados, azul cielo. Saturación ALTA.
- **Biomas**: Pradera Interior (P1), Sabana Seca, Tabernas/Safe zones.

**Entrada del jugador**: "Ah, qué lindo. Puedo respirar." — y ESO es el punto. Contraste con lo que viene es BRUTAL.

### §4.2 MISTERIOSO — "Algo me observa"

**Sensación**: curiosidad + incomodidad. No es peligroso todavía, pero algo no está bien. Belleza SOSPECHOSA.

- **Iluminación**: Luz indirecta (bioluminiscencia, hongos, cristales). Sin fuente "natural" obvia. Sombras de color (azuladas, verdosas, violetas). Niebla de color suave.
- **Sonido**: Goteo de agua, crujidos lejanos, melodías que aparecen/desaparecen. Eco. Tonos menores lentos con pads sintéticos.
- **Movimiento**: Esporas, niebla rodando, luces que parpadean. Orgánico, LENTO pero CONSTANTE.
- **Colores**: Púrpuras, azules profundos, verdes bioluminiscentes. Saturación MEDIA con acentos brillantes.
- **Biomas**: Bosque Denso, Cavernas de Cristal, Hongos Gigantes, Océano Sumergido, Selva Tropical, Laboratorio Arcano.

### §4.3 HOSTIL — "Sobreviví"

**Sensación**: agresión ambiental. El bioma MISMO es enemigo. Avanza con urgencia. Cada segundo te castiga. Victoria = SALIR.

- **Iluminación**: Extrema (lava, hielo brillante) o mínima. Alto contraste. Sombras duras negras. Partículas que afectan visibilidad (ceniza, nieve, arena).
- **Sonido**: Viento violento, crujidos, rugidos. Música agresiva o SILENCIO total (peor).
- **Movimiento**: Partículas agresivas. El terreno se mueve (lava, derrumbes). RÁPIDO y CAÓTICO.
- **Colores**: Rojos/naranjas (calor) o blancos/grises (frío). Saturación BAJA excepto en fuentes de daño (lava roja brillante). Fondo monocromático, peligro tiene COLOR.
- **Biomas**: Tundra, Volcán, Desierto, Forja, Plataformas del Cielo, Playa de Ceniza.

### §4.4 SINIESTRO — "No debería estar vivo"

**Sensación**: horror psicológico. No jumpscares — TENSIÓN. El ambiente dice que algo terrible pasó. Avanza porque parar es PEOR.

- **Iluminación**: OSCURIDAD como mecánica. Jugador ilumina con torch/hechizo. La oscuridad no es "ausencia de luz" — es PRESENCIA de algo. Luces que se apagan.
- **Sonido**: Susurros, risas lejanas, pasos que no son los tuyos. Mínima música. Drones graves, piano aislado, silencio roto por sonidos puntuales. Audio = arma principal del horror.
- **Movimiento**: POCO movimiento excepto cosas que NO deberían moverse (estatuas que cambian posición, sombras propias). Quietud = horror.
- **Colores**: Negros, grises hueso, violetas espectrales. Desaturación EXTREMA. Únicos puntos de color = fuentes de peligro (ojos rojos, fuego espectral verde).
- **Biomas**: Pantano Putrefacto, Catacumbas, Jardín Corrompido, Abismo, Pradera Marchita.

### §4.5 SURREAL — "Esto no es real"

**Sensación**: confusión controlada. Las reglas que aprendiste no aplican. Geometría incorrecta. Colores "mal". No es miedo — DESORIENTACIÓN.

- **Iluminación**: Sin fuente identificable. Todo iluminado "desde adentro". Colores de luz imposibles (magenta, cian). Sombras en dirección equivocada. Bloom agresivo.
- **Sonido**: Reverb infinito, sonidos al revés, melodías familiares a velocidad incorrecta. Audio de biomas anteriores pero DISTORSIONADO. Ambient experimental, glitch.
- **Movimiento**: Geometría que rota, plataformas que aparecen/desaparecen, cielo líquido. Partículas que van HACIA ARRIBA. Gravedad incorrecta.
- **Colores**: Negro vacío con acentos HIPER saturados (púrpura cósmico, cian neón, magenta). O colores "normales" INVERTIDOS (cielo rojo, pasto azul). Paleta INESTABLE.
- **Biomas**: Dimensión Astral/Vacío (P5), Mundo Espejo, Templo del Reloj, Santuario del Umbral.

### §4.6 Tabla resumen biomas (25 totales canon original)

| # | Bioma | Atmósfera | Paleta dominante | Shader especial |
|---|-------|-----------|------------------|-----------------|
| 1 | Pradera Interior | Acogedor | Verde esmeralda + dorado + azul cielo | Wind, fog dorado |
| 2 | Bosque Denso | Misterioso | Verde oscuro + púrpura biolum. + gris | Fog volumétrico, wind |
| 3 | Cavernas de Cristal | Misterioso | Azul cristal + rosa cuarzo + negro | Crystal refraction |
| 4 | Pantano Putrefacto | Siniestro | Verde tóxico + marrón fango | Water, fog, corruption |
| 5 | Tundra Congelada | Hostil | Blanco + azul hielo + gris tormenta | Ice/frost |
| 6 | Volcán Activo | Hostil | Rojo magma + negro + naranja | Lava flow, heat |
| 7 | Ruinas Antiguas | Misterioso | Beige + gris piedra + musgo | Dust particles |
| 8 | Desierto Abrasador | Hostil | Dorado arena + naranja + terracota | Sand scroll |
| 9 | Océano Sumergido | Misterioso | Azul profundo + turquesa | Water, biolum. |
| 10 | Plataformas del Cielo | Hostil | Gris tormenta + púrpura + blanco rayo | Void dissolve, lightning |
| 11 | Selva Tropical | Misterioso | Verde lima + esmeralda + amarillo flor | Wind, rain |
| 12 | Forja Infernal | Hostil | Naranja metal + gris acero + rojo | Lava flow |
| 13 | Catacumbas | Siniestro | Negro + gris hueso + violeta | Fog oscuro, flicker |
| 14 | Jardín Corrompido | Siniestro | Rosa corrupto + verde tóxico + púrpura | Corruption pulse |
| 15 | Dimensión Astral | Surreal | Negro vacío + púrpura cósmico + cian | Void dissolve |
| 16 | Abismo Abismal | Siniestro | Negro abisal + azul tenue | Biolum., oscuridad |
| 17 | Ciudad Abandonada | Siniestro | Gris piedra + marrón madera + negro | Fog urbano |
| 18 | Bosque de Hongos | Misterioso | Azul biolum. + rosa + púrpura | Bioluminescence |
| 19 | Templo del Reloj | Surreal | Dorado reloj + bronce + azul/rojo | Time distortion |
| 20 | Playa de Ceniza | Hostil | Gris ceniza + negro + rojo brasa | Desaturation post |
| 21 | Mundo Espejo | Surreal | Desaturado reflejado + tinte violeta | Mirror effect |
| 22 | Laboratorio Arcano | Misterioso | Azul arcano + dorado rúnico + púrpura | Magic particles |
| 23 | Pradera Marchita | Siniestro | Gris ceniza + verde apagado + negro | Desaturation post |
| 24 | Santuario del Umbral | Surreal | Blanco mármol + negro + dorado divino | Perfection shader |
| 25 | Sabana Seca | Acogedor | Amarillo paja + naranja + azul cielo | Wind, grass sway |

> **Scope reset 2026-05-18**: alpha demo = **solo P1** (Pradera). Los 25 biomas son canon longterm; alpha entrega 1.

---

## §5. Visual Bible — 5 pisos canon (canon imagen + paleta + lighting Godot)

### §5.1 Principios universales Tier I

**Paleta maestra Tier I** (extraída de 5 imágenes canon):

```
CÁLIDOS (dominantes):
  #F5D576  dorado diamante / emisión principal del techo
  #E8D4A0  luz cálida god rays
  #F5B048  dorado fogatas, antorchas
  #F0C898  cielo pastel tarde-atardecer
  #E0C58A  piedra cálida ruinas

VERDES (terreno):
  #8FAE6B  verde pradera pastel (P1)
  #6B8B3A  verde hierba iluminada
  #5C7A34  musgo denso sobre piedra
  #2E3D24  verde oscuro canopy (P2)

FRÍOS (acentos):
  #7A8FC4  azul-lavanda techo interior
  #A8D4E8  azul emisión fantasma / cristales
  #5C84A0  azul agua de estanques
  #7ECFD8  cian hongos bioluminiscentes

OSCUROS (sombras/noche):
  #3D2818  marrón troncos profundo
  #1C3044  azul oscuro noche bosque
  #3C2824  banderas bandidos, ropa oscura
```

**Regla**: en Tier I → cálidos dominan (60-70%), verdes sostienen (20-25%), fríos acentúan (10-15%). Tier II-III → fríos ganan terreno.

**Lighting universal Tier I**:
- Fuente principal: diamante emisivo del techo de caverna (DirectionalLight3D, ~70-80° desde arriba).
- God rays: firma visual del tier interior. Todo piso que muestre techo debe tener rayos volumétricos.
- Temperatura: 3200-3800K (cálida dorada, nunca blanca fría).
- Fog: siempre presente pero sutil (~0.002 densidad), color azul-lavanda para profundidad.
- NO sky node — background solid color (canon técnico).

**Shape language Tier I**:
- Orgánico dominante (curvas, raíces, musgo, piedras redondeadas).
- Las únicas formas geométricas son humanas (outpost, ruinas, carreta).
- Densidad visual: media-alta bosque, media pradera, baja claro.

**Escala por piso (NO uniforme)**:

| Piso | Escala | Por qué |
|------|--------|---------|
| P1 Pradera | 600×600m | Apertura + asombro = su alma |
| P2 Bosque | ~200×200m | Opresión + laberinto |
| P3 Ruinas | ~300×300m | Exploración con rincones |
| P4 Paso | ~400×200m lineal | El camino define la forma |
| P5 Claro | ~100×100m | Intimidad |
| P24 Boss | 80×80m cerrado | Arena instanced |

### §5.2 P1 — Pradera Interior (Tutorial Zone) — IMPLEMENTADA

**Imagen canon**: `game/docs/refs/p1_prairie/canon_main.jpg`
**Escala**: 600×600m

**Paleta**:
```
#F5D576  dorado diamante emisivo ("sol" del techo)
#E8D4A0  dorado god rays cayendo
#8FAE6B  verde pradera pastel suave
#7A8FC4  azul-lavanda cielo interior cristales
#6B7C9E  gris-azul montañas lejanas
#7B5A3C  madera outpost
#F5F5F2  blanco cascadas
```

**Lighting Godot**:
```gdscript
DirectionalLight3D:
  rotation_degrees: Vector3(-75, -30, 0)
  light_energy: 3.5
  light_color: Color(0.96, 0.85, 0.63)     # #F5D8A0

WorldEnvironment:
  ambient_light_color: Color(0.72, 0.77, 0.85)  # #B8C4D8 azul-lavanda
  ambient_light_energy: 0.4
  fog_enabled: true
  fog_density: 0.002
  fog_light_color: Color(0.78, 0.83, 0.88)
  background_mode: CLEAR_COLOR
  background_color: Color(0.72, 0.77, 0.85)
```

**Atmósfera params completos (handoff dept D)**:

| Param | Valor |
|-------|-------|
| Sun azimuth | -30° |
| Sun elevation | -75° (picado desde diamante arriba-izquierda) |
| Sun energy | 3.5 |
| Sun color | #F5D8A0 |
| Shadow color | #B8C4D8 ambient |
| Fog color | #C8D4E0 |
| Fog density | 0.002 |
| Bloom threshold | 0.85 |
| Bloom intensity | 0.4 |
| SSAO intensity | 0.3 |
| Saturation | 1.0 |
| Contrast | 1.05 |
| Skybox HDRI | **NO skybox** — cave ceiling dome + focal diamond |

**Notas modelado**:
- God rays = FIRMA VISUAL. Shader volumétrico o partículas grandes orientadas al diamante.
- Diamante emisivo del techo ENORME (visible desde todo mapa). OmniLight3D/SpotLight3D energy ~10, range ~500m. Shader emission + albedo blanco-dorado.
- Cristales Vía Láctea = MultiMesh con emission suave (~0.5 energy), curva S en techo.
- Outpost = ~30m radio. Empalizadas, 2-3 torres vigía, chimeneas con partículas humo.
- Cascadas = partículas + mesh agua con shader translúcido.

### §5.3 P2 — Bosque del Lindero

**Imagen canon**: `game/docs/refs/p2_bosque_lindero/canon_main.jpg`
**Escala**: ~200×200m (compacto, claustrofóbico)

**Paleta**:
```
#3D2818  marrón profundo troncos
#2E3D24  verde oscuro canopy
#7A8494  gris-azul niebla entre árboles
#F5C76A  dorado luciérnagas (acento emisivo cálido)
#8C7856  tierra con huellas
#7ECFD8  cian hongos bioluminiscentes gigantes
```

**Lighting Godot**:
```gdscript
DirectionalLight3D:
  rotation_degrees: Vector3(-85, 20, 0)   # casi vertical, filtrada
  light_energy: 1.5                         # MUCHO menor que P1
  light_color: Color(0.88, 0.78, 0.55)

WorldEnvironment:
  ambient_light_color: Color(0.22, 0.28, 0.35)
  ambient_light_energy: 0.3
  fog_density: 0.008
  fog_light_color: Color(0.48, 0.52, 0.58)
```

**Atmósfera params dept D**:

| Param | Valor |
|-------|-------|
| Sun azimuth | -45° |
| Sun elevation | 20° (bajo, copas tamizan) |
| Sun energy | 1.8 |
| Sun color | #B0A078 dorado filtrado cálido |
| Shadow color | #1A2818 verde oscuro |
| Fog color | #4A6A3C |
| Fog density | 0.008 |
| Bloom threshold | 1.0 |
| Bloom intensity | 0.2 |
| SSAO intensity | 0.6 |
| Saturation | 0.95 |
| Contrast | 1.1 |
| Skybox HDRI | PolyHaven `forest_01_*.hdr` `[proposal]` |

**Notas modelado**:
- Canopy denso: jugador NO ve techo de caverna ni diamante. Solo vislumbres por agujeros. Contraste con P1.
- Hongos gigantes (2-3m): emission cian ~0.8 energy, StandardMaterial3D albedo `#2A4845` + emission `#7ECFD8`. Funcionan como LANDMARKS.
- Telarañas: mesh plano semi-transparente. Hazard: ralentiza 50% speed 3s.
- Plantas carnívoras: mesh suelo, cerradas si jugador lejos. Open + bite a 4m.
- Árbol doble landmark: dos troncos unidos en base, nido entre ellos a 15m.
- Luciérnagas: MultiMesh emission dorada, path random, densas en sombra.
- Niebla baja: fog ground shader o partículas grandes al nivel del suelo.

### §5.4 P3 — Las Ruinas del Peregrino

**Imagen canon**: `game/docs/refs/p3_ruinas_peregrino/canon_main.jpg`
**Escala**: ~300×300m

**Paleta**:
```
#E0C58A  piedra cálida (dominante)
#5C7A34  musgo verde denso
#F8D878  dorado suave god rays
#A8D4E8  azul claro emisivo fantasma La Hermana Olvidada
#C8E4F0  mariposas azules casi blancas
#5C4530  sombras profundas nichos
```

**Lighting Godot**:
```gdscript
DirectionalLight3D:
  rotation_degrees: Vector3(-80, -10, 0)   # casi vertical, god rays fuertes
  light_energy: 2.8
  light_color: Color(0.97, 0.85, 0.47)

WorldEnvironment:
  ambient_light_color: Color(0.55, 0.50, 0.40)
  ambient_light_energy: 0.35
  fog_density: 0.004
  fog_light_color: Color(0.75, 0.70, 0.58)
```

**Atmósfera params dept D**:

| Param | Valor |
|-------|-------|
| Sun azimuth | -60° lateral alto |
| Sun elevation | 60° (alto, sol duro) |
| Sun energy | 4.0 |
| Sun color | #E8F0FF blanco azulado frío |
| Shadow color | #5A7A9A |
| Fog color | #D4E0F0 |
| Fog density | 0.004 |
| Bloom threshold | 0.75 |
| Bloom intensity | 0.7 |
| SSAO intensity | 0.4 |
| Saturation | 0.85 |
| Contrast | 1.15 |
| Skybox HDRI | PolyHaven `snow_field_*.hdr` `[proposal]` |

**Notas modelado**:
- God rays = MEJOR uso de las 10 imágenes. Referencia maestra volumétricos. Caen casi verticales entre columnas rotas, polvo en haces.
- Fantasma La Hermana Olvidada: PointLight3D azul (#A8D4E8, energy 1.2, range 4m) + shader ghost (albedo semi-transparente, rim, sutil distorsión). Aparece solo si jugador deja ofrenda.
- Estatua monumental: ~8-10m alto, peregrino encapuchado sentado mirando arriba, cubierto musgo. Ofrendas al pie.
- Mariposas gris-azuladas: MultiMesh con animation subtle, solo en este piso.
- Columnas rotas, arcos caídos, baldosas sueltas: terreno irregular multi-altura.

### §5.5 P4 — El Paso del Mercader

**Imagen canon**: `game/docs/refs/p4_paso_mercader/canon_main.png`
**Escala**: ~400×200m (lineal)

**Paleta**:
```
#C0A88C  piedra clara colinas
#8C6A44  tierra cálida camino
#F0C898  cielo pastel
#3C2824  banderas oscuras bandidos
#6B4028  caballo marrón
#484442  armadura caída gris
#7A8B5A  vegetación colinas
```

**Lighting Godot**:
```gdscript
DirectionalLight3D:
  rotation_degrees: Vector3(-65, -40, 0)   # más lateral, tarde, sombras largas
  light_energy: 3.0
  light_color: Color(0.94, 0.78, 0.60)

WorldEnvironment:
  ambient_light_color: Color(0.60, 0.55, 0.48)
  ambient_light_energy: 0.45
  fog_density: 0.003
```

**Atmósfera params dept D**:

| Param | Valor |
|-------|-------|
| Sun azimuth | -90° (sol ocluido lateral) |
| Sun elevation | 40° (oculto tras nubes) |
| Sun energy | 1.5 |
| Sun color | #A098B0 violeta-gris filtrado |
| Shadow color | #3A3050 violeta oscuro |
| Fog color | #7868A8 |
| Fog density | 0.005 |
| Bloom threshold | 0.8 |
| Bloom intensity | 0.9 |
| SSAO intensity | 0.5 |
| Saturation | 0.9 |
| Contrast | 1.2 |
| Skybox HDRI | PolyHaven `stormy_sky_*.hdr` `[proposal]` |

**Nota dept D**: trigger flash global WorldEnvironment.background_energy_multiplier (+1.5 durante 0.1s) sync con VFX lightning strike — canon Honkai Star Rail framing.

**Notas modelado**:
- Forma lineal: paso angosto (200m ancho × 400m largo). Desvíos: N (campamento bandido), S (cueva con cascada).
- Carreta volcada: detallado — ruedas, mercadería, cofres. 5 estados visuales por seed.
- Banderas bandidos: mesh plano + shader viento, texture calavera simple.
- Cadáveres: mesh estáticos NPC armados tirados. SIN sangre visible, SIN heridas. Cuerpos vestidos caídos. Tensión moral suave.
- Caballo: pastando libre (sin dueño si mercader emboscado).

### §5.6 P5 — El Claro del Fuego Solitario

**Imagen canon día**: `game/docs/refs/p5_claro_fuego/canon_day.jpg`
**Imagen canon noche**: `game/docs/refs/p5_claro_fuego/canon_night.jpg`
**Escala**: ~100×100m (intimidad es el punto)

**Paleta día**:
```
#F5B048  dorado cálido fuego (centro emocional)
#F5DC5C  puntos luciérnaga dorados
#6B8B3A  verde hierba iluminada
#5C84A0  azul estanque
#5C3C20  marrón troncos apilados
#A898A0  piedra pálida pérgola
#D8C890  tierra dentro del domo de luz
```

**Paleta noche**:
```
#F8B850  dorado fuego más saturado
#1C3044  azul oscuro bosque nocturno
#F0D870  puntos dorados luciérnagas densas
#4A7236  verde pasto iluminado fuego
#6B5038  marrón bardo y tronco
```

**Lighting Godot (ciclo día/noche ~3-4 min por fase)**:
```gdscript
# Fase DÍA
DirectionalLight3D: light_energy=2.0, color=(0.92, 0.82, 0.60)
WorldEnvironment.ambient: color=(0.55, 0.60, 0.48), energy=0.5

# Fase NOCHE (tween ~30s)
DirectionalLight3D: light_energy=0.3, color=(0.40, 0.45, 0.55)
WorldEnvironment.ambient: color=(0.12, 0.18, 0.27), energy=0.15

# En AMBAS — el fuego es constante:
PointLight3D (fogata): color=(0.96, 0.69, 0.28), energy=5.0, range=8.0, atten=1.8
```

**Atmósfera params dept D** (Dimensión Rota):

| Param | Valor |
|-------|-------|
| Sun azimuth | NO fija (rotating/flicker) |
| Sun elevation | variable 10-80° (inestable) |
| Sun energy | 2.5 (pulsa ±0.5) |
| Sun color | #E0A0E0 magenta suave |
| Shadow color | #6A2870 |
| Fog color | #C84AC8 |
| Fog density | 0.006 |
| Bloom threshold | 0.6 |
| Bloom intensity | 1.0 |
| SSAO intensity | 0.8 |
| Saturation | 1.25 (hiper) |
| Contrast | 1.3 |
| Skybox HDRI | **procedural shader** (no HDRI real — canon "imposible") |

**Notas modelado**:
- Ciclo visual día/noche ~3-4 min por fase. Tween entre lighting sets.
- La Bardo de Cabellos de Ceniza: NPC sentada en tronco caído. **Pelo blanco largo, túnica gris clara** — guiño Frieren. Toca lira con partículas musicales (notas doradas).
- Gato del Bardo: mesh atigrado dormido junto al fuego. No collide, no ataca. Si jugador intenta atacar → desaparece en humo, Bardo deja de tocar.
- Zona de paz forzada: radio 20m del fuego, arma se envaina automática. Enemigos que entran se sientan/alejan.
- Estanque: shader agua simple con reflexión planar fuego. Peces MultiMesh path circular.
- Pérgola: piedra con columnas bajas, asientos tallados, enredaderas + musgo.
- Luciérnagas: pocas en día, DOMO DENSO en noche.

---

## §6. Identidad visual per clase

Cada clase: **silhouette keywords**, **color accent**, **animation weight**, **particle philosophy**, **rim light**.

> **NOTA**: paletas hex son canon v1.0 chilenas (DEPRECATED post-rewrite world_canon v2.0). Para alpha siguen válidas como placeholders. Re-rewrite cultural cuando se haga rewrite world_canon.

### §6.1 Warrior — Orden del Muro de Ñielol

**Silhouette**: bulky · broad · grounded · shield-forward · low center of gravity

Piernas abiertas, escudo al frente. Silhouette "roca".

**Color accent**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#2E4560` | Azul andino profundo — sotana base, capa |
| Secondary | `#B8B8B0` | Plata oxidada — escudo, armadura |
| Trim | `#6B2A20` | Rojo tierra (sangre seca) — detalles |
| Accent (Maestros) | `#8C6A3C` | Bronce apagado — solo cascos Maestro |

**Animation weight**: **1.0 / 0.25s** · heavy, grounded, each step deliberate.
**Justificación**: Havel the Rock + Pilar Gyomei. Walk cycle compound weight máximo. Attack anims con wind-up marcado (0.3s pre-impact).

**Particle philosophy**:
- Dust kick-up on footstep (subtle, lifetime 0.4s).
- Debris burst on shield raise + heavy swing.
- Dust trail on Embestida / charge.
- Color: desaturated brown/gray — NO dorado, NO brillante.

**Rim light**: `#3B5A7A` (azul andino claro). Pulse suave on Rage ≥80%.

### §6.2 Mage — Vigilantes de Atacama

**Silhouette**: thin · tall · hunched-at-rest · erect-at-cast · staff-low · cloak-flowing

Encorvada al leer. Erguida al castear. Finger-guns pose on ultimate.

**Color accent**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#5A2E7A` | Violeta profundo — túnica |
| Secondary | `#3E5A80` | Azul andino — bordes, capucha |
| Trim | `#D4B065` | Oro apagado — qillqa, encuadernación |
| Accent desert | `#B89060` | Ocre desierto |

**Animation weight**: **0.7 / 0.20s** · deliberate, slight float on cast, academic precision.

**Particle philosophy**:
- Arcane wisps passive ambient (violeta `#5A2E7A`, ~8 particles, lifetime 2s).
- Staff emission glow on MP regen (soft pulse oro apagado).
- Glyph circles on skill cast (geometría sagrada — Doctor Strange ref).
- NO fire/ice per-class.

**Rim light**: `#8A4AB0` (violeta claro glow). Intensidad 0.6 durante cast — "se enciende" al trabajar.

### §6.3 Archer — Hermandad de Nahuelbuta + Gremio Forja de Lota

Archer es DUAL. Dos entradas porque lores divergen (silent forest vs industrial).

#### §6.3.1 Ranger (Nahuelbuta) — forest silent

**Silhouette**: crouched · low · silent · bow-ready · hood-forward · camouflage-moteada

**Color accent**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#556B2F` | Verde oliva — capa, túnica |
| Secondary | `#5C3A20` | Marrón tierra — botas, bandolera |
| Trim | `#8A8880` | Gris ceniza + plata desgastada |
| Accent ceremonial | `#C8213A` | Rojo copihue (solo ceremonial) |

**Animation weight**: **0.5 / 0.15s** · poised, quick, silent. Draw anim = breath-hold pause (0.3s) antes del release.

**Particle philosophy**:
- Leaf puff on dodge roll (moss `#4A6A2A`, lifetime 0.3s).
- Breath vapor on draw full charge (cold biomes).
- Arrow trail sutil corto madera — NO neón.

**Rim light**: `#6B8B3A` muted. Intensidad baja 0.2 — el Ranger **no brilla**.

#### §6.3.2 Artillero (Lota) — industrial steampunk-chilote

**Silhouette**: erect · armed-visible · goggle-necked · bandolier-cross · boot-heavy

**Color accent**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#4A4A50` | Gris acero — jubón |
| Secondary | `#8C6A3C` | Bronce oxidado — placas, gafas, gears |
| Trim | `#E08530` | Naranja mecha — cartuchos |
| Accent warn | `#D4C030` | Amarillo azufre — explosivos visibles |
| Dark | `#1A1810` | Negro carbón — humo, pólvora |

**Animation weight**: **0.7 / 0.18s** · mechanical, deliberate, weapon-heavy.

**Particle philosophy**:
- Smoke puff on every shot (post-muzzle, carbón).
- Spark shower on reload (cartridge connect, 0.2s burst).
- Explosion shockwave on Artillero ultimate.

**Rim light**: `#E08530` (naranja mecha). Pulse on explosion precast (tell al party).

### §6.4 Cleric — Sínodo de las Tres Cumbres

**Silhouette**: tall · erect · dignified · robe-flowing · staff-vertical · 3-ramas-differ-in-accent

**Color accent común**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#F0EDE4` | Blanco limpio sotana |
| Secondary | `#B89060` | Dorado apagado (cobre oxidado) |
| Base metal | `#D4C095` | Metal dorado opaco |

**Acento por rama**:
| Rama | Volcán | Hex | Uso |
|------|--------|-----|-----|
| Sanador (Aliento) | Llaima | `#4A7AB0` azul volcánico | Bordes sotana, báculo agua |
| Buffer (Coro) | Osorno | `#C8213A` rojo copihue | Mangas + cinturón, libro |
| Exorcista (Verbo) | Villarrica | `#D4601A` naranja llama | Capucha + runa báculo |

**Animation weight**: **0.8 / 0.20s** · measured, ceremonial, posture-held.

**Particle philosophy**:
- Sanador: halo blanco-dorado al castear heal. Respira soft (fade in 0.5s).
- Buffer: rojo copihue en verso activo, nota musical icon on Verso del Guardián.
- Exorcista: runa naranja llama en espiral al suelo vs undead. Más agresivo visualmente.

**Rim light**: cycling por rama. Intensidad 0.4 base → 0.7 durante ultimate.

### §6.5 Necromancer — Cofradía del Caleuche (DARK)

**Silhouette**: tall · gaunt · hunched · long-robe-trailing · hood-deep · NOT-erect

**Color accent** (DARK v2.0):
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#0E0A12` | Negro profundo (casi negro Chiloé húmedo) |
| Secondary | `#2E1830` | Púrpura corteza podrida |
| Trim blood | `#4A1010` | Rojo sangre seca |
| Bone | `#C8BFA8` | Blanco hueso (símbolos rituales) |
| Rot | `#3A4530` | Verde podredumbre-musgo |

**NO canon**: dorado, brillante, alta saturación. Si aparece → bug dirección.

**Animation weight**: **0.6 / 0.25s** · gaunt, slight hover, ritual-slow.
**Justificación**: Aura Degolladora + Pontiff Sulyvahn. Walk cycle leve hover 0.05m on footstep ("la podredumbre filtrándose").

**Particle philosophy**:
- Black veins passive en piel cuando hay invocaciones activas (shader on-skin, NO partícula externa). A más invocaciones, más denso.
- Purple smoke trail on walk in caves (densidad baja).
- Bone dust on summon spawn (blanco hueso, 0.4s burst).
- Blood drip on HP cost skills (`#4A1010`, lifetime 0.6s).

**Rim light**: `#4A1A50` púrpura-rojo oscuro. Intensidad **baja** (0.15). **NUNCA brillante** — se filtra, no se ilumina.

### §6.6 Danzante de Sombras — Hijos de la Noche Austral

**Silhouette**: thin · angular · flowing · low-off-center · engaging-desenfadada · weapons-concealed

Ligera, relajada, desenfadada. En reposo parece desarmado. Silueta baja desequilibrada en combate.

**Color accent**:
| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#0E0A1A` | Negro profundo |
| Secondary | `#1A1030` | Violeta medianoche |
| Trim ritual | `#8A1818` | Rojo sangre (pintura corporal Hain) |
| Accent metal | `#8A8A8A` | Gris luna (acentos metálicos) |
| Bone ceremony | `#C8BFA8` | Blanco hueso (Hain Selk'nam ritual) |

**Animation weight**: **0.4 / 0.10s** · fluid, fast transitions, off-center, afterimage-ready.

**Particle philosophy**:
- Shadow afterimage on dash / Paso de Sombra (silhouette frame -0.15s, fade 0.3s, `#1A1030`).
- Dissolve particles on Velo Nocturno stealth enter.
- Blade flash short — **NO neon trail**. Corte Fugaz = 1-frame arc `#8A8A8A`.
- Ritual paint glow on ultimate (Danza Mil Sombras) — pintura blanco-rojo-negro activa rim 0.9 durante 1.2s.

**Rim light**: `#3A2050` violeta frío. 0.3 base → 0.9 ultimate.

### §6.7 Tabla resumen animation weights (dept B handoff)

| Clase / Rama | Weight | Blend time | Feel keyword |
|--------------|--------|-----------|--------------|
| Warrior | 1.0 | 0.25s | heavy, grounded |
| Mage | 0.7 | 0.20s | deliberate, slight float |
| Archer Ranger | 0.5 | 0.15s | poised, silent |
| Archer Artillero | 0.7 | 0.18s | mechanical, deliberate |
| Cleric | 0.8 | 0.20s | measured, ceremonial |
| Necromancer | 0.6 | 0.25s | gaunt, slight hover |
| Danzante | 0.4 | 0.10s | fluid, fast transitions |

### §6.8 Marcas de identidad + personalidad por clase (Joan, 2026-07-20 — pendiente de integrar al pilotar cada clase)

Capturado tal como lo dijo Joan durante la sesión de personajes, ancla Diablo II ("tienen esencia"). No construir todavía — se aplica clase por clase cuando le toque el pilot, siguiendo el mismo orden que Warrior.

**Marcas visuales (cuerpo/rostro) por clase:**
- **Mage/Hechicera**: marcas faciales/corporales ligadas a magia y esoterismo — runas o símbolos, no solo túnica.
- **Warrior**: cicatrices + buena musculatura visible (ancla: Barbarian de Diablo II).
- **Necromancer**: refuerza el DARK ya canon (§6.5) — asociación directa a artes oscuras.
- **Archer**: armadura ligera, contextura delgada/ágil — contraste directo con el Warrior bulky.
- Cleric / Danzante: sin marcas específicas dadas todavía — gap, preguntar cuando toque su pilot.

**Personalidad ligada al diseño visual** (Joan: "colocarle personalidades a estas cosas... relacionada más a su diseño"):
- **Warrior**: brusco, resuelve las cosas de forma directa/simple.
- **Mage**: reflexivo ("satérico" en el audio original — sin confirmar si quiso decir sarcástico o certero, preguntar), busca significado y relaciones antes de actuar.
- **Archer**: mejor visión de conjunto, mejor planificación — piensa antes de disparar.
- Cleric / Necromancer / Danzante: sin personalidad asignada todavía — gap.

**Referencia de estilo**: Diablo II — "se nota que una hechicera tiene [las marcas], un guerrero tiene cicatrices" — mismo principio ya sintetizado en `_references/warrior_archetype/_synthesis.md` (Diablo II Barbarian, imágenes 11-12), extender la misma lógica multi-fuente a Sorceress/Necromancer/Amazon cuando se pilotee esa clase — no existe carpeta de referencia para esas todavía.

---

## §7. Pipeline de Renderizado

### §7.1 Godot 4.6 — Forward+ Renderer

Se usa **Forward+** (no Compatibility, no Mobile). Razones:
- Soporta luces volumétricas, GI, post-processing completo.
- Performance superior a Vulkan clustered para escenas con pocas luces dominantes.
- Pisos 600×600m necesitan distance fog y LOD nativos.

### §7.2 Cadena de materiales

Base:
```
StandardMaterial3D
├── albedo_color: color plano (sin textura en mayoría de casos)
├── roughness: 0.7-0.9 (mate, no plástico)
├── metallic: 0 (excepto metales explícitos)
├── shading_mode: per-pixel
└── cull_mode: back
```

**Excepciones que usan ShaderMaterial**:
- Agua (transparencia + movimiento)
- Follaje (viento + alpha cutout)
- Lava/magma (emisión + scroll UV)
- Efectos mágicos (emisión + fresnel)
- Cristales (refracción simplificada)

### §7.3 Por qué NO texturas UV en mayoría de modelos

- Low-poly con vertex color o color plano por material = más baratos que texturas.
- Menos draw calls (1 material vs 1 material + textura).
- Más fácil iterar (cambiar color = cambiar valor, no re-pintar textura).
- Identidad viene de FORMA y COLOR, no del detalle de textura.

**Excepción**: terreno, props grandes (ruinas, edificios), items especiales — tileables, nunca únicas por modelo.

---

## §8. Toon shader canon — params per bioma

Base: toon shader stepped ramp + outline.

| Bioma | Ramp steps | Rim intensity | Outline thickness | Outline color rule |
|-------|-----------|---------------|-------------------|---------------------|
| 1 Pradera | 3 | 0.3 | 0.02 | darker-than-albedo (−25%) |
| 2 Bosque | 3 | 0.5 | 0.02 | darker-than-albedo (−30%) |
| 3 Hielo | 3 | 0.4 | 0.02 | darker-than-albedo (−25%) |
| 4 Tormenta | 3 | 0.6 | 0.02 | darker-than-albedo (−35%) |
| 5 Dim. Rota | **4** | **0.8** | **0.04** | **invertido — glow bright (+40%)** |

**Justificación**:
- Ramp 3 default — suficiente para legibilidad low-poly. Dim. Rota → 4 para más tonos de corrupción.
- Rim intensity escala con "extrañeza" — Pradera 0.3, Tormenta 0.6, Dim. Rota 0.8.
- Outline 0.02 default → 2× en Dim. Rota para reforzar "trazo cómic wrong".
- Outline color regla canon: default darker. Dim. Rota INVIERTE — outline es GLOW (+40%). Comunica sin palabras que el piso ROMPE las reglas visuales.

**Uniforms sugeridos**:
```gdscript
uniform int ramp_steps : hint_range(2, 5) = 3
uniform float rim_intensity : hint_range(0.0, 1.2) = 0.3
uniform float outline_thickness : hint_range(0.0, 0.08) = 0.02
uniform bool outline_invert_to_glow = false  # true solo Dim. Rota
uniform vec3 outline_tint = vec3(1.0, 1.0, 1.0)
```

### §8.1 Otros shaders canon

#### Cell Shading (Toon) — universal

Reduce gradación de luz a 2-3 bandas (iluminado, sombra, penumbra).
- `shade_steps`: 2 (hard) o 3 (soft) por atmósfera.
- `shade_color`: complementario desaturado del albedo (NO negro).
- `outline_width`: 0.002-0.004 (solo personajes/enemigos, NO terreno).
- `outline_color`: negro o color del bioma.

#### Outline Shader

Inverted hull: escala modelo, renderiza solo cara trasera en color sólido. BARATO.
Aplica a: jugadores (siempre), enemigos (siempre), loot (glow), props interactivos (cursor encima).

#### Wind Shader (vegetación)

Mueve vertices vegetación. Basado en vertex Y (más arriba = más movimiento).
Aplica a: pasto, árboles, arbustos, flores.

#### Fresnel / Rim Light

Halo de luz en bordes. Aplica a: personajes (sutil), loot (brillante), objetos mágicos (intenso).

### §8.2 Shaders por bioma (load on-demand)

| Shader | Biomas | Qué hace |
|--------|--------|----------|
| Water surface | Océano, Pantano, Selva | Reflexión planar + scroll UV + transparencia |
| Lava flow | Volcán, Forja | Emisión + scroll UV doble + distorsión calor |
| Ice/frost | Tundra | Fresnel fuerte (blanco), roughness baja |
| Crystal refraction | Cavernas | Refracción screen-space + emisión interna |
| Corruption pulse | Jardín | Colores que pulsan "normal/wrong", noise |
| Void dissolve | Astral, Vacío | Dissolve shader + emisión bordes |
| Time distortion | Templo Reloj | Screen-space distorsión |
| Fog volumetric | Bosque, Pantano, Catacumbas | Fog + density map per bioma |
| Bioluminescence | Hongos, Océano, Abismo | Emisión pulsante sine wave |
| Sand scroll | Desierto | Scroll UV en suelo simulando viento |
| Desaturation post | Pradera Marchita, Ceniza | Post-process que desatura progresivamente |

### §8.3 Shaders de feedback (siempre activos)

| Shader | Uso |
|--------|-----|
| Damage flash | Modelo parpadea rojo 0.1s al recibir daño |
| Heal flash | Modelo parpadea verde 0.1s al curarse |
| Death dissolve | Modelo se disuelve al morir (noise + alpha) |
| Loot glow | Items en suelo pulsan con color de rareza |
| Interaction highlight | Props interactivos brillan al estar en rango |

---

## §9. Iluminación canon

### §9.1 Fuentes de luz por atmósfera

| Atmósfera | Luz principal | Ambient | Sombras | Fog |
|-----------|--------------|---------|---------|-----|
| Acogedor | DirectionalLight3D (sol cálido, 5500K) | Alta, warm (0.3-0.4) | Soft, 50% opacidad | Distance fog dorado, 100m+ |
| Misterioso | OmniLight3D puntuales (bioluminiscencia) | Baja, fría (0.1-0.2) | Colored (azul/verde), soft | Volumetric fog color, 20-40m |
| Hostil | DirectionalLight3D duro + emisiones | Media, extrema | Hard, alto contraste | Particle fog (ceniza/nieve), 30-60m |
| Siniestro | Player torch (única fuente móvil) | Muy baja (0.02-0.05) | Duras, casi negras | Oscuridad como fog, 5-10m |
| Surreal | Sin fuente (ambient puro) | Media, multicolor | Invertidas o ausentes | Bloom como fog, infinito |

### §9.2 Transiciones entre biomas

Cambio de piso = **3-5 segundos**:
1. Fade a negro (0.5s).
2. Carga nuevo bioma (invisible).
3. Fade desde negro con nueva iluminación (0.5s).
4. Niebla se ajusta gradualmente (2-3s) — no instantánea.

### §9.3 Ciclo día-noche

**NO hay ciclo día-noche global**. Cada piso tiene iluminación FIJA. Razones:
- Dentro de torre/abismo no tiene sentido.
- Consistencia visual permite optimizar shaders y pre-bake.
- Cada bioma tiene "hora del día" congelada:
  - Pradera: golden hour permanente.
  - Tundra: amanecer frío.
  - Volcán: noche roja.
  - Catacumbas: medianoche.

**Excepción**: P5 (Claro del Fuego Solitario) tiene ciclo corto día/noche ~3-4 min por fase.

---

## §10. Teoría de Color y Contraste

### §10.1 Saturación = indicador de profundidad en torre

| Rango pisos | Saturación | Sensación |
|-------------|------------|-----------|
| 1-20 Early | Alta (70-100%) | Vibrante, acogedor |
| 21-50 Mid | Media (40-70%) | Tensión creciente |
| 51-80 Late | Baja-Media (30-60%) | Hostil |
| 81-100 Endgame | Mixta: desaturada con acentos HIPER saturados | Surreal, final |

### §10.2 Temperatura color = hospitalidad

| Temperatura | Significado | Uso |
|-------------|-------------|-----|
| Cálido (naranja, dorado, amarillo) | Seguridad, descanso | Tavernas, safe zones, POIs amigables |
| Neutro (verde, beige, gris claro) | Exploración | Praderas, bosques, caminos |
| Frío (azul, violeta, gris oscuro) | Peligro, misterio | Dungeons, biomas hostiles, zonas boss |
| Rojo/magenta saturado | PELIGRO INMEDIATO | Trampas, ataques boss, zonas daño |

### §10.3 Contraste readability — 5 must-distinguish

Jugador SIEMPRE debe poder distinguir:
1. Suelo vs vacío — contraste mínimo 40% luminosidad.
2. Enemigo vs fondo — silueta clara, outline si necesario.
3. Proyectil amigo vs enemigo — colores OPUESTOS (azul amigo, rojo enemigo).
4. Loot en suelo — brillo/emisión para resaltar.
5. Zona daño vs zona segura — rojo/naranja pulsante para daño, sin efecto para seguro.

### §10.4 3 capas de lectura

```
Capa 1 (fondo):    colores muted/desaturados — no compite por atención
Capa 2 (gameplay): colores medios — enemigos, jugadores, props
Capa 3 (feedback): colores BRILLANTES — daño, loot, alertas, UI diegética
```

### §10.5 Paleta maestra del juego (universal, todos los biomas)

| Elemento | Color | Hex | Uso |
|----------|-------|-----|-----|
| HP jugador | Rojo sangre | `#C62828` | Barra vida, daño recibido |
| MP jugador | Azul arcano | `#1565C0` | Barra maná, habilidades mágicas |
| XP | Dorado ámbar | `#FF8F00` | Barra experiencia, level up |
| Daño físico | Blanco-amarillo | `#FFF9C4` | Números daño físico |
| Daño mágico | Cian brillante | `#00E5FF` | Números daño mágico |
| Curación | Verde esmeralda | `#2E7D32` | Números heal, efectos cura |
| Loot Común | Blanco | `#FFFFFF` | Nombre item |
| Loot Raro | Azul | `#2196F3` | Nombre item |
| Loot Mágico | Amarillo dorado | `#FFD600` | Nombre item + resplandor |
| Loot Único | Rojo vino | `#880E4F` | Nombre item + aura |
| Interacción | Blanco outline | `#FFFFFF` | "Presiona E" prompts |
| Peligro ambiental | Rojo pulsante | `#FF1744` | Zonas daño, trampas activas |

---

## §11. Presupuesto de Polígonos + Performance

### §11.1 Por categoría asset

| Categoría | Triángulos max | Ejemplo |
|-----------|----------------|---------|
| Jugador (cuerpo) | 1,500 - 2,500 | Capsula humanoid low-poly con silueta reconocible |
| Jugador (arma) | 200 - 500 | Espada, bastón, arco — forma clara |
| Enemigo común | 500 - 1,500 | Slime (200), lobo (800), esqueleto (1,200) |
| Enemigo mini-boss | 2,000 - 4,000 | Golem, hidra |
| Boss piso | 5,000 - 10,000 | Arquitecto, Dragon |
| Prop pequeño | 50 - 200 | Roca, arbusto, poción, cofre |
| Prop mediano | 200 - 800 | Árbol, pilar, estatua, tienda |
| Prop grande | 800 - 2,000 | Edificio, ruina grande, altar |
| Terreno (chunk) | 5,000 - 10,000 | Chunk 50×50m heightmap |

### §11.2 Presupuesto total por frame

**Target**: máximo **200,000 triángulos visibles por frame**.

| Categoría | Tris estimado |
|-----------|---------------|
| Terreno visible | ~40,000 |
| Props y vegetación | ~80,000 (con instancing) |
| Enemigos (10-15 en pantalla) | ~15,000 |
| Jugadores (6 max) | ~15,000 |
| Efectos (partículas, beams) | ~10,000 |
| HUD 3D (armas en mano) | ~2,000 |
| Headroom picos | ~38,000 |

**Target FPS**:
- GTX 1060 / RX 580 (mínimo) → 60 FPS estable / Medium quality.
- RTX 2060 / RX 5700 (recomendado) → 60 FPS estable / High quality.
- RTX 3070+ → 60+ FPS / Ultra.

### §11.3 Técnicas de optimización obligatorias

**LOD**:
- LOD 0 (0-30m): modelo completo.
- LOD 1 (30-80m): 50% triángulos.
- LOD 2 (80-200m): 25% triángulos.
- LOD 3 (200m+): billboard/impostor (textura 2D).

**Instancing (MultiMeshInstance3D)**:
Todo lo que se repite >10 veces en un piso usa instancing. **1 draw call** para 1,000 copias.
- Pasto, árboles, rocas, hongos, cristales, columnas, escombros.

**Occlusion Culling**:
- Habilitado globalmente Project Settings.
- Biomas interiores (cavernas, catacumbas, forja) se benefician MAS.
- Exteriores (pradera, sabana) se benefician de distance fog como culling visual.

**Chunk Loading** (pisos 600×600m):
- Piso dividido en chunks 50×50m (144 chunks total).
- Solo se cargan chunks en radio 150m del jugador (~28 chunks).
- Pre-cargados en dirección de movimiento.
- Descargados cuando jugador está a +200m.

**Shader LOD**:
- Full: 0-50m.
- Simplified: 50-100m (sin refracción, sin scroll UV).
- Flat color: 100m+ (solo albedo + ambient).

### §11.4 Lo que NUNCA se hace

- GI en tiempo real (pre-bake siempre, o LightmapGI para interiores).
- Sombras dinámicas para MAS de 8 luces por escena.
- Transparencia en más del 15% de pixeles visibles (alpha sort es caro).
- Physics en objetos decorativos (solo gameplay-critical).
- Pathfinding en más de 30 agentes simultáneos por chunk.

---

## §12. Progresión Visual de la Torre

### §12.1 Viaje emocional del color

```
Pisos 1-20:    COLORES VIVIDOS     ████████████████████  Verdes, dorados, azules
                                    La vida. El comienzo. "Puedo hacer esto."

Pisos 21-40:   COLORES EN TENSION  ████████████████████  Purpuras, marrones, grises con acentos
                                    La duda. Las sombras crecen. "Esto se complica."

Pisos 41-60:   COLORES APAGADOS    ████████████████████  Grises, negros, rojos apagados
                                    La resistencia. Todo es gris. "No quiero seguir."

Pisos 61-80:   OSCURIDAD           ████████████████████  Negros, violetas, azules profundos
                                    El abismo. La oscuridad total. "Estoy perdido."

Pisos 81-99:   COLORES IMPOSIBLES  ████████████████████  Negros + neon (purpura, cian, magenta)
                                    Lo surreal. La realidad se rompe. "Esto no es real."

Piso 100:      BLANCO Y NEGRO ORO  ████████████████████  Marmol, obsidiana, oro divino
                                    La perfeccion. El juicio final. "Soy digno."
```

### §12.2 Transiciones críticas

| Momento | Transición | Impacto emocional |
|---------|-----------|-------------------|
| P1 → P2 | Saturación baja 5% | Imperceptible, subconsciente lo nota |
| P10 (primer boss) | Arena dramática, contraste alto | "Esto es serio" |
| P20 → P21 | Caída saturación 10-15% | "Las cosas cambiaron" |
| P50 (midpoint twist) | Glitch visual 1s al cambiar piso | "Algo se rompió" |
| P75 (Pradera Marchita) | Reconoce Pradera P1 pero GRIS | "No... esto era mi lugar seguro" |
| P90+ | Colores neón sobre negro absoluto | "Estoy en otro mundo" |
| P100 | Blanco absoluto, silencio, luego oro | "El final" |

---

## §13. Integration handoff

### §13.1 Para dept Animation (Tier 2)

**Canon files a leer ANTES de tunear AnimationTree**:
1. Este doc §6 (silhouette + animation weights + blend times per clase)
2. `game/docs/lore/_class_lore_*.md §4 Aesthetic / postura` — 6 docs per-clase
3. `game/docs/skills/_system.md §5quinquies` — Cooldown philosophy: **animación = cooldown principal**

**Params canon NO inventar**:
- Animation weights per clase (§6.7 tabla)
- Blend times per clase (§6.7 tabla)
- Feel keyword (guía wind-up/recovery)

**Params SÍ decide**:
- Frames exactos anims concretas (idle, walk, run, attack_light, attack_heavy, cast_*, dodge, hit_react, death)
- IK targets (manos en escudo/báculo/arco/daga)
- Root motion sí/no per clase (recomendación: sí Warrior + Cleric; no Mage casting + Danzante dash)

### §13.2 Para dept Visual Pipeline (Tier 1)

**Canon files a leer ANTES de setup WorldEnvironment + toon shader**:
1. Este doc §5 + §8 (atmosphere params + toon shader per bioma)
2. `game/docs/art/crystal_ceiling.md` — tint canon por bioma (**NO sobreescribir**)
3. `game/docs/art/p1_pradera.md §3 + §4` — paleta + lighting canon piso 1 (**NO sobreescribir**)

**Params canon NO inventar**:
- Ceiling tint hex per-bioma (de `crystal_ceiling.md`).
- Sun color + energy piso 1 (de `p1_pradera.md`).
- Toon shader ramp steps/rim/outline per bioma (§8 tabla).

**Params SÍ decide**:
- HDRI file exacto (PolyHaven names marcados `[proposal]` en §5).
- Shader implementation details (uniforms, blend modes, atlas packing).
- Performance tradeoffs (FPS arena 80m → bajar Dim. Rota ramp steps).

### §13.3 Para dept Art (assets)

**Checklist asset antes de entregar**:
- [ ] Triángulos dentro presupuesto §11.1
- [ ] Material usa StandardMaterial3D color plano o vertex color
- [ ] Si textura: tileable, max 512×512 (256×256 preferido)
- [ ] Tiene LOD 0 y al menos LOD 1 (50% tris)
- [ ] Silueta legible a 30m distancia
- [ ] Cell shader bien aplicado (verificar shade_steps)
- [ ] Outline no clip con geometría
- [ ] Sin n-gons, sin caras sueltas, normals correctas
- [ ] Scale aplicado (1 unit = 1 metro Godot)
- [ ] Pivot point en base del modelo

---

## §14. No goals de este doc

- **Character model specs** (mesh poly count exacto, bone count, texture atlas) — pendiente `character_specs.md` futuro.
- **VFX per-skill** (frame-by-frame Supernova) — pendiente `vfx_canon.md`.
- **UI theme** (colores HUD, fonts, iconografía) — fase Alpha dept UI.
- **Audio direction** (ambient per-bioma, SFX per-skill) — doc aparte futuro.
- **Cinematic framing ultimates** (Honkai Star Rail ref) — requiere `vfx_canon.md` + cutscene system; bloqueado.

---

## §15. Red flags + pendientes

1. **`vfx_canon.md` NO existe** — prompt wave3 lo mencionaba. Dept D debe crearlo antes de VFX per-skill. **Especialmente importante post-clarification 2026-05-18**: VFX skills es el hero de identidad visual.
2. **Skybox HDRI PolyHaven names marcados `[proposal]`** — dept D confirma nombres exactos al implementar.
3. **Piso 5 shader procedural** — no hay canon previo de shader corrupto. Dept D diseña en su worktree y actualiza este doc.
4. **Archer dual animation weight** — split en §6.3.1 + §6.3.2. Recomendación: 2 trees separados (silent forest vs mechanical industrial).
5. **Playtest values `[proposal]`** — revisar tras iteración 1 smoke test. No canon duro hasta validar.
6. **Paletas culturales chilenas v1.0 DEPRECATED** — placeholder válido alpha. Re-rewrite cuando se haga world_canon rewrite post-alpha.

---

## §16. Cross-references

- **World canon**: `_world_canon.md` v2.0 (hub planetario multicultural)
- **Class lore v2.0**: `_class_lore_warrior/mage/archer/cleric/necromancer/danzante_sombras.md`
- **Skills canon**: `_system.md` (tipos skill → tipos anim)
- **Skills per-class v2.0**: `{clase}.md`
- **Art canon existente NO sobreescribir**:
  - `crystal_ceiling.md` — ceiling tint per bioma
  - `p1_pradera.md` — paleta + lighting canon piso 1
  - `skill_icons.md` — iconos UI (fuera scope este doc)
  - `drop_vfx.md`, `mimic.md`, `ambient_fauna.md` — sub-docs art específicos
  - `_visual_pipeline.md` — pipeline operativo (tracking aparte)
  - `_alpha_asset_packs.md` — 5 packs CC0 canon alpha
- **World references**: `_world_references.md` — 26+ refs canon aprobadas
- **GDD**: `GDD_DungeonParty.md §3` (pisos), §4 (clases)
- **DESIGN_BRIEF**: mech refs (Dark and Darker, Diablo 2, DRG, Hades, Frieren, Made in Abyss, Overlord)

---

*Art Canon v2.0. Consolida 3 docs previos (art_direction + visual_bible + _art_direction_bible). Refs actualizadas con LOTR + Metin2 + Dark and Darker + SLF + Tensura (2026-05-18). Cambios al canon se versionan aquí primero.*

---

## §9 — Procedural Family Contract (D2 Act-1 Hybrid)

**Status**: canon vigente desde 2026-06-08. Aplica a todos los assets CSG/procedurales del piso 1 generados por `floor1_prairie.gd`.

### §9.1 Tone — Warm Key + Cool-Dark Fill

Floor 1 runs a **D2 Act-1 hybrid lighting story**:

- **Warm key** (`CavernKeyLight`): `#F5D8A0` warm gold, energy 0.8, pitch -52°, yaw -35°. This is the "diamond cave sun" — the dramatic rim that defines figures and surfaces from above-left. Shadows are cast and defined by this light.
- **Cool-dark fill** (`CeilingLight` in CrystalCeiling): `SKY_COOL #8CA0C8`, energy 0.5 (owned by the `light_energy` export). Cool-dark only, never compensating for the key.
- **Ambient**: dim and cool-tinted (WorldEnvironment), dominated by crystal OmniLights close-range.
- **Net effect**: warm-lit faces vs cool-dark shadows = high contrast, figures defined by warm rim against cool cave shadow. Kimetsu/Valheim cozy soul preserved via the warm key; D2 contrast added via the cool-dark fill.

### §9.2 Family Signature — CSG/Procedural Assets

All procedural CSG surfaces share a consistent visual language:

- **Flat-shade + 1 chamfer**: hard toon ramp (no soft gradients). Where geometry allows, one small chamfer edge gives a secondary mid-band.
- **Bottom-weighted silhouette**: pillars taper slightly wider at base; walls ground-anchor with a thicker foot slab.
- **Detail in notches**: surface interest comes from geometry notches (see `_make_cave_material` noise detail), not albedo complexity.

### §9.3 DP_ToonGrounded Shader Rules

**File**: `game/scenes/levels/dp_toon_grounded.gdshader`
**Applied through**: `_make_material()` in `floor1_prairie.gd` (all procedural CSG surfaces route through this chokepoint).

| Rule | Value |
|------|-------|
| Ramp bands | 3: shadow / mid / light |
| Shadow tint | `#7A8FC4` cool slate-blue, strength 0.45 (NEVER pure black) |
| Mid threshold | 0.30 NdotL |
| Light threshold | 0.65 NdotL |
| Spec | Disabled (matte, no PBR specular) |
| Rim | Optional warm gold `#F8DC9E`, power 5, intensity 0.30 |
| Vertex color | Available via `use_vertex_color` param (off by default for CSG) |

### §9.4 Palette Roles

| Role | Color range | Saturation rule |
|------|-------------|-----------------|
| Dominant ground (floors, terrain, paths) | Olive-greens, dirt browns | **-27% desaturated** vs full-sat. Kimetsu rule: biome is quiet. |
| Cool cavern fill (ceiling, border walls) | Cool gray-beige | Already muted; keep as-is. |
| Warm key (key light, camp fire, altar) | Gold/amber tones | Accent only — no large flat surfaces in full warm-sat. |
| Jewel accents (crystals only) | Cyan `#5FD8FF`, amber `#D1A373`, violet `#B06FFF` | **ONLY saturated pixels on floor 1.** Never apply to structural CSG. |
| Structural stone (pillars, ruins, walls) | Mid-gray + cave noise via `_make_cave_material` | Always via cave material, never flat color. |

### §9.5 Scope Guard — "Stop at 5 bespoke assets"

- **CSG procedural assets** (pillars, ruins, walls, altar, camp props, border): all use `_make_material()` → DP_ToonGrounded.
- **Characters**: stay with their pack materials (KayKit Adventurers / Quaternius). Do NOT override with DP_ToonGrounded.
- **gltf scatter packs** (trees, rocks, bushes): keep their own imported materials for now. A future `material_override` pass would extend DP_ToonGrounded to them — that is explicitly deferred.
- **Stop rule**: when tempted to create a 6th bespoke CSG sub-style, stop and ask "does this appear in the 10-min vertical slice video?" If not → defer.
- **Water**: `water_toon.gdshader` stays separate (animated, translucent — not the toon ramp family).
- **Crystals**: gem glass material (`_create_multimesh_emissive` gem_mode=true) stays separate (translucent + emissive — jewel accent family).

---
