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

	_ordenar_grupo_actual()
	_resaltar_actual()


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

	if restaurar_tecnicas:
		ui_overlay.set_tecnicas_interactivas(true)


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
	_resaltar_actual()


func _get_candidatos_actuales() -> Array:
	return targets.get(grupo_actual, [])


func _ordenar_grupo_actual() -> void:
	var lista := _get_candidatos_actuales()
	lista.sort_custom(func(a, b):
		return a.global_position.x < b.global_position.x
	)
