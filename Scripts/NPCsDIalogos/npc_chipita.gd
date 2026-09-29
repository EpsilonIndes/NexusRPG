extends NpcBase

func on_dialogue_finished():
	PlayableCharacters.set_spawn_override("Chipita", dialogue_anchor.global_position)
	PlayableCharacters.add_to_party("Chipita")
	queue_free()
