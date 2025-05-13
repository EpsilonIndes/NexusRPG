extends Node

func start_npc_dialogue(npc_id: String):
	if not DataLoader.dialogues.has(npc_id):
		UImanager.label_dialogue.mostrar_dialogo("???", ["..."])
		return

	var npc_data = DataLoader.dialogues[npc_id]
	var lineas := []

	for key in npc_data.keys():
		if key.begins_with("linea"):
			lineas.append(npc_data[key])
	
	UImanager.label_dialogue.mostrar_dialogo(npc_data.get("nombre", "???"), lineas)
