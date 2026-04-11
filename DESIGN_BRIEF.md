# Another Game of Dungeon — Design Brief Maestro

> Documento compilado para compartir la visión completa del juego con otro asistente/colaborador.
> Incluye **todas** las decisiones de diseño, referencias, y sistemas discutidos hasta hoy.
> Fecha de corte: 2026-04-10. Estado: prototipo en desarrollo activo.

---

## 1. Concepto

**Another Game of Dungeon** (working title **Dungeon Party**) es un **dungeon crawler cooperativo en primera persona** para 1-6 jugadores. El jugador **baja** por un abismo estilo *Made in Abyss* (no sube una torre), atravesando pisos que son **mundos abiertos completos** — no dungeons de salas conectadas.

- **Engine**: Godot 4.6 / GDScript
- **Plataformas**: Windows, Mac, Linux
- **Networking**: Steam (via GodotSteam)
- **Modelo comercial**: Early Access en Steam, precio inicial USD $14.99
- **Ubicación del equipo**: Chile (tratado fiscal con USA, retención 10%)

### El doble significado de "Party"
El nombre es intencional: **Party = grupo RPG + party con amigos**. Esto convierte al juego en **dungeon crawler coop con capa social**, posicionándolo distinto de *Dark and Darker* / *Deep Rock Galactic* (puro hardcore). La fiesta y los minijuegos son parte del ADN, no pegados con cinta.

---

## 2. Pilares de diseño

1. **Coordinación es poder** — la dificultad no escala con la cantidad de jugadores. Sinergia real, no padding numérico.
2. **Sinergias ganan batallas** — combinaciones de clases desbloquean efectos reales (ej: hielo + rayo = conductor).
3. **Cada run importa** — permadeath con pérdida de loot del run (pero el stash es seguro).
4. **Tu dungeon, tu historia** — mundo persistente con marcas del jugador.
5. **Fácil de aprender, difícil de dominar** — sistemas simples con profundidad emergente.
6. **Hermoso y melancólico** — la atmósfera general debe sentirse post-épica, no solo combate frenético.

---

## 3. Referencias estéticas y narrativas

### Frieren: Beyond Journey's End (anime) — referencia visual clave
- Arquitectura élfica/medieval melancólica, ruinas cargadas de historia
- Paleta cálida pastel, luces doradas, atmósferas nostálgicas
- Props con personalidad — cada objeto parece tener su historia
- **Demonios únicos**: NO el típico rojo con cuernos. Antropomórficos con rasgos inquietantes (ojos extraños, proporciones sutilmente mal)
- Tono general: aventura post-épica, introspectiva, bella tristeza

### Otras referencias
- **Made in Abyss** — estructura descendente del mundo
- **SAO / Danmachi** — cada piso como ecosistema completo, no pasillos
- **Metin 2** — maps MMO grandes con zonas, despawn de drops 3-5 min mostrando el dueño
- **Kimetsu no Yaiba** — paleta de color y atmósferas elementales
- **Diablo 2 / Path of Exile** — UI, inventory grid, stash per-account, character select
- **Shield Hero (Tate no Yusha)** — sistemas de compañeros, monturas, items con progresión narrativa
- **Lethal Company** — diegetic boombox adaptado a fantasy
- **BOTW / Skyrim** — fauna ambiental para que el mundo se sienta vivo
- **Apex Legends** — sistema de ping contextual

---

## 4. Estructura del mundo

### La Torre / Abismo
- **100 pisos potenciales**, con biomas variados
- **Piso 1 y piso 100 fijos**, los intermedios aleatorios por pool de dificultad
- **25 biomas distintos**, no se repiten en un run
- **Adyacencia temática**: transiciones coherentes (seco → semi-seco → húmedo, no saltos extremos)
- La dificultad escala por piso, no por bioma

