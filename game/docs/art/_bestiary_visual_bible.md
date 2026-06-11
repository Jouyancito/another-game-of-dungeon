# Biblia Visual del Bestiario — Dungeon Party

**Versión**: 0.1 (spine) · **Fecha**: 2026-06-09 · **Estado**: vivo, se llena con referencias de Joan
**Departamento**: Art Direction · **Canon padre**: `_art_canon.md` (v2.0)

> **Qué es**: el ADN visual COMPARTIDO que hace que todas las criaturas lean como UN solo mundo
> (no 18 bichos sueltos). Captura lo que Joan pidió: *"los parecidos entre cada uno, las gamas
> de colores, los diseños, los bordes"* — la cohesión, no el asset individual.
>
> **Qué NO es** (y dónde vive eso):
> - **Qué modelo/IA tiene cada mob** → `_enemy_integral_plan.md` (model source + runtime-safe).
> - **Cómo escala el color del mismo bicho por piso** → `enemy_tier_system.md §8`.
> - **Stats/balance** → `balance_v2.md` + `enemy_tier_system.md`.
> - **Reglas ecológicas del mundo** → `_world_coherence.md`.
>
> Esta biblia SINTETIZA esos docs en la capa VISUAL-DE-IDENTIDAD y agrega lo que falta:
> la firma de familia + las fichas por criatura.

---

## 0. Cómo se usa — Reference Intake Protocol

El flujo que Joan describió, formalizado. Por cada criatura nueva:

1. **Joan trae una referencia** (imagen, link, juego, o descripción). Ej: "el golem como el de Metin2".
2. **Claude extrae 4 cosas** de la ref y las cruza con el canon:
   - **Silueta** → ¿a qué familia pertenece? (§3). ¿Cuál es su 1 quiebre asimétrico?
   - **Gama** → dominante + acento, dentro de la paleta del bioma (§2). El acento = pista de nicho.
   - **Borde/firma** → siempre la firma DP (§1). Qué notch de geometría la hace única.
   - **Nicho** → ¿dónde vive y qué come? La morfología debe leerse desde ahí (§4).
3. **Se decide el build-method** (§5): pack-reskin / bpy-bespoke / blob-híbrido.
4. **Se llena la ficha** (§6). La ficha es el contrato visual de esa criatura.

Regla de oro del proceso: **Claude saca los parecidos, Joan corrige el rumbo.** La biblia
crece criatura por criatura; no se inventa todo de una.

---

## 1. ADN compartido — Firma de familia (TODA criatura lo obedece)

Heredado de `_art_canon.md §8` (toon per-bioma) + `§9` (DP_ToonGrounded). Esto es lo que hace
que un slime, un golem y un halcón se sientan del MISMO juego aunque no se parezcan en nada.

- **Flat-shade + 1 chaflán duro.** Toon ramp de 3 bandas (sombra/medio/luz), sin gradientes
  suaves. Donde la geometría permite, UN chaflán chico da una banda-media secundaria.
- **Sombra nunca negra.** Tinte de sombra `#7A8FC4` (cool slate-blue), fuerza 0.45. Specular OFF
  (mate, no PBR). PBR low-poly = "mobile genérico" (canon §2.2).
- **Outline solo en criaturas/personajes** (no terreno). Inverted hull, grosor 0.002-0.004,
  color = complementario DESATURADO del albedo (no negro). En Dim. Rota (P5) el outline se
  INVIERTE a glow: señal de que el piso rompe las reglas (§8.1).
- **Silueta legible a 20m por FORMA, no color.** Test: screenshot 1-bit gris a 20m → la criatura
  se identifica por contorno. Daltónico + luz baja deben bastar. Si dos criaturas comparten
  silueta a 20m = **bug de dirección**, se corrige con prop asimétrico.
- **Bottom-weighted.** Peso abajo, base ancha. El detalle vive en MUESCAS de geometría, no en
  textura de superficie. Albedo plano casi siempre.
- **Saturación = profundidad en la torre.** P1-20 alta (70-100%), baja al descender. El bicho
  NUNCA compite en saturación con el color de una skill (el bioma es callado, -27% desat).

---

## 2. Gama de color — dos ejes

El color de una criatura se decide en DOS ejes que se multiplican:

### Eje A — por bioma (hospitalidad + lore). De `_art_canon.md §5/§9/§10`.

