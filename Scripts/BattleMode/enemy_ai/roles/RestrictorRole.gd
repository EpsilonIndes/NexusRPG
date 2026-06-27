extends EnemyRole
class_name RestrictorRole


func evaluate(context: Dictionary) -> Dictionary:
	var has_condition := bool(context.get("restriction_condition_met", false))
	return {
		"intent": Intent.ATTACK if has_condition else Intent.DEFEND,
		"technique": _find_attack_technique(context),
		"target": _find_vulnerable_opponent(context),
		"reason": "restriction_open" if has_condition else "restriction_closed"
	}
