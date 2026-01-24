# WorldChest.gd (Clase base)
class_name WorldChestBase
extends Node3D

@export var loot_id: String
@export var world_flag_id: String

@onready var animator = $AnimationPlayer

func _ready():
	if WorldFlags.has_flag(world_flag_id):
		_set_open_state_inmediate()

func interact():
	if WorldFlags.has_flag(world_flag_id):
		return
	
	animator.play("abrir")
	
	
	var fueAbierto: bool = LootManager.abrir_loot(loot_id)
	if fueAbierto:
		WorldFlags.set_flag(world_flag_id, true)

func _set_open_state_inmediate():
	# Estado visual al cargar la escena
	animator.play("abierto")
	animator.seek(animator.current_animation_length, true)