extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 10.0
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D

@onready var raycast : RayCast3D = $RayCast3D

@onready var inventory_ui = $"../../CanvasLayer/InventoryUI"

@onready var inventory_manager = get_tree().get_root().get_node("InventoryManager")

var rayCast_Rotation = Vector3.ZERO 

func _process(delta):
	if GameManager.estado_actual == GameManager.EstadosDeJuego.DIALOGO:
		raycast.enabled = false
	else:
		raycast.enabled = true

	if GameManager.estado_actual != GameManager.EstadosDeJuego.LIBRE:
		return

	var input_dir = Vector3.ZERO #Vector3(0, 0, 0)

	if input_dir != Vector3.ZERO:
		var raycast_direction = Vector3(input_dir.x, 0, input_dir.z).normalized()
		raycast.target_position = raycast_direction * 1  # Puedes ajustar el largo del rayito

	if Input.is_action_pressed("arriba"):
		input_dir.z -= 1 * delta #Delta es el tiempo que ha pasado desde el último frame
		animated_sprite.play("moveup")
		
	if Input.is_action_pressed("abajo"):
		input_dir.z += 1 * delta
		animated_sprite.play("movedown")

	if Input.is_action_pressed("izquierda"):
		input_dir.x -= 1 * delta
		animated_sprite.play("move")
		animated_sprite.flip_h = true
	
	if Input.is_action_pressed("derecha"):
		input_dir.x += 1 * delta
		animated_sprite.play("move")
		animated_sprite.flip_h = false

	input_dir = input_dir.normalized() #Normaliza el vector de entrada para que no se mueva más rápido en diagonal

	if input_dir != Vector3.ZERO:
		velocity.x = input_dir.x * speed 
		velocity.z = input_dir.z * speed

		var raycast_direction = Vector3(0, -input_dir.x, input_dir.z).normalized()
		raycast.target_position = raycast_direction * 2.5  # Puedes ajustar el largo del rayito
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if Input.is_action_just_released("arriba"):
			animated_sprite.play("up")
		if Input.is_action_just_released("abajo"):
			animated_sprite.play("down")
		if Input.is_action_just_released("izquierda") or Input.is_action_just_released("derecha"):
			animated_sprite.play("new_animation")

	move_and_slide()
	
	if Input.is_action_just_pressed("accion"):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("interactuables"):
				collider.interact()
			elif collider.get_parent().is_in_group("interactuables"):
				collider.get_parent().interact()
			else:
				print("No se puede pa.")

	if Input.is_action_just_pressed("inventario"):		
		inventory_ui.toggle_inventory()

	#Provicional: input para añadir objetos al inventario
	if Input.is_action_just_pressed("pocion"):
		var iten_name = "Poción"
		var amount = 1
		inventory_manager.add_item(iten_name, amount)
