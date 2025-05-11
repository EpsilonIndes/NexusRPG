extends Node3D

@export var nombre_npc: String = "Cubiletrero"
@export var dialogo_texto: String = "Has interactuado con el Cubiletrero. Suerte++"

func _physics_process(delta):
	
	rotation.y = rotation.y + 1 * delta
	

func interact():
	UImanager.mostrar_dialogo(nombre_npc, dialogo_texto)
