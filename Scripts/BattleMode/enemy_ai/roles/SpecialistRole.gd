extends EnemyRole
class_name SpecialistRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.SPECIAL,
		"technique": _find_attack_technique(context),
		"target": _find_vulnerable_opponent(context),
		"reason": str(context.get("specialist_rule", "specialist_default"))
	}
