extends CanvasLayer

var tech_buttons: Array = []
var interactivo: bool = true
var mouse_filter
const ACTIVE_ALPHA := 1.0
const INACTIVE_ALPHA := 0.35

func _ready():
	add_to_group("technique_overlay")

func _set_children_alpha(alpha: float) -> void:
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = alpha

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
	visible = true
	_set_children_alpha(ACTIVE_ALPHA if valor else INACTIVE_ALPHA)

	mouse_filter = Control.MOUSE_FILTER_STOP if valor else Control.MOUSE_FILTER_IGNORE

	for btn in tech_buttons:
		if not is_instance_valid(btn):
			continue
		btn.disabled = not valor
		btn.mouse_filter = Control.MOUSE_FILTER_STOP if valor else Control.MOUSE_FILTER_IGNORE

	if has_node("TechButtonCircle"):
		$TechButtonCircle.set_interactive(valor)

func clear_techniques() -> void:
	interactivo = false
	visible = false
	_set_children_alpha(ACTIVE_ALPHA)
	tech_buttons.clear()

	for child in get_children():
		child.queue_free()
