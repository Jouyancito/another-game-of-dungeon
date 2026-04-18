# Skill Icons — canon art + convenciones

**Canon art** para iconos de skills del hotbar + panel de habilidades.
Alimenta el campo `icon: Texture2D` de los `SkillResource .tres` que B crea
en Fase 0+.

---

## 1. Convención de path

```
game/assets/ui/icons/skills/{clase}/{skill_id}.svg
```

- `{clase}` = `warrior | mage | archer | cleric | necromancer | danzante_sombras | placeholder`
- `{skill_id}` = snake_case del skill (coincide con id del `.tres`).

Ejemplos:
- `game/assets/ui/icons/skills/warrior/shield_bash.svg`
- `game/assets/ui/icons/skills/mage/fireball.svg`
- `game/assets/ui/icons/skills/cleric/divine_heal.svg`

Los placeholders van en:
- `game/assets/ui/icons/skills/placeholder/slot_1.svg` … `slot_8.svg`

---

## 2. Specs técnicas

| Field | Valor |
|---|---|
| Formato | **SVG** (Godot 4 importa nativo + escala sin pérdida). PNG aceptable solo si un skill necesita raster detalle — default SVG. |
| viewBox | `0 0 64 64` |
| Tamaño declarado | `width="64" height="64"` |
| Área útil | 56×56 px con 4px padding (legible a 32×32 en HUD comprimido) |
| Fondo | `#18181F` (coherente con Tooltip bg `#0D0D1A` y panels inventory) |
| Border radius | 6 (esquinas redondeadas suaves) |
| Stroke outline base | 2-3px |
| Transparencia | SVG sin fill en el viewBox exterior es transparente — no forzar alpha |

---

## 3. Paleta por clase (refs `_class_lore_*.md`)

| Clase | Primario | Accent | Energía | Feel |
|---|---|---|---|---|
| Warrior | Acero `#7A7A82` | Dorado tibio `#D4A040` | Rojo Rage `#E04828` | Gruñido metálico, impacto |
| Mage | Violeta diaguita `#6E3FA8` + azul andino `#3E78B8` | Blanco tiza `#F0ECD8` + oro apagado `#C89F4A` | Cyan lapis `#5EBFE8` (arcano) / Rojo (fuego) / Cyan (hielo) | Altiplano sabio, geometría sagrada |
| Archer | Verde bosque `#4A7A3E` | Cuero `#8A6030` | Dorado `#D0B040` (concentración) | Precisión natural, viento |
| Cleric | Blanco `#E8E8D0` | Dorado sagrado `#F0C060` | Cyan `#80D0E0` (cure) / Rosa `#E080B0` (buff) | Luz, fe |
| Necromancer | Violeta oscuro `#4A2858` | Hueso `#D8C8A0` | Verde necrótico `#60B050` | Decadencia, maldición |
| Danzante de Sombras | Negro `#1A1A22` | Plata `#B0B0B8` | Violeta `#8040A0` (sombra) / Rojo sangre `#A03030` (burst) | Silencio, golpe fantasma |

**Usar al menos 2 colores** por icon: silueta en primario, accent para highlight/detalle. Tercer color (energía) opcional para resaltar el tipo de daño/efecto.

---

## 4. Criterios de legibilidad

- **Silueta reconocible a 32×32**: si a la mitad del tamaño no se entiende de qué es el icon, refactorizar shape.
- **Contraste mínimo**: bg `#18181F` + shape primario con lightness ≥ 45% garantiza silueta clara.
- **Evitar texto**: los placeholders usan números (son placeholders, OK). Skills reales NO deben tener letras — puro shape/iconografía.
- **Un verbo visual por icon**: "bash" = escudo + impacto, "heal" = cruz + glow, "fireball" = esfera + llamas. Si se entiende en 1 segundo, funciona.

---

## 5. Iconos implementados

### 5.1 Placeholders (8/8)

`game/assets/ui/icons/skills/placeholder/slot_{1-8}.svg`

Contorno cuadrado + color distinto + número centrado. Sirven para:
- Slots vacíos del hotbar (Fase 0 UI testing)
- Fallback cuando un `SkillResource` no tiene icon asignado
- Debug visual: color + número hacen fácil identificar qué slot se renderiza

