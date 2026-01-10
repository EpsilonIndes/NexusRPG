# DataLoader.gd (Autoload)
# Este script se encarga de cargar datos desde archivos CSV
# Cargará items, loot, stats, dialogos, técnicas desde las rutas especificadas
extends Node

var dialogues: Dictionary = {}
var items: Dictionary = {}
var loots: Dictionary = {}
var stats: Dictionary = {}
var tecnicas: Dictionary = {}
var enemigos: Dictionary = {}

const BOOL_COLUMNS := [
	"allow_target_switch",
	"can_switch_targets",
	"is_interruptible"
]

func _init():
	load_all_data()

func load_all_data():
	load_dialogues("res://Data/Dialogue/dialogos_NPC_auromora.csv")
	load_items("res://Data/Items/items.csv")
	load_loots("res://Data/Loot/loot_objects.csv")
	load_stats("res://Data/Char_stats/stats.csv")
	load_tecnicas("res://Data/Tecnicas/tecnicas.csv")
	load_enemy_stats("res://Data/Enemy_stats/stats_enemigos.csv")

func load_csv_to_dict(path: String, key_column: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el archivo: " + path)
		return result

	var headers := file.get_line().strip_edges().split(",")

	while not file.eof_reached():
		var row := file.get_line().strip_edges().split(",")
		if row.size() != headers.size():
			continue

		var entry := {}
		for i in headers.size():
			entry[headers[i]] = row[i]
		result[entry[key_column]] = entry

	file.close()
	return result

func load_csv_grouped_by_key(path: String, key_column: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el archivo: " + path)
		return result

	var headers := file.get_line().strip_edges().split(",")

	while not file.eof_reached():
		var row := file.get_line().strip_edges().split(",")
		if row.size() < 2:  # Evita líneas vacías o mal formadas
			continue

		var entry := {}
		for i in headers.size():
			if i < row.size():
				entry[headers[i]] = row[i]
			else:
				entry[headers[i]] = ""
				
		var key = entry.get(key_column, "")
		if not result.has(key):
			result[key] = []

		result[key].append(entry)

	file.close()
	return result

func load_stats_to_dict(path: String, key_column: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el archivo: " + path)
		return result

	var headers := file.get_line().strip_edges().split(",")

	while not file.eof_reached():
		var row := file.get_line().strip_edges().split(",")
		if row.size() != headers.size():
			continue

		var entry: Dictionary = {}
		for i in headers.size():
			var header_name = headers[i]
			var value = row[i]

			if header_name == "effect":
				entry[header_name] = EffectParser.parse_effect_string(value)
			
			elif value.is_valid_float():
				entry[header_name] = float(value)
			
			else: entry[header_name] = value

		result[entry[key_column]] = entry

	file.close()
	return result

func load_items_to_dict(path: String, key_column: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("No se pudo abrir el archivo: " + path)
		return result

	var headers := file.get_line().strip_edges().split(",")

	while not file.eof_reached():
		var row := file.get_line().strip_edges().split(",")

		# evitar líneas vacías o corruptas
		if row.size() != headers.size():
			continue

		var entry: Dictionary = {}

		for i in headers.size():
			var header_name = headers[i]
			var raw_value = row[i].strip_edges()

			# 1) Efectos → parser especial
			if header_name == "effect":
				entry[header_name] = EffectParser.parse_effect_string(raw_value)

			# 2) Número → guardado como float
			elif raw_value.is_valid_float():
				entry[header_name] = float(raw_value)

			# 3) String normal
			else:
				entry[header_name] = raw_value

		# Usar la columna clave para indexar el diccionario
		result[entry[key_column]] = entry

	file.close()
	return result

func load_techs_to_dict(path: String, key_column: String) -> Dictionary:
	var result: Dictionary = {}
	var csv_rows = CsvReader.read_csv(path)
	if csv_rows.is_empty():
		return result
	
	var headers = csv_rows[0] # primera fila = header

	for r in range(1, csv_rows.size()):
		var row = csv_rows[r]
		if row.size() != headers.size():
			print("fila inválida en CSV:", row)
			continue
		
		var entry: Dictionary = {}
		for i in headers.size():
			var header_name = headers[i]
			var value = row[i]

			if header_name == "effect":
				entry[header_name] = EffectParser.parse_effect_string(value)
			elif header_name in BOOL_COLUMNS:
				entry[header_name] = EffectParser.parse_effect_bool(value)
				
			elif value.is_valid_float():
				entry[header_name] = float(value)
			else:
				entry[header_name] = value
			
		result[entry[key_column]] = entry
	
	return result
	

func load_dialogues(path: String):
	dialogues = load_csv_grouped_by_key(path, "npc_id")

func load_items(path: String):
	items = load_items_to_dict(path, "item_id")

func load_loots(path: String):
	loots = load_csv_to_dict(path, "loot_id")

func load_stats(path: String):
	stats = load_stats_to_dict(path, "id")
func load_tecnicas(path: String):
	tecnicas = load_techs_to_dict(path, "tecnique_id")
func load_enemy_stats(path: String):
	enemigos = load_stats_to_dict(path, "id")