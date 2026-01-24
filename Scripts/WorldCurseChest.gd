class_name WorldChestCursed
extends WorldChestBase

func interact():
	if WorldFlags.has_flag(world_flag_id):
		return

	# Evento extra
	GameManager.iniciar_batalla(["Mimic"])

	#await GameManager._on_battle_finished

	super.interact()
