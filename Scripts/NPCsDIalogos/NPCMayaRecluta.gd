extends CharacterBody3D

@export var npc_id: String
func interact():
	DialogueManager.start_npc_dialogue(npc_id)
	PlayableCharacters.add_to_party("Maya")
	PlayableCharacters.remove_from_party("Sigrid")
	print(PlayableCharacters.get_party_actual())
	queue_free()
	