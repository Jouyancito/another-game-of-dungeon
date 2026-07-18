# Reference: crystal_ceiling — DanMachi dungeon floors (2026-07-18)

Requested by Joan for the ceiling/lighting redesign. Images live IN THIS FOLDER
(5 real 1920x1080 anime screenshots, downloaded from the Fandom wiki CDN and
eyeballed one by one — observations below are from the actual images, not from
text descriptions). Cross-validated against the wiki's text description of the
18th floor; both sources agree.

## Images

| File | What it shows |
|---|---|
| `danmachi_18f_under_resort.png` | 18F safe floor: giant central tree, pale white-blue luminous walls |
| `danmachi_great_fall.png` | Waterfall wall with emissive blue crystal clusters growing on rocks |
| `danmachi_rivira_town.png` | Rivira frontier town: log palisade, watchtower, gate (bandit-camp gold) |
| `danmachi_early_floors.png` | Early floors: dark teal cave, glowing dots tracing the ceiling |
| `danmachi_5th_floor.png` | Brown rock tunnel, trail of green glow orbs along the ceiling |

## Qué se VE (observado, no asumido)

**Iluminación del 18F (el "cielo de cristal"):**
- La luz es BLANCA-AZULADA, difusa y OMNIDIRECCIONAL — nivel de luz de día
  nublado, sin sol visible, sin sombras duras en ninguna parte de la escena.
  Las paredes lejanas se leen como cortinas verticales de luz pálida (mist +
  streaks verticales), no como roca oscura.
- **Esto valida la intuición de Joan** ("la luz viene de todas direcciones, no
  debería haber una sombra muy prominente"): el look DanMachi para un piso con
  techo-cielo de cristal es sombra SUAVE, apenas presente, no la sombra dura
  de un DirectionalLight único. Nuestro `CavernKeyLight` actual (una direccional
  con shadow fuerte) contradice la referencia.

**Cristales:**
- En `great_fall`: los cristales crecen en CLUSTERS pequeños sobre los bordes de
  las formaciones de roca (puntas de riscos), intensamente emisivos, cyan-azul,
  contra un entorno oscuro. No son planos ni uniformes: son puntos de acento.
- En pisos tempranos (`early_floors`, `5th_floor`): la única luz son PUNTOS
  chicos de glow (cyan en unos pisos, verde en otros) trazando la línea del
  techo/túnel, como luciérnagas o musgo luminoso. Piso oscuro, acentos puntuales.

**Jerarquía de dos niveles (texto de la wiki, consistente con lo visto):**
18F tiene cristales blancos al CENTRO del techo (leen como sol) + azules
alrededor (leen como cielo), y la intensidad CICLA con la hora del día.

## Qué capturar para nuestro piso 1

1. **Sombras suaves bajo techo-cristal**: bajar dureza/energía de la sombra del
   key light, subir el fill ambiental — la sombra del pilar no debería ser un
   corte negro dramático. (Aplicar DESPUÉS del remodelado del techo, no antes —
   decisión de Joan: no pulir luz de assets que vamos a reemplazar.)
2. **Techo = cluster jerárquico, no plano**: un núcleo brillante central (sol) +
   scatter de cristales menores (cielo). Nuestro `FocusLight` ya apunta ahí
   conceptualmente; la GEOMETRÍA del techo (hoy PlaneMesh tintado) es lo que
   falta modelar con el motor Blender.
3. **Acentos puntuales, no luz uniforme**: cristales chicos emisivos en bordes
   de rocas/pilares (como great_fall) — ya tenemos `_build_crystal_field`, la
   ref valida la dirección y sugiere ponerlos EN las formaciones, no flotando.
4. **Ciclo día/noche del cristal**: la wiki confirma que la luz del techo cicla
   con la hora — coincide con el TODO "animación sutil del tint" ya anotado en
   `crystal_ceiling.md` §10.

## Bonus cruzado — aldea de bandidos

`danmachi_rivira_town.png` es referencia DIRECTA para el campamento/aldea
bandida: empalizada de troncos verticales DESPAREJOS y curtidos (la nuestra es
un cerco prolijo), torre de vigía alta y precaria de madera, portón de postes
amarrados con soga, letrero arqueado pintado a mano, tela rasgada colgando,
construcciones amontonadas trepando la ladera. Copiada también a
`_references/bandit_camp/` (ver ese folder).

## Fuentes (multi-fuente, por convención)

- Screenshots: [DanMachi Wiki (Fandom) — Dungeon](https://danmachi.fandom.com/wiki/Dungeon),
  bajados vía la API MediaWiki (`static.wikia.nocookie.net`), 2026-07-18.
- Texto 18F (blanco-sol + azul-cielo, ciclo horario): misma wiki vía búsqueda,
  corroborado contra [Miraheze DanMachi wiki](https://danmachien.miraheze.org/wiki/Dungeon)
  y [Gamerant — Dungeon floors explained](https://gamerant.com/is-it-wrong-to-try-to-pick-up-girls-in-a-dungeon-the-dungeons-floors-explained/)
  (los tres coinciden en la descripción del 18F).
