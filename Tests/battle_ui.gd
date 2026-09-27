extends Node

class Manager extends Node:
	var combatientes: Array = []
	var combatiente_actual: Node

func _ready() -> void:
	var manager := Manager.new()
	add_child(manager)
	var actor := Combatant.new()
	actor.es_jugador = true
	actor.nombre = "Prueba"
	actor.hp = 80
	actor.hp_max = 100
	manager.combatientes = [actor]
	manager.combatiente_actual = actor
	var hud := preload("res://Escenas/UserUI/battle_hud.tscn").instantiate()
	add_child(hud)
	hud.bind_battle(manager)
	var card = hud.get_node("Team").get_child(0)
	assert(card.get_node("Margin/Rows/HealthText").text == "80 / 100 HP")
	
	actor.hp = 0
	card._refresh()
	assert(card.get_node("Margin/Rows/Health").value == 0)
	
	actor.hp = 40
	actor.hp_max = 120
	card._refresh()
	assert(card.get_node("Margin/Rows/HealthText").text == "40 / 120 HP")
	hud.bind_battle(manager)
	assert(hud.get_node("Team").get_child_count() == 1)
	var drive := preload("res://Escenas/Battle/battle_ui/drive_score_feedback.tscn").instantiate()
	drive.auto_flush_delay = -1.0
	add_child(drive)
	for i in range(8):
		drive.queue_drive_update({"score": i, "feedback": {"text": "Test %d" % i}})
	drive.flush_drive_feedback()
	assert(drive.get_node("Root/FeedbackList").get_child_count() == 4)
	assert(drive.get_node("Root/Score").text == "000007")
	var touch = load("res://Escenas/Battle/battle_ui/target_touch_zone.tscn").instantiate()
	assert(touch is Button)
	touch.free()
	await get_tree().create_timer(1.8).timeout
	actor.free()
	print("BATTLE_UI_TEST PASSED")
	hud.queue_free()
	drive.queue_free()
	manager.queue_free()
	await get_tree().process_frame
	get_tree().quit()