### Cada piso = mundo abierto completo
- **NO** dungeons de salas
- Piso 1: **600×600m** (escala MMO pequeña)
- Distribución procedural por **POIs con seeds**
- Campo abierto entre POIs con contenido disperso
- Bordes naturales (acantilados, lagos, paredes de torre, cascadas)
- El jugador debe sentir que explora un mundo, no un nivel

### Filosofía pre-50 vs post-50
**Pisos 1-50 (civilización)**:
- Tienen caminos/carreteras con sensación civilizada
- Cerca del camino: bandidos, eventos de combate, NPCs, mercaderes
- Lejos del camino: naturaleza, mini pueblos atacados, quests secundarias
- Progresión narrativa guiada

**Pisos 51-100 (wilderness pura)**:
- Sin caminos
- Exploración pura, por cuenta del jugador
- Se nota la transición narrativa — de sociedad organizada a caos natural

### Safe zones
- **Pisos 25 y 50** = zonas seguras con NPCs, comercio, stash, herreros
- Piso 51+ = hardcore total

---

## 5. Clases (5 al lanzamiento)

1. **Warrior** — melee pesado + combo chain de 5 golpes
   - Ramas: **Tanque** (escudo) / **Berserk** (furia)
2. **Mage** — elementos y magia arcana
   - Ataque base: "finger guns" + bolita inestable de energía
   - Ramas: **Elementalista** (fuego/hielo/rayo) / **Arcano** (espacio)
3. **Archer** — flecha + disparo cargado
   - Ramas: **Ranger** (arco rapid fire) / **Artillero** (pistola/granadas/explosivos — NO ballesta)
4. **Necromancer** — orbe + drenaje de vida
   - Ramas: **Maldiciones** (debuffs) / **Creador** (invocaciones)
5. **Healer / Clerigo** — maza + castigo divino
   - Ramas: **Sanador** (heal directo) / **Buffer** (buffs de party)

### Nota sobre ballesta
Arma genérica, cualquier clase puede usarla. Más lenta que arco, más daño.

### Progresión
- Niveles 1-50, curva XP 1.15x
- **3 stat points por nivel** (150 totales)
- Stats: STR, INT, DEX, DEF, VIT
- **Especialización a nivel 10** (2 ramas por clase)
- **Skill tree** estilo Diablo 2
- **6 resets máximo** por personaje → después se convierte en "The Lost"

---

## 6. Combate y feel

### Sistemas implementados
- **Knockback estilo billar**: dirección del golpe empuja al enemigo
- **Combo chain del Warrior**: 5 golpes en secuencia
- **Slime jelly effect**: enemigos gelatinosos se estiran en el golpe y rebotan
- **Division del slime**: al morir se divide en 4 mini-slimes (con spawn realmente caótico — no en cruz)

### Fórmulas
- Daño físico = base + (STR × 2)
- Daño mágico = base + (INT × 2)
- DEF reduce daño físico (mínimo 1)
- Resistencias elementales cap 75%
- HP total = HP base + (VIT × 5)
- MP total = MP base + (INT × 3)

### Escalado de enemigos por piso
| Piso | HP | Daño | DEF |
|------|----|------|-----|
| 1 Pradera | 100 | 10 | 0 |
| 2 Bosque | 200 | 20 | 5 |
| 3 Hielo | 350 | 35 | 12 |
| 4 Tormenta | 500 | 50 | 20 |
| 5 Dimensión Rota | 700 | 70 | 30 |

---

## 7. Loot, raridades y economía

### Raridades (4 tiers — NO hay Epic)
- **Común** (blanco)
- **Mágico** (amarillo)
- **Raro** (azul)
- **Único** (rojo vino)

### Reglas de loot
- **Equipment drops**: solo **rare, magic y unique**. El common se compra, no cae.
- **Drops en el mundo**: estilo Metin 2 — caen al piso, persisten **3 minutos**, muestran el nombre del dueño en party, blinkean los últimos 30s antes de despawn.
- **Cofres**: aparecen cerca de campamentos de bandidos y POIs civilizados. 3 tiers (common / rare / boss).
- **Moneda**: contador, no ocupa grilla de inventario.

