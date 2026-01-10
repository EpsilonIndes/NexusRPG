extends NpcBase

func on_dialogue_finished():
	PlayableCharacters.set_spawn_override("Sigrid", dialogue_anchor.global_position)
	PlayableCharacters.add_to_party("Sigrid")
	queue_free()

func in_dialogue():
	animated_sprite.play("idle_down")