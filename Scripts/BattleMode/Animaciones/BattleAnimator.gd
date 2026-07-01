extends Node

signal animation_started
signal animation_finished
signal animation_impact(source, targets, data)
signal queue_empty

@onready var container: Node = $AnimationContainer

var animation_queue: Array = []
var is_playing: bool = false
var speed_multiplier: float = 1.0
var current_battle_manager: Node = null
var current_source = null
var current_targets: Array = []
var current_data: Dictionary = {}


func play(animation_scene: PackedScene, source, targets, data := {}):
	var request = {
		"scene": animation_scene,
		"source": source,
		"targets": targets,
		"data": data
	}

	animation_queue.append(request)
	_try_play_next()

func clear_queue():
	animation_queue.clear()

func set_speed(multiplier: float):
	speed_multiplier = multiplier

func _try_play_next():
	if is_playing:
		return
	
	if animation_queue.is_empty():
		emit_signal("queue_empty")
		return
	
	is_playing = true
	var request = animation_queue.pop_front()
	_execute(request)
	

func _execute(request: Dictionary) -> void:
	print("Instanciando animación...")
	var anim = request.scene.instantiate()
	print("Anim instanciada: ", anim)
	current_battle_manager = request.data.get("battle_manager", null)
	current_source = request.source
	current_targets = request.targets
	current_data = request.data

	if anim.has_signal("impact"):
		anim.connect("impact", Callable(self, "_on_animation_impact"))
	
	container.add_child(anim)

	if anim.has_method("setup"):
		anim.setup(request.source, request.targets, request.data)
	
	if anim.has_method("set_speed"):
		anim.set_speed(speed_multiplier)		

	emit_signal("animation_started")

	if anim.has_method("play"):
		anim.play()
	
	# Esperar señal FInished
	if anim.has_signal("finished"):
		await anim.finished
	else:
		await get_tree().process_frame
	
	if anim.has_signal("impact") and anim.is_connected("impact", Callable(self, "_on_animation_impact")):
		anim.disconnect("impact", Callable(self, "_on_animation_impact"))
	
	anim.queue_free()
	current_battle_manager = null
	current_source = null
	current_targets = []
	current_data = {}

	emit_signal("animation_finished")
	is_playing = false
	_try_play_next()

func _on_animation_impact(targets):
	var impact_source = current_source
	var impact_targets = targets.duplicate() if targets is Array else targets
	var impact_data = current_data.duplicate(true)

	for t in targets:
		if is_instance_valid(t) and t.has_method("reproducir_feedback"):
			t.reproducir_feedback()

	if current_battle_manager != null and is_instance_valid(current_battle_manager) and current_battle_manager.has_method("flush_drive_feedback"):
		current_battle_manager.flush_drive_feedback()

	await get_tree().process_frame
	emit_signal("animation_impact", impact_source, impact_targets, impact_data)
