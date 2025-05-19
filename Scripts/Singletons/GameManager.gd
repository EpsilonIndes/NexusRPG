extends Node

enum EstadosDeJuego {
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE

func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

var equipo_actual: Array = [] # Lista del equipo vacío, hasta que se llena al instanciarlos más adelante

func agregar_personaje(class_id: String, class_nombre: String):
	if not PlayableCharacters.characters.has(class_id):
		PlayableCharacters.add_character(class_id, class_nombre)
	agregar_al_equipo(class_id)

# Si querés, podés hacer un método para agregar o remover miembros
func agregar_al_equipo(class_id: String):
	if not equipo_actual.has(class_id):
		equipo_actual.append(class_id)

func remover_del_equipo(class_id: String):
	equipo_actual.erase(class_id)

func iniciar_combate(enemy_id: Array[String]):
	# Cambia el estado global
	set_estado(EstadosDeJuego.COMBATE)
	
	# Guarda datos necesarios para el combate
	CombatData.jugadores = equipo_actual.duplicate()
	CombatData.enemigos = enemy_id

	# Cargar escena de batalla
	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")