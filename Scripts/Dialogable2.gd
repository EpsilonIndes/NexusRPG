extends CharacterBody3D

@export var nombre_npc: String = ""
@export var dialogo_texto: String = ""
var llaveUsada: bool = false

func interact():
	UImanager.mostrar_dialogo(nombre_npc, dialogo_texto)
	
	if llaveUsada:
		UImanager.mostrar_dialogo(nombre_npc, "Ah, tenía éter... que estafa.")
		return
	else:		
		if InventoryManager.has_item("key"):
			UImanager.mostrar_dialogo(nombre_npc, "¿Ya abriste el cofre?¿Qué tenía?")
			return
		else:
			InventoryManager.add_item("key", 1)
			llaveUsada = true 

