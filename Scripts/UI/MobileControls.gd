extends Control

const MOVE_LEFT := &"izquierda"
const MOVE_RIGHT := &"derecha"
const MOVE_UP := &"arriba"
const MOVE_DOWN := &"abajo"

@export var show_on_mobile_only: bool = true
@export var force_visible_for_testing: bool = true
@export_range(0.0, 1.0, 0.01) var opacity: float = 0.78
@export var joystick_size: float = 150.0
@export var button_size: float = 64.0
@export var edge_margin: float = 24.0
@export var action_gap: float = 12.0
@export var joystick_deadzone: float = 0.22

var _pressed_actions: Dictionary = {}
var _joystick: VirtualJoystick


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = opacity

	visible = _should_show_controls()
	if not visible:
		return

	_build_controls()
	get_viewport().size_changed.connect(_layout_controls)
	call_deferred("_layout_controls")


func _exit_tree() -> void:
	_release_all_actions()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_release_all_actions()


func _should_show_controls() -> bool:
	if force_visible_for_testing:
		return true
	if not show_on_mobile_only:
		return true
	return OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()


func _build_controls() -> void:
	_joystick = VirtualJoystick.new()
	_joystick.name = "VirtualJoystick"
	_joystick.deadzone = joystick_deadzone
	_joystick.custom_minimum_size = Vector2(joystick_size, joystick_size)
	_joystick.direction_changed.connect(_on_joystick_direction_changed)
	_joystick.released.connect(_release_movement)
	add_child(_joystick)

	var run_button := _make_action_button("RunButton", "RUN", [&"correr"])
	var menu_button := _make_action_button("MenuButton", "MENU", [&"menu"])
	var cancel_button := _make_action_button("CancelButton", "X", [&"cancelar", &"ui_cancel"])
	var accept_button := _make_action_button("AcceptButton", "A", [&"accion", &"ui_accept"])

	add_child(run_button)
	add_child(menu_button)
	add_child(cancel_button)
	add_child(accept_button)


func _make_action_button(node_name: String, label: String, actions: Array[StringName]) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(button_size, button_size)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.58)
	style.border_color = Color(1.0, 1.0, 1.0, 0.36)
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(button_size * 0.5))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("focus", style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.92, 0.78, 0.34, 0.72)
	pressed_style.border_color = Color(1.0, 0.92, 0.56, 0.86)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_font_size_override("font_size", 16)

	button.button_down.connect(_press_actions.bind(actions))
	button.button_up.connect(_release_actions.bind(actions))
	button.tree_exiting.connect(_release_actions.bind(actions))
	return button


func _layout_controls() -> void:
	if not visible or _joystick == null:
		return

	var viewport_size := get_viewport_rect().size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	_joystick.size = Vector2(joystick_size, joystick_size)
	_joystick.position = Vector2(edge_margin, viewport_size.y - joystick_size - edge_margin)

	var accept_button := get_node_or_null("AcceptButton") as Button
	var cancel_button := get_node_or_null("CancelButton") as Button
	var run_button := get_node_or_null("RunButton") as Button
	var menu_button := get_node_or_null("MenuButton") as Button
	if accept_button == null or cancel_button == null or run_button == null or menu_button == null:
		return

	for button in [accept_button, cancel_button, run_button, menu_button]:
		button.size = Vector2(button_size, button_size)

	var right_x := viewport_size.x - edge_margin - button_size
	var bottom_y := viewport_size.y - edge_margin - button_size
	accept_button.position = Vector2(right_x, bottom_y)
	cancel_button.position = Vector2(right_x - button_size - action_gap, bottom_y - button_size * 0.55)
	run_button.position = Vector2(right_x, bottom_y - button_size - action_gap)
	menu_button.position = Vector2(right_x - button_size - action_gap, bottom_y - button_size * 1.55 - action_gap)


func _on_joystick_direction_changed(direction: Vector2) -> void:
	_set_action_strength(MOVE_LEFT, max(-direction.x, 0.0))
	_set_action_strength(MOVE_RIGHT, max(direction.x, 0.0))
	_set_action_strength(MOVE_UP, max(-direction.y, 0.0))
	_set_action_strength(MOVE_DOWN, max(direction.y, 0.0))


func _set_action_strength(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return

	if strength <= 0.0:
		_release_action(action)
		return

	Input.action_press(action, strength)
	_pressed_actions[action] = true


func _press_actions(actions: Array[StringName]) -> void:
	for action in actions:
		if InputMap.has_action(action):
			_emit_action(action, true)
			_pressed_actions[action] = true


func _release_actions(actions: Array[StringName]) -> void:
	for action in actions:
		_release_action(action)


func _release_movement() -> void:
	_release_actions([MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN])


func _release_action(action: StringName) -> void:
	if not _pressed_actions.has(action):
		return
	_emit_action(action, false)
	_pressed_actions.erase(action)


func _release_all_actions() -> void:
	for action in _pressed_actions.keys():
		if InputMap.has_action(action):
			_emit_action(action, false)
	_pressed_actions.clear()


func _emit_action(action: StringName, pressed: bool, strength: float = 1.0) -> void:
	if pressed:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = strength if pressed else 0.0
	Input.parse_input_event(event)


class VirtualJoystick:
	extends Control

	signal direction_changed(direction: Vector2)
	signal released

	var deadzone: float = 0.22
	var _active_touch_index: int = -1
	var _direction := Vector2.ZERO
	var _knob_offset := Vector2.ZERO


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _active_touch_index == -1:
				_active_touch_index = event.index
				_update_from_global_position(event.position)
			elif not event.pressed and event.index == _active_touch_index:
				_clear()
		elif event is InputEventScreenDrag and event.index == _active_touch_index:
			_update_from_global_position(event.position)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_active_touch_index = -2
				_update_from_global_position(event.global_position)
			elif _active_touch_index == -2:
				_clear()
		elif event is InputEventMouseMotion and _active_touch_index == -2:
			_update_from_global_position(event.global_position)


	func _update_from_global_position(global_point: Vector2) -> void:
		var radius = min(size.x, size.y) * 0.5
		var center := global_position + size * 0.5
		var raw_offset := global_point - center
		_knob_offset = raw_offset.limit_length(radius)

		var normalized = _knob_offset / radius
		if normalized.length() < deadzone:
			_direction = Vector2.ZERO
		else:
			_direction = normalized.limit_length(1.0)

		direction_changed.emit(_direction)
		queue_redraw()


	func _clear() -> void:
		_active_touch_index = -1
		_direction = Vector2.ZERO
		_knob_offset = Vector2.ZERO
		direction_changed.emit(Vector2.ZERO)
		released.emit()
		queue_redraw()


	func _draw() -> void:
		var radius = min(size.x, size.y) * 0.5
		var center := size * 0.5
		draw_circle(center, radius, Color(0.05, 0.06, 0.08, 0.42))
		draw_arc(center, radius - 2.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.28), 3.0)
		draw_circle(center + _knob_offset, radius * 0.38, Color(0.95, 0.9, 0.72, 0.72))
