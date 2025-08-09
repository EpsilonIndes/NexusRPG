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
	{"id": "Amanda"},
	{"id": "Miguelito"},
	{"id": "Chipita"},
]

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE

func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

func iniciar_batalla(contra_enemigos: Array[String]):
	GameManager.set_estado(GameManager.EstadosDeJuego.COMBATE)

	CombatData.set_jugadores(get_team_instanciar())
	CombatData.set_enemigos(contra_enemigos)
	
	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")

func _ready():
	for pj in equipo_actual:
		PlayableCharacters.create_character(pj.id) # Crea el personaje, desde el array
	PlayableCharacters.add_to_party("Kosmo")

# Funcion para retornar un array de diccionarios con el equipo actual de 4 personajes
func get_team_instanciar() -> Array[Dictionary]:
	var team: Array[Dictionary] = []
	var ids_validos = PlayableCharacters.get_party_actual()

	for pj_id in ids_validos:
		team.append({"id": pj_id})
		if team.size() >= 4:
			break

	print("Equipo a instanciar:", team)
	return team # [{"id": "Kosmo"}, {"id": "Sigrid"}]
