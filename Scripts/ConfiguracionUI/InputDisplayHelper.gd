extends Node

const UNASSIGNED_TEXT := "Unassigned"

const _KEY_NAME_OVERRIDES := {
	KEY_SPACE: "Space",
	KEY_ESCAPE: "Esc",
	KEY_ENTER: "Enter",
	KEY_KP_ENTER: "Numpad Enter",
	KEY_TAB: "Tab",
	KEY_BACKSPACE: "Backspace",
	KEY_DELETE: "Delete",
	KEY_INSERT: "Insert",
	KEY_HOME: "Home",
	KEY_END: "End",
	KEY_PAGEUP: "Page Up",
	KEY_PAGEDOWN: "Page Down",
	KEY_UP: "Up",
	KEY_DOWN: "Down",
	KEY_LEFT: "Left",
	KEY_RIGHT: "Right",
	KEY_SHIFT: "Shift",
	KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt",
	KEY_META: "Meta",
}

const _JOYPAD_BUTTON_NAMES := {
	JOY_BUTTON_A: "A Button",
	JOY_BUTTON_B: "B Button",
	JOY_BUTTON_X: "X Button",
	JOY_BUTTON_Y: "Y Button",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

const _JOYPAD_AXIS_NAMES := {
	JOY_AXIS_LEFT_X: {
		-1.0: "Left Stick Left",
		1.0: "Left Stick Right",
	},
	JOY_AXIS_LEFT_Y: {
		-1.0: "Left Stick Up",
		1.0: "Left Stick Down",
	},
	JOY_AXIS_RIGHT_X: {
		-1.0: "Right Stick Left",
		1.0: "Right Stick Right",
	},
	JOY_AXIS_RIGHT_Y: {
		-1.0: "Right Stick Up",
		1.0: "Right Stick Down",
	},
	JOY_AXIS_TRIGGER_LEFT: {
		1.0: "LT",
	},
	JOY_AXIS_TRIGGER_RIGHT: {
		1.0: "RT",
	},
}

const _MOUSE_BUTTON_NAMES := {
	MOUSE_BUTTON_LEFT: "Mouse Left",
	MOUSE_BUTTON_RIGHT: "Mouse Right",
	MOUSE_BUTTON_MIDDLE: "Mouse Middle",
	MOUSE_BUTTON_WHEEL_UP: "Wheel Up",
	MOUSE_BUTTON_WHEEL_DOWN: "Wheel Down",
	MOUSE_BUTTON_WHEEL_LEFT: "Wheel Left",
	MOUSE_BUTTON_WHEEL_RIGHT: "Wheel Right",
	MOUSE_BUTTON_XBUTTON1: "Mouse 4",
	MOUSE_BUTTON_XBUTTON2: "Mouse 5",
}


func event_to_text(event: InputEvent) -> String:
	if event == null:
		return UNASSIGNED_TEXT

	if event is InputEventKey:
		return key_to_text(event)
	if event is InputEventJoypadButton:
		return joypad_button_to_text(event)
	if event is InputEventJoypadMotion:
		return joypad_motion_to_text(event)
	if event is InputEventMouseButton:
		return mouse_button_to_text(event)

	var fallback := event.as_text()
	return fallback if not fallback.is_empty() else UNASSIGNED_TEXT


func events_to_text(events: Array, separator := " / ") -> String:
	var names := PackedStringArray()

	for event in events:
		if event is InputEvent:
			names.append(event_to_text(event))

	return separator.join(names) if not names.is_empty() else UNASSIGNED_TEXT


func action_to_text(action: StringName, family: StringName = &"", separator := " / ") -> String:
	if not InputMap.has_action(action):
		return UNASSIGNED_TEXT

	var events := []
	for event in InputMap.action_get_events(action):
		if family == &"" or input_family(event) == family:
			events.append(event)

	return events_to_text(events, separator)


func key_to_text(event: InputEventKey) -> String:
	var parts := PackedStringArray()

	if event.ctrl_pressed and _keycode(event) != KEY_CTRL:
		parts.append(_located_modifier_name(KEY_CTRL, event.location))
	if event.alt_pressed and _keycode(event) != KEY_ALT:
		parts.append(_located_modifier_name(KEY_ALT, event.location))
	if event.shift_pressed and _keycode(event) != KEY_SHIFT:
		parts.append(_located_modifier_name(KEY_SHIFT, event.location))
	if event.meta_pressed and _keycode(event) != KEY_META:
		parts.append(_located_modifier_name(KEY_META, event.location))

	parts.append(_keycode_to_text(_keycode(event), event.location))
	return "+".join(parts)


func joypad_button_to_text(event: InputEventJoypadButton) -> String:
	return _JOYPAD_BUTTON_NAMES.get(event.button_index, "Button %d" % event.button_index)


func joypad_motion_to_text(event: InputEventJoypadMotion) -> String:
	var axis_map: Dictionary = _JOYPAD_AXIS_NAMES.get(event.axis, {})
	if axis_map.is_empty():
		return "Axis %d %s" % [event.axis, _axis_direction_text(event.axis_value)]

	var direction := 1.0 if event.axis_value >= 0.0 else -1.0
	return axis_map.get(direction, "Axis %d %s" % [event.axis, _axis_direction_text(event.axis_value)])


func mouse_button_to_text(event: InputEventMouseButton) -> String:
	return _MOUSE_BUTTON_NAMES.get(event.button_index, "Mouse %d" % event.button_index)


func input_family(event: InputEvent) -> StringName:
	if event is InputEventKey:
		return &"keyboard"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return &"gamepad"
	if event is InputEventMouseButton:
		return &"mouse"
	return &"other"


func _keycode(event: InputEventKey) -> Key:
	if event.physical_keycode != KEY_NONE:
		return event.physical_keycode
	return event.keycode


func _keycode_to_text(keycode: Key, location: int) -> String:
	match keycode:
		KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META:
			return _located_modifier_name(keycode, location)

	if _KEY_NAME_OVERRIDES.has(keycode):
		return _KEY_NAME_OVERRIDES[keycode]

	var text := OS.get_keycode_string(keycode)
	if text.length() == 1:
		return text.to_upper()
	return text if not text.is_empty() else "Key %d" % keycode


func _located_modifier_name(keycode: Key, location: int) -> String:
	var base_name = _KEY_NAME_OVERRIDES.get(keycode, OS.get_keycode_string(keycode))
	match location:
		KEY_LOCATION_LEFT:
			return "L%s" % base_name
		KEY_LOCATION_RIGHT:
			return "R%s" % base_name
		_:
			return base_name


func _axis_direction_text(value: float) -> String:
	return "+" if value >= 0.0 else "-"

