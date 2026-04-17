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
| Mage | Azul arcano `#3A70C0` | Dorado rúnico `#E0B040` | Violeta `#8040C0` (arcano) / Rojo `#D04030` (fuego) / Cyan `#60C0D0` (hielo) | Energía elemental, runas |
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

### 5.2 Warrior / Shield Bash (1/N)

`game/assets/ui/icons/skills/warrior/shield_bash.svg`

**Concepto**: escudo heater (silueta clásica de torneo) con boss central dorado + banda horizontal dorada + 9 shock lines radiales rojas saliendo detrás. Los shock lines comunican "impacto/bash" sin ambigüedad; el escudo comunica la clase y el arma.

**Paleta**: acero `#7A7A82` (primario), dorado `#D4A040` (accent en boss + banda + outline), rojo Rage `#E04828` (energía, shock lines).

**Asignación `SkillResource`**: B setea en el `.tres`:
```
icon = preload("res://assets/ui/icons/skills/warrior/shield_bash.svg")
```

Si B deja `icon = null` (porque pushó el .tres antes que este branch merge), A hace el link en merge o en commit follow-up.

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

### Warrior (10-12 skills canon)
- `shield_bash.svg` ✅ (Fase 0 sample)
- `bloqueo_perfecto.svg`, `escudo_vengador.svg`, `provocacion.svg`, `muralla.svg`, `carga_jabali.svg`, `berserk.svg`, `sed_sangre.svg`, `torbellino.svg`, `grito_guerra.svg`, `rompe_armadura.svg`, `ultimo_aliento.svg`

### Mage (12 skills canon)
- `bola_fuego.svg`, `rayo_hielo.svg`, `cadena_relampago.svg`, `escudo_arcano.svg`, `teleport.svg`, `muro_fuego.svg`, `tormenta_hielo.svg`, `meteorito.svg`, `disipacion.svg`, `prisma.svg`, `barrera_mana.svg`, `singularidad.svg`

### Archer (12 skills canon)
- `disparo_preciso.svg`, `lluvia_flechas.svg`, `flecha_explosiva.svg`, `trampa_red.svg`, `salto_atras.svg`, `ojo_halcon.svg`, `viento_aliado.svg`, `flecha_sangrante.svg`, `emboscada.svg`, `disparo_piercing.svg`, `marca_objetivo.svg`, `ultimatum.svg`

### Cleric (12 skills canon)
- `cura_divina.svg`, `bendicion.svg`, `proteccion_divina.svg`, `exorcismo.svg`, `resurreccion.svg`, `aura_fe.svg`, `luz_sagrada.svg`, `penitencia.svg`, `juicio.svg`, `santuario.svg`, `plegaria_grupo.svg`, `fiat_lux.svg`

### Necromancer (12 skills canon)
- `maldicion.svg`, `invocar_esqueleto.svg`, `drenaje_vida.svg`, `peste.svg`, `aura_decay.svg`, `invocar_liche.svg`, `marca_muerte.svg`, `esclavo_alma.svg`, `nube_toxica.svg`, `pacto_sangre.svg`, `necrosis.svg`, `gran_ritual.svg`

### Danzante de Sombras (12 skills canon)
- `paso_sombra.svg`, `daga_envenenada.svg`, `ilusion.svg`, `salto_fantasma.svg`, `combo_golpes.svg`, `manto_noche.svg`, `dardo_sangre.svg`, `parálisis.svg`, `finta.svg`, `velo_negro.svg`, `golpe_critico.svg`, `danza_muerte.svg`

**Total**: 70+ iconos a crear en futuras fases. Prioridad por orden de implementación de skills en código.

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

**Última revisión**: 2026-04-17 (Fase 0 — D)
