extends Node

func start_npc_dialogue(npc_id: String):
	if not DataLoader.dialogues.has(npc_id):
		UImanager.label_dialogue.mostrar_dialogo("???", ["..."])
		return

	var entradas = DataLoader.dialogues[npc_id]
	var lineas := []
	var nombre := "???"

	for entrada in entradas:
		if typeof(entrada) == TYPE_DICTIONARY:
			lineas.append(entrada.get("linea", ""))
			nombre = entrada.get("nombre", nombre)

	UImanager.label_dialogue.mostrar_dialogo(nombre, lineas)

# "res://Data/Dialogue/dialogos_NPC_auromora.csv"