| Piso | Bioma | Dominantes | Acento (= pista) |
|---|---|---|---|
| **P1** | Pradera Interior (caverna-diamante) | `#8FAE6B` verde pastel, `#E8D4A0` god-ray, `#7B5A3C` madera | jewel `#5FD8FF` cyan / `#D1A373` ámbar / `#B06FFF` violeta (SOLO cristales) |
| **P2** | Bosque del Lindero | `#2E3D24` verde oscuro, `#3D2818` tronco | `#F5C76A` dorado luciérnaga · `#7ECFD8` cian hongo |
| **P3** | Ruinas / Jotunheim | `#E0C58A` piedra cálida, `#5C7A34` musgo | `#A8D4E8` azul fantasma · `#C8E4F0` mariposa |
| **P4** | Paso / Al-Samum | `#C0A88C` piedra, `#8C6A44` tierra | violeta-gris tormenta `#7868A8` |
| **P5** | Umbral Fragmentado | desaturado base | HIPER-saturado magenta `#C84AC8` (peligro/imposible) |

**Regla de temperatura = hospitalidad** (§10.2): cálido = safe · neutro = exploración ·
frío = peligro/boss · magenta saturado = peligro inmediato. El color de una criatura
comunica su rol ANTES de que ataque.

### Eje B — por tier (mismo bicho, más profundo). De `enemy_tier_system.md §8`.

El mismo arquetipo escala color con la profundidad. Ej slime: verde(T1) → marrón pantano(T5)
→ ámbar ácido(T10) → cristal(T25) → violeta-vacío(T50) → blanco-primordial(T100). El jugador
SABE que un slime ámbar es más peligroso que uno verde sin leer stats.

> En alfa solo tocamos P1 (Tier 1). El Eje B queda documentado para no contradecirlo después.

---

## 3. Familias de silueta (read-at-20m)

Seis arquetipos. Cada criatura cae en uno. La regla anti-colisión: **dos arquetipos no pueden
compartir silueta a 20m.** El "1 quiebre asimétrico" es lo que individualiza dentro de la familia.

| Familia | Forma base | Quiebre que individualiza | Criaturas P1 |
|---|---|---|---|
| **Blob / amorfo** | icosphere achatada, sin extremidades | qué color translúcido "comió" | slime, mini, king |
| **Cuadrúpedo** | bajo, 4 patas, cola | cola/orejas = rol (lobo carga, zorro hurta) | lobo, zorro, cabra, rata |
| **Volador** | cuerpo + alas, silueta en cielo | envergadura + cola (pájaro vs halcón) | pájaro, halcón |
| **Artrópodo** | segmentado, patas múltiples | arma-cola / pinzas | escorpión, avispa |
| **Construct** | angular, simétrico-ish, pesado | un lado más "roto"/cristalizado | **golem** |
| **Humanoide** | bípedo, hombros, arma en mano | silueta de arma (espada vs arco) | bandido melee, bandido arquero |
| *(objeto)* | mimetiza un prop | el "tell" antes de revelar | mimic (cofre) |

Refs de silueta por familia (de `_art_canon.md §6`): construct pesado = Havel the Rock /
Gyomei (peso, base ancha). Volador alto = halcón sube la escala para verse a 10-14m.

---

## 4. Curación endémica — la morfología se lee desde el nicho

Principio Axlin (`_floor_sketches.md` + `_world_coherence.md §4`): *"las criaturas son endémicas
— pertenecen a su ambiente, su morfología es legible desde el nicho que ocupan."*

- Una criatura **pertenece** a su bioma. Su forma cuenta su rol ecológico.
  Ej: el slime es semitransparente y **brilla del color que acaba de absorber** → parásito de
  fuente de luz. Eso ES su diseño, sale del nicho.
- **El boss = culminación ecológica**, no un bicho fuerte random. King Slime = *"el que comió
  demasiada bioluminiscencia"* (`§4.2`). Su silueta sale del nicho dominante del piso.
- **Los NO-endémicos se marcan como tales.** Bandidos = *"evidencia de que otros estuvieron acá"*
  (humanoides, rompen la fauna a propósito). Mimic = *"parásito de la dinámica de exploración,
  no del ecosistema mineral"*. Su rareza visual es intencional.
- **Gradiente de realidad** (`§9`): en P1 la morfología obedece proporciones REALES (ancla de
  familiaridad). Descender relaja: P3 escalas titánicas, P5 puede romper cualquier regla. Una
  proporción rota en P1 es bug; en P5 es diseño.

> **Tensión endémica P1 (importante)**: P1 es **caverna de cristal/diamante**. El canon dice
> textual: *"un golem de piedra volcánica en P1 NO tiene lógica."* → en P1 lo endémico es un
> construct de **cristal/geoda** (la roca que el cristal colonizó), no piedra genérica. Ver §6.5.

---

