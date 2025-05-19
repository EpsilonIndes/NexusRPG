# BattleManager.gd Dentro de nodo
# Este script manejará:
#   El orden de turnos
#   La lista de participantes
#   El estado del combate
#   La resolución de acciones y efectos
# BattleManager.gd
extends Node

@onready var player_team = $PlayerTeam
@onready var enemy_team = $EnemyTeam

var jugadores_instanciados: Array = []
var enemigos_instanciados: Array = []

func _ready():
    
	# Instanciar personajes al entrar en batalla
	instanciar_equipo(CombatData.jugadores, player_team, true)
	instanciar_equipo(CombatData.enemigos, enemy_team, false)
	iniciar_turnos()

func instanciar_equipo(lista_ids: Array, contenedor: Node, es_jugador: bool):
	for id in lista_ids:
		var escena_path = "res://Escenas/Battle/characters_battle/%sBattle.tscn" % id if es_jugador else "res://Escenas/Battle/enemyBattle/%s.tscn" % id
		
		var escena = load(escena_path)
		var combatant = escena.instantiate()
		contenedor.add_child(combatant)
		
		if es_jugador:
			jugadores_instanciados.append(combatant)
		else:
			enemigos_instanciados.append(combatant)

func iniciar_turnos():
	# Por ahora solo un print, luego vendrá el sistema de turnos
	print("¡Batalla iniciada entre %d jugadores y %d enemigos!" %
		[jugadores_instanciados.size(), enemigos_instanciados.size()])