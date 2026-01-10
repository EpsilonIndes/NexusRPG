extends NpcBase

func on_dialogue_finished():
	PlayableCharacters.set_spawn_override("Maya", dialogue_anchor.global_position)
	PlayableCharacters.add_to_party("Maya")
	
	queue_free()
