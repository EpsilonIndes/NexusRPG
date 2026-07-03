extends Node3D
class_name NpcBase

@export var npc_id: String
@export var bubble_offset := Vector3(0, 2.4, 0)
@export var dialogue_id := ""
@export var world_flag_id: String
@export var set_world_flag_on_dialogue_finished := true
@export var queue_free_when_world_flag_is_set := true

# Para sprites (temporal, reemplazar luego con animacion de rotacion):
@onready var animated_sprite = $AnimatedSprite3D
@onready var dialogue_anchor = $DialogueAnchor

var bubble_instance: SpeechBubble = null

func _ready():
	if _has_world_flag() and queue_free_when_world_flag_is_set:
		queue_free()

func interact():
	if bubble_instance:
		return

	GameManager.set_estado(GameManager.EstadosDeJuego.DIALOGO)

	bubble_instance = preload("res://Escenas/UserUI/speech_bubble.tscn").instantiate()
	get_tree().current_scene.add_child(bubble_instance)

	bubble_instance.setup($DialogueAnchor, bubble_offset)

	DialogueManager.start_dialogue_async(
		dialogue_id if dialogue_id != "" else npc_id,
		bubble_instance,
		self
	)
	in_dialogue()

func finish_dialogue():
	_set_world_flag_after_dialogue()
	on_dialogue_finished()

# Hook sobrescribible.
func on_dialogue_finished():
	pass

func in_dialogue():
	pass

func _has_world_flag_id() -> bool:
	return _get_world_flag_id() != ""

func _has_world_flag() -> bool:
	var flag_id := _get_world_flag_id()
	return flag_id != "" and WorldFlags.has_flag(flag_id)

func _set_world_flag_after_dialogue() -> void:
	if not set_world_flag_on_dialogue_finished:
		return
	var flag_id := _get_world_flag_id()
	if flag_id == "":
		return
	WorldFlags.set_flag(flag_id, true)

func _get_world_flag_id() -> String:
	return world_flag_id.strip_edges()
