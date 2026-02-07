extends Button

signal stat_selected(stat_key: String)
signal stat_focused(stat_key: String)

var stat_key := ""

@onready var name_label := $StatName
@onready var value_label = $StatValue

func set_stat(key: String, value):
	stat_key = key
	name_label.text = key.capitalize()
	value_label.text = str(value)

func _pressed() -> void:
	emit_signal("stat_selected", stat_key)

func _focus_entered():
	emit_signal("stat_focused", stat_key)
