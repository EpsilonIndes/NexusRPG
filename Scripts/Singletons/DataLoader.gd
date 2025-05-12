extends Node

#Diccionarios
var item_data := {}
var loot_data: Dictionary = {}

func _init():
	cargar_items()
	cargar_loot()

func cargar_items():
	
	var file = FileAccess.open("res://Data/Items/items.csv", FileAccess.READ)
	if file == null:
		push_error("[ItemsLoader] No se pudo abrir items.csv")
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
	print("[ItemsLoader] Items cargados exitosamente.")


func cargar_loot():

	var file_path = "res://Data/Items/loot_objects.csv"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("[LootsLoader] No se pudo abrir loot_objects.csv")
		return

	var headers = file.get_csv_line()

	while not file.eof_reached():
		var row = file.get_csv_line()

		if row.is_empty() or row.size() != headers.size():
			continue

		var entry := {}
		for i in headers.size():
			entry[headers[i]] = row[i]
		loot_data[entry["chest_id"]] = entry
	
	print("[LootsLoader] Loots cargados exitosamente.")