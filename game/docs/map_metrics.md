# Dungeon Party — Métricas de Escala del Mapa

**Departamento**: Game Design  
**Fecha**: 2026-04-08  
**Estado**: v1.0 — aprobado para uso del departamento Gameplay

---

## 1. Referencia: Unidad Humana (Player como metro patrón)

Todas las métricas parten del jugador como unidad de referencia. Godot usa metros reales: 1 unidad = 1 metro.

| Medida | Valor | Fuente |
|--------|-------|--------|
| Radio de cápsula (jugador) | 0.35 m | `player.tscn` — CapsuleShape3D |
| Altura de cápsula (parado) | 1.8 m | `player.tscn` — CapsuleShape3D |
| Altura de cápsula (agachado) | 0.9 m | `base_player.gd` — `crouch_height` |
| Altura de cámara (ojos) | 0.8 m sobre pivot | `player.tscn` — Head Y = 0.8 |
| Altura de ojos real | ~1.6 m sobre el piso | cápsula centrada en Y=0 → centro a 0.9m, ojos a 0.8m sobre eso |
| Ancho visual del jugador | ~0.7 m diámetro | radio × 2 |

| Medida | Valor | Fuente |
|--------|-------|--------|
| Altura enemigo básico | 1.6 m | `enemy_basic.tscn` — BoxMesh |
| Ancho/profundidad enemigo | 0.8 m | `enemy_basic.tscn` — BoxMesh |
| Rango ataque melee | 3.0 m | `base_player.gd` — `attack_range` |

| Medida | Valor | Fuente |
|--------|-------|--------|
| Arena prototipo | 20 × 20 m | `main.tscn` — BoxShape3D piso |
| Altura paredes prototipo | 4.0 m | `main.tscn` — BoxShape3D paredes |

**Relación jugador/pared**: el jugador mide 1.8m de alto contra paredes de 4m → ratio 1:2.2. Proporción correcta para first-person: el techo se siente alto sin perder escala humana.

---

## 2. Estándar de Altura para Todos los Espacios

**Altura de pasillo/sala estándar: 3.5 m**  
**Altura de sala de boss: 8.0 m**

Justificación:
- 3.5m = ~2× la altura del jugador. En first-person esto se siente "dungeon opresivo" sin ser bochornoso.
- El jugador agachado (0.9m) pasa por aberturas de 1.2m sin problema — posible mechanic futura.
- 4m (prototipo actual) es viable pero pierde tensión; 3.5m es el punto justo.
- Boss a 8m: permite proyectiles aéreos, fases de vuelo, escala épica.

---

## 3. Pasillos

Un pasillo conecta dos salas. Su función es **transición + tensión**, no combate (ver sección 7).

| Tipo | Ancho | Largo (variable) | Alto |
|------|-------|-----------------|------|
| Pasillo estándar | 2.5 m | 6 – 16 m | 3.5 m |
| Pasillo estrecho (trampas, secretos) | 1.4 m | 4 – 8 m | 3.5 m |
| Pasillo de escape (post-boss) | 4.0 m | 8 – 20 m | 3.5 m |

**Por qué 2.5m de ancho:**
- El jugador mide 0.7m de diámetro → 2.5m permite pasar 2 jugadores en paralelo sin rozarse.
- En cooperativo de 6 jugadores, 2.5m fuerza orden de marcha (un líder adelante) sin bloquear.
- Pasillo estrecho de 1.4m: solo un jugador a la vez → presión táctica.

**Restricción de diseño**: ningún pasillo de combate. Si hay combate, el espacio se expande a sala pequeña.

---

## 4. Tamaños de Sala

### Sala Pequeña — "Habitación"

| Dimensión | Valor |
|-----------|-------|
| Mínimo | 6 × 6 m |
| Estándar | 8 × 8 m |
| Máximo | 10 × 8 m |
| Alto | 3.5 m |

**Capacidad cómoda**: 1-2 enemigos básicos. Con 6 jugadores se siente aglomerado → presión intencional.  
**Uso**: loot, secretos, trampas, emboscadas de 1-2 enemigos élite.

### Sala Mediana — "Sala de Combate"

| Dimensión | Valor |
|-----------|-------|
| Mínimo | 12 × 12 m |
| Estándar | 16 × 16 m |
| Máximo | 20 × 16 m |
| Alto | 3.5 m |

**Capacidad cómoda**: 3-6 enemigos básicos, o 1-2 élite con adds.  
**Uso**: encuentro estándar, sala de descanso con cofre, sala de miniboss.  
Nota: la arena prototipo (20×20) entra en esta categoría — es grande para una sala mediana pero sirve como punto de calibración ya probado.

### Sala Grande — "Cámara"

| Dimensión | Valor |
|-----------|-------|
| Mínimo | 24 × 20 m |
| Estándar | 28 × 24 m |
| Máximo | 32 × 28 m |
| Alto | 4.5 m |

