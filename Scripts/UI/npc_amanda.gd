extends NpcBase

func on_dialogue_finished():
	PlayableCharacters.add_to_party("Amanda")
	queue_free()
