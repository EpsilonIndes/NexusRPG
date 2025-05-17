# ItemManager.gd (autoload)
extends Node

# Devuelve el nombre visible del item a partir de su ID
func get_item_nombre(item_id: String) -> String:
	if not DataLoader.items.has(item_id):
		push_warning("ItemManager: ID no encontrado: %s" % item_id)
		return "[Item desconocido: %s]" % item_id
	return DataLoader.items[item_id].get("item_name", "[Sin nombre]")

func get_item_id(item_name: String) -> String:
	for id in DataLoader.items.keys():
		if DataLoader.items[id].get("item_name", "") == item_name:
			return id
	push_warning("ItemManager: No se encontró ID para el nombre: %s" % item_name)
	return ""

# Devuelve el tipo de item, para usar categorías como consumible, equipo, etc
func get_item_tipo(item_id: String) -> String:
	if not DataLoader.items.has(item_id):
		return "desconocido"
	return DataLoader.items[item_id].get("item_type", "desconocido")

# Agrega el item al inventario del jugador # Si o sí desde esta funcion
func give_item_to_player(item_id: String, cantidad: int = 1) -> bool:
	if not DataLoader.items.has(item_id):
		push_error("ItemManager: No se pudo dar el ítem, ID inválido: %s" % item_id)
		return false

	InventoryManager.add_item(get_item_nombre(item_id), cantidad)
	print("Se añadió al inventario: %s x%d" % [get_item_nombre(item_id), cantidad])
	return true