### Enhancement (+1 a +9)
- Items pueden mejorarse
- Chance de romper al enhancear
- NO hay riesgo de perder enhancement al reparar

---

## 8. Inventario, stash y equipamiento

### Inventario
- **Grilla 12×7** estilo Diablo 2
- Posición: abajo a la derecha en pantalla
- **Per-character** — se pierde al morir
- Drag & drop real para mover items, double-click para equipar
- Right-click → contextual (Soltar / Usar)
- Toggle con TAB

### Stash (Alijo)
- **Per-account** — shared entre personajes del mismo user
- Solo accesible en **zonas seguras** (outposts pisos 1, 25, 50)
- **Grilla inicial 20×10 = 200 slots**
- **Expandible comprando páginas con oro**
- Persistente, NO se pierde con la muerte
- Estilo Diablo 2 / Path of Exile

### Equipment slots (12)
`head, chest, legs, feet, hands, belt, main_hand, off_hand, ring_1, ring_2, amulet, cape`

Off-hand puede ser: shield / tome / quiver / focus.
Expandible a futuro (15-16 slots con mascotas activas).

### UI del personaje
- **Paper doll** con silueta humanoide dibujada
- Right-click o double-click en slot → desequipar
- Drag desde inventario → slot (futuro)
- Character preview ventana flotante

---

## 9. Muerte, revive y estados

### Estados
1. **Vivo** — normal
2. **Downed** — HP a 0, tirado en el suelo, crawl lento (~1 m/s)
3. **Muerto** — pierde TODO el loot del run, respawn en outpost

### Mecánica del Downed
- Timer base **30 segundos** antes de morir
- Acciones bloqueadas: saltar, atacar, usar items (excepto pergaminos)
- Vista: cámara baja, vignette rojo, audio amortiguado
- HUD: marcador a los compañeros
- HP regenera muy lento (1%/s) — puede auto-levantarse si termina el timer con >10% HP
- **Pergamino de Auto-Revive**: item raro que permite levantarse solo

### Revive por compañero
- **Canalización 5 segundos** sin moverse ni recibir >10 daño
- Completar → downed vuelve con **50% HP + buff "Segunda Chance"** (3s invulnerabilidad)

### Límite de revives por run
- 1er caída: 30s
- 2da caída: 20s
- 3ra caída: 10s
- **4ta caída = muerte instantánea** — no hay revive
- Contador resetea al volver al outpost

### ⭐ Idea clave: enemigos celebran la kill
Cuando el jugador queda downed, los enemigos en el área **dejan de atacar** y entran en **modo celebración 15 segundos**. Esto:
- Crea ventana natural para revivir
- Da feedback visual claro de dónde está el downed
- Personalidad por enemigo (slime baila, lobo aúlla, bandido taunt, golem pecho, escorpión aguijón al cielo, boss rugido dramático + temblor)
- Reduce frustración — no hay chain-kill en downed
- Tras 15s vuelven a patrulla, NO atacan al downed hasta que alguien entra al área

---

## 10. Durabilidad y reparación

### Items con durabilidad (degradan con uso)
- Armas (pierden por golpe aterrizado)
- Armaduras (pierden por daño recibido)
- Antorcha de madera (pierde por tiempo)
- Herramientas futuras (picos, hachas, cañas)

### Items SIN durabilidad (permanentes)
- Orbe arcano, hongo bioluminiscente (luces mágicas/orgánicas)
- Accesorios (anillos, amuletos, capas, cinturones — son mágicos)
- Consumibles (pociones, pergaminos, comida)
- Materiales

### Items de un solo uso
- Pergaminos de hechizo, granadas/bombas, cuchillos arrojadizos
- Comida, llaves especiales, pergaminos de teletransporte

