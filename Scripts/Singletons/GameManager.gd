# GameManager.gd
extends Node

enum EstadosDeJuego {
	LIBRE,
	DIALOGO,
	COMBATE,
	MENU,
	CINEMATICA
}

var in_battle = false


var equipo_actual: Array[Dictionary] = [ # todos los pjs actuales jugables
	{"id": "Astro"},
	{"id": "Sigrid"},
	{"id": "Maya"},
	{"id": "Amanda"},
	{"id": "Miguelito"},
	{"id": "Chipita"},
]

var ui_lock_count := 0

var estado_actual: EstadosDeJuego = EstadosDeJuego.LIBRE
var primera_carga: bool = false

func _ready():
	DataLoader.init_data()

	if not DataLoader._is_ready:	
		await DataLoader.data_loaded
	
	_initialize_team()
	

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
	in_battle = false
	print("Resultado de batalla recibido: ", result)

	var rewards = BattleResultProcessor.procesar_batalla(result)
	print("[GameManager] Recompensas calculadas: ", rewards)

	set_estado(EstadosDeJuego.LIBRE)
	get_tree().change_scene_to_file("res://Escenas/nivel_1.tscn")

func is_in_battle() -> bool:
	return in_battle


func push_ui() -> void:
	ui_lock_count += 1
	estado_actual = EstadosDeJuego.MENU

func pop_ui() -> void:
	ui_lock_count = max(ui_lock_count - 1, 0)
	if ui_lock_count == 0:
		estado_actual = EstadosDeJuego.LIBRE
