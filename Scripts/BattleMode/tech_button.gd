extends TextureButton

signal tecnica_seleccionada(tecnica_id: String)

var tecnica_id: String

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	emit_signal("tecnica_seleccionada", tecnica_id)
