extends CharacterBody3D

@export var nombre_npc: String = "Miguelito"
@export var dialogo_texto: String = "Te sigo Camarada!"

func interact():
	UImanager.mostrar_dialogo(nombre_npc, dialogo_texto)
