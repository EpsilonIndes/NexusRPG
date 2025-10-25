# TechButtonCircle.gd
# Este script se encarga de crear botones de técnicas alrededor de un punto central
extends Node2D

var radio := 120.0
var battle_manager: Node = null

func configurar(tecnicas_ids: Array):
	# Limpiamos los hijos previos
	for child in get_children():
		child.queue_free()

	var angulo := 0.0
	var total := tecnicas_ids.size()

	for tecnica_id in tecnicas_ids:
		var stats = GlobalTechniqueDatabase.get_tecnica_stats(tecnica_id)
		if stats.is_empty():
			push_error("No se encontraron stats para la técnica: %s" % tecnica_id)
			continue

		print("Añadiendo técnica: %s" % tecnica_id)

		# Crear botón
		var boton = preload("res://Escenas/UserUI/tech_button.tscn").instantiate()
		boton.get_node("Label").text = tecnica_id
		boton.position = Vector2(cos(angulo), sin(angulo)) * radio
		
		# Guardar info extra dentro del botón (Para tooltips o al hacer click)
		boton.set("tecnica_id", tecnica_id)
		boton.set("tecnica_stats", stats)
		
		boton.tecnica_seleccionada.connect(
			Callable(battle_manager, "_on_tecnica_seleccionada")
		)

		add_child(boton)
		angulo += TAU / total
