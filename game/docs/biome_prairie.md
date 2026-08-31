# Bioma: Pradera Interior — Diseno Completo

**Version**: 1.0
**Fecha**: 2026-04-09
**Estado**: Design Document
**Departamento**: Game Design

**Tier**: 1 (siempre Piso 1)
**Banda**: 1 (Baja complejidad)
**Nivel jugador**: 1 → ~2-3 (primer piso, tutorial expandido)
**Tamano**: 600 x 600 m (borde organico con Perlin noise)
**Referencia**: SAO Piso 1, Valheim Meadows, Ragnarok Online Prontera Fields, Metin2 Map1

---

## 1. Identidad del Bioma

### Concepto

Un campo abierto DENTRO de una caverna colosal. El techo de piedra tiene un diamante gigante que emite luz calida como un sol artificial. Hierba verde hasta donde alcanza la vista, colinas suaves, arboles dispersos, un lago, ruinas antiguas. Parece un mundo exterior, pero estas dentro de una torre.

La sensacion es de FALSA SEGURIDAD. Todo se ve tranquilo y bonito, pero hay criaturas por todas partes. Es el piso donde aprendes que este mundo es peligroso, pero de a poco.

### Atmosfera

- Luz: calida, dorada, sombras suaves desde el diamante del techo
- Sonido: viento suave, pajaros, agua corriendo, crujidos de hierba
- Temperatura: templada, agradable
- Sensacion: nostalgia, calma inicial que se rompe con el primer combate

### Paleta de colores

- **Terreno**: verde esmeralda (pasto), marron tierra (caminos), gris piedra (ruinas)
- **Agua**: azul cristalino (lago), blanco espuma (cascada)
- **Vegetacion**: verde claro (hierba), verde oscuro (arboles), amarillo (flores silvestres), blanco (margaritas)
- **Cielo/Techo**: gris piedra oscuro con el diamante blanco-dorado en el centro

---

## 2. Geografia — Zonas del Mapa

El mapa de 600x600m se divide en zonas geograficas. Cada zona tiene su propia identidad visual, fauna y densidad de packs. El generador procedural distribuye estas zonas segun la seed, pero siempre mantiene la proporcion general.

### Mapa conceptual de zonas

```
    ╔═══════════════════════════════════════════╗
    ║              ACANTILADOS (borde)           ║
    ║    ┌─────────┐                             ║
    ║    │ COLINAS  │    PRADERA                 ║
    ║    │ ALTAS    │    ABIERTA                 ║
    ║    └─────────┘       (zona central,        ║
    ║                       mas grande)          ║
    ║  BOSQUECITO  ╔═══════════╗   RUINAS        ║
    ║  DE ROBLES   ║   LAGO    ║   ANTIGUAS      ║
    ║              ║ + CASCADA ║                  ║
    ║              ╚═══════════╝                  ║
    ║                                             ║
    ║    CAMPAMENTO        ZONA                   ║
    ║    ABANDONADO        ROCOSA                 ║
    ║                                             ║
    ║    ┌──────────────────────┐                 ║
    ║    │  ENTRADA (portal)    │   ARENA BOSS    ║
    ║    └──────────────────────┘                 ║
    ║              ACANTILADOS (borde)            ║
    ╚═══════════════════════════════════════════╝
```

> Nota: la distribucion exacta es procedural. Este mapa es CONCEPTUAL — muestra que zonas existen, no su posicion fija.

### 2.1 Pradera Abierta (zona central — ~40% del mapa)

**Descripcion**: Campos de hierba verde con colinas suaves, flores silvestres, caminos de tierra. La zona mas grande y abierta. Visibilidad maxima. Aqui hay mas packs de mobs que en ninguna otra zona.

**Terreno**: Plano con ondulaciones suaves (heightmap con noise de baja frecuencia). Caminos de tierra conectan los POIs.

**Vegetacion**:
- Hierba alta (0.5-1m) en parches — puede ocultar agujeros y slimes
- Flores silvestres (amarillas, blancas, azules) — decorativas
- Arboles solitarios dispersos (robles bajos) — landmarks visuales
- Arbustos de bayas — recolectables (pociones basicas)

**Fauna**: Slimes, mariposas (decorativas), conejos (decorativos), pajaros.

**Packs tipicos**: 3-5 slimes pastando, 2-3 pajaros en vuelo, 1 pack mixto slimes + zorro.

**Peligros**: Agujeros ocultos en hierba alta (danio de caida menor), plantas venenosas (DoT leve).

