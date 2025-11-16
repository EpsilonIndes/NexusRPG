extends Node


@onready var curacion_test: Array = [ 
    ["heal_hp", "100"] 
]

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pocion"):
        EffectManager.apply_effects(curacion_test, "Astro")