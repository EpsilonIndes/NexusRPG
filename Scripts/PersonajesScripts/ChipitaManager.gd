extends CharacterBody3D

@export var kosmo_path: NodePath
var kosmo: Node3D = null
@onready var nav_agent = $NavigationAgent3D
@onready var sprite = $Sprite3D
@onready var anim = $AnimationPlayer

const FOLLOW_DISTANCE = 5.0
const MAX_OFFSET = 2.5
var idle_timer = 0.0
var random_idle_playing = false

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
    if !kosmo:                                             # Si Kosmo no está Seteado
        return                                             # Return, es para evitar que el código continúe

    var distance = global_position.distance_to(kosmo.global_position)
    
    if distance > FOLLOW_DISTANCE:
        random_idle_playing = false
        var offset = Vector3(
            randf_range(-MAX_OFFSET, MAX_OFFSET),
            0,
            randf_range(-MAX_OFFSET, MAX_OFFSET)
        )

        var target_pos = kosmo.global_position + offset
        nav_agent.target_position = target_pos

    if nav_agent.is_navigation_finished():
        _handle_idle_behavior(delta)
    else:
        _move_to_target(delta)

func _move_to_target(delta):
    var next_path_pos = nav_agent.get_next_path_position()
    var direction = (next_path_pos - global_position).normalized()
    velocity = direction * 3.0 * delta
    move_and_slide()

    # Orientar el sprite hacia la dirección del movimiento
    if abs(direction.x) > abs(direction.z):
        sprite.flip_h = direction.x < 0
    else:
        sprite.flip_h = direction.z > 0 # opcional, depende del diseño

func _handle_idle_behavior(delta):
    idle_timer += delta
    velocity = Vector3.ZERO
    if idle_timer >= 3.0 and !random_idle_playing:
        idle_timer = 0
        _play_random_idle()

func _play_random_idle():
    random_idle_playing = true
    var options = ["scratch_head", "look_around", "pose"]
    var anim_name = options[randi() % options.size()]
    anim.play(anim_name)