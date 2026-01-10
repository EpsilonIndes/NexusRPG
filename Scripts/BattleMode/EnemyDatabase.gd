# EnemyDatabase.gd
extends Node

func has_enemy(enemy_id: String) -> bool:
	return DataLoader.enemigos.has(enemy_id)

func get_data(enemy_id: String) -> Dictionary:
	if not has_enemy(enemy_id):
		push_error("Enemy no encontrado: %s" % enemy_id)
		return {}
	return DataLoader.enemigos[enemy_id]

func get_stats(enemy_id: String) -> Dictionary:
	var e = get_data(enemy_id)
	if e.is_empty():
		return {}

	return {
		"id": enemy_id,
		"nombre": e.nombre,
		"tipo": e.tipo,
		"hp": e.hp,
		"mp": e.mp,
		"atk": e.atk,
		"def": e.def,
		"spd": e.spd,
		"lck": e.lck,
		"wis": e.wis,
		"exp": e.exp,
		"class_id": e.class_id
	}

func get_exp(enemy_id: String) -> int:
	var e = get_data(enemy_id)
	return e.exp if e.has("exp") else 0