**Capacidad cómoda**: 6-12 enemigos, oleadas, mecánicas de área.  
**Uso**: sala de piso (la más importante antes del boss), sala de evento especial, sala con puzzle de posicionamiento.

### Sala de Boss

| Dimensión | Valor |
|-----------|-------|
| Estándar | 32 × 32 m |
| Expandido (piso 4-5) | 40 × 40 m |
| Alto | 8.0 m |

**Uso**: combate de boss único por piso. El boss de piso 5 ("Dimensión Rota") puede tener sala no euclidiana o de forma irregular — el área total se mantiene en ~1600 m².

---

## 5. Tiempos de Recorrido

Los tiempos representan **cruzar el espacio vacío de lado a lado**, sin obstáculos.

### Pasillos

| Largo | Velocidad normal (5 m/s) | Sprint (8 m/s) |
|-------|--------------------------|----------------|
| 6 m (mínimo) | 1.2 s | 0.75 s |
| 10 m (estándar) | 2.0 s | 1.25 s |
| 16 m (máximo estándar) | 3.2 s | 2.0 s |

### Salas (diagonal larga, peor caso)

| Sala | Diagonal aprox. | Normal (5 m/s) | Sprint (8 m/s) |
|------|----------------|----------------|----------------|
| Pequeña 8×8 | 11.3 m | 2.3 s | 1.4 s |
| Mediana 16×16 | 22.6 m | 4.5 s | 2.8 s |
| Grande 28×24 | 36.9 m | 7.4 s | 4.6 s |
| Boss 32×32 | 45.3 m | 9.1 s | 5.7 s |

**Lectura de diseño**: una sala mediana tarda ~4.5 segundos en cruzarse corriendo normal. En combate activo ese tiempo se multiplica x3-4 por dodging/kiting → los encuentros duran 15-20 segundos mínimo en sala mediana. Correcto para un dungeon crawler de ritmo medio.

---

## 6. Estructura por Piso

### Pisos 1-2 (Pradera, Bosque) — Aprendizaje

| Parámetro | Mínimo | Estándar | Máximo |
|-----------|--------|----------|--------|
| Salas de combate | 5 | 7 | 9 |
| Salas pequeñas (loot/secreto) | 1 | 2 | 3 |
| Sala grande (pre-boss) | 1 | 1 | 1 |
| Sala de boss | 1 | 1 | 1 |
| **Total salas** | **8** | **11** | **14** |
| Pasillos conectores | 7 | 10 | 13 |

### Pisos 3-4 (Hielo, Tormenta) — Tensión máxima

| Parámetro | Mínimo | Estándar | Máximo |
|-----------|--------|----------|--------|
| Salas de combate | 7 | 10 | 13 |
| Salas pequeñas (loot/secreto) | 2 | 3 | 4 |
| Sala grande (pre-boss) | 1 | 2 | 2 |
| Sala de boss | 1 | 1 | 1 |
| **Total salas** | **11** | **16** | **20** |
| Pasillos conectores | 10 | 15 | 19 |

### Piso 5 (Dimensión Rota) — El infierno

| Parámetro | Mínimo | Estándar | Máximo |
|-----------|--------|----------|--------|
| Salas de combate | 8 | 12 | 15 |
| Salas pequeñas (loot/secreto) | 2 | 4 | 5 |
| Salas grandes | 2 | 3 | 3 |
| Sala de boss final | 1 | 1 | 1 |
| **Total salas** | **13** | **20** | **24** |
| Pasillos conectores | 12 | 19 | 23 |

**Tiempo estimado por piso** (velocidad normal, sin backtracking):
- Pisos 1-2: 8-15 minutos
- Pisos 3-4: 15-25 minutos  
- Piso 5: 20-35 minutos

---

## 7. Zonas Muertas (Pasillos Vacíos): Estrategia

### ¿Son buenas o malas?

**Depende de su longitud y posición.** Las zonas muertas no son el enemigo — la **zona muerta sin propósito** sí lo es.

### Referencia a juegos similares

**Diablo 2** — zonas muertas explícitas y bienvenidas:
- Los pasillos del Tristram al Mundo 1 duran ~8 segundos vacíos. Funcionan porque generan anticipación antes del primer encuentro. La tensión acústica (música que cambia) convierte el vacío en narrativa.
- Lección: el vacío necesita audio como señalización emocional.

**Dark Souls 1** — maestría del vacío intencional:
- El puente de los Dragones Sin Escamas (Undead Burg) tiene 40m de espacio "vacío" que en realidad está lleno de peligro implícito (flechas, gargoyle que cae). El jugador se mueve lento porque anticipa.
- Lección: el vacío puede ser peligro invisible, no ausencia de contenido.

**Binding of Isaac** — sin zonas muertas, todo conectado:
- Cada sala tiene contenido mínimo. Los pasillos son transiciones instantáneas (puerta a puerta). Funciona porque el ritmo es frenético y el jugador no puede "respirar".
- Lección: si el ritmo es alto-intensidad constante, eliminar zonas muertas. Si el ritmo es dungeon crawler pesado, necesitás los respiros.

