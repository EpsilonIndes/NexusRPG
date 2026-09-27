# character_slot.gd (Nodo)
extends Button

var character_id: String = ""

@onready var name_label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var level_label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var portrait = $PanelContainer/MarginContainer/HBoxContainer/TextureRect

var is_selected: bool = false
@onready var summary_label: Label = get_node_or_null("PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/Summary")

func set_character(char_id: String, char_data, show_summary: bool = false):
	character_id = char_id
	name_label.text = char_id
	portrait.texture = CharacterFaces.FACE_TEXTURES.get(char_id)

	if char_data and char_data.stats:
		var stats = char_data.stats
		level_label.text = "Lv " + str(int(stats.get("nivel", 1)))
	else:
		level_label.text = "Lv ???"
	if show_summary:
		_show_summary(char_data.stats if char_data else {})
	elif is_instance_valid(summary_label):
		summary_label.hide()

func _show_summary(stats: Dictionary) -> void:
	if not is_instance_valid(summary_label): return
	summary_label.show()
	var hp := int(stats.get("hp", 0))
	summary_label.text = "HP %d / %d    DP %d / %d\nATQ %d · DEF %d · VEL %d%s" % [
		hp, int(stats.get("max_hp", hp)), int(stats.get("dp", 0)), int(stats.get("max_dp", 0)),
		int(stats.get("atk", 0)), int(stats.get("def", 0)), int(stats.get("spd", 0)),
		"\nFuera de combate" if hp <= 0 else ""]

func set_selected(value: bool):
	is_selected = value

	if value:
		add_theme_color_override("font_color", Color.WHITE)
		add_theme_color_override("font_color_focus", Color.WHITE)
	else:
		remove_theme_color_override("font_color")
		remove_theme_color_override("font_color_focus")
