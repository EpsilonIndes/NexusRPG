extends Node

# Diccionario de personajes jugables
var characters: Dictionary = {}

func add_character(pj_name: String, class_nombre: String):
    var stats = StatsLoader.get_class_stats(class_nombre)
    CharacterStats.set_stats(pj_name, stats)
    characters[pj_name] = {
        "class": class_nombre,
        "stats": stats
    }

func get_stat(pj_name: String, stat: String) -> int:
    return CharacterStats.get_stat(pj_name, stat)

func get_all_stats(pj_name: String) -> Dictionary:
    return CharacterStats.get_all_stats(pj_name)
