extends CharacterBody3D

#  			Notas: ChipitaManager2.gd          #
# Chipita debe explorar zonas cercanas cuando  #
# kosmo esté quieto o no haya peligro.		   #
# No se alejará demasiado.                     #
# Se detendrá si Kosmo se mueve lejos o		   #
# si entran en combate.						   #
# Se moverá de forma orgánica, con un poco de  #
# aleatoriedad pero con intención.             #

# Sistema de estados
enum State {
	FOLLOW,
	EXPLORE,
	RETURNING
}

var state = State.FOLLOW

# Lógica principal
var last_direction = "_down" # Inicializa la dirección de la animación
@export var kosmo_path: NodePath
var kosmo: Node3D = null
@onready var nav_agent = $NavigationAgent3D
@onready var anim_sprite = $AnimatedSprite3D
@export var speed: float = 120.0

const FOLLOW_DISTANCE = 1.5
const EXPLORE_RADIUS = 5.0
const MAX_DISTANCE_FROM_KOSMO = 5.0
var target_position: Vector3 = Vector3.ZERO


func _ready():
	if kosmo_path:                                          # Si la ruta de Kosmo está Seteado desde el editor # 
		kosmo = get_node(kosmo_path)                        # Lo asignará a la variable Kosmo                  #
	else:                                                   # De lo contrario, lo asignará automáticamente     #
		print("Ruta no seteada, buscando automáticamente")
		kosmo = get_node("../Player")
	
	if kosmo:
		print("Chipita encontró a Kosmo")
	else:
		print("Chipita no encontró a Kosmo")

func _physics_process(delta):
	if !kosmo:
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
	var distance = global_position.distance_to(kosmo.global_position)
	if distance > FOLLOW_DISTANCE:
		nav_agent.target_position = kosmo.global_position
		Move_to_target(delta)
	else:
		velocity = Vector3.ZERO
		update_animation(Vector3.ZERO)

func Explore_area(delta):
	Move_to_target(delta)
	if global_position.distance_to(target_position) < 1.0:
		state = State.RETURNING

func Return_to_kosmo(delta):
	nav_agent.target_position = kosmo.global_position
	Move_to_target(delta)
	if global_position.distance_to(kosmo.global_position) < FOLLOW_DISTANCE:
		state = State.FOLLOW

func check_state_transition():
	if state == State.FOLLOW and randf() < 0.005:
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
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		update_animation(Vector3.ZERO)
		return
	
	var next_pos = nav_agent.get_next_path_position()
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
		if move_vector.z > 0:
			last_direction = "_down"
		else:
			last_direction = "_up"
		anim_sprite.play("walk" + last_direction)
		anim_sprite.flip_h = false
