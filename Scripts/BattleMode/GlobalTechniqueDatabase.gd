# GlobalTechniqueDatabase.gd
# Este script carga las tecnicas del combatiente.
extends Node

const MAX_EQUIPPED_TECHNIQUES := 4

var tecnica_obtenida: Dictionary = {
	"Astro": ["astro_01", "astro_02", "astro_03", "astro_07"],
	"Chipita": ["chip_01", "chip_02"],
	"Miguelito": ["mig_01", "mig_02", "mig_03"],
	"Maya": ["maya_01", "maya_02", "maya_05"],
	"Sigrid": ["sigrid_01", "sigrid_02", "sigrid_03"],
	"Amanda": ["amanda_01", "amanda_04", "amanda_03"],
	"Lucinara": ["lucinara_01", "lucinara_02", "lucinara_03", "lucinara_04"]
}

var tecnica_equipada: Dictionary = {}

func _ready():
	if not Engine.is_editor_hint():
		print("[GlobalTechniqueDatabase] Usando tecnicas desde DataLoader...")
		_ensure_equipped_defaults()


# CORE

func _get_all_techniques() -> Dictionary:
	return DataLoader.tecnicas

func get_tecnica_stats(tech_id: String) -> Dictionary:
	if not DataLoader.tecnicas.has(tech_id):
		push_warning("Tecnica no encontrada: %s" % tech_id)
		return {}

	var row: Dictionary = DataLoader.tecnicas[tech_id]
	var tecnica := row.duplicate(true)
	tecnica["efectos"] = get_effects(tech_id)
	return tecnica

func get_effects(tech_id: String) -> Array:
	if DataLoader.tecnicas.has(tech_id):
		return DataLoader.tecnicas[tech_id].get("effect", [])
	return []


# QUERIES

func get_techniques_for(personaje: String) -> Array:
	var result: Array = []
	for tech_id in DataLoader.tecnicas.keys():
		var data = DataLoader.tecnicas[tech_id]
		if data.get("personaje", "") == personaje:
			result.append(get_tecnica_stats(tech_id))
	return result

func get_by_role(role: String) -> Array:
	var result: Array = []
	for tech_id in DataLoader.tecnicas.keys():
		var data = DataLoader.tecnicas[tech_id]
		if data.get("rol_combo", "") == role:
			result.append(get_tecnica_stats(tech_id))
	return result


# DESBLOQUEADAS Y EQUIPADAS

func _ensure_equipped_defaults() -> void:
	for personaje in tecnica_obtenida.keys():
		if not tecnica_equipada.has(personaje):
			tecnica_equipada[personaje] = tecnica_obtenida[personaje].slice(0, MAX_EQUIPPED_TECHNIQUES)

func add_techniques_for(personaje: String, tecnica_id: String) -> void:
	if not DataLoader.tecnicas.has(tecnica_id):
		push_error("La tecnica %s no existe en DataLoader" % tecnica_id)
		return

	if not tecnica_obtenida.has(personaje):
		tecnica_obtenida[personaje] = []

	if tecnica_id in tecnica_obtenida[personaje]:
		print("%s ya tiene la tecnica %s" % [personaje, tecnica_id])
		return

	tecnica_obtenida[personaje].append(tecnica_id)
	_ensure_equipped_defaults()

	if tecnica_equipada.get(personaje, []).size() < MAX_EQUIPPED_TECHNIQUES:
		equip_technique(personaje, tecnica_id)

	print("Tecnica %s anadida a %s" % [tecnica_id, personaje])

func get_unlocked_technique_ids_for(personaje: String) -> Array:
	return tecnica_obtenida.get(personaje, []).duplicate(true)

func get_equipped_technique_ids_for(personaje: String) -> Array:
	_ensure_equipped_defaults()
	return tecnica_equipada.get(personaje, []).duplicate(true)

func is_technique_equipped(personaje: String, tecnica_id: String) -> bool:
	return tecnica_id in get_equipped_technique_ids_for(personaje)

func equip_technique(personaje: String, tecnica_id: String) -> bool:
	if not DataLoader.tecnicas.has(tecnica_id):
		push_error("La tecnica %s no existe en DataLoader" % tecnica_id)
		return false

	if tecnica_id not in tecnica_obtenida.get(personaje, []):
		push_warning("%s no tiene desbloqueada la tecnica %s" % [personaje, tecnica_id])
		return false

	_ensure_equipped_defaults()
	if not tecnica_equipada.has(personaje):
		tecnica_equipada[personaje] = []

	if tecnica_id in tecnica_equipada[personaje]:
		return true

	if tecnica_equipada[personaje].size() >= MAX_EQUIPPED_TECHNIQUES:
		return false

	tecnica_equipada[personaje].append(tecnica_id)
	return true

func unequip_technique(personaje: String, tecnica_id: String) -> void:
	_ensure_equipped_defaults()
	if tecnica_equipada.has(personaje):
		tecnica_equipada[personaje].erase(tecnica_id)

func set_equipped_techniques(personaje: String, tecnica_ids: Array) -> void:
	var valid_ids: Array = []
	for tecnica_id in tecnica_ids:
		if valid_ids.size() >= MAX_EQUIPPED_TECHNIQUES:
			break
		if tecnica_id in tecnica_obtenida.get(personaje, []) and tecnica_id not in valid_ids:
			valid_ids.append(tecnica_id)

	tecnica_equipada[personaje] = valid_ids

func get_unlocked_visible_techniques_for(personaje: String) -> Array:
	return _build_visible_technique_list(get_unlocked_technique_ids_for(personaje))

func get_unlocked_visible_techniques_by_role(personaje: String, role: String) -> Array:
	var result: Array = []
	for tecnica in get_unlocked_visible_techniques_for(personaje):
		if tecnica.get("rol_combo", "") == role:
			result.append(tecnica)
	return result

func get_visible_techniques_for(personaje: String) -> Array:
	return _build_visible_technique_list(get_equipped_technique_ids_for(personaje))

func _build_visible_technique_list(ids: Array) -> Array:
	var result := []

	for tech_id in ids:
		if DataLoader.tecnicas.has(tech_id):
			var data: Dictionary = get_tecnica_stats(tech_id)
			data["id"] = tech_id
			data["nombre"] = data.get("nombre_tech", tech_id)
			result.append(data)
		else:
			push_error("Tecnica '%s' no encontrada en DataLoader" % tech_id)

	return result
