extends Node
## Detects presentation needs; never consumes input or changes gameplay bindings.
signal input_method_changed(method: int)
signal layout_changed(mobile: bool)
signal controller_connection_changed(device: int, connected: bool)
signal presentation_changed

enum InputMethod { KEYBOARD_MOUSE, GAMEPAD, TOUCH }
enum InputOverride { AUTO, TOUCH, KEYBOARD_MOUSE, GAMEPAD }
enum LayoutOverride { AUTO, DESKTOP, MOBILE }

var input_method := InputMethod.KEYBOARD_MOUSE
var input_override := InputOverride.AUTO
var layout_override := LayoutOverride.AUTO
var mobile_layout := false
var active_controller := -1
var connected_controllers: Array[int] = []
var _detected_method := InputMethod.KEYBOARD_MOUSE
var _mouse_distance := 0.0
var _axis_values: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	connected_controllers.assign(Input.get_connected_joypads())
	_detected_method = InputMethod.TOUCH if is_mobile_platform() else InputMethod.KEYBOARD_MOUSE
	input_method = _detected_method
	Input.joy_connection_changed.connect(_controller_changed)
	get_viewport().size_changed.connect(_refresh_layout)
	apply_settings()
	_refresh_layout()

func is_mobile_platform() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios")

func uses_touch() -> bool:
	return input_method == InputMethod.TOUCH

func apply_settings() -> void:
	set_input_override(int(SettingsManager.settings.get("interface", {}).get("input_mode", 0)))

func set_input_override(mode: int) -> void:
	input_override = clampi(mode, InputOverride.AUTO, InputOverride.GAMEPAD)
	_update_method()

func set_layout_override(mode: int) -> void:
	layout_override = clampi(mode, LayoutOverride.AUTO, LayoutOverride.MOBILE)
	_refresh_layout()

func _refresh_layout() -> void:
	var next_mobile := is_mobile_platform()
	if layout_override != LayoutOverride.AUTO:
		next_mobile = layout_override == LayoutOverride.MOBILE
	if mobile_layout != next_mobile:
		mobile_layout = next_mobile
		layout_changed.emit(mobile_layout)
	presentation_changed.emit()

func _update_method() -> void:
	var next_method := _detected_method
	match input_override:
		InputOverride.TOUCH: next_method = InputMethod.TOUCH
		InputOverride.KEYBOARD_MOUSE: next_method = InputMethod.KEYBOARD_MOUSE
		InputOverride.GAMEPAD:
			next_method = InputMethod.GAMEPAD if not connected_controllers.is_empty() else _fallback_method()
	if input_method != next_method:
		input_method = next_method
		input_method_changed.emit(input_method)
		presentation_changed.emit()

func _fallback_method() -> int:
	return InputMethod.TOUCH if is_mobile_platform() else InputMethod.KEYBOARD_MOUSE

func _controller_changed(device: int, connected: bool) -> void:
	if connected:
		if device not in connected_controllers:
			connected_controllers.append(device)
	else:
		connected_controllers.erase(device)
		_axis_values.erase(device)
		if device == active_controller or connected_controllers.is_empty():
			active_controller = -1
			_detected_method = _fallback_method()
	_update_method()
	controller_connection_changed.emit(device, connected)

func _detect(method: int, device: int = -1) -> void:
	_detected_method = method
	_mouse_distance = 0.0
	if method == InputMethod.GAMEPAD:
		active_controller = device
	_update_method()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_detect(InputMethod.TOUCH)
	elif event is InputEventScreenDrag and event.relative.length() >= 4.0:
		_detect(InputMethod.TOUCH)
	elif event is InputEventKey and event.pressed and not event.echo:
		_detect(InputMethod.KEYBOARD_MOUSE)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.pressed:
		_detect(InputMethod.KEYBOARD_MOUSE)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.relative.length() >= 2.0:
			_mouse_distance += event.relative.length()
			if _mouse_distance >= 16.0:
				_detect(InputMethod.KEYBOARD_MOUSE)
	elif event is InputEventJoypadButton and event.pressed:
		_detect(InputMethod.GAMEPAD, event.device)
	elif event is InputEventJoypadMotion:
		# Trigger rest positions and stick drift must not steal the interface.
		if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
			return
		var axes: Dictionary = _axis_values.get(event.device, {})
		var previous: float = axes.get(event.axis, 0.0)
		axes[event.axis] = event.axis_value
		_axis_values[event.device] = axes
		if absf(event.axis_value) >= 0.65 and absf(previous) < 0.65:
			_detect(InputMethod.GAMEPAD, event.device)
