extends EnemyRole
class_name RestrictorRole


func evaluate(context: Dictionary) -> Dictionary:
	var has_condition := bool(context.get("restriction_condition_met", false))
	var tactical_role := TacticalRole.SPECIAL if has_condition else TacticalRole.PROTECT
	return {
		"intent": Intent.ATTACK if has_condition else Intent.DEFEND,
		"tactical_role": tactical_role,
		"technique": _find_tactical_technique(context, [tactical_role, TacticalRole.ATTACK]),
		"target": _find_vulnerable_opponent(context) if has_condition else owner,
		"reason": "restriction_open" if has_condition else "restriction_closed"
	}
