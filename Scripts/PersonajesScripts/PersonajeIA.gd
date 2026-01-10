class_name PersonajeIA
extends CharacterBody3D

enum State { FOLLOW, RETURNING }
var state := State.FOLLOW

@export var pj_nombre: String = "???"
@export var speed: float = 3.0
@export var follow_distance: float = 1.8
@export var max_distance_from_kosmo: float = 8.0
@export var follow_delay: float = 0.6
@export var usa_flip_x: bool = true

var follow_enabled := true

var kosmo: Node3D
var target_position: Vector3

var gravity := -9.8
var vertical_velocity := 0.0
var max_fall_speed := 1.0

var last_direction := "_down"

var update_timer := 0.0
var update_interval := 0.25

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_sprite: AnimatedSprite3D = $AnimatedSprite3D


# ----------------------------------------------------
# Ready
# ----------------------------------------------------
func _ready():
	await get_tree().process_frame
	asignar_kosmo()

	await get_tree().physics_frame 

	if kosmo == null:
		push_warning("%s no encontró a Astro" % pj_nombre)
		return

	target_position = kosmo.global_position
	nav_agent.target_position = target_position

	
	anim_sprite.play("idle_down")


# ----------------------------------------------------
# Physics
# ----------------------------------------------------
func _physics_process(delta):
	if not follow_enabled or kosmo == null:
		return

	match state:
		State.FOLLOW:
			_follow_kosmo(delta)
		State.RETURNING:
			_return_to_kosmo(delta)

	_evitar_colision_equipo()


# ----------------------------------------------------
# Follow behavior
# ----------------------------------------------------
func _follow_kosmo(delta):
	var dist = global_position.distance_to(kosmo.global_position)
	# Target deseado: posición del player (sin rotación)
	var desired_target := kosmo.global_position

	var smooth_factor := 6.0
	target_position = target_position.lerp(
		desired_target,
		delta * smooth_factor
	)

	nav_agent.target_position = target_position

	# Si está demasiado lejos → modo recuperación
	if dist > max_distance_from_kosmo * 1.2:
		state = State.RETURNING
		return

	_move_to_target(delta)


# ----------------------------------------------------
# Returning behavior
# ----------------------------------------------------
func _return_to_kosmo(delta):
	nav_agent.target_position = kosmo.global_position
	_move_to_target(delta)

	if global_position.distance_to(kosmo.global_position) <= follow_distance:
		state = State.FOLLOW


# ----------------------------------------------------
# Movement
# ----------------------------------------------------
func _move_to_target(delta):
	var dist_to_target = global_position.distance_to(target_position)

	# Si ya está lo suficientemente cerca → se frena suave
	if dist_to_target < follow_distance * 0.7:
		velocity = velocity.lerp(Vector3.ZERO, delta * 4)

		move_and_slide()
		_update_animation(Vector3.ZERO)
		return

	nav_agent.target_position = target_position

	if nav_agent.is_navigation_finished():
		velocity = velocity.lerp(Vector3.ZERO, delta * 8)
		move_and_slide()
		_update_animation(Vector3.ZERO)
		return

	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()

	var horizontal_velocity = Vector3(dir.x, 0, dir.z) * speed

	# Variación sutil para evitar movimiento robótico
	horizontal_velocity *= randf_range(0.95, 1.05)

	# Gravedad
	if not is_on_floor():
		vertical_velocity = clamp(
			vertical_velocity + gravity * delta,
			-max_fall_speed,
			max_fall_speed
		)
	else:
		vertical_velocity = 0.0

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = vertical_velocity

	var min_speed := 0.15
	if horizontal_velocity.length() < min_speed:
		horizontal_velocity = horizontal_velocity.normalized() * min_speed

	move_and_slide()
	_update_animation(horizontal_velocity)


# ----------------------------------------------------
# Animation
# ----------------------------------------------------
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
		anim_sprite.flip_h = false
		anim_sprite.play("walk" + last_direction)

# ----------------------------------------------------
# Team collision avoidance
# ----------------------------------------------------
func _evitar_colision_equipo():
	var empuje_total := Vector3.ZERO
	var personajes = get_tree().get_nodes_in_group("equipo")

	for otro in personajes:
		if otro == self or not otro is CharacterBody3D:
			continue

		var diff = global_position - otro.global_position
		var dist = diff.length()
		if dist == 0:
			continue

		var min_dist := 1.0
		if dist < min_dist:
			var fuerza = (min_dist - dist) * 0.4
			if otro.name == "Player":
				fuerza *= 2.0
			empuje_total += diff.normalized() * fuerza

	if empuje_total != Vector3.ZERO:
		global_position = global_position.lerp(
			global_position + empuje_total,
			0.5
		)


# ----------------------------------------------------
# Utils
# ----------------------------------------------------
func asignar_kosmo():
	var escena = get_tree().get_current_scene()
	kosmo = _buscar_player(escena)

func _buscar_player(nodo: Node) -> Node3D:
	if nodo.name == "Player":
		return nodo
	for hijo in nodo.get_children():
		var resultado = _buscar_player(hijo)
		if resultado != null:
			return resultado
	return null