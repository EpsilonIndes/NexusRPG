#PlayableCharacters Autoload
# Creador de personajes!

extends Node

# Diccionario de personajes jugables activos en el equipo
var characters: Dictionary = {}

# Agrega un personaje al equipo
func add_character(pj_name: String, class_nombre: String):
	if not DataLoader.stats.has(class_nombre):
		push_error("[PlayableCharacters] Clase no enconrada: %s" % class_nombre)
		return

	var original_stats = DataLoader.stats[class_nombre]
	var estadisticas = {}

	for key in original_stats.keys():
		if key in ["class_id", "job_name", "face"]:
			estadisticas[key] = original_stats[key]
		else:
			estadisticas[key] = int(original_stats[key]) # Cast numérico solo a Stats

	characters[pj_name] = {
		"Name": pj_name,
		"class": class_nombre,
		"stats": estadisticas
	}

func get_stat(pj_name: String, stat: String) -> int:
	if characters.has(pj_name) and characters[pj_name]["stats"].has(stat):
		return characters[pj_name]["stats"][stat].to_int()
	return 0

func get_all_stats(pj_name: String) -> Dictionary:
	if characters.has(pj_name):
		return characters[pj_name]["stats"]
	return {}
