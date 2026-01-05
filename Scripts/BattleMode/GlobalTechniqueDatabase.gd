# GlobalTechniqueDatabase.gd
# Este script carga las técnicas del combatiente
extends Node

var tecnica_obtenida: Dictionary = {
	"Astro": ["astro_01", "astro_02", "astro_03", "astro_07"],
	"Chipita": ["chip_01", "chip_02"],
	"Miguelito": ["mig_01", "mig_02", "mig_03"],
	"Maya": ["maya_01", "maya_02", "maya_05"],
	"Sigrid": ["sigrid_01", "sigrid_02", "sigrid_03"],
	"Amanda": ["amanda_01", "amanda_04", "amanda_03"],
	"Lucinara": ["lucinara_01", "lucinara_02", "lucinara_03", "lucinara_04"]
} # Técnicas obtenidas (algunas por defecto)

#var tecnica_data: Array = [] # Aquí están TODAS las técnicas

func _ready():
	if not Engine.is_editor_hint():
		print("[GlobalTechniqueDatabase] Usando técncias desde DataLoader...")


#					#
#	FUNCIONES CORE	#
#					#

# Devolver TODO el diccionario cargado por Dataloader
func _get_all_techniques() -> Dictionary:
	return DataLoader.tecnicas

# Devuelve una técnica lista para el combate
func get_tecnica_stats(tech_id: String) -> Dictionary:
	if not DataLoader.tecnicas.has(tech_id):
		push_warning("Técnica no encontrada: %s" % tech_id)
		return {}

	var row: Dictionary = DataLoader.tecnicas[tech_id]

	var tecnica := row.duplicate(true)

	# Unificamos el contrato con Combatant / EffectManager
	tecnica["efectos"] = get_effects(tech_id)
	
	return tecnica

# Efectos parseados listos para EffectManager
func get_effects(tech_id: String) -> Array:
	if DataLoader.tecnicas.has(tech_id):
		return DataLoader.tecnicas[tech_id].get("effect", [])
	return []

#					#
#	QUERIES ÚTILES	#
#					#

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

#							 #
#	TÉCNICAS DESBLOQUEADAS	 #
#							 #


func add_techniques_for(personaje: String, tecnica_id: String) -> void:
	if not DataLoader.tecnicas.has(tecnica_id):
		push_error("La técnica %s no existe en DataLoader" % tecnica_id)
		return

	if not tecnica_obtenida.has(personaje):
		tecnica_obtenida[personaje] = []

	if tecnica_id in tecnica_obtenida[personaje]:
		print("%s ya tiene la técnica %s" % [personaje, tecnica_id])
		return
	
	tecnica_obtenida[personaje].append(tecnica_id)
	print("Técnica %s añadida a %s" % [tecnica_id, personaje])

# Devuelve las técnicas desbloqueadas para el UI con nombre visible
func get_visible_techniques_for(personaje: String) -> Array:
	var result := []
	var ids: Array = tecnica_obtenida.get(personaje, [])

	for tech_id in ids:
		if DataLoader.tecnicas.has(tech_id):
			var data: Dictionary = DataLoader.tecnicas[tech_id]
			result.append({
				"id": tech_id,
				"nombre": data.get("nombre_tech", tech_id) # Nombre visible
			})
		else:
			push_error("Técnica '%s' no encontrada en DataLoader" % tech_id)
	
	return result