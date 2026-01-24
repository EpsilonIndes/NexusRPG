# UIOverlay.gd (En Nodo)
extends CanvasLayer

@onready var technique_overlay := $TechniqueOverlay
@onready var target_selector := $TargetSelector


# BattleManager envia un diccionario con los candidatos y el callback propio para continuar el flujo de turnos
# El diccionario tiene forma:
	# targets_data = {"enemies": Array, "allies": Array, "default_group": String}
# y el Callback:
	# Callable(self, "_on_target_selected")

func open_target_selector(targets_data: Dictionary, callback: Callable, cancel_callback: Callable) -> void: # targets_data: Dictionary, el callback
	print("Targets recibidos: ", targets_data)
	
	set_tecnicas_interactivas(false)
	
	if target_selector == null:
		target_selector = preload("res://Escenas/Battle/battle_ui/target_selector.tscn").instantiate()
		add_child(target_selector)
		
	if not is_instance_valid(target_selector):
		push_error("TargetSelector NO válido")
		return
	
	target_selector.visible = true
	target_selector.open(targets_data, callback, cancel_callback)

func set_tecnicas_interactivas(valor: bool) -> void:
	if technique_overlay and technique_overlay.has_method("set_interactive"):
		technique_overlay.set_interactive(valor)
		

