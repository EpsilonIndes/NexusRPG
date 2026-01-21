# ItemEffectManager.gd (Autoload)
extends Node

func apply_effects(effect_list: Array, character_id: String) -> bool:
	for efecto in effect_list:
		if not _apply_single_effect(efecto, character_id):
			return false
	
	return true



func _apply_single_effect(efecto: Array, character_id: String) -> bool: # efecto = ["boost","atk", 0.5]
	var tipo = efecto[0]

	match tipo:
		"heal_fixed":
			var amount = float(efecto[1])
			var chara = PlayableCharacters.get_character(character_id)
			
			var hp_actual = chara.stats["hp"]
			var hp_max = chara.stats["max_hp"]

			var hp_nuevo = min(hp_actual + amount, hp_max)
			var heal_real = hp_nuevo - hp_actual

			chara.stats["hp"] = hp_nuevo
			print("Curación mundo libre:", heal_real)

		"boost":
			var stat = efecto[1]
			var mult = float(efecto[2])
			var chara = PlayableCharacters.get_character(character_id)
			var cant = int(chara.stats[stat] * mult)
			chara.stats[stat] += cant
		
		"revive":
			var chara = PlayableCharacters.get_character(character_id)
			var cant = int(chara.stats["max_hp"] / 2)
			chara.stats["hp"] = cant
		_:
			print("[ItemeffectManager] En batalla: %s", GameManager.is_in_battle())
			print("Efecto no soportado en mundo libre:", tipo)
			return false
		
	return true
