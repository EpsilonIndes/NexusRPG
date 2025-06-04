# PlayableCharacters.gd (Autoload)
extends Node

var characters: Dictionary = {}
var party_actual: Array = []

func create_character(pj_name: String, class_id: String) -> void:
	if characters.has(pj_name):
		push_warning("[PlayableCharacters] Ya existe un personaje con ID: %s" % pj_name)
		return

	if not DataLoader.stats.has(class_id):
		push_error("[PlayableCharacters] Clase no encontrada: %s" % class_id)
		return

	var base_data = DataLoader.stats[class_id]
	var stats := {}

	# Copiar solo stats reales, evitando duplicar info inutil
	for key in base_data.keys():
		if key != "in_party":
			stats[key] = base_data[key] if typeof(base_data[key]) == TYPE_DICTIONARY else int(base_data[key])

	var new_char = PlayableCharacter.new(pj_name, class_id, stats)
	characters[pj_name] = new_char

func add_to_party(pj_name: String):
	var pj = get_character(pj_name)
	if pj and not pj.in_party:
		pj.in_party = true
		party_actual.append(pj_name)

func remove_from_party(pj_name: String):
	var pj = get_character(pj_name)
	if pj and not pj.in_party:
		pj.in_party = false
		party_actual.erase(pj_name)

func get_party_actual() -> Array:
	var valid_party: Array = []
	for pj_name in party_actual:
		if is_in_party(pj_name):
			valid_party.append(pj_name)
	return valid_party

func get_character(pj_name: String) -> PlayableCharacter:
	return characters.get(pj_name, null)

func get_stats(pj_name: String) -> Dictionary:
	var pj = get_character(pj_name)
	if pj != null and pj.stats != null:
		return pj.stats
	else:
		return {}

func is_in_party(pj_name: String) -> bool:
	var pj = get_character(pj_name)
	return pj != null and pj.in_party

func reset_party():
	for pj_name in party_actual:
		if characters.has(pj_name):
			characters[pj_name].in_party = false
	party_actual.clear()