### Herreros
- **Piso 1 (Pradera)** — reparaciones básicas
- **Piso 25** — repara items raros
- **Piso 50** — repara unique y items enhanced

### Costo
`cost = item.value * (max_durability - current) / max_durability`
Multiplicadores: Common ×1.0, Rare ×1.5, Magic ×2.0, Unique ×3.0.

### Sin riesgo de romper
**NO hay chance de romper permanente al reparar.** La tensión ya viene de perder loot al morir, no hace falta doble castigo.

### Items rotos
- NO se destruyen automáticamente
- Aparecen como "ROTO" (gris, tachado)
- Armas rotas: pierden daño base, conservan stats
- Armaduras rotas: pierden DEF, conservan stats

---

## 11. Iluminación, antorchas y oscuridad como mecánica

### Sistema de antorchas
- **OmniLight3D** hija del player, tecla **F** para activar/desactivar
- Quick-swap: guarda "last main weapon" para volver
- Tipos de luz (equip slot offhand o slot dedicado):

| Item | Range | Color | Duración | Nota |
|------|-------|-------|----------|------|
| Antorcha de madera | 6m | Cálido | X min | Inicial, barato |
| Linterna de aceite | 10m | Blanco cálido | Recargable | Mejor alcance |
| Orbe arcano | 12m | Azul | ∞ | Mágico, no se apaga |
| Hongo biolum | 4m | Verde | ∞ | Débil pero free |

### Sombras (phase 2, pendiente)
- Setting de calidad en el shader system
- Low/Med: shadows OFF
- High/Ultra: shadows ON
- Para 6 jugadores: "mi antorcha + 2 más cercanos" para evitar overdraw

### Dark zones
- **Area3D** con tag `dark_zone` marcadas por level designer
- Al entrar: aviso "Está oscuro. Pulsa F para encender antorcha"

### Biomas con oscuridad como mecánica
- **Piso 2 Bosque**: canopy denso, zonas intermitentes
- **Piso 3 Hielo**: cavernas oscuras
- **Piso 5 Dimensión Rota**: oscuridad antinatural, algunos items de luz fallan
- En coop: uno lleva luz, otro pelea → tensión y coordinación real

---

## 12. Mascotas, monturas y carro cooperativo

### Mascotas — filosofía: valor emocional > poder
- **Cosméticas (no-combat)**: gatos, perros, cuervos, conejos, luciérnagas, slime bebé, búhos, ardillas, mini dragón
- **Combat pets (débiles pero útiles)**: lobo entrenado (Archer), esqueleto (Necro), golem (Mage), águila (Ranger), oso (Warrior), fénix (Mage)
- Sistemas: alimentar con hambre decay, bonding 0-100, cosméticos (collares, gorros, bandanas, mini-armaduras)
- **Solo 1 mascota activa**, las demás en la taverna
- NPCs relacionados: Señora de los Gatos, Domador de Bestias, Veterinario, Sastre de Mascotas

### Monturas
**Regla de oro**: solo funcionan en **zonas abiertas**, NO en dungeons interiores.
- Tipos: caballo común, caballo de guerra, jabalí, lobo montaña, grifo, caballo fantasma, slime gigante, dragón joven
- Combate montado: Warrior (-20% precisión), Archer (sin penalización — es su fantasía), Mage/Necro/Cleric (no pueden castear, desmontan)
- Montura recibe daño separado, "desaparece" en 0 HP (no muere permanente), cooldown 2 min

### ⭐ Carro cooperativo (feature diferenciador)
- **Cabras tirando un carro, 2-4 jugadores**
- 1 conductor + hasta 3 pasajeros
- Pasajeros: Archer dispara, Cleric cura conductor, Mage barrera, turista
- Escenarios: huida de bandidos, viaje coop con música, persecución, carreras
- Upgrades: refuerzos HP, ruedas de hierro, caja trasera, cañón (Artillero)
- **Nadie en el género coop tiene algo así** — contenido único, "cinemática viviente"

