extends CharacterBody3D

@export var npc_id: String
func interact():
	DialogueManager.start_npc_dialogue(npc_id)
	PlayableCharacters.add_to_party("Maya")
	PlayableCharacters.add_to_party("Amanda")
	PartyHandler.actualizar_personajes_party()

	queue_free()