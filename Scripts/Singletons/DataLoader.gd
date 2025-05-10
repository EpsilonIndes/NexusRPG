extends Node

#Diccionarios
var item_data := {}
var loot_data: Dictionary = {}

func _init():
	cargar_items()
	cargar_loot()

func cargar_items():
	print("Cargando items.csv")
	var file = FileAccess.open("res://Data/Items/items.csv", FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir items.csv")
		return

	var headers = file.get_line().strip_edges().split(",")

	while !file.eof_reached():
		var row = file.get_line().strip_edges().split(",")
		if row.size() != headers.size(): continue

		var entry := {}
		for i in headers.size():
			entry[headers[i]] = row[i]
		item_data[entry["item_id"]] = entry

	file.close()
	print("Items cargados: ", item_data.keys())


func cargar_loot():

	print("Cargando loot_objects.csv...")
	var file_path = "res://Data/Items/loot_objects.csv"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("No se pudo abrir loot_objects.csv")
		return

	print("Archivo abierto con éxito.")
	var headers = file.get_csv_line()
	print("Encabezados Cargados.")

	while not file.eof_reached():
		var row = file.get_csv_line()
		print("Filas leídas")

		if row.is_empty() or row.size() != headers.size():
			print("Fila inválida, se salta.")
			continue

		var entry := {}
		for i in headers.size():
			entry[headers[i]] = row[i]
		loot_data[entry["chest_id"]] = entry
