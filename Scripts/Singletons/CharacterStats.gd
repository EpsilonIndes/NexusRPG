extends Node

var character_stats: Dictionary = {}

func set_stats(character_name: String, stats: Dictionary) -> void:
    character_stats[character_name] = stats

func get_stat(character_name: String, stat_name: String) -> int:
    if character_stats.has(character_name) and character_stats[character_name].has(stat_name):
        return character_stats[character_name][stat_name]
    return 0

func get_all_stats(character_name: String) -> Dictionary:
    if character_stats.has(character_name):
        return character_stats[character_name]
    return {}
    