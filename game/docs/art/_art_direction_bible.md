# Art Direction Bible — Dungeon Party

**Versión**: 1.0
**Fecha**: 2026-04-21
**Estado**: Canon único de dirección artística. Consolida identidad visual + feel animado per-clase + atmosphere per-piso.
**Depende**:
- `game/docs/lore/_world_canon.md` (mundo + esencia chilena + Necromancer dark)
- `game/docs/lore/_world_references.md` v1.1 (refs canon)
- `game/docs/lore/_class_lore_*.md` v2.0 (6 órdenes — silhouette + palette + refs culturales)
- `game/docs/skills/_system.md` (tipos skill canon — anim esperadas)
- `game/docs/art/crystal_ceiling.md` (tint hex canon por bioma — **NO sobreescribir**)
- `game/docs/art/p1_pradera.md` (paleta + lighting Godot canon piso 1 — **NO sobreescribir**)
**Referenciado por**:
- Dept B (Animation Tier 2) — AnimationTree weights + blend times
- Dept D (Visual Pipeline Tier 1) — toon shader params + WorldEnvironment per bioma
**Audiencia**: Art, Gameplay (spawn anim hooks), UI (tooltips palette), QA (visual regressions).

**Nota canon**: `vfx_canon.md` mencionado en prompt wave2 D **no existe aún** en `game/docs/art/`. Este doc no duplica VFX per-skill — solo **particle philosophy per-clase** (identidad). VFX per-skill queda pendiente doc aparte.

---

## §1. Filosofía visual

### §1.1 Low-poly stylized, no realista

Dungeon Party es **low-poly stylized**, no realista. La dirección se clava en tres ejes:

- **Shape language legible**: silhouette antes que detalle. La forma a distancia pesa más que la textura.
- **Texturas planas + vertex color**: nada de PBR complejo, nada de normal maps (Tier I). Atlas 1024 por bioma (canon `p1_pradera.md §6`).
- **Shader-driven identity**: el bioma se reconoce por luz + tint + rim, no por geometría exclusiva.

**Referencias canon de estilo** (ver `_world_references.md §3`):

- **Deep Rock Galactic** — low-poly con shape language coop legible a 4 jugadores.
- **Risk of Rain 2** — silhouettes distinguibles a distancia, paleta acotada por bioma.
- **Hi-Fi Rush** — toon shading expresivo, saturación valiente, rim lights como canon estético.

### §1.2 Toon > PBR

**Decisión canon**: el render principal es **toon shader stepped ramp**, no PBR.

Razones:
1. **Identidad**: toon + paleta acotada = look reconocible a primer vistazo. PBR en low-poly lee "mobile game genérico".
2. **Performance**: stepped ramp evita cálculos PBR caros. Escala mejor a 1-6 jugadores en arena con enemigos + partículas.
3. **Scope**: menos variables a afinar (no roughness/metallic per-asset), equipo chico (B/C/D coordinan).

**Filtro**: esto NO significa "cartoon saturado". Es toon con **paleta madura** — low saturation en biomas serios (Bosque, Necro zones), alta saturación **solo** donde lore lo pide (Pradera soleada, Dimensión Rota corrupta).

### §1.3 Regla legibilidad coop — silhouettes a 20m

**Canon hard rule**: las 6 clases deben ser **distinguibles por silhouette a 20m de distancia** en combate coop 1-6 jugadores.

- 20m es el rango típico de combate party + boss arena del GDD §3.
- Distinción por **silhouette** (forma), NO solo por **color** (daltónicos, lighting dim).
- Test de validación: screenshot gris 1-bit a 20m cámara third-person → cada clase identificable.

Consecuencias concretas:
- Warrior **broad, bulky, grounded** — no puede leerse como Mage desde atrás.
- Necromancer **encorvado largo** — no puede leerse como Cleric erguido.
- Danzante **ligero angular flowing** — no puede leerse como Archer poised.

Si dos clases comparten silhouette a 20m, es **bug de dirección** — se corrige con prop asimétrico (hombro, capucha, staff, bandolera).

---

## §2. Identidad visual per clase

Cada clase se documenta con 5 campos: **silhouette keywords**, **color accent palette**, **animation weight** (crítico para B), **particle philosophy**, **rim light color**.

Los colores vienen de `_class_lore_*.md §4 Aesthetic` v2.0 — **NO reinventar, citar**.

Los animation weights/blend times se derivan de silhouette lore + refs:
- **Warrior** (Havel the Rock + Pilar de Piedra Gyomei → heavy)
- **Mage** (Frieren paciencia + silueta encorvada al leer → deliberate)
- **Archer Ranger** (silueta silenciosa agachada → poised silent)
- **Archer Artillero** (ballesta pesada, postura firme → deliberate mechanical)
- **Cleric** (postura digna, gesto ceremonial → measured)
- **Necromancer** (encorvado por peso ritual + caminar lento → gaunt hover)
- **Danzante** (ligera, relajada, disuelto en partículas → fluid fast)

### §2.1 Warrior — Orden del Muro de Ñielol

**Silhouette keywords**: bulky · broad · grounded · shield-forward · low center of gravity

- Piernas abiertas, escudo al frente ligeramente bajado (postura huasa canon `_class_lore_warrior.md §4`). Silhouette "roca".

