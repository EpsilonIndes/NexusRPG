# LootManager.gd
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
	ItemManager.give_item_to_player(item_id, cantidad)

	var mensaje = loot.get("dialogue", "¡Conseguiste algo!")
	UImanager.label_dialogue.mostrar_dialogo("cofre", [mensaje])
	return true


