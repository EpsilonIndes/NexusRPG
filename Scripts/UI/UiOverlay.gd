# UIOverlay.gd (En Nodo)
extends CanvasLayer

@onready var technique_overlay := $TechniqueOverlay
@onready var target_selector := $TargetSelector
@onready var drive_score_feedback := get_node_or_null("DriveScoreFeedback")


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
	if not is_instance_valid(technique_overlay):
		return

	if technique_overlay.has_method("set_interactive"):
		technique_overlay.set_interactive(valor)
		return

	for child in technique_overlay.get_children():
		if child.has_method("set_interactive"):
			child.set_interactive(valor)
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if valor else Control.MOUSE_FILTER_IGNORE

func clear_tecnicas() -> void:
	if not is_instance_valid(technique_overlay):
		return

	if technique_overlay.has_method("clear_techniques"):
		technique_overlay.clear_techniques()
		return

	technique_overlay.visible = false
	for child in technique_overlay.get_children():
		child.queue_free()


func queue_drive_update(data: Dictionary) -> void:
	if drive_score_feedback != null and drive_score_feedback.has_method("queue_drive_update"):
		drive_score_feedback.queue_drive_update(data)


func show_pending_drive_feedback() -> void:
	if drive_score_feedback != null and drive_score_feedback.has_method("show_pending_drive_feedback"):
		drive_score_feedback.show_pending_drive_feedback()


func flush_drive_feedback() -> void:
	show_pending_drive_feedback()
