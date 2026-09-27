extends Control

const MEMBER_SCENE := preload("res://Escenas/Battle/battle_ui/party_member_status.tscn")
var manager: Node

func bind_battle(battle_manager: Node) -> void:
	manager = battle_manager
	for child in $Team.get_children():
		$Team.remove_child(child)
		child.queue_free()
	for combatant in manager.combatientes:
		if is_instance_valid(combatant) and combatant.es_jugador:
			var card := MEMBER_SCENE.instantiate()
			$Team.add_child(card)
			card.bind_combatant(combatant, manager)
