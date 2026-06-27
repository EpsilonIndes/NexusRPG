extends Node


@onready var curacion_test: Array = [ 
	["heal_hp", "100"] 
]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pocion"):
		ItemEffectManager.apply_effects(["heal_hp"], "Astro")
		print("Sin arreglar tema Combatant/PlayableCharacters, ahora aplicamos para Combatant")
