extends HBoxContainer

@export var category: String
@export var key: String

@onready var control: Control = $Control
@onready var label: Label = $Label_Tittle

var _ignore_signal: bool = false


func _ready():
	assert(control is CheckBox or control is OptionButton)

	if control is CheckBox:
		control.toggled.connect(_on_check_box_toggled)
	
	elif control is OptionButton:
		_populate_options()
		control.item_selected.connect(_on_option_selected)
		control.focus_mode = Control.FOCUS_ALL


func setup() -> void:
	var value = SettingsManager.get_setting(category, key)
	if value == null:
		return
	
	_ignore_signal = true
	_apply_value_to_control(value)
	_ignore_signal = false


func _on_check_box_toggled(pressed: bool):
	if _ignore_signal:
		return
	SettingsManager.set_setting(category, key, pressed)


func _on_option_selected(index: int):
	if _ignore_signal:
		return
	var value = control.get_item_metadata(index)
	SettingsManager.set_setting(category, key, value)


func _apply_value_to_control(value):
	if control is CheckBox:
		control.button_pressed = value
	
	elif control is OptionButton:
		if value < 0 or value >= control.item_count:
			push_warning("[OptionButton %s] Índice %d fuera de rango (items: %d)" % [name, value, control.item_count])
			return
		elif control is OptionButton:
			value = clamp(value, 0, control.item_count - 1)
			control.select(value)

func _populate_options():
	control.clear()
	control.add_item("640 x 480")
	control.add_item("1024 x 680")
	control.add_item("1280 x 720")
	control.add_item("1366 x 780")
	control.add_item("1920 x 1080")
	control.add_item("2560 x 1440")
	control.add_item("3840 x 2160")