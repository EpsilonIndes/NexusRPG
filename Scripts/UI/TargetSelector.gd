# Este script maneja la selección de objetivos en el modo batalla
extends Control

var candidatos: Array = []
var index_actual: int = 0
var callback: Callable
var activo: bool = false

func open(_candidatos: Array, _callback: Callable) -> void:
    print("Abriendo selector de objetivos")
    candidatos = _candidatos
    callback = _callback
    index_actual = 0
    activo = true
    visible = true
    set_process_input(true)

    candidatos.sort_custom(
        func(a, b):
            return a.global_position.x < b.global_position.x
    )

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




# Cambio de objetivo
func _mover(delta) -> void:
    print("Moviendo selector de objetivo:", delta)
    _quitar_resaltado_actual()
    index_actual = wrapi(index_actual + delta, 0, candidatos.size())
    _resaltar_actual()

func _confirmar() -> void:
    if callback.is_valid():
        callback.call(candidatos[index_actual])
    close()

func _cancelar() -> void:
    print("Seleccion de objetivo cancelado")
    close()


func _resaltar_actual() -> void:
    if candidatos.is_empty():
        return
    if index_actual < 0 or index_actual >= candidatos.size():
        return

    var c = candidatos[index_actual]
    if c.has_method("set_target_highlight"):
        print("Resaltando objetivo:", c.nombre)
        c.set_target_highlight(true)

func _quitar_resaltado_actual() -> void:
    if candidatos.is_empty():
        return
    if index_actual < 0 or index_actual >= candidatos.size():
        return
    
    var c = candidatos[index_actual]
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
    candidatos.clear()
    callback = Callable()
    set_process_input(false)