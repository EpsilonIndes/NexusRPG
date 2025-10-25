# BattleManager.gd (Dentro de nodo)
# Este script maneja:
#   El orden de turnos
#   La lista de participantes
#   El estado del combate
extends Node

enum BattleState {
	INICIO,
	TURNO_JUGADOR,
	SELECCION_ACCION,
	EJECUCION_ACCION,
	TURNO_ENEMIGO,
	CHEQUEAR_FINAL,
	FINAL
}

enum TargetScope {
	ALL_ENEMIES,
	ALL_ALLIES,
	SINGLE_ENEMY,
	SINGLE_ALLY,
	RANDOM_ENEMY,
	RANDOM_ALLY,
	SELF
}

var estado_actual: BattleState = BattleState.INICIO
var combatientes: Array = []
var combatiente_actual: Node = null
var indice_turno: int = 0
@onready var player_team = $PlayerTeam
@onready var enemy_team = $EnemyTeam
@onready var battle_camera = get_parent().get_node("Camera/BattleCamera")
@onready var ui_overlay = get_parent().get_node("UIOverlay")

var tecnica_actual = null
var objetivos_actuales: Array = []

const POS_JUGADORES := [
	Vector3(1, 1.1, -5),  		# Ubicación de Kosmo
	Vector3(-2.5, 1.1, -4.5), 	# Ubicación de Miguelito
	Vector3(2.5, 1.1, -4.5), 	# Ubicación de Chipita
	Vector3(-1, 1.1, -5)   	 	# Ubicación de Sigrid
]
const POS_ENEMIGOS := [
	Vector3(1, 1, 5),
	Vector3(-2.5, 1, 4),
	Vector3(2.5, 1, 4),
	Vector3(-1, 1, 5)
]

func _ready():
	await get_tree().process_frame
	inicializar_combatientes()
	cambiar_estado(BattleState.TURNO_JUGADOR) # primer turno del jugador

func inicializar_combatientes():
	combatientes.clear()
	print("JUGADORES:", CombatData.jugadores)

	instanciar_equipo(CombatData.jugadores, player_team, true)
	instanciar_equipo(CombatData.enemigos, enemy_team, false)

func instanciar_equipo(lista: Array, contenedor: Node, es_jugador: bool):
	for i in range(lista.size()):
		var datos = lista[i]
		var id = datos["id"]

		var path = "res://Escenas/Battle/characters_battle/%sBattle.tscn" % id if es_jugador else "res://Escenas/Battle/enemyBattle/%s.tscn" % id 
		
		var escena = load(path)
		if escena == null:
			push_error("No se pudo cargar la escena de batalla para %s" % id)
			continue
		
		var combatant = escena.instantiate()
		contenedor.add_child(combatant)

		var pos = POS_JUGADORES[i] if es_jugador else POS_ENEMIGOS[i]
		combatant.global_transform.origin = pos
		combatant.position_inicial = pos
		combatant.indice = i
		combatant.inicializar(datos, es_jugador)
		combatant.es_jugador = es_jugador
		combatientes.append(combatant)

func cambiar_estado(nuevo_estado: BattleState):
	estado_actual = nuevo_estado
	match estado_actual:
		BattleState.TURNO_JUGADOR:
			iniciar_turno_jugador()
		BattleState.SELECCION_ACCION:
			seleccionar_accion()
		BattleState.EJECUCION_ACCION:
			ejecutar_accion()
		BattleState.TURNO_ENEMIGO:
			iniciar_turno_enemigo()
		BattleState.CHEQUEAR_FINAL:
			chequear_si_termina()
		BattleState.FINAL:
			finalizar_batalla()

func iniciar_turno_jugador():
	combatiente_actual = obtener_siguiente_combatiente(true)
	if combatiente_actual:
		mostrar_tecnicas_sobre(combatiente_actual.global_transform.origin, combatiente_actual.id)
	else:
		cambiar_estado(BattleState.TURNO_ENEMIGO)

func seleccionar_accion():
	# Espera una señal desde el UI cuando el jugador elija
	pass

func ejecutar_accion():
	if not tecnica_actual:
		push_warning("No hay técnica seleccionada. Volviendo a selección.")
		cambiar_estado(BattleState.TURNO_JUGADOR)
		return
	
	for objetivo in objetivos_actuales:
		EffectManager.apply_effects(tecnica_actual, objetivo.id)
	
	finalizar_turno()


