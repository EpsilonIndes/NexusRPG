extends RefCounted
class_name PlayableCharacter

var id: String
var class_id: String
var stats: Dictionary
var in_party: bool = false

var hp: int
var mp: int
var mag: int
var ataque: int
var defensa: int
var velocidad: int

func _init(pj_id: String, pj_class_id: String, pj_stats: Dictionary) -> void:
	id = pj_id
	class_id = pj_class_id
	stats = pj_stats.duplicate(true)

func get_stats() -> Dictionary:
	return stats

func get_combat_stats() -> Dictionary:
	return {
		"id": id,
		"class_id": class_id,
		"stats": stats,
		"in_party": in_party,
		"hp": hp,
		"mp": mp,
		"mag": mag,
		"atk": ataque,
		"def": defensa,
		"spd": velocidad,
	}