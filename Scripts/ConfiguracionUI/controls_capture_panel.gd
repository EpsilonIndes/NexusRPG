extends Control

signal capture_started(action: StringName, family: StringName)
signal capture_completed(action: StringName, family: StringName)
signal capture_canceled(action: StringName, family: StringName)
signal capture_failed(action: StringName, family: StringName)

const GAMEPAD_AXIS_DEADZONE := 0.5

@onready var message_label: Label = $Panel/Label
@onready var cancel_label: Label = $Panel/cancelLabel

var _capturing := false
var _action: StringName = &""
var _family: StringName = &""


func _ready() -> void:
	visible = false
	set_process_input(false)


func start_capture(action: StringName, family: StringName) -> void:
	if not InputMap.has_action(action):
		push_warning("ControlsCapturePanel: la accion '%s' no existe en InputMap." % action)
		capture_failed.emit(action, family)
		return

	_action = action
	_family = family
	_capturing = true
	visible = true
	set_process_input(true)
	_update_labels()
	capture_started.emit(_action, _family)
	grab_focus()


func cancel_capture() -> void:
	if not _capturing:
		return

	var action := _action
	var family := _family
	_stop_capture()
	capture_canceled.emit(action, family)


func _input(event: InputEvent) -> void:
	if not _capturing:
		return

	if _is_cancel_event(event):
		cancel_capture()
		get_viewport().set_input_as_handled()
		return

	var binding_event := _event_for_family(event, _family)
	if binding_event == null:
		return

	if ControlsController.set_binding(_action, binding_event, true):
		var action := _action
		var family := _family
		_stop_capture()
		capture_completed.emit(action, family)
	else:
		capture_failed.emit(_action, _family)

	get_viewport().set_input_as_handled()


func _stop_capture() -> void:
	_capturing = false
	_action = &""
	_family = &""
	visible = false
	set_process_input(false)


func _update_labels() -> void:
	message_label.text = _message_for_family()
	cancel_label.text = "ESC para cancelar"


func _message_for_family() -> String:
	match _family:
		&"keyboard":
			return "Presiona una tecla..."
		&"gamepad":
			return "Presiona un boton..."
		&"mouse":
			return "Presiona un boton del mouse..."
		_:
			return "Presiona una entrada..."


func _is_cancel_event(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	if not event.pressed or event.echo:
		return false
	return event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE


func _event_for_family(event: InputEvent, family: StringName) -> InputEvent:
	match family:
		&"keyboard":
			return _keyboard_event(event)
		&"gamepad":
			return _gamepad_event(event)
		&"mouse":
			return _mouse_event(event)
		_:
			return _supported_event(event)


func _keyboard_event(event: InputEvent) -> InputEvent:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.duplicate()
	return null


func _gamepad_event(event: InputEvent) -> InputEvent:
	if event is InputEventJoypadButton and event.pressed:
		return event.duplicate()

	if event is InputEventJoypadMotion and absf(event.axis_value) >= GAMEPAD_AXIS_DEADZONE:
		var axis_event := event.duplicate() as InputEventJoypadMotion
		axis_event.axis_value = 1.0 if event.axis_value > 0.0 else -1.0
		return axis_event

	return null


func _mouse_event(event: InputEvent) -> InputEvent:
	if event is InputEventMouseButton and event.pressed:
		return event.duplicate()
	return null


func _supported_event(event: InputEvent) -> InputEvent:
	var keyboard := _keyboard_event(event)
	if keyboard:
		return keyboard

	var gamepad := _gamepad_event(event)
	if gamepad:
		return gamepad

	return _mouse_event(event)
