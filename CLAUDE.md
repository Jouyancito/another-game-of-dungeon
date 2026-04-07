# Dungeon Party (Another Game of Dungeon)

Dungeon crawler cooperativo en primera persona, 1-6 jugadores. Torre de 5 pisos temáticos con dificultad progresiva, loot, clases y progresión persistente.

**Repo**: https://github.com/Jouyancito/another-game-of-dungeon (privado)

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
│   │   ├── base_player.gd        # ~190 líneas — clase base: movimiento, stats, regen, daño
│   │   ├── player.gd             # ~65 líneas — Guerrero: melee pesado + combo
│   │   ├── player.tscn           # CharacterBody3D: cápsula + cámara + head
│   │   ├── mage.gd              # ~110 líneas — Mago: proyectil + rayo canalizado
│   │   └── mage.tscn            # CharacterBody3D: cápsula azul + cámara + head
│   ├── projectile/
│   │   ├── mage_projectile.gd    # Bolita de energía: viaja, impacta, daño
│   │   └── mage_projectile.tscn  # Esfera blanca con emisión azulada
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

- **Herencia de clases**: BasePlayer → Warrior/Mage (código compartido sin duplicar)
- **Movimiento**: WASD + mouse look, salto, gravedad, sprint (Shift), agacharse (Ctrl)
- **Guerrero**: puñetazo pesado (click, 35 dmg base) + combo rápido (mantener, 15 dmg base)
- **Mago**: bolita de energía (click, 25 dmg base, gratis) + rayo canalizado (mantener, 8 dmg/tick, gasta maná)
- **Sistema de stats**: STR, INT, DEX, DEF, VIT con valores base por clase
- **Fórmulas de daño**: físico = base + (STR×2), mágico = base + (INT×2)
- **Defensa**: DEF reduce daño físico (mínimo 1), resistencias elementales cap 75%
- **HP/MP calculados**: HP = base + (VIT×5), MP = base + (INT×3)
- **Regeneración**: vida fuera de combate (15s delay), maná siempre
- **3 stat points por nivel** + función assign_stat() lista para UI
- **Enemigo básico**: cubos rojos, 100 HP, IA con detección 15m, ataque 2m, 30 XP
- **HUD**: barras vida/maná/XP, hotbar 8 slots, crosshair, pantalla de muerte
- **Respawn**: tecla R recarga la escena (temporal para prototipo)

### Stats Base por Clase

| Stat | Guerrero | Mago |
|------|----------|------|
| STR | 12 | 4 |
| INT | 3 | 12 |
| DEX | 6 | 5 |
| DEF | 10 | 3 |
| VIT | 10 | 5 |
| HP base | 100 | 70 |
| MP base | 80 | 120 |
| HP total | 150 | 95 |
| MP total | 89 | 156 |
| Velocidad | 5 m/s | 4.5 m/s |
| Sprint | 8 m/s | 7 m/s |

### Layers de Física

- Layer 1: World
- Layer 2: Player
- Layer 3: Enemies

## Arquitectura

### Herencia
```
BasePlayer (base_player.gd) — class_name BasePlayer
├── Warrior (player.gd) — extends BasePlayer
└── Mage (mage.gd) — extends BasePlayer
```

Métodos override por clase: `_on_class_ready()`, `_on_attack_pressed()`, `_on_attack_released()`

### Señales (Signal-Driven)
- BasePlayer emite: `health_changed`, `mana_changed`, `xp_changed`, `player_died`, `level_up`
- `hud.gd` busca por grupo `"player"` y conecta señales

### Grupos
- `"player"` — identificación del jugador para colisiones/IA
- `"enemies"` — identificación de enemigos para ataques

### Patrones
- `CharacterBody3D` para player y enemigos
- Raycast para melee, Area3D para proyectiles
- Tween para animaciones de muerte
- `StandardMaterial3D` para feedback visual
- `ImmediateMesh` para el rayo canalizado del mago
- Variables `@export` para tunear balance

## Resumen del GDD (fuente de verdad: `GDD_DungeonParty.md`)

### Pilares de Diseño
1. Coordinación es poder — dificultad fija, no escala con jugadores
2. Sinergias ganan batallas — combinaciones de clases desbloquean efectos
3. Cada run importa — permadeath con pérdida de loot
4. Tu dungeon, tu historia — mundo persistente con marcas
5. Fácil de aprender, difícil de dominar — sistemas simples, profundidad emergente

### 5 Clases (lanzamiento)
1. **Warrior**: Tanque (escudo) / Berserk (furia)
2. **Mage**: Elementalista (fuego/hielo/rayo) / Arcano (espacio) — ataque base: finger guns + bolita inestable
3. **Archer**: Ranger (rapid fire) / Artillero (explosivos)
4. **Necromancer**: Maldiciones (debuffs) / Creador (invocaciones)
5. **Healer**: Sanador (heal directo) / Buffer (buffs)

### Progresión
- Niveles 1-50, curva XP 1.15x, 3 stat points por nivel (150 totales)
- Especialización a nivel 10 (2 ramas por clase)
- Skill tree estilo Diablo 2
- 6 resets máximo → después "The Lost"

### Loot y Muerte
- Raridades: Common → Rare → Epic → Legendary
- Enhancement +1 a +9 con chance de romper
- Items modifican stats (+2 DEF, +1 Rango, etc.)
- Muerte = pierde loot del run; inventario en taverna seguro

### Escalado de Enemigos por Piso
| Piso | HP | Daño | DEF |
|------|----|------|-----|
| 1 - Pradera | 100 | 10 | 0 |
| 2 - Bosque | 200 | 20 | 5 |
| 3 - Hielo | 350 | 35 | 12 |
| 4 - Tormenta | 500 | 50 | 20 |
| 5 - Dimensión Rota | 700 | 70 | 30 |

### MVP (Fase 1)
1. Movimiento first-person ✅
2. 2 clases funcionales ✅ (Warrior + Mage base implementados)
3. 2-3 tipos de enemigo con IA
4. 1 piso + 1 boss
5. Sistema vida/muerte con pérdida de loot
6. Loot básico + raridades
7. Taverna simple (lobby)
8. Multiplayer 2 jugadores (Steam)
9. Guardado de perfil local

## Issues Abiertos (GitHub)

Ver https://github.com/Jouyancito/another-game-of-dungeon/issues

## Próximos Pasos

- Probar refactor (BasePlayer herencia) — verificar que todo funcione igual
- Selector de clase (issue #1)
- Ventana de personaje para asignar stat points (issue #2)
- Más tipos de enemigos (issue #4)

## Convenciones

- GDD en `GDD_DungeonParty.md` — consultar antes de decisiones de diseño
- Godot standalone en la raíz del proyecto
- Estilo visual: low-poly, modelos simples, texturas planas
- Herencia BasePlayer para todas las clases
- Señales para comunicar estado entre sistemas
- @export para todo valor de balance
- Grupos para identificar entidades
- Explicar términos de Git con mini-definición entre paréntesis

## Notas de Sesión

- **2026-04-07**: Prototipo inicial — movimiento, combate melee, enemigos, HUD.
- **2026-04-07 (sesión 2)**: Clase Mago (proyectil + rayo canalizado), sistema de stats (STR/INT/DEX/DEF/VIT), defensa, resistencias elementales, regeneración HP/MP, sprint, agacharse, refactor a herencia BasePlayer, repo GitHub creado, 10 issues creados.
