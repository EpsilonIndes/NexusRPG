# BattleManager.gd (Dentro de nodo)
# Este script maneja:
#   El orden de turnos
#   La lista de participantes
#   El estado del combate
#   La resolución de acciones y efectos
extends Node


signal turno_listo(combatant: Combatant) # Señal que se emite cuando un combatiente termina su turno

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

		if es_jugador:
			jugadores_instanciados.append(combatant)
		else:
			enemigos_instanciados.append(combatant)

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
		emit_signal("turno_listo", combatiente)
	else:
		# IA del enemigo
		combatiente.realizar_accion()

func siguiente_turno():
	turno_actual += 1
	ejecutar_turno()

func usar_tecnica(tecnica_id, usuario: Combatant, objetivos: Array):
	var tecnica = DataLoader.tecnicas.get(tecnica_id)
	if tecnica == null:
		push_error("Técnica %s no encontrada." % tecnica_id)
		return
	
	var mp_costo = int(tecnica.get("mp_cost", 0))
	if usuario.mp < mp_costo:
		print("%s no tiene suficiente MP para usar %s." % [usuario.nombre, tecnica.get("name")])
		return
	
	usuario.mp -= mp_costo

	var efectos: Array = tecnica.get("effects", []) # Puede dar error
	for objetivo in objetivos:
		for efecto in efectos:
			EffectManager.aplicar_efecto(efecto, usuario, objetivo)
