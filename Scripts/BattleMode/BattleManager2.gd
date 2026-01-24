# BattleManager2
extends Node

enum BattleState {
	INICIO,
	TURNO_JUGADOR,
	SELECCION_ACCION,
	SELECCION_OBJETIVO,
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

# Resultados de batalla
var enemigos_derrotados: Array[String] = []
var jugadores_participantes: Array[String] = []

var battle_stats := {
	"turns": 0,
	"technique_used": {}
}

signal battle_finished(result: Dictionary)

# Estado
var estado_actual: BattleState = BattleState.INICIO
var combatientes: Array = []
var combatiente_actual: Node = null
var indice_turno: int = 0
var enemy_type_counter: Dictionary = {}

# Tech seleccionada (dict de tech)
var tecnica_actual: Dictionary = {}
var objetivos_actuales: Array = []

var drive_score: int = 0
var ultima_tecnica_usada: String = ""
var repeticion_continua: int = 0

# Referencias en la escena
@onready var player_team = $PlayerTeam
@onready var enemy_team = $EnemyTeam
@onready var battle_camera = get_parent().get_node("Camera/BattleCamera")
@onready var ui_overlay = get_parent().get_node("UIOverlay")
@onready var tecnique_overlay = ui_overlay.get_node("TechniqueOverlay")

const POS_JUGADORES := [
	Vector3(1, 1.1, -5),  	
	Vector3(-2.5, 1.1, -4.5),
	Vector3(2.5, 1.1, -4.5), 
	Vector3(-1, 1.1, -5)
]
const POS_ENEMIGOS := [
	Vector3(1, 1, 5),
	Vector3(-2.5, 1, 4),
	Vector3(2.5, 1, 4),
	Vector3(-1, 1, 5)
]

# --------------------
# API Pública: llamada desde GameManager
# jugadores: Array[Dictionary] (ej. {"id":"Astro"})
# enemigos: Array[String] (ej. ["slime","lobo_helado"])
# --------------------
func start_battle(jugadores: Array, enemigos: Array) -> void:
	combatientes.clear()
	indice_turno = 0
	drive_score = 0
	tecnica_actual = {}
	objetivos_actuales.clear()
	ultima_tecnica_usada = ""
	repeticion_continua = 0

	instanciar_equipo(jugadores, player_team, true)
	instanciar_equipo(enemigos, enemy_team, false)

	cambiar_estado(BattleState.TURNO_JUGADOR)

	battle_stats = {
	"turns": 0,
	"techniques_used": {}
	}

# --------------------
# Instancia escenas de cada combatiente (escenas individuales por ID)
# --------------------
func instanciar_equipo(lista: Array, contenedor: Node, es_jugador: bool) -> void:
	if not es_jugador:
		enemy_type_counter.clear()
	
	for i in range(lista.size()):
		var entrada = lista[i]

		# --- Obtener ID del combatiente ---
		var id: String = ""
		
		if typeof(entrada) == TYPE_DICTIONARY:
			id = str(entrada.get("id", ""))
		else:
			id = str(entrada)

		if id == "":
			push_error("Entrada de combatiente inválida: %s" % str(entrada))
			continue
		

		# --- Path a escena correspondiente ---
		var path: String
		if es_jugador:
			path = "res://Escenas/Battle/characters_battle/%sBattle.tscn" % id
		else:
			path = "res://Escenas/Battle/enemyBattle/%s.tscn" % id

		var escena: PackedScene = load(path)
		if escena == null:
			push_error("No se pudo cargar la escena de batalla para '%s'" % id)
			continue

		# --- Instanciar ---
		var combatant: Combatant = escena.instantiate()
		combatant.name = id

		# --- Nombre visible ---
		if not es_jugador:
			# Contador para enemigos repetidos
			var base_name := id.capitalize() # triangle -> Triangle

			if not enemy_type_counter.has(base_name):
				enemy_type_counter[base_name] = 0
			
			var index: int = enemy_type_counter[base_name]
			enemy_type_counter[base_name] += 1

