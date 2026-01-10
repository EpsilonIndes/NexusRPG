# PartyHandler.gd
extends Node

func actualizar_personajes_party():
	var escena = get_tree().get_current_scene()
	var reservas = escena.get_node("Personajes/reservaIA")
	var contenedor = escena.get_node("Personajes/seguidores")
	var jugador = escena.get_node("Personajes/Player")

	var party = PlayableCharacters.get_party_actual()
	var total = party.size()
	var index = 0

	# Todos los personajes IA deben estar en reservaIA inicialmente
	for personaje in reservas.get_children():
		if not personaje is CharacterBody3D:
			continue # Solo IAs
		
		var pj_id = personaje.name
		var en_party = PlayableCharacters.is_in_party(pj_id)

		if en_party:
			# Despertar
			personaje.reparent(contenedor)
			personaje.visible = true
			personaje.set_process(true)
			personaje.set_process_input(true)
			personaje.set_physics_process(false) # Desactivo física temporal

			# 👉 Intentamos usar spawn narrativo (DialogueAnchor)
			var override_pos = PlayableCharacters.consume_spawn_override(pj_id)
			if override_pos != Vector3.ZERO:
				# Aparece exactamente donde estaba el NPC
				var spawn_pos = override_pos + Vector3.DOWN * 1.5
				personaje.global_position = snap_to_floor(spawn_pos)
				personaje.velocity = Vector3.ZERO

				# Reactivamos física al siguiente frame
				await get_tree().process_frame
				personaje.set_physics_process(true)

				_freeze_follow(personaje, 1.0)
			else:
				# Comportamiento normal: círculo alrededor del player
				call_deferred(
					"_posicionar_personaje",
					personaje,
					jugador.global_position,
					index,
					total
				)
				index += 1
		else:
			# Hibernar
			personaje.reparent(reservas)
			personaje.visible = false
			personaje.set_physics_process(false)
			personaje.set_process(false)
			personaje.set_process_input(false)

			# Lo mandamos fuera del rango, pero dentro del NavigationRegion3D
			personaje.global_position = Vector3(-50, jugador.global_position.y, -5)



# Helpers #

func _posicionar_personaje(personaje: CharacterBody3D, base: Vector3, index: int, total: int):
	var pos_offset = get_posicion_circular(base, index, total)
	pos_offset = snap_to_floor(pos_offset)

	# Fijar posicion mientras fisica esta desactivada
	personaje.global_position = pos_offset
	personaje.velocity = Vector3.ZERO

	# Activar fisica al siguiente frame
	await get_tree().process_frame
	personaje.set_physics_process(true)



func get_posicion_circular(base: Vector3, index: int, total: int, radio: float = 2.0) -> Vector3:
	var angle = TAU * float(index) / float(total)
	var offset = Vector3(cos(angle), 0, sin(angle)) * radio
	return base + offset # Esto distribuye N personajes en un circulo alrededor de un punto


func snap_to_floor(pos: Vector3) -> Vector3:
	var space = get_viewport().get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		pos + Vector3.UP * 2, 
		pos + Vector3.DOWN * 5
	)
	var result = space.intersect_ray(query)

	if result.has("position"):
		pos.y = result["position"].y
	return pos

func _freeze_follow(personaje: Node, tiempo: float) -> void:
	#personaje.look_at(jugador.global_position, Vector3.UP)
	if not personaje.has_method("set_follow_enabled"):
		return

	personaje.set_follow_enabled(false)
	await get_tree().create_timer(tiempo).timeout
	personaje.set_follow_enabled(true)
