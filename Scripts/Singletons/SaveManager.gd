# SaveManager.gd (Autoload)
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".sav"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func build_save_data() -> Dictionary:
	return {
		"meta": {
			"version": 1,
			"timestamp": Time.get_unix_time_from_system()
		},
		"player": {
			"position": Vector3.ZERO,
			"drive_score": 0
		},
		"party_stats": {
			"Astro": {"level": 5, "hp": 120}
		}
	}

func save_game(slot: int) -> void:
	var path := SAVE_DIR + "Slot_%d%s" % [slot, SAVE_EXTENSION]
	var file := FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_var(build_save_data())
		file.close()

func load_game(slot: int) -> Dictionary:
	var path := SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]

	if not FileAccess.file_exists(path):
		push_warning("No existe el slot %d" % slot)
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = file.get_var()
	file.close()

	return data

func get_existing_slots() -> Array:
	var slots := []
	var dir := DirAccess.open(SAVE_DIR)

	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()

		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION):
				slots.append(file_name)
			file_name = dir.get_next()

		dir.list_dir_end()

	return slots