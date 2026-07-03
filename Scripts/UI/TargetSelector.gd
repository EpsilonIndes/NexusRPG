# Este script maneja la seleccion de objetivos en el modo batalla.
extends Control

var targets := {
	"enemies": [],
	"allies": []
}
var grupo_actual: String = "enemies"
var allow_switch: bool = false
var index_actual: int = 0
var callback: Callable
var cancel_callback: Callable
var focus_callback: Callable
var activo: bool = false
var touch_buttons: Array[Button] = []

@export var touch_zone_size := Vector2(128.0, 128.0)
@export var touch_zone_offset := Vector2.ZERO
@export var touch_anchor_height := 1.0
@export var show_debug_touch_zones := false

@onready var ui_overlay = get_parent()

func open(targets_data: Dictionary, _callback: Callable, _cancel_callback: Callable, _focus_callback: Callable = Callable()) -> void:
	if activo:
		push_warning("TargetSelector ya estaba activo, ignorando open() duplicado")
		return

	ui_overlay.set_tecnicas_interactivas(false)
	print("Abriendo selector de objetivos")

	targets.enemies = targets_data.get("enemies", [])
	targets.allies = targets_data.get("allies", [])
	grupo_actual = targets_data.get("default_group", "enemies")
	allow_switch = bool(targets_data.get("allow_switch", false))

	callback = _callback
	cancel_callback = _cancel_callback
	focus_callback = _focus_callback
	index_actual = 0
	activo = true
	visible = true
	set_process_input(true)
	set_process(true)

	_ordenar_grupo_actual()
	_reconstruir_touch_zones()
	_resaltar_actual()
	_actualizar_touch_zones()


func close(restaurar_tecnicas: bool = false) -> void:
	_quitar_resaltado_actual()
	visible = false
	activo = false
	targets.enemies.clear()
	targets.allies.clear()
	callback = Callable()
	cancel_callback = Callable()
	focus_callback = Callable()
	set_process_input(false)
	set_process(false)
	_limpiar_touch_zones()

	if restaurar_tecnicas:
		ui_overlay.set_tecnicas_interactivas(true)


func _process(_delta: float) -> void:
	if not activo:
		return

	_actualizar_touch_zones()


func _input(event: InputEvent) -> void:
	if not activo:
		return

	if event.is_action_pressed("derecha") or event.is_action_pressed("abajo"):
		get_viewport().set_input_as_handled()
		_mover(1)

	elif event.is_action_pressed("izquierda") or event.is_action_pressed("arriba"):
		get_viewport().set_input_as_handled()
		_mover(-1)

	elif event.is_action_pressed("accion"):
		print("ACCION apretado")
		get_viewport().set_input_as_handled()
		_confirmar()

	elif event.is_action_pressed("cancelar"):
		get_viewport().set_input_as_handled()
		_cancelar()

	elif event.is_action_pressed("cambiar_grupo"):
		get_viewport().set_input_as_handled()
		_alternar_grupo()


func _mover(delta) -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		return

	print("Moviendo selector de objetivo:", delta)
	_quitar_resaltado_actual()
	index_actual = wrapi(index_actual + delta, 0, lista.size())
	_resaltar_actual()


func _confirmar() -> void:
	if not activo:
		return

	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		push_error("No hay objetivos para confirmar")
		close()
		return

	var target = lista[index_actual]
	var selected_callback := callback

	close()

	if selected_callback.is_valid():
		selected_callback.call(target)
	else:
		print("[TargetSelector] Callback invalido")


func _cancelar() -> void:
	print("Seleccion de objetivo cancelado")
	var selected_cancel_callback := cancel_callback

	close(true)

	if selected_cancel_callback.is_valid():
		selected_cancel_callback.call()


func _resaltar_actual() -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		return

	var c = lista[index_actual]
	if c.has_method("set_target_highlight"):
		print("Resaltando objetivo:", c.nombre)
		c.set_target_highlight(true)
	if focus_callback.is_valid():
		focus_callback.call(c)