### Inspiración
El usuario cita **Shield Hero (Tate no Yusha)**: Filo la filolial, Raphtalia, el sistema de evolución del escudo de Naofumi. Vínculo > grinding.

---

## 13. Party Activities — el corazón social del juego

### Principio clave: minijuegos DIEGÉTICOS
**NUNCA arcade genérico pegado con cinta.** Cada minijuego es una **mini-quest** con:
- NPC que lo inicia
- Lore que lo justifica
- Recompensas que encajan con el mundo
- Se descubren explorando

### Sistema de señales (coop-critical)
- **Ping rápido** (tecla Q): marker 3D 5s estilo Apex. Contextual según apuntás (enemigo/item/NPC/suelo)
- **Fuegos artificiales**: items consumibles lanzables al cielo, visibles 300m+
  - Bengala roja: help
  - Verde: meeting point
  - Azul: loot importante
  - Multicolor: celebración
  - Humo amarillo: persistente
  - En combate atraen enemigos (tradeoff real)
- Complementarios: ping corto/cerca, fuego artificial largo/lejos

### Emotes
Cantidad **escalable**, no 12 fijos. Set base: saludar, bailar, reír, sí, no, sentarse, brindar, **fumar pipa**, rezar, hierba del bardo, tocar instrumento.

### Cristal Cantor = boombox diegético
Items mágicos que reproducen música grabada por bardos. Tipos con efectos distintos (del héroe, del descanso, del baile, prohibido, del amor). Referencia Lethal Company adaptada a fantasy.

### Categorías de minijuegos

**Heist / Stealth — robar a criaturas imposibles de pelear**
- El Huevo de la Dragona (dormida en nido, distraer y robar, persecución al despertar)
- La Flauta del Gigante (trepar cíclope dormido)
- El Tesoro de la Bruja (líneas de visión, distracciones)
- Las Plumas del Grifo (trepar árbol, distraer con piedras)

**Chase / Catch — atrapar lo que huye**
- El Cerdo del Aldeano (arrinconar entre 4 jugadores)
- El Gnomo Ladrón (seguir huellas invisibles)
- La Gallina Dorada (criatura rara, random spawn)
- La Mariposa Fantasma (solo de noche, material de alquimia)

**Cooperación sincronizada**
- Cocinar un Banquete (roles: carnicero, cocinero, servidor)
- Ritual de Invocación (4 pedestales mantenidos)
- Levantar la Estatua (rhythm sincronizado)
- Puente de Hielo (coordinación de orden)

**Duelos temáticos**
- Torneo de la Taverna (espadas de práctica, apuestas)
- Trago del Valiente (pócima con efectos random)
- Concurso de Tiro (arco y blancos)
- Lucha de Brazos del Campeón (NPCs progresivos)

**Eventos ambientales — aparecen sin buscarlos**
- Fiesta del Pueblo (unirse al baile, buff de moral)
- Concurso de Pesca (día específico en el lago)
- Carrera del Caballo Fantasma (aparece al atardecer)
- Noche de las Estrellas Fugaces (deseo random)
- **Contest de Humo de Pipa estilo Gandalf**

### Sistema de Juicios — "Among Us medieval"
Party puede juzgar a un jugador en la Plaza de los Juicios. Cómico, **sin pérdida real**.
- Trigger: `/juicio @jugador`, limitado a 1/hora
- Fases: acusación 30s → defensa 30s → votación 15s → veredicto
- Castigos cosméticos: guillotina estilo Monty Python, cepo con tomates, alquitrán+plumas, **Piedra de la Vergüenza (cadena al cuello, -40% speed por 10 min)**, miniaturización, gorro vergüenza
- Si inocente: lluvia de monedas falsas + título "Calumnia" al acusador
- 10+ inocentes consecutivos → título "El Justo"
- **Opt-out en settings**