func iniciar_turno_enemigo():
	combatiente_actual = obtener_siguiente_combatiente(false)
	if combatiente_actual:
		combatiente_actual.iniciar_accion()
	else:
		cambiar_estado(BattleState.CHEQUEAR_FINAL)

func obtener_siguiente_combatiente(es_jugador: bool) -> Node:
	while indice_turno < combatientes.size():
		var c = combatientes[indice_turno]
		indice_turno += 1
		if c.esta_vivo() and c.is_jugador() == es_jugador:
			return c
	# Si no hay más, resetear índice
	indice_turno = 0
	return null

func finalizar_turno():
	cambiar_estado(BattleState.CHEQUEAR_FINAL)

func chequear_si_termina():
	var jugadores_vivos = combatientes.any(func(c): return c.is_jugador() and c.esta_vivo())
	var enemigos_vivos = combatientes.any(func(c): return not c.is_jugador() and c.esta_vivo())

	if not jugadores_vivos:
		print("Game Over")
		cambiar_estado(BattleState.FINAL)
	elif not enemigos_vivos:
		print("¡Victoria!")
		cambiar_estado(BattleState.FINAL)
	else:
		# Reiniciar turno con los jugadores
		indice_turno = 0
		cambiar_estado(BattleState.TURNO_JUGADOR)

func finalizar_batalla():
	# Limpieza, volver al mapamundi, recompensas, etc.
	pass

func mostrar_tecnicas_sobre(posicion_3d: Vector3, nombre_personaje: String):
	var tecnicas_ids: Array = []
	if GlobalTechniqueDatabase.tecnica_obtenida.has(nombre_personaje):
		tecnicas_ids = GlobalTechniqueDatabase.tecnica_obtenida[nombre_personaje]
	else:
		print("El personaje %s no tiene técnicas registradas." % nombre_personaje)
	
	print("Técnicas cargadas para %s: %d" % [nombre_personaje, tecnicas_ids.size()])
	for tid in tecnicas_ids:
		print("- %s" % tid)
	
	var screen_pos = battle_camera.unproject_position(posicion_3d)
	var circulo = preload("res://Escenas/UserUI/tech_button_circle.tscn").instantiate()
	circulo.global_position = screen_pos
	circulo.battle_manager = self
	circulo.configurar(tecnicas_ids)

	# Limpiamos overlay viejo
	for child in ui_overlay.get_children():
		if child is Node2D:
			child.queue_free()

	ui_overlay.add_child(circulo)

func _on_tecnica_seleccionada(tecnica_id: String):
	print("Técnica seleccionada: %s" % tecnica_id)

	# Guardar la técnica elegida por el jugador
	tecnica_actual = GlobalTechniqueDatabase.get_tecnica_stats(tecnica_id)
	print("Stats de la técnica: %s" % tecnica_actual)

	# Decidir posibles objetivos según target_scope
	objetivos_actuales = obtener_objetivos(tecnica_actual["target_scope"])
	if objetivos_actuales.is_empty():
		push_warning("No hay objetivos válidos para %s" % tecnica_id)
	else:
		print("Objetivos posibles: %d" % objetivos_actuales.size())

	cambiar_estado(BattleState.EJECUCION_ACCION)

func obtener_objetivos(scope: String) -> Array:
	var aliados = combatientes.filter(func(c): return c.is_jugador() and c.esta_vivo())
	var enemigos = combatientes.filter(func(c): return not c.is_jugador() and c.esta_vivo())

	match scope:
		"ALL_ENEMIES":
			# Selector de enemigo
			return enemigos
		"ALL_ENEMIES":
			return enemigos
		"ALL_ALLIES":
			return aliados
		"SINGLE_ENEMY":
			return enemigos
		"SINGLE_ALLY":
			return aliados
		"RANDOM_ENEMY":
			if enemigos.size() > 0:
				return [enemigos[randi() % enemigos.size()]]
			else:
				return []
		"RANDOM_ALLY":
			if aliados.size() > 0:
				return [aliados[randi() % aliados.size()]]
			else:
				return []
		"SELF":
			return [combatiente_actual]
		_:
			push_warning("Scope desconocido: %s" % scope)
			return []