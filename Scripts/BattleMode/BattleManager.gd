# BattleManager.gd Dentro de nodo
# Este script manejará:
#   El orden de turnos
#   La lista de participantes
#   El estado del combate
#   La resolución de acciones y efectos
extends Node

# Posiciones base:
var posiciones_jugadores: Array = [
	Vector3(1, 1.1, -3.5),  # Ubicación de Kosmo
	Vector3(-2.5, 1.1, -3), # Ubicación de Miguelito
	Vector3(2.5, 1.1, -3), # Ubicación de Chipita
	Vector3(-1, 1.1, -3.5)   # Ubicación de Sigrid
]
var posiciones_enemigos: Array = [
	Vector3(1, 1, 3.5),
	Vector3(-2.5, 1, 3.5),
	Vector3(2.5, 1, 3),
	Vector3(-1, 1, 3)
]

@onready var player_team = $PlayerTeam
@onready var enemy_team = $EnemyTeam

var jugadores_instanciados: Array = []
var enemigos_instanciados: Array = []

func _ready():

	await get_tree().process_frame # Esperar un frame para que el nodo esté listo
	# Instanciar personajes al entrar en batalla
	instanciar_equipo(CombatData.jugadores, player_team, true)
	instanciar_equipo(CombatData.enemigos, enemy_team, false)
	iniciar_turnos()

func instanciar_equipo(lista_ids: Array, contenedor: Node, es_jugador: bool):
	for i in range(lista_ids.size()):

		var id = lista_ids[i]
		var escena_path = "res://Escenas/Battle/characters_battle/%sBattle.tscn" % id if es_jugador else "res://Escenas/Battle/enemyBattle/%s.tscn" % id
		
		var escena = load(escena_path)
		var combatant = escena.instantiate()
		contenedor.add_child(combatant)

		var posicion_inicial = posiciones_jugadores[i] if es_jugador else posiciones_enemigos[i]
		
		combatant.global_transform.origin = posicion_inicial
		combatant.posicion_inicial = posicion_inicial

		if es_jugador:
			jugadores_instanciados.append(combatant)
		else:
			enemigos_instanciados.append(combatant)

func iniciar_turnos(): # Aquí estará el bucle de turnos


	print("¡Batalla iniciada entre %d jugadores y %d enemigos!" %
		[jugadores_instanciados.size(), enemigos_instanciados.size()])