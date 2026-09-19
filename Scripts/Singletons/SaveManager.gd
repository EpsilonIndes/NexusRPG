extends Node
signal load_failed(message: String)
## Object-free, versioned save files. Resume only in exploration.
const SAVE_DIR := "user://saves/"
const WORLD_SCENE := "res://Escenas/pantallas/nivel_1.tscn"
const VERSION := 1
var last_error := ""
var busy := false
var play_seconds := 0.0
var _default_techniques: Dictionary
var _default_equipped: Dictionary

func _ready() -> void:
	_default_techniques = GlobalTechniqueDatabase.tecnica_obtenida.duplicate(true)
	_default_equipped = GlobalTechniqueDatabase.tecnica_equipada.duplicate(true)

func _process(delta: float) -> void:
	if GameManager.game_started and not busy:
		play_seconds += delta

func can_save() -> bool:
	var scene := get_tree().current_scene
	return not busy and GameManager.game_started and not GameManager.in_battle and scene != null and scene.scene_file_path == WORLD_SCENE and GameManager.estado_actual in [GameManager.EstadosDeJuego.LIBRE, GameManager.EstadosDeJuego.MENU]

func reset_progress() -> void:
	PlayableCharacters.characters.clear()
	PlayableCharacters.party_actual.clear()
	PlayableCharacters.spawn_override.clear()
	PlayableCharacters.jugador_actual = "Astro"
	InventoryManager.items.clear()
	WorldFlags.flags.clear()
	WorldStateManager.clear_snapshot()
	GlobalTechniqueDatabase.tecnica_obtenida = _default_techniques.duplicate(true)
	GlobalTechniqueDatabase.tecnica_equipada = _default_equipped.duplicate(true)
	GameManager.primera_carga = false
	GameManager.game_started = false
	GameManager.in_battle = false
	GameManager.ui_lock_count = 0
	play_seconds = 0.0

func build_save_data(title: String) -> Dictionary:
	var scene := get_tree().current_scene
	var player := scene.get_node("Personajes/Player") as Node3D
	var characters := {}
	for id in PlayableCharacters.characters:
		var character: PlayableCharacter = PlayableCharacters.characters[id]
		characters[id] = {"class_id": character.class_id, "stats": character.stats.duplicate(true)}
	return {
		"version": VERSION, "title": title.strip_edges().left(64),
		"timestamp": Time.get_unix_time_from_system(), "play_seconds": play_seconds,
		"scene": scene.scene_file_path,
		"world": {"player_position": player.global_position, "player_rotation": player.global_rotation},
		"characters": characters, "party": PlayableCharacters.get_party_actual().duplicate(),
		"leader": PlayableCharacters.jugador_actual, "items": InventoryManager.items.duplicate(true),
		"flags": WorldFlags.flags.duplicate(true),
		"techniques": GlobalTechniqueDatabase.tecnica_obtenida.duplicate(true),
		"equipped": GlobalTechniqueDatabase.tecnica_equipada.duplicate(true)
	}

func _valid_filename(filename: String) -> bool:
	return filename == filename.get_file() and filename.begins_with("save_") and filename.ends_with(".sav")

func save_game(title: String, filename: String = "") -> bool:
	last_error = ""
	if not can_save():
		return _fail("Solo se puede guardar durante la exploración.")
	if filename.is_empty():
		filename = "save_%s.sav" % Crypto.new().generate_random_bytes(16).hex_encode()
	elif not _valid_filename(filename) or not FileAccess.file_exists(SAVE_DIR + filename):
		return _fail("El archivo seleccionado ya no existe.")
	if DirAccess.make_dir_recursive_absolute(SAVE_DIR) != OK:
		return _fail("No se pudo crear la carpeta de guardados.")
	if title.strip_edges().is_empty():
		title = "Mi partida"
	var path := SAVE_DIR + filename
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return _fail("No se pudo escribir la partida.")
	file.store_var(build_save_data(title), false)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return _fail("No se pudo completar el guardado. El archivo anterior sigue intacto.")
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(path, path + ".bak") != OK:
			return _fail("No se pudo proteger el guardado anterior.")
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.rename_absolute(path + ".bak", path)
		return _fail("No se pudo finalizar el archivo de guardado.")
	return true

func read_save(filename: String) -> Dictionary:
	last_error = ""
	if not _valid_filename(filename):
		_fail("Nombre de archivo inválido.")
		return {}
	var file := FileAccess.open(SAVE_DIR + filename, FileAccess.READ)
	if file == null or file.get_length() > 16000000:
		_fail("No se pudo leer el guardado.")
		return {}
	var data: Variant = file.get_var(false)
	file.close()
	if not _validate(data):
		_fail("Guardado dañado, incompatible o de una versión no admitida.")
		return {}
	return data

