extends HBoxContainer


@export var category: String
@export var key: String
@export var show_percentage: bool = true

@onready var category_label := $Label_Name
@onready var slider := $Slider
@onready var value_label := $Label_Value
@onready var texture_rect := $TextureRect

const SOUND_TEXTURE := {
	"master": preload("res://Assets/UIX/master_uix.png"),
	"sfx": preload("res://Assets/UIX/sfx_uix.png"),
	"music": preload("res://Assets/UIX/music_uix.png")
}

var apply_on_change: bool = true

func _ready():
	slider.value_changed.connect(_on_slider_value_changed)
	await get_tree().process_frame
	

func setup():
	var value = SettingsManager.get_setting(category, key)
	if value == null:
		return
	
	apply_on_change = false
	slider.value = value * 100.0
	apply_on_change = true
	print("OptionRow key:", key)

	texture_rect.texture = SOUND_TEXTURE.get(key)
	category_label.text = str(key).capitalize()
	_update_label()

func _on_slider_value_changed(v: float) -> void:
	var normalized := v * 0.01
	SettingsManager.set_setting(category, key, normalized)

	if apply_on_change:
		SettingsManager.apply_audio()

	_update_label()


func _update_label():
	if show_percentage:
		value_label.text = str(int(slider.value)) + "%"
	else:
		value_label.text = str(slider.value)
	