---

## 14. NPCs y mundo vivo (Prairie Living World — Piso 1)

El Piso 1 debe sentirse **VIVO**, no una arena de combate. Es el piso más civilizado de la torre.

### Elementos clave
- **Puesto de Guardia fortificado**: mini-campamento con muros, torre de vigía, guardias del perímetro, mercader, stash. **Radio de defensa 30m**.
- **Carreta de mercader viajero**: NPC evento estrella con 5 estados (tranquilo, emboscada activa, rueda rota, ya emboscada, pidiendo material)
- **Fauna pacífica** (grupo `wildlife`, separada de `enemies`): ciervos, conejos, pájaros, ardillas. No atacan, pueden ser cazados.
- **NPCs civiles**: campesinos, peregrinos, pastores con rebaños, cazadores friendly
- **~150-180 entidades vivas** en 600×600m (vs ~70 solo hostiles hoy)
- **Eventos dinámicos** (2-3 activos a la vez): caravana bajo ataque, granja incendiada, niño perdido, gitanos comerciantes

### Fauna ambiental (low-effort, high-impact, visual)
- **Mariposas**: MultiMesh con path random en zonas con flores
- **Pajaritos**: en copas de árboles, se espantan al acercarse
- **Nidos**: estáticos en árboles grandes
- **Ardillas**: cruzan caminos, trepan árboles
- **Arañas**: en telarañas estáticas (cuevas, ruinas)
- **Peces**: círculos en estanques

Post-50 (wilderness): **más** fauna, más densa, diferente por bioma.

---

## 15. Boss del Piso 1 — El Trono Viscoso

### Lore
Fue un rey olvidado. Los slimes invadieron la sala del trono y **se lo tragaron** — a él, a la corte, al trono. El slime gigante tiene **la corona y el esqueleto del rey visibles dentro del gel**. Los mini-slimes son "recuerdos" del rey con fragmentos de la corte dentro.

### Arena: "El Salón del Trono Devorado"
- Sala del trono 80×80m, mármol blanco, alfombra roja central
- 6 pilares de mármol (cobertura para mecánicas) cubiertos de gel seco
- 6 antorchas vivas con luz naranja cálida
- Banderas verdes rotas colgando
- Espejos grandes en las paredes laterales
- Estrado elevado con el trono real semi-cubierto de slime
- **Portal de salida FLOTA sobre el trono** — inactivo hasta matar al boss
- Puertas gigantes detrás del jugador **se cierran al entrar** (no hay escape)
- Esqueletos de guardias por el suelo como decoración lore
- Contraste dramático: cálido de antorchas + frío azul del portal

### Visual del boss
- 3m de alto, gel verde oscuro translúcido
- **Corona dorada visible flotando dentro del gel**
- Esqueleto coronado dentro del slime (el rey poseyéndolo)
- Fase 4: la corona brilla como queriendo salir
- Al morir: el gel se derrama, el esqueleto cae con la corona puesta, el portal se activa

### Stats
HP 600, DMG 10, DEF 8, XP 100. Duración objetivo ~3 minutos.

### Mecánicas por fase

**Fase 1 (100-75%) — Aprendizaje**
- Rebote: salta y aterriza sobre el jugador (telegraph: sombra 1.5s)
- Embestida: rueda hacia el jugador
- Escupitajo: bola de slime (mira verde en el suelo 1s antes)

**Fase 2 (75-50%) — División**
- Todo lo anterior +
- Invoca **3 mini slimes reales** con objetos distintivos dentro (casco, capa roja, cascabel, copa, pergamino)
- Los mini slimes VIVOS pueden ser **reabsorbidos** al tocar al boss → le curan HP
- Escupitajo mejorado: 3 bolas en abanico

