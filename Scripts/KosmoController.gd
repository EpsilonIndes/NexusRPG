# PlayerController
extends CharacterBody3D


@export var speed: float = 180
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var inventory_ui = $"../../CanvasLayer/InventoryUI"
@onready var inventory_manager = get_tree().get_root().get_node("InventoryManager")
var last_direction: String = "_down"
var vertical_velocity: float = 0.0
var usa_flip_x: bool = true
var gravity: float = -9.8
var look_direction: Vector3 = Vector3.FORWARD

func _physics_process(delta):

	if GameManager.estado_actual == GameManager.EstadosDeJuego.DIALOGO:
		raycast.enabled = false
	else:
		raycast.enabled = true
	
	if GameManager.estado_actual != GameManager.EstadosDeJuego.LIBRE:
		return
	
	var input_dir = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	var move_vector = Vector3(input_dir.x, 0, input_dir.y).normalized()

	handle_movement(move_vector, delta)
	if move_vector.length() > 0.1:
		look_direction = move_vector.normalized()

	update_sprite(move_vector)
	update_raycast(move_vector)

# --- MOVIMIENTO ---
func handle_movement(move_vector: Vector3, delta: float) -> void:
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	if move_vector != Vector3.ZERO:
		velocity.x = move_vector.x * speed * delta
		velocity.z = move_vector.z * speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

# --- ANIMACIONES ---
func update_sprite(move_vector: Vector3) -> void:
	# Comprobamos si esta cayendo/saltando
	if not is_on_floor():
		if vertical_velocity > 0:
			animated_sprite.play("jump" + last_direction)
		else:
			animated_sprite.play("fall" + last_direction)
		return
	
	if move_vector.length() < 0.1:
		animated_sprite.play("idle" + last_direction)
		return


	if abs(move_vector.x) > abs(move_vector.z):
		if usa_flip_x:
			animated_sprite.flip_h = move_vector.x < 0
			last_direction = "_side"
		else:
			last_direction = "_left" if move_vector.x < 0 else "_right"
	else:
		last_direction = "_down" if move_vector.z > 0 else "_up"
		animated_sprite.flip_h = false

	var anim = ""
	if Input.is_action_pressed("correr"):
		speed = 330
		anim = "sprint" + last_direction
	else:
		speed = 180
		anim = "walk" + last_direction

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

# --- RAYCAST ---
func update_raycast(move_vector: Vector3) -> void:
	if move_vector != Vector3.ZERO:
		var raycast_direction = Vector3(move_vector.x, 0, move_vector.z).normalized()
		raycast.target_position = raycast_direction

# --- INPUTS ESPECIALES ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("accion"):
		try_interact()

	if event.is_action_pressed("inventario"):
		inventory_ui.toggle_inventory()

# --- INTERACCIONES ---
func try_interact() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("interactuables"):
			collider.interact()
		elif collider.get_parent().is_in_group("interactuables"):
			collider.get_parent().interact()
		else:
			print("No se puede pa.")