			var letter := String.chr(65 + index) # A, B, C...
			combatant.display_name = "%s %s" % [base_name, letter]
		else:
			combatant.display_name = id.capitalize()

		# --- Agregar al árbol ---
		contenedor.add_child(combatant)
		combatientes.append(combatant)

		# --- Posición segura ---
		var pos: Vector3
		if es_jugador:
			pos = POS_JUGADORES[i] if i < POS_JUGADORES.size() else POS_JUGADORES.back()
		else:
			pos = POS_ENEMIGOS[i] if i < POS_ENEMIGOS.size() else POS_ENEMIGOS.back()

		combatant.global_transform.origin = pos
		combatant.position_inicial = pos
		combatant.indice = i
		combatant.es_jugador = es_jugador

		# --- Armar datos para inicializar ---
		var datos_dict: Dictionary
		if typeof(entrada) == TYPE_DICTIONARY:
			datos_dict = entrada.duplicate()
		else:
			datos_dict = {
				"id": id, 
				"nombre": combatant.display_name
			}

		# --- Inicializar combatiente ---
		if combatant.has_method("inicializar"):
			combatant.inicializar(datos_dict, es_jugador, self)
		else:
			push_warning("%s no tiene método inicializar()" % combatant.name)

# -----------------------
# Máquina de estados
# -----------------------
func cambiar_estado(nuevo_estado: BattleState) -> void:
	estado_actual = nuevo_estado
	match estado_actual:
		BattleState.TURNO_JUGADOR:
			#indice_turno = 0
			print("Turno del Jugador!")
			iniciar_turno_jugador()
		BattleState.SELECCION_ACCION:
			print("Selecciona acción!")
			seleccionar_accion()
		BattleState.SELECCION_OBJETIVO:
			print("Selecciona objetivo!")
			# El control TOTAL es del TargetSelector
			pass
		BattleState.EJECUCION_ACCION:
			print("Ejecutando acción!")
			ejecutar_accion()
		BattleState.TURNO_ENEMIGO:
			#indice_turno = 0
			print("Turno enemigo!")
			iniciar_turno_enemigo()
		BattleState.CHEQUEAR_FINAL:
			chequear_si_termina()
		BattleState.FINAL:
			print("Batalla finalizada!")
			finalizar_batalla()

# -----------------------
# Flujo del Jugador
# -----------------------
func iniciar_turno_jugador():
	combatiente_actual = obtener_siguiente_combatiente(true)
	if combatiente_actual:
		# Procesar efectos acrivos del combatiente ANTES de mostrar opciones
		if combatiente_actual.has_method("procesar_efectos_activos"):
			combatiente_actual.procesar_efectos_activos()
			# Si el efecto lo mató, saltamos al siguiente
			if not combatiente_actual.esta_vivo():
				# Seguimos en este mismo estado para agarrar al siguiente jugador
				iniciar_turno_jugador()
				return
		
		# Mostrar técnicas y pasar a selección
		
		mostrar_tecnicas_sobre(combatiente_actual.global_transform.origin)
		ui_overlay.set_tecnicas_interactivas(true)
		cambiar_estado(BattleState.SELECCION_ACCION)
	else:
		# No quedan jugadores válidos en este ciclo
		cambiar_estado(BattleState.TURNO_ENEMIGO)


func seleccionar_accion():
	# Espera señal del UI que llame _on_tecnica_seleccionada
	# La UI debe llamar _on_tecnica_seleccionada cuando el jugador confirma
	pass

func ejecutar_accion() -> void:
	# EJECUTAR la técnica usando el combatiente actual
	if combatiente_actual == null:
		push_warning("No hay combatiente actual en ejecutar_accion()")
		finalizar_turno()
		return
		
