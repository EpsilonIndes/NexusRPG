# DataLoader.gd (Autoload)
# DataLoader.gd [items, loot, stats, dialogos]
# DataLoader.gd (Autoload)
extends Node

var dialogues: Dictionary = {}
var items: Dictionary = {}
var loots: Dictionary = {}
var stats: Dictionary = {}
var character_stats: Dictionary = {}

func _ready():
	load_all_data()

func load_all_data():
	load_dialogues("res://Data/Dialogue/dialogos_NPC_auromora.csv")
	load_items("res://Data/Items/items.csv")
	load_loots("res://Data/Loot/loot_objects.csv")
	load_stats("res://Data/Char_stats/stats.csv")

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

func load_dialogues(path: String):
	dialogues = load_csv_to_dict(path, "npc")

func load_items(path: String):
	items = load_csv_to_dict(path, "item_id")

func load_loots(path: String):
	loots = load_csv_to_dict(path, "loot_id")

func load_stats(path: String):
	stats = load_csv_to_dict(path, "class_id")