Colores canon (para evitar confusión con paletas de clase):
| Slot | Color |
|---|---|
| 1 | `#C04040` rojo |
| 2 | `#D07030` naranja |
| 3 | `#D0C030` amarillo |
| 4 | `#50B050` verde |
| 5 | `#3090B0` cyan |
| 6 | `#4060C0` azul |
| 7 | `#8050B0` violeta |
| 8 | `#C05080` rosa |

### 5.2 Warrior — iconos canon (5/12)

Paleta Warrior: acero `#7A7A82` (primario), dorado `#D4A040` (accent), rojo Rage `#E04828` (energía).

#### `punch.svg` — Puño de Guerra (Fase 1)

Puño cerrado en perfil mirando derecha (antebrazo acero + guantelete dorado en muñeca + 4 nudillos dorado) con 5 shock lines radiales rojas delante. Silueta "impacto físico básico". Refs: Diablo 2 monk martial arts, JJK Maki strike frame.

#### `charge.svg` — Embestida (Fase 1)

Guerrero corriendo inclinado hacia derecha (cabeza + torso + brazos + piernas en zancada, banda pectoral + bota dorada) con 5 speed lines rojas + 2 doradas detrás. Sensación de dash ofensivo. Refs: God of War Spartan rage charge, Berserk Guts charge.

#### `war_cry.svg` — Grito de Guerra (Fase 1)

Cabeza perfil (acero + casco/banda dorada frente + ojo rojo fiero) con boca abierta (triángulo hueco) y 3 arcos sonoros concéntricos rojos saliendo a la derecha + 1 arco dorado intermedio. Aura toggle "rugido". Refs: WoW Warrior Battle Shout, FFXIV Inner Beast.

#### `perfect_block.svg` — Bloqueo Perfecto (Fase 1)

Escudo kite más pequeño que shield_bash (lado izquierdo del frame) con boss central dorado + highlight metálico + flash central blanco `#FFF4C0` en el borde derecho (punto de parry) + 5 chispas blancas radiales + 3 doradas. Sensación de "deflect perfecto". Refs: Sekiro deflect spark, Dark Souls parry.

#### `shield_bash.svg` — preview Embestida con Escudo (rama Tank evolución, lvl 25+)

`game/assets/ui/icons/skills/warrior/shield_bash.svg`

**Status**: MANTENIDO post-Fase-1. En Fase 0 era sample de framework B. B reemplazó el stub con las 4 skills canon (punch/charge/war_cry/perfect_block) así que el icon queda huérfano — pero su concepto (escudo heater + shock lines) encaja perfectamente con **Embestida con Escudo** documentado en `warrior.md §3 Evolución rama Tank` (carga ofensiva de tanque). Se preserva como preview asset para esa skill futura en rama Tank ascendencia lvl 25+.

**Concepto**: escudo heater clásico de torneo con boss central dorado + banda horizontal dorada + 9 shock lines radiales rojas. Diferencia visual con `perfect_block.svg`: aquél tiene flash de parry blanco y escudo más chico; éste es escudo completo con impact lines rojas (ataque, no defensa).

**Paleta**: misma Warrior canon.

---

### 5.3 Mage — iconos canon (4/12)

Paleta Mage canon (de `_class_lore_mage.md §4 Aesthetic`):

| Rol | Hex | Justificación canon |
|---|---|---|
| Primario **violeta profundo** | `#6E3FA8` | Pigmento diaguita — túnica de Vigilante (lvl 22-28 Tercer Ciclo). "Se gana, no se regala" |
| Secundario **azul andino** | `#3E78B8` | Altiplano — segundo color primario canon |
| Accent **blanco tiza** | `#F0ECD8` | Páginas de cuaderno, chispas arcanas |
| Accent **oro apagado** | `#C89F4A` | Encuadernación de tomos, cobre de San Pedro |
| Highlight **violeta claro** | `#8A5FC8` | Variación tonal, feel "más claro" (brillo mágico) |
| Energía arcana **cyan-lapislázuli** | `#5EBFE8` | Gemas empotradas en bastón (lapislázuli chileno) — núcleos/runas |
| Supernova extra **dorado caliente** | `#FFE499` + `#FF8C30` | Estrella explotando — excepción térmica justificada para el ult |

> Nota: el brief original sugirió violeta `#6E3FA8` + azul `#4E6FBF` + cyan `#5EBFE8` + blanco `#E8E0FF`. Ajusté a la paleta del canon lore (violeta + azul ANDINO + blanco TIZA + oro APAGADO) porque `_class_lore_mage.md §4` es la fuente de verdad y explica el *por qué cultural* (diaguita/altiplano/San Pedro) — cross-class consistency con warrior (que respeta su lore) + scaling a futuras clases (archer/cleric/etc) es más robusto desde lore que desde brief sin contexto.

