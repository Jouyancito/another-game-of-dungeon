# Catálogo de estilos — nombres que Joan y Claude usan igual

**Por qué existe** (Joan, 2026-08-28): *"si puedes colocarle un nombre de estilo, estaría bueno.
Así también, cuando te pida cierto estilo, tú lo puedas entender o decirme 'sí, manejamos estos
estilos'."* Un estilo entra acá cuando tiene **referencia en el repo + reglas con números**. Un
nombre sin carpeta de referencia no es un estilo, es una opinión.

Cómo se usa: Joan pide "hacelo en <nombre>" → se abre la carpeta de referencia citada, se leen
`_synthesis.md` **y las imágenes**, y se construye desde ahí. Si Joan pide un estilo que no está
en la tabla, la respuesta es "no lo tenemos — pasame una referencia y lo damos de alta".

| Nombre | Manda sobre | Referencia | Geometría | Materiales | Luz / color | Dónde aplica |
|---|---|---|---|---|---|---|
| **PoE bar** (tema principal) | todo el juego | `poe_visual_bar/`, `village_poe_style/`, `_art_canon.md` §17 | estilizada, desgastada, con historia | se leen como lo que son | charcos cálidos contra ambiente frío-oscuro; saturación sólo para lo mágico | canon global, techo PoE 1 |
| **Modelo Valheim** | geometría vs material | `_art_canon.md` §17 (escalera DnD→PoE1→PoE2) | low-poly simple | ricos, con textura | atmósfera dramática | exteriores, scatter, todo lo que se repite |
| **Skyrim (techo de personajes)** | fidelidad de personajes y pelo | `skyrim_faces/`, `dark_and_darker_faces/`, `head_anatomy_metahuman/`, `_asset_creation_contract.md` §3b | cabeza con proporciones medibles | pelo = scalp cap + cards + flyaways | — | clases, NPCs |
| **DP_ToonGrounded** | contrato de estilo de mobs | `_mob_style_contract.md`, skill `blender-asset-smith` | estilizado rico, no low-poly barato | por bioma y tier | — | criaturas |
| **LOTR × Skyrim** (escalón alcanzable — Joan 2026-08-28: *"PoE lo veo muy lejano; Skyrim tiene más similitud con lo que llevamos; lo ideal sería PoE como primera"*) | tema de mundo: épica, ruina, clima, jefes con escala. **Referencia de trabajo de HOY**; PoE bar sigue siendo el norte | `lotr_skyrim/` (19 imágenes con comentario de Joan por escena), `village_lotr/`, `skyrim_faces/`, `tavern/` | techo Skyrim; ruinas transitables; estructuras con 3-5 estados de daño | metal sucio, madera, musgo de abandono; personajes reconocibles, no hiperreales | fuego/antorcha como foco, lluvia, nieve con huellas, niebla por distancia, luna; VFX: violeta = maldición, blanco = purificación, verde = fantasma | mundo entero: jefes, ruinas, taverna, clima, VFX de estado |
| **PBR pintado** (*painterly PBR*) | look de render + detalle de props | `style_painterly_pbr/` | biseles y subdivisión reales en hero props (bisel 3-8 mm), formas gordas +10-20 % | metal/madera/estuco/comida con relieve real (normal/height) + pinceladas en el albedo; subsurface en orgánico | sol cálido rasante, sombras suaves con rebote, paleta saturada 2-3 cálidos + 1 frío complementario | **interiores habitados**: taverna, cocinas, casas, tiendas; hero props de mano |

## Reglas

1. **Un estilo se cita por nombre de esta tabla**, y su carpeta se abre antes de construir
   (convención referencias GUARDAR + USAR, `CLAUDE.md`).
2. **Los estilos se combinan por capa, no se mezclan al azar**: PoE bar es el tema; Valheim decide
   cuánta geometría lleva lo que se repite; PBR pintado decide cómo se ve un interior de cerca;
   Skyrim y DP_ToonGrounded son techos por categoría (personajes / mobs).
3. **Dar de alta un estilo** = carpeta `_references/style_<nombre>/` con imágenes + `_synthesis.md`
   con reglas en números + fila acá + puntero engram `reference/style_<nombre>`.
