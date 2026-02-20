extends HBoxContainer

signal value_changed

@export var category: String
@export var key: String

@onready var control: Control = null
@onready var label: Label = $Label_Tittle

var _ignore_signal: bool = false


func _ready():
	for child in get_children():
		if child is CheckBox or child is OptionButton:
			control = child
			break

	control.focus_mode = Control.FOCUS_ALL

	if control is CheckBox:
		control.toggled.connect(_on_check_box_toggled)
	
	elif control is OptionButton:
		_populate_options()
		control.item_selected.connect(_on_option_selected)
		control.focus_mode = Control.FOCUS_ALL
	
	
	control.focus_entered.connect(func():
		print("FOCUS ENTRÓ EN:", control.name)
	)
	

func setup() -> void:
	var value = SettingsManager.get_setting(category, key)
	if value == null:
		return
	
	_ignore_signal = true
	_apply_value_to_control(value)
	_ignore_signal = false
	label.text = key.capitalize()


func _on_check_box_toggled(pressed: bool):
	if _ignore_signal:
		return
	SettingsManager.set_setting(category, key, pressed)
	emit_signal("value_changed")

func _on_option_selected(index: int):
	if _ignore_signal:
		return
	var value = control.get_item_metadata(index)
	SettingsManager.set_setting(category, key, value)
	emit_signal("value_changed")

func _apply_value_to_control(value):
	if control is CheckBox:
		control.button_pressed = value	
	elif control is OptionButton:
		value = clamp(value, 0, control.item_count - 1)
		control.select(value)

func _populate_options():
	control.clear()
	
	match key:
		"resolution":
			_populate_resolutions()
		"display_mode":
			_populate_displaymode()
		"scaling":
			_populate_scaling()
		_:
			push_warning("OptionRow_Video: Key no soportada -> %s" % key)

func _populate_resolutions():
	for i in SettingsManager.RESOLUTIONS.size():
		var r = SettingsManager.RESOLUTIONS[i]
		control.add_item("%d x %d" % [r.x, r.y])
		control.set_item_metadata(i, i)

func _populate_displaymode():
	control.add_item("Windowed")
	control.set_item_metadata(0, 0)

	control.add_item("Fullscreen")
	control.set_item_metadata(1, 1)

func _populate_scaling():
	control.add_item("None")
	control.set_item_metadata(0, 0)

	control.add_item("Keep Aspect")
	control.set_item_metadata(1, 1)

	control.add_item("Stretch")
	control.set_item_metadata(2, 2)
