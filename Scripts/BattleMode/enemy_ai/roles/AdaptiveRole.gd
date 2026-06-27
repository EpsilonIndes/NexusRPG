extends EnemyRole
class_name AdaptiveRole


func evaluate(context: Dictionary) -> Dictionary:
	var most_used := _get_most_used_player_technique(context)
	if most_used != "":
		return {
			"intent": Intent.COUNTER,
			"technique": _find_attack_technique(context),
			"target": _find_vulnerable_opponent(context),
			"reason": "adapt_to_%s" % most_used
		}

	return super.evaluate(context)


func _get_most_used_player_technique(context: Dictionary) -> String:
	var usage: Dictionary = context.get("player_technique_usage", {})
	var best_id := ""
	var best_count := 0
	for tech_id in usage.keys():
		var count := int(usage[tech_id])
		if count > best_count:
			best_count = count
			best_id = str(tech_id)
	return best_id
