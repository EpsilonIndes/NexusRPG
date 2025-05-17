
extends Node3D

@export var loot_id: String
@onready var animator = $AnimationPlayer
var lootAbierto

func interact():
	if lootAbierto:
		return
	
	animator.play("abrir")
	
	
	var fueAbierto = LootManager.abrir_loot(loot_id)

	if fueAbierto:
		lootAbierto = true