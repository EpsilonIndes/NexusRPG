# GlobalTechniqueDatabase.gd
# Este script carga las técnicas del combatiente
extends Node

var tecnica_data: Array = [] # Aquí están TODAS las técnicas
var tecnica_obtenida: Dictionary = {
	"Astro": ["Golpe Previsor", "Doble Impacto", "Ritmo de Batalla"],
	"Chipita": ["Burbuja Concentrada", "Canalizar Agua"],
	"Miguelito": ["Disparo de Aviso", "Tiro de Rebote", "Letalidad Cazada"],
	"Maya": ["Carga Estelar", "Golpe Ascendente", "Rastro de Ceniza"],
	"Sigrid": ["Corte Preemptivo", "Danza de Acero", "Destino Sellado"],
	"Amanda": ["Resonancia Mental", "Eco de Luz", "Drive Coral"]
} # Técnicas obtenidas (algunas por defecto)

func _ready():
	var file = FileAccess.open("res://Data/Tecnicas/tecnicas.csv", FileAccess.READ)
	file.get_line() 								# <- Ignora la primera línea (encabezados)
	while not file.eof_reached(): 					# <- Mientras el archivo no se haya terminado
		var line = file.get_line().strip_edges() 	# <- Lee una línea y quita espacios
		if line == "":
			continue 								# <- Saltar si hay lineas vacias
		var values = line.split(",")				# <- Divide la línea entre comas (Values obtiene valores entre las comas)
		tecnica_data.append({						# <- Agrega al Array un diccionario que contiene lo que Values obtuvo
			"personaje": values[0],
            "tecnique_id": values[1],
            "rol_combo": values[2],
            "descripcion": values[3],
            "costo_drive": values[4],
            "score_value": values[5],
            "arma": values[6],
			"effect": values[7],
			"target_scope": values[8]
		})

func get_techniques_for(nombre_personaje: String) -> Array:
	return tecnica_data.filter(func(t):
		return t["personaje"] == nombre_personaje) # Retorna solo las techs

# Añadir técnica
func add_techniques_for(nombre_personaje: String, tecnica_id: String) -> void:
	if not tecnica_data.any(func(t): return t["tecnique_id"] == tecnica_id):
		push_error("Técnica %s no existe en la base de datos" % tecnica_id)
		return
	if not tecnica_obtenida.has(nombre_personaje):
		tecnica_obtenida[nombre_personaje] = []
	if tecnica_id in tecnica_obtenida[nombre_personaje]:
		print("%s ya tiene la técnica %s" % [nombre_personaje, tecnica_id])
		return
	
	tecnica_obtenida[nombre_personaje].append(tecnica_id)
	print("Técnica %s añadida a %s" % [tecnica_id, nombre_personaje])

func get_tecnica_stats(tecnica_id: String) -> Dictionary:
	for t in tecnica_data:
		if t["tecnique_id"] == tecnica_id:
			return t
	return {}