func _quitar_resaltado_actual() -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		return

	var c = lista[index_actual]
	if c.has_method("set_target_highlight"):
		print("Quitando resaltado de objetivo:", c.nombre)
		c.set_target_highlight(false)


func _on_target_chosen(target: Combatant) -> void:
	print("Objetivo elegido:", target.nombre)
	var selected_callback := callback

	close()

	if selected_callback.is_valid():
		selected_callback.call(target)


func _seleccionar_indice(nuevo_indice: int) -> void:
	var lista := _get_candidatos_actuales()
	if nuevo_indice < 0 or nuevo_indice >= lista.size():
		return
	if nuevo_indice == index_actual:
		return

	_quitar_resaltado_actual()
	index_actual = nuevo_indice
	_resaltar_actual()


func _on_touch_target_pressed(target: Combatant) -> void:
	if not activo:
		return

	var lista := _get_candidatos_actuales()
	var target_index := lista.find(target)
	if target_index == -1:
		return

	get_viewport().set_input_as_handled()

	if target_index == index_actual:
		_confirmar()
	else:
		_seleccionar_indice(target_index)


func _alternar_grupo() -> void:
	if not allow_switch:
		push_warning("allow_switch no permitido")
		return

	var nuevo_grupo = "allies" if grupo_actual == "enemies" else "enemies"

	if targets[nuevo_grupo].is_empty():
		return

	print("Alternando targets a: ", nuevo_grupo)

	_quitar_resaltado_actual()
	grupo_actual = nuevo_grupo
	index_actual = 0
	_ordenar_grupo_actual()
	_reconstruir_touch_zones()
	_resaltar_actual()
	_actualizar_touch_zones()


func _get_candidatos_actuales() -> Array:
	return targets.get(grupo_actual, [])


func _ordenar_grupo_actual() -> void:
	var lista := _get_candidatos_actuales()
	lista.sort_custom(func(a, b):
		return a.global_position.x < b.global_position.x
	)


func _reconstruir_touch_zones() -> void:
	_limpiar_touch_zones()

	for target in _get_candidatos_actuales():
		var button := Button.new()
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = touch_zone_size
		button.size = touch_zone_size
		button.modulate = Color(1.0, 1.0, 1.0, 0.25 if show_debug_touch_zones else 0.0)
		button.pressed.connect(Callable(self, "_on_touch_target_pressed").bind(target))
		add_child(button)
		touch_buttons.append(button)


func _limpiar_touch_zones() -> void:
	for button in touch_buttons:
		if button != null and is_instance_valid(button):
			button.queue_free()
	touch_buttons.clear()


func _actualizar_touch_zones() -> void:
	var camera := _get_battle_camera()
	if camera == null:
		for button in touch_buttons:
			if button != null and is_instance_valid(button):
				button.visible = false
		return

	var lista := _get_candidatos_actuales()
	for i in range(touch_buttons.size()):
		var button := touch_buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		if i >= lista.size() or not _target_es_valido(lista[i]):
			button.visible = false
			button.disabled = true
			continue

		var target = lista[i]
		var anchor_position := _get_touch_anchor_position(target)
		if camera.is_position_behind(anchor_position):
			button.visible = false
			button.disabled = true
			continue

		var screen_position := camera.unproject_position(anchor_position)
		button.size = touch_zone_size
		button.global_position = screen_position - touch_zone_size * 0.5 + touch_zone_offset
		button.visible = true
		button.disabled = false


func _get_battle_camera() -> Camera3D:
	var scene := get_tree().current_scene
	if scene == null:
		return null

	var camera := scene.get_node_or_null("Camera/BattleCamera")
	if camera is Camera3D:
		return camera

	return get_viewport().get_camera_3d()


func _get_touch_anchor_position(target: Combatant) -> Vector3:
	var damage_anchor := target.get_node_or_null("DamageAnchor")
	if damage_anchor is Node3D:
		return damage_anchor.global_position

	return target.global_position + Vector3.UP * touch_anchor_height


func _target_es_valido(target) -> bool:
	return target != null and is_instance_valid(target) and target.has_method("esta_vivo") and target.esta_vivo()
