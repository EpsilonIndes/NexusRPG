extends CharacterBody3D

var llaveUsada: bool = false

func interact():
	GameManager.set_estado(GameManager.EstadosDeJuego.DIALOGO)
	UImanager.label_dialogue.mostrar_dialogo("Miguelito", [
		"¡Ayuda Kosmo!",
		"¡No puedo moverme!",
		"Creo que pisé algo..."
	])