	# Nos conectamos ala señal turno_finalizado para continuar cuando termine
	# Desconectamos antes por si quedó algo colgando
	if combatiente_actual.is_connected("turno_finalizado", Callable(self, "_on_combatant_turn_finished")):
		combatiente_actual.disconnect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))
	combatiente_actual.connect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))
	
	# Pedimos al combatant que ejecute su técnica (player o enemigo)
	# Si el combatant ya tiene una tecnica_seleccionada (player), ejecutará esa.
	# Si el enemigo, iniciar_accion() habrá creado la selección y llamado ejecutar_tecnica()
	if combatiente_actual.has_method("ejecutar_tecnica"):
		combatiente_actual.ejecutar_tecnica()
	else:
		push_warning("Combatant %s no implementa ejecutar_tecnica()" % str(combatiente_actual))
		# seguridad: finalizar turno manualmente
		_on_combatant_turn_finished()

# -----------------------
# Flujo del enemigo
# -----------------------
func iniciar_turno_enemigo() -> void:
	combatiente_actual = obtener_siguiente_combatiente(false)

	if combatiente_actual == null:
		finalizar_turno()

	if combatiente_actual.esta_vivo():
		# Procesar efectos activos antes de que el enemigo actúe
		if combatiente_actual.has_method("procesar_efectos_activos"):
			combatiente_actual.procesar_efectos_activos()
			if not combatiente_actual.esta_vivo():
				chequear_si_termina()
				return
		
		# Conectar señal y pedir que inicie su acción (La acción emitirá turno_finalizado)
		if combatiente_actual.is_connected("turno_finalizado", Callable(self, "_on_combatant_turn_finished")):
			combatiente_actual.disconnect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))
		combatiente_actual.connect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))

		if combatiente_actual.has_method("iniciar_accion"):
			combatiente_actual.iniciar_accion()
		else:
			push_warning("Combatant %s no tiene iniciar_accion()" % str(combatiente_actual))
			# Si el enemigo no actúa, cerramos el turno
			# Desconectamos y avanzamos
			if combatiente_actual.is_connected("turno_finalizado", Callable(self, "_on_combatant_turn_finished")):
				combatiente_actual.disconnect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))
			_on_combatant_turn_finished()
	else:
		finalizar_turno()

# -----------------------
# Orden de turnos
# -----------------------
func obtener_siguiente_combatiente(es_jugador: bool) -> Node:
	while indice_turno < combatientes.size():
		var c = combatientes [indice_turno]
		indice_turno += 1
		# usar la propiedad es_jugador (no llamada)
		if c.esta_vivo() and c.es_jugador == es_jugador:
			return c
	
	# Si terminamos la lista -> resetear
	indice_turno = 0
	return null


func finalizar_turno() -> void:
	cambiar_estado(BattleState.CHEQUEAR_FINAL)

# -----------------------
# Fin de combate
# -----------------------
func chequear_si_termina():
	var jugadores_vivos = combatientes.any(
		func(c): return c.es_jugador and c.esta_vivo()
	)
	var enemigos_vivos = combatientes.any(
		func(c): return not c.es_jugador and c.esta_vivo()
	)

	if not jugadores_vivos:
		print("GAME OVER")
		cambiar_estado(BattleState.FINAL)
		return

	elif not enemigos_vivos:
		print("Victoria")
		cambiar_estado(BattleState.FINAL)
		return


	# Si terminó el ciclo entero, reseteamos el índice SOLO acá
	if indice_turno >= combatientes.size():
		indice_turno = 0
	
	# Dejamos que el flujo normal decide quién sigue
	var siguiente = combatientes[indice_turno]
	if siguiente.es_jugador:
		combatiente_actual = siguiente
		cambiar_estado(BattleState.TURNO_JUGADOR)
		return
	else:
		combatiente_actual = siguiente
		cambiar_estado(BattleState.TURNO_ENEMIGO)
		return


func finalizar_batalla() -> void:
	print("Finalizando Batalla...")

	"""
	La función any() devuelve true si 
	los elementos coinciden, se debe 
	usar una función Lambda/anónima [func(c)]
	
	"""
	var victoria := combatientes.any(func(c): return c.es_jugador and c.esta_vivo())

	var battle_result = _construir_battle_result(victoria)
	emit_signal("battle_finished", battle_result)

	#Limpieza interna
	enemigos_derrotados.clear()
	jugadores_participantes.clear()
	battle_stats = {
		"turns": 0,
		"techniques_used": {}
	}

	# Volver al mapa, recompensas y demás