**Conclusión para Dungeon Party**: el juego es un dungeon crawler cooperativo con muertes permanentes y loot. El ritmo debe tener PICOS y VALLES. Las zonas muertas son los valles → son obligatorias, pero tienen que tener propósito.

### Estrategia recomendada: "Pasillos con Firma"

Cada pasillo debe tener al menos UNO de los siguientes elementos:

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| **Ambiental** | Detalle visual que cuenta historia | Cadenas en la pared, antorchas apagadas, manchas de sangre |
| **Sonoro** | Audio off-screen que informa | Rugido lejano, agua goteando, pasos |
| **Interactivo pasivo** | No detiene pero invita | Palanca sin función aparente, inscripción en la pared |
| **Trampa latente** | Peligro evitable | Presión plate, flecha al cruzar el umbral |
| **Loot menor** | Razón para explorar | Monedas en el piso, un tarro roto |

**Lo que NUNCA debe ir en un pasillo**: combate de más de 1 enemigo débil. El pasillo no tiene espacio de evasión → frustración, no tensión.

### Regla del 1-3-1

Estructura macro recomendada por sala:
```
[Sala] → 1 pasillo corto (6-8m) → [Sala] → 1 pasillo largo (12-16m) → [Sala grande]
```
- Pasillo corto: ~1.5s en sprint. Respiro mínimo.
- Pasillo largo: ~2-3s en sprint, con al menos 1 firma ambiental. Construcción de tensión antes de sala grande o boss.

---

## 8. Proporción Contenido vs. Espacio Vacío

Aplicable al área total de cada sala (no al piso completo).

| Tipo de sala | % espacio navegable libre | % obstáculos/decoración | % zonas de cobertura |
|-------------|--------------------------|------------------------|---------------------|
| Pasillo | 80% | 10% | 10% |
| Sala pequeña | 65% | 20% | 15% |
| Sala mediana | 55% | 25% | 20% |
| Sala grande | 50% | 20% | 30% |
| Sala de boss | 60% | 10% | 30% |

**Zona de cobertura**: columnas, cajas, pilares — elementos que el jugador usa para cubrirse y el enemigo para flanquear.

**Sala de boss al 60% libre**: el boss necesita espacio para sus patrones de ataque. Reducir el espacio libre bajo 55% hace el combate de boss frustrante en cooperativo (6 jugadores ya ocupan ~3m² de espacio de colisión).

### Ratio global por piso (área de salas vs. área de pasillos)

| Piso | Salas | Pasillos | Ratio sala:pasillo |
|------|-------|----------|-------------------|
| 1-2 | ~70% | ~30% | 2.3:1 |
| 3-4 | ~65% | ~35% | 1.9:1 |
| 5 | ~60% | ~40% | 1.5:1 |

El piso 5 tiene más pasillo proporcionalmente — la tensión ambiental aumenta, el tiempo entre encuentros se estira, la anticipación se vuelve tortura. Es intencional.

---

## 9. Checklist de Validación para Gameplay

Antes de marcar una sala/piso como "playtest-ready", verificar:

- [ ] ¿El jugador puede moverse 360° sin chocar en una sala de combate mediana?
- [ ] ¿El pasillo más corto tiene al menos 6m? (menos de 6m se siente teletransporte)
- [ ] ¿Hay al menos un pasillo largo (10m+) antes de la sala de boss?
- [ ] ¿El boss tiene al menos 32×32m de sala?
- [ ] ¿Cada pasillo tiene una "firma" (ambiental, sonora, trampa o loot menor)?
- [ ] ¿El ratio de cobertura en sala mediana es ≥20%?
- [ ] ¿6 jugadores juntos en la sala pequeña tienen espacio para ver la pantalla? (punto de vista first-person)

---

## 10. Resumen Rápido (referencia de bolsillo)

```
ALTURAS
  Pasillo / sala estándar : 3.5 m
  Sala grande             : 4.5 m
  Sala de boss            : 8.0 m

PASILLOS
  Estándar  : 2.5 m ancho × 6-16 m largo
  Estrecho  : 1.4 m ancho × 4-8 m largo

SALAS (ancho × largo)
  Pequeña   : 6×6 m — 10×8 m
  Mediana   : 12×12 m — 20×16 m
  Grande    : 24×20 m — 32×28 m
  Boss      : 32×32 m — 40×40 m

SALAS POR PISO
  Pisos 1-2 : 8-14 salas
  Pisos 3-4 : 11-20 salas
  Piso 5    : 13-24 salas

TIEMPOS CRUCE DIAGONAL (peor caso)
  Sala pequeña : 2.3 s normal / 1.4 s sprint
  Sala mediana : 4.5 s normal / 2.8 s sprint
  Sala grande  : 7.4 s normal / 4.6 s sprint
  Boss         : 9.1 s normal / 5.7 s sprint
```
