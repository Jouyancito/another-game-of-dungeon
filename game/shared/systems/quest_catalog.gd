extends Node

# Metadata de presentación para quests quest-gated — SOLO strings UI.
# Runtime gating (is_completed) vive en QuestSystem (autoload separado).
# Registrado como autoload "QuestCatalog" en project.godot.
#
# Canon: _system.md §5bis (13 skills ascendencia quest-gated) + per-class docs.
# quest_id acá debe matchear SkillResource.quest_gate StringName en cada .tres.
# Convención quest_id: snake_case del QUEST NAME canon (no del skill name).

const QUEST_META: Dictionary = {
	# ── Warrior (2) ─────────────────────────────────────────────────────────
	&"el_muro_inquebrantable": {  # warrior.md T3 / _system.md §5bis
		"display_name": "El Muro Inquebrantable",
		"description": "Completá piso 50 sin que ningún aliado muera en tu radio de 8m.",
		"trigger_summary": "Piso 50 + 0 muertes aliadas en radio 8m",
		"unlocks_skill": &"warrior_ultimo_bastion",
	},
	&"sangre_llama_sangre": {  # warrior.md B3 / _system.md §5bis
		"display_name": "Sangre que Llama Sangre",
		"description": "Matá 50 enemigos mientras tu HP propio está por debajo del 20%.",
		"trigger_summary": "50 kills con HP propio <20%",
		"unlocks_skill": &"warrior_sangre_llama_sangre",
	},

	# ── Mage (2) ────────────────────────────────────────────────────────────
	&"armonia_rota": {  # mage.md E3 / _system.md §5bis
		"display_name": "Armonía Rota",
		"description": "Aplicá los 3 sub-elementos (fuego, hielo, rayo) a un mismo boss en el mismo encuentro.",
		"trigger_summary": "3 sub-elementos en 1 boss",
		"unlocks_skill": &"mage_armonia_rota",
	},
	&"el_camino_entre_espacios": {  # mage.md A3 / _system.md §5bis — ermitaño P60
		"display_name": "El Camino entre Espacios",
		"description": "Usá Blink 100 veces a lo largo de una run sin morir.",
		"trigger_summary": "100 Blinks sin morir",
		"unlocks_skill": &"mage_singularidad",
	},

	# ── Archer (2) ──────────────────────────────────────────────────────────
	&"ojo_verdadero": {  # archer.md R3 / _system.md §5bis
		"display_name": "Ojo Verdadero",
		"description": "Acertá 25 headshots consecutivos a enemigos tier B o superior.",
		"trigger_summary": "25 headshots consecutivos a tier B+",
		"unlocks_skill": &"archer_ojo_verdadero",
	},
	&"ingenieria_del_caos": {  # archer.md AR3 / _system.md §5bis
		"display_name": "Ingeniería del Caos",
		"description": "Matá 5 enemigos con una sola explosión.",
		"trigger_summary": "5 kills en 1 explosión",
		"unlocks_skill": &"archer_ingenieria_caos",
	},

	# ── Cleric (3) ──────────────────────────────────────────────────────────
	&"gracia_perpetua": {  # cleric.md S3 / _system.md §5bis
		"display_name": "Gracia Perpetua",
		"description": "Revivís 10 aliados diferentes en una misma run.",
		"trigger_summary": "10 aliados diferentes revividos en 1 run",
		"unlocks_skill": &"cleric_gracia_perpetua",
	},
	&"guardian_silencioso": {  # cleric.md B3 / _system.md §5bis
		"display_name": "El Guardián Silencioso",
		"description": "Mantené Aura Resguardo activa durante 30 minutos de combate acumulado.",
		"trigger_summary": "30 min Aura Resguardo activa en combate",
		"unlocks_skill": &"cleric_guardian_silencioso",
	},
	&"luz_sobre_voidsign": {  # cleric.md X3 / _system.md §5bis
		"display_name": "Luz sobre Voidsign",
		"description": "Matá 50 enemigos undead con daño sagrado.",
		"trigger_summary": "50 undead kills con daño holy",
		"unlocks_skill": &"cleric_luz_voidsign",
	},

	# ── Necromancer (2) ─────────────────────────────────────────────────────
	&"pacto_marchita": {  # necromancer.md M3 / _system.md §5bis
		"display_name": "El Pacto de la Marchita",
		"description": "Matá 100 enemigos mientras tienen al menos una maldición tuya activa.",
		"trigger_summary": "100 kills con maldición activa",
		"unlocks_skill": &"necromancer_pacto_marchita",
	},
	&"senor_caidos": {  # necromancer.md C3 / _system.md §5bis
		"display_name": "El Señor de los Caídos",
		"description": "Mantené 3 invocaciones vivas simultáneamente durante 10 minutos reales.",
		"trigger_summary": "3 invocaciones vivas × 10 min reales",
		"unlocks_skill": &"necromancer_senor_caidos",
	},

	# ── Danzante de Sombras (2) ─────────────────────────────────────────────
	&"sombra_elegida": {  # danzante_sombras.md S3 / _system.md §5bis
		"display_name": "La Sombra Elegida",
		"description": "Conseguí 20 kills desde stealth sin romper combate.",
		"trigger_summary": "20 stealth kills sin romper combate",
		"unlocks_skill": &"danzante_sombra_elegida",
	},
	&"baile_espejo": {  # danzante_sombras.md T3 / _system.md §5bis
		"display_name": "El Baile del Espejo",
		"description": "Esquivá 100 ataques usando Reflejo Sombrío.",
		"trigger_summary": "100 esquives con Reflejo Sombrío",
		"unlocks_skill": &"danzante_baile_espejo",
	},
}


## Devuelve el dict metadata de una quest. Dict vacío si no existe — la UI debe
## fallbackear a placeholder tipo "Quest desconocida" en ese caso.
static func get_quest_meta(quest_id: StringName) -> Dictionary:
	return QUEST_META.get(quest_id, {})


## Devuelve true si la quest existe en el catálogo — util para validación de
## SkillResource.quest_gate en tests o editor import time.
static func has_quest(quest_id: StringName) -> bool:
	return QUEST_META.has(quest_id)


## Lista todos los quest_ids canon. Util para tests de cobertura.
static func all_quest_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for k in QUEST_META.keys():
		ids.append(k)
	return ids
