extends EnemyRole
class_name ControllerRole


func evaluate(context: Dictionary) -> Dictionary:
	return {
		"intent": Intent.CONTROL,
		"technique": _find_attack_technique(context),
		"target": _find_vulnerable_opponent(context),
		"reason": "control_pace"
	}
