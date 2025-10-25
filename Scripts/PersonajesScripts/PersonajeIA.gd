class_name PersonajeIA
extends CharacterBody3D

enum State {FOLLOW, RETURNING}
var state = State.FOLLOW

# Cosas configurables
@export var pj_nombre: String = "???"
@export var speed: float = 3.0
@export var follow_distance: float = 2.0
@export var max_distance_from_kosmo: float = 8.0
@export var usa_flip_x: bool
@export var formation_offset: Vector3 = Vector3.ZERO

var kosmo_path: NodePath = NodePath("Player")
var kosmo: Node3D
var target_position: Vector3
var gravity: float = -9.8
var vertical_velocity: float = 0.0
var max_fall_speed: float = 1.0
var last_direction: String = "_down"

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	await get_tree().process_frame
	asignar_kosmo()
	if kosmo == null:
		print("%s no encontró a Astro" % pj_nombre)
		return

	target_position = global_position
	_custom_ready()  # Llamada a método virtual para personalización
	anim_sprite.play("idle_down")

func _physics_process(delta):
	if kosmo == null:
		return
	
	match state:
		State.FOLLOW:
			_follow_kosmo(delta)
		State.RETURNING:
			_return_to_kosmo(delta)
	
	_check_state_transition()

# Personalizacion y asignación
func _custom_ready():
	pass

func asignar_kosmo():
	var escena = get_tree().get_current_scene()
	kosmo = buscar_player(escena)
	if kosmo == null:
		push_warning("%s no encontró a Astro automáticamente" % pj_nombre)

func buscar_player(nodo: Node) -> Node3D:
	if nodo.name == "Player":
		return nodo
	for hijo in nodo.get_children():
		if hijo is Node:
			var resultado = buscar_player(hijo)
			if resultado != null:
				return resultado
	return null


# -- Comportamientos base --
func _follow_kosmo(delta):
	var dist = global_position.distance_to(kosmo.global_position)

	# Direccion virtual del jugador
	var forward_dir: Vector3
	if "look_direction" in kosmo:
		forward_dir = kosmo.look_direction.normalized()
	else:
		forward_dir = Vector3(forward_dir.z, 0, -forward_dir.x).normalized()

	var right_dir = Vector3(forward_dir.z, 0, -forward_dir.x).normalized()

	var rotated_offset = right_dir * formation_offset.x + forward_dir * formation_offset.z
	
	var target_pos = kosmo.global_position + rotated_offset

	# Si está muy lejos, pasa a RETURNING
	if dist > max_distance_from_kosmo:
		state = State.RETURNING
		return

	# Actualizamos el objetivo de navegación
	nav_agent.target_position = target_pos
	_move_to_target(delta)

func _return_to_kosmo(delta):
	nav_agent.target_position = kosmo.global_position
	_move_to_target(delta)

	if global_position.distance_to(kosmo.global_position) < follow_distance:
		state = State.FOLLOW

func _check_state_transition():
	if state == State.RETURNING and global_position.distance_to(kosmo.global_position) < follow_distance:
		state = State.FOLLOW

# Movimiento y animaciones

func _move_to_target(delta):
	if nav_agent.is_navigation_finished():
		velocity = velocity.lerp(Vector3.ZERO, delta * 8)
		move_and_slide()
		_update_animation(Vector3.ZERO)
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	var horizontal_velocity = Vector3(dir.x, 0, dir.z) * speed

	# Gravedad (solo si no esta en el piso)
	if not is_on_floor():
		vertical_velocity += clamp(vertical_velocity + gravity * delta, -max_fall_speed, max_fall_speed)
	else:
		vertical_velocity = 0.0
	
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = vertical_velocity

	move_and_slide()
	_update_animation(horizontal_velocity)
	
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