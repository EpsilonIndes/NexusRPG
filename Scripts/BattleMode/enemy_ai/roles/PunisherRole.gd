extends EnemyRole
class_name PunisherRole


func evaluate(context: Dictionary) -> Dictionary:
	var repeated_count := int(context.get("repeated_player_technique_count", 0))
	var last_role := str(context.get("last_player_combo_role", ""))

	if repeated_count >= 2 or last_role == "finisher":
		return {
			"intent": Intent.COUNTER,
			"technique": _find_attack_technique(context),
			"target": _find_vulnerable_opponent(context),
			"reason": "punish_repetition_or_finisher"
		}

	return super.evaluate(context)
