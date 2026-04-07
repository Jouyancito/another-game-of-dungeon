# Dungeon Party (Another Game of Dungeon)

Dungeon crawler cooperativo en primera persona, 1-6 jugadores. Torre de 5 pisos temáticos con dificultad progresiva, loot, clases y progresión persistente.

## Stack

- **Engine**: Godot 4.6
- **Lenguaje**: GDScript
- **Networking** (futuro): Steam via GodotSteam
- **Plataformas**: Windows, Mac, Linux

## Estructura del Proyecto

```
game/
├── project.godot                  # Config: 1920x1080, windowed, input maps
├── scenes/
│   ├── main/main.tscn            # Arena 20x20, 4 paredes, luz direccional, 3 enemigos
│   ├── player/
│   │   ├── player.gd             # 159 líneas — movimiento, combate, vida/maná/XP
│   │   └── player.tscn           # CharacterBody3D: cápsula + cámara + head
│   ├── enemy/
│   │   ├── enemy_basic.gd        # 108 líneas — IA: idle/pursue/attack
│   │   └── enemy_basic.tscn      # CharacterBody3D: cubo rojo 0.8×1.6×0.8
│   ├── hud/
│   │   ├── hud.gd                # 50 líneas — barras, hotbar, muerte
│   │   ├── hud.tscn              # CanvasLayer: vida/maná/XP, hotbar, crosshair
│   │   └── crosshair.gd          # 20 líneas — 4 líneas + punto central
│   └── levels/                    # Vacío — futuro: generación procedural
├── assets/                        # models/, sounds/, textures/ — vacíos
└── scripts/                       # Vacío — futuro: utilidades
```

## Estado Actual — Fase de Prototipo

### Implementado

- **Movimiento first-person**: WASD + mouse look, salto, gravedad
- **Ataque melee**: raycast desde cámara, 3m rango, 35 daño, cooldown 0.5s
- **Enemigo básico**: cubos rojos, 100 HP (mueren en 3 golpes), IA con detección 15m, persecución, ataque a 2m con cooldown 1s
- **Feedback visual de daño**: enemigos flashean rojo brillante al recibir daño
- **Muerte de enemigos**: se encogen con tween y desaparecen (queue_free)
- **Arena de pruebas**: piso plano 20x20, paredes, iluminación direccional, 3 enemigos en posiciones fijas
- **Sistema de vida y maná del jugador**: 100 HP, 80 MP, señales para HUD, funciones take_damage/heal/use_mana/restore_mana
- **HUD completo**: barras de vida (roja), maná (azul) y XP (dorada) apiladas abajo-izquierda, hotbar de 8 slots genéricos (teclas 1-8), crosshair centrado
- **Pantalla de muerte**: overlay negro con texto "HAS MUERTO", fade-in a 70% opacidad, oculta crosshair
- **Enemigos hacen daño real**: 10 de daño por golpe con cooldown de 1s, conectado al sistema de vida del jugador
- **Enemigos dan XP al morir**: 30 XP por kill, llama `gain_xp()` del player
- **Control de mouse**: Escape togglea captura, click izquierdo captura o ataca, pitch clampeado -90° a +90°
- **TEST temporal**: tecla T gasta 10 maná (para debug, remover antes de release)

### Layers de Física

- Layer 1: World
- Layer 2: Player
- Layer 3: Enemies

## Arquitectura

### Señales (Signal-Driven)
- `player.gd` emite: `health_changed(current, max)`, `mana_changed(current, max)`, `xp_changed(current, needed, level)`, `player_died`
- `hud.gd` escucha todas las señales — UI desacoplada de lógica de juego

### Grupos
- `"player"` — identificación del jugador para colisiones/IA
- `"enemies"` — identificación de enemigos para ataques

### Valores de Balance (todos @export)
- **Player**: 100 HP, 80 MP, 35 dmg, 3m rango, 0.5s cooldown, 5m/s velocidad, 4.5 salto
- **Enemy**: 100 HP, 10 dmg, 15m detección, 2m ataque, 1s cooldown, 3m/s velocidad, 30 XP reward
- **XP**: curva 1.15x por nivel (nivel 1 = 100 XP base)

### Patrones
- `CharacterBody3D` para player y enemigos
- Raycast para detección de ataques (no proyectiles)
- Tween para animaciones de muerte (shrink → queue_free)
- `StandardMaterial3D` para feedback visual de daño
- Variables `@export` para tunear balance sin tocar código

## Resumen del GDD (fuente de verdad: `GDD_DungeonParty.md`)

### Pilares de Diseño
1. Coordinación es poder — dificultad fija, no escala con jugadores
2. Sinergias ganan batallas — combinaciones de clases desbloquean efectos
3. Cada run importa — permadeath con pérdida de loot
4. Tu dungeon, tu historia — mundo persistente con marcas
5. Fácil de aprender, difícil de dominar — sistemas simples, profundidad emergente

### 5 Clases (lanzamiento)
1. **Warrior**: Tanque (escudo) / Berserk (furia)
2. **Mage**: Elementalista (fuego/hielo/rayo) / Arcano (espacio)
3. **Archer**: Ranger (rapid fire) / Artillero (explosivos)
4. **Necromancer**: Maldiciones (debuffs) / Creador (invocaciones)
5. **Healer**: Sanador (heal directo) / Buffer (buffs)

### Progresión
- Niveles 1-50, curva XP 1.15x
- Especialización a nivel 10 (2 ramas por clase)
- Skill tree estilo Diablo 2
- 6 resets máximo → después "The Lost" (pierde ramas, gana "Headbutt" nuke)

### Loot y Muerte
- Raridades: Common → Rare → Epic → Legendary
- Enhancement +1 a +9 con chance de romper
- Muerte = pierde loot del run; inventario en taverna seguro
- Overkill = pierde también XP del nivel actual

### MVP (Fase 1)
1. Movimiento first-person ✅
2. 2 clases funcionales (Warrior base, Mage base)
3. 2-3 tipos de enemigo con IA
4. 1 piso + 1 boss
5. Sistema vida/muerte con pérdida de loot
6. Loot básico + raridades
7. Taverna simple (lobby)
8. Multiplayer 2 jugadores (Steam)
9. Guardado de perfil local

## Próximos Pasos

<!-- Actualizá esta sección a medida que avancemos -->
- Por definir — revisar GDD para priorizar siguiente feature del MVP

## Convenciones

- GDD completo en `GDD_DungeonParty.md` (612 líneas) — consultar antes de decisiones de diseño
- Godot standalone en la raíz del proyecto (no instalado globalmente)
- Estilo visual: low-poly, modelos simples, texturas planas
- Señales para comunicar estado entre sistemas
- @export para todo valor de balance
- Grupos para identificar entidades

## Notas de Sesión

- **2026-04-07**: Verificado estado del prototipo. Player ataca, enemigos mueren en 3 hits, se desvanecen. Todo funcional.
- **2026-04-07**: Implementado HUD completo (barras vida/maná, hotbar 8 slots, crosshair), sistema de vida/maná del jugador, y daño real de enemigos.
- **2026-04-07**: Actualizado CLAUDE.md con arquitectura completa, resumen del GDD, y valores de balance.
