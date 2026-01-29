# PartySumaryUI.gd (En nodo)
extends Control

@onready var container: HBoxContainer = $Panel/HBoxContainer
@export var character_slot_scene: PackedScene



func refresh() -> void:
	for c in container.get_children():
		c.queue_free()

	var team := PlayableCharacters.get_party_actual()
	for char_id in team:
		var char_data = PlayableCharacters.get_character(char_id)
		if not char_data:
			continue
		
		var slot = character_slot_scene.instantiate()
		container.add_child(slot)
		slot.set_character(char_id, char_data)
