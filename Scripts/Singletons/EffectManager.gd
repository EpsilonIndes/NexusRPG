#EffectManager.gd (Autoload)
extends Node


func apply_effects(effect: Variant, target_id: String) -> void:
	var character = PlayableCharacters.get_character(target_id)
	if character == null:
		print_debug("No se encontró al personaje con ID: %s" % target_id)
		return

	var stats = character.get_stats()
	if stats.is_empty():
		print_debug("No se encontraron estadísticas para %s" % target_id)
		return

	var effects_list: Array = [] # ["heal_hp", "100"]
	if effect is String:
		effects_list = [effect]
	elif effect is Array:
		effects_list = effect
	else:
		print_debug("Efecto inválido: %s (tipo: %s)" % [str(effect), typeof(effect)])
		return

	# Parseo de effects
	for efecto in effects_list:
		var effect_name := ""
		var multiplier := 1.0
		
		# Tolerancia: puede venir como ["heal_hp", "100"] 0 "heal_hp:100"
		if efecto is Array:
			effect_name = efecto[0]
			if efecto.size() > 1:
				var val = efecto[1]
				multiplier = float(val) if val is String else float(val)
			elif efecto is String:
				var parts = efecto.split(":")
				effect_name = parts[0]
				if parts.size() > 1:
					multiplier = float(parts[1])


	# Aplicar efecto
		match effect_name:
			"damage":
				_dmg(stats, target_id, multiplier)
			"heal_hp":
				_heal_hp(stats, target_id, multiplier)
			"heal_dp":
				_heal_dp(stats, target_id, multiplier)
			"boost":
				if efecto.size() > 2:
					var stat_name = efecto[1]
					_boost_stat(stats, stat_name, multiplier, target_id)
			"nerf":
				if efecto.size() > 2:
					var stat_name = efecto[1]
					_nerf_stat(stats, stat_name, multiplier, target_id)
			_:  # efecto desconocido
				print_debug("Efecto no reconocido: %s" % str(effect_name))

# Efectos tanto de items como de habilidades 
func _dmg(stats: Dictionary, target_id: String, mult: float) -> void:
	var hp = stats.get("hp", 100)
	var atk = stats.get("atk", 10)
	var final_damage = int(atk * mult)
	final_damage = min(final_damage, hp)
	stats["hp"] = max(hp - final_damage, 0)
	print_debug("Daño aplicado a %s: %d (mult: %.2f) | HP restante: %d" % [target_id, final_damage, mult, stats["hp"]])

func _heal_hp(stats: Dictionary, target_id: String, mult: float) -> void: # Poción básica
	var max_hp = stats.get("max_hp", 100)
	var base_heal = stats.get("wis", 5)
	var heal = int(base_heal * mult)
	stats["hp"] = min(stats.get("hp", 0) + heal, max_hp)
	print_debug("%s recupera %d HP (mult: %.2f) | HP actual: %d" % [target_id, heal, mult, stats["hp"]])

func _heal_dp(stats: Dictionary, target_id: String, mult: float) -> void:
	var max_dp = stats.get("max_dp", 50)
	var base_recover = stats.get("wis", 5)
	var recover = int(base_recover * mult)
	stats["dp"] = min(stats.get("dp", 0) + recover, max_dp)
	print_debug("%s recupera %d PD (mult: %.2f) | PD actual: %d" % [target_id, recover, mult, stats["dp"]])

func _boost_stat(stats: Dictionary, stat_name: String, mult: float, target_id: String) -> void:
	if not stats.has(stat_name):
		print_debug("Stat no encontrada: %s" % stat_name)
		return
	var boost = int(stats[stat_name] * mult)
	stats[stat_name] += boost
	print_debug("%s aumenta %s en %d (mult: %.2f) | Nuevo valor: %d" % [target_id, stat_name, boost, mult, stats[stat_name]])

func _nerf_stat(stats: Dictionary, stat_name: String, mult: float, target_id: String) -> void:
	if not stats.has(stat_name):
		print_debug("Stat no encontrada: %s" % stat_name)
		return
	var nerf = int(stats[stat_name] * mult)
	stats[stat_name] = max(0, stats[stat_name] - nerf)
	print_debug("%s reduce %s en %d (mult: %.2f) | Nuevo valor: %d" % [target_id, stat_name, nerf, mult, stats[stat_name]])