# -----------------------
# UI — Técnicas
# -----------------------
func mostrar_tecnicas_sobre(posicion_3d: Vector3) -> void:
	var char_id := ""

	if combatiente_actual != null:
		if "id" in combatiente_actual:
			char_id = combatiente_actual.id
	
	if char_id == "":
		push_error("combatiente sin ID para cargar técnicas.")
		return
	
	var tecnicas_data := GlobalTechniqueDatabase.get_visible_techniques_for(char_id)

	var screen_pos = battle_camera.unproject_position(posicion_3d)
	var circulo = preload("res://Escenas/UserUI/tech_button_circle.tscn").instantiate()

	circulo.global_position = screen_pos
	circulo.battle_manager = self
	circulo.configurar(tecnicas_data)

	for c in tecnique_overlay.get_children():
		c.queue_free()
	
	tecnique_overlay.add_child(circulo)


# Llamada desde UI cuando el jugador selecciona una técnica
# (La UI debe llamar a este método)
func _on_tecnica_seleccionada(tec_id: String) -> void:
	if estado_actual == BattleState.SELECCION_OBJETIVO:
		print("[BattleManager] estado: SELECCION_OBJETIVO, retornando...")
		return
	
	get_viewport().set_input_as_handled() # Añadido ahorita <--

	if combatiente_actual == null:
		push_warning("No hay combatiente actual al seleccionar técnica")
		return
	
	tecnica_actual = GlobalTechniqueDatabase.get_tecnica_stats(tec_id)
	if tecnica_actual.is_empty():
		push_warning("Técnica %s no encontrada" % tec_id)
		return

	var scope = tecnica_actual.get("target_scope", "SINGLE_ENEMY")
	
	var enemigos := _candidatos_por_scope("SINGLE_ENEMY")
	var aliados := _candidatos_por_scope("SINGLE_ALLY")

	# Diccionario completo de targets
	var targets_data : Dictionary = {
		"enemies": enemigos,
		"allies": aliados,
		"default_group": "allies" if scope == "SINGLE_ALLY" else "enemies",
		"allow_switch": tecnica_actual.get("allow_target_switch", false)
	}

	# Casos que requieren selección manual de objetivo
	if scope in ["SINGLE_ENEMY", "SINGLE_ALLY"] and combatiente_actual.es_jugador:
		# Intentamos usar un target selector de la UI si existe
		if ui_overlay.has_method("open_target_selector"):
			ui_overlay.set_tecnicas_interactivas(false)
			cambiar_estado(BattleState.SELECCION_OBJETIVO)

			await get_tree().process_frame

			ui_overlay.open_target_selector(targets_data, Callable(self, "_on_target_selected"), Callable(self, "_on_cancel_selection_target"))
			return
		else:
			# fallback seguro
			var fallback_group = targets_data["default_group"]
			var fallback_targets = targets_data[fallback_group]
			if fallback_targets.size() > 0:
				objetivos_actuales = [fallback_targets[0]]
	
	else:
		# Otros scopes (ALL / RANDOM / SELF)
		var candidatos = _candidatos_por_scope(scope)
		objetivos_actuales = _map_scope_a_objetivos(scope, candidatos)

	# Ejecutar directamente si no hubo selector
	if objetivos_actuales.size() > 0:
		combatiente_actual.seleccionar_tecnica(tecnica_actual, objetivos_actuales)
		if estado_actual != BattleState.EJECUCION_ACCION:
			cambiar_estado(BattleState.EJECUCION_ACCION)
	
# Callback que la UI de selección de objetivo debe llamar:
# ui_overlay.open_target_selector(candidatos, callback)
# callback recibirá un nodo Combatant
func _on_target_selected(target: Combatant) -> void:
	print("[BattleManager] Objetivo confirmado: ", target.nombre)

	objetivos_actuales = [target]

	if ui_overlay:
		ui_overlay.set_tecnicas_interactivas(true)
	
	# asignar técnica y continuar
	combatiente_actual.seleccionar_tecnica(tecnica_actual, objetivos_actuales)
	
	if estado_actual != BattleState.EJECUCION_ACCION:
		cambiar_estado(BattleState.EJECUCION_ACCION)

