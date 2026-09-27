extends Node
func _ready() -> void:
	var actor := Combatant.new()
	actor.nombre = "Test"
	actor.hp = 100
	actor.hp_max = 100
	actor.efectos_activos = [{"stat":"defensa", "subtipo":"buff", "duracion":2}, {"stat":"velocidad", "subtipo":"debuff", "duracion":1}]
	var card := preload("res://Escenas/Battle/battle_ui/party_member_status.tscn").instantiate()
	add_child(card)
	card.bind_combatant(actor, null)
	var icons := card.get_node("Margin/Rows/StatusIcons")
	assert(icons.visible and icons.get_child_count() == 2)
	assert(icons.get_child(0).indicator == icons.get_child(0).Indicator.BUFF)
	assert(icons.get_child(1).indicator == icons.get_child(1).Indicator.DEBUFF)
	
	print("PARTY_STATUS_ICON_TEST PASSED")
	get_tree().quit()