### 2.2 Lago y Cascada (~10% del mapa)

**Descripcion**: Un lago de agua cristalina alimentado por una cascada que cae desde una formacion rocosa. La cascada oculta una cueva detras (POI secreto). Orilla con juncos, piedras lisas, nenufares.

**Terreno**: Depresion natural. Orillas de arena/piedra. El agua es vadeable en los bordes (0.5m de profundidad), profunda en el centro (3m+, ralentiza movimiento).

**Vegetacion**:
- Juncos y canias en la orilla
- Nenufares en el agua
- Sauce lloron (1-2 arboles grandes en la orilla)
- Musgo en las rocas de la cascada

**Fauna**: Ranas (decorativas), peces (recolectables), slimes de agua (variante azul, solo en la orilla).

**Packs tipicos**: 2-3 slimes de agua en la orilla, 1-2 tortugas (pasivas, sub-A, mucho HP poco DMG).

**POI especial**: Cueva detras de la cascada — cofre con loot, posible NPC mercader.

### 2.3 Colinas Altas (~12% del mapa)

**Descripcion**: Elevaciones de 10-20m sobre el nivel del campo. Desde arriba se ve gran parte del mapa. Terreno irregular, rocas expuestas, viento mas fuerte. Nidos de pajaros en las cimas.

**Terreno**: Pendientes de 20-40 grados. Rocas grandes. Cimas planas pequenas.

**Vegetacion**:
- Hierba corta resistente al viento
- Flores de montana (moradas, resistentes)
- Arbustos espinosos (danio leve al contacto)

**Fauna**: Pajaros (nidos en la cima), cabras montesas (sub-A, pasivas), halcones (sub-B, agresivos, atacan en picada desde arriba).

**Packs tipicos**: 2-3 halcones patrullando desde arriba, 4-5 cabras en la ladera, nido de pajaros (4-6 pajaros, agrean si te acercas al nido).

**Peligros**: Caida desde las cimas (danio de caida), viento fuerte (empuja proyectiles).

### 2.4 Bosquecito de Robles (~8% del mapa)

**Descripcion**: Un grupo denso de arboles viejos. Dentro hay sombra, hongos, troncos caidos. Visibilidad reducida respecto a la pradera abierta. Sensacion de mini-dungeon natural.

**Terreno**: Plano pero con raices expuestas (tropiezo), troncos caidos (cobertura).

**Vegetacion**:
- Robles grandes (3-5m de alto, copas densas)
- Hongos en troncos caidos (recolectables: ingredientes de pociones)
- Musgo, helechos, hiedra en los troncos

**Fauna**: Zorros (sub-B, esquivos, atacan y huyen), aranas pequenas (sub-A, en telaranas), lobos (sub-B, pack AI estricto).

**Packs tipicos**: 3 zorros cazando juntos, 5-6 aranas en telaranas entre arboles, 2-3 lobos patrullando el perimetro.

**Peligros**: Telaranas (ralentizan 30%), hongos toxicos (nube DoT si los pisas).

### 2.5 Ruinas Antiguas (~8% del mapa)

**Descripcion**: Restos de una civilizacion antigua. Muros rotos, columnas caidas, pisos de piedra cubiertos de hierba. Sensacion de que algo vivia aqui antes. Los bandidos lo usan como campamento.

**Terreno**: Piedra tallada rota, escalones, plataformas elevadas (cobertura, ventaja de altura).

**Vegetacion**:
- Hiedra cubriendo muros
- Hierba creciendo entre las piedras
- Arboles jovenes rompiendo el suelo de piedra

**Fauna**: Bandidos (sub-C, humanoides con armas), ratas (sub-A, en los sotanos), murcielagos (sub-A, salen en grupos si molestas).

**Packs tipicos**: 2 bandidos melee + 1 bandido arquero (formacion), 6-8 ratas en sotano, 4-5 murcielagos en techo.

