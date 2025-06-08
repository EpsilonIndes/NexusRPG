extends Node2D

var radio := 100.0

func configurar(tecnicas: Array):
	# Limpiamos los hijos previos
	for child in get_children():
		child.queue_free()

	var angulo := 0.0
	var total := tecnicas.size()

	for t in tecnicas:
		print("Añadiendo técnica: %s" % t["tecnique_id"])
		var boton = preload("res://Escenas/UserUI/tech_button.tscn").instantiate()
		boton.get_node("Label").text = t["tecnique_id"]
		boton.position = Vector2(cos(angulo), sin(angulo)) * radio
		add_child(boton)
		angulo += TAU / total
