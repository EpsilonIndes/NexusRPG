extends Node2D

@export var right_margin := 64.0
@export var center_y_ratio := 0.52
@export var vertical_spacing := 64.0
@export var ellipse_x_radius := 42.0
@export var min_button_size := Vector2(126.0, 36.0)

var battle_manager: Node = null
var botones: Array[Control] = []
var boton_focado: Control = null
var focus_activo := false

const TECH_BUTTON_SCENE := preload("res://Escenas/UserUI/tech_button.tscn")


func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_posicionar_contenedor):
		viewport.size_changed.connect(_posicionar_contenedor)
	_posicionar_contenedor()


func configurar(tecnicas_ids: Array) -> void:
	focus_activo = false
	boton_focado = null

	for child in get_children():
		child.queue_free()

	botones.clear()

	if tecnicas_ids.is_empty():
		push_warning("No se recibieron tecnicas para mostrar.")
		return

	var total := tecnicas_ids.size()
	var index := 0

	for t in tecnicas_ids:
		var tecnica_id := str(t.get("id", t.get("tecnique_id", "")))
		if tecnica_id == "":
			push_error("Tecnica sin ID interno en el array")
			continue

		var stats: Dictionary = t.duplicate(true) if t.has("rol_combo") else GlobalTechniqueDatabase.get_tecnica_stats(tecnica_id)
		if stats.is_empty():
			push_error("No se encontraron stats para la tecnica: %s" % tecnica_id)
			continue

		stats["id"] = tecnica_id
		stats["tecnique_id"] = stats.get("tecnique_id", tecnica_id)

		var nombre_visible = stats.get("nombre_tech", tecnica_id)
		var boton: Control = TECH_BUTTON_SCENE.instantiate()

		if boton.has_method("configurar"):
			boton.configurar(tecnica_id, stats)
		else:
			boton.get_node("Label").text = nombre_visible
			boton.set("tecnica_id", tecnica_id)
			boton.set("tecnica_stats", stats)

		boton.position = _calcular_posicion_boton(index, total, boton)
		boton.focus_mode = Control.FOCUS_ALL

		if boton.has_signal("tecnica_seleccionada"):
			boton.tecnica_seleccionada.connect(Callable(battle_manager, "_on_tecnica_seleccionada"))
		else:
			push_error("El boton no tiene la signal 'tecnica_seleccionada'.")

		add_child(boton)
		botones.append(boton)
		index += 1

	call_deferred("_activar_focus_inicial")


func _posicionar_contenedor() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var viewport_size := viewport.get_visible_rect().size
	global_position = Vector2(
		viewport_size.x - right_margin,
		viewport_size.y * center_y_ratio
	)


func _calcular_posicion_boton(index: int, total: int, boton: Control) -> Vector2:
	var center_index := float(total - 1) * 0.5
	var relative_index := float(index) - center_index
	var normalized := 0.0
	if total > 1 and center_index != 0.0:
		normalized = relative_index / center_index

	var button_size := _get_button_size(boton)
	var arc_offset = -ellipse_x_radius * (1.0 - min(abs(normalized), 1.0))
	var y_offset := relative_index * vertical_spacing

	return Vector2(-button_size.x + arc_offset, y_offset - button_size.y * 0.5)


func _get_button_size(boton: Control) -> Vector2:
	var resolved_size := boton.custom_minimum_size
	if resolved_size == Vector2.ZERO:
		resolved_size = boton.size

	resolved_size.x = max(resolved_size.x * boton.scale.x, min_button_size.x)
	resolved_size.y = max(resolved_size.y * boton.scale.y, min_button_size.y)
	return resolved_size


func _activar_focus_inicial() -> void:
	if botones.is_empty():
		return

	boton_focado = botones[0]
	boton_focado.grab_focus()
	focus_activo = true


func _unhandled_input(event: InputEvent) -> void:
	if not focus_activo or boton_focado == null:
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
		print("ui_accept presionado (Boton de tecnica seleccionado)")


func _mover_focus(direction: Vector2) -> void:
	var mejor_boton: Control = null
	var mejor_puntaje := -INF

	for boton in botones:
		if boton == boton_focado:
			continue

		var offset := boton.position - boton_focado.position
		if offset == Vector2.ZERO:
			continue

		var dot := offset.normalized().dot(direction)
		if dot <= 0.3:
			continue

		var puntaje := dot - offset.length() * 0.001
		if puntaje > mejor_puntaje:
			mejor_puntaje = puntaje
			mejor_boton = boton

	if mejor_boton:
		boton_focado = mejor_boton
		boton_focado.grab_focus()


func limpiar() -> void:
	focus_activo = false
	boton_focado = null

	for child in get_children():
		child.queue_free()

	botones.clear()


func set_interactive(valor: bool) -> void:
	focus_activo = valor
