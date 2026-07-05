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
		"atk": e.atk,
		"def": e.def,
		"spd": e.spd,
		"lck": e.lck,
		"wis": e.wis,
		"exp": e.exp,
		"class_id": e.class_id,
		"enemy_role_id": e.get("enemy_role_id", _role_id_from_class_id(str(e.get("class_id", ""))))
	}

func get_role_data(role_id: String) -> Dictionary:
	if role_id == "":
		return {}

	if not DataLoader.enemy_roles.has(role_id):
		push_warning("Enemy role no encontrado: %s" % role_id)
		return {}

	return DataLoader.enemy_roles[role_id]

func get_exp(enemy_id: String) -> int:
	var e = get_data(enemy_id)
	return e.exp if e.has("exp") else 0

func get_drop_table(enemy_id: String) -> String:
	return get_data(enemy_id).get("drop_table", "")

func _role_id_from_class_id(class_id: String) -> String:
	match class_id:
		"C001":
			return "R001"
		"C002":
			return "R002"
		"C003":
			return "R003"
		_:
			return "R001"
