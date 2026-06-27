extends EnemyRole
class_name PressureRole


func evaluate(context: Dictionary) -> Dictionary:
	var pressure := int(context.get("pressure_turns", 0))
	return {
		"intent": Intent.ATTACK if pressure >= 2 else Intent.CHARGE,
		"technique": _find_attack_technique(context),
		"target": _find_vulnerable_opponent(context),
		"reason": "release_pressure" if pressure >= 2 else "build_pressure"
	}
