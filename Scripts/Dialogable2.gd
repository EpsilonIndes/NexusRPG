extends Node3D

@export var nombre_npc: String = "Miguelito"
@export var dialogo_texto: String = "Ayuda Kosmo, no puedo moverme!"

func interact():
	UImanager.mostrar_dialogo(nombre_npc, dialogo_texto)
