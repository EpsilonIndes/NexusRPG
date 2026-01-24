# BattleResultProcessor.gd (Autoload)
# Objetivo:
#	Tomar el BattleResult
#	Calcular EXP por enemigos derrotados
#	Repartirla a los jugadores participantes
#	Devolver un RewardsResult limpio
extends Node

func procesar_batalla(result: Dictionary) -> Dictionary:
	var rewards := {
		"exp": {},			# { "Astro": 120, "Maya": 90, ...}
		"items": [],		# Vacío por ahora
		"drive_bonus": 0	# reservado
	}

	if not result.victoria:
		return rewards
	
	_calcular_exp(result, rewards)
	_calcular_drops(result, rewards)
	_calcular_bonus_drive(result, rewards)
	return rewards

func _calcular_exp(result: Dictionary, rewards: Dictionary) -> void:
	var enemigos = result.get("enemigos_derrotados", [])
	var jugadores = result.get("jugadores", [])

	var total_exp := 0

	for enemy_id in enemigos:
		var base_exp = EnemyDatabase.get_exp(enemy_id)
		var tipo = EnemyDatabase.get_data(enemy_id).get("tipo", "trash")

		var multiplicador := 1.0
		match tipo:
			"elite": multiplicador = 1.5
			"boss": multiplicador = 2.5

		total_exp += int(base_exp * multiplicador)

	if jugadores.is_empty():
		return

	# Bonus plano por DriveScore (ya lo tenías)
	var drive_flat_bonus = int(result.get("drive_score", 0) / 100)
	total_exp += drive_flat_bonus

	# NUEVO: multiplicador por DriveRank
	#var drive_bonus = rewards.get("drive_bonus", {})
	
	var exp_multiplier := 1.0

	if rewards.has("drive_bonus") and rewards["drive_bonus"] is Dictionary:
		exp_multiplier = rewards["drive_bonus"].get("exp_multiplier", 1.0)
	
	total_exp = int(total_exp * exp_multiplier)

	var exp_por_jugador := int(total_exp / jugadores.size())

	for pj_id in jugadores:
		var pj = PlayableCharacters.get_character(pj_id)
		if pj:
			pj.gain_exp(exp_por_jugador)
			rewards["exp"][pj_id] = exp_por_jugador


func _calcular_drops(result: Dictionary, rewards: Dictionary) -> void:
	var enemigos = result.get("enemigos_derrotados", [])
	var drive_score = result.get("drive_score", 0)

	var drop_bonus = 1.0 + (drive_score / 500.0) # Tunear luego

	for enemy_id in enemigos:
		var drops = DropDatabase.get_drops(enemy_id, drop_bonus)

		for drop in drops:
			ItemManager.give_item_to_player(
				drop.item_id,
				drop.amount
			)
			rewards["items"].append(drop)

		
		

func _calcular_bonus_drive(result: Dictionary, rewards: Dictionary) -> void:
	var score = result.get("drive_score", 0)

	var bonus := {
		"rank": "D",
		"exp_multiplier": 1.0,
		"extra_drop_chance": 0.0
	}

	if score >= 5000:
		bonus.rank = "S"
		bonus.exp_multiplier = 1.25
		bonus.extra_drop_chance = 0.20
	elif score >= 3500:
		bonus.rank = "A"
		bonus.exp_multiplier = 1.15
	if score >= 2000:
		bonus.rank = "B"
		bonus.exp_multiplier = 1.10
	if score >= 1000:
		bonus.rank = "C"
		bonus.exp_multiplier = 1.05
	
	rewards["drive_bonus"] = bonus
