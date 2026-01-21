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
		var tipo = EnemyDatabase.get_data(enemy_id).get("tipo", "trash") # trash, elite, boss
		
		var multiplicador: float
		match tipo:
			"trash": 
				multiplicador = 1.0
			"elite": 
				multiplicador = 1.5
			"boss": 
				multiplicador = 2.5
			_: 
				multiplicador = 1.0

		total_exp += int(base_exp * multiplicador)

	if jugadores.is_empty():
		return
	
	var drive_bonus = int(result.get("drive_score", 0) / 100)
	total_exp += drive_bonus

	var exp_por_jugador := int(total_exp / jugadores.size())

	for pj_id in jugadores:
		var pj = PlayableCharacters.get_character(pj_id)
		if pj:
			pj.gain_exp(exp_por_jugador)
			rewards["exp"][pj_id] = exp_por_jugador

func _calcular_drops(result: Dictionary, rewards: Dictionary) -> void:
	for drop in result.drops:
		ItemManager.give_item_to_player(
			drop.item_id,
			drop.amount
		)

func _calcular_bonus_drive(result: Dictionary, rewards: Dictionary) -> void:
	pass