**Fase 3 (50-25%) — Tormenta de Gelatina**
- Combo de 3 saltos seguidos más rápidos
- Al aterrizar deja **charco ácido** (DoT 3/s por 5s, radio 2m)
- Invoca 5 mini slimes cada 15s
- Oleada pegajosa 360° baja al suelo (saltable)

**Fase 4 (25-0%) — Desesperación**
- Velocidad +50%, todos los ataques más rápidos
- Explosión periódica cada 10s (AoE 5m — alejarse o usar pilares)
- Al llegar a 5% HP se infla 3s y **explota** (AoE 8m, alto daño — último aliento)
- No invoca más slimes en esta fase

### Mini slimes reales (5 tipos, cosméticos distintivos)
| Tipo | Item visible dentro |
|------|---------------------|
| Guardián | Casco pequeño |
| Cortesano | Capa roja ondulante |
| Bufón | Cascabel dorado (tintinea) |
| Copero | Copa de oro |
| Escriba | Pergamino enrollado |

Coleccionar los 5 = logro secreto **"Corte Disuelta"**.

### Drops del boss
- **Corona del Rey Olvidado** (100%) — headgear épico, INT+5, MP+20
- **Gelatina Real** (100%, x2-3) — material crafting raro
- **Cetro del Trono Viscoso** (5%) — arma legendaria para mago
- **Capa del Último Rey** (15%) — capa épica DEF+8
- **Anillo del Monarca** (20%) — accesorio raro
- **Diario del Rey** (30%) — quest item / lore

---

## 16. Intro del juego — kinetic typography con capas de profundidad

**Inspiración**: una guía con efecto visual donde el texto flowea estilo revista y un **dragón se mueve a través del texto** (efecto parallax, dragón pasa entre capas de letras).

**Técnica**:
- Dos (o más) capas de texto en diferentes Z
- Dragón (Sprite3D o MeshInstance) se mueve entre las capas
- El ojo completa la ilusión de que el dragón pasa "por encima y por debajo"

**Dónde usarlo**: intro con "Another Game of Dungeon" animado, dragón/slime pasando entre letras. También transiciones entre pisos.

---

## 17. MVP — Fase 1 prioritaria

1. Movimiento first-person ✅
2. 2-5 clases funcionales ✅ (Warrior, Mage, Archer, Necro, Cleric en prototipo)
3. 2-3 tipos de enemigo con IA ✅ (slime, bandit_melee, bandit_archer, más)
4. **1 piso completo** (Pradera) + **1 boss** (El Trono Viscoso)
5. Sistema vida/muerte con pérdida de loot
6. Loot básico + raridades ✅
7. Taverna simple (lobby)
8. Multiplayer 2 jugadores (Steam)
9. Guardado de perfil local ✅

### Requisitos mínimos para salir de Early Access
- Core loop funcionando (entrar → pelear → lootear → equipar → progresar)
- 5-10 horas de contenido mínimo
- Multiplayer coop básico
- 1 piso completo con boss
- Estabilidad 30+ min sin crashes
- Settings menu (resolución, volumen, keybinds)

### NO necesario para EA
100 pisos, todas las clases, gráficos pulidos, todo el GDD. EA es para iterar con feedback.

---

## 18. Filosofía de diseño (lo que le gusta y rechaza el usuario)

### Le gusta / quiere
- **Profundidad narrativa** en sistemas, no grinding
- **Referencias de anime** (Frieren, Shield Hero, Made in Abyss, SAO, Danmachi, Kimetsu)
- **Sistemas diegéticos**: minijuegos integrados en el mundo, no UI pegada
- **Contenido único que nadie más tiene**: carro cooperativo, juicios medievales
- **Vínculos emocionales**: pets > DPS, mount bonding, compañeros que evolucionan
- **Belleza melancólica**: paleta pastel cálida, atmósferas nostálgicas
- **Feedback de combate tangible**: knockback billar, slime jelly, squash muerte
- **Mundo vivo**: NPCs, fauna pacífica, eventos dinámicos, mercaderes viajeros

