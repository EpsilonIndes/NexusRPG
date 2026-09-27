# GameManager.gd
extends Node

enum EstadosDeJuego {
	MAIN_MENU,
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var in_battle = false
var pending_battle_rewards: Dictionary = {}
var _closing_battle_results := false

const BattleResultsUIScene: PackedScene = preload("res://Escenas/UserUI/battle_results_ui.tscn")


var equipo_actual: Array[Dictionary] = [ # todos los pjs actuales jugables
	{"id": "Astro"},
	{"id": "Sigrid"},
	{"id": "Maya"},
	{"id": "Amanda"},
	{"id": "Miguelito"},
	{"id": "Chipita"},
]

var ui_lock_count := 0
var game_started := false
var estado_actual: EstadosDeJuego = EstadosDeJuego.MAIN_MENU
var primera_carga: bool = false

func _ready():
	pass

func start_game():
	if game_started:
		return
	if SaveManager.busy:
		return
	SaveManager.busy = true
	await SceneTransition.cover()

	var error := get_tree().change_scene_to_file("res://Escenas/pantallas/nivel_1.tscn")
	if error != OK:
		await SceneTransition.reveal()
		SaveManager.busy = false
		push_error("[GameManager] No se pudo cargar nivel_1.tscn. Error: %s" % error)
		return

	SaveManager.reset_progress()
	DataLoader.init_data()
	_initialize_team()
	game_started = true
	set_estado(EstadosDeJuego.LIBRE)
	await get_tree().scene_changed
	await SceneTransition.reveal()
	SaveManager.busy = false


func _initialize_team():
	print("Equipo actual:", equipo_actual)
	print("DataLoader listo:", DataLoader._is_ready)
	print("Stats cargados:", DataLoader.stats.size())

	if primera_carga:
		return

	for pj in equipo_actual:
		PlayableCharacters.create_character(pj.id) # Crea el personaje, desde el array
	PlayableCharacters.add_to_party("Astro")
	primera_carga = true


func set_estado(nuevo_estado):
	estado_actual = nuevo_estado

func es_estado(objetivo):
	return estado_actual == objetivo

func iniciar_batalla(contra_enemigos: Array[String]):
	var player = get_tree().get_current_scene().get_node("Personajes/Player")
	var cont_seguidores = get_tree().get_current_scene().get_node("Personajes/seguidores")
	if not is_instance_valid(player):
		push_error("[GameManager] Player inválido al iniciar batalla")

	in_battle = true

	set_estado(EstadosDeJuego.COMBATE)
	
	WorldStateManager.capture_player(player)
	WorldStateManager.capture_followers(cont_seguidores)

	get_tree().change_scene_to_file("res://Escenas/Battle/battle_scene.tscn")

	# Esperar que termine su _ready()
	await get_tree().tree_changed
	
	# IMPORTANTE: esperar un frame para que la escena cargue
	await get_tree().process_frame

	var scene = get_tree().current_scene
	var jugadores_instanciar = get_team_instanciar()

	var bm := scene.get_node("BattleManager")
	
	# Conectar señal de finalización
	if not bm.is_connected("battle_finished", Callable(self, "_on_battle_finished")):
		bm.connect("battle_finished", Callable(self, "_on_battle_finished"))
	
	bm.start_battle(jugadores_instanciar, contra_enemigos)	
	

# Funcion para retornar un array de diccionarios con el equipo actual de 4 personajes
func get_team_instanciar() -> Array[Dictionary]:
	var team: Array[Dictionary] = []
	var ids_validos = PlayableCharacters.get_party_actual()

	for pj_id in ids_validos:
		team.append({"id": pj_id})
		if team.size() >= 4:
			break

	print("Equipo a instanciar:", team)
	return team # [{"id": "Astro"}, {"id": "Sigrid"}]

func _on_battle_finished(result: Dictionary) -> void:
	if not pending_battle_rewards.is_empty():
		return
	print("Resultado de batalla recibido: ", result)

	var rewards = BattleResultProcessor.procesar_batalla(result)
	print("[GameManager] Recompensas calculadas: ", rewards)
	pending_battle_rewards = rewards.duplicate(true)

	_mostrar_resultado_batalla()


func _mostrar_resultado_batalla() -> void:
	if pending_battle_rewards.is_empty():
		return

	var results_ui = BattleResultsUIScene.instantiate()
	results_ui.name = "BattleResultsUI"
	var results_layer := CanvasLayer.new()
	results_layer.name = "BattleResultsLayer"
	results_layer.layer = 100
	get_tree().current_scene.add_child(results_layer)
	results_layer.add_child(results_ui)
	results_ui.finished.connect(_cerrar_resultado_batalla)
	push_ui()
	results_ui.mostrar_recompensas(pending_battle_rewards)


func _cerrar_resultado_batalla() -> void:
	if _closing_battle_results or pending_battle_rewards.is_empty():
		return
	_closing_battle_results = true
	var change_error := get_tree().change_scene_to_file("res://Escenas/pantallas/nivel_1.tscn")
	if change_error != OK:
		_closing_battle_results = false
		push_error("[GameManager] No se pudo volver al mapa después de la batalla. Error: %s" % change_error)
		return
	await get_tree().scene_changed
	in_battle = false
	pending_battle_rewards.clear()
	pop_ui()
	_closing_battle_results = false

func is_in_battle() -> bool:
	return in_battle


func push_ui() -> void:
	ui_lock_count += 1
	estado_actual = EstadosDeJuego.MENU

func pop_ui() -> void:
	ui_lock_count = max(ui_lock_count - 1, 0)
	if ui_lock_count == 0:
		estado_actual = EstadosDeJuego.LIBRE if game_started else EstadosDeJuego.MAIN_MENU
