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
	PlayableCharacters.add_to_party(class_id)

func remover_personaje(class_id: String):
	PlayableCharacters.remove_from_party(class_id)

func iniciar_batalla(contra_enemigos: Array[String]):
	CombatData.jugadores = PlayableCharacters.get_party_actual()
	#CombatData.jugadores = PlayableCharacters.get_party_actual()
	CombatData.enemigos = contra_enemigos
	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")
