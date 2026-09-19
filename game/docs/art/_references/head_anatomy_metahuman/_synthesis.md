# head_anatomy_metahuman — anatomía de cabeza: ojos, pelo sobre cuero cabelludo, nariz, boca

**Joan dijo (2026-08-28):** *"esta referencia es principalmente sobre la cabeza de una persona:
cómo funcionan los ojos, cómo se coloca el pelo, cómo se fija el pelo al cuero que ayuda, la nariz,
los ojos, la boca. Es como el aspecto de la cara de una persona. No me interesa que sea tan tan
realista, pero sí quizás se acerque un poco."*

→ Manda sobre **anatomía y colocación** (dónde va cada cosa y cómo se une), no sobre el nivel de
fidelidad. El techo sigue siendo Skyrim (`_asset_creation_contract.md` §3b). Cuatro capturas de un
editor tipo MetaHuman (barra inferior "Face ROM / Body ROM / Happy A / Surprise" = clips de rango
de movimiento facial), mismo personaje en cuatro ángulos.

| File | Ángulo | Qué muestra |
|---|---|---|
| `01_front_34` | frente 3/4 | ojos en cuenca bajo el arco de la ceja, párpado superior que tapa parte del iris, lagrimal húmedo; ceja densa en el extremo interno y afinándose afuera; nariz con puente definido y alas; labio inferior más lleno que el superior, surco nasolabial; línea de pelo con entradas en las sienes |
| `02_profile` | perfil | puente de nariz recto-levemente convexo; oreja centrada entre la altura de la ceja y la base de la nariz; el pelo de los costados **pegado al cráneo** siguiendo su curva; la raya lateral; la masa de arriba despega solo al frente (tupé); patilla termina a media oreja |
| `03_profile_back` | perfil trasero | el pelo cubre todo el occipital y **afina hacia la nuca**; dirección del pelo hacia atrás; oreja completamente libre |
| `04_back_34_nape` | nuca 3/4 | línea de nuca recortada; el grano del pelo **converge en el remolino de la coronilla**; pelo corto adherido, sin volumen atrás |

## Idea

La cara no es una superficie pintada: es **piezas con lugar propio**. Cada una tiene una regla de
colocación que se puede medir, y es eso lo que el ojo reconoce como "persona" mucho antes que la
textura. Los cuatro ángulos muestran lo mismo: el pelo es una **capa que sigue al cráneo** (no una
tapa apoyada), y los rasgos están en proporciones canónicas.

## Reglas de colocación (cada frase termina en un número o una orientación)

**Ojos**
- El globo es una **esfera separada** de la cabeza (Ø ~24 mm a escala real), metida en la cuenca;
  los párpados **envuelven** la esfera, no la dibujan encima.
- El párpado superior tapa el **tercio superior del iris**; el inferior toca su borde. Ojos
  "abiertos de más" (iris entero visible) leen sorpresa o muñeco.
- Distancia entre ojos = **un ojo de ancho**. Línea de ojos a **mitad de la altura total** de la
  cabeza (coronilla→mentón).
- Lagrimal (caruncle) en el extremo interno, húmedo: un highlight ahí vale más que cualquier textura.
- Ceja **sobre el reborde óseo**, no sobre el párpado: densa y baja en el extremo interno, sube y
  se afina hacia afuera, termina en vertical con el ala de la nariz.

**Nariz**
- Nace en la glabela (entre cejas), base de la nariz a **mitad entre línea de ojos y mentón**.
- Ancho de la base = **distancia entre lagrimales**.
- En perfil: puente con un plano propio (recto o levemente convexo), la punta sobresale y las alas
  quedan **detrás** de la punta.

**Boca**
- Comisuras alineadas en vertical con el **centro de las pupilas**.
- Línea de boca a **un tercio** entre base de nariz y mentón.
- Labio inferior **más lleno** que el superior; surco (philtrum) entre nariz y labio superior;
  la boca **no es plana**: sigue la curva del arco dental.

**Oreja**
- Entre la altura de la **ceja y la base de la nariz**, en perfil a **mitad** entre frente y nuca,
  levemente inclinada hacia atrás.

**Pelo — cómo se fija al cuero cabelludo (el punto que Joan más subraya)**
- Hay una **línea de pelo** con forma: entradas en las sienes, pico o recta en la frente, patillas
  hasta media oreja, **nuca recortada**. Todo lo que no está dentro de esa línea es piel.
- El pelo **nace del cuero y sigue la curva del cráneo**: en costados y nuca va pegado (grosor de
  capa ≈ 5-15 mm), el volumen sale **solo** donde está peinado (el tupé al frente, ~40-60 mm).
- Tiene **dirección**: de la raya hacia los lados, del remolino de la coronilla hacia afuera, y
  hacia atrás/abajo en la nuca. Los mechones **se solapan**: no se ve cuero salvo en la raya
  (lección del guerrero, 2026-08-15).
- Traducción al método canon de tres capas (`_modeling_knowledge_base.md` §Hair): **scalp cap**
  que define la línea de pelo y da el color base bajo las cards → **cards** que siguen la dirección
  de peinado y se solapan → **flyaways** pocos, en el borde. Técnica de cáscaras opacas:
  DESCARTADA (`hair_polygon_shells/`).

**Piel (secundario para Joan)**
- Subsurface leve (orejas y nariz translúcidas a contraluz), pecas/variación sutil, un poco de
  brillo en frente y nariz. A nivel Skyrim: albedo con variación + roughness map, sin más.

## Colores
Piel cálida media con rojo en orejas/nariz/labios, pelo castaño oscuro con brillo anisotrópico
(línea de highlight que sigue la dirección del peinado), iris avellana, blanco del ojo levemente
gris-rosado (nunca blanco puro).

## Movimiento / Feel
Los clips "Face ROM / Happy / Surprise" indican que la cara está **riggeada para expresión**: los
párpados y la boca son las piezas que se mueven. Colocar el globo ocular como esfera separada
también habilita la mirada (rotar la esfera) — barato y con mucho retorno de "vida".

## Qué capturar

1. Ojos como esferas en cuenca, párpados envolviendo, iris tapado un tercio arriba.
2. Proporciones canónicas medibles (ojos a mitad, nariz a mitad de la mitad inferior, boca a un
   tercio, comisuras bajo pupilas, orejas ceja→nariz).
3. **Línea de pelo explícita** + pelo que sigue el cráneo con dirección y solapamiento; volumen
   solo donde hay peinado.
4. Un poco de vida en piel (subsurface leve, brillos) — sin perseguir fotorealismo.

## Métrica de éxito (definida antes de construir)
Sobre la cabeza del personaje en perfil y frente: las 6 proporciones de arriba medidas en el mesh
con tolerancia ±10 %; y en la nuca/costados el pelo no despega del cráneo más de 15 mm (medido
vértice-a-superficie), con 0 % de cuero visible fuera de la raya en render a tamaño de uso.

## Fuente
Cuatro capturas de pantalla (video de un monitor) de un editor tipo MetaHuman, guardadas por Joan.
Relacionadas: `skyrim_faces/`, `dark_and_darker_faces/` (techo de fidelidad), `hair_undercut_viking/`,
`hair_braided/` (peinados), `hair_polygon_shells/` (técnica descartada, scalp cap sigue válido).
