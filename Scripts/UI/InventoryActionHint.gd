extends HBoxContainer
## Presentation only: the inventory supplies captions and listens for activation.
signal activated

func configure(key: String, caption: String) -> void:
	$Keycap/Glyph.text = key
	$Caption.text = caption

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		activated.emit()
