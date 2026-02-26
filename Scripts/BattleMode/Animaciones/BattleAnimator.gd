extends Node

signal animation_started
signal animation_finished
signal queue_empty

@onready var container: Node = $AnimationContainer

var animation_queue: Array = []
var is_playing: bool = false
var speed_multiplier: float = 1.0


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
	
	if anim.is_connected("impact", Callable(self, "_on_animation_impact")):
		anim.disconnect("impact", Callable(self, "_on_animation_impact"))
	
	anim.queue_free()

	emit_signal("animation_finished")
	is_playing = false
	_try_play_next()

func _on_animation_impact(targets):
	for t in targets:
		if is_instance_valid(t) and t.has_method("reproducir_feedback"):
			t.reproducir_feedback()
