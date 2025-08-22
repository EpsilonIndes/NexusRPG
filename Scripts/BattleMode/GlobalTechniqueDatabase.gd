# GlobalTechniqueDatabase.gd
# Este script carga las técnicas del combatiente
extends Node

var tecnica_data: Array = []
func _ready():
	var file = FileAccess.open("res://Data/Tecnicas/tecnicas.csv", FileAccess.READ)
	file.get_line() # Leer encabecados y descartarlos
	while not file.eof_reached(): # Mientras el archivo no se haya terminado
		var line = file.get_line().strip_edges()
		if line == "":
			continue # Saltar lineas vacias
		var values = line.split(",")
		tecnica_data.append({
			"personaje": values[0],
            "tecnique_id": values[1],
            "rol_combo": values[2],
            "tipo_dano": values[3],
            "descripcion": values[4],
            "costo_drive": values[5],
            "costo_mana": values[6],
            "especialidad": values[7]
		})
func get_techniques_for(nombre_personaje: String) -> Array:
	return tecnica_data.filter(func(t):
		return t["personaje"] == nombre_personaje) # Retorna solo las techs
