extends CharacterBody3D

@export var npc_id: String

func interact():
	GameManager.set_estado(GameManager.EstadosDeJuego.DIALOGO)
	DialogueManager.start_npc_dialogue(npc_id)