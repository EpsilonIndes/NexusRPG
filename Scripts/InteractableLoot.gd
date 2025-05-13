
extends Node3D

@export var loot_id: String

var abierto: bool = false

func interact():
	if abierto:
		print("Ya fue abierto pa.")
		return

	var resultado = LootManager.abrir_cofre(loot_id)

	for linea in resultado:
		if linea != "ERROR":
			UImanager.label_dialogue.mostrar_dialogo("Cofre", [linea])
		else:
			push_error("Error al abrir el cofre")

	abierto = true