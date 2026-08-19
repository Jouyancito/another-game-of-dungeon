# Reference — `gate`

Base name: **`gate_`**. Todo artefacto sobre el portón lleva ese prefijo. Relacionado: `[[logo]]`,
`[[titlescreen]]`.

## Fuente

Tres fotos de portones reales que pasó el owner (Joan) en chat, 2026-08-01, junto con el pedido:
*"la madera debería cubrir todo hasta arriba en el arco, las bisagras deberían estar, notarse la
pesadez del portón y quizás también el desgaste e irregularidad de un portón, al igual que el
marco"* + *"sobre la ranura de la llave, busca sobre portones"*.

> ⚠️ **FALTAN LOS ARCHIVOS.** Las tres imágenes llegaron por chat y **no pude guardarlas al repo**
> (no tengo los bytes ni una URL descargable). Marcas visibles: la primera lleva watermark
> `portonclasico.com`, la tercera `dreamstime`. **Pendiente: que el owner las deje en esta carpeta**
> como `gate_ref_01_portonclasico.jpg`, `gate_ref_02_rustic.jpg`, `gate_ref_03_dreamstime.jpg`.
> Hasta entonces esta síntesis es lo único que queda de ellas.

## Lo que muestran

**Ref 1 — portón clásico muy envejecido.** Arco escarzano (muy rebajado, casi plano). Tablones
verticales anchos, madera oscura con veta muy marcada. **Clavos de cabeza redonda en filas
regulares** por todo el perímetro y por el eje central. Dos **rejillas cuadradas pequeñas** con
barrotes cruzados (mirillas), una por hoja, y debajo de cada una una **argolla colgante**. Una
banda horizontal decorada cruzando cada hoja a media altura. Herrajes en voluta en las esquinas
inferiores. Marco de madera.

**Ref 2 — portón rústico.** Arco de medio punto rebajado, **jambas de madera**. Tablones verticales
desparejos, muy desgastados. Dos o tres **bandas horizontales** cruzando cada hoja y **travesaños
diagonales** formando una Z en la parte baja. Dos tiradores redondos chicos al centro.

**Ref 3 — la más útil para herrajes.** Arco de medio punto pleno. **Tímpano separado**: la parte
del arco es su propio panel, dividido del resto por un travesaño, con su propia hilera de clavos.
**Bisagras de hierro negro tipo cinta (strap hinge)**, tres por hoja, largas, que se van
afinando y **terminan en un remate ornamental de flor de lis / punta de lanza**. Clavos de cabeza
redonda grande en retícula regular. **Dos aldabas de argolla juntas al centro.**

## Denominador común — lo que hay que capturar

1. **Clavos de cabeza redonda en filas regulares sobre todo el tablero.** Están en las tres. Es la
   marca más fuerte de "portón antiguo" y es lo primero que falta cuando un portón se ve pobre.
2. **Bisagras de hierro negro tipo cinta, largas, con remate ornamental.** No son cajitas: cruzan
   buena parte de la hoja y rematan en punta trabajada.
3. **Aldabas de argolla al centro**, contra el montante de cierre.
4. **Bandas horizontales** cruzando cada hoja.
5. **Tablones verticales de ancho DESPAREJO** — nunca todos iguales.
6. **Nada es recto ni simétrico.** El desgaste es la mitad del carácter.

## Colores

Maderas de marrón medio a oscuro con veta muy visible; herrajes **negros mate**, no metálicos
brillantes. Piedra sin definir — las refs traen marco de madera; en el juego el marco es **piedra
por sillares**, que es decisión propia para el dungeon y se aparta de las refs a propósito.

## Estado del build

Implementado en `game/tools/logo/gate.blend` (ver `[[asset/logo]]` en engram): tope de tablones
siguiendo la curva del arco, bisagras cinta con remate, clavos en retícula, aldabas y bocallave.
**Falta**: los clavos son cuadrados y deberían ser de cabeza redonda; las aldabas quedaron chicas.