#### `unstable_orb.svg` — Bolita Inestable

Esfera **asimétrica** (path compuesto — NO circle perfect, esa es la clave "inestable") violeta con highlight claro interior + núcleo cyan-lapis central + 5 chispas blancas erráticas en ángulos irregulares + 2 chispas cyan secundarias. Halo radial difuso violeta como backdrop. Refs: Doctor Strange orbe, JJK Gojo Blue (hueco/succión). La asimetría + ángulos irregulares comunican "frágil/inestable" sin texto.

#### `arcane_storm.svg` — Tormenta Arcana

Vórtice central con 3 brazos espirales (azul andino + violeta primario + violeta claro) convergiendo al ojo de la tormenta (núcleo blanco tiza + punto violeta). 3 lightning bolts zigzag principales blancos saliendo en direcciones radiales distintas + 2 bolts cyan secundarios finos. Halo difuso. Sensación channeled AoE sostenido — la espiral comunica "continúa, no un flash". Refs: Frieren tormenta, JJK Megumi nue.

#### `prismatic_barrier.svg` — Barrera Prismática

Hexágono grande con 6 facetas triangulares desde el centro, cada una con color distinto (violeta + azul andino + cyan + blanco tiza + oro apagado + violeta claro) simulando refracción cristal. Líneas separadoras oscuras refuerzan feel "cristal tallado". Gema central blanca con outline violeta (turquesa/lapis canon). Highlight de refracción blanco en una faceta. Refs: Doctor Strange Eye of Agamotto (canon lore `mage.md §7`), Genshin shield.

#### `supernova.svg` — Supernova (ULTIMATE)

**Diferenciación visual**: más cargada que las otras 3, como corresponde a ult. Cuenta con:
- Halo arcano violeta (outer glow gradient)
- 8 rayos radiales principales (4 blancos + 4 naranjas diagonales)
- 8 rayos intermedios finos blancos (total 16 puntas sintetizando "explosión densa")
- Blast circle concéntrico violeta exterior
- Estrella central 4 puntas (dorado caliente + outline naranja)
- Núcleo blanco caliente con gradient radial (blanco → dorado → naranja → violeta outer)
- Punto central puro blanco

La paleta Supernova **se separa** del canon arcano en el núcleo (dorado `#FFE499` + naranja `#FF8C30`) pero **se reconcilia con la clase** en el halo y blast circle violetas — decisión deliberada: la estrella quema caliente (térmico) pero la *magia* que la sostiene es arcana (violeta). Esto comunica "ultimate cinematográfico" estilo JJK Hollow Purple framing sin romper identidad de clase. Refs: JJK Hollow Purple, Made in Abyss Layer 4, HSR ult pose framing.

---

## 6. Template — agregar nuevo icono

Checklist:

1. **Leer canon de la clase** → `game/docs/skills/_class_lore_{clase}.md` para aesthetic.
2. **Crear archivo** `game/assets/ui/icons/skills/{clase}/{skill_id}.svg` con:
   - `viewBox="0 0 64 64"`, `width="64" height="64"`
   - `<rect>` bg `#18181F` rx=6 + stroke del color primario de clase
   - Shape principal (silueta del skill) en color primario
   - Detalles en accent + energía según la paleta de §3
3. **Test visual a 32×32** y 64×64. Si 32×32 se pierde la silueta, ajustar shape.
4. **Agregar entrada** en §5 de este doc con: clase, skill_id, concepto (1 línea), paleta usada.
5. **Handoff a B** vía bus: path del SVG para setear en el `.tres` correspondiente.

---

## 7. Iconos pendientes (canon — 64 skills de `_system.md`)

Lista no exhaustiva, solo para tracking. NO implementar todos en Fase 0 — se agregan uno a uno cuando cada skill entra a código.

### Warrior (5/12 canon implementados)
- `punch.svg` ✅ (Fase 1 — Puño de Guerra)
- `charge.svg` ✅ (Fase 1 — Embestida)
- `war_cry.svg` ✅ (Fase 1 — Grito de Guerra)
- `perfect_block.svg` ✅ (Fase 1 — Bloqueo Perfecto)
- `shield_bash.svg` ⏳ (preview — Embestida con Escudo rama Tank lvl 25+)
- Pendientes: `escudo_vengador.svg`, `provocacion.svg`, `muralla.svg`, `carga_jabali.svg`, `berserk.svg`, `sed_sangre.svg`, `torbellino.svg`, `rompe_armadura.svg`, `ultimo_aliento.svg`

