# WorldChest.gd (Clase base)
class_name WorldChestBase
extends Node3D

@export var loot_id: String
@export var world_flag_id: String

@onready var animator = $AnimationPlayer

func _ready():
	if _has_world_flag():
		_set_open_state_inmediate()

func interact():
	if _has_world_flag():
		return
	if not _has_loot_id():
		push_warning("[%s] Cofre sin loot_id; no se puede abrir." % name)
		return
	
	_play_animation("abrir")
	
	
	var fueAbierto: bool = LootManager.abrir_loot(loot_id)
	if fueAbierto:
		_set_world_flag()

func _set_open_state_inmediate():
	# Estado visual al cargar la escena
	_play_animation("abierto")
	if animator:
		animator.seek(animator.current_animation_length, true)

func _has_world_flag_id() -> bool:
	return _get_world_flag_id() != ""

func _has_world_flag() -> bool:
	var flag_id := _get_world_flag_id()
	return flag_id != "" and WorldFlags.has_flag(flag_id)

func _set_world_flag() -> void:
	var flag_id := _get_world_flag_id()
	if flag_id == "":
		push_warning("[%s] Cofre abierto sin world_flag_id; no se puede persistir su estado." % name)
		return
	WorldFlags.set_flag(flag_id, true)

func _get_world_flag_id() -> String:
	return world_flag_id.strip_edges()

func _has_loot_id() -> bool:
	return loot_id.strip_edges() != ""

func _play_animation(animation_name: String) -> void:
	if not animator:
		push_warning("[%s] No se encontro AnimationPlayer para el cofre." % name)
		return
	if animator.has_animation(animation_name):
		animator.play(animation_name)
