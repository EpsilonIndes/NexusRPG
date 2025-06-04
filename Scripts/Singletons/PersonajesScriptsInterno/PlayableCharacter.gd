extends RefCounted
class_name PlayableCharacter

var name: String
var class_id: String
var stats: Dictionary
var in_party: bool = false

func _init(pj_name: String, class_id_: String, base_stats: Dictionary):
	name = pj_name
	class_id = class_id_
	stats = base_stats.duplicate(true)

func get_stats() -> Dictionary:
	return stats