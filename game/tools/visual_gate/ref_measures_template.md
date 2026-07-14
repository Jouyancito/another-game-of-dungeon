# Contrato de proporciones — plantilla `<personaje>`

_Kit de medición visual v1 · pareja con `measure_features.py`. Se llena UNA VEZ por
personaje. Es el número objetivo que le faltó a Filomeno: sin él, la oscilación
cejas-ojos (lejos→cerca→lejos, 5 iteraciones) no tiene condición de parada._

## Cómo funciona

1. **Medí el 2D una vez** (columna `target`): abrí la referencia 2D
   (`_refs/<personaje>_nude_apose.png`) y medí en píxeles los mismos ratios que
   `measure_features.py` calcula del 3D. Todos son **fracciones del head-bbox**, así
   que la escala/resolución no importan — solo importan las proporciones.
2. **Definí el head-bbox igual que la herramienta** (crítico para que los números
   sean comparables): el head-bbox = caja que envuelve **ojos + cejas + hocico +
   orejas** (los mismos landmarks que la herramienta une). En el 2D: dibujá esa caja
   sobre la cara, `head_w` = su ancho en px, `head_h` = su alto en px, `head_min_z` =
   su borde inferior. Todos los ratios se miden dentro de esa caja.
3. **`measure_features.py` asserta** la columna `actual` contra `target ± tol` en cada
   iteración. Un ratio fuera de tolerancia = FALLO con número, no "se ve raro".

Medir el 2D: `head_w`/`head_h` en px con cualquier visor; los gaps verticales
(ceja→ojo, ojo→hocico) medidos como `Δpx / head_h`; los anchos (espaciado, tamaño de
ojo) como `Δpx / head_w`.

## Tabla del contrato

| Ratio (clave en `ratios{}` del JSON) | Qué es | `target` (medido del 2D) | `tol` | `actual` (del 3D) | Estado |
|---|---|---|---|---|---|
| `eye_spacing__head_w` | separación inter-ocular / ancho de cabeza | _(llenar)_ | ±0.05 | | |
| `eye_width__head_w` | ancho de un ojo / ancho de cabeza | _(llenar)_ | ±0.05 | | |
| `eye_height__head_h` | altura del centro del ojo (0=mentón,1=corona) | _(llenar)_ | ±0.05 | | |
| `brow_height__head_h` | altura del centro de la ceja | _(llenar)_ | ±0.05 | | |
| `brow_eye_gap__head_h` | gap vertical ceja→ojo / alto de cabeza | _(llenar)_ | ±0.03 | | |
| `muzzle_height__head_h` | altura del centro del hocico | _(llenar)_ | ±0.05 | | |
| `eye_muzzle_gap__head_h` | gap vertical ojo→tope del hocico | _(llenar)_ | ±0.04 | | |

### Zonas de pintura — probe de derrame (el que cazó el cráneo del golem)

`measure_features.py` reporta por material de zona (`nose/mouth/muzzle/ear`) un
`spill_score` = fracción de vértices de la zona por encima de la banda del cráneo
(`--cranium-band`, default 0.80 del alto de cabeza). **Una zona baja (nariz, boca,
hocico) con `spill_score > 0` = pintura derramada hacia arriba = DEFECTO** (invisible
en un render frontal, sólo se ve en la distribución Z o en el worm's-eye).

| Zona (`<short>_spill_score`) | Regla | `target` | `actual` | Estado |
|---|---|---|---|---|
| `nose_spill_score` | nariz NO debe subir al cráneo | `= 0.0` | | |
| `mouth_spill_score` | boca NO debe subir al cráneo | `= 0.0` | | |
| `muzzle_spill_score` | hocico NO debe subir al cráneo | `= 0.0` | | |
| `ear_spill_score` | orejas SÍ viven arriba — informativo, no gate | _(n/a)_ | | |

> Nota: `ear_spill_score` alto es CORRECTO (las orejas están en la corona). El gate de
> derrame aplica sólo a las zonas bajas de cara. No lo pongas como FALLO.

## Ejemplo trabajado — Filomeno (medición del 3D actual, 2026-07-03)

Corrido: `blender.exe -b _gate_test.blend --python measure_features.py -- --target Bear_A_tufts --out measures.json`
(head-bbox `source=features+paint`, `head_w=0.2804`, `head_h=0.3632`). Estos son los
`actual` del MODELO; la columna `target` (del 2D) sigue pendiente de medir — ese es el
próximo paso concreto (Gap 1 del INVENTORY).

| Ratio | `actual` 3D | Lectura |
|---|---|---|
| `eye_spacing__head_w` | **0.542** | ojos separados ~54% del ancho de cabeza |
| `eye_width__head_w` | **0.342** | cada ojo ~34% del ancho — grande (candidato a defecto) |
| `eye_height__head_h` | **0.596** | ojos a ~60% de la altura |
| `brow_height__head_h` | **0.707** | cejas a ~71% |
| `brow_eye_gap__head_h` | **0.112** | gap ceja→ojo = 11% del alto de cabeza |
| `muzzle_height__head_h` | **0.281** | hocico a ~28% |
| `eye_muzzle_gap__head_h` | **0.033** | ojo→hocico apenas 3% — MUY pegados (candidato a defecto) |
| `nose_spill_score` | **0.0** | nariz limpia, sin derrame ✓ |
| `muzzle_spill_score` | **0.0** | hocico limpio ✓ |
| `ear_spill_score` | **1.0** | orejas en la corona (correcto, informativo) |

**Cómo se usa contra la oscilación:** medís `brow_eye_gap__head_h` en el 2D (p.ej.
sale 0.16). El 3D da 0.112 → gap 0.048 por debajo → cejas DEMASIADO cerca de los ojos,
en número. Ajustás, re-medís, y parás cuando `|actual - target| < tol`. Nunca más
"lejos→cerca→lejos" a ojo.

## Flujo de gate completo (los 3 instrumentos juntos)

```
# 1) capturar todos los ángulos (incluye worm's-eye + close-ups)
blender.exe -b <scene>.blend --python orbit_capture.py -- \
    --target Bear_A_tufts --out ./out --frames 8 --res 640x800

# 2) medir números (asserta contra esta tabla)
blender.exe -b <scene>.blend --python measure_features.py -- \
    --target Bear_A_tufts --out ./out/measures.json

# 3) componer UNA imagen: ref 2D + todos los ángulos (juicio side-by-side, no de memoria)
blender.exe -b --factory-startup --python contact_sheet.py -- \
    --out ./out/sheet.png --ref "REF-2D=<ref_2d>.png" \
    --manifest ./out/manifest.json --cols 4

# 4) SÓLO ENTONCES veredicto: leer measures.json (gaps con número) + mirar sheet.png.
#    Regla dura: sin measures.json + sheet.png producidos esta iteración, NO hay veredicto.
```
