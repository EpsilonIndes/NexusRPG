# LootManager.gd Autoload
extends Node

func abrir_loot(loot_id: String) -> bool:

	var loot = DataLoader.loots.get(loot_id)
	if loot == null:
		push_error("Loot no encontrado: " + loot_id)
		return false

	var necesita_llave = loot["requires_key"].to_lower() == "true"
	if necesita_llave and not InventoryManager.has_item("key"):
		UImanager.label_dialogue.mostrar_dialogo("cofre", ["Necesitás una llave."])
		return false
	if necesita_llave:
		InventoryManager.remove_item("key", 1)


	var item_id = loot["item_id"]
	var cantidad = int(loot["quantity"])

	if ItemManager.give_item_to_player(item_id, cantidad):
		var nombre_item = ItemManager.get_item_nombre(item_id)
		UImanager.label_dialogue.mostrar_dialogo("cofre", ["¡Obtuviste %s x%d!" % [nombre_item, cantidad]])
	else:
		UImanager.label_dialogue.mostrar_dialogo("cofre", ["Ups... algo salió mal con ese ítem."])

	return true
