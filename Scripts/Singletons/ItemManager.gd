# ItemManager Autoload
extends Node

func get_item_nombre(item_id: String) -> String:
	if not DataLoader.items.has(item_id):
		return "Item desconocido"
	return DataLoader.items[item_id]["item_name"]

func give_item_to_player(item_id: String, cantidad: int = 1):
	InventoryManager.add_item(item_id, cantidad)
