extends Node

var label_dialogue = null

func mostrar_dialogo(nombre: String, texto: String):
	if label_dialogue:
		label_dialogue.mostrar_dialogo(nombre, texto)
	else:
		print("Error: LabelDialogue no está asignado aún.")
