extends RefCounted
class_name Equipment
## Sistema de equipamiento — 12 slots que aplican stats al jugador.
## No es autoload — se instancia con Equipment.new()

# Slots válidos y sus nombres para UI
const SLOT_NAMES := {
	"head": "Cabeza",
	"chest": "Pecho",
	"legs": "Piernas",
	"feet": "Pies",
	"hands": "Manos",
	"belt": "Cinturón",
	"main_hand": "Mano principal",
	"off_hand": "Mano secundaria",
	"ring_1": "Anillo 1",
	"ring_2": "Anillo 2",
	"amulet": "Amuleto",
	"cape": "Capa",
}

# slot_key → {item_id, quantity} o {} si vacío
var slots: Dictionary = {}


func _init() -> void:
	for slot_key in SLOT_NAMES:
		slots[slot_key] = {}


## Intenta equipar un item. Retorna el item desplazado (si había algo) o {}.
func equip(item_id: String) -> Dictionary:
	var item_data := ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return {}

	var slot_key := _resolve_slot(item_data)
	if slot_key == "":
		push_warning("Equipment: item '%s' no tiene slot válido" % item_id)
		return {}

	var existing_variant = slots[slot_key]
	var displaced: Dictionary = {}
	if existing_variant is Dictionary:
		displaced = (existing_variant as Dictionary).duplicate()
	slots[slot_key] = {"item_id": item_id, "quantity": 1}
	return displaced


## Desequipa el item en un slot. Retorna el item removido o {}.
func unequip(slot_key: String) -> Dictionary:
	if not slots.has(slot_key):
		return {}
	var entry_variant = slots[slot_key]
	var removed: Dictionary = {}
	if entry_variant is Dictionary:
		removed = (entry_variant as Dictionary).duplicate()
	slots[slot_key] = {}
	return removed


## Retorna el item equipado en un slot, o {}.
func get_slot(slot_key: String) -> Dictionary:
	return slots.get(slot_key, {})


## Retorna true si el slot tiene algo equipado.
func has_item_in_slot(slot_key: String) -> bool:
	return not slots.get(slot_key, {}).is_empty()


## Calcula la suma de todos los bonus de stats del equipo.
## Retorna: {"str": int, "int": int, "dex": int, "def": int, "vit": int, ...}
## NOTA: "damage" se excluye intencionalmente — usar get_weapon_damage() para daño de arma.
func get_total_bonuses() -> Dictionary:
	var totals := {}
	for slot_key in slots:
		var entry: Dictionary = slots[slot_key]
		if entry.is_empty():
			continue
		var item_data := ItemDatabase.get_item(entry.get("item_id", ""))
		if item_data.is_empty():
			continue
		var stats: Dictionary = item_data.get("stats", {})
		for stat_key in stats:
			if stat_key == "damage":
				continue  # El daño de arma se obtiene via get_weapon_damage(), no acumular aquí
			if (stat_key as String).begins_with("res_"):
				continue  # Resistencias elementales → get_total_resistances() (son float, no int)
			var val = stats[stat_key]
			if val is int or val is float:
				totals[stat_key] = totals.get(stat_key, 0) + int(val)
	return totals


## Suma las resistencias elementales de todos los items equipados.
## Claves soportadas: res_fire, res_ice, res_lightning, res_poison, res_void.
## Los valores se mantienen como float (los ints los trata get_total_bonuses).
## Retorna: {"res_fire": float, "res_ice": float, ...} — sólo keys con suma > 0.
func get_total_resistances() -> Dictionary:
	var totals := {}
	for slot_key in slots:
		var entry: Dictionary = slots[slot_key]
		if entry.is_empty():
			continue
		var item_data := ItemDatabase.get_item(entry.get("item_id", ""))
		if item_data.is_empty():
			continue
		var stats: Dictionary = item_data.get("stats", {})
		for stat_key in stats:
			if not stat_key.begins_with("res_"):
				continue
			var val = stats[stat_key]
			if val is int or val is float:
				totals[stat_key] = float(totals.get(stat_key, 0.0)) + float(val)
	return totals


## Retorna el bonus de daño total del arma equipada (main_hand).
func get_weapon_damage() -> int:
	var entry: Dictionary = slots.get("main_hand", {})
	if entry.is_empty():
		return 0
	var item_data := ItemDatabase.get_item(entry.get("item_id", ""))
	return item_data.get("stats", {}).get("damage", 0)


## Resuelve a qué slot va un item. Rings usan ring_1 o ring_2 (primer libre).
## Público para que base_player.equip_item pueda verificar espacio antes de equipar.
func resolve_slot(item_data: Dictionary) -> String:
	return _resolve_slot(item_data)


func _resolve_slot(item_data: Dictionary) -> String:
	var slot: String = item_data.get("slot", "")
	if slot == "":
		return ""

	# Anillos: intentar ring_1, luego ring_2, luego reemplazar ring_1
	if slot == "ring":
		if slots.get("ring_1", {}).is_empty():
			return "ring_1"
		elif slots.get("ring_2", {}).is_empty():
			return "ring_2"
		else:
			return "ring_1"  # reemplaza el primero

	# El resto mapea directo
	if slots.has(slot):
		return slot

	return ""


## Serialización para guardar
func to_save_data() -> Dictionary:
	var data := {}
	for slot_key in slots:
		if not slots[slot_key].is_empty():
			data[slot_key] = slots[slot_key].duplicate()
	return data


## Carga desde save
func from_save_data(data: Dictionary) -> void:
	for slot_key in SLOT_NAMES:
		slots[slot_key] = {}
	for slot_key in data:
		if slots.has(slot_key):
			slots[slot_key] = data[slot_key]
