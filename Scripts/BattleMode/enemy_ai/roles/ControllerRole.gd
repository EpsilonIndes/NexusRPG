extends EnemyRole
class_name ControllerRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.CONTROL,
		"tactical_role": TacticalRole.CONTROL,
		"target": _find_vulnerable_opponent(context),
		"reason": "control_pace"
	}
