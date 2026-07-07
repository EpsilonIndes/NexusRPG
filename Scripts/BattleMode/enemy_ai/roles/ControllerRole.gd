extends EnemyRole
class_name ControllerRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.CONTROL,
		"tactical_role": TacticalRole.CONTROL,
		"technique": _find_tactical_technique(context, [TacticalRole.CONTROL, TacticalRole.ATTACK]),
		"target": _find_vulnerable_opponent(context),
		"reason": "control_pace"
	}
