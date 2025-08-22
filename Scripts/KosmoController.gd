# PlayerController
extends CharacterBody3D

@export var speed: float = 190
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var raycast: RayCast3D = $RayCast3D
@onready var inventory_ui = $"../../CanvasLayer/InventoryUI"
@onready var inventory_manager = get_tree().get_root().get_node("InventoryManager")

var last_direction: String = "_down"
var usa_flip_x: bool = true

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
	update_sprite(move_vector)
	update_raycast(move_vector)
	handle_inputs()

# --- MOVIMIENTO ---
func handle_movement(move_vector: Vector3, delta: float) -> void:
	if move_vector != Vector3.ZERO:
		velocity.x = move_vector.x * speed * delta
		velocity.z = move_vector.z * speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

# --- ANIMACIONES ---
func update_sprite(move_vector: Vector3) -> void:
	if move_vector.length() < 0.1:
		animated_sprite.play("idle" + last_direction)
		return
	
	if abs(move_vector.x) > abs(move_vector.z):
		if usa_flip_x:
			animated_sprite.flip_h = move_vector.x < 0
			last_direction = "_side"
			animated_sprite.play("walk" + last_direction)
		else:
			last_direction = "_left" if move_vector.x < 0 else "_right"
			animated_sprite.play("walk" + last_direction)
	else:
		last_direction = "_down" if move_vector.z > 0 else "_up" 
		animated_sprite.flip_h = false
		animated_sprite.play("walk" + last_direction)

# --- RAYCAST ---
func update_raycast(move_vector: Vector3) -> void:
	if move_vector != Vector3.ZERO:
		var raycast_direction = Vector3(move_vector.x, 0, move_vector.z).normalized()
		raycast.target_position = raycast_direction

# --- INPUTS ESPECIALES ---
func handle_inputs() -> void:
	if Input.is_action_just_pressed("accion"):
		try_interact()

	if Input.is_action_just_pressed("inventario"):
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
