extends Node3D
class_name NpcBase

@export var npc_id: String
@export var bubble_offset := Vector3(0, 2.4, 0)
@export var dialogue_id := ""

var bubble_instance: SpeechBubble = null

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

# 🔹 Hook — sobrescribible
func on_dialogue_finished():
	pass