## 5. Build-method — los 3 baldes (cómo se fabrica cada uno)

El eje real no es "todo en Blender". Es **HARD-SURFACE vs ORGÁNICO**, con la **animación** como
muro. (Auditoría 2026-06-09 + scope guard de la skill `blender-asset-smith`.)

| Balde | Criaturas | Método | Por qué |
|---|---|---|---|
| **Orgánico** | lobo, zorro, cabra, rata, serpiente, escorpión, pájaro, halcón, tortuga, +bandidos | **pack re-skin** (gltf importado + material override) | bpy script no hace anatomía curva + rig + ciclo de caminar. Sale caja deformada. |
| **Construct / duro** | golem (y futuros: crystal elemental, geoda) | **bpy bespoke** (`gen_*.py`) + pose en Godot | mismo vocabulario que crystal/rock/pillar/altar. Malla static, animación lumber en Godot |
| **Blob** | slime, mini, king | **bpy malla** (icosphere+displace) + **jiggle en Godot** | modelar el blob en bpy es fácil y on-style; el squash-stretch va en shader/tween Godot |

Estado actual del roster (de `_enemy_integral_plan.md`): la mayoría es **proc** (EnemyModelBuilder)
o **gltf** importado; solo `gen_crystal.py` es bpy-bespoke hoy. El plan integral ya recomendó swaps
de modelo (golem→orc, bandidos→ninja/orc); esta biblia decide la IDENTIDAD visual, el plan integral
decide el modelo-fuente. Se complementan.

### Tabla de decisión P1 (build-method + endémico)

| Criatura | Familia | Endémico P1? | Balde | Acento de color |
|---|---|---|---|---|
| slime / mini | blob | ✅ sí (come bioluminiscencia) | blob | el color del cristal que comió |
| king_slime | blob/boss | ✅ culminación | blob | sobresaturado (exceso) |
| golem | construct | ⚠️ solo si es cristal/geoda | construct (bpy) | vetas jewel cyan/ámbar/violeta |
| lobo / zorro | cuadrúpedo | ✅ predador / carroñero | pack | pelaje desat, ojos acento |
| cabra / rata | cuadrúpedo | ✅ herbívoro / carroñero | pack | tierra/gris |
| serpiente / escorpión | artrópodo-bajo | ✅ emboscada / árido | pack | acento veneno |
| pájaro / halcón | volador | ✅ altura/térmica | pack | silueta cielo |
| tortuga | cuadrúpedo-lento | ✅ ribera | pack | caparazón |
| avispa | artrópodo-volador | ✅ colonia/nido | pack | franjas alarma |
| bandidos (x2) | humanoide | ❌ no (intrusos) | pack | tela oscura, no-fauna |
| mimic | objeto | ❌ no (parásito explor.) | proc (autorado) | mimetiza cofre |

---

## 6. Fichas por criatura — P1 (se llenan con referencias)

### Template de ficha

```
NOMBRE
- Nicho:        dónde vive / qué come (morfología se lee de acá)
- Silueta:      familia (§3) + 1 quiebre asimétrico
- Gama:         dominante + acento (de la paleta del bioma §2)
- Firma/borde:  qué notch de geometría la hace única (sobre la firma DP §1)
- Referencias:  [PENDIENTE — Joan]
- Build:        balde (§5) + modelo-fuente
- Notas anim:   qué movimiento la define
```

> Las fichas se completan a medida que Joan trae referencias. Abajo, golem como ejemplo trabajado
> (v0.2, refs recibidas — piedra+musgo+ojos cyan). El resto son slots.

### 6.5 GOLEM — ejemplo trabajado (v0.2, refs de Joan recibidas 2026-06-09)

**Dirección resuelta: golem de PIEDRA + MUSGO (la pradera lo colonizó) + ojos/núcleo cyan.**
Refs de Joan = 3 imágenes: (1) golem-ecosistema con rocas flotantes y arbolitos encima
[eeden artwork], (2) bruto de piedra musgosa, encorvado, ojos cyan + ancla [stylized game art],
(3) golem-roca realista con cara tallada, musgo arriba, junto al agua. Vibe líder = **img 2**
(silueta más limpia y legible a 20m + ojos cyan = acento jewel), con riqueza de img 1 (vegetación
colonizadora) y cara tallada de img 3.

- **Nicho**: roca antigua dormida siglos en zona húmeda/sombría de la pradera interior → el musgo,
  pasto, hongos y flores le crecieron encima (regla de halo de humedad, `_world_coherence` V1/H5).
  Endémico por DOBLE vía: vegetación (pradera) + ojos/núcleo cyan (cristal-caverna). Resuelve la
  tensión "piedra no es endémica en caverna-cristal" — no es piedra desnuda, es piedra *viva de la
  pradera*.
