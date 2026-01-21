extends CanvasLayer

var tech_buttons: Array = []
var interactivo: bool = true
var mouse_filter

func _ready():
	add_to_group("technique_overlay")

func register_button(btn: Control) -> void:
	if not tech_buttons.has(btn):
		print("Registrando botón de técnica: ", btn)
		tech_buttons.append(btn)
	
func unregister_button(btn: Control) -> void:
	print("Desregistrando botón de técnica: ", btn)
	tech_buttons.erase(btn)
	
func set_interactive(valor: bool) -> void:
	print("[TechniqueOverlay] Seteando interactive: ", valor)
	interactivo = valor

	mouse_filter = Control.MOUSE_FILTER_STOP if valor else Control.MOUSE_FILTER_IGNORE

	for btn in tech_buttons:
		if not is_instance_valid(btn):
			continue
		btn.disabled = not valor
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if valor else Control.MOUSE_FILTER_IGNORE

	if has_node("TechButtonCircle"):
		$TechButtonCircle.set_interactive(valor)