class_name PersonajeIA
extends CharacterBody3D

enum State {FOLLOW, EXPLORE, RETURNING}
var state = State.FOLLOW

# Cosas configurables
@export var pj_nombre: String = "???"
@export var speed: float = 4.0
@export var follow_distance: float = 1.5
@export var explore_radius: float = 5.0
@export var max_distance_from_kosmo: float = 5.0
@export var usa_flip_x: bool
var kosmo_path: NodePath = NodePath("Player")
var kosmo: Node3D
var target_position: Vector3
var last_direction: String = "_down"

var gravity: float = -1.0
var max_fall_speed: float = 1.0
var vertical_velocity: float = 0.0


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	await get_tree().process_frame
	asignar_kosmo()
	if kosmo == null:
		print("%s no encontró a Kosmo" % pj_nombre)
		return
		
	_custom_ready()  # Llamada a método virtual para personalización
	
	# Inicializar el personaje
	target_position = global_position
	anim_sprite.play("idle_down")
	last_direction = "_down"

func _physics_process(delta):
	if kosmo == null:
		return
	
	match state:
		State.FOLLOW:
			_follow_kosmo(delta)
		State.EXPLORE:
			_explore_area(delta)
		State.RETURNING:
			_return_to_kosmo(delta)
	
	_check_state_transition()

# Métodos virtuales (Las clases hijas deben sobreescribirlas o crear métodos propios)
func _custom_ready():
	pass
func _can_explore() -> bool:
	return true
func _get_explore_offset() -> Vector3:
	var angle = randf() * TAU
	return Vector3(cos(angle), 0, sin(angle)) * explore_radius

# -- Comportamientos base --
func _follow_kosmo(delta):
	var distance = global_position.distance_to(kosmo.global_position)
	if distance > follow_distance:
		nav_agent.target_position = kosmo.global_position
		_move_to_target(delta)
	else:
		velocity = Vector3.ZERO
		_update_animation(Vector3.ZERO)

func _explore_area(delta):
	_move_to_target(delta)
	if global_position.distance_to(target_position) < 1.0:
		state = State.RETURNING

func _return_to_kosmo(delta):
	nav_agent.target_position = kosmo.global_position
	_move_to_target(delta)
	if global_position.distance_to(kosmo.global_position) < follow_distance:
		state = State.FOLLOW

func _check_state_transition():
	if state == State.FOLLOW and randf() < 0.005 and _can_explore():
		if global_position.distance_to(kosmo.global_position) < follow_distance:
			target_position = kosmo.global_position + _get_explore_offset()
			nav_agent.target_position = target_position
			state = State.EXPLORE

		elif state == State.EXPLORE and global_position.distance_to(kosmo.global_position) > max_distance_from_kosmo:
			state = State.RETURNING

		elif state == State.FOLLOW and randf() < 0.005 and _can_explore():
			if global_position.distance_to(kosmo.global_position) < follow_distance:
				target_position = kosmo.global_position + _get_explore_offset()
				nav_agent.target_position = target_position
				state = State.EXPLORE
		
		if state == State.RETURNING and global_position.distance_to(kosmo.global_position) < follow_distance:
			state = State.FOLLOW

		
func _move_to_target(delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		_update_animation(Vector3.ZERO)
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	# Movimiento horizontal
	var horizontal_velocity = Vector3(direction.x, 0, direction.z) * speed

	# Gravedad (solo si no esta en el piso)
	if not is_on_floor():
		vertical_velocity += gravity * delta
	else:
		vertical_velocity = 0.0
	
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = vertical_velocity

	_update_animation(horizontal_velocity)
	move_and_slide()

func _update_animation(move_vector: Vector3):
	if move_vector.length() < 0.1:
		anim_sprite.play("idle" + last_direction)
		return

	if abs(move_vector.x) > abs(move_vector.z):
		if usa_flip_x:
			anim_sprite.flip_h = move_vector.x < 0
			last_direction = "_side"
			anim_sprite.play("walk" + last_direction)
		else:
			last_direction = "_left" if move_vector.x < 0 else "_right"
			anim_sprite.play("walk" + last_direction)

	else:
		last_direction = "_down" if move_vector.z > 0 else "_up"
		anim_sprite.play("walk" + last_direction)
		anim_sprite.flip_h = false

func asignar_kosmo():
	var escena = get_tree().get_current_scene()
	kosmo = buscar_player(escena)
	if kosmo == null:
		push_warning("%s no encontró a Kosmo automáticamente" % pj_nombre)
func buscar_player(nodo: Node) -> Node3D:
	if nodo.name == "Player":
		return nodo
	for hijo in nodo.get_children():
		if hijo is Node:
			var resultado = buscar_player(hijo)
			if resultado != null:
				return resultado
	return null