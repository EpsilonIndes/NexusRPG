extends HBoxContainer

signal binding_requested(action: StringName, family: StringName)
signal value_changed

@export var action_name: StringName
@export var display_name: String

@onready var action_label: Label = $Label
@onready var keyboard_button: Button = $KeyboardButton
@onready var gamepad_button: Button = $GamepadButton


func _ready() -> void:
	keyboard_button.pressed.connect(_on_keyboard_button_pressed)
	gamepad_button.pressed.connect(_on_gamepad_button_pressed)

	if get_node_or_null("/root/ControlsController") != null:
		if not ControlsController.binding_changed.is_connected(refresh_display):
			ControlsController.binding_changed.connect(refresh_display)
		if not ControlsController.controls_applied.is_connected(refresh_display):
			ControlsController.controls_applied.connect(refresh_display)

	refresh_display()


func refresh_display(_changed_action: StringName = &"") -> void:
	if not InputMap.has_action(action_name):
		action_label.text = _display_title()
		keyboard_button.text = InputDisplayHelper.UNASSIGNED_TEXT
		gamepad_button.text = InputDisplayHelper.UNASSIGNED_TEXT
		keyboard_button.disabled = true
		gamepad_button.disabled = true
		return

	action_label.text = _display_title()
	keyboard_button.text = InputDisplayHelper.action_to_text(action_name, &"keyboard")
	gamepad_button.text = InputDisplayHelper.action_to_text(action_name, &"gamepad")
	keyboard_button.disabled = false
	gamepad_button.disabled = false

	if _changed_action == action_name:
		value_changed.emit()


func _on_keyboard_button_pressed() -> void:
	binding_requested.emit(action_name, &"keyboard")


func _on_gamepad_button_pressed() -> void:
	binding_requested.emit(action_name, &"gamepad")


func _display_title() -> String:
	if not display_name.is_empty():
		return display_name
	return String(action_name).capitalize()
