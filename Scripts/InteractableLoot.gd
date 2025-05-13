
extends Node3D

@export var loot_id: String

var lootAbierto

func interact():
	if lootAbierto:
		return
	
	var fueAbierto = LootManager.abrir_loot(loot_id)

	if fueAbierto:
		lootAbierto = true
	