# hawk — motion spec (2026-08-25)

Brief de Joan, textual: *"el vuelo normal idle, el moverse cuando tiene un
objetivo, quizás en círculo tipo buitre, y el atacar, que sería en picada y
como agarre con las garras ¿no? y la muerte que podría ser literal caer con
las alas encogidas"*. Este spec lo baja a números ANTES de tocar una key —
contrato golem/tortuga. Cada renglón termina en un número o una orientación.

## División dura: qué anima el CLIP y qué anima la IA
El halcón es el primer mob donde la TRAYECTORIA la pone el GDScript
(`hawk.gd`: CIRCLING orbita `circle_radius=4`, DIVING baja a `dive_speed=12`).
Los clips animan EL CUERPO, no el desplazamiento:
- clip = aleteo, pliegue, garras, cabeceo del torso;
- IA = posición, rumbo, radio del círculo, velocidad de picada.
Un clip que traslade al ave pelearía con la IA — prohibido loc_x/loc_y en clips.

## Movimientos

### idle-loop — PLANEO (96 f @ 24 fps = 4 s)
Un buteo en térmica casi no aletea: alas extendidas con diedro (+8° ya en la
malla), cola levemente abierta. Micro-corrección constante:
- balanceo rot_y ±2.5°, período 4 s (una corrección por ciclo)
- bob loc_z ±8 mm, mismo período, desfasado 90°
- SIN aleteo. El aleteo en idle mata la lectura de "está planeando".

### move-loop — ALETEO con rumbo (48 f = 2 s → ~1 aleteo/s)
Batida real de buteo: lenta y profunda (2 por segundo es de paloma).
- flap: bajada RÁPIDA (40% del ciclo, la que empuja) → subida LENTA (60%)
- amplitud: +28° arriba / −22° abajo alrededor del hombro
- el cuerpo CABECEA con la batida: rot_x ±3°, y bob loc_z 15 mm acoplado
  (sube en la bajada del ala — la sustentación es la bajada)

### attack — PICADA + GARRAS (40 f = 1.67 s, one-shot)
Secuencia real de caza de buteo (no es el stoop del halcón peregrino):
1. ANTICIPACIÓN (0–30%): alas se PLIEGAN a 85% (tuck), cabeza baja,
   rot_x → −45° (nariz abajo). La IA acompaña bajando.
2. CAÍDA (30–55%): tuck sostenido. Al 45%: GARRAS — las patas se lanzan
   ADELANTE (rotación −80° en la cadera), dedos extendidos. Un rapaz golpea
   con las patas por delante de la cabeza.
3. IMPACTO+FRENO (55–75%): alas se ABREN de golpe (tuck→0 en 5 f) como
   freno, rot_x vuelve a 0, cola frena.
4. RECUPERACIÓN (75–100%): batida ×1 para retomar altura, garras vuelven.

### hit — ENCOGERSE (14 f, one-shot)
Pliegue parcial (tuck 0.4) + sacudida rot_y 8° → recupera. Corto: en el aire
un golpe no lo detiene, lo desestabiliza.

### death — CAER CON LAS ALAS ENCOGIDAS (40 f, one-shot)
Joan: "literal caer con las alas encogidas". Anatómicamente correcto: un ave
muerta no planea — sin tono muscular las alas se pliegan solas.
- tuck → 1.0 en 8 f, garras sueltas a medio cerrar
- tumbado: rot_x acumula −120° (vuelca nariz abajo) con rot_y 40° de barrena
- loc_z del clip cae sólo 0.3 m — la CAÍDA REAL la hace la física del juego
  (el clip vende el desplome, la gravedad hace el resto)

## Criterio de éxito (medible con _turtle_anim_strip adaptado)
- idle: amplitud del ala < 3° (si aletea, FAIL)
- move: asimetría de batida medida (bajada 40% ± 5 del ciclo)
- attack: las garras cruzan el plano de la cabeza (y_garras < y_cabeza en el
  frame de strike)
- death: al frame final, envergadura visible < 45% de la extendida

## En mob_lab: el poste como TARGET
Para VER circling/diving de verdad hace falta un objetivo: un dummy en el
grupo "player" en la posición del poste. La IA del halcón lo detecta, circula
tipo buitre y pica. Tecla en mob_lab para alternarlo.

## ADDENDUM 2026-08-25 — cómo caza de verdad (feedback de Joan mirando el lab)

Joan, textual: *"una ave no puede girar tan rápido... las picadas no son en
picada vertical prácticamente, hacen un movimiento de caída amplio... y
después del golpe vuelven a subir o siguen su viaje, no se quedan quietos"*.
Correcto en los tres puntos contra la biología del buteo:

1. **Círculos AMPLIOS y lentos.** Un colirrojo en térmica gira en radios de
   decenas de metros; una vuelta completa toma 10-20 s. Un giro cerrado y
   rápido es de colibrí o vencejo, no de rapaz de ala ancha (carga alar alta
   = radio de giro grande, es física, no estilo).
   → `circle_radius ≥ 10 m` · `circle_speed ≤ 0.6 rad/s` (vuelta ~10 s)
   → y el cuerpo MIRA HACIA DONDE VUELA (tangente), no hacia la presa — un
     ave circulando no vuela de costado.

2. **El ataque es un DESCENSO EN DIAGONAL, no una plomada.** El colirrojo
   caza con un glide de ataque inclinado 20-45°: pierde altura a lo largo de
   una trayectoria LARGA que arranca desde el borde del círculo. La plomada
   vertical (stoop) es del halcón peregrino, otra ave.
   → componente vertical ≤ 0.45 × dive_speed, horizontal a full — con el
     círculo de 10 m el planeo de entrada sale largo solo.

3. **DESPUÉS DEL GOLPE SIGUE DE LARGO.** El impulso no se frena en el punto
   de impacto: golpea al pasar, y la misma velocidad lo saca en subida
   (fly-through). Quedarse clavado en el lugar del golpe es de videojuego
   viejo, no de ave.
   → al golpear: mantener el rumbo horizontal a 0.8 × dive_speed + subir,
     y la retirada NO amortigua la velocidad horizontal de golpe.
