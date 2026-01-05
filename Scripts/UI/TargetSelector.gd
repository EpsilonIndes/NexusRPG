# Este script maneja la selección de objetivos en el modo batalla
extends Control

var targets := {
	"enemies": [],
	"allies": []
}
var grupo_actual: String = "enemies"
var allow_switch: bool = false
var index_actual: int = 0
var callback: Callable
var activo: bool = false

func open(targets_data: Dictionary, _callback: Callable) -> void:
	print("Abriendo selector de objetivos")

	targets.enemies = targets_data.get("enemies", [])
	targets.allies = targets_data.get("allies", [])
	grupo_actual = targets_data.get("default_group", "enemies")
	allow_switch = targets_data.allow_switch

	callback = _callback
	index_actual = 0
	activo = true
	visible = true
	set_process_input(true)

	_ordenar_grupo_actual() 
	_resaltar_actual()


func _unhandled_input(event: InputEvent) -> void:
	if not activo:
		return
	
	if event.is_action_pressed("derecha") or event.is_action_pressed("abajo"):
		_mover(1)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("izquierda") or event.is_action_pressed("arriba"):
		_mover(-1)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("accion"):
		print("ACCION apretado")
		_confirmar()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("cancelar"):
		_cancelar()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("cambiar_grupo"):
		_alternar_grupo()
	

# Cambio de objetivo
func _mover(delta) -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		return
	
	print("Moviendo selector de objetivo:", delta)
	_quitar_resaltado_actual()
	index_actual = wrapi(index_actual + delta, 0, lista.size())
	_resaltar_actual()
	
func _confirmar() -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		push_error("No hay objetivos para confirmar")
		return
	if callback.is_valid():
		callback.call(lista[index_actual])
	close()

func _cancelar() -> void:
	print("Seleccion de objetivo cancelado")
	close()


func _resaltar_actual() -> void:
	var lista := _get_candidatos_actuales()
	if lista.is_empty():
		return

	var c = lista[index_actual]
	if c.has_method("set_target_highlight"):
		print("Resaltando objetivo:", c.nombre)
		c.set_target_highlight(true)

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
	callback.call(target)
	close()

func close() -> void:
	_quitar_resaltado_actual()
	visible = false
	activo = false
	targets.enemies.clear()
	targets.allies.clear()
	callback = Callable()
	set_process_input(false)


func _alternar_grupo() -> void:
	if not allow_switch:
		if allow_switch == null:
			push_error("Allow_switch es nulo")
		else:
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
