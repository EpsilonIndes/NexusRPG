# TechButtonCircle.gd
extends Node2D

var radio := 120.0
var battle_manager: Node = null

var botones: Array[Control] = []
var boton_focado:  Control = null
var focus_activo := false
const TECH_BUTTON_SCENE := preload("res://Escenas/UserUI/tech_button.tscn")

func configurar(tecnicas_ids: Array):
	# Limpiamos los hijos previos
	focus_activo = false
	boton_focado = null

	for child in get_children():
		child.queue_free()

	botones.clear()

	if tecnicas_ids.is_empty():
		push_warning("No se recibieron técnicas para mostrar en el círculo.")
		return

	var total := tecnicas_ids.size()
	var angulo := 0.0

	for t in tecnicas_ids:
		# Extraer el ID
		var tecnica_id := str(t.get("id", t.get("tecnique_id", "")))
		if tecnica_id == "":
			push_error("Técnica sin ID interno en el array")
			continue

		# Obtenemos stats desde GlobalTechniqueDatabase
		var stats: Dictionary = t.duplicate(true) if t.has("rol_combo") else GlobalTechniqueDatabase.get_tecnica_stats(tecnica_id)
		if stats.is_empty():
			push_error("No se encontraron stats para la técnica: %s" % tecnica_id)
			continue

		stats["id"] = tecnica_id
		stats["tecnique_id"] = stats.get("tecnique_id", tecnica_id)

		# Nombre para el UI
		var nombre_visible = stats.get("nombre_tech", tecnica_id)
		#print("Añadiendo técncia:", nombre_visible)

		# Crear botón
		var boton: Control = TECH_BUTTON_SCENE.instantiate()
		if boton.has_method("configurar"):
			boton.configurar(tecnica_id, stats)
		else:
			boton.get_node("Label").text = nombre_visible
		boton.position = Vector2(cos(angulo), sin(angulo)) * radio # Posición circular
		boton.focus_mode = Control.FOCUS_ALL

		# Guardar info dentro del botón
		if not boton.has_method("configurar"):
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
		botones.append(boton)

		angulo += TAU / total

		call_deferred("_activar_focus_inicial")

func _activar_focus_inicial() -> void:
	if botones.is_empty():
		return
	
	boton_focado = botones[0]
	boton_focado.grab_focus()
	focus_activo = true


func _unhandled_input(event: InputEvent) -> void:
	if not focus_activo:
		return
	
	if boton_focado == null:
		return
	
	if event.is_action_pressed("arriba"):
		_mover_focus(Vector2.UP)
	elif event.is_action_pressed("abajo"):
		_mover_focus(Vector2.DOWN)
	elif event.is_action_pressed("izquierda"):
		_mover_focus(Vector2.LEFT)
	elif event.is_action_pressed("derecha"):
		_mover_focus(Vector2.RIGHT)
	elif event.is_action_pressed("accion"):
		get_viewport().set_input_as_handled()
		print("ui_accept presionado (Botón de técnica seleccionado)")

func _mover_focus(direction: Vector2) -> void:
	var mejor_boton: Control = null
	var mejor_puntaje := -INF

	for boton in botones:
		if boton == boton_focado:
			continue
		
		var dir_boton := boton.position.normalized()
		var dot := dir_boton.dot(direction)

		if dot <= 0.3:
			continue
		
		if dot > mejor_puntaje:
			mejor_puntaje = dot
			mejor_boton = boton

	if mejor_boton:
		boton_focado = mejor_boton
		boton_focado.grab_focus()


# Limpiar interfaz cuando se abra el selector de objetivos
func limpiar():
	focus_activo = false
	boton_focado = null

	for child in get_children():
		child.queue_free()

	botones.clear()

func set_interactive(valor: bool) -> void:
	focus_activo = valor