**Color accent palette** (canon `_class_lore_warrior.md §4`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#2E4560` | Azul andino profundo (cordillera de Ñielol) — sotana base, capa |
| Secondary | `#B8B8B0` | Plata oxidada (tiempo del escudero sin nombre) — escudo, armadura |
| Trim | `#6B2A20` | Rojo tierra (sangre seca — nunca brillante) — detalles internos, trarilonko |
| Accent (Maestros) | `#8C6A3C` | Bronce apagado — solo en cascos de Maestro del Muro |

**Animation weight** (dept B — AnimationTree):

| Weight | Blend time | Feel |
|--------|-----------|------|
| **1.0** | **0.25s** | heavy, grounded, each step deliberate |

**Justificación**: Havel the Rock (Dark Souls — canon ref) + Pilar de Piedra Gyomei (Demon Slayer — canon Forma del Titán). Walk cycle compound con weight máximo. Attack anims con wind-up marcado (0.3s pre-impact).

**Particle philosophy**:
- **Dust kick-up** on footstep al caminar (subtle, lifetime 0.4s).
- **Debris burst** on shield raise + heavy swing (canon physical tag skills).
- **Dust trail** on Embestida / charge (canon `player.gd` warrior combo pesado).
- Color: desaturated brown/gray — NO dorado, NO brillante.

**Rim light color**: `#3B5A7A` (azul andino claro, 70% luminance del primary). Pulse suave on Rage ≥80% (canon `_system.md §5ter` Berserker).

### §2.2 Mage — Vigilantes de Atacama

**Silhouette keywords**: thin · tall · hunched-at-rest · erect-at-cast · staff-low · cloak-flowing

- Delgada, alta, encorvada hacia adelante al leer. Erguida solo al castear (canon `_class_lore_mage.md §4`). Finger-guns pose on ultimate (canon `mage.gd` + GDD §4.2).

**Color accent palette** (canon `_class_lore_mage.md §4`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#5A2E7A` | Violeta profundo (pigmento diaguita — túnica Vigilante) |
| Secondary | `#3E5A80` | Azul andino (altiplano) — bordes, capucha |
| Trim | `#D4B065` | Oro apagado (cobre de San Pedro, encuadernación qillqa) |
| Accent desert | `#B89060` | Ocre desierto (bordes de manga) |

**Animation weight** (dept B):

| Weight | Blend time | Feel |
|--------|-----------|------|
| **0.7** | **0.20s** | deliberate, slight float on cast, academic precision |

**Justificación**: Frieren (canon ref) academic patience — no hay apuro. Casting pose con finger-guns (JJK Gojo domain expansion ref) requiere blend 0.20s para que el frame de pose sea legible.

**Particle philosophy**:
- **Arcane wisps** passive ambient — partículas pequeñas violeta (`#5A2E7A`) flotando 0.5m alrededor del Mage cuando está en idle. Densidad baja (lifetime 2s, ~8 particles).
- **Staff emission glow** on MP regen (soft pulse, respecta paleta `#D4B065` oro apagado).
- **Glyph circles** on skill cast (geometría sagrada translúcida — Doctor Strange Eye of Agamotto ref).
- **NO fire/ice per-class** — esos son elemento-específicos, no Mage-base.

**Rim light color**: `#8A4AB0` (violeta claro glow, +30% luminance del primary). Más fuerte (intensity 0.6) durante cast — el Mage "se enciende" al trabajar.

### §2.3 Archer — Hermandad de Nahuelbuta + Gremio Forja de Lota

**Archer es dual**. El prompt wave3 da weight único **0.6 / 0.15s**. Este doc lo refina en **dos entradas canon** porque los lores son distintos (bosque silencioso vs industrial ruidoso). Dept B puede promediar a 0.6 si usa un AnimationTree único para la clase, pero **las anims específicas (ataque, cast) deben divergir**.

#### §2.3.1 Ranger (Nahuelbuta) — forest silent

**Silhouette keywords**: crouched · low · silent · bow-ready · hood-forward · camouflage-moteada

**Color accent palette** (canon `_class_lore_archer.md §4.1`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#556B2F` | Verde oliva (helechos valdivianos) — capa, túnica |
| Secondary | `#5C3A20` | Marrón tierra (corteza de pehuén) — botas, bandolera |
| Trim | `#8A8880` | Gris ceniza (capucha) + plata desgastada (punta flecha) |
| Accent ceremonial | `#C8213A` | Rojo copihue (solo en detalles ceremoniales) |

**Animation weight**: **0.5 / 0.15s** · poised, quick, silent. Walk = stealth-bias low amplitude. Draw anim = breath-hold pause (0.3s) antes del release.

**Particle philosophy**:
- **Leaf puff** on dodge roll (moss tone `#4A6A2A`, lifetime 0.3s).
- **Breath vapor** on draw full charge (cold biomes only — Hielo, Tormenta).
- **Arrow trail** sutil + corto (NO neón, NO chispas) — tonos madera.

**Rim light color**: `#6B8B3A` (verde hierba, muted). Bajo (intensity 0.2) — el Ranger **no brilla**.

#### §2.3.2 Artillero (Lota) — industrial steampunk-chilote

**Silhouette keywords**: erect · armed-visible · goggle-necked · bandolier-cross · boot-heavy

**Color accent palette** (canon `_class_lore_archer.md §4.2`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#4A4A50` | Gris acero — jubón reforzado |
| Secondary | `#8C6A3C` | Bronce oxidado (óxido minero) — placas, gafas, gears |
| Trim | `#E08530` | Naranja mecha (cartuchos, detalles) |
| Accent warn | `#D4C030` | Amarillo azufre (explosivos — zonas visibles) |
| Dark | `#1A1810` | Negro carbón (mina Lota — humo, pólvora) |

**Animation weight**: **0.7 / 0.18s** · mechanical, deliberate, weapon-heavy. Ballesta pesada → draw anim slower que Ranger. Reload chunks visibles (gear-turn frames).

**Particle philosophy**:
- **Smoke puff** on every shot (post-muzzle, 0.5s lifetime, carbón tone `#1A1810` lightened).
- **Spark shower** on reload (cartridge connect, 0.2s burst).
- **Explosion shockwave** on Artillero ultimate skills (canon skill `Ingeniería del Caos`).

**Rim light color**: `#E08530` (naranja mecha) — pulse on explosion precast (tell al party que viene boom).

### §2.4 Cleric — Sínodo de las Tres Cumbres

**Silhouette keywords**: tall · erect · dignified · robe-flowing · staff-vertical · 3-ramas-differ-in-accent

**Color accent palette común** (canon `_class_lore_cleric.md §4.1`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#F0EDE4` | Blanco limpio (sotana lana chilena) |
| Secondary | `#B89060` | Dorado apagado (cobre oxidado — NO brillante) |
| Base metal | `#D4C095` | Metal dorado opaco (humildad litúrgica) |

**Acento por rama** (canon `_class_lore_cleric.md §4.2`):

| Rama | Volcán | Hex accent | Uso |
|------|--------|-----------|-----|
| **Sanador (Aliento)** | Llaima | `#4A7AB0` azul volcánico | Bordes de sotana, báculo gota de agua |
| **Buffer (Coro)** | Osorno | `#C8213A` rojo copihue | Mangas + cinturón, libro de oraciones |
| **Exorcista (Verbo)** | Villarrica | `#D4601A` naranja llama | Capucha + runa en báculo |

**Animation weight** (dept B):

| Weight | Blend time | Feel |
|--------|-----------|------|
| **0.8** | **0.20s** | measured, ceremonial, posture-held |

**Justificación**: FFXIV White Mage/Scholar (canon ref) — role de sostén con gesto visible. Demon Slayer Pilares (canon) — disciplina espiritual. Cast anim con brazo extendido se mantiene 0.4s mínimo (lectura tooltip sinergia — BG3 ref).

**Particle philosophy**:
- **Sanador**: suave halo blanco-dorado (`#F0EDE4` + `#B89060`) al castear heal. Respira soft (fade in 0.5s).
- **Buffer**: rojo copihue en verso activo, nota musical icon simbólica on Verso del Guardián.
- **Exorcista**: runa naranja llama (`#D4601A`) en espiral al suelo al castear vs undead. **Más agresivo** visualmente que las otras 2 ramas — es la única devoción con enemigo natural nuclear canon `_world_canon.md §6`.

**Rim light color**: cycling por rama — Sanador azul volcánico, Buffer rojo copihue, Exorcista naranja llama. Intensity 0.4 base, sube a 0.7 durante ultimate (Honkai Star Rail framing ref).

### §2.5 Necromancer — Cofradía del Caleuche (DARK)

**Silhouette keywords**: tall · gaunt · hunched · long-robe-trailing · hood-deep · NOT-erect

- Ligeramente encorvada por peso ritual + HP drain frecuente. Caminan despacio. Sotana larga negra que arrastra (canon `_class_lore_necromancer.md §4`).

**Color accent palette** (canon `_class_lore_necromancer.md §4` DARK v2.0):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#0E0A12` | Negro profundo (casi negro, tono Chiloé húmedo) |
| Secondary | `#2E1830` | Púrpura de corteza podrida |
| Trim blood | `#4A1010` | Rojo sangre seca (acento) |
| Bone | `#C8BFA8` | Blanco hueso (símbolos rituales, tallados) |
| Rot | `#3A4530` | Verde podredumbre-musgo (mojadura cueva chilota) |

**NO canon**: dorado, brillante, saturación alta. Si aparece dorado, es bug de dirección.

**Animation weight** (dept B):

| Weight | Blend time | Feel |
|--------|-----------|------|
| **0.6** | **0.25s** | gaunt, slight hover, ritual-slow, deliberate toward-the-dead |

**Justificación**: Aura la Degolladora (Frieren canon ref) — estética hueso-esqueleto. Pontiff Sulyvahn (Dark Souls canon) — corrupción litúrgica. Walk cycle con leve hover 0.05m on footstep (no toca suelo limpio — canon dark v2.0 "la podredumbre filtrándose").

**Particle philosophy**:
- **Black veins** passive pasa por la piel del personaje cuando hay invocaciones activas (canon `necromancer.md §0` fantasía visual) — shader on-skin, NO partícula externa. A más invocaciones, más denso.
- **Purple smoke trail** on walk in caves (densidad baja, lifetime 1.5s, tone `#2E1830`).
- **Bone dust** on summon spawn (blanco hueso `#C8BFA8`, 0.4s burst al materializar esqueleto).
- **Blood drip** on HP cost skills (canon Vida-recurso) — partículas cortas `#4A1010`, lifetime 0.6s.

**Rim light color**: `#4A1A50` (púrpura-rojo muy oscuro). Intensity **baja** (0.15 base). **NUNCA brillante** — el Necromancer **no se ilumina**, se filtra. Subtle pulse on invocación cast.

### §2.6 Danzante de Sombras — Hijos de la Noche Austral

**Silhouette keywords**: thin · angular · flowing · low-off-center · engaging-desenfadada · weapons-concealed

- Ligera, relajada, engañosamente desenfadada. En reposo parece desarmado (canon `_class_lore_danzante_sombras.md §4`). Silueta baja desequilibrada en combate (a punto de caer = a punto de atacar).

**Color accent palette** (canon `_class_lore_danzante_sombras.md §4`):

| Rol | Hex | Uso |
|-----|-----|-----|
| Primary | `#0E0A1A` | Negro profundo |
| Secondary | `#1A1030` | Violeta medianoche (casi negro) |
| Trim ritual | `#8A1818` | Rojo sangre (solo en pintura corporal ritual clánica) |
| Accent metal | `#8A8A8A` | Gris luna (acentos metálicos) |
| Bone ceremony | `#C8BFA8` | Blanco hueso (medicinas + Hain Selk'nam ritual — solo ceremonias) |

**Animation weight** (dept B):

| Weight | Blend time | Feel |
|--------|-----------|------|
| **0.4** | **0.10s** | fluid, fast transitions, off-center, afterimage-ready |

**Justificación**: Tengen Uzui + Zenitsu (Demon Slayer canon) — velocidad visible. Soi Fon shunpo (Bleach canon) — desaparición en afterimage. Blend time mínimo del roster (0.10s) permite chain smooth a Paso de Sombra / Velo Nocturno sin visible snap.

**Particle philosophy**:
- **Shadow afterimage** on dash / Paso de Sombra (silhouette del frame −0.15s, fade 0.3s, violeta medianoche `#1A1030`).
- **Dissolve particles** on Velo Nocturno stealth enter — disuelto en partículas canon `_class_lore §4`.
- **Blade flash** short — **NO neon trail**. Corte Fugaz = 1-frame arc flash `#8A8A8A` gris luna.
- **Ritual paint glow** on ultimate (Danza de Mil Sombras) — pintura corporal blanco-rojo-negro del Hain Selk'nam activa rim intensity 0.9 durante 1.2s.

**Rim light color**: `#3A2050` (violeta frío). Intensity 0.3 base, sube a 0.9 on ultimate (pintura ritual activa).

### §2.7 Tabla resumen — animation weights (dept B handoff)

Tabla consolidada para `AnimationTree` tuning:

| Clase / Rama | Weight | Blend time | Feel keyword |
|--------------|--------|-----------|--------------|
| Warrior | 1.0 | 0.25s | heavy, grounded |
| Mage | 0.7 | 0.20s | deliberate, slight float |
| Archer Ranger | 0.5 | 0.15s | poised, silent |
| Archer Artillero | 0.7 | 0.18s | mechanical, deliberate |
| Cleric | 0.8 | 0.20s | measured, ceremonial |
| Necromancer | 0.6 | 0.25s | gaunt, slight hover |
| Danzante | 0.4 | 0.10s | fluid, fast transitions |

**Todos los valores** vienen de lore + refs citadas — **no ojo**. Archer split documentado en §2.3 con justificación (dual lore). Si B usa AnimationTree único para Archer, **promediar a 0.6 / 0.16s** como fallback (coincide con prompt wave3 base); pero attack/cast anims por rama **deben divergir**.

**`[proposal — revisar con playtest]`**: los valores son **primer pass** canon. Revisar después de smoke test visual dept B (iteración 1) — especialmente:
- ¿Mage 0.7 se siente "flotado demás" en combate defensivo? Ajuste a 0.65 si sí.
- ¿Danzante 0.10s causa visible snap en ultimate chain? Subir a 0.12s si sí.

---

## §3. Atmosphere per piso (5 pisos)

Crítico para dept D — estos valores alimentan `WorldEnvironment` + `DirectionalLight3D` per bioma.

**Regla canon firme**: los tints de techo (crystal ceiling) **ya son canon** en `crystal_ceiling.md §5`. Este doc **NO los re-decide** — los cita y agrega el resto de params atmosféricos (sun, fog, bloom, SSAO, skybox, saturation).

**Tinte canon recap** (de `crystal_ceiling.md`):

| Piso | Bioma | Ceiling hex | Mood canon |
|------|-------|------------|------------|
| 1 | Pradera Interior | `#C8E68A` | Verde-amarillo cálido, día primaveral |
| 2 | Bosque / Selva | `#4A7A3E` | Verde profundo, dosel denso |
| 3 | Hielo / Nieve | `#A8D8FF` | Cyan claro, frío duro |
| 4 | Tormenta / Cielo | `#7868A8` | Violeta-gris, nubes eléctricas |
| 5 | Dimensión Rota | `#C84AC8` | Magenta corrupto, wrong |

### §3.1 Piso 1 — Pradera Interior

**Evidencia canon**: `p1_pradera.md §4 Lighting canon` ya fija valores exactos. Este doc los **cita literal**.

| Param | Valor | Evidencia |
|-------|-------|-----------|
| Sun azimuth | -30° | canon `p1_pradera.md` |
| Sun elevation | -75° (picado desde el diamante arriba-izquierda) | canon `p1_pradera.md` |
| Sun energy | 3.5 | canon `p1_pradera.md` |
| Sun color | `#F5D8A0` | canon `p1_pradera.md` (dorado diamante) |
| Shadow color | `#B8C4D8` ambient (sombras azul-lavanda suaves) | canon `p1_pradera.md` |
| Fog color | `#C8D4E0` | canon `p1_pradera.md` |
| Fog density | 0.002 | canon `p1_pradera.md` |
| Bloom threshold | 0.85 | `[proposal]` — preservar dorado del diamante sin overbloom |
| Bloom intensity | 0.4 | `[proposal]` — god rays ya cargan, bloom solo suaviza highlight |
| SSAO intensity | 0.3 | `[proposal]` — suave, hay mucha luz directa |
| Saturation | 1.0 (neutral) | canon 60/25/15 cálidos/verdes/fríos ya balancea |
| Contrast | 1.05 | `[proposal]` — leve push para que god rays lean |
| Skybox HDRI | **NO skybox** — canon uses cave ceiling dome + focal diamond | canon `p1_pradera.md §5.5` |

**Regla crítica**: piso 1 **NO usa skybox HDRI**. Canon `p1_pradera.md §5.5` explicita que "el cielo se arma con background solid color + dome de caverna + diamante emisivo + shader volumétrico god rays". Dept D **respetar**.

### §3.2 Piso 2 — Bosque / Selva

Densidad verde valdiviano-araucaria (cross-ref `_class_lore_archer.md §2.1` Nahuelbuta). Dosel filtra luz.

| Param | Valor | Evidencia |
|-------|-------|-----------|
| Sun azimuth | -45° | `[proposal]` — sol entrando lateral por copas |
| Sun elevation | 20° (bajo, copas tamizan) | `[proposal]` — lore "poca luz penetra" canon `crystal_ceiling.md` |
| Sun energy | 1.8 | `[proposal]` — baja vs pradera (dosel) |
| Sun color | `#B0A078` | `[proposal]` — dorado filtrado cálido |
| Shadow color | `#1A2818` verde oscuro | `[proposal]` — sombras cálido-verdes, no gris neutro |
| Fog color | `#4A6A3C` | tinte canon `crystal_ceiling` modulado |
| Fog density | 0.008 | `[proposal]` — alta, dosel denso, húmedo |
| Bloom threshold | 1.0 | `[proposal]` — casi sin bloom (luz baja) |
| Bloom intensity | 0.2 | `[proposal]` |
| SSAO intensity | 0.6 | `[proposal]` — alta, mucha geometría orgánica |
| Saturation | 0.95 | `[proposal]` — levemente desaturado, realismo forestal |
| Contrast | 1.1 | `[proposal]` — zonas claras (claros) vs sombras densas |
| Skybox HDRI | PolyHaven `forest_01_*.hdr` | `[proposal — revisar]` nombre exacto por dept D |

### §3.3 Piso 3 — Hielo / Nieve

Cyan claro, luz dura cristalina (cross-ref Metroid Prime Phendrana Drifts — canon `crystal_ceiling.md §9`).

| Param | Valor | Evidencia |
|-------|-------|-----------|
| Sun azimuth | -60° | `[proposal]` — alto lateral |
| Sun elevation | 60° (alto, sol duro) | `[proposal]` — lore "luz dura" canon |
| Sun energy | 4.0 | `[proposal]` — intensa (reflejo hielo) |
| Sun color | `#E8F0FF` | `[proposal]` — blanco azulado frío |
| Shadow color | `#5A7A9A` | `[proposal]` — sombras azul frío saturadas |
| Fog color | `#D4E0F0` | `[proposal]` — casi blanco-azul |
| Fog density | 0.004 | `[proposal]` — media, aire seco helado |
| Bloom threshold | 0.75 | `[proposal]` — hielo glare canon |
| Bloom intensity | 0.7 | `[proposal]` — alta (brillo hielo) |
| SSAO intensity | 0.4 | `[proposal]` — media |
| Saturation | 0.85 | `[proposal]` — desaturado (frío) |
| Contrast | 1.15 | `[proposal]` — sombras duras |
| Skybox HDRI | PolyHaven `snow_field_*.hdr` | `[proposal — revisar]` nombre exacto dept D |

### §3.4 Piso 4 — Tormenta / Cielo

Plataformas flotantes, rayos, cielo abierto hostil (canon GDD §3).

| Param | Valor | Evidencia |
|-------|-------|-----------|
| Sun azimuth | -90° | `[proposal]` — sol ocluido lateral |
| Sun elevation | 40° (oculto tras nubes) | `[proposal]` |
| Sun energy | 1.5 | `[proposal]` — baja (nubes cargadas) |
| Sun color | `#A098B0` | `[proposal]` — violeta-gris filtrado |
| Shadow color | `#3A3050` | `[proposal]` — violeta oscuro |
| Fog color | `#7868A8` | canon `crystal_ceiling` tinte |
| Fog density | 0.005 | `[proposal]` — media-alta (aire cargado) |
| Bloom threshold | 0.8 | `[proposal]` — flashes de rayos |
| Bloom intensity | 0.9 | `[proposal]` — alta, rayos canon |
| SSAO intensity | 0.5 | `[proposal]` — media |
| Saturation | 0.9 | `[proposal]` |
| Contrast | 1.2 | `[proposal]` — flashes rayos ganan |
| Skybox HDRI | PolyHaven `stormy_sky_*.hdr` (con cloud movement si shader soporta) | `[proposal — revisar]` dept D |

**Nota dept D**: considerar **trigger flash** global de WorldEnvironment.background_energy_multiplier (+1.5 durante 0.1s) sync con VFX lightning strike — canon Honkai Star Rail framing ref.

### §3.5 Piso 5 — Dimensión Rota

Magenta corrupto, gravedad cambia, geometría imposible (canon GDD §3 + `crystal_ceiling.md`).

| Param | Valor | Evidencia |
|-------|-------|-----------|
| Sun azimuth | NO fija (rotating / flicker) | `[proposal]` — "wrong" canon |
| Sun elevation | variable 10-80° (inestable) | `[proposal]` |
| Sun energy | 2.5 (pulsa ±0.5) | `[proposal]` — inestabilidad |
| Sun color | `#E0A0E0` magenta suave | `[proposal]` |
| Shadow color | `#6A2870` | `[proposal]` — sombras magenta saturadas |
| Fog color | `#C84AC8` | canon `crystal_ceiling` tinte |
| Fog density | 0.006 | `[proposal]` — media |
| Bloom threshold | 0.6 | `[proposal]` — bajo (todo "brilla raro") |
| Bloom intensity | 1.0 | `[proposal]` — máxima (corruption glow) |
| SSAO intensity | 0.8 | `[proposal]` — muy alta (geometría imposible crea zonas oscuras raras — refuerza "wrong") |
| Saturation | 1.25 | `[proposal]` — hiper-saturación canon corrupción |
| Contrast | 1.3 | `[proposal]` — duro, inestable |
| Skybox HDRI | procedural shader (no HDRI real — canon "imposible") | `[proposal — revisar dept D]` — generar con noise + palette warp |

**Regla dept D**: piso 5 **NO puede usar HDRI realista**. Debe ser procedural o custom shader — "las reglas del juego se alteran" canon GDD §3 aplica también a iluminación.

### §3.6 Tabla resumen atmosphere (dept D handoff rápido)

| Piso | Sun energy | Fog density | Bloom intensity | SSAO | Saturation |
|------|-----------|------------|-----------------|------|-----------|
| 1 Pradera | 3.5 | 0.002 | 0.4 | 0.3 | 1.0 |
| 2 Bosque | 1.8 | 0.008 | 0.2 | 0.6 | 0.95 |
| 3 Hielo | 4.0 | 0.004 | 0.7 | 0.4 | 0.85 |
| 4 Tormenta | 1.5 | 0.005 | 0.9 | 0.5 | 0.9 |
| 5 Dim. Rota | 2.5±0.5 | 0.006 | 1.0 | 0.8 | 1.25 |

---

## §4. Toon shader canon — params per bioma

**Base**: shader toon stepped ramp + outline. Variables per-bioma documentadas aquí.

**Tabla canon** (prompt wave3 como base, ampliada con justificación):

| Bioma | Ramp steps | Rim intensity | Outline thickness | Outline color rule |
|-------|-----------|---------------|-------------------|---------------------|
| 1 Pradera | 3 | 0.3 | 0.02 | darker-than-albedo (−25% luminance) |
| 2 Bosque | 3 | 0.5 | 0.02 | darker-than-albedo (−30% luminance) |
| 3 Hielo | 3 | 0.4 | 0.02 | darker-than-albedo (−25% luminance) |
| 4 Tormenta | 3 | 0.6 | 0.02 | darker-than-albedo (−35% luminance) |
| 5 Dim. Rota | **4** | **0.8** | **0.04** | **invertido — glow bright (+40% luminance)** |

**Justificación**:
- **Ramp steps 3 default** — suficiente para legibilidad low-poly. Dim. Rota sube a 4 para dar **más tonos de corrupción** (gradiente "wrong" más gradual, no salto binario).
- **Rim intensity escalando** con "extrañeza" del bioma — Pradera 0.3 (luz natural), Tormenta 0.6 (cargada), Dim. Rota 0.8 (todo brilla raro).
- **Outline thickness 0.02 default** — 2× en Dim. Rota para reforzar "trazo cómic wrong".
- **Outline color regla canon**: default darker-than-albedo (sombra consistente). Dim. Rota **inverte** — outline es **glow** (brighter-than-albedo +40%). Esto comunica sin palabras que el piso **rompe las reglas visuales**, consistente con GDD §3 "las reglas se alteran".

**`[proposal — revisar con playtest]`**: los valores son primer pass. Si shader perf se degrada en arena 1-6 players, bajar Dim. Rota ramp steps a 3 (fallback) y compensar con stronger rim (1.0).

**Uniforms sugeridos** (dept D implementación):

```gdscript
# Para toon_shader.gdshader — uniforms per-bioma via WorldEnvironment material override
uniform int ramp_steps : hint_range(2, 5) = 3
uniform float rim_intensity : hint_range(0.0, 1.2) = 0.3
uniform float outline_thickness : hint_range(0.0, 0.08) = 0.02
uniform bool outline_invert_to_glow = false  # true solo en Dim. Rota
uniform vec3 outline_tint = vec3(1.0, 1.0, 1.0)  # multiplicador opcional por bioma
```

---

## §5. References board

Links a clips / screenshots / ArtStation. **3-5 refs por clase + 3-5 por piso**. Cada ref lleva **por qué** se cita. Links externos — **no incluir imgs pesadas en repo**.

### §5.1 Refs per-clase

#### Warrior
- **Dark Souls — Havel the Rock** (silhouette tank extremo) · https://darksouls.fandom.com/wiki/Havel_the_Rock — silhouette bulky/grounded canon.
- **Demon Slayer — Pilar de Piedra Gyomei** (Forma del Titán) · https://kimetsu-no-yaiba.fandom.com/wiki/Gyomei_Himejima — ref canon para Forma del Titán + calma masiva.
- **Berserk — Band of the Hawk manto** · https://berserk.fandom.com/wiki/Band_of_the_Hawk — disciplina militar, NO caos.
- **Weichafe mapuche histórico** (trarilonko + capa) · https://es.wikipedia.org/wiki/Mapuches — referencia cultural real canon `_class_lore_warrior.md §4`.
- **Attack on Titan — Garrison** · https://attackontitan.fandom.com/wiki/Garrison_Regiment — voto de guarnición (no vanguardia).

#### Mage
- **Frieren (Sousou no Frieren)** · https://frieren.fandom.com/ — paciencia académica + respeto por pequeños hechizos.
- **JJK — Gojo Domain Expansion** · https://jujutsu-kaisen.fandom.com/wiki/Domain_Expansion — casting dramático con pose + nombre visible (canon Supernova).
- **Doctor Strange — Eye of Agamotto** · https://marvel.fandom.com/wiki/Eye_of_Agamotto — geometría sagrada translúcida (Barrera Prismática).
- **Yatiris de la Isla del Sol** (documental / fotografías) · https://es.wikipedia.org/wiki/Yatiri — silueta cultural del sabio altiplano, canon.
- **Dark Souls — Crestfallen Warrior's Mage** (silhouette encapuchada, bastón alto) · https://darksouls.fandom.com/wiki/Magic_Swordsman — canon `_class_lore_mage.md §4`.

#### Archer
- **Hanzo (Overwatch)** · https://overwatch.fandom.com/wiki/Hanzo — ref Ranger: pause + disparo.
- **Ashitaka (Mononoke)** · https://princess-mononoke.fandom.com/wiki/Ashitaka — flecha con intención moral (Ranger).
- **Usopp Gear Second (One Piece)** · https://onepiece.fandom.com/wiki/Usopp — inventor ingenioso (Artillero).
- **TF2 Engineer** · https://tf2.fandom.com/wiki/Engineer — silueta Artillero canon con gears/gadgets visibles.
- **Mineros de Lota histórico** · https://es.wikipedia.org/wiki/Lota — referencia cultural real canon `_class_lore_archer.md §2.2`.

#### Cleric
- **Demon Slayer — 9 Pilares** (fervor espiritual con disciplina) · https://kimetsu-no-yaiba.fandom.com/wiki/Hashira — canon 3 devociones arquetipal.
- **FFXIV White Mage + Scholar** · https://ffxiv.consolegameswiki.com/wiki/White_Mage — rol sostén party canon.
- **Hellsing — Alexander Anderson** · https://hellsing.fandom.com/wiki/Alexander_Anderson — Exorcista con presencia física de combate (canon Villarrica/Verbo).
- **Machi mapuche** · https://es.wikipedia.org/wiki/Machi — Sanador cultural base (canon `_class_lore_cleric.md §4.4`).
- **Cazador de brujos chilote siglo XIX** · https://es.wikipedia.org/wiki/Brujer%C3%ADa_de_Chilo%C3%A9 — Exorcista cultural base canon.

#### Necromancer (DARK canon v2.0)
- **Berserk — Griffith pos-Behelit** · https://berserk.fandom.com/wiki/Griffith — pacto con costo irrecuperable canon.
- **Bloodborne — Cainhurst / Hunter of Hunters** · https://bloodborne.fandom.com/wiki/Cainhurst_Castle — aristocracia corrompida aesthetic.
- **Brujería chilota real (fotografías Martín Gusinde era + recuta Caleuche)** · https://es.wikipedia.org/wiki/Brujer%C3%ADa_de_Chilo%C3%A9 — canon cultural dark.
- **Frieren — Aura la Degolladora** · https://frieren.fandom.com/wiki/Aura — estética hueso + moralidad dark alineada v2.0.
- **Dark Souls — Pontiff Sulyvahn + Archdeacon McDonnell** · https://darksouls.fandom.com/ — corrupción con estética litúrgica pervertida.

#### Danzante de Sombras
- **Demon Slayer — Tengen Uzui** · https://kimetsu-no-yaiba.fandom.com/wiki/Tengen_Uzui — flamboyancia + letalidad sin contradicción.
- **Bleach — Soi Fon Shunpo** · https://bleach.fandom.com/wiki/Soi_Fon — desaparición en afterimage (canon Paso de Sombra).
- **Ghost of Tsushima — Jin post-Ghost** · https://ghostoftsushima.fandom.com/wiki/Jin_Sakai — transición honor → shadow canon.
- **Selk'nam Hain ceremonia (fotografías Martin Gusinde)** · https://es.wikipedia.org/wiki/Selk%27nam — pintura corporal ritual blanco/rojo/negro canon cultural.
- **JJK — Maki Zenin** · https://jujutsu-kaisen.fandom.com/wiki/Maki_Zenin — puro físico, peligrosa en silencio.

### §5.2 Refs per-piso

#### Piso 1 — Pradera Interior
- **SAO Piso 1 (Aincrad Floor 1)** · https://swordartonline.fandom.com/wiki/1st_Floor — pradera abierta con horizonte artificial canon.
- **Valheim Meadows** · https://valheim.fandom.com/wiki/Meadows — paleta verde pastel low-poly legible canon.
- **Ragnarok Online — Prontera Fields** · https://irowiki.org/wiki/Prontera_Field — flores dispersas densidad media.
- **Risk of Rain 2 — Distant Roost** · https://riskofrain2.fandom.com/wiki/Distant_Roost — shape language low-poly + lectura a distancia.
- **Kimetsu no Yaiba (anime)** · canon `p1_pradera.md §2` — luz volumétrica cálida + shape orgánicidad (filosofía visual proyecto).

#### Piso 2 — Bosque / Selva
- **Princess Mononoke — Forest of the Deer God** · https://princess-mononoke.fandom.com/ — dosel denso húmedo con sombras cálidas.
- **Zelda BOTW — Great Hyrule Forest** · https://zelda.fandom.com/wiki/Great_Hyrule_Forest — escala bosque denso con atmósfera canon.
- **Hollow Knight — Greenpath** · https://hollowknight.fandom.com/wiki/Greenpath — aesthetic minimalista forestal canon (ref `_world_references.md §3`).
- **Selva Valdiviana (fotografías reales Chile)** · https://es.wikipedia.org/wiki/Bosques_valdivianos — cultural base Hermandad de Nahuelbuta canon.
- **Risk of Rain 2 — Verdant Falls** · https://riskofrain2.fandom.com/wiki/Verdant_Falls — low-poly bosque con cascadas.

#### Piso 3 — Hielo / Nieve
- **Metroid Prime — Phendrana Drifts** · https://metroid.fandom.com/wiki/Phendrana_Drifts — canon citado en `crystal_ceiling.md §9` — luz azul filtrada "bajo lente natural".
- **Castlevania (series) — ice caverns** · https://castlevania.fandom.com/ — ref canon `crystal_ceiling.md §9`.
- **Breath of the Wild — Hebra Mountains** · https://zelda.fandom.com/wiki/Hebra_Mountains — neve + cyan shadow.
- **Dark Souls III — Irithyll of the Boreal Valley** · https://darksouls.fandom.com/wiki/Irithyll_of_the_Boreal_Valley — hielo con luz dura + saturación baja.
- **Hollow Knight — Crystal Peak** · https://hollowknight.fandom.com/wiki/Crystal_Peak — cristales emisivos low-poly.

#### Piso 4 — Tormenta / Cielo
- **Laputa (Castle in the Sky)** — plataformas flotantes canon.
- **Zelda BOTW — Thunderstorm weather** · https://zelda.fandom.com/ — flash rayos + violet tint canon.
- **Genshin Impact — Inazuma** · https://genshin-impact.fandom.com/wiki/Inazuma — purple storm aesthetic.
- **Risk of Rain 2 — Sky Meadow** · https://riskofrain2.fandom.com/wiki/Sky_Meadow — arena flotante low-poly.
- **Honkai Star Rail — Fragmentum (tormenta)** · https://honkai-star-rail.fandom.com/ — framing cinematográfico canon ref.

#### Piso 5 — Dimensión Rota
- **Made in Abyss — Capas profundas (layer 6/7)** · https://madeinabyss.fandom.com/ — wrongness ambiental canon (filtro: sin body horror — canon `_world_canon.md §7`).
- **Hollow Knight — The Abyss / White Palace** · https://hollowknight.fandom.com/wiki/The_Abyss — geometría imposible + magenta/blanco.
- **Control (Remedy) — The Oldest House shifting rooms** · https://control.fandom.com/ — geometría que cambia canon.
- **Antichamber** · https://antichamber-game.fandom.com/ — geometría imposible con outline canon.
- **JJK — Domain Expansion infinite void** · https://jujutsu-kaisen.fandom.com/ — framing ultimate cinematográfico + wrongness.

---

## §6. Integration handoff

### §6.1 Para dept B (Animation Tier 2)

**Canon files a leer ANTES de tunear AnimationTree**:
1. `game/docs/art/_art_direction_bible.md §2` — weights + blend times per clase (este doc, §2.7 tabla resumen)
2. `game/docs/lore/_class_lore_*.md §4 Aesthetic / postura` — los 6 docs per-clase — silhouette + postura concreta
3. `game/docs/skills/_system.md §5quinquies` — Cooldown philosophy: **animación = cooldown principal**. Las anim blend times deben respetar esto.

**Params canon** que dept B NO debe inventar:
- Animation weights per clase (§2.7 tabla)
- Blend times per clase (§2.7 tabla)
- Feel keyword (guía el wind-up y recovery frames)

**Params que dept B SÍ decide**:
- Frame exacto de anims concretas (idle, walk, run, attack_light, attack_heavy, cast_start, cast_loop, cast_end, dodge, hit_react, death)
- IK targets (manos en escudo/báculo/arco/daga)
- Root motion sí/no per clase (recomendación: sí Warrior, sí Cleric; no Mage casting, no Danzante dash)

### §6.2 Para dept D (Visual Pipeline Tier 1)

**Canon files a leer ANTES de setup WorldEnvironment + toon shader**:
1. `game/docs/art/_art_direction_bible.md §3 + §4` — atmosphere params + toon shader params per bioma (este doc)
2. `game/docs/art/crystal_ceiling.md` — tint canon por bioma (**NO sobreescribir**)
3. `game/docs/art/p1_pradera.md §3 + §4` — paleta + lighting Godot canon piso 1 (**NO sobreescribir**)

**Params canon** que dept D NO debe inventar:
- Ceiling tint hex per-bioma (viene de `crystal_ceiling.md` — cita, no decidas)
- Sun color + energy piso 1 (viene de `p1_pradera.md` — cita, no decidas)
- Toon shader ramp steps / rim intensity / outline thickness per bioma (§4 tabla)

**Params que dept D SÍ decide**:
- HDRI file exacto (PolyHaven names marcados `[proposal — revisar]` en §3)
- Shader implementation details (uniforms exacto, blend modes, atlas packing)
- Performance tradeoffs (si FPS baja en arena 80m, bajar ramp steps Dim. Rota a 3 con fallback compensatorio)

### §6.3 Handoff checklist

Dept B (Animation Tier 2) recibe:
- [x] Animation weights per 6 clases (§2.7)
- [x] Blend times per 6 clases (§2.7)
- [x] Feel keyword per clase (§2.1-§2.6)
- [x] Silhouette keywords (§2.1-§2.6)
- [x] Archer dual split documentado (§2.3.1 + §2.3.2)
- [x] Refs board per clase (§5.1)

Dept D (Visual Pipeline Tier 1) recibe:
- [x] WorldEnvironment params per 5 pisos (§3.1-§3.5 + §3.6 tabla)
- [x] Toon shader uniforms per bioma (§4)
- [x] Paleta accent per 6 clases (§2.1-§2.6) — para material_override per-character
- [x] Rim light color + intensity per clase (§2.1-§2.6)
- [x] Particle philosophy per clase (§2.1-§2.6) — guía decisiones GPUParticles3D
- [x] Refs board per bioma (§5.2)

---

## §7. No goals de este doc

- **Character model specs** (mesh poly count, bone count, texture atlas exacto) — wave4+ (`character_specs.md` futuro)
- **VFX per-skill** (ej: frame-by-frame Supernova) — doc aparte pendiente (`vfx_canon.md` no existe aún — FLAG)
- **UI theme** (colores HUD, fonts, iconografía) — fase Alpha, dept UI
- **Audio direction** (ambient per-bioma, SFX per-skill) — doc aparte futuro
- **Cinematic framing de ultimates** (Honkai Star Rail ref) — requiere `vfx_canon.md` + cutscene system; bloqueado

---

## §8. Red flags + pendientes

1. **`vfx_canon.md` NO existe** en `game/docs/art/` — el prompt wave3 lo menciona como canon ref. Dept D debe crearlo antes de empezar VFX per-skill (fuera de scope de este doc).
2. **Skybox HDRI PolyHaven names marcados `[proposal — revisar]`** — dept D debe confirmar nombres exactos de archivo al implementar (o elegir equivalente).
3. **Piso 5 shader procedural** — no hay canon previo de shader corrupto. Dept D diseña el shader en su worktree y actualiza este doc con params finales.
4. **Archer dual animation weight** — split en 2 entradas (§2.3.1 + §2.3.2) — dept B debe decidir si usa AnimationTree único con fallback 0.6/0.16s o dos trees separados. Recomendación canon: **dos trees separados** para respetar lore (silent forest vs mechanical industrial).
5. **Playtest values `[proposal]`** — todos los valores con ese tag se revisan tras iteración 1 de dept B/D con smoke test visual. No tratar como canon duro hasta validar.

---

## §9. Cross-ref

- **World canon**: `_world_canon.md` (esencia chilena + Necromancer dark + Taberna)
- **Class lore v2.0**: `_class_lore_warrior/mage/archer/cleric/necromancer/danzante_sombras.md` — identidad cultural per clase
- **Skills canon**: `_system.md` — tipos skill (channel/melee/projectile) → tipos anim canon
- **Skills per-class v2.0**: `{clase}.md` — pool skills → tipos anim esperadas (dept B ref)
- **Art canon existente**:
  - `crystal_ceiling.md` — ceiling tint per bioma (NO sobreescribir)
  - `p1_pradera.md` — paleta + lighting canon piso 1 (NO sobreescribir)
  - `skill_icons.md` — iconos UI (fuera scope este doc)
  - `drop_vfx.md`, `mimic.md`, `ambient_fauna.md` — sub-docs art específicos
- **World references**: `_world_references.md` — 26+ refs canon aprobadas (Danmachi/DRG/Hades/Frieren/JJK/Demon Slayer/etc)
- **GDD**: `GDD_DungeonParty.md §3` (pisos + torre), §4 (clases)

---

*Art Direction Bible v1.0. Canon consolidado de dirección visual + feel animado + atmosphere per piso. Dept B y D usan este doc como single source of truth para wave3. Cambios al canon se versionan aquí primero.*
