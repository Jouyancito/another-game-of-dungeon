class_name GameConstants

# Constantes de combate ------------------------------------------------
## Cap máximo de resistencia elemental (0.0 a 1.0). 0.75 = 75% max reducción.
const RESIST_CAP: float = 0.75

# Constantes de target frame MMO --------------------------------------
## Distancia máxima para detectar enemigo apuntado por el crosshair.
const TARGET_FRAME_RANGE: float = 23.0
## Dot product mínimo entre cam_forward y dir-al-enemigo (~14° de cono).
const TARGET_FRAME_CONE: float = 0.97
