extends Node

enum EstadosDeJuego {
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var equipo_actual: Array = [
	{ "id": "Kosmo", "class_id": "quantic_master" },
	{ "id": "Sigrid", "class_id": "knight" },
	{ "id": "Chipita", "class_id": "dark_mage" },
	{ "id": "Maya", "class_id": "lancer" }
]

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE

func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

func iniciar_batalla(contra_enemigos: Array[String]):
	CombatData.jugadores = PlayableCharacters.get_party_actual()
	CombatData.enemigos = contra_enemigos
	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")

func _ready():
	for pj in equipo_actual:
		PlayableCharacters.create_character(pj.id, pj.class_id)
		PlayableCharacters.add_to_party(pj.id)
