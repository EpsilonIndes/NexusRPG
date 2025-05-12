extends Node

var label_dialogue = null

func mostrar_dialogo(nombre: String, texto: String):
	if label_dialogue:
		label_dialogue.mostrar_dialogo(nombre, texto)
		GameManager.set_estado(GameManager.EstadosDeJuego.DIALOGO)
	else:
		print("Error: LabelDialogue no asignado")

func ocultar_dialogo():
	if label_dialogue:
		label_dialogue.ocultar_dialogo()
		GameManager.set_estado(GameManager.EstadosDeJuego.LIBRE)
	else:
		print("Error: LabelDialogue no asignado")
