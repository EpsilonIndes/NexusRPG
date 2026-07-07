extends EnemyRole
class_name PressureRole


func evaluate(context: Dictionary) -> Dictionary:
	var pressure := int(context.get("pressure_turns", 0))
	var tactical_role := TacticalRole.CONTROL if pressure >= 2 else TacticalRole.CHARGE
	return {
		"intent": Intent.ATTACK if pressure >= 2 else Intent.CHARGE,
		"tactical_role": tactical_role,
		"technique": _find_tactical_technique(context, [tactical_role, TacticalRole.ATTACK]),
		"target": _find_vulnerable_opponent(context) if pressure >= 2 else owner,
		"reason": "release_pressure" if pressure >= 2 else "build_pressure"
	}
