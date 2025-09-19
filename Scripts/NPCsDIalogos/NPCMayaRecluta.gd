extends CharacterBody3D

@export var npc_name: String
@export var npc_id: String

func interact():
	DialogueManager.start_npc_dialogue(npc_id)
	PlayableCharacters.add_to_party(npc_name)
	print(PlayableCharacters.get_party_actual())
	queue_free()
	