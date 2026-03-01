extends HBoxContainer

signal value_changed

@export var key: String
@onready var label: Label = $Label_Tittle
@onready var option_button: OptionButton = $OptionButton

var _ignore_signal := false


func _ready():
	option_button.focus_mode = Control.FOCUS_ALL
	option_button.item_selected.connect(self._on_item_selected)


func setup():
	_populate_options()

	var value = SettingsManager.get_setting("graphics", key)
	if value == null:
		label.text = key.capitalize()
		return

	_ignore_signal = true
	_select_value(value)
	_ignore_signal = false
	
	label.text = key.capitalize()

func _populate_options():
	option_button.clear()

	match key:
		"preset":
			_add_item("Bajo", 0)
			_add_item("Medio", 1)
			_add_item("Alto", 2)
			_add_item("Ultra", 3)
			_add_item("Personalizado", 4)

		"shadows":
			_add_item("Off", 0)
			_add_item("Basic", 1)
			_add_item("High", 2)

		"lighting":
			_add_item("Disabled", false)
			_add_item("Enabled", true)

		"postprocess":
			_add_item("Off", 0)
			_add_item("Basic", 1)
			_add_item("Full", 2)

		"particles":
			_add_item("Low", 0)
			_add_item("Medium", 1)
			_add_item("High", 2)

		"camera_shake":
			_add_item("Off", false)
			_add_item("On", true)

func _add_item(text: String, metadata):
	var index = option_button.get_item_count()
	option_button.add_item(text)
	option_button.set_item_metadata(index, metadata)

func _select_value(value):
	for i in range(option_button.get_item_count()):
		if option_button.get_item_metadata(i) == value:
			option_button.select(i)
			return

func _on_item_selected(index: int):
	if _ignore_signal:
		return

	var value = option_button.get_item_metadata(index)

	if key == "preset":
		# Aplicamos preset completo
		var new_settings = GraphicsController.apply_preset(value)
		SettingsManager.settings["graphics"] = new_settings
	else:
		# Cambia solo una opción
		SettingsManager.set_setting("graphics", key, value)
		
		# Detectamos si coincide con preset
		var graphics = SettingsManager.settings["graphics"]
		var detected = GraphicsController.detect_matching_preset(graphics)
		SettingsManager.settings["graphics"]["preset"] = detected

	emit_signal("value_changed")