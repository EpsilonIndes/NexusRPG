extends Control

@onready var margin_container : MarginContainer = $"MarginContainer"
@onready var opciones_ui = $"CanvasLayer/OpcionesUI"
@onready var play_button = $"MarginContainer/VBoxContainer/Play"
@onready var options_button = $"MarginContainer/VBoxContainer/Options"
@onready var exit_button = $"MarginContainer/VBoxContainer/Exit"
@onready var load_button: Button = $MarginContainer/VBoxContainer/Load
@onready var save_slots = $CanvasLayer/SaveSlotsUI

func _ready() -> void:
	if not opciones_ui.closed.is_connected(_on_options_closed):
		opciones_ui.closed.connect(_on_options_closed)
	play_button.grab_focus()
	load_button.pressed.connect(_on_load_pressed)
	save_slots.closed.connect(_on_saves_closed)
	load_button.disabled = SaveManager.get_existing_slots().is_empty()
	DeviceManager.presentation_changed.connect(_update_presentation)
	_update_presentation()

func _update_presentation() -> void:
	var mobile := DeviceManager.mobile_layout or DeviceManager.uses_touch()
	var side_margin := int(get_viewport_rect().size.x * 0.12) if mobile else 400
	margin_container.add_theme_constant_override("margin_left", side_margin)
	margin_container.add_theme_constant_override("margin_right", side_margin)
	for button in [play_button, load_button, options_button, exit_button]:
		button.custom_minimum_size.y = 64 if mobile else 0
	if margin_container.visible and DeviceManager.input_method == DeviceManager.InputMethod.GAMEPAD:
		if get_viewport().gui_get_focus_owner() == null:
			play_button.grab_focus()

func _on_load_pressed() -> void:
	margin_container.hide()
	save_slots.open()

func _on_saves_closed() -> void:
	margin_container.show()
	load_button.disabled = SaveManager.get_existing_slots().is_empty()
	if load_button.disabled:
		play_button.grab_focus()
	else:
		load_button.grab_focus()

func _on_play_pressed() -> void:
	GameManager.start_game()


func _on_options_pressed() -> void:
	margin_container.visible = false
	opciones_ui.open()


func _on_options_closed() -> void:
	margin_container.visible = true
	play_button.grab_focus()


func _on_exit_pressed() -> void:
	get_tree().quit()
