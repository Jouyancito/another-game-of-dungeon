# bandit_figure — bandido melee, arquero y jefe (2026-08-22)

Ficha del **personaje** bandido. El campamento ya tiene la suya en
`_references/bandit_camp/`; esta es la figura, que el bestiario deja como slots 6.1 y 6.2
*[pendiente-referencia]* y pone **segundos en la cola: golem → bandido → lobo**.

## Lo que el canon YA fija — no hay que inventarlo

De `_bestiary_visual_bible.md`:

- **Familia de silueta: humanoide** — *"bípedo, hombros, arma en mano"*, y el rasgo que los
  separa entre sí es **la silueta del arma**: espada vs arco. A 20 m no se distingue una cara;
  se distingue qué lleva en la mano.
- **NO endémicos, y se marcan como tales**: son *"evidencia de que otros estuvieron acá"*. No
  pertenecen al bioma — pertenecen a una historia. Esa es su carga narrativa.
- **Color: tela oscura, no-fauna.** Se separan del ecosistema por material: donde la fauna es
  pelaje y quitina desaturados, ellos son **tela, cuero y metal**.

De `bandit_camp/_synthesis.md`, la identidad de frontera que hay que trasladar del campamento a
la persona: **improvisado, despareja, curtido, amarrado con soga, jirones de tela colgando**.
Nada prolijo ni de a pares. Lo que hace bandido a un bandido es que **nada le hace juego**.

## Escala — ya está resuelta

El cuerpo base del guerrero mide **1,80 m** y su blockout de proporciones vive en
`gen_proportion_blockout.py`. Los bandidos son humanos: misma escala, sin excepción.

- **Bandido melee**: contextura de guerrero, hombros más anchos que el jugador promedio.
- **Bandido arquero**: humanoide **ágil** (así lo llama el bestiario) — más liviano, hombros más
  angostos, postura más erguida.
- **Jefe bandido**: la jerarquía se lee por **volumen de equipo, no por estatura**. Un jefe más
  alto miente sobre la escala humana; un jefe con más capas, una pieza de armadura robada y una
  capa se lee al instante. Máximo 1,90 m.

## Silueta — el orden en que se lee

1. **El arma** (el bestiario lo dice explícito): espada corta y ancha vs arco largo curvo. El
   arco es la mejor lectura de silueta de todo el roster porque es una línea que rompe el
   contorno del cuerpo.
2. **La cabeza**: capucha (arquero), cabeza descubierta o pañuelo (melee), casco robado
   desparejo (jefe).
3. **La asimetría**: una hombrera y no dos. Un guante y no un par. Es la firma "bandido" y sale
   gratis en polígonos.

## Vestuario — qué material va dónde

`_asset_creation_contract.md` §3c y §Tier 0 ya definen que **la prenda REEMPLAZA la región del
cuerpo, no lo viste** — hay que ir a ese documento antes de modelar ropa, no improvisarlo acá.

Registro: cuero curtido y manchado, tela basta teñida de oscuro, metal **sólo en piezas sueltas
y desparejas** (una hebilla, una hombrera, un casco), soga y correas atando lo que no calza.
Nada de conjuntos completos: cada pieza tiene que parecer conseguida por separado.

Techo de fidelidad: **Skyrim** (§3b) — capas modeladas, hebillas con geometría, normal map para
arrugas grandes y desgaste. No poros.

## Qué capturar

1. **La silueta del arma primero.** Espada vs arco decide todo lo demás.
2. **Asimetría deliberada**: una hombrera, un guante, nada de a pares.
3. **Tela y cuero oscuros**, sin paleta de fauna — se tienen que ver ajenos al bioma.
4. **El jefe manda por equipo, no por estatura.** Tope 1,90 m.
5. **Jirones y sogas**: el detalle que traslada la identidad del campamento a la persona.
6. Arquero de contextura ágil; melee de contextura pesada. Que se distingan a 20 m sin el arma.

## Decisión pendiente — la misma que el lobo

`_bestiary_visual_bible.md` §5 marca los bandidos como **pack re-skin** (*"bpy script no hace
anatomía curva + rig + ciclo de caminar"*), y sugiere reskin de `enemy_orc.gltf` / ninja.

Pero desde entonces se construyó **un cuerpo humano bespoke completo** — el guerrero, con MPFB,
41 shape keys, cara pintada por texel a 4K y sistema de pelo. **Ese cuerpo es reutilizable para
los bandidos**: son humanos de la misma escala. Rehacerlos con pack re-skin cuando ya existe un
humano propio sería tirar el trabajo del guerrero.

**Para Joan**: ¿los bandidos salen del cuerpo del guerrero (con otro vestuario y otra
contextura vía shape keys), o van pack re-skin como dice el bestiario? Es la decisión que
desbloquea el slot 6.1.

## Hueco declarado
- ⌛ **Faltan referencias visuales del personaje.** El bestiario los marca *[pendiente-referencia]*
  desde julio y siguen sin imagen. `_art_canon.md` nombra LOTR, Metin2, Dark and Darker y
  Tensura como fuentes aprobadas — hacen falta capturas concretas de bandidos/salteadores.
- Ya existe `_references/dark_and_darker_faces/` para caras, que sirve de punto de partida.

**Fuente/fecha**: canon propio (`_bestiary_visual_bible.md` §2/§3/§5, `bandit_camp/_synthesis.md`,
`_asset_creation_contract.md` §3b/§3c). Sintetizado 2026-08-22.
