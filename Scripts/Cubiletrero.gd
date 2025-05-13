extends Node3D

@export var nombre_npc: String = "Cubiletrero"

func _physics_process(delta):
	
	rotation.y = rotation.y + 1 * delta
	

func interact():
	GameManager.set_estado(GameManager.EstadosDeJuego.DIALOGO)
	UImanager.label_dialogue.mostrar_dialogo(nombre_npc, [
		"Has interactuado con el cubiletrero",
		"Tu suerte aumenta x2"
	])
