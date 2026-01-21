#DialogueManager.gd (Autoload)
extends Node

func start_dialogue_async(npc_id: String, bubble, npc: NpcBase) -> void:
	_run_dialogue(npc_id, bubble, npc)

func _run_dialogue(npc_id: String, bubble: SpeechBubble, npc: NpcBase) -> void:
	await bubble.initialized
	bubble.appear()

	if not DataLoader.dialogues.has(npc_id):
		bubble.set_text("...")
		await esperar_input()
	else:
		var entradas = DataLoader.dialogues[npc_id]
		for entrada in entradas:
			bubble.set_text(entrada["linea"])
			await bubble.type_text()
			await esperar_input()

		
	GameManager.pop_ui()
	
	bubble.queue_free()
	npc.on_dialogue_finished()

func esperar_input():
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("accion"):
			break


# "res://Data/Dialogue/dialogos_NPC_auromora.csv"
