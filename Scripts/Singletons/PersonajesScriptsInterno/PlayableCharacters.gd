# PlayableCharacters.gd (Autoload)
# Este script maneja los personajes jugables del juego
extends Node

# Diccionario de personajes jugables
var characters: Dictionary = {}

# Array de todos los personajes en el team actual
var party_actual: Array = []

# Agrega un personaje al sistema
func add_character(pj_name: String, class_nombre: String):
	if not DataLoader.stats.has(class_nombre):
		push_error("[PlayableCharacters] Clase no encontrada: %s" % class_nombre)
		return

	var original_stats = DataLoader.stats[class_nombre]
	var estadisticas = {}

	for key in original_stats.keys():
		if key in ["class_id", "job_name", "face", "in_party"]:
			estadisticas[key] = original_stats[key]
		else:
			estadisticas[key] = int(original_stats[key]) # Cast numérico solo a Stats

	characters[pj_name] = {
		"Name": pj_name,
		"class": class_nombre,
		"stats": estadisticas
	}

func get_stats(char_id: String) -> Dictionary:
	if PlayableCharacters.characters.has(char_id):
		return PlayableCharacters.characters[char_id].get("stats", {})
	return {}

# Agrega un personaje al equipo jugable
func add_to_party(pj_name: String):
	if characters.has(pj_name):
		characters[pj_name]["in_party"] = true
		party_actual.append(pj_name)
	else:
		push_error("[PlayableCharacters] Personaje no encontrado: %s" % pj_name)
		
# Remueve un personaje del equipo jugable
func remove_from_party(pj_name: String):
	if characters.has(pj_name):
		characters[pj_name]["in_party"] = false
		party_actual.erase(pj_name)

# Devuelve el equipo actual, utilizar para iniciar combate!
func get_party_actual() -> Array[String]:
	var valid_party: Array[String] = []
	for pj_name in party_actual:
		if characters.has(pj_name) and characters[pj_name].get("in_party", false):
			valid_party.append(pj_name)
	return valid_party

# Devuelve un personaje
func get_characters() -> Array:
	var team := []
	for char_id in characters.keys():
		if characters[char_id].get("in_party", false):
			team.append(char_id)
	print("Personajes actuales en equipo:", team)
	return team

# Resetea el equipo actual
func reset_party():
	for pj_name in party_actual:
		if characters.has(pj_name):
			characters[pj_name]["in_party"] = false
	party_actual.clear()
