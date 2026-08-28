# lotr_skyrim — "El Señor de los Anillos en Skyrim": la referencia madre (Joan, 2026-08-28)

**Joan dijo:** *"aquí va una de las referencias más importantes, y está en una de las referencias
que más me gustaría seguir: El Señor de los Anillos y Skyrim."* Y después comentó **cada imagen en
orden**; ese comentario es la fuente de esta síntesis. Lo que sigue por imagen es lo que Joan
destacó, bajado a sistema/asset. 19 capturas de un reel (recreación de escenas de LOTR con el
motor/look de Skyrim; HUD de brújula y barras de Skyrim visibles).

## Lectura imagen por imagen (orden de Joan)

| # | File | Escena | Joan destacó | Sistema / asset al que le habla |
|---|---|---|---|---|
| 1 | `01_balrog_firstperson` | Balrog en el puente de Moria, primera persona con bastón y espada | *"se ve grande, imponente; los efectos de llama y la oscuridad de atrás te dan la sensación de que es lo único frente a ti; cómo se ve la primera persona con su arma — **calza con lo que queremos**; el suelo parece puente de piedra picada, irregular, con textura"* | **Presentación de jefe**: escala + fondo negro que aísla + fuego como única luz. **Manos/armas en primera persona** (bastón izq + espada der = referencia directa del viewmodel). Suelo de piedra irregular con relieve |
| 2 | `02_nazgul_stealth_eye` | Nazgûl a caballo sobre raíces, hobbits escondidos, ícono de ojo | *"mecánica de sigilo: el ojo aparece si te está viendo, cerrado si no; raíces, hoyos, tierra; personajes **muy reconocibles pero no hiperrealistas**"* | **Indicador de sigilo** (ojo abierto/cerrado, estilo Skyrim). Raíces expuestas como terreno jugable. Techo de fidelidad de personajes = reconocible, no hiperreal |
| 3 | `03_troll_moria_door` | Troll rompiendo la puerta, orcos, Gandalf, Aragorn | *"la armadura del troll es **metal sucio**, adecuada; los orcos no son hiperrealistas y se nota que son orcos; buenos colores, texturas, iluminación; suelo, pilares, la puerta rota, **las piedras volando** por la animación"* | Materiales de armadura = metal sucio (roughness alta, suciedad en cavidades). Mobs reconocibles por silueta. **Destrucción con escombros** (piedras volando) |
| 4 | `04_weathertop_nazgul` | Aragorn con antorcha, Frodo caído, Nazgûl encapuchados, ruina | *"**personajes, vestimenta, lo bien definidos y reconocibles**; posturas; la ruina; las escaleras; la iluminación; el entorno es **completamente jugable**"* | Vestuario con silueta clara por personaje. Ruinas transitables (escaleras reales, no decorado). Antorcha como luz puntual |
| 5 | `05_helms_deep_rain` | Asedio del Abismo de Helm, escaleras, lluvia, antorchas | *"los grupos de orcos están **separados, no superpuestos ni colisionando**, está clean; el agua, las antorchas cómo iluminan alrededor, la **lluvia** — esa sensación es agradable"* | **Separación entre unidades** (avoidance, sin interpenetración). Antorchas con radio de luz. Lluvia como sistema de atmósfera |
| 6 | `06_ents_isengard` | Ents atacando la fortaleza, cascada, rocas lanzadas | *"ambiente adecuado: pasto, árboles, agua, río; los ents se sienten árboles andantes **aunque su forma no me gusta mucho, podrían ser mejores**; los árboles son todos similares, estilo pino — **los nuestros / los próximos que trabajaremos son mejores**; el puente roto y la fortaleza sobre una mini isla elevada por piedras es bonito"* | Composición agua+piedra+fortaleza. Ent = anti-referencia de forma. **Variedad de especies de árbol es un diferencial nuestro** (ver `prairie_scene_scatter`, `vegetation/tree-species-architecture`) |
| 7 | `07_gandalf_eomer_sunrise` | Gandalf y Éomer a caballo, claro entre laderas, sol bajo | *"me agrada la luz, se siente como un claro; por la montaña sólo vegetación baja, pero las **laderas son muy adecuadas**; y **montar** en algún momento lo tendremos que trabajar"* | Luz de claro (sol bajo, contraluz en pasto). Laderas de valle como forma de terreno. **Monturas** = tema futuro anotado |
| 8 | `08_sam_shelob` | Sam con el frasco contra Ella-Laraña, Frodo envuelto | *"iluminación genial; diseño de la araña y personajes súper bien logrados; la **telaraña debe ser de bajo requerimiento pero se ve bien**; lo que más destaca es la araña: forma, colores, textura que simula pelos, posiciones"* | Jefe araña: silueta + textura de pelo por albedo/normal (no geometría). Telaraña = cards con alpha, barata. Luz de objeto (frasco) como fuente única |
| 9 | `09_gandalf_saruman_pulse` | Duelo en Orthanc, pulso de escudo que rompe la torre | *"estilo **mago clásico**: batas, túnicas, uso de magia; el efecto de escudo me agrada; hacen un **pulso que rompe la estructura**; quizás no todas las texturas, pero **3-5 formas de destrucción a medida que recibe daño — ¿qué tan lograble es?** con sus efectos de romper; la torre acorde; **el fondo sin tanto detalle pero reconocible**; si no queremos cargar tan lejos, jugar con niebla, nubes, luces"* | Arquetipo de mago (túnica + bastón). VFX de escudo/pulso. **Estados de daño de estructuras (3-5)** — pregunta abierta de Joan, respondida abajo. **LOD por niebla/nubes** para lo lejano |
| 10 | `10_eowyn_witchking` | Éowyn contra el Rey Brujo, grito, campo de batalla | *"cómo están construidos los personajes; la animación de ataque final; **la expresión del personaje — ya no es una malla que no se mueve: dolor, grito, euforia, daño**; uno arrodillado en el suelo, por bloqueo o cansancio, buena pose"* | **Expresiones faciales en combate** (blendshapes mínimos: grito, dolor, esfuerzo). Poses de estado (arrodillado = bloqueo/agotado) |
| 11 | `11_army_of_dead_dock` | Aragorn con el Ejército de los Muertos en el muelle | *"siluetas sólidas, el **efecto verde de ectoplasma** te da a entender que son fantasmas; barcos bien hechos, maderas adecuadas, sogas, cajas, el muelle bien logrado"* | Shader de fantasma (fresnel verde + emisión, malla normal). Props de muelle: madera, sogas, cajas |
| 12 | `12_caradhras_snow` | La Comunidad cruzando la nieve, huellas, rocas cayendo | *"la nieve, el ambiente hostil, los muros cubiertos; **el rastro que deja sería GOOD tenerlo en el juego**; posturas, moverse más lento, tener frío, las piedras cayendo"* | **Huellas/rastro en nieve** (deformación o decals). Clima hostil que afecta movimiento (lento, frío). Desprendimientos como evento ambiental |
| 13 | `13_mumakil_pelennor` | Mûmakil con torres, Legolas trepando, flechas | *"se siente **colosal**, el personaje saltando sigue siendo mucho más pequeño; las estructuras **adheridas, construidas encima, no agregados sin física**; muy bien detallado: arrugas, colmillos con desgaste, colores, iluminación; armadura adecuada a su silueta; **las flechas con su caída, parábola**"* | Escala de jefe colosal con jugador como referencia. Equipo/estructuras que siguen la anatomía del portador. **Proyectiles con parábola** (ya en canon de físicas). Desgaste en materiales (colmillo) |
| 14 | `14_arwen_evenstar_ruins` | Aragorn y Arwen, estatua, ruinas con musgo, luna, "Take Evenstar" | *"precioso el tema de **arquitectura con animación**, musgo de lugar abandonado, enredaderas, la estatua, los pilares, las ruinas, sensación de abandono con oscuridad de luna, místico estilo elfo; personajes con sus vestidos y atuendos; **imagina un NPC entregándote algo que puedas tomar al apuntarlo**"* | Set de ruinas élficas: musgo + enredaderas (`vine/`) + estatua. Luz de luna. **Interacción NPC → objeto por apuntar** (prompt "Take X") |
| 15 | `15_prancing_pony_tavern` | Taberna, Trancos fumando, hobbits en la mesa, chimenea | *"sensación de **bienestar, tranquilidad y festividad**: luces cálidas, NPCs interactuando, chimenea iluminando, arquitectura de taberna estilo Skyrim, piedra con madera; personajes adecuados y realistas; el **gesto de fumar con su humito**"* | Taverna (ver `tavern/`): luz cálida + chimenea + NPCs con idle social. Pipa con humo como gesto/emote |
| 16 | `16_boromir_horn` | Boromir con el cuerno, flechas clavadas, arqueros detrás | *"tiene **flechas incrustadas** de sus enemigos; el gesto de **usar el cuerno como habilidad** me parece muy bueno; ambiente típico camino de Skyrim"* | Proyectiles que quedan clavados en el cuerpo. Habilidad con gesto propio (cuerno = grito/buff). Camino de bosque de Skyrim |
| 17 | `17_gollum_fog_mountain` | Gollum acechando en la montaña, niebla | *"montañas bien construidas, rocosas; destaca la **niebla: a metros no te deja ver, pero la opacidad depende de la distancia** — de cerca igual se ve algo"* | **Niebla por distancia** (densidad exponencial, no muro). Montaña rocosa como forma |
| 18 | `18_black_gate_for_frodo` | Carga hacia la Puerta Negra, "For Frodo" | *(sin comentario de Joan — se guarda sin interpretar)* | — |
| 19 | `19_theoden_curse_purify` | Gandalf sobre Théoden: vórtice violeta + luz blanca, trono | *"los efectos están agradables; podríamos usarlos para **habilidades o efectos de estado: confusión, maldición, purificación**; el trono con su estructura acorde, detallado"* | Lenguaje VFX de estados: violeta = maldición/confusión, blanco = purificación. Prop hero: trono |