func delete_save(filename: String) -> bool:
	last_error = ""
	if busy or GameManager.in_battle:
		return _fail("No se puede eliminar en este momento.")
	if not _valid_filename(filename):
		return _fail("Nombre de archivo inválido.")
	var path := SAVE_DIR + filename
	if not FileAccess.file_exists(path):
		return _fail("El archivo seleccionado ya no existe.")
	# Remove only companions of this exact slot; never enumerate unrelated saves.
	for suffix in [".bak", ".tmp", ""]:
		var target: String = path + suffix
		if FileAccess.file_exists(target) and DirAccess.remove_absolute(target) != OK:
			return _fail("No se pudo eliminar completamente el guardado. Intentá de nuevo.")
	return true

func _validate(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.get("version") != VERSION or data.get("scene") != WORLD_SCENE:
		return false
	for key in ["characters", "items", "flags", "techniques", "equipped", "world"]:
		if not data.get(key) is Dictionary:
			return false
	if not data.get("title") is String or not data.get("timestamp") is float or not data.get("play_seconds") is float:
		return false
	if not is_finite(data.play_seconds) or data.play_seconds < 0 or not is_finite(data.timestamp):
		return false
	if not data.get("party") is Array or data.party.is_empty() or not data.get("leader") is String or data.leader not in data.party:
		return false
	if not data.world.get("player_position") is Vector3 or not data.world.get("player_rotation") is Vector3:
		return false
	if not data.world.player_position.is_finite() or not data.world.player_rotation.is_finite():
		return false
	for id in data.characters:
		var entry: Variant = data.characters[id]
		if not id is String or not DataLoader.stats.has(id) or not entry is Dictionary:
			return false
		if not entry.get("class_id") is String or not entry.get("stats") is Dictionary:
			return false
		for key in DataLoader.stats[id]:
			if key == "in_party":
				continue
			if not entry.stats.has(key):
				return false
			var expected: Variant = DataLoader.stats[id][key]
			var actual: Variant = entry.stats[key]
			if expected is float or expected is int:
				if not (actual is float or actual is int) or not is_finite(float(actual)):
					return false
			elif typeof(actual) != typeof(expected):
				return false
	for id in data.party:
		if not id is String or not data.characters.has(id) or data.party.count(id) != 1:
			return false
	for id in data.items:
		if not id is String or not data.items[id] is int or data.items[id] <= 0:
			return false
	for id in data.flags:
		if not id is String or not data.flags[id] is bool:
			return false
	for key in ["techniques", "equipped"]:
		for id in data[key]:
			if not id is String or not data[key][id] is Array:
				return false
			for technique in data[key][id]:
				if not technique is String:
					return false
	return true

func get_existing_slots() -> Array[Dictionary]:
	DataLoader.init_data()
	var slots: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return slots
	for filename in DirAccess.get_files_at(SAVE_DIR):
		if not _valid_filename(filename):
			continue
		var data := read_save(filename)
		slots.append({"filename": filename, "data": data, "error": last_error})
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.data.get("timestamp", 0) > b.data.get("timestamp", 0))
	return slots

func load_game(filename: String) -> bool:
	if busy or GameManager.in_battle:
		return _fail("No se puede cargar en este momento.")
	busy = true
	await SceneTransition.cover()
	DataLoader.init_data()
	var data := read_save(filename)
	if data.is_empty():
		return await _load_error(last_error)
	var packed := load(WORLD_SCENE) as PackedScene
	if packed == null:
		return await _load_error("No se pudo abrir el mapa de la partida.")
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		return await _load_error("No se pudo cambiar al mapa guardado.")
	# Scene replacement is deferred; install state before the new world's _ready.
	reset_progress()
	for id in data.characters:
		var entry: Dictionary = data.characters[id]
		var character := PlayableCharacter.new(id, entry.class_id, entry.stats)
		character.in_party = id in data.party
		PlayableCharacters.characters[id] = character
	PlayableCharacters.party_actual = data.party.duplicate()
	PlayableCharacters.jugador_actual = data.leader
	InventoryManager.items = data.items.duplicate(true)
	WorldFlags.flags = data.flags.duplicate(true)
	GlobalTechniqueDatabase.tecnica_obtenida = data.techniques.duplicate(true)
	GlobalTechniqueDatabase.tecnica_equipada = data.equipped.duplicate(true)
	# Seguidores son regenerados alrededor del jugador usando PartyHandler.
	WorldStateManager.snapshot = data.world.duplicate(true)
	play_seconds = data.play_seconds
	GameManager.game_started = true
	GameManager.primera_carga = true
	GameManager.set_estado(GameManager.EstadosDeJuego.LIBRE)
	await get_tree().scene_changed
	InventoryManager.inventory_changed.emit()
	await SceneTransition.reveal()
	busy = false
	return true

func _load_error(message: String) -> bool:
	await SceneTransition.reveal()
	busy = false
	last_error = message
	load_failed.emit(message)
	return false

func _fail(message: String) -> bool:
	last_error = message
	return false
