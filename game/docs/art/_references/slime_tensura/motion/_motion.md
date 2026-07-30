# slime_tensura / motion — cómo se DEFORMA un slime al desplazarse

Pedido de Joan (2026-07-30): *"me interesaría que el movimiento sea del slime también,
onda si se mueve hacia el frente, que se deforme hacia esa dirección, puedes ver ejemplos
de slime como el del anime del slime Tensura"*.

## ⚠️ GAP de referencia visual — sigue abierto

**No hay frames del anime en esta carpeta.** Busqué en la web y no pude traer imágenes ni
clips utilizables: no puedo ver video, y las búsquedas devolvieron páginas de wiki y
agregadores de GIFs sin frames descargables ni descripción cuadro a cuadro del movimiento.
Lo que sigue son las reglas que SÍ pude verificar por texto, más el principio de animación
clásico. **Falta que Joan suba 2-3 capturas del anime** (Rimuru desplazándose en forma de
slime) para cerrar esto — hasta entonces la deformación está construida desde principios,
no desde la referencia.

## Lo verificado (texto, multi-fuente)

**Forma y materia de Rimuru** (Tensura wiki): masa **esférica, a veces amorfa**; diámetro
~40 cm inicial, ~80 cm tras reencarnar a ultimate slime. El anime trata el cuerpo
explícitamente como blando y gelatinoso ("squishy slime body" — episodio con Shuna y Shion
peleándose por apretarlo). Rimuru comenta que su cuerpo humano le resulta **más fácil de
mover** que el de slime: el cuerpo de gel es torpe, no ágil.

> Nota de escala: nuestro slime de pradera mide 1.57 m de ancho, el doble del Rimuru
> grande. No es un error — es un mob enemigo, no Rimuru — pero conviene tenerlo presente
> si alguna vez se quiere una cría de slime a escala de referencia.

**Squash & stretch** (principio clásico, Wikipedia):
- **Conservación de volumen** es la regla dura: si se comprime en un eje, DEBE abultarse en
  otro. Un slime que se achata tiene que ensancharse; si sólo se achata, se lee como que
  perdió masa.
- Secuencia canónica: **compress → hold → extend → settle**.
- La magnitud de la deformación depende de la **inercia y la elasticidad**: más velocidad =
  más deformación. No es un valor fijo, escala con el movimiento.
- El baseline es la física observable; el estilo la **exagera** por encima de eso.

## Qué capturar para nuestro slime

1. **La deformación sigue la DIRECCIÓN del desplazamiento**, no una animación fija. Es
   pedido explícito de Joan: si avanza, el gel se derrama hacia adelante. Eso hace que
   dependa de una variable de gameplay (la velocidad) → vive en GDScript, no en un clip
   de Blender (regla de división del motor: clip fijo → bpy, depende de gameplay → Godot).
2. **Lag viscoso**: el gel NO llega instantáneamente a su forma inclinada. Se atrasa
   respecto del cuerpo y sigue de largo al frenar (overshoot), luego se asienta. Esto es lo
   que separa "gel" de "sólido rígido pintado de verde".
3. **Conservación de volumen** al inclinar: si la masa se corre hacia adelante, el cuerpo
   se achata un poco y se ensancha en la base — no puede simplemente trasladarse.
4. **Torpe, no ágil**: el slime es lento y pesado en su propio cuerpo. La deformación
   acompaña ese peso; nada de reacciones nerviosas o rápidas.

## Fuentes

- [Rimuru Tempest — Tensei Shitara Slime Datta Ken Wiki](https://tensura.fandom.com/wiki/Rimuru_Tempest)
  (forma esférica/amorfa, diámetros 40/80 cm, cuerpo humano más fácil de mover)
- [Races/Slime — Tensura Reincarnated Wiki](https://tensura.wiki.gg/wiki/Races/Slime)
- [Squash and stretch — Wikipedia](https://en.wikipedia.org/wiki/Squash_and_stretch)
  (conservación de volumen, secuencia compress→hold→extend→settle, escala con inercia)

Relacionado: `../_synthesis.md` (regla de rasgos faciales en relieve — el slime común quedó
SIN cara por decisión de Joan 2026-07-30; la cara es del Rey Slime).
