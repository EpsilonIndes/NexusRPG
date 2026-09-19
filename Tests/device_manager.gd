extends Node
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("DEVICE TEST: " + message)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := DeviceManager
	manager.set_input_override(manager.InputOverride.AUTO)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ENTER
	manager._input(key)
	check(manager.input_method == manager.InputMethod.KEYBOARD_MOUSE, "Keyboard detected")
	manager.set_layout_override(manager.LayoutOverride.MOBILE)
	manager._controller_changed(77, true)
	check(manager.input_method == manager.InputMethod.KEYBOARD_MOUSE, "Connection alone does not switch mode")
	var axis := InputEventJoypadMotion.new()
	axis.device = 77
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 0.12
	manager._input(axis)
	check(manager.input_method == manager.InputMethod.KEYBOARD_MOUSE, "Stick drift ignored")
	var pad := InputEventJoypadButton.new()
	pad.device = 77
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	manager._input(pad)
	check(manager.input_method == manager.InputMethod.GAMEPAD and manager.mobile_layout, "Gamepad preserves mobile layout")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	manager._input(touch)
	var mouse := InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.pressed = true
	manager._input(mouse)
	check(manager.uses_touch(), "Emulated mouse does not replace touch")
	var panel = load("res://Escenas/UserUI/save_slots_ui.tscn").instantiate()
	add_child(panel)
	panel.open()
	check(panel.touch_view.visible and not panel.slots_list.visible, "Touch view displayed")
	check(not panel.hints.text.contains("Triángulo"), "Touch hints do not mix gamepad")
	manager._input(pad)
	check(not panel.touch_view.visible and panel.slots_list.visible, "Gamepad restores list")
	check(panel.slots_list.has_focus(), "Gamepad restores navigation focus")
	manager._controller_changed(77, false)
	check(manager.input_method != manager.InputMethod.GAMEPAD, "Disconnect falls back")
	panel.close()
	panel.queue_free()
	manager.set_input_override(manager.InputOverride.TOUCH)
	manager._input(key)
	check(manager.uses_touch(), "Manual override survives keyboard input")
	var mobile = load("res://Escenas/UserUI/mobile_controls.tscn").instantiate()
	add_child(mobile)
	GameManager.set_estado(GameManager.EstadosDeJuego.LIBRE)
	mobile._refresh_visibility()
	check(mobile.visible, "Touch exploration controls show")
	var movement: Array[StringName] = [&"izquierda"]
	mobile._press_actions(movement)
	check(Input.is_action_pressed("izquierda"), "Virtual movement held")
	manager.set_input_override(manager.InputOverride.AUTO)
	check(not mobile.visible and not Input.is_action_pressed("izquierda"), "Switch releases held touch input")
	manager.set_input_override(manager.InputOverride.TOUCH)
	GameManager.set_estado(GameManager.EstadosDeJuego.MENU)
	mobile._refresh_visibility()
	check(not mobile.visible, "World controls hidden over menus")
	mobile.queue_free()
	manager.set_input_override(manager.InputOverride.AUTO)
	manager.set_layout_override(manager.LayoutOverride.AUTO)
	print("DEVICE INTEGRATION: %d failures" % failures)
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
