extends EnemyRole
class_name SpecialistRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.SPECIAL,
		"tactical_role": TacticalRole.SPECIAL,
		"target": _find_vulnerable_opponent(context),
		"reason": str(context.get("specialist_rule", "specialist_default"))
	}
