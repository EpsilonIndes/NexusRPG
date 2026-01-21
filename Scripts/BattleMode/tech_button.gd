extends TextureButton

signal tecnica_seleccionada(tecnica_id: String)

var tecnica_id: String
var battle_manager: Node = null
func _ready():
	pressed.connect(_on_pressed)
	
	var overlays = get_tree().get_nodes_in_group("technique_overlay")
	if overlays.size() > 0:
		overlays[0].register_button(self)

func _on_pressed():
	
	emit_signal("tecnica_seleccionada", tecnica_id)

func _exit_tree() -> void:
	var overlays = get_tree().get_nodes_in_group("technique_overlay")
	if overlays.size() > 0:
		overlays[0].unregister_button(self)