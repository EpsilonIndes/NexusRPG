extends EnemyRole
class_name SpecialistRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.SPECIAL,
		"tactical_role": TacticalRole.SPECIAL,
		"technique": _find_tactical_technique(context, [TacticalRole.SPECIAL, TacticalRole.ATTACK]),
		"target": _find_vulnerable_opponent(context),
		"reason": str(context.get("specialist_rule", "specialist_default"))
	}
