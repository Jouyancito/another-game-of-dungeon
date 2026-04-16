extends Node
## Party — autoload stub. Singleplayer usa lista vacia.
## Multiplayer futuro (Steam) reemplaza current_party con lista sincronizada.

var current_party: Array[String] = []  # save_profile_ids


## Retorna la party del profile_id dado. Si esta en current_party, devuelve current_party.
## Si no esta (singleplayer o player fuera de party), devuelve [profile_id] como "party de uno".
func get_party_of(profile_id: String) -> Array[String]:
	if profile_id == "":
		return []
	if profile_id in current_party:
		return current_party.duplicate()
	return [profile_id]


func is_in_party(a: String, b: String) -> bool:
	if a == "" or b == "":
		return false
	if a == b:
		return true
	return a in current_party and b in current_party


func set_party(members: Array[String]) -> void:
	current_party = members.duplicate()


func leave_party() -> void:
	current_party.clear()