## Qué capturar — agrupado por sistema (lo que se repite en el comentario de Joan)

1. **Personajes reconocibles, no hiperrealistas** (imgs 2, 3, 4, 8, 10, 15). Silueta y vestuario
   por clase/rol legibles a 20 m; techo Skyrim (`_asset_creation_contract.md` §3b) confirmado
   por esta referencia. **Expresión facial en combate** (10) es lo nuevo: grito / dolor / esfuerzo.
2. **Materiales que se leen como lo que son** (3, 11, 13, 15): metal sucio, madera, sogas,
   colmillo desgastado. Coincide con `_art_canon.md` §17.
3. **Jefes con escala y aislamiento** (1, 8, 13): fondo oscuro o único foco de luz, jugador como
   regla de medida, equipo que sigue la anatomía del jefe.
4. **Atmósfera como sistema** (5, 7, 12, 14, 17): lluvia, nieve con huellas, niebla por distancia,
   luz de luna, sol bajo en claros. Y **LOD por niebla/nubes** para no cargar lo lejano (9, 17).
5. **Destrucción** (3, 9): escombros al romper + **3-5 estados de daño** en estructuras — ver abajo.
6. **VFX de magia y estado** (9, 11, 19): escudo/pulso, ectoplasma verde, violeta = maldición,
   blanco = purificación. Mago clásico = túnica + bastón.
