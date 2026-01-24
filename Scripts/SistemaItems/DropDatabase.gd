"""
DropDatabase.gd (Autoload)

Carga CSV
Resuelve la tabla
Devuelve Drops

"""
extends Node

func get_drops(enemy_id: String, drop_bonus: float = 1.0) -> Array:
	var result: Array = []

	if not DataLoader.drops.has(enemy_id):
		push_warning("[DropDatabase] Enemigo sin drops:", enemy_id)
		return result

	var drop_table = DataLoader.drops[enemy_id]

	for drop in drop_table:
		var chance: float = float(drop.get("chance", 0.0))
		chance *= drop_bonus
		chance = clamp(chance, 0.0, 1.0)

		if randf() <= chance:
			var min_amount: int = int(drop.get("min", 1))
			var max_amount: int = int(drop.get("max", 1))

			result.append({
				"item_id": drop.get("item_id"),
				"amount": randi_range(min_amount, max_amount)
			})

	return result



func get_drops_viejo(enemy_id: String, drop_bonus: float = 1.0) -> Array:
	var result: Array = []

	print("[DropDatabase] enemy_id recibido:", enemy_id)
	print("[DropDatabase] keys disponibles:", DataLoader.drops.keys())
	if not DataLoader.drops.has(enemy_id):
		push_warning("[DropDatabase] Enemigo no existente o id Errónea, retornando result: ", result)
		return result

	var drop_table = DataLoader.drops[enemy_id]

	for drop in drop_table:
		var chance: float = drop.get("chance", 0.0)
		chance *= drop_bonus

		if randf() <= chance:
			var min_amount: int = drop.get("min", 1)
			var max_amount: int = drop.get("max", 1)

			var amount := randi_range(min_amount,max_amount)

			result.append({
				"item_id": drop.get("item_id"),
				"amount": amount
			})
	
	return result
