#ControlController.gd (Autoload)
extends Node

# Señales
signal controls_applied
signal binding_changed(action: StringName)

const SERIALIZATION_VERSION := 1

var _default_bindings: Dictionary = {}
var _last_applied_settings: Dictionary = {}
var _defaults_captured := false


# Captura defaults y aplica settings persistidos al iniciar
func _ready() -> void:
	capture_defaults()
	if get_node_or_null("/root/SettingsManager") != null:
		apply_controls(SettingsManager.settings.get("controls", {}))


# Guarda el estado base del InputMap
func capture_defaults(force := false) -> void:
	if _defaults_captured and not force:
		return

	_default_bindings.clear()

	for action in InputMap.get_actions():
		var action_name := StringName(action)
		_default_bindings[action_name] = _duplicate_events(InputMap.action_get_events(action_name))

	_defaults_captured = true


# Restaura defaults y aplica bindings personalizadas
func apply_controls(control_settings: Dictionary) -> void:
	capture_defaults()
	_last_applied_settings = control_settings.duplicate(true)
	_apply_default_bindings()

	for action in control_settings.keys():
		var action_name := StringName(action)
		if not _action_exists(action_name):
			continue

		var events := _deserialize_event_list(control_settings[action])
		if events.is_empty():
			continue

		InputMap.action_erase_events(action_name)
		for event in events:
			InputMap.action_add_event(action_name, event.duplicate())

	controls_applied.emit()


# Cambia un evento de una acción y actualiza settings.controls
func set_binding(action: StringName, event: InputEvent, replace := true) -> bool:
	if not _action_exists(action):
		return false
	if event == null:
		push_warning("ControlsController: no se puede asignar un InputEvent nulo a '%s'." % action)
		return false

	var existing_events := InputMap.action_get_events(action)
	InputMap.action_erase_events(action)

	for existing_event in existing_events:
		if replace and _same_input_family(existing_event, event):
			continue
		InputMap.action_add_event(action, existing_event.duplicate())

	InputMap.action_add_event(action, event.duplicate())
	_save_action_to_settings(action)
	binding_changed.emit(action)
	return true


# Restores the captured startup InputMap and mirrors that state into SettingsManager.
func reset_to_defaults() -> void:
	_apply_default_bindings()
	SettingsManager.settings["controls"] = {}
	_last_applied_settings.clear()
	controls_applied.emit()


func _apply_default_bindings() -> void:
	for action in _default_bindings.keys():
		if not _action_exists(action):
			continue

		InputMap.action_erase_events(action)
		for event in _default_bindings[action]:
			InputMap.action_add_event(action, event.duplicate())


# Serializes the current InputMap into SettingsManager.settings.controls.
func save_current_bindings() -> Dictionary:
	var serialized := {}

	for action in InputMap.get_actions():
		var action_name := StringName(action)
		var events := []

		for event in InputMap.action_get_events(action_name):
			var serialized_event := _serialize_event(event)
			if not serialized_event.is_empty():
				events.append(serialized_event)

		serialized[String(action_name)] = events

	SettingsManager.settings["controls"] = serialized
	_last_applied_settings = serialized.duplicate(true)
	return serialized


func _save_action_to_settings(action: StringName) -> void:
	if not SettingsManager.settings.has("controls"):
		SettingsManager.settings["controls"] = {}

	var events := []
	for event in InputMap.action_get_events(action):
		var serialized_event := _serialize_event(event)
		if not serialized_event.is_empty():
			events.append(serialized_event)

	SettingsManager.settings["controls"][String(action)] = events
	_last_applied_settings[String(action)] = events.duplicate(true)


func _action_exists(action: StringName) -> bool:
	if InputMap.has_action(action):
		return true

	push_warning("ControlsController: la acción '%s' no existe en InputMap." % action)
	return false