7. **Interacción y feel** (2, 14, 16): ojo de sigilo, "Take X" al apuntar a un NPC, cuerno como
   habilidad con gesto, flechas clavadas, pipa con humo.
8. **Entorno jugable** (4, 5, 6): ruinas con escaleras reales, unidades sin superponerse, agua +
   piedra + fortaleza. Montar (7) queda anotado como futuro.

## Pregunta de Joan: "3-5 formas de destrucción a medida que recibe daño, ¿qué tan lograble es?"

**Muy lograble, y barato si se hace por estados, no por física.** La receta estándar (Skyrim y la
mayoría de los juegos lo hacen así):

- Cada estructura destruible tiene **N mallas de estado** (intacta → agrietada → parcialmente rota
  → ruina), construidas en Blender como variantes del mismo asset. 3 estados alcanzan; 5 sólo para
  hero (torre de jefe).
- Umbrales por HP (100 / 66 / 33 / 0 %): al cruzar uno, **swap de malla** + ráfaga de
  **GPUParticles3D de escombros** (cards de piedra con gravedad, 0,5-1 s) + polvo + sacudida de
  cámara. El "pulso que rompe" de la img 9 es eso con un flash y un anillo expansivo.
- Lo que NO conviene: fractura en tiempo real (Voronoi + RigidBody por trozo). Cuesta CPU, es
  impredecible y no se ve mejor a la distancia de juego.
- Costo: 1 asset extra por estado (mismo material, misma UV, sólo geometría) + un script de
  ~40 líneas. Ya hay precedente en el repo: el golem colapsa a montón dormido al morir
  (`golem_guardian_preview.gd`, commit 5649960) — es el mismo mecanismo con 2 estados.

## Relación con el canon

- **Confirma** §17 (materiales legibles, luz en charcos cálidos contra ambiente frío, saturación
  para lo mágico) y el techo Skyrim de personajes.
- **Agrega** lo que §17 no tenía: expresión facial en combate, estados de destrucción, atmósfera
  como sistema (lluvia/nieve/niebla por distancia), lenguaje de color para VFX de estado.
- Entra en `_style_catalog.md` como **"LOTR × Skyrim"**: tema de mundo (épica + ruina + clima)
  sobre el techo técnico de Skyrim.

## Fuente
Reel de Instagram: recreación de escenas de *El Señor de los Anillos* con el look de *Skyrim*
(19 capturas). Relacionadas: `village_lotr/`, `skyrim_faces/`, `tavern/`, `vine/`,
`mage_archetype/`, `warrior_archetype/`, `ranger_archetype/`, `world_mood_ig/`.
