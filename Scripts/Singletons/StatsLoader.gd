#Autoload
extends Node

var class_stats: Dictionary = {}

func _init():
	cargar_clases()

func cargar_clases(): #Carga el archivo stats.csv, contiene las clases con sus stats.
	var path = "res://Data/Char_stats/stats.csv"
	var file = FileAccess.open(path, FileAccess.READ)
    
	if file == null:
		push_error("No se pudo abrir stats.csv")
		return

	var headers = file.get_csv_line()

	while not file.eof_reached():
		var row = file.get_csv_line()
		if row.is_empty() or row.size() != headers.size():			
			continue

		var entry := {}
		for i in headers.size():
			var key = headers[i]
			var value = row[i]
			entry[key] = parse_value(value)

		class_stats[entry["class_id"]] = entry

	file.close()
	print("[StatsLoader] Clases cargadas exitosamente.")

func get_class_stats(class_id: String) -> Dictionary:
	return class_stats.get(class_id, {})

func parse_value(val: String) -> Variant: # Convierte datos string en int o float.
	if val.is_valid_int():
		return int(val)
	elif val.is_valid_float():
		return float(val)
	else:
		return val