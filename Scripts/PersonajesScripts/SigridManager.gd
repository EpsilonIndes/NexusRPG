extends CharacterBody3D

enum State {
	FOLLOW,
	EXPLORE,
	RETURNING
}

var state = State.FOLLOW

var last_direction = "_down"
@export var kosmo_path: NodePath
var kosmo: Node3D = null
@export var side_offset: float = 1.5 # Positivo para la derecha, negativo para la izquierda
var lateral_side: int = 1 # 1 para la derecha, -1 para la izquierda
var side_timer := 0.0 # Temporizador para el movimiento lateral
@onready var nav_agent = $NavigationAgent3D
@onready var anim_sprite = $AnimatedSprite3D
@export var speed: float = 100.0

const SIDE_SWITCH_INTERVAL := 10.0 # Cambia cada 10 segundos aproximadamente
const FOLLOW_DISTANCE = 1.5
const EXPLORE_RADIUS = 2.0
const MAX_DISTANCE_FROM_KOSMO = 3.0  # Menor distancia máxima
const EXPLORE_CHANCE = 0.002  # Menor probabilidad de explorar
var target_position: Vector3 = Vector3.ZERO

func _ready():
	if kosmo_path:
		kosmo = get_node(kosmo_path)
	else:
		print("Sigrid busca a Kosmo automáticamente...")
		kosmo = get_node("../Player")
	
	if kosmo:
		print("Sigrid localizó a Kosmo. No es que le importe ni nada...")
	else:
		print("Sigrid no encontró a Kosmo. Típico.")

	if not nav_agent.is_navigation_finished() and nav_agent.get_navigation_map() == null:
		print("Esperando que se sincronice el mapa de navegación...")
		return
	
	await get_tree().process_frame
	await get_tree().process_frame


func _physics_process(delta):
	if !kosmo:
		print("¡Kosmo! ¡¿Dónde estás?!")
		return
	
	match state:
		State.FOLLOW:
			Follow_kosmo(delta)
		State.EXPLORE:
			Explore_area(delta)
		State.RETURNING:
			Return_to_kosmo(delta)
			
	check_state_transition()

func Follow_kosmo(delta):
	side_timer += delta
	if side_timer >= SIDE_SWITCH_INTERVAL:
		lateral_side *= -1  # Cambia de lado dinámicamente
		side_timer = 0.0
	
	var kosmo_right = kosmo.transform.basis.x.normalized()
	var offset = kosmo_right * lateral_side * side_offset
	
	var desired_position = kosmo.global_position + offset
	
	if global_position.distance_to(desired_position) > 0.5:
		nav_agent.target_position = desired_position
		Move_to_target(delta)
	else:
		velocity = Vector3.ZERO
		update_animation(Vector3.ZERO)

func Explore_area(delta):
	Move_to_target(delta)
	if global_position.distance_to(target_position) < 0.5:
		state = State.RETURNING

func Return_to_kosmo(delta):
	nav_agent.target_position = kosmo.global_position
	Move_to_target(delta)
	if global_position.distance_to(kosmo.global_position) < FOLLOW_DISTANCE:
		state = State.FOLLOW

func check_state_transition():
	if state == State.FOLLOW and randf() < EXPLORE_CHANCE:
		if global_position.distance_to(kosmo.global_position) < FOLLOW_DISTANCE:
			var angle = randf() * TAU
			var offset = Vector3(cos(angle), 0, sin(angle)) * EXPLORE_RADIUS
			target_position = kosmo.global_position + offset
			nav_agent.target_position = target_position
			state = State.EXPLORE

	elif state == State.EXPLORE:
		var dist_to_kosmo = global_position.distance_to(kosmo.global_position)
		if dist_to_kosmo > MAX_DISTANCE_FROM_KOSMO:
			state = State.RETURNING

func Move_to_target(delta):
	if nav_agent.get_navigation_map() == null or nav_agent.target_position == null:
		return
	
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		update_animation(Vector3.ZERO)
		return
	
	var next_pos = nav_agent.get_next_path_position()
	if next_pos == Vector3.ZERO:
		return
	
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	velocity = direction * speed * delta
	
	update_animation(direction)
	move_and_slide()

func update_animation(move_vector: Vector3):
	if move_vector.length() < 0.1:
		anim_sprite.play("idle" + last_direction)
		return

	if abs(move_vector.x) > abs(move_vector.z):
		last_direction = "_side"
		anim_sprite.play("walk" + last_direction)
		anim_sprite.flip_h = move_vector.x < 0
	else:
		last_direction = "_down" if move_vector.z > 0 else "_up"
		anim_sprite.play("walk" + last_direction)
		anim_sprite.flip_h = false