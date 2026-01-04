extends CanvasLayer

@onready var technique_overlay := $TechniqueOverlay
@onready var target_selector := $TargetSelector


func open_target_selector(candidatos: Array, callback: Callable) -> void:
	if target_selector == null:
		target_selector = preload("res://Escenas/Battle/battle_ui/target_selector.tscn").instantiate()
		add_child(target_selector)
		
	if not is_instance_valid(target_selector):
		push_error("TargetSelector NO válido")
		return
	target_selector.visible = true
	target_selector.open(candidatos, callback)

func set_tecnicas_interactivas(valor: bool) -> void:
	if technique_overlay and technique_overlay.has_method("set_interactive"):
		technique_overlay.set_interactive(valor)