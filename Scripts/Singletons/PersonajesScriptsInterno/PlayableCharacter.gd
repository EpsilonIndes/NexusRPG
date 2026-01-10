extends RefCounted
class_name PlayableCharacter

var id: String
var class_id: String
var stats: Dictionary
var in_party: bool = false

var hp: int
var dp: int
var ataque: int
var defensa: int
var velocidad: int
var suerte: int
var inteligencia: int


func _init(pj_id: String, pj_class_id: String, pj_stats: Dictionary) -> void:
	id = pj_id
	class_id = pj_class_id
	stats = pj_stats.duplicate(true)

# Experiencia y Nivel
func gain_exp(amount: int) -> void:
	if amount <= 0:
		return

	# Aplicar bonus del Drive
	if not stats.has("exp_actual"):
		stats["exp_actual"] = 0
	if not stats.has("exp_para_siguiente"):
		stats["exp_para_siguiente"] = 100 # fallback
	
	stats["exp_actual"] += amount
	print("[%s] ganó %d EXP! Total: %d" % [id, amount, stats["exp_actual"]])

	while stats["exp_actual"] >= stats["exp_para_siguiente"]:
		stats["exp_actual"] -= stats["exp_para_siguiente"]
		_level_up()

func _level_up() -> void:
	# Subir stats, aumentar exp apra siguiente nivel, etc
	stats["nivel"] = stats.get("nivel", 1) +1
	stats["exp_para_siguiente"] = int(stats["exp_para_siguiente"] * 1.2)
	# bonus de stats:
	stats["hp"] += 5
	stats["atk"] += 2
	stats["def"] += 2
	stats["spd"] += 1
	print("[%s] subió al nivel %d!" % [id, stats["nivel"]])


func get_stats() -> Dictionary:
	return stats

func get_combat_stats() -> Dictionary:
	return {
		"id": id,
		"class_id": class_id,
		"stats": stats,
		"in_party": in_party,
		"hp": hp,
		"dp": dp,
		"atk": ataque,
		"def": defensa,
		"spd": velocidad,
		"lck": suerte,
		"wis": inteligencia,
	}