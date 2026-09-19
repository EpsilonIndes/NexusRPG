extends ScrollContainer
## Touch presentation only; SaveSlotsUI owns all save/load/delete behavior.
signal activated(index: int)
signal delete_requested(index: int)
var _rows: VBoxContainer

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	add_child(_rows)

func rebuild(source: ItemList) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for index in source.item_count:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_rows.add_child(row)
		var button := Button.new()
		button.text = source.get_item_text(index)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 80
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): activated.emit(index))
		row.add_child(button)
		var kind: String = source.get_item_metadata(index)
		if kind not in ["new", "back"]:
			var delete_button := Button.new()
			delete_button.text = "Eliminar"
			delete_button.custom_minimum_size = Vector2(112, 80)
			delete_button.focus_mode = Control.FOCUS_NONE
			delete_button.pressed.connect(func(): delete_requested.emit(index))
			row.add_child(delete_button)
