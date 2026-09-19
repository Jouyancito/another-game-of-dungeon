# Reference: village_hielo — aldea de hielo/nieve (2026-07-18)

For the 3-biome village generation proof (Blender motor). Structure + mood refs
for the ice-floor (P3) village. Eyeballed, images live in this folder.

## Images

| File | What it shows | Rol |
|---|---|---|
| `skyrim_dawnstar.png` | Dawnstar (Skyrim) — nordic snow village on a bay | ESTRUCTURA |
| `ds3_irithyll_01.png` | Irithyll (DS3) — moonlit ice city, aurora | MOOD/PALETA |
| `botw_rito_village.png` | Rito Village (BOTW) — spire landmark far view | landmark (débil como aldea, conservada por contexto) |

## Qué se VE (Dawnstar — la estructural)

- **Longhouses nórdicas**: planta rectangular alargada, techo a dos aguas MUY
  empinado con capa de nieve encima, paredes de madera sobre base de piedra.
- **Torre de vigía de PIEDRA en el punto rocoso más alto** (arriba-izquierda) —
  valida 1:1 la regla "torre en el punto más alto del perímetro" del algoritmo.
- **Sin empalizada continua**: la defensa es el terreno (bahía + risco). Estilo
  hielo → anillo de empalizada más corto/parcial, la roca hace el resto.
- **Pinos nevados** intercalados entre las casas; muelle/agua congelable.

## Qué se VE (Irithyll — la de mood)

- Noche perpetua, luna enorme, aurora boreal verde-azul, agujas/spires.
- Paleta: azul profundo + blanco lunar + acentos cyan — coincide con canon P3
  (`#A8D8FF` hielo, "frío, luz dura").

## Qué capturar para el generador (estilo hielo)

1. Longhouse: caja alargada + techo prisma empinado + capa blanca de nieve.
2. Torre cilíndrica de PIEDRA (no madera) en el punto más alto.
3. Empalizada parcial — el terreno defiende; menos estacas que bosque/pradera.
4. Pinos nevados (conos apilados con blanco arriba).
5. Paleta: azul-blanco lunar, madera oscura fría, piedra gris.

## Fuentes

- [Elder Scrolls Wiki (Fandom) — Dawnstar](https://elderscrolls.fandom.com/wiki/Dawnstar_(Skyrim)), vía API MediaWiki, 2026-07-18.
- [Dark Souls Wiki (Fandom) — Irithyll of the Boreal Valley](https://darksouls.fandom.com/wiki/Irithyll_of_the_Boreal_Valley) — DS3 Irithyll ya estaba aprobada en `_art_canon.md` §refs P3.
- [Zelda Wiki (Fandom) — Rito Village](https://zelda.fandom.com/wiki/Rito_Village) — BOTW Hebra aprobada en canon P3; este screenshot puntual es débil para estructura de aldea (anotado, no borrado).

## Addendum — clima frío (2026-07-18, PO principle 2 "living village" pass)

Investigación vernacular architecture cross-checked (citas completas en
`game/docs/_village_expansion_canon.md` §7): regiones frías favorecen
formas compactas, aislantes, con aberturas pequeñas y protegidas —
opuesto exacto de pradera (ver addendum en `bandit_camp/_synthesis.md`).
Bakeado en `village_gen.py` `STYLES["hielo"]`: `window_scale=0.65`
(ventanas chicas), `porch_chance=0.0` (nadie vive medio-afuera con este
frío), `stone_base_chance=0.65` (zócalo de piedra frecuente — aísla del
suelo helado, coincide con la base de piedra ya vista en Dawnstar).
