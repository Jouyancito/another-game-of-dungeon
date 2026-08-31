# hair_undercut_viking — el peinado elegido para el Warrior (2026-08-15)

**Joan dijo:** *"me agrada este peinado, ¿es posible recrearlo?"*

Dos referencias del mismo registro: **undercut nórdico** — laterales y nuca baja rapados, pelo
largo arriba peinado hacia atrás, recogido en cola o trenzas.

## Imágenes

| # | Archivo | Qué se ve |
|---|---|---|
| 01 | `01_undercut_tied_back_profile.png` | Perfil 3/4. Lateral rapado alto (por encima de la oreja), masa superior peinada hacia atrás y atada en cola larga que cae por la espalda. Barba corta cerrada |
| 02 | `02_undercut_braids_side.png` | Lateral rapado casi al cero. Arriba, **trenzas paralelas** que corren de la frente hacia la nuca y se juntan en una cola. Barba corta |

## Síntesis

### Por qué este peinado resuelve problemas en vez de crearlos

No es solo que guste: es **más barato y más robusto** que lo que se venía construyendo.

1. **Elimina el defecto que quedó sin arreglar.** Los escalones del borde del cap estaban sobre
   la oreja — y en un undercut **ahí no hay pelo**. El borde problemático desaparece del
   diseño, no hay que resolverlo.
2. **El lateral rapado es COLOR, no geometría.** Pelo al ras = piel oscurecida. Se pinta con el
   vertex paint que ya existe (`paint_char_skin.py`), sin una sola cara nueva.
3. **La masa superior va peinada hacia atrás y pegada al cráneo** — que es exactamente lo que
   hace el cap ajustado (+3.5 mm/lado, ya medido). El cap deja de cubrir toda la cabeza y pasa
   a cubrir sólo la franja central, que es menos geometría todavía.
4. **La cola ya existe** en el generador; sólo hay que corregir su nacimiento.

### Forma / silueta
- **Franja central ancha** de pelo, del nacimiento frontal a la nuca. Los lados, rapados.
- La transición rapado/pelo es **una línea dura y alta**, por encima de la oreja. Es un borde
  limpio y recto: barato de modelar y muy legible a distancia.
- **La cola cae por la espalda**, no queda pegada a la nuca. Es la masa del peinado.
- Las trenzas de la ref 02 son surcos paralelos sobre la franja — a tamaño de juego se leen
  como variación de valor, no como geometría separada.

### Colores
Rubio oscuro / castaño claro en ambas. Rompe con el `#241A14` casi negro que tiene hoy el
generador, que sobre piel morena da muy poco contraste.

### Qué capturar
1. **Franja central + laterales rapados.** El cap se recorta a la franja.
2. **Línea de transición alta y dura**, por encima de la oreja.
3. **Cola larga que cae por la espalda** — no una correa corta pegada a la nuca.
4. **Trenzas como valor pintado** sobre la franja, no como geometría.
5. **Barba corta cerrada** en las dos: confirma que el guerrero lleva barba, y que ésta es
   corta — o sea VALOR pintado, no la barba llena que pedía geometría.

### Encaje con el canon
Coincide con el registro veterano-curtido / primitivo-tribal que `warrior_archetype` §(b) ya
recomendaba, y con las dos referencias de guerrero del lote del 2026-08-15 (una con barba
trenzada con anillos). El trarilonko del canon puede montarse sobre la franja sin conflicto.

**Fuente/fecha**: aportadas por Joan, 2026-08-15.