- **Silueta**: familia **construct**, encorvado, brazos grandes con nudillos bajos (postura
  juggernaut), bottom-weighted. Quiebre asimétrico = **un hombro más cubierto de vegetación** que
  el otro. Cara = plano tallado con dos cuencas (ojos emisivos).
- **Gama**: cuerpo piedra desaturada `#6B6258` gris cálido → musgo verde pradera `#5C7A34` /
  `#8FAE6B` (los MISMOS verdes del piso) · ojos/grietas-núcleo cyan emisivo `#5FD8FF` (acento
  jewel) · toques de hongo (rojo/blanco pequeño) y flor. Todo dentro de la paleta P1 (§2).
- **Firma/borde**: cuerpo flat-shade chaflanado (firma DP §1) + outline complementario desat.
  Detalle por muescas de roca, no textura. Núcleo/ojos = facetas emisivas (reusa lógica de
  `gen_crystal.py`).
- **Cohesión con el piso**: la vegetación NO se modela nueva — se **reusan los gltf de scatter de
  pradera** (musgo/hongos/flores que ya tenés) como hijos en hombros/espalda/cabeza. El golem
  literalmente lleva puesta la pradera. ESTE es el "parecido con el resto del piso".
- **Referencias**: ✅ 3 imágenes de Joan (descritas arriba). Pendiente confirmar: ¿rocas flotantes
  sí/no? ¿cuánta vegetación (sutil vs jardín andante)?
- **Build**: **asset COMPUESTO** (no reskin):
  1. Cuerpo → `gen_golem.py` bpy bespoke ✅ HECHO (2026-06-09): pila de ~15 rocas chaflanadas +
     facetas/displace en masas grandes + escombro en juntas + cara tallada. **2464 tris**, 2.48m,
     Z-up (verificado vs orc). Output: `enemies/big/golem_dp_body_01.glb`. Static-pose.
     Nota: "más definición de realismo" (Joan) resuelto por GEOMETRÍA (facetas/escombro), NO PBR
     (canon §2.2 — PBR rompería la pradera toon).
  2. Vegetación → reusar scatter gltf de pradera como child nodes / MultiMesh.
  3. Ojos/núcleo → emisivo cyan vía material_override Godot.
  4. *(opc.)* 2-3 rocas chaflanadas chicas con hover lento (tween Godot) = guiño a img 1.
  - *Alternativa barata (validar rápido)*: reskin `enemy_orc.gltf` gris + musgo scatter encima +
    ojos cyan. Menos único pero 1 sesión. bpy-bespoke queda para v2.
- **Notas anim**: juggernaut lento (IA actual intacta). Dormant = parece un peñasco musgoso
  (squash 1.2/0.5/1.2) → awaken tween al acercarse. Lumber: el peso se siente en el delay.

### Slots pendientes (orden sugerido por payoff de ambiente, de Joan: golem → bandido → lobo)

- 6.1 **Bandido melee** — humanoide, no-endémico. [slot]
- 6.2 **Bandido arquero** — humanoide ágil, silueta de arco. [slot]
- 6.3 **Lobo** — cuadrúpedo predador, manada. [slot]
- 6.4 **Slime / mini** — blob endémico, brilla lo que comió. [slot]
- 6.5 **Golem** — ✅ ejemplo trabajado arriba.
- 6.6 **King Slime (boss)** — culminación ecológica. [slot]
- 6.7..N — zorro, cabra, rata, serpiente, escorpión, pájaro, halcón, tortuga, avispa, mimic. [slots]

---

## Changelog

- **v0.1 (2026-06-09)** — Spine. ADN compartido + 2 ejes de color + 6 familias de silueta +
  curación endémica + 3 baldes de build-method + tabla de decisión P1 + golem como ejemplo
  trabajado. Sintetiza `_art_canon §8/§9`, `enemy_tier_system §8`, `_enemy_integral_plan`,
  `_world_coherence §4/§9`. Fichas per-criatura esperando referencias de Joan.
- **v0.2 (2026-06-09)** — Ficha golem §6.5 resuelta con 3 refs de Joan: piedra + musgo (pradera
  colonizadora) + ojos/núcleo cyan. Endémico por doble vía (vegetación + cristal). Build =
  asset compuesto (bpy body + reuse scatter pradera + emisivo Godot). Pendiente: confirmar scope
  (bespoke vs reskin barato) + detalles (rocas flotantes, cantidad de vegetación).
