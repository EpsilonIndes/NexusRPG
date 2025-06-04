# BattleManager.gd (Dentro de nodo)
# Este script maneja:
#   El orden de turnos
#   La lista de participantes
#   El estado del combate
extends Node
class_name BattleManager
# Posiciones base:
var posiciones_jugadores: Array = [
	Vector3(1, 1.1, -5),  		# Ubicación de Kosmo
	Vector3(-2.5, 1.1, -4.5), 	# Ubicación de Miguelito
	Vector3(2.5, 1.1, -4.5), 	# Ubicación de Chipita
	Vector3(-1, 1.1, -5)   	 	# Ubicación de Sigrid
]
var posiciones_enemigos: Array = [
	Vector3(1, 1, 5),
	Vector3(-2.5, 1, 4),
	Vector3(2.5, 1, 4),
	Vector3(-1, 1, 5)
]

@onready var player_team = $PlayerTeam
@onready var enemy_team = $EnemyTeam

@onready var battle_camera := get_parent().get_node("Camera/BattleCamera")
@onready var ui_overlay := get_parent().get_node("UIOverlay")

var jugadores_instanciados: Array = []
var enemigos_instanciados: Array = []

func _ready():

	await get_tree().process_frame # Esperar un frame para que el nodo esté listo

	instanciar_equipo(CombatData.jugadores, player_team, true)
	instanciar_equipo(CombatData.enemigos, enemy_team, false)
	iniciar_turnos()

func instanciar_equipo(lista_ids: Array, contenedor: Node, es_jugador: bool): # Instancia las escenas de los combatientes
	for i in range(lista_ids.size()):
		var id = lista_ids[i]
		var escena_path = "res://Escenas/Battle/characters_battle/%sBattle.tscn" % id if es_jugador else "res://Escenas/Battle/enemyBattle/%s.tscn" % id

		var escena = load(escena_path)
		var combatant = escena.instantiate()
		contenedor.add_child(combatant)

		var posicion_inicial = posiciones_jugadores[i] if es_jugador else posiciones_enemigos[i]
		
		combatant.global_transform.origin = posicion_inicial
		combatant.posicion_inicial = posicion_inicial
		combatant.indice = i # Ojito
		
		if es_jugador:
			jugadores_instanciados.append(combatant)
		else:
			enemigos_instanciados.append(combatant)
		
		combatant.inicializar()
		
var combatientes_ordenados: Array = []
var turno_actual: int = 0

func iniciar_turnos():
	combatientes_ordenados = jugadores_instanciados + enemigos_instanciados
	combatientes_ordenados.shuffle() # Por ahora mezclamos al azar

	turno_actual = 0
	ejecutar_turno()

	print("¡Batalla iniciada entre %d jugadores y %d enemigos!" %
		[jugadores_instanciados.size(), enemigos_instanciados.size()])

func ejecutar_turno():
	if turno_actual >= combatientes_ordenados.size():
		turno_actual = 0

	var combatiente = combatientes_ordenados[turno_actual]

	if combatiente.esta_muerto:
		siguiente_turno()

	if combatiente.es_jugador:
		# Invocamos el menu
			combatiente.seleccionar_turno()
	else:
		# IA del enemigo
		combatiente.realizar_accion()

func siguiente_turno():
	turno_actual += 1
	ejecutar_turno()

func mostrar_tecnicas_sobre(posicion_3d: Vector3, tecnicas: Array):
	var screen_pos = battle_camera.unproject_position(posicion_3d)
	var circulo = preload("res://Escenas/UserUI/tech_button_circle.tscn").instantiate()
	circulo.global_position = screen_pos
	circulo.configurar(tecnicas)
	for child in ui_overlay.get_children():
		if child is Node2D:
			child.queue_free() # Limpiamos los hijos previos del overlay
	ui_overlay.add_child(circulo)
	