### Rechaza explícitamente
- **Escalado por cantidad de jugadores** — la dificultad es fija, coordinación gana
- **Doble castigo por muerte** — NO hay chance de romper al reparar (perder loot ya es suficiente)
- **Pausa que congela el juego** — es coop online, pausa solo libera el mouse
- **Demonios rojos con cuernos** — cliché, cada demonio único
- **Fastidioso / frustration design** — el downed con enemigos celebrando evita chain-kills
- **Arcade genérico pegado con cinta** — todo minijuego debe ser diegético

### Convenciones de trabajo
- **Conceptos > código** — entender antes de tocar
- **La IA es herramienta, el humano lidera**
- **Fundaciones sólidas** (arquitectura antes que frameworks)
- **Main = siempre bug-free**, trabajo significativo en branches
- **Sin prisas, sin atajos** — real learning takes effort

---

## 19. Publicación — Steam / Early Access

- **Publisher**: dev solo en Chile
- **Estrategia**: Early Access, no release directo
- **Pricing**:
  - Launch: USD $14.99
  - Mid-EA (6 meses): USD $17.99
  - Release 1.0: USD $19.99-24.99
- **Payout**: Payoneer (US Virtual Bank) → cuenta chilena. Comisión total ~3%.
- **Impuestos**: Chile tiene tratado con USA, retención federal 10% (W-8BEN).
- **Nombre definitivo**: **Another Game of Dungeon**
- **Trailer**: esperar hasta que el juego se vea pulido.

---

## 20. Cómo puede ayudarte otro asistente con este documento

Si le pasás este documento a otro Claude (o a cualquier asistente), pedile:

### Preguntas de diseño
- "¿Qué mecánica del Piso 2 encajaría con el bioma Bosque y el sistema de antorchas?"
- "¿Qué enemigos únicos (no cliché Frieren-style) diseñarías para el Piso 3 Hielo?"
- "¿Cómo balanceo los 5 tipos de mini slime del boss del Piso 1 para que ninguno sea estrictamente mejor?"
- "¿Qué NPCs civiles agregarías al Puesto de Guardia para darle personalidad?"

### Preguntas de contenido que le gusta a la gente
- "¿Qué minijuegos diegéticos (tipo heist/chase/coop) encajarían con el bioma X?"
- "¿Qué mecánicas del genero dungeon crawler coop están faltando en el mercado que podrían encajar acá?"
- "¿Qué estructura de progresión de stash/loot mantiene a los jugadores enganchados long-term?"

### Preguntas de ajuste/balance
- "Dado el sistema de durabilidad y los multiplicadores por rareza, ¿cuánto oro debería dar el Piso 1 por hora para que el loop prepare → risk → return → bank sea sostenible?"
- "¿Cómo balanceo los 6 resets máximo de un personaje para que se sienta significativo pero no frustrante?"

### Preguntas creativas
- "Inventame 5 items únicos (rojo vino) con mini-lore visual estilo Frieren — uno por clase."
- "Diseñame una quest secundaria del Piso 1 que se sienta post-épica y melancólica."
- "Inventame 10 títulos de personaje que un jugador puede desbloquear por comportamiento (no por stats)."

### Lo que el asistente DEBE respetar
- NO proponer escalado de dificultad por cantidad de jugadores
- NO proponer chance de romper items al reparar
- NO proponer pausa que congele el juego
- NO sugerir demonios rojos cliché
- Respetar la doble naturaleza "party RPG + party fiesta"
- Respetar la filosofía pre-50 (civilización) vs post-50 (wilderness)
- Mantener la estética melancólica/cálida de Frieren, no grimdark ni anime pop

---

**Fin del documento.**
Actualizado al 2026-04-10. Prototipo activo. Archivo maestro para compartir visión completa con colaboradores AI o humanos.