**POI especial**: Sotano de las ruinas — mini-dungeon de 1-2 salas, cofre al final, acceso a la cripta (issue #29).

### 2.6 Zona Rocosa (~8% del mapa)

**Descripcion**: Terreno pedregoso con formaciones rocosas grandes. Rocas apiladas, grietas, cuevas pequenas. Terreno dificil de navegar. Hogar de golems.

**Terreno**: Piedra irregular, desniveles de 1-3m, grietas (caida), cuevas superficiales (2-3m de profundidad).

**Vegetacion**:
- Liquenes en las rocas
- Cactus enanos (decorativos, zona seca)
- Hierba seca y amarillenta

**Fauna**: Golems de piedra (sub-C, se camuflan como rocas hasta que te acercas), escorpiones (sub-B, veneno), serpientes (sub-A, en grietas).

**Packs tipicos**: 1 golem solo (sub-C solitario), 3-4 escorpiones en grupo, 2-3 serpientes en grietas, 1 golem + 4 serpientes (golem las protege).

**Peligros**: Caida en grietas, rocas que se desmoronan (danio AoE si te paran cerca).

### 2.7 Campamento Abandonado (~4% del mapa)

**Descripcion**: Un campamento de aventureros que fracasaron. Tiendas rotas, fogata apagada, suministros desperdigados. Loot garantizado pero custodiado.

**Terreno**: Plano, claro del bosque o pradera. Fogata central, tiendas, cajas.

**Contenido**:
- Cajas con loot (pociones, equipamiento Common)
- Mesa de crafteo temporal (1 uso)
- Diario de aventurero (lore)

**Fauna**: Saqueadores (bandidos sub-C que llegaron antes que vos), ratas (sub-A en las cajas).

### 2.8 Acantilados / Borde del mapa

**Descripcion**: Paredes de roca que delimitan el mapa. No son invisibles — son acantilados naturales de 15-20m que suben hacia el techo de la caverna. En algunos puntos hay cuevas y repisas.

**Contenido**:
- Cuevas en la pared (POI secreto, loot o NPC)
- Cascadas menores que caen del acantilado
- Nidos de aves rapaces en las repisas altas

### 2.9 Arena del Boss

**Descripcion**: Una zona circular de 80x80m marcada por pilares de piedra antiguos. El terreno cambia a un circulo de hierba corta perfectamente cortada — algo antinatural que indica que este lugar es especial. El boss aparece cuando el jugador entra.

**Terreno**: Circulo plano perfecto, pilares de piedra en los bordes (cobertura parcial).

---

## 3. Criaturas de la Pradera — Catalogo Completo

### 3.1 Sub-tier A — Fauna basica

Criaturas abundantes, poco peligrosas individualmente. Aprendes a pelear con ellas.

#### Slime Verde
- **Stats**: HP 50, DMG 5, DEF 0, XP 10
- **Visual**: Gelatina verde translucida, 0.5m de alto, rebota al moverse
- **Comportamiento**: Pasivo. Se mueve lento rebotando. Ataca solo si lo golpeas primero o te acercas a <3m
- **Ataque**: Embestida (se lanza contra el jugador, corto alcance)
- **Loot**: Gelatina de slime (material crafting), chance de pocion menor
- **Pack tipico**: 3-5 pastando juntos en pradera abierta
- **Nota**: Al morir se parte en efecto jelly (ya implementado en el knockback system)

#### Rata
- **Stats**: HP 30, DMG 3, DEF 0, XP 5
- **Visual**: Rata gris, pequena (0.3m), rapida
- **Comportamiento**: Huye si esta sola. Agresiva si hay 3+ ratas juntas
- **Ataque**: Mordida rapida (poco danio, mucha velocidad de ataque)
- **Loot**: Cola de rata (material), chance de moneda suelta
- **Pack tipico**: 6-8 en sotanos de ruinas, 3-4 en cajas del campamento
- **Nota**: En grupo son molestas por volumen, no por danio individual

#### Serpiente
- **Stats**: HP 40, DMG 6, DEF 0, XP 8
- **Visual**: Serpiente marron/verde, 1m de largo, se arrastra
- **Comportamiento**: Se esconde en hierba alta o grietas. Ataca si pisas cerca
- **Ataque**: Mordida con mini-veneno (3 ticks de 2 DMG)
- **Loot**: Colmillo de serpiente (material), veneno basico (alquimia)
- **Pack tipico**: 2-3 en grietas de zona rocosa, 1-2 ocultas en hierba alta

#### Arana Pequena
- **Stats**: HP 35, DMG 4, DEF 0, XP 7
- **Visual**: Arana marron, 0.4m, telaranas entre arboles
- **Comportamiento**: Espera en telarana. Ataca cuando el jugador toca la red
- **Ataque**: Mordida + telarana (ralentiza 30% por 2s)
- **Loot**: Seda de arana (material crafting, textiles)
- **Pack tipico**: 5-6 en el bosquecito entre arboles

#### Conejo (pasivo/decorativo)
- **Stats**: HP 15, DMG 0, DEF 0, XP 2
- **Visual**: Conejo blanco/marron, huye al ver al jugador
- **Comportamiento**: 100% pasivo, huye siempre. No ataca jamas
- **Loot**: Piel de conejo (material), carne (consumible: cura 5 HP)
- **Pack tipico**: 2-3 en pradera abierta, huyen en cuanto te ven

#### Cabra Montesa
- **Stats**: HP 60, DMG 4, DEF 2, XP 8
- **Visual**: Cabra gris/blanca, cuernos pequenos, en las colinas
- **Comportamiento**: Pasiva hasta que la atacas. Entonces EMBISTE con fuerza
- **Ataque**: Embestida (knockback fuerte, danio medio). Ataca 1 vez y huye
- **Loot**: Cuerno de cabra (material), piel (material)
- **Pack tipico**: 4-5 en ladera de colinas

#### Tortuga
- **Stats**: HP 90, DMG 3, DEF 8, XP 12
- **Visual**: Tortuga marron/verde, 0.6m, lenta, se retrae en caparazon
- **Comportamiento**: Pasiva. Si la atacas, se retrae (DEF sube a 20 por 3s). Ataque lento
- **Ataque**: Mordida lenta (bajo danio, alta defensa)
- **Loot**: Caparazon (material: escudos/armaduras), hierba acuatica
- **Pack tipico**: 2-3 en orilla del lago
- **Nota**: Ensenha al jugador que DEF alta existe — hay que esperar a que saque la cabeza

### 3.2 Sub-tier B — Depredadores

Criaturas que cazan, patrullan, flanquean. Requieren atencion y posicionamiento.

#### Pajaro Agresivo (Corvido)
- **Stats**: HP 80, DMG 8, DEF 2, XP 20
- **Visual**: Pajaro negro grande (1m envergadura), ojos rojos, vuelo rasante
- **Comportamiento**: Vuela en circulos sobre una zona. Si detecta jugador, ataca en picada
- **Ataques**: (1) Picada — baja en diagonal, golpea, sube. (2) Graznido — alerta a otros pajaros en 20m
- **Loot**: Pluma negra (material), garra afilada (material: armas)
- **Pack tipico**: 2-3 volando en formacion sobre pradera o colinas
- **Nota**: Dificil de golpear en melee cuando vuela. El mago tiene ventaja aca

#### Zorro
- **Stats**: HP 70, DMG 9, DEF 1, XP 18
- **Visual**: Zorro rojo/naranja, rapido, esquivo
- **Comportamiento**: Caza en grupo. Uno ataca de frente, los otros rodean
- **Ataques**: (1) Mordida rapida. (2) Esquive lateral — tiene 20% chance de esquivar ataque melee
- **Loot**: Piel de zorro (material: armadura ligera), cola (material: accesorios)
- **Pack tipico**: 3 zorros coordinados en el bosquecito
- **Nota**: Primer enemigo que enseña ESQUIVE al jugador

#### Lobo
- **Stats**: HP 90, DMG 10, DEF 2, XP 22
- **Visual**: Lobo gris, 1m de alto, ojos amarillos, se mueve en grupo
- **Comportamiento**: Pack AI estricto. El alfa ataca primero. Si matas al alfa, los demas huyen. Si no, flanquean
- **Ataques**: (1) Mordida. (2) Embestida — carga 5m en linea recta, knockback
- **Loot**: Piel de lobo (material: armadura), colmillo (material: armas)
- **Pack tipico**: 2-3 lobos con 1 alfa (ligeramente mas grande y HP +20%)
- **Nota**: Primer enemigo con JERARQUIA de pack. Matar al alfa es estrategia clave

#### Escorpion
- **Stats**: HP 75, DMG 8, DEF 3, XP 20
- **Visual**: Escorpion marron/negro, 0.6m, pinzas y aguijon
- **Comportamiento**: Defiende territorio. No persigue lejos. Ataque de veneno
- **Ataques**: (1) Pinza (melee corto). (2) Aguijon — veneno (4 ticks de 3 DMG, total 12)
- **Loot**: Aguijon (material: armas envenenadas), quitina (material: armadura)
- **Pack tipico**: 3-4 en zona rocosa
- **Nota**: Enseha al jugador sobre VENENO (DoT) — necesita pociones de antidoto

#### Halcon
- **Stats**: HP 65, DMG 11, DEF 1, XP 22
- **Visual**: Ave rapaz marron/dorada, rapida, ataque desde altura
- **Comportamiento**: Vuela alto sobre colinas. Ataque en picada mas rapido que el corvido
- **Ataques**: (1) Picada rapida — baja, golpea, sube en <1s. (2) Agarre — intenta agarrar y soltar (danio de caida)
- **Loot**: Pluma dorada (material raro), garras (material: armas)
- **Pack tipico**: 2 halcones en cimas de colinas
- **Nota**: Mas rapido y peligroso que el corvido. El jugador ya aprendio a lidiar con aereos

#### Avispas
- **Stats**: HP 25, DMG 6, DEF 0, XP 8
- **Visual**: Avispa amarilla/negra, 0.2m, en enjambre
- **Comportamiento**: Pasivas en su nido. Si te acercas <5m al nido, TODO el enjambre agrea
- **Ataques**: (1) Picada — rapida, veneno menor (2 ticks de 1 DMG)
- **Loot**: Miel de avispa (material: pociones), aguijon (material)
- **Pack tipico**: 6-8 avispas alrededor de un nido. Respawnean del nido. Destruir el nido = dejan de spawnear
- **Nota**: Ensehan CONTROL DE ZONA — no te metas en su area o sufris. Destruir el nido es el objetivo

### 3.3 Sub-tier C — Alfa / Inteligente

Enemigos peligrosos que requieren estrategia. Pocos pero letales.

#### Bandido Melee
- **Stats**: HP 120, DMG 12, DEF 5, XP 35
- **Visual**: Humanoide con armadura de cuero, espada/garrote, mascara
- **Comportamiento**: Posicion estrategica. Usa cobertura de las ruinas. Bloquea ataques frontales
- **Ataques**: (1) Tajo horizontal (amplio). (2) Embestida con escudo (knockback + stun 1s). (3) Golpe fuerte cargado (telegraph 1s, alto danio)
- **Loot**: Monedas, equipamiento Common (chance Rare), llaves de cofre
- **Pack tipico**: Nunca solo — siempre 2 melee + 1 arquero
- **Nota**: Primer enemigo HUMANOIDE. Bloquea, esquiva, tiene formacion. Requiere flanqueo o timing

#### Bandido Arquero
- **Stats**: HP 80, DMG 14, DEF 2, XP 30
- **Visual**: Humanoide con arco, se posiciona en altura (muros, plataformas)
- **Comportamiento**: Se queda atras. Se reposiciona si te acercas. Prioriza mantener distancia
- **Ataques**: (1) Flecha normal (15m rango). (2) Flecha envenenada (10 DMG + DoT). (3) Disparo rapido (2 flechas seguidas, menos danio)
- **Loot**: Flechas (consumible), arco basico (equip Common), monedas
- **Pack tipico**: 1-2 en posicion elevada, apoyando a melee
- **Nota**: Obliga al jugador a CERRAR DISTANCIA o usar cobertura. El mago tiene ventaja de rango aqui

#### Bandido Lider (mini-boss de zona)
- **Stats**: HP 180, DMG 14, DEF 7, XP 60
- **Visual**: Bandido mas grande, armadura mejor, capa roja, arma de dos manos
- **Comportamiento**: Ordena a los demas bandidos. Si muere, los demas pierden moral (ataque -30%)
- **Ataques**: Todos los del bandido melee + (4) Grito de guerra (buffea aliados +20% DMG por 5s)
- **Loot**: Equipamiento Rare garantizado, monedas x3, chance de mapa del tesoro
- **Pack tipico**: 1 lider + 2 melee + 1 arquero (escuadra completa)
- **Nota**: Enseha PRIORIDAD DE TARGETS. Matas al lider primero para debilitar al grupo. O al arquero para dejar de tomar danio a distancia

#### Golem de Piedra
- **Stats**: HP 160, DMG 13, DEF 10, XP 40
- **Visual**: Humanoide de piedra, 2.5m de alto, lento, ojos brillantes
- **Comportamiento**: Se camufla como roca. Se activa cuando el jugador pasa a <5m. Muy lento pero imparable
- **Ataques**: (1) Punetazo (alto danio, knockback). (2) Pisotada AoE (danio en area 3m). (3) Lanzar roca (rango 10m, telegraph visible)
- **Loot**: Nucleo de piedra (material raro: golems, escudos), mineral (crafting)
- **Pack tipico**: 1 solo (solitario) o 1 golem + 4 serpientes (las protege)
- **Nota**: Primer enemigo TANQUE real. Alto DEF, resistente a danio fisico. El mago es efectivo. El guerrero necesita golpear por atras o esperar la apertura post-ataque

---

## 4. Boss: Rey Slime

### Concepto

El slime mas grande y antiguo de la pradera. Absorbe otros slimes para crecer. Parece ridiculo — es una bola gigante de gelatina verde con una corona oxidada flotando dentro. Pero es genuinamente peligroso con sus mecanicas.

**Referencia**: King Slime (Terraria), Slime boss (Dragon Quest), Gran Jaggi (Monster Hunter — primer boss que enseha patrones)

### Stats

| Stat | Valor | Nota |
|------|-------|------|
| HP | 600 | 3x tier 2-A (patron: boss HP = 3x next tier sub-A) |
| DMG | 10 | = tier 2-A base. La peligrosidad viene de los combos |
| DEF | 8 | Resistente pero no impenetrable |
| XP | 100 | Recompensa de boss |

### Visual

- **4.5m de alto — 2.5x el jugador** (`stand_height = 1.8m`). Decidido por el owner 2026-07-31.
  Con el ratio de silueta 1.18:1 eso da ~5.31m de ancho (radio 2.65m).
  **NO bajar a 3m.** Ese valor era del doc viejo y es solo 1.67x el jugador — no lee como boss.
  Ya pasó una vez: el asset se construyo a 6m, alguien leyo "3m" aca y lo achico a la mitad
  tratandolo como defecto. No era un defecto: el doc estaba corto.
- Gelatina verde oscuro translucida. **El rey es verde**, no dorado ni rojo — la jerarquia se
  cuenta con valor y saturacion, no cambiando de color: los subditos verde claro, el rey verde
  profundo. Misma familia, mando obvio. Ver §4.1 para el sistema de color de la familia gel.
- Corona oxidada visible DENTRO de la gelatina (lore: era un rey que fue absorbido — **se trago
  al monarca entero, insignias incluidas**; no es un slime que *es* rey).
  **La corona va grande** y debe leerse a distancia. Su problema nunca fue el tamaño absoluto
  sino el **ratio corona/cuerpo**: con el cuerpo a 4.5m la corona entra grande sin comerse la
  silueta. Debe leer como metal oxidado (marron-rojizo apagado), NO como gema verde brillante.
- Cuando pierde HP, se vuelve mas transparente y se ven huesos/objetos dentro
- En fase final, brilla y se vuelve inestable

### 4.1 Sistema de color de la familia gel

Cada color hace un trabajo. No son decoracion — son lenguaje que el jugador aprende a leer.

| Color | Significa |
|-------|-----------|
| Verde claro | Comun, pradera |
| Azul | Agua, lagos |
| Verde profundo | El rey — jerarquia, no especie nueva |
| Dorado | Raro, huye del jugador, XP alta (patron Metal Slime de Dragon Quest) |
| Rojo | Fuego / lava, piso caliente |

El dorado y el rojo estan **reservados**: gastarlos en el boss del piso 1 quema la carta mas
fuerte del sistema. Un destello dorado entre el pasto que sale corriendo vale mas que un jefe
dorado.

### Arena

Circulo de 80x80m con 6 pilares de piedra (cobertura). El piso es hierba corta. Cuando el boss invoca slimes, aparecen del suelo gelatinoso que se forma alrededor.

### Fases

#### Fase 1 — "La Bola" (100%-75% HP)

El jugador aprende los movimientos basicos del boss.

| Ataque | Descripcion | Telegraph | Danio |
|--------|-------------|-----------|-------|
| Rebote | Salta y aterriza sobre el jugador | Sombra en el suelo, 1.5s | 10 + onda de choque 3m |
| Embestida | Rueda hacia el jugador | Se comprime 1s, luego carga | 12, knockback |
| Escupitajo | Lanza bola de slime a distancia | Infla la "mejilla", 0.8s | 8 + ralentiza 30% 2s |

**Ritmo**: Ataca cada 3-4 segundos. Ventana de ataque clara despues de cada movimiento.

#### Fase 2 — "Division" (75%-50% HP)

Agrega mecanica nueva: invoca mini-slimes.

- Todo lo de Fase 1 +
- **Invocacion**: cada 20s expulsa 3 mini-slimes (HP 25 cada uno). Si no los matas, el boss los REABSORBE y cura 30 HP por slime
- **Escupitajo mejorado**: ahora dispara 3 bolas en abanico

**Leccion**: el jugador aprende a priorizar adds (matar slimes antes de que los reabsorba).

#### Fase 3 — "Tormenta de Gelatina" (50%-25% HP)

Sube la intensidad. El boss se vuelve mas rapido y agresivo.

- Todo lo anterior +
- **Combo rebote**: 3 saltos seguidos en lugar de 1 (cada uno mas rapido)
- **Charco acido**: al aterrizar deja un charco verde (DoT 3/s por 5s, radio 2m)
- **Invocacion x2**: expulsa 5 mini-slimes cada 15s

**Leccion**: el jugador aprende a MOVERSE CONSTANTEMENTE. No podes quedarte quieto.

#### Fase 4 — "Desesperacion" (25%-0% HP)

El boss esta perdiendo. Se vuelve inestable y peligroso.

- **Modo furia**: velocidad de movimiento +50%, todos los ataques mas rapidos
- **Explosion periodica**: cada 10s emite onda de choque AoE (5m, 8 DMG). El jugador debe alejarse o usar pilares
- **Ultimo aliento**: al llegar a 5% HP, se infla durante 3s (telegraph claro) y EXPLOTA — 20 DMG AoE 8m. Si no te alejas, duele
- **No invoca mas slimes** — es el 1v1 final

### Loot del Boss

| Drop | Probabilidad | Tipo |
|------|-------------|------|
| Corona Oxidada | 100% | Accesorio (quest item, venderle a un NPC en la taverna cuenta la historia) |
| Nucleo de Gelatina Real | 100% | Material (craftear armadura anti-slime o pociones) |
| Equipamiento Rare | 80% | 1 pieza random |
| Equipamiento Epic | 15% | 1 pieza random |
| Receta de pocion | 30% | Pocion de elasticidad (esquive +10% temporal) |

### Diseno de combate

El Rey Slime enseha TODAS las mecanicas basicas del juego:
1. **Esquivar** (telegraphs claros en cada ataque)
2. **Usar cobertura** (pilares para bloquear escupitajos)
3. **Priorizar targets** (matar adds antes de que cure)
4. **Posicionarse** (charcos acidos, AoE de explosion)
5. **Reconocer fases** (el boss cambia, vos tenes que adaptarte)

Si un jugador le gana al Rey Slime, sabe jugar. Ese es el punto.

---

## 5. Distribucion de Packs en el Mapa

### Densidad por zona

| Zona | Packs | Densidad | Dificultad predominante |
|------|-------|----------|------------------------|
| Pradera Abierta | 15-20 | Alta | Sub-A (slimes, conejos) con Sub-B dispersos (pajaros) |
| Lago y Cascada | 3-5 | Baja | Sub-A (tortugas, slimes de agua) |
| Colinas Altas | 5-8 | Media | Sub-B (halcones, lobos) con Sub-A (cabras) |
| Bosquecito | 5-7 | Media-Alta | Sub-B (zorros, lobos) con Sub-A (aranas) |
| Ruinas | 4-6 | Media | Sub-C (bandidos) con Sub-A (ratas, murcielagos) |
| Zona Rocosa | 4-6 | Media | Sub-C (golems) con Sub-A/B (serpientes, escorpiones) |
| Campamento | 2-3 | Baja | Sub-C (saqueadores) con Sub-A (ratas) |
| Borde/Acantilados | 2-3 | Muy Baja | Sub-B (aves rapaces), Sub-A (cabras) |

**Total en el mapa**: ~40-55 packs activos. Con packs de 2-6 mobs cada uno = ~120-200 mobs vivos a la vez.

### Composicion de packs por zona

**Pradera Abierta** (la mas comun — el jugador esta aca la mayor parte del tiempo):
```
Pack comun:     4 slimes verdes (A+A+A+A)
Pack comun:     2 slimes + 2 conejos (A+A+pasivo+pasivo)
Pack medio:     3 slimes + 1 pajaro (A+A+A+B) — el pajaro los "pastorea"
Pack raro:      1 zorro cazando 2 conejos (B+pasivo+pasivo) — escena natural
Pack medio:     2 serpientes ocultas en hierba (A+A) — emboscada
```

**Colinas**:
```
Pack comun:     4 cabras en la ladera (A+A+A+A)
Pack medio:     2 halcones patrullando (B+B) — atacan desde arriba
Pack raro:      Nido de pajaros en la cima (6 corvidos, B+B+B+B+B+B) — zona de peligro
```

**Bosquecito**:
```
Pack comun:     5 aranas en telarana (A+A+A+A+A) — zona de control
Pack medio:     3 zorros de caza (B+B+B) — flanquean
Pack fuerte:    2 lobos + 1 alfa (B+B+B_alfa) — jerarquia
Pack raro:      1 lobo alfa solo (B_alfa) — patrullando perimetro
```

**Ruinas**:
```
Pack fuerte:    2 bandidos melee + 1 arquero (C+C+C)
Pack elite:     1 lider + 2 melee + 1 arquero (C_boss+C+C+C)
Pack comun:     6 ratas en sotano (A+A+A+A+A+A)
Pack medio:     4 murcielagos en techo (A+A+A+A) — activados por ruido
```

**Zona Rocosa**:
```
Pack fuerte:    1 golem solo (C) — se camufla como roca
Pack comun:     3 escorpiones (B+B+B)
Pack medio:     3 serpientes en grietas (A+A+A)
Pack raro:      1 golem + 4 serpientes (C+A+A+A+A) — el golem las "protege"
```

---

## 6. Ecologia y Recolectables

### Plantas y hierbas

| Planta | Zona | Uso | Frecuencia |
|--------|------|-----|-----------|
| Hierba curativa | Pradera abierta | Pocion de vida menor (cura 20 HP) | Comun |
| Flor de sol | Pradera abierta | Pocion de mana menor (restaura 15 MP) | Comun |
| Hongo marron | Bosquecito | Ingrediente: antidoto | Moderado |
| Hongo rojo | Bosquecito | VENENO si lo comes. Ingrediente: pocion de danio | Raro |
| Baya azul | Pradera/Bosquecito | Consumir directamente: cura 5 HP | Comun |
| Raiz de piedra | Zona rocosa | Ingrediente: pocion de defensa | Moderado |
| Nenufar | Lago | Ingrediente: pocion de regeneracion | Raro |
| Flor de viento | Colinas | Ingrediente: pocion de velocidad | Raro |

### Minerales

| Mineral | Zona | Uso |
|---------|------|-----|
| Piedra comun | Zona rocosa, ruinas | Material basico: flechas, herramientas |
| Mineral de hierro | Zona rocosa, cuevas | Material: armas y armaduras Common |
| Cuarzo | Cuevas, acantilados | Material: joyeria, gemas basicas |

### Pesca (lago)

| Pez | Uso |
|-----|-----|
| Pez comun | Consumir: cura 10 HP. Cocinar: cura 20 HP |
| Pez dorado | Vender por monedas (valor alto) |
| Pez raro (1% chance) | Material: pocion especial |

---

## 7. Resumen de Criaturas

| Criatura | Sub-tier | HP | DMG | DEF | XP | Zona principal |
|----------|----------|-----|-----|-----|----|---------------|
| Slime verde | A | 50 | 5 | 0 | 10 | Pradera abierta |
| Rata | A | 30 | 3 | 0 | 5 | Ruinas |
| Serpiente | A | 40 | 6 | 0 | 8 | Zona rocosa, hierba |
| Arana pequena | A | 35 | 4 | 0 | 7 | Bosquecito |
| Conejo | A (pasivo) | 15 | 0 | 0 | 2 | Pradera abierta |
| Cabra montesa | A | 60 | 4 | 2 | 8 | Colinas |
| Tortuga | A (tanque) | 90 | 3 | 8 | 12 | Lago |
| Pajaro corvido | B | 80 | 8 | 2 | 20 | Pradera, colinas |
| Zorro | B | 70 | 9 | 1 | 18 | Bosquecito |
| Lobo | B | 90 | 10 | 2 | 22 | Bosquecito |
| Escorpion | B | 75 | 8 | 3 | 20 | Zona rocosa |
| Halcon | B | 65 | 11 | 1 | 22 | Colinas |
| Avispas | B (enjambre) | 25 | 6 | 0 | 8 | Pradera (nidos) |
| Bandido melee | C | 120 | 12 | 5 | 35 | Ruinas |
| Bandido arquero | C | 80 | 14 | 2 | 30 | Ruinas |
| Bandido lider | C (mini) | 180 | 14 | 7 | 60 | Ruinas |
| Golem de piedra | C | 160 | 13 | 10 | 40 | Zona rocosa |
| **Rey Slime** | **BOSS** | **600** | **10** | **8** | **100** | **Arena** |

**Total**: 17 tipos de criaturas + 1 boss = 18 entidades unicas para la Pradera.
