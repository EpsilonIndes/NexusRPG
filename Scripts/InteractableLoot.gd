extends Node3D

@export var loot_id: String

var abierto: bool = false

func interact():
	
	if abierto == true:
		print("Ya fue abierto pa.")
		return

	var loot_info = DataLoader.loot_data.get(loot_id)
	
	if loot_info == null:
		push_error("Loot ID no encontrado: " + loot_id)
		return

	if loot_info["requires_key"].to_lower() == "true":
		if !InventoryManager.has_item("key"):
			show_dialogue("Necesitás una llave.")
			return

	var item_info = DataLoader.item_data.get(loot_info["item_id"])
	if item_info == null:
		push_error("Item ID no encontrado:" + loot_info["item_id"])
		return
	
	var nombre_item = item_info["item_name"]
	var cantidad = int(loot_info["quantity"])
	show_dialogue("¡Obtuviste %s x%d!" % [nombre_item, cantidad])

	InventoryManager.add_item(nombre_item, cantidad)
	UImanager.mostrar_dialogo("Cofre", loot_info["dialogue"])

	abierto = true

func show_dialogue(text: String):
	print("[DIÁLOGO]: ", text) 