extends NpcBase

func on_dialogue_finished():
	PlayableCharacters.set_spawn_override("Amanda", dialogue_anchor.global_position)
	PlayableCharacters.add_to_party("Amanda")
	queue_free()
