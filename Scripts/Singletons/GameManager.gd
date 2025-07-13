# GameManager.gd
extends Node

enum EstadosDeJuego {
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var equipo_actual: Array[Dictionary] = [ # todos los pjs actuales jugables
	{"id": "Kosmo"},
	{"id": "Sigrid"},
	{"id": "Maya"},
	{"id": "Amanda"}
]

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE

func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

func iniciar_batalla(contra_enemigos: Array[String]):
	CombatData.set_enemigos([]) 
	CombatData.set_jugadores([]) 
	GameManager.set_estado(GameManager.EstadosDeJuego.COMBATE)

	CombatData.set_jugadores(equipo_actual)
	CombatData.set_enemigos(contra_enemigos)
	
	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")

func _ready():
	for pj in equipo_actual:
		PlayableCharacters.create_character(pj.id) # Crea el personaje, desde el array
	PlayableCharacters.add_to_party("Kosmo")
	PlayableCharacters.add_to_party("Sigrid")