func _on_cancel_selection_target() -> void:
	print("[BattleMaager] Cancelado selector de objetivos")
	estado_actual = BattleState.SELECCION_ACCION

func _candidatos_por_scope(scope: String) -> Array:
	var aliados = combatientes.filter(func(c): return c is Combatant and c.es_jugador and c.esta_vivo())
	var enemigos = combatientes.filter(func(c): return c is Combatant and not c.es_jugador and c.esta_vivo())

	match scope:
		"ALL_ENEMIES", "SINGLE_ENEMY", "RANDOM_ENEMY":
			return enemigos
		"ALL_ALLIES", "SINGLE_ALLY", "RANDOM_ALLY":
			return aliados
		"SELF":
			return [combatiente_actual]
		_:
			push_warning("Scope desconocido: %s" % scope)
			return []
# Mapea candidatos según scope (maneja RANDOM y ALL -> listas convertidas)
func _map_scope_a_objetivos(scope: String, candidatos: Array) -> Array:
	match scope:
		"ALL_ENEMIES":
			return candidatos
		"ALL_ALLIES":
			return candidatos
		"SINGLE_ENEMY":
			return [candidatos[0]] if candidatos.size() > 0 else []
		"SINGLE_ALLY":
			return [candidatos[0]] if candidatos.size() > 0 else []
		"RANDOM_ENEMY":
			return [candidatos[randi() % candidatos.size()]] if candidatos.size() > 0 else []
		"RANDOM_ALLY":
			return [candidatos[randi() % candidatos.size()]] if candidatos.size() > 0 else []
		"SELF":
			return [combatiente_actual]
		_:
			return []


#-------------------------------
# Callback cuando un combatante emitió turno_finalizado
#-------------------------------
func _on_combatant_turn_finished() -> void:
	# para resultados:
	if combatiente_actual != null and combatiente_actual.es_jugador:
		if not jugadores_participantes.has(combatiente_actual.id):
			jugadores_participantes.append(combatiente_actual.id)
	
	# desconectar al current si corresponde
	if combatiente_actual != null and combatiente_actual.is_connected("turno_finalizado", Callable(self, "_on_combatant_turn_finished")):
		combatiente_actual.disconnect("turno_finalizado", Callable(self, "_on_combatant_turn_finished"))

	# Actualizar DriveScore (si corresponde)
	actualizar_drive_score()

	# Limpiar técnica actual / objetivos
	tecnica_actual = {}
	objetivos_actuales.clear()

	# Pasamos a chequear fin de batalla
	cambiar_estado(BattleState.CHEQUEAR_FINAL)


#-------------------------------
# DriveScore (Simple por ahora)
#-------------------------------
func actualizar_drive_score() -> void:
	var id = tecnica_actual.get("tecnique_id", "")
	var base = tecnica_actual.get("score_value", 0)

	if id == ultima_tecnica_usada:
		repeticion_continua += 1
		base = int(base * (1.0 / float(repeticion_continua + 1)))
	else:
		repeticion_continua = 0
	
	drive_score += base
	ultima_tecnica_usada = id

	# para resultados:
	if id != "":
		if not battle_stats.has("techniques_used"):
			battle_stats["techniques_used"] = {}
		
		battle_stats["techniques_used"][id] = battle_stats["techniques_used"].get(id, 0) + 1


# para resultados
# enemigos derrotados:
func registrar_enemigos_derrotado(enemigo: Combatant) -> void:
	if enemigo != null and not enemigos_derrotados.has(enemigo.id):
		enemigos_derrotados.append(enemigo.id)

func _construir_battle_result(victoria: bool) -> Dictionary:
	return {
		"victoria": victoria,
		"drive_score": drive_score,
		"enemigos_derrotados": enemigos_derrotados.duplicate(),
		"jugadores": jugadores_participantes.duplicate(),
		"stats": battle_stats.duplicate()
	}

func get_combatant():
	return combatiente_actual