extends PersonajeIA

var tiempo_observando := 0.0
const TIEMPO_OBSERVAR_MAX := 2.5
var esta_observando := false

func _custom_ready():
	pj_nombre = "Amanda"
	usa_flip_x = false
	if kosmo:
		print("%s encontró a Kosmo." % pj_nombre)

func _can_explore() -> bool:
	return randf() < 0.7 and not esta_observando

func _get_explore_offset() -> Vector3:
	var angle = randf() * TAU
	var radio = explore_radius * 0.8
	return Vector3(cos(angle), 0, sin(angle)) * radio

func _explore_area(delta):
	if esta_observando:
		tiempo_observando += delta
		if tiempo_observando >= TIEMPO_OBSERVAR_MAX:
			print("%s termina de observar el area." % pj_nombre)
			esta_observando = false
			state = State.RETURNING
		return
	
	# Se detiene si llegó a su destino
	if global_position.distance_to(target_position) < 1.0:
		esta_observando = true
		tiempo_observando = 0.0
		velocity = Vector3.ZERO
		_update_animation(Vector3.ZERO)
		print("%s está inspeccionando el área..." % pj_nombre)
	else:
		_move_to_target(delta)