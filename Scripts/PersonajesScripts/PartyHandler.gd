# PartyHandler.gd
extends Node

func actualizar_personajes_party():
	var escena = get_tree().get_current_scene()
	var reservas = escena.get_node("Personajes/reservaIA")
	var contenedor = escena.get_node("Personajes/seguidores")
	var jugador = escena.get_node("Personajes/Player")
	var jugador_altura = jugador.global_position.y

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
			
			# Posicionar alrededor de Kosmo a la misma altura
			var pos_offset = get_posicion_circular(jugador.global_position, index, total)
			pos_offset.y = jugador_altura
			personaje.global_position = pos_offset
			index += 1
		else:
			#Hibernar
			personaje.reparent(reservas)
			personaje.visible = false
			personaje.set_physics_process(false)
			personaje.set_process(false)
			personaje.set_process_input(false)

			# Lo mandamos fuera del rango, pero dentro del NavigationRegion3D
			personaje.global_position = Vector3(-50, jugador_altura, -5)


func get_posicion_circular(base: Vector3, index: int, total: int, radio: float = 2.0) -> Vector3:
	var angle = TAU * float(index) / float(total)
	var offset = Vector3(cos(angle), 0, sin(angle)) * radio
	return base + offset # Esto distribuye N personajes en un circulo alrededor de un punto
