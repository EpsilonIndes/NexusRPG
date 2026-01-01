# TechButtonCircle.gd
# Crea un círculo de botones para seleccionar técnicas
extends Node2D

var radio := 120.0
var battle_manager: Node = null

func configurar(tecnicas_ids: Array):
	# Limpiamos los hijos previos
	for child in get_children():
		child.queue_free()

	if tecnicas_ids.is_empty():
		push_warning("No se recibieron técnicas para mostrar en el círculo.")
		return

	var total := tecnicas_ids.size()
	var angulo := 0.0

	for t in tecnicas_ids:
		# Extraer el ID
		var tecnica_id = t["id"]
		if tecnica_id == "":
			push_error("Técnica sin ID interno en el array")
			continue

		# Obtenemos stats desde GlobalTechniqueDatabase
		var stats: Dictionary = GlobalTechniqueDatabase.get_tecnica_stats(tecnica_id)
		if stats.is_empty():
			push_error("No se encontraron stats para la técnica: %s" % tecnica_id)
			continue

		# Nombre para el UI
		var nombre_visible = stats.get("nombre_tech", tecnica_id)
		print("Añadiendo técncia:", nombre_visible)

		# Crear botón
		var boton = preload("res://Escenas/UserUI/tech_button.tscn").instantiate()
		boton.get_node("Label").text = nombre_visible
		boton.position = Vector2(cos(angulo), sin(angulo)) * radio # Posición circular

		# Guardar info dentro del botón
		boton.set("tecnica_id", tecnica_id)
		boton.set("tecnica_stats", stats)

		# Evento
		if boton.has_signal("tecnica_seleccionada"):
			boton.tecnica_seleccionada.connect(
				Callable(battle_manager, "_on_tecnica_seleccionada")
			)
		else:
			push_error("El botón no tiene la señal 'tecnica_seleccionada'.")

		add_child(boton)

		angulo += TAU / total
