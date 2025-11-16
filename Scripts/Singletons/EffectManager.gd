#EffectManager.gd (Autoload)
extends Node


func apply_effects(effects: Array, target_id: String) -> void:
	var character = PlayableCharacters.get_character(target_id)
	if character == null:
		print_debug("No se encontró al personaje con ID: %s" % target_id)
		return

	var stats = character.get_stats()
	if stats.is_empty():
		print_debug("No se encontraron estadísticas para %s" % target_id)
		return

	# effects ya viene parseado desde el DataLoader:
	# [ ["damage", 0.5], ["boost", "spd", 0.2] ]

	for efecto in effects:
		if not (efecto is Array):
			print_debug("Formato de efecto inválido: %s" % str(efecto))
			continue
		if efecto.size() < 2:
			print_debug("efecto_incompleto: %s" % str(efecto))
			continue
		
		var effect_name = efecto[0]
		var value = efecto[1]

		# Tercer valor adicional (boost/nerf)
		var extra_param
		if efecto.size() > 2:
			extra_param = efecto[2]
		else:
			extra_param = null

	# Aplicar efecto
		match effect_name:
			"damage":
				_dmg(stats, target_id, float(value))
			"heal_hp":
				_heal_hp(stats, target_id, float(value))
			"heal_dp":
				_heal_dp(stats, target_id, float(value))
			"boost":
				if extra_param != null:
					_boost_stat(stats, extra_param, float(value), target_id)
			"nerf":
				if extra_param != null:
					_nerf_stat(stats, extra_param, float(value), target_id)
			"revive":
				_heal_hp(stats, target_id, float(value))
				_heal_dp(stats, target_id, float(value))
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