func _duplicate_events(events: Array) -> Array[InputEvent]:
	var duplicated: Array[InputEvent] = []
	for event in events:
		if event is InputEvent:
			duplicated.append(event.duplicate())
	return duplicated


func _deserialize_event_list(value) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if not (value is Array):
		return events

	for serialized_event in value:
		if not (serialized_event is String):
			continue

		var event := _deserialize_event(serialized_event)
		if event:
			events.append(event)

	return events


func _serialize_event(event: InputEvent) -> String:
	var data := {
		"version": SERIALIZATION_VERSION,
		"type": event.get_class(),
		"device": event.device,
	}

	if event is InputEventKey:
		data["keycode"] = event.keycode
		data["physical_keycode"] = event.physical_keycode
		data["key_label"] = event.key_label
		data["unicode"] = event.unicode
		data["location"] = event.location
		data["alt_pressed"] = event.alt_pressed
		data["shift_pressed"] = event.shift_pressed
		data["ctrl_pressed"] = event.ctrl_pressed
		data["meta_pressed"] = event.meta_pressed
	elif event is InputEventJoypadButton:
		data["button_index"] = event.button_index
		data["pressure"] = event.pressure
	elif event is InputEventJoypadMotion:
		data["axis"] = event.axis
		data["axis_value"] = event.axis_value
	elif event is InputEventMouseButton:
		data["button_index"] = event.button_index
		data["factor"] = event.factor
		data["double_click"] = event.double_click
	else:
		push_warning("ControlsController: tipo de InputEvent no soportado para guardar: %s." % event.get_class())
		return ""

	return JSON.stringify(data)


func _deserialize_event(serialized_event: String) -> InputEvent:
	var data = JSON.parse_string(serialized_event)
	if not (data is Dictionary):
		push_warning("ControlsController: evento serializado inválido.")
		return null

	var event: InputEvent = null
	match data.get("type", ""):
		"InputEventKey":
			var key_event := InputEventKey.new()
			key_event.keycode = int(data.get("keycode", 0))
			key_event.physical_keycode = int(data.get("physical_keycode", 0))
			key_event.key_label = int(data.get("key_label", 0))
			key_event.unicode = int(data.get("unicode", 0))
			key_event.location = int(data.get("location", 0))
			key_event.alt_pressed = bool(data.get("alt_pressed", false))
			key_event.shift_pressed = bool(data.get("shift_pressed", false))
			key_event.ctrl_pressed = bool(data.get("ctrl_pressed", false))
			key_event.meta_pressed = bool(data.get("meta_pressed", false))
			event = key_event
		"InputEventJoypadButton":
			var joypad_button_event := InputEventJoypadButton.new()
			joypad_button_event.button_index = int(data.get("button_index", 0))
			joypad_button_event.pressure = float(data.get("pressure", 0.0))
			event = joypad_button_event
		"InputEventJoypadMotion":
			var joypad_motion_event := InputEventJoypadMotion.new()
			joypad_motion_event.axis = int(data.get("axis", 0))
			joypad_motion_event.axis_value = float(data.get("axis_value", 0.0))
			event = joypad_motion_event
		"InputEventMouseButton":
			var mouse_button_event := InputEventMouseButton.new()
			mouse_button_event.button_index = int(data.get("button_index", 0))
			mouse_button_event.factor = float(data.get("factor", 1.0))
			mouse_button_event.double_click = bool(data.get("double_click", false))
			event = mouse_button_event
		_:
			push_warning("ControlsController: tipo de InputEvent no soportado al cargar: %s." % data.get("type", ""))
			return null

	event.device = int(data.get("device", -1))
	return event


func _same_input_family(a: InputEvent, b: InputEvent) -> bool:
	return _input_family(a) == _input_family(b)


func _input_family(event: InputEvent) -> StringName:
	if event is InputEventKey:
		return &"keyboard"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return &"gamepad"
	if event is InputEventMouseButton:
		return &"mouse"
	return &"other"
