extends Node
var failures := 0
var owned_files: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("SAVE TEST: " + message)

func _run() -> void:
	reparent(get_tree().root)
	var before := PackedStringArray()
	if DirAccess.dir_exists_absolute(SaveManager.SAVE_DIR):
		before = DirAccess.get_files_at(SaveManager.SAVE_DIR)
	await GameManager.start_game()
	await get_tree().process_frame
	check(SaveManager.can_save(), "New game permits saving")
	check(not SceneTransition.active and not get_tree().paused, "New game restores gameplay after fade")
	var player: Node3D = get_tree().current_scene.get_node("Personajes/Player")
	player.global_position = Vector3(3, 1, 4)
	PlayableCharacters.add_to_party("Maya")
	PlayableCharacters.get_character("Astro").stats["hp"] = 42
	InventoryManager.items = {"key": 3}
	WorldFlags.set_flag("test_chest")
	GlobalTechniqueDatabase.tecnica_equipada["Astro"] = ["astro_01"]
	SaveManager.play_seconds = 123.0
	check(SaveManager.save_game("Prueba de integración"), "Create save")
	for filename in DirAccess.get_files_at(SaveManager.SAVE_DIR):
		if filename not in before and filename.ends_with(".sav"):
			owned_files.append(filename)
	check(owned_files.size() == 1, "Creates one unique file")
	if not owned_files.is_empty():
		var filename := owned_files[0]
		var saved := SaveManager.read_save(filename)
		check(not saved.is_empty(), "Written save validates")
		check(SaveManager.save_game("Sobrescrito", filename), "Overwrite")
		check(SaveManager.save_game("Sobrescrito otra vez", filename), "Repeated overwrite")
		check(FileAccess.file_exists(SaveManager.SAVE_DIR + filename + ".bak"), "Backup exists")
		InventoryManager.items.clear()
		WorldFlags.flags.clear()
		PlayableCharacters.get_character("Astro").stats["hp"] = 1
		check(await SaveManager.load_game(filename), "Load succeeds")
		check(not SceneTransition.active and not get_tree().paused, "Load releases transition and pause")
		check(InventoryManager.items.get("key") == 3, "Inventory restored")
		check(WorldFlags.has_flag("test_chest"), "World flags restored")
		check(PlayableCharacters.get_character("Astro").stats.hp == 42, "HP restored")
		check(PlayableCharacters.get_party_actual() == ["Astro", "Maya"], "Party restored")
		check(GlobalTechniqueDatabase.tecnica_equipada.Astro == ["astro_01"], "Techniques restored")
		player = get_tree().current_scene.get_node("Personajes/Player")
		check(player.global_position.is_equal_approx(Vector3(3, 1, 4)), "Position restored before world ready")
		check(GameManager.ui_lock_count == 0, "UI locks reset")
		var panel = load("res://Escenas/UserUI/save_slots_ui.tscn").instantiate()
		get_tree().current_scene.get_node("CanvasLayer").add_child(panel)
		panel.open(true)
		check(panel.slots.size() >= 1, "Save list populated")
		var accept_key := InputEventKey.new()
		accept_key.keycode = KEY_ENTER
		accept_key.pressed = true
		get_viewport().push_input(accept_key, true)
		check(panel.new_dialog.visible, "Enter activates new-save row")
		panel.new_dialog.hide()
		panel._focus_list()
		for index in panel.slots_list.item_count:
			if panel.slots_list.get_item_metadata(index) == filename:
				panel.slots_list.select(index)
		get_viewport().push_input(accept_key, true)
		check(panel.confirmation.visible and panel.pending_action == "save", "Enter activates selected save")
		panel.confirmation.hide()
		panel._focus_list()
		panel.mode_tabs.current_tab = 1
		for index in panel.slots_list.item_count:
			if panel.slots_list.get_item_metadata(index) == filename:
				panel.slots_list.select(index)
		var accept_pad := InputEventJoypadButton.new()
		accept_pad.button_index = JOY_BUTTON_A
		accept_pad.pressed = true
		get_viewport().push_input(accept_pad, true)
		check(panel.confirmation.visible and panel.pending_action == "load", "Controller accept activates load")
		panel.confirmation.hide()
		panel._focus_list()
		var triangle := InputEventJoypadButton.new()
		triangle.button_index = JOY_BUTTON_Y
		triangle.pressed = true
		get_viewport().push_input(triangle, true)
		check(panel.confirmation.visible and panel.pending_action == "delete", "Triangle opens delete confirmation")
		check(FileAccess.file_exists(SaveManager.SAVE_DIR + filename), "Delete requires confirmation")
		panel.confirmation.hide()
		panel._focus_list()
		var delete_key := InputEventKey.new()
		delete_key.keycode = KEY_R
		delete_key.pressed = true
		get_viewport().push_input(delete_key, true)
		check(panel.confirmation.visible and panel.pending_action == "delete", "R opens delete confirmation")
		panel.confirmation.hide()
		check(FileAccess.file_exists(SaveManager.SAVE_DIR + filename), "Cancel keeps save")
		panel.close()
		check(GameManager.ui_lock_count == 0, "Panel close releases lock")
		panel.queue_free()
		check(SaveManager.read_save("../escape.sav").is_empty(), "Reject path traversal")
		var broken := saved.duplicate(true)
		broken["version"] = 999
		check(not SaveManager._validate(broken), "Reject unknown version")
		broken = saved.duplicate(true)
		broken["party"] = ["Missing"]
		check(not SaveManager._validate(broken), "Reject missing party member")
		var corrupt_name := "save_%s.sav" % Crypto.new().generate_random_bytes(16).hex_encode()
		owned_files.append(corrupt_name)
		var corrupt_file := FileAccess.open(SaveManager.SAVE_DIR + corrupt_name, FileAccess.WRITE)
		corrupt_file.store_var({"version": 999})
		corrupt_file.close()
		check(not await SaveManager.load_game(corrupt_name), "Corrupt file rejected on disk")
		check(not SceneTransition.active and not get_tree().paused and not SaveManager.busy, "Failed load reveals previous screen and releases locks")
		check(InventoryManager.items.get("key") == 3, "Failed load preserves current progress")
		check(SaveManager.get_existing_slots().size() >= 2, "Corrupt saves remain visible")
		GameManager.in_battle = true
		check(not SaveManager.save_game("Battle"), "Cannot save during battle")
		GameManager.in_battle = false
		get_tree().change_scene_to_file("res://Escenas/pantallas/menu.tscn")
		await get_tree().scene_changed
		var menu := get_tree().current_scene
		check(not menu.load_button.disabled, "Title screen enables load")
		menu._on_load_pressed()
		check(menu.save_slots.visible and not menu.save_slots.allow_save, "Title opens load-only panel")
		check(await SaveManager.load_game(filename), "Load from title succeeds")
		check(not SaveManager.delete_save("../escape.sav"), "Delete rejects path traversal")
		check(SaveManager.delete_save(corrupt_name), "Can delete damaged save")
		check(FileAccess.file_exists(SaveManager.SAVE_DIR + filename), "Deleting another slot preserves selected save")
		check(SaveManager.delete_save(filename), "Delete valid save")
		check(not FileAccess.file_exists(SaveManager.SAVE_DIR + filename) and not FileAccess.file_exists(SaveManager.SAVE_DIR + filename + ".bak"), "Deletion removes file and backup")
		SaveManager.reset_progress()
		check(InventoryManager.items.is_empty() and WorldFlags.flags.is_empty(), "New game reset clears progress")
	for filename in owned_files:
		for suffix in ["", ".bak", ".tmp"]:
			var path: String = SaveManager.SAVE_DIR + filename + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	print("SAVE INTEGRATION: %d failures" % failures)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
