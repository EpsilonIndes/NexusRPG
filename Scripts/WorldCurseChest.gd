class_name WorldChestCursed
extends WorldChestBase

func interact():
	if _has_world_flag():
		return

	# Evento extra
	GameManager.iniciar_batalla(["Mimic"])

	#await GameManager._on_battle_finished

	super.interact()
