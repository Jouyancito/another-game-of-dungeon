extends BaseEnemy

## Enemigo básico — cubo rojo original.
## Mantenido por retrocompatibilidad. Nuevos enemigos usan BaseEnemy directamente.


func _on_enemy_ready() -> void:
	default_color = Color(0.8, 0.2, 0.2)
