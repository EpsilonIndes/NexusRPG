# character_slot.gd (Nodo)
extends Button

var character_id: String = ""

@onready var name_label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var level_label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var portrait = $PanelContainer/MarginContainer/HBoxContainer/TextureRect

var is_selected: bool = false

func set_character(char_id: String, char_data):
	character_id = char_id
	name_label.text = char_id
	portrait.texture = CharacterFaces.FACE_TEXTURES.get(char_id)

	if char_data and char_data.stats:
		var stats = char_data.stats
		level_label.text = "Lv " + str(int(stats.get("nivel", 1)))
	else:
		level_label.text = "Lv ???"

func _pressed() -> void:
	emit_signal("pressed")

func set_selected(value: bool):
	is_selected = value

	if value:
		add_theme_color_override("font_color", Color.WHITE)
		add_theme_color_override("font_color_focus", Color.WHITE)
	else:
		remove_theme_color_override("font_color")
		remove_theme_color_override("font_color_focus")