### Mage (4/12 canon implementados)
- `unstable_orb.svg` ✅ (Fase 2 prep — Bolita Inestable, proyectil básico)
- `arcane_storm.svg` ✅ (Fase 2 prep — Tormenta Arcana, channeled AoE)
- `prismatic_barrier.svg` ✅ (Fase 2 prep — Barrera Prismática, escudo)
- `supernova.svg` ✅ (Fase 2 prep — Supernova, ULTIMATE)
- Pendientes: `bola_fuego.svg`, `rayo_hielo.svg`, `cadena_relampago.svg`, `teleport.svg`, `muro_fuego.svg`, `tormenta_hielo.svg`, `meteorito.svg`, `disipacion.svg` (8 skills T1-T3 elementales)

### Archer (12 skills canon)
- `disparo_preciso.svg`, `lluvia_flechas.svg`, `flecha_explosiva.svg`, `trampa_red.svg`, `salto_atras.svg`, `ojo_halcon.svg`, `viento_aliado.svg`, `flecha_sangrante.svg`, `emboscada.svg`, `disparo_piercing.svg`, `marca_objetivo.svg`, `ultimatum.svg`

### Cleric (12 skills canon)
- `cura_divina.svg`, `bendicion.svg`, `proteccion_divina.svg`, `exorcismo.svg`, `resurreccion.svg`, `aura_fe.svg`, `luz_sagrada.svg`, `penitencia.svg`, `juicio.svg`, `santuario.svg`, `plegaria_grupo.svg`, `fiat_lux.svg`

### Necromancer (12 skills canon)
- `maldicion.svg`, `invocar_esqueleto.svg`, `drenaje_vida.svg`, `peste.svg`, `aura_decay.svg`, `invocar_liche.svg`, `marca_muerte.svg`, `esclavo_alma.svg`, `nube_toxica.svg`, `pacto_sangre.svg`, `necrosis.svg`, `gran_ritual.svg`

### Danzante de Sombras (12 skills canon)
- `paso_sombra.svg`, `daga_envenenada.svg`, `ilusion.svg`, `salto_fantasma.svg`, `combo_golpes.svg`, `manto_noche.svg`, `dardo_sangre.svg`, `parálisis.svg`, `finta.svg`, `velo_negro.svg`, `golpe_critico.svg`, `danza_muerte.svg`

**Total progreso**: 9/64 iconos canon implementados (5 Warrior Fase 1 + 4 Mage Fase 2 prep) + 8 placeholders genéricos + 1 preview (shield_bash). 55+ iconos pendientes en futuras fases, prioridad por orden de implementación de skills en código.

---

## 8. Refs visuales / inspiración

- **Diablo 2 skill icons**: silueta simple, accent dorado, 32×32 legible — canon de la industria.
- **Path of Exile passive tree nodes**: iconografía de clase con paleta fija (Marauder rojo, Witch violeta, etc).
- **Kenney CC0 UI packs** (skill `kenney-quaternius-sourcer`): pack "Game Icons" tiene 500+ SVG CC0 que pueden servir como base o ref. Si se usa uno directo, documentar en §5 con crédito aunque sea CC0.
- **Hades skill icons**: silueta + 2-3 colores + glow barato — funciona muy bien a tamaño chico.
- **WoW Classic ability icons**: ejemplo AAA de consistencia por clase (todos los Warrior shares palette steel+red, todos los Mage share arcane blue+gold).

---

## 9. TODOs / futuras iteraciones

- **Sheet/atlas** cuando haya 30+ iconos: consolidar en spritesheet (no obligatorio con SVG — Godot los cachea OK).
- **Rarity frames** (skill evolucionado vs base): border dorado para evolved, plateado para ascendencia. Aplicar a cada icon en post (filtro SVG) o frame overlay separado.
- **Icons grayscale** para skills en cooldown: post-processing en shader del hotbar, NO duplicar assets.
- **Icons disabled** (no cumple req level/ascendencia): tinta gris + candado overlay. Overlay separado, NO duplicar assets.

---

**Última revisión**: 2026-04-17 (Fase 2 prep Mage — D)
