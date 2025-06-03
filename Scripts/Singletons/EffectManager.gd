#EffectManager.gd (Autoload)
extends Node

func apply_effects(effects: Array, target_id: String) -> void:
	var character = PlayableCharacters.characters.get(target_id)
	if character == null:
		print_debug("No se encontró al personaje con ID: %s" % target_id)
		return

	var stats = character.get("stats", {})
	if stats.is_empty():
		print_debug("No se encontraron estadísticas para %s" % target_id)
		return

	for effect in effects:
		match effect:
			"heal_hp":
				_heal_hp(stats)
			"heal_mp":
				_heal_mp(stats)
			"boost_atk":
				_boost_stat(stats, "atk", 10)
			"nerf_atk":
				_nerf_stat(stats, "atk", 10)
			_:  # efecto desconocido
				print_debug("Efecto no reconocido: %s" % effect)

# Efectos tanto de items como de habilidades 
func _heal_hp(stats: Dictionary): # Poción básica
	var max_hp = stats.get("max_hp", 100)
	stats["hp"] = min(stats.get("hp", 0) + 50, max_hp)

func _heal_mp(stats: Dictionary): # Éter
	var max_mp = stats.get("max_mp", 50)
	stats["mp"] = min(stats.get("mp", 0) + 30, max_mp)

func _boost_stat(stats: Dictionary, stat_name: String, amount: int): 
	if not stats.has(stat_name):
		print_debug("Stat no encontrada: %s" % stat_name)
		return
	stats[stat_name] += amount

func _nerf_stat(stats: Dictionary, stat_name: String, amount: int):
	if not stats.has(stat_name):
		print_debug("Stat no encontrada: %s" % stat_name)
		return
	stats[stat_name] -= amount

func physic_damage(stats: Dictionary, damage: int, target_id: String):
	var hp = stats.get("hp", 100)
	damage = min(damage, hp)
	hp -= damage # por ahora, logica simple
	stats["hp"] = max(hp, 0)
	print_debug("Daño físico aplicado a %s: %d" % [target_id, damage])

